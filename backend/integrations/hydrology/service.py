"""Hydrology service: same explicit-availability pattern as weather/disaster.

Phase 8 (§8.1-§8.2): last successful normalized river-level readings are kept in
a LastKnownCache. On an upstream failure the cached copy is served with its own
honest availability band (reusing the service's 60/360-min bands) plus a
`delivery: cache-fallback` marker — never presented as live, never fabricated.
"""
from datetime import datetime, timezone

from integrations.base import IntegrationConfig, LastKnownCache, SourceUnavailable
from integrations.hydrology.adapter import DEFAULT_CONFIG, CWCProvider

_adapter = CWCProvider(DEFAULT_CONFIG)
_cache = LastKnownCache()


def get_adapter() -> CWCProvider:
    return _adapter


def reconfigure(config: IntegrationConfig) -> None:
    global _adapter
    _adapter = CWCProvider(config)


def cache() -> LastKnownCache:
    """Phase 8 — direct access for tests/ops (store/clear last-known data)."""
    return _cache


async def latest_levels(**params) -> dict:
    try:
        records = await _adapter.fetch(**params)
    except SourceUnavailable as exc:
        cached = _cache.load()
        if cached:
            h = _adapter.health()
            return {"availability": _classify(cached["stored_at"]),
                    "source": _adapter.config.provider,
                    "confidence": h.confidence,
                    "levels": cached["records"],
                    "delivery": "cache-fallback",
                    "reason": str(exc),
                    "cache_age_s": cached["age_s"]}
        return {"availability": "UNAVAILABLE", "source": _adapter.config.provider,
                "confidence": 0.0, "reason": str(exc), "levels": []}
    _cache.store(records)
    h = _adapter.health()
    return {"availability": _classify(h.last_success_at),
            "source": _adapter.config.provider,
            "confidence": h.confidence, "levels": records}


def _classify(last_success_at) -> str:
    if last_success_at is None:
        return "UNAVAILABLE"
    age_min = (datetime.now(timezone.utc) - last_success_at).total_seconds() / 60
    if age_min <= 60:
        return "LIVE"
    if age_min <= 360:
        return "RECENT"
    return "STALE"