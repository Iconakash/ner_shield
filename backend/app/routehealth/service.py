"""Route health DB assembly + infrastructure-gap ranking (SIH26002 P5)."""
from sqlalchemy import text
from sqlalchemy.ext.asyncio import AsyncSession

from app.routehealth import engine

# One indexed aggregate pass over existing tables; per-segment history,
# recent validated incidents, open siblings and latest accessibility score.
_AGG_SQL = """
select rs.id::text as segment_id, r.code as road_code, r.name as road_name,
       rs.district_code, rs.state_code,
       coalesce(hs.closures_12m, 0) as closures_12m,
       coalesce(hs.disruptions_12m, 0) as disruptions_12m,
       (select count(*) from field_reports fr
         where fr.nearest_segment = rs.id and fr.status = 'VALIDATED'
           and fr.created_at > now() - interval '30 days') as recent_incidents,
       (select count(*) from field_reports fr
         where fr.nearest_segment = rs.id and fr.status = 'VALIDATED'
           and fr.created_at > now() - interval '90 days') as incidents_90d,
       (select count(*) from field_reports fr
         where fr.nearest_segment = rs.id and fr.status = 'VALIDATED'
           and fr.created_at between now() - interval '180 days'
                                 and now() - interval '90 days')
            as incidents_prior90d,
       (select count(*) from road_segments s2
         where s2.road_id = rs.road_id and s2.id <> rs.id
           and s2.status::text = 'OPEN') as open_siblings,
       acc.score as accessibility_pct
from road_segments rs
join roads r on r.id = rs.road_id
left join segment_historical_stats hs on hs.segment_id = rs.id
left join lateral (
    select round(s.current_score::numeric, 1) as score
    from accessibility_scores s
    where s.segment_id = rs.id
    order by s.computed_at desc limit 1
) acc on true
where (:state is null or rs.state_code = :state)
  and (:district is null or rs.district_code = :district)
"""


def _score_row(row: dict) -> dict:
    out = dict(row)
    health = engine.health_score(
        closures_12m=int(row["closures_12m"] or 0),
        disruptions_12m=int(row["disruptions_12m"] or 0),
        recent_incidents_30d=int(row["recent_incidents"] or 0),
        open_siblings=(int(row["open_siblings"])
                       if row["open_siblings"] is not None else None),
        accessibility_pct=(float(row["accessibility_pct"])
                           if row["accessibility_pct"] is not None else None))
    out["health"] = health
    out["avg_downtime_h"] = None          # not instrumented — honest null
    out["trend"] = engine.trend(
        recent_incidents_90d=int(row["incidents_90d"] or 0),
        prior_incidents_90d=int(row["incidents_prior90d"] or 0),
        closures_recent=0, closures_prior=0)
    return out


async def ranking(db: AsyncSession, *, state: str | None = None,
                  district: str | None = None, limit: int = 50,
                  order: str = "health") -> list[dict]:
    """Health-ranked segments; `order` in {health, gaps, incidents}."""
    rows = (await db.execute(text(_AGG_SQL),
                             {"state": state, "district": district})
            ).mappings().all()
    scored = [_score_row(dict(r)) for r in rows]
    if order == "gaps":      # worst-first planning view
        scored.sort(key=lambda x: (x["health"]["health_score"],
                                   -(x["closures_12m"] or 0)))
    elif order == "incidents":
        scored.sort(key=lambda x: -(x["recent_incidents"] or 0))
    else:
        scored.sort(key=lambda x: -x["health"]["health_score"])
    return scored[:max(1, min(limit, 200))]


async def segment_health(db: AsyncSession, segment_id: str) -> dict | None:
    row = (await db.execute(text(_AGG_SQL + " and rs.id = cast(:seg as uuid)"),
                            {"state": None, "district": None,
                             "seg": segment_id})).mappings().first()
    if row is None:
        return None
    out = _score_row(dict(row))
    # multi-window incident counts (7/30/90/365 d) for trend charts, where
    # data exists — empty windows are reported as zeros, never invented.
    counts = (await db.execute(text("""
        select count(*) filter (
                 where created_at > now() - interval '7 days')  as d7,
               count(*) filter (
                 where created_at > now() - interval '30 days') as d30,
               count(*) filter (
                 where created_at > now() - interval '90 days') as d90,
               count(*) filter (
                 where created_at > now() - interval '365 days') as d365
        from field_reports
        where nearest_segment = cast(:seg as uuid)
          and status = 'VALIDATED'
    """), {"seg": segment_id})).mappings().first()
    out["incident_windows"] = {"7d": int(counts["d7"]),
                               "30d": int(counts["d30"]),
                               "90d": int(counts["d90"]),
                               "365d": int(counts["d365"])}
    return out


async def infrastructure_gaps(db: AsyncSession, *, state: str | None = None,
                              district: str | None = None,
                              min_failures: int = 3,
                              limit: int = 50) -> list[dict]:
    """Government planning view: repeatedly failing / single-point segments.

    Only segments with at least `min_failures` recorded closures+disruptions
    +validated incidents are listed so the view surfaces CHRONIC problems,
    not one-off noise. Feeds the existing corridor/resilience narrative.
    """
    ranked = await ranking(db, state=state, district=district,
                           limit=500, order="gaps")
    gaps = []
    for seg in ranked:
        failures = int(seg["closures_12m"] or 0) \
            + int(seg["disruptions_12m"] or 0) \
            + int(seg["recent_incidents"] or 0)
        if failures < max(1, min_failures):
            continue
        h = seg["health"]
        siblings = int(seg["open_siblings"] or 0)
        criticality = ("CRITICAL" if h["band"] == "CRITICAL" and siblings == 0
                       else "HIGH" if h["band"] in ("CRITICAL", "POOR")
                       else "MEDIUM" if h["band"] == "FAIR" else "LOW")
        gaps.append({
            "segment_id": seg["segment_id"],
            "road_code": seg["road_code"], "road_name": seg["road_name"],
            "district_code": seg["district_code"],
            "state_code": seg["state_code"],
            "failures": failures,
            "closures_12m": int(seg["closures_12m"] or 0),
            "avg_downtime_h": None,          # not instrumented
            "redundancy": ("NONE" if siblings == 0
                           else "LOW" if siblings <= 1 else "PRESENT"),
            "open_alternatives": siblings,
            "health_score": h["health_score"], "health_band": h["band"],
            "trend": seg["trend"], "criticality": criticality,
        })
        if len(gaps) >= max(1, min(limit, 100)):
            break
    return gaps