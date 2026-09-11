"""Historical validation API (SIH26002 P4).

  GET  /historical/events                 list events (data_quality visible)
  GET  /historical/events/{id}            event + observations
  POST /historical/validation/run/{id}    replay + metrics (MANAGE_SYSTEM)
  GET  /historical/validation/{id}        latest run for an event

Every response carries data_quality + dataset_version. SAMPLE/SIMULATED
datasets are always labeled as such; a missing dataset returns NO_DATASET
rather than invented accuracy.
"""
from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession

from app.audit import service as audit
from app.core.db import get_db, get_system_db
from app.core.security import Principal
from app.dependencies import require_permissions
from app.historical import service as svc

router = APIRouter(prefix="/historical", tags=["historical-validation"])


@router.get("/events",
            dependencies=[Depends(require_permissions("VIEW_MAP"))])
async def events(db: AsyncSession = Depends(get_db)):
    return {"events": await svc.list_events(db)}


@router.get("/events/{event_id}",
            dependencies=[Depends(require_permissions("VIEW_MAP"))])
async def event_detail(event_id: str, db: AsyncSession = Depends(get_db)):
    from app.core.errors import NotFound
    ev = await svc.get_event(db, event_id)
    if ev is None:
        raise NotFound("historical event not found")
    ev["latest_run"] = await svc.latest_run(db, event_id)
    return ev


@router.post("/validation/run/{event_id}")
async def run(event_id: str,
              principal: Principal = Depends(
                  require_permissions("MANAGE_SYSTEM")),
              system_db: AsyncSession = Depends(get_system_db)):
    res = await svc.run_validation(system_db, event_id=event_id,
                                   ran_by=str(principal.user_id))
    await system_db.commit()
    if res.get("run_id"):
        await audit.emit(system_db, actor_id=principal.user_id,
                         actor_role=principal.role,
                         action="HISTORICAL_VALIDATION_RUN",
                         outcome="SUCCESS",
                         resource_type="historical_validation_run",
                         resource_id=res["run_id"],
                         detail={"event": res["event"],
                                 "model": res["model"],
                                 "dataset_version": res["dataset_version"],
                                 "data_quality": res["data_quality"]})
        await system_db.commit()
    return res


@router.get("/validation/{event_id}",
            dependencies=[Depends(require_permissions("VIEW_MAP"))])
async def latest(event_id: str, db: AsyncSession = Depends(get_db)):
    from app.core.errors import NotFound
    run = await svc.latest_run(db, event_id)
    if run is None:
        raise NotFound("no validation run recorded for that event")
    return run
