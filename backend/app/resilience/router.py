# -*- coding: utf-8 -*-
"""Resilience Score API (Phase 22 · C20 · FR-C20.1).

  GET /resilience/districts         ranked composite scores + component
                                    breakdown for every district in the
                                    caller's RLS scope (most fragile first)
  GET /resilience/districts/{code}  one district's breakdown

Read-only awareness surface (mirrors Phase-18 Command Center): aggregation
runs on the CALLER'S RLS-scoped connection so a DISTRICT_OFFICER sees their
district while REGIONAL_AUTHORITY sees the whole region. No audit emit —
pure reads, no engine side effects.
"""

from fastapi import APIRouter, Depends
from sqlalchemy import text
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.db import get_db
from app.core.errors import NotFound
from app.dependencies import require_permissions
from app.resilience import engine

router = APIRouter(prefix="/resilience", tags=["resilience"])

# grouped inputs for the pure engine — one aggregate query per source table
_SEGMENTS_SQL = text("""
    select rs.district_code,
           count(*)::int as total_segments,
           count(*) filter (where rs.status::text = 'OPEN')::int
               as open_segments,
           avg(acc.score) as avg_accessibility,
           avg(gf.flood_susceptibility) as avg_flood_susceptibility,
           avg(gf.landslide_susceptibility) as avg_landslide_susceptibility
    from road_segments rs
    left join lateral (
        select a.score from accessibility_scores a
        where a.segment_id = rs.id
        order by a.computed_at desc limit 1
    ) acc on true
    left join segment_geo_features gf on gf.segment_id = rs.id
    where rs.district_code is not null
    group by rs.district_code
""")

_SUPPLY_SQL = text("""
    select i.district_code,
           avg(case when i.daily_consumption > 0 then
                    least(999.0, greatest(0.0,
                        (i.available_quantity - i.reserved_quantity)
                        / i.daily_consumption))
                else 999.0 end) as avg_days_of_supply
    from inventory i
    where i.district_code is not null
    group by i.district_code
""")

_FACILITIES_SQL = text("""
    select f.district_code,
           count(*) filter (where f.facility_type = 'HOSPITAL')::int
               as hospitals,
           count(*) filter (where f.facility_type = 'WAREHOUSE')::int
               as warehouses
    from facilities f
    where f.district_code is not null
    group by f.district_code
""")

_VEHICLES_SQL = text("""
    select v.home_district as district_code, count(*)::int
               as available_vehicles
    from vehicles v
    where v.status::text = 'AVAILABLE' and v.home_district is not null
    group by v.home_district
""")

_WEATHER_SQL = text("""
    select distinct on (w.district_code)
           w.district_code, w.rainfall_mm_24h,
           w.forecast_rainfall_mm_24h as forecast_mm_24h
    from weather_feed w
    where w.district_code is not null
    order by w.district_code, w.observed_at desc
""")


async def _inputs(db: AsyncSession):
    seg = (await db.execute(_SEGMENTS_SQL)).mappings().all()
    sup = (await db.execute(_SUPPLY_SQL)).mappings().all()
    fac = (await db.execute(_FACILITIES_SQL)).mappings().all()
    veh = (await db.execute(_VEHICLES_SQL)).mappings().all()
    wx = (await db.execute(_WEATHER_SQL)).mappings().all()
    return ([dict(r) for r in seg], [dict(r) for r in sup],
            [dict(r) for r in fac], [dict(r) for r in veh],
            [dict(r) | {"rainfall_mm_24h": float(r["rainfall_mm_24h"] or 0.0),
                        "forecast_mm_24h":
                            float(r["forecast_mm_24h"] or 0.0)}
             for r in wx])


@router.get("/districts",
            dependencies=[Depends(require_permissions("VIEW_MAP"))])
async def resilience_districts(db: AsyncSession = Depends(get_db)):
    districts = (await db.execute(text(
        "select d.code, d.name from districts d order by d.code"
    ))).mappings().all()
    segments, supply, facilities, vehicles, weather = await _inputs(db)
    return engine.compute([dict(d) for d in districts],
                          segments, supply, weather, facilities, vehicles)


@router.get("/districts/{code}",
            dependencies=[Depends(require_permissions("VIEW_MAP"))])
async def resilience_one(code: str, db: AsyncSession = Depends(get_db)):
    row = (await db.execute(text(
        "select d.code, d.name from districts d where d.code = :c"),
        {"c": code})).mappings().first()
    if row is None:
        raise NotFound(f"unknown district '{code}'")
    segments, supply, facilities, vehicles, weather = await _inputs(db)
    result = engine.compute([dict(row)], segments, supply, weather,
                            facilities, vehicles)
    return result["districts"][0]
