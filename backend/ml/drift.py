"""Population-Stability Index (PSI) drift metric + prediction/performance drift.

PURE functions (unit-tested with hand-known inputs).

PSI compares a live feature distribution against a training reference:
    PSI = sum( (live_pct - ref_pct) * ln(live_pct / ref_pct) )
Standard thresholds: <0.10 stable · 0.10-0.25 monitor · >=0.25 DRIFT.

Phase 9 §9.6 adds:
  * prediction_drift — PSI on the model's own output distribution (a shift in
    predicted risk scores signals the world has changed even if inputs look fine).
  * performance_degradation — when ground-truth labels arrive, compare recent
    accuracy against the validation baseline; a sustained drop flags the model.
"""
import math

DRIFT_WARN = 0.10
DRIFT_BREACH = 0.25


def bucketize(values: list[float], edges: list[float]) -> list[int]:
    """Assign each value an index into len(edges)-1 buckets."""
    out = []
    for v in values:
        idx = 0
        for i, e in enumerate(edges):
            if v >= e:
                idx = i
        out.append(min(idx, len(edges) - 2))
    return out


def psi(reference: list[float], live: list[float],
        bins: int = 10, epsilon: float = 1e-6) -> float:
    """PSI between two samples. Degenerate inputs return 0.0 (no signal)."""
    if not reference or not live:
        return 0.0
    lo, hi = min(reference), max(reference)
    if hi <= lo:
        # constant reference: any mass off the constant is maximal drift
        const = reference[0]
        off = sum(1 for v in live if v != const)
        frac = off / len(live)
        if frac == 0:
            return 0.0
        lp, rp = max(frac, epsilon), max(1 - frac, epsilon)
        return round((lp - rp) * math.log(lp / rp)
                     + (rp - lp) * math.log(rp / lp), 4)

    width = (hi - lo) / bins
    edges = [lo + i * width for i in range(bins + 1)]

    def shares(sample):
        b = [0] * bins
        for v in sample:
            i = min(int((v - lo) / width), bins - 1)
            b[i] += 1
        n = len(sample)
        return [max(c / n, epsilon) for c in b]

    r, l = shares(reference), shares(live)
    total = sum((lv - rv) * math.log(lv / rv) for lv, rv in zip(l, r))
    return round(total, 4)


def classify(psi_value: float) -> str:
    if psi_value >= DRIFT_BREACH:
        return "DRIFT"
    if psi_value >= DRIFT_WARN:
        return "MONITOR"
    return "STABLE"


# ---------------------------------------------------- prediction drift (§9.6)
def prediction_drift(reference_scores: list[float],
                     live_scores: list[float], bins: int = 10) -> dict:
    """PSI on the model's output distribution. A shift in predicted-risk
    scores (even with stable inputs) signals the relationship has changed.
    Returns {'psi', 'class', 'reference_mean', 'live_mean'}."""
    value = psi(reference_scores, live_scores, bins=bins)
    ref_mean = (sum(reference_scores) / len(reference_scores)
                if reference_scores else 0.0)
    live_mean = (sum(live_scores) / len(live_scores)
                 if live_scores else 0.0)
    return {"psi": value, "class": classify(value),
            "reference_mean": round(ref_mean, 3),
            "live_mean": round(live_mean, 3)}


# ---------------------------------------------- performance degradation (§9.6)
def performance_degradation(recent_accuracy: float,
                            validation_accuracy: float,
                            drop_threshold: float = 0.05) -> dict:
    """Compare recent labeled accuracy against the validation baseline.
    A drop bigger than `drop_threshold` flags degradation. Returns
    {'degraded', 'recent', 'baseline', 'drop'}."""
    drop = validation_accuracy - recent_accuracy
    return {"degraded": drop > drop_threshold,
            "recent": round(recent_accuracy, 4),
            "baseline": round(validation_accuracy, 4),
            "drop": round(drop, 4)}
