# NER-SHIELD V2 — FastAPI backend

This is the FastAPI service the new Android Flutter client talks to.
It is an **independent copy** of the original reference backend,
re-homed inside this project's workspace so deployment can be managed
alongside the Flutter client. The reference backend remains untouched.

```
Flutter (Android)
    │  HTTPS / HTTP API
    ▼
FastAPI (this service)  ── 0.0.0.0:8000 in dev
    │
    │  server-side database access
    ▼
Supabase PostgreSQL  +  Supabase Auth
```

## What lives here

| Path | Purpose |
|---|---|
| `app/` | FastAPI application package (routers, services, security, DB, realtime bus, sync engine, …) |
| `tests/` | Unit + integration tests |
| `smoke_app.py` | Boot-time check that wires up the app and lists every route. No DB connection required. |
| `pytest.ini` | Pytest config |
| `requirements.txt` | Python dependencies (pins are minimums observed working on Python 3.14) |
| `.env.example` | Server-side environment variable **names only**. Copy to `.env` and fill in real values from the live Supabase dashboard. |
| `scripts/run_local.sh` / `scripts/run_local.bat` | Local uvicorn launcher (binds `0.0.0.0:8000`) |

## Quick start (local boot, no DB required)

```bash
python -m venv .venv
.venv\Scripts\activate            # Windows
pip install -r requirements.txt
python smoke_app.py              # confirms the app wires up + lists all routes
```

## Local run against the live Supabase project

```bash
cp .env.example .env
# edit .env: paste real SUPABASE_URL, SUPABASE_ANON_KEY,
# SUPABASE_SERVICE_ROLE_KEY, SUPABASE_JWT_SECRET, DATABASE_URL
python -m uvicorn app.main:app --host 0.0.0.0 --port 8000
```

Then the Flutter app can reach it at:

| From | URL |
|---|---|
| Android emulator on the host | `http://10.0.2.2:8000/api/v1` |
| Physical Android device on LAN | `http://<host LAN IP>:8000/api/v1` |
| Web / curl on the host | `http://127.0.0.1:8000/api/v1` |

## Health

```
GET /health        liveness — no dependency calls
GET /health/ready  readiness — verifies DB + auth-provider config
```

## Security

- Service-role key + DB password + JWT secret live server-side only.
  The `.env` file is gitignored; `.env.example` carries placeholders.
- The Flutter client does **not** import any backend secret.
  It authenticates via `POST /api/v1/auth/login` (server-side proxy of
  Supabase Auth) and receives a short-lived bearer.
- All `/api/v1/*` routes are authenticated except the documented public set
  (`/auth/login`, `/auth/mfa/verify`, `/gps/ingest`, `/notifications/channels`,
  `/health`, `/health/ready`, `/metrics`, `/docs`, `/openapi.json`).
- RLS is enforced end-to-end: every user request opens a session with the
  verified JWT claims injected as Postgres GUCs, so policies see them.

## Secrets required to start

The owner must supply these from the Supabase project dashboard
(`https://supabase.com/dashboard/project/rzmrjnegxgvnfgeuxaum/settings/api`
and `/settings/database`):

```
SUPABASE_URL
SUPABASE_ANON_KEY
SUPABASE_SERVICE_ROLE_KEY
SUPABASE_JWT_SECRET          (or SUPABASE_JWKS_URL for asymmetric RS256)
DATABASE_URL                 (the project's pooler DSN)
SYSTEM_DATABASE_URL          (optional; defaults to DATABASE_URL)
```

The values are written into `.env`, which is in `.gitignore`.