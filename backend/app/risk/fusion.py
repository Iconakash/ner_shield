"""Multi-source confidence fusion (master upgrade §14/§15) — DETERMINISTIC.

Rules encoded here:
  * Risk and confidence are SEPARATE axes. Nothing in this module changes a
    risk score; it only scores HOW MUCH the available evidence supports it.
  * Agreement raises confidence ONLY among independent sources, weighted by
    each source's reliability, data quality, spatial relevance and freshness.
  * Dissenting evidence reduces confidence. Agreement never implies certainty:
    fused confidence is hard-capped below 1.0.

Pure functions; no network, no DB — trivially testable and explainable.
"""
from dataclasses import dataclass, field

FRESHNESS_HALF_LIFE_H = 6.0     # a 6h-old observation counts half as much
MAX_FUSED_CONFIDENCE = 0.95     # never claim certainty
AGREEMENT_GAIN = 0.25           # max additive gain per additional agreeing source
DISAGREEMENT_PENALTY = 0.30     # fraction of mean dissent weight subtracted


@dataclass(frozen=True)
class SourceSignal:
    """One normalized observation relevant to an assessed hazard."""
    source: str                  # e.g. IMD / COPERNICUS / CWC / NDMA-SACHET
    hazard: str                  # e.g. FLOOD / LANDSLIDE
    agrees: bool                 # does this signal support the assessed risk?
    age_hours: float = 0.0       # observation age (freshness decay)
    reliability: float = 0.8     # source track record 0..1
    quality: float = 0.8         # validation outcome for this record 0..1
    spatial_relevance: float = 1.0   # overlap with the assessed area 0..1

    def __post_init__(self):
        if not self.source:
            raise ValueError("source required")
        for name in ("reliability", "quality", "spatial_relevance"):
            v = getattr(self, name)
            if not 0.0 <= v <= 1.0:
                raise ValueError(f"{name} must be within [0,1] ({name}={v})")
        if self.age_hours < 0:
            raise ValueError("age_hours cannot be negative")


@dataclass(frozen=True)
class FusionResult:
    hazard: str
    confidence: float
    contributing_sources: list[str]
    dissenting_sources: list[str] = field(default_factory=list)
    notes: str = ""


def individual_confidence(s: SourceSignal) -> float:
    """Freshness-decayed, quality/relevance-weighted trust in one source."""
    freshness = 0.5 ** (s.age_hours / FRESHNESS_HALF_LIFE_H)
    return round(s.reliability * s.quality * s.spatial_relevance * freshness, 4)


def fuse(signals: list[SourceSignal], hazard: str) -> FusionResult:
    """Fuse signals about `hazard` into a single confidence value.

    Deterministic; explainable via contributing/dissenting source lists.
    """
    relevant = [s for s in signals if s.hazard == hazard]
    if not relevant:
        return FusionResult(hazard=hazard, confidence=0.0,
                            contributing_sources=[],
                            notes="no relevant sources — data completeness gap")

    weights = {s.source: individual_confidence(s) for s in relevant}
    agreeing = [s for s in relevant if s.agrees]
    dissenting = [s for s in relevant if not s.agrees]

    if not agreeing:
        return FusionResult(hazard=hazard, confidence=0.0,
                            contributing_sources=[],
                            dissenting_sources=sorted(weights),
                            notes="no supporting signal for assessed hazard")

    ordered = sorted((weights[s.source] for s in agreeing), reverse=True)
    base = ordered[0]
    # Diminishing agreement gain: each additional INDEPENDENT agreeing source
    # contributes AGREEMENT_GAIN x its weight, halved per rank distance.
    gain = sum(w * (0.5 ** i) * AGREEMENT_GAIN
               for i, w in enumerate(ordered[1:], start=1))
    penalty = 0.0
    if dissenting:
        mean_dissent = sum(weights[s.source] for s in dissenting) / len(dissenting)
        penalty = DISAGREEMENT_PENALTY * mean_dissent
    fused = min(MAX_FUSED_CONFIDENCE, max(0.0, base + gain - penalty))

    notes_parts = []
    if len(agreeing) > 1:
        notes_parts.append(
            f"{len(agreeing)} independent sources agree on {hazard}")
    if dissenting:
        notes_parts.append(f"{len(dissenting)} source(s) dissent — "
                           "confidence reduced")
    return FusionResult(hazard=hazard, confidence=round(fused, 4),
                        contributing_sources=[
                            s.source for s in sorted(agreeing,
                                                     key=lambda x: -weights[x.source])],
                        dissenting_sources=sorted({s.source for s in dissenting}),
                        notes="; ".join(notes_parts)
                        or "single-source signal only")