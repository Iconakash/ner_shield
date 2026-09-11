# -*- coding: utf-8 -*-
"""Logistics digital twin (Phase 21 · lightweight simulation).

An in-memory, deterministic mirror of the operational picture:

    entities: roads · vehicles · warehouses · districts · hospitals ·
              shipments · weather · disruptions

Three pure operations (no DB, no network, fully unit-testable):

    build(...)   normalize world-state rows into twin entities
    step(...)    advance the twin clock N minutes (movement, recovery, decay)
    assess(...)  calculate the six source-mandated outputs:
                 affected shipments · ETA changes · alternate routes ·
                 supply shortage · critical cargo · recommended actions

Reuse mandate: ETA impact = Phase-11 expected-delay function; shortage =
Phase-9 probability curve; recommended actions = Phase-19 DIA cards. The twin
adds only STATE + TIME, never new math.
"""
import copy

from app.decisions import engine as dia
from app.shipments.service import AVG_SPEED_KPH, segment_delay_minutes
from app.supply.service import shortage_probability

ENTITY_TYPES = ("roads", "vehicles", "warehouses", "districts", "hospitals",
                "shipments", "weather", "disruptions")

# ---------------------------------------------------------------- parameters

DISRUPTION_RECOVERY_PER_HOUR = 8.0   # pts/hour risk recovers toward baseline
WEATHER_DECAY_PER_HOUR = 0.6         # exponential rainfall decay factor
VEHICLE_SPEED_KPH = AVG_SPEED_KPH    # twin cruise speed (35 kph)
SHORTAGE_EXPOSURE_HOURS = 24
CRITICAL_RISK_THRESHOLD = 60.0       # >= this = disruptive exposure

# ------------------------------------------------------------------ build

def build(*, segments: list[dict], vehicles: list[dict],
          warehouses: list[dict], hospitals: list[dict],
          districts: list[dict], shipments: list[dict],
          weather: list[dict], disruptions: list[dict]) -> dict:
    """Normalize world-state rows into twin entities.

    `segments`    : {segment_id, road_id, road_code, district_code, status,
                     length_km, baseline_risk}
    `vehicles`    : {id, code, vtype, status, district}
    `warehouses`  : {facility_id, code, name, district_code, inventory:
                     [{commodity, days_of_supply, daily_consumption,
                       incoming_quantity}]}
    `hospitals`   : {facility_id, code, name, district_code}
    `districts`   : {code, name}
    `shipments`   : {id, code, commodity, is_critical, dest_district,
                     vehicle_id, eta_minutes, segment_ids: [...]}
    `weather`     : {district_code, rainfall_mm_24h, forecast_mm_24h}
    `disruptions` : {segment_id, risk_current, label}  (latest per segment)
    """
    seg_by_id = {}
    for s in segments:
        seg = {**s, "risk_current": float(s.get("baseline_risk", 20.0))}
        seg_by_id[s["segment_id"]] = seg
    for d in disruptions:                       # live disruptions override
        if d["segment_id"] in seg_by_id:
            seg_by_id[d["segment_id"]]["risk_current"] = \
                clamp(d["risk_current"], 0.0, 99.0)
            seg_by_id[d["segment_id"]]["disrupted"] = True

    return {
        "roads": _unique(segments, "road_id", "road_code"),
        "segments": list(seg_by_id.values()),
        "vehicles": [dict(v) for v in vehicles],
        "warehouses": [dict(w) for w in warehouses],
        "hospitals": [dict(h) for h in hospitals],
        "districts": [dict(d) for d in districts],
        "shipments": [{
            **{k: sh.get(k) for k in ("id", "code", "commodity", "is_critical",
                                      "dest_district", "vehicle_id")},
            "planned_eta_minutes": float(sh.get("eta_minutes") or 120.0),
            "eta_minutes": float(sh.get("eta_minutes") or 120.0),
            "progress_pct": 0.0,
            "segment_ids": list(sh.get("segment_ids", [])),
        } for sh in shipments],
        "weather": [dict(w) | {"rainfall_mm_24h":
                               float(w.get("rainfall_mm_24h", 0.0))}
                    for w in weather],
        "disruptions": [
            {"segment_id": d_["segment_id"],
             "risk_current": clamp(d_["risk_current"], 0.0, 99.0),
             "label": d_.get("label")} for d_ in disruptions],
    }


def _unique(rows: list[dict], *keys: str) -> list[dict]:
    seen, out = set(), []
    for r in rows:
        ident = tuple(r.get(k) for k in keys)
        if ident not in seen and any(ident):
            seen.add(ident)
            out.append({k: r.get(k) for k in keys})
    return out


def clamp(v: float, lo: float = 0.0, hi: float = 99.0) -> float:
    return round(max(lo, min(hi, float(v))), 1)

# ------------------------------------------------------------------ step

def step(twin: dict, minutes: int = 60) -> dict:
    """Advance the twin clock. Returns a NEW twin (input never mutated).

    * shipments progress along their route; ETA accrues extra delay while any
      route segment is disrupted (Phase-11 expected-value delay)
    * disruption risk recovers toward the segment baseline
    * rainfall decays exponentially (weather clears)
    """
    t = copy.deepcopy(twin)
    hours = minutes / 60.0
    seg_by_id = {s["segment_id"]: s for s in t["segments"]}

    # disruptions recover toward baseline risk
    for seg in t["segments"]:
        if seg.get("disrupted"):
            floor = float(seg.get("baseline_risk", 20.0))
            seg["risk_current"] = clamp(
                max(floor, seg["risk_current"]
                    - DISRUPTION_RECOVERY_PER_HOUR * hours))

    # shipments move + accrue delay on disrupted corridors
    for sh in t["shipments"]:
        exposed = [seg_by_id[sid] for sid in sh["segment_ids"]
                   if sid in seg_by_id]
        worst_risk = max((s["risk_current"] for s in exposed), default=0.0)
        delay_min = round(segment_delay_minutes(
            sum(s.get("length_km", 20.0) for s in exposed) / max(
                1, len(exposed) or 1),
            VEHICLE_SPEED_KPH, worst_risk) * (minutes / 60.0), 1) \
            if worst_risk >= CRITICAL_RISK_THRESHOLD else 0.0
        moved_pct = min(100.0, VEHICLE_SPEED_KPH * (hours)
                        / max(sh["planned_eta_minutes"] / 60.0, 0.1) * 100.0)
        sh["progress_pct"] = round(min(100.0,
                                       sh.get("progress_pct", 0.0)
                                       + moved_pct), 1)
        sh["eta_minutes"] = round(max(0.0,
                                      sh["eta_minutes"] - minutes + delay_min),
                                  1)

    # weather clears
    decay = WEATHER_DECAY_PER_HOUR ** hours
    for w in t["weather"]:
        w["rainfall_mm_24h"] = round(w["rainfall_mm_24h"] * decay, 1)

    t["clock_minutes"] = t.get("clock_minutes", 0) + minutes
    return t

# ------------------------------------------------------------------ assess

def assess(twin: dict) -> dict:
    """The six mandated calculations over the twin's CURRENT state."""
    seg_by_id = {s["segment_id"]: s for s in twin["segments"]}
    open_by_district: dict[str, int] = {}
    for s in twin["segments"]:
        if s.get("status", "OPEN") != "CLOSED":
            open_by_district[s.get("district_code")] = \
                open_by_district.get(s.get("district_code"), 0) + 1

    affected, eta_changes, critical_cargo, alternates = [], [], [], []
    for sh in twin["shipments"]:
        exposed = [seg_by_id[sid] for sid in sh["segment_ids"]
                   if sid in seg_by_id]
        hit = [s for s in exposed
               if s.get("risk_current", 0) >= CRITICAL_RISK_THRESHOLD
               or s.get("status") == "CLOSED"]
        delay = round(max(0.0, sh["planned_eta_minutes"] - sh["eta_minutes"]), 1)
        entry = {
            "id": sh["id"], "code": sh["code"],
            "commodity": sh.get("commodity"),
            "is_critical": bool(sh.get("is_critical")),
            "eta_minutes": sh["eta_minutes"],
            "delay_minutes": delay,
            "exposed_segments": [s["segment_id"] for s in hit],
            "progress_pct": sh.get("progress_pct", 0.0),
        }
        if hit:
            affected.append(entry)
            eta_changes.append(entry)
        if entry["is_critical"]:
            critical_cargo.append(entry)
        district = sh.get("dest_district")
        alt_count = max(0, open_by_district.get(district, 0)
                        - (1 if hit else 0))
        alternates.append({
            "shipment_id": sh["id"], "district": district,
            "viable_alternates": alt_count,
            "reroute_possible": alt_count > 0 and bool(hit),
        })

    shortage = _shortage_points(twin, affected)
    actions = _recommend(twin, affected, shortage)

    return {
        "affected_shipments": affected,
        "eta_changes": eta_changes,
        "alternate_routes": alternates,
        "supply_shortage": shortage,
        "critical_cargo": critical_cargo,
        "recommended_actions": actions,
        "counts": {
            "roads": len(twin["roads"]),
            "segments": len(twin["segments"]),
            "vehicles": len(twin["vehicles"]),
            "warehouses": len(twin["warehouses"]),
            "hospitals": len(twin["hospitals"]),
            "districts": len(twin["districts"]),
            "shipments": len(twin["shipments"]),
            "weather_stations": len(twin["weather"]),
            "active_disruptions": sum(1 for s in twin["segments"]
                                      if s.get("disrupted")),
            "affected_shipments": len(affected),
            "critical_cargo": len(critical_cargo),
        },
    }

def _shortage_points(twin: dict, affected: list[dict]) -> list[dict]:
    points = []
    for wh in twin["warehouses"]:
        for inv in wh.get("inventory", []):
            prob = shortage_probability(
                inv.get("days_of_supply"), inv.get("commodity", "GENERAL"),
                float(inv.get("incoming_quantity", 0.0)),
                float(inv.get("daily_consumption", 0.0)),
                exposure_hours=SHORTAGE_EXPOSURE_HOURS,
                disruption_context=bool(affected))
            if prob >= dia.PREPOSITION_MIN_PROBABILITY or \
                    inv.get("commodity") in ("MEDICINE", "EMERGENCY_SUPPLIES",
                                             "WATER", "EMERGENCY_FOOD"):
                points.append({
                    "warehouse": wh.get("code"),
                    "district_code": wh.get("district_code"),
                    "commodity": inv.get("commodity"),
                    "days_of_supply": float(inv.get("days_of_supply", 99)),
                    "shortage_probability": prob})
    return points


def _recommend(twin: dict, affected: list[dict],
               shortage: list[dict]) -> list[dict]:
    """Government actions via the Phase-19 DIA rules."""
    recs: list[dict] = []
    for sh in affected:
        if not sh["exposed_segments"]:
            continue
        seg = next((s for s in twin["segments"]
                    if s["segment_id"] == sh["exposed_segments"][0]), {})
        recs.append(dia.recommend_reroute(
            {"id": sh["id"], "code": sh["code"],
             "commodity": sh.get("commodity"),
             "is_critical": sh.get("is_critical"),
             "dest_district": None},
            {"segment_id": seg.get("segment_id", "twin"),
             "overall_label": "CRITICAL"
             if seg.get("status") == "CLOSED" else "HIGH",
             "risk_current": seg.get("risk_current", 60.0),
             "risk_24h": seg.get("risk_current", 60.0),
             "road_code": seg.get("road_code", "TWIN")}))
    for sp in shortage:
        if sp["shortage_probability"] >= dia.PREPOSITION_MIN_PROBABILITY:
            recs.append(dia.recommend_preposition({
                "inventory_id": f"{sp['warehouse']}:{sp['commodity']}",
                "district_code": sp["district_code"],
                "commodity": sp["commodity"],
                "shortage_probability": sp["shortage_probability"],
                "days_of_supply": sp["days_of_supply"],
                "daily_consumption": 100.0,
                "expected_disruption_hours": SHORTAGE_EXPOSURE_HOURS}))
    return dia.rank(dia.dedupe(recs))[:10]


def run(twin: dict, horizon_minutes: int = 360,
        step_minutes: int = 60) -> dict:
    """Headless forward run: trajectory snapshots + final assessment."""
    steps = max(1, min(int(horizon_minutes) // max(5, int(step_minutes)), 48))
    t, trajectory = twin, []
    for i in range(steps):
        remaining = horizon_minutes - i * step_minutes
        t = step(t, min(step_minutes, max(5, remaining)))
        a = assess(t)
        trajectory.append({
            "at_minute": t.get("clock_minutes", (i + 1) * step_minutes),
            "affected_shipments": len(a["affected_shipments"]),
            "avg_eta_minutes": (round(sum(s["eta_minutes"]
                                          for s in t["shipments"])
                                      / len(t["shipments"]), 1)
                                if t["shipments"] else 0.0),
            "avg_risk": (round(sum(s["risk_current"] for s in t["segments"])
                               / len(t["segments"]), 1)
                         if t["segments"] else 0.0),
            "shortage_points": len(a["supply_shortage"]),
        })
    return {"trajectory": trajectory, "final_state": t,
            "assessment": assess(t)}




