"""Authentication endpoints. Login is a server-side proxy of Supabase Auth so that
login attempt tracking / abuse lockout / MFA enforcement are enforced SERVER-SIDE.
The frontend never calls Supabase Auth directly for password grants.
"""
import httpx
from fastapi import APIRouter, Depends, Request
from pydantic import BaseModel, EmailStr, Field
from sqlalchemy import text
from sqlalchemy.ext.asyncio import AsyncSession

from app.audit import service as audit
from app.config import get_settings
from app.core.db import get_db, get_system_db
from app.core.errors import RateLimited, Unauthenticated
from app.core.security import Principal
from app.dependencies import get_principal

router = APIRouter(prefix="/auth", tags=["auth"])


class LoginIn(BaseModel):
    email: EmailStr
    password: str = Field(min_length=8, max_length=128)


def _ip(request: Request) -> str | None:
    return request.client.host if request.client else None


async def _record_attempt(system_db: AsyncSession, email: str, outcome: str,
                          request: Request, user_id: str | None = None,
                          reason: str | None = None) -> None:
    await system_db.execute(text(
        "insert into login_attempts (email, user_id, ip, user_agent, outcome, failure_reason)"
        " values (:e, cast(:u as uuid), cast(:ip as inet), :ua, :o, :r)"),
        {"e": email, "u": user_id, "ip": _ip(request),
         "ua": request.headers.get("user-agent", "")[:300], "o": outcome, "r": reason})


async def _is_locked(system_db: AsyncSession, email: str) -> bool:
    s = get_settings()
    row = (await system_db.execute(text(
        "select count(*) from login_attempts"
        " where email = :e and outcome in ('FAILURE','LOCKED_OUT')"
        " and attempted_at > now() - make_interval(mins => :w)"),
        {"e": email, "w": s.LOGIN_LOCKOUT_WINDOW_MINUTES})
    ).scalar()
    return int(row or 0) >= s.LOGIN_MAX_FAILURES


@router.post("/login")
async def login(body: LoginIn, request: Request,
                system_db: AsyncSession = Depends(get_system_db)):
    """Credentials-only login (R-4/L-1): no role field accepted — role comes from profiles."""
    s = get_settings()
    if await _is_locked(system_db, body.email):
        await _record_attempt(system_db, body.email, "LOCKED_OUT", request)
        raise RateLimited("account temporarily locked; try later")

    async with httpx.AsyncClient(timeout=10) as client:
        resp = await client.post(
            f"{s.SUPABASE_URL}/auth/v1/token?grant_type=password",
            headers={"apikey": s.SUPABASE_ANON_KEY},
            json={"email": body.email, "password": body.password})

    if resp.status_code != 200:
        await _record_attempt(system_db, body.email, "FAILURE", request, reason="bad_credentials")
        # generic error — never reveal whether the account exists
        raise Unauthenticated("invalid credentials")

    data = resp.json()
    claims = data.get("decoded_jwt") or {}
    user_id = data.get("user", {}).get("id")
    profile = (
        await system_db.execute(text(
            "select user_id, role::text as role, is_active, mfa_enabled"
            " from profiles where user_id = cast(:u as uuid)"), {"u": user_id})
    ).mappings().first()

    if profile is None or not profile["is_active"]:
        reason = "no_profile" if profile is None else "disabled"
        await _record_attempt(system_db, body.email, "FAILURE", request, user_id, reason)
        raise Unauthenticated("invalid credentials")
    if profile["mfa_enabled"] and (claims.get("aal") or "aal1") != "aal2":
        await _record_attempt(system_db, body.email, "MFA_CHALLENGED", request, user_id)
        return {"mfa_required": True}

    await _record_attempt(system_db, body.email, "SUCCESS", request, user_id)
    await audit.emit(system_db, actor_id=user_id, actor_role=profile["role"],
                     action="LOGIN_SUCCESS", outcome="SUCCESS",
                     resource_type="session", ip=_ip(request))
    return {
        "access_token": data.get("access_token"),
        "refresh_token": data.get("refresh_token"),
        "expires_in": data.get("expires_in"),
        "role": profile["role"],          # informational only; server enforces everything
    }


@router.post("/logout")
async def logout(request: Request,
                 principal: Principal = Depends(get_principal),
                 db: AsyncSession = Depends(get_db)):
    """Revoke every access token issued up to now for the calling user.

    P0 SECURITY: sets profiles.token_revoked_at = now() so all previously
    minted JWTs (including stolen copies) fail validation immediately —
    stateless-JWT revocation done server-side, not by client-side deletion.
    """
    await db.execute(text(
        "update profiles set token_revoked_at = now()"
        " where user_id = cast(:u as uuid) and"
        " (token_revoked_at is null or token_revoked_at < now())"),
        {"u": principal.user_id})
    await audit.emit(db, actor_id=principal.user_id, actor_role=principal.role,
                     action="LOGOUT_TOKEN_REVOKED", outcome="SUCCESS",
                     resource_type="session", ip=_ip(request))
    return {"ok": True}


class MFAChallengeOut(BaseModel):
    factor_id: str
    challenge_id: str


@router.get("/mfa/challenge")
async def mfa_challenge(request: Request):
    """Create a TOTP challenge for the caller's FIRST-FACTOR session (aal1).

    Keeps the whole MFA dance behind the backend proxy: the browser never
    talks to Supabase Auth directly. Returns the ids required by
    POST /auth/mfa/verify.
    """
    s = get_settings()
    token = request.headers.get("authorization", "").removeprefix("Bearer ").strip()
    headers = {"apikey": s.SUPABASE_ANON_KEY, "Authorization": f"Bearer {token}"}
    async with httpx.AsyncClient(timeout=10) as client:
        fr = await client.get(f"{s.SUPABASE_URL}/auth/v1/factors", headers=headers)
        if fr.status_code != 200:
            raise Unauthenticated("MFA session invalid")
        verified = [f for f in fr.json() if f.get("status") == "verified"]
        if not verified:
            raise Unauthenticated("no verified MFA factor enrolled")
        factor_id = verified[0]["id"]
        cr = await client.post(
            f"{s.SUPABASE_URL}/auth/v1/factors/{factor_id}/challenge",
            headers=headers)
    if cr.status_code != 200:
        raise Unauthenticated("could not start MFA challenge")
    return {"factor_id": factor_id,
            "challenge_id": cr.json().get("id", ""),
            "expires_at": cr.json().get("expires_at")}


class MFAVerifyIn(BaseModel):
    factor_id: str
    challenge_id: str
    code: str = Field(min_length=6, max_length=8)


@router.post("/mfa/verify")
async def mfa_verify(body: MFAVerifyIn, request: Request):
    """Second-factor (TOTP) verification passthrough. Needs the first-factor session."""
    s = get_settings()
    token = request.headers.get("authorization", "").removeprefix("Bearer ").strip()
    async with httpx.AsyncClient(timeout=10) as client:
        resp = await client.post(
            f"{s.SUPABASE_URL}/auth/v1/verify",
            headers={"apikey": s.SUPABASE_ANON_KEY, "Authorization": f"Bearer {token}"},
            json={"type": "totp", "factor_id": body.factor_id,
                  "challenge_id": body.challenge_id, "code": body.code})
    if resp.status_code != 200:
        raise Unauthenticated("MFA verification failed")
    d = resp.json()
    return {"access_token": d.get("access_token"), "refresh_token": d.get("refresh_token"),
            "expires_in": d.get("expires_in")}


@router.get("/me")
async def me(principal: Principal = Depends(get_principal),
             db: AsyncSession = Depends(get_db)):
    """Whoami for the UI. Role/scope shown is informational — server enforces everything."""
    return {
        "user_id": principal.user_id, "email": principal.email, "role": principal.role,
        "org_id": principal.org_id, "language": principal.language,
        "scopes": [{"level": sc.level, "state_code": sc.state_code,
                    "district_code": sc.district_code} for sc in principal.scopes],
        "permissions": sorted(principal.permissions),
    }

