"""Offline synchronization service (Phase 15 · C13/C14, architecture §11).

Push: batched client ops, each idempotent by client_op_id. Every op re-passes
the full security chain server-side (AX-1) and is applied through the SAME
validated services the online path uses — offline data is never trusted.
Pull: role+geo-scoped server changes for cache refresh (critical alerts,
scoped shipments, validated incidents in the officer's area).
"""
import json
from typing import Optional

from sqlalchemy import text
from sqlalchemy.ext.asyncio import AsyncSession

SUPPORTED_OP_TYPES = ("FIELD_REPORT", "GPS_PING")


async def is_duplicate(system_db: AsyncSession, client_op_id: str) -> Optional[dict]:
    row = (await system_db.execute(text(
        "select status, resource_id from sync_ops_log where client_op_id = :o"),
        {"o": client_op_id})).mappings().first()
    return dict(row) if row else None


async def log_op(system_db: AsyncSession, client_op_id: str, op_type: str,
                 status: str, resource_id: str | None = None,
                 device_code: str | None = None) -> None:
    await system_db.execute(text("""
        insert into sync_ops_log (client_op_id, device_code, op_type,
                                  status, resource_id)
        values (:o, :d, :t, :s, :r)
        on conflict (client_op_id) do nothing
    """), {"o": client_op_id, "d": device_code, "t": op_type,
           "s": status, "r": resource_id})


async def apply_field_report(db: AsyncSession, system_db: AsyncSession,
                             principal, payload: dict) -> dict:
    """Apply an offline FIELD_REPORT through the online submission path."""
    from app.field import service as field_svc
    return await field_svc.submit_report(
        db, principal=principal,
        incident_type=payload["incident_type"],
        severity=payload["severity"],
        lon=float(payload["lon"]), lat=float(payload["lat"]),
        description=payload.get("description", ""),
        photo_ref=(f"queued:{payload['photo_name']}"
                   if payload.get("photo_name") else None),
        client_op_id=payload["client_op_id"],
        gps_accuracy_m=payload.get("gps_accuracy_m"),
        observed_at_iso=payload.get("observed_at"))


async def apply_gps_ping(db: AsyncSession, shipment_id: str,
                         payload: dict) -> dict:
    """Insert ping + update vehicle + recalculate predictive ETA (RECALCULATE)."""
    from app.shipments import service as ship_svc
    ship = await ship_svc.get_shipment(db, shipment_id)
    if ship is None:
        from app.core.errors import NotFound
        raise NotFound("shipment not found or outside your scope")
    if ship["status"] not in ("IN_TRANSIT", "ROUTE_ASSIGNED", "VEHICLE_ASSIGNED"):
        from app.core.errors import Conflict
        raise Conflict(f"cannot track location in status {ship['status']}")

    await db.execute(text("""
        insert into gps_pings (shipment_id, vehicle_id, geom, speed_kph,
                               heading_deg, client_op_id)
        values (cast(:s as uuid),
                (select vehicle_id from shipments where id = cast(:s as uuid)),
                st_setsrid(st_makepoint(:lon,:lat),4326), :spd, :hdg, :op)
        on conflict (client_op_id) do nothing
    """), {"s": shipment_id, "lon": float(payload["lon"]),
           "lat": float(payload["lat"]), "spd": payload.get("speed_kph"),
           "hdg": payload.get("heading_deg"), "op": payload["client_op_id"]})
    await db.execute(text("""
        update vehicles set last_geom = st_setsrid(st_makepoint(:lon,:lat),4326),
                            last_seen_at = now()
        where id = (select vehicle_id from shipments where id = cast(:s as uuid))
    """), {"lon": payload["lon"], "lat": payload["lat"], "s": shipment_id})

    eta = await ship_svc.calculate_eta(db, {**ship, "id": shipment_id})
    await svc_add_event(db, shipment_id, "LOCATION_UPDATE",
                        detail={"via": "offline_sync",
                                "eta_minutes": eta["eta_minutes"]})
    return {"eta_minutes": eta["eta_minutes"],
            "expected_disruption_minutes": eta.get("expected_disruption_minutes")}


async def svc_add_event(db: AsyncSession, shipment_id: str, event_type: str,
                        detail: dict) -> None:
    await db.execute(text("""
        insert into shipment_events (shipment_id, event_type, detail)
        values (cast(:s as uuid), :t, cast(:d as jsonb))
    """), {"s": shipment_id, "t": event_type,
           "d": json.dumps(detail or {}, default=str)})


async def pull_changes(db: AsyncSession, principal, cursor: int) -> dict:
    """Server changes for cache refresh, scoped by role + geography (RLS)."""
    alerts = (await db.execute(text("""
        select a.id::text as id, a.level::text as level,
               a.alert_type::text as alert_type, a.title, a.message,
               a.status::text as status, a.state_code, a.district_code
        from alerts a
        where a.current_role::text = :role
          and a.status in ('ACTIVE', 'ESCALATED')
        order by a.created_at desc limit 100
    """), {"role": principal.role})).mappings().all()

    shipments = (await db.execute(text("""
        select s.id::text as id, s.code, s.title,
               s.commodity::text as commodity, s.priority::text as priority,
               s.status::text as status, s.eta_minutes, s.dest_district
        from shipments s
        where s.status in ('VEHICLE_ASSIGNED', 'ROUTE_ASSIGNED', 'IN_TRANSIT')
          and app_has_geo_scope(s.dest_state, s.dest_district)
          and app_has_permission('VIEW_SHIPMENTS')
        order by s.created_at desc limit 100
    """))).mappings().all()

    reports = (await db.execute(text("""
        select fr.id::text as id, fr.code,
               fr.incident_type::text as incident_type,
               fr.severity::text as severity, fr.district_code,
               st_asgeojson(fr.geom) as geo, fr.validated_at
        from field_reports fr
        where fr.status = 'VALIDATED'
          and app_has_geo_scope(fr.state_code, fr.district_code)
        order by fr.id desc limit 100
    """))).mappings().all()

    return {
        "alerts": [dict(r) for r in alerts],
        "shipments": [dict(r) for r in shipments],
        "validated_incidents": [
            {**dict(r), "geo": json.loads(r["geo"]) if r["geo"] else None}
            for r in reports],
        "pulled_at_cursor": cursor,
    }


# ------------------------------------------- connectivity-aware gating (Phase 16)
CONNECTIVITY_CLASSES = ("EXCELLENT", "GOOD", "WEAK", "VERY_WEAK", "OFFLINE")

DEFAULT_SYNC_POLICY = {
    "EXCELLENT": {"max_ops": 100, "allow_photos": True,
                  "allowed_types": ["FIELD_REPORT", "GPS_PING"],
                  "gps_beacon_s": 30},
    "GOOD": {"max_ops": 50, "allow_photos": True,
             "allowed_types": ["FIELD_REPORT", "GPS_PING"], "gps_beacon_s": 60},
    "WEAK": {"max_ops": 20, "allow_photos": False,
             "allowed_types": ["FIELD_REPORT", "GPS_PING"], "gps_beacon_s": 180},
    "VERY_WEAK": {"max_ops": 5, "allow_photos": False,
                  "allowed_types": ["GPS_PING", "CRITICAL_FIELD_REPORT"],
                  "gps_beacon_s": 600},
    "OFFLINE": {"max_ops": 0, "allow_photos": False, "allowed_types": [],
                "gps_beacon_s": None},
}


async def get_active_sync_policy(db: AsyncSession) -> dict:
    row = (await db.execute(text("""
        select policy from sync_policies
        where is_active order by version desc limit 1
    """))).mappings().first()
    # asyncpg auto-decodes jsonb into a Python dict on read; some DB
    # clients return raw JSON strings. Accept either shape so the endpoint
    # is robust without changing semantics.
    if not row:
        return DEFAULT_SYNC_POLICY
    policy = row["policy"]
    if isinstance(policy, (dict, list)):
        return policy
    return json.loads(policy)


def gate_op(op: dict, connectivity_class: str,
            policy: dict | None = None) -> tuple[str, str | None]:
    """PURE gate: returns (verdict, reason).

    verdict ∈ {'ALLOWED', 'DEFERRED', 'REJECTED'}.
    DEFERRED = hold on device until a better link; REJECTED = never valid.
    """
    pol = (policy or DEFAULT_SYNC_POLICY).get(connectivity_class)
    if pol is None:
        return "REJECTED", f"unknown connectivity class {connectivity_class!r}"
    if pol["max_ops"] == 0 or not pol["allowed_types"]:
        return "DEFERRED", "offline: op held locally"

    op_type = op.get("op_type")
    if op_type not in pol["allowed_types"]:
        return "DEFERRED", (f"{op_type} deferred at {connectivity_class}: "
                            f"allowed here = {pol['allowed_types']}")

    payload = op.get("payload") or {}
    has_photo = bool(payload.get("photo_name"))
    sev = str(payload.get("severity", "")).upper()

    if has_photo and not pol["allow_photos"]:
        # photos wait for a better link unless the report itself is CRITICAL
        if sev != "CRITICAL":
            return "DEFERRED", "photo deferred until better connectivity"

    if (connectivity_class == "VERY_WEAK"
            and op_type == "CRITICAL_FIELD_REPORT"
            and sev not in ("HIGH", "CRITICAL")):
        return "DEFERRED", "very-weak link carries HIGH/CRITICAL reports only"

    return "ALLOWED", None


def classify_connectivity(effective_type: str | None, online: bool) -> str:
    """Client-side classifier contract: Network Information API + reachability.

      offline -> OFFLINE · slow-2g -> VERY_WEAK · 2g -> WEAK ·
      3g -> GOOD · 4g+ -> EXCELLENT
    """
    if not online:
        return "OFFLINE"
    return {"slow-2g": "VERY_WEAK", "2g": "WEAK",
            "3g": "GOOD", "4g": "EXCELLENT"}.get(effective_type or "", "GOOD")


async def set_device_connectivity(system_db: AsyncSession, device_code: str,
                                  connectivity_class: str) -> None:
    await system_db.execute(text("""
        update sync_state set connectivity_class = :c, class_updated_at = now()
        where device_id in (select id from sync_devices where device_code = :d)
    """), {"c": connectivity_class, "d": device_code})

