"""PHASE 6 routing integration tests — modes, avoid-lists, multi-stop over the
real PostGIS road network. Gated: local Supabase stack + RUN_SECURITY_IT=1.
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

        uid = str(_uuid.uuid4())
        email = f"router-{uid[:8]}@t.local"
        await conn.execute(text("""
            insert into auth.users (instance_id, id, aud, role, email,
                encrypted_password, email_confirmed_at, created_at, updated_at)
            values ('00000000-0000-0000-0000-000000000000', cast(:id as uuid),
                    'authenticated', 'authenticated', :email, 'x', now(), now())
            on conflict do nothing
        """), {"id": uid, "email": email})
        row = (await conn.execute(text(
            "select id from auth.users where email = :e"), {"e": email})).scalar()
        org = (await conn.execute(text(
            "select id from organizations limit 1"))).scalar()
        await conn.execute(text("""
            insert into profiles (user_id, email, role, org_id)
            values (cast(:u as uuid), :e, 'LOGISTICS_OFFICER', cast(:o as uuid))
            on conflict (user_id) do update set role = excluded.role
        """), {"u": str(row), "e": email, "o": str(org)})
        await conn.execute(text("""
            insert into user_geo_assignments (user_id, level)
            values (cast(:u as uuid), 'REGION')
        """), {"u": str(row)})

    yield {"user": str(row), "engine": engine}
    await engine.dispose()


@pytest_asyncio.fixture
async def client(env):
    from httpx import ASGITransport, AsyncClient

    from app.main import app
    headers = auth_headers(mint_token(env["user"], TEST_SECRET))
    async with AsyncClient(transport=ASGITransport(app=app),  # type: ignore[arg-type]
                           base_url="http://test", headers=headers) as c:
        yield c, env["engine"]


async def _two_facilities(db):
    from sqlalchemy import text
    rows = (await db.execute(text(
        "select code from facilities order by code limit 2"))).mappings().all()
    return [r["code"] for r in rows]


async def test_modes_catalog(client):
    c, _ = client
    r = await c.get("/api/v1/routing/modes")
    assert r.status_code == 200
    assert {m["id"] for m in r.json()["modes"]} >= {
        "shortest", "fastest", "safest", "balanced", "emergency"}


async def test_plan_all_modes_never_use_closed_segments(client):
    c, engine = client
    from sqlalchemy import text
    async with engine.connect() as conn:
        codes = await _two_facilities(conn)
        closed = {r[0] for r in (await conn.execute(text(
            "select id::text from road_segments where status = 'CLOSED'")))}
    if len(codes) < 2:
        pytest.skip("need 2 seeded facilities")
    seen = set()
    for mode in ("fastest", "safest", "emergency"):
        r = await c.post("/api/v1/routing/plan", json={
            "origin": {"facility_code": codes[0]},
            "destination": {"facility_code": codes[1]},
            "k": 3, "mode": mode})
        if r.status_code == 404:      # sparse seed may disconnect OD pairs
            continue
        assert r.status_code == 200, r.text
        data = r.json()
        assert data["mode"] == mode and data["closed_segments_excluded"] is True
        used = {s["segment_id"] for s in data["recommended"]["segments"]}
        assert used.isdisjoint(closed), "route used a CLOSED segment!"
        if mode == "emergency" and data["recommended"]["risk_pct"] >= 45:
            assert data["recommended"]["warning"]
        seen.add(mode)
    assert seen


async def test_plan_honors_avoid_segment_ids(client):
    c, engine = client
    from sqlalchemy import text
    async with engine.connect() as conn:
        codes = await _two_facilities(conn)
        seg = (await conn.execute(text(
            "select id::text from road_segments limit 1"))).scalar()
    r = await c.post("/api/v1/routing/plan", json={
        "origin": {"facility_code": codes[0]},
        "destination": {"facility_code": codes[1]},
        "mode": "balanced", "avoid_segment_ids": [seg]})
    if r.status_code == 404:
        pytest.skip("network too sparse after avoidance")
    assert r.status_code == 200
    data = r.json()
    assert seg in data["avoided_segments"]
    for alt in data["alternatives"]:
        assert seg not in {s["segment_id"] for s in alt["segments"]}


async def test_multi_stop_plans_round_trip(client):
    c, engine = client
    from sqlalchemy import text
    async with engine.connect() as conn:
        codes = [r[0] for r in (await conn.execute(text(
            "select code from facilities order by code limit 3")))]
    if len(codes) < 3:
        pytest.skip("need 3 seeded facilities")
    r = await c.post("/api/v1/routing/multi-stop", json={
        "stops": [{"facility_code": c} for c in codes],
        "mode": "balanced", "return_to_origin": True})
    if r.status_code == 404:
        pytest.skip("some leg unroutable in minimal seed")
    assert r.status_code == 200, r.text
    data = r.json()
    assert data["stop_order"][0] == 0 and data["stop_order"][-1] == 0
    assert sorted(data["stop_order"]) == list(range(3))
    assert len(data["legs"]) == 3
    assert "avg_risk_pct" in data["totals"]


async def test_routing_requires_authentication():
    from httpx import ASGITransport, AsyncClient

    from app.main import app
    async with AsyncClient(transport=ASGITransport(app=app),  # type: ignore[arg-type]
                           base_url="http://test") as anon:
        r = await anon.get("/api/v1/routing/modes")
    assert r.status_code == 401

