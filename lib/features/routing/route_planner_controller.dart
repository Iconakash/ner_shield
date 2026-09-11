import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/connectivity/connectivity_manager.dart';
import '../../core/errors/app_exception.dart';
import '../../core/logging/app_logger.dart';
import '../../models/field_report.dart' show FieldReport;
import '../../models/routing_plan.dart';
import '../../repositories/routing_repository.dart';

/// Planner form state + orchestration (Phase 10).
///
/// Endpoints accept either a facility code or raw `lon, lat` coordinates —
/// matching the backend contract (`origin: {facility_code?|lon,lat}`).
/// Priority input is deliberately omitted: the reference does not pin the
/// allowed enum values in the contract map (documented in
/// docs/backend-integration-issues.md), so the field is left to the backend
/// default rather than guessed.
class PlannerState {
  const PlannerState({
    this.originText = '',
    this.destinationText = '',
    this.modeId,
    this.k = 2,
    this.riskAversion = 0.5,
    this.planning = false,
    this.result,
    this.selectedIndex = 0,
    this.lastError,
    this.modes = const <RoutingMode>[],
    // ---------------- Phase 5 — offline routing (§5.3-5.5) ----------------
    this.offlineNotice,
    this.staleNotice,
    this.lastRequest,
  });

  final String originText;
  final String destinationText;
  final String? modeId;
  final int k;
  final double riskAversion;
  final bool planning;

  /// Sorted (rank 1 first) plan result, when a plan succeeded.
  final List<PlannedRoute>? result;
  final int selectedIndex;
  final String? lastError;
  final List<RoutingMode> modes;

  /// Non-null when the displayed plan came from the offline engine rather
  /// than the live server. The UI must render this prominently — an offline
  /// plan is never live data (§5.3).
  final String? offlineNotice;

  /// Non-null when the offline plan used a snapshot older than the freshness
  /// budget — "STALE — verify against the server before dispatch" (§5.3).
  final String? staleNotice;

  /// Last successfully-issued request, kept so a reconnect can silently
  /// re-plan against the live server (§5.5).
  final RoutePlanRequest? lastRequest;

  bool get hasResult => result != null && result!.isNotEmpty;
  bool get isOfflinePlan => offlineNotice != null;

  PlannerState copyWith({
    String? originText,
    String? destinationText,
    String? modeId,
    bool clearMode = false,
    int? k,
    double? riskAversion,
    bool? planning,
    List<PlannedRoute>? result,
    bool clearResult = false,
    int? selectedIndex,
    String? lastError,
    bool clearLastError = false,
    List<RoutingMode>? modes,
    String? offlineNotice,
    bool clearOfflineNotice = false,
    String? staleNotice,
    bool clearStaleNotice = false,
    RoutePlanRequest? lastRequest,
    bool clearLastRequest = false,
  }) {
    return PlannerState(
      originText: originText ?? this.originText,
      destinationText: destinationText ?? this.destinationText,
      modeId: clearMode ? null : (modeId ?? this.modeId),
      k: k ?? this.k,
      riskAversion: riskAversion ?? this.riskAversion,
      planning: planning ?? this.planning,
      result: clearResult ? null : (result ?? this.result),
      selectedIndex: selectedIndex ?? this.selectedIndex,
      lastError: clearLastError ? null : (lastError ?? this.lastError),
      modes: modes ?? this.modes,
      offlineNotice:
          clearOfflineNotice ? null : (offlineNotice ?? this.offlineNotice),
      staleNotice: clearStaleNotice ? null : (staleNotice ?? this.staleNotice),
      lastRequest: clearLastRequest ? null : (lastRequest ?? this.lastRequest),
    );
  }
}

/// Parses `lon, lat` or a bare facility code into a [RouteEndpoint].
RouteEndpoint? parseEndpoint(String text) {
  final t = text.trim();
  if (t.isEmpty) return null;
  final parts = t.split(RegExp(r'[,\s]+'));
  if (parts.length == 2) {
    final lon = double.tryParse(parts[0]);
    final lat = double.tryParse(parts[1]);
    if (lon == null || lat == null) return null;
    if (!FieldReport.withinBounds(lon: lon, lat: lat)) return null;
    return RouteEndpoint(lon: lon, lat: lat);
  }
  return RouteEndpoint(facilityCode: t);
}

class RoutePlannerController extends Notifier<PlannerState> {
  @override
  PlannerState build() {
    // Phase 5 §5.5 — reconnect triggers a snapshot refresh from the server
    // and a silent re-plan of the last request (offline result is replaced
    // by the authoritative server state).
    ref.listen<String>(connectivityClassProvider, (prev, next) {
      if (prev == 'OFFLINE' && next != 'OFFLINE') {
        _onReconnected();
      }
    });

    // Load supported modes once (cached repository-level).
    Future<void> loadModes() async {
      try {
        final m = await ref.read(routingRepositoryProvider).modes();
        state = state.copyWith(modes: m.value);
      } catch (e, s) {
        AppLogger.instance.error('routing modes load failed', e, s);
        // Non-fatal: planning without an explicit mode uses backend default.
      }
    }

    loadModes();
    return const PlannerState();
  }

  void setOrigin(String v) =>
      state = state.copyWith(originText: v, clearLastError: true);
  void setDestination(String v) =>
      state = state.copyWith(destinationText: v, clearLastError: true);
  void setMode(String? v) =>
      state = state.copyWith(modeId: v, clearMode: v == null);
  void setK(int v) => state = state.copyWith(k: v.clamp(1, 5));
  void setRiskAversion(double v) => state = state.copyWith(riskAversion: v);
  void select(int index) => state = state.copyWith(selectedIndex: index);

  /// Swaps origin and destination text.
  void swap() => state = state.copyWith(
    originText: state.destinationText,
    destinationText: state.originText,
    clearResult: true,
    clearLastError: true,
  );

  /// Requests a fresh plan from the backend engine; on network failure it
  /// falls back to the offline engine over the persisted snapshot (Phase 5).
  Future<void> plan() async {
    final origin = parseEndpoint(state.originText);
    final destination = parseEndpoint(state.destinationText);
    if (origin == null || destination == null) {
      state = state.copyWith(
        lastError:
            'Enter each endpoint as a facility code or as "longitude, '
            'latitude" inside the NER bounds (lon 80-98, lat 21-29.5).',
      );
      return;
    }
    if (!origin.isValid || !destination.isValid) {
      state = state.copyWith(
        lastError: 'Origin and destination are both required.',
      );
      return;
    }
    final request = RoutePlanRequest(
      origin: origin,
      destination: destination,
      riskAversion: state.riskAversion,
      k: state.k,
      mode: state.modeId,
    );
    state = state.copyWith(
      planning: true,
      clearLastError: true,
      clearResult: true,
      clearOfflineNotice: true,
      clearStaleNotice: true,
    );
    try {
      final outcome = await ref
          .read(routingRepositoryProvider)
          .planWithFallback(request);
      switch (outcome) {
        case LivePlan(:final response):
          state = state.copyWith(
            planning: false,
            result: response.sortedByRank,
            selectedIndex: 0,
            lastRequest: request,
            clearOfflineNotice: true,
            clearStaleNotice: true,
          );
        case OfflinePlan(:final result):
          state = state.copyWith(
            planning: false,
            result: result.plan.sortedByRank,
            selectedIndex: 0,
            lastRequest: request,
            offlineNotice:
                'Offline plan — computed on-device from the last synced '
                'road graph. The server remains authoritative once you '
                'reconnect.',
            staleNotice: result.stale
                ? 'STALE DATA — the offline snapshot is older than the '
                    'freshness budget. Verify against the server before '
                    'dispatch.'
                : null,
          );
        case OfflineUnavailable(:final reason):
          state = state.copyWith(planning: false, lastError: reason);
      }
    } catch (e, s) {
      final message = e is AppException
          ? e.message
          : 'Could not plan the route. Please try again.';
      state = state.copyWith(planning: false, lastError: message);
      AppLogger.instance.error('route plan failed', e, s);
    }
  }

  /// §5.5 — on reconnect: refresh the offline snapshot from the server and
  /// silently re-plan the last request so a stale offline result is replaced
  /// by the authoritative server state. Fire-and-forget; failures are
  /// logged, never surfaced as errors (the user still has the offline plan).
  void _onReconnected() {
    final repo = ref.read(routingRepositoryProvider);
    unawaited(() async {
      try {
        await repo.refreshSnapshot();
      } catch (e) {
        AppLogger.instance.warn('offline graph refresh failed: $e');
      }
      final last = state.lastRequest;
      if (last == null || state.planning) return;
      try {
        final outcome = await repo.planWithFallback(last);
        if (outcome is LivePlan) {
          state = state.copyWith(
            result: outcome.response.sortedByRank,
            selectedIndex: 0,
            clearOfflineNotice: true,
            clearStaleNotice: true,
          );
        } else if (outcome is OfflinePlan) {
          // Server still unreachable; keep offline result fresh-labelled.
          state = state.copyWith(
            result: outcome.result.plan.sortedByRank,
            selectedIndex: 0,
            offlineNotice:
                'Offline plan — computed on-device from the last synced '
                'road graph. The server remains authoritative once you '
                'reconnect.',
            staleNotice: outcome.result.stale
                ? 'STALE DATA — the offline snapshot is older than the '
                    'freshness budget. Verify against the server before '
                    'dispatch.'
                : null,
          );
        }
      } catch (e) {
        AppLogger.instance.warn('reconnect re-plan failed: $e');
      }
    }());
  }
}

final routePlannerProvider =
    NotifierProvider<RoutePlannerController, PlannerState>(
      RoutePlannerController.new,
    );
