"""Routing service: DB -> graph -> k alternatives -> ranked plan (C08).

ML prediction stays separate from the graph (source mandate): the risk numbers
attached to edges are read from stored predictions/accessibility; this module
never runs models.
"""

from sqlalchemy import text
from sqlalchemy.ext.asyncio import AsyncSession

from app.routing.geometry import merge_endpoints, snap_to_junction
from app.routing.graph import (
    HANDLING_OVERHEAD_H,
    PRIORITY_AVERSION,
    RouteResult,
    SegmentEdge,
    SegmentGraph,
    k_distinct_routes,
    mode_profile,
    optimize_stop_order,
)

# Risk labels that demand an explicit warning when a route uses them.
HIGH_RISK_LABELS = ("HIGH", "CRITICAL")


async def load_graph(db: AsyncSession) -> tuple[list[SegmentEdge], dict[tuple, int]]:
    """Fetch segments with latest accessibility score + disruption risk."""
    rows = (await db.execute(text("""
        select rs.id::text as segment_id, r.code as road_code, rs.seq,
               st_x(st_pointn(rs.geom, 1)) as x1,
               st_y(st_pointn(rs.geom, 1)) as y1,
               st_x(st_pointn(rs.geom, st_npoints(rs.geom))) as x2,
               st_y(st_pointn(rs.geom, st_npoints(rs.geom))) as y2,
               st_length(rs.geom::geography) / 1000.0 as length_km,
               coalesce(acc.score,
                   case acc.classification when 'SAFE' then 85
                        when 'CAUTION' then 60 when 'HIGH_RISK' then 35
                        else 15 end,
                   case rs.surface when 'PAVED' then 80
                        when 'RURAL' then 60 else 40 end) as accessibility,
               coalesce(pred.risk_24h,
                   case pred2.overall_label when 'CRITICAL' then 92
                        when 'HIGH' then 78 when 'ELEVATED' then 52
                        when 'GUARDED' then 28 else 12 end,
                   case acc.classification when 'SAFE' then 18
                        when 'CAUTION' then 45 when 'HIGH_RISK' then 72
                        else 90 end, 25) as risk_pct
        from road_segments rs
        join roads r on r.id = rs.road_id
        left join lateral (
            select score, classification from accessibility_scores a
            where a.segment_id = rs.id order by computed_at desc limit 1
        ) acc on true
        left join lateral (
            select risk_24h from disruption_predictions dp
            where dp.segment_id = rs.id order by computed_at desc limit 1
        ) pred on true
        left join lateral (
            select overall_label from disruption_predictions dp
            where dp.segment_id = rs.id order by computed_at desc limit 1
        ) pred2 on true
        where rs.status <> 'CLOSED'
    """))).mappings().all()

    raw_edges = [(r["segment_id"], r["road_code"], int(r["seq"]),
                  float(r["x1"]), float(r["y1"]),
                  float(r["x2"]), float(r["y2"]),
                  float(r["length_km"]),
                  max(0.0, min(100.0, float(r["accessibility"]))),
                  max(0.0, min(100.0, float(r["risk_pct"]))))
                 for r in rows]

    endpoints = []
    for i, (_, _, _, x1, y1, x2, y2, *_rest) in enumerate(raw_edges):
        endpoints.append((i, 0, x1, y1))
        endpoints.append((i, 1, x2, y2))
    junction_of = merge_endpoints(endpoints)

    edges = [
        SegmentEdge(segment_id=sid, road_code=code, seq=seq,
                    u=junction_of[(round(x1, 6), round(y1, 6))],
                    v=junction_of[(round(x2, 6), round(y2, 6))],
                    length_km=length_km, accessibility=acc, risk_pct=risk)
        for (sid, code, seq, x1, y1, x2, y2, length_km, acc, risk)
        in raw_edges
    ]
    # rebuild junction map keyed by junction id -> representative coordinate
    jcoords: dict[int, tuple[float, float]] = {}
    for (lon, lat), jid in junction_of.items():
        jcoords.setdefault(jid, (float(lon), float(lat)))
    return edges, jcoords


def default_aversion(priority: str | None) -> float:
    return PRIORITY_AVERSION.get(priority or "NORMAL", 0.65)

def _snap_map(jcoords: dict[int, tuple[float, float]]) -> dict[tuple, int]:
    """Invert {junction_id: (lon,lat)} into the orientation snap_to_junction
    expects ({(lon,lat): junction_id}). Fixes a latent inversion bug where
    /routing/plan always raised TypeError against a live graph."""
    return {coord: jid for jid, coord in jcoords.items()}


async def plan_routes(
    db: AsyncSession,
    origin_lon: float, origin_lat: float,
    dest_lon: float, dest_lat: float,
    priority: str | None = None,
    risk_aversion: float | None = None,
    k: int = 3,
    mode: str | None = None,
    avoid_segment_ids: list[str] | None = None,
) -> dict:
    """Rank k route options between two coordinates under a routing MODE.

    Modes: shortest | fastest | safest | balanced | emergency (graph.MODES).
    CLOSED segments are never loaded into the graph at all, so no mode can
    route through them. Explicitly avoided segment ids are hard-blocked.
    """
    edges, jcoords = await load_graph(db)
    if not edges:
        from app.core.errors import AppError
        raise AppError("routing graph empty — seed the GIS layer first")
    graph = SegmentGraph(edges)
    smap = _snap_map(jcoords)
    src = snap_to_junction(smap, origin_lon, origin_lat)
    dst = snap_to_junction(smap, dest_lon, dest_lat)
    if src is None or dst is None:
        from app.core.errors import NotFound
        raise NotFound("origin/destination could not be snapped to the road network")
    if src == dst:
        from app.core.errors import Conflict
        raise Conflict("origin and destination snap to the same network point")

    prof = mode_profile(mode, priority)
    if risk_aversion is not None and not prof["distance_only"]:
        prof["risk_aversion"] = max(0.0, min(1.0, float(risk_aversion)))
    ra = prof["risk_aversion"]
    blocked = set(avoid_segment_ids or [])

    routes = k_distinct_routes(
        graph, src, dst, ra, k=max(1, min(k, 5)),
        speed_mult=prof["speed_mult"], distance_only=prof["distance_only"])
    if not routes:
        from app.core.errors import NotFound
        raise NotFound("no reachable route between origin and destination "
                       "(check closures/avoided segments)")

    def _label(seg_id_prefix_risk: float) -> str:
        return risk_label_for(seg_id_prefix_risk)

    def _describe(res: RouteResult) -> dict:
        segs = [{"road_code": s.road_code, "seq": s.seq,
                 "segment_id": s.segment_id,
                 "accessibility": round(s.accessibility, 1),
                 "risk_pct": s.risk_pct} for s in res.segments]
        warnings = [s["segment_id"] for s in segs
                    if risk_label_for(s["risk_pct"]) in HIGH_RISK_LABELS]
        if prof["mode"] == "emergency" and warnings:
            note = ("EMERGENCY corridor crosses high-risk segments — "
                    "clearance/advisory required before dispatch")
        elif warnings:
            note = "route crosses high-risk segments"
        else:
            note = None
        return {"distance_km": res.distance_km,
                "eta_hours": res.travel_hours,
                "eta_display": _fmt_eta(res.travel_hours),
                "risk_pct": res.risk_pct,
                "risk_label": risk_label_for(res.risk_pct),
                "cost": res.cost,
                "high_risk_segments": warnings,
                "warning": note,
                "segments": segs}

    ranked = sorted((_describe(r) for r in routes), key=lambda x: x["cost"])
    for i, r in enumerate(ranked):
        r["rank"] = i + 1
        r["recommended"] = i == 0

    fastest = min(ranked, key=lambda r: r["eta_hours"]) if ranked else None
    safest = min(ranked, key=lambda r: r["risk_pct"]) if ranked else None
    rec = ranked[0] if ranked else None
    narrative = None
    if rec and fastest and safest:
        if fastest is rec:
            narrative = (f"Route {rec['rank']} is both the fastest "
                         f"({rec['eta_display']}) and lowest-cost option at "
                         f"{rec['risk_pct']:.0f}% risk.")
        else:
            narrative = (
                f"Chosen route balances reliability and time: "
                f"{rec['eta_display']} at {rec['risk_pct']:.0f}% risk versus the "
                f"fastest option ({fastest['eta_display']} but "
                f"{fastest['risk_pct']:.0f}% risk). Safest available: "
                f"{safest['eta_display']} at {safest['risk_pct']:.0f}%.")
    return {
        "mode": prof["mode"],
        "risk_aversion": ra,
        "avoided_segments": sorted(blocked),
        "closed_segments_excluded": True,
        "recommended": rec,
        "alternatives": ranked,
        "fastest": fastest,
        "safest": safest,
        "narrative": narrative,
    }


async def plan_multi_stop(
    db: AsyncSession,
    stops_lonlat: list[tuple[float, float]],
    priority: str | None = None,
    mode: str | None = None,
    risk_aversion: float | None = None,
    return_to_origin: bool = False,
) -> dict:
    """Visit all stops starting at stop 0 (optionally returning to it).

    Ordering heuristic (graph.optimize_stop_order) + real road-graph legs.
    Every leg obeys the same closure/avoid rules as single-pair planning;
    an unroutable leg fails the WHOLE plan explicitly (no silent skip).
    """
    if len(stops_lonlat) < 2:
        from app.core.errors import AppError
        raise AppError("multi-stop plan needs at least 2 stops")

    edges, jcoords = await load_graph(db)
    if not edges:
        from app.core.errors import AppError
        raise AppError("routing graph empty — seed the GIS layer first")
    graph = SegmentGraph(edges)
    prof = mode_profile(mode, priority)
    if risk_aversion is not None and not prof["distance_only"]:
        prof["risk_aversion"] = max(0.0, min(1.0, float(risk_aversion)))
    ra = prof["risk_aversion"]

    snapped: list[int | None] = [
        snap_to_junction(_snap_map(jcoords), lon, lat)
        for lon, lat in stops_lonlat]
    unsnapped = [i for i, j in enumerate(snapped) if j is None]
    if unsnapped:
        from app.core.errors import NotFound
        raise NotFound(f"stops could not be snapped to the network: {unsnapped}")

    order_idx = optimize_stop_order(
        [(stops_lonlat[i][0], stops_lonlat[i][1])
         for i in range(len(stops_lonlat))],
        return_to_origin=return_to_origin)

    legs = []
    seq = [0] + order_idx[1:]
    if return_to_origin:
        seq.append(0)

    total_km = total_h = total_risk_km = 0.0
    for a, b in zip(seq, seq[1:]):
        ja, jb = snapped[a], snapped[b]
        if ja == jb:
            legs.append({"from_stop": a, "to_stop": b, "distance_km": 0.0,
                         "eta_hours": HANDLING_OVERHEAD_H, "risk_pct": 0.0,
                         "segments": [], "high_risk_segments": [],
                         "warning": None})
            continue
        res = graph.dijkstra(ja, jb, ra, speed_mult=prof["speed_mult"],
                             distance_only=prof["distance_only"])
        if res is None:
            from app.core.errors import NotFound
            raise NotFound(f"no route between stop {a} and stop {b} — "
                           "plan rejected (closures may isolate a stop)")
        seg_ids = [s.segment_id for s in res.segments]  # noqa: F841 (evidence list)
        hi = [s.segment_id for s in res.segments
              if risk_label_for(s.risk_pct) in HIGH_RISK_LABELS]
        legs.append({"from_stop": a, "to_stop": b,
                     "distance_km": res.distance_km,
                     "eta_hours": res.travel_hours,
                     "eta_display": _fmt_eta(res.travel_hours),
                     "risk_pct": res.risk_pct,
                     "segments": [{"road_code": s.road_code, "seq": s.seq,
                                   "segment_id": s.segment_id,
                                   "risk_pct": round(s.risk_pct, 1)}
                                  for s in res.segments],
                     "high_risk_segments": hi,
                     "warning": ("leg crosses high-risk segments" if hi else None)})
        total_km += res.distance_km
        total_h += res.travel_hours
        # length-weighted risk accumulation across the whole tour
        leg_len = sum(s.length_km for s in res.segments) or 1.0
        total_risk_km += res.risk_pct * leg_len

    return {
        "mode": prof["mode"],
        "stop_order": seq,
        "legs": legs,
        "totals": {"distance_km": round(total_km, 2),
                   "eta_hours": round(total_h, 2),
                   "eta_display": _fmt_eta(total_h),
                   "avg_risk_pct": round(total_risk_km / (total_km or 1.0), 1)},
        "warnings": [l["warning"] for l in legs if l["warning"]],
    }


def risk_label_for(risk_pct: float) -> str:
    if risk_pct >= 85:
        return "CRITICAL"
    if risk_pct >= 70:
        return "HIGH"
    if risk_pct >= 45:
        return "ELEVATED"
    if risk_pct >= 20:
        return "GUARDED"
    return "LOW"


async def graph_snapshot(db: AsyncSession) -> dict:
    """Phase 5 — offline routing snapshot (ADDITIVE; reuses load_graph).

    Open segments come from load_graph() verbatim (same accessibility/risk
    weights as /routing/plan — the offline engine must mirror the online
    engine, not diverge from it). Closed segments are listed separately for
    informational display; they are never routable (load_graph already
    excludes them).
    """
    from datetime import datetime, timezone

    edges, jcoords = await load_graph(db)
    open_segments = [
        {
            "segment_id": e.segment_id,
            "road_code": e.road_code,
            "seq": e.seq,
            "x1": jcoords[e.u][0],
            "y1": jcoords[e.u][1],
            "x2": jcoords[e.v][0],
            "y2": jcoords[e.v][1],
            "length_km": e.length_km,
            "accessibility": e.accessibility,
            "risk_pct": e.risk_pct,
            "status": "OPEN",
        }
        for e in edges
    ]
    closed_rows = (
        await db.execute(text("""
            select rs.id::text as segment_id, r.code as road_code, rs.seq,
                   st_x(st_pointn(rs.geom, 1)) as x1,
                   st_y(st_pointn(rs.geom, 1)) as y1,
                   st_x(st_pointn(rs.geom, st_npoints(rs.geom))) as x2,
                   st_y(st_pointn(rs.geom, st_npoints(rs.geom))) as y2
            from road_segments rs
            join roads r on r.id = rs.road_id
            where rs.status = 'CLOSED'
        """))
    ).mappings().all()
    closed_segments = [
        {"segment_id": r["segment_id"], "road_code": r["road_code"],
         "seq": int(r["seq"]), "x1": float(r["x1"]), "y1": float(r["y1"]),
         "x2": float(r["x2"]), "y2": float(r["y2"]), "status": "CLOSED"}
        for r in closed_rows
    ]
    return {
        "fetched_at": datetime.now(timezone.utc).isoformat(),
        "open_segments": open_segments,
        "closed_segments": closed_segments,
    }


def _fmt_eta(hours: float) -> str:
    total_minutes = int(round(hours * 60))
    return f"{total_minutes // 60}h{total_minutes % 60:02d}"

