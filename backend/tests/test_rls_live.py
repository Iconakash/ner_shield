"""LIVE RLS / authorization harness — runs ONLY against a disposable local
Supabase/PostgreSQL stack (supabase start && RUN_SECURITY_IT=1 pytest).
NEVER targets production or shared environments.

Attack matrix executed with real claim-GUC-backed connections:
  * cross-district read via RLS
  * unauthorized write through grants/RLS
  * audit immutability (UPDATE/DELETE blocked by trigger)
"""
import uuid

import pytest
import pytest_asyncio
from sqlalchemy import text

from conftest import RUN_IT

pytestmark = [
    pytest.mark.integration,
    pytest.mark.skipif(not RUN_IT, reason="RUN_SECURITY_IT != 1"),
]


@pytest_asyncio.fixture(scope="module")
async def env():
    from pathlib import Path

    from sqlalchemy.ext.asyncio import create_async_engine
    REPO = Path(__file__).resolve().parents[2]
    engine = create_async_engine(
        "postgresql+asyncpg://postgres:postgres@127.0.0.1:54322/postgres")
    async with engine.begin() as conn:
        for f in sorted((REPO / "database").glob("*/*.sql")):
            await conn.execute(text(f.read_text(encoding="utf-8")))

    async def make_user(label, role, level=None, state=None, district=None):
        uid = str(uuid.uuid4())
        email = f"{label}-{uid[:8]}@rls.local"
        async with engine.begin() as conn:
            await conn.execute(text("""
                insert into auth.users (instance_id, id, aud, role, email,
                    encrypted_password, email_confirmed_at, created_at,
                    updated_at)
                values ('00000000-0000-0000-0000-000000000000',
                        cast(:id as uuid), 'authenticated', 'authenticated',
                        :email, 'x', now(), now())
            """), {"id": uid, "email": email})
            row = (await conn.execute(text(
                "select id from auth.users where email = :e"),
                {"e": email})).scalar()
            org = (await conn.execute(text(
                "select id from organizations limit 1"))).scalar()
            await conn.execute(text("""
                insert into profiles (user_id, email, role, org_id)
                values (cast(:u as uuid), :e, cast(:r as user_role),
                        cast(:o as uuid))
                on conflict (user_id) do nothing
            """), {"u": str(row), "e": email, "r": role, "o": str(org)})
            if level == "REGION":
                await conn.execute(text(
                    "insert into user_geo_assignments (user_id, level)"
                    " values (cast(:u as uuid), 'REGION')"), {"u": str(row)})
            elif state:
                await conn.execute(text(
                    "insert into user_geo_assignments (user_id, level,"
                    " state_code) values (cast(:u as uuid), 'STATE', :s)"),
                    {"u": str(row), "s": state})
            elif district:
                await conn.execute(text(
                    "insert into user_geo_assignments (user_id, level,"
                    " district_code) values (cast(:u as uuid), 'DISTRICT',"
                    " :d)"), {"u": str(row), "d": district})
        return {"id": str(row), "email": email}

    users = {
        "super": await make_user("super", "SUPER_ADMIN", level="REGION"),
        "dist_a": await make_user("da", "DISTRICT_OFFICER",
                                  district="IN-AS-KA"),
        "analyst_b": await make_user("anb", "ANALYST_VIEWER", state="IN-MN"),
    }
    yield {"engine": engine, "users": users}
    await engine.dispose()


async def _scoped_conn(engine, user_id):
    """Connection carrying this user's claim GUC — the channel RLS sees."""
    conn = await engine.connect()
    await conn.execute(text(
        "select set_config('request.jwt.claim.sub', :s, true)"),
        {"s": user_id})
    return conn


async def test_cross_district_geo_protected_read_blocked(env):
    """DISTRICT-scoped officer cannot read another district's protected rows
    through the geo_protected_resources pattern table (RLS policy check)."""
    engine = env["engine"]
    super_id = env["users"]["super"]["id"]

    async with engine.begin() as conn:
        await conn.execute(text("""
            insert into geo_protected_resources
                (title, state_code, district_code, created_by)
            values ('probe-ka', 'IN-AS', 'IN-AS-KA', cast(:a as uuid)),
                   ('probe-ie', 'IN-MN', 'IN-MN-IE', cast(:a as uuid))
        """), {"a": super_id})

    dist_a = env["users"]["dist_a"]["id"]
    conn = await _scoped_conn(engine, dist_a)
    visible = {r[0] for r in (await conn.execute(text(
        "select title from geo_protected_resources"
        " where title in ('probe-ka','probe-ie')")))}
    await conn.close()
    assert visible == {"probe-ka"}          # own district only


async def test_unauthorized_write_via_authenticated_role(env):
    """Authenticated-but-ungranted writes must be refused (grants/RLS)."""
    from sqlalchemy.exc import DBAPIError

    engine = env["engine"]
    analyst = env["users"]["analyst_b"]["id"]
    conn = await _scoped_conn(engine, analyst)
    refused = False
    try:
        await conn.execute(text(
            "insert into road_segments (road_id, seq)"
            " select id, 99 from roads limit 1"))
        await conn.rollback()
    except DBAPIError:
        refused = True
    finally:
        await conn.close()
    assert refused


async def test_audit_log_is_append_only_live(env):
    from sqlalchemy.exc import DBAPIError

    engine = env["engine"]
    super_id = env["users"]["super"]["id"]
    async with engine.begin() as conn:
        await conn.execute(text("""
            insert into audit_log (actor_id, actor_role, action, outcome)
            values (cast(:a as uuid), 'SUPER_ADMIN', 'RLS_TEST_PROBE',
                    'SUCCESS')
        """), {"a": super_id})

    conn = await engine.connect()
    with pytest.raises(DBAPIError):
        await conn.execute(text("update audit_log set action='TAMPERED'"))
    await conn.rollback()
    with pytest.raises(DBAPIError):
        await conn.execute(text("delete from audit_log"))
    await conn.close()


async def test_super_admin_sees_across_districts(env):
    """Positive control: REGION-scope admin reads all probe rows."""
    engine = env["engine"]
    conn = await _scoped_conn(engine, env["users"]["super"]["id"])
    visible = {r[0] for r in (await conn.execute(text(
        "select title from geo_protected_resources"
        " where title like 'probe-%'")))}
    await conn.close()
    assert {"probe-ka", "probe-ie"} <= visible
