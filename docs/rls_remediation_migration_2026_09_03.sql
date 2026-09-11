-- =============================================================================
-- NER-SHIELD V2 — RLS remediation for the 8 tables flagged by the linter.
--
-- Purpose: every table that has RLS enabled but ZERO policies currently returns
-- the empty set to `authenticated` users. That is the correct behaviour for
-- some (server-only) tables, but for the rest it silently breaks the
-- notification-delivery, GPS-health, ML-feature, and sync-status read paths
-- used by FastAPI on behalf of authenticated principals.
--
-- Principle: each policy is the LEAST privilege that matches the sibling
-- pattern documented in the existing 79 policies. No `USING (true)` is added
-- for tables that hold credentials or device-link material — those stay
-- server-only by deliberate omission.
--
-- Backend write paths use the system DB pool (role bypass) or run as
-- `service_role`; clients never INSERT/UPDATE/DELETE these tables.
-- =============================================================================

-- ---------- device_credentials ------------------------------------------------
-- Holds device-credential secret_hash. Reads/writes must be SERVER-ONLY.
-- `device_credentials` has RLS enabled; explicit NO policies = deny-by-default.
-- (We document this instead of adding `USING (true)`.)

-- ---------- gps_health -------------------------------------------------------
-- Operational health rollup, read by the data-health endpoint for any
-- authenticated reader (sibling: gps_devices allows SELECT USING (true)).
DROP POLICY IF EXISTS gps_health_select ON public.gps_health;
CREATE POLICY gps_health_select ON public.gps_health
  FOR SELECT TO authenticated
  USING (true);

-- ---------- ml_feature_snapshots ---------------------------------------------
-- ML feature lineage. Sister table ml_models allows SELECT USING (true); match.
-- Table has relforcerowsecurity=true so authenticated reads must satisfy RLS.
DROP POLICY IF EXISTS ml_feature_snapshots_select ON public.ml_feature_snapshots;
CREATE POLICY ml_feature_snapshots_select ON public.ml_feature_snapshots
  FOR SELECT TO authenticated
  USING (true);

-- ---------- ml_predictions ---------------------------------------------------
-- ML prediction output. Sister table ml_models allows SELECT USING (true); match.
-- Table has relforcerowsecurity=true so authenticated reads must satisfy RLS.
DROP POLICY IF EXISTS ml_predictions_select ON public.ml_predictions;
CREATE POLICY ml_predictions_select ON public.ml_predictions
  FOR SELECT TO authenticated
  USING (true);

-- ---------- notification_deliveries -----------------------------------------
-- Per-user delivery receipts. Sister table notifications scopes by
-- user_id = app_current_user_id(); join through that table.
DROP POLICY IF EXISTS notification_deliveries_select ON public.notification_deliveries;
CREATE POLICY notification_deliveries_select ON public.notification_deliveries
  FOR SELECT TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.notifications n
      WHERE n.id = notification_deliveries.notification_id
        AND n.user_id = public.app_current_user_id()
    )
  );

-- ---------- sync_devices -----------------------------------------------------
-- A device is bound to exactly one user_id; the owner sees their own devices.
DROP POLICY IF EXISTS sync_devices_select ON public.sync_devices;
CREATE POLICY sync_devices_select ON public.sync_devices
  FOR SELECT TO authenticated
  USING (user_id = public.app_current_user_id());

-- ---------- sync_ops_log -----------------------------------------------------
-- Ops log is keyed by device_code; resolve ownership through sync_devices.
DROP POLICY IF EXISTS sync_ops_log_select ON public.sync_ops_log;
CREATE POLICY sync_ops_log_select ON public.sync_ops_log
  FOR SELECT TO authenticated
  USING (
    device_code IN (
      SELECT device_code FROM public.sync_devices
      WHERE user_id = public.app_current_user_id()
    )
  );

-- ---------- sync_state -------------------------------------------------------
-- Per-device sync-state row; ownership via sync_devices.device_id -> user_id.
DROP POLICY IF EXISTS sync_state_select ON public.sync_state;
CREATE POLICY sync_state_select ON public.sync_state
  FOR SELECT TO authenticated
  USING (
    device_id IN (
      SELECT id FROM public.sync_devices
      WHERE user_id = public.app_current_user_id()
    )
  );

-- =============================================================================
-- v_gis_summary — drop and recreate as SECURITY INVOKER.
--
-- The view itself only counts aggregate row totals (states, districts, roads,
-- etc.) — it does not select any user-specific or sensitive columns. There is
-- no functional reason for SECURITY DEFINER; the row counts are governed by
-- RLS on the underlying tables anyway, so SECURITY INVOKER is safe AND fixes
-- the security-advisor ERROR.
-- =============================================================================
DROP VIEW IF EXISTS public.v_gis_summary;
CREATE VIEW public.v_gis_summary
WITH (security_invoker = true) AS
  SELECT
    (SELECT count(*) FROM public.states)                                       AS states,
    (SELECT count(*) FROM public.districts WHERE geom IS NOT NULL)             AS districts_with_geom,
    (SELECT count(*) FROM public.roads)                                        AS roads,
    (SELECT count(*) FROM public.road_segments)                                AS road_segments,
    (SELECT count(*) FROM public.road_segments WHERE district_code IS NOT NULL) AS segs_geo_assigned,
    (SELECT count(*) FROM public.facilities)                                   AS facilities,
    (SELECT count(*) FROM public.railways)                                     AS railways,
    (SELECT count(*) FROM public.waterways)                                    AS waterways;

-- The view is owned by postgres (default). Grant SELECT to authenticated.
GRANT SELECT ON public.v_gis_summary TO authenticated;