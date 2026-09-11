import '../core/storage/cache_first.dart';
import '../models/responder.dart';
import '../services/responder_service.dart';

/// Responders + response task repository (Phase 15).
///
/// Responder lists are cached briefly; nearest-responder queries are always
/// live (geo context changes constantly). Tasks are cacheable but always
/// invalidated on any transition.
class ResponderRepository {
  ResponderRepository(this._svc)
      : _roster = CacheFirst(TtlCache(ttl: const Duration(seconds: 30))),
        _tasks = CacheFirst(TtlCache(ttl: const Duration(seconds: 30)));

  final ResponderService _svc;
  final CacheFirst<List<Responder>> _roster;
  final CacheFirst<List<ResponseTask>> _tasks;

  Future<CachedResult<List<Responder>>> list({
    String? district,
    String? type,
  }) =>
      _roster.run(
        'roster:${district ?? ''}:${type ?? ''}',
        fetch: () => _svc.list(district: district, type: type),
      );

  Future<List<Responder>> nearest({
    required double lon,
    required double lat,
    int limit = 5,
  }) =>
      _svc.nearest(lon: lon, lat: lat, limit: limit);

  Future<CachedResult<List<ResponseTask>>> myTasks() =>
      _tasks.run('tasks', fetch: _svc.myTasks);

  Future<ResponseTask> transition(
    String taskId, {
    required String status,
    String? note,
  }) async {
    final task = await _svc.transition(taskId, status: status, note: note);
    _tasks.invalidateAll();
    return task;
  }

  Future<ResponseTask> notifyResponder(
    String responderId, {
    String? note,
  }) async {
    final task = await _svc.notifyResponder(responderId, note: note);
    _tasks.invalidateAll();
    return task;
  }
}