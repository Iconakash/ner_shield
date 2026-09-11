# -*- coding: utf-8 -*-
"""Decision Intelligence Assistant core (Phase 25 · C23 · FR-C23.2).

PURE module — no DB, no network, fully unit-testable.

EXPLICITLY NOT A CHATBOT (source mandate): there is no free-form language
generation anywhere in this module. Questions are parsed into a FROZEN set of
intents; each intent has one deterministic executor over platform data; every
answer cites the tables it came from and respects the caller's RLS scope.

parse()       question text -> (intent, params) | (None, {})  [never guesses]
intents()     the supported-question catalog shown to officers
compose_*     turn executor rows into the mandated answer shape:
              summary -> ranked entities -> primary cause -> recommendation
"""
import re
from typing import Optional

# ------------------------------------------------------------------- intents

INTENT_SHORTAGE = "SHORTAGE_FORECAST"
INTENT_SINGLE_POINT = "SINGLE_POINT_VULNERABILITY"
INTENT_ALERTS = "PENDING_ALERTS"
INTENT_EXPOSED = "EXPOSED_SHIPMENTS"

COMMODITY_KEYWORDS = {
    "medicine": "MEDICINE",
    "medical": "MEDICINE",
    "drug": "MEDICINE",
    "food": "EMERGENCY_FOOD",
    "water": "WATER",
    "fuel": "FUEL",
    "supplies": "EMERGENCY_SUPPLIES",
}
DEFAULT_COMMODITY = "MEDICINE"
DEFAULT_HOURS = 24
VALID_HOURS = (6, 12, 24, 48, 72)

SHORTAGE_WATCH_THRESHOLD = 55.0        # == Phase-9/C06 watchlist threshold

_CAUSE_DISRUPTION = "Predicted route disruption"
_CAUSE_THIN_STOCK = "Stock cover below consumption"
_CAUSE_NO_INBOUND = "No inbound supply within the window"

SUPPORTED_QUESTIONS = [
    {"intent": INTENT_SHORTAGE,
     "examples": ["Which districts may face medicine shortages within "
                  "24 hours?",
                  "Any water shortage risks in the next 48 hours?"]},
    {"intent": INTENT_SINGLE_POINT,
     "examples": ["Which districts have a single point of failure?",
                  "Districts depending on one corridor?"]},
    {"intent": INTENT_ALERTS,
     "examples": ["How many alerts are pending action?",
                  "Any open critical alerts?"]},
    {"intent": INTENT_EXPOSED,
     "examples": ["Which active shipments cross high-risk corridors?",
                  "Exposed shipments right now?"]},
]


def intents() -> list[dict]:
    """The frozen catalog — the UI offers these; nothing else is answerable."""
    return SUPPORTED_QUESTIONS


def parse(question: str) -> tuple[Optional[str], dict]:
    """Deterministic keyword parse. Returns (None, {}) when unsupported —
    the assistant NEVER fabricates an answer outside the frozen intents."""
    q = (question or "").lower()
    if not q.strip():
        return None, {}

    # --- alerts -----------------------------------------------------------
    if re.search(r"\balert|\bpending action|\bescalat", q):
        return INTENT_ALERTS, {}

    # --- single point / cutoff ---------------------------------------------
    if re.search(r"single.point|cut.?off|one corridor|only corridor|"
                 r"isolat", q):
        return INTENT_SINGLE_POINT, {}

    # --- exposed shipments ---------------------------------------------------
    if re.search(r"shipment|convoy|consignment", q) \
            and re.search(r"exposed|risk|high.risk|delay", q):
        return INTENT_EXPOSED, {}

    # --- shortage forecast ----------------------------------------------------
    if re.search(r"shortage|stock.?out|run out|supply gap", q):
        hours = DEFAULT_HOURS
        m = re.search(r"(\d+)\s*(?:hour|hr)", q)
        if m:
            hours = max(min(VALID_HOURS), min(max(VALID_HOURS),
                                              int(m.group(1))))
        commodity = DEFAULT_COMMODITY
        for kw, code in COMMODITY_KEYWORDS.items():
            if re.search(rf"\b{kw}", q):
                commodity = code
                break
        return INTENT_SHORTAGE, {"commodity": commodity, "hours": hours}

    return None, {}

# ------------------------------------------------------------------ composers

def compose_shortage(rows: list[dict], warehouses: list[dict],
                     commodity: str, hours: int) -> dict:
    """rows: {district_code, days_of_supply, shortage_probability,
    route_disrupted, incoming_quantity}. warehouses: candidate sources with
    stock of the commodity (best stock first), any district."""
    hits = sorted((r for r in rows
                   if r["shortage_probability"] >= SHORTAGE_WATCH_THRESHOLD),
                  key=lambda r: (-r["shortage_probability"],
                                 r["district_code"]))
    items = [{"district_code": r["district_code"],
              "probability": round(r["shortage_probability"]),
              "days_of_supply": round(float(r["days_of_supply"]), 1),
              "primary_cause": (_CAUSE_DISRUPTION if r["route_disrupted"]
                                else _CAUSE_THIN_STOCK
                                if float(r["incoming_quantity"] or 0) <= 0
                                else _CAUSE_NO_INBOUND)}
             for r in hits]

    # recommendation: pre-position from the best-stocked warehouse OUTSIDE
    # the affected districts (in-district stock needs no pre-positioning)
    affected = {i["district_code"] for i in items}
    source = next((w for w in warehouses
                   if w.get("district_code") not in affected), None)
    recommendations = []
    if items and source:
        recommendations.append({
            "action": "PRE_POSITION_SUPPLIES",
            "commodity": commodity,
            "source_warehouse": source.get("code"),
            "warehouse_district": source.get("district_code"),
            "targets": [i["district_code"] for i in items],
            "rationale":
                f"Cover the {hours}h exposure window before shortage "
                f"probability materializes"})

    causes = [c for c in (_CAUSE_DISRUPTION, _CAUSE_THIN_STOCK,
                          _CAUSE_NO_INBOUND)
              if any(i["primary_cause"] == c for i in items)]
    return {
        "intent": INTENT_SHORTAGE,
        "params": {"commodity": commodity, "hours": hours},
        "summary": (f"{len(items)} district(s) identified."
                    if items else
                    f"No {commodity.lower()} shortage risk above "
                    f"{SHORTAGE_WATCH_THRESHOLD:.0f}% within {hours} hours."),
        "items": items,
        "primary_cause": (causes[0] if causes else None),
        "causes": causes,
        "recommendations": recommendations,
        "citations": ["inventory", "disruption_predictions",
                      "facilities", "weather_feed"],
    }

def compose_single_point(districts: list[dict]) -> dict:
    """districts: [{district_code, lifeline_corridor}] already filtered."""
    items = [{"district_code": d["district_code"],
              "lifeline_corridor": d.get("lifeline_corridor")}
             for d in districts]
    return {
        "intent": INTENT_SINGLE_POINT,
        "params": {},
        "summary": (f"{len(items)} district(s) depend on a single corridor."
                    if items else "No single-point districts in your scope."),
        "items": items,
        "primary_cause": None,
        "recommendations": ([{"action": "OPEN_ALTERNATE_CORRIDOR",
                              "targets": [i["district_code"]
                                          for i in items]}] if items else []),
        "citations": ["road_segments", "roads"],
    }


def compose_alerts(counts: dict, total: int) -> dict:
    """counts: {level: open_count}."""
    items = [{"level": lvl, "open": n}
             for lvl, n in sorted(counts.items(), key=lambda kv: -kv[1])
             if n > 0]
    return {
        "intent": INTENT_ALERTS,
        "params": {},
        "summary": f"{total} alert(s) open and awaiting action.",
        "items": items,
        "primary_cause": None,
        "recommendations": [],
        "citations": ["alerts"],
    }


def compose_exposed(shipments: list[dict]) -> dict:
    """shipments: [{code, commodity, is_critical, eta_minutes, worst_label,
    exposed_roads}] already filtered to HIGH/CRITICAL exposure."""
    ordered = sorted(shipments,
                     key=lambda s: (-(1 if s["is_critical"] else 0),
                                    -(s.get("eta_minutes") or 0),
                                    s["code"]))
    items = [{"code": s["code"], "commodity": s.get("commodity"),
              "is_critical": bool(s["is_critical"]),
              "eta_minutes": s.get("eta_minutes"),
              "worst_label": s.get("worst_label"),
              "exposed_roads": s.get("exposed_roads")}
             for s in ordered]
    critical = sum(1 for i in items if i["is_critical"])
    return {
        "intent": INTENT_EXPOSED,
        "params": {},
        "summary": (f"{len(items)} active shipment(s) cross HIGH/CRITICAL "
                    f"corridors ({critical} carrying critical cargo)."
                    if items else
                    "No active shipments on high-risk corridors."),
        "items": items,
        "primary_cause": (_CAUSE_DISRUPTION if items else None),
        "recommendations": ([{"action": "REROUTE_SHIPMENT",
                              "targets": [i["code"] for i in items
                                          if i["is_critical"]],
                              "rationale":
                                  "Critical cargo on risky corridors"}]
                            if any(i["is_critical"] for i in items)
                            else []),
        "citations": ["shipments", "disruption_predictions",
                      "road_segments"],
    }


def unsupported(question: str) -> dict:
    """The non-chatbot guard: decline + show what IS answerable. Never
    fabricates an answer outside the frozen intents."""
    return {
        "intent": None,
        "unsupported_question": question,
        "summary": ("Question not recognized. This assistant answers only "
                    "data-grounded operational questions — see supported "
                    "questions."),
        "supported_questions": intents(),
        "items": [], "recommendations": [], "citations": [],
    }



