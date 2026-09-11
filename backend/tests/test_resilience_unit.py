"""Phase 22 unit tests — Resilience Score (C20 · FR-C20.1).

Pure checks: frozen weight contract, weighted-mean composite, documented
neutrality rule for missing data, monotone component responses, visible
breakdown, ascending watchlist ordering + structural-vulnerability flag,
determinism.
"""

try:
    from app.resilience import engine as re_eng
except ModuleNotFoundError:
    from resilience import engine as re_eng


# ------------------------------------------------------------ weight contract
def test_weights_cover_every_component_exactly_once_and_sum_to_one():
    assert set(re_eng.WEIGHTS) == set(re_eng.COMPONENT_KEYS)
    assert abs(sum(re_eng.WEIGHTS.values()) - 1.0) < 1e-9


def test_composite_is_the_weighted_mean_of_the_five_components():
    d = _district()
    expected = round(sum(re_eng.WEIGHTS[k] * v for k, v in
                         [(k, d["components"][re_eng.COMPONENT_LABELS[k]])
                          for k in re_eng.COMPONENT_KEYS]), 1)
    assert d["score"] == expected
    assert 0.0 <= d["score"] <= 100.0

# --------------------------------------------------------- component behaviour
def test_perfect_district_scores_high_and_is_not_vulnerable():
    d = _district()
    assert d["score"] >= 80.0
    assert d["band"] == "RESILIENT"
    assert d["structurally_vulnerable"] is False


def test_degraded_district_scores_low_and_is_flagged_vulnerable():
    d = _district(avg_accessibility=25.0, avg_days_of_supply=1.5,
                  total_segments=5, open_segments=1,
                  rainfall_mm_24h=180.0, forecast_mm_24h=60.0,
                  susceptibility_avg=90.0, hospitals=0, warehouses=0,
                  available_vehicles=0)
    assert d["score"] < re_eng.STRUCTURAL_VULNERABILITY_BELOW
    assert d["structurally_vulnerable"] is True
    assert d["band"] in ("ELEVATED", "CRITICAL")


def test_missing_data_scores_neutral_never_zero():
    d = re_eng.compute_district(code="XYZ")
    comps = d["components"]
    assert all(v == re_eng.NEUTRAL for v in comps.values())
    assert d["score"] == re_eng.NEUTRAL      # weights sum to 1


def test_more_open_segments_raise_redundancy_monotonically():
    scores = [re_eng.route_redundancy_component(6, n)
              for n in range(0, 7)]
    assert scores == sorted(scores)


def test_heavier_rainfall_lowers_weather_safety():
    dry = re_eng.weather_safety_component(0.0, 0.0, 50.0)
    wet = re_eng.weather_safety_component(120.0, 80.0, 50.0)
    assert wet < dry


def test_thinner_stock_lowers_supply_availability():
    fat = re_eng.supply_availability_component(21.0)
    thin = re_eng.supply_availability_component(2.0)
    assert thin < fat and thin < 25.0 and fat == 100.0


def test_real_zeros_count_against_capacity_but_absence_does_not():
    empty = re_eng.emergency_capacity_component(None, None, None)
    zeroed = re_eng.emergency_capacity_component(0, 0, 0)
    assert empty == re_eng.NEUTRAL
    assert zeroed == 0.0

# ---------------------------------------------------------------- breakdown
def test_component_breakdown_is_visible_with_expected_labels():
    d = _district()
    assert list(d["components"]) == [
        "Connectivity", "Supply Availability", "Route Redundancy",
        "Weather Exposure", "Emergency Capacity"]


def test_weakest_components_surface_the_drivers():
    d = _district(avg_days_of_supply=0.5, rainfall_mm_24h=250.0,
                  susceptibility_avg=95.0)
    assert "Supply Availability" in d["weakest_components"]

# ------------------------------------------------------- region-wide rollup
def test_region_rollup_ranks_most_fragile_first_and_flags_watchlist():
    region = _region()
    scores = [d["score"] for d in region["districts"]]
    assert scores == sorted(scores)                    # ascending resilience
    assert [d["rank"] for d in region["districts"]] == \
        list(range(1, len(scores) + 1))
    fragile = region["districts"][0]["district_code"]
    assert region["structurally_vulnerable_districts"] == [fragile]


def test_region_rollup_is_deterministic():
    assert _region() == _region()


def test_unknown_district_inputs_are_treated_as_neutral_not_dropped():
    region = re_eng.compute(
        districts=[{"code": "GAU", "name": "Kamrup"},
                   {"code": "AIZ", "name": "Aizawl"}],
        segments=[{"district_code": "GAU", "total_segments": 6,
                   "open_segments": 6, "avg_accessibility": 85.0}],
        supply=[], weather=[], facilities=[], vehicles=[])
    aiz = next(d for d in region["districts"]
               if d["district_code"] == "AIZ")
    assert aiz["score"] == re_eng.NEUTRAL              # neutral, still ranked
    gau = next(d for d in region["districts"]
               if d["district_code"] == "GAU")
    assert gau["score"] > aiz["score"]

# ------------------------------------------------------------------ helpers
def _district(**overrides):
    defaults = dict(code="GAU", name="Kamrup",
                    avg_accessibility=82.0, avg_days_of_supply=12.0,
                    total_segments=8, open_segments=8,
                    rainfall_mm_24h=10.0, forecast_mm_24h=5.0,
                    susceptibility_avg=30.0, hospitals=2, warehouses=2,
                    available_vehicles=3)
    return re_eng.compute_district(**{**defaults, **overrides})


def _region():
    return re_eng.compute(
        districts=[{"code": "GAU", "name": "Kamrup"},
                   {"code": "IMPHAL", "name": "Imphal West"}],
        segments=[
            {"district_code": "GAU", "total_segments": 8, "open_segments": 8,
             "avg_accessibility": 84.0, "avg_flood_susceptibility": 25.0,
             "avg_landslide_susceptibility": 20.0},
            {"district_code": "IMPHAL", "total_segments": 5, "open_segments": 1,
             "avg_accessibility": 40.0, "avg_flood_susceptibility": 88.0,
             "avg_landslide_susceptibility": 70.0}],
        supply=[{"district_code": "GAU", "avg_days_of_supply": 13.0},
                {"district_code": "IMPHAL", "avg_days_of_supply": 2.2}],
        weather=[{"district_code": "GAU", "rainfall_mm_24h": 15.0,
                  "forecast_mm_24h": 10.0},
                 {"district_code": "IMPHAL", "rainfall_mm_24h": 150.0,
                  "forecast_mm_24h": 90.0}],
        facilities=[{"district_code": "GAU", "hospitals": 2, "warehouses": 2},
                    {"district_code": "IMPHAL", "hospitals": 0,
                     "warehouses": 1}],
        vehicles=[{"district_code": "GAU", "available_vehicles": 3},
                  {"district_code": "IMPHAL", "available_vehicles": 0}])
