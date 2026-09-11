import '../../models/cached_result.dart';
import '../errors/app_exception.dart';
import 'ttl_cache.dart';

export '../../models/cached_result.dart';
export 'ttl_cache.dart';

/// Network-first loader with a stale-cache fallback.
///
/// Contract (docs/offline-strategy.md §3):
/// 1. Serve a fresh cached value when one exists (no network call).
/// 2. Otherwise fetch; on success cache and return `fromCache: false`.
/// 3. On [NetworkException], return the stale cached value when available so
///    the UI can show last-known data with its timestamp; otherwise rethrow.
/// All other failures (401/403/404/429/5xx/malformed) propagate immediately —
/// they are not connectivity problems and must not be masked by old data.
class CacheFirst<T> {
  CacheFirst(this._cache);

  final TtlCache<String, T> _cache;

  Future<CachedResult<T>> run(
    String key, {
    required Future<T> Function() fetch,
  }) async {
    final fresh = _cache.getIfFresh(key);
    if (fresh != null) return fresh;
    try {
      final value = await fetch();
      _cache.put(key, value);
      return CachedResult(value, fromCache: false, cachedAt: DateTime.now());
    } on NetworkException {
      final stale = _cache.getStale(key);
      if (stale != null) return stale;
      rethrow;
    }
  }

  /// Fresh cached value without hitting the network, or null.
  CachedResult<T>? peekFresh(String key) => _cache.getIfFresh(key);

  /// Stale cached value (for "last known" banners), or null.
  CachedResult<T>? peekStale(String key) => _cache.getStale(key);

  void invalidate(String key) => _cache.invalidate(key);

  void invalidateAll() => _cache.clear();
}