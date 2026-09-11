"""Base integration adapter: timeout/retry/rate-limit/health for all sources."""
import asyncio
import logging
import time
from datetime import datetime, timezone

import httpx
from pydantic import BaseModel, Field

logger = logging.getLogger("ner-shield.integrations")


class SourceUnavailable(Exception):
    """Raised when a source cannot be reached OR is not authorized/configured.

    Callers must surface this as an explicit data-availability state — it is
    NEVER acceptable to substitute simulated data silently.
    """


class IntegrationConfig(BaseModel):
    name: str
    source_type: str                      # WEATHER | DISASTER | TRAFFIC | ROADS | GPS | SATELLITE | SUPPLY
    provider: str = "unassigned"
    endpoint: str | None = None           # None => not configured yet
    api_key_env: str | None = None        # env var NAME holding the credential
    enabled: bool = False                 # disabled until authorized + configured
    timeout_s: float = Field(10.0, gt=0)
    max_retries: int = Field(2, ge=0)
    retry_backoff_s: float = Field(1.0, gt=0)
    rate_limit_per_min: int = Field(60, ge=1)
    license_note: str | None = None


class AdapterHealth(BaseModel):
    name: str
    source_type: str
    provider: str
    status: str                            # HEALTHY | DEGRADED | UNAVAILABLE | DISABLED
    enabled: bool
    configured: bool                       # endpoint + credential present?
    last_success_at: datetime | None = None
    last_failure_at: datetime | None = None
    consecutive_failures: int = 0
    last_error: str | None = None
    confidence: float = 0.0                # decays with failures/staleness
    license_note: str | None = None


class BaseAdapter:
    """Shared machinery; concrete adapters implement _fetch_once() and normalize()."""

    def __init__(self, config: IntegrationConfig):
        self.config = config
        self._last_success_at: datetime | None = None
        self._last_failure_at: datetime | None = None
        self._consecutive_failures = 0
        self._last_error: str | None = None
        self._hit_times: list[float] = []

    # ------------------------------------------------------------- health
    def health(self) -> AdapterHealth:
        if not self.config.enabled:
            status = "DISABLED"
        elif not self.is_configured:
            status = "UNAVAILABLE"
        elif self._consecutive_failures == 0 and self._last_success_at:
            status = "HEALTHY"
        else:
            status = "DEGRADED" if self._last_success_at else "UNAVAILABLE"
        return AdapterHealth(
            name=self.config.name, source_type=self.config.source_type,
            provider=self.config.provider, status=status,
            enabled=self.config.enabled, configured=self.is_configured,
            last_success_at=self._last_success_at,
            last_failure_at=self._last_failure_at,
            consecutive_failures=self._consecutive_failures,
            last_error=self._last_error, confidence=self._confidence(),
            license_note=self.config.license_note)

    @property
    def is_configured(self) -> bool:
        return bool(self.config.endpoint)

    def _confidence(self) -> float:
        """Source confidence 0..1: failures decay it; staleness decays it."""
        if not self._last_success_at:
            return 0.0
        age_s = (datetime.now(timezone.utc) - self._last_success_at).total_seconds()
        staleness = max(0.0, 1.0 - age_s / 3600.0)          # fully stale after 1h
        reliability = max(0.0, 1.0 - 0.25 * self._consecutive_failures)
        return round(staleness * reliability, 3)

    # ------------------------------------------------------------- fetch
    async def fetch(self, **params):
        """Fetch + validate one batch of records from the upstream source.

        Raises SourceUnavailable when disabled/unconfigured/failed — callers
        translate that into explicit UNAVAILABLE states downstream.
        """
        if not self.config.enabled:
            raise SourceUnavailable(f"{self.config.name}: source not enabled "
                                    "(pending authorization/configuration)")
        if not self.is_configured:
            raise SourceUnavailable(f"{self.config.name}: endpoint not configured")
        if not self._rate_allow():
            raise SourceUnavailable(f"{self.config.name}: client-side rate limit reached")

        last_exc: Exception | None = None
        for attempt in range(self.config.max_retries + 1):
            try:
                raw = await self._fetch_once(**params)
                records = [self.normalize(r) for r in raw]
                self._last_success_at = datetime.now(timezone.utc)
                self._consecutive_failures = 0
                self._last_error = None
                logger.info("integration fetch ok", extra={"data": {
                    "source": self.config.name, "records": len(records)}})
                return records
            except SourceUnavailable:
                raise
            except Exception as exc:  # noqa: BLE001 — retries then explicit failure
                last_exc = exc
                self._last_failure_at = datetime.now(timezone.utc)
                self._consecutive_failures += 1
                self._last_error = str(exc)[:300]
                logger.warning("integration fetch failed", extra={"data": {
                    "source": self.config.name, "attempt": attempt + 1,
                    "error": self._last_error}})
                if attempt < self.config.max_retries:
                    await asyncio.sleep(self.config.retry_backoff_s * (attempt + 1))
        raise SourceUnavailable(f"{self.config.name}: upstream failed — {last_exc}")

    async def _fetch_once(self, **params):
        """One HTTP attempt. Override for non-HTTP or batched transports."""
        import os

        headers = {"User-Agent": "NER-SHIELD/1.0 (+government logistics platform)"}
        key_env = self.config.api_key_env
        if key_env:
            key = os.environ.get(key_env)
            if not key:
                raise SourceUnavailable(
                    f"{self.config.name}: credential env {key_env} not set")
            headers["Authorization"] = f"Bearer {key}"
        async with httpx.AsyncClient(timeout=self.config.timeout_s) as client:
            resp = await client.get(self.config.endpoint, params=params, headers=headers)
            resp.raise_for_status()
            return resp.json()

    def normalize(self, record: dict) -> dict:
        """Validate/coerce ONE upstream record into the internal schema.
        Must be deterministic and must NEVER invent observation values."""
        raise NotImplementedError

        """Source confidence 0..1: failures decay it; staleness decays it."""
        if not self._last_success_at:
            return 0.0
        age_s = (datetime.now(timezone.utc) - self._last_success_at).total_seconds()
        staleness = max(0.0, 1.0 - age_s / 3600.0)          # fully stale after 1h
        reliability = max(0.0, 1.0 - 0.25 * self._consecutive_failures)
        return round(staleness * reliability, 3)

    # ------------------------------------------------------------- rate limit
    def _rate_allow(self) -> bool:
        now = time.monotonic()
        self._hit_times = [t for t in self._hit_times if now - t <= 60]
        if len(self._hit_times) >= self.config.rate_limit_per_min:
            return False
        self._hit_times.append(now)
        return True


class LastKnownCache:
    """Phase 8 §8.1 provider cache — last successful normalized payload.

    Stores the records returned by the most recent successful fetch together
    with the retrieval instant. On an upstream failure the provider service may
    serve this copy EXPLICITLY labeled with its own age/availability band — it
    is never presented as live and never refreshed by anything but a real
    upstream success (no fabricated data, §8.2).

    A `max_age_s` budget bounds retention: beyond it `load()` returns None so
    the caller reports an explicit data gap instead of serving very old values.

    Most providers cache a single payload (omit `key`). Routing caches one
    route per coordinate set and passes a stable coordinate hash as `key` —
    both modes share the same age budget and expiry semantics.
    """

    _SINGLETON = "__default__"

    def __init__(self, max_age_s: float = 24 * 3600.0, max_records: int = 5000):
        self.max_age_s = max_age_s
        self.max_records = max_records
        # key -> (records, stored_at). One entry for the singleton providers;
        # one per coordinate set for routing.
        self._entries: dict[str, tuple[list[dict], datetime]] = {}

    def store(self, records: list[dict], *, key: str | None = None,
              at: datetime | None = None) -> None:
        """Replace the cached payload for `key` (records are already normalized)."""
        k = key or self._SINGLETON
        self._entries[k] = (list(records)[: self.max_records],
                             at or datetime.now(timezone.utc))

    def load(self, key: str | None = None) -> dict | None:
        """{'records', 'stored_at', 'age_s'} or None when empty/expired."""
        k = key or self._SINGLETON
        entry = self._entries.get(k)
        if entry is None:
            return None
        records, stored_at = entry
        age_s = (datetime.now(timezone.utc) - stored_at).total_seconds()
        if age_s > self.max_age_s:
            del self._entries[k]
            return None
        return {"records": list(records),
                "stored_at": stored_at,
                "age_s": round(age_s, 3)}

    def clear(self, key: str | None = None) -> None:
        if key is None:
            self._entries.clear()
        else:
            self._entries.pop(key, None)
