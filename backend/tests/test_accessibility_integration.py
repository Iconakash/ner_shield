"""PHASE 5 accessibility integration tests — signal fusion -> score -> reproducibility.
Gated: local Supabase stack + RUN_SECURITY_IT=1.
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
        email = f"acc-admin-{uid[:8]}@t.local"
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
        # one Manipur segment id for targeted signals
        seg = (await conn.execute(text(
            "select rs.id::text from road_segments rs"
            " join districts d on d.code = rs.district_code"
            " where d.code = 'IN-MN-IW' limit 1"))).scalar()

    yield {"admin": str(row), "segment_id": seg, "engine": engine}
    await engine.dispose()


@pytest_asyncio.fixture
async def client(env):
    from httpx import ASGITransport, AsyncClient
    from app.main import app
    headers = {"Authorization": f"Bearer {mint_token(env['admin'], TEST_SECRET)}"}
    async with AsyncClient(transport=ASGITransport(app=app),  # type: ignore[arg-type]
                           base_url="http://test", headers=headers) as c:
        yield c


async def test_signal_ingestion_and_full_pass(env, client):
    sid = env["segment_id"]
    r = await client.post("/api/v1/accessibility/signals", json={"signals": [
        {"signal_kind": "WEATHER", "target_type": "ROAD_SEGMENT",
         "segment_id": sid, "value": 30, "source": "sim-meteo"},
        {"signal_kind": "FLOOD_RISK", "target_type": "ROAD_SEGMENT",
         "segment_id": sid, "value": 40, "source": "sim-hydro"},
        {"signal_kind": "LANDSLIDE_RISK", "target_type": "ROAD_SEGMENT",
         "segment_id": sid, "value": 35, "source": "sim-geo"},
        {"signal_kind": "TRAFFIC", "target_type": "ROAD_SEGMENT",
         "segment_id": sid, "value": 70, "source": "sim-traffic"},
        {"signal_kind": "HISTORICAL_RELIABILITY", "target_type": "ROAD_SEGMENT",
         "segment_id": sid, "value": 60, "source": "sim-history"},
    ]})
    assert r.status_code == 202 and r.json()["accepted"] == 5

    run = await client.post("/api/v1/accessibility/run")
    assert run.status_code == 200, run.text
    body = run.json()
    assert body["road_segment"]["targets_scored"] > 0
    assert body["weights_version"] == 1

    latest = await client.get("/api/v1/accessibility/segments",
                              params={"district_code": "IN-MN-IW"})
    rows = latest.json()
    target_rows = [x for x in rows if x["segment_id"] == sid]
    assert target_rows, "scored segment missing from latest list"
    row = target_rows[0]
    comp = row["components"]
    assert comp["weather"]["value"] == 30.0 and comp["weather"]["assumed"] is False
    assert comp["infrastructure"]["assumed"] is False       # derived from surface
    expected = (comp["infrastructure"]["contribution"] + comp["weather"]["contribution"]
                + comp["flood_risk"]["contribution"] + comp["landslide_risk"]["contribution"]
                + comp["traffic"]["contribution"]
                + comp["historical_reliability"]["contribution"])
    assert abs(row["score"] - round(expected, 2)) < 0.05    # weighted-sum identity
    assert row["classification"] in ("SAFE", "CAUTION", "HIGH_RISK", "CRITICAL")


async def test_scores_are_immutable(env, client):
    from sqlalchemy import text
    from sqlalchemy.ext.asyncio import create_async_engine
    engine = create_async_engine(
        "postgresql+asyncpg://postgres:postgres@127.0.0.1:54322/postgres")
    async with engine.begin() as conn:
        with pytest.raises(Exception):
            await conn.execute(text(
                "update accessibility_scores set score = 100"))
    await engine.dispose()
