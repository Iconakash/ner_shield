"""Worker unit tests — runner lifecycle and job isolation (no infra)."""
import asyncio
import sys as _sys
from pathlib import Path

BACKEND = Path(__file__).resolve().parents[1]
if str(BACKEND) not in _sys.path:
    _sys.path.insert(0, str(BACKEND))

from workers import Job, WorkerRunner  # noqa: E402


async def test_runner_executes_jobs_and_survives_failures():
    ran = {"ok": 0, "bad": 0}

    async def ok_job():
        ran["ok"] += 1

    async def bad_job():
        ran["bad"] += 1
        raise RuntimeError("job exploded")

    r = WorkerRunner()
    r.jobs["ok"] = Job(name="ok", interval_s=0.01, fn=ok_job)
    r.jobs["bad"] = Job(name="bad", interval_s=0.01, fn=bad_job)
    await r.start()
    await asyncio.sleep(0.08)
    await r.stop()
    assert ran["ok"] > 0                 # healthy job runs repeatedly
    assert ran["bad"] > 1                # failing job retries, never kills runner


def test_worker_entrypoint_builds_expected_jobs():
    from workers.runner import build_runner

    r = build_runner(interval_s=60)
    # Provider-integration + decision-intelligence upgrades added per-provider
    # ingest jobs and the intel assessment cycle (all fail gracefully).
    assert set(r.jobs) == {"integration_health", "weather_ingest",
                           "weather_imd_ingest", "disaster_ingest",
                           "disaster_sachet_ingest",
                           "satellite_copernicus_ingest", "hydrology_ingest",
                           "intel_assessment", "task_sla_escalation",
                           "responder_escalation"}
    assert all(j.enabled for j in r.jobs.values())
    assert r.jobs["satellite_copernicus_ingest"].interval_s >= 600  # slow poll
    assert r.jobs["hydrology_ingest"].interval_s >= 300
    assert r.jobs["intel_assessment"].interval_s >= 300
