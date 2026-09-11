import '../../models/cached_result.dart';

/// In-memory TTL cache used by read-heavy repositories (dashboard summary,
/// alerts, reference data).
///
/// Persistence (the Drift/SQLite offline store) lands with the incident
/// offline flow (Phase 9); this class covers the "cache then fall back when
/// offline" contract with explicit freshness signals.
class TtlCache<K, V> {
  TtlCache({this.ttl = const Duration(minutes: 5), this.maxEntries = 128});

  final Duration ttl;
  final int maxEntries;
  final Map<K, _Entry<V>> _store = {};

  int evictions = 0;

  bool _expired(_Entry<V> entry) {
    return DateTime.now().difference(entry.loadedAt) > ttl;
  }

  void put(K key, V value) {
    _store[key] = _Entry(value, DateTime.now());
    if (_store.length > maxEntries) {
      // Evict oldest by insertion order (LinkedHashMap preserves order).
      final oldest = _store.keys.first;
      _store.remove(oldest);
      evictions++;
    }
  }

  /// Live cached value, or null when absent/expired.
  ///
  /// Non-destructive on expiry (see [getIfFresh]) so stale reads remain
  /// available for offline fallback.
  V? get(K key) {
    final entry = _store[key];
    if (entry == null) return null;
    if (_expired(entry)) {
      return null;
    }
    return entry.value;
  }

  /// Cached value tagged with its load time (for stale-data labels), or null
  /// when absent/expired.
  ///
  /// Non-destructive on expiry: the entry stays in the store so [getStale]
  /// can still serve it as the offline "last known" fallback.
  CachedResult<V>? getIfFresh(K key) {
    final entry = _store[key];
    if (entry == null) return null;
    if (_expired(entry)) {
      return null;
    }
    return CachedResult(entry.value, fromCache: true, cachedAt: entry.loadedAt);
  }

  /// Cached value even when past its TTL — the offline fallback used by
  /// repositories when the network is unreachable. Always tagged
  /// `fromCache: true` with the original load time so the UI can show the
  /// last-updated timestamp (master prompt §42: stale data is never silent).
  CachedResult<V>? getStale(K key) {
    final entry = _store[key];
    if (entry == null) return null;
    return CachedResult(entry.value, fromCache: true, cachedAt: entry.loadedAt);
  }

  void invalidate(K key) => _store.remove(key);

  void clear() => _store.clear();

  int get length => _store.length;
}

class _Entry<V> {
  const _Entry(this.value, this.loadedAt);

  final V value;
  final DateTime loadedAt;
}