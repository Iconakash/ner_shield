"""Responder auto-alert engine (SIH26002 P3).

When a HIGH/CRITICAL hazard report is VALIDATED, the existing validation loop
(app/field/service.validate_report) calls dispatch_for_report():

    validated report -> nearest ACTIVE responder (PostGIS KNN, configurable
    radius) -> response_task(PENDING) + alert through the EXISTING alert
    engine -> tracked lifecycle PENDING -> ACKNOWLEDGED -> DISPATCHED ->
    ON_SITE -> RESOLVED (transitions enforced here, audited).

Escalation: tasks still PENDING past the configured window are reassigned to
the next-nearest responder; if none exists the district chain is notified via
the existing alert machinery. All transitions emit audit events.

No real emergency numbers are committed: responder contact records are
configurable rows (seed/demo rows are flagged is_demo = true).
"""
import json

from sqlalchemy import text
from sqlalchemy.ext.asyncio import AsyncSession

# Configurable dispatch policy (documented constants; env-tunable later):
DISPATCH_SEVERITIES = ("HIGH", "CRITICAL")   # severities that trigger dispatch
SEARCH_RADIUS_M = 50_000                     # nearest-responder search radius
ACK_TIMEOUT_MINUTES = 15                     # PENDING -> escalate after this

VALID_TRANSITIONS: dict[str, tuple[str, ...]] = {
    "PENDING": ("ACKNOWLEDGED", "CANCELLED"),
    "ACKNOWLEDGED": ("DISPATCHED", "RESOLVED", "CANCELLED"),
    "DISPATCHED": ("ON_SITE", "RESOLVED", "CANCELLED"),
    "ON_SITE": ("RESOLVED", "CANCELLED"),
    "RESOLVED": (),
    "CANCELLED": (),
}

PRIORITY_OF_SEVERITY = {"HIGH": "HIGH", "CRITICAL": "CRITICAL"}


def next_status_is_valid(current: str, new: str) -> bool:
    return new in VALID_TRANSITIONS.get(current, ())


async def find_nearest(db: AsyncSession, *, lon: float, lat: float,
                       exclude_id: str | None = None) -> dict | None:
    """KNN nearest ACTIVE responder within SEARCH_RADIUS_M (PostGIS geography)."""
    row = (await db.execute(text("""
        select r.id::text as id, r.name, r.responder_type::text as rtype,
               r.district_code, r.contact_method, r.escalation_priority,
               round(st_distance(r.geom::geography,
                     st_setsrid(st_makepoint(:lon,:lat),4326)::geography)
                     ::numeric, 1) as dist_m
        from responders r
        where r.operational_status = 'ACTIVE'
          and (:ex is null or r.id <> cast(:ex as uuid))
          and st_dwithin(r.geom::geography,
              st_setsrid(st_makepoint(:lon,:lat),4326)::geography,
              :radius)
        order by r.geom::geography <->
                 st_setsrid(st_makepoint(:lon,:lat),4326)::geography
        limit 1
    """), {"lon": lon, "lat": lat, "ex": exclude_id,
           "radius": SEARCH_RADIUS_M})).mappings().first()
    return dict(row) if row else None


async def create_task(system_db: AsyncSession, *, report_id: str,
                      alert_id: str | None, responder: dict,
                      severity: str, created_by: str | None = None) -> dict:
    """Create one PENDING task + CREATION event."""
    task = (await system_db.execute(text("""
        insert into response_tasks (report_id, alert_id, responder_id,
                                    distance_m, priority, created_by)
        values (cast(:r as uuid),
                case when :a is null then null else cast(:a as uuid) end,
                cast(:resp as uuid), :d, :p,
                case when :u is null then null else cast(:u as uuid) end)
        returning id::text as id, status::text as status
    """), {"r": report_id, "a": alert_id,
           "resp": responder["id"], "d": responder.get("dist_m"),
           "p": PRIORITY_OF_SEVERITY.get(severity, "HIGH"),
           "u": created_by})).mappings().first()
    await system_db.execute(text("""
        insert into response_task_events (task_id, event_type, note)
        values (cast(:t as uuid), 'CREATED', :n)
    """), {"t": task["id"],
           "n": f"auto-dispatch: {responder['name']} "
                f"({responder['rtype']}, {responder['dist_m']} m)"})
    return dict(task)


async def dispatch_for_report(
    system_db: AsyncSession, *, report_id: str, lon: float, lat: float,
    severity: str, district_code: str | None, alert_id: str | None = None,
    created_by: str | None = None,
) -> dict:
    """Nearest-responder dispatch for a validated HIGH/CRITICAL report.

    Never raises: dispatch failure must not fail the validation loop — the
    outcome (dispatched / no_responder_in_range) is returned for audit.
    """
    try:
        responder = await find_nearest(system_db, lon=lon, lat=lat)
        if responder is None:
            # no responder in range -> notify the district chain instead
            from app.alerts import service as alerts_svc
            await alerts_svc.create_alert(
                system_db, level="HIGH" if severity == "HIGH" else "CRITICAL",
                alert_type="ROAD_WARNING",
                title=f"No responder in range ({district_code or '?'})",
                message=f"{severity} incident at ({lon:.3f},{lat:.3f}) has no "
                        "active responder within range - manual dispatch "
                        "required.",
                state_code=None, district_code=district_code,
                payload={"report": report_id, "dispatch": "uncovered"})
            return {"status": "no_responder_in_range"}
        task = await create_task(system_db, report_id=report_id,
                                 alert_id=alert_id, responder=responder,
                                 severity=severity, created_by=created_by)
        return {"status": "dispatched", "task": task, "responder": {
            "id": responder["id"], "name": responder["name"],
            "type": responder["rtype"], "distance_m": responder["dist_m"]}}
    except Exception as exc:  # noqa: BLE001 — isolation mandated above
        return {"status": "dispatch_failed", "reason": str(exc)[:160]}


async def transition(system_db: AsyncSession, *, task_id: str, new: str,
                     actor_id: str | None = None, role: str | None = None,
                     note: str = "") -> dict:
    """Enforced lifecycle move with event + audit trail."""
    from app.audit import service as audit_svc
    from app.core.errors import Conflict, NotFound

    row = (await system_db.execute(text("""
        select id::text as id, status::text as status from response_tasks
        where id = cast(:t as uuid)
    """), {"t": task_id})).mappings().first()
    if row is None:
        raise NotFound("response task not found")
    if not next_status_is_valid(row["status"], new):
        raise Conflict(f"invalid transition {row['status']} -> {new}")

    sets = "status = :s, updated_at = now()"
    params: dict = {"s": new, "t": task_id}
    if new == "ACKNOWLEDGED":
        sets += ", acknowledged_at = now()"
    elif new == "RESOLVED":
        sets += ", resolved_at = now()"
    await system_db.execute(
        text(f"update response_tasks set {sets} where id = cast(:t as uuid)"),
        params)
    await system_db.execute(text("""
        insert into response_task_events (task_id, event_type, actor_id, note)
        values (cast(:t as uuid), :e,
                case when :u is null then null else cast(:u as uuid) end, :n)
    """), {"t": task_id, "e": new, "u": actor_id, "n": note[:500]})
    await audit_svc.emit(system_db, actor_id=actor_id, actor_role=role,
                         action="RESPONSE_TASK_UPDATED", outcome="SUCCESS",
                         resource_type="response_task", resource_id=task_id,
                         detail={"from": row["status"], "to": new,
                                 "note": note[:200]})
    return {"id": task_id, "status": new}


async def list_tasks(db: AsyncSession, limit: int = 100) -> list[dict]:
    rows = (await db.execute(text("""
        select t.id::text as id, t.status::text as status,
               t.priority::text as priority, t.distance_m,
               t.report_id::text as report_id, t.alert_id::text as alert_id,
               r.name as responder_name,
               r.responder_type::text as responder_type,
               t.assigned_at, t.acknowledged_at, t.resolved_at
        from response_tasks t
        join responders r on r.id = t.responder_id
        order by t.created_at desc limit :l
    """), {"l": max(1, min(limit, 200))})).mappings().all()
    return [dict(r) for r in rows]


async def get_task(db: AsyncSession, task_id: str) -> dict | None:
    row = (await db.execute(text("""
        select t.id::text as id, t.status::text as status,
               t.priority::text as priority, t.distance_m,
               t.report_id::text as report_id,
               r.name as responder_name, r.contact_method,
               r.escalation_priority,
               (select json_agg(json_build_object('event_type', e.event_type,
                                                  'note', e.note,
                                                  'at', e.created_at))
                from response_task_events e where e.task_id = t.id) as events
        from response_tasks t join responders r on r.id = t.responder_id
        where t.id = cast(:t as uuid)
    """), {"t": task_id})).mappings().first()
    if row is None:
        return None
    out = dict(row)
    out["events"] = json.loads(out["events"]) if out["events"] else []
    return out


async def escalation_sweep(system_db: AsyncSession) -> list[dict]:
    """Reassign overdue PENDING tasks to the next-nearest responder.

    Runs from the worker runner. If no alternative responder exists the task
    stays in place and an ESCALATED event + district-chain alert fires.
    """
    from app.alerts import service as alerts_svc
    from app.audit import service as audit_svc

    overdue = (await system_db.execute(text("""
        select t.id::text as id, t.responder_id::text as responder_id,
               t.priority::text as prio,
               st_x(fr.geom) as lon, st_y(fr.geom) as lat,
               coalesce(fr.district_code, '') as district_code
        from response_tasks t
        join field_reports fr on fr.id = t.report_id
        where t.status = 'PENDING'
          and t.assigned_at < now() - make_interval(mins => :m)
        limit 50
    """), {"m": ACK_TIMEOUT_MINUTES})).mappings().all()

    out: list[dict] = []
    for row in overdue:
        alt = await find_nearest(system_db, lon=float(row["lon"]),
                                 lat=float(row["lat"]),
                                 exclude_id=row["responder_id"])
        if alt is not None:
            await system_db.execute(text("""
                update response_tasks set responder_id = cast(:r as uuid),
                    distance_m = :d, assigned_at = now(), updated_at = now()
                where id = cast(:t as uuid)
            """), {"r": alt["id"], "d": alt.get("dist_m"), "t": row["id"]})
            await system_db.execute(text("""
                insert into response_task_events (task_id, event_type, note)
                values (cast(:t as uuid), 'REASSIGNED', :n)
            """), {"t": row["id"],
                   "n": f"ack timeout -> reassigned to {alt['name']}"})
            out.append({"task": row["id"], "reassigned_to": alt["name"]})
        else:
            await system_db.execute(text("""
                insert into response_task_events (task_id, event_type, note)
                values (cast(:t as uuid), 'ESCALATED',
                        'no alternative responder - district authority notified')
            """), {"t": row["id"]})
            if row["district_code"]:
                await alerts_svc.create_alert(
                    system_db,
                    level="CRITICAL" if row["prio"] == "CRITICAL" else "HIGH",
                    alert_type="ROAD_WARNING",
                    title=f"Response task unacknowledged "
                          f"({row['district_code']})",
                    message="Primary and secondary responders did not "
                            "acknowledge within the window - district "
                            "authority action required.",
                    district_code=row["district_code"],
                    payload={"task": row["id"], "escalation": True})
            out.append({"task": row["id"], "escalated": True})

    for e in out:
        await audit_svc.emit(system_db, actor_id=None, actor_role=None,
                             action="RESPONSE_TASK_UPDATED",
                             outcome="SUCCESS",
                             resource_type="response_task",
                             resource_id=e["task"], detail=e)
    return out
