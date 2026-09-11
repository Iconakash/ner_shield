"""Offline synchronization API (Phase 15 · architecture §11).

  POST /sync/devices   register/enroll a field device      (any user)
  POST /sync/push      batched offline ops, idempotent     (role-per-op)
  GET  /sync/pull      scoped cache refresh                (role-scoped)
  GET  /sync/status    device + queue liveness             (any user)

Every pushed op is re-validated server-side: authentication -> account status
-> permission -> geographic scope -> business rules. Offline data is never
trusted (AX-1); duplicates are absorbed by client_op_id idempotency (OFF-03).
"""
from typing import Literal

from fastapi import APIRouter, Depends, Query, Request
from pydantic import BaseModel, Field
from sqlalchemy import text
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.db import get_db, get_system_db
from app.core.security import Principal
from app.dependencies import get_principal
from app.sync import service as sync_svc

router = APIRouter(prefix="/sync", tags=["sync"])


class DeviceIn(BaseModel):
    device_code: str = Field(min_length=6, max_length=120)


class Op(BaseModel):
    client_op_id: str = Field(min_length=8, max_length=120)
    op_type: Literal["FIELD_REPORT", "GPS_PING"]
    payload: dict


class PushIn(BaseModel):
    device_code: str | None = None
    connectivity: Literal["EXCELLENT", "GOOD", "WEAK", "VERY_WEAK",
                          "OFFLINE"] = "GOOD"
    ops: list[Op] = Field(max_length=100)


def _ip(request: Request):
    return request.client.host if request.client else None

@router.post("/devices")
async def register_device(body: DeviceIn, request: Request,
                          principal: Principal = Depends(get_principal),
                          system_db: AsyncSession = Depends(get_system_db)):
    """Device enrollment bound to the authenticated officer (SEC-04)."""
    await system_db.execute(text("""
        insert into sync_devices (device_code, user_id, platform, last_seen_at)
        values (:d, cast(:u as uuid), 'web', now())
        on conflict (device_code) do update set
            user_id = excluded.user_id, last_seen_at = now()
    """), {"d": body.device_code, "u": principal.user_id})
    await system_db.execute(text("""
        insert into sync_state (device_id, user_id)
        select id, cast(:u as uuid) from sync_devices where device_code = :d
        on conflict (device_id) do nothing
    """), {"d": body.device_code, "u": principal.user_id})
    return {"device": body.device_code, "registered": True}


@router.post("/push")
async def push(body: PushIn, request: Request,
               principal: Principal = Depends(get_principal),
               db: AsyncSession = Depends(get_db),
               system_db: AsyncSession = Depends(get_system_db)):
    """Apply queued offline ops. Per-op results; batch continues past rejections.

    FIELD_REPORT ops go through the online submission path (scope + confidence);
    GPS_PING ops re-check shipment scope, then trigger the RECALCULATE step
    (vehicle position + predictive ETA) right here in the loop.
    """
    from app.dependencies import ensure_geo_scope
    from app.shipments import service as ship_svc

    results = []
    policy = await sync_svc.get_active_sync_policy(system_db)
    await sync_svc.set_device_connectivity(
        system_db, body.device_code or "", body.connectivity)

    for op in body.ops:
        verdict, reason = sync_svc.gate_op(op.model_dump(),
                                           body.connectivity, policy)
        if verdict != "ALLOWED":
            results.append({"client_op_id": op.client_op_id,
                            "status": "DEFERRED" if verdict == "DEFERRED"
                            else "REJECTED",
                            "reason": reason})
            continue

        dup = await sync_svc.is_duplicate(system_db, op.client_op_id)
        if dup:
            results.append({"client_op_id": op.client_op_id,
                            "status": "DUPLICATE",
                            **({"resource_id": dup["resource_id"]}
                               if dup["resource_id"] else {})})
            continue
        try:
            if op.op_type == "FIELD_REPORT":
                p = dict(op.payload)
                p["client_op_id"] = op.client_op_id
                res = await sync_svc.apply_field_report(
                    db, system_db, principal, p)
                resource_id = res.get("id")
            elif op.op_type == "GPS_PING":
                shipment_id = op.payload["shipment_id"]
                ship = await ship_svc.get_shipment(db, shipment_id)
                await ensure_geo_scope(principal, ship["dest_state"],
                                       ship["dest_district"], db)
                eta = await sync_svc.apply_gps_ping(db, shipment_id,
                                                    op.payload)
                resource_id = shipment_id
                results.append({"client_op_id": op.client_op_id,
                                "status": "ACCEPTED",
                                "resource_id": resource_id, "eta": eta})
                await sync_svc.log_op(system_db, op.client_op_id,
                                      op.op_type, "ACCEPTED",
                                      resource_id, body.device_code)
                continue
            else:  # pragma: no cover — pydantic Literal guards this
                continue

            await sync_svc.log_op(system_db, op.client_op_id, op.op_type,
                                  "ACCEPTED", resource_id, body.device_code)
            results.append({"client_op_id": op.client_op_id,
                            "status": "ACCEPTED",
                            **({"resource_id": resource_id}
                               if resource_id else {})})
        except Exception as exc:  # noqa: BLE001 — one bad op must not kill batch
            await sync_svc.log_op(system_db, op.client_op_id, op.op_type,
                                  "REJECTED", None, body.device_code)
            results.append({"client_op_id": op.client_op_id,
                            "status": "REJECTED", "reason": str(exc)[:200]})

    await system_db.execute(text("""
        update sync_state set last_push_at = now()
        where device_id in (select id from sync_devices
                            where device_code = :d)
    """), {"d": body.device_code or ""})
    return {"results": results,
            "accepted": sum(1 for r in results if r["status"] == "ACCEPTED"),
            "total": len(results)}

@router.get("/pull")
async def pull(cursor: int = Query(default=0, ge=0),
               principal: Principal = Depends(get_principal),
               db: AsyncSession = Depends(get_db)):
    """Scoped cache refresh for the offline client (alerts, shipments, incidents)."""
    data = await sync_svc.pull_changes(db, principal, cursor)
    return {"cursor": cursor, **data}


@router.get("/policy")
async def get_policy(db: AsyncSession = Depends(get_db)):
    """Effective progressive-sync matrix (client consults before flushing)."""
    policy = await sync_svc.get_active_sync_policy(db)
    return {"connectivity_classes": list(sync_svc.CONNECTIVITY_CLASSES),
            "policy": policy}


@router.get("/status")
async def status(principal: Principal = Depends(get_principal),
                 system_db: AsyncSession = Depends(get_system_db)):
    row = (await system_db.execute(text("""
        select d.device_code, s.pull_cursor, s.last_push_at, s.last_pull_at
        from sync_devices d left join sync_state s on s.device_id = d.id
        where d.user_id = cast(:u as uuid) and d.is_active
        order by d.registered_at desc limit 5
    """), {"u": principal.user_id})).mappings().all()
    return {"devices": [dict(r) for r in row]}


