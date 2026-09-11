"""PHASE 12 security suite (offline-capable portion).

Covers: GPS spoofing/replay/duplicate/invalid-timestamp handling at the trust
layer, device credential uniform-failure, upload path-traversal and polyglot
content rejection, per-IP rate-limit isolation, auth-gate consistency across
every registered /api route, and error-envelope information disclosure.
Live-database attacks (RLS bypass, cross-district/cross-org) run in
test_rls_live.py against a disposable local stack only.
"""
import sys as _sys
from datetime import datetime, timedelta, timezone
from pathlib import Path

import pytest

BACKEND = Path(__file__).resolve().parents[1]
if str(BACKEND) not in _sys.path:
    _sys.path.insert(0, str(BACKEND))

from fastapi.testclient import TestClient  # noqa: E402

from app.gps import schemas as gps_schemas  # noqa: E402
from app.gps import service as gps_svc  # noqa: E402
from app.main import PUBLIC_PATHS, create_app  # noqa: E402


def _client():
    return TestClient(create_app(), raise_server_exceptions=False)


# ------------------------------------------------------- GPS attack surface
def _fix(**over):
    base = dict(latitude=26.14, longitude=91.73,
                timestamp=datetime.now(timezone.utc))
    base.update(over)
    return gps_schemas.TelemetryIn(**base)


@pytest.mark.parametrize("lat,lon", [
    (12.97, 77.59),     # Bengaluru â€” outside NER
    (-33.9, 151.2),     # Sydney
    (35.0, 139.0),      # Tokyo-ish
])
def test_spoofed_coordinates_rejected(lat, lon):
    assert gps_schemas.validate_coordinates(lat, lon) is not None


def test_boundary_coordinates_within_envelope_accepted():
    assert gps_schemas.validate_coordinates(22.0, 88.0) is None
    assert gps_schemas.validate_coordinates(29.5, 97.0) is None


def test_replayed_timestamp_rejected():
    old = datetime.now(timezone.utc) - timedelta(seconds=301)
    assert "stale" in gps_schemas.validate_timestamp(old)


def test_future_timestamp_rejected():
    future = datetime.now(timezone.utc) + timedelta(seconds=61)
    assert "future" in gps_schemas.validate_timestamp(future)


def test_duplicate_telemetry_yields_identical_hash_for_dedup():
    t = _fix(speed_kph=42)
    assert gps_svc.payload_hash("D1", t) == gps_svc.payload_hash("D1", t)
    assert gps_svc.payload_hash("D1", t) != gps_svc.payload_hash("D2", t)


async def test_device_auth_uniform_failure(monkeypatch):
    """Unknown device code and wrong secret must be indistinguishable."""

    class _Result:
        def __init__(self, row):
            self._row = row

        def mappings(self):
            return self

        def first(self):
            return self._row

    class _DB:
        def __init__(self, row):
            self.row = row

        async def execute(self, *a, **k):
            return _Result(self.row)

    empty = _DB(None)
    with pytest.raises(Exception) as e1:
        await gps_svc.authenticate_device(empty, "ghost-device", "whatever")
    stored = {"id": "x", "device_code": "D1", "status": "ACTIVE",
              "secret_hash": gps_svc._hash_secret("real")}
    with pytest.raises(Exception) as e2:
        await gps_svc.authenticate_device(_DB(stored), "D1", "wrong-secret")
    assert str(e1.value) == str(e2.value)          # uniform denial


def test_device_rate_limit_blocks_flood():
    gps_svc._hits.clear()
    original = gps_svc._DEVICE_RATE
    try:
        gps_svc._DEVICE_RATE = 5
        allowed = sum(1 for _ in range(8) if gps_svc._rate_allow("FLOODER"))
        assert allowed == 5
    finally:
        gps_svc._DEVICE_RATE = original


# ------------------------------------------------------------- uploads / paths
def test_upload_rejects_path_traversal_filenames():
    from app.core import uploads

    png = b"\x89PNG\r\n\x1a\n" + b"0" * 64
    with pytest.raises(uploads.UploadRejected):
        uploads.validate_upload(filename="../../../../etc/passwd.png",
                                content_type="image/png", data=png)


def test_upload_storage_name_is_server_generated_and_safe():
    from app.core import uploads

    png = b"\x89PNG\r\n\x1a\n" + b"0" * 64
    name, kind = uploads.validate_upload(filename="holiday photo.PNG",
                                         content_type="image/png", data=png)
    assert kind == "png"
    assert ".." not in name and "/" not in name and "\\" not in name
    assert name.endswith(".png") and len(name) == 32 + 4   # uuid hex + ext


def test_polyglot_gif_php_rejected():
    from app.core import uploads

    evil = b"GIF89a" + b"<?php system($_GET['c']); ?>"
    with pytest.raises(uploads.UploadRejected):
        uploads.validate_upload(filename="x.gif", content_type="image/gif",
                                data=evil)


# ------------------------------------------------------------ API gate matrix
def test_every_api_route_rejects_anonymous_requests():
    """No /api route may respond 2xx/5xx to a tokenless request: every path is
    either in PUBLIC_PATHS (explicit decision) or gated by the bearer chain."""
    app = create_app()
    client = _client()
    for path in app.openapi()["paths"]:
        if not path.startswith("/api/") or path in PUBLIC_PATHS:
            continue
        for method in ("get", "post"):
            fn = getattr(client, method)
            try:
                r = fn(path, json={})
            except Exception:  # noqa: BLE001 â€” transport errors are fine
                continue
            if r.status_code == 404:
                continue          # method not defined on this path
            assert r.status_code in (401, 403, 405, 422), \
                f"{method.upper()} {path} returned {r.status_code} anonymously"


def test_error_envelope_never_leaks_stack_traces():
    r = _client().post("/api/v1/routing/plan", data="{not json",
                       headers={"Authorization": "Bearer x.t.z",
                                "Content-Type": "application/json"})
    body = r.text.lower()
    for leak in ("traceback", ".py'", "exception:", 'file "'):
        assert leak not in body


def test_login_bucket_is_stricter_than_general_api():
    from app.middleware.security import RateLimitMiddleware

    mw = RateLimitMiddleware(app=None)
    assert mw._bucket_for("/api/v1/auth/login") == 10
    assert mw._bucket_for("/api/v1/shipments") == \
        mw._settings.RATE_LIMIT_PER_MINUTE

