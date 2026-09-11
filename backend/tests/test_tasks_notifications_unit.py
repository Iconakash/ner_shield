"""PHASE 7 unit tests — task lifecycle, SLA escalation logic, notification
preference gating, provider configuration gating, endpoint wiring."""
import sys as _sys
from datetime import datetime, timedelta, timezone
from pathlib import Path

BACKEND = Path(__file__).resolve().parents[1]
if str(BACKEND) not in _sys.path:
    _sys.path.insert(0, str(BACKEND))

from app.tasks import lifecycle  # noqa: E402


# ------------------------------------------------------- lifecycle whitelist
def test_happy_path_transitions_are_legal():
    path = ["CREATED", "ASSIGNED", "ACCEPTED", "IN_PROGRESS",
            "COMPLETED", "VERIFIED", "CLOSED"]
    for cur, nxt in zip(path, path[1:]):
        assert lifecycle.can_transition(cur, nxt), f"{cur}->{nxt}"


def test_blocked_and_cancel_side_states():
    assert lifecycle.can_transition("IN_PROGRESS", "BLOCKED")
    assert lifecycle.can_transition("BLOCKED", "IN_PROGRESS")
    assert lifecycle.can_transition("CREATED", "CANCELLED")
    assert not lifecycle.can_transition("CLOSED", "CREATED")
    assert not lifecycle.can_transition("COMPLETED", "CLOSED")  # must verify
    assert not lifecycle.can_transition("VERIFIED", "IN_PROGRESS")


def test_verification_cannot_be_done_by_assignee():
    perms = {"APPROVE_REROUTE"}
    # assignee completing is legal...
    assert lifecycle.actor_may_set(perms, "IN_PROGRESS", "COMPLETED",
                                   is_assignee=True)
    # ...but service enforces four-eyes on VERIFIED (service-level check)


def test_completion_requires_doer_or_authority():
    assert lifecycle.actor_may_set(set(), "ACCEPTED", "IN_PROGRESS",
                                   is_assignee=True)
    assert lifecycle.actor_may_set({"APPROVE_REROUTE"}, "ACCEPTED",
                                   "IN_PROGRESS", is_assignee=False)
    assert not lifecycle.actor_may_set(set(), "ASSIGNED", "ACCEPTED",
                                       is_assignee=False)


# ------------------------------------------------------------------- SLA math
def test_sla_deadline_template_overrides_priority():
    now = datetime.now(timezone.utc)
    assert lifecycle.sla_deadline("CRITICAL", None, now) - now == \
        timedelta(hours=6)
    assert lifecycle.sla_deadline("LOW", 2.5, now) - now == \
        timedelta(hours=2.5)


def test_breach_detection_tz_safe():
    now = datetime.now(timezone.utc)
    assert lifecycle.is_breached(now - timedelta(minutes=1), now)
    assert not lifecycle.is_breached(now + timedelta(hours=1), now)
    naive = (now - timedelta(minutes=1)).replace(tzinfo=None)
    assert lifecycle.is_breached(naive, now)


def test_escalation_raises_one_notch_capped_at_critical():
    assert lifecycle.escalation_target_priority("MEDIUM") == "HIGH"
    assert lifecycle.escalation_target_priority("HIGH") == "CRITICAL"
    assert lifecycle.escalation_target_priority("CRITICAL") == "CRITICAL"


# ================================================= notification preference gate
from app.notifications.service import channel_allowed  # noqa: E402
from app.notifications import providers  # noqa: E402


def _prefs(channels, min_sev="LOW"):
    return {"channels": channels, "min_severity": min_sev}


def test_in_app_always_available_and_cannot_be_disabled():
    p = _prefs({"IN_APP": False})
    assert channel_allowed(p, "IN_APP", "LOW")
    assert channel_allowed(p, "IN_APP", "CRITICAL")


def test_min_severity_gates_low_priority_noise():
    p = _prefs({"EMAIL": True}, min_sev="MEDIUM")
    assert not channel_allowed(p, "EMAIL", "LOW")
    assert channel_allowed(p, "EMAIL", "MEDIUM")


def test_external_channels_require_explicit_optin_even_for_critical():
    p = _prefs({"IN_APP": True})
    assert not channel_allowed(p, "SMS", "CRITICAL")


def test_opted_channel_passes_for_high():
    p = _prefs({"SMS": True, "IN_APP": True}, min_sev="INFO")
    assert channel_allowed(p, "SMS", "HIGH")


# ------------------------------------------------------------- provider gating
def test_unconfigured_providers_report_unavailable(monkeypatch):
    for k in providers.EmailProvider.required_env:
        monkeypatch.delenv(k, raising=False)
    import pytest
    with pytest.raises(providers.ProviderUnavailable):
        providers.get_provider("EMAIL")


def test_configured_email_provider_constructs(monkeypatch):
    for k in providers.EmailProvider.required_env:
        monkeypatch.setenv(k, f"test-{k}")
    p = providers.get_provider("EMAIL")
    assert p.channel == "EMAIL"


def test_provider_registry_has_all_channels():
    assert {"IN_APP", "WEB_PUSH", "EMAIL", "SMS"} == \
        set(providers.PROVIDERS.keys())


async def test_in_app_send_succeeds_without_credentials():
    p = providers.get_provider("IN_APP")
    assert await p.send("user-x", "t", "b") == "in-app"


# ------------------------------------------------------------------ API wiring
def test_endpoints_registered_and_auth_gated():
    from fastapi.testclient import TestClient

    from app.main import create_app

    app = create_app()
    paths = app.openapi()["paths"]
    for expected in ("/api/v1/tasks", "/api/v1/tasks/mine",
                     "/api/v1/notifications",
                     "/api/v1/notifications/preferences",
                     "/api/v1/notifications/channels"):
        assert expected in paths, expected

    client = TestClient(app, raise_server_exceptions=False)
    assert client.get("/api/v1/tasks/mine").status_code == 401
    assert client.get("/api/v1/notifications").status_code == 401


def test_channels_endpoint_reports_configuration_state(monkeypatch):
    """Unconfigured external channels must be visible as such (no fake LIVE)."""
    from fastapi.testclient import TestClient

    from app.main import create_app

    for cls in (providers.WebPushProvider, providers.EmailProvider,
                providers.SmsProvider):
        for k in cls.required_env:
            monkeypatch.delenv(k, raising=False)
    client = TestClient(create_app())
    r = client.get("/api/v1/notifications/channels")
    assert r.status_code == 200
    by_id = {c["id"]: c["configured"] for c in r.json()["channels"]}
    assert by_id["IN_APP"] is True
    assert by_id["EMAIL"] is False and by_id["SMS"] is False

