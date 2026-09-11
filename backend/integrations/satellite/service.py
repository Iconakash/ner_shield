"""Satellite service: same explicit-availability pattern as weather/disaster."""
from datetime import datetime, timezone

from integrations.base import IntegrationConfig, SourceUnavailable
from integrations.satellite.adapter import DEFAULT_CONFIG, SatelliteAdapter

_adapter = SatelliteAdapter(DEFAULT_CONFIG)


def get_adapter() -> SatelliteAdapter:
    return _adapter


def reconfigure(config: IntegrationConfig) -> None:
    global _adapter
    _adapter = SatelliteAdapter(config)


async def latest_scenes(**params) -> dict:
    try:
        records = await _adapter.fetch(**params)
    except SourceUnavailable as exc:
        return {"availability": "UNAVAILABLE",
                "source": _adapter.config.provider, "confidence": 0.0,
                "reason": str(exc), "scenes": []}
    h = _adapter.health()
    age_min = ((datetime.now(timezone.utc) - h.last_success_at).total_seconds()
               / 60) if h.last_success_at else None
    availability = ("LIVE" if age_min is not None and age_min <= 60
                    else "RECENT" if age_min is not None and age_min <= 24 * 60
                    else "STALE" if age_min is not None else "UNAVAILABLE")
    return {"availability": availability,
            "source": _adapter.config.provider,
            "confidence": h.confidence, "scenes": records}
