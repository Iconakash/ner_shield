# -*- coding: utf-8 -*-
"""Resilience Score engine (Phase 22 · C20 · FR-C20.1).

PURE module — no DB, no network, fully unit-testable.

FR-C20.1: Composite Resilience Score per district — accessibility trend x
redundancy x stock cover x response capacity, with the COMPONENT BREAKDOWN
VISIBLE so authorities can identify STRUCTURALLY VULNERABLE districts before
an incident occurs (pre-disaster posture, not live incident reporting).

Five frozen components (0-100 each, higher = more resilient):

    connectivity          avg latest accessibility score of the district's
                          segments (Phase 5 engine output)
    supply_availability   stock cover: avg days-of-supply across inventory
                          (Phase 9 data), full marks at STOCK_TARGET_DAYS
    route_redundancy      open-segment share + corridor depth beyond a single
                          lifeline route (C21 groundwork)
    weather_safety        INVERTED weather exposure: rainfall observed +
                          forecast vs terrain susceptibility (Phase 6 features)
    emergency_capacity    hospitals + warehouses + available vehicles present

Composite = frozen weight vector x components (weights sum to 1.0).
Documented neutrality rule: a component with NO data scores NEUTRAL (50),
never 0 — absence of evidence is not evidence of fragility.
"""
from typing import Optional

# ------------------------------------------------------------- frozen contract

COMPONENT_KEYS = ("connectivity", "supply_availability", "route_redundancy",
                  "weather_safety", "emergency_capacity")

COMPONENT_LABELS = {
    "connectivity": "Connectivity",
    "supply_availability": "Supply Availability",
    "route_redundancy": "Route Redundancy",
    "weather_safety": "Weather Exposure",
    "emergency_capacity": "Emergency Capacity",
}

# Frozen weight vector (v1 calibration). Sum MUST be 1.0 (guarded by test).
WEIGHTS_VERSION = "v1"
WEIGHTS = {
    "connectivity": 0.30,
    "supply_availability": 0.25,
    "route_redundancy": 0.20,
    "weather_safety": 0.15,
    "emergency_capacity": 0.10,
}

NEUTRAL = 50.0                    # component value when no data exists
STRUCTURAL_VULNERABILITY_BELOW = 60.0   # flag districts under this score

# component calibration knobs
STOCK_TARGET_DAYS = 14.0          # >= 2 weeks cover == full supply marks
REDUNDANCY_OPEN_SHARE_WEIGHT = 0.6
REDUNDANCY_DEPTH_TARGET = 3       # >= 4 open segments == full depth marks
RAINFALL_SATURATION_MM = 200.0    # observed+half-forecast reaching this = 0 rain margin
SUSCEPTIBILITY_SHARE = 0.35       # terrain share of the weather penalty
CAPACITY_TARGET = 6.0             # weighted asset presence for full marks
HOSPITAL_WEIGHT_CAPACITY = 1.5
WAREHOUSE_WEIGHT_CAPACITY = 1.0
VEHICLE_WEIGHT_CAPACITY = 1.0

BANDS = (                         # (floor, label) — first match wins
    (80.0, "RESILIENT"),
    (65.0, "STABLE"),
    (50.0, "GUARDED"),
    (35.0, "ELEVATED"),
    (0.0, "CRITICAL"),
)


def clamp(v: float) -> float:
    return round(max(0.0, min(100.0, float(v))), 1)


def band_for(score: float) -> str:
    for floor, label in BANDS:
        if score >= floor:
            return label
    return BANDS[-1][1]

# ---------------------------------------------------------------- components

def connectivity_component(avg_accessibility: Optional[float]) -> float:
    """Avg latest Phase-5 accessibility score, used directly."""
    return NEUTRAL if avg_accessibility is None else clamp(avg_accessibility)


def supply_availability_component(avg_days_of_supply: Optional[float]) -> float:
    """Stock cover vs the 2-week target (None -> neutral)."""
    if avg_days_of_supply is None:
        return NEUTRAL
    return clamp(100.0 * min(1.0, float(avg_days_of_supply) / STOCK_TARGET_DAYS))


def route_redundancy_component(total_segments: Optional[int],
                               open_segments: Optional[int]) -> float:
    """Open share of the network + depth beyond one lifeline corridor."""
    total = int(total_segments or 0)
    if total <= 0:
        return NEUTRAL
    opening = int(open_segments or 0)
    share = opening / total
    depth = min(1.0, max(0, opening - 1) / REDUNDANCY_DEPTH_TARGET)
    return clamp(100.0 * (REDUNDANCY_OPEN_SHARE_WEIGHT * share
                          + (1.0 - REDUNDANCY_OPEN_SHARE_WEIGHT) * depth))


def weather_safety_component(rainfall_mm_24h: Optional[float],
                             forecast_mm_24h: Optional[float],
                             susceptibility_avg: Optional[float]) -> float:
    """INVERTED exposure: wet + susceptible terrain scores low."""
    if rainfall_mm_24h is None and forecast_mm_24h is None \
            and susceptibility_avg is None:
        return NEUTRAL                   # no data -> neutral, never fragile
    effective_rain = float(rainfall_mm_24h or 0.0) \
        + 0.5 * float(forecast_mm_24h or 0.0)
    rain_idx = min(1.0, effective_rain / RAINFALL_SATURATION_MM)
    susc = (float(susceptibility_avg) / 100.0
            if susceptibility_avg is not None else NEUTRAL / 100.0)
    penalty = 100.0 * ((1.0 - SUSCEPTIBILITY_SHARE) * rain_idx
                       + SUSCEPTIBILITY_SHARE * susc)
    return clamp(100.0 - penalty)


def emergency_capacity_component(hospitals: Optional[int],
                                 warehouses: Optional[int],
                                 available_vehicles: Optional[int]) -> float:
    """Response assets present. All-None (no data) -> neutral; real zeros count."""
    if hospitals is None and warehouses is None and available_vehicles is None:
        return NEUTRAL
    load = (HOSPITAL_WEIGHT_CAPACITY * int(hospitals or 0)
            + WAREHOUSE_WEIGHT_CAPACITY * int(warehouses or 0)
            + VEHICLE_WEIGHT_CAPACITY * int(available_vehicles or 0))
    return clamp(100.0 * min(1.0, load / CAPACITY_TARGET))


# -------------------------------------------------------------------- compute

def compute_district(*, code: str, name: Optional[str] = None,
                     avg_accessibility: Optional[float] = None,
                     avg_days_of_supply: Optional[float] = None,
                     total_segments: Optional[int] = None,
                     open_segments: Optional[int] = None,
                     rainfall_mm_24h: Optional[float] = None,
                     forecast_mm_24h: Optional[float] = None,
                     susceptibility_avg: Optional[float] = None,
                     hospitals: Optional[int] = None,
                     warehouses: Optional[int] = None,
                     available_vehicles: Optional[int] = None) -> dict:
    """Composite score + VISIBLE component breakdown for ONE district."""
    components = {
        "connectivity":
            connectivity_component(avg_accessibility),
        "supply_availability":
            supply_availability_component(avg_days_of_supply),
        "route_redundancy":
            route_redundancy_component(total_segments, open_segments),
        "weather_safety":
            weather_safety_component(rainfall_mm_24h, forecast_mm_24h,
                                     susceptibility_avg),
        "emergency_capacity":
            emergency_capacity_component(hospitals, warehouses,
                                         available_vehicles),
    }
    score = round(sum(WEIGHTS[k] * components[k] for k in COMPONENT_KEYS), 1)
    weakest = sorted(components, key=lambda k: components[k])[:2]
    return {
        "district_code": code,
        "district_name": name or code,
        "score": score,
        "score_display": int(round(score)),
        "band": band_for(score),
        "structurally_vulnerable": score < STRUCTURAL_VULNERABILITY_BELOW,
        "components": {COMPONENT_LABELS[k]: components[k]
                       for k in COMPONENT_KEYS},
        "weakest_components": [COMPONENT_LABELS[k] for k in weakest],
        "inputs": {
            "avg_accessibility": avg_accessibility,
            "avg_days_of_supply": avg_days_of_supply,
            "total_segments": total_segments,
            "open_segments": open_segments,
            "rainfall_mm_24h": rainfall_mm_24h,
            "forecast_mm_24h": forecast_mm_24h,
            "susceptibility_avg": susceptibility_avg,
            "hospitals": hospitals,
            "warehouses": warehouses,
            "available_vehicles": available_vehicles,
        },
    }


def compute(districts: list[dict], segments: list[dict],
            supply: list[dict], weather: list[dict],
            facilities: list[dict], vehicles: list[dict]) -> dict:
    """Region-wide rollup.

    `districts`  : {code, name}
    `segments`   : {district_code, total_segments, open_segments,
                    avg_accessibility, susceptibility_avg}   (grouped rows)
    `supply`     : {district_code, avg_days_of_supply}
    `weather`    : {district_code, rainfall_mm_24h, forecast_mm_24h}
    `facilities` : {district_code, hospitals, warehouses}
    `vehicles`   : {district_code, available_vehicles}
    """
    seg_by = {r["district_code"]: r for r in segments}
    sup_by = {r["district_code"]: r for r in supply}
    wx_by = {r["district_code"]: r for r in weather}
    fac_by = {r["district_code"]: r for r in facilities}
    veh_by = {r["district_code"]: r for r in vehicles}

    results = []
    for d in districts:
        code = d["code"]
        seg, sup = seg_by.get(code, {}), sup_by.get(code, {})
        wx, fac, veh = (wx_by.get(code, {}), fac_by.get(code, {}),
                        veh_by.get(code, {}))
        susc = None
        if seg.get("avg_flood_susceptibility") is not None \
                and seg.get("avg_landslide_susceptibility") is not None:
            susc = (float(seg["avg_flood_susceptibility"])
                    + float(seg["avg_landslide_susceptibility"])) / 2.0
        results.append(compute_district(
            code=code, name=d.get("name"),
            avg_accessibility=(float(seg["avg_accessibility"])
                               if seg.get("avg_accessibility") is not None
                               else None),
            avg_days_of_supply=(float(sup["avg_days_of_supply"])
                                if sup.get("avg_days_of_supply") is not None
                                else None),
            total_segments=seg.get("total_segments"),
            open_segments=seg.get("open_segments"),
            rainfall_mm_24h=wx.get("rainfall_mm_24h"),
            forecast_mm_24h=wx.get("forecast_mm_24h"),
            susceptibility_avg=susc,
            hospitals=fac.get("hospitals"),
            warehouses=fac.get("warehouses"),
            available_vehicles=veh.get("available_vehicles")))

    results.sort(key=lambda r: r["score"])          # most fragile first
    for rank, r in enumerate(results, start=1):
        r["rank"] = rank                             # 1 = least resilient
    vulnerable = [r["district_code"] for r in results
                  if r["structurally_vulnerable"]]
    return {
        "weights_version": WEIGHTS_VERSION,
        "weights": dict(WEIGHTS),
        "vulnerability_threshold": STRUCTURAL_VULNERABILITY_BELOW,
        "structurally_vulnerable_districts": vulnerable,
        "region_avg_score": (round(sum(r["score"] for r in results)
                                   / len(results), 1) if results else 0.0),
        # ascending resilience — the pre-incident watchlist order
        "districts": results,
    }

