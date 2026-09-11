"""Layer 6+7 — Decision states, option comparison, review cadence.

The EXISTING risk labels (LOW/GUARDED/ELEVATED/HIGH/CRITICAL) are untouched and
remain the answer to "how dangerous?". DECISION_STATE answers a different
question: "what operational posture should be considered?" — computed from
hazard severity x exposure criticality x route availability x confidences.

Existing decision actions are preserved verbatim; four justified additions are
defined here (VERIFY_FIELD_CONDITION, INCREASE_MONITORING,
PREPARE_ALTERNATE_ROUTE, ESCALATE_AUTHORITY). Approval requirements still map
ONLY onto the frozen APPROVAL_ACTIONS set from the existing decisions engine.
"""
from dataclasses import dataclass, field

# Existing labels (kept literal to avoid import cycles):
RISK_LABELS = ("LOW", "GUARDED", "ELEVATED", "HIGH", "CRITICAL")

DECISION_STATES = ("NORMAL", "WATCH", "PREPARE", "MITIGATE",
                   "ACT", "ESCALATE", "EMERGENCY")

# Existing actions (app/decisions/engine.py) — never renamed:
A_REROUTE = "REROUTE_SHIPMENT"
A_PREPOSITION = "PRE_POSITION_SUPPLIES"
A_MONITOR = "MONITOR_SEGMENT"
A_NOTIFY = "NOTIFY_DISTRICT_OFFICER"
# Justified new actions (§19):
A_VERIFY_FIELD = "VERIFY_FIELD_CONDITION"
A_INCREASE_MONITORING = "INCREASE_MONITORING"
A_PREPARE_ALT_ROUTE = "PREPARE_ALTERNATE_ROUTE"
A_ESCALATE_AUTHORITY = "ESCALATE_AUTHORITY"

_REVIEW_MINUTES = {"NORMAL": 240, "WATCH": 120, "PREPARE": 60,
                   "MITIGATE": 30, "ACT": 15, "ESCALATE": 15, "EMERGENCY": 5}

_LABEL_BASE = {"LOW": "NORMAL", "GUARDED": "WATCH", "ELEVATED": "PREPARE",
               "HIGH": "PREPARE", "CRITICAL": "ACT"}

# Model-confidence level at which an unexposed HIGH-risk segment is trusted
# enough to move operations into mitigation anyway (documented, deterministic):
HIGH_STRONG_MODEL_CONFIDENCE = 0.75


@dataclass(frozen=True)
class SituationInputs:
    risk_label: str                       # existing prediction label
    prediction_confidence: float          # 0..1 model/prediction confidence
    data_confidence: float                # 0..1 fused source/evidence confidence
    exposure_criticality: int = 0         # 0 none .. 3 (critical facility/lifeline)
    open_alternatives: int | None = None  # alternative routes; None = unknown
    confirmed_closure: bool = False       # OBSERVED/CONFIRMED closure (field/GPS)
    verification_pending: bool = False    # source conflict / weak evidence


def decide_state(s: SituationInputs) -> str:
    """Deterministic posture mapping. Risk label sets the FLOOR; exposure,
    alternatives, confirmation and confidence can RAISE (never lower) it."""
    base = _LABEL_BASE.get(s.risk_label, "WATCH")
    idx = DECISION_STATES.index(base)

    def raise_to(state: str) -> None:
        nonlocal idx
        idx = max(idx, DECISION_STATES.index(state))

    if s.confirmed_closure and s.exposure_criticality >= 2:
        raise_to("EMERGENCY")
    elif s.risk_label == "CRITICAL":
        if s.open_alternatives == 0:
            raise_to("ESCALATE")           # nowhere to reroute -> authority
        elif s.exposure_criticality >= 2:
            raise_to("MITIGATE")
    elif s.risk_label == "HIGH":
        # HIGH escalates beyond its PREPARE floor only with meaningful
        # exposure OR strong model evidence; weak evidence alone keeps the
        # posture at PREPARE (§25: act on evidence, not on noise).
        if s.exposure_criticality >= 1 \
                or s.prediction_confidence >= HIGH_STRONG_MODEL_CONFIDENCE:
            raise_to("MITIGATE")
    elif s.risk_label == "ELEVATED" and s.exposure_criticality >= 2 \
            and s.prediction_confidence >= 0.6:
        raise_to("MITIGATE")               # critical shipments on elevated road

    # Low data confidence NEVER escalates posture on its own — it demands
    # verification instead (§25): act on evidence, not on noise.
    return DECISION_STATES[idx]


def review_minutes(state: str) -> int:
    return _REVIEW_MINUTES.get(state, 60)


@dataclass(frozen=True)
class Option:
    action: str
    description: str
    risk_if_taken: str                    # qualitative residual-risk statement
    eta_impact: str | None                # None => UNKNOWN, never invented
    operational_cost: str                 # 'UNKNOWN' unless a cost model exists
    expected_benefit: str
    confidence: float                     # DECISION confidence 0..1
    approval_required: bool


@dataclass(frozen=True)
class DecisionCard:
    """Evidence-backed card (§20). OBSERVED/PREDICTED/RECOMMENDED stay distinct."""
    subject_type: str
    subject_id: str
    title: str
    decision_state: str
    risk_label: str
    probability: float | None
    horizon: str
    prediction_confidence: float
    data_confidence: float
    affected_entities: list[dict]
    impact_summary: list[str]
    top_factors: list[str]
    evidence: list[str]
    options: list[Option] = field(default_factory=list)
    recommended_action: str = ""
    approval_required: bool = False
    review_minutes: int = 60
    status: str = "PREDICTED"             # PREDICTED/OBSERVED/CONFIRMED/UNCONFIRMED


def build_options(s: SituationInputs, *, hazard_label: str = "",
                  subject_label: str = "") -> list[Option]:
    """Meaningful alternatives for the situation, cheapest-intervention first.
    Costs are UNKNOWN (no cost model exists — §18); ETA impacts are stated only
    when structurally implied, otherwise UNKNOWN. Never auto-recommends the
    safest route when it would create an unacceptable logistics delay."""
    state = decide_state(s)
    strong_evidence = min(s.prediction_confidence,
                          s.data_confidence) >= 0.55
    options: list[Option] = []

    if s.verification_pending or s.data_confidence < 0.4:
        options.append(Option(
            action=A_VERIFY_FIELD,
            description=("Dispatch field verification before any operational "
                         "change — sources conflict or evidence is thin"),
            risk_if_taken="No immediate operational disruption",
            eta_impact=None, operational_cost="UNKNOWN",
            expected_benefit="Resolves OBSERVED vs PREDICTED ambiguity",
            confidence=min(0.9, 0.5 + (0.3 if s.verification_pending else 0.0)),
            approval_required=False))

    if s.open_alternatives != 0 and s.risk_label in ("HIGH", "CRITICAL"):
        options.append(Option(
            action=A_PREPARE_ALT_ROUTE,
            description=(f"Pre-plan an alternate corridor around "
                         f"{subject_label or hazard_label or 'the segment'}"),
            risk_if_taken="Keeps current routing while preparing fallback",
            eta_impact="UNKNOWN until executed",
            operational_cost="UNKNOWN",
            expected_benefit="Cuts reaction time if the primary route degrades",
            confidence=round(min(0.85, 0.5 + 0.1 * s.prediction_confidence
                                 + 0.1 * s.data_confidence), 2),
            approval_required=False))

    options.append(Option(
        action=A_INCREASE_MONITORING if state in ("WATCH", "PREPARE")
        else A_MONITOR,
        description=("Tighten polling on this subject; watch weather, river "
                     "and accessibility signals"),
        risk_if_taken="Situation may evolve faster than the review cycle",
        eta_impact=None, operational_cost="UNKNOWN",
        expected_benefit="Earlier detection of deterioration",
        confidence=max(0.4, min(0.9, s.data_confidence + 0.2)),
        approval_required=False))

    if s.risk_label in ("HIGH", "CRITICAL") and strong_evidence:
        options.append(Option(
            action=A_REROUTE,
            description=("Emergency reroute of exposed shipments via the "
                         "existing two-person approval workflow"),
            risk_if_taken="Longer ETA on the alternate corridor",
            eta_impact="+ETA (computed at execution from live routing)",
            operational_cost="UNKNOWN",
            expected_benefit="Avoids predicted HIGH/CRITICAL segments",
            confidence=round(min(0.9, 0.4 + 0.3 * s.prediction_confidence
                                 + 0.2 * s.data_confidence), 2),
            approval_required=True))

    if state in ("ESCALATE", "EMERGENCY"):
        options.append(Option(
            action=A_ESCALATE_AUTHORITY,
            description=("Escalate to regional authority — no viable "
                         "technical option inside current scope"),
            risk_if_taken="None beyond escalation itself",
            eta_impact=None, operational_cost="UNKNOWN",
            expected_benefit="Brings higher-level resources/decisions",
            confidence=0.7, approval_required=False))

    if not options:
        options.append(Option(
            action=A_MONITOR, description="Standard monitoring",
            risk_if_taken="—", eta_impact=None, operational_cost="UNKNOWN",
            expected_benefit="Baseline vigilance", confidence=0.5,
            approval_required=False))
    return options


def recommend(options: list[Option], s: SituationInputs) -> Option:
    """Highest decision-confidence option; verification always wins while it is
    pending (trustworthiness over speed). Deterministic tie-break."""
    pool = options or build_options(s)
    if s.verification_pending:
        verify = [o for o in pool if o.action == A_VERIFY_FIELD]
        if verify:
            return verify[0]
    return max(pool, key=lambda o: o.confidence)


def build_card(*, subject_type: str, subject_id: str, title: str,
               situation: SituationInputs, probability: float | None,
               horizon: str, affected_entities: list[dict],
               impact_summary: list[str], top_factors: list[str],
               evidence_lines: list[str],
               hazard_label: str = "", status: str = "PREDICTED") -> DecisionCard:
    """Assemble the full evidence-backed decision card (§20)."""
    opts = build_options(situation, hazard_label=hazard_label,
                         subject_label=title)
    rec = recommend(opts, situation)
    return DecisionCard(
        subject_type=subject_type, subject_id=subject_id, title=title,
        decision_state=decide_state(situation),
        risk_label=situation.risk_label,
        probability=probability, horizon=horizon,
        prediction_confidence=round(situation.prediction_confidence, 3),
        data_confidence=round(situation.data_confidence, 3),
        affected_entities=affected_entities,
        impact_summary=impact_summary, top_factors=top_factors,
        evidence=evidence_lines, options=list(opts),
        recommended_action=rec.action,
        approval_required=rec.approval_required,
        review_minutes=review_minutes(decide_state(situation)),
        status=status)