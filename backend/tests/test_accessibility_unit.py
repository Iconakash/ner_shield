"""Phase 5 unit tests — accessibility score math and classification bands."""
import pytest

from app.accessibility.service import (
    DEFAULT_BANDS, DEFAULT_WEIGHTS, FACTOR_KEYS, classify, compute_score,
    validate_bands, validate_weights)


def test_default_weights_match_source_specification():
    assert DEFAULT_WEIGHTS == {
        "infrastructure": 0.20, "weather": 0.15, "flood_risk": 0.20,
        "landslide_risk": 0.20, "traffic": 0.10, "historical_reliability": 0.15}


def test_validate_weights_accepts_source_weights():
    validate_weights(DEFAULT_WEIGHTS)  # must not raise


@pytest.mark.parametrize("bad", [
    {"infrastructure": 0.5},                                   # missing keys
    {**DEFAULT_WEIGHTS, "traffic": 0.5},                       # sums to 1.4
    {**DEFAULT_WEIGHTS, "weather": -0.1},                      # negative
    {**{k: v / 1.0 for k, v in DEFAULT_WEIGHTS.items()}, "extra": 0.0},
])
def test_invalid_weights_rejected(bad):
    with pytest.raises(ValueError):
        validate_weights({k: float(v) for k, v in bad.items()}
                         if set(bad) == set(FACTOR_KEYS) else bad)


def test_compute_score_full_components():
    values = {k: 80.0 for k in FACTOR_KEYS}
    score, breakdown = compute_score(values, DEFAULT_WEIGHTS)
    assert score == 80.0
    assert breakdown["infrastructure"]["assumed"] is False
    assert abs(sum(b["contribution"] for b in breakdown.values()) - score) < 0.01


def test_missing_factors_are_assumed_neutral_and_flagged():
    score, breakdown = compute_score({"infrastructure": 85.0}, DEFAULT_WEIGHTS)
    assert breakdown["infrastructure"]["assumed"] is False
    for key in ("weather", "flood_risk", "landslide_risk", "traffic",
                "historical_reliability"):
        assert breakdown[key]["assumed"] is True
        assert breakdown[key]["value"] == 55.0
    # 85*0.20 + 55*0.80 = 17 + 44 = 61
    assert score == 61.0


def test_score_clamped_to_0_100():
    score, _ = compute_score({k: 100 for k in FACTOR_KEYS}, DEFAULT_WEIGHTS)
    assert score == 100.0
    score, _ = compute_score({k: 0 for k in FACTOR_KEYS}, DEFAULT_WEIGHTS)
    assert score == 0.0


# ------------------------------------------------------------------ classification
@pytest.mark.parametrize("score,label", [
    (100, "SAFE"), (80, "SAFE"), (79.99, "CAUTION"), (60, "CAUTION"),
    (59.99, "HIGH_RISK"), (40, "HIGH_RISK"), (39.99, "CRITICAL"), (0, "CRITICAL"),
])
def test_classification_bands_exact(score, label):
    assert classify(score) == label


def test_bands_validation_rejects_drift():
    validate_bands(DEFAULT_BANDS)                       # frozen thresholds ok
    bad = [{"min": 70, "label": "SAFE"},
           {"min": 60, "label": "CAUTION"}, {"min": 40, "label": "HIGH_RISK"},
           {"min": 0, "label": "CRITICAL"}]
    with pytest.raises(ValueError):
        validate_bands(bad)                             # threshold drift rejected
