"""In-process metrics registry — Prometheus text exposition, no dependencies.

Counters + simple histograms (count/sum/max). Single-process scope: each
API worker exposes its own /metrics (standard Prometheus pattern); a Redis
backing layer can replace the dicts later without touching call sites.
NEVER attach tokens, coordinates of individuals, or message bodies as labels.
"""
import threading
import time

_lock = threading.Lock()
_counters: dict[str, float] = {}
_histos: dict[str, dict[str, float]] = {}
_start = time.monotonic()


def _key(name: str, labels: dict | None) -> str:
    if not labels:
        return name
    items = sorted(labels.items())
    return name + "{" + ",".join(f'{k}="{v}"' for k, v in items) + "}"


def inc(name: str, labels: dict | None = None, value: float = 1.0) -> None:
    with _lock:
        _counters[_key(name, labels)] = \
            _counters.get(_key(name, labels), 0.0) + value


def observe(name: str, value: float, labels: dict | None = None) -> None:
    """Record one latency/size observation (count/_sum/_max)."""
    base = _key(name, labels)
    with _lock:
        h = _histos.setdefault(base, {"count": 0.0, "sum": 0.0, "max": 0.0})
        h["count"] += 1
        h["sum"] += value
        h["max"] = max(h["max"], value)


def snapshot() -> dict:
    with _lock:
        return {"uptime_s": round(time.monotonic() - _start, 1),
                "counters": dict(_counters),
                "histograms": {k: dict(v) for k, v in _histos.items()}}


def render_prometheus() -> str:
    lines = ["# TYPE ner_shield_uptime_seconds gauge",
             f"ner_shield_uptime_seconds {snapshot()['uptime_s']}"]
    snap = snapshot()
    for key, val in sorted(snap["counters"].items()):
        lines.append(f"{_sanitize(key)} {val}")
    for key, h in sorted(snap["histograms"].items()):
        base = _sanitize(key)
        lines.append(f'{base}_count {h["count"]}')
        lines.append(f'{base}_sum {round(h["sum"], 6)}')
        lines.append(f'{base}_max {round(h["max"], 6)}')
    return "\n".join(lines) + "\n"


def _sanitize(metric: str) -> str:
    """Metric names/labels must satisfy the Prometheus character rules."""
    out = metric.replace("-", "_")
    out = out.replace('{', '_{').replace('}', '}')
    # inside labels quotes are fine; strip stray braces from names only
    name, _, labels = out.partition("{")
    name = "".join(c if (c.isalnum() or c == "_" or c == ":") else "_"
                   for c in name)
    return name + (("{" + labels) if labels else "")
