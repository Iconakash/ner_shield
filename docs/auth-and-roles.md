# NER-SHIELD — Auth & Roles

## Authentication flow (backend authoritative)

1. **Login:** `POST /api/v1/auth/login` `{email, password}` — server-side proxy
   of Supabase Auth. No role field. Wrong login → generic
   `UNAUTHENTICATED` (never reveals whether account exists). Repeated
   failures → `RATE_LIMITED` lockout (5 failures / 15 min).
2. **MFA (if enrolled):** First-factor session → `GET /auth/mfa/challenge`
   → `POST /auth/mfa/verify` `{factor_id, challenge_id, code}` → second
   `access_token`.
3. **Profile resolution:** `GET /auth/me` returns role, org, language,
   scopes, permissions — all resolved server-side from `profiles` +
   `role_permissions` + `user_geo_assignments`. The client stores this for
   UX filtering only.
4. **Session persistence:** Access tokens are short-lived; refresh token
   allows a new session. **Backend enforces ≤72h re-auth** (OFF-05).
   Client keeps tokens in secure storage (flutter_secure_storage), clears on
   logout.
5. **Logout:** `POST /auth/logout` stamps `token_revoked_at` server-side,
   invalidating every earlier token. Client then wipes local secrets.
6. **Account disabled:** Any request → 403 `FORBIDDEN_ROLE` ("account is
   disabled"). Client shows a clear message and signs out.

## Role comparison — PRD vs backend

| PRD persona | Backend role (authoritative) | Permissions granted by backend | Flutter experience |
|---|---|---|---|
| Super Admin | `SUPER_ADMIN` | everything incl. MANAGE_USERS, MANAGE_SYSTEM, VIEW_AUDIT_LOG | Full command center; all districts read; users/scope read only (provisioning stays web) |
| (Regional HQ) | `REGIONAL_AUTHORITY` | multi-state view/approve; ISSUE_ALERT; APPROVE_REROUTE; analytics | Region-wide dashboards; approve actions |
| District Admin | `DISTRICT_OFFICER` | scoped incident verification, alerts, shipment visibility own geography | District dashboard; validation queue; alerts |
| Transporter / Logistics | `LOGISTICS_OFFICER` | CREATE/MODIFY_SHIPMENT, GPS tracking, reroute request+approve | Shipments CRUD, vehicle view, routes, ETA |
| Field Officer | `FIELD_OFFICER` | VIEW_MAP/ROADS/INCIDENTS, CREATE_INCIDENT (field reports) | Quick incident capture, offline queue, my reports |
| Analyst / Citizen(read-only) | `ANALYST_VIEWER` | read-only dashboards, EXPORT_REPORT | Read-only analytics/views |
| Driver | — (no backend role) | n/a | **GAP** — a driver uses a FIELD_OFFICER/login provisioned to view a limited trip; documented |
| Citizen | — (no backend role) | n/a | **GAP** — no citizen sign-up in backend; documented |

## Frozen permission codes (seen in reference)

`VIEW_MAP` · `CREATE_INCIDENT` · `VERIFY_INCIDENT` · `VIEW_INCIDENTS` ·
`VIEW_SHIPMENTS` · `MODIFY_SHIPMENT` · `REQUEST_REROUTE` · `APPROVE_REROUTE` ·
`ISSUE_ALERT` · `MANAGE_USERS` · `MANAGE_SYSTEM` · `VIEW_AUDIT_LOG` ·
`EXPORT_REPORT`

## Geographic scope model

`user_geo_assignments`: `REGION ⊇ STATE ⊇ DISTRICT`. Enforcement at API layer
(`ensure_geo_scope`) AND RLS. Client shows only what `/auth/me` reports as
scoped; hides nothing as a security boundary.

## Two-person rules (never bypass in UI)

- `EMERGENCY_REROUTE`, `MAJOR_SUPPLY_REDISTRIBUTION`,
  `CRITICAL_LOGISTICS_STATUS`: requester ≠ approver.
- `HIGH_LEVEL_ALERT`: draft (CREATE_ALERT) vs publish (ISSUE_ALERT).
- Task verification: assignee can complete but never verify own work.

## Client-side UX guardrails

- Never render an action for a role that lacks the permission code.
- On `FORBIDDEN_ROLE` / `FORBIDDEN_SCOPE`, show a clear explanation + get in
  touch path — never a stack trace.
- `/auth/me` is refetched on app resume to catch role/status changes.