"""NER-SHIELD FastAPI application factory (security-first wiring).

Middleware order (outermost first):
    RequestContext -> SecurityHeaders -> RateLimit -> CORS -> routes
Authorization is NOT global middleware: it is the per-route dependency chain
(authentication -> account status -> permission -> geographic scope) so that
every protected endpoint declares its requirements explicitly (C-Authz).
"""
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from starlette.middleware.base import BaseHTTPMiddleware

from app.config import get_settings
from app.core.errors import install_error_handlers
from app.middleware.security import (
    BodySizeLimitMiddleware,
    MetricsMiddleware,
    RateLimitMiddleware,
    RequestContextMiddleware,
    SecurityHeadersMiddleware,
)

# Routes that need no bearer token. Everything else 401s at the dependency chain.
# /auth/login and /auth/mfa/verify authenticate via credentials/first-factor
# session themselves — demanding a bearer there would brick login (PHASE 26 fix).
PUBLIC_PATHS = {"", "/", "/health", "/health/ready", "/docs", "/openapi.json",
                "/api/v1/auth/login", "/api/v1/auth/mfa/verify",
                # Device-telemetry path authenticates with its own device
                # credentials (X-Device-*); a user bearer would be wrong there.
                "/api/v1/gps/ingest",
                # Aggregate operational counters only (no user data);
                # protect via network ACL in production.
                "/metrics",
                # Non-sensitive capability discovery used by the login page.
                "/api/v1/notifications/channels"}


class AuthGateMiddleware(BaseHTTPMiddleware):
    """Checkpoint 0: cheap presence-of-credentials gate for non-public paths.

    Full verification happens in get_principal(); this middleware only makes
    'no token at all' fail fast and uniformly. Returns the standard error
    envelope DIRECTLY — an exception raised here would bypass FastAPI's
    exception handlers (they sit inner) and surface as a misleading 500.
    """

    async def dispatch(self, request, call_next):
        path = request.url.path
        if path.startswith("/api/") and path not in PUBLIC_PATHS:
            if not request.headers.get("authorization", "").startswith("Bearer "):
                from fastapi.responses import JSONResponse

                from app.core.errors import Unauthenticated
                from app.core.request_context import get_request_id

                exc = Unauthenticated("authentication required")
                return JSONResponse(
                    status_code=exc.status_code,
                    content={"error": {"code": exc.code, "message": exc.message,
                                       "request_id": get_request_id(),
                                       "detail": None}})
        return await call_next(request)


def create_app() -> FastAPI:
    settings = get_settings()
    app = FastAPI(
        title="NER-SHIELD API",
        version="0.1.0",
        docs_url="/docs" if settings.ENV != "prod" else None,
        openapi_url="/openapi.json" if settings.ENV != "prod" else None,
    )

    # middleware: last added = outermost
    app.add_middleware(AuthGateMiddleware)
    app.add_middleware(BodySizeLimitMiddleware)
    app.add_middleware(RateLimitMiddleware)
    app.add_middleware(MetricsMiddleware)
    app.add_middleware(SecurityHeadersMiddleware)
    app.add_middleware(RequestContextMiddleware)
    app.add_middleware(
        CORSMiddleware,
        allow_origins=settings.CORS_ORIGINS,     # strict allowlist — no wildcards
        allow_credentials=False,                 # Bearer tokens, not cookies => CSRF-safe
        allow_methods=["GET", "POST", "PATCH", "PUT"],
        allow_headers=["Authorization", "Content-Type"],
        max_age=600,
    )

    install_error_handlers(app)

    from app.core.logging import setup_logging
    setup_logging(settings.LOG_LEVEL)

    from app.accessibility.router import router as accessibility_router
    from app.alerts.router import router as alerts_router
    from app.approvals.router import router as approvals_router
    from app.audit.router import router as audit_router
    from app.auth.router import router as auth_router
    from app.command.router import router as command_router
    from app.data_health.router import router as data_health_router
    from app.corridors.router import router as corridors_router
    from app.decisions.router import router as decisions_router
    from app.assistant.router import router as assistant_router
    from app.field.router import router as field_router
    from app.gis.router import router as gis_router
    from app.gps.router import router as gps_router
    from app.realtime.router import router as realtime_router
    from app.tasks.router import router as tasks_router
    from app.notifications.router import router as notifications_router
    from app.i18n.router import router as i18n_router
    from app.impact.router import router as impact_router
    from app.opsref.router import router as opsref_router
    from app.risk.router import router as risk_router
    from app.intel.router import router as intel_router
    from app.redundancy.router import router as redundancy_router
    from app.resilience.router import router as resilience_router
    from app.routing.router import router as routing_router
    from app.shipments.router import router as shipments_router
    from app.simulation.router import router as simulation_router
    from app.supply.router import router as supply_router
    from app.sync.router import router as sync_router
    from app.twin.router import router as twin_router
    from app.users.router import router as users_router
    # SIH26002 additions (P1-P8)
    from app.historical.router import router as historical_router
    from app.impactmetrics.router import router as impactmetrics_router
    from app.media.router import router as media_router
    from app.responders.router import router as responders_router
    from app.routehealth.router import router as routehealth_router

    for r in (auth_router, users_router, approvals_router, audit_router,
              field_router, opsref_router, gis_router, shipments_router,
              accessibility_router, risk_router, impact_router, supply_router,
              routing_router, alerts_router, sync_router, i18n_router,
              command_router, decisions_router, simulation_router,
              twin_router, resilience_router, redundancy_router,
              corridors_router, assistant_router, data_health_router,
              gps_router, tasks_router, notifications_router,
              realtime_router, intel_router,
              media_router, responders_router, routehealth_router,
              impactmetrics_router, historical_router):
        app.include_router(r, prefix="/api/v1")

    @app.get("/health")
    async def health():
        """Liveness: process is up. No dependency calls, no secrets."""
        return {"status": "ok"}

    @app.get("/health/ready")
    async def ready():
        """Readiness: critical dependencies checked. Returns per-dependency state,
        never secrets. A failing DB yields 503 so orchestrators gate correctly."""
        import time

        from sqlalchemy import text

        deps: dict[str, dict] = {}
        ok = True

        started = time.monotonic()
        try:
            from app.core.db import UserSession
            async with UserSession() as session:
                await session.execute(text("select 1"))
            deps["database"] = {"status": "up", "latency_ms":
                                round((time.monotonic() - started) * 1000, 1)}
        except Exception:  # noqa: BLE001 — readiness must not leak internals
            deps["database"] = {"status": "down"}
            ok = False

        deps["auth_provider"] = {
            "status": "configured" if (settings.SUPABASE_JWKS_URL
                                       or settings.SUPABASE_JWT_SECRET) else "unconfigured"}
        if deps["auth_provider"]["status"] == "unconfigured":
            ok = False

        body = {"status": "ready" if ok else "degraded",
                "env": settings.ENV,
                "data_mode": settings.DATA_MODE,
                "dependencies": deps}
        from fastapi.responses import JSONResponse
        return JSONResponse(status_code=200 if ok else 503, content=body)

    @app.get("/metrics")
    async def prometheus_metrics():
        """Operational counters/latencies (aggregate only — no user data).
        Network ACLs should restrict scraping to the monitoring system."""
        from fastapi.responses import PlainTextResponse

        from app.core import metrics
        return PlainTextResponse(metrics.render_prometheus(),
                                 media_type="text/plain; version=0.0.4")

    return app


app = create_app()

