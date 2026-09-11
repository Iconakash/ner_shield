# NER-SHIELD — Realtime Analysis

## Backend reality (authoritative)

- **Transport:** SSE (`GET /api/v1/realtime/stream`), authenticated via the
  standard bearer dependency chain.
- **Permission filtering is SERVER-SIDE.** Each subscriber's permissions gate
  which events are forwarded. Sensitive payloads never reach unauthorized
  subscribers.
- **Scope filtering is at the DB/RLS layer** for payload resolution.
- **Single-instance limitation (documented):** in-process event bus — not
  horizontally scalable. Do NOT design the client assuming distributed
  fan-out.
- Publishers observed in reference: gps / shipment / alert / risk / task /
  data-health.

## Client design

- A Dart SSE client (Dio `ResponseType.stream` or `http` stream) wraps the
  bus. Because only SSE is provided, the client implements:
  - Connect with auth headers.
  - Parse `event:` / `data:` frames.
  - Heartbeat / keep-alive handling.
  - Automatic reconnect with exponential backoff + jitter.
  - On reconnect: refetch latest state via REST (`/command/summary`,
    `/alerts/inbox`, etc.) to recover missed state.
  - Dedup by event id + monotonically increasing cursor where provided.
  - Drop stale events (event timestamp older than last known).
- Riverpod `StreamProvider` exposes a typed `RealtimeEvent` stream; individual
  repos (alerts, shipments, tasks) map events into their state without full
  screen reloads.

## Event taxonomy (client)

| kind | payload | client effect |
|---|---|---|
| `alert` | alert row | upsert into alerts inbox; bump unread; toasts for HIGH/CRITICAL |
| `shipment` | shipment row | upsert into shipments list; update map features |
| `gps` | position | update vehicle marker; append trail point |
| `risk` | prediction row | update risk overlays + KPI tile |
| `task` | task row | upsert into tasks list |
| `data-health` | source status | update health screen |

## Reconnect / recovery

```
Connect (Bearer) → stream
   ├─ on disconnect → backoff(1s..60s) + jitter
   ├─ on reconnect → REST refresh of active scopes (cursor=latest)
   └─ on token expiry(401 SSE) → refresh token → reconnect
```

## Gaps / notes

- No Supabase channel API in this client (data plane stays FastAPI).
- If backend later moves to Postgres LISTEN/NOTIFY or Redis Pub/Sub, the SSR
  transport stays the same for the client — no client change required.
- SSE over mobile data must be resilient to carrier idle-timeout; keep-alive
  needed.