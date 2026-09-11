"""Provider-integration unit tests (master upgrade §25).

Pure, no infra: shipped-disabled guarantees, normalization contracts,
quarantine of malformed data, OSRM contract mapping, Copernicus credential
refusal, SACHET hazard/severity mapping, multi-source confidence fusion.
"""
import sys as _sys
from datetime import datetime, timedelta, timezone
from pathlib import Path

import pytest

BACKEND = Path(__file__).resolve().parents[1]
if str(BACKEND) not in _sys.path:
    _sys.path.insert(0, str(BACKEND))

from integrations.base import IntegrationConfig, SourceUnavailable  # noqa: E402,F401
from integrations.disaster.sachet import DEFAULT_CONFIG as SACHET_CFG  # noqa: E402
from integrations.hydrology.adapter import DEFAULT_CONFIG as CWC_CFG  # noqa: E402
from integrations.routing.providers import DEFAULT_CONFIG as OSRM_CFG  # noqa: E402
from integrations.satellite.copernicus import (  # noqa: E402
    DEFAULT_CONFIG as COPERNICUS_CFG, CopernicusProvider, _bbox_from_geojson)
from integrations.weather.imd import DEFAULT_CONFIG as IMD_CFG  # noqa: E402


# ------------------------------------------------- shipped-disabled guarantees
def test_all_new_providers_ship_disabled_and_unconfigured():
    for cfg in (IMD_CFG, SACHET_CFG, CWC_CFG, COPERNICUS_CFG, OSRM_CFG):
        assert cfg.enabled is False, cfg.name
        assert cfg.endpoint is None, cfg.name
        assert "requir" in (cfg.license_note or "").lower(), cfg.name


def test_new_adapters_report_unavailable_health():
    from integrations.disaster.sachet import SachetProvider
    from integrations.hydrology.adapter import CWCProvider
    from integrations.routing.providers import OSRMProvider
    from integrations.weather.imd import IMDProvider

    for cls, cfg in ((IMDProvider, IMD_CFG), (SachetProvider, SACHET_CFG),
                     (CWCProvider, CWC_CFG), (OSRMProvider, OSRM_CFG)):
        a = cls(cfg)
        assert a.health().status == "DISABLED"


# ------------------------------------------------------------ IMD adapter
def test_imd_normalization_enforces_weather_contract():
    from integrations.weather.imd import IMDProvider

    a = IMDProvider(IMD_CFG.model_copy(
        update={"enabled": True, "endpoint": "http://imd-gateway"}))
    out = a.normalize({"district_code": "IN-AS", "rainfall_mm_24h": 42.5,
                       "observed_at": "2026-08-24T06:00:00Z"})
    assert out["source"] == "IMD" and out["rainfall_mm_24h"] == 42.5
    with pytest.raises(Exception):
        # missing mandatory rainfall must NEVER be defaulted to 0
        a.normalize({"district_code": "IN-AS",
                     "observed_at": "2026-08-24T06:00:00Z"})


def test_imd_prefilter_quarantines_bad_rows():
    from integrations.weather.imd import IMDProvider, prefilter_contract

    a = IMDProvider(IMD_CFG.model_copy(update={"provider": "IMD"}))
    good = {"district_code": "IN-MN", "rainfall_mm_24h": 10,
            "observed_at": "2026-08-24T06:00:00Z"}
    bad = {"district_code": "IN-MN", "observed_at": "2026-08-24T06:00:00Z"}
    kept = prefilter_contract(a, [good, bad])
    assert len(kept) == 1 and kept[0] is good


# --------------------------------------------------------- SACHET adapter
def test_sachet_maps_documented_alert_levels_and_hazards():
    from integrations.disaster.sachet import SachetProvider

    a = SachetProvider(SACHET_CFG.model_copy(
        update={"enabled": True, "endpoint": "http://sachet-feed"}))
    rec = {"external_id": "S-1", "hazard": "HEAVY_RAINFALL",
           "severity": "WARNING", "title": "heavy rain alert",
           "issued_at": "2026-08-24T05:00:00Z"}
    out = a.normalize(rec)
    assert out["hazard"] == "FLOOD" and out["severity"] == "CRITICAL"
    assert out["authority"] == "NDMA-SACHET"

    lightning = a.normalize({**rec, "external_id": "S-2", "hazard": "LIGHTNING",
                             "severity": "ADVISORY"})
    assert lightning["hazard"] == "OTHER" and lightning["severity"] == "LOW"


async def test_sachet_fetch_drops_unmappable_records(monkeypatch):
    from integrations.disaster.sachet import SachetProvider

    a = SachetProvider(SACHET_CFG.model_copy(
        update={"enabled": True, "endpoint": "http://sachet-feed",
                "max_retries": 0}))

    async def fake_transport(self, **params):   # stub the HTTP layer
        return {"advisories": [
            {"external_id": "OK-1", "hazard": "FLOOD", "severity": "ALERT",
             "title": "flood warning",
             "issued_at": "2026-08-24T05:00:00Z"},
            {"external_id": "BAD-1", "hazard": "METEOR_SHOWER",
             "severity": "ALERT", "title": "?",
             "issued_at": "2026-08-24T05:00:00Z"},
            {"no_external_id": True},
        ]}

    monkeypatch.setattr("integrations.base.BaseAdapter._fetch_once",
                        fake_transport)
    records = await a.fetch()
    assert len(records) == 1
    assert records[0]["hazard"] == "FLOOD"


# ----------------------------------------------------------- CWC provider
def test_cwc_normalization_rejects_invalid_readings():
    from integrations.hydrology.adapter import CWCProvider

    a = CWCProvider(CWC_CFG.model_copy(
        update={"enabled": True, "endpoint": "http://cwc-feed"}))
    ok = a.normalize({"station_code": "BRMP", "water_level_m": 84.21,
                      "level_trend": "RISING",
                      "observed_at": "2026-08-24T04:00:00Z"})
    assert ok["level_trend"] == "RISING" and ok["source"] == "CWC"
    # missing water_level is allowed (omit, never zero-fill)
    assert a.normalize({"station_code": "X",
                        "observed_at": "2026-08-24T04:00:00Z"})[
        "water_level_m"] is None
    with pytest.raises(Exception):
        a.normalize({"station_code": "X", "level_trend": "EXPLODING",
                     "observed_at": "2026-08-24T04:00:00Z"})
    with pytest.raises(Exception):
        a.normalize({"station_code": "X", "discharge_cumecs": -5,
                     "observed_at": "2026-08-24T04:00:00Z"})


# ---------------------------------------------------- Copernicus provider
async def test_copernicus_refuses_without_credentials(monkeypatch):
    a = CopernicusProvider(COPERNICUS_CFG.model_copy(
        update={"enabled": True,
                "endpoint": "https://catalogue.example/odata/v1"}),
        client_id=None, client_secret=None)
    monkeypatch.delenv("COPERNICUS_CLIENT_ID", raising=False)
    monkeypatch.delenv("COPERNICUS_CLIENT_SECRET", raising=False)
    with pytest.raises(SourceUnavailable):
        await a._access_token()


async def test_copernicus_refuses_when_disabled():
    a = CopernicusProvider(COPERNICUS_CFG)          # disabled + unconfigured
    with pytest.raises(SourceUnavailable):
        await a.fetch()


def test_copernicus_bbox_extraction_and_normalize():
    geom = {"type": "Polygon",
            "coordinates": [[[89, 22], [97, 22], [97, 28], [89, 28],
                             [89, 22]]]}
    assert _bbox_from_geojson(geom) == [89.0, 22.0, 97.0, 28.0]
    assert _bbox_from_geojson(None) is None

    a = CopernicusProvider(COPERNICUS_CFG.model_copy(
        update={"enabled": True,
                "endpoint": "https://catalogue.example/odata/v1"}))
    scene = a.normalize({
        "Id": "S2A_MSIL2A_20260820",
        "ContentDate": {"Start": "2026-08-20T04:30:00Z"},
        "GeoFootprint": geom})
    assert scene["external_id"] == "S2A_MSIL2A_20260820"
    assert scene["coverage_bbox"][0] == 89.0
    assert scene["storage_path"] is None          # metadata-only pipeline


# ------------------------------------------------------------ OSRM routing
async def test_osrm_refuses_when_disabled_or_unconfigured():
    from integrations.routing.providers import OSRMProvider

    coords = [(91.7, 26.1), (91.8, 26.2)]
    a = OSRMProvider(OSRM_CFG)                    # disabled
    with pytest.raises(SourceUnavailable):
        await a.calculate_route(coords)
    b = OSRMProvider(OSRM_CFG.model_copy(update={"enabled": True}))
    with pytest.raises(SourceUnavailable):        # enabled but no base URL
        await b.calculate_route(coords)


async def test_osrm_url_building_and_coordinate_guard(monkeypatch):
    from integrations.routing.providers import OSRMProvider

    a = OSRMProvider(OSRM_CFG.model_copy(
        update={"enabled": True, "endpoint": "http://osrm.internal"}))
    captured = {}

    async def fake_get(self, url, params=None, headers=None, **kw):
        captured["url"], captured["params"] = url, params

        class R:
            status_code = 200

            def raise_for_status(self):
                pass

            def json(self):
                return {"code": "Ok", "routes": [{
                    "distance": 12345.0, "duration": 900.0,
                    "geometry": {"coordinates": [
                        [91.7, 26.1], [91.75, 26.15], [91.8, 26.2]]}}]}

        return R()

    monkeypatch.setattr("httpx.AsyncClient.get", fake_get)
    route = await a.calculate_route([(91.7, 26.1), (91.8, 26.2)])
    dist = await a.calculate_distance_m([(91.7, 26.1), (91.8, 26.2)])
    eta = await a.calculate_eta_hours([(91.7, 26.1), (91.8, 26.2)])
    assert captured["url"].startswith("http://osrm.internal/route/v1/driving/")
    assert "91.700000,26.100000;91.800000,26.200000" in captured["url"]
    assert route.distance_m == 12345.0 and route.duration_s == 900.0
    assert dist == 12345.0 and abs(eta - 0.25) < 1e-9
    assert route.geometry and route.geometry[0] == (91.7, 26.1)
    assert route.provider == "OSRM"


async def test_osrm_non_ok_code_raises_explicit_unavailable(monkeypatch):
    from integrations.routing.providers import OSRMProvider

    a = OSRMProvider(OSRM_CFG.model_copy(
        update={"enabled": True, "endpoint": "http://osrm.internal",
                "max_retries": 0}))

    async def bad_json(self, url, params=None, headers=None, **kw):
        class R:
            status_code = 200

            def raise_for_status(self):
                pass

            def json(self):
                return {"code": "NoRoute", "routes": []}

        return R()

    monkeypatch.setattr("httpx.AsyncClient.get", bad_json)
    with pytest.raises(SourceUnavailable):
        await a.calculate_route([(91.7, 26.1), (91.8, 26.2)])
    h = a.health()
    assert h.consecutive_failures >= 1 and h.confidence == 0.0
    assert h.status in ("DEGRADED", "UNAVAILABLE")


def test_coordinate_guard_rejects_transposed_and_out_of_range():
    from integrations.routing.schemas import (RouteContractError,
                                              validate_lonlat)

    assert validate_lonlat(91.7, 26.1) == (91.7, 26.1)   # lon,lat OK
    with pytest.raises(RouteContractError):               # transposed signature
        validate_lonlat(26.1, 95.0)
    with pytest.raises(RouteContractError):               # out of range
        validate_lonlat(999.0, 26.1)


def test_routing_service_defaults_to_internal_engine():
    from integrations.routing import service as routing_svc

    assert routing_svc.get_provider() is None
    assert routing_svc.is_external_enabled() is False


# ------------------------------------------------------------------ fusion
def test_fusion_single_source_is_bounded_and_fresh_weighted():
    from app.risk.fusion import SourceSignal, fuse

    fresh = fuse([SourceSignal(source="IMD", hazard="FLOOD", agrees=True)],
                 "FLOOD")
    stale = fuse([SourceSignal(source="IMD", hazard="FLOOD", agrees=True,
                               age_hours=48)], "FLOOD")
    assert 0 < fresh.confidence <= 0.95
    assert stale.confidence < fresh.confidence     # staleness reduces trust
    assert fresh.notes == "single-source signal only"


def test_fusion_multi_source_agreement_raises_confidence():
    from app.risk.fusion import SourceSignal, fuse

    one = fuse([SourceSignal("IMD", "FLOOD", True)], "FLOOD").confidence
    many = fuse([
        SourceSignal("IMD", "FLOOD", True),
        SourceSignal("CWC", "FLOOD", True),
        SourceSignal("NDMA-SACHET", "FLOOD", True),
        SourceSignal("COPERNICUS", "FLOOD", True),
    ], "FLOOD")
    assert many.confidence > one                   # agreement strengthens
    assert len(many.contributing_sources) == 4
    assert many.confidence <= 0.95                 # never certainty


def test_fusion_disagreement_reduces_confidence():
    from app.risk.fusion import SourceSignal, fuse

    agree_only = fuse([SourceSignal("IMD", "FLOOD", True),
                       SourceSignal("CWC", "FLOOD", True)], "FLOOD")
    with_dissent = fuse([SourceSignal("IMD", "FLOOD", True),
                         SourceSignal("CWC", "FLOOD", True),
                         SourceSignal("FIELD", "FLOOD", False)], "FLOOD")
    assert with_dissent.confidence < agree_only.confidence
    assert with_dissent.dissenting_sources == ["FIELD"]
    assert "dissent" in with_dissent.notes


def test_fusion_no_relevant_sources_is_explicit_gap():
    from app.risk.fusion import SourceSignal, fuse

    r = fuse([SourceSignal("IMD", "LANDSLIDE", True)], "FLOOD")
    assert r.confidence == 0.0 and "completeness" in r.notes


def test_fusion_validates_signal_inputs():
    from app.risk.fusion import SourceSignal

    with pytest.raises(ValueError):
        SourceSignal("", "FLOOD", True)
    with pytest.raises(ValueError):
        SourceSignal("IMD", "FLOOD", True, reliability=1.5)
    with pytest.raises(ValueError):          # negative age rejected at build
        SourceSignal("IMD", "FLOOD", True, age_hours=-3)


def test_risk_and_confidence_are_separate_axes():
    """§30: HIGH RISK != HIGH CONFIDENCE — weak evidence stays low confidence."""
    from app.risk.fusion import SourceSignal, fuse

    weak_evidence = fuse(
        [SourceSignal("IMD", "FLOOD", True, age_hours=30, quality=0.4)],
        "FLOOD")
    assert weak_evidence.confidence < 0.3


# --------------------------------------------- registry & worker integration
def test_data_health_registry_includes_new_providers():
    from app.data_health.service import _adapters

    names = {a.config.name for a in _adapters()}
    assert {"weather-primary", "weather-imd", "disaster-primary",
            "disaster-sachet", "satellite-primary", "satellite-copernicus",
            "cwc-primary"} <= names


def test_worker_runner_registers_new_ingest_jobs():
    from workers.runner import build_runner

    jobs = set(build_runner(interval_s=60).jobs)
    assert {"weather_imd_ingest", "disaster_sachet_ingest",
            "satellite_copernicus_ingest", "hydrology_ingest"} <= jobs


def test_config_loader_keeps_everything_off_by_default(monkeypatch):
    from integrations import config_loader
    from integrations.routing import service as routing_svc

    for var in ("IMD_ENABLED", "IMD_BASE_URL", "SACHET_ENABLED",
                "SACHET_BASE_URL", "COPERNICUS_ENABLED",
                "COPERNICUS_BASE_URL", "CWC_ENABLED", "CWC_BASE_URL",
                "ROUTING_PROVIDER"):
        monkeypatch.delenv(var, raising=False)
    n = config_loader.apply()
    assert n == 0
    assert config_loader.imd_service.get_adapter().config.enabled is False
    assert config_loader.sachet_service.get_adapter().config.enabled is False
    assert routing_svc.is_external_enabled() is False


def test_stale_data_detection_and_availability_labels():
    """Availability labeling must exist per provider family (§10/§11)."""
    from integrations.hydrology.service import _classify as hydro_classify
    from integrations.satellite.copernicus_service import get_adapter
    from integrations.weather.imd_service import _classify as imd_classify

    now = datetime.now(timezone.utc)
    assert imd_classify(now) == "LIVE"
    assert imd_classify(now - timedelta(hours=5)) == "STALE"
    assert hydro_classify(now - timedelta(hours=2)) == "RECENT"
    assert hydro_classify(None) == "UNAVAILABLE"
    assert get_adapter().health().status == "DISABLED"


# ===========================================================================
# Phase 8 — Weather provider test matrix (§8.5)
# adapter unit / mocked response / timeout / auth failure / cache fallback
# ===========================================================================
import httpx  # noqa: E402


def _imd_ready(**extra):
    """Enabled + configured IMD adapter with fast retries for tests."""
    from integrations.weather.imd import IMDProvider

    cfg = IMD_CFG.model_copy(update={
        "enabled": True, "endpoint": "http://imd-gateway",
        "max_retries": extra.pop("max_retries", 0),
        "retry_backoff_s": 0.0, **extra})
    return IMDProvider(cfg)


def _mock_response(status_code=200, payload=None, calls=None):
    """Build an httpx.AsyncClient.get monkeypatch stub per the OSRM pattern."""

    async def fake_get(self, url, params=None, headers=None, **kw):
        if calls is not None:
            calls["n"] += 1
        if isinstance(status_code, Exception):
            raise status_code

        class R:
            def raise_for_status(self):
                if self.status_code >= 400:
                    req = httpx.Request("GET", url)
                    raise httpx.HTTPStatusError(
                        f"{self.status_code}", request=req,
                        response=httpx.Response(self.status_code, request=req))

            def json(self):
                return payload

        R.status_code = status_code
        return R()

    return fake_get


async def test_imd_fetch_mocked_response_unwraps_envelope_and_normalizes(
        monkeypatch):
    """§8.5-2 — mocked 200 response: envelope unwrap + normalize + health."""
    a = _imd_ready()
    payload = {"observations": [
        {"district_code": "IN-MN", "rainfall_mm_24h": 21.5,
         "observed_at": "2026-09-08T06:00:00Z"},
        {"district_code": "IN-AS", "rainfall_mm_24h": 5.0,
         "observed_at": "2026-09-08T06:00:00Z"}]}
    monkeypatch.setenv("IMD_API_KEY", "test-key")
    monkeypatch.setattr("httpx.AsyncClient.get",
                        _mock_response(payload=payload))
    out = await a.fetch_validated(district="IN-MN")
    assert len(out) == 2
    assert all(r["source"] == "IMD" for r in out)
    assert out[0]["rainfall_mm_24h"] == 21.5
    h = a.health()
    assert h.status == "HEALTHY" and h.last_success_at is not None


async def test_imd_timeout_retries_then_reports_unavailable(monkeypatch):
    """§8.5-4 — timeout: retried per config, then explicit SourceUnavailable."""
    a = _imd_ready(max_retries=2)
    calls = {"n": 0}
    monkeypatch.setenv("IMD_API_KEY", "test-key")
    monkeypatch.setattr("httpx.AsyncClient.get", _mock_response(
        status_code=httpx.TimeoutException("connect timeout"), calls=calls))
    with pytest.raises(SourceUnavailable):
        await a.fetch()
    assert calls["n"] == 3                      # 1 initial + 2 retries
    h = a.health()
    assert h.status == "UNAVAILABLE"            # never had a success
    assert h.consecutive_failures == 3
    assert h.last_failure_at is not None


async def test_imd_http_401_is_explicit_unavailable_not_crash(monkeypatch):
    """§8.5-6 — authentication failure: explicit unavailable, no crash."""
    a = _imd_ready(max_retries=1)
    calls = {"n": 0}
    monkeypatch.setenv("IMD_API_KEY", "wrong-key")
    monkeypatch.setattr("httpx.AsyncClient.get", _mock_response(
        status_code=401, calls=calls))
    with pytest.raises(SourceUnavailable) as excinfo:
        await a.fetch()
    assert calls["n"] == 2                      # retried once, then gave up
    assert "401" in str(excinfo.value)
    assert a.health().consecutive_failures == 2


def test_last_known_cache_unit_contract():
    """§8.1 cache: empty/expired → explicit None; else records + honest age."""
    from integrations.base import LastKnownCache

    c = LastKnownCache(max_age_s=3600)
    assert c.load() is None                     # never stored
    c.store([{"a": 1}], at=datetime.now(timezone.utc) - timedelta(hours=2))
    assert c.load() is None                     # beyond budget → explicit gap
    c2 = LastKnownCache(max_age_s=3 * 3600)
    c2.store([{"a": 1}, {"a": 2}],
             at=datetime.now(timezone.utc) - timedelta(hours=2))
    loaded = c2.load()
    assert loaded is not None
    assert loaded["records"] == [{"a": 1}, {"a": 2}]
    assert 7000 < loaded["age_s"] < 7300
    c2.clear()
    assert c2.load() is None


async def test_weather_service_cache_fallback_on_provider_failure(monkeypatch):
    """§8.5-7 — provider dies after a good fetch: serve last-known copy,
    explicitly marked cache-fallback, honestly age-labeled (never faked)."""
    from integrations.weather import DEFAULT_CONFIG, service as weather_svc

    weather_svc.reconfigure(DEFAULT_CONFIG.model_copy(update={
        "enabled": True, "endpoint": "http://weather-gateway",
        "max_retries": 0, "retry_backoff_s": 0.0}))
    weather_svc.cache().clear()
    monkeypatch.setenv("WEATHER_API_KEY", "test-key")

    good = {"observations": [{"district_code": "IN-MN", "rainfall_mm_24h": 12.5,
                              "observed_at": "2026-09-08T06:00:00Z"}]}
    monkeypatch.setattr("httpx.AsyncClient.get",
                        _mock_response(payload=good))
    out1 = await weather_svc.latest_observations()
    assert out1["availability"] == "LIVE"
    assert "delivery" not in out1               # live path contract unchanged
    assert len(out1["observations"]) == 1

    monkeypatch.setattr("httpx.AsyncClient.get", _mock_response(
        status_code=httpx.ConnectError("cable cut")))
    out2 = await weather_svc.latest_observations()
    assert out2["delivery"] == "cache-fallback"
    assert out2["observations"] == out1["observations"]
    assert out2["availability"] in {"LIVE", "RECENT", "STALE"}
    assert 0.0 <= out2["confidence"] <= 1.0
    assert "cable cut" in out2["reason"]
    # restore module state for other tests
    weather_svc.reconfigure(DEFAULT_CONFIG)
    weather_svc.cache().clear()


async def test_weather_service_without_cache_reports_unavailable(monkeypatch):
    """Failure with an EMPTY cache keeps the existing UNAVAILABLE contract."""
    from integrations.weather import DEFAULT_CONFIG, service as weather_svc

    weather_svc.reconfigure(DEFAULT_CONFIG.model_copy(update={
        "enabled": True, "endpoint": "http://weather-gateway",
        "max_retries": 0, "retry_backoff_s": 0.0}))
    weather_svc.cache().clear()
    monkeypatch.setenv("WEATHER_API_KEY", "test-key")
    monkeypatch.setattr("httpx.AsyncClient.get", _mock_response(
        status_code=httpx.ConnectError("no route")))
    out = await weather_svc.latest_observations()
    assert out["availability"] == "UNAVAILABLE"
    assert out["observations"] == []
    assert "delivery" not in out
    weather_svc.reconfigure(DEFAULT_CONFIG)
    weather_svc.cache().clear()


async def test_imd_service_cache_fallback_labels_stale_not_live(monkeypatch):
    """Old cached observations are labeled STALE — never presented as live."""
    from integrations.weather import imd_service
    from integrations.weather.imd import DEFAULT_CONFIG

    imd_service.reconfigure(DEFAULT_CONFIG.model_copy(update={
        "enabled": True, "endpoint": "http://imd-gateway",
        "max_retries": 0, "retry_backoff_s": 0.0}))
    imd_service.cache().clear()
    imd_service.cache().store(
        [{"district_code": "IN-MN", "rainfall_mm_24h": 30.0,
          "observed_at": "2026-09-08T01:00:00Z", "source": "IMD"}],
        at=datetime.now(timezone.utc) - timedelta(hours=4))
    monkeypatch.setenv("IMD_API_KEY", "test-key")
    monkeypatch.setattr("httpx.AsyncClient.get", _mock_response(
        status_code=httpx.ConnectError("gateway down")))
    out = await imd_service.latest_observations()
    assert out["delivery"] == "cache-fallback"
    assert out["availability"] == "STALE"
    assert len(out["observations"]) == 1
    imd_service.reconfigure(DEFAULT_CONFIG)
    imd_service.cache().clear()


def test_config_loader_wires_weather_provider_when_flagged(monkeypatch):
    """§8.1/§8.4 — WEATHER_ENABLED + WEATHER_BASE_URL enables exactly that
    provider; missing flags keep everything off (default preserved)."""
    from integrations.weather import DEFAULT_CONFIG, service as weather_svc
    from integrations import config_loader

    for var in ("IMD_ENABLED", "SACHET_ENABLED", "COPERNICUS_ENABLED",
                "CWC_ENABLED", "ROUTING_ENABLED", "OSRM_ENABLED"):
        monkeypatch.delenv(var, raising=False)
    monkeypatch.setenv("WEATHER_ENABLED", "1")
    monkeypatch.setenv("WEATHER_BASE_URL", "http://weather-gateway")
    assert config_loader.apply() == 1
    cfg = weather_svc.get_adapter().config
    assert cfg.enabled is True and cfg.endpoint == "http://weather-gateway"
    # restore default (disabled) state
    weather_svc.reconfigure(DEFAULT_CONFIG)


# ===========================================================================
# Phase 8 — Disaster (SACHET) provider test matrix (§8.5)
# ===========================================================================
def _sachet_ready(**extra):
    from integrations.disaster.sachet import SachetProvider

    cfg = SACHET_CFG.model_copy(update={
        "enabled": True, "endpoint": "http://sachet-feed",
        "max_retries": extra.pop("max_retries", 0),
        "retry_backoff_s": 0.0, **extra})
    return SachetProvider(cfg)


def _advisory_record(ext="S-1", hazard="HEAVY_RAINFALL", severity="WARNING"):
    return {"external_id": ext, "hazard": hazard, "severity": severity,
            "title": "heavy rain alert", "issued_at": "2026-09-08T05:00:00Z"}


async def test_sachet_timeout_retries_then_reports_unavailable(monkeypatch):
    """§8.5-4 — timeout: retried per config, then explicit SourceUnavailable."""
    a = _sachet_ready(max_retries=2)
    calls = {"n": 0}
    monkeypatch.setattr("httpx.AsyncClient.get", _mock_response(
        status_code=httpx.TimeoutException("connect timeout"), calls=calls))
    with pytest.raises(SourceUnavailable):
        await a.fetch()
    assert calls["n"] == 3                      # 1 initial + 2 retries
    h = a.health()
    assert h.status == "UNAVAILABLE"            # never had a success
    assert h.consecutive_failures == 3
    assert h.last_failure_at is not None


async def test_sachet_http_401_is_explicit_unavailable_not_crash(monkeypatch):
    """§8.5-6 — SACHET has no client credential (api_key_env None); a gateway
    401 must still surface as explicit unavailable, never a crash."""
    a = _sachet_ready(max_retries=1)
    calls = {"n": 0}
    monkeypatch.setattr("httpx.AsyncClient.get", _mock_response(
        status_code=401, calls=calls))
    with pytest.raises(SourceUnavailable) as excinfo:
        await a.fetch()
    assert calls["n"] == 2                      # retried once, then gave up
    assert "401" in str(excinfo.value)
    assert a.health().consecutive_failures == 2


async def test_sachet_mocked_alerts_envelope_maps_and_normalizes(monkeypatch):
    """§8.5-2 — mocked 200 CAP envelope: unwrap + map + normalize + health."""
    a = _sachet_ready()
    payload = {"alerts": [_advisory_record("S-1"),
                          _advisory_record("S-2", hazard="CYCLONE",
                                           severity="ALERT")]}
    monkeypatch.setattr("httpx.AsyncClient.get",
                        _mock_response(payload=payload))
    out = await a.fetch()
    assert len(out) == 2
    assert {r["hazard"] for r in out} == {"FLOOD", "CYCLONE"}
    assert {r["severity"] for r in out} == {"CRITICAL", "HIGH"}
    assert {r["authority"] for r in out} == {"NDMA-SACHET"}
    h = a.health()
    assert h.status == "HEALTHY" and h.last_success_at is not None


async def test_sachet_service_cache_fallback_on_provider_failure(monkeypatch):
    """§8.5-7 — feed dies after a good fetch: serve last-known advisories,
    explicitly marked cache-fallback, honestly age-labeled (never faked)."""
    from integrations.disaster import sachet_service
    from integrations.disaster.sachet import DEFAULT_CONFIG

    sachet_service.reconfigure(DEFAULT_CONFIG.model_copy(update={
        "enabled": True, "endpoint": "http://sachet-feed",
        "max_retries": 0, "retry_backoff_s": 0.0}))
    sachet_service.cache().clear()

    monkeypatch.setattr("httpx.AsyncClient.get", _mock_response(
        payload={"alerts": [_advisory_record("S-1")]}))
    out1 = await sachet_service.active_advisories()
    assert out1["availability"] == "LIVE"
    assert "delivery" not in out1               # live path contract unchanged
    assert len(out1["advisories"]) == 1
    assert out1["advisories"][0]["severity"] == "CRITICAL"

    monkeypatch.setattr("httpx.AsyncClient.get", _mock_response(
        status_code=httpx.ConnectError("cable cut")))
    out2 = await sachet_service.active_advisories()
    assert out2["delivery"] == "cache-fallback"
    assert out2["advisories"] == out1["advisories"]
    assert out2["availability"] in {"LIVE", "RECENT", "STALE"}
    assert 0.0 <= out2["confidence"] <= 1.0
    assert "cable cut" in out2["reason"]
    # restore module state for other tests
    sachet_service.reconfigure(DEFAULT_CONFIG)
    sachet_service.cache().clear()


async def test_sachet_service_cache_fallback_labels_stale_not_live(monkeypatch):
    """Old cached advisories are labeled STALE — never presented as live."""
    from integrations.disaster import sachet_service
    from integrations.disaster.sachet import DEFAULT_CONFIG

    sachet_service.reconfigure(DEFAULT_CONFIG.model_copy(update={
        "enabled": True, "endpoint": "http://sachet-feed",
        "max_retries": 0, "retry_backoff_s": 0.0}))
    sachet_service.cache().clear()
    sachet_service.cache().store(
        [{"external_id": "S-9", "hazard": "FLOOD", "severity": "HIGH",
          "title": "flood warning", "issued_at": "2026-09-08T01:00:00Z",
          "authority": "NDMA-SACHET"}],
        at=datetime.now(timezone.utc) - timedelta(hours=4))
    monkeypatch.setattr("httpx.AsyncClient.get", _mock_response(
        status_code=httpx.ConnectError("gateway down")))
    out = await sachet_service.active_advisories()
    assert out["delivery"] == "cache-fallback"
    assert out["availability"] == "STALE"
    assert len(out["advisories"]) == 1
    sachet_service.reconfigure(DEFAULT_CONFIG)
    sachet_service.cache().clear()


async def test_disaster_service_cache_fallback_on_provider_failure(monkeypatch):
    """§8.5-7 — generic disaster-primary slot gets the same cache contract."""
    from integrations.disaster import DEFAULT_CONFIG, service as disaster_svc

    disaster_svc.reconfigure(DEFAULT_CONFIG.model_copy(update={
        "enabled": True, "endpoint": "http://disaster-gateway",
        "max_retries": 0, "retry_backoff_s": 0.0}))
    disaster_svc.cache().clear()
    monkeypatch.setenv("DISASTER_API_KEY", "test-key")

    payload = {"advisories": [{"external_id": "D-1", "hazard": "FLOOD",
                               "severity": "HIGH", "title": "flood warning",
                               "issued_at": "2026-09-08T05:00:00Z",
                               "authority": "NDMA"}]}
    monkeypatch.setattr("httpx.AsyncClient.get",
                        _mock_response(payload=payload))
    out1 = await disaster_svc.active_advisories()
    assert out1["availability"] == "LIVE"
    assert "delivery" not in out1
    assert len(out1["advisories"]) == 1

    monkeypatch.setattr("httpx.AsyncClient.get", _mock_response(
        status_code=httpx.ConnectError("cable cut")))
    out2 = await disaster_svc.active_advisories()
    assert out2["delivery"] == "cache-fallback"
    assert out2["advisories"] == out1["advisories"]
    assert out2["availability"] in {"LIVE", "RECENT", "STALE"}
    assert 0.0 <= out2["confidence"] <= 1.0
    disaster_svc.reconfigure(DEFAULT_CONFIG)
    disaster_svc.cache().clear()


async def test_disaster_service_without_cache_reports_unavailable(monkeypatch):
    """Failure with an EMPTY cache keeps the existing UNAVAILABLE contract."""
    from integrations.disaster import DEFAULT_CONFIG, service as disaster_svc

    disaster_svc.reconfigure(DEFAULT_CONFIG.model_copy(update={
        "enabled": True, "endpoint": "http://disaster-gateway",
        "max_retries": 0, "retry_backoff_s": 0.0}))
    disaster_svc.cache().clear()
    monkeypatch.setenv("DISASTER_API_KEY", "test-key")
    monkeypatch.setattr("httpx.AsyncClient.get", _mock_response(
        status_code=httpx.ConnectError("no route")))
    out = await disaster_svc.active_advisories()
    assert out["availability"] == "UNAVAILABLE"
    assert out["advisories"] == []
    assert "delivery" not in out
    disaster_svc.reconfigure(DEFAULT_CONFIG)
    disaster_svc.cache().clear()


# ===========================================================================
# Phase 8 — Hydrology (CWC) provider test matrix (§8.5)
# ===========================================================================
def _cwc_ready(**extra):
    from integrations.hydrology.adapter import CWCProvider

    cfg = CWC_CFG.model_copy(update={
        "enabled": True, "endpoint": "http://cwc-feed",
        "max_retries": extra.pop("max_retries", 0),
        "retry_backoff_s": 0.0, **extra})
    return CWCProvider(cfg)


def _reading(code="BRMP", level=84.21, trend="RISING"):
    return {"station_code": code, "water_level_m": level,
            "level_trend": trend,
            "observed_at": "2026-09-08T04:00:00Z"}


async def test_cwc_timeout_retries_then_reports_unavailable(monkeypatch):
    """§8.5-4 — timeout: retried per config, then explicit SourceUnavailable."""
    a = _cwc_ready(max_retries=2)
    calls = {"n": 0}
    monkeypatch.setenv("CWC_API_KEY", "test-key")
    monkeypatch.setattr("httpx.AsyncClient.get", _mock_response(
        status_code=httpx.TimeoutException("connect timeout"), calls=calls))
    with pytest.raises(SourceUnavailable):
        await a.fetch()
    assert calls["n"] == 3                      # 1 initial + 2 retries
    h = a.health()
    assert h.status == "UNAVAILABLE"            # never had a success
    assert h.consecutive_failures == 3
    assert h.last_failure_at is not None


async def test_cwc_http_401_is_explicit_unavailable_not_crash(monkeypatch):
    """§8.5-6 — authentication failure: explicit unavailable, no crash."""
    a = _cwc_ready(max_retries=1)
    calls = {"n": 0}
    monkeypatch.setenv("CWC_API_KEY", "wrong-key")
    monkeypatch.setattr("httpx.AsyncClient.get", _mock_response(
        status_code=401, calls=calls))
    with pytest.raises(SourceUnavailable) as excinfo:
        await a.fetch()
    assert calls["n"] == 2                      # retried once, then gave up
    assert "401" in str(excinfo.value)
    assert a.health().consecutive_failures == 2


async def test_cwc_mocked_readings_envelope_normalizes(monkeypatch):
    """§8.5-2 — mocked 200 readings envelope: unwrap + normalize + health."""
    a = _cwc_ready()
    payload = {"readings": [_reading("BRMP", 84.21, "RISING"),
                            _reading("DHAB", 12.5, "FALLING")]}
    monkeypatch.setenv("CWC_API_KEY", "test-key")
    monkeypatch.setattr("httpx.AsyncClient.get",
                        _mock_response(payload=payload))
    out = await a.fetch()
    assert len(out) == 2
    assert {r["station_code"] for r in out} == {"BRMP", "DHAB"}
    assert {r["level_trend"] for r in out} == {"RISING", "FALLING"}
    assert all(r["source"] == "CWC" for r in out)
    h = a.health()
    assert h.status == "HEALTHY" and h.last_success_at is not None


async def test_hydrology_service_cache_fallback_on_provider_failure(monkeypatch):
    """§8.5-7 — feed dies after a good fetch: serve last-known levels,
    explicitly marked cache-fallback, honestly age-labeled (never faked)."""
    from integrations.hydrology.adapter import DEFAULT_CONFIG
    from integrations.hydrology import service as hydro_svc

    hydro_svc.reconfigure(DEFAULT_CONFIG.model_copy(update={
        "enabled": True, "endpoint": "http://cwc-feed",
        "max_retries": 0, "retry_backoff_s": 0.0}))
    hydro_svc.cache().clear()
    monkeypatch.setenv("CWC_API_KEY", "test-key")

    monkeypatch.setattr("httpx.AsyncClient.get", _mock_response(
        payload={"readings": [_reading("BRMP", 84.21, "RISING")]}))
    out1 = await hydro_svc.latest_levels()
    assert out1["availability"] == "LIVE"
    assert "delivery" not in out1               # live path contract unchanged
    assert len(out1["levels"]) == 1
    assert out1["levels"][0]["water_level_m"] == 84.21

    monkeypatch.setattr("httpx.AsyncClient.get", _mock_response(
        status_code=httpx.ConnectError("cable cut")))
    out2 = await hydro_svc.latest_levels()
    assert out2["delivery"] == "cache-fallback"
    assert out2["levels"] == out1["levels"]
    assert out2["availability"] in {"LIVE", "RECENT", "STALE"}
    assert 0.0 <= out2["confidence"] <= 1.0
    assert "cable cut" in out2["reason"]
    # restore module state for other tests
    hydro_svc.reconfigure(DEFAULT_CONFIG)
    hydro_svc.cache().clear()


async def test_hydrology_service_cache_fallback_labels_stale_not_live(monkeypatch):
    """Old cached readings are labeled STALE — never presented as live."""
    from integrations.hydrology.adapter import DEFAULT_CONFIG
    from integrations.hydrology import service as hydro_svc

    hydro_svc.reconfigure(DEFAULT_CONFIG.model_copy(update={
        "enabled": True, "endpoint": "http://cwc-feed",
        "max_retries": 0, "retry_backoff_s": 0.0}))
    hydro_svc.cache().clear()
    hydro_svc.cache().store(
        [{"station_code": "OLD", "water_level_m": 90.0,
          "level_trend": "RISING", "observed_at": "2026-09-08T01:00:00Z",
          "source": "CWC"}],
        at=datetime.now(timezone.utc) - timedelta(hours=6))
    monkeypatch.setenv("CWC_API_KEY", "test-key")
    monkeypatch.setattr("httpx.AsyncClient.get", _mock_response(
        status_code=httpx.ConnectError("gateway down")))
    out = await hydro_svc.latest_levels()
    assert out["delivery"] == "cache-fallback"
    assert out["availability"] == "STALE"
    assert len(out["levels"]) == 1
    hydro_svc.reconfigure(DEFAULT_CONFIG)
    hydro_svc.cache().clear()


async def test_hydrology_service_without_cache_reports_unavailable(monkeypatch):
    """Failure with an EMPTY cache keeps the existing UNAVAILABLE contract."""
    from integrations.hydrology.adapter import DEFAULT_CONFIG
    from integrations.hydrology import service as hydro_svc

    hydro_svc.reconfigure(DEFAULT_CONFIG.model_copy(update={
        "enabled": True, "endpoint": "http://cwc-feed",
        "max_retries": 0, "retry_backoff_s": 0.0}))
    hydro_svc.cache().clear()
    monkeypatch.setenv("CWC_API_KEY", "test-key")
    monkeypatch.setattr("httpx.AsyncClient.get", _mock_response(
        status_code=httpx.ConnectError("no route")))
    out = await hydro_svc.latest_levels()
    assert out["availability"] == "UNAVAILABLE"
    assert out["levels"] == []
    assert "delivery" not in out
    hydro_svc.reconfigure(DEFAULT_CONFIG)
    hydro_svc.cache().clear()


# ===========================================================================
# Phase 8 — Satellite (Copernicus) provider test matrix (§8.5)
# OAuth2 client-credentials flow (token POST + catalogue GET), so the mock
# replaces httpx.AsyncClient entirely and serves both legs.
# ===========================================================================
def _scene_item(id="S2A_20260820"):
    return {"Id": id,
            "ContentDate": {"Start": "2026-08-20T04:30:00Z"},
            "GeoFootprint": {"type": "Polygon",
                             "coordinates": [[[89, 22], [97, 22],
                                             [97, 28], [89, 28],
                                             [89, 22]]]}}


def _copernicus_client(token_payload, catalogue_payload, calls):
    """httpx.AsyncClient replacement serving the token POST + catalogue GET."""

    class _Resp:
        def __init__(self, status, payload):
            self.status_code = status
            self._payload = payload

        def raise_for_status(self):
            if self.status_code >= 400:
                raise httpx.HTTPStatusError(
                    f"{self.status_code}", request=None, response=self)

        def json(self):
            return self._payload

    class _Client:
        def __init__(self, *a, **kw):
            pass

        async def __aenter__(self):
            return self

        async def __aexit__(self, *a):
            return False

        async def post(self, url, **kw):
            if isinstance(token_payload, Exception):
                raise token_payload
            return _Resp(200, token_payload)

        async def get(self, url, **kw):
            if calls is not None:
                calls["n"] += 1
            if isinstance(catalogue_payload, Exception):
                raise catalogue_payload
            return _Resp(200, catalogue_payload)

    return _Client


def _copernicus_ready(**extra):
    cfg = COPERNICUS_CFG.model_copy(update={
        "enabled": True,
        "endpoint": "https://catalogue.example/odata/v1",
        "max_retries": extra.pop("max_retries", 0),
        "retry_backoff_s": 0.0, **extra})
    return CopernicusProvider(cfg)


async def test_copernicus_timeout_retries_then_reports_unavailable(monkeypatch):
    """§8.5-4 — token POST timeout: retried per config, then SourceUnavailable."""
    a = _copernicus_ready(max_retries=2)
    calls = {"n": 0}
    monkeypatch.setenv("COPERNICUS_CLIENT_ID", "test-id")
    monkeypatch.setenv("COPERNICUS_CLIENT_SECRET", "test-secret")
    monkeypatch.setattr("httpx.AsyncClient", _copernicus_client(
        token_payload=httpx.TimeoutException("connect timeout"),
        catalogue_payload=None, calls=calls))
    with pytest.raises(SourceUnavailable):
        await a.fetch()
    assert calls["n"] == 0                       # never reached the GET
    assert a.health().status == "UNAVAILABLE"    # never had a success
    assert a.health().consecutive_failures == 3  # 1 initial + 2 retries


async def test_copernicus_token_401_is_explicit_unavailable(monkeypatch):
    """§8.5-6 — credential rejected at the token endpoint: explicit
    SourceUnavailable, no crash (401/403 handled inside _access_token)."""
    a = _copernicus_ready(max_retries=2)
    calls = {"n": 0}
    monkeypatch.setenv("COPERNICUS_CLIENT_ID", "bad-id")
    monkeypatch.setenv("COPERNICUS_CLIENT_SECRET", "bad-secret")

    class _401:
        status_code = 401

        def raise_for_status(self):
            pass

        def json(self):
            return {}

    class _Client:
        def __init__(self, *a, **kw):
            pass

        async def __aenter__(self):
            return self

        async def __aexit__(self, *a):
            return False

        async def post(self, url, **kw):
            return _401()

        async def get(self, url, **kw):
            return _401()

    monkeypatch.setattr("httpx.AsyncClient", _Client)
    with pytest.raises(SourceUnavailable) as excinfo:
        await a.fetch()
    assert "credential rejected (401)" in str(excinfo.value)
    assert calls["n"] == 0                       # failed at token, never GET'd


async def test_copernicus_mocked_catalogue_normalizes(monkeypatch):
    """§8.5-2 — mocked token + catalogue: scenes normalize + health HEALTHY."""
    a = _copernicus_ready()
    calls = {"n": 0}
    monkeypatch.setenv("COPERNICUS_CLIENT_ID", "test-id")
    monkeypatch.setenv("COPERNICUS_CLIENT_SECRET", "test-secret")
    monkeypatch.setattr("httpx.AsyncClient", _copernicus_client(
        token_payload={"access_token": "tok", "expires_in": 300},
        catalogue_payload={"value": [_scene_item("S2A_20260820"),
                                     _scene_item("S2B_20260821")]},
        calls=calls))
    out = await a.fetch()
    assert calls["n"] == 1
    assert len(out) == 2
    assert {s["external_id"] for s in out} == {"S2A_20260820", "S2B_20260821"}
    assert all(s["provider"] == "COPERNICUS" for s in out)
    assert out[0]["coverage_bbox"] == [89.0, 22.0, 97.0, 28.0]
    h = a.health()
    assert h.status == "HEALTHY" and h.last_success_at is not None


async def test_copernicus_service_cache_fallback_on_provider_failure(monkeypatch):
    """§8.5-5/§8.5-7 — feed dies after a good fetch: serve last-known scenes,
    explicitly marked cache-fallback, honestly age-labeled (never faked)."""
    from integrations.satellite.copernicus_service import (
        DEFAULT_CONFIG, cache, latest_scenes, reconfigure)

    reconfigure(DEFAULT_CONFIG.model_copy(update={
        "enabled": True, "endpoint": "https://catalogue.example/odata/v1",
        "max_retries": 0, "retry_backoff_s": 0.0}))
    cache().clear()
    monkeypatch.setenv("COPERNICUS_CLIENT_ID", "test-id")
    monkeypatch.setenv("COPERNICUS_CLIENT_SECRET", "test-secret")

    ok_client = _copernicus_client(
        token_payload={"access_token": "tok", "expires_in": 300},
        catalogue_payload={"value": [_scene_item("S2A_20260820")]},
        calls=None)
    monkeypatch.setattr("httpx.AsyncClient", ok_client)
    out1 = await latest_scenes()
    assert out1["availability"] == "LIVE"
    assert "delivery" not in out1                   # live path contract unchanged
    assert len(out1["scenes"]) == 1

    # Provider dies AFTER auth (token is cached from the first fetch): the
    # catalogue GET now fails, so the cache-fallback path serves last-known
    # scenes. A generic exception is retried then wrapped as SourceUnavailable.
    monkeypatch.setattr("httpx.AsyncClient", _copernicus_client(
        token_payload={"access_token": "tok", "expires_in": 300},
        catalogue_payload=httpx.ConnectError("cable cut"),
        calls=None))
    out2 = await latest_scenes()
    assert out2["delivery"] == "cache-fallback"
    assert out2["scenes"] == out1["scenes"]
    assert out2["availability"] in {"LIVE", "RECENT", "STALE"}
    assert 0.0 <= out2["confidence"] <= 1.0
    assert "cable cut" in out2["reason"]
    # restore module state for other tests
    reconfigure(DEFAULT_CONFIG)
    cache().clear()


async def test_copernicus_service_cache_fallback_labels_stale_not_live(monkeypatch):
    """Old cached scenes are labeled STALE — never presented as live."""
    from integrations.satellite.copernicus_service import (
        DEFAULT_CONFIG, cache, latest_scenes, reconfigure)

    reconfigure(DEFAULT_CONFIG.model_copy(update={
        "enabled": True, "endpoint": "https://catalogue.example/odata/v1",
        "max_retries": 0, "retry_backoff_s": 0.0}))
    cache().clear()
    cache().store(
        [{"external_id": "OLD", "provider": "COPERNICUS",
          "acquired_at": "2026-09-08T01:00:00Z",
          "coverage_bbox": [89.0, 22.0, 97.0, 28.0]}],
        at=datetime.now(timezone.utc) - timedelta(hours=8))
    monkeypatch.setenv("COPERNICUS_CLIENT_ID", "test-id")
    monkeypatch.setenv("COPERNICUS_CLIENT_SECRET", "test-secret")
    monkeypatch.setattr("httpx.AsyncClient", _copernicus_client(
        token_payload=httpx.ConnectError("gateway down"),
        catalogue_payload=None, calls=None))
    out = await latest_scenes()
    assert out["delivery"] == "cache-fallback"
    assert out["availability"] == "STALE"
    assert len(out["scenes"]) == 1
    reconfigure(DEFAULT_CONFIG)
    cache().clear()


async def test_copernicus_service_without_cache_reports_unavailable(monkeypatch):
    """Failure with an EMPTY cache keeps the existing UNAVAILABLE contract."""
    from integrations.satellite.copernicus_service import (
        DEFAULT_CONFIG, cache, latest_scenes, reconfigure)

    reconfigure(DEFAULT_CONFIG.model_copy(update={
        "enabled": True, "endpoint": "https://catalogue.example/odata/v1",
        "max_retries": 0, "retry_backoff_s": 0.0}))
    cache().clear()
    monkeypatch.setenv("COPERNICUS_CLIENT_ID", "test-id")
    monkeypatch.setenv("COPERNICUS_CLIENT_SECRET", "test-secret")
    monkeypatch.setattr("httpx.AsyncClient", _copernicus_client(
        token_payload=httpx.ConnectError("no route"),
        catalogue_payload=None, calls=None))
    out = await latest_scenes()
    assert out["availability"] == "UNAVAILABLE"
    assert out["scenes"] == []
    assert "delivery" not in out
    reconfigure(DEFAULT_CONFIG)
    cache().clear()


# ===========================================================================
# Phase 8 — Routing (OSRM) provider test matrix (§8.5)
# OSRMProvider wraps BaseAdapter (does not extend it) and implements its own
# retry/rate-limit. Routing is safety-critical: a stale route must NEVER be
# silently substituted for navigation, so the cache is read via an explicit
# last_known_route() accessor and calculate_route keeps raising on failure.
# ===========================================================================
def _osrm_ready(**extra):
    from integrations.routing.providers import OSRMProvider

    cfg = OSRM_CFG.model_copy(update={
        "enabled": True, "endpoint": "http://osrm.internal",
        "max_retries": extra.pop("max_retries", 0),
        "retry_backoff_s": 0.0, **extra})
    return OSRMProvider(cfg)


_OSRM_COORDS = [(91.7, 26.1), (91.8, 26.2)]


async def _ok_get(self, url, params=None, headers=None, **kw):
    class R:
        status_code = 200

        def raise_for_status(self):
            pass

        def json(self):
            return {"code": "Ok", "routes": [{
                "distance": 12345.0, "duration": 900.0,
                "geometry": {"coordinates": [
                    [91.7, 26.1], [91.75, 26.15], [91.8, 26.2]]}}]}
    return R()


async def test_osrm_timeout_retries_then_reports_unavailable(monkeypatch):
    """§8.5-4 — request timeout: retried per config, then SourceUnavailable."""
    a = _osrm_ready(max_retries=2)
    calls = {"n": 0}

    async def timed_out(self, url, params=None, headers=None, **kw):
        calls["n"] += 1
        raise httpx.TimeoutException("connect timeout")

    monkeypatch.setattr("httpx.AsyncClient.get", timed_out)
    with pytest.raises(SourceUnavailable):
        await a.calculate_route(_OSRM_COORDS)
    assert calls["n"] == 3                       # 1 initial + 2 retries
    h = a.health()
    assert h.status == "UNAVAILABLE"             # never had a success
    assert h.consecutive_failures == 3


async def test_osrm_service_caches_last_successful_route(monkeypatch):
    """§8.1 — a successful calculate_route caches the normalized route
    per coordinate set."""
    from integrations.routing import service as routing_svc

    routing_svc.reconfigure(OSRM_CFG.model_copy(update={
        "enabled": True, "endpoint": "http://osrm.internal",
        "max_retries": 0}))
    routing_svc.cache().clear()
    monkeypatch.setattr("httpx.AsyncClient.get", _ok_get)

    route = await routing_svc.calculate_route(_OSRM_COORDS)
    assert route.distance_m == 12345.0

    cached = routing_svc.cache().load(key="91.700000,26.100000;91.800000,26.200000")
    assert cached is not None
    assert cached["records"][0]["distance_m"] == 12345.0
    routing_svc.reconfigure(None)
    routing_svc.cache().clear()


async def test_osrm_last_known_route_fallback(monkeypatch):
    """§8.2 — after a good fetch, last_known_route() returns the cached
    route with an explicit cache-fallback label + honest availability
    (never presented as live)."""
    from integrations.routing import service as routing_svc

    routing_svc.reconfigure(OSRM_CFG.model_copy(update={
        "enabled": True, "endpoint": "http://osrm.internal",
        "max_retries": 0}))
    routing_svc.cache().clear()
    monkeypatch.setattr("httpx.AsyncClient.get", _ok_get)
    await routing_svc.calculate_route(_OSRM_COORDS)

    degraded = routing_svc.last_known_route(_OSRM_COORDS)
    assert degraded is not None
    assert degraded["delivery"] == "cache-fallback"
    assert degraded["availability"] in {"RECENT", "STALE", "EXPIRED"}
    assert degraded["route"].distance_m == 12345.0
    assert degraded["cache_age_s"] >= 0
    routing_svc.reconfigure(None)
    routing_svc.cache().clear()


async def test_osrm_calculate_route_still_raises_on_failure(monkeypatch):
    """§8.2 safety — calculate_route keeps raising SourceUnavailable on a
    provider failure (existing contract preserved; callers fall back to the
    internal engine). A stale route is never silently substituted."""
    from integrations.routing import service as routing_svc

    routing_svc.reconfigure(OSRM_CFG.model_copy(update={
        "enabled": True, "endpoint": "http://osrm.internal",
        "max_retries": 0}))
    routing_svc.cache().clear()
    # Pre-populate the cache to prove it is NOT served silently.
    routing_svc.cache().store(
        [{"provider": "OSRM", "distance_m": 100.0, "duration_s": 10.0,
          "computed_at": "2026-09-08T05:00:00Z", "confidence": 0.5}],
        key="91.700000,26.100000;91.800000,26.200000")

    async def broken(self, url, params=None, headers=None, **kw):
        raise httpx.ConnectError("gateway down")

    monkeypatch.setattr("httpx.AsyncClient.get", broken)
    with pytest.raises(SourceUnavailable):
        await routing_svc.calculate_route(_OSRM_COORDS)
    # last_known_route() is the ONLY way to read the cached copy.
    assert routing_svc.last_known_route(_OSRM_COORDS) is not None
    routing_svc.reconfigure(None)
    routing_svc.cache().clear()


async def test_osrm_last_known_route_none_when_never_succeeded(monkeypatch):
    """No successful fetch yet → last_known_route() returns None (explicit
    data gap, never a fabricated route)."""
    from integrations.routing import service as routing_svc

    routing_svc.reconfigure(OSRM_CFG.model_copy(update={
        "enabled": True, "endpoint": "http://osrm.internal",
        "max_retries": 0}))
    routing_svc.cache().clear()
    assert routing_svc.last_known_route(_OSRM_COORDS) is None
    routing_svc.reconfigure(None)
    routing_svc.cache().clear()