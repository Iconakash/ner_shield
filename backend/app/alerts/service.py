"""Alert Engine (Phase 12 · FR-C11).

Targeted routing, not broadcast: every alert type has a frozen escalation chain
of roles. The alert sits with the first role; unacknowledged alerts escalate to
the next role after a severity-based timeout (CRITICAL 15m · HIGH 30m ·
WARNING 60m · INFO never). Acknowledgment by the current chain role stops
escalation. Every hop is an append-only event + audit row (AUD-05).
"""
import json

from sqlalchemy import text
from sqlalchemy.ext.asyncio import AsyncSession

# Frozen escalation chains (source-mandated order, then upward).
ALERT_CHAINS: dict[str, list[str]] = {
    "ROAD_WARNING": ["DISTRICT_OFFICER", "REGIONAL_AUTHORITY", "SUPER_ADMIN"],
    "CRITICAL_SHIPMENT": ["LOGISTICS_OFFICER", "REGIONAL_AUTHORITY", "SUPER_ADMIN"],
    "REGIONAL_SUPPLY_CRISIS": ["REGIONAL_AUTHORITY", "SUPER_ADMIN"],
    "DISRUPTION_PREDICTED": ["DISTRICT_OFFICER", "REGIONAL_AUTHORITY", "SUPER_ADMIN"],
    "SHORTAGE_PREDICTED": ["DISTRICT_OFFICER", "LOGISTICS_OFFICER",
                           "REGIONAL_AUTHORITY", "SUPER_ADMIN"],
    "IMPACT_ALERT": ["DISTRICT_OFFICER", "LOGISTICS_OFFICER",
                     "REGIONAL_AUTHORITY", "SUPER_ADMIN"],
    "SYSTEM": ["SUPER_ADMIN"],
    # ---- decision-intelligence extension (migration 0027); existing types
    # above are untouched and keep their frozen chains ------------------------
    "FLOOD_RISK": ["DISTRICT_OFFICER", "REGIONAL_AUTHORITY", "SUPER_ADMIN"],
    "LANDSLIDE_RISK": ["DISTRICT_OFFICER", "REGIONAL_AUTHORITY", "SUPER_ADMIN"],
    "EXTREME_RAINFALL": ["DISTRICT_OFFICER", "REGIONAL_AUTHORITY", "SUPER_ADMIN"],
    "ROAD_CLOSURE": ["DISTRICT_OFFICER", "REGIONAL_AUTHORITY", "SUPER_ADMIN"],
    "ROUTE_FAILURE_PREDICTED": ["LOGISTICS_OFFICER", "REGIONAL_AUTHORITY",
                                "SUPER_ADMIN"],
    "SOURCE_CONFLICT": ["SUPER_ADMIN"],
    "DATA_STALE": ["SUPER_ADMIN"],
}

# Minutes before an unacknowledged alert escalates (INFO never escalates).
LEVEL_TIMEOUTS: dict[str, int | None] = {
    "INFO": None, "WARNING": 60, "HIGH": 30, "CRITICAL": 15,
}

SEVERITY_RANK = {"INFO": 0, "WARNING": 1, "HIGH": 2, "CRITICAL": 3}


def chain_for(alert_type: str) -> list[str]:
    return ALERT_CHAINS.get(alert_type, ["SUPER_ADMIN"])


def timeout_minutes(level: str) -> int | None:
    return LEVEL_TIMEOUTS.get(level)


def can_acknowledge(user_role: str, current_role: str | None,
                    is_super: bool = False) -> bool:
    """Only the role currently holding the ball (or SUPER_ADMIN) may ack."""
    if is_super:
        return True
    return user_role == current_role


async def create_alert(
    system_db: AsyncSession, *, level: str, alert_type: str,
    title: str, message: str = "",
    state_code: str | None = None, district_code: str | None = None,
    segment_id: str | None = None, shipment_id: str | None = None,
    payload: dict | None = None,
) -> dict:
    chain = chain_for(alert_type)
    row = (await system_db.execute(text("""
        insert into alerts (level, alert_type, title, message,
            state_code, district_code, segment_id, shipment_id, payload,
            current_role, escalate_after_minutes)
        values (cast(:lv as alert_level), cast(:t as alert_type), :title,
                :msg, :s, :d,
                case when :seg is null then null else cast(:seg as uuid) end,
                case when :shp is null then null else cast(:shp as uuid) end,
                cast(:p as jsonb), cast(:r as user_role),
                coalesce(:ea, 30))
        returning id::text as id, current_role::text as current_role
    """), {"lv": level, "t": alert_type, "title": title, "msg": message,
           "s": state_code, "d": district_code, "seg": segment_id,
           "shp": shipment_id, "p": json.dumps(payload or {}),
           "r": chain[0],
           "ea": timeout_minutes(level)})
    ).mappings().first()
    aid = row["id"]
    await add_event(system_db, aid, stage=0, event_type="CREATED",
                    to_role=chain[0], detail={"level": level})
    return {"id": aid, "status": "ACTIVE", "current_role": chain[0]}


async def add_event(system_db: AsyncSession, alert_id: str, *, stage: int,
                    event_type: str, actor_id: str | None = None,
                    to_role: str | None = None, reason: str | None = None,
                    detail: dict | None = None) -> None:
    await system_db.execute(text("""
        insert into alert_events (alert_id, stage, event_type, actor_id,
            to_role, reason, detail)
        values (cast(:a as uuid), :st, :et, cast(:ac as uuid),
                cast(:tr as user_role), :rs, cast(:d as jsonb))
    """), {"a": alert_id, "st": stage, "et": event_type, "ac": actor_id,
           "tr": to_role, "rs": reason, "d": json.dumps(detail or {})})

async def acknowledge(system_db: AsyncSession, alert_id: str,
                      user_id: str, user_role: str) -> dict:
    row = await _get(system_db, alert_id)
    if not can_acknowledge(user_role, row["current_role"]):
        from app.core.errors import ForbiddenRole
        raise ForbiddenRole(
            f"acknowledgment belongs to {row['current_role']} in the escalation chain")
    if row["status"] in ("ACKNOWLEDGED", "RESOLVED"):
        from app.core.errors import Conflict
        raise Conflict("alert already closed")
    await system_db.execute(text("""
        update alerts set status = 'ACKNOWLEDGED',
            acknowledged_by = cast(:u as uuid), acknowledged_at = now()
        where id = cast(:a as uuid)
    """), {"u": user_id, "a": alert_id})
    await add_event(system_db, alert_id, stage=int(row["current_stage"]),
                    event_type="ACKNOWLEDGED", actor_id=user_id)
    return {"id": alert_id, "status": "ACKNOWLEDGED"}


async def resolve(system_db: AsyncSession, alert_id: str,
                  user_id: str, user_role: str, note: str | None = None) -> dict:
    row = await _get(system_db, alert_id)
    if row["status"] == "RESOLVED":
        from app.core.errors import Conflict
        raise Conflict("alert already resolved")
    if not can_acknowledge(user_role, row["current_role"], is_super=user_role == "SUPER_ADMIN"):
        from app.core.errors import ForbiddenRole
        raise ForbiddenRole("only the current chain role or SUPER_ADMIN may resolve")
    await system_db.execute(text("""
        update alerts set status = 'RESOLVED',
            resolved_by = cast(:u as uuid), resolved_at = now()
        where id = cast(:a as uuid)
    """), {"u": user_id, "a": alert_id})
    await add_event(system_db, alert_id, stage=int(row["current_stage"]),
                    event_type="RESOLVED", actor_id=user_id, reason=note)
    return {"id": alert_id, "status": "RESOLVED"}


async def escalation_sweep(system_db: AsyncSession) -> dict:
    """Promote every overdue unacknowledged alert to the next chain role."""
    overdue = (await system_db.execute(text("""
        select a.id::text as id, a.level::text as level,
               a.alert_type::text as alert_type,
               a.current_stage, a.status::text as status
        from alerts a
        where a.status in ('ACTIVE', 'ESCALATED')
          and a.level::text <> 'INFO'
    """))).mappings().all()
    # chain lengths vary per type; stage/timeout checks happen per-alert below.
    escalated = []
    for row in overdue:
        aid = row["id"]
        chain = chain_for(row["alert_type"])
        stage = int(row["current_stage"])
        timeout = timeout_minutes(row["level"])
        if timeout is None or stage >= len(chain) - 1:
            continue
        last_action = (await system_db.execute(text("""
            select coalesce(max(e.occurred_at), a.created_at) as t
            from alerts a left join alert_events e on e.alert_id = a.id
            where a.id = cast(:i as uuid)
        """), {"i": aid})).scalar()
        stale = (await system_db.execute(text("""
            select now() - :t > make_interval(mins => :m) as stale
        """), {"t": last_action, "m": timeout})).scalar()
        if not stale:
            continue

        next_stage = stage + 1
        next_role = chain[next_stage]
        await system_db.execute(text("""
            update alerts set status = 'ESCALATED',
                current_stage = :st, current_role = cast(:r as user_role)
            where id = cast(:i as uuid)
        """), {"st": next_stage, "r": next_role, "i": aid})
        await add_event(system_db, aid, stage=next_stage,
                        event_type="ESCALATED", to_role=next_role,
                        reason="TIMEOUT")
        escalated.append({"id": aid, "alert_type": row["alert_type"],
                          "to": next_role})

    from app.audit import service as audit_service
    for e in escalated:
        await audit_service.emit(system_db, actor_id=None, actor_role=None,
                                 action="ALERT_ESCALATED", outcome="SUCCESS",
                                 resource_type="alert", resource_id=e["id"],
                                 detail=e)
    return {"escalated": len(escalated), "items": escalated}


async def _get(system_db: AsyncSession, alert_id: str) -> dict:
    row = (await system_db.execute(text("""
        select id::text as id, level::text as level,
               alert_type::text as alert_type,
               status::text as status, current_stage, current_role::text as current_role,
               state_code, district_code
        from alerts where id = cast(:a as uuid)
    """), {"a": alert_id})).mappings().first()
    if row is None:
        from app.core.errors import NotFound
        raise NotFound("alert not found")
    return dict(row)


async def inbox(db: AsyncSession, role: str, state_code: str | None,
                district_code: str | None, limit: int = 100) -> list[dict]:
    """Alerts currently assigned to the caller's role within their geography."""
    rows = (await db.execute(text("""
        select a.id::text as id, a.level::text as level,
               a.alert_type::text as alert_type, a.title, a.message,
               a.status::text as status, a.current_role::text as current_role,
               a.state_code, a.district_code, a.created_at,
               coalesce(a.acknowledged_at, a.resolved_at) as acted_at
        from alerts a
        where a.current_role::text = :role
          and a.status in ('ACTIVE', 'ESCALATED')
          and (cast(:s as text) is null or a.state_code = cast(:s as text)
               or a.state_code is null)
          and (cast(:d as text) is null or a.district_code = cast(:d as text)
               or a.district_code is null)
        order by case a.level::text when 'CRITICAL' then 0 when 'HIGH' then 1
                 when 'WARNING' then 2 else 3 end,
                 a.created_at desc
        limit :l
    """), {"role": role, "s": state_code, "d": district_code,
           "l": max(1, min(limit, 300))})).mappings().all()
    return [dict(r) for r in rows]


# ============================================================================
# Decision-intelligence extension (additive): deduplication + lifecycle.
# Existing functions above are untouched.

ALLOWED_TRANSITIONS: dict[str, set[str]] = {
    "ACTIVE": {"VALIDATED", "MITIGATED", "RESOLVED"},
    "ESCALATED": {"VALIDATED", "MITIGATED", "RESOLVED"},
    "ACKNOWLEDGED": {"VALIDATED", "MITIGATED", "RESOLVED"},
    "VALIDATED": {"MITIGATED", "RESOLVED", "CLOSED"},
    "MITIGATED": {"RESOLVED", "CLOSED"},
    "RESOLVED": {"CLOSED"},
    "CLOSED": set(),
}


def valid_transition(current: str, new: str) -> bool:
    """Pure lifecycle check (§22) so callers can validate before hitting DB."""
    if current not in ALLOWED_TRANSITIONS or new not in ALLOWED_TRANSITIONS:
        return False
    return new in ALLOWED_TRANSITIONS[current]


async def upsert_deduped_alert(
    system_db: AsyncSession, *, dedup_key: str, level: str, alert_type: str,
    title: str, message: str = "", hazard: str | None = None,
    fingerprint: str | None = None,
    state_code: str | None = None, district_code: str | None = None,
    segment_id: str | None = None, shipment_id: str | None = None,
    payload: dict | None = None,
) -> dict:
    """Create OR refresh one alert per dedup key (§23).

    Same continuing condition => UPDATE existing open alert (occurrence count +
    last_confirmed_at bump; severity raised if the new level ranks higher).
    No duplicate spam per polling cycle. Returns {'id','status','deduped'}.
    """
    existing = (await system_db.execute(text("""
        select id::text as id, status::text as status, level::text as level,
               occurrence_count
        from alerts where dedup_key = :k
          and status::text in ('ACTIVE', 'ESCALATED', 'ACKNOWLEDGED',
                               'VALIDATED', 'MITIGATED')
        limit 1
    """), {"k": dedup_key})).mappings().first()

    if existing:
        aid = existing["id"]
        raise_rank = SEVERITY_RANK.get(level, 0) > SEVERITY_RANK.get(
            existing["level"], 0)
        await system_db.execute(text("""
            update alerts set
              occurrence_count = occurrence_count + 1,
              last_confirmed_at = now(),
              message = :msg,
              payload = cast(:p as jsonb)
              {level_set}
            where id = cast(:a as uuid)
        """).format(level_set=(
            ", level = cast(:lv as alert_level)" if raise_rank else "")),
            {"msg": message, "p": json.dumps(payload or {}),
             **({"lv": level} if raise_rank else {}), "a": aid})
        await add_event(system_db, aid,
                        stage=0, event_type="UPDATED",
                        reason="CONDITION_PERSISTS",
                        detail={"occurrence": int(existing["occurrence_count"]) + 1})
        return {"id": aid, "status": existing["status"], "deduped": True}

    created = await create_alert(
        system_db, level=level, alert_type=alert_type, title=title,
        message=message, state_code=state_code, district_code=district_code,
        segment_id=segment_id, shipment_id=shipment_id, payload=payload)
    await system_db.execute(text("""
        update alerts set dedup_key = :k, hazard = :hz,
                          condition_fingerprint = :fp, last_confirmed_at = now()
        where id = cast(:a as uuid)
    """), {"k": dedup_key, "hz": hazard, "fp": fingerprint,
           "a": created["id"]})
    return {**created, "deduped": False}


async def transition(system_db: AsyncSession, alert_id: str, new_status: str,
                     user_role: str, note: str | None = None) -> dict:
    """Apply a lifecycle move (DETECTED→…→CLOSED) with machine-enforced order."""
    from app.core.errors import Conflict

    row = await _get(system_db, alert_id)
    current = row["status"]
    if not valid_transition(current, new_status):
        raise Conflict(
            f"invalid alert transition {current} -> {new_status}")
    column_map = {
        "VALIDATED": ("status = 'VALIDATED'",),
        "MITIGATED": ("status = 'MITIGATED'",),
        "CLOSED": ("status = 'CLOSED'",),
    }
    sets = list(column_map[new_status])
    await system_db.execute(text(
        f"update alerts set {', '.join(sets)} where id = cast(:a as uuid)"),
        {"a": alert_id})
    await add_event(system_db, alert_id, stage=int(row["current_stage"]),
                    event_type=new_status, actor_id=None, reason=note,
                    detail={"by_role": user_role})
    return {"id": alert_id, "previous": current, "status": new_status}


