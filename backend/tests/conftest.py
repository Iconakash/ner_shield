"""Shared pytest configuration.

Unit tests always run (no infra needed).
Integration tests (cross-role/cross-district attacks, RLS, audit immutability)
require a local Supabase stack: RUN_SECURITY_IT=1 supabase start ... && pytest -m integration
"""
import os
import pathlib
import time
import uuid

import jwt as pyjwt
import pytest

REPO_ROOT = pathlib.Path(__file__).resolve().parents[2]

TEST_SECRET = "test-only-jwt-secret-not-used-in-prod"

# Settings must resolve BEFORE app import; provide safe test defaults.
os.environ.setdefault("ENV", "test")
os.environ.setdefault("SUPABASE_URL", "http://127.0.0.1:54321")
os.environ.setdefault("SUPABASE_ANON_KEY", "test-anon-key")
os.environ.setdefault("SUPABASE_JWT_SECRET", TEST_SECRET)
os.environ.setdefault(
    "DATABASE_URL",
    "postgresql+asyncpg://postgres:postgres@127.0.0.1:54322/postgres")
os.environ.setdefault("CORS_ORIGINS", '["http://localhost:5500"]')

RUN_IT = os.environ.get("RUN_SECURITY_IT") == "1"

pytest_plugins = ("pytest_asyncio",)


def mint_token(user_id: str, secret: str = TEST_SECRET,
               minutes: int = 10, iat_offset: int = 0) -> str:
    """Mint an HS256 access token the way Supabase would (aud=authenticated)."""
    now = int(time.time()) + iat_offset
    return pyjwt.encode(
        {
            "sub": user_id, "email": f"{user_id}@test.local", "aud": "authenticated",
            "role": "authenticated", "iat": now, "exp": now + minutes * 60,
            "session_id": str(uuid.uuid4()),
        },
        secret, algorithm="HS256")


def auth_headers(token: str) -> dict:
    return {"Authorization": f"Bearer {token}"}


def sql_files() -> list[pathlib.Path]:
    d = REPO_ROOT / "database"
    files = []
    for sub in ("migrations", "functions", "policies", "seed"):
        files.extend(sorted((d / sub).glob("*.sql")))
    return files


@pytest.fixture(scope="session")
def anyio_backend() -> str:
    return "asyncio"
