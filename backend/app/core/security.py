"""Security primitives: token verification, Principal, permission registry, scope math.

Pure module — no DB, no HTTP. Unit-tested without infrastructure.
"""
from dataclasses import dataclass, field
from typing import Iterable, Optional

import jwt as pyjwt

# ---------------------------------------------------------------- permissions
ALL_PERMISSIONS = [
    "VIEW_MAP", "VIEW_ROADS", "VIEW_INCIDENTS", "CREATE_INCIDENT", "VERIFY_INCIDENT",
    "VIEW_SHIPMENTS", "CREATE_SHIPMENT", "MODIFY_SHIPMENT", "VIEW_GPS",
    "REQUEST_REROUTE", "APPROVE_REROUTE", "VIEW_SUPPLY_RISK",
    "CREATE_ALERT", "ISSUE_ALERT", "VIEW_ANALYTICS", "EXPORT_REPORT",
    "MANAGE_USERS", "MANAGE_SYSTEM", "VIEW_AUDIT_LOG",
]

ROLES = [
    "SUPER_ADMIN", "REGIONAL_AUTHORITY", "DISTRICT_OFFICER",
    "LOGISTICS_OFFICER", "FIELD_OFFICER", "ANALYST_VIEWER",
]

# Mirror of database/seed/0001 role_permissions (DB remains source of truth;
# this constant seeds nothing — it exists for tests and emergency fallback).
ROLE_PERMISSIONS: dict[str, set[str]] = {
    "SUPER_ADMIN": set(ALL_PERMISSIONS),
    "REGIONAL_AUTHORITY": {
        "VIEW_MAP", "VIEW_ROADS", "VIEW_INCIDENTS", "VERIFY_INCIDENT", "VIEW_SHIPMENTS",
        "VIEW_GPS", "REQUEST_REROUTE", "APPROVE_REROUTE", "VIEW_SUPPLY_RISK",
        "CREATE_ALERT", "ISSUE_ALERT", "VIEW_ANALYTICS", "EXPORT_REPORT", "VIEW_AUDIT_LOG",
    },
    "DISTRICT_OFFICER": {
        "VIEW_MAP", "VIEW_ROADS", "VIEW_INCIDENTS", "VERIFY_INCIDENT", "VIEW_SHIPMENTS",
        "VIEW_GPS", "REQUEST_REROUTE", "VIEW_SUPPLY_RISK", "CREATE_ALERT", "ISSUE_ALERT",
        "VIEW_ANALYTICS", "EXPORT_REPORT", "VIEW_AUDIT_LOG",
    },
    "LOGISTICS_OFFICER": {
        "VIEW_MAP", "VIEW_ROADS", "VIEW_INCIDENTS", "VIEW_SHIPMENTS", "CREATE_SHIPMENT",
        "MODIFY_SHIPMENT", "VIEW_GPS", "REQUEST_REROUTE", "APPROVE_REROUTE",
        "VIEW_SUPPLY_RISK", "VIEW_ANALYTICS", "EXPORT_REPORT",
    },
    "FIELD_OFFICER": {"VIEW_MAP", "VIEW_ROADS", "VIEW_INCIDENTS", "CREATE_INCIDENT", "VIEW_GPS"},
    "ANALYST_VIEWER": {
        "VIEW_MAP", "VIEW_ROADS", "VIEW_INCIDENTS", "VIEW_SHIPMENTS", "VIEW_GPS",
        "VIEW_SUPPLY_RISK", "VIEW_ANALYTICS", "EXPORT_REPORT",
    },
}

# Two-person approval workflow requirements (baseline mandate)
APPROVAL_WORKFLOW_PERMISSIONS = {
    "EMERGENCY_REROUTE": {"REQUEST_REROUTE", "APPROVE_REROUTE"},
    "MAJOR_SUPPLY_REDISTRIBUTION": {"MODIFY_SHIPMENT", "APPROVE_REROUTE"},
    "HIGH_LEVEL_ALERT": {"CREATE_ALERT", "ISSUE_ALERT"},   # draft vs publish separation
    "CRITICAL_LOGISTICS_STATUS": {"MODIFY_SHIPMENT", "APPROVE_REROUTE"},
}


class TokenError(Exception):
    """Raised when a bearer token fails verification."""


# Algorithms we will accept when verifying a JWKS-backed access token.
# Restricted to asymmetric Supabase algorithms (ECDSA P-256 and RSA-SHA256).
# HS* / "none" are NEVER accepted on the JWKS path so a stolen symmetric secret
# cannot be used to forge tokens against the asymmetric verifier.
_JWKS_ALLOWED_ALGS = frozenset({"ES256", "RS256"})


def verify_access_token(token: str, jwt_secret: Optional[str], jwks_url: Optional[str]) -> dict:
    """Verify a Supabase access JWT and return its claims.

    HS256 shared-secret mode (legacy / local-dev); JWKS asymmetric mode for the
    live project. The JWKS path derives its accepted algorithm from the JWK
    itself (Supabase currently publishes ES256 keys) and refuses anything else.
    """
    try:
        if jwks_url:
            client = pyjwt.PyJWKClient(jwks_url)
            signing_key = client.get_signing_key_from_jwt(token)
            key = signing_key.key
            # Read the algorithm the JWK was actually registered with, then
            # constrain it to our allowlist. The token's own alg header is
            # intentionally NOT trusted as the source of truth.
            jwk = signing_key._jwk_data  # type: ignore[attr-defined]
            alg = jwk.get("alg") or jwk.get("alg_from_jwks")
            # PyJWKClient stores the raw JWK under _jwk_data; fall back to the
            # signing key's public-key properties if alg is absent (RFC 7517
            # permits alg to be omitted from individual JWKs).
            if not alg:
                kty = jwk.get("kty")
                if kty == "EC":
                    alg = "ES256"
                elif kty == "RSA":
                    alg = "RS256"
                else:
                    raise TokenError("JWKS key has no usable algorithm")
            if alg not in _JWKS_ALLOWED_ALGS:
                raise TokenError(f"JWKS algorithm not allowed: {alg}")
        elif jwt_secret:
            key, alg = jwt_secret, "HS256"
        else:  # pragma: no cover - guarded by Settings boot check
            raise TokenError("no verification material configured")
        return pyjwt.decode(
            token, key, algorithms=[alg],
            audience="authenticated",
            options={"require": ["exp", "sub", "iat"]},
        )
    except pyjwt.PyJWTError as exc:
        raise TokenError(str(exc)) from exc


class TokenRevokedError(TokenError):
    """Raised when a token was issued at or before the account's revocation instant."""


# ---------------------------------------------------------------- revocation
def is_token_revoked(claims: dict, token_revoked_at) -> bool:
    """P0 SECURITY FIX — mathematically correct revocation check.

    A JWT is revoked iff it was issued AT OR BEFORE the account's
    token_revoked_at instant. JWT ``iat`` is unix epoch SECONDS;
    ``token_revoked_at`` is a timezone-aware datetime (or None).

    Second-level granularity means tokens minted in the same second as the
    revocation commit are also rejected — the safe direction for a
    government-grade system (fail closed). Callers needing leniency may pass
    a token_revoked_at truncated back by their accepted clock skew.

    Never compare iat against integer version counters.
    """
    if token_revoked_at is None:
        return False
    iat = int(claims.get("iat", 0))
    return iat <= int(token_revoked_at.timestamp())


# ---------------------------------------------------------------- principal
@dataclass(frozen=True)
class GeoScope:
    level: str                 # REGION | STATE | DISTRICT
    state_code: Optional[str] = None
    district_code: Optional[str] = None


@dataclass(frozen=True)
class Principal:
    user_id: str
    email: str
    role: str
    org_id: Optional[str]
    is_active: bool
    mfa_enabled: bool
    language: str
    scopes: tuple[GeoScope, ...] = field(default_factory=tuple)
    permissions: frozenset[str] = frozenset()
    token_claims: dict = field(default_factory=dict)

    def has_permissions(self, required: Iterable[str]) -> bool:
        return all(p in self.permissions for p in required)

    def in_geo_scope(self, state_code: str, district_code: Optional[str]) -> bool:
        """Pure mirror of SQL app_has_geo_scope() — MUST stay semantically identical."""
        for s in self.scopes:
            if s.level == "REGION":
                return True
            if state_code and s.level == "STATE" and s.state_code == state_code:
                return True
            if district_code and s.level == "DISTRICT" and s.district_code == district_code:
                return True
        return self.role == "SUPER_ADMIN"
