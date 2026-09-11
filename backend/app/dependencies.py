"""The security dependency chain.

Every protected endpoint MUST validate, in order:
  authentication -> account status -> permission -> geographic scope
Enforced via get_principal() plus require_permissions()/ensure_geo_scope() factories.
"""

from fastapi import Depends, Request
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from sqlalchemy import text
from sqlalchemy.ext.asyncio import AsyncSession

from app.audit import service as audit_service
from app.config import get_settings
from app.core.db import get_db
from app.core.errors import AccountDisabled, ForbiddenRole, ForbiddenScope, Unauthenticated
from app.core.request_context import set_jwt_claims
from app.core.security import (
    GeoScope,
    Principal,
    TokenError,
    is_token_revoked,
    verify_access_token,
)

_bearer = HTTPBearer(auto_error=False)


def _client_ip(request: Request) -> str | None:
    return request.client.host if request.client else None


async def get_optional_claims(request: Request) -> dict | None:
    """Verify the bearer token if present; attach claims to context. None if absent."""
    creds: HTTPAuthorizationCredentials | None = await _bearer(request)
    if creds is None:
        return None
    s = get_settings()
    try:
        claims = verify_access_token(creds.credentials, s.SUPABASE_JWT_SECRET, s.SUPABASE_JWKS_URL)
    except TokenError:
        raise Unauthenticated("invalid or expired token")
    set_jwt_claims(claims)          # consumed by get_db for RLS GUCs
    return claims


async def get_principal(
    request: Request,
    db: AsyncSession = Depends(get_db),
    claims: dict | None = Depends(get_optional_claims),
) -> Principal:
    """AUTHENTICATION -> ACCOUNT STATUS. No token = no access (AX-1)."""
    if not claims:
        raise Unauthenticated("authentication required")
    profile = await _load_profile(db, str(claims["sub"]))

    if not profile["is_active"]:
        await audit_service.emit(
            db, actor_id=str(profile["user_id"]), actor_role=profile["role"],
            action="ACCOUNT_DISABLED_BLOCK", outcome="DENIED",
            resource_type="endpoint", resource_id=request.url.path, ip=_client_ip(request))
        raise AccountDisabled()

    issued_at = int(claims.get("iat", 0))
    # P0 SECURITY FIX: revocation compares JWT iat (unix seconds) against the
    # timezone-aware token_revoked_at instant — NEVER against the legacy
    # integer token_version counter (meaningless unit mismatch).
    if is_token_revoked(claims, profile["token_revoked_at"]):
        await audit_service.emit(
            db, actor_id=str(profile["user_id"]), actor_role=profile["role"],
            action="REVOKED_TOKEN_BLOCK", outcome="DENIED",
            resource_type="endpoint", resource_id=request.url.path,
            detail={"iat": issued_at}, ip=_client_ip(request))
        raise Unauthenticated("token revoked")

    return Principal(
        user_id=str(profile["user_id"]), email=profile["email"], role=profile["role"],
        org_id=str(profile["org_id"]) if profile["org_id"] else None,
        is_active=profile["is_active"], mfa_enabled=profile["mfa_enabled"],
        language=profile["language"], scopes=tuple(profile["scopes"]),
        permissions=profile["permissions"], token_claims=claims,
    )


async def _load_profile(db: AsyncSession, user_id: str) -> dict:
    """Load authorization truth (role, scopes, permissions) from the DB — never from JWT."""
    row = (
        await db.execute(text(
            "select user_id, email, full_name, role::text as role, org_id, is_active,"
            " mfa_enabled, language, token_version, token_revoked_at"
            " from profiles where user_id = :u"),
            {"u": user_id})
    ).mappings().first()
    if row is None:
        # Identity exists in Supabase Auth but no profile => not provisioned.
        raise Unauthenticated("profile not provisioned")
    profile = dict(row)
    scopes = (
        await db.execute(text(
            "select level::text as level, state_code, district_code"
            " from user_geo_assignments where user_id = :u"), {"u": user_id})
    ).mappings().all()
    perms = (
        await db.execute(text(
            "select rp.permission_code from role_permissions rp"
            " join profiles p on p.role = rp.role where p.user_id = :u"), {"u": user_id})
    ).scalars().all()
    profile["scopes"] = [
        GeoScope(level=s["level"], state_code=s["state_code"], district_code=s["district_code"])
        for s in scopes
    ]
    profile["permissions"] = frozenset(perms)
    return profile


def require_permissions(*required: str):
    """PERMISSION checkpoint. Route-declared, default-deny (C-Authz)."""
    async def _guard(
        request: Request,
        principal: Principal = Depends(get_principal),
        db: AsyncSession = Depends(get_db),
    ) -> Principal:
        if not principal.has_permissions(required):
            await audit_service.emit(
                db, actor_id=principal.user_id, actor_role=principal.role,
                action="PERMISSION_DENIED", outcome="DENIED",
                resource_type="permission", resource_id=",".join(required),
                detail={"path": request.url.path, "held": sorted(principal.permissions)},
                ip=_client_ip(request))
            raise ForbiddenRole(f"missing permission(s): {','.join(sorted(required))}")
        return principal
    return _guard


async def ensure_geo_scope(
    principal: Principal,
    state_code: str,
    district_code: str | None,
    db: AsyncSession,
    request: Request | None = None,
    action: str = "SCOPE_DENIED",
) -> None:
    """GEOGRAPHIC SCOPE checkpoint for object-level access (services call this)."""
    if not principal.in_geo_scope(state_code, district_code):
        await audit_service.emit(
            db, actor_id=principal.user_id, actor_role=principal.role,
            action=action, outcome="DENIED",
            resource_type="geo", resource_id=f"{state_code}/{district_code}",
            detail={"path": request.url.path if request else None},
            ip=_client_ip(request) if request else None)
        raise ForbiddenScope(
            f"resource outside authorized geographic scope ({state_code}/{district_code})")

