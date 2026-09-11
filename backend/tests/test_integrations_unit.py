"""Integration-layer unit tests — pure, no infra.

Covers the master-upgrade adapter contract: disabled/unconfigured sources
refuse to fetch, retries + health transitions work, confidence decays,
weather/disaster normalization enforces schemas, availability labeling never
claims LIVE without a successful fetch.
"""
import sys as _sys
from datetime import datetime, timedelta, timezone
from pathlib import Path

import pytest

BACKEND = Path(__file__).resolve().parents[1]
if str(BACKEND) not in _sys.path:
    _sys.path.insert(0, str(BACKEND))

from integrations.base import (  # noqa: E402
    AdapterHealth, BaseAdapter, IntegrationConfig, SourceUnavailable)
from integrations.disaster.adapter import DEFAULT_CONFIG as DISASTER_CFG  # noqa: E402
from integrations.weather.adapter import DEFAULT_CONFIG as WEATHER_CFG  # noqa: E402


def cfg(**over) -> IntegrationConfig:
    base = dict(name="t", source_type="WEATHER", provider="prov")
    base.update(over)
    return IntegrationConfig(**base)


class StubAdapter(BaseAdapter):
    """Injects canned upstream records without any network."""

    def __init__(self, config, records=None, fail=False):
        super().__init__(config)
        self.records = records if records is not None else []
        self.fail = fail
        self.calls = 0

    async def _fetch_once(self, **params):
        self.calls += 1
        if self.fail:
            raise RuntimeError("boom")
        return self.records

    def normalize(self, record):  # identity for stubs
        return record


# ------------------------------------------------------- refusal guarantees
async def test_disabled_source_refuses_to_fetch():
    a = StubAdapter(cfg(enabled=False))
    with pytest.raises(SourceUnavailable):
        await a.fetch()


async def test_enabled_but_unconfigured_refuses():
    a = StubAdapter(cfg(enabled=True, endpoint=None))   # no endpoint
    with pytest.raises(SourceUnavailable):
        await a.fetch()


async def test_rate_limit_blocks_excess_calls():
    a = StubAdapter(cfg(enabled=True, endpoint="http://x",
                        rate_limit_per_min=2))
    ok = 0
    for _ in range(5):
        try:
            await a.fetch()
            ok += 1
        except SourceUnavailable:
            pass
    assert ok == 2                       # third+ call blocked by client limiter


# ------------------------------------------------------------- health state
async def test_health_transitions_disabled_unavailable_healthy():
    a = StubAdapter(cfg(enabled=False))
    assert a.health().status == "DISABLED"

    b = StubAdapter(cfg(enabled=True))   # configured=False (no endpoint)
    assert b.health().status == "UNAVAILABLE"
    assert b.health().configured is False

    c = StubAdapter(cfg(enabled=True, endpoint="http://x"), records=[{"v": 1}])
    await c.fetch()
    h = c.health()
    assert h.status == "HEALTHY" and h.confidence > 0


async def test_retries_then_reports_failure_and_decays_confidence():
    a = StubAdapter(cfg(enabled=True, endpoint="http://x",
                        max_retries=2, retry_backoff_s=0.01), fail=True)
    with pytest.raises(SourceUnavailable):
        await a.fetch()
    assert a.calls == 3                  # initial + 2 retries
    h = a.health()
    assert h.consecutive_failures == 3
    assert h.last_error and "boom" in h.last_error
    assert h.confidence == 0.0           # never succeeded => zero trust


async def test_confidence_decays_with_staleness():
    a = StubAdapter(cfg(enabled=True, endpoint="http://x"))
    a._last_success_at = datetime.now(timezone.utc) - timedelta(hours=3)
    assert a.health().confidence == 0.0
    a._last_success_at = datetime.now(timezone.utc)
    assert a.health().confidence > 0.9


def test_adapter_health_model_shape():
    h = AdapterHealth(name="n", source_type="WEATHER", provider="p",
                      status="DISABLED", enabled=False, configured=False)
    assert h.status in {"HEALTHY", "DEGRADED", "UNAVAILABLE", "DISABLED"}


# ------------------------------------------------------------ default configs
def test_default_sources_ship_disabled_pending_authorization():
    """Rule 2: shipped defaults must NEVER present themselves as live."""
    for c in (WEATHER_CFG, DISASTER_CFG):
        assert c.enabled is False
        assert c.endpoint is None
        assert "requir" in (c.license_note or "").lower()


# ----------------------------------------------- weather schema normalization
def test_weather_normalization_validates_contract():
    from integrations.weather.adapter import WeatherAdapter

    a = WeatherAdapter(WEATHER_CFG.model_copy(
        update={"enabled": True, "endpoint": "http://x"}))
    rec = {"district_code": "IN-AS-GA", "rainfall_mm_24h": 12.5,
           "forecast_rainfall_mm_24h": 30.0,
           "observed_at": "2026-08-24T06:00:00Z"}
    out = a.normalize(rec)
    assert out["source"] == WEATHER_CFG.provider
    assert out["rainfall_mm_24h"] == 12.5

    with pytest.raises(Exception):
        # missing mandatory rainfall -> rejected, never defaulted/invented
        a.normalize({"district_code": "X", "observed_at": "2026-08-24T06:00:00Z"})


def test_disaster_normalization_constrains_hazard_severity():
    from integrations.disaster.adapter import DisasterAdapter

    a = DisasterAdapter(DISASTER_CFG.model_copy(
        update={"enabled": True, "endpoint": "http://x"}))
    rec = {"external_id": "A-1", "hazard": "FLOOD", "severity": "HIGH",
           "title": "flood warning", "issued_at": "2026-08-24T05:00:00Z",
           "authority": "SDMA"}
    assert a.normalize(rec)["hazard"] == "FLOOD"
    with pytest.raises(Exception):
        a.normalize({**rec, "severity": "APOCALYPTIC"})


# --------------------------------------------------------- availability labels
async def test_weather_service_labels_unavailable_without_source(monkeypatch):
    from integrations.weather import service

    async def refuse(**params):
        raise SourceUnavailable("disabled")

    monkeypatch.setattr(service._adapter, "fetch", refuse)
    out = await service.latest_observations()
    assert out["availability"] == "UNAVAILABLE"
    assert out["observations"] == []
    assert out["confidence"] == 0.0


async def test_weather_service_classifies_freshness():
    from integrations.weather import service

    now = datetime.now(timezone.utc)
    assert service._classify(None) == "UNAVAILABLE"
    assert service._classify(now) == "LIVE"
    assert service._classify(now - timedelta(minutes=60)) == "RECENT"
    assert service._classify(now - timedelta(hours=5)) == "STALE"


# ------------------------------------------------------------ data_health svc
def test_data_health_freshness_classification_matches_ui_contract():
    from app.data_health.service import classify_freshness

    now = datetime.now(timezone.utc)
    assert classify_freshness(now - timedelta(minutes=10)) == "LIVE"
    assert classify_freshness(now - timedelta(minutes=120)) == "RECENT"
    assert classify_freshness(now - timedelta(days=2)) == "STALE"
    assert classify_freshness(None) == "UNAVAILABLE"


def test_data_health_router_registered_and_gated():
    """/api/v1/data-health must exist and demand authentication + VIEW_MAP."""
    from fastapi.testclient import TestClient

    from app.main import create_app

    app = create_app()
    assert "/api/v1/data-health" in app.openapi()["paths"]
    client = TestClient(app, raise_server_exceptions=False)
    r = client.get("/api/v1/data-health")
    assert r.status_code == 401          # bearer gate (AuthGateMiddleware)

