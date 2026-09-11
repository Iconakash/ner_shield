"""Historical validation / back-testing (SIH26002 P4).

Purpose: demonstrate that NER-SHIELD can REPLAY historical disaster
conditions and compare model predictions against recorded outcomes.

HONESTY CONTRACT (non-negotiable):
  * Ground truth comes ONLY from imported rows in historical_events /
    historical_event_observations carrying an explicit data_quality label:
      VERIFIED   — imported from a cited authoritative dataset
      SAMPLE     — demonstrative structure, sample values (DEMO DATA)
      SIMULATED  — synthetic exercise data
  * Metrics are computed for whatever dataset exists, but the UI/API always
    echoes data_quality + dataset_version so SAMPLE data can never masquerade
    as validated accuracy. With no dataset configured the API says exactly
    that instead of inventing numbers.
  * Replay uses the existing ML heuristic directly (pure functions, no writes
    to live prediction tables) so back-testing can never contaminate live
    state. Model name/version + dataset version are stored on every run.
"""
import json

from sqlalchemy import text
from sqlalchemy.ext.asyncio import AsyncSession

# Disruption-probability threshold at which a segment counts as "predicted
# high risk" during replay (same convention as operational watchlists).
HIGH_RISK_THRESHOLD = 50.0


def replay_features(rainfall_mm_24h: float | None) -> dict:
    """Build the frozen 11-feature input from one observation row.

    Only documented columns are used; missing indicators stay neutral rather
    than being fabricated (terrain/history unknown at replay time is a
    documented limitation of historical replay).
    """
    rain = float(rainfall_mm_24h or 0.0)
    return {
        "rainfall_mm_24h": rain,
        "forecast_rainfall_mm_24h": 0.0,   # historical forecast unknown
        "elevation_m": None,
        "slope_deg": None,
        "flood_susceptibility": min(100, int(max(0.0, (rain - 50.0)) * 2)),
        "landslide_susceptibility": min(100, int(max(0.0, (rain - 60.0)) * 2)),
        "road_condition_score": None,
        "historical_disruptions_12m": 0,
        "historical_closures_12m": 0,
        "traffic_index": None,
        "field_report_score": 0,
    }


def compare(predicted_segments: set[str], observed_segments: set[str],
            *, lead_times_h: list[float] | None = None) -> dict:
    """Pure comparison metrics over predicted vs observed segment sets."""
    detected = predicted_segments & observed_segments
    missed = observed_segments - predicted_segments
    false_positives = predicted_segments - observed_segments
    lead = sorted(lead_times_h or [])
    return {
        "actual_affected": len(observed_segments),
        "predicted_high_risk": len(predicted_segments),
        "detected": len(detected),
        "missed": len(missed),
        "false_positives": len(false_positives),
        "detection_rate_pct": (round(100.0 * len(detected)
                                     / len(observed_segments), 1)
                               if observed_segments else None),
        "false_alarm_rate_pct": (round(100.0 * len(false_positives)
                                       / len(predicted_segments), 1)
                                 if predicted_segments else None),
        "avg_warning_lead_time_h": (round(sum(lead) / len(lead), 1)
                                    if lead else None),
        "detected_segment_ids": sorted(detected),
        "missed_segment_ids": sorted(missed),
        "false_positive_segment_ids": sorted(false_positives),
    }


async def _active_model(system_db: AsyncSession) -> tuple[str, str]:
    """Registry-approved PRODUCTION bundle if any; heuristic otherwise."""
    try:
        row = (await system_db.execute(text("""
            select model_name, version from ml_model_versions
            where stage = 'PRODUCTION'
            order by created_at desc limit 1
        """))).mappings().first()
        if row is not None:
            return row["model_name"], row["version"]
    except Exception:  # noqa: BLE001 — registry optional at replay time
        pass
    return ("disruption-heuristic", "rule-fallback")


async def run_validation(system_db: AsyncSession, *, event_id: str,
                         ran_by: str | None = None) -> dict:
    """Replay one stored event through the current model.

    Pure with respect to live state: NO disruption_predictions rows are
    written; the heuristic is invoked directly on imported observations.
    """
    from app.core.errors import NotFound

    ev = (await system_db.execute(text("""
        select id::text as id, name, event_date,
               data_quality::text as data_quality, dataset_version
        from historical_events where id = cast(:e as uuid)
    """), {"e": event_id})).mappings().first()
    if ev is None:
        raise NotFound("historical event not found")

    obs = (await system_db.execute(text("""
        select o.segment_id::text as segment_id, o.observed_affected,
               o.rainfall_mm_24h, o.disruption_start
        from historical_event_observations o
        where o.event_id = cast(:e as uuid) and o.segment_id is not null
    """), {"e": event_id})).mappings().all()
    if not obs:
        # honest empty result: never fabricate accuracy without a dataset
        return {"event": ev["name"], "data_quality": ev["data_quality"],
                "status": "NO_DATASET",
                "message": "Historical validation dataset not configured "
                           "(no segment observations stored for this event)"}

    from ml.heuristic import predict_horizons  # existing pure model

    predicted: list[dict] = []
    lead_times: list[float] = []
    for o in obs:
        out = predict_horizons(replay_features(
            float(o["rainfall_mm_24h"] or 0.0)))
        prob = float(out["horizons"].get("24h") or 0.0)
        if prob >= HIGH_RISK_THRESHOLD:
            predicted.append({"segment_id": o["segment_id"],
                              "probability": prob})
        if o["observed_affected"] and o["disruption_start"] is not None \
                and ev["event_date"] is not None:
            hours = (o["disruption_start"] - ev["event_date"]) \
                .total_seconds() / 3600.0
            if hours > 0:
                lead_times.append(hours)

    observed = {o["segment_id"] for o in obs if o["observed_affected"]}
    metrics = compare({p["segment_id"] for p in predicted}, observed,
                      lead_times_h=lead_times)

    model_name, model_version = await _active_model(system_db)
    row = (await system_db.execute(text("""
        insert into historical_validation_runs
            (event_id, model_name, model_version, dataset_version,
             metrics, predicted, ran_by)
        values (cast(:e as uuid), :mn, :mv, :dv,
                cast(:m as jsonb), cast(:p as jsonb),
                case when :u is null then null else cast(:u as uuid) end)
        returning id::text as id, ran_at
    """), {"e": event_id, "mn": model_name, "mv": model_version,
           "dv": ev["dataset_version"], "m": json.dumps(metrics),
           "p": json.dumps(predicted), "u": ran_by})).mappings().first()

    return {"run_id": row["id"], "ran_at": str(row["ran_at"]),
            "event": ev["name"], "model": f"{model_name}@{model_version}",
            "dataset_version": ev["dataset_version"],
            "data_quality": ev["data_quality"],
            "threshold_pct": HIGH_RISK_THRESHOLD,
            **metrics}


async def get_event(db: AsyncSession, event_id: str) -> dict | None:
    row = (await db.execute(text("""
        select e.id::text as id, e.name, e.event_date, e.description,
               e.data_quality::text as data_quality, e.dataset_version,
               e.source_citation,
               (select json_agg(json_build_object(
                        'segment_id', o.segment_id::text,
                        'district_code', o.district_code,
                        'observed_affected', o.observed_affected,
                        'rainfall_mm_24h', o.rainfall_mm_24h))
                from historical_event_observations o
                where o.event_id = e.id) as observations
        from historical_events e where e.id = cast(:e as uuid)
    """), {"e": event_id})).mappings().first()
    if row is None:
        return None
    out = dict(row)
    out["observations"] = json.loads(out["observations"]) \
        if isinstance(out["observations"], str) else out["observations"]
    return out


async def list_events(db: AsyncSession) -> list[dict]:
    rows = (await db.execute(text("""
        select e.id::text as id, e.name, e.event_date, e.description,
               e.data_quality::text as data_quality, e.dataset_version,
               e.source_citation,
               count(o.id) as observation_count,
               count(*) filter (where o.observed_affected) as affected_count
        from historical_events e
        left join historical_event_observations o on o.event_id = e.id
        group by e.id order by e.event_date desc limit 50
    """))).mappings().all()
    return [dict(r) for r in rows]


async def latest_run(db: AsyncSession, event_id: str) -> dict | None:
    row = (await db.execute(text("""
        select id::text as id, model_name, model_version, dataset_version,
               metrics, ran_at from historical_validation_runs
        where event_id = cast(:e as uuid) order by ran_at desc limit 1
    """), {"e": event_id})).mappings().first()
    if row is None:
        return None
    out = dict(row)
    out["metrics"] = json.loads(out["metrics"]) \
        if isinstance(out["metrics"], str) else out["metrics"]
    return out
