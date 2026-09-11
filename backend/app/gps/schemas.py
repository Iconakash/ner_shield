"""GPS telemetry schemas + PURE validators (unit-tested without infra).

Validation is server-side only; nothing from the device is trusted a priori.
"""
import hashlib
import json
from datetime import datetime, timezone

from pydantic import BaseModel, Field

# NER of India bounding box (generous operational envelope). Fixes outside it
# are REJECTED as probable spoofing rather than silently accepted.
NER_BBOX = {"lat_min": 21.5, "lat_max": 29.9, "lon_min": 87.5, "lon_max": 97.6}

# Clock-drift envelope for anti-replay: older than this = stale/replayed;
# too far in the future = bad clock or forgery.
MAX_PAST_DRIFT_S = 300
MAX_FUTURE_DRIFT_S = 60


class TelemetryIn(BaseModel):
    latitude: float = Field(ge=-90, le=90)
    longitude: float = Field(ge=-180, le=180)
    timestamp: datetime
    speed_kph: float | None = Field(None, ge=0, le=300)
    heading_deg: float | None = Field(None, ge=0, le=360)
    accuracy_m: float | None = Field(None, ge=0)
    battery_pct: float | None = Field(None, ge=0, le=100)
    signal_class: str | None = Field(None, max_length=16)


class DeviceRegistrationIn(BaseModel):
    label: str = Field(min_length=1, max_length=120)
    provider: str = Field(default="internal", max_length=60)
    model: str | None = Field(None, max_length=120)


def validate_coordinates(lat: float, lon: float) -> str | None:
    """Return a rejection reason, or None when the fix is plausible."""
    if not (NER_BBOX["lat_min"] <= lat <= NER_BBOX["lat_max"]
            and NER_BBOX["lon_min"] <= lon <= NER_BBOX["lon_max"]):
        return ("coordinates outside the North-Eastern Region operating "
                "envelope (possible spoofing)")
    return None


def validate_timestamp(ts: datetime, now: datetime | None = None) -> str | None:
    """Return a rejection reason, or None when the observation time is fresh."""
    now = now or datetime.now(timezone.utc)
    if ts.tzinfo is None:
        ts = ts.replace(tzinfo=timezone.utc)
    drift_s = (now - ts).total_seconds()
    if drift_s > MAX_PAST_DRIFT_S:
        return f"observation stale by {int(drift_s)}s (replay/stale buffer)"
    if drift_s < -MAX_FUTURE_DRIFT_S:
        return "observation timestamp in the future beyond clock skew"
    return None


def payload_hash(device_code: str, t: TelemetryIn) -> str:
    """Stable content hash for duplicate/replay detection at the storage layer."""
    canon = json.dumps({
        "d": device_code, "lat": round(t.latitude, 6),
        "lon": round(t.longitude, 6),
        "ts": t.timestamp.isoformat(),
        "spd": t.speed_kph, "hdg": t.heading_deg,
    }, sort_keys=True, separators=(",", ":"))
    return hashlib.sha256(canon.encode()).hexdigest()
