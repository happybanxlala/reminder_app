# 12 Account Binding Foundation Spec

## 1. Purpose

This document defines the product and data boundary for Restart Phase 4.

Phase 4 is Account Binding Foundation.

Phase 4 starts by defining what account binding means before implementing runtime behavior.

Phase 4A does not implement login, OAuth, Supabase auth runtime, Personal Pack cloud migration, or Shared Pack production activation.

Phase 4 exists because Phase 3 Shared Pack production activation is blocked by runtime identity/account boundary.

Phase 4B secure runtime config boundary is defined in `docs/core/13_secure_runtime_config_boundary.md`.

Phase 4B only handles config supply and validation.

Account identity runtime remains Phase 4C.

Account identity runtime foundation is defined in `docs/core/14_account_identity_runtime_foundation.md`.

Phase 4C provides runtime identity abstractions only.

Real provider-specific login remains out of scope unless explicitly introduced in a later phase.

Personal Pack migration remains Phase 5.

## 2. Confirmed Definition

Account binding means connecting the current device’s user data and shared identity to a stable account identity that can be recovered and re-verified later.

It provides the foundation for account protection and future device restore.

It does not mean Personal Pack cloud sync is complete immediately.

It does not mean full restore is complete immediately.

It does not mean realtime sync.

It does not mean multi-account switching.

It does not mean OAuth/provider overbuild in Phase 4A.

> Account binding lets the user protect their Reminder App data with an account, so Personal Pack and Shared Pack data can later be synced and restored safely.

## 3. Product Goal

Before account binding:

- most data is limited to this device
- Personal Pack data is not account-protected yet
- Shared Pack production UI remains blocked unless a production-safe runtime identity exists

After account binding:

- the app has a stable account identity
- Shared Pack membership can be associated with that account
- future Personal Pack cloud migration becomes possible
- local Drift gradually becomes cache / device integration layer, not the user-facing data category

Phase 4 is not full cloud migration.

Personal Pack cloud migration is Phase 5.

Realtime / Offline / Advanced Sync is Phase 6.

## 4. Product Language

Recommended user-facing wording:

- Account protection
- Bind account
- Account status
- Cloud backup
- Restore on new device
- Protected by account
- Not yet protected by account
- Personal Pack
- Shared Pack

Avoid user-facing wording:

- Local Pack
- Remote Pack
- local-only
- remote-backed
- anonymous identity
- anonymous user
- Supabase user
- Supabase UID
- RLS
- mapping
- snapshot
- RPC
- outbox
- provider token
- refresh token

## 5. Account States

These are product-level account states.

### unbound

Meaning:

- No stable account is currently bound.
- Personal Pack data mainly stays on this device.
- Shared Pack production activation remains unavailable unless another approved runtime identity design exists.

User-facing wording:

- "This device is not protected by an account yet."
- "Bind an account to protect your data and prepare for restore on another device."

### binding

Meaning:

- User has started account binding.
- Binding is not completed yet.

User-facing wording:

- "Binding account..."

### bound

Meaning:

- App has a stable account identity.
- Account protection boundary exists.
- Shared Pack production activation can be considered in Phase 4E.
- Personal Pack cloud migration still requires Phase 5.

User-facing wording:

- "Account protected."
- "Shared Pack access can be protected by your account."

### bindingFailed

Meaning:

- Account binding failed or was cancelled.

User-facing wording:

- "Account binding did not finish. Please try again."

### needsReauth

Meaning:

- Existing account session needs refresh or re-authentication.

User-facing wording:

- "Please verify your account again."

Rules:

- Do not call unbound users anonymous users in UI.
- Do not expose identity_id.
- Do not expose provider UID.
- Do not imply Personal Pack is already fully cloud-backed in Phase 4.

## 6. Account Protection Boundary

Account protection means:

- The app can associate data access with a stable account identity.
- The user can later prove they are the same account.
- Shared Pack membership can later be recovered by account.
- Personal Pack cloud migration can later use this account identity.

Account protection does not yet mean:

- every Personal Pack has already been uploaded
- every Personal item is already synced
- full restore is already available
- realtime sync exists
- offline outbox exists
- account switching exists
- provider-specific OAuth overbuild exists

## 7. Phase 4 Data Boundary

Allowed in Phase 4:

- account identity boundary
- account status model
- account protection wording
- Shared Pack runtime identity boundary
- token safety rules
- setup-required / account-required UI states
- enabling Shared Pack active_v1_manual after identity/runtime setup is safe

Not allowed in Phase 4A:

- actual runtime account binding implementation
- OAuth provider implementation
- Supabase.auth runtime calls
- Personal Pack remote upload
- Personal item remote upload
- full restore
- realtime
- outbox
- conflict handling
- widget shared actions

## 8. Before Account Binding

Before account binding:

- Personal Pack data is mainly device-limited.
- Local Drift remains the primary local store.
- Shared Pack UI may remain setup-required/dev-gated.
- The app must not imply that Personal Pack data is cloud backed.
- The app must not imply that Shared Pack membership is recoverable through an account.

Recommended user-facing warning:

"Personal Pack data on this device is not protected by an account yet."

## 9. After Account Binding

After account binding:

- account identity becomes stable.
- Shared Pack membership can be associated with the account.
- Shared Pack production UI can later move to active_v1_manual.
- Personal Pack data is not automatically migrated until Phase 5.
- Local Drift becomes cache / device integration layer over time.

Recommended user-facing wording:

"Your account is bound. Shared Pack access can now be protected by your account."

Caution:

Do not claim "all data is backed up" until Phase 5 migration is complete.

## 10. Personal Pack Boundary

Phase 4A does not migrate Personal Pack data.

Phase 4 may show account status and prepare account identity.

Personal Pack cloud protection is not complete until Phase 5.

Personal Pack cloud migration belongs to:

Restart Phase 5: Personal Data Cloud Migration

## 11. Shared Pack Boundary

Shared Pack v1 already has remote schema/RPC and technical foundation from Phase 3.

However, product activation waits for account/runtime identity.

Shared Pack v1 can move to active_v1_manual only when:

- stable account identity exists
- Supabase config is safe
- UI can call SharedPackApplicationService safely
- request catalog status is updated
- manual refresh remains the model
- no realtime/outbox/background sync is added
- product wording does not imply full Personal Pack cloud migration

## 12. Backup / Export Safety

Backup/export must not include:

- Supabase access token
- refresh token
- service role key
- provider token
- database password
- DATABASE_URL
- plaintext credentials
- invite code as recovery method

Backup/export may remain a legacy local data export, but it must not restore remote access.

Primary future restore flow:

Install app
-> Bind/Login account
-> Pull personal packs after Phase 5
-> Pull shared memberships
-> Rebuild local cache

## 13. Phase Ownership

Phase 4A:

- account binding definition and boundary contract only

Phase 4B:

- secure runtime config boundary

Phase 4C:

- account identity runtime foundation

Phase 4D:

- account status UI
- defined in `docs/core/15_account_status_ui.md`
- visualizes account states only
- does not implement login/runtime auth

Phase 4E:

- enable Shared Pack active_v1_manual

Phase 4F:

- two-device Shared Pack QA

Phase 4G:

- Phase 4 closure

Phase 5:

- Personal Pack cloud migration

Phase 6:

- realtime/offline/advanced sync

## 14. Stop Conditions

Stop and return to this spec if:

- Codex adds OAuth in Phase 4A
- Codex adds Supabase.auth calls in Phase 4A
- Codex adds login/signup UI in Phase 4A
- Codex uploads Personal Pack data before Phase 5
- Codex changes Shared Pack request status to active_v1_manual before account/runtime identity is safe
- Codex stores tokens in backup/export
- Codex exposes Supabase/remote identity language to users
- Codex adds realtime/outbox/background sync
- Codex turns Local/Remote into product categories
- Codex claims Personal Pack cloud backup is complete in Phase 4A

## 15. Final Contract Statement

phase_4a_status: account_binding_definition_confirmed

Phase 4A defines the account binding product and data boundary.

It does not implement account binding runtime.

It does not activate Shared Pack production UI.

It does not migrate Personal Pack data.

The next phase is Phase 4B: Secure Runtime Config Boundary.
