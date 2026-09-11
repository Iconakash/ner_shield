"""PHASE 3 GIS integration tests — PostGIS spatial operations over the seeded subset.

Gated like the security suite: local Supabase stack + RUN_SECURITY_IT=1.
    set RUN_SECURITY_IT=1 && python -m pytest tests/test_gis_integration.py -m integration -v
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
    """Apply all SQL (idempotent), then provision one ANALYST_VIEWER (VIEW_MAP)."""
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
        email = f"gis-viewer-{uid[:8]}@t.local"
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
            values (cast(:u as uuid), :e, 'ANALYST_VIEWER', cast(:o as uuid))
            on conflict (user_id) do update set role = 'ANALYST_VIEWER'
        """), {"u": str(row), "e": email, "o": str(org)})

    yield {"viewer": str(row), "engine": engine}
    await engine.dispose()


@pytest_asyncio.fixture
async def client(env):
    from httpx import ASGITransport, AsyncClient
    from app.main import app
    transport = ASGITransport(app=app)  # type: ignore[arg-type]
    headers = {"Authorization": f"Bearer {mint_token(env['viewer'], TEST_SECRET)}"}
    async with AsyncClient(transport=transport, base_url="http://test",
                           headers=headers) as c:
        yield c


# ------------------------------------------------------------------ ST_Contains
async def test_locate_point_inside_imphal_east(client):
    r = await client.get("/api/v1/gis/locate", params={"lon": 93.94, "lat": 24.66})
    assert r.status_code == 200, r.text
    assert r.json()["district_code"] == "IN-MN-IE"
    assert r.json()["state_code"] == "IN-MN"


async def test_locate_point_outside_subset_errors(client):
    r = await client.get("/api/v1/gis/locate", params={"lon": 77.20, "lat": 28.61})  # Delhi
    assert r.status_code == 400


# ------------------------------------------------------- ST_DWithin + ST_Distance
async def test_facilities_near_rims_ordered_by_distance(client):
    """Hospitals within 50 km of RIMS Imphal: nearest first, distance attached."""
    r = await client.get("/api/v1/gis/facilities", params={
        "facility_type": "HOSPITAL", "near_lon": 93.87, "near_lat": 24.79,
        "radius_m": 50000})
    assert r.status_code == 200, r.text
    feats = r.json()["features"]
    codes = [f["properties"]["code"] for f in feats]
    assert "HOSP-RIMS" in codes
    dists = [f["properties"]["distance_m"] for f in feats]
    assert dists == sorted(dists), "ST_Distance ordering violated"
    assert dists[0] < 5000, "RIMS should be ~0 m from the query point"
    assert r.json()["query"]["operation"] == "ST_DWithin + ST_Distance"


async def test_radius_excludes_far_hospital(client):
    """Guwahati hospital (~250 km away) must not appear in the 50 km Imphal radius."""
    r = await client.get("/api/v1/gis/facilities", params={
        "facility_type": "HOSPITAL", "near_lon": 93.87, "near_lat": 24.79,
        "radius_m": 50000})
    codes = {f["properties"]["code"] for f in r.json()["features"]}
    assert "HOSP-GMCH" not in codes


# ------------------------------------------------------------------ ST_Intersects
async def test_roads_intersecting_imphal_east(client):
    r = await client.get("/api/v1/gis/roads", params={"district_code": "IN-MN-IE"})
    assert r.status_code == 200
    codes = {f["properties"]["code"] for f in r.json()["features"]}
    assert {"NH-02", "NH-102A"} <= codes       # both touch Imphal East
    assert "NH-51" not in codes                # Meghalaya link must not match Manipur


# ------------------------------------------------------------------ seed integrity
async def test_segments_have_geo_assignment_and_length(client):
    r = await client.get("/api/v1/gis/segments", params={"district_code": "IN-MN-IW"})
    assert r.status_code == 200
    segs = r.json()["features"]
    assert segs, "expected NH-02 segments assigned to Imphal West"
    for s in segs:
        assert s["properties"]["district_code"] == "IN-MN-IW"
        assert s["properties"]["length_m"] > 0


async def test_gis_summary_counts(client):
    r = await client.get("/api/v1/gis/summary")
    assert r.status_code == 200
    s = r.json()
    assert s["states"] == 8
    assert s["districts_with_geom"] == 24
    assert s["roads"] >= 9 and s["facilities"] >= 20
    assert s["railways"] >= 3 and s["waterways"] >= 2


# ------------------------------------------------------------------ security chain
async def test_gis_requires_authentication():
    from httpx import ASGITransport, AsyncClient
    from app.main import app
    transport = ASGITransport(app=app)  # type: ignore[arg-type]
    async with AsyncClient(transport=transport, base_url="http://test") as c:
        r = await c.get("/api/v1/gis/states")
    assert r.status_code == 401

