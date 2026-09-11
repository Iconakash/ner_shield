"""Risk-aware routing core (Phase 10 · C08) — PURE module, no DB/network.

Graph: nodes are merged segment-endpoint junctions; edges carry
length/accessibility/disruption-risk. Algorithms: Dijkstra + penalized
re-runs for k-distinct alternatives (C21 redundancy groundwork).
"""
import heapq
import math
from dataclasses import dataclass

# ------------------------------------------------------------------ tuning knobs
RISK_PENALTY_HOURS = 6.0        # a fully-risky segment costs +6h-equivalent at ra=1
SNAP_EPS_DEG = 0.03             # junction merge tolerance (~3 km)
SPEED_BASE_KPH = 15.0           # speed at accessibility 0
SPEED_MAX_EXTRA = 30.0          # additional kph at accessibility 100
HANDLING_OVERHEAD_H = 0.25      # load/unload overhead per route

# Priority -> default risk aversion (0 = pure fastest, 1 = pure safest)
PRIORITY_AVERSION = {"CRITICAL": 0.35, "HIGH": 0.50,
                     "MEDIUM": 0.65, "NORMAL": 0.75}

# ------------------------------------------------------- routing-mode profiles
# Modes are EXPLICIT contracts exposed on the API:
#   shortest   — minimize distance only (ra ignored)
#   fastest    — minimize expected travel time (ra=0)
#   safest     — minimize risk exposure (ra=1)
#   balanced   — risk-aware blend (default; ra from priority or explicit)
#   emergency  — time-first under an active emergency: reduced risk aversion,
#                convoy speed bonus; STILL never routes through CLOSED roads,
#                and every HIGH/CRITICAL segment used is surfaced as a warning.
MODES = ("shortest", "fastest", "safest", "balanced", "emergency")
EMERGENCY_SPEED_BONUS = 1.30      # cleared-corridor convoy speed factor
EMERGENCY_AVERSION = 0.20


def mode_profile(mode: str | None, priority: str | None = None) -> dict:
    """Resolve a mode name into (risk_aversion, speed_multiplier, distance_only)."""
    m = (mode or "balanced").lower()
    if m not in MODES:
        raise ValueError(f"unknown routing mode: {mode!r}")
    if m == "shortest":
        return {"mode": m, "risk_aversion": 0.0, "speed_mult": 1.0,
                "distance_only": True}
    if m == "fastest":
        return {"mode": m, "risk_aversion": 0.0, "speed_mult": 1.0,
                "distance_only": False}
    if m == "safest":
        return {"mode": m, "risk_aversion": 1.0, "speed_mult": 1.0,
                "distance_only": False}
    if m == "emergency":
        return {"mode": m, "risk_aversion": EMERGENCY_AVERSION,
                "speed_mult": EMERGENCY_SPEED_BONUS, "distance_only": False}
    ra = PRIORITY_AVERSION.get(priority or "NORMAL", 0.65)
    return {"mode": m, "risk_aversion": ra, "speed_mult": 1.0,
            "distance_only": False}


@dataclass(frozen=True)
class SegmentEdge:
    segment_id: str
    road_code: str
    seq: int
    u: int                      # merged junction index (origin end)
    v: int                      # merged junction index (destination end)
    length_km: float
    accessibility: float        # 0-100 goodness (latest score or derived)
    risk_pct: float             # disruption risk 0-100 (latest prediction)


@dataclass
class RouteResult:
    node_path: list[int]
    segments: list[SegmentEdge]
    distance_km: float
    travel_hours: float
    risk_pct: float
    cost: float


def _edge_travel_hours(e: SegmentEdge, speed_mult: float = 1.0) -> float:
    speed = (SPEED_BASE_KPH + SPEED_MAX_EXTRA * (e.accessibility / 100.0)) * speed_mult
    return (e.length_km / speed) if speed > 0 else float("inf")


def _edge_cost(e: SegmentEdge, risk_aversion: float,
               speed_mult: float = 1.0, distance_only: bool = False) -> float:
    if distance_only:
        return e.length_km
    hours = _edge_travel_hours(e, speed_mult)
    return hours + risk_aversion * RISK_PENALTY_HOURS * (e.risk_pct / 100.0)


class SegmentGraph:
    """Adjacency structure built from SegmentEdge records."""

    def __init__(self, edges: list[SegmentEdge]):
        self.edges = [e for e in edges if e.u != e.v]
        self.adj: dict[int, list[tuple[int, SegmentEdge]]] = {}
        for e in self.edges:
            self.adj.setdefault(e.u, []).append((e.v, e))
            self.adj.setdefault(e.v, []).append((e.u, e))

    def dijkstra(self, source: int, target: int,
                 risk_aversion: float,
                 blocked: set[str] | None = None,
                 penalties: dict[str, float] | None = None,
                 speed_mult: float = 1.0,
                 distance_only: bool = False) -> RouteResult | None:
        """Least-cost path under the risk-aware edge cost."""
        blocked = blocked or set()
        penalties = penalties or {}
        dist: dict[int, float] = {source: 0.0}
        prev: dict[int, tuple[int, SegmentEdge]] = {}
        pq: list[tuple[float, int]] = [(0.0, source)]
        visited: set[int] = set()
        while pq:
            d, u = heapq.heappop(pq)
            if u in visited:
                continue
            visited.add(u)
            if u == target:
                break
            for v, e in self.adj.get(u, []):
                if e.segment_id in blocked:
                    continue
                w = _edge_cost(e, risk_aversion, speed_mult,
                               distance_only) * penalties.get(e.segment_id, 1.0)
                nd = d + w
                if nd < dist.get(v, math.inf):
                    dist[v] = nd
                    prev[v] = (u, e)
                    heapq.heappush(pq, (nd, v))
        if target not in visited:
            return None

        segs: list[SegmentEdge] = []
        cur = target
        while cur != source:
            u, e = prev[cur]
            segs.append(e)
            cur = u
        segs.reverse()

        km = sum(s.length_km for s in segs)
        hours = sum(_edge_travel_hours(s, speed_mult) for s in segs) + HANDLING_OVERHEAD_H
        tot_len = sum(s.length_km for s in segs) or 1.0
        risk = sum(s.risk_pct * s.length_km for s in segs) / tot_len
        cost = sum(_edge_cost(s, risk_aversion, speed_mult, distance_only) *
                   penalties.get(s.segment_id, 1.0) for s in segs) + HANDLING_OVERHEAD_H
        node_path = [source]
        for s in segs:
            node_path.append(s.v if s.u == node_path[-1] else s.u)
        return RouteResult(node_path, segs, round(km, 2),
                           round(hours, 2), round(risk, 1), round(cost, 2))


def k_distinct_routes(graph: SegmentGraph, source: int, target: int,
                      risk_aversion: float, k: int = 3,
                      penalty_factor: float = 1.6,
                      speed_mult: float = 1.0,
                      distance_only: bool = False) -> list[RouteResult]:
    """Iteratively penalize used segments to obtain distinct alternatives."""
    routes: list[RouteResult] = []
    penalties: dict[str, float] = {}
    for _ in range(k):
        res = graph.dijkstra(source, target, risk_aversion, penalties=penalties,
                             speed_mult=speed_mult, distance_only=distance_only)
        if res is None:
            break
        if any(r.segments == res.segments for r in routes):
            break
        routes.append(res)
        for s in res.segments:
            penalties[s.segment_id] = penalties.get(s.segment_id, 1.0) * penalty_factor
    return routes


# ------------------------------------------------------------------ multi-stop
def _haversine_km(a: tuple[float, float], b: tuple[float, float]) -> float:
    lon1, lat1, lon2, lat2 = map(math.radians, (a[0], a[1], b[0], b[1]))
    dlat, dlon = lat2 - lat1, lon2 - lon1
    h = math.sin(dlat / 2) ** 2 + math.cos(lat1) * math.cos(lat2) * math.sin(dlon / 2) ** 2
    return 2 * 6371.0 * math.asin(math.sqrt(h))


def optimize_stop_order(stops: list[tuple[float, float]],
                        return_to_origin: bool = False) -> list[int]:
    """Visitation order for stops (indices into `stops`), first stop fixed at 0.

    Heuristic tour over straight-line distances (nearest-neighbour seed +
    2-opt improvement). Actual legs are then routed on the road graph by the
    service layer — this ordering is an O(n²)-bounded approximation suitable
    for the ≤25-stop operational limit enforced at the API.
    """
    n = len(stops)
    if n <= 2:
        return list(range(n))

    def tour_len(order: list[int]) -> float:
        pts = [stops[i] for i in order]
        if return_to_origin:
            pts = pts + [pts[0]]
        return sum(_haversine_km(pts[i], pts[i + 1]) for i in range(len(pts) - 1))

    # nearest-neighbour seed from stop 0
    unvisited = set(range(1, n))
    order = [0]
    while unvisited:
        last = stops[order[-1]]
        nxt = min(unvisited, key=lambda i: _haversine_km(last, stops[i]))
        order.append(nxt)
        unvisited.discard(nxt)

    # 2-opt improvement
    improved = True
    while improved:
        improved = False
        best = tour_len(order)
        for i in range(1, n - 1):
            for j in range(i + 1, n):
                cand = order[:i] + order[i:j + 1][::-1] + order[j + 1:]
                cl = tour_len(cand)
                if cl < best - 1e-9:
                    order, best, improved = cand, cl, True
    return order
