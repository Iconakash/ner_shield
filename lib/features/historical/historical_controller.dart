import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../models/cached_result.dart';
import '../../models/historical_event.dart';

/// Historical event list — `GET /historical/events` (master prompt §P4).
/// Server returns `data_quality` + `dataset_version` for every row; the
/// client renders those verbatim so a SAMPLE / SIMULATED result cannot be
/// presented as MEASURED.
final historicalEventsProvider = AsyncNotifierProvider<
    HistoricalEventsController,
    CachedResult<List<HistoricalEvent>>>(HistoricalEventsController.new);

class HistoricalEventsController
    extends AsyncNotifier<CachedResult<List<HistoricalEvent>>> {
  @override
  Future<CachedResult<List<HistoricalEvent>>> build() {
    return ref.watch(historicalRepositoryProvider).events();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(historicalRepositoryProvider).events(),
    );
  }
}

/// Single-event detail (autoDispose: one event lives only while its
/// detail screen is open).
final historicalEventDetailProvider = FutureProvider.autoDispose
    .family<CachedResult<HistoricalEvent>, String>((ref, eventId) {
  return ref.watch(historicalRepositoryProvider).eventDetail(eventId);
});

/// Latest validation run for an event (autoDispose for the same reason).
final historicalValidationProvider = FutureProvider.autoDispose
    .family<CachedResult<HistoricalValidationRun>, String>((ref, eventId) {
  return ref.watch(historicalRepositoryProvider).latestValidation(eventId);
});