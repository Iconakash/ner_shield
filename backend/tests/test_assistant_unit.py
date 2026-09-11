"""Phase 25 unit tests — Decision Intelligence Assistant (C23 · FR-C23.2).

Pure checks: deterministic intent parsing (commodity/hour params), the
non-chatbot guard, shortage answer shape per the source blueprint (ranked
percentages, primary cause, pre-position recommendation citing a warehouse
outside the affected districts), and citation of underlying tables.
"""

try:
    from app.assistant import engine as ae
except ModuleNotFoundError:
    from assistant import engine as ae


# ------------------------------------------------------------------- parsing
def test_blueprint_question_parses_to_shortage_forecast():
    intent, params = ae.parse(
        "Which districts may face medicine shortages within 24 hours?")
    assert intent == ae.INTENT_SHORTAGE
    assert params == {"commodity": "MEDICINE", "hours": 24}


def test_commodity_and_horizon_extraction():
    intent, params = ae.parse("any water shortage risk in the next 48 hours?")
    assert intent == ae.INTENT_SHORTAGE
    assert params["commodity"] == "WATER"
    assert params["hours"] == 48


def test_out_of_range_hours_are_clamped_into_the_valid_set():
    _, params = ae.parse("medicine shortages within 3 hours?")
    assert params["hours"] == 6
    _, params = ae.parse("medicine shortages within 500 hours?")
    assert params["hours"] == 72


def test_other_frozen_intents_parse_without_params():
    assert ae.parse("which districts have a single point of failure?")[0] \
        == ae.INTENT_SINGLE_POINT
    assert ae.parse("any open critical alerts pending action?")[0] \
        == ae.INTENT_ALERTS
    assert ae.parse("exposed shipments right now?")[0] \
        == ae.INTENT_EXPOSED


def test_unsupported_questions_never_map_to_an_intent():
    for q in ("what is the capital of India?",
              "tell me a joke", "write me a poem about monsoon"):
        intent, params = ae.parse(q)
        assert intent is None and params == {}


def test_empty_question_is_rejected():
    assert ae.parse("") == (None, {})

# ------------------------------------------------------- non-chatbot guard
def test_unsupported_answer_offers_catalog_instead_of_fabricating():
    answer = ae.unsupported("who will win the election?")
    assert answer["intent"] is None
    assert answer["items"] == []
    assert answer["supported_questions"] == ae.intents()

# ------------------------------------------------------------------ shortage
def _rows(*overrides, **common):
    base = {"district_code": "D", "days_of_supply": 1.0,
            "incoming_quantity": 0.0, "route_disrupted": True,
            "shortage_probability": 87.0}
    seq = list(overrides) or [{}]
    return [dict(base, **o, **common) for o in seq]


def test_blueprint_answer_shape_percentages_cause_recommendation():
    rows = _rows({"district_code": "A", "shortage_probability": 87.0},
                 {"district_code": "B", "shortage_probability": 74.2},
                 {"district_code": "C", "shortage_probability": 68.9},
                 {"district_code": "SAFE", "shortage_probability": 20.0})
    whs = [{"code": "WH-IN-D", "district_code": "A"},
           {"code": "W2", "district_code": "OUT"}]
    ans = ae.compose_shortage(rows, whs, "MEDICINE", 24)
    assert ans["summary"].startswith("3 district(s) identified.")
    probs = [i["probability"] for i in ans["items"]]
    assert probs == sorted(probs, reverse=True)      # worst first
    assert ans["items"][0]["district_code"] == "A"   # 87% leads
    assert "SAFE" not in [i["district_code"] for i in ans["items"]]
    # cause precedence: route disruption dominates when present
    assert ans["primary_cause"] == "Predicted route disruption"
    rec = ans["recommendations"][0]
    assert rec["action"] == "PRE_POSITION_SUPPLIES"
    assert rec["source_warehouse"] == "W2"           # outside affected set


def test_thin_stock_becomes_the_cause_when_routes_are_healthy():
    ans = ae.compose_shortage(_rows(route_disrupted=False,
                                    incoming_quantity=0.0), [],
                              "MEDICINE", 24)
    assert ans["primary_cause"] == "Stock cover below consumption"


def test_below_threshold_districts_yield_a_clean_negative_answer():
    ans = ae.compose_shortage(_rows(shortage_probability=30.0), [],
                              "MEDICINE", 24)
    assert ans["items"] == []
    assert "No" in ans["summary"]
    assert ans["recommendations"] == []


def test_every_answer_cites_underlying_tables():
    ans = ae.compose_shortage(_rows(), [], "MEDICINE", 24)
    assert "inventory" in ans["citations"]
    assert isinstance(ans["intent"], str)


# ------------------------------------------------------- other intent answers
def test_single_point_answer_names_lifeline_and_recommends_alternate():
    ans = ae.compose_single_point(
        [{"district_code": "L", "lifeline_corridor": "NH-02"}])
    assert "1 district(s)" in ans["summary"]
    assert ans["items"][0]["lifeline_corridor"] == "NH-02"
    assert ans["recommendations"][0]["action"] == "OPEN_ALTERNATE_CORRIDOR"


def test_alerts_answer_counts_by_level_desc():
    ans = ae.compose_alerts({"HIGH": 3, "CRITICAL": 5}, 8)
    assert ans["summary"].startswith("8 alert(s)")
    assert [i["level"] for i in ans["items"]] == ["CRITICAL", "HIGH"]

