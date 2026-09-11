"""Data-source health service: DB registry + live adapter state, merged.

Every row answers: what is the source, is it enabled/configured, when did it
last succeed, how fresh is its newest observation, and how much do we trust it.
Freshness classification is shared with the UI contract:
LIVE <=30min · RECENT <=3h · STALE older · UNAVAILABLE never/disabled.
"""
from datetime import datetime, timezone

from sqlalchemy import text
from sqlalchemy.ext.asyncio import AsyncSession

# Adapter registry — extend as more integration packages land.
def _adapters():
    from integrations.disaster.sachet_service import get_adapter as sachet_adapter
    from integrations.disaster.service import get_adapter as disaster_adapter
    from integrations.hydrology.service import get_adapter as cwc_adapter
    from integrations.routing import service as routing_svc
    from integrations.satellite.copernicus_service import \
        get_adapter as copernicus_adapter
    from integrations.satellite.service import get_adapter as satellite_adapter
    from integrations.weather.imd_service import get_adapter as imd_adapter
    from integrations.weather.service import get_adapter as weather_adapter

    out = [weather_adapter(), imd_adapter(), disaster_adapter(),
           sachet_adapter(), satellite_adapter(), copernicus_adapter(),
           cwc_adapter()]
    ext_routing = routing_svc.get_provider()
    if ext_routing is not None:
        out.append(ext_routing)
    return out


FRESH_LIVE_MIN = 30
FRESH_RECENT_MIN = 180


def classify_freshness(last_observation_at) -> str:
    if last_observation_at is None:
        return "UNAVAILABLE"
    age_min = (datetime.now(timezone.utc)
               - last_observation_at).total_seconds() / 60
    if age_min <= FRESH_LIVE_MIN:
        return "LIVE"
    if age_min <= FRESH_RECENT_MIN:
        return "RECENT"
    return "STALE"


async def list_sources(db: AsyncSession) -> list[dict]:
    rows = (await db.execute(text("""
        select name, source_type::text as source_type, provider, endpoint,
               status::text as status, enabled,
               last_success_at, last_failure_at, last_observation_at,
               consecutive_failures, last_error, confidence::float as confidence,
               license, updated_at
        from data_sources
        order by source_type, name
    """))).mappings().all()

    out = []
    for r in rows:
        item = dict(r)
        item["freshness"] = classify_freshness(item.get("last_observation_at"))
        out.append(item)
    return out


async def sync_adapter_health(system_db: AsyncSession) -> int:
    """Push in-process adapter health into the registry (worker-callable).
    Uses the SYSTEM connection because authenticated users cannot write here.
    Returns number of rows updated."""
    updated = 0
    for ad in _adapters():
        h = ad.health()
        await system_db.execute(text("""
            update data_sources set
              status = cast(:st as data_source_status),
              enabled = :en,
              last_success_at = coalesce(:ls, last_success_at),
              last_failure_at = coalesce(:lf, last_failure_at),
              consecutive_failures = :cf,
              last_error = :err,
              confidence = :conf
            where name = :name
        """), {"st": h.status, "en": h.enabled, "ls": h.last_success_at,
               "lf": h.last_failure_at, "cf": h.consecutive_failures,
               "err": h.last_error, "conf": h.confidence, "name": h.name})
        updated += 1
    return updated
