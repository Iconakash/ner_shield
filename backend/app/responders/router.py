"""Responder API (SIH26002 P3). Additive surface over the responder engine."""
from typing import Literal

from fastapi import APIRouter, Depends, Query
from pydantic import BaseModel, Field
from sqlalchemy import text
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.db import get_db, get_system_db
from app.core.security import Principal
from app.dependencies import get_principal, require_permissions
from app.responders import service as svc

router = APIRouter(tags=["responders"])

RESPONDER_TYPES = ("HEALTH_FACILITY", "EMERGENCY_RESPONSE", "POLICE",
                   "FIRE", "ROAD_MAINTENANCE", "GOVERNMENT_FIELD_UNIT",
                   "OTHER")


class ResponderIn(BaseModel):
    name: str = Field(min_length=2, max_length=160)
    responder_type: Literal[tuple(RESPONDER_TYPES)]
    lon: float = Field(ge=80.0, le=98.0)
    lat: float = Field(ge=21.0, le=29.5)
    state_code: str | None = Field(default=None, max_length=8)
    district_code: str | None = Field(default=None, max_length=12)
    contact_method: Literal["DISPATCH_RADIO", "PHONE", "SATELLITE_PHONE",
                            "APP"] = "DISPATCH_RADIO"
    contact_info: str = Field(default="", max_length=200)
    escalation_priority: int = Field(default=100, ge=1, le=999)


class TransitionIn(BaseModel):
    status: Literal["ACKNOWLEDGED", "DISPATCHED", "ON_SITE", "RESOLVED",
                    "CANCELLED"]
    note: str = Field(default="", max_length=500)


@router.get("/responders",
            dependencies=[Depends(require_permissions("VIEW_INCIDENTS"))])
async def list_responders(db: AsyncSession = Depends(get_db),
                          district: str | None = None,
                          rtype: str | None = None):
    rows = (await db.execute(text("""
        select id::text as id, name, responder_type::text as responder_type,
               operational_status::text as operational_status,
               district_code, state_code, contact_method, is_demo,
               st_asgeojson(geom)::json as geo
        from responders
        where (:d is null or district_code = :d)
          and (:t is null or responder_type::text = :t)
        order by escalation_priority limit 200
    """), {"d": district, "t": rtype})).mappings().all()
    return [dict(r) for r in rows]


@router.post("/responders", status_code=201,
             dependencies=[Depends(require_permissions("MANAGE_SYSTEM"))])
async def create_responder(body: ResponderIn,
                           principal: Principal = Depends(get_principal),
                           system_db: AsyncSession = Depends(get_system_db)):
    row = (await system_db.execute(text("""
        insert into responders (name, responder_type, geom, state_code,
                                district_code, contact_method, contact_info,
                                escalation_priority)
        values (:n, cast(:t as responder_type),
                st_setsrid(st_makepoint(:lon,:lat),4326), :s, :d,
                :cm, :ci, :p)
        returning id::text as id
    """), {"n": body.name, "t": body.responder_type, "lon": body.lon,
           "lat": body.lat, "s": body.state_code, "d": body.district_code,
           "cm": body.contact_method, "ci": body.contact_info,
           "p": body.escalation_priority})).mappings().first()
    await system_db.commit()
    return {"id": row["id"]}


@router.get("/responders/nearest",
            dependencies=[Depends(require_permissions("VIEW_INCIDENTS"))])
async def nearest(lon: float = Query(ge=80.0, le=98.0),
                  lat: float = Query(ge=21.0, le=29.5),
                  db: AsyncSession = Depends(get_db)):
    res = await svc.find_nearest(db, lon=lon, lat=lat)
    return res or {"none_in_range": True}


@router.get("/response-tasks",
            dependencies=[Depends(require_permissions("VIEW_INCIDENTS"))])
async def tasks(db: AsyncSession = Depends(get_db), limit: int = 100):
    return await svc.list_tasks(db, limit=limit)


@router.get("/response-tasks/{task_id}",
            dependencies=[Depends(require_permissions("VIEW_INCIDENTS"))])
async def task_detail(task_id: str, db: AsyncSession = Depends(get_db)):
    from app.core.errors import NotFound
    res = await svc.get_task(db, task_id)
    if res is None:
        raise NotFound("response task not found")
    return res


@router.patch("/response-tasks/{task_id}")
async def move_task(task_id: str, body: TransitionIn,
                    principal: Principal = Depends(
                        require_permissions("VERIFY_INCIDENT")),
                    system_db: AsyncSession = Depends(get_system_db)):
    res = await svc.transition(system_db, task_id=task_id, new=body.status,
                               actor_id=str(principal.user_id),
                               role=principal.role, note=body.note)
    await system_db.commit()
    return res
