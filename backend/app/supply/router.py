"""Supply Intelligence API (Phase 9 · C06/C07).

  POST /supply/inventory      upsert stock rows            (MODIFY_SHIPMENT)
  GET  /supply/inventory      scoped stock view            (VIEW_SUPPLY_RISK)
  POST /supply/shortage-scan  run shortage detection       (VIEW_SUPPLY_RISK)
  GET  /supply/watchlist      critical watchlist           (VIEW_SUPPLY_RISK)
"""
from typing import Literal, Optional

from fastapi import APIRouter, Depends, Query, Request
from pydantic import BaseModel, Field
from sqlalchemy import text
from sqlalchemy.ext.asyncio import AsyncSession

from app.audit import service as audit
from app.core.db import get_db, get_system_db
from app.core.errors import NotFound
from app.dependencies import ensure_geo_scope, require_permissions
from app.supply import service as supply_svc

router = APIRouter(prefix="/supply", tags=["supply"])


class InventoryUpsert(BaseModel):
    facility_code: str
    commodity: Literal["MEDICINE", "EMERGENCY_SUPPLIES", "WATER",
                       "EMERGENCY_FOOD", "FOOD_GRAIN", "FUEL", "GENERAL"]
    available_quantity: float = Field(ge=0)
    daily_consumption: float = Field(ge=0)
    incoming_quantity: float = Field(default=0, ge=0)
    reserved_quantity: float = Field(default=0, ge=0)


class ShortageScan(BaseModel):
    district_code: Optional[str] = None
    expected_disruption_hours: int = Field(default=18, ge=1, le=168)
    disruption_context: bool = False


COMMODITIES = ("MEDICINE", "EMERGENCY_SUPPLIES", "WATER", "EMERGENCY_FOOD",
               "FOOD_GRAIN", "FUEL", "GENERAL")


def _ip(request: Request):
    return request.client.host if request.client else None

@router.post("/inventory")
async def upsert_inventory(body: InventoryUpsert, request: Request,
                           principal=Depends(require_permissions("MODIFY_SHIPMENT")),
                           db: AsyncSession = Depends(get_db),
                           system_db: AsyncSession = Depends(get_system_db)):
    """Stock upsert — logistics officers within their geographic scope only."""
    fac = (await db.execute(text("""
        select f.id::text as id, f.district_code, f.state_code
        from facilities f where f.code = :c and f.facility_type = 'WAREHOUSE'
    """), {"c": body.facility_code})).mappings().first()
    if fac is None:
        raise NotFound("warehouse not found")
    await ensure_geo_scope(principal, fac["state_code"],
                           fac["district_code"], db, request)

    await system_db.execute(text("""
        insert into inventory (facility_id, district_code, state_code, commodity,
            available_quantity, daily_consumption, incoming_quantity,
            reserved_quantity, org_id, updated_by)
        values (cast(:f as uuid), :d, :s, cast(:c as commodity_type),
                :a, :dc, :inc, :re,
                (select id from organizations order by created_at limit 1),
                cast(:u as uuid))
        on conflict (facility_id, commodity) do update set
            available_quantity = excluded.available_quantity,
            daily_consumption = excluded.daily_consumption,
            incoming_quantity = excluded.incoming_quantity,
            reserved_quantity = excluded.reserved_quantity,
            updated_by = excluded.updated_by, updated_at = now()
    """), {"f": fac["id"], "d": fac["district_code"], "s": fac["state_code"],
           "c": body.commodity, "a": body.available_quantity,
           "dc": body.daily_consumption, "inc": body.incoming_quantity,
           "re": body.reserved_quantity, "u": principal.user_id})
    dos = supply_svc.days_of_supply(body.available_quantity,
                                    body.reserved_quantity,
                                    body.daily_consumption)
    await audit.emit(system_db, actor_id=principal.user_id,
                     actor_role=principal.role, action="SECURITY_EVENT",
                     outcome="SUCCESS", resource_type="inventory",
                     resource_id=f"{body.facility_code}:{body.commodity}",
                     detail=body.model_dump(), ip=_ip(request))
    return {"facility": body.facility_code, "commodity": body.commodity,
            "days_of_supply": dos}

@router.get("/inventory", dependencies=[Depends(require_permissions("VIEW_SUPPLY_RISK"))])
async def list_inventory(db: AsyncSession = Depends(get_db),
                         district_code: Optional[str] = None):
    """RLS scope-filters automatically; days-of-supply computed per row."""
    rows = (await db.execute(text("""
        select f.code as facility_code, f.name as facility_name,
               i.district_code, i.state_code,
               i.commodity::text as commodity, i.available_quantity,
               i.daily_consumption, i.incoming_quantity, i.reserved_quantity
        from inventory i join facilities f on f.id = i.facility_id
        where (:d is null or i.district_code = :d)
        order by i.state_code, i.commodity limit 300
    """), {"d": district_code})).mappings().all()
    out = []
    for r in rows:
        item = dict(r)
        item["days_of_supply"] = supply_svc.days_of_supply(
            float(item["available_quantity"]), float(item["reserved_quantity"]),
            float(item["daily_consumption"]))
        out.append(item)
    return out


@router.post("/shortage-scan")
async def shortage_scan(body: ShortageScan, request: Request,
                        principal=Depends(require_permissions("VIEW_SUPPLY_RISK")),
                        db: AsyncSession = Depends(get_db),
                        system_db: AsyncSession = Depends(get_system_db)):
    """Predictive shortage detection over RLS-scoped inventory; persists rows."""
    result = await supply_svc.run_shortage_scan(
        db, exposure_hours=body.expected_disruption_hours,
        district_code=body.district_code,
        disruption_context=body.disruption_context)
    await audit.emit(system_db, actor_id=principal.user_id,
                     actor_role=principal.role, action="ANALYZE",
                     outcome="SUCCESS", resource_type="shortage_scan",
                     detail={"scanned": result["scanned"],
                             "district": body.district_code}, ip=_ip(request))
    return {"scanned": result["scanned"],
            "exposure_hours": result["exposure_hours"],
            "watchlist": result["watchlist"]}


@router.get("/watchlist", dependencies=[Depends(require_permissions("VIEW_SUPPLY_RISK"))])
async def watchlist(db: AsyncSession = Depends(get_db),
                    lang: Optional[str] = None):
    """C06 critical watchlist: worst prediction per (district, critical commodity).

    Phase 17: adds localized recommendation text per FR-C15.1 (?lang= param;
    canonical action codes preserved for machine consumers).
    """
    from app.i18n import service as i18n_svc
    rows = (await db.execute(text("""
        select distinct on (district_code, commodity::text)
               district_code, commodity::text as commodity,
               days_of_supply, demand_label, shortage_probability,
               recommended_action, suggested_quantity, computed_at
        from shortage_predictions
        where commodity::text in
              ('MEDICINE','EMERGENCY_SUPPLIES','WATER','EMERGENCY_FOOD')
          and shortage_probability >= 55
        order by district_code, commodity::text, computed_at desc
    """))).mappings().all()
    out = sorted([dict(r) for r in rows],
                 key=lambda x: -x["shortage_probability"])
    resolved = i18n_svc.normalize_lang(lang)
    return [i18n_svc.localize_supply_prediction(r, resolved) for r in out]


# ============================================ P6 (SIH26002): shortage heatmap
@router.get("/heatmap",
            dependencies=[Depends(require_permissions("VIEW_SUPPLY_RISK"))])
async def heatmap(db: AsyncSession = Depends(get_db),
                  commodity: Optional[str] = Query(default=None)):
    """District supply-shortage risk as a GeoJSON FeatureCollection.

    Reuses the LATEST stored shortage_predictions (the existing engine);
    returns an EMPTY layer until a scan has run — no fabricated risk.
    """
    if commodity is not None and commodity not in COMMODITIES:
        from app.core.errors import NotFound
        raise NotFound(f"unknown commodity '{commodity}'")
    return await supply_svc.shortage_heatmap(db, commodity=commodity)


@router.get("/heatmap/{district_code}",
            dependencies=[Depends(require_permissions("VIEW_SUPPLY_RISK"))])
async def heatmap_detail(district_code: str,
                         db: AsyncSession = Depends(get_db)):
    """Click-through: per-commodity stock/days-of-supply/risk + incoming
    shipments + disrupted segments for one district."""
    return await supply_svc.district_supply_detail(db, district_code)


