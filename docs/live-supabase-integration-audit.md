# NER-SHIELD — Live Supabase Integration Audit

> **Audit date:** 2026-09-02 · **Method:** read-only MCP inspection of the
> live project + read-only inspection of `lib/`, `pubspec.yaml`, `docs/`,
> `.env*`. **No live database object was modified.** No Flutter feature was
> redesigned.

---

## 0. Executive summary

1. **The live Supabase project is brand-new and empty.** It contains zero
   public tables, zero views, zero enums, zero RLS policies, zero custom data
   functions, zero triggers (besides system ones), zero storage buckets, zero
   migrations and zero auth users. There is nothing yet to verify the Flutter
   app's data mappings against.
2. **The Flutter app does not talk to Supabase directly — by documented
   design.** There is no `supabase_flutter` dependency, no
   `Supabase.initialize`, and zero occurrences of "Supabase" in `lib/`. The
   client integrates with the **FastAPI backend** (`/api/v1/*` over a single
   Dio instance) which itself fronts Supabase Postgres/Auth (see
   `docs/backend-integration-issues.md` I-01 and `docs/security-plan.md`).
   This audit therefore verified the *indirect* integration posture rather
   than inventing a direct one.
3. **Client security posture is clean** (Step 5): no service-role key, no
   database passwords, no provider secrets, no hardcoded credentials anywhere
   in the client; `.env` does not exist; the only committed env template holds
   placeholders. One hardening gap was found and fixed (`.env` was not listed
   in `.gitignore`).
4. **End-to-end auth against the live project could not be exercised**
   (Step 6): the FastAPI service is not deployed against this new Supabase
   project and no users exist. The code-level flow was verified instead, and
   the known Phase-4 leftover (token refresh) remains open and documented.
5. **Quality gate (Step 9):** `flutter pub get` ✔ · `flutter analyze`
   **No issues found** ✔ · `flutter test` **71 passed** ✔.
6. **Recommended next step:** provision the NER-SHIELD schema/policies in the
   live Supabase project (backend work, documented in
   `docs/backend-integration-issues.md` L-01), then deploy/point the FastAPI
   API at it; only after that can T1–T15 live integration tests run.

---

## 1. Live Supabase inventory (observed, read-only)

### Database

| Item | Observed |
|---|---|
| `public` tables | **0** |
| `public` views | **0** |
| `public` enums | **0** |
| `public` functions | **1** — `rls_auto_enable()` (event-trigger helper, SECURITY DEFINER) |
| RLS policies (`pg_policies`) | **0** (no tables to protect) |
| Triggers | system-only (`realtime.subscription_check_filters`, `storage.*`) |
| Migrations | **0** |
| Installed extensions | `plpgsql`, `pgcrypto`, `uuid-ossp`, `pg_stat_statements`, `supabase_vault` — **PostGIS NOT installed** (the NER-SHIELD schema is geo-heavy) |
| Custom roles | 0 |

### Auth

| Item | Observed |
|---|---|
| `auth.users` rows | **0** |
| `auth.sessions` rows | 0 |
| Providers | email/password (platform default); no custom provider configured |
| Auth-side triggers/hooks | none (no `handle_new_user`-style hook — expected: schema not yet provisioned) |

### Authorization (RLS)

- `pg_policies` is empty — no SELECT/INSERT/UPDATE/DELETE policies exist yet.
- Note: the single `public.rls_auto_enable()` event-trigger helper will
  auto-ENABLE row level security on any future `public` table (policies still
  must be authored). This is a helpful guardrail, **not** a substitute for
  policies.

### Storage

- `storage.buckets` is **empty** — zero buckets, therefore zero bucket
  policies; no evidence/media storage structure exists yet.

### Realtime

- The default publication `supabase_realtime` exists but contains **0
  tables**; no table is realtime-enabled; no NER-SHIELD channels/events are
  configured.

### Advisor findings (security)

- `rls_auto_enable()` (SECURITY DEFINER) is executable by `anon` and
  `authenticated` via `/rest/v1/rpc/rls_auto_enable`. Low impact today (the
  function only acts on DDL event triggers), but should be locked down during
  provisioning. Logged as **L-02** in `docs/backend-integration-issues.md`.
- No performance advisors pending.

---

## 2. Flutter integration inventory (observed, read-only)

| Concern | Implementation | Files |
|---|---|---|
| Supabase initialization | **None** — by design (I-01). No `supabase_flutter` in `pubspec.yaml`, no `Supabase.initialize` | — |
| Supabase URL / anon key | Not read by any code. `.env.example` documents them as *optional placeholders only*; `AppConfig` reads `API_BASE_URL`, `API_PUBLIC_URL`, `ENV`, `DATA_MODE`, `USE_SECURE_STORAGE`, `OSM_TILE_URL` via `--dart-define` | `lib/core/config/app_config.dart` |
| Environment/config | Compile-time `String.fromEnvironment` overrides; client-safe values only | `lib/core/config/app_config.dart` |
| Authentication | Proxied password grant: `POST /auth/login` → `GET /auth/me` → `POST /auth/logout` over Dio; generic errors; no role field | `lib/services/auth_service.dart` |
| Session restoration | Launch → `hasSession` → headless `/auth/me` → `AuthState.ready(principal)`; non-retryable failure clears tokens | `lib/features/auth/auth_controller.dart` |
| Token/session refresh | **Not implemented yet** (documented Phase-4 leftover; plan: refresh-once-on-401 → else re-login). Bearer injection exists; no 401-refresh interceptor | `lib/core/network/api_client.dart` |
| API/service layer | One shared Dio (`baseUrl = $API_BASE_URL/api/v1`), per-endpoint services, response guards, error-envelope mapping | `lib/core/network/api_client.dart`, `lib/core/errors/*`, `lib/services/*` |
| Database access | Via FastAPI only (PostgREST never used). Repos are TTL-cache-first with stale-when-offline fallback | `lib/repositories/*`, `lib/core/storage/ttl_cache.dart` |
| Realtime | Designed as **SSE** from FastAPI (`/realtime/stream`) — Phase 17 pending; no Supabase channels by design | `docs/realtime-analysis.md` |
| Storage | Designed as server-issued **signed URLs**; client never holds bucket credentials; media capture pending native plugins | `docs/security-plan.md` |
| Models | freezed + snake_case JSON; GeoJSON FeatureCollection parsing for GIS layers | `lib/models/*` |
| Providers/controllers | Riverpod (AsyncNotifier/StreamProvider) per feature | `lib/features/**` |
| Error handling | Sealed `AppException` tree mapped from the backend envelope (`UNAUTHENTICATED`, `FORBIDDEN_ROLE`, `FORBIDDEN_SCOPE`, `CONFLICT`, `VALIDATION_ERROR`, `RATE_LIMITED`, `NETWORK`, …); user-safe messages only | `lib/core/errors/*` |
| Offline storage | In-memory queue behind a `SyncQueueStorage` contract (persistent Drift/SQLite swap planned without caller changes) | `lib/core/sync/sync_queue.dart` |
| Sync queue | Lifecycle PENDING→SYNCING→SYNCED/FAILED/OFFLINE + attempt history + policy-driven flush (`/sync/policy` → `/sync/push`) with connectivity classes | `lib/features/incidents/sync_controller.dart` |
| Role shell | Sections derived from server-provided role (display-only); guard redirects unauthenticated users | `lib/features/shell/app_shell.dart`, `lib/routing/app_router.dart` |

---

## 3. Verification table (Step 3)

| Area | Live Supabase | Flutter Implementation | Status | Required Action |
| ------------ | ------------- | ---------------------- | ------ | --------------- |
| Auth | Fresh project; `auth.users` = 0; email provider default; 0 sessions | Proxied login/me/logout over Dio; tokens in secure storage; restore on launch | **NOT AVAILABLE** (live e2e impossible: no FastAPI deployment against this project, no users) | Provision users via backend; then run tests T1–T5 live |
| Profiles | No `profiles` table | `AppPrincipal` (user_id/email/role/org/language/scopes/permissions) composed by `/auth/me` | **NOT AVAILABLE** | Backend provisioning (schema + role tables) |
| Roles | No role representation at all | Frozen 6-role set from server; shell sections per role | **NOT AVAILABLE** | Backend provisioning; client mapping already aligned |
| RLS | `rls_auto_enable` guardrail present; **0 policies** (no tables) | Assumes server-side authz (AX-1); never queries tables directly | **REQUIRES BACKEND CHANGE** | Author schema + policies server-side; client unaffected |
| Incidents | No tables/rows | Wizard + queue + `/field/reports` service/repo implemented | **NOT AVAILABLE** | Backend provisioning; then T7–T9 live |
| Alerts | No tables/rows | Alerts service/repo/screen wired (Phase 12) | **NOT AVAILABLE** | Backend provisioning |
| Emergency | No tables/rows | Not built (Phase 15 pending) | **NOT AVAILABLE** | Backend provisioning; client work later |
| Tasks | No tables/rows | Not built (Phase 16 pending) | **NOT AVAILABLE** | Backend provisioning; client work later |
| Evidence | No buckets/tables | Not built | **NOT AVAILABLE** | Backend provisioning |
| Satellite | No tables; no Copernicus-equivalent configured | Not built; metadata-only plan documented (I-10) | **EXTERNAL PROVIDER REQUIRED** | Provider authorization + signed-URL endpoint server-side |
| Vehicles | No tables/rows | Vehicle surfaces ride on `/shipments/*` + GPS ops (client side ready) | **NOT AVAILABLE** | Backend provisioning |
| Shipments | No tables/rows | Shipments service/repo/screen implemented (Phase 11) | **NOT AVAILABLE** | Backend provisioning; then T12 live |
| Routes | No tables/rows | `/routing/plan`, modes, why-route implemented (Phase 10) | **NOT AVAILABLE** | Backend provisioning |
| Predictions | No tables/rows | `/risk/latest` + explain + why-route views implemented (Phase 13) | **NOT AVAILABLE** | Backend provisioning |
| Realtime | `supabase_realtime` publication empty; no realtime-enabled tables | SSE-from-FastAPI design (not yet implemented, Phase 17); no Supabase channels by design (I-06) | **NOT AVAILABLE** | Backend provisioning; SSE remains the client plan |
| Storage | 0 buckets, 0 policies | Signed-URL plan; media capture pending | **NOT AVAILABLE** | Create buckets + policies server-side during provisioning |
| Offline Sync | N/A (FastAPI concern, not Supabase) | Queue + lifecycle + policy flush implemented and unit-tested | **VERIFIED** (client logic; backend unverified) | Live `/sync/*` once backend is deployed |

### Additional rows verified outside the required table

| Concern | Live Supabase | Flutter Implementation | Status | Required Action |
|---|---|---|---|---|
| Secrets in client | n/a | No service_role key, no DB passwords, no private keys, no hardcoded URLs; `.env` absent; `.env.example` placeholders only | **VERIFIED** (after `.gitignore` fix below) | Keep Phase-19 scan gate |
| Token refresh | n/a (auth proxied) | Not implemented; documented Phase-4 leftover | **FLUTTER MISSING** | Implement refresh-once-on-401 + MFA UX (next client phase) |
| Real data consumption | No data anywhere | Empty/error states render genuine unavailable states; no mocks in feature paths | **VERIFIED** (graceful degradation) | Re-verify with live backend |

---

## 4. Security verification (Step 5)

- Searched the entire repo for `service_role`, `service-role`, `postgres://`,
  private-key shapes, provider secrets: **no client-side secrets found**.
- `pubspec.yaml` has no Supabase SDK; the client cannot and does not bypass
  the API layer. Authorization remains server-enforced (FastAPI dependency
  chain + future RLS), satisfying AX-1/AX-2/AX-3.
- `.env` does not exist locally; `.env.example` contains only placeholders.
- **Gap found & fixed:** `.gitignore` did not exclude `.env` (the security
  plan requires "real `.env` under gitignore"). Added `.env` + `.env.*` with a
  `!.env.example` negation — no functional change; prevents an accidental
  commit if git is initialized later.
- No RLS was weakened (there is nothing to weaken; policies will be authored
  server-side at provisioning time).

---

## 5. Authentication end-to-end (Step 6)

**Code-level flow verified (launch → restore → me → role → shell):**

```
main → NerShieldApp (GoRouter, initial '/')
  └─ AuthController.build()
       ├─ no tokens → AuthState.pure() → routes stay public
       └─ hasSession → GET /auth/me (headless restore)
            ├─ ok → AuthState.ready(principal) → redirect /shell/dashboard
            ├─ retryable error → rethrow (retry banner)
            └─ non-retryable → clear tokens → AuthState.pure() → /login
AppShell → sections derived from principal.role (display-only)
```

| Scenario | Live result | Why |
|---|---|---|
| login / logout / session persistence / refresh / expired session / unauthorized user / disabled user | **NOT AVAILABLE** | Requires the FastAPI service deployed against this Supabase project plus provisioned users/roles — neither exists today. These flows are tests T1–T5/T15 and remain gated on a reachable backend. |

Reported honestly as unavailable — no fake session or seeded auth user was
created.

---

## 6. Real data verification (Step 7)

- No NER-SHIELD data exists in the live project, and the app's data plane
  (FastAPI) is not reachable from this environment. Therefore **no real-data
  assertions could be made**; nothing was mocked, seeded or hardcoded.
- The verified client behaviour in the absence of a backend is the correct
  one: repository failures map to `NetworkException`/timeout states and
  screens render Loading/Empty/Error states (covered by the phase suites;
  71 tests green). This matches Step 7's requirement to "expose the correct
  unavailable/empty state".

---

## 7. Fixes applied (Step 8)

| Fix | Type | File |
|---|---|---|
| `.env` / `.env.*` added to `.gitignore` (with `!.env.example`) — secrets-hygiene gap vs. `docs/security-plan.md` §Secure config | Flutter-side hardening | `.gitignore` |

No data-plane code was changed: there were **no incorrect table/column
mappings, repositories, realtime subscriptions or storage calls to fix**,
because the client intentionally has none — it integrates through FastAPI by
documented design. No backend object was created or modified.

---

## 8. Test gate (Step 9)

| Command | Result |
|---|---|
| `flutter pub get` | ✔ Got dependencies |
| `flutter analyze` | ✔ **No issues found** |
| `flutter test` | ✔ **71 passed** (error mapping, bootstrap, models, response guards, TTL cache, dashboard, maps, field reports/offline, routing) |
| `flutter build apk --debug` | Not run in this session (heavy Gradle step); analyze+test gates green — run before the release phase per `docs/implementation-roadmap.md` |

---

## 9. Backend provisioning requirements (details in `docs/backend-integration-issues.md`)

1. **L-01:** the live Supabase project is empty; the NER-SHIELD schema
   (profiles/roles/geo/incidents/shipments/tasks/evidence/…), RLS policies
   and PostGIS extension must be provisioned server-side before any live
   integration test can pass.
2. **L-02:** lock down `rls_auto_enable()` EXECUTE from
   `anon`/`authenticated`.
3. The FastAPI service must be deployed/pointed at this project (env wiring),
   because the client's contract is the FastAPI API, not PostgREST.

---

## 10. Recommended next step

**Backend (blocking):** provision the live Supabase project per L-01 (schema +
RLS + PostGIS + buckets) and deploy the API against it — without this, every
live integration item stays NOT AVAILABLE.

**Client (after backend is reachable, or in parallel):** the highest-value
*Flutter* integration work evidenced by this audit is the Phase-4 leftover:
**token refresh (refresh-once-on-401) + MFA challenge/verify UX**, which the
security plan mandates and which is the only "FLUTTER MISSING" auth gap found.
After that, continue the frozen roadmap (Phase 14 historical → 15 emergency →
16 tasks/evidence/satellite → 17 realtime SSE).


