"""Satellite scene schema — internal normalized contract (metadata only).
Large imagery NEVER enters PostgreSQL: artifacts go to object storage and are
referenced by storage_path (master upgrade §13/§28)."""
from datetime import datetime

from pydantic import BaseModel, Field


class SatelliteScene(BaseModel):
    external_id: str = Field(min_length=1)
    provider: str
    license: str | None = None
    acquired_at: datetime                       # true acquisition time
    coverage_bbox: list[float] | None = Field(
        None, min_length=4, max_length=4)       # [lon_min, lat_min, lon_max, lat_max]
    resolution_m: float | None = Field(None, gt=0)
    cloud_cover_pct: float | None = Field(None, ge=0, le=100)
    bands: list[str] = Field(default_factory=list)
    storage_path: str | None = None             # object-storage key, not DB blob
    source_url: str | None = None
