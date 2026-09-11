"""PHASE 19 Action Center integration tests — recommendations endpoint.
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
        uid = str(_uuid.uuid4())
        email = f"super-{uid[:8]}@t.local"
        await conn.execute(text("""
            insert into auth.users (instance_id, id, aud, role, email,
                encrypted_password, email_confirmed_at, created_at, updated_at)
            values ('00000000-0000-0000-0000-000000000000', cast(:id as uuid),
                    'authenticated', 'authenticated', :email, 'x', now(), now())
        """), {"id": uid, "email": email})
        row = (await conn.execute(text(
            "select id from auth.users where email = :e"), {"e": email})).scalar()
        org = (await conn.execute(text(
            "select id from organizations limit 1"))).scalar()
        await conn.execute(text("""
            insert into profiles (user_id, email, role, org_id)
            values (cast(:u as uuid), :e, 'SUPER_ADMIN', cast(:o as uuid))
        """), {"u": str(row), "e": email, "o": str(org)})
    yield {"super_uid": str(row), "engine": engine}
    await engine.dispose()


@pytest_asyncio.fixture
async def super_client(env):
    from httpx import ASGITransport, AsyncClient
    from app.main import app
    headers = auth_headers(mint_token(env["super_uid"], TEST_SECRET))
    async with AsyncClient(transport=ASGITransport(app=app),  # type: ignore[arg-type]
                           base_url="http://test", headers=headers) as c:
        yield c


async def test_recommendations_contract(super_client):
    r = await super_client.get("/api/v1/decisions/recommendations")
    assert r.status_code == 200
    body = r.json()
    assert set(body) >= {"recommendations", "generated_at", "contract"}
    assert body["contract"] == ["reason", "confidence", "affected_entities",
                                "expected_impact", "recommended_action",
                                "approval_required"]
    for rec in body["recommendations"]:
        assert set(body["contract"]) <= set(rec)
        scores = [x["priority_score"] for x in body["recommendations"]]
        assert scores == sorted(scores, reverse=True)


async def test_recommendations_require_auth():
    from httpx import ASGITransport, AsyncClient
    from app.main import app
    async with AsyncClient(transport=ASGITransport(app=app),  # type: ignore[arg-type]
                           base_url="http://test") as anon:
        r = await anon.get("/api/v1/decisions/recommendations")
    assert r.status_code == 401
