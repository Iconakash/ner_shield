"""Disaster advisory service: same orchestration pattern as weather.

Phase 8 (§8.1-8.2): last successful advisories are kept in a LastKnownCache;
on an upstream failure the cached copy is served with its own age-derived
availability band plus a `delivery: cache-fallback` marker (never faked live).
The live-path availability semantics are unchanged.
"""
from datetime import datetime, timezone

from integrations.base import IntegrationConfig, LastKnownCache, SourceUnavailable
from integrations.disaster.adapter import DEFAULT_CONFIG, DisasterAdapter

_adapter = DisasterAdapter(DEFAULT_CONFIG)
_cache = LastKnownCache()


def get_adapter() -> DisasterAdapter:
    return _adapter


def reconfigure(config: IntegrationConfig) -> None:
    global _adapter
    _adapter = DisasterAdapter(config)


def cache() -> LastKnownCache:
    """Phase 8 — direct access for tests/ops (store/clear last-known data)."""
    return _cache


async def active_advisories(**params) -> dict:
    """Explicit-availability wrapper; never substitutes simulated advisories."""
    try:
        records = await _adapter.fetch(**params)
    except SourceUnavailable as exc:
        cached = _cache.load()
        if cached:
            h = _adapter.health()
            return {"availability": _classify(cached["stored_at"]),
                    "source": _adapter.config.provider,
                    "confidence": h.confidence,
                    "advisories": cached["records"],
                    "delivery": "cache-fallback",
                    "reason": str(exc),
                    "cache_age_s": cached["age_s"]}
        return {"availability": "UNAVAILABLE", "source": _adapter.config.provider,
                "confidence": 0.0, "reason": str(exc), "advisories": []}
    _cache.store(records)
    h = _adapter.health()
    return {"availability": ("LIVE" if h.status == "HEALTHY"
                             else ("RECENT" if h.last_success_at else "UNAVAILABLE")),
            "source": _adapter.config.provider,
            "confidence": h.confidence, "advisories": records}


def _classify(last_success_at) -> str:
    """Age-band labeling for cached copies (LIVE ≤30m, RECENT ≤180m, STALE)."""
    if last_success_at is None:
        return "UNAVAILABLE"
    age_min = (datetime.now(timezone.utc) - last_success_at).total_seconds() / 60
    if age_min <= 30:
        return "LIVE"
    if age_min <= 180:
        return "RECENT"
    return "STALE"
