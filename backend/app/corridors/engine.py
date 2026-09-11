# -*- coding: utf-8 -*-
"""Critical Corridor Ranking engine (Phase 24 · C22 · FR-C22.1).

PURE module — no DB, no network, fully unit-testable. CSV export lives here
too so it is testable without HTTP.

FR-C22.1: ranked table of corridors by STRATEGIC CRITICALITY, exportable —
infrastructure-prioritization intelligence for government planners.

Five frozen factors (0-100 each, higher = more critical):

    population_dependency     communities served by the corridor (linear cap)
    essential_goods_dependency   active shipments riding the corridor
                              (critical commodities double-weighted)
    hospital_connectivity     hospitals in the districts the corridor serves
    scarcity                  LACK of alternative routes: other viable roads
                              serving the same districts (fewer => higher)
    disruption_probability    avg latest 24h disruption risk on its segments

Composite = frozen weight vector x factors (weights sum to 1.0), banded:
    >= 75 CRITICAL · >= 60 HIGH · >= 45 MEDIUM · else LOW
"""
from typing import Optional

# ------------------------------------------------------------- frozen contract

FACTOR_KEYS = ("population_dependency", "essential_goods_dependency",
               "hospital_connectivity", "scarcity", "disruption_probability")

FACTOR_LABELS = {
    "population_dependency": "Population Dependency",
    "essential_goods_dependency": "Essential Goods Dependency",
    "hospital_connectivity": "Hospital Connectivity",
    "scarcity": "Alternative Route Scarcity",
    "disruption_probability": "Disruption Probability",
}

WEIGHTS_VERSION = "v1"
WEIGHTS = {
    "population_dependency": 0.25,
    "essential_goods_dependency": 0.20,
    "hospital_connectivity": 0.20,
    "scarcity": 0.15,
    "disruption_probability": 0.20,
}

# factor calibration knobs
POPULATION_CAP = 200_000          # people served reaching full marks
GOODS_TARGET = 10                 # weighted active shipments for full marks
CRITICAL_SHIPMENT_WEIGHT = 2      # critical commodities count double
HOSPITAL_TARGET = 3               # hospitals served for full marks
ALTERNATIVES_TARGET = 4           # this many viable alternates -> scarcity 0

BANDS = ((75.0, "CRITICAL"), (60.0, "HIGH"), (45.0, "MEDIUM"), (0.0, "LOW"))


def band_for(score: float) -> str:
    for floor, label in BANDS:
        if score >= floor:
            return label
    return BANDS[-1][1]


def clamp(v: float) -> float:
    return round(max(0.0, min(100.0, float(v))), 1)

# ------------------------------------------------------------------ factors

def population_factor(population_served: Optional[int]) -> float:
    """Linear-cap normalization (same pattern as the Phase-8 impact engine)."""
    if population_served is None:
        return 0.0
    return clamp(100.0 * int(population_served) / POPULATION_CAP)


def goods_factor(critical_shipments: Optional[int],
                 other_shipments: Optional[int]) -> float:
    """Essential-goods flow riding the corridor; critical cargo doubles."""
    flow = CRITICAL_SHIPMENT_WEIGHT * int(critical_shipments or 0) \
        + int(other_shipments or 0)
    return clamp(100.0 * flow / GOODS_TARGET)


def hospital_factor(hospitals_served: Optional[int]) -> float:
    if hospitals_served is None:
        return 0.0
    return clamp(100.0 * int(hospitals_served) / HOSPITAL_TARGET)


def scarcity_factor(viable_alternates: Optional[int]) -> float:
    """LACK of alternatives: 0 alternates => 100, ALTERNATIVES_TARGET => 0."""
    n = max(0, int(viable_alternates or 0))
    return clamp(100.0 * (1.0 - min(1.0, n / ALTERNATIVES_TARGET)))


def disruption_factor(avg_risk: Optional[float]) -> float:
    """Latest 24h disruption probability used directly (already 0-100)."""
    if avg_risk is None:
        return 0.0
    return clamp(avg_risk)

# ------------------------------------------------------------------- compute

def rank_corridor(*, road_code: str, name: Optional[str] = None,
                  population_served: Optional[int] = None,
                  critical_shipments: Optional[int] = None,
                  other_shipments: Optional[int] = None,
                  hospitals_served: Optional[int] = None,
                  viable_alternates: Optional[int] = None,
                  avg_risk: Optional[float] = None,
                  total_segments: Optional[int] = None,
                  open_segments: Optional[int] = None,
                  districts_served: Optional[int] = None) -> dict:
    """Criticality score + VISIBLE factor breakdown for ONE corridor."""
    factors = {
        "population_dependency":
            population_factor(population_served),
        "essential_goods_dependency":
            goods_factor(critical_shipments, other_shipments),
        "hospital_connectivity":
            hospital_factor(hospitals_served),
        "scarcity":
            scarcity_factor(viable_alternates),
        "disruption_probability":
            disruption_factor(avg_risk),
    }
    score = round(sum(WEIGHTS[k] * factors[k] for k in FACTOR_KEYS), 1)
    drivers = sorted(factors, key=lambda k: -factors[k])[:2]
    return {
        "road_code": road_code,
        "road_name": name or road_code,
        "score": score,
        "band": band_for(score),
        "factors": {FACTOR_LABELS[k]: factors[k] for k in FACTOR_KEYS},
        "top_drivers": [FACTOR_LABELS[k] for k in drivers],
        "inputs": {
            "population_served": population_served,
            "critical_shipments": critical_shipments,
            "other_shipments": other_shipments,
            "hospitals_served": hospitals_served,
            "viable_alternates": viable_alternates,
            "avg_risk": avg_risk,
            "total_segments": total_segments,
            "open_segments": open_segments,
            "districts_served": districts_served,
        },
    }

def compute(district_populations: dict[str, int],
            district_hospitals: dict[str, int],
            corridor_rows: list[dict],
            corridor_districts: list[dict],
            corridor_shipments: list[dict]) -> dict:
    """Region-wide ranked table.

    `district_populations` : {district_code: population}
    `district_hospitals`   : {district_code: hospital count}
    `corridor_rows`        : {road_id, road_code, name, total_segments,
                              open_segments, avg_risk}
    `corridor_districts`   : {road_id, district_code}  (serving map)
    `corridor_shipments`   : {road_id, critical_shipments, other_shipments}
    """
    dists_by_road: dict[str, set] = {}
    for r in corridor_districts:
        dists_by_road.setdefault(r["road_id"], set()).add(
            r["district_code"])

    # viable alternates per corridor: other roads sharing >=1 served district
    roads_by_district: dict[str, set] = {}
    for r in corridor_districts:
        roads_by_district.setdefault(r["district_code"], set()).add(
            r["road_id"])
    ships_by_road = {r["road_id"]: r for r in corridor_shipments}

    rows = []
    for c in corridor_rows:
        rid = c["road_id"]
        served = dists_by_road.get(rid, set())
        population = sum(district_populations.get(d, 0) for d in served)
        hospitals = sum(district_hospitals.get(d, 0) for d in served)
        alternates = set()
        for d in served:
            alternates |= roads_by_district.get(d, set())
        alternates.discard(rid)
        ships = ships_by_road.get(rid, {})
        rows.append(rank_corridor(
            road_code=c["road_code"], name=c.get("name"),
            population_served=population,
            critical_shipments=ships.get("critical_shipments"),
            other_shipments=ships.get("other_shipments"),
            hospitals_served=hospitals,
            viable_alternates=len(alternates),
            avg_risk=(float(c["avg_risk"])
                      if c.get("avg_risk") is not None else None),
            total_segments=c.get("total_segments"),
            open_segments=c.get("open_segments"),
            districts_served=len(served)))

    rows.sort(key=lambda r: (-r["score"], r["road_code"]))
    for i, r in enumerate(rows, start=1):
        r["rank"] = i
    return {
        "weights_version": WEIGHTS_VERSION,
        "weights": dict(WEIGHTS),
        "band_thresholds": {"CRITICAL": BANDS[0][0], "HIGH": BANDS[1][0],
                            "MEDIUM": BANDS[2][0]},
        "counts": {label: sum(1 for r in rows if r["band"] == label)
                   for label in ("CRITICAL", "HIGH", "MEDIUM", "LOW")},
        # descending criticality — the prioritization order
        "corridors": rows,
    }

CSV_HEADER = ["rank", "road_code", "road_name", "band", "score",
              "population_dependency", "essential_goods_dependency",
              "hospital_connectivity", "scarcity", "disruption_probability",
              "population_served", "districts_served", "hospitals_served",
              "viable_alternates", "avg_risk"]


def to_csv(ranking: dict) -> str:
    """FR-C22.1 exportable: stable CSV of the ranked table."""
    lines = [",".join(CSV_HEADER)]
    for r in ranking.get("corridors", []):
        f = r["factors"]
        inp = r["inputs"]
        row = [r["rank"], r["road_code"], f'"{r["road_name"]}"', r["band"],
               r["score"],
               f[FACTOR_LABELS["population_dependency"]],
               f[FACTOR_LABELS["essential_goods_dependency"]],
               f[FACTOR_LABELS["hospital_connectivity"]],
               f[FACTOR_LABELS["scarcity"]],
               f[FACTOR_LABELS["disruption_probability"]],
               inp["population_served"], inp["districts_served"],
               inp["hospitals_served"], inp["viable_alternates"],
               inp["avg_risk"]]
        lines.append(",".join("" if v is None else str(v) for v in row))
    return "\n".join(lines) + "\n"



