"""Database engines and per-request RLS claim propagation (architecture §9.1).

Two pools:
  * user pool   — every request; claims injected per transaction so RLS applies.
  * system pool — audited admin/system paths only (login attempt writes, approval
    transitions). Prod must run it under a minimally-privileged role.
"""
from typing import AsyncIterator

from sqlalchemy import text
from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker, create_async_engine

from app.config import get_settings

_settings = get_settings()


def _make_engine(url: str):
    return create_async_engine(url, pool_pre_ping=True, future=True)


user_engine = _make_engine(_settings.DATABASE_URL)
system_engine = (
    _make_engine(_settings.SYSTEM_DATABASE_URL)
    if _settings.SYSTEM_DATABASE_URL else user_engine
)

UserSession = async_sessionmaker(user_engine, expire_on_commit=False)
SystemSession = async_sessionmaker(system_engine, expire_on_commit=False)

_CLAIMS_SQL = text("select set_config('request.jwt.claims', :claims, true)")
_SUB_SQL = text("select set_config('request.jwt.claim.sub', :sub, true)")


async def get_db(request=None) -> AsyncIterator[AsyncSession]:
    """User-scoped session. Injects the verified JWT claims so RLS policies see them."""
    from app.core.request_context import get_jwt_claims

    claims = get_jwt_claims() or {}
    import json
    async with UserSession() as session:
        async with session.begin():
            await session.execute(_CLAIMS_SQL, {"claims": json.dumps(claims)})
            if claims.get("sub"):
                await session.execute(_SUB_SQL, {"sub": str(claims["sub"])})
            yield session


async def get_system_db() -> AsyncIterator[AsyncSession]:
    """System-scoped session for audited security-critical paths ONLY (C-Audit)."""
    async with SystemSession() as session:
        async with session.begin():
            yield session
