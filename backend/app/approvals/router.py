"""Two-person approval workflow.

Covers the four mandated critical actions: EMERGENCY_REROUTE,
MAJOR_SUPPLY_REDISTRIBUTION, HIGH_LEVEL_ALERT, CRITICAL_LOGISTICS_STATUS.
Server-side rules: requester != approver; approver needs the action's approval
permission AND geographic scope over the target area; every transition audited.
Transitions run on the system connection with explicit checks here — clients can
never UPDATE approval rows directly (RLS denies it too).
"""
import json
from typing import Literal

from fastapi import APIRouter, Depends, Request
from pydantic import BaseModel, Field
from sqlalchemy import text
from sqlalchemy.ext.asyncio import AsyncSession

from app.audit import service as audit
from app.core.db import get_db, get_system_db
from app.core.errors import Conflict, ForbiddenRole, NotFound
from app.core.security import APPROVAL_WORKFLOW_PERMISSIONS, Principal
from app.dependencies import ensure_geo_scope, get_principal

router = APIRouter(prefix="/approvals", tags=["approvals"])

ActionType = Literal["EMERGENCY_REROUTE", "MAJOR_SUPPLY_REDISTRIBUTION",
                     "HIGH_LEVEL_ALERT", "CRITICAL_LOGISTICS_STATUS"]


class ApprovalRequestIn(BaseModel):
    action_type: ActionType
    title: str = Field(min_length=3, max_length=200)
    payload: dict = Field(default_factory=dict)
    state_code: str | None = None
    district_code: str | None = None


class DecisionIn(BaseModel):
    decision: Literal["APPROVED", "REJECTED", "CANCELLED"]
    note: str | None = Field(default=None, max_length=500)


def _ip(request: Request):
    return request.client.host if request.client else None


@router.post("", status_code=201)
async def request_approval(body: ApprovalRequestIn, request: Request,
                           principal: Principal = Depends(get_principal),
                           db: AsyncSession = Depends(get_db),
                           system_db: AsyncSession = Depends(get_system_db)):
    req_perm, _appr_perm = APPROVAL_WORKFLOW_PERMISSIONS[body.action_type]
    await ensure_geo_scope(principal, body.state_code or "*", body.district_code, db, request)
    if not principal.has_permissions([req_perm]):
        await audit.emit(db, actor_id=principal.user_id, actor_role=principal.role,
                         action="PERMISSION_DENIED", outcome="DENIED",
                         resource_type="approval_request",
                         detail={"missing": req_perm}, ip=_ip(request))
        raise ForbiddenRole(f"requires {req_perm}")

    row = (await system_db.execute(text(
        "insert into approval_requests (action_type, title, payload, org_id,"
        " state_code, district_code, requested_by)"
        " values (cast(:t as approval_action), :title, cast(:p as jsonb),"
        " cast(:o as uuid), :s, :d, cast(:u as uuid)) returning id"),
        {"t": body.action_type, "title": body.title, "p": json.dumps(body.payload),
         "o": principal.org_id, "s": body.state_code,
         "d": body.district_code, "u": principal.user_id}
    )).mappings().first()
    rid = str(row["id"])
    await audit.emit(system_db, actor_id=principal.user_id, actor_role=principal.role,
                     action="APPROVAL_REQUESTED", outcome="SUCCESS",
                     resource_type="approval", resource_id=rid,
                     detail={"action_type": body.action_type}, ip=_ip(request))
    return {"id": rid, "status": "PENDING"}

@router.post("/{approval_id}/decide")
async def decide_approval(approval_id: str, body: DecisionIn, request: Request,
                          principal: Principal = Depends(get_principal),
                          db: AsyncSession = Depends(get_db),
                          system_db: AsyncSession = Depends(get_system_db)):
    row = (await system_db.execute(text(
        "select id::text as id, action_type::text as action_type, status::text as status,"
        " requested_by::text as requested_by, state_code, district_code"
        " from approval_requests where id = cast(:i as uuid)"), {"i": approval_id}
    )).mappings().first()
    if row is None:
        raise NotFound("approval request not found")
    if row["status"] != "PENDING":
        raise Conflict(f"request already {row['status']}")

    _req_perm, appr_perm = APPROVAL_WORKFLOW_PERMISSIONS[row["action_type"]]
    await ensure_geo_scope(principal, row["state_code"] or "*",
                           row["district_code"], db, request)
    if not principal.has_permissions([appr_perm]):
        raise ForbiddenRole(f"requires {appr_perm}")
    if principal.user_id == row["requested_by"]:
        # two-person rule: the requester can never decide their own request
        raise Conflict("requester cannot approve their own request")
    if body.decision == "CANCELLED":
        if principal.user_id != row["requested_by"]:
            raise ForbiddenRole("only the requester may cancel")

    new_status = body.decision
    await system_db.execute(text(
        "update approval_requests set status = cast(:st as approval_status),"
        " approver_id = cast(:a as uuid), decision_note = :n,"
        " decided_at = now() where id = cast(:i as uuid) and status = 'PENDING'"),
        {"st": new_status, "a": principal.user_id, "n": body.note, "i": approval_id})

    await audit.emit(system_db, actor_id=principal.user_id, actor_role=principal.role,
                     action="APPROVAL_DECIDED", outcome="SUCCESS",
                     resource_type="approval", resource_id=approval_id,
                     detail={"decision": new_status,
                             "action_type": row["action_type"],
                             "requested_by": row["requested_by"]},
                     ip=_ip(request))
    return {"id": approval_id, "status": new_status}


@router.get("/pending")
async def list_pending(principal: Principal = Depends(get_principal),
                       db: AsyncSession = Depends(get_db)):
    """Pending requests visible inside caller's geographic scope (RLS also applies)."""
    rows = (await db.execute(text(
        "select id::text as id, action_type::text as action_type, title, status::text"
        " as status, state_code, district_code, requested_at from approval_requests"
        " where status = 'PENDING' order by requested_at desc limit 200"))).mappings().all()
    return [dict(r) for r in rows]

