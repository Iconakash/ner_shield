"""Disruption Prediction API (Phase 6).

  POST /risk/weather   ingest rainfall/forecast observations (MANAGE_SYSTEM)
  POST /risk/run       full prediction pass, 5 horizons     (MANAGE_SYSTEM)
  GET  /risk/latest    latest predictions w/ explanations   (VIEW_MAP)
"""
from typing import Literal, Optional

from fastapi import APIRouter, Depends, Query, Request
from pydantic import BaseModel, Field
from sqlalchemy import text
from sqlalchemy.ext.asyncio import AsyncSession

from app.audit import service as audit
from app.core.db import get_db, get_system_db
from app.core.errors import NotFound
from app.dependencies import ensure_geo_scope, get_principal, require_permissions
from app.risk import service as risk_svc

router = APIRouter(prefix="/risk", tags=["risk"])


class WeatherIn(BaseModel):
    segment_id: str | None = None
    district_code: str | None = None
    rainfall_mm_24h: float = Field(ge=0, le=500)
    forecast_rainfall_mm_24h: float = Field(ge=0, le=500)
    source: str = Field(min_length=1, max_length=80)


class WeatherBatch(BaseModel):
    observations: list[WeatherIn] = Field(max_length=500)


def _ip(request: Request):
    return request.client.host if request.client else None


@router.post("/weather", status_code=202,
             dependencies=[Depends(require_permissions("MANAGE_SYSTEM"))])
async def ingest_weather(body: WeatherBatch, request: Request,
                         principal=Depends(require_permissions("MANAGE_SYSTEM")),
                         system_db: AsyncSession = Depends(get_system_db)):
    accepted = 0
    for obs in body.observations:
        await system_db.execute(text("""
            insert into weather_feed (segment_id, district_code,
                rainfall_mm_24h, forecast_rainfall_mm_24h, source)
            values (case when :seg is null then null else cast(:seg as uuid) end,
                    :dist, :rain, :fcast, :src)
        """), {"seg": obs.segment_id, "dist": obs.district_code,
               "rain": obs.rainfall_mm_24h,
               "fcast": obs.forecast_rainfall_mm_24h, "src": obs.source})
        accepted += 1
    await audit.emit(system_db, actor_id=principal.user_id,
                     actor_role=principal.role, action="SECURITY_EVENT",
                     outcome="SUCCESS", resource_type="weather_feed",
                     detail={"accepted": accepted}, ip=_ip(request))
    return {"accepted": accepted}


@router.post("/run")
async def run_predictions(request: Request,
                          principal=Depends(require_permissions("MANAGE_SYSTEM")),
                          system_db: AsyncSession = Depends(get_system_db)):
    """Full-region disruption prediction pass (scheduler hook, NFR-02 cadence)."""
    result = await risk_svc.run_prediction_pass(system_db)
    await audit.emit(system_db, actor_id=principal.user_id,
                     actor_role=principal.role, action="ANALYZE",
                     outcome="SUCCESS", resource_type="disruption_run",
                     detail=result, ip=_ip(request))
    return result


@router.get("/latest", dependencies=[Depends(require_permissions("VIEW_MAP"))])
async def latest(db: AsyncSession = Depends(get_db),
                 district_code: Optional[str] = Query(default=None)):
    rows = await risk_svc.latest_predictions(db, district_code)
    if not rows:
        raise NotFound("no predictions yet — run the engine first")
    return rows


@router.get("/{segment_id}/explain",
            dependencies=[Depends(require_permissions("VIEW_MAP"))])
async def explain(segment_id: str, db: AsyncSession = Depends(get_db)):
    """Local WHY explanation: base value, full signed factor vector, narrative."""
    item = await risk_svc.explain_segment(db, segment_id)
    if item is None:
        raise NotFound("no prediction for this segment — run the engine first")
    return item


@router.get("/why-route/{shipment_id}",
            dependencies=[Depends(require_permissions("VIEW_SHIPMENTS"))])
async def why_route(shipment_id: str, request: Request,
                    principal=Depends(get_principal),
                    horizon: Literal["current", "6h", "12h", "24h", "72h"]
                    = Query(default="24h"),
                    db: AsyncSession = Depends(get_db)):
    """'Why will this route fail?' — aggregates predictions + accessibility
    along the shipment's assigned route into a verdict and narrative."""
    from app.core.errors import AppError, NotFound as NF
    from app.shipments import service as ship_svc

    shipment = await ship_svc.get_shipment(db, shipment_id)
    if shipment is None:
        raise NF("shipment not found or outside your geographic scope")
    await ensure_geo_scope(principal, shipment["dest_state"],
                           shipment["dest_district"], db, request)
    if not shipment["route_road_id"]:
        raise AppError("shipment has no assigned route to explain")

    rows = await risk_svc.route_segments_with_intel(db, shipment_id, horizon)
    result = risk_svc.summarize_route(rows, horizon)
    result.update({"shipment_id": shipment_id,
                   "road_code": shipment["road_code"] or
                   (rows[0]["road_code"] if rows else None),
                   "segments": [{k: r.get(k) for k in
                                 ("seq", "district_name", "acc_classification",
                                  "risk_pct", "overall_label", "all_factors")}
                                for r in rows]})
    return result
