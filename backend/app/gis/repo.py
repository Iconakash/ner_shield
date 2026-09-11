"""GIS data access — every spatial operation lives here (PostGIS).

Spatial-op coverage (Phase 3 mandate):
  ST_Contains    → locate_point()  (+ segment district assignment in seed)
  ST_Intersects  → roads_fc() district filter
  ST_DWithin     → facilities_fc() radius filter (geography => meters)
  ST_Distance    → facilities_fc() nearest-first ordering + distance_m payload
All GeoJSON is produced with ST_AsGeoJSON.
"""
import json
from typing import Optional

from sqlalchemy import text
from sqlalchemy.ext.asyncio import AsyncSession


def _fc(features: list[dict]) -> dict:
    return {"type": "FeatureCollection", "features": features}


async def states_fc(db: AsyncSession) -> dict:
    rows = (await db.execute(text("""
        select s.code, s.name,
               coalesce(st_asgeojson(s.geom),
                        '{"type":"GeometryCollection","geometries":[]}') as geo,
               (select count(*) from districts d
                 where d.state_code = s.code and d.geom is not null) as districts
        from states s where s.geom is not null order by s.code
    """))).mappings().all()
    return _fc([
        {"type": "Feature", "geometry": json.loads(r["geo"]),
         "properties": {"code": r["code"], "name": r["name"],
                        "districts": int(r["districts"])}}
        for r in rows
    ])


async def districts_fc(db: AsyncSession, state_code: Optional[str]) -> dict:
    rows = (await db.execute(text("""
        select d.code, d.name, d.state_code,
               st_asgeojson(d.geom) as geo, st_asgeojson(d.centroid) as centroid
        from districts d
        where d.geom is not null and (:st is null or d.state_code = :st)
        order by d.code
    """), {"st": state_code})).mappings().all()
    return _fc([
        {"type": "Feature", "geometry": json.loads(r["geo"]),
         "properties": {"code": r["code"], "name": r["name"],
                        "state_code": r["state_code"],
                        "centroid": json.loads(r["centroid"])}}
        for r in rows
    ])


async def locate_point(db: AsyncSession, lon: float, lat: float) -> Optional[dict]:
    """ST_Contains: which state/district polygon contains this point?
    Smallest-area match wins when simplified prototype boxes overlap."""
    row = (await db.execute(text("""
        select d.code as district_code, d.name as district_name,
               s.code as state_code, s.name as state_name
        from districts d join states s on s.code = d.state_code
        where d.geom is not null
          and st_contains(d.geom, st_setsrid(st_makepoint(:lon,:lat),4326))
        order by st_area(d.geom) asc limit 1
    """), {"lon": lon, "lat": lat})).mappings().first()
    return dict(row) if row else None

async def roads_fc(db: AsyncSession, state_code: Optional[str],
                   district_code: Optional[str]) -> dict:
    """Roads; when a district is given, only roads INTERSECTING its polygon (ST_Intersects)."""
    rows = (await db.execute(text("""
        select distinct r.code, r.name, r.road_class, st_asgeojson(r.geom) as geo
        from roads r
        where (:dist is null or exists (
                  select 1 from road_segments rs
                  join districts d on d.code = rs.district_code
                  where rs.road_id = r.id and d.code = :dist
                    and st_intersects(d.geom, rs.geom)))
          and (:state is null or exists (
                  select 1 from road_segments rs
                  where rs.road_id = r.id and rs.state_code = :state))
        order by r.code
    """), {"dist": district_code, "state": state_code})).mappings().all()
    return _fc([
        {"type": "Feature", "geometry": json.loads(r["geo"]),
         "properties": {"code": r["code"], "name": r["name"], "road_class": r["road_class"]}}
        for r in rows
    ])


async def segments_fc(db: AsyncSession, district_code: Optional[str],
                      status: Optional[str]) -> dict:
    rows = (await db.execute(text("""
        select rs.id::text as id, r.code as road_code, r.name as road_name,
               rs.seq, rs.district_code, rs.surface, rs.status, rs.length_m,
               st_asgeojson(rs.geom) as geo
        from road_segments rs join roads r on r.id = rs.road_id
        where (:d is null or rs.district_code = :d)
          and (:status is null or rs.status = :status)
        order by r.code, rs.seq
    """), {"d": district_code, "status": status})).mappings().all()
    return _fc([
        {"type": "Feature", "geometry": json.loads(r["geo"]),
         "properties": {k: r[k] for k in ("id", "road_code", "road_name", "seq",
                                          "district_code", "surface", "status",
                                          "length_m")}}
        for r in rows
    ])


async def facilities_fc(
    db: AsyncSession, facility_type: Optional[str], state_code: Optional[str],
    near_lon: Optional[float], near_lat: Optional[float], radius_m: Optional[float],
) -> dict:
    """Facilities; with point+radius: ST_DWithin (geography=meters), ordered by
    ST_Distance ascending, each feature carrying distance_m."""
    rows = (await db.execute(text("""
        select f.code, f.name, f.facility_type, f.state_code, f.district_code,
               f.capacity_note, st_asgeojson(f.geom) as geo,
               case when :lon is null then null::numeric else
                    round(st_distance(f.geom::geography,
                          st_setsrid(st_makepoint(:lon,:lat),4326)::geography)::numeric, 1)
               end as distance_m
        from facilities f
        where (:ftype is null or f.facility_type = :ftype)
          and (:state is null or f.state_code = :state)
          and (:lon is null or st_dwithin(
                  f.geom::geography,
                  st_setsrid(st_makepoint(:lon,:lat),4326)::geography,
                  :radius_m))
        order by distance_m asc nulls last, f.code
        limit 200
    """), {"ftype": facility_type, "state": state_code,
           "lon": near_lon, "lat": near_lat, "radius_m": radius_m or 0})).mappings().all()
    return _fc([
        {"type": "Feature", "geometry": json.loads(r["geo"]),
         "properties": {"code": r["code"], "name": r["name"],
                        "facility_type": r["facility_type"],
                        "state_code": r["state_code"], "district_code": r["district_code"],
                        "capacity_note": r["capacity_note"],
                        **({"distance_m": float(r["distance_m"])}
                           if r["distance_m"] is not None else {})}}
        for r in rows
    ])


async def linear_features_fc(db: AsyncSession, kind: str) -> dict:
    if kind == "railways":
        sql = "select code, name, operator, st_asgeojson(geom) as geo from railways"
    else:
        sql = ("select code, name, navigable::text as operator,"
               " st_asgeojson(geom) as geo from waterways")
    rows = (await db.execute(text(sql))).mappings().all()
    return _fc([
        {"type": "Feature", "geometry": json.loads(r["geo"]),
         "properties": {"code": r["code"], "name": r["name"], "operator": r["operator"]}}
        for r in rows
    ])


async def gis_summary(db: AsyncSession) -> dict:
    row = (await db.execute(text("select * from v_gis_summary"))).mappings().one()
    return {k: int(v) for k, v in dict(row).items()}

