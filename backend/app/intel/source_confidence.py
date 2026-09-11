"""Layer 2 — Source confidence (master upgrade §7).

DATA CONFIDENCE ONLY. This is deliberately distinct from:
  * RISK (how dangerous is the situation)      — app/risk/*
  * PREDICTION confidence (model certainty)    — disruption_predictions output
  * DECISION confidence (evidence for action)  — app/intel/decision_state.py

Weights are configurable and every score returns its full breakdown so no
confidence number is unexplainable.
"""
from dataclasses import dataclass, replace

from app.intel.data_quality import QualityAssessment


@dataclass(frozen=True)
class SourceProfile:
    """Static per-source traits (authority + historical reliability)."""
    authority: float             # institutional trust 0..1
    reliability: float = 0.8     # track-record 0..1 (updated by ops later)


@dataclass(frozen=True)
class ConfidenceWeights:
    authority: float = 0.30
    freshness: float = 0.25
    spatial_relevance: float = 0.20
    completeness: float = 0.15
    reliability: float = 0.10

    def normalized(self) -> "ConfidenceWeights":
        total = (self.authority + self.freshness + self.spatial_relevance
                 + self.completeness + self.reliability)
        if total <= 0:
            return self
        return replace(self, authority=self.authority / total,
                       freshness=self.freshness / total,
                       spatial_relevance=self.spatial_relevance / total,
                       completeness=self.completeness / total,
                       reliability=self.reliability / total)


# Documented default profiles (extend as providers are authorized).
PROFILES: dict[str, SourceProfile] = {
    "IMD": SourceProfile(authority=0.95, reliability=0.85),
    "CWC": SourceProfile(authority=0.92, reliability=0.85),
    "NDMA-SACHET": SourceProfile(authority=0.97, reliability=0.9),
    "COPERNICUS": SourceProfile(authority=0.88, reliability=0.8),
    "FIELD_REPORT": SourceProfile(authority=0.75, reliability=0.75),
    "GPS_DEVICE": SourceProfile(authority=0.7, reliability=0.8),
    "sim-imd": SourceProfile(authority=0.3, reliability=0.5),   # demo seed rows
}


def get_profile(source: str) -> SourceProfile:
    return PROFILES.get(source, SourceProfile(authority=0.5))


@dataclass(frozen=True)
class ConfidenceBreakdown:
    source: str
    components: dict
    weights_used: dict
    confidence: float            # 0..1 DATA confidence
    explanation: str


def score(assessment: QualityAssessment, *, spatial_relevance: float = 1.0,
          profile: SourceProfile | None = None,
          weights: ConfidenceWeights | None = None) -> ConfidenceBreakdown:
    """Explainable DATA confidence for one assessed record.

    spatial_relevance: 0..1 overlap between the record's footprint and the
    assessed entity (segment/district/corridor).
    """
    p = profile or get_profile(assessment.source)
    w = (weights or ConfidenceWeights()).normalized()

    # validation status gates everything else (invalid data earns ~nothing)
    gate = {"VALID": 1.0, "PARTIAL": 0.7, "STALE": 0.5}.get(
        assessment.validation_status, 0.05)

    components = {
        "authority": p.authority,
        "freshness": assessment.freshness_score,
        "spatial_relevance": max(0.0, min(1.0, spatial_relevance)),
        "completeness": assessment.quality_score,
        "reliability": p.reliability,
    }
    raw = sum(components[k] * getattr(w, k) for k in components)
    confidence = round(min(1.0, max(0.0, raw * gate)), 4)
    drivers = sorted(components, key=lambda k: -components[k] * getattr(w, k))
    return ConfidenceBreakdown(
        source=assessment.source,
        components={k: round(v, 4) for k, v in components.items()},
        weights_used={k: round(getattr(w, k), 4) for k in components},
        confidence=confidence,
        explanation=(
            f"validation={assessment.validation_status} gates the weighted "
            f"mix; top driver: {drivers[0]}"
            + (f"; issues: {','.join(assessment.issues)}"
               if assessment.issues else "")))
