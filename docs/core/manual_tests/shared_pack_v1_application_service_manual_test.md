# Shared Pack v1 Application Service Manual Test

This is a future dev-only manual verification checklist for the isolated Shared Pack application service boundary.

It is not a production UI flow. The app does not currently expose Shared Pack create, invite, join, refresh, or shared item-state update behavior from normal navigation.

## Prerequisites

- Supabase-side Shared Pack v1 migration has been applied in a local development database.
- Remote RPC smoke test has passed separately.
- A dev/manual harness can construct `SharedPackApplicationService` with:
  - `SharedPackRemoteRepository`
  - `SharedPackCacheProjectionService`
  - `SharedPackIdentityProvider`
- Test identities are supplied by the harness or test code.

Do not commit Supabase URLs, anon keys, service role keys, database passwords, `DATABASE_URL`, access tokens, or refresh tokens.

## Flow

1. Provide identity A through `SharedPackIdentityProvider`.
2. Call `SharedPackApplicationService.createSharedPack`.
3. Verify the result includes a remote Pack id and local pack mapping.
4. Call `SharedPackApplicationService.generateInvite`.
5. Verify the invite code is returned and no invite metadata is written to Drift.
6. Provide identity B through `SharedPackIdentityProvider`.
7. Call `SharedPackApplicationService.previewInvite`.
8. Verify the preview resolves to one specific Shared Pack.
9. Call `SharedPackApplicationService.joinByInvite`.
10. Verify the result includes a local pack shell projection and pack mapping.
11. Call `SharedPackApplicationService.refreshSharedPack`.
12. Verify snapshot projection creates or updates local cache rows and item mappings.
13. Call `SharedPackApplicationService.updateSharedItemState`.
14. Verify remote success happens before local item-state projection.
15. Refresh from the other identity and verify projected cache reflects the remote item state.

## Expected Results

- Missing pack mapping returns an application-level missing mapping result before remote calls.
- Missing item mapping returns an application-level missing mapping result before remote calls.
- Remote failures do not project local cache.
- Projection failures are surfaced as application-level failures.
- No production UI, provider, route, app startup, realtime, outbox, background sync, account binding, restore, or widget shared action is involved.

## Current Status

Phase 3F adds the application service boundary and automated tests only. This manual flow remains future dev-only documentation until a separate phase adds an explicit dev harness.
