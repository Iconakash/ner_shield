"""Supply Intelligence (Phase 9 · C06/C07).

Pure analytics (unit-testable) + DB scan that turns inventory rows into
immutable shortage predictions with pre-positioning recommendations.

  days_of_supply      = (available - reserved) / daily_consumption
  forecast_demand(h)  = daily_consumption * (h/24) * demand_surge
  demand_label        = urgency from days-of-cover: <3.5 HIGH · <7 MEDIUM
                        <14 NORMAL · else LOW
  shortage_probability: piecewise baseline curve on days-of-supply, adjusted by
    critical commodity (+10), incoming coverage (-20), active HIGH disruption
    context (+10); clamped to [5, 99]. Provisional — calibrate with validation
    data exactly like the accessibility/risk engines.
"""
import json
from typing import Optional

from sqlalchemy import text
from sqlalchemy.ext.asyncio import AsyncSession

MODE = "supply-rule-1.0"

DEMAND_SURGE = {"HIGH": 1.5, "MEDIUM": 1.2, "NORMAL": 1.0, "LOW": 0.8}
CRITICAL_COMMODITIES = {"MEDICINE", "EMERGENCY_SUPPLIES", "WATER", "EMERGENCY_FOOD"}


def days_of_supply(available: float, reserved: float,
                   daily_consumption: float) -> Optional[float]:
    """None when consumption is zero (no depletion)."""
    if daily_consumption <= 0:
        return None
    net = max(0.0, available - reserved)
    return round(min(net / daily_consumption, 999.0), 2)


def demand_label(days_of_supply: Optional[float]) -> str:
    if days_of_supply is None:
        return "LOW"
    if days_of_supply < 3.5:
        return "HIGH"
    if days_of_supply < 7:
        return "MEDIUM"
    if days_of_supply < 14:
        return "NORMAL"
    return "LOW"


def forecast_demand(daily_consumption: float, horizon_hours: int,
                    label: str) -> float:
    return round(daily_consumption * (horizon_hours / 24.0)
                 * DEMAND_SURGE.get(label, 1.0), 1)


def _baseline_probability(dos: float) -> float:
    """Piecewise-linear curve anchored at the source document's example zone."""
    anchors = [(0.0, 95.0), (1.0, 95.0), (2.0, 78.0), (3.0, 60.0),
               (5.0, 38.0), (7.0, 22.0), (10.0, 8.0), (999.0, 5.0)]
    for (d0, p0), (d1, p1) in zip(anchors, anchors[1:]):
        if d0 <= dos <= d1:
            if d1 == d0:
                return p0
            share = (dos - d0) / (d1 - d0)
            return p0 + share * (p1 - p0)
    return 5.0


def shortage_probability(days_of_supply: Optional[float],
                         commodity: str, incoming: float,
                         daily_consumption: float,
                         exposure_hours: int,
                         disruption_context: bool) -> float:
    """Shortage probability % with documented modifiers."""
    if days_of_supply is None:
        return 5.0                      # no consumption => no shortage mechanism
    p = _baseline_probability(float(days_of_supply))
    if commodity in CRITICAL_COMMODITIES:
        p += 10.0                       # criticality of the commodity
    need = daily_consumption * (exposure_hours / 24.0)
    if incoming > 0 and need > 0 and incoming >= need * 0.75:
        p -= 20.0                       # inbound stock already covers exposure
    if disruption_context:
        p += 10.0                       # HIGH+ disruption active on serving routes
    return round(max(5.0, min(99.0, p)), 1)


def recommended_action(probability: float, commodity: str,
                       incoming: float) -> tuple[str, float]:
    """Returns (action, suggested_preposition_quantity_units)."""
    critical = commodity in CRITICAL_COMMODITIES
    if probability >= 70 and critical and incoming <= 0:
        return "PRE_POSITION", 100.0
    if probability >= 70:
        return ("PRE_POSITION" if critical else "ACCELERATE_INCOMING"), 100.0
    if probability >= 55:
        if incoming > 0:
            return "ACCELERATE_INCOMING", 50.0
        return "PRE_POSITION", 50.0 if critical else 25.0
    if probability >= 35:
        return "MONITOR_CLOSELY", 0.0
    return "MONITOR", 0.0

# ------------------------------------------------------- DB scan + persistence
CRITICAL_COMMODITY_SQL_LIST = "('MEDICINE','EMERGENCY_SUPPLIES','WATER','EMERGENCY_FOOD')"


async def run_shortage_scan(
    db: AsyncSession, exposure_hours: int = 18,
    district_code: Optional[str] = None,
    disruption_context: bool = False,
) -> dict:
    """Scan inventory (scope-filtered by RLS) and persist shortage predictions."""
    rows = (await db.execute(text("""
        select i.id::text as id, i.district_code, d.name as district_name,
               f.code as facility_code, f.name as facility_name,
               i.commodity::text as commodity,
               i.available_quantity, i.reserved_quantity,
               i.daily_consumption, i.incoming_quantity
        from inventory i
        join facilities f on f.id = i.facility_id
        left join districts d on d.code = i.district_code
        where (:d is null or i.district_code = :d)
        order by i.commodity
    """), {"d": district_code})).mappings().all()

    results = []
    for r in rows:
        dos = days_of_supply(float(r["available_quantity"]),
                             float(r["reserved_quantity"]),
                             float(r["daily_consumption"]))
        label = demand_label(dos)
        fc = forecast_demand(float(r["daily_consumption"]),
                             exposure_hours, label)
        prob = shortage_probability(
            dos, r["commodity"], float(r["incoming_quantity"]),
            float(r["daily_consumption"]), exposure_hours, disruption_context)
        action, qty = recommended_action(prob, r["commodity"],
                                         float(r["incoming_quantity"]))
        drivers = {
            "days_of_supply": dos,
            "expected_disruption_hours": exposure_hours,
            "critical_commodity": r["commodity"].startswith(("MEDICINE",
                "EMERGENCY", "WATER")),
            "incoming_units": float(r["incoming_quantity"]),
            "disruption_context": disruption_context,
        }
        await db.execute(text("""
            insert into shortage_predictions
              (inventory_id, district_code, commodity, days_of_supply,
               expected_disruption_hours, forecast_demand, demand_label,
               shortage_probability, recommended_action, suggested_quantity,
               drivers, mode)
            values (cast(:inv as uuid), :dist, cast(:com as commodity_type),
                    :dos, :exp, :fc, :dl, :prob, :act, :qty,
                    cast(:drv as jsonb), :mode)
        """), {"inv": r["id"], "dist": r["district_code"], "com": r["commodity"],
               "dos": dos if dos is not None else 999.0,
               "exp": exposure_hours, "fc": fc, "dl": label, "prob": prob,
               "act": action, "qty": qty, "drv": json.dumps(drivers),
               "mode": MODE})
        results.append({
            "district": r["district_code"], "facility": r["facility_code"],
            "commodity": r["commodity"], "days_of_supply": dos,
            "demand_label": label, "forecast_demand": fc,
            "shortage_probability": prob, "recommended_action": action,
            "suggested_quantity": qty})

    # critical watchlist: worst per (district, commodity), critical commodities first
    watchlist = sorted(
        [r for r in results
         if r["commodity"] in CRITICAL_COMMODITIES and r["shortage_probability"] >= 55],
        key=lambda x: -x["shortage_probability"])
    return {"scanned": len(results), "exposure_hours": exposure_hours,
            "watchlist": watchlist, "predictions": results}


# ================================================= P6 (SIH26002): GIS heatmap
async def shortage_heatmap(db: AsyncSession, *,
                           commodity: str | None = None) -> dict:
    """District supply-shortage risk as GeoJSON, from the LATEST stored
    shortage_predictions per (district, commodity) — pure reuse of the
    existing engine; no second predictor. Empty until a scan has run."""
    rows = (await db.execute(text("""
        select distinct on (sp.district_code, sp.commodity)
               sp.district_code, d.name as district_name,
               sp.commodity::text as commodity,
               sp.shortage_probability, sp.days_of_supply,
               sp.demand_label::text as demand_label,
               sp.recommended_action, sp.computed_at
        from shortage_predictions sp
        join districts d on d.code = sp.district_code
        where (:c is null or sp.commodity::text = :c)
        order by sp.district_code, sp.commodity, sp.computed_at desc
    """), {"c": commodity})).mappings().all()

    # aggregate to district-level features carrying per-commodity detail
    districts: dict[str, dict] = {}
    for r in rows:
        entry = districts.setdefault(r["district_code"], {
            "district_code": r["district_code"],
            "district_name": r["district_name"],
            "commodities": [], "worst_probability": 0.0})
        entry["commodities"].append({
            "commodity": r["commodity"],
            "risk_pct": float(r["shortage_probability"]),
            "days_of_supply": (float(r["days_of_supply"])
                               if r["days_of_supply"] is not None else None),
            "demand_label": r["demand_label"],
            "recommended_action": r["recommended_action"]})
        entry["worst_probability"] = max(
            entry["worst_probability"], float(r["shortage_probability"]))
    for entry in districts.values():
        entry["risk_level"] = ("CRITICAL" if entry["worst_probability"] >= 75
                               else "HIGH" if entry["worst_probability"] >= 55
                               else "MEDIUM" if entry["worst_probability"] >= 35
                               else "LOW")

    # district geometries (RLS-scoped read), features assembled in Python
    codes = list(districts.keys())
    if not codes:
        return {"type": "FeatureCollection", "features": []}
    geom_rows = (await db.execute(text("""
        select code, st_asgeojson(geom)::json as geo
        from districts where code = any(:codes)
    """), {"codes": codes})).mappings().all()
    features = []
    for g in geom_rows:
        entry = districts[g["code"]]
        features.append({
            "type": "Feature", "geometry": g["geo"],
            "properties": {"district_code": entry["district_code"],
                           "district_name": entry["district_name"],
                           "supply_risk": entry["risk_level"],
                           "worst_probability": entry["worst_probability"],
                           "commodities": entry["commodities"]}})
    return {"type": "FeatureCollection", "features": features}


async def district_supply_detail(db: AsyncSession, district_code: str) -> dict:
    """Click-through intelligence for one district: per-commodity stock/risk,
    incoming shipments and active disruptions (all existing sources)."""
    commodities = (await db.execute(text("""
        select distinct on (i.commodity)
               i.commodity::text as commodity,
               sum(i.available_quantity - i.reserved_quantity)
                   over (partition by i.commodity) as net_available,
               max(i.daily_consumption)
                   over (partition by i.commodity) as daily_consumption
        from inventory i where i.district_code = :d
        order by i.commodity
    """), {"d": district_code})).mappings().all()
    out = []
    for c in commodities:
        dos = days_of_supply(float(c["net_available"] or 0), 0.0,
                             float(c["daily_consumption"] or 0))
        out.append({"commodity": c["commodity"],
                    "days_of_supply": dos,
                    "risk": demand_label(dos)})
    shipments = (await db.execute(text("""
        select count(*) as incoming from shipments s
        where s.status in ('IN_TRANSIT', 'ROUTE_ASSIGNED')
          and exists (select 1 from facilities f
                      where f.district_code = :d
                        and st_dwithin(s.route_geom::geography,
                                       f.geom::geography, 25000))
    """), {"d": district_code})).scalar()
    disruptions = (await db.execute(text("""
        select count(*) as open from road_segments rs
        where rs.status::text <> 'OPEN'
          and rs.district_code = :d
    """), {"d": district_code})).scalar()
    return {"district_code": district_code,
            "commodities": out,
            "incoming_shipments": int(shipments or 0),
            "disrupted_segments": int(disruptions or 0)}


