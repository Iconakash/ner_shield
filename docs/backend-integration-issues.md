# NER-SHIELD — Backend Integration Issues

> Every PRD↔backend discrepancy, recorded without modifying the old project.
> Format per §63 of the master prompt.

---

### I-01 — Backend is not "Supabase direct"

- **Endpoints:** all `/api/v1/*`
- **Expected (PRD):** direct Supabase (PostgREST / supabase_flutter)
- **Actual:** FastAPI proxy over Supabase Postgres + Auth; login via proxy
- **Impact:** client uses Dio to FastAPI; no supabase_flutter data plane
- **Flutter workaround:** Dio + `/auth/login`; secure token storage
- **Backend change required:** none (client may embed anon key if Storage
  reads are added later)

---

### I-02 — Role name mismatch (PRD vs backend)

- **Endpoints:** `/auth/me`
- **Expected (PRD):** super_admin, district_admin, field_officer, transporter,
  driver, emergency_officer, citizen
- **Actual:** SUPER_ADMIN, REGIONAL_AUTHORITY, DISTRICT_OFFICER,
  LOGISTICS_OFFICER, FIELD_OFFICER, ANALYST_VIEWER
- **Impact:** role-driven shells must map to the frozen set
- **Flutter workaround:** role mapping table in `auth-and-roles.md`
- **Backend change required:** none (add aliases only if MDoNER wants)

---

### I-03 — Driver persona unsupported

- **Endpoints:** n/a
- **Expected (PRD):** Driver lightweight trip view + SOS
- **Actual:** no DRIVER role/endpoint
- **Impact:** driver flows cannot be delivered as a first-class role
- **Flutter workaround:** build Trip view scoped to a ship/logistics user;
  mark as "Driver mode (provisional)"
- **Backend change required:** add DRIVER role + driver-scoped endpoints

---

### I-04 — Citizen persona unsupported

- **Endpoints:** n/a
- **Expected (PRD):** public citizen read-only portal
- **Actual:** no CITIZEN role; every data endpoint requires a bearer token
- **Impact:** cannot ship citizen app against this backend
- **Flutter workaround:** none (do not fake public data)
- **Backend change required:** citizen role + anon-friendly read endpoints

---

### I-05 — OTP login

- **Endpoints:** `/auth/login`
- **Expected (PRD):** email/phone OTP sign-in
- **Actual:** password grant only
- **Impact:** OTP UX cannot be delivered
- **Flutter workaround:** password login + MFA(TOTP) step
- **Backend change required:** add OTP/magic-link endpoint (Supabase supports
  it directly) + proxy

---

### I-06 — Realtime is SSE, not Supabase Realtime

- **Endpoints:** `/realtime/stream`
- **Expected (PRD):** Supabase Realtime channels
- **Actual:** in-process SSE bus (single-instance)
- **Impact:** client must implement SSE client + reconnect/recovery; cannot
  rely on multi-instance fan-out
- **Flutter workaround:** Dart SSE client + REST recovery
- **Backend change required:** production-broker swap (LISTEN/NOTIFY or Redis)

---

### I-07 — Push notifications

- **Endpoints:** `/notifications/*`
- **Expected (PRD):** FCM end-to-end
- **Actual:** channel abstraction with WEB_PUSH / EMAIL / SMS; FCM optional via
  provider config
- **Impact:** client registers devices + can render preference UI
- **Flutter workaround:** register via `/notifications/devices`; surface
  configured channels; stage FCM adapter behind config
- **Backend change required:** FCM provider adapter toggle at deployment

---

### I-08 — External providers (IMD/SACHET/Copernicus/CWC/OSRM)

- **Endpoints:** `/data-health`
- **Expected (PRD):** live weather/satellite/etc.
- **Actual:** all adapters DISABLED + UNCONFIGURED by default; return
  SIMULATED/UNAVAILABLE labels
- **Impact:** client must show freshness/confidence labels and NEVER fake data
- **Flutter workaround:** data-health screen + SIMULATED/DEMO badges
- **Backend change required:** provider authorization + config at deployment

---

### I-09 — Analytics/historical surfaces partially missing

- **Endpoints:** `/historical/*`, `/impact/*`
- **Expected (PRD):** full historical analytics + charts
- **Actual:** historical validation runs (P4) exist; impact summary exists;
  other historical charts not exposed
- **Impact:** charts limited to what backend returns
- **Flutter workaround:** render only available series; empty-state otherwise
- **Backend change required:** additional aggregation endpoints if needed

---

### I-10 — Satellite evidence

- **Endpoints:** `/intel/*`, evidence tables
- **Expected (PRD):** satellite imagery display
- **Actual:** satellite_scenes metadata tables exist; Copernicus adapter off;
  no direct imagery endpoint to client
- **Impact:** client can display metadata/evidence, not raw scenes
- **Flutter workaround:** evidence + decision-card view; satellite imagery
  marked "provider not configured"
- **Backend change required:** authorized Copernicus integration + signed URL
  for scene artifacts

---

### I-11 — WhatsApp+SMS alert channels

- **Endpoints:** `/notifications/channels`
- **Expected (PRD):** SMS/WhatsApp client options
- **Actual:** channels configurable server-side; SMS/WhatsApp provider not
  configured
- **Impact:** client lists configured channels; cannot enable unconfigured ones
- **Flutter workaround:** read `/notifications/channels`; render appropriately
- **Backend change required:** provider procurement + config

---

### I-12 — Map provider

- **Endpoints:** n/a
- **Expected (PRD):** OSM default; Mapbox/Bhuvan optional
- **Actual:** `OSM_TILE_URL` server config; Leaflet frontend today
- **Impact:** Flutter map uses OSM tiles (attribution required)
- **Flutter workaround:** flutter_map + OSM; tile URL from config
- **Backend change required:** none

---

### I-13 — Role assignment UI

- **Endpoints:** `/users/*`
- **Expected (PRD):** role picker at registration
- **Actual:** roles assignable only by SUPER_ADMIN; no self-service
- **Impact:** registration (if any) must never show role picker
- **Flutter workaround:** login-only; role comes from `/auth/me`
- **Backend change required:** none (aligns with AX-5)

---

### L-01 — Live Supabase project is empty; schema/RLS provisioning required

- **Scope:** live Supabase project `rzmrjnegxgvnfgeuxaum` (MCP-connected,
  audited read-only 2026-09-02)
- **Expected:** NER-SHIELD schema (profiles/roles/geo/incidents/alerts/
  shipments/tasks/evidence/…), RLS policies, PostGIS, storage buckets
- **Actual:** 0 public tables/views/enums, 0 RLS policies, 0 migrations,
  0 storage buckets, `supabase_realtime` publication with 0 tables, 0 auth
  users. **PostGIS is not installed** (schema is geo-heavy). Only
  `public.rls_auto_enable()` exists (see L-02).
- **Impact:** no live end-to-end verification is possible for any data area;
  all live audit rows are NOT AVAILABLE
  (`docs/live-supabase-integration-audit.md`). Flutter remains on the FastAPI
  data plane by design (I-01).
- **Flutter workaround:** none possible — no fake data, no local schema
  simulation (per security plan)
- **Backend change required:** provision schema + RLS policies + roles +
  PostGIS + buckets, then deploy/point the FastAPI API at this project; after
  that run the live T1–T17 gates

---

### L-02 — `rls_auto_enable()` EXECUTE open to anon/authenticated

- **Scope:** `public.rls_auto_enable()` (SECURITY DEFINER event-trigger
  helper; the only public function)
- **Expected:** no public RPC surface beyond what features need
- **Actual:** security advisor WARN — callable by `anon` and `authenticated`
  via `/rest/v1/rpc/rls_auto_enable`
- **Impact:** low today (the function only acts on DDL event triggers), but it
  is an unnecessary exposed RPC
- **Flutter workaround:** none (client never calls it)
- **Backend change required:** `REVOKE EXECUTE ON FUNCTION
  public.rls_auto_enable() FROM anon, authenticated;` (or move it out of the
  exposed schema) during provisioning