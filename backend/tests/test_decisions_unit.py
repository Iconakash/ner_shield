"""Phase 19 unit tests — Decision Intelligence Assistant rule engine (FR-C23.1).

The killer-feature contract: every recommendation carries the SIX mandated
fields, confidence is derived from engine scores, approval requirements map
onto the frozen two-person workflow, ranking is deterministic.
"""
import pytest

try:
    from app.decisions import engine
    from app.core.security import APPROVAL_WORKFLOW_PERMISSIONS
except ModuleNotFoundError:
    from decisions import engine
    from core.security import APPROVAL_WORKFLOW_PERMISSIONS


# ------------------------------------------------------------ sample signals
SHIP = {"id": "s-uuid-104", "code": "SHP-104", "commodity": "MEDICINE",
        "is_critical": True, "dest_district": "IMPHAL", "state_code": "IN-MN"}
PRED = {"segment_id": "seg-1", "overall_label": "CRITICAL",
        "risk_current": 85.0, "risk_24h": 92.0, "road_code": "NH-02"}
SHORTAGE = {"inventory_id": "inv-9", "district_code": "GAU",
            "commodity": "EMERGENCY_SUPPLIES", "shortage_probability": 84.0,
            "days_of_supply": 2.1, "daily_consumption": 220.0,
            "expected_disruption_hours": 18}
MONITOR_PRED = {"segment_id": "seg-7", "overall_label": "HIGH",
                "risk_current": 82.0, "risk_24h": 88.0,
                "road_code": "R-17", "district_code": "JRH"}
CLOSED_SEG = {"segment_id": "seg-3", "road_code": "NH-06",
              "district_code": "SHL", "state_code": "IN-ML",
              "updated_recently": True}


# ------------------------------------------------------- six-field contract
def test_every_rule_output_carries_all_six_mandated_fields():
    recs = [engine.recommend_reroute(SHIP, PRED),
            engine.recommend_preposition(SHORTAGE),
            engine.recommend_monitor(MONITOR_PRED),
            engine.recommend_notify(CLOSED_SEG)]
    for rec in recs:
        assert set(engine.REQUIRED_FIELDS) <= set(rec)
        assert rec["reason"] and rec["recommended_action"]
        assert rec["expected_impact"] and rec["affected_entities"]
        assert 1 <= rec["confidence"] <= 99


def test_validate_rejects_incomplete_recommendation():
    with pytest.raises(ValueError, match="mandated fields"):
        engine.validate({"reason": "x"})


def test_validate_rejects_unknown_approval_action():
    bad = engine.recommend_reroute(SHIP, PRED)
    bad["approval_required"] = "SOME_INVENTED_ACTION"
    with pytest.raises(ValueError, match="unknown approval"):
        engine.validate(bad)

# ------------------------------------------------------------- rule triggers
def test_reroute_spec_example_medicine_104():
    rec = engine.recommend_reroute(SHIP, PRED)
    assert "Reroute" in rec["title"] and "#SHP-104" in rec["title"]
    assert rec["confidence"] == pytest.approx(91.0)   # 85 + 6 critical bonus
    assert "CRITICAL disruption risk" in rec["reason"]
    assert {e["type"] for e in rec["affected_entities"]} == \
        {"SHIPMENT", "ROAD_SEGMENT", "DISTRICT"}
    assert rec["evidence"][0]["type"] == "disruption_prediction"


def test_preposition_spec_example_district_confidence_84():
    rec = engine.recommend_preposition(SHORTAGE)
    assert rec["title"].startswith("Pre-position emergency supplies")
    assert "GAU" in rec["title"]
    assert rec["confidence"] == 84.0                  # == shortage probability


def test_monitor_spec_example_r17_risk_82():
    rec = engine.recommend_monitor(MONITOR_PRED)
    assert rec["title"].startswith("Monitor R-17")
    assert rec["confidence"] == 82.0                  # == risk_current


def test_notify_reason_is_accessibility_degradation():
    rec = engine.recommend_notify(CLOSED_SEG)
    assert "accessibility degradation" in rec["reason"].lower()
    assert "District Officer" in rec["title"]


def test_soft_triggers_do_not_fire():
    assert engine.recommend_monitor(
        {**MONITOR_PRED, "overall_label": "GUARDED"}) is None
    assert engine.recommend_monitor(
        {**MONITOR_PRED, "overall_label": "LOW"}) is None
    assert engine.recommend_notify({**CLOSED_SEG,
                                    "updated_recently": False}) is None

# ------------------------------------------- confidence derived, never invented
def test_confidence_tracks_underlying_signal_strength():
    low = engine.recommend_preposition({**SHORTAGE,
                                        "shortage_probability": 55.0})
    high = engine.recommend_preposition({**SHORTAGE,
                                         "shortage_probability": 95.0})
    assert low["confidence"] < high["confidence"]
    non_crit = engine.recommend_reroute({**SHIP, "is_critical": False}, PRED)
    assert non_crit["confidence"] == 85.0             # no criticality bonus


# -------------------------------------------------------- approval mapping
def test_approval_requirements_map_to_frozen_workflow_actions():
    for rule, action in engine.APPROVAL_ACTIONS.items():
        assert action in APPROVAL_WORKFLOW_PERMISSIONS, (
            f"{rule} demands an action outside the two-person workflow")


def test_approval_gated_cards_embed_ready_dispatch_template():
    reroute = engine.recommend_reroute(SHIP, PRED)
    d = reroute["dispatch"]
    assert d["action_type"] == "EMERGENCY_REROUTE"
    assert d["payload"]["recommendation_id"] == reroute["id"]
    pre = engine.recommend_preposition(SHORTAGE)
    assert pre["dispatch"]["action_type"] == "MAJOR_SUPPLY_REDISTRIBUTION"
    # monitor/notify need NO approval — dispatch must be absent
    assert engine.recommend_monitor(MONITOR_PRED)["dispatch"] is None
    assert engine.recommend_notify(CLOSED_SEG)["dispatch"] is None


# ------------------------------------------------------ ids, ranking, dedupe
def test_ids_are_deterministic_per_operational_situation():
    a = engine.recommend_reroute(SHIP, PRED)
    b = engine.recommend_reroute(dict(SHIP), dict(PRED))
    c = engine.recommend_reroute({**SHIP, "id": "different"}, PRED)
    assert a["id"] == b["id"]
    assert a["id"] != c["id"]


def test_ranking_approval_gated_first_then_confidence():
    reroute = engine.recommend_reroute(SHIP, PRED)          # 91 + 12 = 103
    monitor = engine.recommend_monitor(MONITOR_PRED)        # 82
    ranked = engine.rank([monitor, reroute])
    assert ranked[0]["id"] == reroute["id"]
    assert all(ranked[i]["priority_score"] >= ranked[i + 1]["priority_score"]
               for i in range(len(ranked) - 1))


def test_dedupe_collapses_same_situation():
    r1 = engine.recommend_preposition(SHORTAGE)
    r2 = engine.recommend_preposition(dict(SHORTAGE))
    assert len(engine.dedupe([r1, r2, r1])) == 1


def test_build_recommendations_end_to_end_pipeline():
    recs = engine.build_recommendations(
        ships_at_risk=[(SHIP, PRED)],
        shortage_rows=[SHORTAGE],
        monitor_preds=[MONITOR_PRED],
        closed_segments=[CLOSED_SEG])
    rules = [r["rule"] for r in recs]
    assert rules.count("REROUTE_SHIPMENT") == 1
    assert rules.count("PRE_POSITION_SUPPLIES") == 1
    assert rules.count("MONITOR_SEGMENT") == 1
    assert rules.count("NOTIFY_DISTRICT_OFFICER") == 1
    # approval-gated actions lead the ACTION REQUIRED list
    assert recs[0]["approval_required"] is not None


