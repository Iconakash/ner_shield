"""Error envelope + exception types (architecture §6 contract)."""
from app.core.request_context import get_request_id


class AppError(Exception):
    status_code = 400
    code = "VALIDATION_ERROR"

    def __init__(self, message: str = "", detail: dict | None = None):
        super().__init__(message or self.code)
        self.message = message or self.code
        self.detail = detail


class Unauthenticated(AppError):
    status_code, code = 401, "UNAUTHENTICATED"


class AccountDisabled(AppError):
    status_code, code = 403, "FORBIDDEN_ROLE"
    def __init__(self): super().__init__("account is disabled")


class ForbiddenRole(AppError):
    status_code, code = 403, "FORBIDDEN_ROLE"


class ForbiddenScope(AppError):
    status_code, code = 403, "FORBIDDEN_SCOPE"


class NotFound(AppError):
    status_code, code = 404, "NOT_FOUND"


class Conflict(AppError):
    status_code, code = 409, "CONFLICT"


class RateLimited(AppError):
    status_code, code = 429, "RATE_LIMITED"


def install_error_handlers(app) -> None:
    from fastapi import Request
    from fastapi.responses import JSONResponse
    from fastapi.exceptions import RequestValidationError

    def _envelope(code: str, message: str, detail=None, status: int = 400):
        return JSONResponse(
            status_code=status,
            content={"error": {"code": code, "message": message,
                               "request_id": get_request_id(), "detail": detail}},
        )

    @app.exception_handler(AppError)
    async def _app_error(_: Request, exc: AppError):
        return _envelope(exc.code, exc.message, exc.detail, exc.status_code)

    @app.exception_handler(RequestValidationError)
    async def _validation(_: Request, exc: RequestValidationError):
        return _envelope("VALIDATION_ERROR", "request validation failed",
                         {"errors": exc.errors()}, 400)

    @app.exception_handler(Exception)
    async def _unhandled(_: Request, exc: Exception):
        # Never leak internals (SEC / information-disclosure)
        return _envelope("INTERNAL", "internal server error", None, 500)
