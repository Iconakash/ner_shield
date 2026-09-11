"""ML model REGISTRY operations (master upgrade §17-18).

Guarantees:
  * Every version carries training-data lineage; synthetic-trained versions
    are born DEMO and the application refuses DEMO->PRODUCTION promotion.
  * Production inference resolves ONLY the is_current PRODUCTION version.
  * Promotions are explicit human decisions recorded in ml_promotions.
"""
import hashlib
import json

from sqlalchemy import text
from sqlalchemy.ext.asyncio import AsyncSession


class PromotionDenied(Exception):
    pass


def promotion_allowed(from_stage: str, to_stage: str,
                      has_evaluations: bool = False) -> tuple[bool, str]:
    """PURE stage-transition rule (unit-tested). Returns (allowed, reason).
    Hard rules:
      * DEMO -> PRODUCTION is forbidden outright (must pass VALIDATION)
      * any move INTO PRODUCTION requires recorded evaluation metrics
      * backwards moves are forbidden except retirement
    """
    order = ["DEMO", "VALIDATION", "PRODUCTION", "RETIRED"]
    if from_stage not in order or to_stage not in order:
        return False, f"unknown stage(s): {from_stage} -> {to_stage}"
    if from_stage == to_stage:
        return False, "no-op transition"
    if from_stage == "DEMO" and to_stage == "PRODUCTION":
        return False, ("DEMO models (e.g. synthetic-trained) must pass "
                       "VALIDATION with evaluations before PRODUCTION")
    if to_stage == "PRODUCTION" and not has_evaluations:
        return False, "no evaluation metrics recorded for this version"
    if order.index(to_stage) < order.index(from_stage) and to_stage != "RETIRED":
        return False, f"cannot demote {from_stage} -> {to_stage}"
    return True, "ok"


async def ensure_model(db: AsyncSession, name: str, task: str,
                       feature_spec: dict) -> str:
    row = (await db.execute(text("""
        insert into ml_models (name, task, feature_spec)
        values (:n, :t, cast(:f as jsonb))
        on conflict (name) do update set task = excluded.task
        returning id::text as id
    """), {"n": name, "t": task, "f": json.dumps(feature_spec)}
    )).mappings().first()
    return row["id"]


async def register_version(db: AsyncSession, model_name: str, version: str,
                           artifact_uri: str, training_dataset: str,
                           hyperparameters: dict | None = None,
                           notes: str = "", created_by: str = "system",
                           stage: str = "DEMO") -> dict:
    """Register a trained artifact. Synthetic-data models MUST stay DEMO."""
    if "synthetic" in training_dataset.lower() and stage != "DEMO":
        raise PromotionDenied(
            "synthetic-data models cannot be registered above DEMO stage")
    row = (await db.execute(text("""
        insert into ml_model_versions (model_id, version, artifact_uri,
            training_dataset, hyperparameters, notes, created_by, stage)
        values ((select id from ml_models where name = :m),
                :v, :a, :td, cast(:h as jsonb), :notes, :cb,
                cast(:s as model_stage))
        on conflict (model_id, version) do update
          set artifact_uri = excluded.artifact_uri
        returning id::text as id, stage::text as stage
    """), {"m": model_name, "v": version, "a": artifact_uri,
           "td": training_dataset, "h": json.dumps(hyperparameters or {}),
           "notes": notes, "cb": created_by, "s": stage})).mappings().first()
    return dict(row)


async def promote(db: AsyncSession, version_id: str, to_stage: str,
                  approved_by: str, justification: str) -> dict:
    """Explicit, audited stage transition. Hard rules:
       DEMO -> PRODUCTION forbidden (must pass VALIDATION with metrics);
       -> PRODUCTION requires at least one evaluation metric recorded."""
    cur = (await db.execute(text(
        "select stage::text as s from ml_model_versions"
        " where id = cast(:i as uuid)"),
        {"i": version_id})).mappings().first()
    if cur is None:
        from app.core.errors import NotFound
        raise NotFound("model version not found")
    frm = cur["s"]

    n = (await db.execute(text(
        "select count(*) from ml_evaluations where version_id"
        " = cast(:i as uuid)"), {"i": version_id})).scalar()
    allowed, reason = promotion_allowed(frm, to_stage, has_evaluations=bool(n))
    if not allowed:
        raise PromotionDenied(reason)

    await db.execute(text("""
        insert into ml_promotions (version_id, from_stage, to_stage,
                                   approved_by, justification)
        values (cast(:i as uuid), cast(:f as model_stage),
                cast(:t as model_stage), :by, :just)
    """), {"i": version_id, "f": frm, "t": to_stage,
           "by": approved_by, "just": justification})

    if to_stage == "PRODUCTION":
        mid = (await db.execute(text(
            "select model_id from ml_model_versions where id"
            " = cast(:i as uuid)"), {"i": version_id})).scalar()
        await db.execute(text(
            "update ml_model_versions set is_current = false"
            " where model_id = cast(:m as uuid)"
            " and stage = 'PRODUCTION'"),
            {"m": str(mid)})
        await db.execute(text(
            "update ml_model_versions set is_current = true"
            " where id = cast(:i as uuid)"), {"i": version_id})
    elif to_stage == "RETIRED":
        await db.execute(text(
            "update ml_model_versions set is_current = false"
            " where id = cast(:i as uuid)"), {"i": version_id})

    await db.execute(text(
        "update ml_model_versions set stage = cast(:t as model_stage)"
        " where id = cast(:i as uuid)"), {"i": version_id, "t": to_stage})
    return {"version_id": version_id, "from": frm, "to": to_stage}


async def active_production_artifact(db: AsyncSession,
                                     model_name: str) -> str | None:
    """Artifact URI of the current PRODUCTION version — None means 'no
    production model approved; fall back to the transparent heuristic'."""
    row = (await db.execute(text("""
        select v.artifact_uri from ml_model_versions v
        join ml_models m on m.id = v.model_id
        where m.name = :m and v.stage = 'PRODUCTION' and v.is_current
        limit 1
    """), {"m": model_name})).mappings().first()
    return row["artifact_uri"] if row else None


async def record_evaluation(db: AsyncSession, version_id: str,
                            metric_name: str, value: float,
                            horizon: str | None = None,
                            slice_: str = "overall",
                            validation_period: str | None = None) -> None:
    await db.execute(text("""
        insert into ml_evaluations (version_id, metric_name, horizon, slice,
                                    value, validation_period)
        values (cast(:v as uuid), :m, :h, :s, cast(:val as numeric),
                cast(:p as daterange))
        on conflict (version_id, metric_name, horizon, slice)
        do update set value = excluded.value
    """), {"v": version_id, "m": metric_name, "h": horizon, "s": slice_,
           "val": value, "p": validation_period})


def feature_hash(features: dict) -> str:
    canon = json.dumps(features, sort_keys=True, separators=(",", ":"))
    return hashlib.sha256(canon.encode()).hexdigest()


async def record_prediction(db: AsyncSession, *, model_id: str | None = None,
                            version_id: str | None = None,
                            target_type: str, target_id: str,
                            outputs: dict, features: dict | None = None,
                            latency_ms: float | None = None,
                            evidence_ids: list[str] | None = None) -> int:
    """Persist one inference for audit/drift; returns prediction row id."""
    row = (await db.execute(text("""
        insert into ml_predictions (model_id, version_id, target_type,
                                    target_id, outputs, latency_ms,
                                    evidence_ids)
        values (cast(:m as uuid), cast(:v as uuid), :tt, :ti,
                cast(:o as jsonb), cast(:lat as numeric), cast(:ev as jsonb))
        returning id
    """), {"m": model_id, "v": version_id, "tt": target_type, "ti": target_id,
           "o": json.dumps(outputs), "lat": latency_ms,
           "ev": json.dumps(evidence_ids or [])})).mappings().first()
    pid = row["id"]
    if features is not None:
        await db.execute(text("""
            insert into ml_feature_snapshots (prediction_id, features,
                                              feature_hash)
            values (:p, cast(:f as jsonb), :fh)
        """), {"p": pid, "f": json.dumps(features),
               "fh": feature_hash(features)})
    return pid


async def link_evidence(db: AsyncSession, prediction_id: int,
                        source: str, source_record_id: str,
                        observed_at=None, confidence: float | None = None,
                        payload_hash: str | None = None) -> str:
    """Create-or-reuse an evidence_record and link it to this prediction."""
    import hashlib as _hl

    ph = payload_hash or _hl.sha256(
        f"{source}:{source_record_id}".encode()).hexdigest()
    ev = (await db.execute(text("""
        insert into evidence_records (source, source_record_id, observed_at,
                                      confidence, payload_hash)
        values (:s, :sr, :oa, cast(:c as numeric), :ph)
        on conflict (source, source_record_id) do update
          set observed_at = coalesce(excluded.observed_at,
                                     evidence_records.observed_at)
        returning id::text as id
    """), {"s": source, "sr": source_record_id, "oa": observed_at,
           "c": confidence, "ph": ph})).mappings().first()
    await db.execute(text("""
        insert into evidence_links (evidence_id, subject_type, subject_id)
        values (cast(:e as uuid), 'disruption_prediction', cast(:p as text))
        on conflict do nothing
    """), {"e": ev["id"], "p": str(prediction_id)})
    return ev["id"]


async def record_drift(db: AsyncSession, model_id: str | None,
                       feature_name: str, value: float,
                       threshold: float | None = None) -> bool:
    breached = threshold is not None and value >= threshold
    await db.execute(text("""
        insert into ml_drift_metrics (model_id, feature_name, value,
                                      threshold, breached)
        values (cast(:m as uuid), :f, cast(:v as numeric),
                cast(:t as numeric), :b)
    """), {"m": model_id, "f": feature_name, "v": value,
           "t": threshold, "b": breached})
    return breached
