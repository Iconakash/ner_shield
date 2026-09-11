# -*- coding: utf-8 -*-
"""Route Redundancy API (Phase 23 · C21 · FR-C21.1).

  GET /redundancy/districts         per-district Primary / Alternative /
                                    Emergency route counts + redundancy
                                    level, most fragile first
  GET /redundancy/districts/{code}  one district's corridor breakdown

Read-only awareness surface (mirrors Phase-18 Command Center / Phase-22
Resilience): aggregation runs on the CALLER'S RLS-scoped connection.
Corridors are the same roads the Phase-10 routing graph is built from —
latest accessibility score + latest disruption risk per segment.
"""
from fastapi import APIRouter, Depends
from sqlalchemy import text
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.db import get_db
from app.core.errors import NotFound
from app.dependencies import require_permissions
from app.redundancy import engine

router = APIRouter(prefix="/redundancy", tags=["redundancy"])

_CORRIDORS_SQL = text("""
    select rs.district_code, r.code as road_code,
           count(*)::int as total_segments,
           count(*) filter (where rs.status::text = 'OPEN')::int
               as open_segments,
           avg(coalesce(pred.risk_24h, pred2_implied.risk, 25.0)) as avg_risk,
           avg(acc.score) as avg_accessibility
    from road_segments rs
    join roads r on r.id = rs.road_id
    left join lateral (
        select a.score from accessibility_scores a
        where a.segment_id = rs.id
        order by a.computed_at desc limit 1
    ) acc on true
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
    ) pred2_implied on true
    where rs.district_code is not null
    group by rs.district_code, r.code
""")


@router.get("/districts",
            dependencies=[Depends(require_permissions("VIEW_MAP"))])
async def redundancy_districts(db: AsyncSession = Depends(get_db)):
    districts = (await db.execute(text(
        "select d.code, d.name from districts d order by d.code"
    ))).mappings().all()
    rows = (await db.execute(_CORRIDORS_SQL)).mappings().all()
    return engine.compute([dict(d) for d in districts],
                          [dict(r) for r in rows])


@router.get("/districts/{code}",
            dependencies=[Depends(require_permissions("VIEW_MAP"))])
async def redundancy_one(code: str, db: AsyncSession = Depends(get_db)):
    district = (await db.execute(text(
        "select d.code, d.name from districts d where d.code = :c"),
        {"c": code})).mappings().first()
    if district is None:
        raise NotFound(f"unknown district '{code}'")
    rows = (await db.execute(_CORRIDORS_SQL)).mappings().all()
    result = engine.compute([dict(district)],
                            [dict(r) for r in rows])
    return result["districts"][0]
