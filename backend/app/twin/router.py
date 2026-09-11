# -*- coding: utf-8 -*-
"""Logistics digital twin API (Phase 21 · FR-C19.1).

  GET  /twin/state    live twin snapshot over the caller's RLS scope + t=0
                      assessment (affected shipments, ETA changes, alternate
                      routes, shortage, critical cargo, recommended actions)
  POST /twin/replay   headless forward run — advance the twin clock and return
                      the trajectory + final assessment (twin state is
                      replayable per FR-C19.1; nothing is persisted)

Read-only by design (mirrors Phase-20 simulation): the snapshot is gathered on
the CALLER'S RLS-scoped connection so an officer twins their own geography.
Every call is audited as ANALYZE.
"""
import json
from typing import Optional

from fastapi import APIRouter, Depends, Request
from pydantic import BaseModel, Field
from sqlalchemy import text
from sqlalchemy.ext.asyncio import AsyncSession

from app.audit import service as audit
from app.core.db import get_db
from app.dependencies import get_principal, require_permissions
from app.twin import engine

router = APIRouter(prefix="/twin", tags=["twin"])

MAX_ROWS = 60


async def _snapshot(db: AsyncSession, district: Optional[str]) -> dict:
    """Gather the RLS-scoped world state for engine.build()."""
    d, cap = district, MAX_ROWS

    seg_rows = (await db.execute(text("""
        select rs.id::text as segment_id, r.code as road_code,
               rs.district_code, rs.status::text as status,
               coalesce(dp.risk_current, 25) as baseline_risk,
               dp.risk_current as live_risk,
               dp.overall_label as label,
               coalesce(rs.length_m, 20000) / 1000.0 as length_km
        from road_segments rs
        join roads r on r.id = rs.road_id
        left join lateral (
            select p.risk_current, p.overall_label
            from disruption_predictions p
            where p.target_type = 'ROAD_SEGMENT' and p.segment_id = rs.id
            order by p.computed_at desc limit 1
        ) dp on true
        where (:d is null or rs.district_code = :d)
        order by dp.risk_current desc nulls last
        limit :cap
    """), {"d": d, "cap": cap})).mappings().all()
    segments = [dict(r) | {
        "baseline_risk": float(r["baseline_risk"]),
        "length_km": float(r["length_km"]),
        "live_risk": float(r["live_risk"]) if r["live_risk"] is not None else None}
        for r in seg_rows]
    disruptions = [{"segment_id": s["segment_id"],
                    "risk_current": s["live_risk"],
                    "label": s.get("label")}
                   for s in segments if s["live_risk"] is not None]

    ship_rows = (await db.execute(text("""
        select s.id::text as id, s.code, s.commodity::text as commodity,
               s.is_critical, s.dest_district,
               s.vehicle_id::text as vehicle_id,
               coalesce(s.eta_minutes, 120) as eta_minutes,
               array_agg(distinct rs.id::text) as segment_ids
        from shipments s
        join road_segments rs on st_intersects(s.route_geom, rs.geom)
        where s.status::text in ('ROUTE_ASSIGNED', 'IN_TRANSIT')
          and s.route_geom is not null
          and (:d is null or s.dest_district = :d or rs.district_code = :d)
        group by s.id, s.code, s.commodity, s.is_critical, s.dest_district,
                 s.vehicle_id, s.eta_minutes
        limit :cap
    """), {"d": d, "cap": cap})).mappings().all()
    shipments = [dict(r) | {"eta_minutes": float(r["eta_minutes"] or 120.0)}
                 for r in ship_rows]

    veh_rows = (await db.execute(text("""
        select v.id::text as id, v.code, v.vtype::text as vtype,
               v.status::text as status, v.home_district as district
        from vehicles v
        where (:d is null or v.home_district = :d)
        limit :cap
    """), {"d": d, "cap": cap})).mappings().all()

    wh_rows = (await db.execute(text("""
        select f.id::text as facility_id, f.code, f.name, f.district_code,
               coalesce(inv.items, '[]'::json)::text as inventory_json
        from facilities f
        left join lateral (
            select json_agg(json_build_object(
                       'commodity', i.commodity::text,
                       'days_of_supply',
                           case when i.daily_consumption > 0 then
                               least(999.0, greatest(0.0,
                                   (i.available_quantity - i.reserved_quantity)
                                   / i.daily_consumption))
                           else 999.0 end,
                       'daily_consumption', i.daily_consumption,
                       'incoming_quantity', i.incoming_quantity)) as items
            from inventory i
            where i.facility_id = f.id
              and (:d is null or i.district_code = :d)
        ) inv on true
        where f.facility_type = 'WAREHOUSE'
          and (:d is null or f.district_code = :d)
        limit :cap
    """), {"d": d, "cap": cap})).mappings().all()
    warehouses = [dict(r) | {"inventory": json.loads(r["inventory_json"])}
                  for r in wh_rows]

    hosp_rows = (await db.execute(text("""
        select f.id::text as facility_id, f.code, f.name, f.district_code
        from facilities f
        where f.facility_type = 'HOSPITAL'
          and (:d is null or f.district_code = :d)
        limit :cap
    """), {"d": d, "cap": cap})).mappings().all()

    dist_rows = (await db.execute(text("""
        select dd.code, dd.name from districts dd
        where (:d is null or dd.code = :d)
        limit :cap
    """), {"d": d, "cap": cap})).mappings().all()

    weather_rows = (await db.execute(text("""
        select wf.district_code,
               wf.rainfall_mm_24h,
               wf.forecast_rainfall_mm_24h as forecast_mm_24h
        from (
            select distinct on (w.district_code) w.*
            from weather_feed w
            where w.district_code is not null
              and (:d is null or w.district_code = :d)
            order by w.district_code, w.observed_at desc
        ) wf
    """), {"d": d})).mappings().all()
    weather = [dict(w) | {
        "rainfall_mm_24h": float(w["rainfall_mm_24h"] or 0.0),
        "forecast_mm_24h": float(w["forecast_mm_24h"] or 0.0)}
        for w in weather_rows]

    return engine.build(
        segments=segments, vehicles=[dict(v) for v in veh_rows],
        warehouses=warehouses, hospitals=[dict(h) for h in hosp_rows],
        districts=[dict(x) for x in dist_rows], shipments=shipments,
        weather=weather, disruptions=disruptions)


class ReplayIn(BaseModel):
    horizon_minutes: int = Field(default=360, ge=15, le=2016)
    step_minutes: int = Field(default=60, ge=5, le=360)
    district_code: Optional[str] = None     # None = caller's whole scope


@router.get("/state",
            dependencies=[Depends(require_permissions("VIEW_MAP"))])
async def twin_state(request: Request, principal=Depends(get_principal),
                     db: AsyncSession = Depends(get_db)):
    twin = await _snapshot(db, None)
    await audit.emit(db, actor_id=principal.user_id,
                     actor_role=principal.role, action="ANALYZE",
                     outcome="SUCCESS", resource_type="twin",
                     detail={"view": "state"},
                     ip=request.client.host if request.client else None)
    return twin | {"assessment": engine.assess(twin)}


@router.post("/replay",
             dependencies=[Depends(require_permissions("VIEW_MAP"))])
async def twin_replay(body: ReplayIn, request: Request,
                      principal=Depends(get_principal),
                      db: AsyncSession = Depends(get_db)):
    twin = await _snapshot(db, body.district_code)
    result = engine.run(twin, body.horizon_minutes, body.step_minutes)
    await audit.emit(db, actor_id=principal.user_id,
                     actor_role=principal.role, action="ANALYZE",
                     outcome="SUCCESS", resource_type="twin",
                     detail={"view": "replay",
                             "horizon_minutes": body.horizon_minutes,
                             "step_minutes": body.step_minutes,
                             "district_code": body.district_code},
                     ip=request.client.host if request.client else None)
    return result
