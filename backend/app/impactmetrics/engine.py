"""Impact analytics (SIH26002 P7) — pure estimators.

HONESTY CONTRACT:
  * Every number carries a `basis`: MEASURED | ESTIMATED | SIMULATED.
  * Cost figures are ESTIMATES from a transparent per-hour delay model —
    never presented as audited government savings.
  * People impact uses operational terminology only ("population potentially
    affected", "essential-supply access risk") — no mortality/lives-saved
    claims without verified evidence.
"""

# Documented estimation model (INR). Deliberately simple and visible so any
# official can audit the arithmetic; tune per-deployment via env later.
DEFAULT_COST_PER_VEHICLE_HOUR_INR = 850.0   # crew+fuel+wear, loaded truck
DEFAULT_COST_PER_ESSENTIAL_TON_HOUR_INR = 40.0


def cost_saving_estimate(*, delay_hours_avoided: float,
                         vehicles_involved: int,
                         avg_tons_per_vehicle: float = 8.0,
                         cost_per_vehicle_hour: float =
                         DEFAULT_COST_PER_VEHICLE_HOUR_INR,
                         cost_per_ton_hour: float =
                         DEFAULT_COST_PER_ESSENTIAL_TON_HOUR_INR) -> dict:
    """ESTIMATED cost avoided = vehicle-hours + ton-hour delay components."""
    hours = max(0.0, float(delay_hours_avoided))
    vehicles = max(0, int(vehicles_involved))
    vehicle_hours = round(hours * vehicles, 2)
    ton_hours = round(hours * vehicles * max(0.0,
                                            float(avg_tons_per_vehicle)), 2)
    inr = round(hours * vehicles * float(cost_per_vehicle_hour)
                + hours * vehicles * max(0.0, float(avg_tons_per_vehicle))
                * float(cost_per_ton_hour), 0)
    return {
        "basis": "ESTIMATED",
        "delay_hours_avoided": hours,
        "vehicles_involved": vehicles,
        "vehicle_hours": vehicle_hours,
        "ton_hours": ton_hours,
        "estimated_cost_avoided_inr": inr,
        "model": {"cost_per_vehicle_hour_inr": cost_per_vehicle_hour,
                  "cost_per_essential_ton_hour_inr": cost_per_ton_hour},
    }


def people_impact_estimate(*, district_population: int | None,
                           days_of_supply: float | None,
                           commodity: str) -> dict:
    """Population with essential-supply access RISK — operational wording.

    Exposure = district population when the commodity is below the 3.5-day
    HIGH-urgency cover; None inputs yield an explicit 'unknown', never zero.
    """
    if district_population is None:
        return {"basis": "UNKNOWN",
                "people_potentially_affected": None,
                "note": "district population not available"}
    dos = float(days_of_supply) if days_of_supply is not None else None
    at_risk = (int(district_population)
               if dos is not None and dos < 3.5 else 0)
    return {
        "basis": "ESTIMATED",
        "commodity": commodity,
        "days_of_supply": dos,
        "people_potentially_affected": at_risk,
        "terminology": ("population with essential-supply access risk "
                        "(< 3.5 days of cover)"),
    }
