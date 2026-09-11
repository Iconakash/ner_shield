// Phase 4 — OfflineTileFetcher behavior (§4.3 cache miss / write-through /
// offline gating / corruption / TTL refresh). Runs against an in-memory
// Drift DB and a fake http.Client — no real network access.

import 'dart:async';
import 'dart:typed_data';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:ner_shield/core/maps/offline_tile_cache.dart';
import 'package:ner_shield/core/maps/offline_tile_fetcher.dart';
import 'package:ner_shield/core/sync/sync_queue_database.dart';

// 1x1 transparent PNG.
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

const String _tpl = 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';

/// Deterministic fake http client: returns queued responses; throws once
/// the queue is exhausted (simulating a dead network).
class _FakeHttpClient extends http.BaseClient {
  _FakeHttpClient(this._responses);

  final List<http.Response> _responses;
  int calls = 0;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    calls++;
    if (calls > _responses.length) {
      throw http.ClientException('simulated network down');
    }
    final r = _responses[calls - 1];
    return http.StreamedResponse(
      Stream.fromIterable([r.bodyBytes]),
      r.statusCode,
      headers: r.headers,
    );
  }
}

http.Response _pngResponse(Uint8List body) => http.Response.bytes(
      body,
      200,
      headers: {'content-type': 'image/png'},
    );

Future<SyncQueueDatabase> _db() async => SyncQueueDatabase(NativeDatabase.memory());

void main() {
  group('Phase 4 — OfflineTileFetcher', () {
    test('offline + cached tile → served from cache, no network call',
        () async {
      final db = await _db();
      final cache = OfflineTileCache(db);
      final h = OfflineTileCache.hashForTemplate(_tpl);
      await cache.write(z: 5, x: 10, y: 20, templateHash: h,
          bytes: _png, contentType: 'image/png');

      final fetcher = OfflineTileFetcher(
        cache: cache,
        urlTemplate: _tpl,
        isOffline: () => true,
        client: _FakeHttpClient(const <http.Response>[]),
      );
      final r = await fetcher.fetch(5, 10, 20);
      expect(r.bytes, equals(_png));
      expect(r.fromCache, isTrue);
      await db.close();
    });

    test('offline + uncached tile → offlineMiss, no network call', () async {
      final db = await _db();
      final cache = OfflineTileCache(db);
      final fetcher = OfflineTileFetcher(
        cache: cache,
        urlTemplate: _tpl,
        isOffline: () => true,
        client: _FakeHttpClient(const <http.Response>[]),
      );
      final r = await fetcher.fetch(5, 10, 20);
      expect(r.bytes, isNull);
      expect(
          await cache.tileCount(OfflineTileCache.hashForTemplate(_tpl)), 0);
      await db.close();
    });

    test('online + cache miss → network fetch + write-through persists',
        () async {
      final db = await _db();
      final cache = OfflineTileCache(db);
      final client = _FakeHttpClient([_pngResponse(_png)]);
      final fetcher = OfflineTileFetcher(
        cache: cache,
        urlTemplate: _tpl,
        client: client,
      );
      final r = await fetcher.fetch(5, 10, 20);
      expect(r.bytes, equals(_png));
      expect(client.calls, 1);
      final h = OfflineTileCache.hashForTemplate(_tpl);
      expect(await cache.tileCount(h), 1);
      // Offline again → now served from the persisted cache.
      fetcher.offline = true;
      final again = await fetcher.fetch(5, 10, 20);
      expect(again.bytes, equals(_png));
      expect(again.fromCache, isTrue);
      await db.close();
    });

    test('online + HTML error body → offlineMiss, nothing cached', () async {
      final db = await _db();
      final cache = OfflineTileCache(db);
      final html = Uint8List.fromList(
          '<html>429 Too Many Requests</html>'.codeUnits);
      final client = _FakeHttpClient([_pngResponse(html)]);
      final fetcher = OfflineTileFetcher(
        cache: cache,
        urlTemplate: _tpl,
        client: client,
      );
      final r = await fetcher.fetch(5, 10, 20);
      expect(r.bytes, isNull);
      expect(
          await cache.tileCount(OfflineTileCache.hashForTemplate(_tpl)), 0);
      await db.close();
    });

    test('TTL refresh: stale cached tile re-fetches when online', () async {
      final db = await _db();
      final cache = OfflineTileCache(db);
      final v1 = _png;
      final v2 = Uint8List.fromList([..._png, 0x00, 0x00]);
      final client = _FakeHttpClient([_pngResponse(v1), _pngResponse(v2)]);
      final fetcher = OfflineTileFetcher(
        cache: cache,
        urlTemplate: _tpl,
        maxTileAge: Duration.zero,
        client: client,
      );
      final first = await fetcher.fetch(5, 10, 20);
      expect(first.bytes, equals(v1));
      expect(client.calls, 1);
      // Second call: cache hit but stale → refresh from network → v2.
      final second = await fetcher.fetch(5, 10, 20);
      expect(client.calls, 2);
      expect(second.bytes, equals(v2));
      expect(second.fromCache, isFalse);
      await db.close();
    });

    test('TTL refresh failure → stale cached tile still served', () async {
      final db = await _db();
      final cache = OfflineTileCache(db);
      final client = _FakeHttpClient([_pngResponse(_png)]);
      final fetcher = OfflineTileFetcher(
        cache: cache,
        urlTemplate: _tpl,
        maxTileAge: Duration.zero,
        client: client,
      );
      // First call populates the cache (network 1).
      await fetcher.fetch(5, 10, 20);
      expect(client.calls, 1);
      // Second call is stale + online, but the network is now DOWN:
      // the fetch must fall back to the stale cached bytes.
      final second = await fetcher.fetch(5, 10, 20);
      expect(client.calls, 2);
      expect(second.bytes, equals(_png));
      expect(second.fromCache, isTrue);
      await db.close();
    });
  });
}