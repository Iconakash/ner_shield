"""Normalized route contracts shared by every RoutingProvider implementation."""
from datetime import datetime
import math

from pydantic import BaseModel, Field

# Loose NER-of-India bounding box (anti-misuse sanity check; lon,lat order).
NER_BBOX = (88.0, 21.5, 97.6, 29.6)   # lon_min, lat_min, lon_max, lat_max


class NormalizedRoute(BaseModel):
    """One provider-normalized route. Coordinates are (lon, lat) tuples."""
    provider: str
    distance_m: float = Field(ge=0)
    duration_s: float = Field(ge=0)
    geometry: list[tuple[float, float]] | None = None
    computed_at: datetime
    confidence: float = Field(0.5, ge=0, le=1)


class RouteContractError(ValueError):
    """Raised when an upstream payload cannot satisfy NormalizedRoute."""


def validate_lonlat(lon: float, lat: float) -> tuple[float, float]:
    """CRS/order guard: providers disagree on coordinate order; reject nonsense.
    Raises RouteContractError on impossible coordinates."""
    lon, lat = float(lon), float(lat)
    if not (math.isfinite(lon) and math.isfinite(lat)):
        raise RouteContractError("non-finite coordinate")
    if abs(lat) > 90 or abs(lon) > 180:
        # common lat,lon vs lon,lat transposition signature
        if abs(lon) <= 90 < abs(lat):
            raise RouteContractError(
                "coordinate order looks transposed (lat>90 as longitude?)")
        raise RouteContractError(f"coordinate out of range ({lon},{lat})")
    return lon, lat


def in_ner_bbox(lon: float, lat: float) -> bool:
    lon_min, lat_min, lon_max, lat_max = NER_BBOX
    return lon_min <= lon <= lon_max and lat_min <= lat <= lat_max