import '../core/storage/cache_first.dart';
import '../models/task.dart';
import '../services/tasks_service.dart';

/// Action Center + evidence + satellite reads (Phase 16).
class TasksRepository {
  TasksRepository(this._svc)
      : _mine = CacheFirst(TtlCache(ttl: const Duration(seconds: 30))),
        _scenes = CacheFirst(TtlCache(ttl: const Duration(minutes: 5)));

  final TasksService _svc;
  final CacheFirst<List<TaskItem>> _mine;
  final CacheFirst<List<SatelliteEvidence>> _scenes;

  Future<CachedResult<List<TaskItem>>> mine() =>
      _mine.run('mine', fetch: _svc.mine);

  Future<CachedResult<List<SatelliteEvidence>>> satelliteScenes({
    String? stateCode,
    String? districtCode,
  }) =>
      _scenes.run(
        'scenes:${stateCode ?? ''}:${districtCode ?? ''}',
        fetch: () =>
            _svc.satelliteScenes(stateCode: stateCode, districtCode: districtCode),
      );

  Future<TaskItem> transition(
    String taskId, {
    required String toStatus,
    String? note,
  }) async {
    final task = await _svc.transition(taskId, toStatus: toStatus, note: note);
    _mine.invalidateAll();
    return task;
  }

  Future<TaskItem> detail(String taskId) => _svc.detail(taskId);

  /// Signed URLs are short-lived; never cached.
  Future<FieldMedia> mediaSignedUrl({
    required String reportId,
    required String mediaId,
  }) =>
      _svc.fieldMediaSignedUrl(reportId: reportId, mediaId: mediaId);
}