# NER-SHIELD — Feature Matrix (living document)

Statuses: `Planned` · `Analyzing` · `Implementing` · `Implemented` · `Tested`
· `Backend unavailable` · `External provider required` · `Blocked` ·
`Not applicable`

> **Live Supabase audit (2026-09-02):** the MCP-connected live project is
> empty (0 tables / 0 policies / 0 buckets / 0 users; PostGIS missing) — every
> live integration row below stays pending the backend provisioning pass
> (L-01). See `docs/live-supabase-integration-audit.md` and
> `docs/backend-integration-issues.md`.

| Feature | PRD | Backend | API | Role | Realtime | Offline | UI | Status |
|---|---|---|---|---|---|---|---|---|
| Auth — password login | ✔ | ✔ | `/auth/login` | all | — | — | Landing→Login | Planned |
| Auth — MFA (TOTP) | ✔ | ✔ | `/auth/mfa/*` | all | — | — | MFA screen | Planned |
| Auth — session restore | ✔ | ✔ | `/auth/me` + refresh | all | — | — | Splash | Planned |
| Auth — logout/revoke | ✔ | ✔ | `/auth/logout` | all | — | — | Profile | Planned |
| Role resolution shell | ✔ | ✔ | `/auth/me` | all | — | — | Shell switch | Planned |
| Dashboard KPI tiles | ✔ | ✔ | `/command/summary` | VIEW_MAP | SSE refresh | cache | Dashboard | Implemented |
| Dashboard charts | ✔ | partial | `/historical/*`,`/impact/*` | analyst | — | cache | Charts | Backend partial |
| GIS map + layers | ✔ | ✔ | `/gis/*`, `/command/layers/*` | VIEW_MAP | — | tile cache | Map | Implemented |
| Segment detail + risk explain | ✔ | ✔ | `/risk/{id}/explain` | VIEW_MAP | SSE | cache | Bottom sheet | Planned |
| Incident report (field) | ✔ | ✔ | `/field/reports` | CREATE_INCIDENT | — | queued | 5-step wizard | Implemented |
| Incident validation | ✔ | ✔ | `/field/reports/queue`,`/validate` | VERIFY_INCIDENT | SSE | cache | List+detail | Planned |
| Incident media upload (P1) | ✔ | ✔ | `/field/reports/{id}/media` | CREATE_INCIDENT | — | queued | Camera | Planned |
| Reporter trust (P2) | ✔ | ✔ | `/field/reporters/{id}/trust` | verify/self | — | cache | Detail card | Planned |
| Shipments CRUD | ✔ | ✔ | `/shipments` | MODIFY_SHIPMENT | SSE | queued | CRUD | Planned |
| Vehicle tracking | ✔ | ✔ | `/shipments/{id}/location`,`/sync/push` GPS_PING | LOGISTICS | SSE gps | queued pings | Trip view | Planned |
| Predictive ETA | ✔ | ✔ | `/shipments/{id}/eta` | VIEW_SHIPMENTS | SSE | cache | Card | Planned |
| Risk-aware routing | ✔ | ✔ | `/routing/plan`,`/routing/modes`,`/risk/why-route/{id}` | VIEW_MAP | — | cache | Ranked plan list + WHY cards | Tested (plan; multi-stop pending) |
| Route health / gaps (P5) | ✔ | ✔ | `/routes/health*` | VIEW_MAP | — | cache | Cards | Backend partial |
| Alerts inbox | ✔ | ✔ | `/alerts/inbox` | scoped | SSE alert | cache | Inbox | Planned |
| Alerts acknowledge/resolve | ✔ | ✔ | `/alerts/{id}/*` | scoped | — | queued | Inbox | Planned |
| Notifications + prefs | ✔ | ✔ | `/notifications/*` | all | — | cache | Settings | Planned |
| Push (WEB_PUSH/FCM) | ✔ | partial | `/notifications/devices` | all | — | — | Settings | External provider required |
| Data source health | ✔ | ✔ | `/data-health` | VIEW_MAP | SSE data-health | cache | Health screen | Planned |
| i18n (en/hi/as/mni) | ✔ | ✔ | `/i18n/*` | all | — | per-lang cache | l10n | Planned |
| Tasks (Action Center) | ✔ | ✔ | `/tasks/*` | scoped | SSE task | cache | Task list | Planned |
| Emergency command layers | ✔ | ✔ | `/command/layers/*` | VIEW_MAP | SSE | cache | Command Center | Planned |
| Emergency routing mode | ✔ | ✔ | `/routing` mode=emergency | VIEW_MAP | — | cache | Routing | Planned |
| Supply heatmap (P6) | ✔ | ✔ | `/supply/heatmap` | VIEW_MAP | — | cache | Map layer | Backend partial |
| Impact analytics (P7) | ✔ | ✔ | `/impact/*` | analyst | — | cache | Analytics | Planned |
| Historical validation (P4) | ✔ | ✔ | `/historical/*` | analyst | — | cache | Analytics | Backend partial |
| Decision intelligence (intel) | ✔ | ✔ | `/intel/*` | VIEW_MAP | SSE | cache | Cards | Backend partial |
| Responder auto-alert (P3) | ✔ | ✔ | `/responders/*` | MANAGE_SYSTEM | SSE | cache | Response task | Backend partial |
| Satellite evidence | ✔ | partial | `/intel/*`, evidence tables | VIEW_MAP | — | cache | Evidence viewer | Backend partial |
| Offline sync queue | ✔ | ✔ | `/sync/*` | FIELD_OFFICER | — | ✔ core | Sync status | Tested (queue lifecycle + policy flush) |
| Connectivity-aware gating | ✔ | ✔ | `/sync/policy` | all | — | ✔ | Sync status | Tested |
| Citizens portal | ✔ | ✘ | — | — | — | — | — | Backend unavailable |
| Driver lightweight app | ✔ | ✘ | — | — | — | — | — | Backend unavailable |
| OTP login | ✔ | ✔ (server-side) | `/auth/login` | all | — | — | Login | Backend partial |
| WhatsApp/SMS client channel | ✔ | config | `/notifications/channels` | all | — | — | Settings | External provider required |
| Mapbox premium layer | optional | config | — | VIEW_MAP | — | — | Map | External provider required |

## Never ship

- Faked risk scores / predictions
- Fabricated logistics state
- Hardcoded route ETAs
- Mock "live" vehicle positions presented without DEMO label