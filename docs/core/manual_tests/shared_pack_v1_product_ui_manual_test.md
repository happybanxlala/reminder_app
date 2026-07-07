# Shared Pack v1 Product UI Manual Test

This checklist documents the Phase 3H dev-gated product UI wiring.

The current app runtime is intentionally setup-required / disabled because production-safe Supabase config and a real identity source are not available yet. Do not commit URLs, anon keys, service role keys, database URLs, access tokens, refresh tokens, or local credentials.

## Phase 3H.5 Runtime Setup Decision

Decision document:

```text
docs/core/10_shared_pack_runtime_setup_decision.md
```

Current recommendation: `keep_dev_gated_until_phase_4`.

Product UI cannot be tested end-to-end against real Shared Pack remote behavior yet.

Reasons:

- no production-safe Supabase config convention
- no production identity provider
- device-scoped identity is not approved for production product activation in Phase 3
- Shared Pack membership recovery is unresolved before account binding
- product UI must not imply account protection, cloud backup, or restore before those exist

Current manual testing remains limited to:

- default setup-required product UI checks
- fake controller widget tests
- dev/manual application-service harnesses

Phase 4 or an explicitly approved runtime setup phase must provide safe config and identity before production product UI can call the real service.

## Current Executable UI Coverage

Run:

```sh
flutter test test/shared_pack_ux_shell_test.dart
```

The widget tests use fake `SharedPackUiController` overrides only.

Covered states:

- Pack member dialog shows setup-required by default.
- Fake-enabled owner invite flow shows loading, success, grouped code such as `K7M 4Q9`, and error states.
- Settings invite dialog accepts values such as `k7m 4q9`, normalizes them to `K7M4Q9` for submit, and displays grouped text.
- Fake-enabled Settings preview shows the target Pack name.
- Fake-enabled Settings confirm calls join through the controller.
- Preview does not write local cache.
- Manual refresh affordance appears only for mapped Pack contexts exposed by the fake controller.
- Existing Personal Pack completion remains on the local reminder repository path.

## Default Runtime Manual Check

1. Open Pack management.
2. Open a custom Pack overflow menu.
3. Choose members.
4. Verify the dialog shows setup-required copy and the invite action is disabled.
5. Open Settings.
6. Open the Shared Pack invite-code entry.
7. Verify the input and join flow remain setup-required / disabled.

Expected result: no remote request is made and no local cache projection occurs.

## What Cannot Be Tested From Production UI Yet

- Real invite generation.
- Real invite preview.
- Real join by invite.
- Real manual refresh from Supabase.
- Real shared item-state update.
- Two-device product UI QA.
- Membership recovery after reinstall, device loss, or account change.

## Future Two-device / Two-identity Manual Script

This script is intentionally future-only until safe runtime config and identity are supplied by a later phase.

1. Device or identity A opens a mapped Shared Pack.
2. Identity A generates a Pack-scoped invite code.
3. Device or identity B opens Settings.
4. Identity B enters the invite code with spaces or hyphens.
5. Identity B previews the Pack name.
6. Identity B confirms join.
7. Identity B manually refreshes the Shared Pack.
8. Identity B updates one mapped shared item state.
9. Identity A manually refreshes and sees the updated item state.

Expected result after future runtime wiring: remote success occurs before local cache projection, and each invite code resolves to one specific Shared Pack.

## Current Limitations

- No production-safe Supabase config provider.
- No production identity provider or account binding.
- No realtime.
- No outbox, retry queue, background sync, or conflict resolution.
- No backup restore or personal cloud migration.
- No home widget shared action.
- No product item creation flow for Shared Pack yet.
- Existing Personal Pack item completion remains local.
