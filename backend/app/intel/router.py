"""Decision-intelligence API (additive).

  GET   /intel/hazards                     fused hazard assessments + cards
  GET   /intel/decision-card/{segment_id}  one evidence-backed card
  POST  /intel/outcomes                    open a closed-loop outcome record
  PATCH /intel/outcomes/{decision_id}      record approval/execution/outcome
  GET   /intel/outcomes/{decision_id}      inspect the closed loop

Reads are VIEW_MAP; writes are MANAGE_SYSTEM on the system connection and every
transition is audit-emitted. This router never executes actions itself — the
existing two-person approval workflow remains the only action path.
"""
from fastapi import APIRouter, Depends, Query, Request
from pydantic import BaseModel, Field
from sqlalchemy.ext.asyncio import AsyncSession

from app.audit import service as audit
from app.core.db import get_db, get_system_db
from app.core.errors import NotFound
from app.dependencies import require_permissions
from app.intel import service as intel_svc

router = APIRouter(prefix="/intel", tags=["decision-intelligence"])


class OutcomeIn(BaseModel):
    decision_id: str = Field(min_length=4, max_length=64)
    rule: str = Field(min_length=2, max_length=80)
    action: str = Field(min_length=2, max_length=80)
    approval_request_id: str | None = None
    recommended: dict = Field(default_factory=dict)


class OutcomePatch(BaseModel):
    status: str | None = Field(default=None,
                               pattern="^(PENDING|APPROVED|REJECTED|CANCELLED)$")
    outcome: str | None = Field(
        default=None,
        pattern="^(EXECUTED|SUCCESSFUL|PARTIAL|FAILED|CANCELLED)$")
    actual_impact: dict | None = None
    verification_source: str | None = Field(default=None, max_length=200)


@router.get("/hazards",
            dependencies=[Depends(require_permissions("VIEW_MAP"))])
async def hazards(db: AsyncSession = Depends(get_db), limit: int = 25):
    """Situation → Prediction → Impact → Decision → Evidence → Confidence,
    per exposed segment with a recent prediction (§38 output design)."""
    rows = await intel_svc.assess_segments(db, limit=limit)
    return {"assessments": rows[:max(1, min(limit, 100))],
            "contract": {"availability": "OBSERVED|PREDICTED|RECOMMENDED"
                                         "|CONFIRMED stay distinct"}}


@router.get("/decision-card/{segment_id}",
            dependencies=[Depends(require_permissions("VIEW_MAP"))])
async def decision_card(segment_id: str,
                        db: AsyncSession = Depends(get_db)):
    rows = await intel_svc.assess_segments(db, limit=100)
    match = next((r for r in rows if r["segment_id"] == segment_id), None)
    if match is None:
        raise NotFound("no active hazard assessment for that segment")
    return match


@router.post("/outcomes", status_code=201,
             dependencies=[Depends(require_permissions("MANAGE_SYSTEM"))])
async def open_outcome(body: OutcomeIn, request: Request,
                       principal=Depends(require_permissions("MANAGE_SYSTEM")),
                       system_db: AsyncSession = Depends(get_system_db)):
    res = await intel_svc.open_outcome(
        system_db, decision_id=body.decision_id, rule=body.rule,
        action=body.action, approval_request_id=body.approval_request_id,
        recommended=body.recommended, created_by=str(principal.user_id))
    await audit.emit(system_db, actor_id=principal.user_id,
                     actor_role=principal.role,
                     action="DECISION_OUTCOME_OPENED", outcome="SUCCESS",
                     resource_type="decision_outcome",
                     resource_id=res["id"], detail={"decision": body.decision_id})
    return res


@router.patch("/outcomes/{decision_id}",
              dependencies=[Depends(require_permissions("MANAGE_SYSTEM"))])
async def patch_outcome(decision_id: str, body: OutcomePatch,
                        request: Request,
                        principal=Depends(require_permissions("MANAGE_SYSTEM")),
                        system_db: AsyncSession = Depends(get_system_db)):
    res = await intel_svc.set_outcome(
        system_db, decision_id, status=body.status, outcome=body.outcome,
        actual_impact=body.actual_impact,
        verification_source=body.verification_source)
    await audit.emit(system_db, actor_id=principal.user_id,
                     actor_role=principal.role,
                     action="DECISION_OUTCOME_UPDATED", outcome="SUCCESS",
                     resource_type="decision_outcome", resource_id=decision_id,
                     detail={"status": body.status, "outcome": body.outcome})
    return res


@router.get("/outcomes/{decision_id}",
            dependencies=[Depends(require_permissions("VIEW_MAP"))])
async def read_outcome(decision_id: str,
                       db: AsyncSession = Depends(get_db)):
    row = await intel_svc.get_outcome(db, decision_id)
    if row is None:
        raise NotFound("no outcome record for that decision")
    return row


@router.get("/satellite/scenes",
            dependencies=[Depends(require_permissions("VIEW_INCIDENTS"))])
async def satellite_scenes(
    state_code: str | None = Query(default=None, max_length=8),
    district_code: str | None = Query(default=None, max_length=12),
    provider: str | None = Query(default=None, max_length=80),
    limit: int = Query(default=50, ge=1, le=200),
    db: AsyncSession = Depends(get_db),
):
    """Satellite scene METADATA (SIH26002 P7) — metadata only, never imagery.

    Reads RLS-scoped `satellite_scenes` rows. The optional `state_code` /
    `district_code` filters resolve each scene's coverage-bbox centre with
    ST_Contains against the reference districts, so a scene is only claimed
    for a geography we can actually verify (scenes without a coverage bbox
    are excluded whenever a geo filter is requested). `signed_url` is
    intentionally NULL — it appears only once an authorized Copernicus /
    object-storage pipeline populates `storage_path` (I-10). No fake
    imagery and no invented download links are ever served.
    """
    rows = (await db.execute(text("""
        select
          s.id::text as id,
          s.external_id as scene_id,
          s.provider as source,
          s.acquired_at::text as captured_at,
          s.cloud_cover_pct::float as cloud_cover_pct,
          s.resolution_m::float as resolution_m,
          s.status::text as status,
          s.source_url,
          d.code as district_code,
          d.state_code
        from satellite_scenes s
        cross join lateral (
          select case jsonb_typeof(s.coverage)
                   when 'array' then s.coverage
                   else coalesce(s.coverage -> 'coverage_bbox', '[]'::jsonb)
                 end as cov
        ) c
        left join lateral (
          select di.code, di.state_code
          from districts di
          where di.geom is not null
            and jsonb_array_length(c.cov) >= 4
            and st_contains(di.geom, st_setsrid(st_makepoint(
                ((c.cov ->> 0)::float + (c.cov ->> 2)::float) / 2.0,
                ((c.cov ->> 1)::float + (c.cov ->> 3)::float) / 2.0), 4326))
          limit 1
        ) d on true
        where (:provider is null or s.provider = :provider)
          and (:st is null or d.state_code = :st)
          and (:dst is null or d.code = :dst)
        order by s.acquired_at desc
        limit :lim
    """), {"provider": provider, "st": state_code, "dst": district_code,
           "lim": limit})).mappings().all()

    out = []
    for r in rows:
        item = dict(r)
        # Metadata-only pipeline: URLs are issued by the storage layer after
        # an authorized archive lands; `null` is the honest pre-provision state.
        item["signed_url"] = None
        item["signed_url_expires_at"] = None
        item["product_type"] = None
        out.append(item)
    return out