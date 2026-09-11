import '../core/storage/cache_first.dart';
import '../models/segment.dart';
import '../services/accessibility_service.dart';

/// Accessibility scoring reads (per-segment OPEN/PARTIAL/CLOSED rows).
class AccessibilityRepository {
  AccessibilityRepository(this._svc)
      : _segments = CacheFirst(TtlCache(ttl: const Duration(seconds: 60)));

  final AccessibilityService _svc;
  final CacheFirst<List<AccessibilitySegment>> _segments;

  /// Latest per-segment accessibility rows, optionally per district.
  Future<CachedResult<List<AccessibilitySegment>>> segments(
          {String? districtCode}) =>
      _segments.run(
        'segments:${districtCode ?? 'all'}',
        fetch: () => _svc.segments(districtCode: districtCode),
      );

  void invalidateSegments() => _segments.invalidateAll();
}