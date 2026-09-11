# NER-SHIELD — Flutter Architecture

## Stack selection (Android-first)

| Concern | Choice | Reason |
|---|---|---|
| Language/UI | Flutter 3.x / Dart 3 (SDK ^3.13.2) | matches created project |
| State | `flutter_riverpod` (Riverpod 2.x) | recommended by PRD; great for async + offline streams; testable |
| Navigation | `go_router` | deep links, role guards, notification taps |
| Networking | `dio` + `dio` interceptors | timeouts, retries, refresh-token interceptor, SSE stream support |
| Offline DB | `drift` (SQLite) | typed tables, sync queue, easy tests |
| Storage (secure) | `flutter_secure_storage` | tokens, refresh tokens |
| Connectivity | `connectivity_plus` | class classifier for sync gating |
| Location | `geolocator` | field capture + trip tracking |
| Camera/media | `image_picker` + `flutter_image_compress` | field photos compressed for low bandwidth |
| Push | `firebase_messaging` (optional wiring; backend channels may use WEB_PUSH) | staged behind `notifications` provider |
| Maps | `flutter_map` + OSM tiles | PRD recommends; cost-friendly; tile caching |
| Charts | `fl_chart` | operational dashboards; testable |
| Localization | `flutter_localizations` + ARB scaffolding; backend `/i18n` supplies real strings | en/hi/as/mni + structure for more |
| Background | `workmanager` (sync flush, GPS beacon) — **only if required** | keep scope tight |
| Codegen | `freezed` + `json_serializable` | value models + JSON |

No package is added without a purpose; each must have Android support,
maintenance, licensing and security checked.

## Layering (strict)

```
Presentation (widgets/screens; no business logic)
      ↓
State Management (Riverpod controllers; async/error/loading/empty states)
      ↓
Repository (single source per domain; local-first reads; writes behind services)
      ↓
Service / API layer (Dio client, endpoint wrappers, error mapper)
      ↓
Backend (FastAPI /api/v1)
```

- Widgets never call HTTP directly.
- Controllers never contain SQL.
- Models are `freezed`; JSON parsing in dedicated `fromJson`/`toJson`.
- Single Dio instance; single Drift DB; single `AppRouter`; single theme.

## Module tree (fresh build)

```
lib/
├── main.dart
├── app/                  # app bootstrap (providers container, router wiring)
├── core/
│   ├── config/           # AppConfig (from --dart-define / .env loaded once)
│   ├── errors/           # AppException + error-message mapping
│   ├── network/          # Dio client + auth interceptor + retry
│   ├── storage/          # secure storage, drift db, shared prefs
│   ├── connectivity/     # connectivity stream → class
│   ├── permissions/      # location + notification permission flows
│   ├── localization/     # language resolution + l10n delegates
│   ├── logging/          # structured safe logger
│   └── utils/
├── routing/              # go_router config + guards + redirects
├── theme/                # tokens, ThemeData, dark/light
├── models/               # freezed models (User, Shipment, Alert, ...)
├── repositories/
├── services/             # api clients per domain
├── realtime/             # SSE client + stream providers
├── features/
│   ├── landing/ auth/ dashboard/ maps/ incidents/ routing/
│   ├── logistics/ vehicles/ shipments/ alerts/ emergency/ tasks/
│   ├── evidence/ satellite/ predictions/ historical/ command_center/
│   ├── reports/ profile/ settings/ data_health/ i18n_admin/
└── shared/
    ├── widgets/ components/ extensions/
```

Only create modules that are actually used — no empties.

## Async state pattern

Every pull with network dependency flows through a Riverpod
`AsyncNotifier`/`AsyncValue`:
- `AsyncValue.isLoading` → skeleton.
- `AsyncValue.isError` → error widget with `AppException.message` + Retry.
- Empty → explanation + next action.
- Offline → explicit offline banner + last-synced timestamp.