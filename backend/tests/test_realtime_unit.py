"""PHASE 9 unit tests — realtime bus: publish/subscribe, permission filtering,
slow-consumer handling, endpoint gating."""
import sys as _sys
from pathlib import Path

BACKEND = Path(__file__).resolve().parents[1]
if str(BACKEND) not in _sys.path:
    _sys.path.insert(0, str(BACKEND))

from app.realtime.bus import EVENT_PERMISSIONS, EventBus  # noqa: E402


def test_event_kinds_have_permission_contracts():
    for kind in ("gps_update", "shipment_update", "alert_new", "risk_change",
                 "field_report", "task_update", "data_source_health"):
        assert kind in EVENT_PERMISSIONS


async def test_subscriber_receives_published_events():
    bus = EventBus()
    sid = bus.subscribe()
    await bus.publish("risk_change", {"segment": "s1", "label": "HIGH"})
    ev = bus._subs[sid].get_nowait()
    assert ev.kind == "risk_change" and ev.payload["segment"] == "s1"


async def test_stream_filters_events_without_permission():
    import asyncio

    bus = EventBus()
    sid = bus.subscribe()
    await bus.publish("gps_update", {"lat": 26.1})
    await bus.publish("task_update", {"id": "t1"})
    agen = bus.stream(sid, lambda perm: False).__aiter__()   # zero permissions
    first = await asyncio.wait_for(agen.__anext__(), 1)
    assert b"stream connected" in first
    try:
        # every queued event requires permissions this subscriber lacks ->
        # nothing may be yielded before the timeout fires
        nxt = await asyncio.wait_for(agen.__anext__(), 0.25)
        raise AssertionError(f"unauthorized event leaked: {nxt!r}")
    except asyncio.TimeoutError:
        pass


async def test_stream_yields_permitted_events():
    import asyncio

    bus = EventBus()
    sid = bus.subscribe()
    await bus.publish("risk_change", {"segment": "s1"})
    agen = bus.stream(sid, lambda perm: True).__aiter__()
    await asyncio.wait_for(agen.__anext__(), 1)              # marker
    chunk = await asyncio.wait_for(agen.__anext__(), 1)
    assert b"event: risk_change" in chunk and b'"segment"' in chunk


async def test_unsubscribe_stops_delivery():
    bus = EventBus()
    sid = bus.subscribe()
    bus.unsubscribe(sid)
    assert bus.subscriber_count == 0
    await bus.publish("risk_change", {})          # no subscribers, no error


async def test_unknown_kind_is_rejected_not_broadcast():
    bus = EventBus()
    sid = bus.subscribe()
    await bus.publish("mystery_kind", {"x": 1})
    assert bus._subs[sid].empty()


# ------------------------------------------------------------------ API wiring
def test_realtime_endpoints_registered_and_gated():
    from fastapi.testclient import TestClient

    from app.main import create_app

    app = create_app()
    paths = app.openapi()["paths"]
    assert "/api/v1/realtime/stream" in paths
    assert "/api/v1/realtime/status" in paths
    client = TestClient(app, raise_server_exceptions=False)
    r = client.get("/api/v1/realtime/stream")
    assert r.status_code == 401                   # bearer gate applies to SSE
