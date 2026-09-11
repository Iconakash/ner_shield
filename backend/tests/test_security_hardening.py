"""PHASE 26 ??? SECURITY HARDENING suite (pre-deployment gate).

Unit-level adversarial checks that run WITHOUT infrastructure:
    * authorization matrix (the mandated role/district denials)
    * token validation edge cases (alg=none, missing claims, forgery)
    * account-enumeration uniformity + brute-force lockout (fake Supabase)
    * upload hardening (magic bytes, spoofing, size, randomized names)
    * API surface (body-size cap, malformed JSON, CORS allowlist)

RLS / direct-SQL attacks live in test_security_integration.py (need Supabase).
"""
import uuid

import jwt as pyjwt
import pytest
from fastapi.testclient import TestClient

from conftest import mint_token
from app.core.security import (
    ROLE_PERMISSIONS,
    GeoScope,
    Principal,
    TokenError,
    verify_access_token,
)
from app.core.uploads import UploadRejected, sniff_kind, validate_upload

# ============================================================== AUTHORIZATION
# The exact denials mandated by the Phase-26 checklist, as executable truth.

def _principal(role, scopes=()):
    return Principal(
        user_id="u", email="u@x.local", role=role, org_id=None,
        is_active=True, mfa_enabled=False, language="en",
        scopes=tuple(scopes),
        permissions=frozenset(ROLE_PERMISSIONS.get(role, set())))


def test_viewer_cannot_modify_shipment():
    p = _principal("ANALYST_VIEWER")
    assert not p.has_permissions(("MODIFY_SHIPMENT",))


def test_field_officer_cannot_modify_shipment():
    p = _principal("FIELD_OFFICER")
    assert not p.has_permissions(("MODIFY_SHIPMENT",))


def test_district_officer_x_cannot_touch_district_y():
    p = _principal("DISTRICT_OFFICER",
                   scopes=(GeoScope("DISTRICT", district_code="DIST-X"),))
    assert not p.in_geo_scope("IN-MN", "DIST-Y")
    assert p.in_geo_scope("IN-MN", "DIST-X")


def test_logistics_officer_cannot_manage_users():
    p = _principal("LOGISTICS_OFFICER")
    assert not p.has_permissions(("MANAGE_USERS",))


def test_regional_authority_cannot_modify_model_or_system():
    p = _principal("REGIONAL_AUTHORITY")
    assert not p.has_permissions(("MANAGE_SYSTEM",))
    assert not p.has_permissions(("MANAGE_USERS",))


def test_super_admin_alone_holds_user_and_system_admin():
    p = _principal("SUPER_ADMIN")
    assert p.has_permissions(("MANAGE_USERS", "MANAGE_SYSTEM"))

# ============================================================ TOKEN VALIDATION

SECRET = "unit-test-jwt-secret"
import time as _time
NOW = int(_time.time())


def _token(claims, key=SECRET, alg="HS256"):
    return pyjwt.encode(claims, key, algorithm=alg)


def _good_claims():
    return {"sub": "user-1", "aud": "authenticated", "role": "authenticated",
            "iat": NOW, "exp": NOW + 600}


def test_valid_token_still_verifies():
    assert verify_access_token(_token(_good_claims()), SECRET, None)["sub"] \
        == "user-1"


def test_alg_none_token_is_rejected():
    tok = pyjwt.encode(_good_claims(), key="", algorithm="none")
    with pytest.raises(TokenError):
        verify_access_token(tok, SECRET, None)


def test_hs256_forgery_with_attacker_key_is_rejected():
    forged = pyjwt.encode(_good_claims(), "attacker-key", algorithm="HS256")
    with pytest.raises(TokenError):
        verify_access_token(forged, SECRET, None)


def test_missing_sub_claim_is_rejected():
    bad = {k: v for k, v in _good_claims().items() if k != "sub"}
    with pytest.raises(TokenError):
        verify_access_token(_token(bad), SECRET, None)


def test_missing_exp_claim_is_rejected():
    bad = {k: v for k, v in _good_claims().items() if k != "exp"}
    with pytest.raises(TokenError):
        verify_access_token(_token(bad), SECRET, None)


def test_garbage_bearer_is_rejected():
    with pytest.raises(TokenError):
        verify_access_token("not-a-jwt-at-all", SECRET, None)

# ============================================================ FILE UPLOADS

PNG = b"\x89PNG\r\n\x1a\n" + b"\x00" * 32
JPEG = b"\xff\xd8\xff\xe0" + b"\x00" * 32
WEBP = b"RIFF\x24\x00\x00\x00WEBPVP8 " + b"\x00" * 16
EXE = b"MZ\x90\x00\x03\x00\x00\x00" + b"\x00" * 32


def test_honest_png_upload_is_accepted_and_randomized():
    name, kind = validate_upload(filename="report.png",
                                 content_type="image/png", data=PNG)
    assert kind == "png"
    assert name != "report.png"
    assert name.endswith(".png")
    assert len(name.split(".")[0]) == 32          # uuid4 hex, no user input


def test_exe_renamed_to_jpg_is_caught_by_magic_bytes():
    with pytest.raises(UploadRejected):
        validate_upload(filename="photo.jpg", content_type="image/jpeg",
                        data=EXE)


def test_content_type_spoofing_is_caught():
    with pytest.raises(UploadRejected):          # text body claiming to be png
        validate_upload(filename="a.png", content_type="image/png",
                        data=b"<script>alert(1)</script>")


def test_extension_contradicting_content_type_is_rejected():
    with pytest.raises(UploadRejected):
        validate_upload(filename="a.png", content_type="image/jpeg", data=JPEG)


def test_disallowed_extensions_are_rejected():
    for bad in ("shell.sh", "doc.pdf", "archive.zip"):
        with pytest.raises(UploadRejected):
            validate_upload(filename=bad, content_type="application/octet-stream",
                            data=b"x")


def test_double_extension_and_path_traversal_are_rejected():
    for bad in ("evil.tar.jpg", "../../etc/passwd.jpg", "..\\win.jpg",
                "noext"):
        with pytest.raises(UploadRejected):
            validate_upload(filename=bad, content_type="image/png", data=PNG)


def test_oversized_and_empty_uploads_are_rejected(monkeypatch):
    monkeypatch.setenv("MAX_UPLOAD_BYTES", "100")
    from app.config import get_settings
    get_settings.cache_clear()
    try:
        with pytest.raises(UploadRejected):
            validate_upload(filename="big.png", content_type="image/png",
                            data=PNG + b"\x00" * 500)
        with pytest.raises(UploadRejected):
            validate_upload(filename="ok.png", content_type="image/png",
                            data=b"")
    finally:
        get_settings.cache_clear()


def test_webp_and_jpeg_magic_sniffers_agree_with_kind():
    # jpeg data maps to the 'jpg' family (canonical storage extension)
    assert sniff_kind(JPEG) in ("jpg", "jpeg")
    assert sniff_kind(WEBP) == "webp"
    assert sniff_kind(PNG) == "png"

# ============================================ LOGIN ABUSE / ENUMERATION / API
USER_ID = "11111111-2222-3333-4444-555555555555"


class _Result:
    def __init__(self, scalar=None, first=None):
        self._scalar, self._first = scalar, first

    def scalar(self):
        return self._scalar

    def mappings(self):
        return self

    def first(self):
        return self._first


class FakeSystemDB:
    """Covers login_attempts counting/inserts, profiles read, audit inserts."""

    def __init__(self, profile=None, failures=0):
        self.profile = profile
        self.failures = failures

    async def execute(self, query, params=None):
        sql = str(query)
        if "count(*)" in sql:
            return _Result(scalar=self.failures)
        if "from profiles" in sql:
            return _Result(first=self.profile)
        return _Result()                       # inserts (attempts / audit)


_ACTIVE_PROFILE = {"user_id": USER_ID, "role": "FIELD_OFFICER",
                   "is_active": True, "mfa_enabled": False}


class FakeAuthResponse:
    def __init__(self, status_code, payload):
        self.status_code = status_code
        self._payload = payload

    def json(self):
        return self._payload


class FakeSupabaseClient:
    status_code = 200
    payload = {
        "access_token": "tok", "refresh_token": "r", "expires_in": 3600,
        "user": {"id": USER_ID},
        "decoded_jwt": {"sub": USER_ID, "aal": "aal2"},
    }

    def __init__(self, **kw):
        pass

    async def __aenter__(self):
        return self

    async def __aexit__(self, *exc):
        return False

    async def post(self, url, **kw):
        if FakeSupabaseClient.status_code == 200:
            return FakeAuthResponse(200, FakeSupabaseClient.payload)
        return FakeAuthResponse(FakeSupabaseClient.status_code, {})


@pytest.fixture
def api(monkeypatch):
    """Fresh app per test: isolated rate-limit buckets + fake Supabase."""
    monkeypatch.setattr("app.auth.router.httpx.AsyncClient",
                        FakeSupabaseClient)
    from app.core.db import get_system_db
    from app.main import create_app

    application = create_app()
    fake_db = FakeSystemDB(profile=_ACTIVE_PROFILE)
    application.dependency_overrides[get_system_db] = lambda: fake_db
    client = TestClient(application, raise_server_exceptions=False)
    yield client, fake_db
    application.dependency_overrides.clear()


def _login(client, email="officer@ner.gov.in", password="longenough123"):
    return client.post("/api/v1/auth/login",
                       json={"email": email, "password": password})


def test_login_is_reachable_without_bearer(api):
    """Phase-26 fix regression: AuthGate must not brick the login path."""
    client, _ = api
    r = _login(client)
    assert not (r.status_code == 401 and
                r.json()["error"]["message"] == "authentication required")


def test_brute_force_lockout_returns_429_after_max_failures(api):
    client, db = api
    db.failures = 5                                  # == LOGIN_MAX_FAILURES
    r = _login(client)
    assert r.status_code == 429
    assert r.json()["error"]["code"] == "RATE_LIMITED"


def test_account_enumeration_is_uniform_across_failure_modes(api):
    client, db = api
    bodies = []

    # a) wrong password (supabase rejects)
    FakeSupabaseClient.status_code = 400
    bodies.append(_login(client).json()["error"])
    FakeSupabaseClient.status_code = 200

    # b) valid supabase credentials but no provisioned profile
    db.profile = None
    bodies.append(_login(client, email="ghost@ner.gov.in").json()["error"])

    # c) provisioned but disabled account
    db.profile = dict(_ACTIVE_PROFILE, is_active=False)
    bodies.append(_login(client, email="benched@ner.gov.in").json()["error"])

    assert {b["code"] for b in bodies} == {"UNAUTHENTICATED"}
    assert {b["message"] for b in bodies} == {"invalid credentials"}


def test_mfa_enforced_when_profile_requires_it(api):
    client, db = api
    db.profile = dict(_ACTIVE_PROFILE, mfa_enabled=True)
    FakeSupabaseClient.payload = {
        "access_token": "partial", "refresh_token": "r", "expires_in": 3600,
        "user": {"id": USER_ID},
        "decoded_jwt": {"sub": USER_ID, "aal": "aal1"},   # first factor only
    }
    r = _login(client)
    assert r.status_code == 200
    assert r.json().get("mfa_required") is True
    assert "access_token" not in r.json()

# ============================================================ API SURFACE

def test_oversized_request_body_rejected_before_auth():
    from app.main import create_app
    client = TestClient(create_app())
    huge = "x" * (1_048_576 + 1)
    r = client.post("/api/v1/assistant/ask", content=huge,
                    headers={"Content-Type": "application/json"})
    assert r.status_code == 413
    assert r.json()["error"]["code"] == "PAYLOAD_TOO_LARGE"


def test_malformed_json_yields_validation_error_not_500():
    from app.main import create_app
    client = TestClient(create_app())
    token = mint_token(str(uuid.uuid4()))
    r = client.post("/api/v1/assistant/ask", content="{not json,,",
                    headers={"Content-Type": "application/json",
                             "Authorization": f"Bearer {token}"})
    assert r.status_code in (400, 422)               # never a 500 leak


def test_cors_allows_only_configured_origins():
    from app.main import create_app
    client = TestClient(create_app())
    preflight = {"Origin": "http://localhost:5500",
                 "Access-Control-Request-Method": "POST"}
    ok = client.options("/api/v1/auth/login", headers=preflight)
    assert ok.headers.get("access-control-allow-origin") \
        == "http://localhost:5500"

    evil = client.options("/api/v1/auth/login",
                          headers={"Origin": "https://evil.example",
                                   "Access-Control-Request-Method": "POST"})
    assert evil.headers.get("access-control-allow-origin") is None



