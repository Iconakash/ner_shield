# -*- coding: utf-8 -*-
"""What-if simulator API (Phase 20 · FR-C18.1).

  POST /simulation/what-if   inject a hypothetical event into the CURRENT
                             world-state snapshot -> mandated 8-stage cascade

Read-only by design: a what-if must never contaminate live operational data.
The snapshot is gathered on the CALLER'S RLS-scoped connection, so an officer
simulates their own geography. Every run is audited as ANALYZE.
"""
from typing import Literal, Optional

from fastapi import APIRouter, Depends, Request
from pydantic import BaseModel, Field
from sqlalchemy import text
from sqlalchemy.ext.asyncio import AsyncSession

from app.audit import service as audit
from app.core.db import get_db
from app.dependencies import get_principal, require_permissions
from app.simulation import engine

router = APIRouter(prefix="/simulation", tags=["simulation"])

MAX_SEGMENTS = 60


class WhatIfIn(BaseModel):
    event_type: Literal["HEAVY_RAINFALL", "LANDSLIDE", "FLOOD"]
    intensity: Literal["LOW", "MODERATE", "SEVERE", "EXTREME"]
    duration_hours: int = Field(default=12, ge=1, le=168)
    district_code: Optional[str] = None     # None = caller's whole scope

@router.post("/what-if",
             dependencies=[Depends(require_permissions("VIEW_MAP"))])
async def what_if(body: WhatIfIn, request: Request,
                  principal=Depends(get_principal),
                  db: AsyncSession = Depends(get_db)):
    # -- world state: modeled segments + terrain susceptibility ---------------
    seg_rows = (await db.execute(text("""
        select rs.id::text as segment_id, r.code as road_code,
               rs.district_code,
               coalesce(dp.risk_current, 25) as baseline_risk,
               coalesce(acc.score, 75) as baseline_acc,
               coalesce(gf.flood_susceptibility, 50) as flood_susceptibility,
               coalesce(gf.landslide_susceptibility, 50)
                   as landslide_susceptibility,
               coalesce(rs.length_m, 20000) / 1000.0 as length_km,
               greatest(0, (
                   select count(*) from road_segments o2
                   where o2.district_code = rs.district_code
                     and o2.status::text = 'OPEN'
               ) - 1) as alternates
        from road_segments rs
        join roads r on r.id = rs.road_id
        left join segment_geo_features gf on gf.segment_id = rs.id
        left join lateral (
            select d.risk_current from disruption_predictions d
            where d.target_type = 'ROAD_SEGMENT' and d.segment_id = rs.id
            order by d.computed_at desc limit 1
        ) dp on true
        left join lateral (
            select a.score from accessibility_scores a
            where a.segment_id = rs.id
            order by a.computed_at desc limit 1
        ) acc on true
        where (:d is null or rs.district_code = :d)
        order by dp.risk_current desc nulls last
        limit :cap
    """), {"d": body.district_code, "cap": MAX_SEGMENTS})).mappings().all()
    segments = [dict(r) | {
        "baseline_risk": float(r["baseline_risk"]),
        "baseline_acc": float(r["baseline_acc"]),
        "length_km": float(r["length_km"])} for r in seg_rows]

    # -- active shipments whose routes cross the simulated segments ----------
    ship_rows = (await db.execute(text("""
        select distinct on (s.id)
               s.id::text as id, s.code, s.commodity::text as commodity,
               s.is_critical, s.dest_district,
               coalesce(s.base_eta_minutes, 120) as normal_eta_minutes,
               round(st_length(st_intersection(s.route_geom, rs.geom))
                     ::numeric / 1000, 2) as exposed_length_km,
               rs.id::text as segment_id
        from shipments s
        join road_segments rs on st_intersects(s.route_geom, rs.geom)
        where s.status::text in ('ROUTE_ASSIGNED', 'IN_TRANSIT')
          and s.route_geom is not null
          and (:d is null or s.dest_district = :d
               or rs.district_code = :d)
        order by s.id, rs.seq limit :cap
    """), {"d": body.district_code, "cap": MAX_SEGMENTS})).mappings().all()
    shipments = [dict(r) | {"normal_eta_minutes":
                                float(r["normal_eta_minutes"]),
                            "exposed_length_km":
                                float(r["exposed_length_km"] or 25.0)}
                 for r in ship_rows]

    # -- inventory stock points in the region ----------------------------------
    inv_rows = (await db.execute(text("""
        select i.district_code,
               i.commodity::text as commodity,
               case when i.daily_consumption > 0
                    then least(999.0, greatest(0.0,
                         (i.available_quantity - i.reserved_quantity)
                         / i.daily_consumption))
                    else 999.0 end as days_of_supply,
               i.daily_consumption, i.incoming_quantity
        from inventory i
        where (:d is null or i.district_code = :d)
        order by i.daily_consumption desc limit :cap
    """), {"d": body.district_code, "cap": MAX_SEGMENTS})).mappings().all()
    inventory = [dict(r) | {"days_of_supply": float(r["days_of_supply"]),
                            "daily_consumption":
                                float(r["daily_consumption"]),
                            "incoming_quantity":
                                float(r["incoming_quantity"])}
                 for r in inv_rows]

    result = engine.simulate(body.event_type, body.intensity,
                             body.duration_hours, segments, shipments,
                             inventory)

    await audit.emit(db, actor_id=principal.user_id,
                     actor_role=principal.role, action="ANALYZE",
                     outcome="SUCCESS", resource_type="simulation",
                     detail={"event_type": body.event_type,
                             "intensity": body.intensity,
                             "duration_hours": body.duration_hours,
                             "district_code": body.district_code},
                     ip=request.client.host if request.client else None)
    return result


