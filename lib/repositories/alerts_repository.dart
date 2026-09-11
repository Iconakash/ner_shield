import '../core/storage/cache_first.dart';
import '../models/alert.dart';
import '../services/alerts_service.dart';

/// Alert inbox reads + lifecycle actions.
///
/// Mutations bypass the cache and invalidate it on success so the next read
/// reflects the acknowledgment (escalation stops server-side immediately).
class AlertsRepository {
  AlertsRepository(this._svc)
      : _inbox = CacheFirst(TtlCache(ttl: const Duration(seconds: 30)));

  final AlertsService _svc;
  final CacheFirst<List<Alert>> _inbox;

  /// Role/RLS-scoped inbox; [lang] asks the backend for localized copies.
  Future<CachedResult<List<Alert>>> inbox({String? lang, int limit = 100}) =>
      _inbox.run(
        'inbox:$lang:$limit',
        fetch: () => _svc.inbox(limit: limit, lang: lang),
      );

  Future<void> acknowledge(String alertId) async {
    await _svc.acknowledge(alertId);
    _inbox.invalidateAll();
  }

  Future<void> resolve(String alertId, {String? note}) async {
    await _svc.resolve(alertId, note: note);
    _inbox.invalidateAll();
  }

  /// Public cache invalidation — used by the reconnection reconciler
  /// when pull deltas indicate the alert inbox changed server-side.
  void invalidateAll() => _inbox.invalidateAll();
}