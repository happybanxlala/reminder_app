# 16 Shared Pack Account Identity Bridge

## 1. Purpose

Phase 4E adds the Shared Pack account identity bridge.

Shared Pack requester identity now resolves through `AccountIdentityRuntime` by using `AccountBackedSharedPackIdentityProvider`.

Phase 4E does not activate Shared Pack production UI.

## 2. Relationship to Phase 4C

Reference: `docs/core/14_account_identity_runtime_foundation.md`

Phase 4E uses:

- `AccountIdentityRuntime`
- `AccountBackedSharedPackIdentityProvider`

The bridge does not call Supabase.

The bridge does not read runtime config.

The bridge does not store identity, tokens, or credentials.

## 3. Relationship to Phase 4D

Reference: `docs/core/15_account_status_ui.md`

Account Status UI remains informational.

The Settings account status display does not activate Shared Pack invite, join, refresh, or item-state update behavior.

## 4. Identity Resolution Rules

`bound` with identity:

- returns `accountId`

`unbound`:

- fails safely as account required / missing identity

`needsReauth`:

- fails safely as account verification required

`binding`:

- fails safely because binding is not complete

`bindingFailed`:

- fails safely because binding did not complete

## 5. Production Default

Default production account runtime remains unbound.

Therefore Shared Pack requester identity is not usable by default.

Shared Pack production UI remains unavailable / setup-required until real account binding and runtime activation are explicitly approved.

## 6. Static / Dev Identity Rule

`StaticSharedPackIdentityProvider` may remain only for tests and dev/manual harnesses.

Static/dev requester identity must not be used in production Shared Pack paths.

No fake device ID may be treated as account identity.

## 7. Request Catalog Status

Shared Pack v1 requests remain `implemented_not_wired`.

No request is marked `active_v1_manual` in Phase 4E.

No account_binding request is implemented or active in Phase 4E.

## 8. What Phase 4E Enables

Phase 4E enables:

- Shared Pack requester identity architecture to use account runtime
- future activation work after real account binding exists
- safer removal of static/dev identity from production-adjacent paths

## 9. What Phase 4E Does Not Enable

Phase 4E does not enable:

- login
- OAuth
- Supabase.auth
- Shared Pack production invite/join/refresh
- Personal Pack cloud migration
- restore
- realtime
- outbox
- background sync

## 10. Stop Conditions

Stop if:

- Shared Pack is marked active_v1_manual
- production UI is activated
- static/dev identity is used as production identity
- device ID is treated as account identity
- Supabase.auth is added
- login/OAuth is added
- Personal Pack migration starts

## 11. Final Status Marker

phase_4e_status: shared_pack_account_identity_bridge_added

Phase 4E adds the Shared Pack account identity bridge.

Default production account runtime remains unbound.

It does not implement real account binding.

It does not activate Shared Pack production UI.
