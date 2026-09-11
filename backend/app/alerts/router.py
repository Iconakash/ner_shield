"""Alert inbox + lifecycle API (Phase 12). Escalation sweep is a system hook."""
from typing import Literal

from fastapi import APIRouter, Depends, Query, Request
from pydantic import BaseModel, Field
from sqlalchemy.ext.asyncio import AsyncSession

from app.alerts import service as alert_svc
from app.audit import service as audit
from app.core.db import get_db, get_system_db
from app.core.security import Principal
from app.dependencies import get_principal, require_permissions

router = APIRouter(prefix="/alerts", tags=["alerts"])


class AlertCreate(BaseModel):
    level: Literal["INFO", "WARNING", "HIGH", "CRITICAL"]
    alert_type: Literal["ROAD_WARNING", "CRITICAL_SHIPMENT",
                        "REGIONAL_SUPPLY_CRISIS", "DISRUPTION_PREDICTED",
                        "SHORTAGE_PREDICTED", "IMPACT_ALERT", "SYSTEM"]
    title: str = Field(min_length=3, max_length=200)
    message: str = Field(default="", max_length=2000)
    state_code: str | None = None
    district_code: str | None = None
    segment_id: str | None = None
    shipment_id: str | None = None
    payload: dict = Field(default_factory=dict)


def _ip(request: Request):
    return request.client.host if request.client else None


@router.post("", status_code=201,
             dependencies=[Depends(require_permissions("MANAGE_SYSTEM"))])
async def create_alert(body: AlertCreate, request: Request,
                       principal=Depends(require_permissions("MANAGE_SYSTEM")),
                       system_db: AsyncSession = Depends(get_system_db)):
    """Engine/admin creation point. Engines call alert_svc.create_alert directly."""
    result = await alert_svc.create_alert(
        system_db, level=body.level, alert_type=body.alert_type,
        title=body.title, message=body.message,
        state_code=body.state_code, district_code=body.district_code,
        segment_id=body.segment_id, shipment_id=body.shipment_id,
        payload=body.payload)
    await audit.emit(system_db, actor_id=principal.user_id,
                     actor_role=principal.role, action="ALERT_CREATED",
                     outcome="SUCCESS", resource_type="alert",
                     resource_id=result["id"],
                     detail={"level": body.level, "type": body.alert_type},
                     ip=_ip(request))
    return {**result, "title": body.title}


@router.get("/inbox")
async def inbox(principal: Principal = Depends(get_principal),
                db: AsyncSession = Depends(get_db),
                limit: int = Query(default=100, ge=1, le=300),
                lang: str | None = Query(default=None)):
    """Alerts currently awaiting THIS officer's role within their geography.

    Phase 17: localized title/message/emergency-instruction fields are added
    per FR-C15.1 (?lang= > profile language); canonical English is preserved.
    """
    from app.dependencies import _client_ip  # noqa: F401 (scope helper reuse)
    from app.i18n import service as i18n_svc
    resolved = i18n_svc.resolve_lang(request=None, principal=principal,
                                     explicit=lang)
    state = principal.scopes[0].state_code if principal.scopes else None
    district = next((s.district_code for s in principal.scopes
                     if s.level == "DISTRICT"), None)
    rows = await alert_svc.inbox(db, principal.role, state, district, limit)
    return [{**row, **i18n_svc.localized_alert(row, resolved)} for row in rows]


@router.post("/{alert_id}/acknowledge")
async def acknowledge(alert_id: str, request: Request,
                      principal: Principal = Depends(get_principal),
                      system_db: AsyncSession = Depends(get_system_db)):
    result = await alert_svc.acknowledge(system_db, alert_id,
                                         principal.user_id, principal.role)
    await audit.emit(system_db, actor_id=principal.user_id,
                     actor_role=principal.role, action="ALERT_ACKNOWLEDGED",
                     outcome="SUCCESS", resource_type="alert",
                     resource_id=alert_id, ip=_ip(request))
    return result


@router.post("/{alert_id}/resolve")
async def resolve(alert_id: str, note: str | None = None,
                  request: Request = None,
                  principal: Principal = Depends(get_principal),
                  system_db: AsyncSession = Depends(get_system_db)):
    result = await alert_svc.resolve(system_db, alert_id,
                                     principal.user_id, principal.role, note)
    await audit.emit(system_db, actor_id=principal.user_id,
                     actor_role=principal.role, action="ALERT_RESOLVED",
                     outcome="SUCCESS", resource_type="alert",
                     resource_id=alert_id, detail={"note": note}, ip=_ip(request))
    return result


@router.post("/escalation-sweep",
             dependencies=[Depends(require_permissions("MANAGE_SYSTEM"))])
async def escalation_sweep(request: Request,
                           principal=Depends(require_permissions("MANAGE_SYSTEM")),
                           system_db: AsyncSession = Depends(get_system_db)):
    """Scheduler hook (NFR/FR-C11.2): promote overdue unacknowledged alerts."""
    return await alert_svc.escalation_sweep(system_db)
