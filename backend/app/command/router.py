# -*- coding: utf-8 -*-
"""Command Center API (Phase 18 · FR-C16.1).

  GET /command/summary          six actionable KPI tiles (one query)
  GET /command/layers/{name}    live map layers as GeoJSON FeatureCollections

Read-only awareness surface (FR-C16.1): every route runs the standard security
chain with VIEW_MAP — the caller's RLS scope drives drill-down automatically,
so a DISTRICT-scoped officer sees only their district's picture.
"""
from datetime import datetime, timezone

from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession

from app.command import service as cmd_svc
from app.core.db import get_db
from app.core.errors import NotFound
from app.dependencies import require_permissions

router = APIRouter(prefix="/command", tags=["command"])


@router.get("/summary", dependencies=[Depends(require_permissions("VIEW_MAP"))])
async def summary(db: AsyncSession = Depends(get_db)):
    """The frozen six tiles. Counts are RLS-scoped to the caller's geography."""
    result = await cmd_svc.summary(db)
    result["generated_at"] = datetime.now(timezone.utc).isoformat()
    return result


@router.get("/layers/{name}", dependencies=[Depends(require_permissions("VIEW_MAP"))])
async def map_layer(name: str, db: AsyncSession = Depends(get_db)):
    """GeoJSON FeatureCollection for one operational layer.

    Hospitals / Warehouses reuse /gis/facilities?facility_type=... — no
    duplication of reference-geography reads here.
    """
    builder = cmd_svc.LAYER_BUILDERS.get(name)
    if builder is None:
        raise NotFound(
            f"unknown layer '{name}'",
            detail={"known": sorted(cmd_svc.LAYER_BUILDERS)})
    return await builder(db)
