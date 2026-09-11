# NER-SHIELD — Security Plan

## Threat posture

This app is an **untrusted display layer**. Every rule follows the backend's
AX-1..AX-6 axioms:
- AX-1: never trust frontend authorization — server enforces everything.
- AX-2: no secrets in the client except the anon key (public) + user's own
  short-lived token.
- AX-3: service-role credentials never reach the client.
- AX-5: role is never user-editable or client-selected.

## What the Flutter client will hold

- Supabase **anon key** (public by design) ONLY IF a direct Supabase read is
  required. Default plan: all reads via FastAPI — so even the anon key is
  optional. `.env.example` documents the public values only.
- User access token + refresh token, stored in `flutter_secure_storage`
  (KeyStore-backed/EncryptedSharedPreferences on Android), never in plain
  shared prefs or logs.

## Hardening checklist

- **Tokens:** refresh-before-expiry; logout revokes server-side; on 401 →
  attempt refresh exactly once → else force re-login.
- **Logging:** structured, safe; never logs passwords, tokens, keys, media
  bytes. Redact `Authorization` in Dio interceptors.
- **Network:** TLS only (cleartext disabled on Android in release);
  `usesCleartextTraffic=false`; debug builds allow localhost only.
- **Deep links:** parse only trusted host patterns; always route through the
  role guard.
- **Permissions:** request location only where a flow needs it; notification
  permission only when enabling push; Android 13 runtime permissions handled.
- **Secure config:** `--dart-define` for all environment; no hardcoded URLs in
  source. `.env.example` (no values) committed; real `.env` under gitignore.
- **Media:** the app only ever uploads local photos and reads short-lived
  signed URLs; it never places bucket credentials.
- **Sensitive data:** draft field reports persisted in the local DB are
  encrypted-at-rest via device-level encryption (SQLCipher-style option
  documented; keep simple for v1 but never plain log them).
- **Debug config:** `kReleaseMode` gates any debug-only hooks.

## Roles in the client

- Role/permission checks in UI are cosmetic + educational.
- If server returns `FORBIDDEN_ROLE`/`FORBIDDEN_SCOPE`, show explanation; do
  not silently retry.

## Security review gates (Phase 19)

- Search the repo for banned key shapes (`service_role`, `postgres://`,
  private keys).
- Run `flutter analyze` clean; review all `debugPrint`/`print`.
- Verify release AndroidManifest has no cleartext, no extra exports.