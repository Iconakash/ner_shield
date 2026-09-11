"""Task lifecycle contracts — PURE, unit-tested without infra.

CREATED → ASSIGNED → ACCEPTED → IN_PROGRESS → COMPLETED → VERIFIED → CLOSED
with BLOCKED and CANCELLED side-states. Transitions are whitelisted; anything
else is a programming error or an unauthorized attempt.
"""
from datetime import timedelta
from typing import Literal

TaskStatus = Literal["CREATED", "ASSIGNED", "ACCEPTED", "IN_PROGRESS",
                     "BLOCKED", "COMPLETED", "VERIFIED", "CLOSED", "CANCELLED"]

LEGAL_TRANSITIONS: dict[str, tuple[str, ...]] = {
    "CREATED":     ("ASSIGNED", "CANCELLED"),
    "ASSIGNED":    ("ACCEPTED", "IN_PROGRESS",        # accept-or-auto-start policy
                    "ASSIGNED",                        # reassignment
                    "CANCELLED"),
    "ACCEPTED":    ("IN_PROGRESS", "BLOCKED"),
    "IN_PROGRESS": ("BLOCKED", "COMPLETED"),
    "BLOCKED":     ("IN_PROGRESS", "CANCELLED"),
    "COMPLETED":   ("VERIFIED", "IN_PROGRESS"),       # verification may reject
    "VERIFIED":    ("CLOSED",),
    "CLOSED":      (),
    "CANCELLED":   (),
}

# Statuses allowed to be set by the ASSIGNEE vs by an AUTHORIZER.
ASSIGNEE_TRANSITIONS = {"ACCEPTED", "IN_PROGRESS", "BLOCKED", "COMPLETED"}
AUTHORIZER_TRANSITIONS = {"ASSIGNED", "VERIFIED", "CLOSED", "CANCELLED"}

CRITICAL_PRIORITIES = {"HIGH", "CRITICAL"}
DEFAULT_SLA_HOURS = {"LOW": 72.0, "MEDIUM": 36.0, "HIGH": 12.0, "CRITICAL": 6.0}


def can_transition(current: str, target: str) -> bool:
    return target in LEGAL_TRANSITIONS.get(current, ())


def actor_may_set(actor_permissions: set[str], current: str, target: str,
                  is_assignee: bool) -> bool:
    """Permission + role-of-actor gate for one transition."""
    if not can_transition(current, target):
        return False
    if target in AUTHORIZER_TRANSITIONS:
        # verification/closure requires explicit authority; assignment needs
        # MODIFY_SHIPMENT-grade authority delegated to task managers
        return "APPROVE_REROUTE" in actor_permissions
    if target == "ACCEPTED" and not is_assignee:
        return False                      # only the assignee accepts work
    if target == "COMPLETED":
        return is_assignee                # only the doer completes...
    if target in ASSIGNEE_TRANSITIONS:
        return is_assignee or "APPROVE_REROUTE" in actor_permissions
    return False


def sla_deadline(priority: str, template_hours: float | None,
                 from_dt) -> object:
    """SLA clock: template overrides priority default."""
    hours = template_hours if template_hours else \
        DEFAULT_SLA_HOURS.get(priority.upper(), 36.0)
    return from_dt + timedelta(hours=float(hours))


def is_breached(due_at, now) -> bool:
    if due_at is None:
        return False
    if hasattr(due_at, "tzinfo") and due_at.tzinfo is None:
        return now.replace(tzinfo=None) > due_at
    return now > due_at


def escalation_target_priority(priority: str) -> str:
    """Escalation raises severity one notch (capped at CRITICAL)."""
    ladder = ["LOW", "MEDIUM", "HIGH", "CRITICAL"]
    i = ladder.index(priority.upper()) if priority.upper() in ladder else 1
    return ladder[min(i + 1, len(ladder) - 1)]
