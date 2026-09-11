"""PHASE 8 impact engine integration tests — blast radius of a failing segment.
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
        for label, role in (("super", "SUPER_ADMIN"),
                            ("logistics_mn", "LOGISTICS_OFFICER")):
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
            org = (await conn.execute(text(
                "select id from organizations where name='NER Logistics Wing'"
                " union all select id from organizations limit 1"))).scalar()
            await conn.execute(text("""
                insert into profiles (user_id, email, role, org_id)
                values (cast(:u as uuid), :e, cast(:r as user_role), cast(:o as uuid))
                on conflict (user_id) do update set role = excluded.role
            """), {"u": users[label], "e": email, "r": role, "o": str(org)})

        await conn.execute(text("""
            insert into user_geo_assignments (user_id, level, state_code)
            values (cast(:u as uuid), 'STATE', 'IN-MN') on conflict do nothing
        """), {"u": users["logistics_mn"]})

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
    admin = make("super")
    logi = make("logistics_mn")
    try:
        yield admin, logi
    finally:
        await admin.aclose()
        await logi.aclose()

async def test_segment_failure_blast_radius(env, clients):
    """Route a shipment over NH-02 -> run engines -> assess the Imphal segment."""
    admin, logi = clients

    created = await logi.post("/api/v1/shipments", json={
        "title": "Essential food to Imphal West",
        "commodity": "EMERGENCY_FOOD", "priority": "HIGH",
        "origin": {"facility_code": "WH-KOH-DIPR"},
        "destination": {"facility_code": "WH-IMP-FCS"}})
    assert created.status_code == 201, created.text
    sid = created.json()["id"]
    await logi.post(f"/api/v1/shipments/{sid}/assign-vehicle",
                    json={"vehicle_code": "MN-T-101"})
    rt = await logi.post(f"/api/v1/shipments/{sid}/assign-route",
                         json={"road_code": "NH-02"})
    assert rt.status_code == 200, rt.text

    acc = await admin.post("/api/v1/accessibility/run")
    assert acc.status_code == 200
    pred = await admin.post("/api/v1/risk/run")
    assert pred.status_code == 200

    segs = (await admin.get("/api/v1/gis/segments",
                            params={"district_code": "IN-MN-IW"})).json()
    assert segs, "expected NH-02 segments in Imphal West"
    seg_id = segs[0]["id"]

    assessed = await admin.post("/api/v1/impact/assess",
                                json={"segment_id": seg_id})
    assert assessed.status_code == 200, assessed.text
    body = assessed.json()

    # headline output mandated by the source document, e.g. "IMPACT: CRITICAL"
    assert body["impact"] in ("CRITICAL", "HIGH", "MODERATE", "LOW")

    affected = body["affected"]
    shipped_ids = {s["id"] for s in affected["shipments"]}
    assert sid in shipped_ids, "routed shipment must appear in blast radius"
    assert affected["total_population_affected"] >= 99_000   # Kohima town alone
    assert any(w["code"] == "WH-IMP-FCS" for w in affected["warehouses"])
    assert any(h["code"] == "HOSP-RIMS" for h in affected["hospitals"])
    assert len(affected["districts"]) >= 1

    comps = body["components"]
    assert set(comps) == {"population", "essential_supplies",
                          "critical_facilities", "alternatives", "duration"}
    assert abs(sum(c["weight"] for c in comps.values()) - 1.0) < 1e-6


async def test_impact_assessments_immutable(env, clients):
    from sqlalchemy import text
    from sqlalchemy.ext.asyncio import create_async_engine
    engine = create_async_engine(
        "postgresql+asyncpg://postgres:postgres@127.0.0.1:54322/postgres")
    async with engine.begin() as conn:
        await conn.execute(text("""
            insert into impact_assessments (impact_score, impact_label,
                components, weights_version, expected_duration_hours,
                summary_sentence)
            values (50, 'HIGH', '{}'::jsonb, 1, 24, 'test row')
        """))
        with pytest.raises(Exception):
            await conn.execute(text(
                "update impact_assessments set impact_score = 0"))
    await engine.dispose()

