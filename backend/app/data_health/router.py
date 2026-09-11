"""Data-health endpoints. Readable by any authenticated map user (the Command
Center embeds this); writes flow only through workers/system connection."""
from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.db import get_db
from app.core.security import Principal
from app.dependencies import require_permissions

router = APIRouter(prefix="/data-health", tags=["data-health"])


@router.get("")
async def data_health(
    principal: Principal = Depends(require_permissions("VIEW_MAP")),
    db: AsyncSession = Depends(get_db),
):
    """Freshness/health of every critical data source (master upgrade §35).

    Each row exposes: status, enabled, last_success_at, freshness class
    (LIVE/RECENT/STALE/UNAVAILABLE), confidence, and license note.
    Sources pending authorization are explicitly labeled — never shown as live.
    """
    from app.data_health import service as svc

    sources = await svc.list_sources(db)
    return {
        "title": "DATA SOURCE HEALTH",
        "sources": sources,
        "summary": {
            "total": len(sources),
            "live": sum(1 for s in sources if s["freshness"] == "LIVE"),
            "stale": sum(1 for s in sources if s["freshness"] == "STALE"),
            "unavailable": sum(1 for s in sources if s["freshness"] == "UNAVAILABLE"),
        },
    }
