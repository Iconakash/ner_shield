import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../models/cached_result.dart';
import '../../models/risk_item.dart';

/// Latest disruption predictions per segment (`GET /risk/latest`).
///
/// AI/ML stays server-side (master prompt §32): the client renders the
/// backend's scores, labels, factors, narrative and model metadata verbatim.
/// No client-side model, no derived risk values.
final riskLatestProvider = AsyncNotifierProvider<RiskController,
    CachedResult<List<RiskPrediction>>>(RiskController.new);

class RiskController
    extends AsyncNotifier<CachedResult<List<RiskPrediction>>> {
  @override
  Future<CachedResult<List<RiskPrediction>>> build() {
    return ref.watch(riskRepositoryProvider).latest();
  }

  /// Pull-to-refresh — explicit loading state (house pattern).
  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(riskRepositoryProvider).latest(),
    );
  }
}

/// WHY card for one segment (`GET /risk/{segment_id}/explain`). The
/// repository caches it briefly; `autoDispose` keeps one segment's card in
/// memory only while its sheet is open.
final riskExplainProvider = FutureProvider.autoDispose
    .family<CachedResult<RiskExplain>, String>((ref, segmentId) {
  return ref.watch(riskRepositoryProvider).explain(segmentId);
});
