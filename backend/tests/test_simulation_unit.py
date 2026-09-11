"""Phase 20 unit tests — What-if simulator cascade (FR-C18.1).

Pure checks over a synthetic world state: the eight mandated stages, monotone
intensity response, closure/cut-off logic, and reuse of the Phase-9/11/19
engines for ETA, supply, and government actions.
"""

try:
    from app.simulation import engine as sim
except ModuleNotFoundError:
    from simulation import engine as sim


# ------------------------------------------------------------ synthetic world
SEG_A = {"segment_id": "seg-A", "road_code": "NH-02", "district_code": "GAU",
         "baseline_risk": 30.0, "baseline_acc": 80.0,
         "flood_susceptibility": 90, "landslide_susceptibility": 40,
         "length_km": 25.0, "alternates": 0}
SEG_B = {"segment_id": "seg-B", "road_code": "R-17", "district_code": "GAU",
         "baseline_risk": 15.0, "baseline_acc": 88.0,
         "flood_susceptibility": 25, "landslide_susceptibility": 15,
         "length_km": 18.0, "alternates": 2}
SHIP = {"id": "shp-1", "code": "SHP-104", "commodity": "MEDICINE",
        "is_critical": True, "dest_district": "GAU",
        "segment_id": "seg-A", "normal_eta_minutes": 240.0,
        "exposed_length_km": 25.0}
INV = {"district_code": "GAU", "commodity": "EMERGENCY_SUPPLIES",
       "days_of_supply": 2.1, "daily_consumption": 220.0,
       "incoming_quantity": 0.0}


def _run(**overrides):
    return sim.simulate(
        event_type=overrides.get("event_type", "HEAVY_RAINFALL"),
        intensity=overrides.get("intensity", "EXTREME"),
        duration_hours=overrides.get("duration_hours", 12),
        segments=overrides.get("segments", [dict(SEG_A), dict(SEG_B)]),
        shipments=overrides.get("shipments", [dict(SHIP)]),
        inventory=overrides.get("inventory", [dict(INV)]))


# ------------------------------------------------------------- stage contract
def test_cascade_returns_exactly_the_mandated_stages_in_order():
    result = _run()
    assert result["stage_order"] == [
        "Rainfall", "Road risk", "Accessibility", "Shipments", "ETA",
        "Supply", "Alternative routes", "Government actions"]
    assert set(result["stages"]) == set(result["stage_order"])


def test_rainfall_stage_reports_effective_load():
    result = _run(duration_hours=12)
    # EXTREME base 350mm x duration factor (0.5 + 0.5*12/24 = 0.75)
    assert result["stages"]["Rainfall"]["summary"].find("262.5 mm") >= 0


def test_event_inputs_echoed_for_reproducibility():
    result = _run(event_type="FLOOD", intensity="SEVERE", duration_hours=24)
    assert (result["event_type"], result["intensity"],
            result["duration_hours"]) == ("FLOOD", "SEVERE", 24)

# ------------------------------------------------------- road risk projection
def test_extreme_rain_drives_high_susceptibility_segment_to_closure():
    result = _run()
    segs = {s["segment_id"]: s for s in result["stages"]["Road risk"]["segments"]}
    a, b = segs["seg-A"], segs["seg-B"]
    # high flood susceptibility (90) takes the brunt; low (25) barely moves
    assert a["risk_uplift"] > b["risk_uplift"] * 2
    assert a["projected_status"] == "CLOSED"
    assert a["label_after"] == "CRITICAL"
    assert b["projected_status"] in ("OPEN", "PARTIAL")


def test_risk_never_exceeds_99_and_accessibility_never_below_zero():
    result = _run(segments=[dict(SEG_A, baseline_risk=95.0,
                                 flood_susceptibility=100)])
    seg = result["stages"]["Road risk"]["segments"][0]
    assert 0 <= seg["risk_after"] <= 99
    assert seg["acc_after"] >= 0


def test_intensity_response_is_monotone():
    avgs = []
    for intensity in ("LOW", "MODERATE", "SEVERE", "EXTREME"):
        r = _run(intensity=intensity)
        segs = r["stages"]["Road risk"]["segments"]
        avgs.append(sum(s["risk_after"] for s in segs) / len(segs))
    assert avgs == sorted(avgs), f"not monotone: {avgs}"


def test_low_intensity_on_robust_network_stays_open():
    result = _run(intensity="LOW")
    segs = result["stages"]["Road risk"]["segments"]
    assert all(s["projected_status"] == "OPEN" for s in segs)


# --------------------------------------------------- shipments / ETA / supply
def test_shipment_eta_degrades_and_supply_reacts():
    result = _run()
    eta = result["stages"]["ETA"]["summary"]
    assert "worst delay" in eta and "+0 min" not in eta
    impacts = result["stages"]["Shipments"]["impacts"]
    assert impacts and impacts[0]["eta_after_min"] > impacts[0]["eta_before_min"]
    # critical medicine on a closed corridor -> shortage probability reacts
    supply = result["stages"]["Supply"]["impacts"]
    assert supply[0]["shortage_probability_after"] >= 55


def test_before_after_summary_captures_the_whole_cascade():
    ba = _run()["before_after"]
    assert ba["road_risk_avg"]["after"] > ba["road_risk_avg"]["before"]
    assert ba["accessibility_avg"]["after"] < ba["accessibility_avg"]["before"]
    assert ba["shipments_exposed"] == 1
    assert ba["max_delay_minutes"] > 0
    assert ba["stock_points_at_risk"] >= 1


# ------------------------------------------- alternative routes / cut-off
def test_district_without_alternates_is_cut_off_when_corridor_closes():
    result = _run()          # SEG_A has alternates=0 and closes under EXTREME
    alt_stage = result["stages"]["Alternative routes"]
    assert "GAU" in alt_stage["cut_off_districts"]
    cut = [a for a in alt_stage["alternatives"] if a["district_cut_off"]]
    assert cut and cut[0]["viable_alternates"] == 0


def test_redundant_network_never_cuts_off():
    result = _run(segments=[dict(SEG_B, alternates=3)],
                  shipments=[], inventory=[])
    assert result["stages"]["Alternative routes"]["cut_off_districts"] == []

# ---------------------------------------------------- government actions stage
def test_actions_are_real_phase19_dia_cards():
    result = _run()
    actions = result["stages"]["Government actions"]["actions"]
    rules = {a["rule"] for a in actions}
    # closed corridor -> notify; exposed critical shipment -> reroute;
    # thin supply -> pre-position
    assert "NOTIFY_DISTRICT_OFFICER" in rules
    assert "REROUTE_SHIPMENT" in rules
    assert "PRE_POSITION_SUPPLIES" in rules
    for rec in actions:
        assert set(dia_required_fields()) <= set(rec)


def dia_required_fields():
    try:
        from app.decisions.engine import REQUIRED_FIELDS
    except ModuleNotFoundError:
        from decisions.engine import REQUIRED_FIELDS
    return REQUIRED_FIELDS


def test_no_actionable_cascade_yields_empty_action_list():
    result = _run(intensity="LOW",
                  segments=[dict(SEG_B)],
                  shipments=[], inventory=[dict(INV, days_of_supply=90.0)])
    assert result["stages"]["Government actions"]["actions"] == []


def test_simulation_is_deterministic_for_identical_inputs():
    r1 = _run()
    r2 = _run()
    assert r1["before_after"] == r2["before_after"]
    assert [a["id"] for a in r1["stages"]["Government actions"]["actions"]] \
        == [a["id"] for a in r2["stages"]["Government actions"]["actions"]]


