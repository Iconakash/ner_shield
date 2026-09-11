# -*- coding: utf-8 -*-
"""Decision Intelligence Assistant API (Phase 19 · FR-C23.1).

  GET /decisions/recommendations   ranked ACTION REQUIRED cards

Read-only DIA: every recommendation embeds its evidence links and, when the
two-person workflow is required, a ready-to-post /approvals dispatch template.
Approvals remain the SINGLE write path — this module never mutates state.
"""
from datetime import datetime, timezone

from fastapi import APIRouter, Depends
from sqlalchemy import text
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.db import get_db
from app.decisions import engine
from app.decisions.llm_advisory import explain_recommendations
from app.dependencies import require_permissions

router = APIRouter(prefix="/decisions", tags=["decisions"])


@router.get("/recommendations",
            dependencies=[Depends(require_permissions("VIEW_MAP"))])
async def recommendations(db: AsyncSession = Depends(get_db),
                          limit: int = 25, explain: bool = False):
    """Ranked ACTION REQUIRED list, RLS-scoped to the caller's geography.

    Signal scan (each capped; latest-prediction semantics match /command):
      1. active shipments intersecting HIGH/CRITICAL segments  -> reroute
      2. recent shortage predictions >= watchlist threshold    -> pre-position
      3. elevated segments still OPEN                          -> monitor
      4. recently CLOSED segments (accessibility degradation)  -> notify

    When `explain=true`, each card gains a natural-language `explanation`
    produced by the optional advisory layer (Phase 10 §10.3). The explanation
    is strictly advisory — it restates the deterministic decision and never
    invents risk scores, routes, or evidence. Requires no external service by
    default (deterministic template); uses an LLM only if LLM_ENDPOINT is set.
    """
    # -- 1) reroute candidates ------------------------------------------------
    ship_rows = (await db.execute(text("""
        select s.id::text as id, s.code, s.commodity::text as commodity,
               s.is_critical, s.dest_district, s.dest_state,
               dp.overall_label, dp.risk_current, dp.risk_24h,
               rs.id::text as segment_id, r.code as road_code
        from shipments s
        join road_segments rs on st_intersects(s.route_geom, rs.geom)
        join roads r on r.id = rs.road_id
        join lateral (
            select d.overall_label, d.risk_current, d.risk_24h
            from disruption_predictions d
            where d.target_type = 'ROAD_SEGMENT' and d.segment_id = rs.id
            order by d.computed_at desc limit 1
        ) dp on true
        where s.status::text in ('ROUTE_ASSIGNED', 'IN_TRANSIT')
          and dp.overall_label in ('HIGH', 'CRITICAL')
        order by dp.risk_current desc limit :cap
    """), {"cap": max(1, min(limit, 50))})).mappings().all()

    ships_at_risk = [
        ({k: row[k] for k in ("id", "code", "commodity", "is_critical",
                              "dest_district", "dest_state")},
         {"segment_id": row["segment_id"], "overall_label": row["overall_label"],
          "risk_current": float(row["risk_current"]),
          "risk_24h": float(row["risk_24h"]), "road_code": row["road_code"]})
        for row in ship_rows]

    # -- 2) pre-position candidates -------------------------------------------
    sp_rows = (await db.execute(text("""
        select distinct on (sp.inventory_id)
               sp.inventory_id::text as inventory_id, i.district_code,
               sp.commodity::text as commodity, sp.shortage_probability,
               sp.days_of_supply, i.daily_consumption,
               sp.expected_disruption_hours
        from shortage_predictions sp
        join inventory i on i.id = sp.inventory_id
        where sp.shortage_probability >= :prob
          and sp.computed_at > now() - make_interval(hours => 24)
        order by sp.inventory_id, sp.computed_at desc
        limit :cap
    """), {"prob": engine.PREPOSITION_MIN_PROBABILITY,
           "cap": max(1, min(limit, 50))})).mappings().all()
    shortage_rows = [dict(r) for r in sp_rows]
    for r in shortage_rows:
        r["shortage_probability"] = float(r["shortage_probability"])
        r["days_of_supply"] = float(r["days_of_supply"])
        r["daily_consumption"] = float(r["daily_consumption"])

    # -- 3) monitor candidates (elevated segment still OPEN) -------------------
    mon_rows = (await db.execute(text("""
        select distinct on (dp.segment_id)
               dp.segment_id::text as segment_id, dp.overall_label,
               dp.risk_current, dp.risk_24h,
               r.code as road_code, rs.district_code
        from disruption_predictions dp
        join road_segments rs on rs.id = dp.segment_id
        join roads r on r.id = rs.road_id
        where dp.target_type = 'ROAD_SEGMENT'
          and dp.overall_label in ('ELEVATED', 'HIGH', 'CRITICAL')
          and rs.status::text = 'OPEN'
        order by dp.segment_id, dp.computed_at desc limit :cap
    """), {"cap": max(1, min(limit, 50))})).mappings().all()
    monitor_preds = [{"segment_id": r["segment_id"],
                      "overall_label": r["overall_label"],
                      "risk_current": float(r["risk_current"]),
                      "risk_24h": float(r["risk_24h"]),
                      "road_code": r["road_code"],
                      "district_code": r["district_code"]}
                     for r in mon_rows]

    # -- 4) accessibility degradation (recent closures) -------------------------
    closed_rows = (await db.execute(text("""
        select rs.id::text as segment_id, r.code as road_code,
               rs.district_code, rs.state_code
        from road_segments rs
        join roads r on r.id = rs.road_id
        where rs.status::text in ('CLOSED', 'PARTIAL')
          and rs.updated_at > now() - make_interval(hours => 24)
        order by rs.updated_at desc limit :cap
    """), {"cap": max(1, min(limit, 50))})).mappings().all()
    closed_segments = [dict(r) | {"updated_recently": True}
                       for r in closed_rows]

    recs = engine.build_recommendations(
        ships_at_risk, shortage_rows, monitor_preds, closed_segments)
    recs = recs[:max(1, min(limit, 50))]
    if explain:
        # §10.3 optional advisory layer — pure, read-only, never mutates the
        # underlying recommendations (explain_recommendations copies each card).
        recs = explain_recommendations(recs)
    return {"recommendations": recs,
            "generated_at": datetime.now(timezone.utc).isoformat(),
            "contract": list(engine.REQUIRED_FIELDS)}
