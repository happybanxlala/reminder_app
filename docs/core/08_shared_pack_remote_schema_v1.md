# 08 Shared Pack Remote Schema v1

This document is the remote schema contract for Shared Pack v1.

Phase 3B adds the first Supabase-side migration:

```text
supabase/migrations/20260630000000_shared_pack_v1_remote_schema.sql
```

The migration creates schema and RPC contracts. Phase 3D adds an isolated Flutter remote API boundary for these RPCs, but it does not wire Shared Pack remote behavior into UI, providers, app startup, Drift cache, routes, or user-facing flows.

## 1. Purpose

Shared Pack v1 is intentionally small. The remote contract only needs to support:

- Create Shared Pack.
- Generate invite code.
- Preview invite.
- Join by invite.
- Fetch remote snapshot manually.
- Update Shared Pack item state.

The core acceptance target for Shared Pack v1 remains:

```text
A updates a Shared Pack item.
B manually refreshes.
B can see A's update.
```

This document does not implement or design:

- Realtime sync.
- Outbox.
- Background sync.
- Account binding.
- Personal Pack cloud migration.
- Full cloud restore.
- Widget shared actions.
- Conflict resolution.

Phase 3D adds Flutter-side remote API methods only. The app still has no Supabase startup configuration, provider wiring, route changes, UI behavior changes, local cache writes, or user-facing runtime flow for Shared Pack remote behavior.

## 2. Product Model

The product model remains:

- Personal Pack is for individual use.
- Shared Pack is for multiple members.

Local / remote storage is a technical concern, not user-facing product language. Users should not need to understand whether a Pack is local-only, remote-backed, tied to a Supabase user, or tied to an anonymous identity.

Shared Pack v1 needs only enough remote authority to support manual refresh and shared item updates. It is not a full cloud sync system.

## 3. Minimum Remote Entities

Shared Pack v1 uses these minimum remote entities in Phase 3B:

1. `shared_packs`
2. `shared_pack_members`
3. `shared_pack_invites`
4. `shared_pack_items`

`shared_pack_item_states` is deferred for v1. Item state lives directly on `shared_pack_items` to keep the first Shared Pack remote model small. Do not over-model completion history in Phase 3B.

## 4. Proposed Tables

These tables are created by `supabase/migrations/20260630000000_shared_pack_v1_remote_schema.sql`.

### shared_packs

Purpose: represents one Shared Pack.

Suggested columns:

| Column | Draft type | Notes |
| --- | --- | --- |
| `id` | `uuid primary key` | Remote Pack ID. |
| `name` | `text not null` | User-facing Pack name. |
| `owner_identity_id` | `uuid not null` | Technical identity reference. Exact account-binding source is deferred. |
| `created_at` | `timestamptz` | Remote creation time. |
| `updated_at` | `timestamptz` | Remote update time. |
| `archived_at` | `timestamptz nullable` | Optional soft archive marker. |

Notes:

- `owner_identity_id` is a technical identity reference because account binding is not part of Shared Pack v1.
- Do not expose owner identity wording to users.
- Pack ownership is needed for permission and invite management.

### shared_pack_members

Purpose: represents membership in one Shared Pack.

Suggested columns:

| Column | Draft type | Notes |
| --- | --- | --- |
| `id` | `uuid primary key` | Membership row ID. |
| `pack_id` | `uuid references shared_packs(id)` | Shared Pack membership scope. |
| `member_identity_id` | `uuid not null` | Technical identity reference. Exact account-binding source is deferred. |
| `role` | `text default 'member'` | V1 only needs `owner` and `member`. |
| `joined_at` | `timestamptz` | Join time. |
| `removed_at` | `timestamptz nullable` | Optional soft removal marker. |

Role direction:

- V1 only needs owner / member.
- Do not implement owner / editor / viewer complexity yet.

### shared_pack_invites

Purpose: represents invite codes scoped to one Shared Pack.

Suggested columns:

| Column | Draft type | Notes |
| --- | --- | --- |
| `id` | `uuid primary key` | Invite row ID. |
| `pack_id` | `uuid references shared_packs(id)` | Invite resolves to one Shared Pack. |
| `code` | `text unique not null` | Canonical 6-character code. |
| `created_by_identity_id` | `uuid not null` | Technical identity reference. Exact account-binding source is deferred. |
| `created_at` | `timestamptz` | Invite creation time. |
| `expires_at` | `timestamptz nullable` | Optional for v1. |
| `revoked_at` | `timestamptz nullable` | Not required for v1. |

Invite code rules:

- Canonical stored/query code is 6 characters.
- Display may group as `K7M 4Q9`.
- Stored/query form should be `K7M4Q9`.
- Character set: `ABCDEFGHJKMNPQRSTUVWXYZ23456789`.
- Avoid ambiguous characters: `0`, `O`, `1`, `I`, `L`.
- Users should not be required to type spaces or hyphens.
- Invite code is scoped to one Shared Pack.
- Invite code must not represent a user, account, workspace, or local device.

For v1, expiry may be nullable / optional. Do not implement revoke, rotate, QR code, or deep link in v1.

### shared_pack_items

Purpose: represents the remote copy of items inside one Shared Pack.

Suggested columns:

| Column | Draft type | Notes |
| --- | --- | --- |
| `id` | `uuid primary key` | Remote item ID. |
| `pack_id` | `uuid references shared_packs(id)` | Shared Pack item scope. |
| `title` | `text not null` | Minimum item display label. |
| `notes` | `text nullable` | Optional item note. |
| `schedule_payload` | `jsonb nullable` | Draft schedule representation. |
| `state` | `text` | V1 item state if not using a separate state table. |
| `last_completed_at` | `timestamptz nullable` | Latest completion marker if represented in v1. |
| `updated_by_identity_id` | `uuid nullable` | Technical identity reference. Exact account-binding source is deferred. |
| `created_at` | `timestamptz` | Remote creation time. |
| `updated_at` | `timestamptz` | Remote update time. |
| `archived_at` | `timestamptz nullable` | Optional soft archive marker. |

Notes:

- Keep this minimal.
- Do not mirror the entire local Drift model unless required for Shared Pack v1.
- Use `jsonb` only for fields that are not stable enough yet.
- Avoid designing full completion history merge in v1.

### shared_pack_item_states Deferred

`shared_pack_item_states` is not created in the Phase 3B migration.

Deferred draft if item state later needs to be separated from item definition:

| Column | Draft type | Notes |
| --- | --- | --- |
| `id` | `uuid primary key` | State row ID. |
| `item_id` | `uuid references shared_pack_items(id)` | Remote item. |
| `pack_id` | `uuid references shared_packs(id)` | Shared Pack scope. |
| `state` | `text` | Current shared item state. |
| `last_completed_at` | `timestamptz nullable` | Latest completion marker if represented in v1. |
| `updated_by_identity_id` | `uuid` or `text`, TBD | Exact identity source is deferred. |
| `updated_at` | `timestamptz` | State update time. |

Decision: for v1, keep state directly on `shared_pack_items` unless a later implementation phase proves that item definition and state must be separated.

## 5. RPC Contracts

The Phase 3B migration creates these RPC functions:

| Request ID | RPC |
| --- | --- |
| `shared_pack.create_pack.v1` | `public.shared_pack_create_pack_v1` |
| `shared_pack.generate_invite.v1` | `public.shared_pack_generate_invite_v1` |
| `shared_pack.preview_invite.v1` | `public.shared_pack_preview_invite_v1` |
| `shared_pack.join_by_invite.v1` | `public.shared_pack_join_by_invite_v1` |
| `shared_pack.fetch_snapshot.v1` | `public.shared_pack_fetch_snapshot_v1` |
| `shared_pack.update_item_state.v1` | `public.shared_pack_update_item_state_v1` |

Support functions:

- `public.shared_pack_normalize_invite_code_v1`
- `public.shared_pack_random_invite_code_v1`
- `public.shared_pack_identity_matches_v1`
- `public.shared_pack_is_active_member_v1`
- `public.shared_pack_is_owner_v1`
- `public.set_updated_at`

## 6. Flutter Remote API Boundary

Flutter RPC wrappers live in:

```text
lib/features/shared_pack/remote/shared_pack_remote_api.dart
```

Implemented wrapper methods:

- `SharedPackRemoteApi.createPack`
- `SharedPackRemoteApi.generateInvite`
- `SharedPackRemoteApi.previewInvite`
- `SharedPackRemoteApi.joinByInvite`
- `SharedPackRemoteApi.fetchSnapshot`
- `SharedPackRemoteApi.updateItemState`

Boundary notes:

- `SharedPackRemoteApi` uses an injected RPC client.
- A private Supabase-backed RPC adapter is the only Supabase client adapter in this boundary.
- `SharedPackRemoteRepository` is a thin wrapper over the remote API.
- DTO parsing and invite-code normalization stay in the remote boundary.
- No UI, provider, app startup, route, realtime, outbox, background sync, account binding, personal cloud migration, or restore flow calls these methods yet.

## 6.1 Application Service Boundary

Phase 3F adds an isolated application service at:

```text
lib/features/shared_pack/application/shared_pack_application_service.dart
```

Implemented service methods:

- `SharedPackApplicationService.createSharedPack`
- `SharedPackApplicationService.generateInvite`
- `SharedPackApplicationService.previewInvite`
- `SharedPackApplicationService.joinByInvite`
- `SharedPackApplicationService.refreshSharedPack`
- `SharedPackApplicationService.updateSharedItemState`

Boundary notes:

- The service coordinates `SharedPackRemoteRepository`, `SharedPackCacheProjectionService`, and `SharedPackIdentityProvider`.
- Create, join, refresh, and item-state update flows require remote success before local cache projection.
- Generate invite and refresh resolve `local_pack_id -> remote_pack_id` through centralized mapping when the caller starts from a local Pack id.
- Item-state update resolves `local_item_id -> remote_item_id` through centralized mapping when the caller starts from a local item id.
- Missing mapping, identity failure, remote failure, and projection failure are returned as application-level results, not user-facing copy.
- `SharedPackIdentityProvider` is a temporary service boundary, not account binding, account protection, OAuth, or account switching.
- The service is not wired into UI, providers, routes, app startup, existing reminder completion actions, or Pack settings actions.
- Phase 4 or later must define account binding before this becomes a production user flow.

## 6.2 Dev-only Manual Flow Harness

Phase 3G adds a dev/manual-only executable harness at:

```text
test/shared_pack_dev_manual_flow_test.dart
```

Harness design:

- Uses deterministic fake remote state.
- Uses real `SharedPackApplicationService`.
- Uses real in-memory Drift `AppDatabase`.
- Uses real `SharedPackCacheProjectionService`.
- Uses `StaticSharedPackIdentityProvider` with owner and joiner dev/manual identities.
- Does not construct a real Supabase client.
- Does not require committed credentials.

Covered flow:

- Owner `createSharedPack`.
- Owner `generateInvite`.
- Joiner `previewInvite`.
- Joiner `joinByInvite`.
- Joiner `refreshSharedPack`.
- Member `updateSharedItemState`.
- Other member `refreshSharedPack` again.

Known limitation:

- The fake harness seeds one remote item as dev/manual test state.
- A real local Supabase manual run still needs SQL/manual setup for `shared_pack_items` until a later phase defines product item creation for Shared Pack.

Boundary notes:

- The harness is not reachable from production UI, providers, routes, or app startup.
- It does not make Shared Pack v1 user-active.
- Dev/manual identities are not account binding, account protection, OAuth, or account switching.

## 7. Identity Direction

Shared Pack v1 may require a remote identity before full account binding exists.

However:

- Do not design full account binding in Phase 3A.
- Do not expose anonymous identity language to users.
- Use implementation-neutral schema wording such as `identity_id`.
- Mark the exact identity source as TBD for a later phase.
- Phase 3B uses `uuid` identity columns to align with Supabase `auth.uid()` as a technical implementation detail.
- Do not add Google / Apple OAuth.
- Do not add account switching.

## 8. Local / Remote Mapping Direction

Phase 3E centralizes local / remote mapping:

- `local_pack_id <-> remote_pack_id`
- `local_item_id <-> remote_item_id`

Mapping expectations:

- Mapping must be centralized.
- Do not add unrelated mapping fields across multiple tables.
- Core model spec lists mapping tables / fields.
- Drift mapping tables are `shared_pack_remote_pack_mappings` and `shared_pack_remote_item_mappings`.
- Mapping is a technical cache concern, not a user-facing product category.

## 9. Local Cache Projection

Phase 3E adds a local cache projection foundation at:

```text
lib/features/shared_pack/data/shared_pack_cache_projection_service.dart
```

Mapping tables:

- `shared_pack_remote_pack_mappings`
- `shared_pack_remote_item_mappings`

Snapshot projection behavior:

- `FetchSharedPackSnapshotRemoteResponse` can create or update a local Shared Pack cache row.
- Projection preserves the existing `local_pack_id` when `remote_pack_id` is already mapped.
- Projection creates or updates local item cache rows for remote snapshot items.
- Projection preserves existing `local_item_id` values when `remote_item_id` is already mapped.
- Remote item `schedule_payload` is not converted in Phase 3E.
- Missing remote items are not deleted or archived during Phase 3E projection.

Item state projection behavior:

- `UpdateSharedPackItemStateRemoteResponse` updates mapped local item cache state fields only when `remote_item_id` mapping exists.
- If mapping is missing, projection returns a missing-mapping result and does not create a partial local item.
- Remote success is required before future app flows should call this projection.

Limitations:

- No UI wiring.
- No provider or app startup wiring.
- No deletion / archive reconciliation.
- No realtime.
- No outbox.
- No conflict resolution.
- No account binding.
- No personal cloud migration.
- No restore flow.

## 10. Request-to-Object Mapping

### shared_pack.create_pack.v1

Candidate objects:

- `shared_packs`
- `shared_pack_members`
- `public.shared_pack_create_pack_v1`

Operation: RPC.

Notes:

- Must create the Pack and owner membership together.
- See `docs/core/07_remote_request_catalog.md`.

### shared_pack.generate_invite.v1

Candidate object:

- `shared_pack_invites`
- `public.shared_pack_generate_invite_v1`

Operation: RPC.

Notes:

- Must generate a valid 6-character code.
- Must avoid ambiguous characters.
- Must scope invite to one Shared Pack.
- See `docs/core/07_remote_request_catalog.md`.

### shared_pack.preview_invite.v1

Candidate objects:

- `shared_pack_invites`
- `shared_packs`
- `public.shared_pack_preview_invite_v1`

Operation: RPC.

Notes:

- Should return Pack name and join availability only.
- See `docs/core/07_remote_request_catalog.md`.

### shared_pack.join_by_invite.v1

Candidate objects:

- `shared_pack_invites`
- `shared_pack_members`
- `public.shared_pack_join_by_invite_v1`

Operation: RPC.

Notes:

- Must validate invite and create membership.
- See `docs/core/07_remote_request_catalog.md`.

### shared_pack.fetch_snapshot.v1

Candidate objects:

- `shared_packs`
- `shared_pack_members`
- `shared_pack_items`
- `public.shared_pack_fetch_snapshot_v1`

Operation: RPC.

Notes:

- Manual refresh only.
- No realtime listener.
- See `docs/core/07_remote_request_catalog.md`.

### shared_pack.update_item_state.v1

Candidate objects:

- `shared_pack_items`
- `public.shared_pack_update_item_state_v1`

Operation: RPC.

Notes:

- Remote success is required before local cache update in v1.
- See `docs/core/07_remote_request_catalog.md`.

## 11. RLS Direction

Phase 3B enables RLS on:

- `public.shared_packs`
- `public.shared_pack_members`
- `public.shared_pack_invites`
- `public.shared_pack_items`

Current RLS status: enabled and conservative. Policies use active-member and owner helper functions. Exact account-binding source remains TBD.

- Only Pack members can read Shared Pack data.
- Only Pack members can update Shared Pack item state.
- Only the owner can manage invites in v1.
- Join by invite is handled through a safe RPC instead of broad invite table reads.
- Service role must not be used by the Flutter client.
- No service role key should ever be stored in the app or backup.

## 12. Manual Refresh Data Flow

Write flow:

```text
User action
-> local validation
-> shared_pack_remote_api
-> remote success
-> update local Drift cache
-> UI refresh
```

Read flow:

```text
User taps refresh
-> shared_pack_remote_api fetch snapshot
-> remote DTO
-> mapper
-> update local Drift cache
-> UI displays latest data
```

Shared Pack v1 does not include:

- Outbox.
- Optimistic remote sync.
- Realtime.
- Background sync.

## 13. Remote-side Smoke Test

Smoke test artifact:

```text
supabase/tests/shared_pack_v1_rpc_smoke_test.sql
```

Migration prerequisite:

```text
supabase/migrations/20260630000000_shared_pack_v1_remote_schema.sql
```

The smoke test is a manual/local SQL script. It runs in a transaction and ends with `ROLLBACK`, so it should not leave persistent test data.

Happy path coverage:

- Create pack through `public.shared_pack_create_pack_v1`.
- Confirm owner membership is created.
- Generate invite through `public.shared_pack_generate_invite_v1`.
- Confirm invite code length, allowed charset, and ambiguous-character exclusions.
- Preview invite through `public.shared_pack_preview_invite_v1`.
- Join by invite through `public.shared_pack_join_by_invite_v1`.
- Repeat join and confirm duplicate active membership is not created.
- Prepare one test item directly in `public.shared_pack_items` as smoke test setup only.
- Fetch snapshot through `public.shared_pack_fetch_snapshot_v1` as owner and member.
- Update item state through `public.shared_pack_update_item_state_v1`.
- Fetch snapshot again and confirm the updated item state is visible.

Negative case coverage:

- Invalid invite preview returns not joinable / no target Pack data.
- Invalid invite join fails and does not create membership.
- Non-member fetch fails.
- Non-member update fails and does not change item state.
- Direct insert of an invalid invite code is rejected by constraints.

Expected result:

- The SQL script completes without raised assertion errors.
- The final statement rolls back all smoke test data.

Local execution status:

- Passed on 2026-07-01 in a local Supabase database at `127.0.0.1:54322`.
- Execution command:
  `psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -f supabase/tests/shared_pack_v1_rpc_smoke_test.sql`
- Happy path and negative cases completed without raised assertion errors.
- No Flutter behavior changed as part of this remote-side smoke test.

Manual run path:

```text
psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -f supabase/tests/shared_pack_v1_rpc_smoke_test.sql
```

Known limitation:

- The script validates RPC membership checks with explicit `identity_id` values.
- Full JWT / auth-context testing remains for a later Supabase test setup.
- The Flutter app has isolated remote API methods, but no UI / provider / app flow calls these RPCs.

## 14. Open Questions

- What exact remote identity source will Shared Pack v1 use before full account binding?
- What is the minimum item payload needed to represent current Reminder App items?
- What full local cache refresh UI and manual trigger will call projection in a later phase?
- How will manual test accounts / dev identities be created without exposing technical identity language to users?

## 15. Phase 3B Acceptance Checklist

- Remote schema contract document exists.
- Minimum tables are documented.
- Invite code constraints are documented.
- Request IDs are mapped to proposed Supabase objects.
- RLS direction is documented.
- Local / remote mapping expectation is documented.
- No Dart Supabase request is implemented.
- Supabase migration exists at `supabase/migrations/20260630000000_shared_pack_v1_remote_schema.sql`.
- No UI behavior changes.
- All Shared Pack v1 request IDs remain planned.
