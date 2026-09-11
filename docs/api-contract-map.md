# NER-SHIELD — API Contract Map

> Living map of every backend endpoint the Flutter client needs, with the
> exact request/response shapes observed in the reference. **Never invent an
> endpoint; when the backend does not expose one, document the gap.**

## Conventions

- All endpoints under `/api/v1`.
- JSON fields are `snake_case` (as returned by the reference routers).
- Datetimes ISO-8601 UTC; geometries GeoJSON `FeatureCollection`
  (`{type:"FeatureCollection", features:[{geometry, properties}]}`).

## Auth

| Method | Path | Request | Response | Errors |
|---|---|---|---|---|
| POST | `/auth/login` | `{email, password}` | `{access_token, refresh_token, expires_in, token_type, user}` | `UNAUTHENTICATED`, `RATE_LIMITED` |
| GET | `/auth/mfa/challenge` | — | `{factor_id, challenge_id, expires_at}` | `UNAUTHENTICATED` |
| POST | `/auth/mfa/verify` | `{factor_id, challenge_id, code}` | `{access_token, refresh_token, expires_in}` | `UNAUTHENTICATED` |
| GET | `/auth/me` | — | `{user_id, email, role, org_id, language, scopes:[{level,state_code,district_code}], permissions:[]}` | `UNAUTHENTICATED`, `FORBIDDEN_ROLE` |
| POST | `/auth/logout` | — | `{ok:true}` | `UNAUTHENTICATED` |

## GIS

| Method | Path | Request | Response |
|---|---|---|---|
| GET | `/gis/states` | — | FC(states) |
| GET | `/gis/districts` | `state_code?` | FC(districts incl. centroid) |
| GET | `/gis/locate` | `lon,lat` | `{state_code, district_code, operation}` |
| GET | `/gis/roads` | `state_code?,district_code?` | FC(roads) |
| GET | `/gis/segments` | `district_code?,status?(OPEN|PARTIAL|CLOSED)` | FC(segments) |
| GET | `/gis/facilities` | `facility_type?,state_code?,near_lon,near_lat,radius_m` | FC(facilities) |
| GET | `/gis/railways` | — | FC |
| GET | `/gis/waterways` | — | FC |
| GET | `/gis/summary` | — | aggregate |

## Command Center

| Method | Path | Response |
|---|---|---|
| GET | `/command/summary` | `{critical_alerts, high_risk_roads, active_shipments, critical_shipments, supply_risk_districts, predicted_disruptions, generated_at}` |
| GET | `/command/layers/high-risk-roads` | FC |
| GET | `/command/layers/disruptions` | FC |
| GET | `/command/layers/shipments` | FC |
| GET | `/command/layers/weather` | FC |

## Accessibility / Risk / Routing

| Method | Path | Request | Response |
|---|---|---|---|
| GET | `/accessibility/segments` | `district_code?` | `[{segment_id, acc_classification, acc_score, factors, updated_at}]` |
| GET | `/accessibility/districts` | — | `[{district_code, district_name, acc_class}]` |
| GET | `/accessibility/history` | `segment_id, limit=20` | score history |
| GET | `/risk/latest` | `district_code?` | rows with risk scores + factors + model meta |
| GET | `/risk/{segment_id}/explain` | — | `{segment_id, base_value, factors:[{feature, contribution, label}], narrative}` |
| GET | `/risk/why-route/{shipment_id}` | `horizon=?` | verdict + narrative + per-segment intel |
| GET | `/routing/modes` | — | `{modes:[{id, description}]}` |
| POST | `/routing/plan` | `{origin:{facility_code?|lon,lat}, destination:{...}, priority?, risk_aversion?, k?, mode?, avoid_segment_ids?}` | `{routes:[{rank, mode, segments:[...], total_distance_km, total_eta_minutes, aggregate_risk}]}` |
| POST | `/routing/multi-stop` | `{stops:[...], priority?, mode?, risk_aversion?, return_to_origin}` | ordered legs |

## Shipments (logistics)

| Method | Path | Request | Response |
|---|---|---|---|
| GET | `/shipments` | — | `[{id, code, title, commodity, priority, status, origin_name, dest_name, vehicle_code, dest_state, dest_district, eta_at}]` |
| GET | `/shipments/{id}` | — | detail |
| POST | `/shipments` | `{title, commodity, priority, origin, destination}` | created shipment |
| POST | `/shipments/{id}/assign-vehicle` | `{vehicle_code}` | `{id, vehicle_code}` |
| POST | `/shipments/{id}/assign-route` | `{road_code}` | `{id, road_code}` |
| POST | `/shipments/{id}/location` | `{lon,lat,speed_kph?,heading_deg?}` | `{id, eta_minutes}` |
| POST | `/shipments/{id}/status` | `{new_status, note?}` | `{id, status}` |
| GET | `/shipments/{id}/eta` | — | `{id, eta_minutes, calculated_at}` |
| POST | `/shipments/{id}/confirm-delivery` | — | `{id, status:DELIVERED, delivered_at}` |

Commodity: `MEDICINE|EMERGENCY_SUPPLIES|WATER|EMERGENCY_FOOD|FOOD_GRAIN|FUEL|GENERAL`.
Priority: `CRITICAL|HIGH|MEDIUM|NORMAL`. Status: `VEHICLE_ASSIGNED|ROUTE_ASSIGNED|IN_TRANSIT|DELIVERED|CANCELLED`.

## Field intel + media (P1)

| Method | Path | Request | Response |
|---|---|---|---|
| POST | `/field/reports` | `{incident_type, severity, lon, lat, description?, photo_name?, client_op_id?, gps_accuracy_m?, observed_at?}` | `{id, code, confidence, status}` |
| GET | `/field/reports/queue` | — | pending validation |
| POST | `/field/reports/{id}/validate` | `{decision:VALIDATED\|REJECTED, note?}` | result |
| GET | `/field/reports/mine` | — | my reports |
| GET | `/field/reports/{id}/detail` | — | report + confidence + media |
| GET | `/field/reporters/{id}/trust` | — | `{trust_score, components}` |
| POST | `/field/reports/{id}/media` | multipart file ≤10 MiB | `{id, byte_size, sha256, storage_path, deduplicated?}` |
| GET | `/field/reports/{id}/media` | — | media metadata list |
| GET | `/field/reports/{id}/media/{mid}/url` | — | `{url, expires_in_s:600}` |

Incident types: `LANDSLIDE|FLOOD|ROAD_DAMAGE|TRAFFIC_BLOCKAGE|BRIDGE_PROBLEM|OTHER`.
Severities: `LOW|MEDIUM|HIGH|CRITICAL`. Bounds: lon∈[80,98], lat∈[21,29.5].

## Alerts

| Method | Path | Request | Response |
|---|---|---|---|
| GET | `/alerts/inbox` | `limit=100,lang?` | localized alerts |
| POST | `/alerts` | `{level, alert_type, title, message?, state_code?, district_code?, segment_id?, shipment_id?, payload?}` | created |
| POST | `/alerts/{id}/acknowledge` | — | status |
| POST | `/alerts/{id}/resolve` | `note?` | status |
| POST | `/alerts/escalation-sweep` | — | sweep count |

Levels: `INFO|WARNING|HIGH|CRITICAL`. Types: `ROAD_WARNING|CRITICAL_SHIPMENT|REGIONAL_SUPPLY_CRISIS|DISRUPTION_PREDICTED|SHORTAGE_PREDICTED|IMPACT_ALERT|SYSTEM`.

## Notifications

| Method | Path | Request | Response |
|---|---|---|---|
| GET | `/notifications/channels` (public) | — | `{channels:[{id, configured}]}` |
| POST | `/notifications/devices` | `{channel:WEB_PUSH\|EMAIL\|SMS, target, label?}` | registered |
| GET | `/notifications/preferences` | — | prefs |
| PUT | `/notifications/preferences` | `{channels:{}, min_severity}` | prefs |
| GET | `/notifications` | `unread_only?` | `{notifications:[...], unread}` |
| POST | `/notifications/acknowledge` | `{notification_id}` | `{acknowledged:true}` |

## Tasks

| Method | Path | Request | Response |
|---|---|---|---|
| GET | `/tasks/mine` | — | `{tasks:[...]}` |
| GET | `/tasks/{id}` | — | task |
| POST | `/tasks` | `{title, description?, priority, source_type?, source_id?, district_code?, state_code?, template_code?, recommendation_ref?}` | created |
| POST | `/tasks/{id}/assign` | `{assignee_id, note?}` | `{id, status:ASSIGNED}` |
| POST | `/tasks/{id}/transition` | `{to_status, note?}` | task |

## Sync

| Method | Path | Request | Response |
|---|---|---|---|
| POST | `/sync/devices` | `{device_code}` | `{device, registered}` |
| POST | `/sync/push` | `{device_code?, connectivity, ops:[{client_op_id, op_type, payload}]}` | `{results:[{client_op_id, status, reason?}], accepted, total}` |
| GET | `/sync/pull` | `cursor=0` | `{cursor, alerts, shipments, validated_incidents, pulled_at_cursor}` (grouped RLS-scoped cache snapshot; client maps to typed deltas) |
| GET | `/sync/policy` | — | `{connectivity_classes, policy}` |
| GET | `/sync/status` | — | `{devices:[...]}` |

## Other reads / writes

| Method | Path | Response |
|---|---|---|
| GET | `/data-health` | `{title, sources:[{code, enabled, freshness, confidence, license_note, last_success_at}], summary}` |
| GET | `/i18n/languages` | `{default, coverage_note, languages, profile_language}` |
| GET | `/i18n/field-schema` | translated form schema |
| GET | `/impact/summary`, `/impact/metrics` | impact analytics |
| GET | `/supply/heatmap[/{district}]` | shortage watchlist |
| GET | `/routes/health`, `/routes/health/gaps` | route reliability |
| GET | `/intel/hazards` | `{assessments:[...], contract}` |
| GET | `/intel/decision-card/{segment_id}` | evidence-backed card |
| GET | `/intel/satellite/scenes` | `?state_code=&district_code=&provider=&limit=` → `[SatelliteEvidence]` metadata rows (signed_url NULL until authorized archive) |
| GET | `/realtime/status` | `{subscribers, published_total, dropped_total}` |
| GET | `/audit` | audit log (VIEW_AUDIT_LOG) |
| GET | `/health`, `/health/ready` | liveness/readiness |

## Realtime

| Method | Path | Response |
|---|---|---|
| GET | `/realtime/stream` | SSE `text/event-stream`, permission-filtered |

Events (publishers in reference): gps / shipment / alert / risk / task /
data-health. Each event carries a permission tag so server filters per
subscriber.

## GPS devices (hardware telemetry — informational to the app)

| Method | Path | Notes |
|---|---|---|
| POST | `/gps/devices` | register (MANAGE_SYSTEM) |
| POST | `/gps/devices/{code}/credentials/rotate` | rotate secret (MANAGE_SYSTEM) |
| POST | `/gps/ingest` | public path; `X-Device-Code`/`X-Device-Secret` |