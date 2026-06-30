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
| Status | `planned` / `active` / `deprecated` |
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

Phase 2B creates these files as compile-only boundary placeholders. They are not wired into runtime and do not implement Supabase calls, Drift writes, auth, invite validation, sync, routes, or UI behavior.

```text
lib/features/shared_pack/remote/
  shared_pack_remote_api.dart
  shared_pack_remote_dto.dart
  shared_pack_remote_mapper.dart
  shared_pack_remote_request_ids.dart
  shared_pack_remote_repository.dart
```

Expected responsibilities:

- `shared_pack_remote_api.dart` is the only future Shared Pack location allowed to call Supabase table / RPC directly.
- `shared_pack_remote_request_ids.dart` mirrors Request IDs listed in this catalog.
- `shared_pack_remote_dto.dart` owns remote input / output DTOs.
- `shared_pack_remote_mapper.dart` converts remote DTOs to local / domain / cache models.
- `shared_pack_remote_repository.dart` exposes clean methods to domain or application layers.

UI, pages, widgets, controllers, and providers must call application / repository methods, not Supabase directly.

## 6. Planned Requests: Shared Pack v1

All entries in this section are planned placeholders only. They must not be treated as implemented behavior.

Schema contract reference: `docs/core/08_shared_pack_remote_schema_v1.md`.
Migration reference: `supabase/migrations/20260630000000_shared_pack_v1_remote_schema.sql`.

### shared_pack.create_pack.v1

| Field | Value |
| --- | --- |
| Request ID | `shared_pack.create_pack.v1` |
| Feature | `shared_pack` |
| Status | `planned` |
| Code entry | `lib/features/shared_pack/remote/shared_pack_remote_api.dart` / `SharedPackRemoteApi.createPack` |
| Supabase object | `public.shared_pack_create_pack_v1`, `public.shared_packs`, `public.shared_pack_members` |
| Operation | `rpc` |
| Auth required | Undecided |
| Input DTO | Not implemented |
| Output DTO | Not implemented |
| Local effect | After remote success, create or update `local_pack_id <-> remote_pack_id` mapping |
| Error behavior | Not implemented |
| Test coverage | Schema and migration guardrails only: `test/shared_pack_remote_schema_contract_test.dart`, `test/shared_pack_remote_migration_contract_test.dart` |
| Notes | Planned only; Flutter does not call this request yet. Migration: `supabase/migrations/20260630000000_shared_pack_v1_remote_schema.sql`. Schema contract: `docs/core/08_shared_pack_remote_schema_v1.md`. |

### shared_pack.generate_invite.v1

| Field | Value |
| --- | --- |
| Request ID | `shared_pack.generate_invite.v1` |
| Feature | `shared_pack` |
| Status | `planned` |
| Code entry | `lib/features/shared_pack/remote/shared_pack_remote_api.dart` / `SharedPackRemoteApi.generateInvite` |
| Supabase object | `public.shared_pack_generate_invite_v1`, `public.shared_pack_invites` |
| Operation | `rpc` |
| Auth required | Undecided |
| Input DTO | Not implemented |
| Output DTO | Not implemented |
| Local effect | None until remote success; may update cached invite metadata in later phase |
| Error behavior | Not implemented |
| Test coverage | Schema and migration guardrails only: `test/shared_pack_remote_schema_contract_test.dart`, `test/shared_pack_remote_migration_contract_test.dart` |
| Notes | Planned only; Flutter does not call this request yet. SQL generation uses 6-character codes from `ABCDEFGHJKLMNPQRSTUVWXYZ23456789`. Migration: `supabase/migrations/20260630000000_shared_pack_v1_remote_schema.sql`. Schema contract: `docs/core/08_shared_pack_remote_schema_v1.md`. |

### shared_pack.preview_invite.v1

| Field | Value |
| --- | --- |
| Request ID | `shared_pack.preview_invite.v1` |
| Feature | `shared_pack` |
| Status | `planned` |
| Code entry | `lib/features/shared_pack/remote/shared_pack_remote_api.dart` / `SharedPackRemoteApi.previewInvite` |
| Supabase object | `public.shared_pack_preview_invite_v1`, `public.shared_pack_invites`, `public.shared_packs` |
| Operation | `rpc` |
| Auth required | Undecided |
| Input DTO | Not implemented |
| Output DTO | Not implemented |
| Local effect | No Drift write; preview only |
| Error behavior | Not implemented |
| Test coverage | Schema and migration guardrails only: `test/shared_pack_remote_schema_contract_test.dart`, `test/shared_pack_remote_migration_contract_test.dart` |
| Notes | Planned only; Flutter does not call this request yet. Invite code resolves to one specific Pack, not a user workspace. Migration: `supabase/migrations/20260630000000_shared_pack_v1_remote_schema.sql`. Schema contract: `docs/core/08_shared_pack_remote_schema_v1.md`. |

### shared_pack.join_by_invite.v1

| Field | Value |
| --- | --- |
| Request ID | `shared_pack.join_by_invite.v1` |
| Feature | `shared_pack` |
| Status | `planned` |
| Code entry | `lib/features/shared_pack/remote/shared_pack_remote_api.dart` / `SharedPackRemoteApi.joinByInvite` |
| Supabase object | `public.shared_pack_join_by_invite_v1`, `public.shared_pack_invites`, `public.shared_pack_members` |
| Operation | `rpc` |
| Auth required | Undecided |
| Input DTO | Not implemented |
| Output DTO | Not implemented |
| Local effect | After remote success, create or update Shared Pack local cache / mapping |
| Error behavior | Not implemented |
| Test coverage | Schema and migration guardrails only: `test/shared_pack_remote_schema_contract_test.dart`, `test/shared_pack_remote_migration_contract_test.dart` |
| Notes | Planned only; Flutter does not call this request yet. RPC validates invite and creates or returns active membership. Migration: `supabase/migrations/20260630000000_shared_pack_v1_remote_schema.sql`. Schema contract: `docs/core/08_shared_pack_remote_schema_v1.md`. |

### shared_pack.fetch_snapshot.v1

| Field | Value |
| --- | --- |
| Request ID | `shared_pack.fetch_snapshot.v1` |
| Feature | `shared_pack` |
| Status | `planned` |
| Code entry | `lib/features/shared_pack/remote/shared_pack_remote_api.dart` / `SharedPackRemoteApi.fetchSnapshot` |
| Supabase object | `public.shared_pack_fetch_snapshot_v1`, `public.shared_packs`, `public.shared_pack_members`, `public.shared_pack_items` |
| Operation | `rpc` |
| Auth required | Undecided |
| Input DTO | Not implemented |
| Output DTO | Not implemented |
| Local effect | Update local Drift cache after successful manual refresh |
| Error behavior | Not implemented |
| Test coverage | Schema and migration guardrails only: `test/shared_pack_remote_schema_contract_test.dart`, `test/shared_pack_remote_migration_contract_test.dart` |
| Notes | Planned only; Flutter does not call this request yet. Manual refresh only; no realtime listener. `shared_pack_item_states` is deferred for v1. Migration: `supabase/migrations/20260630000000_shared_pack_v1_remote_schema.sql`. Schema contract: `docs/core/08_shared_pack_remote_schema_v1.md`. |

### shared_pack.update_item_state.v1

| Field | Value |
| --- | --- |
| Request ID | `shared_pack.update_item_state.v1` |
| Feature | `shared_pack` |
| Status | `planned` |
| Code entry | `lib/features/shared_pack/remote/shared_pack_remote_api.dart` / `SharedPackRemoteApi.updateItemState` |
| Supabase object | `public.shared_pack_update_item_state_v1`, `public.shared_pack_items` |
| Operation | `rpc` |
| Auth required | Undecided |
| Input DTO | Not implemented |
| Output DTO | Not implemented |
| Local effect | Update local Drift cache only after remote success |
| Error behavior | Not implemented |
| Test coverage | Schema and migration guardrails only: `test/shared_pack_remote_schema_contract_test.dart`, `test/shared_pack_remote_migration_contract_test.dart` |
| Notes | Planned only; Flutter does not call this request yet. Remote success is required before local cache update in v1. No outbox. `shared_pack_item_states` is deferred for v1. Migration: `supabase/migrations/20260630000000_shared_pack_v1_remote_schema.sql`. Schema contract: `docs/core/08_shared_pack_remote_schema_v1.md`. |

## 7. Planned Requests: Account Binding

Future only. Not part of Shared Pack v1.

- `account_binding.bind_account.v1`
- `account_binding.get_status.v1`

No request entries are active in the current phase.

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
