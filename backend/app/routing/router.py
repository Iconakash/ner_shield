"""Risk-aware routing API (Phase 10 · C08). Advisory rankings — a human
LOGISTICS_OFFICER decides (AI-08); no route is auto-assigned here."""
from typing import Literal, Optional

from fastapi import APIRouter, Depends
from pydantic import BaseModel, Field

from app.core.db import get_db
from app.dependencies import require_permissions
from app.routing import service as routing_svc
from sqlalchemy import text
from sqlalchemy.ext.asyncio import AsyncSession


class Place(BaseModel):
    facility_code: Optional[str] = None
    lon: Optional[float] = None
    lat: Optional[float] = None


class PlanIn(BaseModel):
    origin: Place
    destination: Place
    priority: Literal["CRITICAL", "HIGH", "MEDIUM", "NORMAL"] | None = None
    risk_aversion: float | None = Field(default=None, ge=0.0, le=1.0)
    k: int = Field(default=3, ge=1, le=5)
    mode: Literal["shortest", "fastest", "safest", "balanced",
                  "emergency"] | None = None
    avoid_segment_ids: list[str] = Field(default_factory=list, max_length=50)


class Waypoint(BaseModel):
    facility_code: Optional[str] = None
    lon: Optional[float] = None
    lat: Optional[float] = None


class MultiStopIn(BaseModel):
    stops: list[Waypoint] = Field(min_length=2, max_length=25)
    priority: Literal["CRITICAL", "HIGH", "MEDIUM", "NORMAL"] | None = None
    mode: Literal["shortest", "fastest", "safest", "balanced",
                  "emergency"] | None = None
    risk_aversion: float | None = Field(default=None, ge=0.0, le=1.0)
    return_to_origin: bool = False


router = APIRouter(prefix="/routing", tags=["routing"])


@router.get("/modes")
async def routing_modes():
    """Machine-readable mode catalog for UI dropdowns (no auth-sensitive data,
    but kept behind the standard bearer gate by the global AuthGate)."""
    from app.routing.graph import (EMERGENCY_AVERSION, EMERGENCY_SPEED_BONUS)

    return {"modes": [
        {"id": "shortest", "description": "Minimize distance only"},
        {"id": "fastest", "description": "Minimize expected travel time"},
        {"id": "safest", "description": "Minimize disruption-risk exposure"},
        {"id": "balanced", "description": "Risk-aware blend; aversion from priority"},
        {"id": "emergency", "description":
            f"Time-first under active emergency ({EMERGENCY_SPEED_BONUS:.2f}x convoy "
            f"speed, aversion {EMERGENCY_AVERSION}); never uses CLOSED roads and "
            "flags every high-risk segment crossed"},
    ]}


async def _resolve_place(db: AsyncSession, p) -> tuple[float, float]:
    if p.facility_code:
        row = (await db.execute(text("""
            select st_x(geom) as lon, st_y(geom) as lat
            from facilities where code = :c
        """), {"c": p.facility_code})).mappings().first()
        if row is None:
            from app.core.errors import NotFound
            raise NotFound(f"facility '{p.facility_code}' not found")
        return float(row["lon"]), float(row["lat"])
    if p.lon is None or p.lat is None:
        from app.core.errors import AppError
        raise AppError("place needs facility_code or lon+lat")
    return p.lon, p.lat


@router.post("/plan", dependencies=[Depends(require_permissions("VIEW_MAP"))])
async def plan(body: PlanIn, db: AsyncSession = Depends(get_db)):
    o_lon, o_lat = await _resolve_place(db, body.origin)
    d_lon, d_lat = await _resolve_place(db, body.destination)
    return await routing_svc.plan_routes(
        db, o_lon, o_lat, d_lon, d_lat,
        priority=body.priority, risk_aversion=body.risk_aversion, k=body.k,
        mode=body.mode, avoid_segment_ids=body.avoid_segment_ids)


@router.post("/multi-stop", dependencies=[Depends(require_permissions("VIEW_MAP"))])
async def multi_stop(body: MultiStopIn, db: AsyncSession = Depends(get_db)):
    """Multi-stop delivery/reconnaissance plan: stop order + routed legs.
    Advisory only — dispatch remains a human decision (AI-08)."""
    coords = [await _resolve_place(db, w) for w in body.stops]
    return await routing_svc.plan_multi_stop(
        db, coords, priority=body.priority, mode=body.mode,
        risk_aversion=body.risk_aversion,
        return_to_origin=body.return_to_origin)


@router.get("/graph-snapshot",
            dependencies=[Depends(require_permissions("VIEW_MAP"))])
async def graph_snapshot(db: AsyncSession = Depends(get_db)):
    """ADDITIVE Phase 5 endpoint — offline routing support (master prompt §5).

    Returns the SAME edge list the authoritative /routing/plan engine uses
    (load_graph — identical accessibility/risk weights, zero semantic drift),
    plus the CLOSED segment list so the offline client knows what is closed.
    The client persists this snapshot locally and may plan offline with it;
    the server remains authoritative whenever connectivity exists.
    """
    return await routing_svc.graph_snapshot(db)

