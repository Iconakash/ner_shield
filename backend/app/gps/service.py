"""GPS device service: registration, credential rotation, device authentication,
replay/duplicate-protected ingest. Security-critical paths use the SYSTEM
connection (device principals have no user JWT / RLS identity)."""
import hashlib
import hmac
import secrets
import time
from collections import defaultdict, deque

from sqlalchemy import text
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.errors import NotFound, RateLimited, Unauthenticated
from app.gps.schemas import DeviceRegistrationIn, TelemetryIn, payload_hash

# Per-device ingest rate limit (in-memory; per-process — perimeter limits apply too).
_DEVICE_RATE = 120
_hits: dict[str, deque] = defaultdict(deque)


def _hash_secret(raw: str) -> str:
    return hashlib.sha256(f"ns-gps:{raw}".encode()).hexdigest()


def _secret_matches(raw: str, stored_hash: str) -> bool:
    return hmac.compare_digest(_hash_secret(raw), stored_hash)


async def register_device(system_db: AsyncSession, principal,
                          body: DeviceRegistrationIn) -> dict:
    """Create a device + first credential. Raw secret is returned ONCE."""
    raw_secret = secrets.token_urlsafe(32)
    row = (await system_db.execute(text("""
        insert into gps_devices (label, provider, model, registered_by)
        values (:l, :p, :m, cast(:u as uuid))
        returning id::text as id, device_code
    """), {"l": body.label, "p": body.provider, "m": body.model,
           "u": principal.user_id})).mappings().first()
    await system_db.execute(text("""
        insert into device_credentials (device_id, secret_hash, issued_by)
        values (cast(:d as uuid), :h, cast(:u as uuid))
    """), {"d": row["id"], "h": _hash_secret(raw_secret), "u": principal.user_id})
    return {"device_id": row["id"], "device_code": row["device_code"],
            "secret": raw_secret,
            "note": "store this secret now; it is not retrievable"}


async def rotate_credential(system_db: AsyncSession, principal,
                            device_code: str) -> dict:
    """Revoke current credential, issue v(n+1). Old secret stops working at once."""
    dev = await get_device(system_db, device_code)
    row = (await system_db.execute(text("""
        select coalesce(max(key_version), 0) + 1 as nextv
        from device_credentials where device_id = cast(:d as uuid)
    """), {"d": dev["id"]})).mappings().first()
    raw_secret = secrets.token_urlsafe(32)
    await system_db.execute(text("""
        update device_credentials set revoked_at = now()
        where device_id = cast(:d as uuid) and revoked_at is null
    """), {"d": dev["id"]})
    await system_db.execute(text("""
        insert into device_credentials (device_id, secret_hash, key_version, issued_by)
        values (cast(:d as uuid), :h, :v, cast(:u as uuid))
    """), {"d": dev["id"], "h": _hash_secret(raw_secret),
           "v": row["nextv"], "u": principal.user_id})
    return {"device_code": device_code, "key_version": row["nextv"],
            "secret": raw_secret}


async def get_device(system_db: AsyncSession, device_code: str) -> dict:
    row = (await system_db.execute(text(
        "select id::text as id, device_code, status::text as status"
        " from gps_devices where device_code = :c"), {"c": device_code}
    )).mappings().first()
    if row is None:
        raise NotFound("device not found")
    return dict(row)


async def authenticate_device(system_db: AsyncSession, code: str | None,
                              secret: str | None) -> dict:
    """Constant-time credential check against the newest non-revoked secret."""
    if not code or not secret:
        raise Unauthenticated("device credentials required")
    row = (await system_db.execute(text("""
        select d.id::text as id, d.device_code, d.status::text as status,
               c.secret_hash
        from gps_devices d
        join device_credentials c on c.device_id = d.id and c.revoked_at is null
        where d.device_code = :c
        order by c.key_version desc limit 1
    """), {"c": code})).mappings().first()
    if row is None or not _secret_matches(secret, row["secret_hash"]):
        # uniform failure: never reveal whether the code exists
        raise Unauthenticated("invalid device credentials")
    if row["status"] != "ACTIVE":
        raise Unauthenticated("device is not active")
    return {"id": row["id"], "device_code": row["device_code"]}


def _rate_allow(device_code: str) -> bool:
    now = time.monotonic()
    w = _hits[device_code]
    while w and now - w[0] > 60:
        w.popleft()
    if len(w) >= _DEVICE_RATE:
        return False
    w.append(now)
    return True


async def ingest(system_db: AsyncSession, device: dict, t: TelemetryIn) -> dict:
    """Validate → dedup/replay-check → record evidence → update device state.

    Returns {'verdict': ACCEPTED|DUPLICATE|REJECTED, 'reason': ...}.
    Rejections are RECORDED (tampering evidence) but never move shipment state.
    """
    if not _rate_allow(device["device_code"]):
        raise RateLimited("device ingest rate limit exceeded")

    ph = payload_hash(device["device_code"], t)

    async def record(verdict: str, reason: str | None):
        await system_db.execute(text("""
            insert into gps_device_events (device_id, payload_hash, observed_at,
                                           verdict, reject_reason)
            values (cast(:d as uuid), :h, :ts, :v, :r)
            on conflict do nothing
        """), {"d": device["id"], "h": ph, "ts": t.timestamp,
               "v": verdict, "r": reason})

    # 1) content-level replay/duplicate detection (storage-backed, unique index)
    dup = (await system_db.execute(text(
        "select 1 from gps_device_events where device_id = cast(:d as uuid)"
        " and payload_hash = :h and verdict <> 'REJECTED' limit 1"),
        {"d": device["id"], "h": ph})).scalar()
    if dup:
        await record("DUPLICATE", "identical payload already accepted")
        return {"verdict": "DUPLICATE", "reason": "duplicate telemetry"}

    # 2) timestamp freshness (anti-replay window) + 3) geographic plausibility
    from app.gps.schemas import validate_coordinates, validate_timestamp

    for validator in (validate_timestamp,):
        if reason := validator(t.timestamp):
            await record("REJECTED", reason)
            return {"verdict": "REJECTED", "reason": reason}
    if reason := validate_coordinates(t.latitude, t.longitude):
        await record("REJECTED", reason)
        return {"verdict": "REJECTED", "reason": reason}

    # 4) commit evidence + live position when a shipment is bound
    await record("ACCEPTED", None)
    ship_row = (await system_db.execute(text(
        "select shipment_id::text as sid from gps_devices"
        " where id = cast(:d as uuid)"), {"d": device["id"]})).mappings().first()
    shipment_id = ship_row["sid"] if ship_row else None
    if shipment_id:
        await system_db.execute(text("""
            insert into gps_pings (shipment_id, vehicle_id, geom, speed_kph,
                                   heading_deg)
            values (cast(:s as uuid),
                    (select vehicle_id from shipments where id = cast(:s as uuid)),
                    st_setsrid(st_makepoint(:lon,:lat),4326), :spd, :hdg)
        """), {"s": shipment_id, "lon": t.longitude, "lat": t.latitude,
               "spd": t.speed_kph, "hdg": t.heading_deg})
    await system_db.execute(text("""
        update gps_devices set last_seen_at = now(), battery_pct = :b,
               signal_class = :sig
        where id = cast(:d as uuid)
    """), {"d": device["id"], "b": t.battery_pct, "sig": t.signal_class})
    try:
        from app.core import metrics
        metrics.inc("ner_shield_gps_ingest_total",
                    {"verdict": "ACCEPTED"})
    except Exception:  # noqa: BLE001
        pass
    try:
        from app.realtime.bus import bus
        await bus.publish("gps_update", {
            "device_code": device["device_code"],
            "shipment_tracked": bool(shipment_id),
            "lat": t.latitude, "lon": t.longitude,
            "observed_at": t.timestamp.isoformat()})
    except Exception:  # noqa: BLE001 — realtime must never break ingestion
        pass
    return {"verdict": "ACCEPTED", "shipment_tracked": bool(shipment_id)}
