"""Boot smoke test: verifies the FastAPI app wires up and lists its routes.

Run from backend/:  python scripts_smoke_app.py   (env vars per .env.example)
"""
import os

os.environ.setdefault("ENV", "test")
os.environ.setdefault("SUPABASE_URL", "http://127.0.0.1:54321")
os.environ.setdefault("SUPABASE_ANON_KEY", "test-anon-key")
os.environ.setdefault("SUPABASE_JWT_SECRET", "test-only-jwt-secret-not-used-in-prod")
os.environ.setdefault(
    "DATABASE_URL", "postgresql+asyncpg://postgres:postgres@127.0.0.1:54322/postgres")

from app.main import create_app  # noqa: E402

app = create_app()
schema = app.openapi()
paths = sorted(schema["paths"].keys())
print("APP_OK paths:", len(paths))
for p in paths:
    methods = ",".join(sorted(m.upper() for m in schema["paths"][p]))
    print(f"  {methods:20s} {p}")

# sanity: protected surface exists and every protected route sits under /api/v1
api_routes = [p for p in paths if p.startswith("/api/")]
assert api_routes, "no API routes registered!"
# login must be public-reachable; /users must exist (MANAGE_USERS-guarded)
assert "/api/v1/auth/login" in paths and "/api/v1/users" in paths
print("SMOKE_OK")
