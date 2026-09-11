"""GIS read API — GeoJSON FeatureCollections for Leaflet/OpenStreetMap.

Security chain on every route (C-Authz): authentication → account status →
permission (VIEW_MAP) — geographic scope does not restrict reference geography,
which every authenticated role may read per baseline §4.4.
"""
from typing import Literal, Optional

from fastapi import APIRouter, Depends, Query
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.db import get_db
from app.core.errors import AppError
from app.dependencies import require_permissions
from app.gis import repo

router = APIRouter(prefix="/gis", tags=["gis"])

FacilityType = Literal["WAREHOUSE", "HOSPITAL", "LOGISTICS_HUB", "AIRPORT"]


@router.get("/states", dependencies=[Depends(require_permissions("VIEW_MAP"))])
async def get_states(db: AsyncSession = Depends(get_db)):
    return await repo.states_fc(db)


@router.get("/districts", dependencies=[Depends(require_permissions("VIEW_MAP"))])
async def get_districts(db: AsyncSession = Depends(get_db),
                        state_code: Optional[str] = Query(default=None)):
    return await repo.districts_fc(db, state_code)


@router.get("/locate", dependencies=[Depends(require_permissions("VIEW_MAP"))])
async def locate(lon: float = Query(ge=-180, le=180),
                 lat: float = Query(ge=-90, le=90),
                 db: AsyncSession = Depends(get_db)):
    """ST_Contains: resolve a point to its district/state."""
    result = await repo.locate_point(db, lon, lat)
    if result is None:
        raise AppError("point is outside the modeled NER subset",
                       detail={"lon": lon, "lat": lat})
    result["operation"] = "ST_Contains"
    return result


@router.get("/roads", dependencies=[Depends(require_permissions("VIEW_MAP"))])
async def get_roads(db: AsyncSession = Depends(get_db),
                    state_code: Optional[str] = None,
                    district_code: Optional[str] = None):
    """ST_Intersects: roads intersecting the given district polygon."""
    fc = await repo.roads_fc(db, state_code, district_code)
    if district_code:
        for f in fc["features"]:
            f["properties"]["queried_operation"] = "ST_Intersects"
    return fc


@router.get("/segments", dependencies=[Depends(require_permissions("VIEW_MAP"))])
async def get_segments(db: AsyncSession = Depends(get_db),
                       district_code: Optional[str] = None,
                       status: Optional[Literal["OPEN", "PARTIAL", "CLOSED"]] = None):
    return await repo.segments_fc(db, district_code, status)


@router.get("/facilities", dependencies=[Depends(require_permissions("VIEW_MAP"))])
async def get_facilities(
    db: AsyncSession = Depends(get_db),
    facility_type: Optional[FacilityType] = None,
    state_code: Optional[str] = None,
    near_lon: Optional[float] = Query(default=None, ge=-180, le=180),
    near_lat: Optional[float] = Query(default=None, ge=-90, le=90),
    radius_m: int = Query(default=50000, ge=100, le=500000),
):
    """ST_DWithin + ST_Distance: facilities within radius of a point, nearest first.
    Requires both coordinates when any proximity filter is requested."""
    if (near_lon is None) != (near_lat is None):
        raise AppError("near_lon and near_lat must be provided together")
    fc = await repo.facilities_fc(db, facility_type, state_code,
                                  near_lon, near_lat, float(radius_m))
    if near_lon is not None:
        fc["query"] = {"operation": "ST_DWithin + ST_Distance",
                       "radius_m": radius_m,
                       "center": {"lon": near_lon, "lat": near_lat}}
    return fc


@router.get("/railways", dependencies=[Depends(require_permissions("VIEW_MAP"))])
async def get_railways(db: AsyncSession = Depends(get_db)):
    return await repo.linear_features_fc(db, "railways")


@router.get("/waterways", dependencies=[Depends(require_permissions("VIEW_MAP"))])
async def get_waterways(db: AsyncSession = Depends(get_db)):
    return await repo.linear_features_fc(db, "waterways")


@router.get("/summary", dependencies=[Depends(require_permissions("VIEW_MAP"))])
async def get_summary(db: AsyncSession = Depends(get_db)):
    return await repo.gis_summary(db)

