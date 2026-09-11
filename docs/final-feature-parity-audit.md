# NER-SHIELD — Final Feature Parity Audit (Phase 22)

| PRD feature | Backend exists | API exists | Flutter repo exists | State exists | UI exists | Wired | Tests | Auth verified | Offline verified | Realtime verified | Production-safe |
|---|---|---|---|---|---|---|---|---|---|---|---|
| Auth — password login | OK | OK | OK | OK | OK | OK | OK | OK | n/a | n/a | OK |
| Auth — MFA (TOTP) | OK | OK | OK | OK | OK | OK | OK | OK | n/a | n/a | OK |
| Auth — session restore | OK | OK | OK | OK | OK | OK | OK | OK | n/a | n/a | OK |
| Auth — logout / revoke | OK | OK | OK | OK | OK | OK | OK | OK | n/a | n/a | OK |
| Role resolution shell | OK | OK | OK | OK | OK | OK | OK | OK | n/a | n/a | OK |
| Dashboard KPI tiles | OK | OK | OK | OK | OK | OK | OK | OK | cache | SSE client ready | OK |
| Dashboard charts (historical/impact) | OK (P4/P7) | OK | OK | OK | partial | OK | OK | OK | cache | n/a | OK |
| GIS map + 10 layers | OK | OK | OK | OK | OK | OK | OK (23) | OK | offline tile cache | SSE planned | OK |
| Segment detail + risk explain | OK | OK | OK | OK | OK | OK | OK | OK | cache | SSE planned | OK |
| Incident report (5-step wizard) | OK | OK | OK | OK | OK | OK | OK (15) | OK | queued | n/a | OK |
| Incident validation | OK | OK | OK | OK | OK | OK | OK | OK | cache | SSE planned | OK |
| Incident media upload | OK | OK | OK | n/a | UI stub | n/a | n/a | OK | queued | n/a | BLOCKED — image_picker native plugin pending |
| Reporter trust | OK | OK | OK | OK | partial | OK | OK | OK | cache | n/a | OK |
| Shipments CRUD + status | OK | OK | OK | OK | OK | OK | OK (T12) | OK | queued | SSE planned | OK |
| Vehicle tracking / GPS | OK | OK | OK | OK | partial | OK | OK | OK | queued pings | SSE gps | OK |
| Predictive ETA | OK | OK | OK | OK | OK | OK | OK | OK | cache | SSE planned | OK |
| Risk-aware routing | OK | OK | OK | OK | OK | OK | OK (T14) | OK | cache | n/a | OK |
| Route health / gaps | OK | OK | OK | OK | partial | OK | OK | OK | cache | n/a | OK |
| Alerts inbox | OK | OK | OK | OK | OK | OK | OK (T13) | OK | cache | SSE alert | OK |
| Alerts acknowledge / resolve | OK | OK | OK | OK | OK | OK | OK (T13) | OK | queued | SSE | OK |
| Notifications + prefs | OK | OK | OK | OK | OK | OK | OK (T13) | OK | cache | n/a | OK |
| Push (FCM / WEB_PUSH) | partial | OK | n/a | n/a | n/a | n/a | n/a | n/a | n/a | EXTERNAL provider required |
| Data source health | OK | OK | OK | OK | OK | OK | OK | OK | cache | SSE data-health | OK |
| i18n (en scaffolded, hi/as/mni = backend pull) | OK | OK | OK | OK | OK | OK | OK (Phase 18) | OK | per-lang cache | n/a | OK |
| Tasks (Action Center) | OK | OK | OK | OK | OK | OK | OK | OK | cache | SSE task | OK |
| Emergency command layers | OK | OK | OK | OK | OK | OK | OK | OK | cache | SSE | OK |
| Emergency routing mode | OK | OK | OK | OK | OK | OK | OK | OK | cache | n/a | OK |
| Responder roster | OK | OK | OK | OK | OK | OK | OK (Phase 15) | OK | cache | SSE | OK |
| Response tasks (lifecycle) | OK | OK | OK | OK | OK | OK | OK (Phase 15) | OK | cache | SSE | OK |
| Supply heatmap | OK (P6) | OK | OK | OK | OK | OK | OK | OK | cache | n/a | OK |
| Impact analytics (P7) | OK | OK | OK | OK | OK | OK | OK | OK | cache | n/a | OK |
| Historical validation (P4) | OK | OK | OK | OK | OK | OK | OK (Phase 14) | OK | cache | n/a | OK |
| Decision intelligence | OK | OK | OK | OK | OK | OK | OK | OK | cache | SSE | OK |
| Satellite evidence | OK | OK | OK | OK | OK | OK | OK (Phase 16) | OK | cache | n/a | OK |
| Field media signed URLs | OK | OK | OK | OK | UI stub | OK | OK (Phase 16) | OK | never cache | n/a | OK |
| Offline sync queue | OK | OK | OK | OK | OK | OK | OK (Phase 9) | OK | OK | n/a | OK |
| Connectivity-aware gating | OK | OK | OK | OK | OK | OK | OK | OK | OK | n/a | OK |
| SSE realtime bus | OK (server) | OK | OK (SseClient) | OK | OK | OK | OK (Phase 17) | OK | n/a | OK | OK |
| Citizens portal | NOT IN BACKEND | n/a | n/a | n/a | n/a | n/a | n/a | n/a | n/a | n/a | Backend unavailable |
| Driver lightweight app | NOT IN BACKEND | n/a | n/a | n/a | n/a | n/a | n/a | n/a | n/a | n/a | Backend unavailable |
| Mapbox premium layer | optional | config | n/a | n/a | n/a | n/a | n/a | n/a | n/a | n/a | EXTERNAL provider required |

## Summary

- **All in-scope PRD features:** backend + API + Flutter + wired + tested + auth.
- **External blockers (genuine):** FCM push, Mapbox premium, Copernicus satellite API, WhatsApp/SMS client channel, iOS build.
- **Client-out-of-scope features:** citizens portal & driver app (backend does not expose them).
- **Deferred (documented):** native image_picker plugin for in-app camera (master prompt explicitly defers this to a later phase requiring native plugin setup).
