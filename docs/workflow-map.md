# NER-SHIELD — Workflow Map

> How the product flows from launch to logout, per role. Each workflow names
> the backend APIs that back it. Gaps between PRD and backend are flagged as
> [GAP].

## 0. Launch → Session restore

1. App start → splash.
2. Read secure storage: refresh token present?
   - No → Landing → Login.
   - Yes → optionally refresh access token → `GET /auth/me`.
3. If `/auth/me` succeeds → resolve role/scopes → route to role shell.
4. If 401 (expired/revoked) → clear storage → Login with reason.

## 1. Login

1. Email + password (min 8 chars; server validates).
2. On success → if `mfa_enabled` → MFA challenge → verify TOTP.
3. Fetch `/auth/me` → role, permissions, scopes.
4. Persist refresh/access tokens securely.
5. Navigate to role shell (`/ops` (all roles) → dashboard per role).

## 2. Role shells

- `SUPER_ADMIN` / `REGIONAL_AUTHORITY`: Command Center → Analytics → Users(read)
  → Audit → Data Health.
- `DISTRICT_OFFICER`: District Dashboard → Incidents (validation) → Alerts →
  Shipments → Tasks → Reports.
- `LOGISTICS_OFFICER`: Shipments → Routing → Vehicles → Alerts → Tasks.
- `FIELD_OFFICER`: Quick Report → My Reports → Map → Alerts → Tasks.
- `ANALYST_VIEWER`: Analytics → Reports (export) → Map (view).

## 3. Dashboard

- `/command/summary` → six KPI tiles (RLS-scoped).
- Data freshness label from `/data-health` + `/command/summary.generated_at`.

## 4. Map

- `/gis/states`, `/gis/districts`, `/gis/segments`, `/gis/roads`,
  `/gis/facilities`, `/gis/railways`, `/gis/waterways`.
- `/command/layers/{high-risk-roads|disruptions|shipments|weather}`.
- `/risk/latest` + `/accessibility/segments` overlays.
- Tap segment → detail bottom sheet → risk explain.

## 5. Incident reporting (field)

1. Quick Report button → form.
2. `GET /i18n/field-schema?lang=` (labels translated, cached per lang).
3. Type, severity, location (GPS or map tap), photo capture/compress, note.
4. If online → `POST /field/reports` (+ optional media `POST .../media`).
5. If offline → enqueue local draft (client_op_id), status `PENDING`.
6. On reconnect → `POST /sync/push` (FIELD_REPORT op) → EXCELLENT/GOOD class
   required otherwise remains queued → ACK shows SYNCED; failure shows reason.
7. My reports list (`GET /field/reports/mine`) + detail with confidence.

## 6. Incident validation (district officer)

1. `/field/reports/queue` → list (SUBMITTED).
2. Open detail (`/field/reports/{id}/detail`) incl. media signed URL.
3. Validate/reject (`POST /field/reports/{id}/validate`).

## 7. Routing

1. Choose origin/destination (facility code or lon/lat).
2. `POST /routing/plan` (mode, risk_aversion, k) → ranks routes.
3. Show alternatives with distance/ETA/risk; `mode=emergency` when flagged.
4. Assign route to shipment (`/shipments/{id}/assign-route`) — advisory only.

## 8. Shipments (logistics)

1. List `/shipments` → detail.
2. Create `POST /shipments` → assign vehicle → assign route → start →
   location pings (GPS) → status updates → ETA (`GET /shipments/{id}/eta`)
   → confirm delivery (CRITICAL → approval workflow required).

## 9. Alerts & notifications

1. `/alerts/inbox` (localized by `?lang=`).
2. Acknowledge `POST /alerts/{id}/acknowledge`, Resolve `POST .../resolve`.
3. Push: register device `POST /notifications/devices` (WEB_PUSH).
4. `/notifications` inbox + ack.
5. Realtime SSE delivers live alerts (permission filtered).

## 10. Emergency

- Command Center layers + `/intel/hazards` + decision cards.
- Emergency routing mode; escalation sweep is backend driven.
- [GAP] PRD "Emergency Mode dashboard" maps to Command Center + Emergency
  route mode — no distinct backend `emergency_mode` module.

## 11. Tasks

- `/tasks/mine`, `/tasks/{id}`; create/assign/transition as authorized.

## 12. Reports / analytics (analyst + admins)

- `/command/summary`, `/impact/summary|metrics`, `/supply/heatmap`,
  `/routes/health`, `/historical/...`, export via `EXPORT_REPORT`.

## 13. Offline queue sync

Covered in `offline-strategy.md` — push/pull with connectivity gating.

## 14. Logout

`POST /auth/logout` → clear secure storage → Landing.

## PRD flows the backend does not expose (GAPs)

| PRD flow | Backend reality | Resolution |
|---|---|---|
| Citizen sign-up/read-only portal | No CITIZEN role | Not built; documented in backend-integration-issues.md |
| Driver lightweight app | No DRIVER role | Field-officer-scoped trip view; documented |
| OTP login (email/phone OTP) | Password grant only (Supabase may allow magic links but login proxy uses password) | Email+password; note as limitation |
| WhatsApp/SMS alert channel from client | Channels configurable server-side (`/notifications/channels`); client only lists configured | Client renders available channels only |
| Mapbox/Bhuvan layers | OSM tiles (`OSM_TILE_URL`) | flutter_map with OSM; provider interface for others |