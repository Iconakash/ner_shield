"""Phase 10 unit tests — risk-aware routing core (pure, no DB)."""
import pytest

from app.routing.graph import (
    EMERGENCY_AVERSION, EMERGENCY_SPEED_BONUS, MODES, PRIORITY_AVERSION,
    SegmentEdge, SegmentGraph, k_distinct_routes, mode_profile,
    optimize_stop_order)


def _edge(sid, u, v, km, acc, risk):
    return SegmentEdge(segment_id=sid, road_code="R", seq=0, u=u, v=v,
                       length_km=km, accessibility=acc, risk_pct=risk)


@pytest.fixture
def diamond():
    """A--(fast/risky)-->B ; A--(slower/safer)-->C ; B,D --> T ; C-->T.

    Reproduces the source example: Route A fastest but risky,
    Routes B/C safer but slower.
    """
    edges = [
        _edge("A1", 0, 1, 120, 90, 83),   # fast highway, risky (monsoon)
        _edge("B1", 0, 2, 150, 70, 19),   # longer, safer
        _edge("B2", 2, 3, 60, 80, 11),
        _edge("A2", 1, 3, 40, 95, 5),     # short safe tail after risky hop
    ]
    return SegmentGraph(edges)


def test_priority_aversion_defaults():
    assert PRIORITY_AVERSION["CRITICAL"] < PRIORITY_AVERSION["NORMAL"]
    assert PRIORITY_AVERSION["HIGH"] == 0.50


def test_risky_shortest_chosen_at_zero_aversion(diamond):
    res = diamond.dijkstra(0, 3, risk_aversion=0.0)
    assert res is not None
    assert [s.segment_id for s in res.segments] == ["A1", "A2"]
    assert res.risk_pct > 50


def test_balanced_aversion_switches_to_safer_route(diamond):
    """The source-example decision: pick B over A when risk matters."""
    res = diamond.dijkstra(0, 3, risk_aversion=0.6)
    assert res is not None
    ids = [s.segment_id for s in res.segments]
    assert "B1" in ids and "A1" not in ids


def test_k_alternatives_returns_distinct_paths(diamond):
    routes = k_distinct_routes(diamond, 0, 3, risk_aversion=0.6, k=3)
    assert len(routes) >= 2
    sigs = {tuple(s.segment_id for s in r.segments) for r in routes}
    assert len(sigs) == len(routes)


def test_eta_and_distance_sums(diamond):
    res = diamond.dijkstra(0, 3, risk_aversion=0.0)
    assert res.distance_km == pytest.approx(160.0)
    # speed on A1 = 15+30*0.9 = 42; A2 = 15+30*0.95 = 43.5
    expected_h = 120 / 42 + 40 / 43.5 + 0.25
    assert res.travel_hours == pytest.approx(expected_h, abs=0.01)


def test_length_weighted_risk_average(diamond):
    res = diamond.dijkstra(0, 3, risk_aversion=0.0)
    expected = (83 * 120 + 5 * 40) / 160
    assert res.risk_pct == pytest.approx(expected, abs=0.1)


# ===================================================== PHASE 6: routing modes
def test_mode_catalog_and_profiles():
    assert set(MODES) == {"shortest", "fastest", "safest", "balanced", "emergency"}
    assert mode_profile("shortest")["distance_only"] is True
    assert mode_profile("safest")["risk_aversion"] == 1.0
    assert mode_profile("fastest")["risk_aversion"] == 0.0
    assert mode_profile("balanced", "CRITICAL")["risk_aversion"] == \
        PRIORITY_AVERSION["CRITICAL"]
    assert mode_profile("emergency")["speed_mult"] == EMERGENCY_SPEED_BONUS
    assert mode_profile("emergency")["risk_aversion"] == EMERGENCY_AVERSION
    with pytest.raises(ValueError):
        mode_profile("teleport")


def test_safest_mode_picks_low_risk_route(diamond):
    """ra=1 must strongly prefer the safe B route over fast/risky A."""
    routes = k_distinct_routes(diamond, 0, 3, risk_aversion=1.0, k=2)
    best = routes[0]
    assert [s.segment_id for s in best.segments] == ["B1", "B2"]


def test_shortest_mode_is_distance_only(diamond):
    """Distance-only cost ignores risk AND speed: pure km minimization."""
    res = diamond.dijkstra(0, 3, risk_aversion=1.0, distance_only=True)
    # A route = 160km vs B route = 210km -> distance-only picks A despite risk 83%
    assert [s.segment_id for s in res.segments] == ["A1", "A2"]
    assert res.distance_km == pytest.approx(160.0)


def test_emergency_speed_bonus_shortens_eta_not_distance(diamond):
    normal = diamond.dijkstra(0, 3, risk_aversion=EMERGENCY_AVERSION)
    emergency = diamond.dijkstra(0, 3, risk_aversion=EMERGENCY_AVERSION,
                                 speed_mult=EMERGENCY_SPEED_BONUS)
    assert emergency.travel_hours < normal.travel_hours
    assert emergency.distance_km == normal.distance_km


def test_blocked_segment_forces_alternative(diamond):
    """Explicit avoid list hard-blocks segments (closed-road analogue)."""
    res = diamond.dijkstra(0, 3, risk_aversion=0.6, blocked={"A1"})
    assert [s.segment_id for s in res.segments] == ["B1", "B2"]


def test_unreachable_when_all_paths_blocked(diamond):
    res = diamond.dijkstra(0, 3, risk_aversion=0.5,
                           blocked={"A1", "A2", "B1", "B2"})
    assert res is None


# ============================================== PHASE 6: multi-stop service path
async def test_plan_multi_stop_orders_stops_and_ranks_legs(monkeypatch):
    """Full multi-stop pipeline over a synthetic graph (no DB)."""
    from app.routing import service as svc

    edges = [
        _edge("S1", 0, 1, 50, 85, 10),
        _edge("S2", 1, 2, 50, 85, 10),
        _edge("S3", 2, 3, 40, 80, 20),
    ]
    jcoords = {0: (91.70, 26.10), 1: (91.75, 26.12), 2: (91.80, 26.14),
               3: (91.85, 26.16)}

    async def fake_load_graph(db):
        return edges, jcoords

    monkeypatch.setattr(svc, "load_graph", fake_load_graph)

    # stops land on junctions 0, 2, 1 (out of optimal order)
    stops = [jcoords[0], jcoords[2], jcoords[1]]
    out = await svc.plan_multi_stop(None, stops, mode="fastest")

    assert out["mode"] == "fastest"
    assert sorted(out["stop_order"]) == [0, 1, 2]
    assert len(out["legs"]) == len(out["stop_order"]) - 1
    assert out["totals"]["distance_km"] > 0
    assert all("eta_display" in l for l in out["legs"])
    assert out["warnings"] == []


async def test_plan_multi_stop_return_to_origin_closes_tour(monkeypatch):
    from app.routing import service as svc

    edges = [_edge("T1", 0, 1, 30, 90, 5)]
    jcoords = {0: (91.70, 26.10), 1: (91.74, 26.12)}

    async def fake_load_graph(db):
        return edges, jcoords

    monkeypatch.setattr(svc, "load_graph", fake_load_graph)
    out = await svc.plan_multi_stop(None, [jcoords[0], jcoords[1]],
                                    return_to_origin=True)
    assert out["stop_order"][0] == 0 and out["stop_order"][-1] == 0
    assert len(out["legs"]) == 2


async def test_plan_multi_stop_rejects_unroutable_leg_explicitly(monkeypatch):
    """A stop isolated by closures must FAIL the whole plan loudly (no silent skip)."""
    from app.core.errors import NotFound

    from app.routing import service as svc

    edges = [_edge("U1", 0, 1, 30, 90, 5)]      # stop 3's junction unreachable
    jcoords = {0: (91.70, 26.10), 1: (91.74, 26.12), 2: (95.00, 28.00)}

    async def fake_load_graph(db):
        return edges, jcoords

    monkeypatch.setattr(svc, "load_graph", fake_load_graph)
    with pytest.raises(NotFound):
        await svc.plan_multi_stop(None, [jcoords[0], jcoords[1], jcoords[2]])


async def test_plan_routes_reports_mode_and_warnings(monkeypatch):
    from app.routing import service as svc

    edges = [
        _edge("W1", 0, 1, 60, 60, 88),          # HIGH-risk shortcut
        _edge("W2", 0, 2, 100, 75, 20),
        _edge("W3", 2, 1, 60, 80, 15),
    ]
    jcoords = {0: (91.7, 26.1), 1: (92.0, 26.3), 2: (91.8, 26.4)}

    async def fake_load_graph(db):
        return edges, jcoords

    monkeypatch.setattr(svc, "load_graph", fake_load_graph)
    out = await svc.plan_routes(None, 91.70, 26.10, 92.00, 26.30,
                                mode="emergency")
    assert out["mode"] == "emergency"
    assert out["closed_segments_excluded"] is True
    rec = out["recommended"]
    assert rec["recommended"] is True
    if rec["risk_pct"] >= 45:
        assert rec["warning"] and "EMERGENCY" in rec["warning"]

def test_stop_order_visits_all_stops_starting_at_first():
    stops = [(91.7, 26.1), (94.5, 25.6), (92.8, 27.0), (93.6, 26.7)]
    order = optimize_stop_order(stops)
    assert order[0] == 0 and sorted(order) == list(range(len(stops)))


def test_two_opt_beats_naive_zigzag():
    # deliberately zig-zag arrangement: naive insertion would alternate shores;
    # a clustered layout must end up cheaper than the reversed worst tour.
    stops = [(0.0, 0.0), (0.01, 0.0), (0.02, 0.0), (0.03, 0.0),
             (0.04, 0.0)]                       # collinear: optimal = sorted order
    order = optimize_stop_order(stops)
    def t(o):
        return sum(abs(stops[o[i]][0] - stops[o[i + 1]][0])
                   for i in range(len(o) - 1))
    assert t(order) <= t(list(range(len(stops)))) + 1e-9


def test_return_to_origin_appends_depot():
    stops = [(91.7, 26.1), (91.9, 26.15), (91.5, 26.05)]
    order = optimize_stop_order(stops, return_to_origin=True)
    assert order[0] == 0 and len(order) == len(stops)   # service appends depot


def test_emergency_mode_is_explicit_in_plan_shape(diamond):
    """Mode metadata must be machine-checkable (API contract test proxy)."""
    prof = mode_profile("emergency")
    assert prof["mode"] == "emergency"
    assert prof["distance_only"] is False



def test_unreachable_target_returns_none():
    g = SegmentGraph([_edge("X", 0, 1, 10, 90, 10)])
    assert g.dijkstra(0, 5, 0.5) is None


def test_blocked_segment_forces_alternative(diamond):
    base = diamond.dijkstra(0, 3, 0.0)
    alt = diamond.dijkstra(0, 3, 0.0, blocked={"A1"})
    assert [s.segment_id for s in base.segments] == ["A1", "A2"]
    assert "A1" not in [s.segment_id for s in alt.segments]
