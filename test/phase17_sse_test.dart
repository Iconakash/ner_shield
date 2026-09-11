import 'package:flutter_test/flutter_test.dart';
import 'package:ner_shield/core/realtime/sse_client.dart';
import 'package:ner_shield/features/realtime/realtime_controller.dart';

void main() {
  group('SseClient transport', () {
    test('isConnected starts false and stays false without token', () async {
      final client = SseClient(
        baseUrl: 'http://test.invalid',
        accessTokenProvider: () async => null,
      );
      expect(client.isConnected, isFalse);
      await client.connect();
      expect(client.isConnected, isFalse);
      await client.stop();
    });

    test('stop prevents further reconnect attempts', () async {
      final client = SseClient(
        baseUrl: 'http://test.invalid',
        accessTokenProvider: () async => null,
      );
      await client.connect();
      await client.stop();
      await client.connect();
      expect(client.isConnected, isFalse);
    });

    test('stream is a broadcast stream', () {
      final client = SseClient(
        baseUrl: 'http://test.invalid',
        accessTokenProvider: () async => 'token',
      );
      expect(client.stream.isBroadcast, isTrue);
      client.stop();
    });
  });

  group('RealtimeEvent immutability', () {
    test('exposes all four fields', () {
      final e = RealtimeEvent(
        kind: 'alert',
        id: 'e-1',
        data: <String, dynamic>{'level': 'HIGH'},
        receivedAt: DateTime.utc(2026, 9, 3),
      );
      expect(e.kind, 'alert');
      expect(e.id, 'e-1');
      expect(e.data, isNotNull);
      expect(e.receivedAt.year, 2026);
    });
  });

  group('RealtimeDedup', () {
    test('first occurrence passes, repeats are filtered', () {
      final d = RealtimeDedup();
      expect(d.consume('e-1'), isTrue);
      expect(d.consume('e-1'), isFalse);
      expect(d.consume('e-2'), isTrue);
      expect(d.consume('e-2'), isFalse);
    });

    test('empty id always passes (frame without id)', () {
      final d = RealtimeDedup();
      expect(d.consume(''), isTrue);
      expect(d.consume(''), isTrue);
    });

    test('evicts oldest when maxSize is reached', () {
      final d = RealtimeDedup(maxSize: 2);
      expect(d.consume('a'), isTrue);
      expect(d.consume('b'), isTrue);
      expect(d.consume('c'), isTrue);
      expect(d.consume('a'), isTrue);
    });
  });
}