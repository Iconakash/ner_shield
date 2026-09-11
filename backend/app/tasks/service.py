"""Action Center task service. All mutations audited; notifications emitted on
assignment/escalation via the notifications service (in-app always available)."""
from datetime import datetime, timezone

from sqlalchemy import text
from sqlalchemy.ext.asyncio import AsyncSession

from app.audit import service as audit
from app.core.errors import Conflict, ForbiddenRole, NotFound
from app.tasks import lifecycle


async def _next_code(db: AsyncSession) -> str:
    row = (await db.execute(text("select count(*) + 1 from tasks"))).scalar()
    return f"TASK-{int(row or 1):06d}"


async def create_task(db, principal, *, title, description="",
                      priority="MEDIUM", source_type=None, source_id=None,
                      state_code=None, district_code=None, template_code=None,
                      due_at=None, assign_to=None, recommendation_ref=None):
    tpl = None
    if template_code:
        tpl = (await db.execute(text(
            "select id, sla_hours, default_priority from task_templates"
            " where code = :c"), {"c": template_code})).mappings().first()
        if tpl is None:
            raise NotFound(f"task template '{template_code}' not found")
        priority = priority if priority != "MEDIUM" else tpl["default_priority"]
    if district_code and not state_code:
        srow = (await db.execute(text(
            "select state_code from districts where code = :d"),
            {"d": district_code})).mappings().first()
        state_code = srow["state_code"] if srow else None

    due = due_at or lifecycle.sla_deadline(
        priority, float(tpl["sla_hours"]) if tpl else None,
        datetime.now(timezone.utc))
    code = await _next_code(db)
    row = (await db.execute(text("""
        insert into tasks (code, title, description, priority, source_type,
                           source_id, recommendation_ref, org_id, state_code,
                           district_code, created_by, assigned_to, due_at,
                           template_id)
        values (:code, :title, :desc, cast(:prio as task_priority), :stype,
                :sid, :rec, cast(:org as uuid), :state, :dist,
                cast(:actor as uuid), cast(:assignee as uuid), :due,
                cast(:tpl as uuid))
        returning id::text as id, code
    """), {"code": code, "title": title, "desc": description,
           "prio": priority, "stype": source_type, "sid": source_id,
           "rec": recommendation_ref, "org": principal.org_id,
           "state": state_code, "dist": district_code,
           "actor": principal.user_id, "assignee": assign_to,
           "due": due, "tpl": tpl["id"] if tpl else None})).mappings().first()

    await db.execute(text("""
        insert into task_events (task_id, event_type, to_status, actor_id, detail)
        values (cast(:t as uuid), 'CREATED', 'CREATED', cast(:a as uuid),
                jsonb_build_object('source_type', :st, 'source_id', :si))
    """), {"t": row["id"], "a": principal.user_id, "st": source_type,
           "si": source_id})

    if assign_to:
        await _record_assignment(db, principal, row["id"], assign_to)
        await db.execute(text(
            "update tasks set status = 'ASSIGNED' where id = cast(:t as uuid)"
            " and status = 'CREATED'"), {"t": row["id"]})
    await audit.emit(db, actor_id=principal.user_id, actor_role=principal.role,
                     action="TASK_CREATE", outcome="SUCCESS",
                     resource_type="task", resource_id=row["id"],
                     detail={"priority": priority, "source_type": source_type})
    return dict(row)


async def _record_assignment(db, principal, task_id, assignee_id):
    await db.execute(text("""
        update task_assignments set active = false where task_id = cast(:t as uuid);
        insert into task_assignments (task_id, assignee_id, assigned_by)
        values (cast(:t as uuid), cast(:u as uuid), cast(:a as uuid))
    """), {"t": task_id, "u": assignee_id, "a": principal.user_id})


async def transition(db, principal, task_id: str, target: str,
                     note: str | None = None) -> dict:
    """Apply one whitelisted lifecycle transition with permission checks."""
    t = (await db.execute(text("""
        select id::text as id, status::text as status,
               assigned_to::text as assigned_to, code, title
        from tasks where id = cast(:i as uuid)
    """), {"i": task_id})).mappings().first()
    if t is None:
        raise NotFound("task not found")
    current = t["status"]
    if not lifecycle.can_transition(current, target):
        raise Conflict(f"illegal transition {current} -> {target}")

    is_assignee = t["assigned_to"] == principal.user_id
    perms = set(principal.permissions)
    if target in ("ACCEPTED", "COMPLETED") and not is_assignee \
            and "APPROVE_REROUTE" not in perms:
        raise ForbiddenRole("only the assignee may accept/complete a task")
    if target == "VERIFIED" and principal.user_id == t["assigned_to"]:
        raise Conflict("verification requires someone other than the assignee "
                       "(four-eyes principle)")

    col_map = {"COMPLETED": "completed_at", "VERIFIED": "verified_at",
               "CLOSED": "closed_at"}
    sets = ["status = cast(:s as task_status)"]
    params: dict = {"i": task_id, "s": target}
    if target in col_map:
        sets.append(f"{col_map[target]} = now()")
    if note is not None:
        sets.append("outcome_note = :n")
        params["n"] = note

    await db.execute(text(
        f"update tasks set {', '.join(sets)} where id = cast(:i as uuid)"),
        params)

    await db.execute(text("""
        insert into task_events (task_id, event_type, from_status, to_status,
                                 actor_id, detail)
        values (cast(:t as uuid), 'STATUS_CHANGE',
                cast(:f as task_status), cast(:to as task_status),
                cast(:a as uuid), jsonb_build_object('note', :n))
    """), {"t": task_id, "f": current, "to": target,
           "a": principal.user_id, "n": note})

    await audit.emit(db, actor_id=principal.user_id, actor_role=principal.role,
                     action=f"TASK_{target}", outcome="SUCCESS",
                     resource_type="task", resource_id=task_id,
                     detail={"from": current, "to": target})

    if target == "ASSIGNED":
        await _notify_assignment(db, principal, dict(t))
    try:
        from app.realtime.bus import bus
        await bus.publish("task_update", {"id": task_id,
                                          "code": t["code"],
                                          "status": target})
    except Exception:  # noqa: BLE001 — realtime must never break transitions
        pass
    return {"id": task_id, "code": t["code"], "status": target}


async def _notify_assignment(db, principal, task_row):
    if not task_row.get("assigned_to"):
        return
    from app.notifications import service as ntf
    await ntf.notify_user(
        db, user_id=task_row["assigned_to"],
        template_code="TASK_ASSIGNED", severity="MEDIUM",
        title=f"New task {task_row['code']}: {task_row['title']}",
        body=f"Task {task_row['code']} assigned by {principal.email}",
        source_type="TASK", source_id=task_row["id"])


async def escalate_overdue(db) -> list[dict]:
    """Find breached open tasks; record SLA breach, bump severity + notify.
    Runs on the SYSTEM connection from the worker, or an admin session."""
    rows = (await db.execute(text("""
        select id::text as id, code, title, assigned_to::text as assigned_to,
               priority::text as priority, due_at, escalated
        from tasks
        where due_at is not null and due_at < now()
          and status not in ('CLOSED', 'CANCELLED')
          and escalated = false
        limit 200
    """))).mappings().all()
    out = []
    for r in rows:
        new_prio = lifecycle.escalation_target_priority(r["priority"])
        minutes_over = int((datetime.now(timezone.utc)
                            - r["due_at"]).total_seconds() // 60)
        await db.execute(text("""
            update tasks set priority = cast(:p as task_priority),
                   escalated = true where id = cast(:i as uuid)
        """), {"p": new_prio, "i": r["id"]})
        await db.execute(text("""
            insert into task_sla (task_id, breached, minutes_overdue,
                                  action_taken)
            values (cast(:t as uuid), true, cast(:mo as numeric), 'ESCALATED')
        """), {"t": r["id"], "mo": minutes_over})
        await db.execute(text("""
            insert into task_events (task_id, event_type, detail)
            values (cast(:t as uuid), 'ESCALATE',
                    jsonb_build_object('minutes_overdue', cast(:mo as int),
                                       'new_priority', :p))
        """), {"t": r["id"], "mo": minutes_over, "p": new_prio})
        if r["assigned_to"]:
            from app.notifications import service as ntf
            await ntf.notify_user(
                db, user_id=r["assigned_to"],
                template_code="TASK_ESCALATED", severity="CRITICAL",
                title=f"Task {r['code']} escalated ({new_prio})",
                body=f"SLA breached by {minutes_over} minutes.",
                source_type="TASK", source_id=r["id"])
        out.append({"id": r["id"], "code": r["code"],
                    "new_priority": new_prio,
                    "minutes_overdue": minutes_over})
    return out


async def list_my_tasks(db, principal, include_done=False) -> list[dict]:
    extra = "" if include_done else \
        " and t.status::text not in ('CLOSED','CANCELLED')"
    rows = (await db.execute(text(f"""
        select t.id::text as id, t.code, t.title, t.status::text as status,
               t.priority::text as priority, t.due_at, t.escalated,
               t.source_type, t.source_id
        from tasks t
        where (t.assigned_to = cast(:u as uuid)
                  or app_current_role() in
                     ('SUPER_ADMIN','REGIONAL_AUTHORITY'))
        {extra}
        order by t.due_at nulls last, t.created_at desc limit 200
    """), {"u": principal.user_id})).mappings().all()
    return [dict(r) for r in rows]


async def get_task(db, task_id: str) -> dict | None:
    row = (await db.execute(text("""
        select t.id::text as id, t.code, t.title, t.description,
               t.status::text as status, t.priority::text as priority,
               t.source_type, t.source_id, t.state_code, t.district_code,
               t.assigned_to::text as assigned_to, t.created_by::text as created_by,
               t.due_at, t.escalated, t.outcome_note, t.created_at
        from tasks t where t.id = cast(:i as uuid)
    """), {"i": task_id})).mappings().first()
    if row is None:
        return None
    item = dict(row)
    events = (await db.execute(text("""
        select event_type, from_status::text as from_status,
               to_status::text as to_status, detail, created_at
        from task_events where task_id = cast(:i as uuid)
        order by created_at asc limit 100
    """), {"i": task_id})).mappings().all()
    item["events"] = [dict(e) for e in events]
    return item

