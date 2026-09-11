"""Scoped audit trail reads (VIEW_AUDIT_LOG / SUPER_ADMIN). No mutations exist —
the table is append-only at the DB level (AUD-01)."""
from fastapi import APIRouter, Depends, Query
from sqlalchemy.ext.asyncio import AsyncSession

from app.audit import service as audit_service
from app.core.db import get_db
from app.dependencies import require_permissions

router = APIRouter(prefix="/audit", tags=["audit"])


@router.get("", dependencies=[Depends(require_permissions("VIEW_AUDIT_LOG"))])
async def list_audit(limit: int = Query(default=100, ge=1, le=500),
                     db: AsyncSession = Depends(get_db)):
    """Most recent audit events visible under the caller's authorization (RLS filters)."""
    return await audit_service.list_recent(db, limit)
