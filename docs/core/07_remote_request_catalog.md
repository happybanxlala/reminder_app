# 07 Remote Request Catalog

This document is the required catalog for every future Supabase table, view, RPC, or auth-related remote request used by the app.

It is a planning and review guardrail. It does not define implemented remote behavior by itself, and placeholder entries in this document must not be treated as code, schema, SQL, RPC, auth, sync, or invite implementation.

## 1. Purpose

Remote behavior must be inspectable before implementation.

This catalog exists to prevent Supabase calls from being scattered across UI, pages, widgets, controllers, providers, debug flows, or one-off scripts. Every app remote request must have a stable Request ID, a known code entry point, a known Supabase object, a known local effect, and a known failure behavior.

The product language remains centered on:

- Personal Pack
- Shared Pack

Do not use Local Pack / Remote Pack, local-only, remote-backed, Supabase user, or anonymous identity as user-facing product categories.

## 2. Core Rule

- Every new Supabase request must be added to this catalog before implementation.
- UI, page, widget, controller, and provider layers must not directly call Supabase.
- Direct Supabase calls must be centralized in remote API / remote data source files.
- This catalog documents app remote requests, not service role scripts.
- Request IDs must be stable and referenced from code.
- Debug-only or manual-test remote flows still require catalog entries.

Forbidden outside approved remote API / data source files:

```dart
supabase.from(...)
supabase.rpc(...)
supabase.auth...
Supabase.instance...
SupabaseClient(...)
```

## 3. Request Entry Template

Every future request entry must include these fields.

| Field | Description |
| --- | --- |
| Request ID | Stable ID, for example `shared_pack.create_pack.v1` |
| Feature | `shared_pack` / `account_binding` / `personal_cloud_migration` / `cloud_restore` / `debug_or_manual_test` |
| Status | `planned` / `implemented_not_wired` / `active` / `deprecated` |
| Code entry | Actual Dart file and method that performs the request |
| Supabase object | Table / view / RPC / auth call name |
| Operation | `select` / `insert` / `update` / `delete` / `rpc` / `auth` |
| Auth required | `none` / `anonymous` / `linked_account` / `service_not_allowed` |
| Input DTO | Request input model |
| Output DTO | Response model |
| Local effect | Whether it writes to Drift / cache / mapping |
| Error behavior | How failures are surfaced to UI |
| Test coverage | Unit / integration / manual test reference |
| Notes | RLS, limitations, future changes |

Template:

```text
### request_id.v1

| Field | Value |
| --- | --- |
| Request ID | request_id.v1 |
| Feature | feature_name |
| Status | planned |
| Code entry | Not implemented |
| Supabase object | Undecided |
| Operation | Undecided |
| Auth required | Undecided |
| Input DTO | Not implemented |
| Output DTO | Not implemented |
| Local effect | None in current phase |
| Error behavior | Not implemented |
| Test coverage | Not implemented |
| Notes | Planned placeholder only |
```

Status meaning:

- `planned`: documented but no Dart request implementation exists yet.
- `implemented_not_wired`: Dart remote API, isolated application boundary, and/or dev-gated product UI facade exists, but no production-safe remote config, identity source, provider wiring, app startup, or active user-facing remote flow calls it yet.
- `active`: reachable from production app UI / provider / app startup / user-facing flow.
- `deprecated`: retained only for compatibility or migration review.

## 4. Request ID Convention

Use:

```text
feature.action_or_resource.vN
```

Examples:

- `shared_pack.create_pack.v1`
- `shared_pack.generate_invite.v1`
- `shared_pack.preview_invite.v1`
- `shared_pack.join_by_invite.v1`
- `shared_pack.fetch_snapshot.v1`
- `shared_pack.update_item_state.v1`
- `account_binding.bind_account.v1`
- `personal_cloud_migration.upload_pack.v1`
- `cloud_restore.fetch_account_snapshot.v1`

Rules:

- Use snake_case.
- Use stable IDs.
- Increment `vN` only when behavior or contract changes.
- Do not reuse deprecated IDs for different behavior.
- Keep request IDs product / feature oriented, not table oriented when possible.

## 5. Future Code Boundary

Phase 3D keeps Shared Pack remote behavior inside this boundary. It is not wired into UI, providers, app startup, Drift writes, auth setup, sync, routes, or user-visible behavior.

```text
lib/features/shared_pack/remote/
  shared_pack_remote_api.dart
  shared_pack_remote_dto.dart
  shared_pack_remote_mapper.dart
  shared_pack_remote_request_ids.dart
  shared_pack_remote_repository.dart
```

Responsibilities:

- `shared_pack_remote_api.dart` is the only Shared Pack location allowed to call Supabase RPCs directly.
- `shared_pack_remote_request_ids.dart` mirrors Request IDs listed in this catalog.
- `shared_pack_remote_dto.dart` owns remote input / output DTOs.
- `shared_pack_remote_mapper.dart` owns remote response parsing and invite-code normalization only.
- `shared_pack_remote_repository.dart` is a thin wrapper over the remote API.

UI, pages, widgets, controllers, and providers must call application / repository methods, not Supabase directly.

Phase 3H adds a dev-gated product UI facade, still without production remote runtime wiring:

```text
lib/features/shared_pack/application/shared_pack_ui_controller.dart
```

Responsibilities:

- `SharedPackUiController` is the only UI-facing Shared Pack remote facade.
- The default provider returns setup-required / disabled because production-safe Supabase config and identity are not available yet.
- Tests may override the controller with fakes to exercise owner invite, Settings join, and manual refresh UI states.
- UI, pages, widgets, controllers, and providers still must not call Supabase directly.

## 6. Shared Pack v1 Remote API Requests

All entries in this section have Flutter remote API implementations and an isolated application service boundary. Phase 3H adds dev-gated UI/controller affordances, but they must not be treated as production-active behavior because production-safe Supabase config and a real identity provider are still unavailable.

Schema contract reference: `docs/core/08_shared_pack_remote_schema_v1.md`.
Migration reference: `supabase/migrations/20260630000000_shared_pack_v1_remote_schema.sql`.
Local cache mapping tables: `shared_pack_remote_pack_mappings` for `local_pack_id <-> remote_pack_id`, and `shared_pack_remote_item_mappings` for `local_item_id <-> remote_item_id`.
Remote-side smoke test reference: `supabase/tests/shared_pack_v1_rpc_smoke_test.sql` passed on 2026-07-01 against local Supabase / `psql`.
Dev/manual flow harness reference: `test/shared_pack_dev_manual_flow_test.dart`; this exercises the application service boundary with fake remote state and in-memory Drift only, and does not make any request production-active.
Dev-gated product UI test reference: `test/shared_pack_ux_shell_test.dart`; this uses fake controller overrides only and does not make any request production-active.
Runtime setup decision reference: `docs/core/10_shared_pack_runtime_setup_decision.md`; Phase 3H.5 keeps Shared Pack v1 dev-gated until Phase 4 account binding / runtime setup is resolved.
Phase 3 closure reference: `docs/core/11_shared_pack_phase_3_closure.md`; Phase 3 is closed as a dev-gated foundation and activation waits for Phase 4.
Phase 4A account binding contract reference: `docs/core/12_account_binding_foundation_spec.md`. Phase 4A is contract-only; account_binding requests remain future placeholders and are not implemented or active.
Phase 4B secure runtime config boundary reference: `docs/core/13_secure_runtime_config_boundary.md`. Config loading is not a Supabase request; Phase 4B adds no table/RPC request entries and does not activate existing requests.
Phase 4C account identity runtime reference: `docs/core/14_account_identity_runtime_foundation.md`. Identity runtime is not a Supabase request; Phase 4C adds no table/RPC request entries and does not activate existing requests.
Phase 4D account status UI reference: `docs/core/15_account_status_ui.md`. Account status UI is local runtime/status UI only; it is not a Supabase request, adds no table/RPC entries, and does not activate Shared Pack or account_binding requests.
Phase 4E Shared Pack account identity bridge reference: `docs/core/16_shared_pack_account_identity_bridge.md`. The bridge resolves requester identity through `AccountIdentityRuntime`; it is not a Supabase request, adds no table/RPC entries, and does not activate Shared Pack or account_binding requests.

### shared_pack.create_pack.v1

| Field | Value |
| --- | --- |
| Request ID | `shared_pack.create_pack.v1` |
| Feature | `shared_pack` |
| Status | `implemented_not_wired` |
| Code entry | `lib/features/shared_pack/remote/shared_pack_remote_api.dart` / `SharedPackRemoteApi.createPack`; `lib/features/shared_pack/application/shared_pack_application_service.dart` / `SharedPackApplicationService.createSharedPack` |
| Supabase object | `public.shared_pack_create_pack_v1`, `public.shared_packs`, `public.shared_pack_members` |
| Operation | `rpc` |
| Auth required | Undecided |
| Input DTO | `CreateSharedPackRemoteRequest` |
| Output DTO | `CreateSharedPackRemoteResponse` |
| Local effect | Phase 3F application service calls remote create first, then projects a local Shared Pack cache shell and `local_pack_id <-> remote_pack_id` mapping after remote success; not wired into production app flow yet |
| Error behavior | `SharedPackRemoteException` is wrapped as `SharedPackApplicationErrorCode.remoteFailure` with request ID; projection failure is surfaced as `projectionFailure`; identity failure is `missingIdentity`; not user-facing |
| Test coverage | Dev/manual flow harness: `test/shared_pack_dev_manual_flow_test.dart`; application service tests: `test/shared_pack_application_service_test.dart`; Flutter API tests: `test/shared_pack_remote_api_test.dart`; boundary/catalog/schema/migration/smoke guardrails: `test/shared_pack_remote_boundary_test.dart`, `test/shared_pack_remote_schema_contract_test.dart`, `test/shared_pack_remote_migration_contract_test.dart`, `test/shared_pack_rpc_smoke_test_contract_test.dart`; manual SQL artifact passed locally on 2026-07-01: `supabase/tests/shared_pack_v1_rpc_smoke_test.sql` |
| Notes | Flutter remote API and isolated application service implementation exist, but no production UI/provider/app flow calls create yet. Phase 3H does not add Shared Pack creation or Pack conversion UI. Migration: `supabase/migrations/20260630000000_shared_pack_v1_remote_schema.sql`. Schema contract: `docs/core/08_shared_pack_remote_schema_v1.md`. |

### shared_pack.generate_invite.v1

| Field | Value |
| --- | --- |
| Request ID | `shared_pack.generate_invite.v1` |
| Feature | `shared_pack` |
| Status | `implemented_not_wired` |
| Code entry | `lib/features/shared_pack/remote/shared_pack_remote_api.dart` / `SharedPackRemoteApi.generateInvite`; `lib/features/shared_pack/application/shared_pack_application_service.dart` / `SharedPackApplicationService.generateInvite`; `lib/features/shared_pack/application/shared_pack_ui_controller.dart` / `SharedPackUiController.generateInvite`; `lib/features/reminders/ui/pages/feature_page_packs.dart` / Pack member dialog |
| Supabase object | `public.shared_pack_generate_invite_v1`, `public.shared_pack_invites` |
| Operation | `rpc` |
| Auth required | Undecided |
| Input DTO | `GenerateSharedPackInviteRemoteRequest` |
| Output DTO | `GenerateSharedPackInviteRemoteResponse` |
| Local effect | Application service resolves `local_pack_id -> remote_pack_id` when needed, then calls remote generate; no Drift write for invite metadata in v1 |
| Error behavior | Missing local pack mapping returns `missingPackMapping` before remote call; remote failures are `remoteFailure` with request ID; identity failure is `missingIdentity`; default product UI shows setup-required and does not call remote |
| Test coverage | Dev-gated UI tests: `test/shared_pack_ux_shell_test.dart`; dev/manual flow harness: `test/shared_pack_dev_manual_flow_test.dart`; application service tests: `test/shared_pack_application_service_test.dart`; Flutter API tests: `test/shared_pack_remote_api_test.dart`; boundary/catalog/schema/migration/smoke guardrails: `test/shared_pack_remote_boundary_test.dart`, `test/shared_pack_remote_schema_contract_test.dart`, `test/shared_pack_remote_migration_contract_test.dart`, `test/shared_pack_rpc_smoke_test_contract_test.dart`; manual SQL artifact passed locally on 2026-07-01: `supabase/tests/shared_pack_v1_rpc_smoke_test.sql` |
| Notes | Phase 3H owner-side Pack member UI can call this only through a fake/dev override. Default production runtime remains disabled because production-safe Supabase config and identity provider are unavailable. SQL generation uses 6-character codes from `ABCDEFGHJKMNPQRSTUVWXYZ23456789`. Migration: `supabase/migrations/20260630000000_shared_pack_v1_remote_schema.sql`. Schema contract: `docs/core/08_shared_pack_remote_schema_v1.md`. |

### shared_pack.preview_invite.v1

| Field | Value |
| --- | --- |
| Request ID | `shared_pack.preview_invite.v1` |
| Feature | `shared_pack` |
| Status | `implemented_not_wired` |
| Code entry | `lib/features/shared_pack/remote/shared_pack_remote_api.dart` / `SharedPackRemoteApi.previewInvite`; `lib/features/shared_pack/application/shared_pack_application_service.dart` / `SharedPackApplicationService.previewInvite`; `lib/features/shared_pack/application/shared_pack_ui_controller.dart` / `SharedPackUiController.previewInvite`; `lib/features/reminders/ui/pages/feature_page_settings.dart` / Settings join dialog |
| Supabase object | `public.shared_pack_preview_invite_v1`, `public.shared_pack_invites`, `public.shared_packs` |
| Operation | `rpc` |
| Auth required | Undecided |
| Input DTO | `PreviewSharedPackInviteRemoteRequest` |
| Output DTO | `PreviewSharedPackInviteRemoteResponse` |
| Local effect | No Drift write; preview only |
| Error behavior | Invalid input returns `invalidInput`; remote failures are `remoteFailure` with request ID; default product UI shows setup-required and does not call remote |
| Test coverage | Dev-gated UI tests: `test/shared_pack_ux_shell_test.dart`; dev/manual flow harness: `test/shared_pack_dev_manual_flow_test.dart`; application service tests: `test/shared_pack_application_service_test.dart`; Flutter API tests: `test/shared_pack_remote_api_test.dart`; boundary/catalog/schema/migration/smoke guardrails: `test/shared_pack_remote_boundary_test.dart`, `test/shared_pack_remote_schema_contract_test.dart`, `test/shared_pack_remote_migration_contract_test.dart`, `test/shared_pack_rpc_smoke_test_contract_test.dart`; manual SQL artifact passed locally on 2026-07-01: `supabase/tests/shared_pack_v1_rpc_smoke_test.sql` |
| Notes | Phase 3H Settings join UI can preview only through a fake/dev override. Preview accepts spaces/hyphens and submits a normalized Pack-scoped invite code. Invite code resolves to one specific Pack, not a user workspace. Migration: `supabase/migrations/20260630000000_shared_pack_v1_remote_schema.sql`. Schema contract: `docs/core/08_shared_pack_remote_schema_v1.md`. |

### shared_pack.join_by_invite.v1

| Field | Value |
| --- | --- |
| Request ID | `shared_pack.join_by_invite.v1` |
| Feature | `shared_pack` |
| Status | `implemented_not_wired` |
| Code entry | `lib/features/shared_pack/remote/shared_pack_remote_api.dart` / `SharedPackRemoteApi.joinByInvite`; `lib/features/shared_pack/application/shared_pack_application_service.dart` / `SharedPackApplicationService.joinByInvite`; `lib/features/shared_pack/application/shared_pack_ui_controller.dart` / `SharedPackUiController.joinByInvite`; `lib/features/reminders/ui/pages/feature_page_settings.dart` / Settings join dialog |
| Supabase object | `public.shared_pack_join_by_invite_v1`, `public.shared_pack_invites`, `public.shared_pack_members` |
| Operation | `rpc` |
| Auth required | Undecided |
| Input DTO | `JoinSharedPackByInviteRemoteRequest` |
| Output DTO | `JoinSharedPackByInviteRemoteResponse` |
| Local effect | Application service calls remote join first, then projects a local Shared Pack cache shell and `local_pack_id <-> remote_pack_id` mapping after remote success; snapshot refresh remains a separate explicit service call |
| Error behavior | Invalid input returns `invalidInput`; remote failures are `remoteFailure` with request ID; projection failures are `projectionFailure`; identity failure is `missingIdentity`; default product UI shows setup-required and does not call remote |
| Test coverage | Dev-gated UI tests: `test/shared_pack_ux_shell_test.dart`; dev/manual flow harness: `test/shared_pack_dev_manual_flow_test.dart`; application service tests: `test/shared_pack_application_service_test.dart`; Flutter API tests: `test/shared_pack_remote_api_test.dart`; boundary/catalog/schema/migration/smoke guardrails: `test/shared_pack_remote_boundary_test.dart`, `test/shared_pack_remote_schema_contract_test.dart`, `test/shared_pack_remote_migration_contract_test.dart`, `test/shared_pack_rpc_smoke_test_contract_test.dart`; manual SQL artifact passed locally on 2026-07-01: `supabase/tests/shared_pack_v1_rpc_smoke_test.sql` |
| Notes | Phase 3H Settings join UI can confirm only through a fake/dev override. Default production runtime remains disabled because production-safe Supabase config and identity provider are unavailable. RPC validates invite and creates or returns active membership. Migration: `supabase/migrations/20260630000000_shared_pack_v1_remote_schema.sql`. Schema contract: `docs/core/08_shared_pack_remote_schema_v1.md`. |

### shared_pack.fetch_snapshot.v1

| Field | Value |
| --- | --- |
| Request ID | `shared_pack.fetch_snapshot.v1` |
| Feature | `shared_pack` |
| Status | `implemented_not_wired` |
| Code entry | `lib/features/shared_pack/remote/shared_pack_remote_api.dart` / `SharedPackRemoteApi.fetchSnapshot`; `lib/features/shared_pack/application/shared_pack_application_service.dart` / `SharedPackApplicationService.refreshSharedPack`; `lib/features/shared_pack/application/shared_pack_ui_controller.dart` / `SharedPackUiController.refreshSharedPack`; `lib/features/reminders/ui/pages/feature_page_packs.dart` / mapped Pack member dialog refresh affordance |
| Supabase object | `public.shared_pack_fetch_snapshot_v1`, `public.shared_packs`, `public.shared_pack_members`, `public.shared_pack_items` |
| Operation | `rpc` |
| Auth required | Undecided |
| Input DTO | `FetchSharedPackSnapshotRemoteRequest` |
| Output DTO | `FetchSharedPackSnapshotRemoteResponse`, `SharedPackSnapshotItemRemoteDto` |
| Local effect | Application service resolves `local_pack_id -> remote_pack_id` when needed, calls remote snapshot fetch, then projects the snapshot into local Drift cache and maintains pack/item mappings after remote success |
| Error behavior | Missing local pack mapping returns `missingPackMapping` before remote call; remote failures are `remoteFailure` with request ID; projection failures are `projectionFailure`; identity failure is `missingIdentity`; default product UI shows setup-required and does not call remote |
| Test coverage | Dev-gated UI tests: `test/shared_pack_ux_shell_test.dart`; dev/manual flow harness: `test/shared_pack_dev_manual_flow_test.dart`; application service tests: `test/shared_pack_application_service_test.dart`; Flutter API tests: `test/shared_pack_remote_api_test.dart`; boundary/catalog/schema/migration/smoke guardrails: `test/shared_pack_remote_boundary_test.dart`, `test/shared_pack_remote_schema_contract_test.dart`, `test/shared_pack_remote_migration_contract_test.dart`, `test/shared_pack_rpc_smoke_test_contract_test.dart`; manual SQL artifact passed locally on 2026-07-01: `supabase/tests/shared_pack_v1_rpc_smoke_test.sql` |
| Notes | Phase 3H adds a refresh affordance only for mapped Pack contexts when a fake/dev controller exposes it. Default production runtime remains disabled; no realtime listener. `shared_pack_item_states` is deferred for v1. Migration: `supabase/migrations/20260630000000_shared_pack_v1_remote_schema.sql`. Schema contract: `docs/core/08_shared_pack_remote_schema_v1.md`. |

### shared_pack.update_item_state.v1

| Field | Value |
| --- | --- |
| Request ID | `shared_pack.update_item_state.v1` |
| Feature | `shared_pack` |
| Status | `implemented_not_wired` |
| Code entry | `lib/features/shared_pack/remote/shared_pack_remote_api.dart` / `SharedPackRemoteApi.updateItemState`; `lib/features/shared_pack/application/shared_pack_application_service.dart` / `SharedPackApplicationService.updateSharedItemState`; `lib/features/shared_pack/application/shared_pack_ui_controller.dart` / `SharedPackUiController.updateSharedItemState` |
| Supabase object | `public.shared_pack_update_item_state_v1`, `public.shared_pack_items` |
| Operation | `rpc` |
| Auth required | Undecided |
| Input DTO | `UpdateSharedPackItemStateRemoteRequest` |
| Output DTO | `UpdateSharedPackItemStateRemoteResponse` |
| Local effect | Application service resolves `local_item_id -> remote_item_id` when needed, calls remote update, then projects item-state response into mapped local cache after remote success; no optimistic local update |
| Error behavior | Missing local item mapping returns `missingItemMapping` before remote call; remote failures are `remoteFailure` with request ID; projection failures are `projectionFailure`; identity failure is `missingIdentity`; default product UI does not call remote |
| Test coverage | Dev/manual flow harness: `test/shared_pack_dev_manual_flow_test.dart`; application service tests: `test/shared_pack_application_service_test.dart`; Flutter API tests: `test/shared_pack_remote_api_test.dart`; boundary/catalog/schema/migration/smoke guardrails: `test/shared_pack_remote_boundary_test.dart`, `test/shared_pack_remote_schema_contract_test.dart`, `test/shared_pack_remote_migration_contract_test.dart`, `test/shared_pack_rpc_smoke_test_contract_test.dart`; manual SQL artifact passed locally on 2026-07-01: `supabase/tests/shared_pack_v1_rpc_smoke_test.sql`; production completion guardrail: `test/shared_pack_remote_boundary_test.dart` |
| Notes | Phase 3H adds a UI-controller facade method only. Existing Personal Pack completion remains local and does not call Shared Pack remote state update. Remote success is required before local cache projection. No outbox. `shared_pack_item_states` is deferred for v1. Migration: `supabase/migrations/20260630000000_shared_pack_v1_remote_schema.sql`. Schema contract: `docs/core/08_shared_pack_remote_schema_v1.md`. |

## 7. Planned Requests: Account Binding

Future only. Not part of Shared Pack v1. Phase 4A defines the account binding product/data boundary only and does not implement account_binding remote requests.

- `account_binding.bind_account.v1`
- `account_binding.get_status.v1`

No account_binding request entries are implemented or active in the current phase.

## 8. Planned Requests: Personal Cloud Migration

Future only. Not part of Shared Pack v1.

- `personal_cloud_migration.upload_pack.v1`
- `personal_cloud_migration.upload_item.v1`
- `personal_cloud_migration.fetch_personal_snapshot.v1`

No request entries are active in the current phase.

## 9. Planned Requests: Cloud Restore

Future only. Not part of Shared Pack v1.

- `cloud_restore.fetch_account_snapshot.v1`
- `cloud_restore.rebuild_local_cache.v1`

No request entries are active in the current phase.

## 10. Planned Requests: Debug Or Manual Test

Future debug or manual-test requests must still be cataloged before implementation.

No request entries are active in the current phase.

## 11. Forbidden Patterns

- Calling `supabase.from(...)` directly from UI / page / widget / controller / provider.
- Calling `supabase.rpc(...)` directly from UI / page / widget / controller / provider.
- Calling `Supabase.instance...` directly from UI / page / widget / controller / provider.
- Creating `SupabaseClient` directly in UI / page / widget / controller / provider.
- Adding a new Supabase request without a catalog entry.
- Adding realtime, outbox, or background sync inside Shared Pack v1.
- Using Local / Remote as the main user-facing product classification.
- Putting Supabase tokens or credentials into backup / export files.
- Adding debug-only remote flows without catalog entries.

## 12. Manual Review Checklist

Before adding or changing any remote request, answer:

- Is the request listed in this catalog?
- Does the Request ID exist in code?
- Which file performs the Supabase call?
- Which Supabase object is called?
- Does it require auth?
- What DTO is used?
- What local cache / Drift table is affected?
- What happens when the request fails?
- Is there a unit, integration, or manual test?
- Is the user-facing language Personal / Shared rather than Local / Remote?
