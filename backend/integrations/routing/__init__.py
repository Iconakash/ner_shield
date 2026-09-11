"""Routing provider abstraction + OSRM adapter (master upgrade §8/§10).

The EXISTING internal risk-aware graph engine (app/routing/*) remains the
default and is untouched. This package adds an optional external RoutingProvider
so distance/ETA/geometry can be supplied by a self-hosted or authorized OSRM
instance when deployment chooses ROUTING_PROVIDER=osrm. The public OSRM HTTP
API contract (GET {base}/route/v1/{profile}/{lon},{lat};...?alternatives=&...)
is documented at project-osrm.org — nothing here invents endpoints.
"""
