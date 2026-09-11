import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../models/cached_result.dart';
import '../../models/responder.dart';

/// Responder roster (`GET /responders`).
final respondersProvider = AsyncNotifierProvider<
    RespondersController,
    CachedResult<List<Responder>>>(RespondersController.new);

class RespondersController
    extends AsyncNotifier<CachedResult<List<Responder>>> {
  @override
  Future<CachedResult<List<Responder>>> build() {
    return ref.watch(responderRepositoryProvider).list();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(responderRepositoryProvider).list(),
    );
  }
}

/// Response tasks assigned to the signed-in user (`GET /response-tasks/mine`).
final responseTasksProvider = AsyncNotifierProvider<
    ResponseTasksController,
    CachedResult<List<ResponseTask>>>(ResponseTasksController.new);

class ResponseTasksController
    extends AsyncNotifier<CachedResult<List<ResponseTask>>> {
  @override
  Future<CachedResult<List<ResponseTask>>> build() {
    return ref.watch(responderRepositoryProvider).myTasks();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(responderRepositoryProvider).myTasks(),
    );
  }

  Future<bool> transition(
    String taskId, {
    required String status,
    String? note,
  }) async {
    try {
      await ref
          .read(responderRepositoryProvider)
          .transition(taskId, status: status, note: note);
      await refresh();
      return true;
    } catch (_) {
      return false;
    }
  }
}

/// Always-live nearest-responder query — never cached (geo context shifts
/// per call).
final nearestRespondersProvider =
    FutureProvider.autoDispose.family<List<Responder>, ({double lon, double lat})>(
  (ref, coords) {
    return ref
        .read(responderRepositoryProvider)
        .nearest(lon: coords.lon, lat: coords.lat);
  },
);

/// Responder lifecycle transitions the UI offers per current status (matches
/// the backend's allowed set; server stays the authority).
const kResponderTaskTransitions = <String, List<String>>{
  'NOTIFIED': ['ACKNOWLEDGED', 'CANCELLED'],
  'ACKNOWLEDGED': ['DISPATCHED', 'CANCELLED'],
  'DISPATCHED': ['ON_SITE', 'CANCELLED'],
  'ON_SITE': ['RESOLVED', 'CANCELLED'],
};

List<String> responderNextStatusesFor(String? status) =>
    kResponderTaskTransitions[status] ?? const [];