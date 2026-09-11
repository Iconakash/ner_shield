# -*- coding: utf-8 -*-
"""Critical Corridor Ranking API (Phase 24 · C22 · FR-C22.1).

  GET /corridors/ranking         ranked table by strategic criticality
                                 (population x goods x hospitals x scarcity
                                 x disruption), most critical first
  GET /corridors/ranking/export  the same table as CSV (FR-C22.1 exportable)
  GET /corridors/ranking/{code}  one corridor's factor breakdown

Read-only awareness surface on the CALLER'S RLS-scoped connection.
"""
from fastapi import APIRouter, Depends
from fastapi.responses import Response
from sqlalchemy import text
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.db import get_db
from app.core.errors import NotFound
from app.dependencies import require_permissions
from app.corridors import engine

router = APIRouter(prefix="/corridors", tags=["corridors"])

_CORRIDORS_SQL = text("""
    select r.id::text as road_id, r.code as road_code, r.name,
           count(*)::int as total_segments,
           count(*) filter (where rs.status::text = 'OPEN')::int
               as open_segments,
           avg(coalesce(pred.risk_24h, implied.risk)) as avg_risk
    from roads r
    join road_segments rs on rs.road_id = r.id
    left join lateral (
        select d.risk_24h from disruption_predictions d
        where d.target_type = 'ROAD_SEGMENT' and d.segment_id = rs.id
        order by d.computed_at desc limit 1
    ) pred on true
    left join lateral (
        select case p.overall_label when 'CRITICAL' then 92.0
                    when 'HIGH' then 78.0 when 'ELEVATED' then 52.0
                    when 'GUARDED' then 28.0 else 12.0 end as risk
        from disruption_predictions p
        where p.target_type = 'ROAD_SEGMENT' and p.segment_id = rs.id
        order by p.computed_at desc limit 1
    ) implied on true
    group by r.id, r.code, r.name
""")

_SERVING_SQL = text("""
    select distinct rs.road_id::text as road_id, rs.district_code
    from road_segments rs
    where rs.district_code is not null
""")

_POPULATION_SQL = text("""
    select c.district_code, sum(c.population)::bigint as population
    from communities c
    where c.district_code is not null
    group by c.district_code
""")

_HOSPITALS_SQL = text("""
    select f.district_code, count(*)::int as hospitals
    from facilities f
    where f.facility_type = 'HOSPITAL' and f.district_code is not null
    group by f.district_code
""")

_SHIPMENTS_SQL = text("""
    select rs.road_id::text as road_id,
           count(*) filter (where s.is_critical)::int as critical_shipments,
           count(*) filter (where not s.is_critical)::int as other_shipments
    from shipments s
    join road_segments rs on st_intersects(s.route_geom, rs.geom)
    where s.status::text in ('ROUTE_ASSIGNED', 'IN_TRANSIT')
      and s.route_geom is not null
    group by rs.road_id
""")


async def _inputs(db: AsyncSession):
    corridors = (await db.execute(_CORRIDORS_SQL)).mappings().all()
    serving = (await db.execute(_SERVING_SQL)).mappings().all()
    pops = (await db.execute(_POPULATION_SQL)).mappings().all()
    hosps = (await db.execute(_HOSPITALS_SQL)).mappings().all()
    ships = (await db.execute(_SHIPMENTS_SQL)).mappings().all()
    return (
        [dict(r) | {"avg_risk": (float(r["avg_risk"])
                                 if r["avg_risk"] is not None else None)}
         for r in corridors],
        [dict(r) for r in serving],
        {r["district_code"]: int(r["population"]) for r in pops},
        {r["district_code"]: int(r["hospitals"]) for r in hosps},
        [dict(r) for r in ships])


async def _ranking(db: AsyncSession) -> dict:
    corridors, serving, pops, hosps, ships = await _inputs(db)
    return engine.compute(pops, hosps, corridors, serving, ships)


@router.get("/ranking",
            dependencies=[Depends(require_permissions("VIEW_MAP"))])
async def corridor_ranking(db: AsyncSession = Depends(get_db)):
    return await _ranking(db)


@router.get("/ranking/export",
            dependencies=[Depends(require_permissions("VIEW_MAP"))])
async def corridor_ranking_export(db: AsyncSession = Depends(get_db)):
    """FR-C22.1: the ranked table, exportable as CSV."""
    csv_text = engine.to_csv(await _ranking(db))
    return Response(
        content=csv_text,
        media_type="text/csv; charset=utf-8",
        headers={"Content-Disposition":
                 "attachment; filename=ner-shield-corridor-ranking.csv"})


@router.get("/ranking/{code}",
            dependencies=[Depends(require_permissions("VIEW_MAP"))])
async def corridor_one(code: str, db: AsyncSession = Depends(get_db)):
    ranking = await _ranking(db)
    row = next((r for r in ranking["corridors"]
                if r["road_code"] == code), None)
    if row is None:
        raise NotFound(f"unknown corridor '{code}'")
    return row
