# NER-SHIELD — Backend Contract (authoritative)

> Derived from the reference backend (`reference/old ner shild project/backend/`).
> This is the microservice contract the Flutter client is built against.

## 1. Transport & auth

- **Base URL:** `API_PUBLIC_URL` — default `http://localhost:8000` (dev).
  All data endpoints live under prefix **`/api/v1`**.
- **Auth header:** `Authorization: Bearer <access_token>` (Supabase-issued JWT,
  short-lived).
- **Public endpoints (no bearer):** `/health`, `/health/ready`, `/docs`,
  `/openapi.json`, `/api/v1/auth/login`, `/api/v1/auth/mfa/verify`,
  `/api/v1/gps/ingest` (device-credentials), `/metrics`,
  `/api/v1/notifications/channels`.
- **Body limits:** JSON/API ≤ 1 MiB; uploads ≤ 10 MiB.

## 2. Error envelope (every 4xx/5xx)

```json
{ "error": { "code": "...", "message": "...", "request_id": "...", "detail": null } }
```

| HTTP | code | Typical meaning |
|---|---|---|
| 401 | `UNAUTHENTICATED` | Bad credentials / expired token / revoked token |
| 403 | `FORBIDDEN_ROLE` | Missing permission, or account disabled |
| 403 | `FORBIDDEN_SCOPE` | Outside geographic scope |
| 404 | `NOT_FOUND` | Resource missing or out of scope |
| 409 | `CONFLICT` | State conflict (e.g., bad status transition) |
| 422 | `VALIDATION_ERROR` | Body invalid |
| 429 | `RATE_LIMITED` | Sliding-window rate limit / login lockout |
| 500 | `INTERNAL` | Generic server error (never leaks internals) |

## 3. Auth endpoints

| Method/Path | Body | Returns |
|---|---|---|
| `POST /api/v1/auth/login` | `{email, password}` | `{access_token, refresh_token, expires_in, ...}` (first-factor session; may be MFA-provisional) |
| `GET  /api/v1/auth/mfa/challenge` | — | `{factor_id, challenge_id, expires_at}` |
| `POST /api/v1/auth/mfa/verify` | `{factor_id, challenge_id, code}` | `{access_token, refresh_token, expires_in}` |
| `GET  /api/v1/auth/me` | — | `{user_id, email, role, org_id, language, scopes[], permissions[]}` |
| `POST /api/v1/auth/logout` | — | revokes token; `{ok:true}` |

Notes: No role field in login. Role/scope/permissions come from `/auth/me`
(server-enforced). MFA flow: login → `MFA_REQUIRED` hint → challenge → verify.

## 4. Core data endpoints (features)

### GIS (VIEW_MAP)
- `GET /gis/states` → GeoJSON FeatureCollection
- `GET /gis/districts?state_code=` → GeoJSON
- `GET /gis/locate?lon=&lat=` → `{state_code, district_code, operation}`
- `GET /gis/roads?state_code=&district_code=` → GeoJSON
- `GET /gis/segments?district_code=&status=` → GeoJSON
- `GET /gis/facilities?facility_type=&state_code=&near_lon=&near_lat=&radius_m=` → GeoJSON
- `GET /gis/railways`, `GET /gis/waterways` → GeoJSON
- `GET /gis/summary` → aggregate stats

### Command Center (VIEW_MAP)
- `GET /command/summary` → six KPI tiles (RLS-scoped)
- `GET /command/layers/{name}` → GeoJSON layers: `high-risk-roads`,
  `disruptions`, `shipments`, `weather`

### Accessibility (VIEW_MAP reads; MANAGE_SYSTEM writes)
- `GET /accessibility/segments?district_code=`
- `GET /accessibility/districts`
- `GET /accessibility/history?segment_id=&limit=`
- (Writes `signals` / `run` / `weights` are MANAGE_SYSTEM only)

### Risk / prediction (VIEW_MAP reads)
- `GET /risk/latest?district_code=`
- `GET /risk/{segment_id}/explain`
- `GET /risk/why-route/{shipment_id}?horizon=current|6h|12h|24h|72h` (VIEW_SHIPMENTS)

### Routing (VIEW_MAP)
- `GET /routing/modes` → machine-readable mode catalog
- `POST /routing/plan` → ranked routes (advisory only)
- `POST /routing/multi-stop` → multi-stop plan (advisory)

### Shipments (VIEW_SHIPMENTS / MODIFY_SHIPMENT)
- `GET /shipments` → list (RLS-scoped)
- `GET /shipments/{id}` → detail
- `POST /shipments` → create
- `POST /shipments/{id}/assign-vehicle`
- `POST /shipments/{id}/assign-route`
- `POST /shipments/{id}/location` (GPS ping via API)
- `POST /shipments/{id}/status`
- `GET /shipments/{id}/eta`
- `POST /shipments/{id}/confirm-delivery` (approval-gated for CRITICAL)

### Field intel (CREATE_INCIDENT / VERIFY_INCIDENT / VIEW_INCIDENTS)
- `POST /field/reports` → create (returns code, confidence)
- `GET /field/reports/queue` → validation queue
- `POST /field/reports/{id}/validate` → VALIDATED / REJECTED
- `GET /field/reports/mine` → my reports
- `GET /field/reports/{id}/detail` → report + confidence + media
- `GET /field/reporters/{id}/trust` → reporter trust ledger
- Media sub-routes: `POST/GET /field/reports/{id}/media`,
  `GET /field/reports/{id}/media/{mid}/url` (signed)

### Alerts (any authenticated reader of own role+scope)
- `GET /alerts/inbox?limit=&lang=`
- `POST /alerts` (MANAGE_SYSTEM — create)
- `POST /alerts/{alert_id}/acknowledge`
- `POST /alerts/{alert_id}/resolve`
- `POST /alerts/escalation-sweep` (MANAGE_SYSTEM)

### Notifications
- `GET /notifications/channels` (public)
- `POST /notifications/devices`
- `GET/PUT /notifications/preferences`
- `GET /notifications?unread_only=`
- `POST /notifications/acknowledge`

### Tasks (Action Center)
- `GET /tasks/mine`
- `GET /tasks/{task_id}`
- `POST /tasks` (REQUEST_REROUTE)
- `POST /tasks/{task_id}/assign` (APPROVE_REROUTE)
- `POST /tasks/{task_id}/transition`

### Sync
- `POST /sync/devices`
- `POST /sync/push` — ops `FIELD_REPORT`, `GPS_PING`; connectivity classes
  `EXCELLENT|GOOD|WEAK|VERY_WEAK|OFFLINE`
- `GET /sync/pull?cursor=`
- `GET /sync/policy`
- `GET /sync/status`

### Other read surfaces
- `GET /data-health` (VIEW_MAP)
- `GET /i18n/languages`, `GET /i18n/field-schema?lang=`
- `GET /impact/summary | /metrics`
- `GET /supply/heatmap[/{district}]`
- `GET /routes/health`, `/routes/health/gaps`, `/routes/health/{segment}`
- `GET /intel/hazards`, `GET /intel/decision-card/{segment_id}`
- `GET /historical/...` (validation runs)
- `GET /audit` (VIEW_AUDIT_LOG)
- `GET /users/{user_id}` (MANAGE_USERS)