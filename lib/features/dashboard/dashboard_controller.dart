import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../models/cached_result.dart';
import '../../models/command_summary.dart';

/// Dashboard state = the backend's frozen six-KPI command summary
/// (`GET /command/summary`, RLS-scoped) wrapped in its cache-freshness info.
///
/// No client-side aggregation: the tiles, their order and their meaning come
/// from the backend (reference `backend/app/command/service.py::summary`).
final dashboardProvider = AsyncNotifierProvider<DashboardController,
    CachedResult<CommandSummary>>(DashboardController.new);

class DashboardController
    extends AsyncNotifier<CachedResult<CommandSummary>> {
  @override
  Future<CachedResult<CommandSummary>> build() {
    return ref.watch(commandRepositoryProvider).summary();
  }

  /// Pull-to-refresh / retry. Cache-first: offline it falls back to the last
  /// known summary with its timestamp instead of clearing the screen.
  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(commandRepositoryProvider).summary(),
    );
  }
}