"""Decision-intelligence layer unit tests (master upgrade §41).

Pure, no infra: data quality, source confidence separation, evidence fusion,
source conflict, decision states/options/cards, alert dedup keys & lifecycle,
and additive wiring (router gate, worker job).
"""
import sys as _sys
from datetime import datetime, timedelta, timezone
from pathlib import Path

import pytest

BACKEND = Path(__file__).resolve().parents[1]
if str(BACKEND) not in _sys.path:
    _sys.path.insert(0, str(BACKEND))

from app.intel.data_quality import (assess, condition_fingerprint,  # noqa: E402
                                    expiry_for)
from app.intel.decision_state import (  # noqa: E402
    A_MONITOR, A_PREPARE_ALT_ROUTE, A_REROUTE, A_VERIFY_FIELD,
    DECISION_STATES, SituationInputs, build_card, build_options, decide_state,
    recommend, review_minutes)
from app.intel.evidence import EvidenceItem, fuse_hazard, summarize  # noqa: E402
from app.intel.service import build_evidence, pred_confidence  # noqa: E402

NOW = datetime.now(timezone.utc)


# ------------------------------------------------------------- Layer 1: DQ
def test_future_timestamp_is_invalid_not_clamped():
    a = assess(source="IMD", source_type="WEATHER",
               observed_at=NOW + timedelta(hours=2),
               values={"rainfall_mm_24h": 10.0},
               ranges={"rainfall_mm_24h": (0, 500)})
    assert a.validation_status == "INVALID"
    assert a.confidence_score == 0.0


def test_stale_data_is_flagged_and_decayed_never_fresh():
    fresh = assess(source="CWC", source_type="HYDROLOGY",
                   observed_at=NOW - timedelta(minutes=30),
                   values={"water_level_m": 80.0},
                   ranges={"water_level_m": (-20, 200)})
    old = assess(source="CWC", source_type="HYDROLOGY",
                 observed_at=NOW - timedelta(days=5),
                 values={"water_level_m": 80.0},
                 ranges={"water_level_m": (-20, 200)})
    assert fresh.validation_status == "VALID"
    assert "stale_observation" in old.issues
    assert old.freshness_score == 0.0 < fresh.freshness_score


def test_missing_value_reported_never_zero_filled():
    a = assess(source="IMD", source_type="WEATHER",
               observed_at=NOW, values={},           # rainfall MISSING
               ranges={"rainfall_mm_24h": (0, 500)})
    assert any(i.startswith("missing:") for i in a.issues)
    assert a.quality_score < 1.0                      # penalized, not defaulted


def test_out_of_range_flags_partial_but_keeps_record():
    a = assess(source="X", source_type="WEATHER", observed_at=NOW,
               values={"rainfall_mm_24h": 9000.0},
               ranges={"rainfall_mm_24h": (0, 500)})
    assert a.validation_status == "PARTIAL"
    assert any(i.startswith("out_of_range") for i in a.issues)


def test_expiry_helper_and_condition_fingerprint():
    exp = expiry_for(60, now=NOW)
    assert exp > NOW
    f1 = condition_fingerprint(["seg-1", "FLOOD"])
    assert f1 == condition_fingerprint([" seg-1 ", " flood "])
    assert f1 != condition_fingerprint(["seg-1", "LANDSLIDE"])


# ------------------------------------------- Layer 2: SOURCE confidence
def test_source_confidence_is_explainable_and_distinct_from_risk():
    from app.intel.source_confidence import get_profile, score

    good = assess(source="IMD", source_type="WEATHER",
                  observed_at=NOW - timedelta(minutes=10),
                  values={"rainfall_mm_24h": 80},
                  ranges={"rainfall_mm_24h": (0, 500)})
    br = score(good, spatial_relevance=1.0)
    assert 0 < br.confidence <= 1.0
    assert set(br.components) == {"authority", "freshness",
                                  "spatial_relevance", "completeness",
                                  "reliability"}
    assert abs(sum(br.weights_used.values()) - 1.0) < 1e-6
    assert "top driver" in br.explanation          # every number explainable

    stale = assess(source="IMD", source_type="WEATHER",
                   observed_at=NOW - timedelta(days=9),
                   values={"rainfall_mm_24h": 80},
                   ranges={"rainfall_mm_24h": (0, 500)})
    assert score(stale).confidence < br.confidence  # staleness reduces trust

    demo = score(assess(source="sim-imd", source_type="WEATHER",
                        observed_at=NOW,
                        values={"rainfall_mm_24h": 80},
                        ranges={"rainfall_mm_24h": (0, 500)}))
    real = score(assess(source="IMD", source_type="WEATHER",
                        observed_at=NOW,
                        values={"rainfall_mm_24h": 80},
                        ranges={"rainfall_mm_24h": (0, 500)}))
    assert demo.confidence < real.confidence        # simulated < authoritative
    assert get_profile("UNKNOWN").authority == 0.5  # honest default


def test_prediction_confidence_proxy_is_completeness_based_and_capped():
    low = pred_confidence(weather_fresh=False, terrain_present=False,
                          history_present=False)
    high = pred_confidence(weather_fresh=True, terrain_present=True,
                           history_present=True)
    assert low == pytest.approx(0.40)
    assert high == pytest.approx(0.75)
    assert high <= 0.85                              # never overclaimed


# --------------------------------- Layer 3+4: evidence & hazard fusion
def _wx(src="IMD", supports=True, hours_old=1, kind="forecast_heavy_rainfall"):
    return EvidenceItem(hazard_type="FLOOD", source=src, kind=kind,
                        supports=supports,
                        observed_at=NOW - timedelta(hours=hours_old),
                        label=f"{kind} ({src})")


def test_unsupported_hazard_and_empty_items_rejected():
    with pytest.raises(ValueError):
        EvidenceItem(hazard_type="VOLCANO", source="X", kind="y",
                     supports=True)
    assert fuse_hazard([], "FLOOD") is None          # no evidence => no hazard


def test_multi_source_agreement_strengthens_hazard_confidence():
    one = fuse_hazard([_wx()], "FLOOD")
    many = fuse_hazard([
        _wx("IMD"),                                   # heavy rainfall forecast
        _wx("CWC", kind="observed_river_level_rising"),
        EvidenceItem(hazard_type="FLOOD", source="TERRAIN",
                     kind="terrain_flood_susceptibility", supports=True,
                     label="high susceptibility"),
    ], "FLOOD")
    assert many.confidence > one.confidence
    assert len(many.evidence) == 3
    assert many.probability <= 95.0                   # never certainty (§40)


def test_source_conflict_reduces_confidence_and_demands_verification():
    agree = fuse_hazard([_wx("IMD"),
                         _wx("CWC", kind="observed_river_level_rising")],
                        "FLOOD")
    conflict = fuse_hazard([_wx("IMD"),
                            _wx("CWC", kind="observed_river_level_rising"),
                            _wx("FIELD_REPORT", supports=False,
                                kind="field_observation_dry")], "FLOOD")
    assert conflict.conflict is not None
    assert conflict.verification_required is True
    assert conflict.status == "UNCONFIRMED"
    assert conflict.confidence < agree.confidence
    lines = summarize(conflict)
    assert any("SOURCE CONFLICT" in ln for ln in lines)


def test_weak_single_signal_also_requires_verification():
    weak = fuse_hazard([_wx(hours_old=60)], "FLOOD")
    assert weak is not None
    assert weak.verification_required is True
    assert weak.confidence < 0.35


# ------------------------------- Layer 6+7: decision states and options
def test_existing_risk_labels_map_to_posture_floor_without_being_replaced():
    assert decide_state(SituationInputs("LOW", 0.8, 0.9)) == "NORMAL"
    assert decide_state(SituationInputs("GUARDED", 0.8, 0.9)) == "WATCH"
    assert decide_state(SituationInputs("ELEVATED", 0.8, 0.9)) == "PREPARE"
    assert decide_state(SituationInputs("HIGH", 0.8, 0.9)) == "MITIGATE"
    assert decide_state(SituationInputs("CRITICAL", 0.8, 0.9)) == "ACT"
    from app.intel.decision_state import RISK_LABELS
    assert RISK_LABELS == ("LOW", "GUARDED", "ELEVATED", "HIGH", "CRITICAL")


def test_exposure_alternatives_and_confirmation_raise_posture():
    base = SituationInputs("HIGH", 0.7, 0.8)
    critical_exposure = SituationInputs("HIGH", 0.7, 0.8,
                                        exposure_criticality=2)
    assert decide_state(critical_exposure) == "MITIGATE"
    assert decide_state(critical_exposure) != decide_state(base)

    trapped = SituationInputs("CRITICAL", 0.7, 0.8, open_alternatives=0)
    assert decide_state(trapped) == "ESCALATE"

    confirmed = SituationInputs("CRITICAL", 0.8, 0.8, exposure_criticality=3,
                                confirmed_closure=True)
    assert decide_state(confirmed) == "EMERGENCY"

    # low data confidence does NOT escalate posture on its own — verification
    # handles ambiguity instead (§25):
    assert decide_state(SituationInputs("CRITICAL", 0.8, 0.15)) == "ACT"


def test_options_costs_are_unknown_and_verification_wins_when_pending():
    s = SituationInputs("HIGH", 0.8, 0.85, exposure_criticality=2,
                        open_alternatives=1, verification_pending=True)
    opts = build_options(s)
    for o in opts:
        assert o.operational_cost == "UNKNOWN"        # §18: no invented costs
    rec = recommend(opts, s)
    assert rec.action == A_VERIFY_FIELD               # trust before action

    s_ok = SituationInputs("HIGH", 0.8, 0.85, exposure_criticality=2,
                           open_alternatives=1)
    actions = {o.action for o in build_options(s_ok)}
    assert A_PREPARE_ALT_ROUTE in actions
    assert A_REROUTE in actions                       # existing action preserved
    reroute = next(o for o in build_options(s_ok) if o.action == A_REROUTE)
    assert reroute.approval_required is True          # human authority (§30)


def test_review_cadence_tightens_with_severity():
    assert review_minutes("NORMAL") > review_minutes("PREPARE")
    assert review_minutes("EMERGENCY") == 5


def test_decision_card_carries_all_mandated_sections():
    s = SituationInputs("HIGH", 0.7, 0.8, exposure_criticality=2)
    card = build_card(subject_type="ROAD_SEGMENT", subject_id="seg-1",
                      title="NH-15 (IN-AS)", situation=s, probability=72.0,
                      horizon="24h",
                      affected_entities=[{"type": "ROAD_SEGMENT",
                                          "id": "seg-1", "label": "NH-15"}],
                      impact_summary=["2 critical shipment(s) exposed"],
                      top_factors=["Heavy rainfall forecast"],
                      evidence_lines=["Forecast 90 mm/24h (IMD)"],
                      hazard_label="FLOOD")
    assert card.decision_state in DECISION_STATES
    assert card.risk_label == "HIGH"                  # risk preserved separately
    assert card.recommended_action in {A_VERIFY_FIELD, A_PREPARE_ALT_ROUTE,
                                       A_MONITOR, A_REROUTE}
    assert card.review_minutes > 0
    assert card.status == "PREDICTED"                 # never shown as CONFIRMED
    assert all(o.operational_cost == "UNKNOWN" for o in card.options)


# --------------------------------------- additive wiring & alert lifecycle
def test_alert_chains_extended_without_touching_existing_types():
    from app.alerts.service import ALERT_CHAINS, chain_for

    # existing chains unchanged (spot-check the frozen originals)
    assert chain_for("ROAD_WARNING")[0] == "DISTRICT_OFFICER"
    assert chain_for("SYSTEM") == ["SUPER_ADMIN"]
    # new hazard/conflict types route through the same escalation machinery
    assert chain_for("FLOOD_RISK")[0] == "DISTRICT_OFFICER"
    assert chain_for("SOURCE_CONFLICT") == ["SUPER_ADMIN"]
    assert "FLOOD_RISK" in ALERT_CHAINS and "DATA_STALE" in ALERT_CHAINS


def test_alert_lifecycle_transitions_enforced():
    from app.alerts.service import valid_transition

    assert valid_transition("ACTIVE", "VALIDATED")
    assert valid_transition("ESCALATED", "MITIGATED")
    assert valid_transition("RESOLVED", "CLOSED")
    for bad in (("CLOSED", "ACTIVE"), ("ACTIVE", "CLOSED"),
                ("RESOLVED", "MITIGATED"), ("VALIDATED", "VALIDATED")):
        assert not valid_transition(*bad)
    assert not valid_transition("UNKNOWN", "ACTIVE")


def test_evidence_extraction_thresholds_are_conservative():
    def row(rain=0.0, fcst=0.0, slide=0, slope=0):
        return {"segment_id": "s1", "district_code": "IN-AS",
                "rainfall_mm_24h": rain, "forecast_rainfall_mm_24h": fcst,
                "landslide_susceptibility": slide, "slope_deg": slope,
                "weather_source": "IMD"}

    assert build_evidence(row()) == []                 # silence => no evidence
    ev = build_evidence(row(rain=50.0))
    assert [e.hazard_type for e in ev] == ["EXTREME_RAINFALL"]
    ev = build_evidence(row(fcst=65.0, slide=60, slope=15))
    hazards = sorted(e.hazard_type for e in ev)
    assert hazards == ["FLOOD", "LANDSLIDE"]


def test_assess_segment_row_completes_and_produces_hazards():
    """Regression: a missing timezone import raised NameError inside
    assess_segment_row and was silently swallowed by the caller's
    'one bad row must not kill the pass' handler — /intel/hazards would
    return empty forever. This pins the pure path as genuinely working."""
    from app.intel.service import assess_segment_row

    row = {"segment_id": "s1", "road_code": "NH-15", "district_code": "IN-AS",
           "overall_label": "HIGH", "segment_status": "OPEN",
           "rainfall_mm_24h": 86.0, "forecast_rainfall_mm_24h": 90.0,
           "weather_observed_at": NOW - timedelta(minutes=20),
           "weather_source": "IMD",
           "slope_deg": 18.0, "flood_susceptibility": 70,
           "landslide_susceptibility": 65, "has_history": True,
           "water_level_m": None, "warning_level_m": None,
           "level_trend": None, "river_observed_at": None,
           "river_source": None, "n_critical_shipments": 2}
    assessments, p_conf = assess_segment_row(row)
    assert assessments                      # evidence exists => hazards produced
    assert all(0 <= a.probability <= 95 for a in assessments)
    assert 0 < p_conf <= 0.85


def test_intel_router_registered_and_gated():
    from fastapi.testclient import TestClient

    from app.main import create_app

    app = create_app()
    paths = app.openapi()["paths"]
    assert "/api/v1/intel/hazards" in paths
    assert "/api/v1/intel/outcomes/{decision_id}" in paths
    # P0 — satellite scene METADATA read (SIH26002 P7). The Flutter client
    # (`lib/services/tasks_service.dart`) depends on this endpoint; it must
    # never 404 and must not be public.
    assert "/api/v1/intel/satellite/scenes" in paths
    client = TestClient(app, raise_server_exceptions=False)
    assert client.get("/api/v1/intel/hazards").status_code == 401
    assert client.post("/api/v1/intel/outcomes", json={}).status_code == 401
    assert client.get("/api/v1/intel/satellite/scenes").status_code == 401