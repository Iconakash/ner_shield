"""User/role/scope administration — MANAGE_USERS only (SUPER_ADMIN per baseline §4.4).
All mutations run on the system connection with explicit audit emission; role is
NEVER accepted from self-service input (AX-5, R-4).
"""
from typing import Literal

from fastapi import APIRouter, Depends, Request
from pydantic import BaseModel, EmailStr, Field
from sqlalchemy import text
from sqlalchemy.ext.asyncio import AsyncSession

from app.audit import service as audit
from app.config import get_settings
from app.core.db import get_system_db
from app.core.errors import Conflict, NotFound
from app.core.security import Principal
from app.dependencies import get_principal, require_permissions

router = APIRouter(prefix="/users", tags=["users"])


class UserCreate(BaseModel):
    email: EmailStr
    password: str = Field(min_length=12, max_length=128)
    full_name: str = Field(min_length=1, max_length=120)
    role: Literal["SUPER_ADMIN", "REGIONAL_AUTHORITY", "DISTRICT_OFFICER",
                  "LOGISTICS_OFFICER", "FIELD_OFFICER", "ANALYST_VIEWER"]
    org_id: str | None = None


class ScopeGrant(BaseModel):
    level: Literal["REGION", "STATE", "DISTRICT"]
    state_code: str | None = None
    district_code: str | None = None


class LanguagePref(BaseModel):
    language: Literal["en", "hi", "as"]   # frozen MVP set (Phase 17 · FR-C15)


@router.patch("/me/language")
async def set_my_language(body: LanguagePref, request: Request,
                          principal: Principal = Depends(get_principal),
                          system_db: AsyncSession = Depends(get_system_db)):
    """Self-service UI/notification language (FR-C15.2).

    Language is NOT a security attribute — unlike role/scope it may be changed
    by the user; role still never comes from client input (AX-5 untouched).
    """
    await system_db.execute(text(
        "update profiles set language = :l where user_id = cast(:u as uuid)"),
        {"l": body.language, "u": principal.user_id})
    await audit.emit(system_db, actor_id=principal.user_id,
                     actor_role=principal.role, action="USER_UPDATE",
                     outcome="SUCCESS", resource_type="user",
                     resource_id=principal.user_id,
                     detail={"language": body.language},
                     ip=request.client.host if request.client else None)
    return {"user_id": principal.user_id, "language": body.language}


async def _get_profile(system_db: AsyncSession, user_id: str) -> dict:
    row = (await system_db.execute(text(
        "select user_id, email, role::text as role, is_active from profiles"
        " where user_id = cast(:u as uuid)"), {"u": user_id})).mappings().first()
    if row is None:
        raise NotFound("user not found")
    return dict(row)


from typing import Literal

@router.post("", status_code=201,
             dependencies=[Depends(require_permissions("MANAGE_USERS"))])
async def create_user(body: UserCreate, request: Request,
                      principal=Depends(require_permissions("MANAGE_USERS")),
                      system_db: AsyncSession = Depends(get_system_db)):
    """Provision auth user (service-role admin API, server-side only — AX-3) + profile."""
    import httpx
    s = get_settings()
    async with httpx.AsyncClient(timeout=15) as client:
        resp = await client.post(
            f"{s.SUPABASE_URL}/auth/v1/admin/users",
            headers={"apikey": s.SUPABASE_SERVICE_ROLE_KEY,
                     "Authorization": f"Bearer {s.SUPABASE_SERVICE_ROLE_KEY}"},
            json={"email": body.email, "password": body.password, "email_confirm": True})
    if resp.status_code not in (200, 201):
        detail = resp.json().get("msg", "auth provisioning failed")
        raise Conflict(f"could not provision auth user: {detail}")
    new_id = resp.json()["id"]

    await system_db.execute(text(
        "insert into profiles (user_id, email, full_name, role, org_id)"
        " values (cast(:u as uuid), :e, :n, cast(:r as user_role),"
        " coalesce(cast(:o as uuid), (select id from organizations order by created_at limit 1)))"),
        {"u": new_id, "e": body.email, "n": body.full_name, "r": body.role, "o": body.org_id})
    await audit.emit(system_db, actor_id=principal.user_id, actor_role=principal.role,
                     action="USER_CREATE", outcome="SUCCESS",
                     resource_type="user", resource_id=new_id,
                     detail={"email": body.email, "role": body.role},
                     ip=request.client.host if request.client else None)
    return {"user_id": new_id, "email": body.email, "role": body.role}


@router.patch("/{user_id}/status",
              dependencies=[Depends(require_permissions("MANAGE_USERS"))])
async def set_active(user_id: str, is_active: bool, request: Request,
                     principal=Depends(require_permissions("MANAGE_USERS")),
                     system_db: AsyncSession = Depends(get_system_db)):
    """Enable/disable. Disabling ALSO revokes all tokens issued up to now
    (P0 SECURITY FIX: token_revoked_at, not the legacy token_version counter)."""
    await _get_profile(system_db, user_id)
    if is_active:
        await system_db.execute(text(
            "update profiles set is_active = true, token_version = token_version + 1"
            " where user_id = cast(:u as uuid)"), {"u": user_id})
    else:
        await system_db.execute(text(
            "update profiles set is_active = false, token_version = token_version + 1,"
            " token_revoked_at = now()"
            " where user_id = cast(:u as uuid)"
            " and (token_revoked_at is null or token_revoked_at < now())"),
            {"u": user_id})
    await audit.emit(system_db, actor_id=principal.user_id, actor_role=principal.role,
                     action="USER_UPDATE", outcome="SUCCESS",
                     resource_type="user", resource_id=user_id,
                     detail={"is_active": is_active},
                     ip=request.client.host if request.client else None)
    return {"user_id": user_id, "is_active": is_active}


@router.post("/{user_id}/revoke-tokens",
             dependencies=[Depends(require_permissions("MANAGE_USERS"))])
async def revoke_tokens(user_id: str, request: Request,
                        principal=Depends(require_permissions("MANAGE_USERS")),
                        system_db: AsyncSession = Depends(get_system_db)):
    """EMERGENCY ACCOUNT REVOCATION (P0 SECURITY).

    Invalidates every access token issued to this user up to now — used for
    credential rotation, MFA reset, password-reset enforcement and incident
    response. The account itself stays active; the user simply must sign in
    again (and complete MFA afresh) to obtain a valid token.
    """
    await _get_profile(system_db, user_id)
    await system_db.execute(text(
        "update profiles set token_revoked_at = now(),"
        " token_version = token_version + 1"
        " where user_id = cast(:u as uuid)"
        " and (token_revoked_at is null or token_revoked_at < now())"),
        {"u": user_id})
    await audit.emit(system_db, actor_id=principal.user_id, actor_role=principal.role,
                     action="TOKENS_REVOKED", outcome="SUCCESS",
                     resource_type="user", resource_id=user_id,
                     ip=request.client.host if request.client else None)
    return {"user_id": user_id, "tokens_revoked_at": "now()"}


@router.post("/{user_id}/scopes",
             dependencies=[Depends(require_permissions("MANAGE_USERS"))])
async def grant_scope(user_id: str, body: ScopeGrant, request: Request,
                      principal=Depends(require_permissions("MANAGE_USERS")),
                      system_db: AsyncSession = Depends(get_system_db)):
    await _get_profile(system_db, user_id)
    if body.level == "STATE" and not body.state_code:
        raise Conflict("STATE scope requires state_code")
    if body.level == "DISTRICT" and not body.district_code:
        raise Conflict("DISTRICT scope requires district_code")
    await system_db.execute(text(
        "insert into user_geo_assignments (user_id, level, state_code, district_code,"
        " granted_by) values (cast(:u as uuid), cast(:l as geo_level), :s, :d,"
        " cast(:g as uuid)) on conflict do nothing"),
        {"u": user_id, "l": body.level, "s": body.state_code,
         "d": body.district_code, "g": principal.user_id})
    await audit.emit(system_db, actor_id=principal.user_id, actor_role=principal.role,
                     action="SCOPE_GRANT", outcome="SUCCESS",
                     resource_type="geo_scope", resource_id=user_id,
                     detail=body.model_dump(),
                     ip=request.client.host if request.client else None)
    return {"user_id": user_id, "scope": body.model_dump()}


@router.get("/{user_id}", dependencies=[Depends(require_permissions("MANAGE_USERS"))])
async def get_user(user_id: str, system_db: AsyncSession = Depends(get_system_db)):
    profile = await _get_profile(system_db, user_id)
    scopes = (await system_db.execute(text(
        "select level::text as level, state_code, district_code from user_geo_assignments"
        " where user_id = cast(:u as uuid)"), {"u": user_id})).mappings().all()
    profile["scopes"] = [dict(s) for s in scopes]
    return profile

