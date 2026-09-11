"""Phase 7 unit tests — explainable-AI contracts."""

try:
    from backend.ml.heuristic import predict_horizons
    from backend.ml.feature_spec import FEATURE_ORDER
except ModuleNotFoundError:
    from ml.heuristic import predict_horizons
    from ml.feature_spec import FEATURE_ORDER

from app.risk.service import build_summary, summarize_route


STORMY = {
    "rainfall_mm_24h": 95, "forecast_rainfall_mm_24h": 150,
    "elevation_m": 2800, "slope_deg": 30,
    "flood_susceptibility": 55, "landslide_susceptibility": 80,
    "road_condition_score": 45, "historical_disruptions_12m": 4,
    "historical_closures_12m": 3, "traffic_index": 70,
    "field_report_score": 65,
}


def test_all_factors_covers_every_feature_sorted_by_magnitude():
    out = predict_horizons(STORMY)
    all_f = out["all_factors"]
    assert [f["feature"] for f in all_f] and len(all_f) == len(FEATURE_ORDER)
    mags = [abs(f["contribution"]) for f in all_f]
    assert mags == sorted(mags, reverse=True), "all_factors must be magnitude-sorted"
    # top_factors is the display slice of the same vector
    assert all_f[:5] == out["top_factors"]


def test_contributions_reconstruct_the_clamped_score():
    out = predict_horizons(STORMY)
    total = sum(f["contribution"] for f in out["all_factors"])
    raw_base = 45.0 + total
    assert out["base"] == round(max(0.0, min(100.0, raw_base)), 2)


def test_storm_profile_explains_with_weather_first():
    out = predict_horizons(STORMY)
    top = {f["feature"] for f in out["top_factors"]}
    assert {"forecast_rainfall_mm_24h"} & top, \
        "storm profile must attribute to forecast rainfall"


def test_build_summary_sentence_shape():
    factors = [{"feature": "forecast_rainfall_mm_24h", "contribution": 31.2},
               {"feature": "slope_deg", "contribution": 26.0}]
    s = build_summary("NH-02", "Imphal East", "HIGH", 86.0, "24h", factors)
    assert s.startswith("HIGH disruption risk on NH-02 near Imphal East")
    assert "86%" in s and "24h" in s
    assert "heavy forecast rainfall" in s and "steep slope exposure" in s


# ---------------------------------------------------------------- route aggregation
def _seg(seq, risk, label, district="Imphal East", factors=None):
    return {"seq": seq, "road_code": "NH-02", "district_name": district,
            "district_code": "IN-MN-IE", "risk_pct": risk,
            "overall_label": label, "acc_classification": "CAUTION",
            "all_factors": factors or [
                {"feature": "forecast_rainfall_mm_24h",
                 "label": "Forecast rainfall (next 24h)", "contribution": 30.0}]}


def test_route_verdict_high_when_any_segment_critical_risk():
    rows = [_seg(1, 40, "ELEVATED"), _seg(2, 86, "HIGH")]
    res = summarize_route(rows)
    assert res["verdict"] == "HIGH"
    assert res["segments_assessed"] == 2
    assert res["percent_failing"] == 50.0     # one of two segments failing
    assert res["worst_segment"]["risk_pct"] == 86
    assert "should NOT be used" in res["narrative"]
    assert res["aggregated_drivers"][0]["label"].startswith("Forecast rainfall")


def test_route_passable_when_all_low():
    rows = [_seg(1, 10, "LOW"), _seg(2, 14, "LOW")]
    res = summarize_route(rows)
    assert res["verdict"] == "LOW"
    assert "should NOT be used" not in res["narrative"]


def test_empty_route_handled():
    res = summarize_route([])
    assert res["verdict"] == "PASSABLE"
