"""Impact analytics DB service (SIH26002 P7).

Aggregates ESTIMATED impact from existing operational records (decision
outcomes, validated reports, critical shipments, district population) and
records them in the `impact_metrics` ledger with an explicit basis label.
"""
import json

from sqlalchemy import text
from sqlalchemy.ext.asyncio import AsyncSession

from app.impactmetrics import engine


async def summary(db: AsyncSession) -> dict:
    """Impact KPI block for the Command Center — every value labeled.

    Sources (all pre-existing tables):
      * delay reduction  : decision_outcomes with a successful reroute outcome
      * shipments protected: critical shipments whose segment risk dropped or
        reroute outcome recorded (counted conservatively)
      * population at risk: districts whose latest shortage prediction is HIGH+
    """
    reroutes = (await db.execute(text("""
        select count(*) as n,
               coalesce(sum((actual_impact->>'eta_minutes_saved')::numeric), 0)
                   as minutes_saved
        from decision_outcomes
        where action = 'REROUTE_SHIPMENT'
          and outcome in ('SUCCESSFUL', 'PARTIAL')
    """))).mappings().first()

    protected = (await db.execute(text("""
        select count(*) as n from shipments s
        where s.is_critical and s.status in ('IN_TRANSIT', 'ROUTE_ASSIGNED')
          and exists (
            select 1 from road_segments rs
            where s.route_geom is not null
              and st_intersects(s.route_geom, rs.geom)
              and rs.status::text <> 'OPEN')
    """))).mappings().first()

    at_risk_pop = (await db.execute(text("""
        select coalesce(sum(c.population), 0) as pop
        from communities c
        where exists (
            select 1 from shortage_predictions sp
            where sp.district_code = c.district_code
              and sp.shortage_probability >= 55
              and sp.computed_at > now() - interval '7 days')
    """))).mappings().first()

    hours_saved = round(float(reroutes["minutes_saved"] or 0) / 60.0, 1)
    cost = engine.cost_saving_estimate(
        delay_hours_avoided=hours_saved,
        vehicles_involved=int(reroutes["n"] or 0))

    return {
        "label": "ESTIMATED / SIMULATION — not audited government savings",
        "estimated_delay_reduction_h": hours_saved,
        "reroutes_completed": int(reroutes["n"] or 0),
        "estimated_cost_avoided_inr": cost["estimated_cost_avoided_inr"],
        "cost_model": cost["model"],
        "critical_shipments_on_disrupted_routes":
            int(protected["n"] or 0),
        "population_with_essential_supply_access_risk":
            int(at_risk_pop["pop"] or 0),
        "terminology_note": ("population potentially affected by essential-"
                             "supply access risk; NOT a casualty metric"),
    }


async def record(db: AsyncSession, *, kind: str, value: float,
                 basis: str, state_code: str | None = None,
                 district_code: str | None = None,
                 detail: dict | None = None,
                 model_version: str | None = None) -> dict:
    row = (await db.execute(text("""
        insert into impact_metrics (metric_kind, value, basis, state_code,
                                    district_code, detail, model_version)
        values (:k, :v, :b,
                case when :s is null then null else cast(:s as text) end,
                case when :d is null then null else cast(:d as text) end,
                cast(:det as jsonb), :mv)
        returning id::text as id, recorded_at
    """), {"k": kind, "v": value, "b": basis, "s": state_code,
           "d": district_code, "det": json.dumps(detail or {}),
           "mv": model_version})).mappings().first()
    return {"id": row["id"], "recorded_at": str(row["recorded_at"])}


async def recent(db: AsyncSession, limit: int = 50) -> list[dict]:
    rows = (await db.execute(text("""
        select id::text as id, metric_kind, value, basis, state_code,
               district_code, recorded_at
        from impact_metrics order by recorded_at desc limit :l
    """), {"l": max(1, min(limit, 200))})).mappings().all()
    return [dict(r) for r in rows]
