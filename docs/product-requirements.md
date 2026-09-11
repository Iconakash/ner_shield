# NER-SHIELD — Product Requirements (extracted from PRD)

> Source: `RPD/NER-Smart-Logistics-PRD.md`. This document restates the PRD
> contents that the Flutter client must satisfy, stripped of backend-implementation
> assumptions the old project contradicts. The PRD remains the product-scope
> authority; backend-implementation conflicts are listed in
> `backend-integration-issues.md`.

## 1. Product identity

- **Problem Statement:** SIH26002
- **Organization:** Ministry of Development of North Eastern Region (MDoNER)
- **Mission:** AI-Based Smart Logistics & Accessibility Intelligence Platform
  for North Eastern Region (NER)
- **Why NER:** Chronic disruption to essential-goods transport (medicine, food,
  construction, agri-produce) due to landslides, floods, poor road
  infrastructure, and limited connectivity.
- **Coverage:** All 8 NER states (Arunachal Pradesh, Assam, Manipur, Meghalaya,
  Mizoram, Nagaland, Sikkim, Tripura).

## 2. Capabilities the client must surface

| PRD feature | Client responsibility |
|---|---|
| Real-time road/bridge accessibility | Display segments on map with Open / Partial / Blocked / Unknown states. |
| AI disruption prediction (risk score 0–100) | Show scores, contributing factors, confidence, and "why" explanation. **Backend computes; client renders.** |
| AI-suggested alternate routes | Display backend-returned alternatives with distance, ETA, risk. **Client does not compute.** |
| GPS vehicle tracking | Show live positions, route trail, heading, speed. **Backend stores; client streams.** |
| Geo-tagged incident reporting (offline-capable) | Capture form (type, severity, GPS, photo, description), local queue, sync. |
| Centralized dashboards | Per-role KPI tiles (connectivity, bottlenecks, emergencies). |
| Multilingual alerts (push/SMS) | Display alerts in profile language; subscribe to user preferences. |
| Offline-first as core architecture | Mandatory, not optional. Full incident capture + cached views while offline. |

## 3. PRD user roles vs frozen backend roles

The PRD lists: `super_admin`, `district_admin`, `field_officer`, `transporter`,
`driver`, `emergency_officer`, `citizen`.

The backend's frozen roles are:
`SUPER_ADMIN`, `REGIONAL_AUTHORITY`, `DISTRICT_OFFICER`, `LOGISTICS_OFFICER`,
`FIELD_OFFICER`, `ANALYST_VIEWER`.

Resolution policy: **backend role names are authoritative.** The Flutter client
maps each PRD persona to the closest backend role and documents the mapping in
`auth-and-roles.md`. The client never invents capabilities the backend does
not authorize.

## 4. Core UX capabilities by role

### Super Admin / Regional Authority
- Region-wide overview
- Districts + states list
- Analytics dashboards
- User / scope / role administration (read-only on mobile)
- Audit log read access
- Emergency command center
- Data-source health

### District Officer
- District dashboard
- Roads + segments view
- Incidents (validate / reject / approve)
- Vehicles + shipments within district
- Alerts (issue / acknowledge)
- Tasks (assign / verify)
- Reports (export where authorized)

### Field Officer (mobile-first)
- Quick incident reporting (GPS, camera, offline)
- Assignments / tasks list
- Evidence capture
- Offline queue with sync status
- Alerts inbox

### Logistics Officer
- Shipments (create, assign vehicle/route, status, confirm delivery)
- GPS tracking for own convoys
- Risk-aware route planning
- Predictive ETA
- Alerts / tasks

### Analyst Viewer
- Read-only dashboards
- Historical views
- Report export
- No write actions

### Driver (PRD persona — NOT a backend role)
The PRD envisions a "Driver" persona. The backend has no `DRIVER` role. **For
v1 the Flutter app exposes a Driver *view* under `FIELD_OFFICER`/`LOGISTICS_OFFICER`
credentials**, focused on current-trip route, alerts, SOS. Documented as a gap.

### Citizen (PRD persona — NOT a backend role)
The PRD envisions a Citizen persona. The backend has no `CITIZEN` role. **For
v1 the Flutter app does not implement Citizen sign-up; a future backend role
or public-token access would be required.** Documented as a gap.

## 5. Non-functional requirements that drive client design

- **Offline resilience:** Core mobile flows must work fully offline (incident
  capture, route view, cached alerts) with sync-on-reconnect.
- **Low bandwidth:** Paginated/compressed payloads; auto-compressed images;
  cached map tiles.
- **Localization:** At least en + 3 NER languages at MVP. Backend MVP frozen
  set is en / hi / as (with `mni` added as DEMO-pending per P8). Client
  must be architected for ≥9 NER languages but never claim parity it does not
  have — see `auth-and-roles.md`.
- **Accessibility:** Large touch targets, scalable text, high-contrast support,
  semantic labels, non-color-only status.
- **Security:** No secrets in client; token refresh + revocation aware; deep
  links sanitized.

## 6. Out of scope for the Flutter client

- Procurement of live government data contracts.
- Authoring the AI/ML pipeline (backend-only).
- Backend role assignment / user provisioning (SUPER_ADMIN web console).
- Cross-state resource negotiation workflows (PRD §14 Tier 2).
- Calibrated digital twin (Tier 2).
- Conversational DIA (Tier 2).