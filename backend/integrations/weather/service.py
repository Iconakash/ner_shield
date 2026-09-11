"""Weather service: adapter orchestration with explicit availability labeling.

Phase 8 (§8.1-8.2): the last successful normalized observations are kept in a
LastKnownCache. When the upstream provider fails, the cached copy is served
with its OWN age-derived availability band plus a `delivery: cache-fallback`
marker — the caller can always tell last-known data from live data.
"""
from integrations.base import IntegrationConfig, LastKnownCache, SourceUnavailable
from integrations.weather.adapter import DEFAULT_CONFIG, WeatherAdapter

_adapter = WeatherAdapter(DEFAULT_CONFIG)
_cache = LastKnownCache()


def get_adapter() -> WeatherAdapter:
    return _adapter


def reconfigure(config: IntegrationConfig) -> None:
    """Swap configuration (deployment-time). Keeps health counters fresh."""
    global _adapter
    _adapter = WeatherAdapter(config)


def cache() -> LastKnownCache:
    """Phase 8 — direct access for tests/ops (store/clear last-known data)."""
    return _cache


async def latest_observations(**params) -> dict:
    """Returns {'availability', 'source', 'confidence', 'observations'}.
    availability is ALWAYS one of LIVE/RECENT/STALE/UNAVAILABLE/SIMULATED.
    Cache-fallback responses add `delivery`, `reason` and `cache_age_s`."""
    try:
        records = await _adapter.fetch(**params)
    except SourceUnavailable as exc:
        cached = _cache.load()
        if cached:
            # §8.2 — serve the last-known copy, honestly age-labeled. The
            # adapter's own confidence (staleness × failure reliability)
            # describes exactly how much to trust it.
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
    # §8.1 — write-through cache of every successful normalized fetch.
    _cache.store(records)
    h = _adapter.health()
    return {"availability": _classify(h.last_success_at),
            "source": _adapter.config.provider,
            "confidence": h.confidence, "observations": records}


def _classify(last_success_at) -> str:
    if last_success_at is None:
        return "UNAVAILABLE"
    from datetime import datetime, timezone

    age_min = (datetime.now(timezone.utc) - last_success_at).total_seconds() / 60
    if age_min <= 30:
        return "LIVE"
    if age_min <= 180:
        return "RECENT"
    return "STALE"

