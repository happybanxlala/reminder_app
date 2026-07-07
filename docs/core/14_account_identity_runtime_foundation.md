# 14 Account Identity Runtime Foundation

## 1. Purpose

This document defines the minimal runtime representation of account identity.

Phase 4C creates account identity runtime foundation.

It does not implement login.

It does not implement OAuth.

It does not call Supabase.auth.

It does not activate Shared Pack production UI.

It does not migrate Personal Pack data.

## 2. Relationship to Phase 4A

Reference: `docs/core/12_account_binding_foundation_spec.md`.

Account binding means connecting the current device’s user data and shared identity to a stable account identity that can be recovered and re-verified later.

Phase 4C implements only the runtime representation needed before real account binding.

## 3. Relationship to Phase 4B

Reference: `docs/core/13_secure_runtime_config_boundary.md`.

Phase 4B solved config supply.

Phase 4C solves identity runtime representation.

Config availability alone does not mean account identity exists.

## 4. Account Runtime States

### unbound

- Technical meaning: no account identity is available.
- User-safe meaning: this device is not protected by an account yet.
- Remote writes: cannot provide account identity.
- Shared Pack: cannot use this for production Shared Pack requests.

### binding

- Technical meaning: binding has started but is not complete.
- User-safe meaning: account binding is in progress.
- Remote writes: cannot provide account identity.
- Shared Pack: cannot use this for production Shared Pack requests.

### bound

- Technical meaning: stable non-secret account identity is available.
- User-safe meaning: account protection boundary exists.
- Remote writes: may provide account identity in later phases.
- Shared Pack: may use this only after production UI and request catalog are explicitly activated later.

### bindingFailed

- Technical meaning: binding failed or was cancelled.
- User-safe meaning: account binding did not finish.
- Remote writes: cannot provide account identity.
- Shared Pack: cannot use this for production Shared Pack requests.

### needsReauth

- Technical meaning: an account session needs re-verification.
- User-safe meaning: please verify your account again.
- Remote writes: cannot provide account identity for new writes in Phase 4C.
- Shared Pack: cannot use this for production Shared Pack requests.

## 5. Account Identity Value

`AccountIdentity` contains:

- stable non-secret `accountId`
- optional safe display label
- optional safe provider label
- optional `boundAt`
- optional `lastVerifiedAt`

It must not contain:

- access token
- refresh token
- provider token
- service role key
- database password
- DATABASE_URL
- plaintext credentials

The UI must not expose provider UID, Supabase UID, or identity_id.

## 6. Default Runtime

Default production runtime remains unbound until real binding implementation is added.

`DefaultUnboundAccountIdentityRuntime`:

- does not call remote
- does not call Supabase.auth
- does not invent a device-scoped account
- does not activate Shared Pack
- returns an `unbound` snapshot

## 7. Test/Fake Runtime

Fake bound identity is allowed in tests.

Fake runtime must not be used as production account binding.

Fake runtime exists under test support only.

## 8. Shared Pack Identity Adapter

`AccountBackedSharedPackIdentityProvider` can later bridge account identity to `SharedPackIdentityProvider`.

The adapter returns `accountId` only when account status is `bound`.

For `unbound`, `binding`, `bindingFailed`, and `needsReauth`, it fails safely.

Phase 4C does not wire this adapter to production Shared Pack UI.

Shared Pack requests remain `implemented_not_wired`.

## 9. Backup / Export Safety

Account runtime must not put tokens or credentials in backup/export.

Forbidden:

- access token
- refresh token
- service role key
- provider token
- database password
- DATABASE_URL
- plaintext credentials

## 10. What Phase 4C Enables

Phase 4C enables:

- account status UI in Phase 4D
- later Shared Pack active_v1_manual in Phase 4E
- stable account identity boundary for future Personal Pack migration in Phase 5

## 11. What Phase 4C Does Not Enable Yet

Phase 4C does not enable:

- production Shared Pack invite/join/refresh
- Personal Pack cloud sync
- restore
- realtime
- outbox
- background sync
- account switching

## 12. Stop Conditions

Stop if:

- Supabase.auth is added
- login UI is added
- OAuth is added
- device ID is called account identity
- token is stored in backup/export
- Shared Pack is marked active_v1_manual
- Personal Pack migration starts
- realtime/outbox/background sync is added

## 13. Final Status Marker

phase_4c_status: account_identity_runtime_foundation_defined

Phase 4C defines the account identity runtime foundation.

Default production runtime remains unbound.

It does not implement real account binding yet.

It does not activate Shared Pack production UI.

The next phase is Phase 4D: Account Status UI.
