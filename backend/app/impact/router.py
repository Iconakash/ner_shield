"""Impact Engine API (Phase 8 · C05).

  POST /impact/assess   assess a segment's failure impact (VIEW_SUPPLY_RISK)
  GET  /impact/latest   recent assessments                  (VIEW_SUPPLY_RISK)
"""

from fastapi import APIRouter, Depends, Query, Request
from pydantic import BaseModel
from sqlalchemy import text
from sqlalchemy.ext.asyncio import AsyncSession

from app.audit import service as audit
from app.core.db import get_db, get_system_db
from app.core.errors import NotFound
from app.dependencies import require_permissions
from app.impact import service as impact_svc

router = APIRouter(prefix="/impact", tags=["impact"])


class AssessIn(BaseModel):
    segment_id: str


def _ip(request: Request):
    return request.client.host if request.client else None


@router.post("/assess")
async def assess(body: AssessIn, request: Request,
                 principal=Depends(require_permissions("VIEW_SUPPLY_RISK")),
                 db: AsyncSession = Depends(get_db),
                 system_db: AsyncSession = Depends(get_system_db)):
    """Assess the blast radius of a failing segment using its latest prediction.

    Read-like derivation from existing intelligence (any officer with supply-risk
    visibility may trigger it); the assessment itself is written through the
    audited system connection.
    """
    pred = (await db.execute(text("""
        select risk_24h, overall_label from disruption_predictions
        where segment_id = cast(:s as uuid)
        order by computed_at desc limit 1
    """), {"s": body.segment_id})).mappings().first()
    if pred is None:
        raise NotFound("no prediction for this segment — run the risk engine first")

    result = await impact_svc.assess_segment(
        db=system_db, segment_id=body.segment_id,
        risk_pct=float(pred["risk_24h"]),
        risk_label=pred["overall_label"])

    await audit.emit(system_db, actor_id=principal.user_id,
                     actor_role=principal.role, action="IMPACT_ASSESSED",
                     outcome="SUCCESS", resource_type="impact_assessment",
                     resource_id=str(result.get("segment_id")),
                     detail={"impact_label": result["impact_label"],
                             "score": result["impact_score"]}, ip=_ip(request))
    return result


@router.get("/latest", dependencies=[Depends(require_permissions("VIEW_SUPPLY_RISK"))])
async def latest(db: AsyncSession = Depends(get_db),
                 limit: int = Query(default=50, ge=1, le=200)):
    rows = (await db.execute(text("""
        select id::text as id, segment_id::text as segment_id, road_code,
               horizon, risk_pct, risk_label, impact_score, impact_label,
               summary_sentence, computed_at
        from impact_assessments order by computed_at desc limit :l
    """), {"l": max(1, min(limit, 200))})).mappings().all()
    return [dict(r) for r in rows]
