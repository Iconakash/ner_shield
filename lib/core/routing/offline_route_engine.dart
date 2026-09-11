// Phase 5 — OFFLINE risk-aware routing engine (master prompt §5.1-5.4).
//
// This is a DELIBERATE, EXACT mirror of the authoritative server engine
// (`backend/app/routing/graph.py` + `geometry.py`). Same tuning knobs, same
// edge-cost semantics, same junction merging, same k-alternative and
// multi-stop strategies. The offline layer must never invent a second
// routing philosophy — when the server is reachable it stays authoritative
// and this engine's result is discarded in favour of the live plan.
//
// Inputs come from the persisted graph snapshot (`GET /routing/graph-snapshot`,
// which reuses the server's own edge loader), so edge weights are identical
// to the online engine by construction.

import 'dart:math' as math;

// ------------------------------------------------------------------ tuning knobs
// Mirrored verbatim from backend/app/routing/graph.py.
const double kRiskPenaltyHours = 6.0;
const double kSnapEpsDeg = 0.03;
const double kSpeedBaseKph = 15.0;
const double kSpeedMaxExtra = 30.0;
const double kHandlingOverheadH = 0.25;

/// Priority -> default risk aversion (0 = pure fastest, 1 = pure safest).
const Map<String, double> kPriorityAversion = {
  'CRITICAL': 0.35,
  'HIGH': 0.50,
  'MEDIUM': 0.65,
  'NORMAL': 0.75,
};

const List<String> kRoutingModes = [
  'shortest',
  'fastest',
  'safest',
  'balanced',
  'emergency',
];
const double kEmergencySpeedBonus = 1.30;
const double kEmergencyAversion = 0.20;

/// Server HIGH_RISK_LABELS — segments at/above these bands are surfaced as
/// explicit warnings in every mode (mandatory in emergency mode).
const List<String> kHighRiskLabels = ['HIGH', 'CRITICAL'];

/// One road-graph edge. Mirrors the server `SegmentEdge` dataclass.
class OfflineSegmentEdge {
  const OfflineSegmentEdge({
    required this.segmentId,
    required this.roadCode,
    required this.seq,
    required this.u,
    required this.v,
    required this.lengthKm,
    required this.accessibility,
    required this.riskPct,
  });

  final String segmentId;
  final String roadCode;
  final int seq;
  final int u; // merged junction index (origin end)
  final int v; // merged junction index (destination end)
  final double lengthKm;
  final double accessibility; // 0-100 goodness
  final double riskPct; // disruption risk 0-100
}

/// Resolved routing-mode profile. Mirrors the server `mode_profile`.
class OfflineModeProfile {
  const OfflineModeProfile({
    required this.mode,
    required this.riskAversion,
    required this.speedMult,
    required this.distanceOnly,
  });

  final String mode;
  final double riskAversion;
  final double speedMult;
  final bool distanceOnly;
}

OfflineModeProfile modeProfile(String? mode, [String? priority]) {
  final m = (mode ?? 'balanced').toLowerCase();
  if (!kRoutingModes.contains(m)) {
    throw ArgumentError.value(mode, 'mode', 'unknown routing mode');
  }
  switch (m) {
    case 'shortest':
      return OfflineModeProfile(
          mode: m, riskAversion: 0, speedMult: 1.0, distanceOnly: true);
    case 'fastest':
      return OfflineModeProfile(
          mode: m, riskAversion: 0, speedMult: 1.0, distanceOnly: false);
    case 'safest':
      return OfflineModeProfile(
          mode: m, riskAversion: 1.0, speedMult: 1.0, distanceOnly: false);
    case 'emergency':
      return OfflineModeProfile(
          mode: m,
          riskAversion: kEmergencyAversion,
          speedMult: kEmergencySpeedBonus,
          distanceOnly: false);
    default:
      return OfflineModeProfile(
        mode: m,
        riskAversion: kPriorityAversion[priority ?? 'NORMAL'] ?? 0.65,
        speedMult: 1.0,
        distanceOnly: false,
      );
  }
}

/// Mirrors the server `risk_label_for` bands.
String riskLabelFor(double riskPct) {
  if (riskPct >= 85) return 'CRITICAL';
  if (riskPct >= 70) return 'HIGH';
  if (riskPct >= 45) return 'ELEVATED';
  if (riskPct >= 20) return 'GUARDED';
  return 'LOW';
}

/// Mirrors the server `_fmt_eta`.
String fmtEta(double hours) {
  final totalMinutes = (hours * 60).round();
  final h = totalMinutes ~/ 60;
  final m = totalMinutes % 60;
  return '${h}h${m.toString().padLeft(2, '0')}';
}

double haversineKm((double, double) a, (double, double) b) {
  final (lon1, lat1) = a;
  final (lon2, lat2) = b;
  final dlat = _rad(lat2 - lat1);
  final dlon = _rad(lon2 - lon1);
  final h = math.sin(dlat / 2) * math.sin(dlat / 2) +
      math.cos(_rad(lat1)) *
          math.cos(_rad(lat2)) *
          math.sin(dlon / 2) *
          math.sin(dlon / 2);
  return 2 * 6371.0 * math.asin(math.sqrt(h));
}

double _rad(double deg) => deg * math.pi / 180.0;

double _round(double v, int digits) {
  final f = math.pow(10, digits).toDouble();
  return (v * f).roundToDouble() / f;
}

double _edgeTravelHours(OfflineSegmentEdge e, double speedMult) {
  final speed =
      (kSpeedBaseKph + kSpeedMaxExtra * (e.accessibility / 100.0)) * speedMult;
  return speed > 0 ? e.lengthKm / speed : double.infinity;
}

double _edgeCost(OfflineSegmentEdge e, double riskAversion, double speedMult,
    bool distanceOnly) {
  if (distanceOnly) return e.lengthKm;
  return _edgeTravelHours(e, speedMult) +
      riskAversion * kRiskPenaltyHours * (e.riskPct / 100.0);
}

class OfflineRouteResult {
  OfflineRouteResult({
    required this.nodePath,
    required this.segments,
    required this.distanceKm,
    required this.travelHours,
    required this.riskPct,
    required this.cost,
  });

  final List<int> nodePath;
  final List<OfflineSegmentEdge> segments;
  final double distanceKm;
  final double travelHours;
  final double riskPct;
  final double cost;
}

/// Adjacency structure + Dijkstra. Mirrors the server `SegmentGraph`.
class OfflineRoadGraph {
  OfflineRoadGraph(List<OfflineSegmentEdge> edges) {
    for (final e in edges) {
      if (e.u == e.v) continue; // self-loops dropped (server parity)
      _edges.add(e);
      _adj.putIfAbsent(e.u, () => []).add((e.v, e));
      _adj.putIfAbsent(e.v, () => []).add((e.u, e));
    }
  }

  final List<OfflineSegmentEdge> _edges = [];
  final Map<int, List<(int, OfflineSegmentEdge)>> _adj = {};

  List<OfflineSegmentEdge> get edges => List.unmodifiable(_edges);
  bool get isEmpty => _edges.isEmpty;

  /// Least-cost path under the risk-aware edge cost. Null when unreachable.
  /// The operational NER graph is small (tens of segments), so extract-min
  /// over a map keeps server parity while staying O(n²)-bounded.
  OfflineRouteResult? dijkstra(
    int source,
    int target, {
    required double riskAversion,
    Set<String> blocked = const {},
    Map<String, double> penalties = const {},
    double speedMult = 1.0,
    bool distanceOnly = false,
  }) {
    final dist = <int, double>{source: 0.0};
    final prev = <int, (int, OfflineSegmentEdge)>{};
    final visited = <int>{};
    while (true) {
      int? best;
      double bestD = double.infinity;
      for (final entry in dist.entries) {
        if (visited.contains(entry.key)) continue;
        if (entry.value < bestD) {
          bestD = entry.value;
          best = entry.key;
        }
      }
      if (best == null) break;
      final u = best;
      visited.add(u);
      if (u == target) break;
      for (final (v, e) in _adj[u] ?? const <(int, OfflineSegmentEdge)>[]) {
        if (blocked.contains(e.segmentId)) continue;
        final w = _edgeCost(e, riskAversion, speedMult, distanceOnly) *
            (penalties[e.segmentId] ?? 1.0);
        final nd = bestD + w;
        if (nd < (dist[v] ?? double.infinity)) {
          dist[v] = nd;
          prev[v] = (u, e);
        }
      }
    }
    if (!visited.contains(target)) return null;

    final segsReversed = <OfflineSegmentEdge>[];
    var cur = target;
    while (cur != source) {
      final (u, e) = prev[cur]!;
      segsReversed.add(e);
      cur = u;
    }
    final segs = segsReversed.reversed.toList();

    final km = segs.fold(0.0, (s, e) => s + e.lengthKm);
    final hours = segs.fold(0.0, (s, e) => s + _edgeTravelHours(e, speedMult)) +
        kHandlingOverheadH;
    final totLen = segs.fold(0.0, (s, e) => s + e.lengthKm);
    final risk = totLen == 0
        ? 0.0
        : segs.fold(0.0, (s, e) => s + e.riskPct * e.lengthKm) / totLen;
    final cost = segs.fold(
            0.0,
            (s, e) =>
                s +
                _edgeCost(e, riskAversion, speedMult, distanceOnly) *
                    (penalties[e.segmentId] ?? 1.0)) +
        kHandlingOverheadH;
    final nodePath = <int>[source];
    for (final s in segs) {
      nodePath.add(s.u == nodePath.last ? s.v : s.u);
    }
    return OfflineRouteResult(
      nodePath: nodePath,
      segments: segs,
      distanceKm: _round(km, 2),
      travelHours: _round(hours, 2),
      riskPct: _round(risk, 1),
      cost: _round(cost, 2),
    );
  }
}

/// Iteratively penalize used segments to obtain distinct alternatives.
/// Mirrors the server `k_distinct_routes` (penalty factor 1.6).
List<OfflineRouteResult> kDistinctRoutes(
  OfflineRoadGraph graph,
  int source,
  int target, {
  required double riskAversion,
  int k = 3,
  double penaltyFactor = 1.6,
  double speedMult = 1.0,
  bool distanceOnly = false,
  Set<String> blocked = const {},
}) {
  final routes = <OfflineRouteResult>[];
  final penalties = <String, double>{};
  String sig(OfflineRouteResult r) =>
      r.segments.map((s) => s.segmentId).join('|');
  for (var i = 0; i < k; i++) {
    final res = graph.dijkstra(
      source,
      target,
      riskAversion: riskAversion,
      penalties: penalties,
      speedMult: speedMult,
      distanceOnly: distanceOnly,
      blocked: blocked,
    );
    if (res == null) break;
    if (routes.any((r) => sig(r) == sig(res))) break;
    routes.add(res);
    for (final s in res.segments) {
      penalties[s.segmentId] = (penalties[s.segmentId] ?? 1.0) * penaltyFactor;
    }
  }
  return routes;
}

// ------------------------------------------------------------- geometry helpers
// Mirrors backend/app/routing/geometry.py (equirectangular, eps grid,
// union-find junction merge).

String _coordKey(double lon, double lat) =>
    '${_round6(lon)},${_round6(lat)}';

double _round6(double v) => (v * 1e6).roundToDouble() / 1e6;

/// Union-find merge of segment endpoints into junction ids.
/// `endpoints` yields (segmentIndex, end 0|1, lon, lat).
/// Returns {exact_coord_key: junction_id} — mirrors `merge_endpoints`.
Map<String, int> mergeEndpoints(List<(int, int, double, double)> endpoints) {
  final parent = <String, String>{};

  String find(String k) {
    parent.putIfAbsent(k, () => k);
    var cur = k;
    while (parent[cur] != cur) {
      parent[cur] = parent[parent[cur]]!; // path halving
      cur = parent[cur]!;
    }
    return cur;
  }

  void union(String a, String b) {
    final ra = find(a);
    final rb = find(b);
    if (ra != rb) parent[rb] = ra;
  }

  bool near(double lon1, double lat1, double lon2, double lat2) {
    final dlon = (lon2 - lon1) * math.cos(_rad((lat1 + lat2) / 2));
    final dlat = lat2 - lat1;
    return math.sqrt(dlon * dlon + dlat * dlat) <= kSnapEpsDeg;
  }

  // Grid bucket, same cell shape as the server (int(lon/eps), int(lat/eps)).
  final grid = <(int, int), List<(double, double)>>{};
  for (final (_, _, lon, lat) in endpoints) {
    grid
        .putIfAbsent((lon ~/ kSnapEpsDeg, lat ~/ kSnapEpsDeg), () => [])
        .add((lon, lat));
  }

  for (final entry in grid.entries) {
    final members = entry.value;
    final neighbours = <List<(double, double)>>[
      members,
      ...[
        (entry.key.$1 + 1, entry.key.$2),
        (entry.key.$1, entry.key.$2 - 1),
        (entry.key.$1 + 1, entry.key.$2 - 1),
      ].map((nc) => grid[nc] ?? const <(double, double)>[]),
    ];
    for (var i = 0; i < members.length; i++) {
      final (lon1, lat1) = members[i];
      for (final group in neighbours) {
        for (final (lon2, lat2) in group) {
          if (lon1 == lon2 && lat1 == lat2) continue;
          if (near(lon1, lat1, lon2, lat2)) {
            union(_coordKey(lon1, lat1), _coordKey(lon2, lat2));
          }
        }
      }
    }
  }

  final junctionOf = <String, int>{};
  final roots = <String, int>{};
  for (final (_, _, lon, lat) in endpoints) {
    final k = _coordKey(lon, lat);
    final r = find(k);
    if (!roots.containsKey(r)) roots[r] = roots.length;
    junctionOf[k] = roots[r]!;
  }
  return junctionOf;
}

/// Raw snapshot row fed into [buildOfflineGraph].
class RawGraphEdge {
  const RawGraphEdge({
    required this.segmentId,
    required this.roadCode,
    required this.seq,
    required this.x1,
    required this.y1,
    required this.x2,
    required this.y2,
    required this.lengthKm,
    required this.accessibility,
    required this.riskPct,
  });

  final String segmentId;
  final String roadCode;
  final int seq;
  final double x1;
  final double y1;
  final double x2;
  final double y2;
  final double lengthKm;
  final double accessibility;
  final double riskPct;
}

/// Builds the offline graph from raw snapshot rows. CLOSED rows must
/// already be filtered by the caller (the server snapshot splits
/// open/closed; the store exposes only open rows for graph building).
({OfflineRoadGraph graph, Map<int, (double, double)> junctionCoords})
    buildOfflineGraph(List<RawGraphEdge> rows) {
  final endpoints = <(int, int, double, double)>[];
  for (var i = 0; i < rows.length; i++) {
    endpoints.add((i, 0, rows[i].x1, rows[i].y1));
    endpoints.add((i, 1, rows[i].x2, rows[i].y2));
  }
  final junctionOf = mergeEndpoints(endpoints);

  final edges = <OfflineSegmentEdge>[];
  for (var i = 0; i < rows.length; i++) {
    final r = rows[i];
    edges.add(OfflineSegmentEdge(
      segmentId: r.segmentId,
      roadCode: r.roadCode,
      seq: r.seq,
      u: junctionOf[_coordKey(r.x1, r.y1)]!,
      v: junctionOf[_coordKey(r.x2, r.y2)]!,
      lengthKm: r.lengthKm,
      accessibility: r.accessibility.clamp(0, 100).toDouble(),
      riskPct: r.riskPct.clamp(0, 100).toDouble(),
    ));
  }
  final jcoords = <int, (double, double)>{};
  for (final entry in junctionOf.entries) {
    final parts = entry.key.split(',');
    jcoords[entry.value] = (double.parse(parts[0]), double.parse(parts[1]));
  }
  return (graph: OfflineRoadGraph(edges), junctionCoords: jcoords);
}

/// Nearest junction to (lon, lat) in equirectangular km. Mirrors
/// `snap_to_junction` (no max-distance rejection — server parity).
int? snapToJunction(
  Map<int, (double, double)> junctionCoords,
  double lon,
  double lat,
) {
  int? best;
  var bestKm = double.infinity;
  for (final entry in junctionCoords.entries) {
    final (jlon, jlat) = entry.value;
    final dlon = (jlon - lon) * math.cos(_rad(lat));
    final dlat = jlat - lat;
    final km = math.sqrt(dlon * dlon + dlat * dlat) * 111.32;
    if (km < bestKm) {
      bestKm = km;
      best = entry.key;
    }
  }
  return best;
}

/// Visitation order for stops (nearest-neighbour seed + 2-opt). Mirrors the
/// server `optimize_stop_order` (O(n²)-bounded, ≤25-stop operational limit).
List<int> optimizeStopOrder(
  List<(double, double)> stops, {
  bool returnToOrigin = false,
}) {
  final n = stops.length;
  if (n <= 2) return List<int>.generate(n, (i) => i);

  double tourLen(List<int> order) {
    final pts = order.map((i) => stops[i]).toList();
    if (returnToOrigin) pts.add(pts.first);
    var len = 0.0;
    for (var i = 0; i < pts.length - 1; i++) {
      len += haversineKm(pts[i], pts[i + 1]);
    }
    return len;
  }

  final remaining = List<int>.generate(n - 1, (i) => i + 1);
  final order = <int>[0];
  while (remaining.isNotEmpty) {
    final last = stops[order.last];
    int? nxt;
    var best = double.infinity;
    for (final i in remaining) {
      final d = haversineKm(last, stops[i]);
      if (d < best) {
        best = d;
        nxt = i;
      }
    }
    order.add(nxt!);
    remaining.remove(nxt);
  }

  var improved = true;
  while (improved) {
    improved = false;
    final best = tourLen(order);
    for (var i = 1; i < n - 1; i++) {
      for (var j = i + 1; j < n; j++) {
        final cand = [...order];
        final seg = cand.sublist(i, j + 1).reversed.toList();
        cand
          ..removeRange(i, j + 1)
          ..insertAll(i, seg);
        final cl = tourLen(cand);
        if (cl < best - 1e-9) {
          order
            ..clear()
            ..addAll(cand);
          improved = true;
        }
      }
    }
  }
  return order;
}