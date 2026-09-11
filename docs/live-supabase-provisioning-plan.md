# NER-SHIELD — Live Supabase Provisioning Plan

> **Date:** 2026-09-02 · **Live project:** `rzmrjnegxgvnfgeuxaum` (verified
> empty: 0 tables / views / enums / policies / buckets / auth users /
> migrations). **Method:** authoritative SQL transcribed from the existing
> backend (`reference/old ner shild project/database/`, READ-ONLY) and applied
> via Supabase MCP migrations. No invented schema. Old project untouched.

## 1. Source of truth (PHASE A result)

The existing backend defines its database as numbered SQL files applied by
`scripts/_apply_db.py` in the order **functions → migrations → policies →
seeds** (filename order, per-statement, missing-dependency deferral). Files:

- `database/migrations/0001…0028` (schema, enums, indexes, triggers)
- `database/functions/0001_auth_helpers.sql` (RLS helpers + audit immutability)
- `database/policies/0001…0028` (RLS; 19 files + 1 inline policy in 0024)
- `database/seed/0001…0028` (reference/config data)

Live-state facts verified: PostGIS 3.3.7 **available** (not installed);
`rls_auto_enable()` = SECURITY DEFINER, owner `postgres`,
`search_path=pg_catalog`, EXECUTE granted to `anon` + `authenticated` +
`service_role` + PUBLIC; `postgres`/`service_role` have `rolbypassrls=true`,
`anon`/`authenticated` fully RLS-bound (matches reference architecture).

## 2. Object inventory (every item SOURCE = EXISTING BACKEND / MIGRATION)

**Extensions:** `pgcrypto` (0001), `postgis` (0002). Already platform-
installed: plpgsql, pgcrypto, uuid-ossp, pg_stat_statements, supabase_vault.

**Enums (25):** user_role, geo_level, approval_action, approval_status
(0001); vehicle_type, vehicle_status, shipment_priority, commodity_type,
shipment_status (0004); alert_level, alert_type, alert_status (0012);
incident_type, incident_severity (0013); device_status (0018); scene_status
(0019); model_stage (0020); task_status, task_priority (0021);
notification_channel, delivery_status (0022); data_source_type,
data_source_status (0023); responder_type, responder_status (0028).

**Tables (77) by source migration:** 0001: organizations, states, districts,
profiles, permissions, role_permissions, user_geo_assignments, login_attempts,
security_events, audit_log, approval_requests, geo_protected_resources ·
0002: roads, road_segments, facilities, railways, waterways (+ geometry
columns on states/districts, 8 GiST indexes) · 0004: vehicles, shipments,
shipment_events, gps_pings · 0005: accessibility_scores, accessibility_weights,
geo_factor_signals · 0006: segment_geo_features, segment_historical_stats,
disruption_predictions, weather_feed · 0008: impact_weights, communities,
impact_assessments · 0009: inventory, shortage_predictions · 0012: alerts,
alert_events · 0013: field_reports · 0015: sync_devices, sync_state,
sync_ops_log · 0016: sync_policies · 0018: gps_devices, device_assignments,
device_credentials, gps_health, gps_device_events · 0019: satellite_scenes ·
0020: ml_models, ml_model_versions, ml_evaluations, ml_promotions,
ml_feature_snapshots, ml_drift_metrics, ml_predictions · 0021: task_templates,
tasks, task_assignments, task_events, task_sla · 0022: notification_templates,
notification_preferences, notification_devices, notifications,
notification_deliveries · 0023: data_sources · 0024: evidence_records,
evidence_links · 0026: river_observations, provider_sync_logs · 0027:
decision_outcomes · 0028: responders, response_tasks, response_task_events,
field_report_media, historical_events, historical_event_observations,
historical_validation_runs, impact_metrics.

**Functions (9):** app_current_user_id, app_current_role, app_is_super_admin,
app_has_permission, app_has_geo_scope, app_can_read_geo, touch_updated_at,
forbid_mutation (functions/0001) · evidence_trail (in 0024).

**Triggers (7):** trg_profiles_touch, trg_audit_immutable (functions/0001) ·
trg_gps_devices_touch (0018), trg_tasks_touch (0021), trg_notifpref_touch
(0022), trg_data_sources_touch (0023), trg_decision_outcomes_touch (0027).

**RLS:** default-deny; enable (+ FORCE where source says so) on every table;
grants via the `app_*` helper functions; `anon` revoked everywhere; writes
restricted per reference (audit_log insert-only; profiles super-admin-update
only; operational deletes service-path only).

**Storage (SOURCE = EXISTING BACKEND CONTRACT):** private bucket
`field-reports` (backend `.env.example` `SUPABASE_STORAGE_BUCKET`; README P1:
service-role upload/download server-side + server-minted short-lived signed
URLs). No client storage policies — Flutter never touches Storage; keep the
bucket default-deny (no anon/authenticated policies).

**Realtime:** NONE. Backend realtime is an in-process SSE bus
(`app/realtime/bus.py`, `router.py` → `StreamingResponse text/event-stream`);
no Supabase Realtime / LISTEN-NOTIFY usage anywhere in the backend →
`supabase_realtime` publication stays empty (SOURCE = EXISTING BACKEND).

**Auth:** profiles is 1:1 `auth.users` (FK on delete cascade); roles live only
in `profiles.role` (AX-5); **no users will be created** — FastAPI proxies
Supabase Auth and user provisioning is a backend/ops action, not a DB seed.

**Seed data (SOURCE = EXISTING BACKEND):** APPLY 0001_reference_data
(permissions/role_permissions/states/districts/organizations), 0002_gis_seed,
0004_logistics_seed, 0005_accessibility_seed, 0006_disruption_seed,
0008_communities_seed, 0009_supply_seed, 0016_sync_policy_seed,
0023_data_sources_seed, 0026_external_providers_seed (all `is_demo: 0` —
reference/config data the backend requires to function).
**EXCLUDE 0028_sih_features_demo_seed.sql** (`is_demo: 1` on every row —
demo/sample data; creating fake production data is forbidden; the backend
degrades gracefully without it via honest NO_DATASET/empty states).

## 3. Transform register (mechanical only — semantics preserved)

| ID | Transform | Sites | Reason |
|---|---|---|---|
| T1 | `alter table X enable row level security force` → `enable row level security;` + `force row level security;` | 33 sites (migrations 0005, 0006, 0009×2, 0019, 0024, 0026×2, 0027; policies 0001, 0004, 0012, 0013, 0018, 0019, 0020×7, 0021, 0022, 0023, 0028×7) | shorthand is not stock PostgreSQL syntax; `_apply_db.py` performs the same expansion |
| T2 | bare `current_role` identifier → `"current_role"` | 0012_alerts.sql:31,41 (and policy refs while transcribing 0012_alerts_policies.sql) | reserved keyword used as column name; `_apply_db.py` `_RESERVED_AS_IDENT` does the same |
| T3 | in 0008: create `impact_weights` **before** `impact_assessments` | 0008_impact.sql:30/40 | FK-at-create-time ordering; reference relies on deferral retries |
| T4 | defer the 5 `touch_updated_at()` trigger statements (0018, 0021, 0022, 0023, 0027) until after functions/0001 | 5 statements | triggers reference a function defined in functions/0001; re-applied verbatim as their own migration |
| T5 | `create extension if not exists postgis;` → `set search_path = public, extensions;` + `create extension if not exists postgis with schema extensions;` (session-local) | 0002_gis_core | hosted-Supabase convention keeps `spatial_ref_sys` out of the API-exposed public schema; live DB `search_path` already ends in `extensions`, so unqualified `geometry(...)`/`ST_*` resolve identically at runtime |

Apply order (differs from `_apply_db.py` only by T3/T4 — no carry logic
needed): **migrations 0001→0028 → functions/0001 → T4 triggers → policies →
seeds → Phase-D hardening → storage bucket**.

## 4. Security considerations

- Default-deny preserved: RLS forced where the source forces it; `anon` gets
  nothing; `authenticated` only what policies grant; system paths bypass RLS
  via `service_role`/`postgres` (`rolbypassrls=true`) exactly as designed.
- **Phase D:** `rls_auto_enable()` retained (it enforces the default-deny
  posture for future tables) but hardened: `REVOKE ALL ON FUNCTION
  public.rls_auto_enable() FROM anon, authenticated, service_role, PUBLIC`.
  No backend migration calls it via RPC; it only fires on DDL events.
- No service_role credentials in Flutter; storage stays service-role-only.
- No RLS weakening: `using (true)` appears only where the source itself grants
  authenticated read (reference data, GIS layers).

## 5. Rollback considerations

Each phase = one named Supabase migration (history preserved in
`supabase_migrations`). The live project has no data/users; rollback = drop
objects in reverse phase order (nuclear option: `DROP SCHEMA public CASCADE`).
Seeds are idempotent. Nothing pre-existing can be destroyed (project verified
empty immediately before apply; re-verified during Phase C).

