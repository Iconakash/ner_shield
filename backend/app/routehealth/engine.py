"""Route health scoring (SIH26002 P5).

ROUTE RISK  (existing, untouched) = how dangerous/unavailable is the route
                                    NOW / in the near future?
ROUTE HEALTH (this module)        = how reliable has this infrastructure been
                                    HISTORICALLY, and how vulnerable is it?

Pure scoring first (unit-testable), then indexed SQL aggregation over EXISTING
tables (segment_historical_stats, field_reports, road_segments). Nothing here
writes risk scores or touches the prediction engine.

Documented honesty notes:
  * average downtime telemetry is NOT instrumented in the current schema, so
    avg_downtime_h stays None rather than being estimated silently;
  * redundancy uses an open-sibling-segment count on the same road as a
    transparent proxy feeding the existing corridor/resilience view.
"""

# Scoring constants (documented, deterministic):
CLOSURE_PENALTY_PER = 2.5      # per closure in the trailing 12 months
CLOSURE_PENALTY_CAP = 35.0
RECENT_INCIDENT_PENALTY = 4.0  # per validated incident, trailing 30 days
RECENT_INCIDENT_CAP = 15.0
DISRUPTION_PENALTY_PER = 1.5   # per historical disruption (12m)
DISRUPTION_PENALTY_CAP = 20.0
LOW_REDUNDANCY_PENALTY = 10.0  # zero open siblings on the same road
NO_ACCESSIBILITY_DATA_PENALTY = 5.0

HEALTH_BANDS = [(75, "GOOD"), (55, "FAIR"), (35, "POOR")]   # else CRITICAL


def health_score(*, closures_12m: int, disruptions_12m: int,
                 recent_incidents_30d: int, open_siblings: int | None,
                 accessibility_pct: float | None) -> dict:
    """Deterministic reliability score 0..100 with a full component breakdown."""
    c = max(0, int(closures_12m))
    d = max(0, int(disruptions_12m))
    r = max(0, int(recent_incidents_30d))

    closure_pen = min(CLOSURE_PENALTY_CAP, CLOSURE_PENALTY_PER * c)
    disruption_pen = min(DISRUPTION_PENALTY_CAP, DISRUPTION_PENALTY_PER * d)
    incident_pen = min(RECENT_INCIDENT_CAP, RECENT_INCIDENT_PENALTY * r)
    redundancy_pen = LOW_REDUNDANCY_PENALTY if open_siblings == 0 else 0.0
    access_pen = (max(0.0, (70.0 - float(accessibility_pct)) / 2.0)
                  if accessibility_pct is not None
                  else NO_ACCESSIBILITY_DATA_PENALTY)

    score = round(max(0.0, min(100.0, 100.0 - closure_pen - disruption_pen
                               - incident_pen - redundancy_pen - access_pen)),
                  1)
    band = next((label for minimum, label in HEALTH_BANDS
                 if score >= minimum), "CRITICAL")
    return {
        "health_score": score,
        "band": band,
        "components": {
            "closures_12m": {"count": c, "penalty": closure_pen},
            "disruptions_12m": {"count": d, "penalty": disruption_pen},
            "recent_incidents_30d": {"count": r, "penalty": incident_pen},
            "redundancy": {"open_siblings": open_siblings,
                           "penalty": redundancy_pen},
            "current_accessibility": {"pct": accessibility_pct,
                                      "penalty": round(access_pen, 1)},
        },
    }


def trend(recent_incidents_90d: int, prior_incidents_90d: int,
          closures_recent: int, closures_prior: int) -> str:
    """Direction of travel over trailing vs preceding 90-day windows."""
    delta = ((recent_incidents_90d + 2 * closures_recent)
             - (prior_incidents_90d + 2 * closures_prior))
    if delta >= 2:
        return "DECLINING"
    if delta <= -2:
        return "IMPROVING"
    return "STABLE"
