"""RoutingProvider interface + OSRM implementation.

OSRMProvider composes BaseAdapter machinery (timeout/retry/backoff/client-side
rate limit/health/confidence) so route calls get identical protection to every
other external source. The default profile is `driving`; the base URL must be
deployment-supplied (self-hosted or authorized) — no public-server hard-coding.
"""
import logging
from abc import ABC, abstractmethod
from collections.abc import Sequence
from datetime import datetime, timezone

from integrations.base import IntegrationConfig, SourceUnavailable
from integrations.routing.schemas import (
    NormalizedRoute, RouteContractError, validate_lonlat)

logger = logging.getLogger("ner-shield.integrations.routing")

DEFAULT_CONFIG = IntegrationConfig(
    name="routing-osrm",
    source_type="ROADS",
    provider="OSRM",
    endpoint=None,
    api_key_env=None,
    enabled=False,
    rate_limit_per_min=60,
    license_note="Requires a self-hosted or authorized OSRM instance; ODbL "
                 "attribution applies when built on OpenStreetMap data.",
)


class RoutingProvider(ABC):
    """Provider-agnostic routing contract (master upgrade §8)."""

    name: str = "unassigned"

    @abstractmethod
    async def calculate_route(self, coordinates: Sequence[tuple[float, float]],
                              *, include_geometry: bool = True,
                              alternatives: bool = False) -> NormalizedRoute:
        """Best single route through `coordinates` ((lon,lat) order)."""

    async def calculate_alternative_routes(
            self, coordinates: Sequence[tuple[float, float]],
            *, include_geometry: bool = True) -> list[NormalizedRoute]:
        alt = await self.calculate_route(coordinates,
                                         include_geometry=include_geometry,
                                         alternatives=True)
        return [alt]

    async def calculate_distance_m(
            self, coordinates: Sequence[tuple[float, float]]) -> float:
        return (await self.calculate_route(coordinates,
                                           include_geometry=False)).distance_m

    async def calculate_eta_hours(
            self, coordinates: Sequence[tuple[float, float]]) -> float:
        return (await self.calculate_route(
            coordinates, include_geometry=False)).duration_s / 3600.0


class OSRMProvider(RoutingProvider):
    """Documented OSRM HTTP API (`GET /route/v1/driving/{lon},{lat};...`)."""

    def __init__(self, config: IntegrationConfig):
        from integrations.base import BaseAdapter

        self._base = BaseAdapter(config)
        self.name = config.provider

    @property
    def health(self):
        return self._base.health

    @property
    def config(self):
        return self._base.config

    async def _request(self, coords, *, alternatives: bool,
                       overview: bool) -> dict:
        import httpx

        cfg = self._base.config
        if not cfg.enabled:
            raise SourceUnavailable(f"{cfg.name}: routing provider not enabled")
        if not cfg.endpoint:
            raise SourceUnavailable(f"{cfg.name}: OSRM_BASE_URL not configured")
        if len(coords) < 2:
            raise RouteContractError("need at least two coordinates")
        validated = [validate_lonlat(lon, lat) for lon, lat in coords]
        coord_str = ";".join(f"{lon:.6f},{lat:.6f}" for lon, lat in validated)
        url = f"{cfg.endpoint.rstrip('/')}/route/v1/driving/{coord_str}"
        params: dict[str, str] = {
            "alternatives": "true" if alternatives else "false",
            "overview": "simplified" if overview else "false",
            "geometries": "geojson"}
        if not self._base._rate_allow():
            raise SourceUnavailable(f"{cfg.name}: rate limit reached")
        last_exc: Exception | None = None
        for attempt in range(cfg.max_retries + 1):
            try:
                async with httpx.AsyncClient(timeout=cfg.timeout_s) as client:
                    resp = await client.get(
                        url, params=params, headers={"User-Agent": "NER-SHIELD/1.0"})
                resp.raise_for_status()
                payload = resp.json()
                code = payload.get("code", "Ok") if isinstance(payload, dict) \
                    else "Ok"
                if code != "Ok":
                    raise RuntimeError(f"OSRM code={code}")
                self._base._consecutive_failures = 0
                self._base._last_success_at = datetime.now(timezone.utc)
                self._base._last_error = None
                return payload
            except SourceUnavailable:
                raise
            except Exception as exc:  # noqa: BLE001 — retried then explicit
                last_exc = exc
                self._base._last_failure_at = datetime.now(timezone.utc)
                self._base._consecutive_failures += 1
                self._base._last_error = str(exc)[:300]
                logger.warning("osrm request failed", extra={"data": {
                    "attempt": attempt + 1, "error": self._base._last_error}})
                if attempt < cfg.max_retries:
                    import asyncio
                    await asyncio.sleep(cfg.retry_backoff_s * (attempt + 1))
        raise SourceUnavailable(f"{cfg.name}: upstream failed — {last_exc}")

    async def calculate_route(self, coordinates, *, include_geometry=True,
                              alternatives=False) -> NormalizedRoute:
        payload = await self._request(coordinates,
                                      alternatives=alternatives,
                                      overview=include_geometry)
        routes = payload.get("routes") or []
        if not routes:
            raise RouteContractError("OSRM returned zero routes")
        h = self._base.health()
        first = routes[0]
        try:
            geometry = None
            if include_geometry:
                raw = (first.get("geometry") or {}).get("coordinates") or []
                geometry = [(float(c[0]), float(c[1])) for c in raw] or None
            return NormalizedRoute(
                provider=self.config.provider,
                distance_m=float(first["distance"]),
                duration_s=float(first["duration"]),
                geometry=geometry,
                computed_at=datetime.now(timezone.utc),
                confidence=max(h.confidence, 0.1))
        except (KeyError, TypeError, ValueError) as exc:
            raise RouteContractError(f"malformed OSRM route: {exc}") from exc