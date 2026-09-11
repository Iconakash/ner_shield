import 'package:flutter_test/flutter_test.dart';
import 'package:ner_shield/core/errors/app_exception.dart';
import 'package:ner_shield/core/storage/cache_first.dart';

void main() {
  group('TtlCache', () {
    test('serves fresh values and reports their load time', () {
      final c = TtlCache<String, int>(ttl: const Duration(minutes: 5));
      c.put('k', 7);
      final r = c.getIfFresh('k');
      expect(r, isNotNull);
      expect(r!.value, 7);
      expect(r.fromCache, isTrue);
      expect(r.cachedAt, isNotNull);
    });

    test('expired entries are invisible to getIfFresh but live in getStale',
        () async {
      final c = TtlCache<String, String>(ttl: Duration.zero);
      c.put('k', 'last-known');
      // Let at least one clock tick pass so the entry is strictly expired.
      await Future<void>.delayed(const Duration(milliseconds: 5));
      expect(c.getIfFresh('k'), isNull);
      final stale = c.getStale('k');
      expect(stale, isNotNull);
      expect(stale!.value, 'last-known');
      expect(stale.fromCache, isTrue);
    });

    test('evicts oldest beyond maxEntries', () {
      final c = TtlCache<String, int>(maxEntries: 2);
      c.put('a', 1);
      c.put('b', 2);
      c.put('c', 3);
      expect(c.length, 2);
      expect(c.evictions, 1);
      expect(c.get('a'), isNull);
    });
  });

  group('CacheFirst', () {
    test('network success caches with fromCache=false', () async {
      final cf = CacheFirst<int>(TtlCache(ttl: const Duration(minutes: 5)));
      var calls = 0;
      final r = await cf.run('k', fetch: () async {
        calls++;
        return 42;
      });
      expect(r.value, 42);
      expect(r.fromCache, isFalse);
      // Second read is served from cache without a new fetch.
      final r2 = await cf.run('k', fetch: () async {
        calls++;
        return 42;
      });
      expect(r2.fromCache, isTrue);
      expect(calls, 1);
    });

    test('network failure falls back to stale data, tagged fromCache', () async {
      final cf = CacheFirst<int>(TtlCache(ttl: Duration.zero));
      await cf.run('k', fetch: () async => 9); // seeds an already-stale entry
      // Ensure the seeded entry is strictly past its (zero) TTL.
      await Future<void>.delayed(const Duration(milliseconds: 5));
      final r = await cf.run(
        'k',
        fetch: () async => throw const NetworkException('offline'),
      );
      expect(r.value, 9);
      expect(r.fromCache, isTrue);
      expect(r.cachedAt, isNotNull);
    });

    test('non-network failures are NOT masked by stale data', () async {
      final cf = CacheFirst<int>(TtlCache(ttl: Duration.zero));
      await cf.run('k', fetch: () async => 9);
      await Future<void>.delayed(const Duration(milliseconds: 5));
      expect(
        () => cf.run(
          'k',
          fetch: () async =>
              throw const ForbiddenException('outside your scope'),
        ),
        throwsA(isA<ForbiddenException>()),
      );
    });

    test('network failure with empty cache rethrows', () async {
      final cf = CacheFirst<int>(TtlCache(ttl: const Duration(minutes: 5)));
      expect(
        () => cf.run(
          'k',
          fetch: () async => throw const NetworkException('offline'),
        ),
        throwsA(isA<NetworkException>()),
      );
    });
  });
}
