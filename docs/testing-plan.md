# NER-SHIELD — Testing Plan

## Test pyramid

1. **Unit** — models (freezed JSON round-trip), validators (incident bounds,
   forms), error mapping, sync queue, connectivity classifier, permissions
   helper, repositories (mock Dio), SSE parser.
2. **Widget** — landing, login, dashboard, map layer toggles, incident form,
   alerts, offline/error states, role shell nav.
3. **Integration** — auth flow (mock API) → session → role → dashboard;
   offline → create report → queue → reconnect → sync → confirm;
   notification → tap → deep link → correct screen;
   realtime disconnect → reconnect → recover.

## Frameworks

- `flutter_test` + `mockito` (or `mocktail`) for mocks.
- `integration_test` package for on-device flows.
- `http`/`dio` mocked via a stub DioAdapter.
- Drift tested with `NativeDatabase.memory()`.

## Critical path tests (must exist before "Tested")

| # | Path |
|---|---|
| T1 | Login success → session stored → `/auth/me` → role shell |
| T2 | Login failure (bad creds) → generic error message |
| T3 | MFA challenge + verify flow |
| T4 | Token expiry → refresh → continue; refresh fail → sign out |
| T5 | Logout → server revoke → secure storage cleared |
| T6 | Dashboard loads 6 KPIs from `/command/summary` |
| T7 | Incident form: GPS bounds validation, media pick, offline enqueue |
| T8 | Sync: op queued → push accepted → status SYNCED |
| T9 | Sync: op rejected → status FAILED + reason shown |
| T10 | Realtime connect/disconnect/reconnect recovery |
| T11 | Map layers load + segment detail sheet |
| T12 | Shipment detail + ETA + location ping |
| T13 | Alerts inbox ack/resolve |
| T14 | Route plan alternatives render |
| T15 | Role guard blocks unauthorized tab |
| T16 | Localization: en/hi/as switch |
| T17 | Accessibility: semantics labels present |

## Offline test matrix

- No Internet → launch → cached state → create draft → save → close app →
  reconnect → auto sync → server ACK.
- Interrupted upload; retry; duplicate sync (client_op_id); expired auth.
- Connectivity class gating: VERY_WEAK blocks photos.

## Android test matrix

- Small/normal/large phone, tablet; portrait/landscape; slow network,
  offline, location denied, notification denied, background/foreground,
  app restart, session restore.

## CI-style gates

`flutter analyze` → `flutter test` → optional `flutter build apk --release`.
Run at phase gates; do not accumulate failures.