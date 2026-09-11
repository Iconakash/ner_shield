"""PHASE 12 load harness — asyncio concurrency probe against a RUNNING stack.

Usage (requires the API running, e.g. `docker compose up api` or uvicorn):
    RUN_LOAD=1 LOAD_BASE_URL=http://127.0.0.1:8000 pytest tests/test_load.py -q

Measures p50/p95/p99 latency + error rate per scenario and asserts only
correctness invariants; capacity thresholds are recorded in
docs/LOAD_TEST_RESULTS.md for the operator's hardware.
"""
import asyncio
import os
import statistics
import time

import httpx
import pytest

RUN_LOAD = os.environ.get("RUN_LOAD") == "1"
BASE = os.environ.get("LOAD_BASE_URL", "http://127.0.0.1:8000")

pytestmark = [
    pytest.mark.integration,
    pytest.mark.skipif(not RUN_LOAD, reason="RUN_LOAD != 1"),
]

CONCURRENCY = int(os.environ.get("LOAD_CONCURRENCY", "20"))
REQUESTS = int(os.environ.get("LOAD_REQUESTS", "200"))


async def _probe(client: httpx.AsyncClient, name: str, method: str,
                 path: str, token: str | None = None,
                 json_body: dict | None = None) -> tuple[str, float, int]:
    headers = {"Authorization": f"Bearer {token}"} if token else {}
    started = time.perf_counter()
    r = await client.request(method, BASE + path, json=json_body,
                             headers=headers)
    elapsed = time.perf_counter() - started
    return name, elapsed, r.status_code


def _summarize(samples: list[tuple[str, float, int]], name: str) -> dict:
    lat = sorted(s[1] for s in samples if s[0] == name)
    errors = sum(1 for s in samples if s[0] == name and s[2] >= 500)
    if not lat:
        return {"name": name, "n": 0}
    return {
        "name": name, "n": len(lat),
        "p50_ms": round(statistics.median(lat) * 1000, 1),
        "p95_ms": round(lat[int(len(lat) * 0.95)] * 1000, 1),
        "max_ms": round(max(lat) * 1000, 1),
        "errors": errors,
    }


SCENARIOS = [
    ("health", "GET", "/health", None, None),
    ("readiness", "GET", "/health/ready", None, None),
    ("metrics", "GET", "/metrics", None, None),
    ("auth_reject", "GET", "/api/v1/command/summary", None, None),
]


@pytest.mark.asyncio
async def test_load_baseline_scenarios():
    """Public + auth-rejection scenarios under concurrent load."""
    results: list[tuple[str, float, int]] = []
    async with httpx.AsyncClient(timeout=10) as client:
        async def worker():
            for _ in range(REQUESTS // CONCURRENCY):
                for name, method, path, tok, body in SCENARIOS:
                    results.append(await _probe(client, name, method, path,
                                                tok, body))
        await asyncio.gather(*(worker() for _ in range(CONCURRENCY)))

    summary = [_summarize(results, n) for n, *_ in SCENARIOS]
    for s in summary:
        print("LOAD", s)
        assert s["n"] > 0
        # correctness invariants: no server errors under load
        assert s["errors"] == 0, f"{s['name']} produced 5xx responses"
