import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';

import 'offline_tile_fetcher.dart';

/// Phase 4 — flutter_map [TileProvider] backed by [OfflineTileFetcher].
///
/// Tiles are served from the persistent cache when present; on cache
/// miss the fetcher downloads from the configured provider, writes
/// through to the cache, and returns the bytes. When offline AND the
/// tile is uncached, the provider returns flutter_map's stock
/// transparent placeholder so the camera stays responsive rather than
/// blocking on a stalled request.
///
/// Attribution is preserved by the underlying [TileLayer] widget — this
/// provider does NOT modify the URL template or the OSM-required
/// user-agent.
class OfflineTileProvider extends TileProvider {
  OfflineTileProvider({
    required this._fetcher,
    required this.urlTemplate,
  });

  final OfflineTileFetcher _fetcher;
  final String urlTemplate;

  @override
  ImageProvider getImage(TileCoordinates coordinates, TileLayer options) {
    final z = coordinates.z.round();
    final x = coordinates.x.round();
    final y = coordinates.y.round();
    return _OfflineTileImageProvider(
      z: z,
      x: x,
      y: y,
      fetcher: _fetcher,
    );
  }
}

/// Wraps the result of [OfflineTileFetcher.fetch] as an
/// [ImageProvider]. The actual bytes are resolved asynchronously — the
/// provider completes once the fetcher returns. While the byte load is
/// pending, Flutter's [ImageStream] keeps the tile cell visible as the
/// map widget's background (no flicker).
class _OfflineTileImageProvider extends ImageProvider<_OfflineTileImageProvider> {
  _OfflineTileImageProvider({
    required this.z,
    required this.x,
    required this.y,
    required this.fetcher,
  });

  final int z;
  final int x;
  final int y;
  final OfflineTileFetcher fetcher;

  @override
  Future<_OfflineTileImageProvider> obtainKey(ImageConfiguration configuration) {
    return SynchronousFuture<_OfflineTileImageProvider>(this);
  }

  @override
  ImageStreamCompleter loadImage(
    _OfflineTileImageProvider key,
    ImageDecoderCallback decode,
  ) {
    return MultiFrameImageStreamCompleter(
      codec: _build(decode),
      scale: 1.0,
      debugLabel: 'offline_tile_$z/$x/$y',
    );
  }

  Future<ui.Codec> _build(ImageDecoderCallback decode) async {
    final result = await fetcher.fetch(z, x, y);
    final bytes = result.bytes;
    final ui2 = bytes == null || bytes.isEmpty
        ? TileProvider.transparentImage
        : bytes;
    final buffer = await ui.ImmutableBuffer.fromUint8List(ui2);
    return decode(buffer);
  }

  @override
  bool operator ==(Object other) =>
      other is _OfflineTileImageProvider &&
      other.z == z &&
      other.x == x &&
      other.y == y;

  @override
  int get hashCode => Object.hash(z, x, y);
}