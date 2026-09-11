# -*- coding: utf-8 -*-
"""Command Center aggregation (Phase 18 · FR-C16.1).

Design rules:
  * ACTIONABLE ONLY: six frozen KPI tiles — no vanity charts (source mandate).
    Each KPI answers "do I need to act right now, and where?"
  * ONE round trip for all six counts, executed on the CALLER'S RLS-scoped
    connection so a district officer sees their district's numbers while the
    regional authority sees the whole region (FR-C16.1 drill-down scoping).
  * Map layers are GeoJSON FeatureCollections built with ST_AsGeoJSON — the
    DB stays the only place geometry is serialized.
"""
from typing import Any

from sqlalchemy import text
from sqlalchemy.ext.asyncio import AsyncSession

# ------------------------------------------------------- frozen KPI contracts

# Alerts that still demand attention at the highest severity.
OPEN_ALERT_STATUSES = ("ACTIVE", "ESCALATED")

# Shipment statuses that mean "in motion / about to move".
ACTIVE_SHIPMENT_STATUSES = ("ROUTE_ASSIGNED", "IN_TRANSIT")

# Prediction labels that constitute an actionable road risk.
HIGH_RISK_LABELS = ("HIGH", "CRITICAL")

# District-level labels worth surfacing as predicted disruptions.
PREDICTED_LABELS = ("ELEVATED", "HIGH", "CRITICAL")

# Matches the C06 critical watchlist threshold (supply/service.py).
SUPPLY_RISK_PROBABILITY = 55.0

# Freshness window for supply-risk district counting (predictions are
# append-only; counting history would overstate current risk).
SUPPLY_RISK_WINDOW_HOURS = 24


def kpi_definitions() -> dict[str, str]:
    """Frozen tile list — the dashboard renders EXACTLY these, in order."""
    return {
        "critical_alerts": "Open CRITICAL alerts awaiting action",
        "high_risk_roads": "Road segments with latest risk HIGH/CRITICAL",
        "active_shipments": "Shipments routed or in transit",
        "critical_shipments": "Active shipments carrying critical commodities",
        "supply_risk_districts": "Districts with recent shortage probability "
                                 f">= {SUPPLY_RISK_PROBABILITY:.0f}",
        "predicted_disruptions": "Districts currently flagged by the "
                                 "prediction engine",
    }


# ------------------------------------------------------------- KPI aggregation

_SUMMARY_SQL = text("""
select
  -- 1) critical alerts still open
  (select count(*) from alerts a
    where a.level::text = 'CRITICAL'
      and a.status::text in (:st1, :st2)) as critical_alerts,

  -- 2) road segments whose LATEST prediction is HIGH/CRITICAL
  (select count(*) from (
     select distinct on (dp.segment_id) dp.overall_label
     from disruption_predictions dp
     where dp.target_type = 'ROAD_SEGMENT' and dp.segment_id is not null
     order by dp.segment_id, dp.computed_at desc
   ) latest
   where latest.overall_label in (:lbl1, :lbl2)) as high_risk_roads,

  -- 3) active shipments
  (select count(*) from shipments s
    where s.status::text in (:shp1, :shp2)) as active_shipments,

  -- 4) active critical-commodity shipments
  (select count(*) from shipments s
    where s.status::text in (:shp1, :shp2) and s.is_critical) as critical_shipments,

  -- 5) districts with recent high shortage probability (watchlist threshold)
  (select count(distinct sp.district_code) from shortage_predictions sp
    where sp.shortage_probability >= :prob
      and sp.district_code is not null
      and sp.computed_at > now() - make_interval(hours => :wh)) as supply_risk_districts,

  -- 6) districts currently flagged by the prediction engine
  (select count(*) from (
     select distinct on (dp.district_code) dp.overall_label
     from disruption_predictions dp
     where dp.target_type = 'DISTRICT' and dp.district_code is not null
     order by dp.district_code, dp.computed_at desc
   ) latest
   where latest.overall_label in (:plbl1, :plbl2, :plbl3)) as predicted_disruptions
""")


async def summary(db: AsyncSession) -> dict[str, Any]:
    """The six Command Center tiles. RLS scopes every subquery to the caller."""
    row = (await db.execute(
        _SUMMARY_SQL,
        {"st1": OPEN_ALERT_STATUSES[0], "st2": OPEN_ALERT_STATUSES[1],
         "lbl1": HIGH_RISK_LABELS[0], "lbl2": HIGH_RISK_LABELS[1],
         "shp1": ACTIVE_SHIPMENT_STATUSES[0], "shp2": ACTIVE_SHIPMENT_STATUSES[1],
         "prob": SUPPLY_RISK_PROBABILITY, "wh": SUPPLY_RISK_WINDOW_HOURS,
         "plbl1": PREDICTED_LABELS[0], "plbl2": PREDICTED_LABELS[1],
         "plbl3": PREDICTED_LABELS[2]},
    )).mappings().one()
    counts = {k: int(row[k]) for k in kpi_definitions()}
    return {
        "title": "NER-SHIELD COMMAND CENTER",
        "kpis": [{"id": k, "count": counts[k], "description": d}
                 for k, d in kpi_definitions().items()],
        "counts": counts,
        "generated_at": None,   # router stamps server time
    }


# ----------------------------------------------------------------- map layers

def _fc(features: list[dict]) -> dict:
    return {"type": "FeatureCollection", "features": features}


async def high_risk_roads_fc(db: AsyncSession) -> dict:
    """Segments whose LATEST prediction is HIGH/CRITICAL — red lines on the map."""
    rows = (await db.execute(text("""
        select distinct on (dp.segment_id)
               dp.overall_label, dp.risk_current, dp.risk_24h,
               st_asgeojson(rs.geom)::json as geom,
               r.code as road_code, r.name as road_name,
               rs.district_code, rs.status::text as segment_status
        from disruption_predictions dp
        join road_segments rs on rs.id = dp.segment_id
        join roads r on r.id = rs.road_id
        where dp.target_type = 'ROAD_SEGMENT' and dp.segment_id is not null
        order by dp.segment_id, dp.computed_at desc
    """))).mappings().all()
    return _fc([
        {"type": "Feature",
         "geometry": r["geom"],
         "properties": {
             "kind": "high_risk_road", "road_code": r["road_code"],
             "road_name": r["road_name"], "district_code": r["district_code"],
             "segment_status": r["segment_status"],
             "overall_label": r["overall_label"],
             "risk_current": float(r["risk_current"]),
             "risk_24h": float(r["risk_24h"]),
         }}
        for r in rows if r["overall_label"] in HIGH_RISK_LABELS
    ])


async def disruptions_fc(db: AsyncSession) -> dict:
    """District-level predicted disruptions at district centroids."""
    rows = (await db.execute(text("""
        select distinct on (dp.district_code)
               dp.overall_label, dp.risk_current, dp.risk_24h, dp.top_factors,
               st_asgeojson(d.centroid)::json as geom,
               d.code as district_code, d.name as district_name
        from disruption_predictions dp
        join districts d on d.code = dp.district_code
        where dp.target_type = 'DISTRICT' and dp.district_code is not null
        order by dp.district_code, dp.computed_at desc
    """))).mappings().all()
    features = []
    for r in rows:
        if r["overall_label"] not in PREDICTED_LABELS:
            continue
        factors = r["top_factors"] if isinstance(r["top_factors"], dict) else []
        top = ""
        if isinstance(factors, list) and factors:
            top = str(factors[0].get("label") or factors[0].get("feature") or "")
        features.append({
            "type": "Feature", "geometry": r["geom"],
            "properties": {
                "kind": "disruption", "district_code": r["district_code"],
                "district_name": r["district_name"],
                "overall_label": r["overall_label"],
                "risk_current": float(r["risk_current"]),
                "risk_24h": float(r["risk_24h"]), "top_factor": top,
            }})
    return _fc(features)


async def active_shipments_fc(db: AsyncSession) -> dict:
    """Live convoy picture: active shipment routes as LineStrings."""
    rows = (await db.execute(text("""
        select s.code, s.title, s.commodity::text as commodity,
               s.priority::text as priority, s.status::text as status,
               s.is_critical, s.eta_minutes,
               st_asgeojson(s.route_geom)::json as geom
        from shipments s
        where s.status::text in (:shp1, :shp2)
          and s.route_geom is not null
    """), {"shp1": ACTIVE_SHIPMENT_STATUSES[0],
           "shp2": ACTIVE_SHIPMENT_STATUSES[1]})).mappings().all()
    return _fc([
        {"type": "Feature", "geometry": r["geom"],
         "properties": {
             "kind": "shipment", "code": r["code"], "title": r["title"],
             "commodity": r["commodity"], "priority": r["priority"],
             "status": r["status"], "is_critical": r["is_critical"],
             "eta_minutes": r["eta_minutes"],
         }}
        for r in rows
    ])


async def weather_fc(db: AsyncSession) -> dict:
    """Latest rainfall observation per district — the monsoon overlay."""
    rows = (await db.execute(text("""
        select distinct on (wf.district_code)
               wf.rainfall_mm_24h, wf.forecast_rainfall_mm_24h,
               wf.observed_at, wf.source,
               st_asgeojson(d.centroid)::json as geom,
               d.code as district_code, d.name as district_name
        from weather_feed wf
        join districts d on d.code = wf.district_code
        where wf.district_code is not null
        order by wf.district_code, wf.observed_at desc
    """))).mappings().all()
    return _fc([
        {"type": "Feature", "geometry": r["geom"],
         "properties": {
             "kind": "weather", "district_code": r["district_code"],
             "district_name": r["district_name"],
             "rainfall_mm_24h": float(r["rainfall_mm_24h"]),
             "forecast_rainfall_mm_24h": float(r["forecast_rainfall_mm_24h"]),
             "observed_at": r["observed_at"].isoformat(),
             "source": r["source"],
         }}
        for r in rows
    ])


LAYER_BUILDERS = {
    "high-risk-roads": high_risk_roads_fc,
    "disruptions": disruptions_fc,
    "shipments": active_shipments_fc,
    "weather": weather_fc,
}


