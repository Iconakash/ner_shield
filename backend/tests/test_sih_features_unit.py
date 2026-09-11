"""SIH26002 P1-P8 unit tests (pure logic, no infra).

Covers: photo-path minting, reporter trust math + confidence integration,
responder task transitions, historical replay/metrics honesty, route health
scoring + trend, impact estimators, and Meitei catalog parity.
"""
import sys as _sys
from pathlib import Path

import pytest

BACKEND = Path(__file__).resolve().parents[1]
if str(BACKEND) not in _sys.path:
    _sys.path.insert(0, str(BACKEND))


# ------------------------------------------------------------------- P1 media
def test_storage_path_is_server_minted_and_traversal_proof():
    from app.media.service import mint_storage_path

    p = mint_storage_path("11111111-2222-3333-4444-555555555555", "jpg")
    assert p.startswith("field-reports/11111111-2222-3333-4444-555555555555/")
    assert p.endswith(".jpg") and ".." not in p and "/" not in p.rsplit(
        "/", 1)[-1].rsplit(".", 1)[0]
    # two calls never collide (uuid path segment)
    assert p != mint_storage_path("11111111-2222-3333-4444-555555555555",
                                  "jpg")


def test_upload_validation_rejects_bad_types_and_sizes():
    from app.core.uploads import UploadRejected, validate_upload

    png_magic = b"\x89PNG\r\n\x1a\n" + b"0" * 64
    name, kind = validate_upload(filename="cam.png",
                                 content_type="image/png", data=png_magic)
    assert kind == "png" and name.endswith(".png")
    with pytest.raises(UploadRejected):
        validate_upload(filename="evil.exe", content_type="image/png",
                        data=png_magic)
    with pytest.raises(UploadRejected):          # magic bytes contradict type
        validate_upload(filename="faked.jpg", content_type="image/jpeg",
                        data=png_magic)
    with pytest.raises(UploadRejected):
        validate_upload(filename="big.png", content_type="image/png",
                        data=b"\x89PNG\r\n\x1a\n" + b"0" * 20_485_760)


# --------------------------------------------------------------- P2 trust
def test_new_reporter_starts_neutral_not_zero_or_hundred():
    from app.field.service import trust_score

    t = trust_score(0, 0)
    assert 40 <= t["trust_score"] <= 80 and t["cold_start"] is True
    perfect = trust_score(42, 0)
    bad = trust_score(0, 10)
    assert 0 < perfect["trust_score"] < 100      # smoothing: never 100
    assert 0 < bad["trust_score"] < 100          # never 0 either
    assert perfect["trust_score"] > bad["trust_score"]


def test_reporter_history_component_is_additive_only():
    from app.field.service import compute_confidence

    base_score, base = compute_confidence(
        has_photo=True, severity="HIGH", snap_distance_m=200,
        in_modeled_area=True, gps_accuracy_m=8,
        reporter_role="FIELD_OFFICER", corroborating_reports=2)
    boosted, boosted_bd = compute_confidence(
        has_photo=True, severity="HIGH", snap_distance_m=200,
        in_modeled_area=True, gps_accuracy_m=8,
        reporter_role="FIELD_OFFICER", corroborating_reports=2,
        reporter_trust_score=95.0)
    assert "reporter_history" not in base            # legacy shape unchanged
    assert boosted == min(100.0, base_score + 4.8)   # 95% of max 5 pts
    assert boosted_bd["reporter_history"]["max"] == 5


# -------------------------------------------------------------- P3 responders
def test_response_task_transitions_are_enforced():
    from app.responders.service import next_status_is_valid as ok

    assert ok("PENDING", "ACKNOWLEDGED")
    assert ok("ACKNOWLEDGED", "DISPATCHED")
    assert ok("DISPATCHED", "ON_SITE")
    assert ok("ON_SITE", "RESOLVED")
    for bad in (("PENDING", "RESOLVED"), ("RESOLVED", "PENDING"),
                ("CANCELLED", "ACKNOWLEDGED"), ("PENDING", "PENDING")):
        assert not ok(*bad)


# --------------------------------------------------------- P4 historical
def test_replay_features_use_frozen_feature_names():
    from ml.feature_spec import FEATURE_ORDER

    from app.historical.service import replay_features

    feats = replay_features(120.0)
    assert set(feats) == set(FEATURE_ORDER)          # model contract intact
    assert feats["rainfall_mm_24h"] == 120.0
    assert feats["flood_susceptibility"] > 0         # heavy rain => signal


def test_compare_metrics_are_exact_and_honest():
    from app.historical.service import compare

    m = compare({"a", "b", "c"}, {"b", "c", "d"},
                lead_times_h=[6.0, 12.0])
    assert m["detected"] == 2 and m["missed"] == 1
    assert m["false_positives"] == 1
    assert m["detection_rate_pct"] == round(100 * 2 / 3, 1)
    assert m["false_alarm_rate_pct"] == round(100 * 1 / 3, 1)
    assert m["avg_warning_lead_time_h"] == 9.0
    empty = compare(set(), {"x"})
    assert empty["false_alarm_rate_pct"] is None     # no division by zero
    assert empty["detection_rate_pct"] == 0.0


# ------------------------------------------------------------ P5 route health
def test_health_score_monotonic_and_bounded():
    from app.routehealth.engine import health_score

    good = health_score(closures_12m=0, disruptions_12m=0,
                        recent_incidents_30d=0, open_siblings=3,
                        accessibility_pct=90)
    bad = health_score(closures_12m=18, disruptions_12m=12,
                       recent_incidents_30d=5, open_siblings=0,
                       accessibility_pct=20)
    assert 0 <= good["health_score"] <= 100
    assert good["health_score"] >= 75 and good["band"] == "GOOD"
    assert bad["health_score"] < good["health_score"]
    assert bad["health_score"] >= 0                  # clamped
    # monotonicity: more closures never improves the score
    mid = health_score(closures_12m=5, disruptions_12m=2,
                       recent_incidents_30d=1, open_siblings=1,
                       accessibility_pct=60)
    worse = health_score(closures_12m=9, disruptions_12m=2,
                         recent_incidents_30d=1, open_siblings=1,
                         accessibility_pct=60)
    assert worse["health_score"] < mid["health_score"]
    assert bad["components"]["redundancy"]["penalty"] > 0   # single point


def test_trend_directions():
    from app.routehealth.engine import trend

    assert trend(recent_incidents_90d=6, prior_incidents_90d=1,
                 closures_recent=1, closures_prior=0) == "DECLINING"
    assert trend(recent_incidents_90d=0, prior_incidents_90d=6,
                 closures_recent=0, closures_prior=2) == "IMPROVING"
    assert trend(recent_incidents_90d=2, prior_incidents_90d=2,
                 closures_recent=0, closures_prior=0) == "STABLE"


# ------------------------------------------------------------- P7 impact
def test_cost_estimate_is_labeled_estimated_and_monotonic():
    from app.impactmetrics.engine import cost_saving_estimate

    small = cost_saving_estimate(delay_hours_avoided=2, vehicles_involved=3)
    big = cost_saving_estimate(delay_hours_avoided=8.3, vehicles_involved=6)
    assert small["basis"] == "ESTIMATED"
    assert big["estimated_cost_avoided_inr"] > \
        small["estimated_cost_avoided_inr"] >= 0
    zero = cost_saving_estimate(delay_hours_avoided=0, vehicles_involved=5)
    assert zero["estimated_cost_avoided_inr"] == 0


def test_people_impact_uses_operational_wording_never_claims():
    from app.impactmetrics.engine import people_impact_estimate

    out = people_impact_estimate(district_population=18420,
                                 days_of_supply=2.1, commodity="WATER")
    assert out["basis"] == "ESTIMATED"
    assert out["people_potentially_affected"] == 18420
    assert "risk" in out["terminology"]
    unknown = people_impact_estimate(district_population=None,
                                     days_of_supply=None, commodity="FOOD")
    assert unknown["basis"] == "UNKNOWN"
    assert unknown["people_potentially_affected"] is None   # never fake zero


# ----------------------------------------------------------------- P8 i18n
def test_meitei_catalog_has_full_parity_and_is_marked_demo():
    from app.i18n.catalog import CATALOGS

    en = CATALOGS["en"]
    mni = CATALOGS["mni"]
    missing = set(en) - set(mni)
    extra = set(mni) - set(en)
    assert not missing, f"mni missing keys: {sorted(missing)[:8]}"
    assert not extra, f"mni has unknown keys: {sorted(extra)[:8]}"
    from app.i18n.service import SUPPORTED_LANGUAGES

    assert SUPPORTED_LANGUAGES["mni"].get("demo") is True
    # placeholders survive translation ({district}/{level} etc.)
    for key, value in en.items():
        for token in ("{district}", "{level}", "{incident_type}",
                      "{confidence}"):
            if token in value:
                assert token in mni[key], f"{key} lost {token}"


def test_worker_registers_responder_escalation_job():
    from workers.runner import build_runner

    r = build_runner(interval_s=60)
    assert "responder_escalation" in r.jobs

