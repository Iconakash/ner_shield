"""Phase 21 unit tests — Logistics digital twin (FR-C19.1).

Pure checks over a synthetic world state: build normalization + live
disruption overlay, step() clock/movement/recovery/decay with input
immutability, assess() six mandated outputs, reuse of the Phase-9/11/19
engines, replay determinism.
"""
import copy


try:
    from app.twin import engine as te
except ModuleNotFoundError:
    from twin import engine as te


# ------------------------------------------------------------ synthetic world
SEG_A = {"segment_id": "seg-A", "road_id": "r1", "road_code": "NH-02",
         "district_code": "GAU", "status": "OPEN", "baseline_risk": 30.0,
         "length_km": 25.0}
SEG_B = {"segment_id": "seg-B", "road_id": "r2", "road_code": "R-17",
         "district_code": "GAU", "status": "OPEN", "baseline_risk": 15.0,
         "length_km": 18.0}
DISR = [{"segment_id": "seg-A", "risk_current": 85.0, "label": "CRITICAL"}]
VEHICLE = {"id": "veh-1", "code": "AS-T-001", "vtype": "HEAVY_TRUCK",
           "status": "ASSIGNED", "district": "GAU"}
WAREHOUSE = {"facility_id": "wh-1", "code": "WH-GAU", "name": "GAU godown",
             "district_code": "GAU",
             "inventory": [{"commodity": "EMERGENCY_SUPPLIES",
                            "days_of_supply": 2.0,
                            "daily_consumption": 220.0,
                            "incoming_quantity": 0.0}]}
HOSPITAL = {"facility_id": "h-1", "code": "HOSP-GAU", "name": "GAU hospital",
            "district_code": "GAU"}
DISTRICT = {"code": "GAU", "name": "Kamrup"}
SHIPMENT = {"id": "shp-1", "code": "SHP-104", "commodity": "MEDICINE",
            "is_critical": True, "dest_district": "GAU",
            "vehicle_id": "veh-1", "eta_minutes": 240.0,
            "segment_ids": ["seg-A"]}
WEATHER = [{"district_code": "GAU", "rainfall_mm_24h": 40.0,
            "forecast_mm_24h": 10.0}]


def _build(**overrides):
    return te.build(
        segments=overrides.get("segments", [dict(SEG_A), dict(SEG_B)]),
        vehicles=overrides.get("vehicles", [dict(VEHICLE)]),
        warehouses=overrides.get("warehouses", [dict(WAREHOUSE)]),
        hospitals=overrides.get("hospitals", [dict(HOSPITAL)]),
        districts=overrides.get("districts", [dict(DISTRICT)]),
        shipments=overrides.get("shipments", [dict(SHIPMENT)]),
        weather=overrides.get("weather", copy.deepcopy(WEATHER)),
        disruptions=overrides.get("disruptions", copy.deepcopy(DISR)))


# ------------------------------------------------------------------ build
def test_build_normalizes_entities_and_counts_them():
    t = _build()
    assert set(te.ENTITY_TYPES) <= set(t)
    assert t["roads"][0] == {"road_id": "r1", "road_code": "NH-02"}
    sh = t["shipments"][0]
    assert sh["eta_minutes"] == sh["planned_eta_minutes"] == 240.0
    assert sh["progress_pct"] == 0.0


def test_build_overrides_baseline_with_live_disruption():
    t = _build()
    seg_a = next(s for s in t["segments"] if s["segment_id"] == "seg-A")
    assert seg_a["risk_current"] == 85.0 and seg_a["disrupted"] is True
    seg_b = next(s for s in t["segments"] if s["segment_id"] == "seg-B")
    assert seg_b["risk_current"] == 15.0 and not seg_b.get("disrupted")


def test_build_clamps_out_of_range_disruption_risk():
    t = _build(disruptions=[{"segment_id": "seg-B",
                             "risk_current": 500.0, "label": "CRITICAL"}])
    seg_b = next(s for s in t["segments"] if s["segment_id"] == "seg-B")
    assert seg_b["risk_current"] == 99.0

# ------------------------------------------------------------------- step
def test_step_advances_clock_and_never_mutates_input():
    t0 = _build()
    frozen = copy.deepcopy(t0)
    t1 = te.step(t0, 60)
    assert t1["clock_minutes"] == 60
    assert t0 == frozen                       # input twin untouched
    assert t1 is not t0


def test_shipments_progress_and_eta_counts_down():
    sh0 = _build()["shipments"][0]
    t1 = te.step(_build(), 60)
    sh1 = t1["shipments"][0]
    assert 0 < sh1["progress_pct"] <= 100
    assert sh1["eta_minutes"] < sh0["eta_minutes"]


def test_disruption_risk_recovers_toward_baseline():
    t = _build()
    for _ in range(8):                        # ~8h at 8 pts/hour
        t = te.step(t, 60)
    seg_a = next(s for s in t["segments"] if s["segment_id"] == "seg-A")
    assert seg_a["risk_current"] < 85.0
    assert seg_a["risk_current"] >= seg_a["baseline_risk"]


def test_rainfall_decays_but_never_negative():
    t = _build()
    for _ in range(6):
        t = te.step(t, 60)
    w = t["weather"][0]
    assert 0.0 <= w["rainfall_mm_24h"] < 40.0

# ----------------------------------------------------------------- assess
def test_assess_returns_exactly_the_six_mandated_outputs():
    a = te.assess(_build())
    for key in ("affected_shipments", "eta_changes", "alternate_routes",
                "supply_shortage", "critical_cargo", "recommended_actions"):
        assert key in a
    assert set(a["counts"]) >= {"segments", "shipments",
                                "active_disruptions"}


def test_disrupted_corridor_affected_shipment_is_detected():
    a = te.assess(_build())
    assert len(a["affected_shipments"]) == 1
    hit = a["affected_shipments"][0]
    assert hit["code"] == "SHP-104"
    assert hit["exposed_segments"] == ["seg-A"]
    assert a["eta_changes"] == a["affected_shipments"]
    assert a["counts"]["affected_shipments"] == 1


def test_critical_cargo_lists_all_critical_shipments_even_unexposed():
    t = _build(shipments=[dict(SHIPMENT),
                          dict(SHIPMENT, id="shp-2", code="SHP-105",
                               segment_ids=["seg-B"])])
    ids = {c["id"] for c in te.assess(t)["critical_cargo"]}
    assert ids == {"shp-1", "shp-2"}


def test_alternate_routes_flag_reroute_possibility():
    alts = te.assess(_build())["alternate_routes"]
    entry = next(x for x in alts if x["shipment_id"] == "shp-1")
    # GAU still has one open segment (seg-B) -> reroute possible
    assert entry["viable_alternates"] == 1
    assert entry["reroute_possible"] is True


def test_thin_stock_on_serving_route_yields_shortage_point():
    pts = te.assess(_build())["supply_shortage"]
    assert pts and pts[0]["commodity"] == "EMERGENCY_SUPPLIES"
    assert pts[0]["shortage_probability"] >= 5.0

# -------------------------------------------------- government actions (DIA)
def test_actions_are_real_phase19_dia_cards():
    actions = te.assess(_build())["recommended_actions"]
    rules = {a["rule"] for a in actions}
    assert "REROUTE_SHIPMENT" in rules
    assert "PRE_POSITION_SUPPLIES" in rules
    try:
        from app.decisions.engine import REQUIRED_FIELDS
    except ModuleNotFoundError:
        from decisions.engine import REQUIRED_FIELDS
    for rec in actions:
        assert set(REQUIRED_FIELDS) <= set(rec)


# ------------------------------------------------------------------- run
def test_run_replay_trajectory_is_ordered_deterministic_and_assessed():
    r1 = te.run(_build(), horizon_minutes=180, step_minutes=60)
    r2 = te.run(_build(), horizon_minutes=180, step_minutes=60)
    mins = [snap["at_minute"] for snap in r1["trajectory"]]
    assert mins == sorted(mins) and len(mins) == 3
    assert r1["trajectory"] == r2["trajectory"]
    assert "assessment" in r1 and "final_state" in r1
