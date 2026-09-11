"""Action Center task API (master upgrade §22)."""
from typing import Literal, Optional

from fastapi import APIRouter, Depends
from pydantic import BaseModel, Field
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.db import get_db
from app.core.security import Principal
from app.dependencies import require_permissions
from app.tasks import service as task_svc

router = APIRouter(prefix="/tasks", tags=["tasks"])


def _principal():
    from app.dependencies import get_principal
    return get_principal


class TaskCreateIn(BaseModel):
    title: str = Field(min_length=3, max_length=200)
    description: str = Field(default="", max_length=4000)
    priority: Literal["LOW", "MEDIUM", "HIGH", "CRITICAL"] = "MEDIUM"
    source_type: Optional[Literal["ALERT", "INCIDENT", "SHIPMENT",
                                  "RISK", "SUPPLY", "MANUAL"]] = None
    source_id: Optional[str] = None
    district_code: Optional[str] = None
    state_code: Optional[str] = None
    template_code: Optional[str] = None
    recommendation_ref: Optional[str] = None


class AssignIn(BaseModel):
    assignee_id: str = Field(min_length=8)
    note: str | None = None


class TransitionIn(BaseModel):
    to_status: Literal["ASSIGNED", "ACCEPTED", "IN_PROGRESS", "BLOCKED",
                       "COMPLETED", "VERIFIED", "CLOSED", "CANCELLED"]
    note: str | None = Field(default=None, max_length=2000)


@router.post("", dependencies=[Depends(require_permissions("REQUEST_REROUTE"))])
async def create_task(body: TaskCreateIn,
                      principal: Principal = Depends(require_permissions(
                          "REQUEST_REROUTE")),
                      db: AsyncSession = Depends(get_db)):
    """Create a task (optionally from an alert/incident/shipment/risk source).
    Creating does NOT execute anything: work happens only when humans act."""
    return await task_svc.create_task(
        db, principal, title=body.title, description=body.description,
        priority=body.priority, source_type=body.source_type,
        source_id=body.source_id, state_code=body.state_code,
        district_code=body.district_code, template_code=body.template_code,
        recommendation_ref=body.recommendation_ref)


@router.get("/mine")
async def my_tasks(principal: Principal = Depends(_principal()),
                   db: AsyncSession = Depends(get_db)):
    return {"tasks": await task_svc.list_my_tasks(db, principal)}


@router.post("/{task_id}/assign")
async def assign(task_id: str, body: AssignIn,
                 principal: Principal = Depends(require_permissions(
                     "APPROVE_REROUTE")),
                 db: AsyncSession = Depends(get_db)):
    """Assign/reassign. Requires APPROVE_REROUTE-grade authority."""
    await task_svc.transition(db, principal, task_id, "ASSIGNED",
                              note=body.note)
    return {"id": task_id, "status": "ASSIGNED"}


@router.post("/{task_id}/transition")
async def do_transition(task_id: str, body: TransitionIn,
                        principal: Principal = Depends(require_permissions(
                            "VIEW_MAP")),
                        db: AsyncSession = Depends(get_db)):
    """Lifecycle move; the service enforces who may set what."""
    return await task_svc.transition(db, principal, task_id, body.to_status,
                                     note=body.note)


@router.get("/{task_id}")
async def get_task(task_id: str,
                   principal: Principal = Depends(require_permissions(
                       "VIEW_MAP")),
                   db: AsyncSession = Depends(get_db)):
    t = await task_svc.get_task(db, task_id)
    if t is None:
        from app.core.errors import NotFound
        raise NotFound("task not found")
    return t
