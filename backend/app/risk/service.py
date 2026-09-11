"""Disruption prediction orchestration (C03/C04).

Feature assembly from DB -> predictor (registered XGBoost bundle when available,
heuristic fallback otherwise) -> immutable prediction rows with mandatory
explanations (AI-01). Risk label bands are provisional/calibratable.
"""
import json
from datetime import datetime, timezone
from typing import Optional
from pathlib import Path

from sqlalchemy import text
from sqlalchemy.ext.asyncio import AsyncSession

try:
    from backend.ml.feature_spec import FEATURE_ORDER, sanitize_features
    from backend.ml.heuristic import HORIZONS
    from backend.ml import registry as _ml_registry
except ModuleNotFoundError:  # backend/ is the working dir (uvicorn app.main:app)
    from ml.feature_spec import FEATURE_ORDER, sanitize_features
    from ml.heuristic import HORIZONS
    from ml import registry as _ml_registry

REPO = Path(__file__).resolve().parents[2]
REGISTRY = REPO / "ml_models" / "disruption_xgb"

# Bands calibrated so the source-document example holds: peak 86% => Risk: HIGH.
RISK_LABEL_BANDS = [(90, "CRITICAL"), (70, "HIGH"),
                    (40, "ELEVATED"), (15, "GUARDED"), (0, "LOW")]
SEVERITY_BY_LABEL = {"CRITICAL": "CATASTROPHIC", "HIGH": "MAJOR",
                     "ELEVATED": "MODERATE", "GUARDED": "MINOR",
                     "LOW": "NEGLIGIBLE"}

_model_cache = None


def _load_bundle():
    """Load newest registered XGBoost bundle; None => heuristic mode (AI-04)."""
    global _model_cache
    if _model_cache is not None:
        return _model_cache
    try:
        import joblib
        artifacts = sorted(REGISTRY.glob("*/model.joblib"), reverse=True)
        if artifacts:
            _model_cache = {"bundle": joblib.load(artifacts[0]),
                            "path": str(artifacts[0])}
    except Exception:  # noqa: BLE001
        _model_cache = None
    return _model_cache


def label_for(max_pct: float) -> str:
    for minimum, label in RISK_LABEL_BANDS:
        if max_pct >= minimum:
            return label
    return "LOW"


async def build_feature_rows(db: AsyncSession) -> list[dict]:
    """Assemble the 11 source-mandated features for every road segment.

    rainfall/forecast   <- latest weather_feed row for the segment (0 when absent)
    elevation..slide    <- segment_geo_features (seeded terrain)
    road_condition      <- surface/status derivation (0-100 goodness)
    disruptions/closures <- segment_historical_stats (zero-seeded until history)
    traffic_index       <- latest TRAFFIC accessibility signal
    field_report_score  <- recent hazard-signal proxy until C12 field reports land
    """
    rows = (await db.execute(text("""
        select rs.id::text as segment_id,
               coalesce(wx.rainfall_mm_24h, 0)           as rainfall_mm_24h,
               coalesce(wx.forecast_rainfall_mm_24h, 0)  as forecast_rainfall_mm_24h,
               coalesce(t.elevation_m, 800)              as elevation_m,
               coalesce(t.slope_deg, 10)                 as slope_deg,
               coalesce(t.flood_susceptibility, 40)      as flood_susceptibility,
               coalesce(t.landslide_susceptibility, 40)  as landslide_susceptibility,
               greatest(0,
                 case rs.surface when 'PAVED' then 85 when 'RURAL' then 65 else 45 end
                 - case rs.status when 'CLOSED' then 60
                                  when 'PARTIAL' then 20 else 0 end)
                                                          as road_condition_score,
               coalesce(h.disruptions_12m, 0)             as historical_disruptions_12m,
               coalesce(h.closures_12m, 0)                as historical_closures_12m,
               coalesce(sig.traffic, 45)                  as traffic_index,
               least(coalesce(sig.hazard_max, 0)::numeric * 0.4
                     + coalesce(sig.hazard_count, 0) * 15, 100)
                                                          as field_report_score,
                      r.code as road_code, d.code as district_code,
               wx.observation_id as weather_observation_id,
               wx.observed_at as weather_observed_at,
               wx.confidence as weather_confidence
        from road_segments rs
        join roads r          on r.id = rs.road_id
        left join segment_geo_features t on t.segment_id = rs.id
        left join segment_historical_stats h on h.segment_id = rs.id
        left join lateral (
            select f.id::text as observation_id,
                   f.rainfall_mm_24h, f.forecast_rainfall_mm_24h,
                   f.observed_at, f.source, f.confidence
            from weather_feed f
            where (f.segment_id = rs.id or f.district_code = rs.district_code)
            order by observed_at desc limit 1
        ) wx on true
        left join lateral (
            select avg(case when signal_kind = 'TRAFFIC' then value end) as traffic,
                   max(case when signal_kind in ('FLOOD_RISK','LANDSLIDE_RISK')
                            then value end) as hazard_max,
                   count(*) filter (
                     where signal_kind in ('FLOOD_RISK','LANDSLIDE_RISK')
                       and observed_at > now() - interval '72 hours'
                   ) as hazard_count
            from geo_factor_signals s
            where s.target_type = 'ROAD_SEGMENT' and s.segment_id = rs.id
        ) sig on true
        left join districts d on d.code = rs.district_code
    """))).mappings().all()
    return [dict(r) for r in rows]

def predict_for_features(segment: dict,
                         artifact_path: str | None = None) -> dict:
    """Run prediction for one segment.

    Registry-gated (Phase 8): XGBoost inference runs ONLY when the caller
    resolved an approved PRODUCTION artifact from the ML registry. Otherwise
    the transparent heuristic is used and labeled as such — a synthetic-data
    DEMO bundle on disk can no longer silently serve predictions.
    """
    raw = {k: segment.get(k) for k in FEATURE_ORDER_KEYS}
    feats = sanitize_features(raw)

    if artifact_path:
        import joblib

        import numpy as np
        bundle = joblib.load(artifact_path)
        vec = np.array([to_vector(feats)])
        horizons = {}
        for h in HORIZONS:
            horizons[h] = round(float(bundle["models"][h].predict(vec)[0]), 1)
        mode, model_version = "xgb", Path(artifact_path).parent.name
        top_factors, all_factors, base_value = shap_top_factors(bundle, vec, feats)
    else:
        try:
            from backend.ml.heuristic import predict_horizons
        except ModuleNotFoundError:
            from ml.heuristic import predict_horizons
        result = predict_horizons(feats)
        horizons = result["horizons"]
        top_factors = result["top_factors"]
        all_factors = result["all_factors"]
        base_value = result["base"]
        mode, model_version = "heuristic", "rule-1.0"

    max_pct = max(horizons.values())
    peak_horizon = max(horizons, key=lambda k: horizons[k])
    label = label_for(max_pct)
    summary = build_summary(segment.get("road_code"),
                            segment.get("district_name") or
                            (segment.get("district_code")),
                            label, max_pct, peak_horizon, top_factors)
    return {"horizons": horizons, "overall_label": label,
            "severity": SEVERITY_BY_LABEL[label],
            "top_factors": top_factors, "all_factors": all_factors,
            "base_value": base_value, "summary_sentence": summary,
            "mode": mode,
            "model_name": "disruption_xgb" if mode == "xgb" else "disruption_rule",
            "model_version": model_version}


def to_vector(feats: dict) -> list[float]:
    return [float(feats[name]) for name in FEATURE_ORDER]  # module-level import


def shap_top_factors(bundle, vec, feats: dict) -> tuple[list[dict], list[dict]]:
    """TreeExplainer contributions aggregated across horizon models.

    Returns (top_factors, all_factors). Falls back to the heuristic's exact
    additive decomposition when SHAP is unavailable — still a faithful local
    explanation for that mode (AI-01).
    """
    try:
        import numpy as np
        import shap
        combined = None
        expected = None
        for _h, model in bundle["models"].items():
            explainer = shap.TreeExplainer(model)
            sv = np.array(explainer.shap_values(vec))[0]
            combined = sv if combined is None else combined + sv
            ev = explainer.expected_value
            expected = float(ev) if expected is None else expected  # first wins
        order = sorted(zip(FEATURE_ORDER, combined), key=lambda kv: -abs(kv[1]))
        from backend.ml.feature_spec import FEATURE_LABELS
        allf = [{"feature": k, "label": FEATURE_LABELS[k],
                 "contribution": round(float(v), 2)} for k, v in order]
        return allf[:5], allf, round(float(expected or 45.0), 1)
    except Exception:  # noqa: BLE001 — SHAP optional at inference time
        try:
            from backend.ml.heuristic import predict_horizons
        except ModuleNotFoundError:
            from ml.heuristic import predict_horizons
        result = predict_horizons(feats)
        return (result["top_factors"], result["all_factors"], result["base"])


DRIVER_PHRASES = {
    "rainfall_mm_24h": "recent heavy rainfall",
    "forecast_rainfall_mm_24h": "heavy forecast rainfall",
    "elevation_m": "high-altitude terrain",
    "slope_deg": "steep slope exposure",
    "flood_susceptibility": "flood-prone lowland",
    "landslide_susceptibility": "landslide-prone terrain",
    "road_condition_score": "degraded road condition",
    "historical_disruptions_12m": "prior disruption history",
    "historical_closures_12m": "historical closure frequency",
    "traffic_index": "heavy traffic load",
    "field_report_score": "fresh field intelligence",
}


def build_summary(road_code: str | None, district_name: str | None,
                  label: str, peak_pct: float, peak_horizon: str,
                  top_factors: list[dict]) -> str:
    """Plain-language WHY sentence (FR-C04.1): label + where + when + drivers."""
    drivers = ", ".join(
        f"{DRIVER_PHRASES.get(f['feature'], f['feature'])} "
        f"({float(f['contribution']):+.1f})"
        for f in top_factors[:3])
    road = road_code or "this corridor"
    place = f" near {district_name}" if district_name else ""
    return (f"{label} disruption risk on {road}{place}: "
            f"peaks at {peak_pct:.0f}% within {peak_horizon}. "
            f"Primary drivers: {drivers}.")



async def persist_predictions(db: AsyncSession, results: list[dict]) -> int:
    inserted = 0
    for res in results:
        h = res["horizons"]
        await db.execute(text("""
            insert into disruption_predictions
              (target_type, segment_id, district_code,
               risk_current, risk_6h, risk_12h, risk_24h, risk_72h,
               overall_label, severity, top_factors, feature_values,
               model_name, model_version, mode,
               base_value, all_factors, summary_sentence)
            values ('ROAD_SEGMENT', cast(:seg as uuid), :dist,
                    :c, :h6, :h12, :h24, :h72, :label, :sev,
                    cast(:tf as jsonb), cast(:fv as jsonb),
                    :mn, :mv, :mode,
                    :base, cast(:af as jsonb), :summary)
        """), {"seg": res["segment_id"], "dist": res.get("district_code"),
               "c": h["current"], "h6": h["6h"], "h12": h["12h"],
               "h24": h["24h"], "h72": h["72h"],
               "label": res["overall_label"], "sev": res["severity"],
               "tf": json.dumps(res["top_factors"]),
               "fv": json.dumps(res["feature_values"]),
               "mn": res["model_name"], "mv": res["model_version"],
               "mode": res["mode"],
               "base": res.get("base_value"),
               "af": json.dumps(res.get("all_factors") or []),
               "summary": res.get("summary_sentence")})
        inserted += 1
    return inserted


async def run_prediction_pass(db: AsyncSession) -> dict:
    """Full-region pass (NFR-02 cadence): features -> predict -> persist.

    Phase 8 governance: the XGBoost bundle is used ONLY if an approved
    PRODUCTION version is registered in ml_model_versions; otherwise the
    transparent heuristic serves predictions. Every prediction gets an
    ml_predictions row + feature snapshot, and its weather observation is
    linked as evidence (lineage trail answerable via evidence_trail()).
    """
    try:
        artifact = await _ml_registry.active_production_artifact(
            db, "disruption_xgb")
    except Exception:  # noqa: BLE001 — registry tables may not exist yet
        artifact = None

    segments = await build_feature_rows(db)
    results = []
    for seg in segments:
        started = datetime.now(timezone.utc)
        prediction = predict_for_features(seg, artifact_path=artifact)
        prediction["feature_values"] = sanitize_features(
            {k: seg.get(k) for k in FEATURE_ORDER_KEYS})
        prediction["segment_id"] = seg["segment_id"]
        prediction["district_code"] = seg.get("district_code")
        results.append(prediction)

        try:
            pid = await _ml_registry.record_prediction(
                db, target_type="ROAD_SEGMENT", target_id=seg["segment_id"],
                outputs={"horizons": prediction["horizons"],
                         "overall_label": prediction["overall_label"],
                         "mode": prediction["mode"],
                         "model_version": prediction["model_version"]},
                features=prediction["feature_values"],
                latency_ms=(datetime.now(timezone.utc) - started)
                .total_seconds() * 1000.0)
            obs = seg.get("weather_observation_id")
            if obs:
                await _ml_registry.link_evidence(
                    db, pid, source="weather_feed", source_record_id=obs,
                    observed_at=seg.get("weather_observed_at"),
                    confidence=float(seg["weather_confidence"])
                    if seg.get("weather_confidence") is not None else None)
        except Exception:  # noqa: BLE001 — lineage must not break predictions
            pass

    count = await persist_predictions(db, results)
    labels = {}
    for r in results:
        labels[r["overall_label"]] = labels.get(r["overall_label"], 0) + 1
    return {"targets_predicted": count, "labels": labels,
            "model_mode": "xgb" if artifact else "heuristic"}


async def latest_predictions(db: AsyncSession, district_code: str | None):
    rows = (await db.execute(text("""
        select distinct on (p.segment_id::text)
               p.segment_id::text as segment_id, r.code as road_code,
               d.code as district_code, d.name as district_name,
               p.risk_current, p.risk_6h, p.risk_12h, p.risk_24h, p.risk_72h,
               p.overall_label, p.severity, p.top_factors, p.summary_sentence,
               p.base_value, p.mode, p.model_name, p.model_version, p.computed_at
        from disruption_predictions p
        left join road_segments rs on rs.id = p.segment_id
        left join roads r on r.id = rs.road_id
        left join districts d on d.code = rs.district_code
        where (cast(:d as text) is null or d.code = cast(:d as text))
        order by p.segment_id::text, p.computed_at desc limit 200
    """), {"d": district_code})).mappings().all()
    out = []
    for r in rows:
        item = dict(r)
        item["top_factors"] = json.loads(item["top_factors"])
        out.append(item)
    return out


FEATURE_ORDER_KEYS = FEATURE_ORDER


# ---------------------------------------------------------------- Phase 7: WHY?
def summarize_route(route_rows: list[dict], horizon: str = "24h") -> dict:
    """Pure aggregation for 'Why will this route fail?' (killer-feature contract)."""
    if not route_rows:
        return {"verdict": "PASSABLE", "segments_assessed": 0,
                "narrative": "No segments assessed along this route."}

    worst = max(route_rows, key=lambda r: r.get("risk_pct") or 0)
    bad_labels = {"HIGH", "CRITICAL"}
    failing = [r for r in route_rows
               if r.get("overall_label") in bad_labels
               or r.get("acc_classification") == "CRITICAL"]
    pct_failing = round(100.0 * len(failing) / len(route_rows), 1)
    verdict = label_for(float(worst.get("risk_pct") or 0))

    totals: dict[str, float] = {}
    labels: dict[str, str] = {}
    explained = 0
    for r in route_rows:
        factors = r.get("all_factors") or []
        if factors:
            explained += 1
        for f in factors:
            key = f["feature"]
            labels[key] = f.get("label", key)
            totals[key] = totals.get(key, 0.0) + float(f.get("contribution", 0))
    drivers = sorted(
        ({"feature": k, "label": labels[k],
          "avg_contribution": round(v / max(1, explained), 2)}
         for k, v in totals.items()),
        key=lambda d: -abs(d["avg_contribution"]))[:4]

    road = route_rows[0].get("road_code") or "this corridor"
    driver_txt = ", ".join(f"{d['label']} ({d['avg_contribution']:+.1f})"
                           for d in drivers) or "no dominant single cause"
    narrative = (
        f"{len(route_rows)} segments assessed on {road} at {horizon}: "
        f"{pct_failing}% are HIGH/CRITICAL. Worst point: "
        f"{worst.get('district_name') or worst.get('district_code') or 'segment'} "
        f"at {float(worst.get('risk_pct') or 0):.0f}% "
        f"({worst.get('overall_label')}). "
        f"Dominant causes across the route: {driver_txt}."
        + (" Route should NOT be used without mitigation."
           if verdict in ("HIGH", "CRITICAL") else ""))

    return {"verdict": verdict, "horizon": horizon,
            "segments_assessed": len(route_rows),
            "segments_high_or_critical": len(failing),
            "percent_failing": pct_failing,
            "worst_segment": {k: worst.get(k) for k in
                              ("seq", "district_name", "district_code",
                               "risk_pct", "overall_label")},
            "aggregated_drivers": drivers,
            "narrative": narrative}


async def explain_segment(db: AsyncSession, segment_id: str) -> Optional[dict]:
    """Local explanation for the newest prediction on a segment + evidence."""
    row = (await db.execute(text("""
        select p.id::text as prediction_id, p.segment_id::text as segment_id,
               r.code as road_code, d.code as district_code,
               d.name as district_name,
               p.risk_current, p.risk_6h, p.risk_12h, p.risk_24h, p.risk_72h,
               p.overall_label, p.severity, p.base_value,
               p.all_factors, p.top_factors, p.summary_sentence,
               p.model_name, p.model_version, p.mode, p.computed_at,
               wx.source as weather_source, wx.observed_at as weather_observed_at
        from disruption_predictions p
        left join road_segments rs on rs.id = p.segment_id
        left join roads r on r.id = rs.road_id
        left join districts d on d.code = rs.district_code
        left join lateral (
            select source, observed_at from weather_feed w
            where w.segment_id = p.segment_id
            order by observed_at desc limit 1
        ) wx on true
        where p.segment_id = cast(:s as uuid)
        order by p.computed_at desc limit 1
    """), {"s": segment_id})).mappings().first()
    if row is None:
        return None
    item = dict(row)
    item["all_factors"] = json.loads(item["all_factors"] or "[]")
    item["top_factors"] = json.loads(item["top_factors"] or "[]")
    item["horizons"] = {"current": float(item.pop("risk_current")),
                        "6h": float(item.pop("risk_6h")),
                        "12h": float(item.pop("risk_12h")),
                        "24h": float(item.pop("risk_24h")),
                        "72h": float(item.pop("risk_72h"))}
    item["evidence"] = {
        "weather_source": item.pop("weather_source") or "no observation",
        "weather_observed_at": (str(item.pop("weather_observed_at"))
                                if item.get("weather_observed_at") else None),
    }
    return item


async def route_segments_with_intel(db: AsyncSession, shipment_id: str,
                                    horizon: str = "24h"):
    col = {"current": "risk_current", "6h": "risk_6h", "12h": "risk_12h",
           "24h": "risk_24h", "72h": "risk_72h"}[horizon]
    rows = (await db.execute(text(f"""
        select rs.seq, r.code as road_code, d.name as district_name,
               d.code as district_code, rs.status::text as status,
               (select classification from accessibility_scores a
                 where a.segment_id = rs.id order by computed_at desc limit 1
               ) as acc_classification,
               (select round({col}, 1) from disruption_predictions dp
                 where dp.segment_id = rs.id order by computed_at desc limit 1
               ) as risk_pct,
               (select overall_label from disruption_predictions dp
                 where dp.segment_id = rs.id order by computed_at desc limit 1
               ) as overall_label,
               (select all_factors from disruption_predictions dp
                 where dp.segment_id = rs.id order by computed_at desc limit 1
               ) as all_factors
        from shipments sh
        join road_segments rs on rs.road_id = sh.route_road_id
        join roads r on r.id = sh.route_road_id
        left join districts d on d.code = rs.district_code
        where sh.id = cast(:i as uuid)
        order by rs.seq
    """), {"i": shipment_id})).mappings().all()
    out = []
    for r in rows:
        item = dict(r)
        if item.get("all_factors"):
            item["all_factors"] = json.loads(item["all_factors"])
        out.append(item)
    return out




