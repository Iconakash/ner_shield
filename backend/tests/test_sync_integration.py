"""PHASE 15 offline-sync integration tests (C13/C14, OFF-01..06).
Gated: local Supabase stack + RUN_SECURITY_IT=1.
"""
import uuid as _uuid

import pytest
import pytest_asyncio

from conftest import RUN_IT, TEST_SECRET, mint_token, auth_headers

pytestmark = [
    pytest.mark.integration,
    pytest.mark.skipif(not RUN_IT, reason="RUN_SECURITY_IT != 1"),
]


@pytest_asyncio.fixture(scope="module")
async def env():
    import uuid as _uuid2
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
        for label in ("super", "field_mn", "logistics_mn"):
            uid = str(_uuid2.uuid4())
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
            role = {"super": "SUPER_ADMIN", "field_mn": "FIELD_OFFICER",
                    "logistics_mn": "LOGISTICS_OFFICER"}[label]
            org = (await conn.execute(text(
                "select id from organizations limit 1"))).scalar()
            await conn.execute(text("""
                insert into profiles (user_id, email, role, org_id)
                values (cast(:u as uuid), :e, cast(:r as user_role),
                        cast(:o as uuid))
                on conflict (user_id) do update set role = excluded.role
            """), {"u": users[label], "e": email, "r": role, "o": str(org)})

        await conn.execute(text("""
            insert into user_geo_assignments (user_id, level, state_code)
            values (cast(:fm as uuid), 'STATE', 'IN-MN'),
                   (cast(:lm as uuid), 'STATE', 'IN-MN')
            on conflict do nothing
        """), {"fm": users["field_mn"], "lm": users["logistics_mn"]})

    yield {"users": users, "engine": engine}
    await engine.dispose()


@pytest_asyncio.fixture
async def clients(env):
    from httpx import ASGITransport, AsyncClient
    from app.main import app
    made = {}
    for label in ("super", "field_mn", "logistics_mn"):
        headers = auth_headers(mint_token(env["users"][label], TEST_SECRET))
        made[label] = AsyncClient(
            transport=ASGITransport(app=app),  # type: ignore[arg-type]
            base_url="http://test", headers=headers)
    try:
        yield made
    finally:
        for c in made.values():
            await c.aclose()


async def _routed_shipment(logi):
    r = await logi.post("/api/v1/shipments", json={
        "title": "Offline-ping target", "commodity": "WATER",
        "priority": "NORMAL",
        "origin": {"facility_code": "WH-KOH-DIPR"},
        "destination": {"facility_code": "WH-IMP-FCS"}})
    assert r.status_code == 201, r.text
    sid = r.json()["id"]
    assert (await logi.post(f"/api/v1/shipments/{sid}/assign-vehicle",
                            json={"vehicle_code": "MN-T-101"})).status_code == 200
    assert (await logi.post(f"/api/v1/shipments/{sid}/assign-route",
                            json={"road_code": "NH-02"})).status_code == 200
    return sid

async def test_push_field_report_idempotent(env, clients):
    field, _ = clients["field_mn"], None
    op_id = str(_uuid.uuid4())
    body = {"device_code": "dev-test-01", "ops": [{
        "client_op_id": op_id, "op_type": "FIELD_REPORT",
        "payload": {"incident_type": "LANDSLIDE", "severity": "HIGH",
                    "lon": 93.98, "lat": 25.30,
                    "description": "offline capture",
                    "client_op_id": op_id}}]}

    first = await field.post("/api/v1/sync/push", json=body)
    assert first.status_code == 200, first.text
    assert first.json()["results"][0]["status"] == "ACCEPTED"

    # same client_op_id replayed after a crash => DUPLICATE, no second row
    replay = await field.post("/api/v1/sync/push", json=body)
    assert replay.json()["results"][0]["status"] == "DUPLICATE"

    from sqlalchemy import text
    from sqlalchemy.ext.asyncio import create_async_engine
    engine = create_async_engine(
        "postgresql+asyncpg://postgres:postgres@127.0.0.1:54322/postgres")
    async with engine.connect() as conn:
        n = (await conn.execute(text(
            "select count(*) from field_reports where client_op_id = :o"),
            {"o": op_id})).scalar()
    await engine.dispose()
    assert n == 1


async def test_gps_ping_sync_triggers_eta_recalculate(env, clients):
    admin, field, logi = (clients["super"], clients["field_mn"],
                          clients["logistics_mn"])
    sid = await _routed_shipment(logi)
    await admin.post("/api/v1/accessibility/run")
    await admin.post("/api/v1/risk/run")

    op_id = str(_uuid.uuid4())
    r = await field.post("/api/v1/sync/push", json={"ops": [{
        "client_op_id": op_id, "op_type": "GPS_PING",
        "payload": {"shipment_id": sid, "lon": 93.98, "lat": 25.20,
                    "speed_kph": 38}}]})
    assert r.status_code == 200, r.text
    res = r.json()["results"][0]
    assert res["status"] == "ACCEPTED"
    assert res["eta"]["eta_minutes"] > 0            # RECALCULATE step ran

    # duplicate ping is absorbed
    dup = await field.post("/api/v1/sync/push", json={"ops": [{
        "client_op_id": op_id, "op_type": "GPS_PING",
        "payload": {"shipment_id": sid, "lon": 93.98, "lat": 25.20}}]})
    assert dup.json()["results"][0]["status"] == "DUPLICATE"


async def test_out_of_scope_ping_rejected(env, clients):
    """FIELD_OFFICER scoped to Manipur cannot push pings for Nagaland routes."""
    _, field, logi = clients["field_mn"], None, clients["logistics_mn"]
    sid = await _routed_shipment(logi)
    r = await field.post("/api/v1/sync/push", json={"ops": [{
        "client_op_id": str(_uuid.uuid4()), "op_type": "GPS_PING",
        "payload": {"shipment_id": sid, "lon": 94.11, "lat": 25.67}}]})
    assert r.status_code == 200                      # batch-level OK
    res = r.json()["results"][0]
    assert res["status"] == "REJECTED"               # op itself denied


async def test_pull_returns_scoped_cache_data(env, clients):
    super_c, field, logi = clients["super"], clients["field_mn"], \
        clients["logistics_mn"]
    await _routed_shipment(logi)
    data = await field.get("/api/v1/sync/pull?cursor=0")
    assert data.status_code == 200
    body = data.json()
    assert len(body["shipments"]) >= 1
    assert all(s["dest_district"].startswith("IN-MN")
               for s in body["shipments"])           # geo-scoped cache feed


async def test_unauthenticated_sync_denied(clients):
    from httpx import ASGITransport, AsyncClient
    from app.main import app
    async with AsyncClient(transport=ASGITransport(app=app),  # type: ignore[arg-type]
                           base_url="http://test") as anon:
        r = await anon.get("/api/v1/sync/pull")
    assert r.status_code == 401

