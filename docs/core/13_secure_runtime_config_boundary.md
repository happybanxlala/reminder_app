# 13 Secure Runtime Config Boundary

## 1. Purpose

This document defines how remote client config is supplied safely.

Phase 4B solves runtime config boundary only.

It does not implement account binding runtime.

It does not activate Shared Pack product UI.

It does not migrate Personal Pack data.

Account identity runtime is defined in `docs/core/14_account_identity_runtime_foundation.md`.

Config availability does not imply account identity exists.

## 2. Config Values

The app uses project-specific dart-define names:

- `REMINDER_SUPABASE_URL`
- `REMINDER_SUPABASE_ANON_KEY`

Supabase URL and anon key are client runtime config.

The anon key is not the service_role key.

The service_role key is forbidden in the app.

`DATABASE_URL` is forbidden in the app.

Access token and refresh token values are runtime credentials. They must not be committed to source and must not be stored in backup/export.

## 3. Accepted Config Source

The accepted Phase 4B config source is `dart-define`.

Placeholder-only example:

```sh
flutter run \
  --dart-define=REMINDER_SUPABASE_URL=https://YOUR_PROJECT.supabase.co \
  --dart-define=REMINDER_SUPABASE_ANON_KEY=YOUR_SUPABASE_ANON_KEY
```

Do not include real values in committed files, docs, tests, scripts, or screenshots.

## 4. Runtime Status

Runtime config validation has three states:

- `missing`: URL or anon key is empty; app remains setup-required.
- `placeholder`: config contains placeholder, malformed, or forbidden-looking values; app remains setup-required.
- `valid`: config is present and URL-shaped; later phases may use it.

Phase 4B does not activate Shared Pack production behavior even when config is valid.

## 5. Redaction

Config may be reported only through safe redaction:

- show URL host only
- show anon key length only
- never print the full anon key
- never print access tokens
- never print refresh tokens
- never print provider tokens

## 6. Forbidden Values

The following values are forbidden in committed app source, tests, docs, scripts, and backup/export payloads:

- service_role key
- DATABASE_URL
- PostgreSQL connection string
- access token
- refresh token
- provider token
- database password
- `.env` files with real credentials

## 7. Code Boundary

Phase 4B adds this code boundary:

`lib/core/config/remote_runtime_config.dart`

Rules:

- config reads happen here
- UI does not read raw environment/config
- providers do not read raw environment/config
- controllers do not read raw environment/config
- no Supabase call happens in this boundary
- no SupabaseClient factory is added in Phase 4B
- no production Shared Pack activation happens in Phase 4B

## 8. Relationship to Account Binding

Phase 4B only makes config supply safe.

Phase 4C will define account identity runtime foundation.

Phase 4D will show account status UI.

Phase 4D Account Status UI is defined in `docs/core/15_account_status_ui.md`.

Account Status UI does not require Supabase config to be valid. Config remains separate from account status display.

Phase 4E adds the Shared Pack account identity bridge. Shared Pack activation still requires explicitly approved account binding/runtime activation later.

## 9. Relationship to Backup / Export

Backup/export must not contain tokens.

Backup/export must not contain service_role.

Backup/export must not contain DATABASE_URL.

Backup/export must not restore remote access by credentials.

## 10. Stop Conditions

Stop if:

- real credentials are committed
- service_role is used
- DATABASE_URL appears in app config
- Supabase.auth is added
- Shared Pack UI is activated
- Personal Pack data migration begins
- realtime/outbox/background sync is added

## 11. Final Status Marker

phase_4b_status: secure_runtime_config_boundary_defined

Phase 4B defines a secure runtime config boundary.

It does not implement account binding runtime.

It does not activate Shared Pack production UI.

The next phase is Phase 4C: Account Identity Runtime Foundation.
