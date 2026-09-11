"""Disaster alert/advisory schemas — common internal contract across authorities."""
from datetime import datetime
from typing import Literal

from pydantic import BaseModel, Field


class DisasterAdvisory(BaseModel):
    external_id: str = Field(min_length=1)      # dedup key from issuing authority
    hazard: Literal["FLOOD", "LANDSLIDE", "CYCLONE", "STORM",
                    "EARTHQUAKE", "OTHER"]
    severity: Literal["INFO", "LOW", "MEDIUM", "HIGH", "CRITICAL"]
    title: str
    summary: str | None = None
    state_code: str | None = None
    district_code: str | None = None
    issued_at: datetime
    expires_at: datetime | None = None
    authority: str                              # e.g. national/state disaster authority
    confidence: float = Field(0.7, ge=0, le=1)
