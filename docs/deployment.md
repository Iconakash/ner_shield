# NER-SHIELD V2 — Deployment Guide

This document is the authoritative reference for bringing the NER-SHIELD V2
production stack online. It covers the architecture, the secrets the owner
must supply, the local boot procedure, and the integration verification
matrix.

## 1. Architecture

```
┌────────────────────────────────┐
│  Android app (Flutter)         │
│  d:/NER-SHIELD-WORKSPACE/      │
│       ner_shield/               │
└───────────────┬────────────────┘
                │ HTTPS / HTTP API
                ▼
┌────────────────────────────────┐
│  FastAPI backend               │
│  d:/NER-SHIELD-WORKSPACE/      │
│       ner_shield/backend/       │
│  0.0.0.0:8000 in dev           │
└───────────────┬────────────────┘
                │ server-side, RLS-claim injection
                ▼
┌────────────────────────────────┐
│  Supabase project              │
│  rzmrjnegxgvnfgeuxaum          │
│  Postgres + PostGIS + Auth     │
└────────────────────────────────┘
```

The Flutter client **does not** import `supabase_flutter`. It talks only to
the FastAPI service over the `Dio` HTTP client. The Supabase URL and anon
key are not consumed by the Flutter code (`lib/core/config/app_config.dart`).

## 2. Secrets the project owner must supply

| Variable | Where to find it | Lives in |
|---|---|---|
| `SUPABASE_URL` | Project Settings → API → Project URL | `backend/.env` |
| `SUPABASE_ANON_KEY` | Project Settings → API → anon public | `backend/.env` |
| `SUPABASE_SERVICE_ROLE_KEY` | Project Settings → API → service_role | `backend/.env` |
| `SUPABASE_JWT_SECRET` | Project Settings → API → JWT Secret | `backend/.env` |
| `DATABASE_URL` | Project Settings → Database → pooler DSN | `backend/.env` |
| `SYSTEM_DATABASE_URL` | same; can reuse `DATABASE_URL` | `backend/.env` |

None of these values ever appear in the Flutter source, in `.env.example`,
in `git`, or in any HTTP response body.

## 3. Local development — step by step

```bash
cd d:/NER-SHIELD-WORKSPACE/ner_shield/backend
python -m venv .venv                       # first time only
.venv/Scripts/Activate.ps1
pip install -r requirements.txt             # first time only
cp .env.example .env
# edit .env — paste the six values from §2
./scripts/run_local.bat                     # Windows
```

Sanity checks:

```bash
curl http://127.0.0.1:8000/health           # {"status":"ok"}
curl http://127.0.0.1:8000/health/ready     # {"status":"ready",...}
curl http://127.0.0.1:8000/docs             # OpenAPI UI (dev only)
```

Flutter side (Android emulator):

```bash
cd d:/NER-SHIELD-WORKSPACE/ner_shield
flutter pub get
flutter run -d <emulator-id>                # default 10.0.2.2:8000
```

For a physical Android device on a LAN:

```bash
flutter run -d <device> --dart-define=API_BASE_URL=http://192.168.1.20:8000
```

## 4. Smoke + regression

```bash
# Backend — boot smoke (no DB needed)
cd backend
.venv/Scripts/python.exe smoke_app.py        # APP_OK + SMOKE_OK

# Backend — unit tests (no live DB needed)
.venv/Scripts/python.exe -m pytest -m "not integration" --no-header

# Flutter — analyzer + tests
cd ..
flutter analyze                             # No issues found!
flutter test                                # All tests passed!
```

## 5. RLS posture after this phase

| Table | State | Policy |
|---|---|---|
| `device_credentials` | RLS enabled, no policy | **Server-only by design** (holds `secret_hash`) |
| `gps_health` | RLS + SELECT policy | `USING (true)` (matches sister `gps_devices`) |
| `ml_feature_snapshots` | RLS + SELECT policy, FORCE | `USING (true)` |
| `ml_predictions` | RLS + SELECT policy, FORCE | `USING (true)` |
| `notification_deliveries` | RLS + SELECT policy | scoped via `notifications.user_id = app_current_user_id()` |
| `sync_devices` | RLS + SELECT policy | `user_id = app_current_user_id()` |
| `sync_ops_log` | RLS + SELECT policy | via `sync_devices.user_id = app_current_user_id()` |
| `sync_state` | RLS + SELECT policy | via `sync_devices.user_id = app_current_user_id()` |

Migration applied by this phase: `ns_v2_rls_remediation_2026_09_03`.
View `public.v_gis_summary` was rebuilt with `security_invoker = true`.

## 6. End-to-end integration status

| Flow | Status |
|---|---|
| FastAPI app boots + registers 126 routes | ✅ SMOKE_OK |
| FastAPI → Supabase (when DATABASE_URL set) | ⚠️ Requires owner-supplied DATABASE_URL |
| FastAPI → live query path with RLS | ⚠️ Requires owner-supplied DB + SERVICE_ROLE_KEY + JWT_SECRET |
| Flutter ↔ FastAPI on emulator | ⚠️ Requires backend running with the six secrets |
| Login, /auth/me, /auth/logout | ⚠️ Requires auth user in `auth.users` + matching `profiles` row |
| Dashboard, Alerts, Risk, Shipments, Emergency, Sync | ⚠️ Live-verify once auth works |
| SSE /realtime/stream | ⚠️ Live-verify once auth works |
| Push notifications (FCM) | ⏸ Deferred |
| External providers (weather, satellite, SMS, …) | ⏸ Deferred |
| iOS build | ⏸ Out of scope (Android-first) |
| Persistent offline queue (Drift/SQLite) | ⏸ Deferred (current queue in-memory) |

## 7. Exact next phase

The next phase is the owner-action-only chain: fill `backend/.env` with the
six secrets from §2, boot the backend, create a dedicated auth user + matching
`profiles` row (SQL below), then run `flutter run -d <android>` against the
running backend and confirm login + dashboard render real values.

## 8. Test-user provisioning (run once by the owner)

```sql
-- Step 1: in the Supabase dashboard, Authentication → Users → Add user
--         with a known email + a strong random password. Copy the user_id.

-- Step 2: in SQL Editor, with the user_id from step 1 substituted:
INSERT INTO public.profiles (
  user_id, email, full_name, role, org_id,
  is_active, mfa_enabled, language
) VALUES (
  '<USER_ID>',
  'test.field@ner-shield.invalid',
  'Test Field Officer',
  'FIELD_OFFICER',
  (SELECT id FROM public.organizations ORDER BY created_at LIMIT 1),
  true,
  false,
  'en'
);

-- Step 3: grant a geographic scope (one district):
INSERT INTO public.user_geo_assignments (user_id, level, state_code, district_code)
SELECT '<USER_ID>', 'DISTRICT', s.code, d.code
FROM public.states s, public.districts d
WHERE s.code = d.state_code
LIMIT 1;
```

FIELD_OFFICER inherits from the seeded `role_permissions`: `VIEW_MAP`,
`VIEW_ROADS`, `VIEW_INCIDENTS`, `CREATE_INCIDENT`, `VIEW_GPS` — the minimum
set to exercise the dashboard + report-incident flows without granting
administrative reach.