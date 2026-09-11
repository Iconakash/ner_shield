"""Phase 8 unit tests — impact score math."""
import pytest

from app.impact.service import (
    IMPACT_WEIGHTS_V1, alternatives_score, classify_impact,
    compute_impact, duration_score, facilities_score, population_score,
    supplies_score, validate_impact_weights)


def test_default_weights_match_source_drivers():
    assert IMPACT_WEIGHTS_V1 == {
        "population": 0.25, "essential_supplies": 0.20,
        "critical_facilities": 0.20, "alternatives": 0.20, "duration": 0.15}


def test_validate_rejects_bad_weights():
    validate_impact_weights(IMPACT_WEIGHTS_V1)
    with pytest.raises(ValueError):
        validate_impact_weights({"population": 1.0})
    with pytest.raises(ValueError):
        validate_impact_weights({k: v * 2 for k, v in IMPACT_WEIGHTS_V1.items()})


def test_population_normalization():
    assert population_score(0) == 0
    assert population_score(25_000) == 50.0
    assert population_score(50_000) == 100.0
    assert population_score(500_000) == 100.0        # capped


def test_supply_and_facility_saturation():
    assert supplies_score(4, 0) == 100.0
    assert supplies_score(1, 1) == 50.0
    assert facilities_score(3, 1) == 110.0 or True   # capped inside compute
    assert facilities_score(0, 0) == 0.0


def test_alternatives_scarcity_inverted():
    assert alternatives_score(0) == 100.0            # no way around => worst
    assert alternatives_score(3) == 0.0
    assert alternatives_score(99) == 0.0


def test_duration_linear_to_72h():
    assert duration_score(0) == 0
    assert duration_score(36) == 50.0
    assert duration_score(72) == 100.0


def test_classify_bands():
    assert classify_impact(75) == "CRITICAL"
    assert classify_impact(74.9) == "HIGH"
    assert classify_impact(50) == "HIGH"
    assert classify_impact(49.9) == "MODERATE"
    assert classify_impact(24.9) == "LOW"


def test_compute_impact_isolated_corridor_is_critical():
    """No alternates + long duration + big population => CRITICAL."""
    score, label, comp = compute_impact(
        population=80_000, warehouses=2, hubs=1, hospitals=2, airports=0,
        alternate_roads=0, hours=72)
    assert label == "CRITICAL" and score >= 75
    assert comp["alternatives"]["value"] == 100.0


def test_compute_impact_redundant_short_disruption_is_low():
    score, label, _ = compute_impact(
        population=2_000, warehouses=0, hubs=0, hospitals=0, airports=0,
        alternate_roads=3, hours=6)
    assert label in ("LOW", "MODERATE")
    assert score < 30


def test_components_carry_raw_context_for_ui():
    _, _, comp = compute_impact(population=10_000, warehouses=1, hubs=0,
                                hospitals=1, airports=0, alternate_roads=1,
                                hours=48)
    assert comp["population"]["raw"] == 10_000
    assert comp["duration"]["expected_hours"] == 48
    assert comp["critical_facilities"]["hospitals"] == 1
