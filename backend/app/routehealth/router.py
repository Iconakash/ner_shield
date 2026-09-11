"""Route health + infrastructure gap API (SIH26002 P5).

  GET /routes/health            ranking (filters: state, district, order)
  GET /routes/health/gaps       critical infrastructure gaps (planning view)
  GET /routes/health/{segment}  one segment: score, components, trend windows
"""
from fastapi import APIRouter, Depends, Query
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.db import get_db
from app.dependencies import require_permissions
from app.routehealth import service as svc

router = APIRouter(prefix="/routes/health", tags=["route-health"])


@router.get("", dependencies=[Depends(require_permissions("VIEW_MAP"))])
async def ranking(db: AsyncSession = Depends(get_db),
                  state: str | None = Query(max_length=8),
                  district: str | None = Query(max_length=12),
                  order: str = Query(default="health",
                                     pattern="^(health|gaps|incidents)$"),
                  limit: int = Query(default=50, ge=1, le=200)):
    rows = await svc.ranking(db, state=state, district=district,
                             limit=limit, order=order)
    return {"segments": rows, "note": "ROUTE HEALTH != ROUTE RISK: health "
            "summarises historical reliability; live risk remains in "
            "/accessibility and /risk."}


@router.get("/gaps", dependencies=[Depends(require_permissions("VIEW_MAP"))])
async def gaps(db: AsyncSession = Depends(get_db),
               state: str | None = Query(max_length=8),
               district: str | None = Query(max_length=12),
               min_failures: int = Query(default=3, ge=1, le=50),
               limit: int = Query(default=50, ge=1, le=100)):
    return {"gaps": await svc.infrastructure_gaps(
        db, state=state, district=district, min_failures=min_failures,
        limit=limit)}


@router.get("/{segment_id}",
            dependencies=[Depends(require_permissions("VIEW_MAP"))])
async def segment(segment_id: str, db: AsyncSession = Depends(get_db)):
    from app.core.errors import NotFound
    res = await svc.segment_health(db, segment_id)
    if res is None:
        raise NotFound("road segment not found")
    return res
