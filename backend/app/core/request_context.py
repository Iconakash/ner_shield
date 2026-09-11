"""Per-request context: request id + verified JWT claims (contextvar-based)."""
from contextvars import ContextVar
from uuid import uuid4

_request_id: ContextVar[str] = ContextVar("request_id", default="-")
_jwt_claims: ContextVar[dict] = ContextVar("jwt_claims", default={})


def new_request_id() -> str:
    rid = uuid4().hex
    _request_id.set(rid)
    return rid


def get_request_id() -> str:
    return _request_id.get()


def set_jwt_claims(claims: dict) -> None:
    _jwt_claims.set(claims or {})


def get_jwt_claims() -> dict:
    return _jwt_claims.get()
