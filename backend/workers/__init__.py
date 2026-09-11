"""NER-SHIELD background workers (master upgrade §12).

Design: a single asyncio runner executes registered job coroutines on fixed
intervals. Redis-backed queues can replace/augment this later WITHOUT changing
job implementations (each job is just an async function). Expensive ML or
external-API work NEVER runs inside HTTP request handlers.
"""
import asyncio
import logging
from dataclasses import dataclass, field
from typing import Callable, Coroutine

logger = logging.getLogger("ner-shield.workers")


@dataclass
class Job:
    name: str
    interval_s: int
    fn: Callable[[], Coroutine]
    enabled: bool = True
    _task: asyncio.Task | None = field(default=None, repr=False)


class WorkerRunner:
    def __init__(self):
        self.jobs: dict[str, Job] = {}

    def register(self, name: str, interval_s: int, fn: Callable,
                 enabled: bool = True) -> None:
        self.jobs[name] = Job(name=name, interval_s=interval_s, fn=fn,
                              enabled=enabled)

    async def _loop(self, job: Job) -> None:
        logger.info("worker job started", extra={"data": {
            "job": job.name, "interval_s": job.interval_s}})
        while True:
            try:
                await job.fn()
            except asyncio.CancelledError:
                raise
            except Exception as exc:  # noqa: BLE001 — a failing job never kills the runner
                logger.exception("worker job failed", extra={"data": {"job": job.name}})
                logger.warning("job error: %s", str(exc)[:200])
            await asyncio.sleep(job.interval_s)

    async def start(self) -> None:
        for job in self.jobs.values():
            if job.enabled:
                job._task = asyncio.create_task(self._loop(job),
                                                name=f"worker:{job.name}")

    async def stop(self) -> None:
        for job in self.jobs.values():
            if job._task:
                job._task.cancel()
        for job in self.jobs.values():
            if job._task:
                try:
                    await job._task
                except asyncio.CancelledError:
                    pass
        logger.info("worker runner stopped")
