"""Phase 9 unit tests — supply analytics contracts (source-example fidelity)."""
import pytest

try:
    from app.supply.service import (
        days_of_supply, demand_label, forecast_demand, recommended_action,
        shortage_probability)
except ModuleNotFoundError:
    from supply.service import (
        days_of_supply, demand_label, forecast_demand, recommended_action,
        shortage_probability)


# ---------------------------------------------------------------- days of supply
def test_days_of_supply_basic():
    assert days_of_supply(500, 0, 220) == 2.27          # source example zone
    assert days_of_supply(500, 60, 220) == 2.0          # reserved reduces cover
    assert days_of_supply(100, 200, 50) == 0.0          # over-reserved floors at 0
    assert days_of_supply(500, 0, 0) is None            # no consumption


def test_days_of_supply_capped():
    assert days_of_supply(1_000_000, 0, 0.5) == 999.0


# ---------------------------------------------------------------- demand label
@pytest.mark.parametrize("dos,label", [
    (None, "LOW"), (15.0, "LOW"), (10.0, "NORMAL"), (6.0, "MEDIUM"),
    (3.4, "HIGH"), (2.2, "HIGH"),                       # source example => HIGH
])
def test_demand_labels(dos, label):
    assert demand_label(dos) == label


def test_forecast_demand_applies_surge():
    # 220/day * (18/24) * HIGH surge 1.5 = 247.5
    assert forecast_demand(220, 18, "HIGH") == 247.5
    assert forecast_demand(220, 24, "LOW") == 176.0


# ---------------------------------------------------------------- probability
def test_probability_decreases_with_more_cover():
    probs = [shortage_probability(d, "MEDICINE", 0, 220, 18, False)
             for d in (0.5, 1.5, 2.2, 4.0, 8.0)]
    assert probs == sorted(probs, reverse=True), "must be monotonically decreasing"
    assert all(5 <= p <= 99 for p in probs)


def test_source_example_zone_is_high_risk():
    """~2.2 days medicine during disruption => HIGH shortage probability."""
    p = shortage_probability(2.2, "MEDICINE", incoming=300,
                             daily_consumption=220,
                             exposure_hours=18, disruption_context=True)
    assert p >= 60


def test_incoming_coverage_reduces_risk():
    tight = dict(days_of_supply=2.0, commodity="MEDICINE", incoming=0,
                 daily_consumption=220, exposure_hours=24,
                 disruption_context=False)
    covered = dict(tight, incoming=400)                  # covers exposure need
    assert shortage_probability(**covered) < shortage_probability(**tight)


def test_disruption_context_raises_risk():
    calm = shortage_probability(2.2, "MEDICINE", 0, 220, 18, False)
    stormy = shortage_probability(2.2, "MEDICINE", 0, 220, 18, True)
    assert stormy > calm


def test_non_critical_general_stock_is_calmer():
    gen = shortage_probability(2.2, "GENERAL", 0, 100, 18, False)
    med = shortage_probability(2.2, "MEDICINE", 0, 100, 18, False)
    assert med > gen


# ---------------------------------------------------------------- recommendations
def test_pre_position_recommendation_for_medicine_example():
    p = shortage_probability(2.2, "MEDICINE", incoming=300,
                             daily_consumption=220, exposure_hours=18,
                             disruption_context=True)
    action, qty = recommended_action(p, "MEDICINE", incoming=300)
    assert action in ("PRE_POSITION", "ACCELERATE_INCOMING")
    assert qty > 0


def test_low_risk_means_monitor_only():
    p = shortage_probability(20.0, "WATER", 0, 100, 18, False)
    action, qty = recommended_action(p, "WATER", 0)
    assert action == "MONITOR" and qty == 0
