# -*- coding: utf-8 -*-
"""Route Redundancy Intelligence engine (Phase 23 · C21 · FR-C21.1).

PURE module — no DB, no network, fully unit-testable.

FR-C21.1: route redundancy intelligence — how many viable ways in/out does a
district have, and where is logistics fragile BY STRUCTURE rather than by
incident? Reuses the corridor data the Phase-10 routing graph is built from
(same accessibility/risk sources), classified at CORRIDOR (= road) grain:

    PRIMARY      the single best viable corridor serving the district
                 (most open capacity -> most accessible -> least risky)
    ALTERNATIVE   every other viable corridor
    EMERGENCY    subset of viable corridors kept open under stress:
                 avg accessibility >= EMERGENCY_MIN_ACCESSIBILITY AND
                 avg disruption risk <= EMERGENCY_MAX_RISK

Redundancy level (from ALTERNATIVE count — mirrors the source blueprint):
    >= 3  HIGH      2  MEDIUM      1  LOW      0  NONE

A district with <= 1 viable corridor is flagged:
    SINGLE-POINT LOGISTICS VULNERABILITY
(one landslide/closure cuts the district off entirely).
"""
from typing import Optional

# ---------------------------------------------------------------- thresholds
VIABLE_MAX_AVG_RISK = 70.0        # above this a corridor is not usable
EMERGENCY_MIN_ACCESSIBILITY = 60.0
EMERGENCY_MAX_AVG_RISK = 45.0

LEVELS = ("HIGH", "MEDIUM", "LOW", "NONE")
SINGLE_POINT_ALERT = "SINGLE-POINT LOGISTICS VULNERABILITY"


def level_for(alternatives: int) -> str:
    """MEDIUM at two alternates, per the blueprint example (1 primary + 2 alt)."""
    if alternatives >= 3:
        return "HIGH"
    if alternatives == 2:
        return "MEDIUM"
    if alternatives == 1:
        return "LOW"
    return "NONE"


# --------------------------------------------------------------- compute

def compute_district(*, code: str, name: Optional[str] = None,
                     corridors: list[dict]) -> dict:
    """Classify every corridor serving ONE district and score redundancy.

    `corridors`: [{road_code, total_segments, open_segments,
                   avg_risk, avg_accessibility}]  (grouped per road)
    """
    viable = sorted((c for c in corridors if is_viable(c)), key=_rank_key)
    primary_code = viable[0]["road_code"] if viable else None
    primary_taken = False

    classified = []
    primary = alternative = emergency = 0
    for c in corridors:
        entry = dict(c)
        if not is_viable(c):
            entry["role"] = "UNUSABLE"
            entry["viable"] = False
            entry["emergency_capable"] = False
        else:
            if c.get("road_code") == primary_code and not primary_taken:
                entry["role"] = "PRIMARY"
                primary = 1
                primary_taken = True
            else:
                entry["role"] = "ALTERNATIVE"
                alternative += 1
            entry["viable"] = True
            entry["emergency_capable"] = is_emergency_capable(c)
            if entry["emergency_capable"]:
                emergency += 1
        classified.append(entry)

    alternatives = len(viable) - 1 if viable else 0
    level = level_for(alternatives) if viable else "NONE"
    single_point = len(viable) <= 1
    lifeline = (viable[0]["road_code"] if single_point and viable else None)

    return {
        "district_code": code,
        "district_name": name or code,
        "primary_routes": primary,
        "alternative_routes": alternative,
        "emergency_routes": emergency,
        "viable_corridors": len(viable),
        "redundancy_level": level,
        "single_point_vulnerability": single_point,
        "alert": SINGLE_POINT_ALERT if single_point else None,
        "lifeline_corridor": lifeline,
        "corridors": [
            {"road_code": c.get("road_code"),
             "role": c["role"], "viable": c["viable"],
             "emergency_capable": c["emergency_capable"],
             "total_segments": int(c.get("total_segments") or 0),
             "open_segments": int(c.get("open_segments") or 0),
             "avg_risk": round(float(c.get("avg_risk") or 0.0), 1),
             "avg_accessibility":
                 (round(float(c["avg_accessibility"]), 1)
                  if c.get("avg_accessibility") is not None else None)}
            for c in classified],
    }


def compute(districts: list[dict], corridor_rows: list[dict]) -> dict:
    """Region-wide rollup.

    `districts`     : {code, name}
    `corridor_rows` : {district_code, road_code, total_segments,
                       open_segments, avg_risk, avg_accessibility}
                      grouped by (district_code, road_code)
    """
    by_district: dict[str, list[dict]] = {}
    for r in corridor_rows:
        by_district.setdefault(r["district_code"], []).append(r)

    results = [compute_district(code=d["code"], name=d.get("name"),
                                corridors=by_district.get(d["code"], []))
               for d in districts]

    # most fragile first: fewer alternates first; ties -> fewer emergency routes
    results.sort(key=lambda r: (r["alternative_routes"],
                                -r["emergency_routes"],
                                r["district_code"]))
    for rank, r in enumerate(results, start=1):
        r["rank"] = rank                     # 1 = most fragile

    vulnerable = [r["district_code"] for r in results
                  if r["single_point_vulnerability"]]
    return {
        "thresholds": {
            "viable_max_avg_risk": VIABLE_MAX_AVG_RISK,
            "emergency_min_accessibility": EMERGENCY_MIN_ACCESSIBILITY,
            "emergency_max_avg_risk": EMERGENCY_MAX_AVG_RISK,
        },
        "single_point_districts": vulnerable,
        "level_counts": {lvl: sum(1 for r in results
                                  if r["redundancy_level"] == lvl)
                         for lvl in LEVELS},
        # ascending redundancy — the structural-risk watchlist order
        "districts": results,
    }



def is_viable(corridor: dict) -> bool:
    """A corridor serves the district only while part of it is open and its
    average disruption risk stays below the usability ceiling."""
    return int(corridor.get("open_segments") or 0) > 0 \
        and float(corridor.get("avg_risk") or 0.0) <= VIABLE_MAX_AVG_RISK


def is_emergency_capable(corridor: dict) -> bool:
    """Emergency-grade: usable under stress (good accessibility, low risk)."""
    return float(corridor.get("avg_accessibility") or 0.0) \
        >= EMERGENCY_MIN_ACCESSIBILITY \
        and float(corridor.get("avg_risk") or 0.0) <= EMERGENCY_MAX_AVG_RISK


def _rank_key(corridor: dict):
    """Best corridor first: open capacity desc, accessibility desc, risk asc."""
    total = max(1, int(corridor.get("total_segments") or 1))
    return (-int(corridor.get("open_segments") or 0) / total,
            -float(corridor.get("avg_accessibility") or 0.0),
            float(corridor.get("avg_risk") or 0.0))
