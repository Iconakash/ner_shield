"""Impact Engine (Phase 8 · C05).

"If this road fails, these services and shipments are affected."

Pure scoring math (unit-testable) + the PostGIS assessment that finds affected
shipments, warehouses, hospitals, logistics hubs, districts, communities and
alternative routes, then computes a weighted 0-100 Impact Score with label:

    >=75 CRITICAL · >=50 HIGH · >=25 MODERATE · else LOW
"""
import json

from sqlalchemy import text
from sqlalchemy.ext.asyncio import AsyncSession

IMPACT_WEIGHTS_V1 = {
    "population": 0.25, "essential_supplies": 0.20,
    "critical_facilities": 0.20, "alternatives": 0.20, "duration": 0.15,
}
IMPACT_BANDS = [(75, "CRITICAL"), (50, "HIGH"), (25, "MODERATE"), (0, "LOW")]

# expected disruption duration by triggering risk label (hours)
DURATION_BY_LABEL = {"CRITICAL": 72, "HIGH": 48,
                     "ELEVATED": 24, "GUARDED": 12, "LOW": 6}

CATCHMENT_M = 10000          # facilities/communities within 10 km of segment


def classify_impact(score: float) -> str:
    for minimum, label in IMPACT_BANDS:
        if score >= minimum:
            return label
    return "LOW"  # pragma: no cover


def validate_impact_weights(weights: dict[str, float]) -> None:
    expected = {"population", "essential_supplies", "critical_facilities",
                "alternatives", "duration"}
    if set(weights) != expected:
        raise ValueError(f"impact weights must cover exactly {sorted(expected)}")
    total = sum(float(v) for v in weights.values())
    if abs(total - 1.0) > 1e-6:
        raise ValueError(f"impact weights must sum to 1.0 (got {total})")


# ------------------------------------------------------- component normalizers
def population_score(total_population: int) -> float:
    """50,000 affected people => 100 (linear cap)."""
    return min(100.0, 100.0 * total_population / 50000.0)


def supplies_score(n_warehouses: int, n_hubs: int) -> float:
    """Essential-supply nodes: each warehouse/hub matters; 4+ saturates."""
    return min(100.0, 25.0 * (n_warehouses + n_hubs))


def facilities_score(n_hospitals: int, n_airports: int) -> float:
    """Hospitals weigh most; airports are strategic multipliers."""
    return min(100.0, 100.0 * (n_hospitals * 0.3 + n_airports * 0.2))


def alternatives_score(n_alternate_roads: int) -> float:
    """Scarcity inverted: zero alternates => worst (100). Saturates at 3."""
    return max(0.0, 100.0 * (1.0 - min(n_alternate_roads, 3) / 3.0))


def duration_score(hours: int) -> float:
    return min(100.0, 100.0 * hours / 72.0)


def compute_impact(population: int, warehouses: int, hubs: int, hospitals: int,
                   airports: int, alternate_roads: int, hours: int,
                   weights: dict[str, float] | None = None) -> tuple[float, str, dict]:
    w = dict(weights or IMPACT_WEIGHTS_V1)
    validate_impact_weights(w)
    components = {
        "population": {"raw": population, "value": round(population_score(population), 2),
                       "weight": w["population"]},
        "essential_supplies": {"warehouses": warehouses, "logistics_hubs": hubs,
                               "value": round(supplies_score(warehouses, hubs), 2),
                               "weight": w["essential_supplies"]},
        "critical_facilities": {"hospitals": hospitals, "airports": airports,
                                "value": round(facilities_score(hospitals, airports), 2),
                                "weight": w["critical_facilities"]},
        "alternatives": {"alternate_roads": alternate_roads,
                         "value": round(alternatives_score(alternate_roads), 2),
                         "weight": w["alternatives"]},
        "duration": {"expected_hours": hours,
                     "value": round(duration_score(hours), 2), "weight": w["duration"]},
    }
    score = round(sum(c["value"] * c["weight"] for c in components.values()), 2)
    score = min(100.0, max(0.0, score))
    return score, classify_impact(score), components

# ------------------------------------------------------- spatial assessment
async def assess_segment(db: AsyncSession, segment_id: str,
                         risk_pct: float, risk_label: str,
                         horizon: str = "24h") -> dict:
    """Full impact assessment for one high-risk road segment.

    Affected sets via PostGIS:
      shipments   — assigned route INTERSECTS the segment geometry
      facilities  — ST_DWithin 10 km catchment around the segment
      districts   — containing + districts intersecting a 15 km buffer
      communities — ST_DWithin catchment (population summed)
      alternatives— other OPEN roads touching affected state segments
    """
    seg_row = (await db.execute(text("""
        select rs.id::text as id, rs.geom, rs.district_code, rs.state_code,
               r.code as road_code, r.name as road_name
        from road_segments rs join roads r on r.id = rs.road_id
        where rs.id = cast(:s as uuid)
    """), {"s": segment_id})).mappings().first()
    if seg_row is None:
        from app.core.errors import NotFound
        raise NotFound("segment not found")

    ship_rows = (await db.execute(text("""
        select s.id::text as id, s.code, s.title,
               s.priority::text as priority, s.status::text as status,
               s.commodity::text as commodity
        from shipments s
        where s.status in ('IN_TRANSIT','ROUTE_ASSIGNED','VEHICLE_ASSIGNED')
          and st_intersects(s.route_geom, :geom)
    """), {"geom": seg_row["geom"]})).mappings().all()

    fac_rows = (await db.execute(text("""
        select f.code, f.name, f.facility_type::text as facility_type,
               f.district_code
        from facilities f
        where st_dwithin(f.geom::geography, (:geom)::geography, :catch)
        order by f.facility_type, f.name
    """), {"geom": seg_row["geom"], "catch": CATCHMENT_M})).mappings().all()

    comm_rows = (await db.execute(text("""
        select c.code, c.name, c.district_code, c.population
        from communities c
        where st_dwithin(c.geom::geography, (:geom)::geography, :catch)
        order by c.population desc
    """), {"geom": seg_row["geom"], "catch": CATCHMENT_M})).mappings().all()

    dist_rows = (await db.execute(text("""
        select d.code, d.name from districts d
        where d.geom is not null
          and st_dwithin(d.geom::geography, (:geom)::geography, 15000)
    """), {"geom": seg_row["geom"]})).mappings().all()

    alt_row = (await db.execute(text("""
        select count(distinct r2.id) from roads r2
        join road_segments rs2 on rs2.road_id = r2.id
        where r2.code <> :self_code and rs2.status = 'OPEN'
          and rs2.state_code = any(:dists::text[])
    """), {"self_code": seg_row["road_code"],
           "dists": sorted({r["code"] for r in dist_rows}) or ["__none__"]}
    )).scalar()
    alternate_roads = int(alt_row or 0)

    population = sum(int(r["population"] or 0) for r in comm_rows)
    warehouses = sum(1 for f in fac_rows if f["facility_type"] == "WAREHOUSE")
    hubs = sum(1 for f in fac_rows if f["facility_type"] == "LOGISTICS_HUB")
    hospitals = sum(1 for f in fac_rows if f["facility_type"] == "HOSPITAL")
    airports = sum(1 for f in fac_rows if f["facility_type"] == "AIRPORT")

    hours = DURATION_BY_LABEL.get(risk_label, 24)
    score, label, components = compute_impact(
        population=population, warehouses=warehouses, hubs=hubs,
        hospitals=hospitals, airports=airports,
        alternate_roads=alternate_roads, hours=hours)

    wrow = (await db.execute(text(
        "select version from impact_weights where is_active"
        " order by version desc limit 1"))).scalar() or 1

    affected = {
        "shipments": [dict(r) for r in ship_rows],
        "warehouses": [dict(r) for r in fac_rows if r["facility_type"] == "WAREHOUSE"],
        "hospitals": [dict(r) for r in fac_rows if r["facility_type"] == "HOSPITAL"],
        "logistics_hubs": [dict(r) for r in fac_rows
                           if r["facility_type"] == "LOGISTICS_HUB"],
        "airports": [dict(r) for r in fac_rows if r["facility_type"] == "AIRPORT"],
        "districts": [{"code": r["code"], "name": r["name"]} for r in dist_rows],
        "communities": [dict(r) for r in comm_rows],
        "total_population_affected": population,
        "alternative_open_roads": alternate_roads,
    }
    summary = (
        f"IMPACT: {label} ({score:.0f}/100). Failure of {seg_row['road_code']} "
        f"affects {len(ship_rows)} active shipment(s), "
        f"{population:,} people across {len(dist_rows)} district(s), "
        f"{warehouses + hubs} supply node(s) and {hospitals} hospital(s); "
        f"{alternate_roads} alternative OPEN road(s) remain; "
        f"expected disruption ~{hours}h.")

    await db.execute(text("""
        insert into impact_assessments
          (trigger_type, segment_id, road_code, horizon, risk_pct, risk_label,
           impact_score, impact_label, components, weights_version,
           affected, expected_duration_hours, summary_sentence)
        values ('SEGMENT_RISK', cast(:seg as uuid), :rcode, :hz, :rpct, :rlabel,
                :score, :ilabel, cast(:comp as jsonb), :wv,
                cast(:aff as jsonb), :hours, :summary)
    """), {"seg": segment_id, "rcode": seg_row["road_code"], "hz": horizon,
           "rpct": risk_pct, "rlabel": risk_label, "score": score,
           "ilabel": label, "comp": json.dumps(components), "wv": int(wrow),
           "aff": json.dumps(affected, default=str), "hours": hours,
           "summary": summary})

    return {"segment_id": segment_id, "road_code": seg_row["road_code"],
            "impact_score": score, "impact_label": label, "impact": label,
            "components": components, "affected": affected,
            "expected_duration_hours": hours, "summary_sentence": summary}


