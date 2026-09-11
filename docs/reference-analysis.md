# NER-SHIELD — Reference Project Analysis

> Source: `reference/old ner shild project/` — **READ ONLY**.
> Records what the existing backend actually is, what the PRD gets wrong about
> it, and which contracts the new Flutter client must target.

## 1. What the reference actually is

A **Python FastAPI modular monolith** running alongside a **Supabase-hosted
PostgreSQL + PostGIS + Supabase Auth** database. Authentication is issued by
Supabase Auth but the FastAPI service **proxies** the login so lockout,
attempt tracking, MFA, and revocation are server-side enforced.

### Runtime topology

```
Flutter / Browser / Capacitor
   │  Bearer JWT (Supabase Auth) — anon key is public; user JWT is short-lived
   ▼
FastAPI /api/v1/*  ── middleware stack (outermost first):
   RequestContext → SecurityHeaders(+CSP,HSTS in prod) → RateLimit(per-IP sliding window)
   → BodySizeLimit(1 MiB) → CORS(strict allowlist) → routes
   │
   ├── AuthGateMiddleware: fast-fail 401 when no bearer on /api/*
   │
   ▼ Per-route dependency chain (C-Authz):
   get_principal() = verify JWT (HS256 dev / JWKS RS256 prod)
                     → load profile from DB (role NEVER from token)
                     → account status + token_revoked_at timestamp revocation
   require_permissions(...) = default-deny permission gate (audited denials)
   ensure_geo_scope(state, district) = object-level geographic authorization
   │
   ▼ SQLAlchemy async, TWO pools:
   user pool   — every request; sets request.jwt.claims GUCs so Postgres RLS applies
   system pool — audited security-critical paths only (login, approvals, sync op log)
   │
   ▼ PostgreSQL (+PostGIS, pgcrypto) via Supabase-local in dev
```

### Module map (35+ routers under `/api/v1`)

| Module | Purpose |
|---|---|
| `auth` | login proxy, MFA verify, `/auth/me`, logout/revoke |
| `users` | user directory (SUPER_ADMIN only), language pref, scope grant |
| `approvals` | two-person workflow (EMERGENCY_REROUTE etc.) |
| `audit` | append-only audit log read |
| `gis` | states / districts / roads / segments / facilities / railways / waterways GeoJSON |
| `accessibility` | dynamic segment scoring engine |
| `risk` | disruption prediction (XGBoost or heuristic), immutable predictions + explanations |
| `impact` | closure/disruption impact analysis |
| `supply` | inventory + shortage probability watchlist |
| `routing` | risk-aware route selection, multi-stop |
| `shipments` | registry, status lifecycle, GPS ingest, predictive ETA |
| `alerts` | create/acknowledge/resolve/escalate-sweep |
| `field` | field intelligence reports (GPS-tagged, photos) |
| `sync` | offline push/pull, idempotent ops, connectivity-class gating |
| `i18n` | multilingual string catalog |
| `command` | command-center KPI aggregation + GeoJSON layers |
| `decisions`, `assistant` | deterministic recommendation engines |
| `simulation`, `twin` | what-if scenarios, replay |
| `resilience`, `redundancy`, `corridors` | district resilience, redundancy, critical corridors |
| `opsref` | operational reference (reference-pattern) |
| `intel` | decision-intelligence layer: data quality, source confidence, evidence fusion, hazard assessment, decision cards, closed-loop outcomes |
| `tasks` | Action Center task lifecycle |
| `notifications` | user devices / preferences / inbox / ack |
| `gps` | device registration, telemetry ingest, health |
| `media` | field-photo upload + signed URLs (P1) |
| `responders` | responder auto-alert + response tasks (P3) |
| `routehealth` | route health + infrastructure gaps (P5) |
| `historical` | historical validation runs (P4) |
| `impactmetrics` | impact analytics summary (P7) |
| `data_health` | per-source freshness / confidence / license notes |
| `realtime` | SSE bus with permission-filtered fan-out |
### ML pipeline

- **Heuristic fallback** (`ml/heuristic.py`) — deterministic, transparent, emits
  horizons + signed per-feature contributions. Default serving path.
- **XGBoost bundle** (`ml/train_disruption.py`) — trained on SYNTHETIC
  rule-labeled data. Stage ladder: `DEMO → VALIDATION → PRODUCTION →
  RETIRED`. **DEMO → PRODUCTION forbidden outright.**
- 11 mandated features frozen in `ml/feature_spec.py`.
- Every prediction writes an immutable row + factor vector + evidence trail.

### Realtime transport

In-process event bus feeding SSE subscribers (`GET /api/v1/realtime/stream`).
**Single-instance only** — not horizontally scalable. Production hardening is a
documented next-phase item (LISTEN/NOTIFY or Redis Pub/Sub). The publisher/
subscriber interfaces are transport-agnostic, so the Flutter client can later
swap to a Supabase-style channel without feature-code changes.

### Offline / sync

- Client-generated `client_op_id` UUIDs; idempotent pushes via `sync_ops_log`.
- Pull via `GET /sync/pull?cursor=N` returns scoped cache delta.
- Connectivity classes: `EXCELLENT | GOOD | WEAK | VERY_WEAK | OFFLINE`
  govern which op types may flush (very_weak = GPS + HIGH/CRITICAL text only).
- Re-authentication required ≤ 72h server-enforced (OFF-05).

### Storage

- **Field-photo bucket:** Private Supabase Storage `field-reports`.
- All reads return short-lived signed URLs (≤ 600s); raw bytes never traverse
  the data API on read.
- Magic-byte / size validation server-side; randomized storage paths
  (path-traversal-proof); sha256 idempotent retries.

### Authorization model

- **Roles never from JWT claims.** `profiles.role` + `role_permissions` +
  `user_geo_assignments` are the truth.
- **Three checkpoints:** middleware → service guards → Postgres RLS.
- **Two-person rules:** requester ≠ approver for EMERGENCY_REROUTE,
  MAJOR_SUPPLY_REDISTRIBUTION, CRITICAL_LOGISTICS_STATUS; verifier ≠
  completer for tasks.
- **Per-request `SET LOCAL` claim propagation** so RLS sees the JWT subject.

## 2. PRD vs reference — major conflicts

| PRD assumption | Reference reality | Client impact |
|---|---|---|
| Backend = Supabase direct (PostgREST, Auth JS) | Backend = FastAPI on top of Supabase Postgres; login proxied; client never talks to Supabase Auth for password grants | Use Dio with FastAPI base URL; auth via `/auth/login`; no `supabase_flutter` for auth |
| Roles: super_admin…citizen | Roles: SUPER_ADMIN…ANALYST_VIEWER | Client maps PRD personas to backend roles; documents driver/citizen gaps |
| Realtime = Supabase Realtime | Realtime = SSE bus `GET /api/v1/realtime/stream` | Dart SSE client; Riverpod StreamProvider; reconnect/recover |
| Storage buckets managed by frontend | Storage backend is server-side signed URLs | Client requests signed URLs; never embeds bucket creds |
| Tri-target (Android/iOS/Web) | Field Mobile is Android-first via Capacitor | **Android-only for v1** |
| FCM for push | WEB_PUSH / EMAIL / SMS device channels | Subscribe via `/notifications/devices`; FCM if backend later supports |
| Edge Functions for AI | XGBoost + heuristic pipeline in Python | Consume `/risk/latest`, `/risk/{segment}/explain`; never compute |

## 3. What the Flutter client MUST do vs MUST NOT do

**MUST:**
- Call FastAPI at `/api/v1/*` with `Authorization: Bearer <jwt>`.
- Honor server-set roles / permissions / scopes (display only).
- Use server-issued signed URLs for media reads.
- Implement `client_op_id` UUIDs for offline ops.
- Re-validate connectivity class before pushing GPS pings.
- Localize strictly within the catalog served by `/i18n/languages`.
- Surface data freshness from `/api/v1/data-health`.

**MUST NOT:**
- Embed service-role keys, DB URLs, signing secrets.
- Compute risk / route / ETA / accessibility locally.
- Use `supabase_flutter` to talk to the data plane.
- Bypass permission checks by hiding UI (cosmetic only).
- Persist sensitive tokens longer than the backend's 72h re-auth window.
- Show fabricated / mock data as live.