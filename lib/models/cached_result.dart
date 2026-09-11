/// Result of a repository read that may have been served from cache.
///
/// `fromCache == true` means the value is NOT a live server response — the UI
/// must show the last-updated timestamp instead of implying freshness
/// (section 42 of the master prompt).
class CachedResult<T> {
  const CachedResult(this.value, {required this.fromCache, this.cachedAt});

  final T value;
  final bool fromCache;

  /// When non-null, the moment the cached (or fetched) value was produced.
  final DateTime? cachedAt;

  bool get servedFromCache => fromCache;
}