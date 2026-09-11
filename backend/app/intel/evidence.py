"""Layer 3+4 — Normalized evidence, hazard fusion, SOURCE-CONFLICT detection.

An EvidenceItem is one OBSERVED/PREDICTED signal tied to a hazard. Fusion:
  * confidence math is delegated to the existing deterministic engine
    (app/risk/fusion.py) so there is exactly ONE fusion implementation;
  * supporting + credible dissenting evidence => SOURCE CONFLICT: confidence
    reduced, field verification REQUIRED — never "FLOOD = TRUE" by blind vote;
  * hazards are only produced when evidence exists. No variable => no hazard.
"""
from dataclasses import dataclass
from datetime import datetime

from app.risk.fusion import SourceSignal, fuse

SUPPORTED_HAZARDS = ("FLOOD", "LANDSLIDE", "EXTREME_RAINFALL", "CYCLONE",
                     "EARTHQUAKE", "ROAD_FAILURE", "CONNECTIVITY_FAILURE")

SEVERITY_BANDS = [(70, "CRITICAL"), (45, "HIGH"),
                  (25, "ELEVATED"), (10, "GUARDED")]     # else LOW


@dataclass(frozen=True)
class EvidenceItem:
    hazard_type: str
    source: str                  # IMD / CWC / COPERNICUS / NDMA-SACHET / FIELD_REPORT / ...
    kind: str                    # e.g. rainfall_forecast, river_trend, water_expansion
    supports: bool               # does it support the assessed hazard?
    observed_at: datetime | None = None
    value: float | None = None   # raw magnitude if applicable
    label: str = ""              # human-readable line for cards
    location: dict | None = None
    reliability: float = 0.8
    quality: float = 0.8
    spatial_relevance: float = 1.0

    def __post_init__(self):
        if self.hazard_type not in SUPPORTED_HAZARDS:
            raise ValueError(f"unsupported hazard_type {self.hazard_type!r}")
        if not self.source or not self.kind:
            raise ValueError("source and kind are mandatory")
        # §39: every item must be tagged observed vs predicted upstream in `kind`
        # (convention: kinds starting with 'forecast_'/'predicted_' are PREDICTED)

    def to_signal(self) -> SourceSignal:
        age_h = 0.0
        if self.observed_at is not None:
            now = datetime.now(self.observed_at.tzinfo or None)
            age_h = max(0.0, (now - self.observed_at).total_seconds() / 3600.0)
        return SourceSignal(source=self.source, hazard=self.hazard_type,
                            agrees=self.supports, age_hours=age_h,
                            reliability=self.reliability, quality=self.quality,
                            spatial_relevance=self.spatial_relevance)


@dataclass(frozen=True)
class SourceConflict:
    sources_for: list[str]
    sources_against: list[str]
    note: str


@dataclass(frozen=True)
class HazardAssessment:
    hazard_type: str
    probability: float           # 0..100 operational probability band
    severity: str                # LOW/GUARDED/ELEVATED/HIGH/CRITICAL (existing labels)
    confidence: float            # fused DATA confidence 0..1 (never >0.95)
    time_horizon: str            # 'NOW' | '6h' | '12h' | '24h' | '48h' | '72h'
    evidence: list[dict]         # [{source,kind,label,supports,contribution}]
    conflict: SourceConflict | None
    verification_required: bool
    status: str                  # PREDICTED | OBSERVED | CONFIRMED | UNCONFIRMED (§25)
    affected_area: dict | None = None


def _severity(probability: float) -> str:
    for minimum, label in SEVERITY_BANDS:
        if probability >= minimum:
            return label
    return "LOW"


def fuse_hazard(items: list[EvidenceItem], hazard_type: str, *,
                horizon: str = "24h",
                observed_status: str = "PREDICTED",
                affected_area: dict | None = None) -> HazardAssessment | None:
    """Fuse evidence for ONE hazard. Returns None when no relevant evidence
    exists (never fabricate a hazard from silence)."""
    relevant = [i for i in items if i.hazard_type == hazard_type]
    if not relevant:
        return None

    fused = fuse([i.to_signal() for i in relevant], hazard_type)

    # ---- source-conflict rule (§24): credible dissent caps trust -------------
    against = sorted({i.source for i in relevant if not i.supports})
    supporting = [i for i in relevant if i.supports]
    conflict = None
    verification_required = False
    if against and supporting:
        conflict = SourceConflict(
            sources_for=sorted({i.source for i in supporting}),
            sources_against=against,
            note=("sources disagree — confidence reduced; field verification "
                  "recommended before operational action"))
        verification_required = True
    elif fused.confidence < 0.35 and len(supporting) <= 1:
        # weak single-source signal also demands ground truth before action
        verification_required = True

    probability = round(min(95.0, fused.confidence * 100.0), 1)
    evidence_rows = [{
        "source": i.source, "kind": i.kind, "label": i.label,
        "supports": i.supports, "value": i.value,
        "observed_at": i.observed_at.isoformat() if i.observed_at else None,
    } for i in relevant]

    return HazardAssessment(
        hazard_type=hazard_type,
        probability=probability,
        severity=_severity(probability),
        confidence=fused.confidence,
        time_horizon=horizon,
        evidence=evidence_rows,
        conflict=conflict,
        verification_required=verification_required,
        status="UNCONFIRMED" if verification_required else observed_status,
        affected_area=affected_area)


def summarize(assessment: HazardAssessment) -> list[str]:
    """Human-readable 'Evidence:' bullet lines for decision cards (§20)."""
    lines = [e.get("label") or f"{e['kind']} ({e['source']})"
             for e in assessment.evidence if e["supports"]]
    if assessment.conflict:
        lines.append("SOURCE CONFLICT — "
                     + ", ".join(assessment.conflict.sources_against)
                     + " dissent")
    return lines
