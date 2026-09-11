"""Phase 12 unit tests — alert chains, timeouts, acknowledgment rules."""
from app.alerts.service import (
    ALERT_CHAINS, can_acknowledge, chain_for, timeout_minutes)


def test_source_mandated_chains():
    assert chain_for("ROAD_WARNING")[0] == "DISTRICT_OFFICER"
    assert chain_for("CRITICAL_SHIPMENT")[0] == "LOGISTICS_OFFICER"
    assert chain_for("REGIONAL_SUPPLY_CRISIS")[0] == "REGIONAL_AUTHORITY"


def test_escalation_always_ends_at_super_admin():
    for t, chain in ALERT_CHAINS.items():
        assert chain[-1] == "SUPER_ADMIN", f"{t} must end at SUPER_ADMIN"
        assert len(chain) == len(set(chain)), f"{t} has duplicate roles"


def test_no_chain_skips_the_middle():
    """Regional supply crisis goes to REGIONAL first, then SUPER — never DISTRICT."""
    chain = ALERT_CHAINS["REGIONAL_SUPPLY_CRISIS"]
    assert "DISTRICT_OFFICER" not in chain
    assert "LOGISTICS_OFFICER" not in chain


def test_timeouts_severity_ordered_and_info_never_escalates():
    assert timeout_minutes("INFO") is None
    assert timeout_minutes("CRITICAL") < timeout_minutes("HIGH")
    assert timeout_minutes("HIGH") < timeout_minutes("WARNING")


def test_ack_rules_current_role_only_or_super():
    assert can_acknowledge("DISTRICT_OFFICER", "DISTRICT_OFFICER")
    assert not can_acknowledge("REGIONAL_AUTHORITY", "DISTRICT_OFFICER")
    assert can_acknowledge("ANY_ROLE", "WHOEVER", is_super=True)
