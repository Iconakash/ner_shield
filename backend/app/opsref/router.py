"""REFERENCE-PATTERN endpoint over geo_protected_resources.

Exists ONLY so RLS behavior is testable end-to-end before business modules exist
(security-first mandate). Business modules (incidents/shipments) must copy this
router/service pattern and then delete this module via change request.
"""
import json

from fastapi import APIRouter, Depends, Request
from pydantic import BaseModel, Field
from sqlalchemy import text
from sqlalchemy.ext.asyncio import AsyncSession

from app.dependencies import ensure_geo_scope, get_principal, require_permissions
from app.core.db import get_db
from app.core.security import Principal

router = APIRouter(prefix="/ops-resources", tags=["ops-reference"])


class ResourceIn(BaseModel):
    title: str = Field(min_length=1, max_length=200)
    state_code: str
    district_code: str
    payload: dict = Field(default_factory=dict)


@router.post("", status_code=201,
             dependencies=[Depends(require_permissions("CREATE_INCIDENT"))])
async def create_resource(body: ResourceIn, request: Request,
                          principal: Principal = Depends(get_principal),
                          db: AsyncSession = Depends(get_db)):
    """FIELD_OFFICER-style creation — geographic scope checked in app AND RLS."""
    await ensure_geo_scope(principal, body.state_code, body.district_code, db, request)
    row = (await db.execute(text(
        "insert into geo_protected_resources"
        " (title, state_code, district_code, created_by, payload)"
        " values (:t, :s, :d, cast(:u as uuid), cast(:p as jsonb)) returning id::text"),
        {"t": body.title, "s": body.state_code, "d": body.district_code,
         "u": principal.user_id, "p": json.dumps(body.payload)})
    ).mappings().first()
    return {"id": row["id"], "title": body.title}


@router.get("/{resource_id}",
            dependencies=[Depends(require_permissions("VIEW_INCIDENTS"))])
async def get_resource(resource_id: str,
                       principal: Principal = Depends(get_principal),
                       db: AsyncSession = Depends(get_db)):
    row = (await db.execute(text(
        "select id::text as id, title, state_code, district_code, payload,"
        " created_at from geo_protected_resources where id = cast(:i as uuid)"),
        {"i": resource_id})).mappings().first()
    if row is None:
        from app.core.errors import NotFound
        raise NotFound("resource not found or outside your geographic scope")
    return dict(row)


@router.get("", dependencies=[Depends(require_permissions("VIEW_INCIDENTS"))])
async def list_resources(principal: Principal = Depends(get_principal),
                         db: AsyncSession = Depends(get_db)):
    """List is scope-filtered by RLS — no app-side filter needed (defense in depth)."""
    rows = (await db.execute(text(
        "select id::text as id, title, state_code, district_code, created_at"
        " from geo_protected_resources order by created_at desc limit 200"))).mappings().all()
    return [dict(r) for r in rows]
