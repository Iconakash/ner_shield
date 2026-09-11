"""Decision-intelligence assembly service.

READ-ONLY over existing tables (weather_feed, segment_geo_features,
road_segments/roads, disruption_predictions, river_observations, shipments):
it fuses their rows into hazard assessments + decision cards. It NEVER writes
risk scores, never mutates predictions, and never marks a predicted road CLOSED
(predicted vs confirmed closure stays distinct — §12).

Writes performed here are limited to the NEW additive surfaces: deduplicated
alert upserts and closed-loop outcome records (both audited system paths).
"""
from sqlalchemy import text
from sqlalchemy.ext.asyncio import AsyncSession

from app.intel.decision_state import SituationInputs, build_card
from app.intel.evidence import EvidenceItem, HazardAssessment, fuse_hazard

# Documented evidence thresholds (conservative; missing data => no evidence,
# never a fabricated signal). Values follow IMD/CWC operational conventions.
HEAVY_RAIN_OBS_MM = 50.0        # observed 24h rainfall = EXTREME_RAINFALL signal
HEAVY_RAIN_FCST_MM = 65.0       # forecast 24h rainfall = FLOOD driver
FLOOD_SUSCEPTIBLE = 60          # terrain flood susceptibility 0..100
LANDSLIDE_SUSCEPTIBLE = 60      # terrain landslide susceptibility 0..100
LANDSLIDE_MIN_SLOPE_DEG = 15.0

# Explainable PREDICTION-confidence proxy: the existing model emits no
# calibrated confidence, so we derive one from input COMPLETENESS only
# (documented, deterministic, never presented as model certainty).
PRED_CONF_BASE = 0.40


def pred_confidence(*, weather_fresh: bool, terrain_present: bool,
                    history_present: bool) -> float:
    c = PRED_CONF_BASE
    if weather_fresh:
        c += 0.15
    if terrain_present:
        c += 0.10
    if history_present:
        c += 0.10
    return round(min(0.85, c), 3)


_SEGMENT_SQL = """
select distinct on (dp.segment_id)
       dp.segment_id::text as segment_id,
       dp.overall_label, dp.risk_current, dp.risk_24h, dp.computed_at,
       r.code as road_code, rs.district_code, rs.state_code,
       rs.status::text as segment_status,
       wx.rainfall_mm_24h, wx.forecast_rainfall_mm_24h,
       wx.observed_at as weather_observed_at, wx.source as weather_source,
       t.slope_deg, t.flood_susceptibility, t.landslide_susceptibility,
       h.disruptions_12m is not null as has_history,
       riv.water_level_m, riv.warning_level_m, riv.level_trend,
       riv.observed_at as river_observed_at, riv.source as river_source,
       coalesce(crit.n_critical, 0) as n_critical_shipments
from disruption_predictions dp
join road_segments rs on rs.id = dp.segment_id
join roads r on r.id = rs.road_id
left join lateral (
    select f.rainfall_mm_24h, f.forecast_rainfall_mm_24h,
           f.observed_at, f.source
    from weather_feed f
    where (f.segment_id = dp.segment_id
           or f.district_code = rs.district_code)
    order by f.observed_at desc limit 1
) wx on true
left join segment_geo_features t on t.segment_id = dp.segment_id
left join segment_historical_stats h on h.segment_id = dp.segment_id
left join lateral (
    select o.water_level_m, o.warning_level_m, o.level_trend,
           o.observed_at, o.source
    from river_observations o
    where o.district_code = rs.district_code
    order by o.observed_at desc limit 1
) riv on true
left join lateral (
    select count(*) as n_critical from shipments s
    where s.is_critical
      and s.status::text in ('ROUTE_ASSIGNED', 'IN_TRANSIT')
      and st_intersects(s.route_geom, rs.geom)
) crit on true
where dp.target_type = 'ROAD_SEGMENT'
order by dp.segment_id, dp.computed_at desc
limit :cap
"""


def _num(v) -> float | None:
    return None if v is None else float(v)


def build_evidence(row: dict) -> list[EvidenceItem]:
    """Deterministic evidence extraction from one assembled segment row."""
    items: list[EvidenceItem] = []
    rain_obs = _num(row.get("rainfall_mm_24h"))
    rain_fcst = _num(row.get("forecast_rainfall_mm_24h"))
    wx_src = row.get("weather_source") or "unknown"
    wx_at = row.get("weather_observed_at")

    if rain_obs is not None and rain_obs >= HEAVY_RAIN_OBS_MM:
        items.append(EvidenceItem(
            hazard_type="EXTREME_RAINFALL", source=wx_src,
            kind="observed_rainfall_24h", supports=True, value=rain_obs,
            observed_at=wx_at,
            label=f"Observed rainfall {rain_obs:.0f} mm/24h ({wx_src})",
            location={"district_code": row.get("district_code")}))
    if rain_fcst is not None and rain_fcst >= HEAVY_RAIN_FCST_MM:
        items.append(EvidenceItem(
            hazard_type="FLOOD", source=wx_src,
            kind="forecast_heavy_rainfall", supports=True, value=rain_fcst,
            observed_at=wx_at,
            label=f"Heavy rainfall forecast {rain_fcst:.0f} mm/24h ({wx_src})",
            location={"district_code": row.get("district_code")}))

    flood_susc = _num(row.get("flood_susceptibility"))
    if flood_susc is not None and flood_susc >= FLOOD_SUSCEPTIBLE:
        items.append(EvidenceItem(
            hazard_type="FLOOD", source="TERRAIN",
            kind="terrain_flood_susceptibility", supports=True,
            value=flood_susc,
            label=f"High terrain flood susceptibility ({flood_susc:.0f}/100)",
            location={"segment_id": row["segment_id"]},
            reliability=0.9, quality=0.9))

    slide_susc = _num(row.get("landslide_susceptibility"))
    slope = _num(row.get("slope_deg"))
    if (slide_susc is not None and slide_susc >= LANDSLIDE_SUSCEPTIBLE
            and slope is not None and slope >= LANDSLIDE_MIN_SLOPE_DEG):
        items.append(EvidenceItem(
            hazard_type="LANDSLIDE", source="TERRAIN",
            kind="terrain_landslide_susceptibility", supports=True,
            value=max(slide_susc, slope),
            label=(f"Steep slope {slope:.0f}\u00b0 with landslide "
                   f"susceptibility {slide_susc:.0f}/100"),
            location={"segment_id": row["segment_id"]},
            reliability=0.9, quality=0.9))

    trend = row.get("level_trend")
    wl = _num(row.get("water_level_m"))
    warn = _num(row.get("warning_level_m"))
    riv_src = row.get("river_source") or "CWC"
    if trend == "RISING":
        items.append(EvidenceItem(
            hazard_type="FLOOD", source=riv_src,
            kind="observed_river_level_rising", supports=True, value=wl,
            observed_at=row.get("river_observed_at"),
            label="River level rising (hydrological observation)",
            location={"district_code": row.get("district_code")},
            reliability=0.92))
    if wl is not None and warn is not None and wl >= warn:
        items.append(EvidenceItem(
            hazard_type="FLOOD", source=riv_src,
            kind="observed_river_above_warning_level", supports=True,
            value=wl, observed_at=row.get("river_observed_at"),
            label=f"River at {wl:.2f} m — at/above warning level {warn:.2f} m",
            location={"district_code": row.get("district_code")},
            reliability=0.95))
    return items


def assess_segment_row(row: dict) -> tuple[list[HazardAssessment], float]:
    """Fuse evidence into per-hazard assessments for one segment row.
    Returns (assessments, prediction_confidence_proxy)."""
    from datetime import datetime, timezone

    now = datetime.now(timezone.utc)
    wx_at = row.get("weather_observed_at")
    weather_fresh = bool(wx_at and (now - wx_at).total_seconds() < 86400)
    p_conf = pred_confidence(weather_fresh=weather_fresh,
                             terrain_present=row.get("slope_deg") is not None,
                             history_present=bool(row.get("has_history")))

    items = build_evidence(row)
    area = {"segment_id": row["segment_id"],
            "road_code": row.get("road_code"),
            "district_code": row.get("district_code")}
    assessments = []
    for hazard in ("FLOOD", "LANDSLIDE", "EXTREME_RAINFALL"):
        a = fuse_hazard(items, hazard, affected_area=area)
        if a is not None:
            assessments.append(a)
    return assessments, p_conf


def situation_for(row: dict, assessment: HazardAssessment,
                  p_conf: float) -> SituationInputs:
    n_crit = int(row.get("n_critical_shipments") or 0)
    return SituationInputs(
        risk_label=row["overall_label"],
        prediction_confidence=p_conf,
        data_confidence=assessment.confidence,
        exposure_criticality=2 if n_crit > 0 else 0,
        open_alternatives=None,     # unknown unless redundancy engine supplies it
        confirmed_closure=(row.get("segment_status") == "CLOSED"),
        verification_pending=assessment.verification_required)


def _impact_lines(row: dict, assessment: HazardAssessment) -> list[str]:
    lines = []
    n = int(row.get("n_critical_shipments") or 0)
    if n:
        lines.append(f"{n} critical shipment(s) routed through this segment")
    if row.get("segment_status") == "CLOSED":
        lines.append("Segment CONFIRMED closed (observed state)")
    elif row.get("overall_label") in ("HIGH", "CRITICAL"):
        lines.append("Disruption predicted — closure NOT confirmed")
    if assessment.conflict:
        lines.append("Sources disagree — field verification recommended")
    return lines


def _top_factors(row: dict) -> list[str]:
    factors = []
    fcst = _num(row.get("forecast_rainfall_mm_24h"))
    if fcst is not None and fcst >= HEAVY_RAIN_FCST_MM:
        factors.append("Heavy rainfall forecast")
    if row.get("level_trend") == "RISING":
        factors.append("Rising river level")
    slide = _num(row.get("landslide_susceptibility"))
    if slide is not None and slide >= LANDSLIDE_SUSCEPTIBLE:
        factors.append("High terrain susceptibility")
    factors.append(f"Model risk label {row['overall_label']}")
    return factors[:4]


def _dump_assessment(a: HazardAssessment) -> dict:
    from app.intel.evidence import summarize
    return {
        "hazard_type": a.hazard_type, "probability": a.probability,
        "severity": a.severity, "confidence": a.confidence,
        "time_horizon": a.time_horizon, "status": a.status,
        "verification_required": a.verification_required,
        "evidence_lines": summarize(a),
        "conflict": ({"sources_for": a.conflict.sources_for,
                      "sources_against": a.conflict.sources_against,
                      "note": a.conflict.note} if a.conflict else None),
        "affected_area": a.affected_area,
        "evidence": a.evidence}


async def assess_segments(db: AsyncSession, limit: int = 50) -> list[dict]:
    """Assemble hazard assessments + decision cards for segments with recent
    predictions. Read-only; RLS applies on the caller's session."""
    rows = (await db.execute(text(_SEGMENT_SQL),
                             {"cap": max(1, min(limit, 100))})
            ).mappings().all()
    out: list[dict] = []
    for raw in rows:
        row = dict(raw)
        row["risk_current"] = _num(row.get("risk_current"))
        row["risk_24h"] = _num(row.get("risk_24h"))
        try:
            assessments, p_conf = assess_segment_row(row)
        except Exception:  # noqa: BLE001 — one bad row must not kill the pass
            continue
        if not assessments:
            continue
        top = max(assessments, key=lambda a: a.probability)
        situation = situation_for(row, top, p_conf)
        n_crit = int(row.get("n_critical_shipments") or 0)
        card = build_card(
            subject_type="ROAD_SEGMENT", subject_id=row["segment_id"],
            title=f"{row['road_code']} ({row.get('district_code') or '\u2014'})",
            situation=situation, probability=top.probability,
            horizon=top.time_horizon,
            affected_entities=[
                {"type": "ROAD_SEGMENT", "id": row["segment_id"],
                 "label": row["road_code"]},
                {"type": "DISTRICT", "id": row.get("district_code"),
                 "label": row.get("district_code")},
                *([{"type": "CRITICAL_SHIPMENTS", "id": row["segment_id"],
                    "label": f"{n_crit} critical shipment(s)"}]
                  if n_crit > 0 else [])],
            impact_summary=_impact_lines(row, top),
            top_factors=_top_factors(row),
            evidence_lines=[e.get("label") or e["kind"]
                            for e in top.evidence if e["supports"]],
            hazard_label=top.hazard_type, status=top.status)
        out.append({
            "segment_id": row["segment_id"], "road_code": row["road_code"],
            "district_code": row.get("district_code"),
            "risk_label": row["overall_label"],
            "risk_current": row["risk_current"],
            "prediction_confidence": p_conf,
            "hazards": [_dump_assessment(a) for a in assessments],
            "card": {
                "decision_state": card.decision_state,
                "recommended_action": card.recommended_action,
                "approval_required": card.approval_required,
                "review_minutes": card.review_minutes,
                "options": [o.__dict__ for o in card.options],
                "impact_summary": card.impact_summary,
                "top_factors": card.top_factors,
                "affected_entities": card.affected_entities}})
    out.sort(key=lambda d: -(d["hazards"][0]["probability"]))
    return out


# ------------------------------------------------------------- closed loop
async def open_outcome(system_db: AsyncSession, *, decision_id: str,
                       rule: str, action: str,
                       approval_request_id: str | None = None,
                       recommended: dict | None = None,
                       created_by: str | None = None) -> dict:
    import json

    row = (await system_db.execute(text("""
        insert into decision_outcomes (decision_id, rule, action,
            approval_request_id, recommended, created_by)
        values (:d, :r, :a,
                case when :ar is null then null else cast(:ar as uuid) end,
                cast(:rec as jsonb),
                case when :u is null then null else cast(:u as uuid) end)
        on conflict (decision_id) do update
          set recommended = excluded.recommended,
              approval_request_id = coalesce(excluded.approval_request_id,
                                             decision_outcomes.approval_request_id)
        returning id::text as id, status::text as status
    """), {"d": decision_id, "r": rule, "a": action, "ar": approval_request_id,
           "rec": json.dumps(recommended or {}), "u": created_by}
    )).mappings().first()
    return {"id": row["id"], "decision_id": decision_id,
            "status": row["status"]}


async def set_outcome(system_db: AsyncSession, decision_id: str, *,
                      status: str | None = None,
                      outcome: str | None = None,
                      actual_impact: dict | None = None,
                      verification_source: str | None = None) -> dict:
    import json

    sets = ["updated_at = now()"]
    params: dict = {"d": decision_id}
    if status:
        sets.append("status = :st")
        params["st"] = status
    if outcome:
        sets.append("outcome = :oc, verified_at = now()")
        params["oc"] = outcome
    if actual_impact is not None:
        sets.append("actual_impact = cast(:ai as jsonb)")
        params["ai"] = json.dumps(actual_impact)
    if verification_source:
        sets.append("verification_source = :vs")
        params["vs"] = verification_source
    row = (await system_db.execute(text(
        f"update decision_outcomes set {', '.join(sets)} "
        "where decision_id = :d returning id::text as id,"
        " status::text as status, outcome"), params)).mappings().first()
    if row is None:
        from app.core.errors import NotFound
        raise NotFound(f"no outcome record for decision '{decision_id}'")
    return {"decision_id": decision_id, "status": row["status"],
            "outcome": row["outcome"]}


async def get_outcome(db: AsyncSession, decision_id: str) -> dict | None:
    row = (await db.execute(text("""
        select decision_id, rule, action, status::text as status, outcome,
               actual_impact, verification_source, verified_at, created_at
        from decision_outcomes where decision_id = :d
    """), {"d": decision_id})).mappings().first()
    return dict(row) if row else None