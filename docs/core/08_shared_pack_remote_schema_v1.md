# 08 Shared Pack Remote Schema v1

This document is the remote schema contract for Shared Pack v1.

Phase 3B adds the first Supabase-side migration:

```text
supabase/migrations/20260630000000_shared_pack_v1_remote_schema.sql
```

The migration creates schema and RPC contracts only. It does not wire the Flutter app to Supabase, and Shared Pack remote behavior is not usable from the app yet.

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

Phase 3B adds Supabase-side foundation only. The Flutter app still has no Supabase client wiring, provider wiring, route changes, UI behavior changes, local cache writes, or runtime calls for Shared Pack remote behavior.

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
- Character set: `ABCDEFGHJKLMNPQRSTUVWXYZ23456789`.
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

## 6. Identity Direction

Shared Pack v1 may require a remote identity before full account binding exists.

However:

- Do not design full account binding in Phase 3A.
- Do not expose anonymous identity language to users.
- Use implementation-neutral schema wording such as `identity_id`.
- Mark the exact identity source as TBD for a later phase.
- Phase 3B uses `uuid` identity columns to align with Supabase `auth.uid()` as a technical implementation detail.
- Do not add Google / Apple OAuth.
- Do not add account switching.

## 7. Local / Remote Mapping Direction

Future implementation must centralize local / remote mapping:

- `local_pack_id <-> remote_pack_id`
- `local_item_id <-> remote_item_id`

Mapping expectations:

- Mapping must be centralized.
- Do not add unrelated mapping fields across multiple tables.
- Core model spec must list mapping tables / fields before implementation.
- Phase 3B does not implement Drift mapping changes.

## 8. Request-to-Object Mapping

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

## 9. RLS Direction

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

## 10. Manual Refresh Data Flow

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

## 11. Open Questions

- What exact remote identity source will Shared Pack v1 use before full account binding?
- What is the minimum item payload needed to represent current Reminder App items?
- What local Drift mapping table / fields will be added in the next implementation phase?
- How will manual test accounts / dev identities be created without exposing technical identity language to users?

## 12. Phase 3B Acceptance Checklist

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
