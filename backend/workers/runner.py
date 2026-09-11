"""Worker entrypoint:  python -m workers.runner

Jobs:
  * integration_health — attempts each enabled adapter fetch (no-op refusal for
    disabled/unconfigured sources), then pushes adapter health into the
    data_sources registry so the Command Center sees freshness.
  * weather_ingest / disaster_ingest — fetch + normalize; persistence into
    weather_feed / advisory tables lands with the live-source authorization
    (the adapters refuse to fabricate data until then, so these jobs log an
    explicit UNAVAILABLE state rather than writing simulated rows).

Run alongside the API: uvicorn app.main:app + python -m workers.runner
"""
import asyncio
import logging
import signal  # noqa: F401  (used on POSIX; Windows falls back to KeyboardInterrupt)
import sys

from integrations.base import SourceUnavailable
from integrations.disaster import service as disaster_svc
from integrations.disaster import sachet_service
from integrations.hydrology import service as hydrology_svc
from integrations.satellite import copernicus_service
from integrations.weather import imd_service
from integrations.weather import service as weather_svc

from workers import WorkerRunner


async def _attempt(source_label: str, fetch) -> None:
    """One ingestion cycle for a source. Explicit UNAVAILABLE is normal and
    logged at INFO — it must stay visible, never silent, never simulated."""
    try:
        result = await fetch()
        logging.getLogger("ner-shield.workers").info(
            "ingestion cycle done",
            extra={"data": {"source": source_label,
                            "availability": result.get("availability"),
                            "records": len(result.get("observations")
                                      or result.get("advisories")
                                      or result.get("scenes")
                                      or result.get("levels") or [])}})
    except SourceUnavailable as exc:
        logging.getLogger("ner-shield.workers").info(
            "source unavailable (pending authorization/config)",
            extra={"data": {"source": source_label, "reason": str(exc)[:200]}})


async def weather_ingest() -> None:
    await _attempt("weather-primary", weather_svc.latest_observations)


async def weather_imd_ingest() -> None:
    await _attempt("weather-imd", imd_service.latest_observations)


async def disaster_ingest() -> None:
    await _attempt("disaster-primary", disaster_svc.active_advisories)


async def disaster_sachet_ingest() -> None:
    await _attempt("disaster-sachet", sachet_service.active_advisories)


async def satellite_copernicus_ingest() -> None:
    await _attempt("satellite-copernicus", copernicus_service.latest_scenes)


async def hydrology_ingest() -> None:
    await _attempt("cwc-primary", hydrology_svc.latest_levels)


async def intel_assessment() -> None:
    """Closed-loop decision-intelligence cycle (additive).

    Fuses existing data into hazard assessments; creates/refreshes DEDUPLICATED
    alerts for HIGH+ hazards and SOURCE_CONFLICT conditions. Failures are logged
    and never crash the runner; the read-only nature means a failed cycle
    simply leaves existing predictions/alerts untouched.
    """
    log = logging.getLogger("ner-shield.workers.intel")
    try:
        from app.alerts import service as alerts_svc
        from app.core.db import SystemSession
        from app.intel import service as intel_svc

        async with SystemSession() as session:
            assessments = await intel_svc.assess_segments(session, limit=50)
            created = deduped = 0
            for row in assessments:
                for hz in row["hazards"]:
                    if not (hz["severity"] in ("HIGH", "CRITICAL")
                            or hz.get("conflict")):
                        continue
                    fp = f"{row['segment_id']}|{hz['hazard_type']}"
                    key = f"intel:{fp}"
                    if hz.get("conflict"):
                        level, atype = "WARNING", "SOURCE_CONFLICT"
                        title = (f"Source conflict — {hz['hazard_type']} "
                                 f"on {row['road_code']}")
                    elif hz["severity"] == "CRITICAL":
                        level, atype = "CRITICAL", f"{hz['hazard_type']}_RISK"
                        title = (f"{hz['hazard_type']} CRITICAL — "
                                 f"{row['road_code']}")
                    else:
                        level, atype = "HIGH", f"{hz['hazard_type']}_RISK"
                        title = (f"{hz['hazard_type']} HIGH — "
                                 f"{row['road_code']}")
                    res = await alerts_svc.upsert_deduped_alert(
                        session, dedup_key=key, level=level,
                        alert_type=atype, title=title,
                        message="; ".join(hz.get("evidence_lines") or []),
                        hazard=hz["hazard_type"],
                        fingerprint=fp,
                        district_code=row.get("district_code"),
                        segment_id=row["segment_id"],
                        payload={"probability": hz["probability"],
                                 "confidence": hz["confidence"],
                                 "status": hz["status"]})
                    created += 0 if res["deduped"] else 1
                    deduped += 1 if res["deduped"] else 0
            await session.commit()
        log.info("intel assessment done", extra={"data": {
            "assessed": len(assessments), "alerts_created": created,
            "alerts_refreshed": deduped}})
    except Exception as exc:  # noqa: BLE001 — job isolation (never kill runner)
        log.warning("intel assessment skipped: %s", str(exc)[:200])


async def integration_health() -> None:
    """Mirror in-process adapter health into data_sources (system connection)."""
    from app.core.db import SystemSession
    from app.data_health.service import sync_adapter_health

    async with SystemSession() as session:
        async with session.begin():
            n = await sync_adapter_health(session)
    logging.getLogger("ner-shield.workers").debug(
        "adapter health synced", extra={"data": {"rows": n}})


async def task_sla_escalation() -> None:
    """Escalate breached tasks; emits CRITICAL in-app notifications."""
    from app.core.db import SystemSession
    from app.tasks.service import escalate_overdue

    async with SystemSession() as session:
        async with session.begin():
            escalated = await escalate_overdue(session)
    if escalated:
        logging.getLogger("ner-shield.workers").info(
            "tasks escalated", extra={"data": {"count": len(escalated)}})


async def responder_escalation() -> None:
    """SIH26002 P3: reassign overdue unacknowledged response tasks."""
    from app.core.db import SystemSession
    from app.responders import service as responder_svc

    async with SystemSession() as session:
        async with session.begin():
            moved = await responder_svc.escalation_sweep(session)
    if moved:
        logging.getLogger("ner-shield.workers").info(
            "response tasks escalated", extra={"data": {"count": len(moved)}})


def build_runner(interval_s: int = 60) -> WorkerRunner:
    r = WorkerRunner()
    r.register("integration_health", interval_s, integration_health)
    r.register("weather_ingest", interval_s, weather_ingest)
    r.register("weather_imd_ingest", interval_s, weather_imd_ingest)
    r.register("disaster_ingest", interval_s, disaster_ingest)
    r.register("disaster_sachet_ingest", interval_s, disaster_sachet_ingest)
    # Copernicus catalogue + CWC hydrology change slowly; poll less often.
    slow = max(interval_s * 10, 600)
    r.register("satellite_copernicus_ingest", slow,
               satellite_copernicus_ingest)
    r.register("hydrology_ingest", max(interval_s * 5, 300), hydrology_ingest)
    r.register("intel_assessment", max(interval_s * 5, 300),
               intel_assessment)
    r.register("task_sla_escalation", max(60, interval_s),
               task_sla_escalation)
    r.register("responder_escalation", max(60, interval_s),
               responder_escalation)
    return r


async def main() -> int:
    logging.basicConfig(level="INFO",
                        format="%(asctime)s %(levelname)s %(name)s %(message)s")
    from integrations import config_loader
    config_loader.apply()      # feature flags; providers stay OFF unless env on
    runner = build_runner()
    await runner.start()
    try:
        while True:
            await asyncio.sleep(3600)
    except (KeyboardInterrupt, asyncio.CancelledError):
        pass
    finally:
        await runner.stop()
    return 0


if __name__ == "__main__":
    if sys.platform == "win32":
        asyncio.set_event_loop_policy(asyncio.WindowsSelectorEventLoopPolicy())
    raise SystemExit(asyncio.run(main()))
