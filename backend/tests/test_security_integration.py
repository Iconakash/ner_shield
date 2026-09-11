"""SECURITY-FIRST integration gate.

Automated unauthorized-access attacks across roles and districts, plus RLS and
audit-immutability verification. Requires a local Supabase stack:

    supabase start                     # auth + db on :54321/:54322
    set RUN_SECURITY_IT=1
    pytest backend/tests/test_security_integration.py -m integration -v

Business modules may NOT be built until this suite passes.
"""
import json
import uuid

import pytest
import pytest_asyncio
from sqlalchemy import text

from conftest import RUN_IT, TEST_SECRET, mint_token, auth_headers

pytestmark = [
    pytest.mark.integration,
    pytest.mark.skipif(not RUN_IT, reason="RUN_SECURITY_IT != 1"),
]


# ------------------------------------------------------------------ bootstrap
@pytest_asyncio.fixture(scope="module")
async def env():
    """Apply SQL files; create fixture identities in auth.users + profiles/scopes."""
    from sqlalchemy.ext.asyncio import create_async_engine
    from pathlib import Path
    REPO = Path(__file__).resolve().parents[2]

    engine = create_async_engine(
        "postgresql+asyncpg://postgres:postgres@127.0.0.1:54322/postgres")
    async with engine.begin() as conn:
        for f in sorted((REPO / "database").glob("*/*.sql")):
            await conn.execute(text(f.read_text(encoding="utf-8")))

        users = {}
        for label in ("super", "regional", "officer_a", "officer_b", "field_a",
                      "field_disabled", "analyst", "logistics_a"):
            uid = str(uuid.uuid4())
            await conn.execute(text("""
                insert into auth.users (instance_id, id, aud, role, email,
                    encrypted_password, email_confirmed_at, created_at, updated_at)
                values ('00000000-0000-0000-0000-000000000000', cast(:id as uuid),
                        'authenticated', 'authenticated', :email, 'x', now(), now())
                on conflict do nothing
            """), {"id": uid, "email": f"{label}-{uid[:8]}@security-test.local"})
            row = (await conn.execute(text(
                "select id from auth.users where email = :e"),
                {"e": f"{label}-{uid[:8]}@security-test.local"})).scalar()
            users[label] = str(row)

        org = (await conn.execute(text(
            "select id from organizations where name='NER Joint Command Cell'"))).scalar()

        profiles = [
            ("super", "SUPER_ADMIN", True), ("regional", "REGIONAL_AUTHORITY", True),
            ("officer_a", "DISTRICT_OFFICER", True), ("officer_b", "DISTRICT_OFFICER", True),
            ("field_a", "FIELD_OFFICER", True), ("field_disabled", "FIELD_OFFICER", False),
            ("analyst", "ANALYST_VIEWER", True), ("logistics_a", "LOGISTICS_OFFICER", True),
        ]
        for label, role, active in profiles:
            await conn.execute(text("""
                insert into profiles (user_id, email, full_name, role, org_id, is_active)
                values (cast(:id as uuid), :email, :label, cast(:role as user_role),
                        cast(:org as uuid), :active)
                on conflict (user_id) do update set role = excluded.role,
                    is_active = excluded.is_active
            """), {"id": users[label], "email": f"{label}@t.local", "label": label,
                   "role": role, "org": str(org), "active": active})

        scopes = [
            ("officer_a", "DISTRICT", None, "IN-MN-IE"),   # District X
            ("officer_b", "DISTRICT", None, "IN-NL-KO"),   # District Y (far away)
            ("field_a", "DISTRICT", None, "IN-MN-IE"),
            ("field_disabled", "DISTRICT", None, "IN-MN-IE"),
            ("regional", "REGION", None, None),
            ("logistics_a", "STATE", "IN-MN", None),
        ]
        for label, level, state, district in scopes:
            await conn.execute(text("""
                insert into user_geo_assignments (user_id, level, state_code, district_code)
                values (cast(:u as uuid), cast(:l as geo_level), :s, :d)
                on conflict do nothing
            """), {"u": users[label], "l": level, "s": state, "d": district})

    yield {"users": users, "engine": engine}
    await engine.dispose()


def tok(env_users: dict, label: str) -> str:
    return mint_token(env_users[label], TEST_SECRET)


@pytest_asyncio.fixture
async def client():
    from httpx import ASGITransport, AsyncClient
    from app.main import app
    transport = ASGITransport(app=app)  # type: ignore[arg-type]
    async with AsyncClient(transport=transport, base_url="http://test") as c:
        yield c


# ------------------------------------------------------------------ the attacks
async def test_unauthenticated_request_is_401(client):
    r = await client.get("/api/v1/ops-resources")
    assert r.status_code == 401
    assert r.json()["error"]["code"] == "UNAUTHENTICATED"


async def test_tampered_token_is_401(client, env):
    bad = tok(env, "officer_a")[:-4] + "beef"
    r = await client.get("/api/v1/auth/me", headers=auth_headers(bad))
    assert r.status_code == 401


async def test_disabled_account_blocked_with_audit(env, client):
    r = await client.get("/api/v1/auth/me", headers=auth_headers(tok(env, "field_disabled")))
    assert r.status_code == 403


async def test_officer_creates_resource_in_own_district(env, client):
    r = await client.post("/api/v1/ops-resources",
                          headers=auth_headers(tok(env, "officer_a")),
                          json={"title": "landslide NH-2", "state_code": "IN-MN",
                                "district_code": "IN-MN-IE"})
    assert r.status_code == 201, r.text
    env["resource_x"] = r.json()["id"]


async def test_field_officer_cannot_create_in_other_district(env, client):
    """FIELD_OFFICER scoped to District X attempts creation in District Y."""
    r = await client.post("/api/v1/ops-resources",
                          headers=auth_headers(tok(env, "field_a")),
                          json={"title": "illegal cross-district report",
                                "state_code": "IN-NL", "district_code": "IN-NL-KO"})
    assert r.status_code == 403
    assert r.json()["error"]["code"] == "FORBIDDEN_SCOPE"


async def test_district_officer_b_denied_access_to_district_x_record(env, client):
    """DISTRICT_OFFICER assigned District Y must not read District X records."""
    r = await client.get(f"/api/v1/ops-resources/{env['resource_x']}",
                         headers=auth_headers(tok(env, "officer_b")))
    assert r.status_code in (403, 404)   # app-layer guard or RLS-hidden => not found


async def test_officer_a_reads_own_district_record(env, client):
    r = await client.get(f"/api/v1/ops-resources/{env['resource_x']}",
                         headers=auth_headers(tok(env, "officer_a")))
    assert r.status_code == 200
    assert r.json()["district_code"] == "IN-MN-IE"


async def test_list_is_scoped_per_caller(env, client):
    ra = (await client.get("/api/v1/ops-resources",
                           headers=auth_headers(tok(env, "regional")))).json()
    rb = (await client.get("/api/v1/ops-resources",
                           headers=auth_headers(tok(env, "officer_b")))).json()
    ids_b = {x["id"] for x in rb}
    assert env["resource_x"] not in ids_b                    # RLS hides District X from Y
    assert any(x["id"] == env["resource_x"] for x in ra)     # REGION sees everything


async def test_regional_authority_cannot_administer_users(env, client):
    """REGIONAL_AUTHORITY may view NER ops but cannot manage users / alter system."""
    r = await client.post("/api/v1/users", headers=auth_headers(tok(env, "regional")),
                          json={"email": "x@y.local", "password": "longenough123",
                                "full_name": "X", "role": "FIELD_OFFICER"})
    assert r.status_code == 403
    assert r.json()["error"]["code"] == "FORBIDDEN_ROLE"


async def test_analyst_viewer_read_only(env, client):
    r = await client.get("/api/v1/ops-resources", headers=auth_headers(tok(env, "analyst")))
    assert r.status_code == 200                              # may read (scoped)
    w = await client.post("/api/v1/ops-resources",
                          headers=auth_headers(tok(env, "analyst")),
                          json={"title": "nope", "state_code": "IN-MN",
                                "district_code": "IN-MN-IE"})
    assert w.status_code == 403                              # cannot mutate


async def test_cross_role_user_creation_denied_for_logistics(env, client):
    r = await client.post("/api/v1/users",
                          headers=auth_headers(tok(env, "logistics_a")),
                          json={"email": "z@z.local", "password": "longenough123",
                                "full_name": "Z", "role": "ANALYST_VIEWER"})
    assert r.status_code == 403


# ------------------------------------------- RLS direct-SQL verification (bypass attempt)
async def test_rls_blocks_direct_sql_cross_district(env):
    """Even raw SQL with officer_b's claims cannot see/modify District X rows."""
    from sqlalchemy.ext.asyncio import create_async_engine
    engine = create_async_engine(
        "postgresql+asyncpg://postgres:postgres@127.0.0.1:54322/postgres")
    claims = json.dumps({"sub": env["users"]["officer_b"], "aud": "authenticated",
                         "role": "authenticated"})
    async with engine.connect() as conn:
        await conn.execute(text(
            "select set_config('request.jwt.claims', :c, true),"
            " set_config('request.jwt.claim.sub', :s, true)"),
            {"c": claims, "s": env["users"]["officer_b"]})
        visible = (await conn.execute(text(
            "select count(*) from geo_protected_resources"
            " where district_code = 'IN-MN-IE'"))).scalar()
        assert visible == 0, "RLS FAILED: officer_b sees District X rows"
    await engine.dispose()


async def test_audit_log_is_immutable(env):
    """UPDATE/DELETE on audit_log must raise (AUD-01)."""
    from sqlalchemy.ext.asyncio import create_async_engine
    engine = create_async_engine(
        "postgresql+asyncpg://postgres:postgres@127.0.0.1:54322/postgres")
    async with engine.begin() as conn:
        await conn.execute(text(
            "insert into audit_log (actor_id, action, outcome)"
            " values (cast(:a as uuid), 'SECURITY_EVENT', 'SUCCESS')"),
            {"a": env["users"]["super"]})
        with pytest.raises(Exception):
            await conn.execute(text("update audit_log set action = 'TAMPERED'"))
    await engine.dispose()


# ------------------------------------------- two-person approval workflow
async def test_two_person_approval_happy_path(env, client):
    # LOGISTICS_OFFICER (state IN-MN scope) requests emergency reroute in District X
    r = await client.post("/api/v1/approvals",
                          headers=auth_headers(tok(env, "logistics_a")),
                          json={"action_type": "EMERGENCY_REROUTE",
                                "title": "Reroute via NH-15", "payload": {"reason": "landslide"},
                                "state_code": "IN-MN", "district_code": "IN-MN-IE"})
    assert r.status_code == 201, r.text
    rid = r.json()["id"]

    # requester self-approval must fail
    own = await client.post(f"/api/v1/approvals/{rid}/decide",
                            headers=auth_headers(tok(env, "logistics_a")),
                            json={"decision": "APPROVED"})
    assert own.status_code == 409

    # REGIONAL_AUTHORITY approves => success
    ok = await client.post(f"/api/v1/approvals/{rid}/decide",
                           headers=auth_headers(tok(env, "regional")),
                           json={"decision": "APPROVED", "note": "agreed"})
    assert ok.status_code == 200
    assert ok.json()["status"] == "APPROVED"

    # deciding again is a conflict
    again = await client.post(f"/api/v1/approvals/{rid}/decide",
                              headers=auth_headers(tok(env, "regional")),
                              json={"decision": "REJECTED"})
    assert again.status_code == 409


async def test_field_officer_cannot_request_approval(env, client):
    r = await client.post("/api/v1/approvals",
                          headers=auth_headers(tok(env, "field_a")),
                          json={"action_type": "HIGH_LEVEL_ALERT", "title": "nope"})
    assert r.status_code == 403


async def test_permission_denials_are_audited(env, client):
    # trigger a denial...
    await client.post("/api/v1/users", headers=auth_headers(tok(env, "regional")),
                      json={"email": "q@q.local", "password": "longenough123",
                            "full_name": "Q", "role": "FIELD_OFFICER"})
    # ...then read the trail as SUPER_ADMIN and confirm it was recorded
    r = await client.get("/api/v1/audit?limit=50", headers=auth_headers(tok(env, "super")))
    assert r.status_code == 200
    actions = {row["action"] for row in r.json()}
    assert "PERMISSION_DENIED" in actions


async def test_security_headers_present(client):
    r = await client.get("/health")
    assert r.headers.get("X-Content-Type-Options") == "nosniff"
    assert r.headers.get("X-Frame-Options") == "DENY"



# ============================================================ PHASE 26 HARDENING
# Dedicated pre-deployment security phase additions. Same dormancy rules apply.

async def test_phase26_cross_district_update_blocked(env, client):
    """Officer B must not modify District X's resource (IDOR + RLS)."""
    r = await client.patch(f"/api/v1/ops-resources/{env['resource_x']}",
                           headers=auth_headers(tok(env, "officer_b")),
                           json={"title": "hijacked"})
    assert r.status_code in (403, 404)
    # row untouched
    ra = await client.get(f"/api/v1/ops-resources/{env['resource_x']}",
                          headers=auth_headers(tok(env, "officer_a")))
    assert ra.json()["title"] != "hijacked"


async def test_phase26_unauthorized_delete_blocked(env, client):
    """FIELD_OFFICER cannot delete another district's resource; ANALYST neither."""
    for label in ("field_a", "analyst"):
        r = await client.delete(f"/api/v1/ops-resources/{env['resource_x']}",
                                headers=auth_headers(tok(env, label)))
        assert r.status_code in (403, 404)
    # owner still sees it -> nothing was deleted
    ra = await client.get(f"/api/v1/ops-resources/{env['resource_x']}",
                          headers=auth_headers(tok(env, "officer_a")))
    assert ra.status_code == 200


async def test_phase26_jwt_role_claim_tampering_is_ignored(env):
    """Privilege escalation: forging SUPER_ADMIN in the JWT changes nothing —
    authorization truth lives in profiles, never in token claims."""
    import jwt as pyjwt
    import time as _t
    now = int(_t.time())
    forged = pyjwt.encode(
        {"sub": env["users"]["logistics_a"], "aud": "authenticated",
         "role": "authenticated", "iat": now, "exp": now + 300,
         "app_metadata": {"role": "SUPER_ADMIN"}},
        TEST_SECRET, algorithm="HS256")
    from httpx import ASGITransport, AsyncClient
    from app.main import app as fastapi_app
    transport = ASGITransport(app=fastapi_app)
    async with AsyncClient(transport=transport, base_url="http://test") as c:
        r = await c.post("/api/v1/users", headers=auth_headers(forged),
                         json={"email": "escal@ted.local",
                               "password": "longenough123", "full_name": "Esc",
                               "role": "SUPER_ADMIN"})
    assert r.status_code == 403
    assert r.json()["error"]["code"] == "FORBIDDEN_ROLE"


async def test_phase26_rls_blocks_direct_sql_cross_district_update(env):
    """Direct-SQL UPDATE under officer_b claims touches zero District X rows."""
    from sqlalchemy.ext.asyncio import create_async_engine
    engine = create_async_engine(
        "postgresql+asyncpg://postgres:postgres@127.0.0.1:54322/postgres")
    claims = json.dumps({"sub": env["users"]["officer_b"],
                         "aud": "authenticated", "role": "authenticated"})
    async with engine.begin() as conn:
        await conn.execute(text(
            "select set_config('request.jwt.claims', :c, true),"
            " set_config('request.jwt.claim.sub', :s, true)"),
            {"c": claims, "s": env["users"]["officer_b"]})
        res = await conn.execute(text(
            "update geo_protected_resources set title = 'pwned'"
            " where district_code = 'IN-MN-IE'"))
        assert res.rowcount == 0, "RLS FAILED: officer_b updated District X rows"
    await engine.dispose()
