# -*- coding: utf-8 -*-
"""Decision Intelligence Assistant — rule-guided recommendation engine (Phase 19 · C23.1).

PURE module: no DB, no network. The router feeds it signal rows; every output
is a fully-formed recommendation carrying the SIX source-mandated fields:

    reason · confidence · affected_entities · expected_impact ·
    recommended_action · approval_required          (+ evidence links)

Design honesty rules:
  * Confidence is DERIVED from the underlying engine scores (risk_current,
    shortage_probability, …) — never invented.
  * Approval requirements map ONLY onto the frozen two-person workflow actions
    (APPROVAL_WORKFLOW_PERMISSIONS). A recommendation that needs no approval
    says so explicitly instead of pretending.
  * IDs are deterministic hashes of (rule, source entity ids) so the same
    operational situation always yields the same actionable card.
"""
import hashlib
from typing import Any

# ------------------------------------------------------------------ contract

REQUIRED_FIELDS = ("reason", "confidence", "affected_entities",
                   "expected_impact", "recommended_action",
                   "approval_required")

RULE_REROUTE = "REROUTE_SHIPMENT"
RULE_PREPOSITION = "PRE_POSITION_SUPPLIES"
RULE_MONITOR = "MONITOR_SEGMENT"
RULE_NOTIFY = "NOTIFY_DISTRICT_OFFICER"

# Only these may demand the two-person workflow (frozen set, baseline §4).
APPROVAL_ACTIONS = {
    RULE_REROUTE: "EMERGENCY_REROUTE",
    RULE_PREPOSITION: "MAJOR_SUPPLY_REDISTRIBUTION",
}

# Trigger thresholds (aligned with the engines that produce the signals).
REROUTE_TRIGGER_LABELS = ("HIGH", "CRITICAL")
MONITOR_TRIGGER_LABELS = ("ELEVATED", "HIGH", "CRITICAL")
PREPOSITION_MIN_PROBABILITY = 55.0        # == supply watchlist threshold


def _rec_id(rule: str, *sources: str) -> str:
    return hashlib.sha1(
        "|".join([rule, *(str(s) for s in sources)]).encode()).hexdigest()[:12]


def validate(rec: dict) -> dict:
    """Every recommendation MUST carry all six mandated fields."""
    missing = [f for f in REQUIRED_FIELDS if f not in rec]
    if missing:
        raise ValueError(f"recommendation missing mandated fields: {missing}")
    if rec["approval_required"] is not None and \
            rec["approval_required"] not in APPROVAL_ACTIONS.values():
        raise ValueError(f"unknown approval action {rec['approval_required']}")
    return rec


def _make(*, rule: str, sources: list[str], title: str, action: str,
          reason: str, confidence: float, affected: list[dict],
          impact: str, evidence: list[dict], geo: dict | None = None,
          extra: dict | None = None) -> dict:
    confidence = round(max(1.0, min(99.0, float(confidence))), 1)
    approval = APPROVAL_ACTIONS.get(rule)
    rec: dict[str, Any] = {
        "id": _rec_id(rule, *sources),
        "rule": rule,
        "title": title,
        # ---- the six mandated fields -------------------------------------
        "recommended_action": action,
        "reason": reason,
        "confidence": confidence,
        "affected_entities": affected,
        "expected_impact": impact,
        "approval_required": approval,
        # -------------------------------------------------------------------
        "evidence": evidence,
        # rank: approval-gated actions are urgent BY DEFINITION; everything
        # else ranks purely by confidence.
        "priority_score": round(confidence + (12.0 if approval else 0.0), 1),
        "dispatch": ({"action_type": approval, "title": title,
                      "state_code": (geo or {}).get("state_code"),
                      "district_code": (geo or {}).get("district_code"),
                      "payload": {"recommendation_id": _rec_id(rule, *sources),
                                  "rule": rule}}
                     if approval else None),
    }
    if extra:
        rec.update(extra)
    return validate(rec)

# ----------------------------------------------------------------- the rules

def recommend_reroute(ship: dict, pred: dict) -> dict:
    """Rule 1 — active shipment crossing a HIGH/CRITICAL-risk segment.

    `ship`:  {id, code, commodity, is_critical, dest_district}
    `pred`:  {segment_id, overall_label, risk_current, risk_24h, road_code}
    """
    crit = bool(ship.get("is_critical"))
    # confidence derived from prediction risk; critical cargo raises stakes
    confidence = pred["risk_current"] + (6.0 if crit else 0.0)
    return _make(
        rule=RULE_REROUTE,
        sources=[ship["id"], pred["segment_id"]],
        title=(f"Reroute {'critical ' if crit else ''}"
               f"{str(ship.get('commodity', 'shipment')).lower().replace('_', ' ')}"
               f" shipment #{ship.get('code', ship['id'])}"),
        action="Re-plan route around the flagged segment before departure",
        reason=(f"Route crosses {pred['road_code']} segment with "
                f"{pred['overall_label']} disruption risk "
                f"({pred['risk_current']:.0f}% now, {pred['risk_24h']:.0f}% in 24h)"),
        confidence=confidence,
        affected=[{"type": "SHIPMENT", "id": ship["id"],
                   "label": f"#{ship.get('code', ship['id'])}"},
                  {"type": "ROAD_SEGMENT", "id": pred["segment_id"],
                   "label": pred["road_code"]},
                  {"type": "DISTRICT", "id": ship.get("dest_district"),
                   "label": ship.get("dest_district") or "—"}],
        impact=(f"Avoids a corridor with {pred['risk_24h']:.0f}% 24h disruption "
                f"probability; protects "
                f"{str(ship.get('commodity', '')).lower().replace('_', ' ')} "
                f"delivery ETA"),
        evidence=[{"type": "disruption_prediction", "id": pred["segment_id"]},
                  {"type": "shipment", "id": ship["id"]}],
        geo={"district_code": ship.get("dest_district"),
             "state_code": ship.get("state_code")},
    )


def recommend_preposition(sp: dict) -> dict:
    """Rule 2 — shortage probability at/above the watchlist threshold.

    `sp`: {inventory_id, district_code, commodity, shortage_probability,
           days_of_supply, daily_consumption, expected_disruption_hours}
    """
    return _make(
        rule=RULE_PREPOSITION,
        sources=[sp["inventory_id"]],
        title=(f"Pre-position {str(sp['commodity']).lower().replace('_', ' ')} "
               f"in district {sp['district_code']}"),
        action="Pre-position stock at forward facilities in the affected district",
        reason=(f"Shortage probability {sp['shortage_probability']:.0f}% — only "
                f"{sp['days_of_supply']:.1f} days of supply left against a "
                f"{sp['expected_disruption_hours']}h exposure horizon"),
        confidence=sp["shortage_probability"],
        affected=[{"type": "DISTRICT", "id": sp["district_code"],
                   "label": sp["district_code"]},
                  {"type": "COMMODITY", "id": sp["commodity"],
                   "label": str(sp["commodity"]).lower().replace("_", " ")}],
        impact=(f"Closes a ~{sp['daily_consumption']:.0f}/day consumption gap for "
                f"{sp['expected_disruption_hours']}h "
                f"(≈{sp['daily_consumption'] * sp['expected_disruption_hours'] / 24:.0f} units)"),
        evidence=[{"type": "shortage_prediction", "id": str(sp["inventory_id"])}],
        geo={"district_code": sp.get("district_code")},
    )


def recommend_monitor(pred: dict) -> dict | None:
    """Rule 3 — elevated-risk segment still OPEN (watch, don't act yet)."""
    if pred["overall_label"] not in MONITOR_TRIGGER_LABELS:
        return None
    return _make(
        rule=RULE_MONITOR,
        sources=[pred["segment_id"]],
        title=f"Monitor {pred['road_code']} ({pred['district_code']})",
        action="Increase observation frequency; verify ground truth via field report",
        reason=(f"{pred['overall_label']} disruption risk on an OPEN segment "
                f"({pred['risk_current']:.0f}% now, rising to "
                f"{pred['risk_24h']:.0f}% in 24h)"),
        confidence=pred["risk_current"],
        affected=[{"type": "ROAD_SEGMENT", "id": pred["segment_id"],
                   "label": pred["road_code"]},
                  {"type": "DISTRICT", "id": pred["district_code"],
                   "label": pred["district_code"]}],
        impact="Early warning only — no operational cost while risk stays below closure",
        evidence=[{"type": "disruption_prediction", "id": pred["segment_id"]}],
        geo={"district_code": pred.get("district_code")},
    )


def recommend_notify(seg: dict) -> dict | None:
    """Rule 4 — accessibility degradation confirmed on the ground.

    `seg`: {segment_id, road_code, district_code, state_code, updated_recently}
    """
    if not seg.get("updated_recently"):
        return None
    return _make(
        rule=RULE_NOTIFY,
        sources=[seg["segment_id"]],
        title=(f"Notify District Officer — {seg['road_code']} "
               f"({seg['district_code']})"),
        action="Dispatch notification/verification task to the district officer",
        reason=("Accessibility degradation confirmed: segment recently closed "
                "or downgraded on the network"),
        confidence=90.0,   # ground-truth status change, not a forecast
        affected=[{"type": "ROAD_SEGMENT", "id": seg["segment_id"],
                   "label": seg["road_code"]},
                  {"type": "DISTRICT", "id": seg["district_code"],
                   "label": seg["district_code"]}],
        impact="Faster local response and validation of downstream reroutes",
        evidence=[{"type": "road_segment", "id": seg["segment_id"]}],
        geo={"district_code": seg.get("district_code"),
             "state_code": seg.get("state_code")},
    )

# ------------------------------------------------------------- ranking + dedupe

def rank(recs: list[dict]) -> list[dict]:
    """Highest priority first; deterministic tie-break on id."""
    return sorted(recs, key=lambda r: (-r["priority_score"], r["id"]))


def dedupe(recs: list[dict]) -> list[dict]:
    """Same operational situation → same deterministic id → one card."""
    seen: dict[str, dict] = {}
    for r in recs:
        seen.setdefault(r["id"], r)
    return list(seen.values())


def build_recommendations(ships_at_risk: list[tuple[dict, dict]],
                          shortage_rows: list[dict],
                          monitor_preds: list[dict],
                          closed_segments: list[dict]) -> list[dict]:
    """Assemble the ranked ACTION REQUIRED list from raw signal rows.

    Each argument is a list of rows already filtered by the router's SQL to
    trigger conditions (the engine re-checks soft conditions defensively).
    """
    recs: list[dict] = []
    for ship, pred in ships_at_risk:
        if pred.get("overall_label") in REROUTE_TRIGGER_LABELS:
            recs.append(recommend_reroute(ship, pred))
    for sp in shortage_rows:
        if sp["shortage_probability"] >= PREPOSITION_MIN_PROBABILITY:
            recs.append(recommend_preposition(sp))
    for pred in monitor_preds:
        rec = recommend_monitor(pred)
        if rec:
            recs.append(rec)
    for seg in closed_segments:
        rec = recommend_notify(seg)
        if rec:
            recs.append(rec)
    return rank(dedupe(recs))


