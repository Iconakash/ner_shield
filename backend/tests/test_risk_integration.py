"""PHASE 6 integration gate: weather ingest -> prediction run -> explanation output.
Gated like all suites: local Supabase + RUN_SECURITY_IT=1.
"""
import pytest
import pytest_asyncio

from conftest import RUN_IT, TEST_SECRET, mint_token

pytestmark = [
    pytest.mark.integration,
    pytest.mark.skipif(not RUN_IT, reason="RUN_SECURITY_IT != 1"),
]


@pytest_asyncio.fixture(scope="module")
async def env():
    import uuid
    from pathlib import Path

    from sqlalchemy import text
    from sqlalchemy.ext.asyncio import create_async_engine
    REPO = Path(__file__).resolve().parents[2]
    engine = create_async_engine(
        "postgresql+asyncpg://postgres:postgres@127.0.0.1:54322/postgres")
    async with engine.begin() as conn:
        for f in sorted((REPO / "database").glob("*/*.sql")):
            await conn.execute(text(f.read_text(encoding="utf-8")))

        uid = str(uuid.uuid4())
        email = f"risk-admin-{uid[:8]}@t.local"
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
            "select id from organizations order by created_at limit 1"))).scalar()
        await conn.execute(text("""
            insert into profiles (user_id, email, role, org_id)
            values (cast(:u as uuid), :e, 'SUPER_ADMIN', cast(:o as uuid))
            on conflict (user_id) do update set role = 'SUPER_ADMIN'
        """), {"u": str(row), "e": email, "o": str(org)})

    yield {"admin": str(row), "engine": engine}
    await engine.dispose()


@pytest_asyncio.fixture
async def client(env):
    from httpx import ASGITransport, AsyncClient
    from app.main import app
    headers = {"Authorization": f"Bearer {mint_token(env['admin'], TEST_SECRET)}"}
    async with AsyncClient(transport=ASGITransport(app=app),  # type: ignore[arg-type]
                           base_url="http://test", headers=headers) as c:
        yield c


async def test_prediction_pass_produces_five_horizons_with_explanations(client):
    run = await client.post("/api/v1/risk/run")
    assert run.status_code == 200, run.text
    body = run.json()
    assert body["targets_predicted"] > 0

    latest = (await client.get("/api/v1/risk/latest")).json()
    assert len(latest) == body["targets_predicted"]
    for p in latest[:5]:
        horizons = [p["risk_current"], p["risk_6h"], p["risk_12h"],
                    p["risk_24h"], p["risk_72h"]]
        assert all(0 <= v <= 100 for v in horizons)
        assert p["overall_label"] in ("LOW", "GUARDED", "ELEVATED", "HIGH", "CRITICAL")
        assert p["top_factors"], "AI-01: explanation mandatory"
        for f in p["top_factors"]:
            assert f["label"] and isinstance(f["contribution"], (int, float))


async def test_predictions_immutable(env, client):
    from sqlalchemy import text
    from sqlalchemy.ext.asyncio import create_async_engine
    engine = create_async_engine(
        "postgresql+asyncpg://postgres:postgres@127.0.0.1:54322/postgres")
    async with engine.begin() as conn:
        with pytest.raises(Exception):
            await conn.execute(text(
                "update disruption_predictions set risk_24h = 0"))
    await engine.dispose()
