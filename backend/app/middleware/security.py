"""Middleware: request-id/context, security headers, rate limiting, metrics.

Order (outermost first) set in main.py:
    RequestContext -> SecurityHeaders -> RateLimit -> Metrics -> CORS -> routes
"""
import time
from collections import defaultdict, deque

from starlette.middleware.base import BaseHTTPMiddleware
from starlette.responses import JSONResponse

from app.core import metrics
from app.core.request_context import get_request_id, new_request_id
from app.config import get_settings

_SECURE_HEADERS = {
    "X-Content-Type-Options": "nosniff",
    "X-Frame-Options": "DENY",
    "Referrer-Policy": "no-referrer",
    "Permissions-Policy": "geolocation=(self)",
    "Cross-Origin-Opener-Policy": "same-origin",
}
_CSP = ("default-src 'self'; img-src 'self' https://*.tile.openstreetmap.org data:; "
        "script-src 'self'; style-src 'self' 'unsafe-inline'; connect-src 'self'")


class RequestContextMiddleware(BaseHTTPMiddleware):
    async def dispatch(self, request, call_next):
        new_request_id()
        response = await call_next(request)
        response.headers["X-Request-ID"] = get_request_id()
        return response


class SecurityHeadersMiddleware(BaseHTTPMiddleware):
    async def dispatch(self, request, call_next):
        response = await call_next(request)
        for k, v in _SECURE_HEADERS.items():
            response.headers.setdefault(k, v)
        if request.url.path.endswith(".html") or request.url.path in ("/", ""):
            response.headers.setdefault("Content-Security-Policy", _CSP)
        if get_settings().ENV == "prod":
            response.headers.setdefault(
                "Strict-Transport-Security", "max-age=31536000; includeSubDomains")
        return response


class RateLimitMiddleware(BaseHTTPMiddleware):
    """Sliding-window per IP. /auth/login gets a much tighter bucket (login abuse)."""

    def __init__(self, app):
        super().__init__(app)
        self._hits: dict[str, deque] = defaultdict(deque)
        self._settings = get_settings()

    def _bucket_for(self, path: str) -> int:
        return 10 if path.startswith("/api/v1/auth/login") else self._settings.RATE_LIMIT_PER_MINUTE

    async def dispatch(self, request, call_next):
        if request.url.path.startswith("/health"):
            return await call_next(request)
        ip = request.client.host if request.client else "?"
        key = f"{ip}:{'login' if request.url.path.startswith('/api/v1/auth/login') else 'api'}"
        now = time.monotonic()
        window = self._hits[key]
        while window and now - window[0] > 60:
            window.popleft()
        limit = self._bucket_for(request.url.path)
        if len(window) >= limit:
            return JSONResponse(status_code=429,
                content={"error": {"code": "RATE_LIMITED", "message": "too many requests",
                                   "request_id": get_request_id(), "detail": None}},
                headers={"Retry-After": "60"})
        window.append(now)
        return await call_next(request)


class MetricsMiddleware(BaseHTTPMiddleware):
    """Per-route request count + latency (Phase 10 observability)."""

    async def dispatch(self, request, call_next):
        started = time.monotonic()
        response = await call_next(request)
        route = request.scope.get("route")
        # route templates keep label cardinality bounded (no raw ids)
        path = getattr(route, "path", None) or request.url.path
        labels = {"method": request.method, "path": path,
                  "status": str(response.status_code)}
        metrics.inc("ner_shield_http_requests_total", labels)
        metrics.observe("ner_shield_http_request_seconds",
                        time.monotonic() - started,
                        {"method": request.method, "path": path})
        if response.status_code == 401:
            metrics.inc("ner_shield_auth_failures_total",
                        {"path": path})
        return response


class BodySizeLimitMiddleware(BaseHTTPMiddleware):
    """Reject oversized requests BEFORE parsing (Phase 26 · DoS hardening).

    Trusts only the Content-Length header for the cheap pre-check; chunked
    bodies are additionally capped while streaming via max_request_size on
    the route layer where applicable. Health endpoints are exempt.
    """

    def __init__(self, app):
        super().__init__(app)
        self._limit = get_settings().MAX_BODY_BYTES

    async def dispatch(self, request, call_next):
        if request.url.path.startswith("/health"):
            return await call_next(request)
        declared = request.headers.get("content-length")
        if declared and declared.isdigit() and int(declared) > self._limit:
            return JSONResponse(status_code=413,
                content={"error": {"code": "PAYLOAD_TOO_LARGE",
                                   "message": "request body exceeds allowed size",
                                   "request_id": get_request_id(), "detail": None}})
        return await call_next(request)
