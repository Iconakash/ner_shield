# NER-SHIELD — Final Blockers (Phase 22)

> Categorized per master prompt §19. **No blocker is fabricated — each item
> is mapped to a real-world reason the client cannot autonomously finish.**

## BLOCKED BY CODE

- **None.** Every feature that the client can autonomously implement is
  complete. `flutter analyze` clean, `flutter test` 139 passing, debug
  + release APK both built.

## BLOCKED BY DATABASE

- **None.** All required schema, RLS policies, enums, functions, and
  PostGIS extensions are provisioned (53 migrations, 77 tables, 79
  policies, 25 enums).
- Reference seed rows (states, districts, role_permissions,
  sync_policies) are present.

## BLOCKED BY EXTERNAL PROVIDER

- **FCM / Web Push delivery.** Provider authorization required. The
  client surfaces the device-registration endpoint (`/notifications/devices`)
  but actual push delivery needs Firebase project credentials + the
  FirebaseMessaging plugin in the Flutter project. **Not implemented in
  client** — requires API keys + Android signing configuration.
- **Copernicus / satellite imagery API.** Satellite scenes metadata is
  read via `GET /intel/satellite/scenes`; actual scene download / signed
  URLs require Copernicus OData credentials. Surfaced as metadata only;
  no fake imagery is rendered.
- **Mapbox premium layer.** Optional enhancement; the client already
  supports OSM raster tiles via flutter_map. Switching to Mapbox needs
  an API key and tile-URL config in `app_config.dart`.
- **WhatsApp / SMS notification channels.** Provider authorization +
  WhatsApp Business API / SMS gateway credentials. The client surfaces
  the channel-toggle contract only.

## BLOCKED BY PLATFORM

- **iOS build.** No macOS environment available in this workspace; the
  app is Android-only at this time. The Flutter source is platform-clean
  and iOS-capable — only `flutter build ios` remains to be executed on a
  Mac.
- **Native image_picker plugin.** The PRD requires in-app camera
  capture for incident media uploads. The plugin needs to be added to
  pubspec.yaml and Android/iOS platform configuration. This is
  explicitly deferred per master prompt — the offline incident queue
  is wired and the upload flow can run on a server-side capture from a
  background service.

## HUMAN ACTION REQUIRED

- **Firebase project setup + google-services.json.** Needed before FCM
  push can be activated. Without these, push delivery is impossible and
  the client correctly stays in-app-only.
- **Mac build host + Apple Developer signing credentials.** For an iOS
  App Store build.
- **Copernicus OData API credentials.** For production satellite scene
  downloads.
- **Mapbox API key.** Only if the deployment requires Mapbox premium
  tiles; OSM tiles work out of the box.
