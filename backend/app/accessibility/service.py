"""Accessibility scoring service (Phase 5 · C02).

Pure functions (unit-testable without infra) + the DB engine that fuses signals,
derives infrastructure/historical factors, computes weighted scores, classifies,
and appends immutable score rows.

Score = Σ factor_value × factor_weight, 0–100, classified:
    80–100 SAFE · 60–79 CAUTION · 40–59 HIGH_RISK · 0–39 CRITICAL
"""
import json
from typing import Any

from sqlalchemy import text
from sqlalchemy.ext.asyncio import AsyncSession

ENGINE_VERSION = "acc-engine-1.0"

FACTOR_KEYS = ("infrastructure", "weather", "flood_risk", "landslide_risk",
               "traffic", "historical_reliability")

# PROVISIONAL defaults (weights v1). Calibration replaces via new weight versions.
DEFAULT_WEIGHTS = {
    "infrastructure": 0.20, "weather": 0.15, "flood_risk": 0.20,
    "landslide_risk": 0.20, "traffic": 0.10, "historical_reliability": 0.15,
}
DEFAULT_BANDS = [{"min": 80, "label": "SAFE"},
                 {"min": 60, "label": "CAUTION"},
                 {"min": 40, "label": "HIGH_RISK"},
                 {"min": 0, "label": "CRITICAL"}]

NEUTRAL_ASSUMED_VALUE = 55.0   # fail-safe stand-in when a factor has no signal


def validate_weights(weights: dict[str, float]) -> None:
    if set(weights) != set(FACTOR_KEYS):
        raise ValueError(f"weights must cover exactly {sorted(FACTOR_KEYS)}")
    for k, v in weights.items():
        if not (0.0 <= float(v) <= 1.0):
            raise ValueError(f"weight {k}={v} outside [0,1]")
    total = sum(float(v) for v in weights.values())
    if abs(total - 1.0) > 1e-6:
        raise ValueError(f"weights must sum to 1.0 (got {total})")


def validate_bands(bands: list[dict]) -> None:
    mins = sorted((int(b["min"]) for b in bands), reverse=True)
    labels = {b["label"] for b in bands}
    if not {"SAFE", "CAUTION", "HIGH_RISK", "CRITICAL"} <= labels:
        raise ValueError("bands must include SAFE/CAUTION/HIGH_RISK/CRITICAL")
    if mins != [80, 60, 40, 0]:
        raise ValueError("band thresholds must be exactly 80/60/40/0 (frozen)")


def classify(score: float, bands: list[dict] | None = None) -> str:
    for band in sorted(bands or DEFAULT_BANDS, key=lambda b: -b["min"]):
        if score >= band["min"]:
            return band["label"]
    return "CRITICAL"  # pragma: no cover — bands always end at min 0


def compute_score(component_values: dict[str, float],
                  weights: dict[str, float]) -> tuple[float, dict[str, Any]]:
    """Weighted sum with per-factor contribution breakdown.

    component_values missing a key => neutral assumed value, flagged 'assumed'.
    Returns (score, breakdown) where breakdown is the jsonb stored on the row.
    """
    validate_weights(weights)
    breakdown: dict[str, Any] = {}
    score = 0.0
    for key in FACTOR_KEYS:
        raw = component_values.get(key)
        assumed = raw is None
        value = float(raw) if raw is not None else NEUTRAL_ASSUMED_VALUE
        if not 0.0 <= value <= 100.0:
            raise ValueError(f"component {key}={value} outside 0..100")
        w = float(weights[key])
        score += value * w
        breakdown[key] = {"value": round(value, 2), "weight": w,
                          "contribution": round(value * w, 2),
                          "assumed": assumed}
    score = round(min(100.0, max(0.0, score)), 2)
    return score, breakdown


# ------------------------------------------------------------------ engine
async def get_active_weights(db: AsyncSession) -> dict:
    row = (await db.execute(text("""
        select version, weights, bands from accessibility_weights
        where is_active order by version desc limit 1
    """))).mappings().first()
    if row is None:
        raise RuntimeError("no accessibility_weights configured; run seed 0005")
    return {"version": int(row["version"]),
            "weights": json.loads(row["weights"]),
            "bands": json.loads(row["bands"])}


async def _latest_signals(db: AsyncSession, target_type: str):
    """Latest signal per (target, factor kind) within the observation window."""
    return (await db.execute(text("""
        select distinct on (key, tid) key, tid, signal_kind, value
        from (
          select s.signal_kind as signal_kind,
                 coalesce(s.segment_id::text, s.district_code) as key,
                 coalesce(s.segment_id::text, s.district_code) as tid,
                 s.value, s.observed_at,
                 row_number() over (
                   partition by coalesce(s.segment_id::text, s.district_code),
                                s.signal_kind
                   order by s.observed_at desc) as rn
          from geo_factor_signals s
          where s.target_type = :tt
        ) ranked join geo_factor_signals s2
          on s2.target_type = :tt
         and coalesce(s2.segment_id::text, s2.district_code) = ranked.key
         and s2.signal_kind = ranked.signal_kind
         and s2.observed_at = ranked.observed_at
        where ranked.rn = 1
    """), {"tt": target_type})).mappings().all()


async def _segment_infra_values(db: AsyncSession) -> dict[str, float]:
    """Deterministic infrastructure factor from segment surface/status."""
    rows = (await db.execute(text("""
        select rs.id::text as sid,
               case rs.surface when 'PAVED' then 85 when 'RURAL' then 65 else 45 end
                 - case when rs.status = 'CLOSED' then 75
                        when rs.status = 'PARTIAL' then 25
                        else 0 end as infra
        from road_segments rs
    """))).mappings().all()
    return {r["sid"]: max(0.0, float(r["infra"])) for r in rows}


async def run_scoring(db: AsyncSession) -> dict:
    """Full scoring pass over all ROAD_SEGMENT + DISTRICT targets (NFR-02 cadence).

    Returns per-target counts by classification. Runs on the caller's transaction;
    the API invokes it via the system connection (engine is a system job).
    """
    weights_cfg = await get_active_weights(db)
    weights, bands = weights_cfg["weights"], weights_cfg["bands"]

    summary: dict[str, dict] = {}
    for target_type in ("ROAD_SEGMENT", "DISTRICT"):
        signals = await _latest_signals(db, target_type)
        signal_map: dict[str, dict[str, float]] = {}
        for r in signals:
            key = r["key"]
            signal_map.setdefault(key, {})[r["signal_kind"].lower()] = float(r["value"])

        if target_type == "ROAD_SEGMENT":
            infra = await _segment_infra_values(db)
            targets = {row["id"]: None for row in
                       (await db.execute(text(
                           "select id::text as id from road_segments"))
                        ).mappings().all()}
        else:
            infra = {}
            targets = {r["code"]: None for r in (
                await db.execute(text("select code from districts"))
            ).mappings().all()}

        counts = {"SAFE": 0, "CAUTION": 0, "HIGH_RISK": 0, "CRITICAL": 0}
        for tid in targets:
            components = {**signal_map.get(tid, {})}
            if target_type == "ROAD_SEGMENT" and tid in infra:
                components["infrastructure"] = infra[tid]
            score, breakdown = compute_score(components, weights)
            label = classify(score, bands)
            counts[label] += 1
            await db.execute(text("""
                insert into accessibility_scores
                  (target_type, segment_id, district_code, score,
                   classification, components, weights_version, engine_version)
                values (:tt,
                        case when :tt = 'ROAD_SEGMENT' then cast(:tid as uuid) end,
                        case when :tt = 'DISTRICT' then :tid end,
                        :score, :label, cast(:comp as jsonb), :wv, :ev)
            """), {"tt": target_type, "tid": tid, "score": score, "label": label,
                   "comp": json.dumps(breakdown),
                   "wv": weights_cfg["version"], "ev": ENGINE_VERSION})

        summary[target_type] = {
            "targets_scored": len(targets), **counts}

    return {"engine_version": ENGINE_VERSION,
            "weights_version": weights_cfg["version"],
            **{f"{k.lower()}": v for k, v in summary.items()}}


# ------------------------------------------------------------------ queries
async def latest_scores(db: AsyncSession, target_type: str,
                        district_code: str | None) -> list[dict]:
    rows = (await db.execute(text("""
        select distinct on (coalesce(segment_id::text, district_code))
               coalesce(segment_id::text, district_code) as key,
               target_type::text as target_type,
               segment_id::text as segment_id, district_code,
               r.code as road_code, rs.seq,
               d.name as district_name, d.state_code,
               score, classification, components, weights_version,
               engine_version, computed_at
        from accessibility_scores sc
        left join road_segments rs on rs.id = sc.segment_id
        left join roads r on r.id = rs.road_id
        left join districts d on d.code = sc.district_code
        where sc.target_type = :tt
          and (:d is null or sc.district_code = :d)
        order by coalesce(segment_id::text, district_code), computed_at desc
    """), {"tt": target_type, "d": district_code})).mappings().all()
    out = []
    for r in rows:
        item = dict(r)
        item["components"] = json.loads(item["components"])
        out.append(item)
    return out


async def history_for_segment(db: AsyncSession, segment_id: str,
                              limit: int = 20) -> list[dict]:
    rows = (await db.execute(text("""
        select score, classification, components, weights_version,
               engine_version, computed_at
        from accessibility_scores
        where segment_id = cast(:s as uuid)
        order by computed_at desc limit :l
    """), {"s": segment_id, "l": max(1, min(limit, 200))})).mappings().all()
    return [{**dict(r), "components": json.loads(r["components"])} for r in rows]

