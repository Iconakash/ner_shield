"""Weather observation/forecast schemas — the internal normalized contract.

Risk engine consumes ONLY this shape regardless of upstream provider.
"""
from datetime import datetime
from typing import Literal

from pydantic import BaseModel, Field


class WeatherObservation(BaseModel):
    """One normalized station/district observation. No defaults for measured
    values: an adapter must either know or omit — never guess."""
    district_code: str | None = None
    segment_id: str | None = None
    rainfall_mm_24h: float = Field(ge=0)
    forecast_rainfall_mm_24h: float | None = Field(None, ge=0)
    temperature_c: float | None = None
    humidity_pct: float | None = Field(None, ge=0, le=100)
    wind_kph: float | None = Field(None, ge=0)
    warning: str | None = None                  # provider warning text if any
    forecast_horizon_h: int | None = Field(None, ge=1, le=240)
    observed_at: datetime
    source: str
    confidence: float = Field(0.5, ge=0, le=1)


Availability = Literal["LIVE", "RECENT", "STALE", "UNAVAILABLE", "SIMULATED"]
