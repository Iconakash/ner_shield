import 'dart:async';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import 'offline_tile_cache.dart';

/// Result of a tile fetch attempt.
class TileFetchResult {
  const TileFetchResult.bytes(this.bytes, {required this.contentType})
      : fromCache = false,
        offline = false;
  const TileFetchResult.fromCache(this.bytes, {required this.contentType})
      : fromCache = true,
        offline = false;
  const TileFetchResult.offlineMiss({required this.contentType})
      : bytes = null,
        fromCache = false,
        offline = false;

  final Uint8List? bytes;
  final String contentType;
  final bool fromCache;
  final bool offline;
}

/// Phase 4 — single-shot tile fetcher. Pulls tiles from the persistent
/// cache first; on miss, downloads via [http] (kept tiny — one
/// dependency, no Dio needed for tile fetches) and writes through.
///
/// Update strategy (Phase 4 §4.3):
///   * When [maxTileAge] is null (default) a cached tile is always served.
///   * When [maxTileAge] is set, a cached tile older than that threshold
///     is refreshed from the network once when online; if that refresh
///     fails the stale (but still valid) cached tile is served — the UI
///     never gets a fabricated tile, only a known-aged one.
///
/// The fetch respects the OSM Tile Usage Policy:
///   * User-Agent string is set on every request.
///   * Tiles are cached only for the user that requested them.
///   * No background / bulk pre-fetching is performed.
class OfflineTileFetcher {
  OfflineTileFetcher({
    required this.cache,
    required this.urlTemplate,
    this.maxTileAge,
    this._isOffline,
    http.Client? client,
  }) : _client = client ?? http.Client();

  final OfflineTileCache cache;
  final String urlTemplate;
  final http.Client _client;
  final bool Function()? _isOffline;

  /// Older-than-this cached tiles are refreshed from the network when
  /// online (still served while offline). Null = never auto-refresh.
  final Duration? maxTileAge;

  final Map<String, DateTime> _writtenAt = {};

  /// Override flag for tests / callers without a connectivity stream.
  /// When [_isOffline] is provided it takes precedence (live connectivity
  /// is always fresher than a static flag).
  bool offline = false;

  String get templateHash => OfflineTileCache.hashForTemplate(urlTemplate);

  bool _computeOffline() => _isOffline?.call() ?? offline;

  /// Builds the concrete URL for a tile (z/x/y substitution).
  String _urlFor(int z, int x, int y) {
    return urlTemplate
        .replaceAll('{z}', '$z')
        .replaceAll('{x}', '$x')
        .replaceAll('{y}', '$y');
  }

  String _key(int z, int x, int y) => '$z/$x/$y';

  /// Fetches one tile. Behaviour:
  ///   * cache hit + fresh (or offline) → [TileFetchResult.fromCache]
  ///   * cache hit but stale (> [maxTileAge]) + online → refresh once;
  ///     serve the refreshed bytes on success, serve cached on failure
  ///   * cache miss + network reachable → network fetch + cache write
  ///   * cache miss + network unreachable / failure → [TileFetchResult.offlineMiss]
  Future<TileFetchResult> fetch(int z, int x, int y) async {
    final cached = await cache.read(
      z: z,
      x: x,
      y: y,
      templateHash: templateHash,
    );
    if (cached != null) {
      if (!_needsRefresh(z, x, y) || _computeOffline()) {
        return TileFetchResult.fromCache(
          cached,
          contentType: _sniff(cached),
        );
      }
      // Online + stale: try one refresh, fall back to cached on failure.
      final refreshed = await _tryNetwork(z, x, y);
      if (refreshed != null) {
        return refreshed;
      }
      return TileFetchResult.fromCache(
        cached,
        contentType: _sniff(cached),
      );
    }
    // Offline mode: do NOT hit the network. Returning offlineMiss lets
    // the UI render a "tile not cached" placeholder instead of hanging
    // on a stalled request.
    if (_computeOffline()) {
      return TileFetchResult.offlineMiss(contentType: 'image/png');
    }
    return (await _tryNetwork(z, x, y)) ??
        TileFetchResult.offlineMiss(contentType: 'image/png');
  }

  bool _needsRefresh(int z, int x, int y) {
    final age = maxTileAge;
    if (age == null) return false;
    final written = _writtenAt[_key(z, x, y)];
    if (written == null) return false;
    return DateTime.now().toUtc().difference(written) >= age;
  }

  /// Network fetch + cache write-through. Returns null on any failure.
  Future<TileFetchResult?> _tryNetwork(int z, int x, int y) async {
    try {
      final resp = await _client
          .get(
            Uri.parse(_urlFor(z, x, y)),
            headers: {
              'User-Agent': cache.config.userAgent,
              'Accept': 'image/png,image/jpeg,image/webp,*/*;q=0.5',
            },
          )
          .timeout(const Duration(seconds: 8));
      if (resp.statusCode != 200 || resp.bodyBytes.isEmpty) {
        return null;
      }
      final contentType = (resp.headers['content-type'] ?? '').toLowerCase();
      final ok = await cache.write(
        z: z,
        x: x,
        y: y,
        templateHash: templateHash,
        bytes: resp.bodyBytes,
        contentType: contentType,
      );
      if (!ok) {
        return null;
      }
      _writtenAt[_key(z, x, y)] = DateTime.now().toUtc();
      return TileFetchResult.bytes(resp.bodyBytes, contentType: contentType);
    } catch (_) {
      return null;
    }
  }

  /// Lightweight magic-byte sniff for the content-type label.
  static String _sniff(Uint8List b) {
    if (b.length >= 4 && b[0] == 0x89 && b[1] == 0x50 && b[2] == 0x4E) {
      return 'image/png';
    }
    if (b.length >= 3 && b[0] == 0xFF && b[1] == 0xD8 && b[2] == 0xFF) {
      return 'image/jpeg';
    }
    if (b.length >= 12 && b[8] == 0x57 && b[9] == 0x45) {
      return 'image/webp';
    }
    return 'application/octet-stream';
  }

  // Override in production via constructor injection if you need to
  // honour the connectivity stream. Defaults to false (online) so the
  // fetcher is unit-testable in isolation.
  void dispose() {
    _client.close();
  }
}