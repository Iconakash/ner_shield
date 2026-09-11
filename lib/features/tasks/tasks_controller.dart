import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../models/cached_result.dart';
import '../../models/task.dart';

/// Tasks assigned to the signed-in user (`GET /tasks/mine`).
final myTasksProvider = AsyncNotifierProvider<
    MyTasksController,
    CachedResult<List<TaskItem>>>(MyTasksController.new);

class MyTasksController
    extends AsyncNotifier<CachedResult<List<TaskItem>>> {
  @override
  Future<CachedResult<List<TaskItem>>> build() {
    return ref.watch(tasksRepositoryProvider).mine();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(tasksRepositoryProvider).mine(),
    );
  }

  Future<bool> transition(
    String taskId, {
    required String toStatus,
    String? note,
  }) async {
    try {
      await ref
          .read(tasksRepositoryProvider)
          .transition(taskId, toStatus: toStatus, note: note);
      await refresh();
      return true;
    } catch (_) {
      return false;
    }
  }
}

/// Single-task detail (autoDispose: alive only while the detail sheet is
/// open).
final taskDetailProvider =
    FutureProvider.autoDispose.family<TaskItem, String>((ref, taskId) {
  return ref.watch(tasksRepositoryProvider).detail(taskId);
});

/// Satellite evidence scenes (cached 5m).
final satelliteScenesProvider = AsyncNotifierProvider<
    SatelliteScenesController,
    CachedResult<List<SatelliteEvidence>>>(SatelliteScenesController.new);

class SatelliteScenesController
    extends AsyncNotifier<CachedResult<List<SatelliteEvidence>>> {
  @override
  Future<CachedResult<List<SatelliteEvidence>>> build() {
    return ref.watch(tasksRepositoryProvider).satelliteScenes();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(tasksRepositoryProvider).satelliteScenes(),
    );
  }
}

/// Status set for Action Center tasks (matches backend). The server is the
/// authority — invalid transitions surface its 409 verbatim.
const kTaskStatusTransitions = <String, List<String>>{
  'ASSIGNED': ['ACCEPTED', 'CANCELLED'],
  'ACCEPTED': ['IN_PROGRESS', 'BLOCKED', 'CANCELLED'],
  'IN_PROGRESS': ['BLOCKED', 'COMPLETED', 'CANCELLED'],
  'BLOCKED': ['IN_PROGRESS', 'CANCELLED'],
  'COMPLETED': ['VERIFIED', 'CANCELLED'],
};

List<String> taskNextStatusesFor(String? status) =>
    kTaskStatusTransitions[status] ?? const [];