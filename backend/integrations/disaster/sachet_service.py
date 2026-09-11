"""SACHET service: dedicated adapter slot (independent of disaster-primary).

Phase 8 (§8.1-8.2): same LastKnownCache contract as the weather services —
every successful normalized fetch is cached; on an upstream failure the last
successful advisories are served with their own honest availability band and a
`delivery: cache-fallback` marker. Never presented as live, never fabricated.
"""
from datetime import datetime, timezone

from integrations.base import IntegrationConfig, LastKnownCache, SourceUnavailable
from integrations.disaster.adapter import DisasterAdapter
from integrations.disaster.sachet import DEFAULT_CONFIG, SachetProvider

_adapter: DisasterAdapter = SachetProvider(DEFAULT_CONFIG)
_cache = LastKnownCache()


def get_adapter() -> DisasterAdapter:
    return _adapter


def reconfigure(config: IntegrationConfig) -> None:
    global _adapter
    _adapter = SachetProvider(config)


def cache() -> LastKnownCache:
    """Phase 8 — direct access for tests/ops (store/clear last-known data)."""
    return _cache


async def active_advisories(**params) -> dict:
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
    return {"availability": _classify(h.last_success_at),
            "source": _adapter.config.provider,
            "confidence": h.confidence, "advisories": records}


def _classify(last_success_at) -> str:
    if last_success_at is None:
        return "UNAVAILABLE"
    age_min = (datetime.now(timezone.utc) - last_success_at).total_seconds() / 60
    if age_min <= 30:
        return "LIVE"
    if age_min <= 180:
        return "RECENT"
    return "STALE"