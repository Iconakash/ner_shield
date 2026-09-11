"""PHASE 8 unit tests — ML registry governance rules, PSI drift metric,
feature hashing, satellite scene schema. Pure, no infra."""
import sys as _sys
from pathlib import Path

import pytest

BACKEND = Path(__file__).resolve().parents[1]
if str(BACKEND) not in _sys.path:
    _sys.path.insert(0, str(BACKEND))

from ml.drift import classify, psi  # noqa: E402
from ml.registry import feature_hash, promotion_allowed  # noqa: E402


# ------------------------------------------------------- promotion governance
def test_demo_cannot_jump_to_production():
    ok, reason = promotion_allowed("DEMO", "PRODUCTION")
    assert not ok and "VALIDATION" in reason


def test_validation_to_production_requires_evaluations():
    ok, _ = promotion_allowed("VALIDATION", "PRODUCTION",
                              has_evaluations=False)
    assert not ok
    ok, _ = promotion_allowed("VALIDATION", "PRODUCTION",
                              has_evaluations=True)
    assert ok


def test_full_lifecycle_path_is_legal():
    steps = [("DEMO", "VALIDATION", False),          # to validation: no evals needed
             ("VALIDATION", "PRODUCTION", True)]     # production: evals required
    for frm, to, ev in steps:
        ok, reason = promotion_allowed(frm, to, has_evaluations=ev)
        assert ok, reason


def test_demotions_forbidden_except_retirement():
    assert not promotion_allowed("PRODUCTION", "DEMO")[0]
    assert not promotion_allowed("VALIDATION", "DEMO")[0]
    ok, _ = promotion_allowed("PRODUCTION", "RETIRED")
    assert ok


def test_unknown_stages_rejected():
    assert not promotion_allowed("CHAOS", "PRODUCTION")[0]
    assert not promotion_allowed("DEMO", "DEMO")[0]


# ------------------------------------------------------------------ PSI drift
def test_psi_identical_distributions_near_zero():
    ref = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10] * 10
    assert psi(ref, list(ref)) < 0.01


def test_psi_detects_shifted_distribution():
    ref = list(range(100))
    live = [v + 60 for v in range(100)]
    assert psi(ref, live) > 0.25


def test_psi_class_bands_match_standard_thresholds():
    assert classify(0.02) == "STABLE"
    assert classify(0.15) == "MONITOR"
    assert classify(0.40) == "DRIFT"
def test_psi_degenerate_inputs_safe():
    assert psi([], [1, 2]) == 0.0
    assert psi([1, 1], []) == 0.0
    assert psi([5, 5, 5], [5, 5, 5]) == 0.0        # constant == constant


# ----------------------------------- Phase 9 §9.6 — prediction & performance drift
def test_prediction_drift_stable_when_distributions_match():
    from ml.drift import prediction_drift
    ref = [10, 20, 30, 40, 50] * 20
    live = [10, 20, 30, 40, 50] * 20
    d = prediction_drift(ref, live)
    assert d["class"] == "STABLE"
    assert d["reference_mean"] == d["live_mean"]


def test_prediction_drift_detects_shifted_output():
    from ml.drift import prediction_drift
    ref = [10, 15, 20, 25, 30] * 20      # low-risk period
    live = [60, 70, 80, 90, 100] * 20     # model now scores much higher
    d = prediction_drift(ref, live)
    assert d["class"] == "DRIFT"
    assert d["live_mean"] > d["reference_mean"]


def test_performance_degradation_flags_drop():
    from ml.drift import performance_degradation
    d = performance_degradation(recent_accuracy=0.70,
                                validation_accuracy=0.85)
    assert d["degraded"] is True
    assert abs(d["drop"] - 0.15) < 1e-9


def test_performance_degradation_ok_when_stable():
    from ml.drift import performance_degradation
    d = performance_degradation(recent_accuracy=0.84,
                                validation_accuracy=0.85,
                                drop_threshold=0.05)
    assert d["degraded"] is False


def test_psi_degenerate_inputs_safe():
    assert psi([], [1, 2]) == 0.0
    assert psi([1, 1], []) == 0.0
    assert psi([5, 5, 5], [5, 5, 5]) == 0.0        # constant == constant


# -------------------------------------------------------------- feature hash
def test_feature_hash_is_order_insensitive_and_content_bound():
    a = feature_hash({"rainfall": 10, "slope": 30})
    b = feature_hash({"slope": 30, "rainfall": 10})
    c = feature_hash({"rainfall": 11, "slope": 30})
    assert a == b and a != c


# ---------------------------------------------------------- satellite schemas
def test_satellite_scene_normalization_and_metadata_only_rule():
    from integrations.satellite.adapter import DEFAULT_CONFIG, SatelliteAdapter

    a = SatelliteAdapter(DEFAULT_CONFIG.model_copy(
        update={"enabled": True, "endpoint": "http://x"}))
    rec = {"external_id": "SC-1", "provider": "prov",
           "acquired_at": "2026-08-20T05:00:00Z",
           "coverage_bbox": [88.0, 21.5, 97.5, 29.9],
           "resolution_m": 10.0, "cloud_cover_pct": 12.5,
           "storage_path": "s3://bucket/scenes/SC-1.tif"}
    out = a.normalize(rec)
    assert out["storage_path"].startswith("s3://")   # object storage reference

    with pytest.raises(Exception):
        a.normalize({"external_id": "SC-2"})          # missing acquisition time


def test_satellite_defaults_ship_disabled_pending_authorization():
    from integrations.satellite.adapter import DEFAULT_CONFIG as CFG
    assert CFG.enabled is False and CFG.endpoint is None


# --------------------------------------------- risk engine registry gate shape
async def test_prediction_pass_labels_model_mode(monkeypatch):
    """run_prediction_pass must expose which mode actually served."""

    from app.risk import service as risk_svc

    async def fake_features(db):
        return [{"segment_id": "s1", "road_code": "R1", "district_code": None}]

    inserted = {}

    async def fake_persist(db, results):
        inserted["n"] = len(results)
        return len(results)

    monkeypatch.setattr(risk_svc, "build_feature_rows", fake_features)

    async def fake_sleep(*a, **k):
        return None

    class _R:
        @staticmethod
        async def active_production_artifact(db, name):
            return None                      # no approved PRODUCTION model

        record_prediction = staticmethod(fake_sleep)
        link_evidence = staticmethod(fake_sleep)

    monkeypatch.setattr(risk_svc, "_ml_registry", _R)
    monkeypatch.setattr(risk_svc, "persist_predictions", fake_persist)
    out = await risk_svc.run_prediction_pass(None)
    assert out["model_mode"] == "heuristic"      # synthetic bundle NOT used
    assert inserted["n"] == 1
