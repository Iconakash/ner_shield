"""GPS endpoints.

* /devices            — admin registration (MANAGE_SYSTEM), secret shown once
* /devices/{c}/rotate — credential rotation (MANAGE_SYSTEM)
* /ingest             — DEVICE-authenticated telemetry (no user JWT); strict
                        per-device rate limiting + replay/spoof protection
"""
from fastapi import APIRouter, Depends, Header, Request
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.db import get_system_db
from app.core.security import Principal
from app.dependencies import require_permissions
from app.gps import service as gps
from app.gps.schemas import DeviceRegistrationIn, TelemetryIn

router = APIRouter(prefix="/gps", tags=["gps"])


@router.post("/devices")
async def register_device(
    body: DeviceRegistrationIn,
    principal: Principal = Depends(require_permissions("MANAGE_SYSTEM")),
    system_db: AsyncSession = Depends(get_system_db),
):
    return await gps.register_device(system_db, principal, body)


@router.post("/devices/{device_code}/credentials/rotate")
async def rotate_credentials(
    device_code: str,
    principal: Principal = Depends(require_permissions("MANAGE_SYSTEM")),
    system_db: AsyncSession = Depends(get_system_db),
):
    return await gps.rotate_credential(system_db, principal, device_code)


@router.post("/ingest")
async def ingest(
    body: TelemetryIn,
    request: Request,
    x_device_code: str | None = Header(default=None),
    x_device_secret: str | None = Header(default=None),
    system_db: AsyncSession = Depends(get_system_db),
):
    """Self-authenticated device path (excluded from the bearer gate in
    main.PUBLIC_PATHS). Credentials + replay + spoof checks all enforced here."""
    device = await gps.authenticate_device(system_db, x_device_code, x_device_secret)
    return await gps.ingest(system_db, device, body)
