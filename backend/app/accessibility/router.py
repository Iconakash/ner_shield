"""Accessibility Intelligence API (Phase 5).

  POST /accessibility/signals   ingest factor observations   (MANAGE_SYSTEM)
  POST /accessibility/run       execute a scoring pass      (MANAGE_SYSTEM)
  POST /accessibility/weights   new calibratable version    (MANAGE_SYSTEM)
  GET  /accessibility/segments  latest per-segment scores   (VIEW_MAP)
  GET  /accessibility/districts latest district scores     (VIEW_MAP)
  GET  /accessibility/history   score history for segment  (VIEW_MAP)

All reads respect the standard security chain; scores are reference intelligence
readable by every authenticated role per baseline §4.4.
"""
import json
from typing import Literal, Optional

from fastapi import APIRouter, Depends, Query, Request
from pydantic import BaseModel, Field
from sqlalchemy import text
from sqlalchemy.ext.asyncio import AsyncSession

from app.accessibility import service as svc
from app.audit import service as audit
from app.core.db import get_db, get_system_db
from app.core.errors import NotFound
from app.dependencies import require_permissions

router = APIRouter(prefix="/accessibility", tags=["accessibility"])


class SignalIn(BaseModel):
    signal_kind: Literal["INFRASTRUCTURE", "WEATHER", "FLOOD_RISK",
                         "LANDSLIDE_RISK", "TRAFFIC", "HISTORICAL_RELIABILITY"]
    target_type: Literal["ROAD_SEGMENT", "DISTRICT"]
    segment_id: str | None = None
    district_code: str | None = None
    value: float = Field(ge=0, le=100)
    source: str = Field(min_length=1, max_length=80)


class SignalsBatch(BaseModel):
    signals: list[SignalIn] = Field(max_length=500)


class WeightsUpdate(BaseModel):
    weights: dict[str, float]
    bands: list[dict] | None = None


def _ip(request: Request):
    return request.client.host if request.client else None


@router.post("/signals", status_code=202,
             dependencies=[Depends(require_permissions("MANAGE_SYSTEM"))])
async def ingest_signals(body: SignalsBatch, request: Request,
                         principal=Depends(require_permissions("MANAGE_SYSTEM")),
                         system_db: AsyncSession = Depends(get_system_db)):
    """Feed-adapter landing point (C01 simulated drivers write here too)."""
    accepted = 0
    for s in body.signals:
        await system_db.execute(text("""
            insert into geo_factor_signals (signal_kind, target_type,
                segment_id, district_code, value, source)
            values (:k, :tt,
                    case when :tt = 'ROAD_SEGMENT' then cast(:seg as uuid) end,
                    case when :tt = 'DISTRICT' then :dist end, :v, :src)
        """), {"k": s.signal_kind, "tt": s.target_type, "seg": s.segment_id,
               "dist": s.district_code, "v": s.value, "src": s.source})
        accepted += 1
    await audit.emit(system_db, actor_id=principal.user_id,
                     actor_role=principal.role, action="SECURITY_EVENT",
                     outcome="SUCCESS", resource_type="acc_signals",
                     detail={"accepted": accepted}, ip=_ip(request))
    return {"accepted": accepted}

@router.post("/run")
async def run_scoring(request: Request,
                      principal=Depends(require_permissions("MANAGE_SYSTEM")),
                      system_db: AsyncSession = Depends(get_system_db)):
    """Execute one full scoring pass (scheduler calls this on the NFR-02 cadence)."""
    result = await svc.run_scoring(system_db)
    await audit.emit(system_db, actor_id=principal.user_id,
                     actor_role=principal.role, action="ANALYZE",
                     outcome="SUCCESS", resource_type="accessibility_run",
                     detail=result, ip=_ip(request))
    return result


@router.post("/weights")
async def update_weights(body: WeightsUpdate, request: Request,
                         principal=Depends(require_permissions("MANAGE_SYSTEM")),
                         db: AsyncSession = Depends(get_db),
                         system_db: AsyncSession = Depends(get_system_db)):
    """Publish a NEW calibration version (old versions retained for reproducibility)."""
    svc.validate_weights(body.weights)
    bands = body.bands or svc.DEFAULT_BANDS
    svc.validate_bands(bands)
    ver = (await db.execute(text(
        "select coalesce(max(version),0)+1 from accessibility_weights"))).scalar()
    await db.execute(text("""
        update accessibility_weights set is_active = false where is_active
    """))
    await db.execute(text("""
        insert into accessibility_weights (version, weights, bands, is_active,
                                           created_by)
        values (:v, cast(:w as jsonb), cast(:b as jsonb), true, cast(:u as uuid))
    """), {"v": ver, "w": json.dumps(body.weights),
           "b": json.dumps(bands), "u": principal.user_id})
    await audit.emit(db, actor_id=principal.user_id, actor_role=principal.role,
                     action="POLICY_CHANGE", outcome="SUCCESS",
                     resource_type="acc_weights_version", resource_id=str(ver),
                     detail={"weights": body.weights}, ip=_ip(request))
    return {"version": ver, "active": True}


@router.get("/segments", dependencies=[Depends(require_permissions("VIEW_MAP"))])
async def segment_scores(db: AsyncSession = Depends(get_db),
                         district_code: Optional[str] = None):
    rows = await svc.latest_scores(db, "ROAD_SEGMENT", district_code)
    if district_code and not rows:
        raise NotFound("no scores for that district yet — run the engine first")
    return rows


@router.get("/districts", dependencies=[Depends(require_permissions("VIEW_MAP"))])
async def district_scores(db: AsyncSession = Depends(get_db)):
    return await svc.latest_scores(db, "DISTRICT", None)


@router.get("/history", dependencies=[Depends(require_permissions("VIEW_MAP"))])
async def history(segment_id: str,
                  limit: int = Query(default=20, ge=1, le=200),
                  db: AsyncSession = Depends(get_db)):
    rows = await svc.history_for_segment(db, segment_id, limit)
    if not rows:
        raise NotFound("no score history for that segment")
    return rows

