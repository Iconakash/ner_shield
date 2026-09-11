"""Notification API: user-owned devices/preferences + inbox."""
from typing import Literal

from fastapi import APIRouter, Depends
from pydantic import BaseModel, Field
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.db import get_db
from app.core.security import Principal
from app.dependencies import get_principal
from app.notifications import service as ntf_svc
from app.notifications.providers import PROVIDERS

router = APIRouter(prefix="/notifications", tags=["notifications"])


class DeviceIn(BaseModel):
    channel: Literal["WEB_PUSH", "EMAIL", "SMS"]
    target: str = Field(min_length=3, max_length=320)
    label: str = Field(default="", max_length=120)


class PreferencesIn(BaseModel):
    channels: dict[str, bool] = Field(default_factory=dict)
    min_severity: Literal["INFO", "LOW", "MEDIUM", "HIGH", "CRITICAL"] = "LOW"


class AckIn(BaseModel):
    notification_id: str


@router.get("/channels")
async def channels():
    """Which channels exist and which are configured (no secrets returned)."""
    return {"channels": [
        {"id": ch, "configured": cls.is_configured()}
        for ch, cls in PROVIDERS.items()
    ]}


@router.post("/devices")
async def register_device(body: DeviceIn,
                          principal: Principal = Depends(get_principal),
                          db: AsyncSession = Depends(get_db)):
    return await ntf_svc.register_device(db, principal.user_id, body.channel,
                                         body.target, body.label)


@router.put("/preferences")
async def set_preferences(body: PreferencesIn,
                          principal: Principal = Depends(get_principal),
                          db: AsyncSession = Depends(get_db)):
    return await ntf_svc.set_preferences(db, principal.user_id,
                                         body.channels, body.min_severity)


@router.get("/preferences")
async def get_preferences(principal: Principal = Depends(get_principal),
                          db: AsyncSession = Depends(get_db)):
    return await ntf_svc.get_preferences(db, principal.user_id)


@router.get("")
async def inbox(unread_only: bool = False,
                principal: Principal = Depends(get_principal),
                db: AsyncSession = Depends(get_db)):
    items = await ntf_svc.list_my_notifications(db, principal.user_id,
                                                unread_only)
    return {"notifications": items, "unread": sum(
        1 for i in items if i["read_at"] is None)}


@router.post("/acknowledge")
async def acknowledge(body: AckIn,
                      principal: Principal = Depends(get_principal),
                      db: AsyncSession = Depends(get_db)):
    ok = await ntf_svc.acknowledge(db, principal.user_id, body.notification_id)
    if not ok:
        from app.core.errors import NotFound
        raise NotFound("notification not found or already read")
    return {"acknowledged": True}
