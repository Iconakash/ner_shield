import '../core/errors/app_exception.dart';
import '../core/routing/offline_route_graph_store.dart';
import '../core/routing/offline_route_planner.dart';
import '../core/storage/cache_first.dart';
import '../models/routing_plan.dart';
import '../services/routing_service.dart';

export '../core/routing/offline_route_graph_store.dart'
    show OfflineRouteGraphStore, StoredGraphSnapshot, defaultStaleAfter;

/// Outcome of [RoutingRepository.planWithFallback].
sealed class PlanOutcome {
  const PlanOutcome();
}

/// Server-authoritative plan (the normal online path).
class LivePlan extends PlanOutcome {
  const LivePlan(this.response);
  final RoutePlanResponse response;
}

/// Offline plan from the persisted snapshot (explicitly labelled stale
/// or fresh; the UI must never present it as live data).
class OfflinePlan extends PlanOutcome {
  const OfflinePlan(this.result);
  final OfflinePlanResult result;
}

/// Offline planning was impossible (no snapshot / unroutable). Carries a
/// user-safe explanation — never a fake plan.
class OfflineUnavailable extends PlanOutcome {
  const OfflineUnavailable(this.reason);
  final String reason;
}

/// Route planning + modes.
///
/// Modes are near-static configuration (cached 1 hour). Plans are always
/// fetched live: the backend engine evaluates current road state, incidents
/// and risk at call time, so a cached plan would be dangerously stale.
class RoutingRepository {
  RoutingRepository(this._svc, {this._offlineStore})
    : _modes = CacheFirst(TtlCache(ttl: const Duration(hours: 1)));

  final RoutingService _svc;
  final CacheFirst<List<RoutingMode>> _modes;
  final OfflineRouteGraphStore? _offlineStore;

  /// Supported planning modes for this deployment (cached).
  Future<CachedResult<List<RoutingMode>>> modes() =>
      _modes.run('routing-modes', fetch: _svc.modes);

  /// Plan a route (never cached — see class doc).
  Future<RoutePlanResponse> plan(RoutePlanRequest request) =>
      _svc.plan(request);

  /// Fetches and persists the offline graph snapshot. Call while online
  /// (auto-refreshed on reconnect by the planner controller, §5.5).
  Future<DateTime> refreshSnapshot() async {
    final store = _offlineStore;
    if (store == null) {
      throw StateError('offline routing not configured for this repository');
    }
    final snapshot = await _svc.graphSnapshot();
    await store.save(snapshot);
    return snapshot.fetchedAt;
  }

  /// Plan with offline fallback (Phase 5 §5.2-5.4):
  ///
  ///  1. server first — it stays authoritative whenever reachable;
  ///  2. on a NETWORK failure, fall back to the persisted snapshot and the
  ///     mirrored offline engine, returning an explicitly-labelled result;
  ///  3. when even that is impossible, return [OfflineUnavailable] with a
  ///     user-safe explanation (no fake plans, ever).
  ///
  /// Other failures (validation, authz, server 4xx/5xx) are rethrown —
  /// falling back offline would mask real errors.
  Future<PlanOutcome> planWithFallback(
    RoutePlanRequest request, {
    Duration staleAfter = defaultStaleAfter,
  }) async {
    try {
      return LivePlan(await _svc.plan(request));
    } on NetworkException {
      final store = _offlineStore;
      if (store == null) {
        return const OfflineUnavailable(
            'You are offline and offline routing is not configured on this '
            'device.');
      }
      final stored = await store.load();
      if (stored == null) {
        return const OfflineUnavailable(
            'You are offline and no routing snapshot has been cached yet. '
            'Connect once to download the offline road graph.');
      }
      // Facility codes cannot be resolved offline: the snapshot carries the
      // road graph, not the facility registry (explicit degraded mode).
      if (request.origin.facilityCode != null ||
          request.destination.facilityCode != null) {
        return const OfflineUnavailable(
            'Facility codes cannot be resolved offline. Re-enter each '
            'endpoint as "longitude, latitude" to plan offline.');
      }
      try {
        final result = planOffline(
          stored.openRows,
          originLon: request.origin.lon!,
          originLat: request.origin.lat!,
          destLon: request.destination.lon!,
          destLat: request.destination.lat!,
          priority: request.priority,
          riskAversion: request.riskAversion,
          k: request.k ?? 3,
          mode: request.mode,
          avoidSegmentIds: request.avoidSegmentIds ?? const [],
          snapshotAt: stored.fetchedAt,
          stale: stored.isStale(staleAfter: staleAfter),
          snapshotAge: stored.age,
        );
        return OfflinePlan(result);
      } on OfflinePlanException catch (e) {
        return OfflineUnavailable(e.message);
      }
    }
  }
}
