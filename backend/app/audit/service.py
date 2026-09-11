"""Append-only audit emission + scoped reads (AUD-01..06, architecture §10)."""
import json
from typing import Any, Literal

from sqlalchemy import text
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.request_context import get_request_id

# Closed vocabulary (C-Audit). Callers cannot invent free-form actions.
ACTIONS = {
    "LOGIN_SUCCESS", "LOGIN_FAILURE", "LOGIN_LOCKED", "LOGOUT",
    # Token revocation emitted by /auth/logout: every previously-minted JWT
    # (incl. stolen copies) fails validation immediately after this row commits.
    "LOGOUT_TOKEN_REVOKED",
    # P0 SECURITY — chain-level revocation guard. Emitted by app/dependencies.py
    # get_principal() when a request arrives with a JWT that was minted before
    # the user's most recent revocation instant. Must NEVER crash; the
    # vocabulary was extended to avoid the 500-on-401 regression.
    "REVOKED_TOKEN_BLOCK", "TOKENS_REVOKED",
    "USER_CREATE", "USER_UPDATE", "SCOPE_GRANT", "SCOPE_REVOKE",
    "PERMISSION_DENIED", "SCOPE_DENIED", "ACCOUNT_DISABLED_BLOCK",
    "ANALYZE", "EXPORT", "POLICY_CHANGE", "APPROVAL_REQUESTED",
    "APPROVAL_DECIDED", "SECURITY_EVENT",
    # Phase 4 — logistics engine
    "SHIPMENT_CREATED", "VEHICLE_ASSIGNED", "ROUTE_ASSIGNED",
    "LOCATION_UPDATED", "STATUS_CHANGED", "ETA_CALCULATED",
    "DELIVERY_CONFIRMED",
    # Phase 8 — impact engine
    "IMPACT_ASSESSED",
    # Phase 12 — alert engine
    "ALERT_CREATED", "ALERT_ESCALATED", "ALERT_ACKNOWLEDGED", "ALERT_RESOLVED",
    # Phase 13 — field intelligence
    "REPORT_SUBMITTED", "REPORT_VALIDATED", "REPORT_REJECTED",
    # SIH26002 features (P1-P8)
    "RESPONDER_ALERTED", "RESPONSE_TASK_CREATED", "RESPONSE_TASK_UPDATED",
    "TASK_CREATE",
    "HISTORICAL_VALIDATION_RUN", "IMPACT_RECORDED",
    # Phase 21 — decision-intelligence closed-loop outcomes
    "DECISION_OUTCOME_OPENED", "DECISION_OUTCOME_UPDATED",
}


async def emit(
    db: AsyncSession,
    *,
    actor_id: str | None,
    actor_role: str | None,
    action: str,
    outcome: Literal["SUCCESS", "DENIED", "FAILURE"],
    resource_type: str | None = None,
    resource_id: str | None = None,
    detail: dict[str, Any] | None = None,
    ip: str | None = None,
) -> None:
    """Insert one audit row inside the caller's transaction. Fails => op fails."""
    if action not in ACTIONS:
        raise ValueError(f"unknown audit action {action}")  # C-Audit closed vocabulary
    await db.execute(
        text("""
            insert into audit_log
              (actor_id, actor_role, action, resource_type, resource_id,
               outcome, detail, ip, request_id)
            values (:actor, cast(:role as user_role), :action, :rtype, :rid,
                    :outcome, cast(:detail as jsonb), cast(:ip as inet), :req)
        """),
        {
            "actor": actor_id, "role": actor_role, "action": action,
            "rtype": resource_type, "rid": resource_id, "outcome": outcome,
            "detail": json.dumps(detail or {}), "ip": ip, "req": get_request_id(),
        },
    )


async def list_recent(db: AsyncSession, limit: int = 100) -> list[dict]:
    rows = (
        await db.execute(text(
            "select id, occurred_at, actor_id, actor_role, action, resource_type,"
            " resource_id, outcome, detail from audit_log"
            " order by occurred_at desc limit :l"),
            {"l": max(1, min(limit, 500))})
    ).mappings().all()
    return [dict(r) for r in rows]
