// Phase 4 — Offline map raster tile cache (master prompt §4.3-4.4).
//
// Tests run against an in-memory Drift database; no platform channels
// or network access required. Each test seeds cache rows directly so
// we exercise the storage / corruption / LRU paths deterministically.

import 'dart:typed_data';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ner_shield/core/maps/offline_tile_cache.dart';
import 'package:ner_shield/core/sync/sync_queue_database.dart';

// 1x1 transparent PNG bytes (valid image header).
final Uint8List _png = Uint8List.fromList([
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A,
  0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44, 0x52,
  0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
  0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4,
  0x89, 0x00, 0x00, 0x00, 0x0D, 0x49, 0x44, 0x41,
  0x54, 0x78, 0x9C, 0x62, 0x00, 0x01, 0x00, 0x00,
  0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00,
  0x00, 0x00, 0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE,
  0x42, 0x60, 0x82,
]);

// Truncated JPEG.
final Uint8List _jpeg = Uint8List.fromList([
  0xFF, 0xD8, 0xFF, 0xE0, 0x00, 0x10, 0x4A, 0x46, 0x49, 0x46, 0x00,
  0x01, 0x01, 0x00, 0x00, 0x01, 0x00, 0x01, 0x00, 0x00, 0xFF, 0xD9,
]);

// Garbage bytes that look like an HTML error page.
final Uint8List _html = Uint8List.fromList(
    '<!DOCTYPE html><html><body>429 Too Many Requests</body></html>'.codeUnits);

Future<SyncQueueDatabase> _newDb() async {
  final db = SyncQueueDatabase(NativeDatabase.memory());
  return db;
}

Future<OfflineTileCache> _newCache(
  SyncQueueDatabase db, {
  OfflineTileCacheConfig config = const OfflineTileCacheConfig(),
}) async {
  return OfflineTileCache(db, config: config);
}

void main() {
  group('Phase 4 — template hash isolation', () {
    test('same template → same hash', () {
      const t = 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
      expect(
        OfflineTileCache.hashForTemplate(t),
        equals(OfflineTileCache.hashForTemplate(t)),
      );
    });
    test('different templates → different hashes', () {
      const a = 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
      const b = 'https://api.mapbox.com/v4/.../{z}/{x}/{y}.png';
      expect(
        OfflineTileCache.hashForTemplate(a),
        isNot(equals(OfflineTileCache.hashForTemplate(b))),
      );
    });
  });

  group('Phase 4 — magic-byte sniff', () {
    test('rejects HTML body even when content-type is image/png', () async {
      final db = await _newDb();
      final cache = await _newCache(db);
      final ok = await cache.write(
        z: 5, x: 27, y: 15,
        templateHash: 'th',
        bytes: _html,
        contentType: 'image/png',
      );
      expect(ok, isFalse);
      final got = await cache.read(z: 5, x: 27, y: 15, templateHash: 'th');
      expect(got, isNull);
      await db.close();
    });
    test('rejects empty bytes', () async {
      final db = await _newDb();
      final cache = await _newCache(db);
      final ok = await cache.write(
        z: 5, x: 27, y: 15,
        templateHash: 'th',
        bytes: Uint8List(0),
        contentType: 'image/png',
      );
      expect(ok, isFalse);
      await db.close();
    });
    test('accepts PNG with content-type hint', () async {
      final db = await _newDb();
      final cache = await _newCache(db);
      final ok = await cache.write(
        z: 5, x: 27, y: 15,
        templateHash: 'th',
        bytes: _png,
        contentType: 'image/png',
      );
      expect(ok, isTrue);
      final got = await cache.read(z: 5, x: 27, y: 15, templateHash: 'th');
      expect(got, isNotNull);
      expect(got, equals(_png));
      await db.close();
    });
    test('accepts JPEG even with no content-type (sniff wins)', () async {
      final db = await _newDb();
      final cache = await _newCache(db);
      final ok = await cache.write(
        z: 5, x: 27, y: 15,
        templateHash: 'th',
        bytes: _jpeg,
        contentType: '',
      );
      expect(ok, isTrue);
      await db.close();
    });
  });

  group('Phase 4 — write-through cache hit', () {
    test('second read of same tile returns the same bytes', () async {
      final db = await _newDb();
      final cache = await _newCache(db);
      await cache.write(
        z: 7, x: 50, y: 60,
        templateHash: 'osm',
        bytes: _png,
        contentType: 'image/png',
      );
      final a = await cache.read(z: 7, x: 50, y: 60, templateHash: 'osm');
      final b = await cache.read(z: 7, x: 50, y: 60, templateHash: 'osm');
      expect(a, isNotNull);
      expect(a, equals(b));
      await db.close();
    });
    test('different (z, x, y) returns different rows', () async {
      final db = await _newDb();
      final cache = await _newCache(db);
      await cache.write(
        z: 7, x: 50, y: 60, templateHash: 'osm',
        bytes: _png, contentType: 'image/png',
      );
      await cache.write(
        z: 7, x: 51, y: 60, templateHash: 'osm',
        bytes: _png, contentType: 'image/png',
      );
      expect(
        await cache.read(z: 7, x: 50, y: 60, templateHash: 'osm'),
        isNotNull,
      );
      expect(
        await cache.read(z: 7, x: 51, y: 60, templateHash: 'osm'),
        isNotNull,
      );
      expect(
        await cache.read(z: 7, x: 52, y: 60, templateHash: 'osm'),
        isNull,
      );
      await db.close();
    });
  });

  group('Phase 4 — corruption detection', () {
    test('row whose stored sha256 mismatches its bytes is rejected', () async {
      final db = await _newDb();
      final cache = await _newCache(db);
      await cache.write(
        z: 7, x: 50, y: 60,
        templateHash: 'osm',
        bytes: _png,
        contentType: 'image/png',
      );
      await db.customUpdate(
        "update map_tile_rows set sha256 = 'deadbeef' "
        "where z = 7 and x = 50 and y = 60 and template_hash = 'osm'",
        updates: {db.mapTileRows},
      );
      final got = await cache.read(z: 7, x: 50, y: 60, templateHash: 'osm');
      expect(got, isNull);
      final after = await (db.select(db.mapTileRows)).get();
      expect(after, isEmpty,
          reason: 'corrupted row should be deleted on read miss');
      await db.close();
    });
  });

  group('Phase 4 — capacity / LRU eviction', () {
    test('eviction frees enough bytes to fit under the budget', () async {
      final db = await _newDb();
      final cache = await _newCache(
        db,
        config: const OfflineTileCacheConfig(
          maxBytes: 256,
          minFreeRatio: 0.0,
        ),
      );
      for (var i = 0; i < 6; i++) {
        await cache.write(
          z: 7, x: i, y: 0,
          templateHash: 'osm',
          bytes: _png,
          contentType: 'image/png',
        );
      }
      final total = await db.customSelect(
        'select coalesce(sum(size_bytes), 0) as s from map_tile_rows',
        readsFrom: {db.mapTileRows},
      ).getSingle();
      final sum = total.read<int>('s');
      expect(sum, lessThanOrEqualTo(256),
          reason: 'total bytes ($sum) should be ≤ budget after LRU');
      await db.close();
    });
  });

  group('Phase 4 — restart survival', () {
    test('rows written by one cache instance are visible after re-open',
        () async {
      final db = await _newDb();
      final cacheA = await _newCache(db);
      await cacheA.write(
        z: 6, x: 10, y: 20,
        templateHash: 'osm',
        bytes: _png,
        contentType: 'image/png',
      );
      final cacheB = await _newCache(db);
      final got = await cacheB.read(z: 6, x: 10, y: 20, templateHash: 'osm');
      expect(got, isNotNull);
      expect(got, equals(_png));
      await db.close();
    });
  });

  group('Phase 4 — cache summary', () {
    test('tileCount + totalBytes reflect writes', () async {
      final db = await _newDb();
      final cache = await _newCache(db);
      await cache.write(z: 5, x: 0, y: 0, templateHash: 'osm',
          bytes: _png, contentType: 'image/png');
      await cache.write(z: 5, x: 1, y: 0, templateHash: 'osm',
          bytes: _png, contentType: 'image/png');
      await cache.write(z: 5, x: 2, y: 0, templateHash: 'osm',
          bytes: _png, contentType: 'image/png');
      final n = await cache.tileCount('osm');
      final b = await cache.totalBytes('osm');
      expect(n, equals(3));
      expect(b, equals(_png.length * 3));
      await db.close();
    });
    test('clear() removes every row for the template hash', () async {
      final db = await _newDb();
      final cache = await _newCache(db);
      await cache.write(z: 5, x: 0, y: 0, templateHash: 'osm',
          bytes: _png, contentType: 'image/png');
      await cache.write(z: 5, x: 0, y: 0, templateHash: 'other',
          bytes: _png, contentType: 'image/png');
      await cache.clear(templateHash: 'osm');
      expect(await cache.tileCount('osm'), 0);
      expect(await cache.tileCount('other'), 1);
      await db.close();
    });
  });
}