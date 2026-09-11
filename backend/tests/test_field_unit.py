"""Phase 13/14 unit tests — field report confidence model v2."""
import pytest

from app.field.service import (
    CLOSING_TYPES, SEVERITY_ALERT_LEVEL, SEVERITY_VALUE, SIGNAL_MAP,
    compute_confidence)


def test_signal_map_covers_all_six_types():
    for t in ("LANDSLIDE", "FLOOD", "ROAD_DAMAGE", "TRAFFIC_BLOCKAGE",
              "BRIDGE_PROBLEM", "OTHER"):
        assert t in SIGNAL_MAP
    assert SIGNAL_MAP["OTHER"] is None            # OTHER carries no factor signal


def test_structural_failures_close_segments():
    assert {"LANDSLIDE", "FLOOD", "BRIDGE_PROBLEM"} <= CLOSING_TYPES
    assert not {"TRAFFIC_BLOCKAGE", "ROAD_DAMAGE"} & CLOSING_TYPES


def test_severity_maps_to_signal_value_and_alert_level():
    assert SEVERITY_VALUE["CRITICAL"] == 92
    assert SEVERITY_ALERT_LEVEL == {
        "LOW": "INFO", "MEDIUM": "WARNING",
        "HIGH": "HIGH", "CRITICAL": "CRITICAL"}


# ------------------------------------------------- confidence model v2
def _conf(**overrides):
    kwargs = dict(has_photo=True, severity="CRITICAL",
                  snap_distance_m=200.0, in_modeled_area=True,
                  gps_accuracy_m=8.0, observed_age_hours=1.0,
                  reporter_role="FIELD_OFFICER", corroborating_reports=0)
    kwargs.update(overrides)
    return compute_confidence(**kwargs)


def test_full_quality_report_scores_85():
    score, breakdown = _conf()
    assert score == 85.0                          # everything good, no corroboration
    assert all(breakdown[k]["points"] > 0
               for k in ("gps_validity", "timestamp_freshness", "photo",
                         "reporter_role_trust", "road_proximity",
                         "modeled_area"))


def test_corroboration_pushes_past_solo_ceiling():
    solo, _ = _conf()
    one, b1 = _conf(corroborating_reports=1)
    three, _ = _conf(corroborating_reports=3)
    assert one == pytest.approx(solo + 5.0)
    assert three == pytest.approx(min(100.0, solo + 10.0))
    assert b1["corroboration"]["independent_reports"] == 1


def test_source_example_87_percent_shape():
    """GPS ±20m (12) + fresh (10) + photo (15) + sev (10) + role (10)
       + on-road (20) + area (5) + one corroboration (+5) = 87."""
    score, breakdown = compute_confidence(
        has_photo=True, severity="HIGH", snap_distance_m=400.0,
        in_modeled_area=True, gps_accuracy_m=20.0,
        observed_age_hours=2.0, reporter_role="FIELD_OFFICER",
        corroborating_reports=1)
    assert score == 87.0
    assert breakdown["corroboration"]["points"] == 5.0


def test_unknown_gps_and_stale_report_score_low():
    score, breakdown = compute_confidence(
        has_photo=False, severity="LOW", snap_distance_m=None,
        in_modeled_area=False, gps_accuracy_m=500.0,
        observed_age_hours=96.0, reporter_role="ANALYST_VIEWER",
        corroborating_reports=0)
    # gps 0 + ts 0 + photo 0 + sev 4 + role 5 + road 0 + area 0 + corr 0
    assert score == 9.0
    assert breakdown["timestamp_freshness"]["note"].startswith("stale")


def test_role_trust_ordering():
    field, _ = compute_confidence(has_photo=False, severity="LOW",
                                  snap_distance_m=None, in_modeled_area=True,
                                  reporter_role="FIELD_OFFICER")
    analyst, _ = compute_confidence(has_photo=False, severity="LOW",
                                    snap_distance_m=None, in_modeled_area=True,
                                    reporter_role="ANALYST_VIEWER")
    assert field > analyst                        # trusted reporter role wins


def test_every_breakdown_component_present_with_max():
    _, breakdown = _conf()
    expected = {"gps_validity", "timestamp_freshness", "photo",
                "severity_weight", "reporter_role_trust", "road_proximity",
                "modeled_area", "corroboration", "total"}
    assert set(breakdown) == expected
