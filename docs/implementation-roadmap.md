# NER-SHIELD — Implementation Roadmap

> Phase plan mapped to the master prompt §60-§61. Each phase ends with an
> inspect/implement/analyze/test/fix/review/document gate.

| Phase | Content | Deliverables | Gate |
|---|---|---|---|
| 0 | Forensic analysis | docs/* (product, reference, backend contract, api map, data map, auth/roles, workflow, features, realtime, offline, architecture, ui-ux, responsive, security, testing, integration issues) | ✔ docs complete |
| 1 | Documentation + feature matrix | finalize docs; freeze plan | ✔ |
| 2 | Flutter foundation | pubspec deps, folder tree, main.dart bootstrap, config, logger, errors, storage, dio, connectivity | analyze clean |
| 3 | Design system + landing | theme (M3), tokens, shared widgets, landing screen pure Flutter | analyze clean |
| 4 | Authentication | login + MFA + session restore + `/auth/me` + secure storage | tests T1–T5 |
| 5 | Role-based navigation | go_router guards + role shells + logs + deep links | tests T15 |
| 6 | API/data architecture | models (freezed), repositories, services, error mapping, sync queue, caching | tests T8–T9 |
| 7 | Dashboard | KPI tiles + charts + freshness | test T6 |
| 8 | GIS/maps | flutter_map layers + detail sheet + search | test T11 |
| 9 | Incidents + offline | wizard + media + queue + sync status | tests T7–T9 |
| 10 | Routing | plan + alternatives + modes + shipment assign | test T14 |
| 11 | Logistics | shipments CRUD + vehicle + GPS + ETA | test T12 |
| 12 | Alerts + notifications | inbox + prefs + devices + push | test T13 |
| 13 | AI/risk/predictions | latest + explain cards + why-route | — |
| 14 | Historical | charts from backend series + empties | — |
| 15 | Emergency | command layers + decision cards + emergency routing | — |
| 16 | Tasks + evidence + satellite | task lifecycle + evidence view + satellite metadata | — |
| 17 | Realtime | SSE client + reconnect/recovery + dedupe | test T10 |
| 18 | Localization + accessibility | ARB scaffolding + i18n wiring + a11y sweep | — |
| 19 | Security + performance | secret scan, log redaction, perf pass | audit |
| 20 | Testing | unit/widget/integration suites, offline + android matrices | all tests |
| 21 | Production build | `flutter analyze` · `flutter test` · `flutter build apk --release` | release APK |
| 22 | Parity audit | `feature-parity-report.md` + final security/perf audits | complete |

## Status

- Phase 0 — **complete** (all discovery docs authored). ✔ docs complete
- Phase 1 — **complete** (docs frozen; roadmap + feature matrix live). ✔
- Phase 2 — **Flutter foundation in place** (pubspec deps, folder skeleton,
  config, errors, logging, secure storage, Dio + auth interceptor,
  connectivity, theme). `flutter analyze` clean · `flutter test` green. ✔
- Phase 3 — **Design system + landing done** (M3 theme light/dark, status
  chips, screen-state components). Landing built purely in Flutter. ✔
- Phase 4 — **Auth foundation done** (`AuthService` login/me/logout,
  `AuthController` with session restore + role resolution, Login screen,
  secure token persistence, router guard). MFA + refresh flow pending. ⏳
- Phase 5 — **Role shell skeleton done** (role-driven NavigationBar sections;
  dashboard section live; placeholder screens swap in per phase). Deep links
  pending. ◑
- Phase 6 — **Complete** (models, response guards, endpoint services,
  TTL-cache repositories, unit tests). ✔
- Phase 7 — **Complete** (six-KPI command dashboard wired into the shell). ✔
- Phases 8 — **Complete** (flutter_map OSM + 10 layers + coordinate search +
  long-press locate + detail bottom sheet + offline stale banner; widget +
  geometry + controller tests green, `flutter analyze` clean). ✔
- Phases 9–10 — **Complete** per `work-status.md` (field reports + offline
  queue; routing planner + WHY cards). ✔
- Live Supabase integration audit — **complete** (2026-09-02): the
  MCP-connected live project is empty (no tables/policies/buckets/users), so
  all live data verification is pending backend provisioning (L-01); the
  client was verified against the FastAPI contract; secrets scan clean;
  `flutter analyze` clean · `flutter test` 71 green. See
  `docs/live-supabase-integration-audit.md`.

## Next up (planned order)

- **Backend (blocking):** provision the live Supabase project — schema + RLS
  policies + roles + PostGIS + buckets (`backend-integration-issues.md` L-01),
  lock down `rls_auto_enable()` (L-02), then deploy/point the FastAPI API at
  it; only then can live T1–T17 run.
- **Client:** Phase 4 leftover — token refresh (refresh-once-on-401) + MFA
  challenge/verify UX (the only FLUTTER-MISSING auth gap found by the audit).
- Then continue the frozen order: Phase 14 historical → 15 emergency →
  16 tasks/evidence/satellite → 17 realtime SSE → 18 l10n/a11y → 19
  security/perf → 20 testing matrix → 21 release build → 22 parity audit.

## Working notes

- Old project untouched. Fresh Flutter project at `ner_shield/`.
- Android-only implementation; cleartext disabled in release (debug-only
  cleartext overlay). Application ID `in.gov.mdoner.nershield`.