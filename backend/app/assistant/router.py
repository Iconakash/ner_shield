# -*- coding: utf-8 -*-
"""Decision Intelligence Assistant API (Phase 25 · C23 · FR-C23.2).

  GET  /assistant/questions   the frozen catalog of answerable questions
  POST /assistant/ask         {question} -> data-grounded answer

NOT a chatbot: questions are parsed into frozen intents (assistant.engine);
each intent runs ONE deterministic query set on the CALLER'S RLS-scoped
connection; answers cite their source tables. Unrecognized questions get the
catalog back — never a fabricated answer. Every call is audited ANALYZE.
"""
from fastapi import APIRouter, Depends, Request
from pydantic import BaseModel, Field
from sqlalchemy import text
from sqlalchemy.ext.asyncio import AsyncSession

from app.assistant import engine
from app.audit import service as audit
from app.core.db import get_db
from app.dependencies import get_principal, require_permissions
from app.supply.service import shortage_probability

router = APIRouter(prefix="/assistant", tags=["assistant"])

_OPEN_ALERT_STATUSES = ("ACTIVE", "ESCALATED")

# --- SHORTAGE_FORECAST --------------------------------------------------------
_SHORTAGE_SQL = text("""
    select i.district_code,
           min(case when i.daily_consumption > 0 then
                    least(999.0, greatest(0.0,
                        (i.available_quantity - i.reserved_quantity)
                        / i.daily_consumption))
                else 999.0 end) as days_of_supply,
           coalesce(sum(i.daily_consumption), 0)::float as daily_consumption,
           coalesce(sum(i.incoming_quantity), 0)::float as incoming_quantity,
           coalesce(bool_or(rk.high_risk), false) as route_disrupted
    from inventory i
    left join lateral (
        select bool_or(p.overall_label in ('HIGH', 'CRITICAL')) as high_risk
        from road_segments rs
        left join lateral (
            select d.overall_label from disruption_predictions d
            where d.target_type = 'ROAD_SEGMENT' and d.segment_id = rs.id
            order by d.computed_at desc limit 1
        ) p on true
        where rs.district_code = i.district_code
          and rs.status::text <> 'CLOSED'
    ) rk on true
    where i.commodity::text = :commodity
    group by i.district_code
""")

_SOURCE_WAREHOUSES_SQL = text("""
    select f.code, f.name, f.district_code,
           coalesce(sum(i.available_quantity - i.reserved_quantity), 0)
               as stock
    from facilities f
    join inventory i on i.facility_id = f.id
         and i.commodity::text = :commodity
    where f.facility_type = 'WAREHOUSE'
    group by f.code, f.name, f.district_code
    order by stock desc
    limit 5
""")

# --- SINGLE_POINT_VULNERABILITY -----------------------------------------------
_CORRIDORS_SQL = text("""
    select rs.district_code, r.code as road_code,
           count(*) filter (where rs.status::text = 'OPEN')::int
               as open_segments
    from road_segments rs
    join roads r on r.id = rs.road_id
    where rs.district_code is not null
    group by rs.district_code, r.code
    having count(*) filter (where rs.status::text = 'OPEN') > 0
""")

# --- PENDING_ALERTS -----------------------------------------------------------
_ALERTS_SQL = text("""
    select a.level::text as level, count(*)::int as n
    from alerts a
    where a.status::text in (:st1, :st2)
    group by a.level::text
""")

# --- EXPOSED_SHIPMENTS --------------------------------------------------------
_EXPOSED_SQL = text("""
    select s.code, s.commodity::text as commodity, s.is_critical,
           coalesce(s.eta_minutes, 120) as eta_minutes,
           max(case p.overall_label when 'CRITICAL' then 5
                    when 'HIGH' then 4 else 0 end) as severity,
           array_agg(distinct r.code)
               filter (where p.overall_label in ('HIGH', 'CRITICAL'))
               as exposed_roads
    from shipments s
    join road_segments rs on st_intersects(s.route_geom, rs.geom)
    join roads r on r.id = rs.road_id
    left join lateral (
        select d.overall_label from disruption_predictions d
        where d.target_type = 'ROAD_SEGMENT' and d.segment_id = rs.id
        order by d.computed_at desc limit 1
    ) p on true
    where s.status::text in ('ROUTE_ASSIGNED', 'IN_TRANSIT')
      and s.route_geom is not null
    group by s.id, s.code, s.commodity, s.is_critical, s.eta_minutes
    having bool_or(p.overall_label in ('HIGH', 'CRITICAL'))
    limit 25
""")


class AskIn(BaseModel):
    question: str = Field(min_length=3, max_length=280)


async def _run_intent(intent: str, params: dict,
                      db: AsyncSession) -> dict:
    if intent == engine.INTENT_SHORTAGE:
        commodity, hours = params["commodity"], params["hours"]
        rows = (await db.execute(_SHORTAGE_SQL,
                                 {"commodity": commodity})).mappings().all()
        scored = [{
            "district_code": r["district_code"],
            "days_of_supply": float(r["days_of_supply"]),
            "incoming_quantity": float(r["incoming_quantity"]),
            "route_disrupted": bool(r["route_disrupted"]),
            "shortage_probability": shortage_probability(
                float(r["days_of_supply"]), commodity,
                float(r["incoming_quantity"]),
                float(r["daily_consumption"]),
                exposure_hours=hours,
                disruption_context=bool(r["route_disrupted"])),
        } for r in rows]
        whs = (await db.execute(_SOURCE_WAREHOUSES_SQL,
                                {"commodity": commodity})).mappings().all()
        return engine.compose_shortage(scored, [dict(w) for w in whs],
                                       commodity, hours)

    if intent == engine.INTENT_SINGLE_POINT:
        rows = (await db.execute(_CORRIDORS_SQL)).mappings().all()
        by_district: dict[str, list[str]] = {}
        for r in rows:
            by_district.setdefault(r["district_code"], []).append(
                r["road_code"])
        lonely = sorted(
            ({"district_code": d, "lifeline_corridor": roads[0]}
             for d, roads in by_district.items() if len(roads) == 1),
            key=lambda x: x["district_code"])
        return engine.compose_single_point(lonely)

    if intent == engine.INTENT_ALERTS:
        rows = (await db.execute(_ALERTS_SQL, {
            "st1": _OPEN_ALERT_STATUSES[0],
            "st2": _OPEN_ALERT_STATUSES[1]})).mappings().all()
        counts = {r["level"]: int(r["n"]) for r in rows}
        return engine.compose_alerts(counts, sum(counts.values()))

    if intent == engine.INTENT_EXPOSED:
        rows = (await db.execute(_EXPOSED_SQL)).mappings().all()
        label_of = {5: "CRITICAL", 4: "HIGH"}
        return engine.compose_exposed([{
            "code": r["code"], "commodity": r["commodity"],
            "is_critical": r["is_critical"],
            "eta_minutes": float(r["eta_minutes"]),
            "worst_label": label_of.get(int(r["severity"])),
            "exposed_roads": list(r["exposed_roads"] or []),
        } for r in rows])

    return engine.unsupported(intent)


@router.get("/questions",
            dependencies=[Depends(require_permissions("VIEW_MAP"))])
async def supported_questions():
    """The frozen catalog — what this assistant can and will answer."""
    return {"explicitly_not_a_chatbot": True,
            "supported_questions": engine.intents()}


@router.post("/ask",
             dependencies=[Depends(require_permissions("VIEW_MAP"))])
async def ask(body: AskIn, request: Request,
              principal=Depends(get_principal),
              db: AsyncSession = Depends(get_db)):
    intent, params = engine.parse(body.question)
    if intent is None:
        answer = engine.unsupported(body.question)
    else:
        answer = await _run_intent(intent, params, db)

    await audit.emit(db, actor_id=principal.user_id,
                     actor_role=principal.role, action="ANALYZE",
                     outcome="SUCCESS", resource_type="assistant",
                     detail={"intent": intent,
                             "question_length": len(body.question)},
                     ip=request.client.host if request.client else None)
    return answer


