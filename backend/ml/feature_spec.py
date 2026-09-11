"""Frozen feature specification — the 11 source-mandated features.

Order IS the model contract: artifacts trained against this list must receive
vectors in exactly this order (AI-02 feature_spec.json mirrors it).
"""

FEATURE_ORDER = [
    "rainfall_mm_24h",
    "forecast_rainfall_mm_24h",
    "elevation_m",
    "slope_deg",
    "flood_susceptibility",
    "landslide_susceptibility",
    "road_condition_score",
    "historical_disruptions_12m",
    "historical_closures_12m",
    "traffic_index",
    "field_report_score",
]

FEATURE_LABELS = {
    "rainfall_mm_24h": "Rainfall (24h)",
    "forecast_rainfall_mm_24h": "Forecast rainfall (next 24h)",
    "elevation_m": "Elevation",
    "slope_deg": "Slope",
    "flood_susceptibility": "Flood susceptibility",
    "landslide_susceptibility": "Landslide susceptibility",
    "road_condition_score": "Road condition",
    "historical_disruptions_12m": "Historical disruptions (12m)",
    "historical_closures_12m": "Historical closures (12m)",
    "traffic_index": "Traffic load",
    "field_report_score": "Recent field reports",
}

# Plausible operating ranges for clamping/sanitizing raw inputs.
FEATURE_RANGES = {
    "rainfall_mm_24h": (0.0, 500.0),
    "forecast_rainfall_mm_24h": (0.0, 500.0),
    "elevation_m": (0.0, 5000.0),
    "slope_deg": (0.0, 90.0),
    "flood_susceptibility": (0, 100),
    "landslide_susceptibility": (0, 100),
    "road_condition_score": (0, 100),
    "historical_disruptions_12m": (0, 50),
    "historical_closures_12m": (0, 50),
    "traffic_index": (0, 100),
    "field_report_score": (0, 100),
}

NEUTRAL_FEATURE_DEFAULTS = {
    "rainfall_mm_24h": 0.0,
    "forecast_rainfall_mm_24h": 0.0,
    "elevation_m": 800.0,
    "slope_deg": 10.0,
    "flood_susceptibility": 40,
    "landslide_susceptibility": 40,
    "road_condition_score": 70,
    "historical_disruptions_12m": 0,
    "historical_closures_12m": 0,
    "traffic_index": 45,
    "field_report_score": 30,
}


def sanitize_features(raw: dict) -> dict:
    """Clamp to ranges and fill missing features with neutral defaults."""
    out = {}
    for name in FEATURE_ORDER:
        lo, hi = FEATURE_RANGES[name]
        value = raw.get(name, NEUTRAL_FEATURE_DEFAULTS[name])
        try:
            value = float(value)
        except (TypeError, ValueError):
            value = float(NEUTRAL_FEATURE_DEFAULTS[name])
        out[name] = max(lo, min(hi, value))
    return out


def to_vector(sanitized: dict) -> list[float]:
    return [float(sanitized[name]) for name in FEATURE_ORDER]
