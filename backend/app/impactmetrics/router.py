"""Impact analytics API (SIH26002 P7).

  GET /impact/summary        KPI block (every value labeled ESTIMATED/etc.)
  GET /impact/metrics        recent impact_metrics ledger entries

The summary endpoint computes from existing operational records only; nothing
here claims measured savings without a MEASURED basis row.
"""
from fastapi import APIRouter, Depends, Query
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.db import get_db
from app.dependencies import require_permissions
from app.impactmetrics import service as svc

router = APIRouter(prefix="/impact", tags=["impact-analytics"])


@router.get("/summary",
            dependencies=[Depends(require_permissions("VIEW_MAP"))])
async def summary(db: AsyncSession = Depends(get_db)):
    return await svc.summary(db)


@router.get("/metrics",
            dependencies=[Depends(require_permissions("VIEW_MAP"))])
async def metrics(db: AsyncSession = Depends(get_db),
                  limit: int = Query(default=50, ge=1, le=200)):
    return {"metrics": await svc.recent(db, limit=limit)}
