"""Layer 1 — Data quality assessment (master upgrade §6).

Pure module. Produces the mandated metadata for any observation:

    source · source_type · observed_at · received_at · expires_at · location ·
    quality_score · freshness_score · confidence_score · validation_status

Hard rules:
  * a MISSING value is carried as None — never coerced to 0;
  * impossible values are FLAGGED (validation_status), never silently kept;
  * timestamps in the future (beyond clock skew) are rejected as INVALID.
"""
from dataclasses import dataclass, field
from datetime import datetime, timedelta, timezone

MAX_FUTURE_SKEW_S = 300          # tolerate 5 minutes of clock skew
DEFAULT_MAX_AGE_H = 72.0         # beyond this an observation is STALE


@dataclass
class QualityAssessment:
    source: str
    source_type: str
    observed_at: datetime | None
    received_at: datetime | None
    expires_at: datetime | None
    location: dict | None
    quality_score: float          # 0..1 intrinsic record validity
    freshness_score: float        # 0..1 age decay (1 = just observed)
    validation_status: str        # VALID | PARTIAL | STALE | INVALID
    issues: list[str] = field(default_factory=list)

    @property
    def confidence_score(self) -> float:
        """DATA confidence of this single record (quality x freshness)."""
        return round(self.quality_score * self.freshness_score, 4)


def _age_hours(observed_at: datetime, now: datetime) -> float:
    return (now - observed_at).total_seconds() / 3600.0


def assess(
    *,
    source: str,
    source_type: str,
    observed_at: datetime | str | None,
    received_at: datetime | str | None = None,
    expires_at: datetime | str | None = None,
    values: dict[str, float | None] | None = None,
    ranges: dict[str, tuple[float, float]] | None = None,
    max_age_h: float = DEFAULT_MAX_AGE_H,
    now: datetime | None = None,
    location: dict | None = None,
) -> QualityAssessment:
    """Validate one observation. `values` maps field->value; `ranges` gives the
    plausible (min,max) per field. Missing fields are reported, not defaulted."""
    now = now or datetime.now(timezone.utc)
    issues: list[str] = []

    def _dt(v):
        if v is None:
            return None
        if isinstance(v, str):
            try:
                v = datetime.fromisoformat(v.replace("Z", "+00:00"))
            except ValueError:
                issues.append("malformed_timestamp")
                return None
        if v.tzinfo is None:
            v = v.replace(tzinfo=timezone.utc)
        return v

    obs = _dt(observed_at)
    rec = _dt(received_at)
    exp = _dt(expires_at)

    if obs is None and observed_at is not None:
        pass                                    # malformed already flagged
    if obs is not None:
        if (now - obs).total_seconds() < -MAX_FUTURE_SKEW_S:
            issues.append("timestamp_in_future")
            return QualityAssessment(
                source, source_type, obs, rec, exp, location,
                0.0, 0.0, "INVALID", issues)
        age_h = _age_hours(obs, now)
        if age_h > max_age_h:
            issues.append("stale_observation")

    completeness_total = len(ranges or {})
    completeness_ok = 0
    missing: list[str] = []
    for name, span in (ranges or {}).items():
        val = (values or {}).get(name)
        if val is None:
            missing.append(name)
            continue
        lo, hi = span
        if not lo <= float(val) <= hi:
            issues.append(f"out_of_range:{name}")
            continue
        completeness_ok += 1
    if missing:
        issues.append("missing:" + ",".join(missing))

    n_checked = completeness_total or 1
    range_penalty = min(0.4, 0.2 * sum(1 for i in issues
                                       if i.startswith("out_of_range")))
    quality = round(max(0.0, 1.0 - range_penalty
                        - 0.1 * (len(missing) / n_checked)), 4)
    if obs is not None and "stale_observation" not in issues:
        age_h = _age_hours(obs, now)
        freshness = round(max(0.0, 1.0 - age_h / max_age_h), 4)
    elif obs is not None:
        freshness = 0.0
    else:
        issues.append("missing:observed_at")
        quality = 0.0
        freshness = 0.0

    if "timestamp_in_future" in issues:
        status = "INVALID"
    elif any(i.startswith("out_of_range") for i in issues):
        status = "PARTIAL"
    elif "stale_observation" in issues:
        status = "STALE"
    elif issues:
        status = "PARTIAL"
    else:
        status = "VALID"
    return QualityAssessment(source, source_type, obs, rec, exp, location,
                             quality, freshness, status, issues)


def expiry_for(horizon_minutes: int, now: datetime | None = None) -> datetime:
    """Freshness horizon helper so cached records carry expires_at (§22)."""
    return (now or datetime.now(timezone.utc)) + timedelta(minutes=horizon_minutes)


def condition_fingerprint(parts: list[str]) -> str:
    """Deterministic fingerprint of an alerting condition (§23 dedup)."""
    import hashlib
    return hashlib.sha256("|".join(p.strip().lower()
                                   for p in parts).encode()).hexdigest()[:16]
