"""Heuristic disruption predictor (AI-04 fallback + explanation source).

Deterministic rule model over the 11 features. Produces the same output contract
as the XGBoost models: five horizon percentages plus additive per-feature
contributions used as the explanation when TreeExplainer is unavailable.
"""
from .feature_spec import FEATURE_LABELS

HORIZONS = ("current", "6h", "12h", "24h", "72h")

# Exposure multipliers: risk grows ahead of the event window, peaks ~24h, decays.
HORIZON_MULTIPLIERS = {
    "current": 0.55,
    "6h": 0.90,
    "12h": 1.15,
    "24h": 1.30,
    "72h": 1.05,
}

# Rule weights (sum = 1). Provisional; calibration replaces via trained models.
RULE_WEIGHTS = {
    "rainfall_mm_24h": 0.10,
    "forecast_rainfall_mm_24h": 0.22,
    "elevation_m": 0.04,
    "slope_deg": 0.08,
    "flood_susceptibility": 0.16,
    "landslide_susceptibility": 0.16,
    "road_condition_score": 0.06,
    "historical_disruptions_12m": 0.05,
    "historical_closures_12m": 0.04,
    "traffic_index": 0.04,
    "field_report_score": 0.05,
}
# Neutral reference values: contribution = weight * (value - neutral), signed.
NEUTRALS = {
    "rainfall_mm_24h": 20.0, "forecast_rainfall_mm_24h": 20.0,
    "elevation_m": 800.0, "slope_deg": 12.0,
    "flood_susceptibility": 40.0, "landslide_susceptibility": 40.0,
    "road_condition_score": 70.0, "historical_disruptions_12m": 2.0,
    "historical_closures_12m": 1.0, "traffic_index": 45.0,
    "field_report_score": 30.0,
}


def _normalized_risk_contributions(f: dict) -> dict[str, float]:
    """Signed per-feature contributions on a 0-100 'base susceptibility' scale.

    Each feature's full practical range maps to roughly +/- its rule weight in
    percentage points, keeping the blended base inside a sane 0-100 envelope.
    """
    return {
        "rainfall_mm_24h": (f["rainfall_mm_24h"] - 20.0) / 100.0
            * RULE_WEIGHTS["rainfall_mm_24h"] * 100,
        "forecast_rainfall_mm_24h": (f["forecast_rainfall_mm_24h"] - 20.0) / 120.0
            * RULE_WEIGHTS["forecast_rainfall_mm_24h"] * 100,
        "elevation_m": (min(f["elevation_m"], 4000.0) - 800.0) / 3200.0
            * RULE_WEIGHTS["elevation_m"] * 100,
        "slope_deg": (f["slope_deg"] - 12.0) / 38.0
            * RULE_WEIGHTS["slope_deg"] * 100,
        "flood_susceptibility": (f["flood_susceptibility"] - 40.0) / 60.0
            * RULE_WEIGHTS["flood_susceptibility"] * 100,
        "landslide_susceptibility": (f["landslide_susceptibility"] - 40.0) / 60.0
            * RULE_WEIGHTS["landslide_susceptibility"] * 100,
        # adverse road condition RAISES risk => inverted goodness score
        "road_condition_score": (70.0 - f["road_condition_score"]) / 70.0
            * RULE_WEIGHTS["road_condition_score"] * 100,
        "historical_disruptions_12m": (f["historical_disruptions_12m"] - 2.0) / 10.0
            * RULE_WEIGHTS["historical_disruptions_12m"] * 100,
        "historical_closures_12m": (f["historical_closures_12m"] - 1.0) / 8.0
            * RULE_WEIGHTS["historical_closures_12m"] * 100,
        "traffic_index": (f["traffic_index"] - 45.0) / 55.0
            * RULE_WEIGHTS["traffic_index"] * 100,
        "field_report_score": (f["field_report_score"] - 30.0) / 70.0
            * RULE_WEIGHTS["field_report_score"] * 100,
    }


def predict_horizons(features: dict) -> dict:
    """Return {'horizons','top_factors','all_factors','base'}.

    base = 45 (calibrated neutral) + sum(signed contributions), clamped 0-100.
    horizon_pct = clamp(base * multiplier). all_factors is the COMPLETE signed
    local explanation vector (Phase 7); top_factors is its display slice.
    """
    contribs = _normalized_risk_contributions(features)
    base = max(0.0, min(100.0, 45.0 + sum(contribs.values())))

    horizons = {}
    for h in HORIZONS:
        horizons[h] = round(max(0.0, min(95.0, base * HORIZON_MULTIPLIERS[h])), 1)

    ranked = sorted(contribs.items(), key=lambda kv: abs(kv[1]), reverse=True)
    all_factors = [
        {"feature": k, "label": FEATURE_LABELS[k], "contribution": round(v, 2)}
        for k, v in ranked
    ]
    return {"horizons": horizons,
            "top_factors": all_factors[:5],
            "all_factors": all_factors,
            "base": round(base, 2)}
