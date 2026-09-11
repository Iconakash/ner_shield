"""Logistics API — the seven mandated operations (Phase 4).

  CREATE SHIPMENT      POST   /shipments
  ASSIGN VEHICLE       POST   /shipments/{id}/assign-vehicle
  ASSIGN ROUTE         POST   /shipments/{id}/assign-route
  UPDATE LOCATION      POST   /shipments/{id}/location
  UPDATE STATUS        POST   /shipments/{id}/status
  CALCULATE ETA        GET    /shipments/{id}/eta
  DELIVERY CONFIRMATION POST  /shipments/{id}/confirm-delivery

Security chain per C-Authz: authentication -> account status -> permission ->
geographic scope (origin AND destination for creation; destination for ops).
"""
import json
from typing import Literal, Optional

from fastapi import APIRouter, Depends, Request
from pydantic import BaseModel, Field
from sqlalchemy import text
from sqlalchemy.ext.asyncio import AsyncSession

from app.audit import service as audit
from app.core.db import get_db, get_system_db
from app.core.errors import Conflict, NotFound
from app.core.security import Principal
from app.dependencies import ensure_geo_scope, get_principal, require_permissions
from app.shipments import service as svc

router = APIRouter(prefix="/shipments", tags=["shipments"])


class PlaceIn(BaseModel):
    facility_code: Optional[str] = None
    lon: Optional[float] = None
    lat: Optional[float] = None


class ShipmentCreate(BaseModel):
    title: str = Field(min_length=3, max_length=160)
    commodity: Literal["MEDICINE", "EMERGENCY_SUPPLIES", "WATER", "EMERGENCY_FOOD",
                       "FOOD_GRAIN", "FUEL", "GENERAL"]
    priority: Literal["CRITICAL", "HIGH", "MEDIUM", "NORMAL"]
    origin: PlaceIn
    destination: PlaceIn


class VehicleAssign(BaseModel):
    vehicle_code: str


class RouteAssign(BaseModel):
    road_code: str


class LocationUpdate(BaseModel):
    lon: float = Field(ge=80.0, le=98.0)     # NER bounding box (DAT-05)
    lat: float = Field(ge=21.0, le=29.5)
    speed_kph: Optional[float] = Field(default=None, ge=0, le=150)
    heading_deg: Optional[float] = Field(default=None, ge=0, le=360)


class StatusUpdate(BaseModel):
    new_status: Literal["VEHICLE_ASSIGNED", "ROUTE_ASSIGNED", "IN_TRANSIT",
                        "DELIVERED", "CANCELLED"]
    note: str | None = None


def _ip(request: Request):
    return request.client.host if request.client else None


async def _load_or_404(db: AsyncSession, shipment_id: str) -> dict:
    s = await svc.get_shipment(db, shipment_id)
    if s is None:
        raise NotFound("shipment not found or outside your geographic scope")
    return s


@router.get("", dependencies=[Depends(require_permissions("VIEW_SHIPMENTS"))])
async def list_shipments(principal: Principal = Depends(get_principal),
                         db: AsyncSession = Depends(get_db)):
    rows = (await db.execute(text("""
        select s.id::text as id, s.code, s.title, s.commodity::text as commodity,
               s.priority::text as priority, s.status::text as status,
               s.origin_name, s.dest_name, v.code as vehicle_code,
               s.dest_state, s.dest_district, s.eta_at
        from shipments s left join vehicles v on v.id = s.vehicle_id
        order by case s.priority::text when 'CRITICAL' then 0 when 'HIGH' then 1
                 when 'MEDIUM' then 2 else 3 end, s.created_at desc
        limit 200
    """))).mappings().all()
    return [dict(r) for r in rows]          # RLS already scope-filtered

@router.get("/{shipment_id}",
            dependencies=[Depends(require_permissions("VIEW_SHIPMENTS"))])
async def get_shipment(shipment_id: str, principal: Principal = Depends(get_principal),
                       db: AsyncSession = Depends(get_db)):
    s = await _load_or_404(db, shipment_id)
    await ensure_geo_scope(principal, s["dest_state"], s["dest_district"], db)
    for k in ("origin_geo", "dest_geo"):
        s[k] = json.loads(s[k]) if isinstance(s[k], str) else s[k]
    return s


@router.post("", status_code=201,
             dependencies=[Depends(require_permissions("CREATE_SHIPMENT"))])
async def create_shipment(body: ShipmentCreate, request: Request,
                          principal: Principal = Depends(get_principal),
                          db: AsyncSession = Depends(get_db)):
    """CREATE SHIPMENT. Origin AND destination must both be inside caller scope."""
    origin = await svc.resolve_place(db, body.origin.facility_code,
                                     body.origin.lon, body.origin.lat)
    dest = await svc.resolve_place(db, body.destination.facility_code,
                                   body.destination.lon, body.destination.lat)
    await ensure_geo_scope(principal, origin["state"], origin["district"], db, request)
    await ensure_geo_scope(principal, dest["state"], dest["district"], db, request)

    is_critical = svc.is_critical_commodity(body.commodity) or body.priority == "CRITICAL"
    code = f"SHP-{principal.user_id[:4].upper()}-{int(__import__('time').time())}"

    row = (await db.execute(text("""
        insert into shipments (code, title, commodity, is_critical, priority,
            origin_name, origin_geom, origin_state, origin_district,
            dest_name, dest_geom, dest_state, dest_district,
            org_id, requested_by)
        values (:code, :title, cast(:com as commodity_type), :crit,
                cast(:pri as shipment_priority),
                :oname, st_setsrid(st_makepoint(:olon,:olat),4326), :ost, :odist,
                :dname, st_setsrid(st_makepoint(:dlon,:dlat),4326), :dst, :ddist,
                cast(:org as uuid), cast(:u as uuid))
        returning id::text
    """), {"code": code, "title": body.title, "com": body.commodity,
           "crit": is_critical, "pri": body.priority,
           "oname": origin["name"], "olon": origin["geo"]["coordinates"][0],
           "olat": origin["geo"]["coordinates"][1], "ost": origin["state"],
           "odist": origin["district"],
           "dname": dest["name"], "dlon": dest["geo"]["coordinates"][0],
           "dlat": dest["geo"]["coordinates"][1], "dst": dest["state"],
           "ddist": dest["district"],
           "org": principal.org_id, "u": principal.user_id}
    )).mappings().first()
    sid = row["id"]
    await svc.add_event(db, sid, "CREATED", principal.user_id,
                        {"commodity": body.commodity, "priority": body.priority})
    await audit.emit(db, actor_id=principal.user_id, actor_role=principal.role,
                     action="SHIPMENT_CREATED", outcome="SUCCESS",
                     resource_type="shipment", resource_id=sid,
                     detail={"code": code, "critical": is_critical}, ip=_ip(request))
    return {"id": sid, "code": code, "status": "DRAFT", "is_critical": is_critical}


@router.post("/{shipment_id}/assign-vehicle")
async def assign_vehicle(shipment_id: str, body: VehicleAssign, request: Request,
                         principal: Principal = Depends(
                             require_permissions("MODIFY_SHIPMENT")),
                         db: AsyncSession = Depends(get_db)):
    """ASSIGN VEHICLE — vehicle must exist and be AVAILABLE."""
    s = await _load_or_404(db, shipment_id)
    await ensure_geo_scope(principal, s["dest_state"], s["dest_district"], db, request)
    if s["status"] not in ("DRAFT", "VEHICLE_ASSIGNED"):
        raise Conflict(f"cannot assign vehicle in status {s['status']}")
    veh = (await db.execute(text(
        "select id::text as id, status::text as status from vehicles where code = :c"),
        {"c": body.vehicle_code})).mappings().first()
    if veh is None:
        raise NotFound("vehicle not found")
    if veh["status"] not in ("AVAILABLE",):
        raise Conflict(f"vehicle {body.vehicle_code} is {veh['status']}, not AVAILABLE")

    await db.execute(text(
        "update shipments set vehicle_id = cast(:v as uuid),"
        " status = 'VEHICLE_ASSIGNED', updated_at = now()"
        " where id = cast(:i as uuid)"), {"v": veh["id"], "i": shipment_id})
    await db.execute(text(
        "update vehicles set status = 'ASSIGNED' where id = cast(:v as uuid)"),
        {"v": veh["id"]})
    await svc.add_event(db, shipment_id, "VEHICLE_ASSIGNED", principal.user_id,
                        {"vehicle": body.vehicle_code})
    await audit.emit(db, actor_id=principal.user_id, actor_role=principal.role,
                     action="VEHICLE_ASSIGNED", outcome="SUCCESS",
                     resource_type="shipment", resource_id=shipment_id,
                     detail={"vehicle": body.vehicle_code}, ip=_ip(request))
    return {"id": shipment_id, "vehicle": body.vehicle_code, "status": "VEHICLE_ASSIGNED"}

@router.post("/{shipment_id}/assign-route")
async def assign_route(shipment_id: str, body: RouteAssign, request: Request,
                       principal: Principal = Depends(
                           require_permissions("MODIFY_SHIPMENT")),
                       db: AsyncSession = Depends(get_db)):
    """ASSIGN ROUTE — copies the road geometry and measures it (ST_Length geography)."""
    s = await _load_or_404(db, shipment_id)
    await ensure_geo_scope(principal, s["dest_state"], s["dest_district"], db, request)
    if s["status"] not in ("DRAFT", "VEHICLE_ASSIGNED", "ROUTE_ASSIGNED"):
        raise Conflict(f"cannot assign route in status {s['status']}")
    road = (await db.execute(text(
        "select id::text as id from roads where code = :c"), {"c": body.road_code}
    )).mappings().first()
    if road is None:
        raise NotFound("road not found")

    row = (await db.execute(text("""
        update shipments set
          route_road_id = cast(:r as uuid),
          route_geom = (select geom from roads where id = cast(:r as uuid)),
          route_length_m = st_length((select geom from roads
                                      where id = cast(:r as uuid))::geography),
          status = case when status = 'DRAFT' then 'ROUTE_ASSIGNED'
                        else status end::shipment_status,
          updated_at = now()
        where id = cast(:i as uuid)
        returning route_length_m
    """), {"r": road["id"], "i": shipment_id})).mappings().first()

    await svc.add_event(db, shipment_id, "ROUTE_ASSIGNED", principal.user_id,
                        {"road": body.road_code,
                         "length_km": round(float(row["route_length_m"]) / 1000, 2)})
    await audit.emit(db, actor_id=principal.user_id, actor_role=principal.role,
                     action="ROUTE_ASSIGNED", outcome="SUCCESS",
                     resource_type="shipment", resource_id=shipment_id,
                     detail={"road": body.road_code}, ip=_ip(request))
    return {"id": shipment_id, "road": body.road_code,
            "length_km": round(float(row["route_length_m"]) / 1000, 2)}


@router.post("/{shipment_id}/location")
async def update_location(shipment_id: str, body: LocationUpdate, request: Request,
                          principal: Principal = Depends(
                              require_permissions("MODIFY_SHIPMENT")),
                          db: AsyncSession = Depends(get_db)):
    """UPDATE LOCATION — GPS ping ingest; recomputes ETA when a route is assigned."""
    s = await _load_or_404(db, shipment_id)
    await ensure_geo_scope(principal, s["dest_state"], s["dest_district"], db, request)
    if s["status"] not in ("IN_TRANSIT", "ROUTE_ASSIGNED", "VEHICLE_ASSIGNED"):
        raise Conflict(f"cannot track location in status {s['status']}")

    if s["status"] == "VEHICLE_ASSIGNED":
        await db.execute(text(
            "update shipments set status = 'IN_TRANSIT', updated_at = now()"
            " where id = cast(:i as uuid)"), {"i": shipment_id})
        s["status"] = "IN_TRANSIT"

    await db.execute(text("""
        insert into gps_pings (shipment_id, vehicle_id, geom, speed_kph, heading_deg)
        values (cast(:s as uuid), (select vehicle_id from shipments
                                   where id = cast(:s as uuid)),
                st_setsrid(st_makepoint(:lon,:lat),4326), :spd, :hdg)
    """), {"s": shipment_id, "lon": body.lon, "lat": body.lat,
           "spd": body.speed_kph, "hdg": body.heading_deg})
    await db.execute(text("""
        update vehicles set last_geom = st_setsrid(st_makepoint(:lon,:lat),4326),
                            last_seen_at = now()
        where id = (select vehicle_id from shipments where id = cast(:s as uuid))
    """), {"lon": body.lon, "lat": body.lat, "s": shipment_id})
    await svc.add_event(db, shipment_id, "LOCATION_UPDATE", principal.user_id,
                        {"lon": body.lon, "lat": body.lat})

    eta = None
    if s["route_geom"]:
        eta = await svc.calculate_eta(db, {**s, "id": shipment_id})
        await svc.add_event(db, shipment_id, "ETA_CALCULATED", principal.user_id, eta)

    await audit.emit(db, actor_id=principal.user_id, actor_role=principal.role,
                     action="LOCATION_UPDATED", outcome="SUCCESS",
                     resource_type="shipment", resource_id=shipment_id,
                     ip=_ip(request))
    return {"id": shipment_id, "status": s["status"], **({"eta": eta} if eta else {})}

@router.post("/{shipment_id}/status")
async def update_status(shipment_id: str, body: StatusUpdate, request: Request,
                        principal: Principal = Depends(
                            require_permissions("MODIFY_SHIPMENT")),
                        db: AsyncSession = Depends(get_db),
                        system_db: AsyncSession = Depends(get_system_db)):
    """UPDATE STATUS — frozen state machine; CRITICAL shipments need an APPROVED
    CRITICAL_LOGISTICS_STATUS approval before DELIVERED/CANCELLED (two-person rule)."""
    s = await _load_or_404(db, shipment_id)
    await ensure_geo_scope(principal, s["dest_state"], s["dest_district"], db, request)
    svc.validate_transition(s["status"], body.new_status)

    if s["is_critical"] and body.new_status in svc.TERMINAL_STATUSES:
        approved = await svc.require_terminal_approval(system_db, shipment_id)
        if not approved:
            raise Conflict(
                "CRITICAL shipment terminal status requires an APPROVED "
                "CRITICAL_LOGISTICS_STATUS approval (two-person workflow)")

    if body.new_status == "DELIVERED":
        return await _confirm_delivery(db, system_db, shipment_id, principal,
                                       request, note=body.note)

    await db.execute(text(
        "update shipments set status = cast(:st as shipment_status), updated_at = now()"
        " where id = cast(:i as uuid)"), {"st": body.new_status, "i": shipment_id})
    if body.new_status == "CANCELLED" and s["vehicle_code"]:
        await db.execute(text(
            "update vehicles set status = 'AVAILABLE'"
            " where id = (select vehicle_id from shipments where id = cast(:i as uuid))"),
            {"i": shipment_id})

    await svc.add_event(db, shipment_id, "STATUS_CHANGE", principal.user_id,
                        {"from": s["status"], "to": body.new_status,
                         "note": body.note})
    await audit.emit(db, actor_id=principal.user_id, actor_role=principal.role,
                     action="STATUS_CHANGED", outcome="SUCCESS",
                     resource_type="shipment", resource_id=shipment_id,
                     detail={"from": s["status"], "to": body.new_status},
                     ip=_ip(request))
    return {"id": shipment_id, "status": body.new_status}


@router.get("/{shipment_id}/eta",
            dependencies=[Depends(require_permissions("VIEW_SHIPMENTS"))])
async def get_eta(shipment_id: str, principal: Principal = Depends(get_principal),
                  db: AsyncSession = Depends(get_db)):
    """CALCULATE ETA — on-demand recalculation."""
    s = await _load_or_404(db, shipment_id)
    await ensure_geo_scope(principal, s["dest_state"], s["dest_district"], db)
    eta = await svc.calculate_eta(db, {**s, "id": shipment_id})
    await audit.emit(db, actor_id=principal.user_id, actor_role=principal.role,
                     action="ETA_CALCULATED", outcome="SUCCESS",
                     resource_type="shipment", resource_id=shipment_id, ip=None)
    return eta


@router.post("/{shipment_id}/confirm-delivery")
async def confirm_delivery(shipment_id: str, request: Request,
                           principal: Principal = Depends(
                               require_permissions("MODIFY_SHIPMENT")),
                           db: AsyncSession = Depends(get_db),
                           system_db: AsyncSession = Depends(get_system_db)):
    """DELIVERY CONFIRMATION — records who/when; approval-gated for CRITICAL."""
    s = await _load_or_404(db, shipment_id)
    await ensure_geo_scope(principal, s["dest_state"], s["dest_district"], db, request)
    if s["is_critical"]:
        approved = await svc.require_terminal_approval(system_db, shipment_id)
        if not approved:
            raise Conflict(
                "CRITICAL shipment delivery requires an APPROVED "
                "CRITICAL_LOGISTICS_STATUS approval (two-person workflow)")
    return await _confirm_delivery(db, system_db, shipment_id, principal, request)


async def _confirm_delivery(db: AsyncSession, system_db: AsyncSession,
                            shipment_id: str, principal: Principal,
                            request: Request, note: str | None = None):
    row = (await db.execute(text("""
        update shipments set status = 'DELIVERED', delivered_at = now(),
                              confirmed_by = cast(:u as uuid), updated_at = now()
        where id = cast(:i as uuid) and status in ('IN_TRANSIT','ROUTE_ASSIGNED')
        returning delivered_at
    """), {"u": principal.user_id, "i": shipment_id})).mappings().first()
    if row is None:
        raise Conflict("delivery confirmation allowed only from IN_TRANSIT/ROUTE_ASSIGNED")

    await db.execute(text(
        "update vehicles set status = 'AVAILABLE'"
        " where id = (select vehicle_id from shipments where id = cast(:i as uuid))"),
        {"i": shipment_id})
    await svc.add_event(system_db, shipment_id, "DELIVERY_CONFIRMED",
                        principal.user_id, {"confirmed_by": principal.user_id})
    await audit.emit(system_db, actor_id=principal.user_id, actor_role=principal.role,
                     action="DELIVERY_CONFIRMED", outcome="SUCCESS",
                     resource_type="shipment", resource_id=shipment_id,
                     ip=_ip(request))
    return {"id": shipment_id, "status": "DELIVERED",
            "delivered_at": row["delivered_at"].isoformat()}



