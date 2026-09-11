"""Field Intelligence (Phase 13 · C12) — the human + AI feedback loop.

Flow (source-mandated): Field Report -> Validation -> Confidence ->
Road Segment -> Accessibility Update -> Risk Recalculation -> Route
Recalculation -> Alert.
"""
import json
import time
from typing import Any

from sqlalchemy import text
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.security import Principal

# incident type -> fused-signal kind (feeds accessibility + risk engines)
SIGNAL_MAP = {
    "LANDSLIDE": "LANDSLIDE_RISK",
    "FLOOD": "FLOOD_RISK",
    "ROAD_DAMAGE": "INFRASTRUCTURE",
    "TRAFFIC_BLOCKAGE": "TRAFFIC",
    "BRIDGE_PROBLEM": "INFRASTRUCTURE",
    "OTHER": None,
}
SEVERITY_VALUE = {"LOW": 35, "MEDIUM": 60, "HIGH": 80, "CRITICAL": 92}
SEVERITY_ALERT_LEVEL = {"LOW": "INFO", "MEDIUM": "WARNING",
                        "HIGH": "HIGH", "CRITICAL": "CRITICAL"}
# structural failures close the segment outright at HIGH/CRITICAL severity
CLOSING_TYPES = {"LANDSLIDE", "FLOOD", "BRIDGE_PROBLEM"}

BASE_CONFIDENCE = 40.0  # legacy constant retained for reference


def compute_confidence(
    *, has_photo: bool, severity: str, snap_distance_m: float | None,
    in_modeled_area: bool,
    gps_accuracy_m: float | None = None,
    observed_age_hours: float = 0.0,
    reporter_role: str = "FIELD_OFFICER",
    corroborating_reports: int = 0,
    reporter_trust_score: float | None = None,
) -> tuple[float, dict]:
    """Multi-signal confidence v2 (Phase 14). Pure — every component visible.

    Components (max): gps_validity 15 · timestamp 10 · photo 15 ·
    severity 10 · reporter_role 10 · road_proximity 20 · modeled_area 5 ·
    corroboration 10  =>  theoretical max 95..100 depending on corroboration.
    Optional SIH26002 P2 addition: `reporter_trust_score` (0..100 historical
    accuracy) contributes up to 5 pts as ONE more visible input. It never
    lowers a score below the legacy value and is never a sole reject reason.
    """
    # --- GPS validity ------------------------------------------------------
    if gps_accuracy_m is None:
        gps_pts, gps_note = 4.0, "unknown accuracy"
    elif gps_accuracy_m <= 10:
        gps_pts, gps_note = 15.0, f"±{gps_accuracy_m:.0f} m"
    elif gps_accuracy_m <= 30:
        gps_pts, gps_note = 12.0, f"±{gps_accuracy_m:.0f} m"
    elif gps_accuracy_m <= 75:
        gps_pts, gps_note = 6.0, f"±{gps_accuracy_m:.0f} m"
    else:
        gps_pts, gps_note = 0.0, f"±{gps_accuracy_m:.0f} m"

    # --- timestamp freshness ----------------------------------------------
    age = max(0.0, observed_age_hours)
    if age <= 6:
        ts_pts, ts_note = 10.0, "observed <6h ago"
    elif age <= 24:
        ts_pts, ts_note = 7.0, "observed <24h ago"
    elif age <= 72:
        ts_pts, ts_note = 3.0, "observed <72h ago"
    else:
        ts_pts, ts_note = 0.0, "stale observation"

    photo_pts = 15.0 if has_photo else 0.0

    sev_pts = 10.0 if severity in ("HIGH", "CRITICAL") else 4.0

    role_pts = {"FIELD_OFFICER": 10.0, "DISTRICT_OFFICER": 10.0,
                "LOGISTICS_OFFICER": 7.0}.get(reporter_role, 5.0)

    if snap_distance_m is None:
        road_pts, road_note = 0.0, "no road within 15 km"
    elif snap_distance_m <= 500:
        road_pts, road_note = 20.0, "on-road"
    elif snap_distance_m <= 1000:
        road_pts, road_note = 16.0, "within 1 km"
    elif snap_distance_m <= 3000:
        road_pts, road_note = 10.0, "within 3 km"
    else:
        road_pts, road_note = 4.0, "far from network"

    area_pts = 5.0 if in_modeled_area else 0.0

    n_corr = max(0, int(corroborating_reports))
    corr_pts = {0: 0.0, 1: 5.0, 2: 8.0}.get(n_corr, 10.0)

    # P2: historical reporter trust — additive bonus only (never punitive on
    # its own; officials still decide validation outcomes).
    hist_pts = 0.0
    if reporter_trust_score is not None:
        hist_pts = round(5.0 * max(0.0, min(100.0,
                                            float(reporter_trust_score)))
                         / 100.0, 1)

    breakdown = {
        "gps_validity": {"points": gps_pts, "max": 15, "note": gps_note},
        "timestamp_freshness": {"points": ts_pts, "max": 10, "note": ts_note},
        "photo": {"points": photo_pts, "max": 15},
        "severity_weight": {"points": sev_pts, "max": 10,
                            "severity": severity},
        "reporter_role_trust": {"points": role_pts, "max": 10,
                                "role": reporter_role},
        "road_proximity": {"points": road_pts, "max": 20, "note": road_note},
        "modeled_area": {"points": area_pts, "max": 5},
        "corroboration": {"points": corr_pts, "max": 10,
                          "independent_reports": n_corr},
    }
    if reporter_trust_score is not None:
        breakdown["reporter_history"] = {"points": hist_pts, "max": 5,
                                         "trust": reporter_trust_score}
    score = round(min(100.0, sum(v["points"] for v in breakdown.values())), 2)
    breakdown["total"] = score
    return score, breakdown



async def resolve_location(db: AsyncSession, lon: float, lat: float):
    """ST_Contains for district + ST_DWithin nearest-segment snap."""
    d = (await db.execute(text("""
        select d.code, d.state_code from districts d
        where d.geom is not null
          and st_contains(d.geom, st_setsrid(st_makepoint(:lon,:lat),4326))
        order by st_area(d.geom) asc limit 1
    """), {"lon": lon, "lat": lat})).mappings().first()

    s = (await db.execute(text("""
        select rs.id::text as id, r.code as road_code,
               round(st_distance(rs.geom::geography,
                     st_setsrid(st_makepoint(:lon,:lat),4326)::geography)::numeric,1)
                 as dist_m
        from road_segments rs join roads r on r.id = rs.road_id
        where st_dwithin(rs.geom::geography,
              st_setsrid(st_makepoint(:lon,:lat),4326)::geography, 15000)
        order by st_distance(rs.geom::geography,
                  st_setsrid(st_makepoint(:lon,:lat),4326)::geography)
        limit 1
    """), {"lon": lon, "lat": lat})).mappings().first()
    return {
        "state_code": d["state_code"] if d else None,
        "district_code": d["code"] if d else None,
        "nearest_segment_id": s["id"] if s else None,
        "snap_distance_m": float(s["dist_m"]) if s else None,
        "in_modeled_area": d is not None or s is not None,
    }


async def submit_report(
    db: AsyncSession, *, principal: Principal, incident_type: str,
    severity: str, lon: float, lat: float, description: str,
    photo_ref: str | None, client_op_id: str | None = None,
    gps_accuracy_m: float | None = None,
    observed_at_iso: str | None = None,
) -> dict:
    """SUBMIT: resolve location, snap to segment, score confidence v2, persist."""
    loc = await resolve_location(db, lon, lat)

    # corroborating independent reports: same type, different reporter,
    # within 5 km and the last 72 hours, not rejected
    corr_row = (await db.execute(text("""
        select count(*) from field_reports fr
        where fr.incident_type::text = :t
          and fr.reported_by <> cast(:u as uuid)
          and fr.status <> 'REJECTED'
          and fr.created_at > now() - interval '72 hours'
          and st_dwithin(fr.geom::geography,
                st_setsrid(st_makepoint(:lon,:lat),4326)::geography, 5000)
    """), {"t": incident_type, "u": principal.user_id,
           "lon": lon, "lat": lat})).scalar()
    corroborations = int(corr_row or 0)

    observed_age_hours = 0.0
    if observed_at_iso:
        from datetime import datetime, timezone as _tz
        try:
            observed_dt = datetime.fromisoformat(observed_at_iso.replace("Z", "+00:00"))
            observed_age_hours = max(0.0, (datetime.now(_tz.utc)
                                           - observed_dt).total_seconds() / 3600.0)
        except ValueError:
            pass

    trust = await reporter_trust(db, str(principal.user_id))
    confidence, breakdown = compute_confidence(
        has_photo=bool(photo_ref), severity=severity,
        snap_distance_m=loc["snap_distance_m"],
        in_modeled_area=loc["in_modeled_area"],
        gps_accuracy_m=gps_accuracy_m,
        observed_age_hours=observed_age_hours,
        reporter_role=principal.role,
        corroborating_reports=corroborations,
        reporter_trust_score=trust["trust_score"])
    code = f"FR-{principal.user_id[:4].upper()}-{int(time.time())}"

    op_id = client_op_id or f"{principal.user_id}:{code}"
    row = (await db.execute(text("""
        insert into field_reports (code, reported_by, incident_type, severity,
            description, photo_ref, geom, state_code, district_code,
            nearest_segment, distance_to_segment_m, confidence,
            confidence_components, gps_accuracy_m, observed_at,
            corroboration_count, client_op_id)
        values (:code, cast(:u as uuid), cast(:t as incident_type),
                cast(:sv as incident_severity), :desc, :photo,
                st_setsrid(st_makepoint(:lon,:lat),4326), :s, :d,
                case when :seg is null then null
                     else cast(:seg as uuid) end,
                :dist, :conf, cast(:cc as jsonb), :acc,
                coalesce(:obs, now()), :corr, :opid)
        on conflict (client_op_id) do nothing
        returning id::text as id, code, confidence, status
    """), {"code": code, "u": principal.user_id, "t": incident_type,
           "sv": severity, "desc": description[:2000], "photo": photo_ref,
           "lon": lon, "lat": lat, "s": loc["state_code"],
           "d": loc["district_code"], "seg": loc["nearest_segment_id"],
           "dist": loc["snap_distance_m"], "conf": confidence,
           "cc": json.dumps(breakdown), "acc": gps_accuracy_m,
           "obs": observed_at_iso, "corr": corroborations,
           "opid": op_id}
    )).mappings().first()
    if row is None:  # idempotent replay from offline queue
        existing = (await db.execute(text(
            "select id::text as id, code, confidence, status from field_reports"
            " where client_op_id = :o"), {"o": op_id})).mappings().first()
        return {**dict(existing), "replayed": True}

    from app.audit import service as audit_service
    await audit_service.emit(db, actor_id=principal.user_id,
                             actor_role=principal.role,
                             action="REPORT_SUBMITTED", outcome="SUCCESS",
                             resource_type="field_report",
                             resource_id=row["id"],
                             detail={"code": row["code"],
                                     "confidence": float(row["confidence"])})
    return {"id": row["id"], "code": row["code"],
            "confidence": float(row["confidence"]), "status": row["status"],
            "nearest_segment": loc["nearest_segment_id"],
            "snap_distance_m": loc["snap_distance_m"],
            "confidence_breakdown": breakdown,
            "reporter_trust": trust}
async def validate_report(
    system_db: AsyncSession, db: AsyncSession, *, report_id: str,
    validator: Principal, decision: str, note: str | None = None,
) -> dict:
    """VALIDATION step + the rest of the mandated loop:

    signals -> accessibility update -> risk recalculation -> route ETA
    recalculation -> targeted alert (HIGH/CRITICAL severities).
    """
    rep = (await system_db.execute(text("""
        select fr.id::text as id, fr.code, fr.incident_type::text as itype,
               fr.severity::text as sev, fr.nearest_segment,
               fr.district_code, fr.state_code, fr.status,
               st_x(fr.geom) as lon, st_y(fr.geom) as lat
        from field_reports fr where fr.id = cast(:i as uuid)
    """), {"i": report_id})).mappings().first()
    if rep is None:
        from app.core.errors import NotFound
        raise NotFound("report not found or outside your scope")
    if rep["status"] != "SUBMITTED":
        from app.core.errors import Conflict
        raise Conflict(f"report already {rep['status']}")

    # object-level authorization: validator must hold scope over report geography
    from app.dependencies import ensure_geo_scope
    await ensure_geo_scope(validator, rep["state_code"], rep["district_code"], db)

    await system_db.execute(text("""
        update field_reports set status = :st,
            validated_by = cast(:v as uuid), validated_at = now(),
            validation_note = :n
        where id = cast(:i as uuid)
    """), {"st": decision, "v": validator.user_id, "n": note, "i": report_id})

    loop: dict[str, Any] = {"validation": decision}
    if decision == "VALIDATED":
        # 1) Accessibility Update — inject a normalized fused signal
        kind = SIGNAL_MAP[rep["itype"]]
        if kind and rep["nearest_segment"]:
            await system_db.execute(text("""
                insert into geo_factor_signals (signal_kind, target_type,
                    segment_id, value, source)
                values (:k, 'ROAD_SEGMENT', cast(:seg as uuid), :v, :src)
            """), {"k": kind, "seg": rep["nearest_segment"],
                   "v": SEVERITY_VALUE[rep["sev"]],
                   "src": f"field_report:{rep['code']}"})

        # 2) structural failures close the segment outright
        if (rep["sev"] in ("HIGH", "CRITICAL")
                and rep["itype"] in CLOSING_TYPES and rep["nearest_segment"]):
            await system_db.execute(text("""
                update road_segments set status = 'CLOSED', updated_at = now()
                where id = cast(:s as uuid)
            """), {"s": rep["nearest_segment"]})
        elif rep["sev"] == "HIGH" and rep["nearest_segment"]:
            await system_db.execute(text("""
                update road_segments set status = 'PARTIAL', updated_at = now()
                where id = cast(:s as uuid) and status = 'OPEN'
            """), {"s": rep["nearest_segment"]})

        # 3+4) Risk Recalculation -> Route Recalculation for affected convoys
        from app.accessibility import service as acc_svc
        from app.risk import service as risk_svc
        acc_result = await acc_svc.run_scoring(system_db)
        risk_result = await risk_svc.run_prediction_pass(system_db)
        loop["accessibility_run"] = acc_result.get("road_segment", {})
        loop["risk_run"] = {"targets": risk_result.get("targets_predicted"),
                            "labels": risk_result.get("labels")}

        eta_recalcs: list[dict] = []
        if rep["nearest_segment"]:
            ships = (await system_db.execute(text("""
                select s.id::text as id from shipments s
                where s.status in ('IN_TRANSIT','ROUTE_ASSIGNED')
                  and st_intersects(s.route_geom,
                      (select geom from road_segments
                       where id = cast(:s as uuid)))
                limit 10
            """), {"s": rep["nearest_segment"]})).mappings().all()
            for sh in ships:
                ship_row = await shipments_get(system_db, sh["id"])
                eta = await eta_calculate(system_db, {**ship_row, "id": sh["id"]})
                eta_recalcs.append({"shipment_id": sh["id"],
                                    "eta_minutes": eta["eta_minutes"],
                                    "expected_disruption_minutes":
                                        eta["expected_disruption_minutes"]})
        loop["eta_recalculations"] = eta_recalcs

        # 5) targeted alert via the Phase-12 chain engine
        level = SEVERITY_ALERT_LEVEL[rep["sev"]]
        from app.alerts import service as alerts_svc
        alert = None
        if level != "INFO":
            alert = await alerts_svc.create_alert(
                system_db, level=level, alert_type="ROAD_WARNING",
                title=f"Validated {rep['itype'].lower()} ({rep['sev']}) on "
                      f"{rep['district_code']}",
                message=note or "Validated field report",
                state_code=rep["state_code"], district_code=rep["district_code"],
                segment_id=rep["nearest_segment"], payload={"report": rep["code"]})
            loop["alert_id"] = alert["id"]

        # P3 (SIH26002): nearest-responder auto-dispatch for serious hazards.
        # Isolated outcome — dispatch problems never fail validation.
        from app.responders import service as responder_svc
        if rep["sev"] in responder_svc.DISPATCH_SEVERITIES and \
                rep["lon"] is not None:
            loop["responder_dispatch"] = await responder_svc.dispatch_for_report(
                system_db, report_id=rep["id"], lon=float(rep["lon"]),
                lat=float(rep["lat"]), severity=rep["sev"],
                district_code=rep["district_code"],
                alert_id=loop.get("alert_id"),
                created_by=str(validator.user_id))
            if loop["responder_dispatch"].get("status") == "dispatched":
                from app.audit import service as audit_service
                rd = loop["responder_dispatch"]
                await audit_service.emit(
                    system_db, actor_id=None, actor_role=None,
                    action="RESPONDER_ALERTED", outcome="SUCCESS",
                    resource_type="response_task",
                    resource_id=rd["task"]["id"],
                    detail={"report": rep["code"],
                            "responder": rd["responder"]["name"],
                            "distance_m": rd["responder"]["distance_m"]})

    from app.audit import service as audit_service
    action = "REPORT_VALIDATED" if decision == "VALIDATED" else "REPORT_REJECTED"
    # REPORT_* actions are part of the closed vocabulary (added in Phase 13)
    from app.audit.service import ACTIONS as _ACTIONS
    audit_action = action if action in _ACTIONS else "ANALYZE"
    await audit_service.emit(
        system_db, actor_id=validator.user_id, actor_role=validator.role,
        action=audit_action, outcome="SUCCESS",
        resource_type="field_report", resource_id=report_id,
        detail={"decision": decision, "loop": loop}, ip=None)

    return {"id": report_id, "status": decision, "loop": loop}


async def shipments_get(db: AsyncSession, shipment_id: str) -> dict:
    from app.shipments import service as ship_svc
    row = await ship_svc.get_shipment(db, shipment_id)
    return row or {}


# ======================================================= P2: reporter trust
# Historical trust for a FIELD REPORTER, derived ONLY from completed official
# verifications of their past reports (existing field_reports rows — no new
# source of truth). It feeds evidence confidence as ONE input; it is never a
# sole rejection reason, and officials can always verify/reject manually.

TRUST_PRIOR_CORRECT = 2     # Laplace-style cold-start prior ...
TRUST_PRIOR_TOTAL = 3       # ... => new reporter starts ~67/100, never 0/100


def trust_score(correct: int, rejected: int) -> dict:
    """Smoothed historical accuracy 0..100 with full explainability.

    trust = (correct + prior_correct) / (verified_total + prior_total)
    A brand-new reporter therefore starts neither at 0% nor 100% (~67), and a
    short history cannot produce extreme scores. Rejected reports (including
    duplicates/spam once rejected by officials) count against accuracy.
    """
    c = max(0, int(correct))
    r = max(0, int(rejected))
    total = c + r
    score = round(100.0 * (c + TRUST_PRIOR_CORRECT)
                  / (total + TRUST_PRIOR_TOTAL), 1)
    band = ("HIGH" if score >= 85 else "MODERATE" if score >= 60
            else "LOW_EXPERIENCE" if total == 0 else "LOW")
    return {
        "trust_score": score,                 # 0..100 display value
        "band": band,
        "reports_verified": total,
        "verified_correct": c,
        "rejected": r,
        "cold_start": total < 5,              # honest flag for thin history
        "method": f"laplace(prior {TRUST_PRIOR_CORRECT}/"
                  f"{TRUST_PRIOR_TOTAL}) over official verifications",
    }


async def reporter_trust(db: AsyncSession, reporter_id: str) -> dict:
    """Aggregate one reporter's verification track record (indexed lookups)."""
    row = (await db.execute(text("""
        select count(*) filter (where status = 'VALIDATED') as correct,
               count(*) filter (where status = 'REJECTED')  as rejected
        from field_reports
        where reported_by = cast(:u as uuid)
          and status in ('VALIDATED', 'REJECTED')
    """), {"u": reporter_id})).mappings().first()
    out = trust_score(int(row["correct"] or 0), int(row["rejected"] or 0))
    out["reporter_id"] = reporter_id
    return out


async def eta_calculate(db: AsyncSession, shipment: dict) -> dict:
    """Thin indirection so field module doesn't duplicate ETA logic."""
    from app.shipments import service as ship_svc
    return await ship_svc.calculate_eta(db, shipment)


async def inbox_reports(db: AsyncSession, validator_scope_only: bool = True):
    rows = (await db.execute(text("""
        select fr.id::text as id, fr.code, fr.reported_by::text as reported_by,
               fr.incident_type::text as incident_type,
               fr.severity::text as severity, fr.description,
               fr.district_code, fr.state_code, fr.confidence, fr.status,
               fr.created_at,
               st_asgeojson(fr.geom) as geo
        from field_reports fr
        where fr.status = 'SUBMITTED'
        order by fr.created_at desc limit 200
    """))).mappings().all()
    out = []
    for r in rows:
        item = dict(r)
        item["geo"] = json.loads(item["geo"]) if item["geo"] else None
        out.append(item)
    return out


