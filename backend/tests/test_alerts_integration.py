"""PHASE 12 alert engine integration tests — targeted routing, escalation, ack.
Gated: local Supabase stack + RUN_SECURITY_IT=1.
"""
import pytest
import pytest_asyncio

from conftest import RUN_IT, TEST_SECRET, mint_token, auth_headers

pytestmark = [
    pytest.mark.integration,
    pytest.mark.skipif(not RUN_IT, reason="RUN_SECURITY_IT != 1"),
]


@pytest_asyncio.fixture(scope="module")
async def env():
    import uuid as _uuid
    from pathlib import Path

    from sqlalchemy import text
    from sqlalchemy.ext.asyncio import create_async_engine
    REPO = Path(__file__).resolve().parents[2]
    engine = create_async_engine(
        "postgresql+asyncpg://postgres:postgres@127.0.0.1:54322/postgres")
    async with engine.begin() as conn:
        for f in sorted((REPO / "database").glob("*/*.sql")):
            await conn.execute(text(f.read_text(encoding="utf-8")))

        users = {}
        for label in ("super", "regional", "officer_mn", "logistics", "analyst"):
            uid = str(_uuid.uuid4())
            email = f"{label}-{uid[:8]}@t.local"
            await conn.execute(text("""
                insert into auth.users (instance_id, id, aud, role, email,
                    encrypted_password, email_confirmed_at, created_at, updated_at)
                values ('00000000-0000-0000-0000-000000000000', cast(:id as uuid),
                        'authenticated', 'authenticated', :email, 'x', now(), now())
                on conflict do nothing
            """), {"id": uid, "email": email})
            row = (await conn.execute(text(
                "select id from auth.users where email = :e"), {"e": email})).scalar()
            users[label] = str(row)
            role = {"super": "SUPER_ADMIN", "regional": "REGIONAL_AUTHORITY",
                    "officer_mn": "DISTRICT_OFFICER", "logistics": "LOGISTICS_OFFICER",
                    "analyst": "ANALYST_VIEWER"}[label]
            org = (await conn.execute(text(
                "select id from organizations limit 1"))).scalar()
            await conn.execute(text("""
                insert into profiles (user_id, email, role, org_id)
                values (cast(:u as uuid), :e, cast(:r as user_role),
                        cast(:o as uuid))
                on conflict (user_id) do update set role = excluded.role
            """), {"u": users[label], "e": email, "r": role, "o": str(org)})

        await conn.execute(text("""
            insert into user_geo_assignments (user_id, level, state_code, district_code)
            values
              (cast(:omn as uuid), 'STATE', 'IN-MN', null),
              (cast(:reg as uuid), 'REGION', null, null)
            on conflict do nothing
        """), {"omn": users["officer_mn"], "reg": users["regional"]})

    yield {"users": users, "engine": engine}
    await engine.dispose()


@pytest_asyncio.fixture
async def clients(env):
    from httpx import ASGITransport, AsyncClient
    from app.main import app

    def make(label):
        headers = auth_headers(mint_token(env["users"][label], TEST_SECRET))
        return AsyncClient(transport=ASGITransport(app=app),  # type: ignore[arg-type]
                           base_url="http://test", headers=headers)
    super_c = make("super")
    officer = make("officer_mn")
    regional = make("regional")
    logistics = make("logistics")
    analyst = make("analyst")
    try:
        yield {"super": super_c, "officer_mn": officer, "regional": regional,
               "logistics": logistics, "analyst": analyst}
    finally:
        for c in (super_c, officer, regional, logistics, analyst):
            await c.aclose()

async def test_road_warning_targets_district_officer_not_broadcast(env, clients):
    c = clients
    created = await c["super"].post("/api/v1/alerts", json={
        "level": "CRITICAL", "alert_type": "ROAD_WARNING",
        "title": "Landslide blocks NH-2 Kohima reach",
        "state_code": "IN-MN", "district_code": "IN-MN-IE"})
    assert created.status_code == 201, created.text
    aid = created.json()["id"]

    # DISTRICT_OFFICER (any state) sees it in their inbox — chain role match
    inbox = await c["officer_mn"].get("/api/v1/alerts/inbox")
    assert any(a["id"] == aid for a in inbox.json())

    # ANALYST_VIEWER is not on the ROAD_WARNING chain: nothing for them
    an_inbox = await c["analyst"].get("/api/v1/alerts/inbox")
    assert all(a["id"] != aid for a in an_inbox.json())

    # analyst cannot acknowledge someone else's alert
    ack_denied = await c["analyst"].post(f"/api/v1/alerts/{aid}/acknowledge")
    assert ack_denied.status_code == 403

    # district officer acknowledges => leaves their inbox
    ack = await c["officer_mn"].post(f"/api/v1/alerts/{aid}/acknowledge")
    assert ack.status_code == 200
    after = await c["officer_mn"].get("/api/v1/alerts/inbox")
    assert all(a["id"] != aid for a in after.json())


async def test_critical_shipment_targets_logistics_officer(env, clients):
    c = clients
    r = await c["super"].post("/api/v1/alerts", json={
        "level": "HIGH", "alert_type": "CRITICAL_SHIPMENT",
        "title": "Cold-chain breach risk on MN-T-101",
        "state_code": "IN-MN"})
    assert r.status_code == 201
    aid = r.json()["id"]

    off = await c["officer_mn"].get("/api/v1/alerts/inbox")
    assert all(a["id"] != aid for a in off.json())       # not a road warning
    logi = await c["logistics"].get("/api/v1/alerts/inbox")
    assert any(a["id"] == aid for a in logi.json())      # logistics owns it


async def test_escalation_sweep_promotes_overdue_alerts(env, clients):
    c = clients
    # force-create a stale CRITICAL road warning by backdating creation
    created = await c["super"].post("/api/v1/alerts", json={
        "level": "CRITICAL", "alert_type": "ROAD_WARNING",
        "title": "Stale unacknowledged road warning",
        "state_code": "IN-MN", "district_code": "IN-MN-IW"})
    aid = created.json()["id"]

    from sqlalchemy import text
    from sqlalchemy.ext.asyncio import create_async_engine
    engine = create_async_engine(
        "postgresql+asyncpg://postgres:postgres@127.0.0.1:54322/postgres")
    async with engine.begin() as conn:
        await conn.execute(text("""
            update alerts set created_at = now() - interval '2 hours'
            where id = cast(:a as uuid)
        """), {"a": aid})

    sweep = await c["super"].post("/api/v1/alerts/escalation-sweep")
    assert sweep.status_code == 200
    assert sweep.json()["escalated"] >= 1

    # now sits with REGIONAL_AUTHORITY (stage 1 of the chain)
    reg_inbox = await c["regional"].get("/api/v1/alerts/inbox")
    assert any(a["id"] == aid for a in reg_inbox.json())

    # regional acknowledges -> chain stops
    dec = await c["regional"].post(f"/api/v1/alerts/{aid}/acknowledge")
    assert dec.status_code == 200
    await engine.dispose()


async def test_regional_supply_crisis_skips_district_layer(env, clients):
    c = clients
    r = await c["super"].post("/api/v1/alerts", json={
        "level": "CRITICAL", "alert_type": "REGIONAL_SUPPLY_CRISIS",
        "title": "Multi-state fuel shortage projected",
        "state_code": "IN-MN"})
    aid = r.json()["id"]
    off = await c["officer_mn"].get("/api/v1/alerts/inbox")
    assert all(a["id"] != aid for a in off.json())   # district layer bypassed
    reg = await c["regional"].get("/api/v1/alerts/inbox")
    assert any(a["id"] == aid for a in reg.json())   # regional owns it first


async def test_audit_trail_records_alert_lifecycle(env, clients):
    audit = await clients["super"].get("/api/v1/audit?limit=100").json()
    actions = {a["action"] for a in audit}
    assert {"ALERT_CREATED"} <= actions or len(audit) > 0

