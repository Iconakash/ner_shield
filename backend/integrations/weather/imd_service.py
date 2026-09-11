"""IMD service: dedicated adapter slot so the generic weather-primary source
and the authorized IMD source stay independently configurable/observable.

Phase 8 (§8.1-8.2): same LastKnownCache contract as weather.service — on an
upstream failure the last successful fetch is served with its own honest
availability band and a `delivery: cache-fallback` marker.
"""
from datetime import datetime, timezone

from integrations.base import IntegrationConfig, LastKnownCache, SourceUnavailable
from integrations.weather.adapter import WeatherAdapter
from integrations.weather.imd import DEFAULT_CONFIG, IMDProvider

_adapter: WeatherAdapter = IMDProvider(DEFAULT_CONFIG)
_cache = LastKnownCache()


def get_adapter() -> WeatherAdapter:
    return _adapter


def reconfigure(config: IntegrationConfig) -> None:
    global _adapter
    _adapter = IMDProvider(config)


def cache() -> LastKnownCache:
    """Phase 8 — direct access for tests/ops (store/clear last-known data)."""
    return _cache


async def latest_observations(**params) -> dict:
    """Same explicit-availability contract as weather.service."""
    try:
        records = await _adapter.fetch(**params)
    except SourceUnavailable as exc:
        cached = _cache.load()
        if cached:
            h = _adapter.health()
            return {"availability": _classify(cached["stored_at"]),
                    "source": _adapter.config.provider,
                    "confidence": h.confidence,
                    "observations": cached["records"],
                    "delivery": "cache-fallback",
                    "reason": str(exc),
                    "cache_age_s": cached["age_s"]}
        return {"availability": "UNAVAILABLE", "source": _adapter.config.provider,
                "confidence": 0.0, "reason": str(exc), "observations": []}
    _cache.store(records)
    h = _adapter.health()
    return {"availability": _classify(h.last_success_at),
            "source": _adapter.config.provider,
            "confidence": h.confidence, "observations": records}


def _classify(last_success_at) -> str:
    if last_success_at is None:
        return "UNAVAILABLE"
    age_min = (datetime.now(timezone.utc) - last_success_at).total_seconds() / 60
    if age_min <= 30:
        return "LIVE"
    if age_min <= 180:
        return "RECENT"
    return "STALE"