"""Phase 16 unit tests — connectivity classification + progressive gating."""
import pytest

from app.sync.service import (
    CONNECTIVITY_CLASSES, DEFAULT_SYNC_POLICY, classify_connectivity, gate_op)


REPORT = {"op_type": "FIELD_REPORT",
          "payload": {"incident_type": "FLOOD", "severity": "MEDIUM"}}
CRIT_REPORT = {"op_type": "FIELD_REPORT",
               "payload": {"incident_type": "LANDSLIDE", "severity": "CRITICAL",
                           "photo_name": "debris.jpg"}}
GPS = {"op_type": "GPS_PING", "payload": {"lon": 93.9, "lat": 24.8}}


# ---------------------------------------------------------------- classifier
@pytest.mark.parametrize("eff,online,expected", [
    ("4g", True, "EXCELLENT"), ("3g", True, "GOOD"), ("2g", True, "WEAK"),
    ("slow-2g", True, "VERY_WEAK"), (None, False, "OFFLINE"),
])
def test_classify_connectivity(eff, online, expected):
    assert classify_connectivity(eff, online) == expected


def test_five_classes_frozen():
    assert CONNECTIVITY_CLASSES == ("EXCELLENT", "GOOD", "WEAK",
                                    "VERY_WEAK", "OFFLINE")


# ---------------------------------------------------------------- gating matrix
def test_excellent_allows_everything():
    v, reason = gate_op(CRIT_REPORT, "EXCELLENT")
    assert v == "ALLOWED" and reason is None


def test_weak_defers_photos_but_keeps_text_and_gps():
    v, reason = gate_op(REPORT | {"payload": {"severity": "MEDIUM",
                                              "photo_name": "x.jpg"}},
                        "WEAK")
    assert v == "DEFERRED" and "photo" in reason

    text_only = {"op_type": "FIELD_REPORT",
                 "payload": {"incident_type": "FLOOD", "severity": "MEDIUM"}}
    assert gate_op(text_only, "WEAK")[0] == "ALLOWED"
    assert gate_op(GPS, "WEAK")[0] == "ALLOWED"


def test_very_weak_carries_gps_and_critical_reports_only():
    gps_ok = gate_op(GPS, "VERY_WEAK")
    crit_ok = gate_op({**CRIT_REPORT, "op_type": "CRITICAL_FIELD_REPORT"},
                      "VERY_WEAK")
    medium = gate_op({"op_type": "CRITICAL_FIELD_REPORT",
                      "payload": {"incident_type": "FLOOD",
                                  "severity": "MEDIUM"}}, "VERY_WEAK")
    routine = gate_op(REPORT, "VERY_WEAK")
    assert gps_ok[0] == "ALLOWED"
    assert crit_ok[0] == "ALLOWED"
    assert medium[0] == "DEFERRED"
    assert routine[0] == "DEFERRED"


def test_critical_report_photo_passes_even_on_weak_link():
    """OFF-06: CRITICAL severity overrides photo deferral."""
    v, _ = gate_op(CRIT_REPORT, "WEAK")
    assert v == "ALLOWED"


def test_offline_defers_everything():
    for op in (REPORT, GPS):
        v, reason = gate_op(op, "OFFLINE")
        assert v == "DEFERRED" and "held locally" in reason


def test_unknown_class_rejected():
    v, _ = gate_op(GPS, "5G-TURBO")
    assert v == "REJECTED"


def test_policy_matrix_covers_all_classes():
    assert set(DEFAULT_SYNC_POLICY) == set(CONNECTIVITY_CLASSES)
