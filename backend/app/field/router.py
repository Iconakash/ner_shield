"""Field Intelligence API (Phase 13) — the extremely simple officer surface.

  POST /field/reports                 SUBMIT (FIELD_OFFICER, CREATE_INCIDENT)
  GET  /field/reports/queue           validation queue   (VERIFY_INCIDENT)
  POST /field/reports/{id}/validate    VALIDATED / REJECTED (VERIFY_INCIDENT)
"""
import time
from typing import Literal

from fastapi import APIRouter, Depends, Request
from pydantic import BaseModel, Field
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.db import get_db, get_system_db
from app.core.security import Principal
from app.dependencies import get_principal, require_permissions
from app.field import service as field_svc

router = APIRouter(prefix="/field", tags=["field"])


class ReportIn(BaseModel):
    incident_type: Literal["LANDSLIDE", "FLOOD", "ROAD_DAMAGE",
                           "TRAFFIC_BLOCKAGE", "BRIDGE_PROBLEM", "OTHER"]
    severity: Literal["LOW", "MEDIUM", "HIGH", "CRITICAL"]
    lon: float = Field(ge=80.0, le=98.0)
    lat: float = Field(ge=21.0, le=29.5)
    description: str = Field(default="", max_length=2000)
    photo_name: str | None = Field(default=None, max_length=260)
    client_op_id: str | None = Field(default=None, max_length=120)
    gps_accuracy_m: float | None = Field(default=None, ge=0.0, le=9999.0)
    observed_at: str | None = Field(default=None, max_length=40)  # ISO-8601


class ValidationIn(BaseModel):
    decision: Literal["VALIDATED", "REJECTED"]
    note: str | None = Field(default=None, max_length=500)


@router.post("/reports", status_code=201,
             dependencies=[Depends(require_permissions("CREATE_INCIDENT"))])
async def submit_report(body: ReportIn, request: Request,
                        principal: Principal = Depends(get_principal),
                        db: AsyncSession = Depends(get_db)):
    """SUBMIT — one call does everything: location resolve, segment snap,
    confidence scoring, persistence. Offline replays are idempotent."""
    return await field_svc.submit_report(
        db, principal=principal, incident_type=body.incident_type,
        severity=body.severity, lon=body.lon, lat=body.lat,
        description=body.description,
        photo_ref=f"queued:{body.photo_name}" if body.photo_name else None,
        client_op_id=body.client_op_id,
        gps_accuracy_m=body.gps_accuracy_m,
        observed_at_iso=body.observed_at)


@router.get("/reports/queue",
            dependencies=[Depends(require_permissions("VERIFY_INCIDENT"))])
async def validation_queue(db: AsyncSession = Depends(get_db)):
    """SUBMITTED reports awaiting a scoped validator's decision."""
    return await field_svc.inbox_reports(db)


@router.post("/reports/{report_id}/validate")
async def validate(report_id: str, body: ValidationIn,
                   principal: Principal = Depends(
                       require_permissions("VERIFY_INCIDENT")),
                   db: AsyncSession = Depends(get_db),
                   system_db: AsyncSession = Depends(get_system_db)):
    """VALIDATION step; on VALIDATED this drives the entire downstream loop
    (signals -> accessibility -> risk -> route ETAs -> alert)."""
    return await field_svc.validate_report(
        system_db, db, report_id=report_id, validator=principal,
        decision=body.decision, note=body.note)


@router.get("/reports/mine")
async def my_reports(principal: Principal = Depends(get_principal),
                     db: AsyncSession = Depends(get_db)):
    from sqlalchemy import text
    rows = (await db.execute(text("""
        select code, incident_type::text as incident_type,
               severity::text as severity, status::text as status,
               confidence, created_at
        from field_reports where reported_by = cast(:u as uuid)
        order by created_at desc limit 100
    """), {"u": principal.user_id})).mappings().all()
    return [dict(r) for r in rows]


# ------------------------------------------------ P2 (SIH26002): reporter trust
@router.get("/reporters/{reporter_id}/trust")
async def get_trust(reporter_id: str,
                    principal: Principal = Depends(get_principal),
                    db: AsyncSession = Depends(get_db)):
    """Reporter trust ledger — visible to the reporter themselves and to
    officials with incident-verification rights."""
    if str(principal.user_id) != reporter_id \
            and "VERIFY_INCIDENT" not in principal.permissions:
        from app.core.errors import ForbiddenRole
        raise ForbiddenRole("trust ledger is visible to the reporter or "
                            "verification officials only")
    return await field_svc.reporter_trust(db, reporter_id)


@router.get("/reports/{report_id}/detail",
            dependencies=[Depends(require_permissions("VIEW_INCIDENTS"))])
async def report_detail(report_id: str,
                        db: AsyncSession = Depends(get_db)):
    """Report + confidence breakdown + reporter trust + media references
    (single read for the validation/detail view; §20-style card)."""
    from sqlalchemy import text

    rep = (await db.execute(text("""
        select fr.id::text as id, fr.code, fr.reported_by::text as reported_by,
               fr.incident_type::text as incident_type,
               fr.severity::text as severity, fr.description, fr.photo_ref,
               fr.state_code, fr.district_code, fr.confidence,
               fr.confidence_components, fr.status::text as status,
               fr.validation_note, fr.corroboration_count, fr.created_at,
               st_asgeojson(fr.geom)::json as geo
        from field_reports fr where fr.id = cast(:i as uuid)
    """), {"i": report_id})).mappings().first()
    if rep is None:
        from app.core.errors import NotFound
        raise NotFound("report not found")
    out = dict(rep)
    out["components"] = (rep["confidence_components"] if isinstance(
        rep["confidence_components"], dict) else None)
    out.pop("confidence_components", None)
    out["reporter_trust"] = await field_svc.reporter_trust(
        db, rep["reported_by"])
    from app.media import service as media_svc
    out["media"] = await media_svc.list_media(db, report_id)
    return out


def _unused_time_guard():  # pragma: no cover
    return time
