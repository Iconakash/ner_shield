# -*- coding: utf-8 -*-
"""What-if disaster simulator (Phase 20 · FR-C18.1).

PURE module — a hypothetical event is injected into a snapshot of the current
world state; NOTHING is persisted (a what-if must never contaminate live data).

Mandated cascade (source doc): every run returns these eight named stages —

    Rainfall -> Road risk -> Accessibility -> Shipments ->
    ETA -> Supply -> Alternative routes -> Government actions

Reuse over reinvention: ETA impact uses the Phase-11 expected-delay function,
supply projections use the Phase-9 shortage probability curve, and the final
stage emits real Phase-19 DIA recommendation cards so the simulator hands the
operator actionable, approval-mapped next steps rather than pretty numbers.
"""

# reuse existing PURE engines (never duplicate math that already has tests)
from app.decisions import engine as dia
from app.shipments.service import AVG_SPEED_KPH, segment_delay_minutes
from app.supply.service import shortage_probability

EVENT_TYPES = ("HEAVY_RAINFALL", "LANDSLIDE", "FLOOD")
INTENSITIES = ("LOW", "MODERATE", "SEVERE", "EXTREME")

STAGE_NAMES = ("Rainfall", "Road risk", "Accessibility", "Shipments",
               "ETA", "Supply", "Alternative routes", "Government actions")

# ------------------------------------------------------------------ parameters

BASE_MM_24H = {"HEAVY_RAINFALL": {"LOW": 60, "MODERATE": 120,
                                  "SEVERE": 220, "EXTREME": 350},
               # flood/landslide events are triggered by saturated ground;
               # model their hydrological pre-load as equivalent rainfall
               "FLOOD": {"LOW": 90, "MODERATE": 160, "SEVERE": 260,
                         "EXTREME": 380},
               "LANDSLIDE": {"LOW": 40, "MODERATE": 90, "SEVERE": 180,
                             "EXTREME": 300}}

# how much of each terrain susceptibility a given event type exercises
SUSCEPTIBILITY_MIX = {
    "HEAVY_RAINFALL": {"flood": 0.65, "landslide": 0.35},
    "FLOOD": {"flood": 1.00, "landslide": 0.00},
    "LANDSLIDE": {"flood": 0.00, "landslide": 1.00},
}

RISK_UPLIFT_PER_EFFECTIVE_MM = 0.35   # tuned: EXTREME/12h ~ +70 on susc=80%
ACC_DROP_PER_RISK_POINT = 0.9         # accessibility falls ~1:1 with risk
CLOSURE_RISK_THRESHOLD = 85.0
PARTIAL_RISK_THRESHOLD = 60.0
MONITOR_LABELS = ("HIGH", "CRITICAL")
PREPOSITION_MIN_PROBABILITY = 55.0    # watchlist parity
REROUTE_DELAY_MINUTES = 30.0          # delay worth an officer's attention

LABEL_THRESHOLDS = ((80.0, "CRITICAL"), (60.0, "HIGH"), (40.0, "ELEVATED"),
                    (20.0, "GUARDED"))

# ------------------------------------------------------------------- helpers

def clamp(v: float, lo: float = 0.0, hi: float = 99.0) -> float:
    return round(max(lo, min(hi, v)), 1)


def risk_label(risk_pct: float) -> str:
    for threshold, label in LABEL_THRESHOLDS:
        if risk_pct >= threshold:
            return label
    return "LOW"


def acc_classification(score: float) -> str:
    """Same frozen vocabulary as accessibility_scores (0005 migration)."""
    if score >= 70:
        return "SAFE"
    if score >= 45:
        return "CAUTION"
    if score >= 25:
        return "HIGH_RISK"
    return "CRITICAL"


def effective_load_mm(event_type: str, intensity: str,
                      duration_hours: int) -> float:
    """Rainfall stage: base depth scaled by duration exposure (12h ≈ 0.75x)."""
    duration_factor = min(1.5, 0.5 + 0.5 * max(1, duration_hours) / 24.0)
    return round(BASE_MM_24H[event_type][intensity] * duration_factor, 1)


def segment_susceptibility(event_type: str, seg: dict) -> float:
    mix = SUSCEPTIBILITY_MIX[event_type]
    return round(mix["flood"] * seg.get("flood_susceptibility", 50.0)
                 + mix["landslide"] * seg.get("landslide_susceptibility", 50.0),
                 1)

# ------------------------------------------------------------- the cascade

def project_segment(event_type: str, intensity: str, duration_hours: int,
                    seg: dict) -> dict:
    """Rainfall -> Road risk -> Accessibility for ONE segment.

    `seg`: {segment_id, road_code, district_code, baseline_risk,
            baseline_acc, flood_susceptibility, landslide_susceptibility,
            length_m, alternates}
    """
    load = effective_load_mm(event_type, intensity, duration_hours)
    susc = segment_susceptibility(event_type, seg)
    uplift = round(min(99.0 - seg["baseline_risk"],
                       RISK_UPLIFT_PER_EFFECTIVE_MM * load * susc / 100.0), 1)

    risk_after = clamp(seg["baseline_risk"] + uplift)
    acc_after = round(max(0.0, seg["baseline_acc"]
                          - uplift * ACC_DROP_PER_RISK_POINT), 1)

    if risk_after >= CLOSURE_RISK_THRESHOLD or acc_after < 15:
        projected_status = "CLOSED"
    elif risk_after >= PARTIAL_RISK_THRESHOLD:
        projected_status = "PARTIAL"
    else:
        projected_status = "OPEN"

    return {
        "segment_id": seg["segment_id"], "road_code": seg.get("road_code"),
        "district_code": seg.get("district_code"),
        "susceptibility": susc, "risk_uplift": uplift,
        "risk_before": clamp(seg["baseline_risk"]),
        "risk_after": risk_after,
        "label_before": risk_label(seg["baseline_risk"]),
        "label_after": risk_label(risk_after),
        "acc_before": clamp(seg["baseline_acc"], 0, 100),
        "acc_after": acc_after,
        "class_before": acc_classification(seg["baseline_acc"]),
        "class_after": acc_classification(acc_after),
        "projected_status": projected_status,
    }


def simulate(event_type: str, intensity: str, duration_hours: int,
             segments: list[dict], shipments: list[dict],
             inventory: list[dict]) -> dict:
    """Run the full mandated cascade over a world-state snapshot.

    `segments`   : rows as accepted by project_segment (+ optional alternates)
    `shipments`  : {id, code, commodity, is_critical, dest_district,
                    segment_id, normal_eta_minutes, exposed_length_km}
    `inventory`  : {district_code, commodity, days_of_supply,
                    daily_consumption, incoming_quantity}
    """
    # ---- stages 1-3: rainfall -> per-segment road risk -> accessibility -----
    projections = [project_segment(event_type, intensity, duration_hours, s)
                   for s in segments]

    # ---- stages 4-5: shipments -> ETA ---------------------------------------
    shipment_impacts = []
    for sh in shipments:
        proj = next((p for p in projections
                     if p["segment_id"] == sh.get("segment_id")), None)
        if proj is None or proj["risk_after"] < 20:
            continue
        delay = round(segment_delay_minutes(
            sh.get("exposed_length_km", 25.0), AVG_SPEED_KPH,
            proj["risk_after"]), 1)
        shipment_impacts.append({
            **{k: sh[k] for k in ("id", "code", "commodity", "is_critical",
                                  "dest_district") if k in sh},
            "eta_before_min": sh.get("normal_eta_minutes"),
            "delay_minutes": delay,
            "eta_after_min": (sh.get("normal_eta_minutes") or 0) + delay})

    # ---- stage 6: supply ------------------------------------------------------
    exposure = duration_hours + 6          # response lead time on top of event
    supply_impacts = []
    for inv in inventory:
        prob = shortage_probability(
            inv.get("days_of_supply"), inv.get("commodity", "GENERAL"),
            float(inv.get("incoming_quantity", 0.0)),
            float(inv.get("daily_consumption", 0.0)),
            exposure_hours=exposure, disruption_context=True)
        supply_impacts.append({
            "district_code": inv.get("district_code"),
            "commodity": inv.get("commodity"),
            "shortage_probability_after": prob})

    # ---- stage 7: alternative routes / cut-off districts ---------------------
    alt_by_id = {s["segment_id"]: int(s.get("alternates", 1))
                 for s in segments}
    closures = [p for p in projections if p["projected_status"] == "CLOSED"]
    cut_offs = sorted({p["district_code"] for p in closures
                       if p["district_code"]
                       and not alt_by_id.get(p["segment_id"], 1)})
    alternatives = [{
        "segment_id": p["segment_id"], "road_code": p["road_code"],
        "projected_status": p["projected_status"],
        "viable_alternates": alt_by_id.get(p["segment_id"], 1),
        "district_cut_off": bool(p["district_code"]
                                 and not alt_by_id.get(p["segment_id"], 1)),
    } for p in projections]

    # ---- stage 8: government actions (real Phase-19 DIA cards) ---------------
    actions: list[dict] = []
    for sh in shipment_impacts:
        if sh["delay_minutes"] >= REROUTE_DELAY_MINUTES:
            worst = max((p for p in projections), key=lambda x: x["risk_after"])
            actions.append(dia.recommend_reroute(
                {"id": sh["id"], "code": sh["code"],
                 "commodity": sh.get("commodity"),
                 "is_critical": sh.get("is_critical"),
                 "dest_district": sh.get("dest_district")},
                {"segment_id": sh.get("segment_id")
                 or (worst and worst["segment_id"]) or "sim",
                 "overall_label": "CRITICAL" if sh["delay_minutes"] > 90
                 else "HIGH",
                 "risk_current": min(99.0, sh["delay_minutes"]),
                 "risk_24h": min(99.0, sh["delay_minutes"] + 5),
                 "road_code": "SIM"}))
    inv_by_district = {i.get("district_code"): i for i in inventory}
    for sp in supply_impacts:
        if sp["shortage_probability_after"] >= PREPOSITION_MIN_PROBABILITY:
            inv = inv_by_district.get(sp["district_code"], {})
            actions.append(dia.recommend_preposition({
                "inventory_id":
                    f"{sp['district_code']}:{sp['commodity']}:sim",
                "district_code": sp["district_code"],
                "commodity": sp["commodity"],
                "shortage_probability": sp["shortage_probability_after"],
                "days_of_supply": float(inv.get("days_of_supply", 2.0)),
                "daily_consumption":
                    float(inv.get("daily_consumption", 100.0)),
                "expected_disruption_hours": exposure}))
    for p in projections:
        if p["label_after"] in MONITOR_LABELS \
                and p["projected_status"] != "CLOSED":
            rec = dia.recommend_monitor({
                "segment_id": p["segment_id"],
                "overall_label": p["label_after"],
                "risk_current": p["risk_after"], "risk_24h": p["risk_after"],
                "road_code": p["road_code"],
                "district_code": p["district_code"]})
            if rec:
                actions.append(rec)
    for c in closures:
        actions.append(dia.recommend_notify({
            "segment_id": c["segment_id"], "road_code": c["road_code"],
            "district_code": c["district_code"], "state_code": None,
            "updated_recently": True}))

    return _staged(event_type=event_type, intensity=intensity,
                   duration_hours=duration_hours,
                   projections=projections,
                   shipment_impacts=shipment_impacts,
                   supply_impacts=supply_impacts, alternatives=alternatives,
                   cut_offs=cut_offs, actions=dia.rank(dedupe(actions))[:10])

def dedupe(recs: list[dict]) -> list[dict]:
    seen: dict[str, dict] = {}
    for r in recs:
        seen.setdefault(r["id"], r)
    return list(seen.values())


def _staged(*, event_type: str, intensity: str, duration_hours: int,
            projections: list[dict], shipment_impacts: list[dict],
            supply_impacts: list[dict], alternatives: list[dict],
            cut_offs: list[str], actions: list[dict]) -> dict:
    """Wrap results in the mandated cascade stage order."""
    stages = [
        {"stage": "Rainfall",
         "summary": f"{event_type} ({intensity}) for {duration_hours}h — "
                    f"effective load {effective_load_mm(event_type, intensity,
                                                        duration_hours)} mm"},
        {"stage": "Road risk",
         "segments": projections,
         "summary": _risk_summary(projections)},
        {"stage": "Accessibility",
         "summary": _acc_summary(projections)},
        {"stage": "Shipments",
         "impacts": shipment_impacts,
         "summary": f"{len(shipment_impacts)} active shipment(s) exposed"},
        {"stage": "ETA",
         "summary": _eta_summary(shipment_impacts)},
        {"stage": "Supply",
         "impacts": supply_impacts,
         "summary": _supply_summary(supply_impacts)},
        {"stage": "Alternative routes",
         "alternatives": alternatives,
         "cut_off_districts": cut_offs,
         "summary": (f"{len(cut_offs)} district(s) cut off"
                     if cut_offs else "all districts retain a route")},
        {"stage": "Government actions",
         "actions": actions,
         "summary": f"{len(actions)} recommended action(s)"},
    ]
    return {
        "event_type": event_type, "intensity": intensity,
        "duration_hours": duration_hours,
        "stages": {s["stage"]: s for s in stages},
        "stage_order": list(STAGE_NAMES),
        "before_after": _before_after(projections, shipment_impacts,
                                      supply_impacts, cut_offs),
    }


def _risk_summary(projections: list[dict]) -> str:
    if not projections:
        return "no modeled segments in region"
    closed = sum(p["projected_status"] == "CLOSED" for p in projections)
    crit = sum(p["label_after"] == "CRITICAL" for p in projections)
    return (f"{len(projections)} segment(s): avg risk "
            f"{sum(p['risk_after'] for p in projections) / len(projections):.0f}%"
            f" · {crit} CRITICAL · {closed} projected closure(s)")


def _acc_summary(projections: list[dict]) -> str:
    if not projections:
        return "—"
    after = [p["acc_after"] for p in projections]
    return (f"avg accessibility {sum(after) / len(after):.0f}/100 "
            f"(was {sum(p['acc_before'] for p in projections) / len(projections):.0f})")


def _eta_summary(shipment_impacts: list[dict]) -> str:
    if not shipment_impacts:
        return "no ETA impact on active shipments"
    worst = max(shipment_impacts, key=lambda x: x["delay_minutes"])
    return (f"worst delay +{worst['delay_minutes']:.0f} min on "
           f"#{worst.get('code', '')}; avg +"
           f"{sum(x['delay_minutes'] for x in shipment_impacts) / len(shipment_impacts):.0f} min")


def _supply_summary(supply_impacts: list[dict]) -> str:
    if not supply_impacts:
        return "no inventory modeled in region"
    risky = [s for s in supply_impacts
             if s["shortage_probability_after"] >= PREPOSITION_MIN_PROBABILITY]
    return f"{len(risky)}/{len(supply_impacts)} stock point(s) at shortage risk"


def _before_after(projections, shipment_impacts, supply_impacts,
                  cut_offs) -> dict:
    def _avg(rows, key):
        return round(sum(r[key] for r in rows) / len(rows), 1) if rows else None

    return {
        "road_risk_avg": {"before": _avg(projections, "risk_before"),
                          "after": _avg(projections, "risk_after")},
        "accessibility_avg": {"before": _avg(projections, "acc_before"),
                              "after": _avg(projections, "acc_after")},
        "shipments_exposed": len(shipment_impacts),
        "max_delay_minutes": (max((s["delay_minutes"] for s in shipment_impacts),
                                  default=0)),
        "stock_points_at_risk": sum(
            s["shortage_probability_after"] >= PREPOSITION_MIN_PROBABILITY
            for s in supply_impacts),
        "districts_cut_off": cut_offs,
        "projected_closures": sum(p["projected_status"] == "CLOSED"
                                  for p in projections),
    }




