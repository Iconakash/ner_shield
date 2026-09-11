"""In-process realtime event bus (master upgrade §11).

Design: publishers call await publish(kind, payload, scope); every connected,
authorized SSE subscriber receives only events their scope permits.
Single-process by design today; the publish()/subscribe() seam is exactly
where a Redis pub/sub backend slots in for multi-worker deployments WITHOUT
touching any publisher code.
"""
import asyncio
import json
import logging
from dataclasses import dataclass, field

logger = logging.getLogger("ner-shield.realtime")

# Event kinds and the permission each requires to even see them.
EVENT_PERMISSIONS = {
    "gps_update": "VIEW_GPS",
    "shipment_update": "VIEW_SHIPMENTS",
    "alert_new": "VIEW_INCIDENTS",
    "risk_change": "VIEW_MAP",
    "field_report": "VIEW_INCIDENTS",
    "task_update": "VIEW_MAP",
    "data_source_health": "VIEW_MAP",
}


@dataclass
class Event:
    kind: str
    payload: dict = field(default_factory=dict)


class EventBus:
    def __init__(self, buffer_per_subscriber: int = 100):
        self._subs: dict[int, asyncio.Queue] = {}
        self._next_id = 0
        self._buffer = buffer_per_subscriber
        self.published_count = 0          # observability counters (Phase 10)
        self.dropped_count = 0

    async def publish(self, kind: str, payload: dict) -> None:
        if kind not in EVENT_PERMISSIONS:
            logger.warning("unknown realtime event kind", extra={
                "data": {"kind": kind}})
            return
        self.published_count += 1
        dead = []
        for sid, q in self._subs.items():
            try:
                q.put_nowait(Event(kind, dict(payload)))
            except asyncio.QueueFull:
                # slow consumer: drop the OLDEST and retry once
                try:
                    q.get_nowait()
                    q.put_nowait(Event(kind, dict(payload)))
                    self.dropped_count += 1
                except Exception:  # noqa: BLE001
                    dead.append(sid)
            except Exception:  # noqa: BLE001 — never let one sub kill others
                dead.append(sid)
        for sid in dead:
            self._subs.pop(sid, None)

    def subscribe(self) -> int:
        self._next_id += 1
        self._subs[self._next_id] = asyncio.Queue(maxsize=self._buffer)
        return self._next_id

    def unsubscribe(self, sid: int) -> None:
        self._subs.pop(sid, None)

    @property
    def subscriber_count(self) -> int:
        return len(self._subs)

    async def stream(self, sid: int, has_permission) -> "asyncio.Queue":
        """Yield SSE-formatted bytes filtered by the caller's permissions."""
        q = self._subs[sid]
        yield b": stream connected\n\n"
        while True:
            ev = await q.get()
            required = EVENT_PERMISSIONS.get(ev.kind)
            if required and not has_permission(required):
                continue
            data = json.dumps({"kind": ev.kind, **ev.payload},
                              default=str, separators=(",", ":"))
            yield f"event: {ev.kind}\ndata: {data}\n\n".encode()


bus = EventBus()
