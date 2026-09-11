"""Copernicus service: dedicated adapter slot (independent of satellite-primary).

Phase 8 (§8.1-§8.2): last successful normalized scenes are kept in a LastKnownCache.
On an upstream failure the cached copy is served with its own honest availability
band plus a `delivery: cache-fallback` marker — never presented as live, never
fabricated. The live-path availability semantics ("LIVE" iff a success) are kept
unchanged; age bands apply to the cache-fallback path only.
"""
from datetime import datetime, timezone

from integrations.base import IntegrationConfig, LastKnownCache, SourceUnavailable
from integrations.satellite.adapter import DEFAULT_CONFIG as _PRIMARY_CFG
from integrations.satellite.copernicus import DEFAULT_CONFIG, CopernicusProvider

_adapter = CopernicusProvider(DEFAULT_CONFIG)
_cache = LastKnownCache()


def get_adapter() -> CopernicusProvider:
    return _adapter


def reconfigure(config: IntegrationConfig) -> None:
    global _adapter
    _adapter = CopernicusProvider(config)


def cache() -> LastKnownCache:
    """Phase 8 — direct access for tests/ops (store/clear last-known data)."""
    return _cache


async def latest_scenes(**params) -> dict:
    """Same explicit-availability contract as satellite.service."""
    try:
        records = await _adapter.fetch(**params)
    except SourceUnavailable as exc:
        cached = _cache.load()
        if cached:
            h = _adapter.health()
            return {"availability": _classify(cached["stored_at"]),
                    "source": _adapter.config.provider,
                    "confidence": h.confidence,
                    "scenes": cached["records"],
                    "delivery": "cache-fallback",
                    "reason": str(exc),
                    "cache_age_s": cached["age_s"]}
        return {"availability": "UNAVAILABLE", "source": _adapter.config.provider,
                "confidence": 0.0, "reason": str(exc), "scenes": []}
    _cache.store(records)
    h = _adapter.health()
    availability = "LIVE" if h.last_success_at else "UNAVAILABLE"
    return {"availability": availability, "source": _adapter.config.provider,
            "confidence": h.confidence, "scenes": records}


def _classify(last_success_at) -> str:
    """Age-band labeling for cached copies (LIVE ≤60m, RECENT ≤360m, STALE)."""
    if last_success_at is None:
        return "UNAVAILABLE"
    age_min = (datetime.now(timezone.utc) - last_success_at).total_seconds() / 60
    if age_min <= 60:
        return "LIVE"
    if age_min <= 360:
        return "RECENT"
    return "STALE"


# keep a reference so linters don't flag the primary config import used by docs
_ = _PRIMARY_CFG