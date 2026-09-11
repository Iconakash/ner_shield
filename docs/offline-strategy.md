# NER-SHIELD — Offline Strategy

> Backend contract per `reference docs/OFFLINE.md` and `app/sync/router.py`.
> This is a **core architectural requirement** (PRD §4, OFF-01..06).

## Backend sync contract

- **Push:** `POST /api/v1/sync/push` with batched ops `{client_op_id *,
  op_type: FIELD_REPORT|GPS_PING, payload}`. Every op is re-validated
  server-side (auth → status → permission → scope → business rules). Nothing
  from the device is trusted.
- **Idempotency:** dedup by `client_op_id` against `sync_ops_log`. Duplicate
  ops return `DUPLICATE` / `ACCEPTED` without double effects.
- **Pull:** `GET /sync/pull?cursor=N` → scoped cache delta (alerts,
  shipments, incidents, reference data).
- **Connectivity classes:** `EXCELLENT|GOOD|WEAK|VERY_WEAK|OFFLINE` control
  max ops, photo transfer, allowed op types, beacon interval. Server serves
  `GET /sync/policy`; client consults before flushing.
  - `VERY_WEAK`: GPS pings + HIGH/CRITICAL text reports only.
  - Phones: no transfer until better class (and even GOOD may gate).
- **Re-auth:** cached sessions expire ≤72h; expired sessions reject push with
  `UNAUTHENTICATED`; ops stay queued locally.

## Client architecture (offline-first)

```
UI
 ↓
Repository (async/await; reads from local DB first, then network)
 ↓
Local Database (Drift/SQLite) — cache + draft + sync queue
 ↓
Sync Queue (client_op_id UUIDs; explicit statuses)
 ↓
Connectivity Manager (connectivity_plus; class classifier)
 ↓
Backend (Dio)
```

- **Cache:** profile, districts, segments, alerts, shipments, i18n field
  schema, latest risk, data-health. Each cache row stores `last_synced_at`.
- **Drafts:** incident drafts persist locally (media compressed locally) in
  status `PENDING`. On write, generate `client_op_id` (uuid v4).
- **Queue statuses surfaced in UI:** `PENDING · SYNCING · SYNCED · FAILED ·
  OFFLINE`. A local save NEVER claims server success.
- **Flush triggers:** connectivity restored, app foreground, timer (interval
  policy), manual "Sync now".
- **Media:** capture → compress (flutter_image_compress) → store local →
  upload via `POST /field/reports/{id}/media` (multipart) → attach → confirm.
  Idempotent by sha256 dedup server-side. Retry with backoff. If upload fails
  (interrupted, auth expired), media ref stays in the queue.

## Conflict policy (server-authoritative)

- Config / assignments / reference: server wins (pull refreshes).
- Officer text records (field reports): append-only; write-wins by op id.
- Rejected ops surface explicit reasons to the officer. No silent loss.

## UI states

Every offline-capable screen shows explicit offline state + last-updated
timestamp. Sync screen shows pending count + per-op status + retry action.

## Testing matrix (see testing-plan.md §6)

- No Internet → Launch → Cached state → create report → save locally → close
  → reconnect → sync → server ACK.
- Interrupted upload; retry; duplicate; expired auth; conflicting changes.