"""Phase 23 unit tests — Route Redundancy Intelligence (C21 · FR-C21.1).

Pure checks: blueprint example (1 primary + 2 alternates = MEDIUM), level
bands, viability gating (closures + high risk), emergency-grade gating,
primary selection quality, SINGLE-POINT LOGISTICS VULNERABILITY flag,
watchlist ordering, determinism.
"""

try:
    from app.redundancy import engine as rd
except ModuleNotFoundError:
    from redundancy import engine as rd


def _corridor(code, open_seg=None, total=4, risk=20.0, acc=80.0, **kw):
    return {"road_code": code, "total_segments": total,
            "open_segments": total if open_seg is None else open_seg,
            "avg_risk": risk, "avg_accessibility": acc, **kw}


# ------------------------------------------------------------- level bands
def test_blueprint_example_one_primary_two_alternatives_is_medium():
    # District X: Primary 1, Alternative 2 -> Redundancy: MEDIUM
    d = rd.compute_district(
        code="X",
        corridors=[_corridor("NH-01"), _corridor("NH-06"),
                   _corridor("SH-02")])
    assert d["primary_routes"] == 1
    assert d["alternative_routes"] == 2
    assert d["redundancy_level"] == "MEDIUM"
    assert d["single_point_vulnerability"] is False


def test_level_bands_match_the_frozen_scale():
    assert rd.level_for(5) == "HIGH"
    assert rd.level_for(3) == "HIGH"
    assert rd.level_for(2) == "MEDIUM"
    assert rd.level_for(1) == "LOW"
    assert rd.level_for(0) == "NONE"

# ----------------------------------------------------------------- viability
def test_single_viable_corridor_raises_single_point_vulnerability():
    d = rd.compute_district(code="LONELY", corridors=[_corridor("NH-02")])
    assert d["viable_corridors"] == 1
    assert d["single_point_vulnerability"] is True
    assert d["alert"] == rd.SINGLE_POINT_ALERT \
        == "SINGLE-POINT LOGISTICS VULNERABILITY"
    assert d["lifeline_corridor"] == "NH-02"
    assert d["redundancy_level"] == "NONE"


def test_fully_closed_corridor_is_unusable_and_not_counted():
    d = rd.compute_district(
        code="GAU", corridors=[_corridor("NH-01", open_seg=0),
                               _corridor("R-17")])
    roles = {c["road_code"]: c["role"] for c in d["corridors"]}
    assert roles["NH-01"] == "UNUSABLE"
    assert d["viable_corridors"] == 1
    assert d["single_point_vulnerability"] is True


def test_high_average_risk_disqualifies_a_corridor():
    d = rd.compute_district(
        code="RISKY", corridors=[_corridor("NH-01"),
                                 _corridor("BAD", risk=85.0)])
    assert d["alternative_routes"] == 0
    assert d["single_point_vulnerability"] is True


def test_district_with_no_corridors_at_all_is_flagged():
    d = rd.compute_district(code="VOID", corridors=[])
    assert d["single_point_vulnerability"] is True
    assert d["redundancy_level"] == "NONE"
    assert d["lifeline_corridor"] is None

# ------------------------------------------------------------------ emergency
def test_emergency_routes_require_accessibility_and_low_risk():
    d = rd.compute_district(
        code="MIX",
        corridors=[_corridor("GOOD", risk=15.0, acc=88.0),
                   _corridor("ROUGH", risk=30.0, acc=40.0),
                   _corridor("HOT", risk=60.0, acc=85.0)])
    emg = [c["road_code"] for c in d["corridors"]
           if c["emergency_capable"]]
    assert emg == ["GOOD"]
    assert d["emergency_routes"] == 1

# ------------------------------------------------------------------ primary
def test_primary_goes_to_the_best_open_corridor_not_alphabetical():
    d = rd.compute_district(
        code="GAU",
        corridors=[_corridor("A-ROAD", open_seg=1, total=6,
                             risk=50.0, acc=55.0),
                   _corridor("B-ROAD", open_seg=6, total=6,
                             risk=10.0, acc=90.0)])
    roles = {c["road_code"]: c["role"] for c in d["corridors"]}
    assert roles["B-ROAD"] == "PRIMARY"          # most open + best condition
    assert roles["A-ROAD"] == "ALTERNATIVE"

# ------------------------------------------------------------ region rollup
def test_region_rollup_ranks_most_fragile_first_with_watchlist():
    region = _region()
    alts = [d["alternative_routes"] for d in region["districts"]]
    assert alts == sorted(alts)
    assert [d["rank"] for d in region["districts"]] == [1, 2, 3]
    fragile = region["districts"][0]["district_code"]
    assert region["single_point_districts"] == [fragile]
    assert region["level_counts"]["NONE"] >= 1


def test_rollup_is_deterministic():
    assert _region() == _region()

# ------------------------------------------------------------------ helpers
def _region():
    return rd.compute(
        districts=[{"code": "X", "name": "District X"},
                   {"code": "LONE", "name": "Lifeline"},
                   {"code": "WEB", "name": "Well Woven"}],
        corridor_rows=[
            {"district_code": "X", "road_code": "NH-01", "total_segments": 4,
             "open_segments": 4, "avg_risk": 18.0, "avg_accessibility": 82.0},
            {"district_code": "X", "road_code": "NH-06", "total_segments": 4,
             "open_segments": 4, "avg_risk": 25.0, "avg_accessibility": 76.0},
            {"district_code": "X", "road_code": "SH-02", "total_segments": 4,
             "open_segments": 3, "avg_risk": 35.0, "avg_accessibility": 70.0},
            {"district_code": "LONE", "road_code": "NH-02",
             "total_segments": 6, "open_segments": 6, "avg_risk": 22.0,
             "avg_accessibility": 80.0},
            {"district_code": "WEB", "road_code": "NH-01", "total_segments": 4,
             "open_segments": 4, "avg_risk": 12.0, "avg_accessibility": 90.0},
            {"district_code": "WEB", "road_code": "NH-06", "total_segments": 4,
             "open_segments": 4, "avg_risk": 15.0, "avg_accessibility": 86.0},
            {"district_code": "WEB", "road_code": "SH-05", "total_segments": 4,
             "open_segments": 4, "avg_risk": 20.0, "avg_accessibility": 84.0},
            {"district_code": "WEB", "road_code": "MDR-11",
             "total_segments": 4, "open_segments": 4, "avg_risk": 25.0,
             "avg_accessibility": 78.0}])
