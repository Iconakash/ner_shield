"""Pure unit tests for the authorization core — run without any infrastructure."""
import pytest

from app.core.security import (
    ALL_PERMISSIONS, APPROVAL_WORKFLOW_PERMISSIONS, ROLE_PERMISSIONS,
    GeoScope, Principal, TokenError, verify_access_token,
)
from conftest import TEST_SECRET, mint_token


def _principal(role: str, scopes: list[GeoScope]) -> Principal:
    return Principal(
        user_id="u", email="u@test.local", role=role, org_id=None, is_active=True,
        mfa_enabled=False, language="en", scopes=tuple(scopes),
        permissions=frozenset(ROLE_PERMISSIONS[role]),
    )


# ---------------------------------------------------------------- role matrix
def test_all_roles_present_and_complete():
    assert set(ROLE_PERMISSIONS) == {
        "SUPER_ADMIN", "REGIONAL_AUTHORITY", "DISTRICT_OFFICER",
        "LOGISTICS_OFFICER", "FIELD_OFFICER", "ANALYST_VIEWER"}
    for role, perms in ROLE_PERMISSIONS.items():
        unknown = perms - set(ALL_PERMISSIONS)
        assert not unknown, f"{role} references unknown permissions {unknown}"


def test_regional_authority_cannot_administer_platform():
    p = ROLE_PERMISSIONS["REGIONAL_AUTHORITY"]
    assert "MANAGE_USERS" not in p
    assert "MANAGE_SYSTEM" not in p
    # but may view regional operational data and approve reroutes
    assert {"VIEW_MAP", "VIEW_SHIPMENTS", "APPROVE_REROUTE"} <= p


def test_field_officer_is_minimal_and_cannot_verify():
    p = ROLE_PERMISSIONS["FIELD_OFFICER"]
    assert "CREATE_INCIDENT" in p
    assert not p & {"VERIFY_INCIDENT", "ISSUE_ALERT", "MANAGE_USERS", "EXPORT_REPORT"}


def test_analyst_viewer_is_read_only():
    p = ROLE_PERMISSIONS["ANALYST_VIEWER"]
    mutating = {"CREATE_INCIDENT", "VERIFY_INCIDENT", "CREATE_SHIPMENT",
                "MODIFY_SHIPMENT", "REQUEST_REROUTE", "APPROVE_REROUTE",
                "CREATE_ALERT", "ISSUE_ALERT", "MANAGE_USERS", "MANAGE_SYSTEM"}
    assert not (p & mutating), "ANALYST_VIEWER must hold zero mutating permissions"


def test_district_officer_lacks_cross_cutting_admin():
    p = ROLE_PERMISSIONS["DISTRICT_OFFICER"]
    assert "MANAGE_USERS" not in p and "MANAGE_SYSTEM" not in p
    assert "VIEW_AUDIT_LOG" in p  # scoped read allowed per baseline §4.4


def test_super_admin_has_everything():
    assert ROLE_PERMISSIONS["SUPER_ADMIN"] == set(ALL_PERMISSIONS)


# ---------------------------------------------------------------- geo scope math
A = GeoScope("DISTRICT", state_code="IN-MN", district_code="IN-MN-IE")
STATE_MN = GeoScope("STATE", state_code="IN-MN")
REGION = GeoScope("REGION")


@pytest.mark.parametrize("role,scopes,state,district,expected", [
    ("FIELD_OFFICER", [A], "IN-MN", "IN-MN-IE", True),      # own district
    ("FIELD_OFFICER", [A], "IN-MN", "IN-MN-IW", False),     # neighbor district X vs Y
    ("DISTRICT_OFFICER", [A], "IN-MN", "IN-MN-CH", False),  # cross-district denial
    ("DISTRICT_OFFICER", [STATE_MN], "IN-MN", "IN-MN-CH", True),   # state-wide officer
    ("REGIONAL_AUTHORITY", [REGION], "IN-SK", "IN-SK-GE", True),   # whole NER view
    ("ANALYST_VIEWER", [], "IN-MN", "IN-MN-IE", False),     # no scope => no access
])
def test_scope_containment(role, scopes, state, district, expected):
    assert _principal(role, scopes).in_geo_scope(state, district) is expected


def test_super_admin_bypasses_scope():
    assert _principal("SUPER_ADMIN", []).in_geo_scope("IN-TR", "IN-TR-WA") is True


# ---------------------------------------------------------------- token verification
def test_valid_token_verifies():
    claims = verify_access_token(mint_token("u-123"), TEST_SECRET, None)
    assert claims["sub"] == "u-123"
    assert claims["aud"] == "authenticated"


def test_tampered_token_rejected():
    tok = mint_token("u-123")
    bad = tok[:-6] + ("aaaaaa" if not tok.endswith("aaaaaa") else "bbbbbb")
    with pytest.raises(TokenError):
        verify_access_token(bad, TEST_SECRET, None)


def test_expired_token_rejected():
    tok = mint_token("u-123", minutes=-10)
    with pytest.raises(TokenError):
        verify_access_token(tok, TEST_SECRET, None)


def test_wrong_audience_rejected():
    now = 1_700_000_000
    import jwt as pyjwt
    tok = pyjwt.encode({"sub": "x", "aud": "someone-else", "iat": now,
                        "exp": now + 60}, TEST_SECRET, algorithm="HS256")
    with pytest.raises(TokenError):
        verify_access_token(tok, TEST_SECRET, None)


# ---------------------------------------------------------------- approvals config
def test_two_person_workflow_covers_mandated_actions():
    assert set(APPROVAL_WORKFLOW_PERMISSIONS) == {
        "EMERGENCY_REROUTE", "MAJOR_SUPPLY_REDISTRIBUTION",
        "HIGH_LEVEL_ALERT", "CRITICAL_LOGISTICS_STATUS"}
    for action, perms in APPROVAL_WORKFLOW_PERMISSIONS.items():
        assert len(perms) == 2, f"{action} needs request+approve permission pair"


def test_principal_permission_gate():
    p = _principal("LOGISTICS_OFFICER", [])
    assert p.has_permissions(["VIEW_SHIPMENTS"])
    assert not p.has_permissions(["MANAGE_USERS"])   # cross-role attempt blocked


# ---------------------------------------------------- JWKS / ES256 verification
# Live Supabase publishes an ECDSA P-256 key (alg=ES256). The verifier MUST
# derive its accepted algorithm from the JWK itself and reject any other alg.
# These tests run offline: we mint our own ES256 keypair, serve a one-line
# JWKS via a stubbed PyJWKClient, and exercise the asymmetric path.

import jwt as _pyjwt
from cryptography.hazmat.primitives.asymmetric import ec
from cryptography.hazmat.primitives import serialization

from app.core import security as _sec_mod


def _es256_keypair():
    sk = ec.generate_private_key(ec.SECP256R1())
    pem = sk.private_bytes(
        encoding=serialization.Encoding.PEM,
        format=serialization.PrivateFormat.PKCS8,
        encryption_algorithm=serialization.NoEncryption(),
    )
    pub = sk.public_key().public_numbers()
    return pem, pub, "test-kid-es256"


def _b64int(s: str) -> int:
    import base64
    return int.from_bytes(base64.urlsafe_b64decode(s + "=" * (-len(s) % 4)),
                          "big")


def _build_es256_jwk(pub_numbers, kid):
    def _b64uint(n: int) -> str:
        import base64
        blen = (n.bit_length() + 7) // 8
        return base64.urlsafe_b64encode(n.to_bytes(blen, "big")).rstrip(b"=").decode()
    return {"kty": "EC", "crv": "P-256", "alg": "ES256",
            "use": "sig", "kid": kid,
            "x": _b64uint(pub_numbers.x), "y": _b64uint(pub_numbers.y)}


class _StubSigningKey:
    """Mimics the attributes verify_access_token reads from jwt.PyJWK."""
    def __init__(self, jwk_dict):
        self._jwk_data = jwk_dict
        self.key = ec.EllipticCurvePublicNumbers(
            x=_b64int(jwk_dict["x"]), y=_b64int(jwk_dict["y"]),
            curve=ec.SECP256R1(),
        ).public_key()


class _StubJWKClient:
    def __init__(self, jwk_dict):
        self._jwk = jwk_dict

    def get_signing_key_from_jwt(self, _token):
        return _StubSigningKey(self._jwk)


def _mint_es256(claims, pem, kid):
    return _pyjwt.encode(claims, pem, algorithm="ES256",
                         headers={"kid": kid})


def _good_jwt_claims(now: int) -> dict:
    return {"sub": "u-es256", "email": "u@es.local",
            "aud": "authenticated", "role": "authenticated",
            "iat": now, "exp": now + 600}


def test_es256_token_verifies_via_jwks_path(monkeypatch):
    """Live Supabase shape: ES256, JWKS-discovered algorithm, full claims."""
    import time
    pem, pub, kid = _es256_keypair()
    jwk = _build_es256_jwk(pub, kid)
    monkeypatch.setattr(_sec_mod.pyjwt, "PyJWKClient",
                        lambda _url: _StubJWKClient(jwk))
    tok = _mint_es256(_good_jwt_claims(int(time.time())), pem, kid)
    claims = verify_access_token(tok, None, "https://example/jwks.json")
    assert claims["sub"] == "u-es256"
    assert claims["aud"] == "authenticated"


def test_es256_token_rejected_when_jwks_advertises_a_different_alg(monkeypatch):
    """An attacker cannot trick us into accepting ES256 if the JWK says HS256."""
    import time
    pem, pub, kid = _es256_keypair()
    jwk = _build_es256_jwk(pub, kid)
    jwk["alg"] = "HS256"
    monkeypatch.setattr(_sec_mod.pyjwt, "PyJWKClient",
                        lambda _url: _StubJWKClient(jwk))
    tok = _mint_es256(_good_jwt_claims(int(time.time())), pem, kid)
    with pytest.raises(TokenError):
        verify_access_token(tok, None, "https://example/jwks.json")


def test_hs256_forgery_against_jwks_path_is_rejected(monkeypatch):
    """An HS256 token must NOT pass the JWKS path even if the secret leaks."""
    import time
    pem, pub, kid = _es256_keypair()
    jwk = _build_es256_jwk(pub, kid)
    monkeypatch.setattr(_sec_mod.pyjwt, "PyJWKClient",
                        lambda _url: _StubJWKClient(jwk))
    forged = _pyjwt.encode(_good_jwt_claims(int(time.time())),
                           "attacker-symmetric-key", algorithm="HS256")
    with pytest.raises(TokenError):
        verify_access_token(forged, None, "https://example/jwks.json")


def test_es256_jwk_without_explicit_alg_falls_back_to_kty(monkeypatch):
    """RFC 7517 permits alg to be omitted from individual JWKs; kty drives it."""
    import time
    pem, pub, kid = _es256_keypair()
    jwk = _build_es256_jwk(pub, kid)
    del jwk["alg"]
    monkeypatch.setattr(_sec_mod.pyjwt, "PyJWKClient",
                        lambda _url: _StubJWKClient(jwk))
    tok = _mint_es256(_good_jwt_claims(int(time.time())), pem, kid)
    claims = verify_access_token(tok, None, "https://example/jwks.json")
    assert claims["sub"] == "u-es256"


def test_jwks_with_unsupported_alg_is_rejected(monkeypatch):
    """If a JWK advertised an algorithm outside {ES256, RS256}, we refuse."""
    import time
    pem, pub, kid = _es256_keypair()
    jwk = _build_es256_jwk(pub, kid)
    jwk["alg"] = "HS384"
    monkeypatch.setattr(_sec_mod.pyjwt, "PyJWKClient",
                        lambda _url: _StubJWKClient(jwk))
    tok = _mint_es256(_good_jwt_claims(int(time.time())), pem, kid)
    with pytest.raises(TokenError):
        verify_access_token(tok, None, "https://example/jwks.json")


def test_es256_token_missing_exp_is_rejected(monkeypatch):
    """Even on the JWKS path, exp/sub/iat remain required."""
    import time
    pem, pub, kid = _es256_keypair()
    jwk = _build_es256_jwk(pub, kid)
    monkeypatch.setattr(_sec_mod.pyjwt, "PyJWKClient",
                        lambda _url: _StubJWKClient(jwk))
    bad = {k: v for k, v in _good_jwt_claims(int(time.time())).items()
           if k != "exp"}
    tok = _mint_es256(bad, pem, kid)
    with pytest.raises(TokenError):
        verify_access_token(tok, None, "https://example/jwks.json")
