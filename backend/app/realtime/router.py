"""SSE stream endpoint. Authenticated + permission-filtered per subscriber."""
import asyncio

from fastapi import APIRouter, Depends
from fastapi.responses import StreamingResponse
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.db import get_db
from app.core.security import Principal
from app.dependencies import get_principal, require_permissions
from app.realtime.bus import bus

router = APIRouter(prefix="/realtime", tags=["realtime"])


@router.get("/stream")
async def stream(principal: Principal = Depends(get_principal),
                 db: AsyncSession = Depends(get_db)):
    """Server-Sent Events feed: gps/shipment/alert/risk/task/data-health
    updates, each filtered against the subscriber's permissions server-side.
    Sensitive payloads are NEVER sent to unauthorized subscribers."""
    sid = bus.subscribe()

    def has_permission(perm: str) -> bool:
        return perm in principal.permissions

    async def gen_with_cleanup():
        try:
            async for chunk in bus.stream(sid, has_permission):
                yield chunk
        except asyncio.CancelledError:
            pass
        finally:
            bus.unsubscribe(sid)

    return StreamingResponse(gen_with_cleanup(), media_type="text/event-stream",
                             headers={"Cache-Control": "no-cache",
                                      "X-Accel-Buffering": "no"})


@router.get("/status")
async def status(principal: Principal = Depends(require_permissions("VIEW_MAP"))):
    """Operational view of the realtime channel (subscriber count only)."""
    return {"subscribers": bus.subscriber_count,
            "published_total": bus.published_count,
            "dropped_total": bus.dropped_count}
