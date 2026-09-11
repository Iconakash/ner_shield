import 'dart:convert';

import 'package:crypto/crypto.dart' as crypto;
import 'package:drift/drift.dart';

import '../sync/sync_queue_database.dart';

/// Configuration knobs for the offline map tile cache (Phase 4 §4.3).
class OfflineTileCacheConfig {
  const OfflineTileCacheConfig({
    this.maxBytes = 200 * 1024 * 1024,
    this.minFreeRatio = 0.1,
    this.userAgent = 'in.gov.mdoner.nershield',
  });

  final int maxBytes;
  final double minFreeRatio;
  final String userAgent;
}

/// Phase 4 — Drift-backed persistent tile store.
///
/// Provides:
///   * write-through caching (bytes persisted immediately on fetch)
///   * LRU read tracking (every [read] touches [lastAccessedAt])
///   * capacity management ([evictIfNeeded])
///   * corruption detection (sha256 mismatch rejects the row)
///
/// Tile keys are `(z, x, y, templateHash)`. The template hash keeps two
/// providers' caches from colliding when the URL templates differ.
class OfflineTileCache {
  OfflineTileCache(this._db, {this._config = const OfflineTileCacheConfig()});

  final SyncQueueDatabase _db;
  final OfflineTileCacheConfig _config;

  OfflineTileCacheConfig get config => _config;

  /// Computes the template hash (sha256 of the URL template).
  static String hashForTemplate(String urlTemplate) {
    final digest = crypto.sha256.convert(utf8.encode(urlTemplate));
    return digest.toString();
  }

  /// Looks up a tile. Returns the bytes if present, schema-valid, and
  /// sha256-verified. Returns `null` for cache miss or corruption.
  Future<Uint8List?> read({
    required int z,
    required int x,
    required int y,
    required String templateHash,
  }) async {
    final row = await (_db.select(_db.mapTileRows)
          ..where((t) =>
              t.z.equals(z) &
              t.x.equals(x) &
              t.y.equals(y) &
              t.templateHash.equals(templateHash))
          ..limit(1))
        .getSingleOrNull();
    if (row == null) return null;
    final expected = crypto.sha256.convert(row.bytes).toString();
    if (expected != row.sha256) {
      await (_db.delete(_db.mapTileRows)
            ..where((t) =>
                t.z.equals(z) &
                t.x.equals(x) &
                t.y.equals(y) &
                t.templateHash.equals(templateHash)))
          .go();
      return null;
    }
    if (!_looksLikeImage(row.bytes, row.contentType)) {
      await (_db.delete(_db.mapTileRows)
            ..where((t) =>
                t.z.equals(z) &
                t.x.equals(x) &
                t.y.equals(y) &
                t.templateHash.equals(templateHash)))
          .go();
      return null;
    }
    await (_db.update(_db.mapTileRows)
          ..where((t) =>
              t.z.equals(z) &
              t.x.equals(x) &
              t.y.equals(y) &
              t.templateHash.equals(templateHash)))
        .write(MapTileRowsCompanion(
      lastAccessedAt: Value(DateTime.now().toUtc().toIso8601String()),
    ));
    return Uint8List.fromList(row.bytes);
  }

  /// Persists a tile. Validates magic bytes + length before writing.
  Future<bool> write({
    required int z,
    required int x,
    required int y,
    required String templateHash,
    required Uint8List bytes,
    required String contentType,
  }) async {
    if (bytes.isEmpty) return false;
    if (!_looksLikeImage(bytes, contentType)) return false;
    final digest = crypto.sha256.convert(bytes).toString();
    final now = DateTime.now().toUtc().toIso8601String();
    await _db.into(_db.mapTileRows).insertOnConflictUpdate(
          MapTileRowsCompanion.insert(
            z: z,
            x: x,
            y: y,
            templateHash: templateHash,
            bytes: bytes,
            contentType: contentType,
            sizeBytes: bytes.length,
            sha256: digest,
            cachedAt: now,
            lastAccessedAt: now,
          ),
        );
    await evictIfNeeded();
    return true;
  }

  /// Total cached bytes (per template hash).
  Future<int> totalBytes(String templateHash) async {
    final sum = await _db.customSelect(
      'select coalesce(sum(size_bytes), 0) as s from map_tile_rows '
      'where template_hash = ?',
      variables: [Variable.withString(templateHash)],
      readsFrom: {_db.mapTileRows},
    ).getSingle();
    return sum.read<int>('s');
  }

  /// Number of cached tiles (per template hash).
  Future<int> tileCount(String templateHash) async {
    final c = await _db.customSelect(
      'select count(*) as c from map_tile_rows where template_hash = ?',
      variables: [Variable.withString(templateHash)],
      readsFrom: {_db.mapTileRows},
    ).getSingle();
    return c.read<int>('c');
  }

  /// Most recent cachedAt instant (per template hash). Null when empty.
  Future<DateTime?> lastUpdatedAt(String templateHash) async {
    final r = await _db.customSelect(
      'select max(cached_at) as m from map_tile_rows where template_hash = ?',
      variables: [Variable.withString(templateHash)],
      readsFrom: {_db.mapTileRows},
    ).getSingle();
    final raw = r.read<String?>('m');
    return raw == null ? null : DateTime.tryParse(raw);
  }

  /// LRU evict down to `maxBytes * (1 - minFreeRatio)`.
  Future<int> evictIfNeeded() async {
    final current = await _db.customSelect(
      'select coalesce(sum(size_bytes), 0) as s from map_tile_rows',
      readsFrom: {_db.mapTileRows},
    ).getSingle();
    final total = current.read<int>('s');
    final budget = (_config.maxBytes * (1 - _config.minFreeRatio)).toInt();
    if (total <= budget) return 0;
    final overage = total - budget;
    final oldest = await _db.customSelect(
      'select z, x, y, template_hash, size_bytes from map_tile_rows '
      'order by last_accessed_at asc limit 200',
      readsFrom: {_db.mapTileRows},
    ).get();
    var freed = 0;
    var deleted = 0;
    for (final row in oldest) {
      if (freed >= overage) break;
      final sz = row.read<int>('size_bytes');
      final z = row.read<int>('z');
      final x = row.read<int>('x');
      final y = row.read<int>('y');
      final th = row.read<String>('template_hash');
      final affected = await (_db.delete(_db.mapTileRows)
            ..where((t) =>
                t.z.equals(z) &
                t.x.equals(x) &
                t.y.equals(y) &
                t.templateHash.equals(th)))
          .go();
      if (affected > 0) {
        freed += sz;
        deleted++;
      }
    }
    return deleted;
  }

  /// Wipe the entire cache (admin / logout-everywhere hook).
  Future<void> clear({String? templateHash}) async {
    if (templateHash == null) {
      await _db.delete(_db.mapTileRows).go();
    } else {
      await (_db.delete(_db.mapTileRows)
            ..where((t) => t.templateHash.equals(templateHash)))
          .go();
    }
  }

  /// Magic-byte sniff: PNG / JPEG / WebP only. Rejects HTML / JSON /
  /// binary garbage (a 200 OK with an error body is the most common
  /// cause of map-tile corruption in the wild).
  static bool _looksLikeImage(Uint8List bytes, String contentType) {
    if (bytes.length < 8) return false;
    if (bytes[0] == 0x89 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x4E &&
        bytes[3] == 0x47) {
      return contentType.contains('png') || contentType.isEmpty;
    }
    if (bytes[0] == 0xFF &&
        bytes[1] == 0xD8 &&
        bytes[2] == 0xFF) {
      return contentType.contains('jpeg') ||
          contentType.contains('jpg') ||
          contentType.isEmpty;
    }
    if (bytes.length >= 12 &&
        bytes[0] == 0x52 &&
        bytes[1] == 0x49 &&
        bytes[2] == 0x46 &&
        bytes[3] == 0x46 &&
        bytes[8] == 0x57 &&
        bytes[9] == 0x45 &&
        bytes[10] == 0x42 &&
        bytes[11] == 0x50) {
      return contentType.contains('webp') || contentType.isEmpty;
    }
    return false;
  }
}

/// Plain read-only summary for UI badges (Phase 4 §4.4).
class OfflineTileCacheSummary {
  const OfflineTileCacheSummary({
    required this.tilesCached,
    required this.bytesCached,
    required this.bytesBudget,
    required this.templateHash,
    required this.lastUpdated,
  });

  final int tilesCached;
  final int bytesCached;
  final int bytesBudget;
  final String templateHash;
  final DateTime? lastUpdated;

  double get headroom => bytesBudget == 0
      ? 1.0
      : (1.0 - bytesCached / bytesBudget).clamp(0.0, 1.0).toDouble();

  String? staleLabel({Duration staleAfter = const Duration(days: 14)}) {
    final lu = lastUpdated;
    if (lu == null) return null;
    final age = DateTime.now().toUtc().difference(lu);
    if (age <= staleAfter) return null;
    final days = age.inDays;
    return 'Map tiles last cached ${days == 0 ? "today" : "$days d ago"}.';
  }
}