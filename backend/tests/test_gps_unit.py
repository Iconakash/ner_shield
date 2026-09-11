"""GPS device trust-layer unit tests — pure validators, secret handling,
and endpoint wiring. DB-backed flows are covered by the integration suite."""
import sys as _sys
from datetime import datetime, timedelta, timezone
from pathlib import Path

import pytest

BACKEND = Path(__file__).resolve().parents[1]
if str(BACKEND) not in _sys.path:
    _sys.path.insert(0, str(BACKEND))

from app.gps.schemas import (  # noqa: E402
    TelemetryIn, payload_hash, validate_coordinates, validate_timestamp)
from app.gps import service as gps  # noqa: E402


def fix(**over) -> TelemetryIn:
    base = dict(latitude=26.14, longitude=91.73,               # Guwahati-ish
                timestamp=datetime.now(timezone.utc))
    base.update(over)
    return TelemetryIn(**base)


# ------------------------------------------------------------- coordinates
def test_valid_ner_fix_passes():
    assert validate_coordinates(26.14, 91.73) is None


def test_fix_outside_ner_bbox_rejected_as_spoof():
    reason = validate_coordinates(12.97, 77.59)     # Bengaluru — far outside NER
    assert reason and "spoofing" in reason


def test_extreme_lat_lon_rejected_by_schema():
    with pytest.raises(Exception):
        fix(latitude=123.0)


# -------------------------------------------------------------- timestamps
def test_fresh_observation_passes():
    assert validate_timestamp(datetime.now(timezone.utc)) is None


def test_stale_observation_flagged_for_replay():
    old = datetime.now(timezone.utc) - timedelta(minutes=10)
    reason = validate_timestamp(old)
    assert reason and "stale" in reason


def test_future_timestamp_beyond_skew_flagged():
    future = datetime.now(timezone.utc) - timedelta(seconds=-600)
    reason = validate_timestamp(future)
    assert reason and "future" in reason


# ------------------------------------------------------------------ dedup hash
def test_payload_hash_is_stable_and_content_bound():
    t = fix(speed_kph=40)
    a = payload_hash("DEV-1", t)
    b = payload_hash("DEV-1", t)                       # same content => same hash
    c = payload_hash("DEV-2", t)                       # different device => differs
    d = payload_hash("DEV-1", fix(speed_kph=41))       # different content => differs
    assert a == b and a != c and a != d


# ----------------------------------------------------------- secret handling
def test_secret_hashing_is_salt_domain_separated_and_constant_time():
    h1 = gps._hash_secret("abc")
    assert h1 == gps._hash_secret("abc")
    assert h1 != hashlib_sha256_plain("abc")          # domain-separated
    assert gps._secret_matches("abc", h1)
    assert not gps._secret_matches("abd", h1)


def hashlib_sha256_plain(s: str) -> str:
    import hashlib
    return hashlib.sha256(s.encode()).hexdigest()


# ------------------------------------------------------------ rate limiting
def test_per_device_rate_limit_blocks_after_threshold(monkeypatch):
    monkeypatch.setattr(gps, "_DEVICE_RATE", 3)
    gps._hits.clear()
    verdicts = [gps._rate_allow("DEV-R") for _ in range(5)]
    assert verdicts[:3] == [True, True, True]
    assert verdicts[3:] == [False, False]


# ------------------------------------------------------- endpoint wiring
def test_ingest_endpoint_registered_and_device_gated():
    from fastapi.testclient import TestClient

    from app.main import create_app

    app = create_app()
    paths = app.openapi()["paths"]
    assert "/api/v1/gps/ingest" in paths
    assert "/api/v1/gps/devices" in paths

    client = TestClient(app, raise_server_exceptions=False)
    valid = {"latitude": 26.14, "longitude": 91.73,
             "timestamp": datetime.now(timezone.utc).isoformat()}
    r = client.post("/api/v1/gps/ingest", json=valid)
    # bearer gate skips this path; missing DEVICE credentials => 401 envelope
    assert r.status_code == 401
    assert r.json()["error"]["code"] == "UNAUTHENTICATED"


def test_admin_registration_requires_manage_system():
    from fastapi.testclient import TestClient

    from app.main import create_app

    client = TestClient(create_app(), raise_server_exceptions=False)
    r = client.post("/api/v1/gps/devices", json={"label": "x"})
    assert r.status_code == 401          # no bearer -> gate rejects before perms
