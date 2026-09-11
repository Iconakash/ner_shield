"""Shipment lifecycle + ETA engine (Phase 4; FR-C08..C10).

Status machine (frozen):
    DRAFT -> VEHICLE_ASSIGNED -> ROUTE_ASSIGNED -> IN_TRANSIT -> DELIVERED
         (any pre-terminal state) -> CANCELLED

Two-person mandate: a CRITICAL-priority shipment may only reach DELIVERED or
CANCELLED when an APPROVED CRITICAL_LOGISTICS_STATUS approval exists for it.

ETA engine: route+ping -> remaining distance along the assigned polyline via
ST_LineLocatePoint/ST_LineSubstring (geography => meters); fallback great-circle
x detour factor. Convoy speed constant until accessibility scoring lands (C02 hook).
"""
import json
from datetime import datetime, timedelta, timezone
from typing import Any, Optional

from sqlalchemy import text
from sqlalchemy.ext.asyncio import AsyncSession

AVG_SPEED_KPH = 35.0          # TODO(C02): replace w/ accessibility-adjusted speed
DETOUR_FACTOR = 1.3           # straight-line -> road detour allowance
RISK_DELAY_SENSITIVITY = 1.5  # expected-value slowdown multiplier per risk fraction
CRITICAL_COMMODITIES = {"MEDICINE", "EMERGENCY_SUPPLIES", "WATER", "EMERGENCY_FOOD"}


def segment_delay_minutes(km: float, speed_kph: float, risk_pct: float,
                          sensitivity: float = RISK_DELAY_SENSITIVITY) -> float:
    """Expected-value disruption delay for one segment (PURE — Phase 11).

    travel_hours x risk_fraction x sensitivity, expressed in minutes.
    """
    return (km / max(speed_kph, 1.0)) * (max(0.0, risk_pct) / 100.0) \
        * sensitivity * 60.0


def fmt_duration(minutes: float) -> str:
    m = int(round(minutes))
    return f"{m // 60}h{m % 60:02d}"


TRANSITIONS: dict[str, set[str]] = {
    "DRAFT": {"VEHICLE_ASSIGNED", "CANCELLED"},
    "VEHICLE_ASSIGNED": {"ROUTE_ASSIGNED", "IN_TRANSIT", "CANCELLED"},
    "ROUTE_ASSIGNED": {"IN_TRANSIT", "CANCELLED"},
    "IN_TRANSIT": {"DELIVERED", "CANCELLED"},
}
TERMINAL_STATUSES = {"DELIVERED", "CANCELLED"}


def is_critical_commodity(commodity: str) -> bool:
    return commodity in CRITICAL_COMMODITIES


def validate_transition(current: str, new_status: str) -> None:
    if new_status == current:
        return
    allowed = TRANSITIONS.get(current, set())
    if new_status not in allowed:
        from app.core.errors import Conflict
        raise Conflict(f"illegal status transition {current} -> {new_status}")


async def get_shipment(db: AsyncSession, shipment_id: str) -> Optional[dict]:
    row = (await db.execute(text("""
        select s.id::text as id, s.code, s.title,
               s.commodity::text as commodity, s.is_critical,
               s.priority::text as priority,
               s.origin_name, st_asgeojson(s.origin_geom) as origin_geo,
               s.origin_state, s.origin_district,
               s.dest_name, st_asgeojson(s.dest_geom) as dest_geo,
               s.dest_state, s.dest_district,
               v.code as vehicle_code, r.code as road_code,
               s.status::text as status, s.eta_at, s.eta_minutes,
               s.route_length_m, s.created_at, s.delivered_at
        from shipments s
        left join vehicles v on v.id = s.vehicle_id
        left join roads r on r.id = s.route_road_id
        where s.id = cast(:i as uuid)
    """), {"i": shipment_id})).mappings().first()
    return dict(row) if row else None


async def resolve_place(
    db: AsyncSession, facility_code: Optional[str],
    lon: Optional[float], lat: Optional[float],
) -> dict:
    """Origin/destination resolution: facility code wins; else raw coordinates are
    located via ST_Contains to attach governing state/district codes."""
    import json
    if facility_code:
        row = (await db.execute(text("""
            select f.name, f.state_code, f.district_code, st_asgeojson(f.geom) as geo
            from facilities f where f.code = :c
        """), {"c": facility_code})).mappings().first()
        if row is None:
            from app.core.errors import NotFound
            raise NotFound(f"facility '{facility_code}' not found")
        return {"name": row["name"], "state": row["state_code"],
                "district": row["district_code"], "geo": json.loads(row["geo"])}
    if lon is None or lat is None:
        from app.core.errors import AppError
        raise AppError("place needs either facility_code or lon+lat")
    located = await db.execute(text("""
        select d.code, d.state_code from districts d
        where d.geom is not null
          and st_contains(d.geom, st_setsrid(st_makepoint(:lon,:lat),4326))
        order by st_area(d.geom) asc limit 1
    """), {"lon": lon, "lat": lat})
    d = located.mappings().first()
    return {"name": f"{lon:.4f},{lat:.4f}",
            "state": d["state_code"] if d else None,
            "district": d["code"] if d else None,
            "geo": {"type": "Point", "coordinates": [lon, lat]}}


async def calculate_eta(db: AsyncSession, shipment: dict) -> dict:
    """PREDICTIVE ETA (Phase 11): normal + expected disruption = risk-adjusted.

    Route+ping path uses PostGIS for remaining distance; disruption delay is the
    expected-value slowdown across en-route segments weighted by their latest
    disruption predictions — ML stays separate from the graph (source mandate).
    """
    sid = shipment["id"]

    # 1) route-based remaining distance when we have a route AND at least one ping
    row = (await db.execute(text("""
        select round(st_length(
                 st_linesubstring(s.route_geom, f.frac, 1)::geography
               )::numeric / 1000, 2) as remain_km,
               round((s.route_length_m / 1000.0)::numeric, 2) as total_km
        from shipments s,
             lateral (select st_linelocatepoint(
                         s.route_geom,
                         (select gp.geom from gps_pings gp
                          where gp.shipment_id = s.id
                          order by recorded_at desc limit 1))::float8) as f(frac)
        where s.id = cast(:i as uuid)
          and s.route_geom is not null
          and f.frac is not null
    """), {"i": sid})).mappings().first()

    if row is not None:
        remaining_km = float(row["remain_km"] or 0)
        total_km = float(row["total_km"] or 0) if row["total_km"] else None
        method = "route_polyline_remaining"
    else:
        # 2) fallback: great-circle origin->destination x detour factor
        d = (await db.execute(text("""
            select st_distance(s.origin_geom::geography, s.dest_geom::geography) as m
            from shipments s where s.id = cast(:i as uuid)
        """), {"i": sid})).mappings().first()
        straight_km = float(d["m"]) / 1000.0 if d and d["m"] else 0.0
        remaining_km = round(straight_km * DETOUR_FACTOR, 2)
        total_km = remaining_km
        method = "great_circle_x_detour"

    normal_minutes = int(round(remaining_km / AVG_SPEED_KPH * 60)) \
        if remaining_km else 0

    # expected disruption delay across en-route segments (route-based only)
    delay_minutes = 0.0
    drivers: list[dict] = []
    if row is not None:
        seg_rows = (await db.execute(text("""
            select rs.id::text as segment_id, r.code as road_code,
                   d.name as district_name,
                   rs.length_m / 1000.0 as km,
                   coalesce(p.risk_24h,
                       case a.classification when 'SAFE' then 18
                            when 'CAUTION' then 45 when 'HIGH_RISK' then 72
                            else 90 end, 25) as risk_pct,
                   greatest(10.0, 15 + 30 * coalesce(a.score, 70) / 100.0)
                                                          as speed_kph
            from shipments sh
            join road_segments rs on rs.road_id = sh.route_road_id
            join roads r on r.id = rs.road_id
            left join districts d on d.code = rs.district_code
            left join lateral (
                select score, classification from accessibility_scores a
                where a.segment_id = rs.id order by computed_at desc limit 1
            ) a on true
            left join lateral (
                select risk_24h from disruption_predictions dp
                where dp.segment_id = rs.id order by computed_at desc limit 1
            ) p on true
            where sh.id = cast(:i as uuid)
        """), {"i": sid})).mappings().all()
        for r in seg_rows:
            dm = segment_delay_minutes(float(r["km"]),
                                       float(r["speed_kph"]),
                                       float(r["risk_pct"]))
            delay_minutes += dm
            drivers.append({"segment_id": r["segment_id"],
                            "road_code": r["road_code"],
                            "district_name": r["district_name"],
                            "risk_pct": round(float(r["risk_pct"]), 1),
                            "delay_minutes": round(dm, 1)})
    delay_minutes = int(round(delay_minutes))
    drivers.sort(key=lambda x: -x["delay_minutes"])

    adjusted = normal_minutes + delay_minutes
    eta_at = datetime.now(timezone.utc) + timedelta(minutes=adjusted)

    await db.execute(text("""
        update shipments set eta_minutes = :adj, eta_at = :eta,
               base_eta_minutes = :nm, expected_disruption_minutes = :dm,
               updated_at = now()
        where id = cast(:i as uuid)
    """), {"adj": adjusted, "eta": eta_at, "nm": normal_minutes,
           "dm": delay_minutes, "i": sid})

    return {"shipment_id": sid, "method": method,
            "remaining_km": remaining_km,
            **({"total_route_km": total_km} if total_km else {}),
            "normal_eta_minutes": normal_minutes,
            "normal_eta_display": fmt_duration(normal_minutes),
            "expected_disruption_minutes": delay_minutes,
            "expected_disruption_display": fmt_duration(delay_minutes),
            "eta_minutes": adjusted,
            "eta_display": fmt_duration(adjusted),
            "eta_at": eta_at.isoformat(),
            "assumed_speed_kph": AVG_SPEED_KPH,
            "drivers": drivers[:3]}


async def require_terminal_approval(
    system_db: AsyncSession, shipment_id: str, requester_note: str | None = None
) -> bool:
    """True when an APPROVED CRITICAL_LOGISTICS_STATUS approval exists for this
    shipment (two-person mandate for critical logistics status changes)."""
    row = (await system_db.execute(text("""
        select 1 from approval_requests
        where action_type = 'CRITICAL_LOGISTICS_STATUS'
          and status = 'APPROVED'
          and payload ->> 'shipment_id' = :sid
        limit 1
    """), {"sid": shipment_id})).scalar()
    return bool(row)


async def add_event(db: AsyncSession, shipment_id: str, event_type: str,
                    actor_id: Optional[str], detail: dict[str, Any]) -> None:
    await db.execute(text(
        "insert into shipment_events (shipment_id, event_type, actor_id, detail)"
        " values (cast(:s as uuid), :t, cast(:a as uuid), cast(:d as jsonb))"),
        {"s": shipment_id, "t": event_type, "a": actor_id,
         "d": json.dumps(detail or {}, default=str)})

