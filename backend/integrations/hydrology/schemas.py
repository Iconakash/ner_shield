"""River observation schema — internal normalized hydrology contract.

Risk/routing engines consume ONLY this shape regardless of upstream provider.
Freshness metadata: observed_at (source), received_at/expires_at are stamped at
persistence time by the ingestion path.
"""
from datetime import datetime
from typing import Literal

from pydantic import BaseModel, Field

Quality = Literal["HIGH", "MEDIUM", "LOW"]
Trend = Literal["RISING", "FALLING", "STEADY", "UNKNOWN"]


class RiverObservation(BaseModel):
    station_code: str = Field(min_length=1)
    station_name: str | None = None
    river_name: str | None = None
    basin: str | None = None
    state_code: str | None = None
    district_code: str | None = None
    water_level_m: float | None = Field(None, ge=-20.0, le=200.0)
    level_trend: Trend | None = None
    warning_level_m: float | None = Field(None, ge=-20.0, le=200.0)
    danger_level_m: float | None = Field(None, ge=-20.0, le=200.0)
    discharge_cumecs: float | None = Field(None, ge=0)
    observed_at: datetime
    source: str
    quality: Quality | None = None
    confidence: float = Field(0.5, ge=0, le=1)