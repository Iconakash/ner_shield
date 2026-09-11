// Phase 5 — offline plan builder. Turns the persisted snapshot into the
// SAME client contract the authoritative server plan produces
// (`RoutePlanResponse{routes:[PlannedRoute]}` per docs/api-contract-map.md),
// mirroring the server's ranking, narrative and high-risk warning semantics
// (backend/app/routing/service.py `plan_routes`).
//
// Degraded modes are EXPLICIT (§5.4): never fake precision. When the
// snapshot is stale, every result carries the snapshot age.

import '../../models/routing_plan.dart';
import 'offline_route_engine.dart';

/// Raised with a user-safe message when an offline plan cannot be produced.
class OfflinePlanException implements Exception {
  const OfflinePlanException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// Result wrapper distinguishing offline output from a live server plan.
class OfflinePlanResult {
  const OfflinePlanResult({
    required this.plan,
    required this.snapshotAt,
    required this.stale,
    required this.degradedNotes,
  });

  final RoutePlanResponse plan;
  final DateTime snapshotAt;
  final bool stale;
  final List<String> degradedNotes;
}

/// Builds a ranked plan from the offline snapshot. Mirrors the server
/// `plan_routes` step-for-step: snap → mode profile → k alternatives →
/// cost-ranked → high-risk warnings → narrative.
OfflinePlanResult planOffline(
  List<RawGraphEdge> openRows, {
  required double originLon,
  required double originLat,
  required double destLon,
  required double destLat,
  String? priority,
  double? riskAversion,
  int k = 3,
  String? mode,
  List<String> avoidSegmentIds = const [],
  required DateTime snapshotAt,
  required bool stale,
  Duration? snapshotAge,
}) {
  final notes = <String>[];
  if (openRows.isEmpty) {
    throw const OfflinePlanException(
        'No offline road graph is cached yet. Connect to the network once '
        'so the routing snapshot can be downloaded, then offline planning '
        'will work for the cached region.');
  }

  final built = buildOfflineGraph(openRows);
  final graph = built.graph;
  final jcoords = built.junctionCoords;

  final src = snapToJunction(jcoords, originLon, originLat);
  final dst = snapToJunction(jcoords, destLon, destLat);
  if (src == null || dst == null) {
    throw const OfflinePlanException(
        'origin/destination could not be snapped to the offline road network');
  }
  if (src == dst) {
    throw const OfflinePlanException(
        'origin and destination snap to the same network point');
  }

  final prof = modeProfile(mode, priority);
  var ra = prof.riskAversion;
  if (riskAversion != null && !prof.distanceOnly) {
    ra = riskAversion.clamp(0.0, 1.0).toDouble();
  }
  final blocked = avoidSegmentIds.toSet();

  final routes = kDistinctRoutes(
    graph,
    src,
    dst,
    riskAversion: ra,
    k: k.clamp(1, 5),
    speedMult: prof.speedMult,
    distanceOnly: prof.distanceOnly,
    blocked: blocked,
  );
  if (routes.isEmpty) {
    throw const OfflinePlanException(
        'no reachable route between origin and destination in the offline '
        'snapshot (check closures/avoided segments)');
  }

  ({
    List<Map<String, dynamic>> seg,
    double cost,
    double etaHours,
    double riskPct,
    List<String> highRisk,
    String? note
  }) describe(OfflineRouteResult res) {
    final segs = <Map<String, dynamic>>[];
    for (final s in res.segments) {
      segs.add({
        'road_code': s.roadCode,
        'seq': s.seq,
        'segment_id': s.segmentId,
        'accessibility': _round1(s.accessibility),
        'risk_pct': s.riskPct,
      });
    }
    final highRisk = segs
        .where((s) => kHighRiskLabels
            .contains(riskLabelFor((s['risk_pct'] as num).toDouble())))
        .map((s) => s['segment_id'] as String)
        .toList();
    String? note;
    if (prof.mode == 'emergency' && highRisk.isNotEmpty) {
      note = 'EMERGENCY corridor crosses high-risk segments — '
          'clearance/advisory required before dispatch';
    } else if (highRisk.isNotEmpty) {
      note = 'route crosses high-risk segments';
    }
    return (
      seg: segs,
      cost: res.cost,
      etaHours: res.travelHours,
      riskPct: res.riskPct,
      highRisk: highRisk,
      note: note,
    );
  }

  final ranked = routes.map(describe).toList()
    ..sort((a, b) => a.cost.compareTo(b.cost));

  final plannedRoutes = <PlannedRoute>[];
  for (var i = 0; i < ranked.length; i++) {
    final r = ranked[i];
    plannedRoutes.add(PlannedRoute(
      rank: i + 1,
      mode: prof.mode,
      segments: r.seg,
      totalDistanceKm: routes[i].distanceKm,
      totalEtaMinutes: r.etaHours * 60.0,
      aggregateRisk: r.riskPct / 100.0,
      aggregateRiskLabel: riskLabelFor(r.riskPct),
      narrative: r.note,
    ));
  }

  // Server-style narrative on the recommendation, prefixed with the
  // explicit offline/degraded banner (never presented as live data).
  final fastestIdx = _argMin(ranked.map((r) => r.etaHours).toList());
  final safestIdx = _argMin(ranked.map((r) => r.riskPct).toList());
  final rec = ranked.first;
  final ageLabel =
      snapshotAge == null ? '' : ' Snapshot age: ${_humanAge(snapshotAge)}.';
  final banner = stale
      ? 'OFFLINE PLAN from a STALE snapshot — verify against the server '
          'before dispatch.$ageLabel'
      : 'OFFLINE PLAN from the last synced snapshot.$ageLabel';
  String narrative;
  if (fastestIdx == 0) {
    narrative = '$banner Rank 1 is both the fastest '
        '(${fmtEta(rec.etaHours)}) and lowest-cost option at '
        '${rec.riskPct.toStringAsFixed(0)}% risk.';
  } else {
    final fastest = ranked[fastestIdx];
    final safest = ranked[safestIdx];
    narrative = '$banner Rank 1 balances reliability and time: '
        '${fmtEta(rec.etaHours)} at ${rec.riskPct.toStringAsFixed(0)}% risk '
        'versus the fastest option (${fmtEta(fastest.etaHours)} but '
        '${fastest.riskPct.toStringAsFixed(0)}% risk). Safest available: '
        '${fmtEta(safest.etaHours)} at ${safest.riskPct.toStringAsFixed(0)}%.';
  }

  // Attach the recommendation summary (incl. the offline/stale banner) to the
  // rank-1 route so the UI never loses the degraded-data labelling (§5.3).
  if (plannedRoutes.isNotEmpty && narrative.isNotEmpty) {
    final first = plannedRoutes.first;
    final base = first.narrative;
    plannedRoutes[0] = first.copyWith(
      narrative: base == null || base.isEmpty ? narrative : '$narrative $base',
    );
  }

  return OfflinePlanResult(
    plan: RoutePlanResponse(routes: plannedRoutes),
    snapshotAt: snapshotAt,
    stale: stale,
    degradedNotes: notes,
  );
}

int _argMin(List<double> xs) {
  var best = 0;
  for (var i = 1; i < xs.length; i++) {
    if (xs[i] < xs[best]) best = i;
  }
  return best;
}

double _round1(double v) => (v * 10).roundToDouble() / 10;

String _humanAge(Duration age) {
  if (age.inMinutes < 1) return 'just now';
  if (age.inHours < 1) return '${age.inMinutes} min ago';
  if (age.inDays < 1) return '${age.inHours} h ago';
  return '${age.inDays} d ago';
}