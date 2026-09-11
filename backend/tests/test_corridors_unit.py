"""Phase 24 unit tests — Critical Corridor Ranking (C22 · FR-C22.1).

Pure checks: frozen weight contract, weighted-mean composite, banding
(CRITICAL/HIGH/MEDIUM/LOW), monotone factor responses, scarcity from shared-
district alternates, visible factor breakdown, descending prioritization
order, determinism, and the FR-C22.1 CSV export.
"""

try:
    from app.corridors import engine as ce
except ModuleNotFoundError:
    from corridors import engine as ce


# ------------------------------------------------------------ weight contract
def test_weights_cover_every_factor_once_and_sum_to_one():
    assert set(ce.WEIGHTS) == set(ce.FACTOR_KEYS)
    assert abs(sum(ce.WEIGHTS.values()) - 1.0) < 1e-9


def test_score_is_the_weighted_mean_of_the_five_factors():
    r = rank()
    expected = round(sum(ce.WEIGHTS[k] * v for k, v in
                         [(k, r["factors"][ce.FACTOR_LABELS[k]])
                          for k in ce.FACTOR_KEYS]), 1)
    assert r["score"] == expected
    assert 0.0 <= r["score"] <= 100.0

# ------------------------------------------------------------------- banding
def test_bands_match_the_blueprint_scale():
    assert ce.band_for(90.0) == "CRITICAL"
    assert ce.band_for(75.0) == "CRITICAL"
    assert ce.band_for(74.9) == "HIGH"
    assert ce.band_for(60.0) == "HIGH"
    assert ce.band_for(50.0) == "MEDIUM"
    assert ce.band_for(20.0) == "LOW"


def test_lifeline_corridor_ranks_critical_and_low_risk_redundant_is_low():
    lifeline = rank(pop=300_000, critical=6, hospitals=4, alts=0, risk=80.0)
    quiet = rank(pop=5_000, critical=0, other=1, hospitals=0, alts=5,
                 risk=10.0)
    assert lifeline["band"] == "CRITICAL"
    assert quiet["band"] == "LOW"
    assert lifeline["score"] > quiet["score"]

# --------------------------------------------------------- factor behaviour
def test_more_population_raises_dependency_monotonically():
    a = ce.population_factor(50_000)
    b = ce.population_factor(150_000)
    c = ce.population_factor(500_000)          # capped
    assert 0 <= a < b < c <= 100.0


def test_critical_cargo_counts_double_toward_goods_dependency():
    mixed = ce.goods_factor(critical_shipments=3, other_shipments=0)
    plain = ce.goods_factor(critical_shipments=0, other_shipments=3)
    assert mixed == 2 * plain                   # same count, heavier mix


def test_fewer_alternates_means_higher_scarcity():
    assert ce.scarcity_factor(0) == 100.0
    assert ce.scarcity_factor(2) > ce.scarcity_factor(3)
    assert ce.scarcity_factor(10) == 0.0


def test_disruption_probability_is_used_directly():
    assert ce.disruption_factor(80.0) == 80.0
    assert ce.disruption_factor(None) == 0.0

# ------------------------------------------------------------------ rollup
def test_ranking_orders_most_critical_first_with_visible_breakdown():
    region = _region()
    scores = [c["score"] for c in region["corridors"]]
    assert scores == sorted(scores, reverse=True)
    assert [c["rank"] for c in region["corridors"]] == [1, 2, 3]
    top = region["corridors"][0]
    assert list(top["factors"]) == [
        "Population Dependency", "Essential Goods Dependency",
        "Hospital Connectivity", "Alternative Route Scarcity",
        "Disruption Probability"]
    assert len(top["top_drivers"]) == 2
    counts = region["counts"]
    assert sum(counts.values()) == 3


def test_alternates_are_derived_from_shared_districts_not_self():
    # Fixture: LIFELINE serves GAU only; NH-01 serves GAU+SCL; SH-05 serves
    # SCL only -> each corridor's alternates are OTHER roads sharing a district.
    region = recompute()
    alts = {c["road_code"]: c["inputs"]["viable_alternates"]
            for c in region["corridors"]}
    assert alts["NH-LIFELINE"] == 1     # NH-01 shares GAU
    assert alts["SH-05"] == 1           # NH-01 shares SCL
    assert alts["NH-01"] == 2           # touches both districts

# ------------------------------------------------------------------- CSV
def test_csv_export_has_header_and_one_row_per_corridor():
    csv_text = ce.to_csv(_region())
    lines = csv_text.strip().splitlines()
    assert lines[0].startswith("rank,road_code,road_name,band,score")
    assert len(lines) == 4                      # header + 3 corridors
    assert "NH-LIFELINE" in lines[1]            # most critical first


def test_ranking_is_deterministic():
    assert _region() == _region()

# ------------------------------------------------------------------ helpers
_SHORT = {"pop": "population_served", "critical": "critical_shipments",
          "other": "other_shipments", "hospitals": "hospitals_served",
          "alts": "viable_alternates", "risk": "avg_risk"}


def rank(**kw):
    defaults = dict(road_code="NH-X", name="X", population_served=100_000,
                    critical_shipments=2, other_shipments=2,
                    hospitals_served=2, viable_alternates=1, avg_risk=55.0)
    merged = {**defaults, **{_SHORT[k]: v for k, v in kw.items()}}
    return ce.rank_corridor(**merged)


def recompute():
    return ce.compute(
        district_populations={"GAU": 400_000, "SCL": 50_000},
        district_hospitals={"GAU": 3, "SCL": 1},
        corridor_rows=[
            {"road_id": "r1", "road_code": "NH-LIFELINE", "name": "Lifeline",
             "total_segments": 8, "open_segments": 8, "avg_risk": 78.0},
            {"road_id": "r2", "road_code": "NH-01", "name": "Trunk",
             "total_segments": 6, "open_segments": 6, "avg_risk": 40.0},
            {"road_id": "r3", "road_code": "SH-05", "name": "Hill spur",
             "total_segments": 4, "open_segments": 4, "avg_risk": 30.0}],
        corridor_districts=[
            {"road_id": "r1", "district_code": "GAU"},
            {"road_id": "r2", "district_code": "GAU"},
            {"road_id": "r2", "district_code": "SCL"},
            {"road_id": "r3", "district_code": "SCL"}],
        corridor_shipments=[
            {"road_id": "r1", "critical_shipments": 4,
             "other_shipments": 1},
            {"road_id": "r2", "critical_shipments": 1,
             "other_shipments": 2}])


def _region():
    return recompute()
