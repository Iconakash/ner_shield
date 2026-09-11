"""PHASE 18 Command Center integration tests — summary + live layers.
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
        for label in ("super", "regional", "analyst"):
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
                    "analyst": "ANALYST_VIEWER"}[label]
            org = (await conn.execute(text(
                "select id from organizations limit 1"))).scalar()
            await conn.execute(text("""
                insert into profiles (user_id, email, role, org_id)
                values (cast(:u as uuid), :e, cast(:r as user_role),
                        cast(:o as uuid))
                on conflict (user_id) do update set role = excluded.role
            """), {"u": users[label], "e": email, "r": role, "o": str(org)})

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
    return {"super": make("super"), "analyst": make("analyst")}


# ------------------------------------------------------------------ summary
async def test_summary_returns_exactly_six_tiles(clients):
    async with clients["super"] as c:
        r = await c.get("/api/v1/command/summary")
    assert r.status_code == 200
    body = r.json()
    assert [k["id"] for k in body["kpis"]] == [
        "critical_alerts", "high_risk_roads", "active_shipments",
        "critical_shipments", "supply_risk_districts",
        "predicted_disruptions"]
    assert all(isinstance(k["count"], int) and k["count"] >= 0
               for k in body["kpis"])
    assert body["generated_at"]


async def test_summary_readable_by_analyst_viewer(clients):
    """FR-C16.1: read-only awareness surface for scoped viewers."""
    async with clients["analyst"] as c:
        r = await c.get("/api/v1/command/summary")
    assert r.status_code == 200


# ------------------------------------------------------------------- layers
LAYER_URLS = ["high-risk-roads", "disruptions", "shipments", "weather"]


@pytest.mark.parametrize("name", LAYER_URLS)
async def test_layers_are_feature_collections(clients, name):
    async with clients["super"] as c:
        r = await c.get(f"/api/v1/command/layers/{name}")
    assert r.status_code == 200
    body = r.json()
    assert body["type"] == "FeatureCollection"
    assert isinstance(body["features"], list)


async def test_unknown_layer_is_404_with_known_list(clients):
    async with clients["super"] as c:
        r = await c.get("/api/v1/command/layers/nope")
    assert r.status_code == 404
    assert "high-risk-roads" in str(r.json())


async def test_command_requires_authentication():
    from httpx import ASGITransport, AsyncClient
    from app.main import app
    async with AsyncClient(transport=ASGITransport(app=app),  # type: ignore[arg-type]
                           base_url="http://test") as anon:
        r = await anon.get("/api/v1/command/summary")
    assert r.status_code == 401

