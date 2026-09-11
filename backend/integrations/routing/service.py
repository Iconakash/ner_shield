"""Routing service: optional external provider slot.

The existing internal risk-aware graph engine (app/routing/service.py) remains
the DEFAULT and is never modified by this module. When deployment sets
ROUTING_PROVIDER=osrm + OSRM_BASE_URL, this service exposes the RoutingProvider
contract for callers that explicitly opt into external routing.

Phase 8 (§8.1-§8.2): the last successfully computed route is cached per
coordinate set. On a provider failure calculate_route still raises
SourceUnavailable (the existing contract — callers fall back to the internal
engine), and a stale route is NEVER silently substituted for navigation
(safety). Degraded-mode consumers instead call last_known_route() explicitly,
which returns the cached route with an honest degraded label + age.
"""
from integrations.base import IntegrationConfig, LastKnownCache, SourceUnavailable
from integrations.routing.providers import OSRMProvider
from integrations.routing.schemas import NormalizedRoute

_provider: OSRMProvider | None = None
_route_cache = LastKnownCache()


def get_provider() -> OSRMProvider | None:
    """Configured external provider, or None when using internal routing."""
    return _provider


def cache() -> LastKnownCache:
    """Phase 8 — direct access for tests/ops (store/clear last-known routes)."""
    return _route_cache


def reconfigure(config: IntegrationConfig | None) -> None:
    global _provider
    _provider = OSRMProvider(config) if config is not None else None


def is_external_enabled() -> bool:
    return (_provider is not None and _provider.config.enabled
            and bool(_provider.config.endpoint))


def _route_key(coordinates) -> str:
    """Stable key for a coordinate set (lon,lat order, 6-dp)."""
    return ";".join(f"{float(lon):.6f},{float(lat):.6f}" for lon, lat in coordinates)


async def calculate_route(coordinates, **kw) -> NormalizedRoute:
    if not is_external_enabled():
        raise SourceUnavailable(
            "routing-osrm: external routing disabled "
            "(ROUTING_PROVIDER != osrm or OSRM_BASE_URL unset)")
    route = await _provider.calculate_route(coordinates, **kw)
    # §8.1 — cache the last successful normalized route per coordinate set.
    _route_cache.store([route.model_dump(mode="json")], key=_route_key(coordinates))
    return route


def last_known_route(coordinates) -> dict | None:
    """§8.2 degraded-mode accessor: the last route computed for these
    coordinates, or None. Returned with an explicit `delivery:
    cache-fallback` label and the cache age — never presented as live and
    never fabricated. Callers choose this consciously; it is not a silent
    substitute for calculate_route (a stale route must not drive navigation).
    """
    cached = _route_cache.load(key=_route_key(coordinates))
    if cached is None:
        return None
    route = NormalizedRoute(**cached["records"][0])
    age_min = cached["age_s"] / 60.0
    if age_min <= 60:
        availability = "RECENT"
    elif age_min <= 360:
        availability = "STALE"
    else:
        availability = "EXPIRED"
    return {"route": route, "delivery": "cache-fallback",
            "availability": availability, "cache_age_s": cached["age_s"]}


async def calculate_alternative_routes(coordinates, **kw):
    if not is_external_enabled():
        raise SourceUnavailable(
            "routing-osrm: external routing disabled "
            "(ROUTING_PROVIDER != osrm or OSRM_BASE_URL unset)")
    return await _provider.calculate_alternative_routes(coordinates, **kw)


async def calculate_distance_m(coordinates) -> float:
    route = await calculate_route(coordinates, include_geometry=False)
    return route.distance_m


async def calculate_eta_hours(coordinates) -> float:
    route = await calculate_route(coordinates, include_geometry=False)
    return route.duration_s / 3600.0