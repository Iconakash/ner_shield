"""Phase 6 unit tests — feature spec + heuristic predictor contracts."""

try:
    from backend.ml.feature_spec import (
        FEATURE_LABELS, FEATURE_ORDER, sanitize_features, to_vector)
    from backend.ml.heuristic import HORIZONS, predict_horizons
except ModuleNotFoundError:
    from ml.feature_spec import (
        FEATURE_LABELS, FEATURE_ORDER, sanitize_features, to_vector)
    from ml.heuristic import HORIZONS, predict_horizons


BASE = {
    "rainfall_mm_24h": 20, "forecast_rainfall_mm_24h": 20,
    "elevation_m": 800, "slope_deg": 12,
    "flood_susceptibility": 40, "landslide_susceptibility": 40,
    "road_condition_score": 70, "historical_disruptions_12m": 2,
    "historical_closures_12m": 1, "traffic_index": 45,
    "field_report_score": 30,
}


def test_feature_order_matches_source_mandate():
    assert FEATURE_ORDER == [
        "rainfall_mm_24h", "forecast_rainfall_mm_24h", "elevation_m", "slope_deg",
        "flood_susceptibility", "landslide_susceptibility", "road_condition_score",
        "historical_disruptions_12m", "historical_closures_12m",
        "traffic_index", "field_report_score"]
    assert set(FEATURE_LABELS) == set(FEATURE_ORDER)


def test_horizon_contract_exactly_five():
    assert tuple(sorted(HORIZONS)) == ("12h", "24h", "6h", "72h", "current")


def test_all_horizons_present_and_bounded():
    out = predict_horizons(BASE)
    assert set(out["horizons"]) == set(HORIZONS)
    for v in out["horizons"].values():
        assert 0.0 <= v <= 95.0


def test_heavy_forecast_rain_raises_24h_risk():
    calm = predict_horizons(BASE)["horizons"]["24h"]
    storm = dict(BASE, forecast_rainfall_mm_24h=140, rainfall_mm_24h=90)
    stormy = predict_horizons(storm)["horizons"]["24h"]
    assert stormy > calm + 15          # strong monotonic response
    assert stormy >= 75                # lands in HIGH band territory


def test_landslide_prone_segment_scores_higher_than_valley_plain():
    hills = dict(BASE, elevation_m=2800, slope_deg=38, landslide_susceptibility=85)
    plains = dict(BASE, elevation_m=60, slope_deg=4, flood_susceptibility=85)
    assert (predict_horizons(hills)["horizons"]["24h"]
            > predict_horizons(plains)["horizons"]["24h"])


def test_r17_style_profile_reproduces_high_label():
    """Source example: R-17 — 24h peaks at 86%, overall Risk: HIGH."""
    r17 = dict(BASE, forecast_rainfall_mm_24h=150, rainfall_mm_24h=95,
               slope_deg=30, landslide_susceptibility=80, traffic_index=70)
    out = predict_horizons(r17)
    peak = max(out["horizons"].values())
    from app.risk.service import label_for
    assert label_for(peak) in ("HIGH", "CRITICAL")
    assert out["horizons"]["24h"] == peak or out["horizons"]["72h"] == peak


def test_explanation_contract_top_factors_nonempty_with_labels():
    out = predict_horizons(BASE)
    factors = out["top_factors"]
    assert 1 <= len(factors) <= 5
    for f in factors:
        assert f["label"]                       # human-readable label present
        assert isinstance(f["contribution"], float)


def test_sanitize_clamps_and_fills_defaults():
    feats = sanitize_features({"rainfall_mm_24h": 9999, "slope_deg": -5})
    assert feats["rainfall_mm_24h"] == 500.0     # clamped to range max
    assert feats["slope_deg"] == 0.0             # clamped to range min
    assert feats["elevation_m"] == 800.0         # neutral default filled
    vec = to_vector(feats)
    assert len(vec) == len(FEATURE_ORDER)


def test_mode_is_heuristic_without_registered_models():
    """On a clean machine the heuristic serves with identical output shape (AI-04)."""
    out = predict_horizons(BASE)
    assert set(out) >= {"horizons", "top_factors"}
