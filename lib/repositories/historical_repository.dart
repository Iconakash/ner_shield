import '../core/storage/cache_first.dart';
import '../models/historical_event.dart';
import '../services/historical_service.dart';

/// Historical analytics reads + replay.
///
/// Event list and detail are cacheable (heavy backend computation, low
/// churn). Validation runs are cached briefly so a refresh within the
/// same session doesn't re-hit the engine; the run action itself always
/// revalidates the cache for its event.
class HistoricalRepository {
  HistoricalRepository(this._svc)
      : _events = CacheFirst(TtlCache(ttl: const Duration(minutes: 5))),
        _detail = CacheFirst(TtlCache(ttl: const Duration(minutes: 5))),
        _validations =
            CacheFirst(TtlCache(ttl: const Duration(seconds: 30)));

  final HistoricalService _svc;
  final CacheFirst<List<HistoricalEvent>> _events;
  final CacheFirst<HistoricalEvent> _detail;
  final CacheFirst<HistoricalValidationRun> _validations;

  /// RLS-scoped event list (cached 5m).
  Future<CachedResult<List<HistoricalEvent>>> events() =>
      _events.run('events', fetch: _svc.events);

  /// Single-event detail (cached 5m under a per-id key).
  Future<CachedResult<HistoricalEvent>> eventDetail(String eventId) =>
      _detail.run('event:$eventId', fetch: () => _svc.eventDetail(eventId));

  /// Latest validation run for an event (cached 30s).
  Future<CachedResult<HistoricalValidationRun>> latestValidation(
    String eventId,
  ) => _validations.run(
    'validation:$eventId',
    fetch: () => _svc.latestValidation(eventId),
  );

  /// Trigger a new validation run (MANAGE_SYSTEM). Server response
  /// becomes the latest cached value.
  Future<HistoricalValidationRun> runValidation(String eventId) async {
    final result = await _svc.runValidation(eventId);
    _validations.invalidateAll();
    return result;
  }
}