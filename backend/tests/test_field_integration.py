"""PHASE 13 integration gate — the human + AI feedback loop end-to-end.
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
                            ("field_a", "FIELD_OFFICER"),
                            ("officer_mn", "DISTRICT_OFFICER"),
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
              (cast(:fa as uuid), 'DISTRICT', null, 'IN-MN-IE'),
              (cast(:lmn as uuid), 'STATE', 'IN-MN', null)
            on conflict do nothing
        """), {"fa": users["field_a"], "lmn": users["logistics_mn"]})

    yield {"users": users, "engine": engine}
    await engine.dispose()


@pytest_asyncio.fixture
async def clients(env):
    from httpx import ASGITransport, AsyncClient
    from app.main import app
    made = {}
    for label in ("super", "field_a", "officer_mn", "logistics_mn"):
        headers = auth_headers(mint_token(env["users"][label], TEST_SECRET))
        made[label] = AsyncClient(
            transport=ASGITransport(app=app),  # type: ignore[arg-type]
            base_url="http://test", headers=headers)
    try:
        yield made
    finally:
        for c in made.values():
            await c.aclose()

async def test_field_report_drives_the_full_loop(env, clients):
    """Convoy on NH-02 + CRITICAL landslide report -> whole loop fires."""
    admin, field, logi, officer = (clients["admin"], clients["field_a"],
                                   clients["logistics_mn"], clients["officer_mn"])

    created = await logi.post("/api/v1/shipments", json={
        "title": "Medicine resupply Imphal",
        "commodity": "MEDICINE", "priority": "CRITICAL",
        "origin": {"facility_code": "WH-KOH-DIPR"},
        "destination": {"facility_code": "HOSP-RIMS"}})
    assert created.status_code == 201, created.text
    sid = created.json()["id"]
    await logi.post(f"/api/v1/shipments/{sid}/assign-vehicle",
                    json={"vehicle_code": "MN-T-101"})
    await logi.post(f"/api/v1/shipments/{sid}/assign-route",
                    json={"road_code": "NH-02"})
    await admin.post("/api/v1/accessibility/run")   # baseline engines
    await admin.post("/api/v1/risk/run")

    report = await field.post("/api/v1/field/reports", json={
        "incident_type": "LANDSLIDE", "severity": "CRITICAL",
        "lon": 93.98, "lat": 25.30,
        "description": "Entire carriageway blocked by debris",
        "photo_name": "landslide_01.jpg"})
    assert report.status_code == 201, report.text
    body = report.json()
    assert body["status"] == "SUBMITTED"
    assert body["confidence"] >= 75                 # v2 model, GPS accuracy unknown
    assert body["nearest_segment"]

    validated = await officer.post(
        f"/api/v1/field/reports/{body['id']}/validate",
        json={"decision": "VALIDATED", "note": "confirmed via patrol"})
    assert validated.status_code == 200, validated.text
    loop = validated.json()["loop"]
    assert loop["accessibility_run"]["targets_scored"] > 0
    assert loop["risk_run"]["targets"] > 0
    assert loop.get("alert_id")                     # ROAD_WARNING alert fired
    assert any(e["shipment_id"] == sid
               for e in loop["eta_recalculations"]) # convoy ETA recalculated

    # segment physically CLOSED by the structural failure; signal injected
    from sqlalchemy import text
    from sqlalchemy.ext.asyncio import create_async_engine
    engine = create_async_engine(
        "postgresql+asyncpg://postgres:postgres@127.0.0.1:54322/postgres")
    async with engine.connect() as conn:
        st = (await conn.execute(text(
            "select status::text from road_segments where id = cast(:s as uuid)"),
            {"s": body["nearest_segment"]})).scalar()
        sig = (await conn.execute(text("""
            select count(*) from geo_factor_signals
            where signal_kind = 'LANDSLIDE_RISK'
              and target_type = 'ROAD_SEGMENT'
              and segment_id = cast(:s as uuid)
        """), {"s": body["nearest_segment"]})).scalar()
    await engine.dispose()
    assert st == "CLOSED"
    assert int(sig) >= 1


async def test_out_of_scope_submission_denied(env, clients):
    """FIELD_OFFICER scoped to Manipur cannot file reports in Nagaland."""
    r = await clients["field_a"].post("/api/v1/field/reports", json={
        "incident_type": "FLOOD", "severity": "HIGH",
        "lon": 94.11, "lat": 25.67})                # Kohima
    assert r.status_code == 403
    assert r.json()["error"]["code"] == "FORBIDDEN_SCOPE"


async def test_field_officer_cannot_validate(env, clients):
    r = await clients["field_a"].post("/api/v1/field/reports/x/validate",
                                      json={"decision": "VALIDATED"})
    assert r.status_code == 403                     # lacks VERIFY_INCIDENT


# ------------------------------------------------- PHASE 14: corroboration boost
async def test_corroborating_report_raises_confidence(env, clients):
    """A second independent officer reporting the same incident nearby must
    increase the next reporter's confidence via the corroboration component."""
    import uuid as _uuid
    from pathlib import Path
    from sqlalchemy import text
    from sqlalchemy.ext.asyncio import create_async_engine

    REPO = Path(__file__).resolve().parents[2]
    engine = create_async_engine(
        "postgresql+asyncpg://postgres:postgres@127.0.0.1:54322/postgres")

    # seed one prior independent LANDSLIDE report 300 m away, <72 h old
    async with engine.begin() as conn:
        uid = str(_uuid.uuid4())
        email = f"peer-{uid[:8]}@t.local"
        await conn.execute(text("""
            insert into auth.users (instance_id, id, aud, role, email,
                encrypted_password, email_confirmed_at, created_at, updated_at)
            values ('00000000-0000-0000-0000-000000000000', cast(:id as uuid),
                    'authenticated', 'authenticated', :email, 'x', now(), now())
            on conflict do nothing
        """), {"id": uid, "email": email})
        peer = (await conn.execute(text(
            "select id from auth.users where email = :e"), {"e": email})).scalar()
        org = (await conn.execute(text(
            "select id from organizations limit 1"))).scalar()
        seg = (await conn.execute(text("""
            select rs.id from road_segments rs
            join districts d on d.code = rs.district_code
            where d.code = 'IN-MN-IW' limit 1
        """))).scalar()
        await conn.execute(text("""
            insert into field_reports (code, reported_by, incident_type,
                severity, geom, state_code, district_code, nearest_segment,
                status)
            values ('FR-PEER-1', cast(:u as uuid), 'LANDSLIDE', 'HIGH',
                    st_setsrid(st_makepoint(93.981, 25.302), 4326),
                    'IN-MN', 'IN-MN-IW', cast(:s as uuid), 'VALIDATED')
        """), {"u": str(peer), "s": str(seg)})

    # now field_a submits the same landslide nearby => corroboration counted
    r = await clients["field_a"].post("/api/v1/field/reports", json={
        "incident_type": "LANDSLIDE", "severity": "CRITICAL",
        "lon": 93.982, "lat": 25.303,
        "description": "second independent confirmation",
        "photo_name": "landslide_02.jpg",
        "gps_accuracy_m": 8.0})
    assert r.status_code == 201, r.text
    body = r.json()
    assert body["confidence"] >= 90                 # solo ceiling 85 + corroboration
    assert body["confidence_breakdown"]["corroboration"]["independent_reports"] == 1
    await engine.dispose()


