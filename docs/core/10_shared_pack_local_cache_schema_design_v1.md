# Shared Pack Local Cache Schema Design v1

## 1. Document Status

- Status: **Phase 1b COMPLETE — documentation-only architecture gate**.
- Repository baseline: branch `ver-1.3.2`, commit `ffc4bdc`, inspected on 2026-08-05.
- Starting working tree: clean; no pre-existing user changes were present.
- Current production schema: `driftSchemaVersion = 5`.
- Planned schema after Phase 2b implementation: `driftSchemaVersion = 6`.
- Runtime status: unchanged. This phase creates no Dart file, table, DAO, migration, route, provider, dependency, generated file, or test.
- Next allowed design phase: Phase 1c, Snapshot Projector Design. This document does not implement or specify that algorithm.

Decision vocabulary:

- **Locked**: Phase 2b implementation MUST follow this schema contract unless an upstream authority is deliberately revised first.
- **Recommended**: implementation placement or expression may be refined without changing the locked schema or ownership boundary.
- **Deferred**: the named later phase owns the decision; Phase 1b provides storage capacity or constraints only.

## 2. Purpose and Scope

This document locks the Shared Pack v1 local readable-cache schema sufficiently for Phase 2b to implement Drift schema v6. It owns database topology, table/column types, nullability, keys, constraints, indexes, migration behavior, and backup/import/reset isolation.

It does not own:

- snapshot validation, canonicalization, fingerprint calculation, comparison, or projection sequencing;
- request locking, retry orchestration, trust-state transitions, or pending-intent lifecycle;
- Supabase SQL, RLS, RPC, remote idempotency storage, or remote errors;
- application-service methods, Riverpod state, routes, UI states, Fake Remote behavior, or UAT.

Shared cache remains a local projection of remote authority. A schema row is not permission to mutate locally, discover memberships remotely, integrate Shared Items into Home/Widget/notification, or restore Shared access from Personal backup.

## 3. Sources and Authority

This design was prepared by fully reading and cross-checking:

- `README.md`;
- `docs/core/04_core_model_spec_v1.md`;
- `docs/core/05_home_widget_spec.md`;
- `docs/core/06_shared_pack_direction_spec_v1.md`;
- `docs/core/07_shared_pack_remote_contract_v1.md`;
- `docs/core/08_shared_pack_runtime_consistency_spec_v1.md`;
- `docs/core/09_shared_pack_technical_design_v1.md`;
- `docs/ui/visual_direction.md`;
- the current `AppDatabase`, Personal table declarations, `ReminderDao`, backup service/models, database provider, migration test, and backup service test.

Conflict authority is: `06` product scope, `07` remote DTO/snapshot contract, `08` runtime consistency, `04` Personal boundary, `05` Widget exclusion, then `09` architecture ownership. Phase 1b does not reopen their decisions.

Two requested repository paths have current names different from the prompt:

- `lib/features/reminders/providers/database_providers.dart` (plural);
- `test/backup_service_test.dart`.

No source contradiction blocks this schema design.

## 4. Current Repository Evidence

| Area | Inspected evidence | Phase 1b consequence |
| --- | --- | --- |
| Database | `AppDatabase` owns one SQLite connection and declares `schemaVersion => 5` | Plan one existing-database v5→v6 migration |
| Registration | `@DriftDatabase` registers Personal tables and `ReminderDao` | Add future Shared registrations only at the database host; do not transfer Shared ownership to Personal files |
| Creation/migration | `onCreate` calls `createAll`; upgrades are incremental helpers | Fresh v6 and true v5→v6 paths both require explicit verification |
| Seed behavior | `beforeOpen` ensures Personal default Pack, app settings, and system StageTracker | v6 adds no Shared seed or identity initialization |
| Personal tables | `tables.dart` contains only Personal/local-first tables | Shared declarations belong in the Shared feature, not this file |
| Personal DAO | `ReminderDao` declares and operates only Personal tables | It MUST NOT become the Shared DAO |
| Backup export | `exportBackupData` builds a fixed `BackupData` from explicit Personal queries | Shared rows remain absent without widening the payload |
| Import | `replaceUserDataFromBackup` calls `_clearUserData`, restores Personal seeds, then inserts explicit Personal tables | Shared tables MUST remain outside both clearing and insertion paths |
| Reset | `_clearUserData` uses an explicit child-first Personal delete list; it is not a broad wipe | Shared cache and pending intents remain preserved by Personal reset |
| Existing migration test | Opens only a fresh in-memory current-schema database and asserts version 5 | It is not evidence of a real historical upgrade |

## 5. Locked Database Topology and Ownership

### 5.1 Database topology

**Locked:** use the existing `AppDatabase` and the existing `reminder_app.sqlite` connection. Phase 2b raises `driftSchemaVersion` from 5 to 6.

Reasons:

- v6 is additive; no Shared v5 rows exist and no authority conversion is required;
- current backup/reset paths use explicit Personal table lists, so Shared preservation does not require another file;
- one transactional Drift host can provide the required Pack/membership/item foreign keys and atomic local projection boundary;
- a second database adds connection, lifecycle, failure, and backup/reset coordination without protecting an invariant not already protected by feature-owned DAO boundaries.

Sharing a SQLite file does **not** merge Personal/local-first and Shared/remote-authoritative semantics.

### 5.2 Future file and class ownership

Recommended target placement, locked as feature ownership:

```text
lib/features/shared_packs/data/local/shared_pack_cache_tables.dart
lib/features/shared_packs/data/local/shared_pack_cache_dao.dart
```

Phase 2b may choose exact Dart table class names, but all four declarations belong in `shared_pack_cache_tables.dart`, and all Shared queries/writes/transactions belong in a Shared-owned DAO or local adapter in `shared_packs/data/local/`.

`AppDatabase` is only the registration, connection, and migration host. It may import/register the Shared tables and DAO and expose the generated DAO accessor. It MUST NOT become the application-facing Shared repository.

Locked dependency rules:

- `ReminderDao` does not register, query, insert, update, or delete Shared tables.
- Personal repositories never read or write Shared tables.
- Shared application/providers/UI never depend directly on `AppDatabase` or `ReminderDao`.
- Shared callers use a Shared-owned local abstraction injected at composition time.
- Personal and Shared authority models remain separate despite one SQLite file.
- Shared table declarations are not added to Personal `tables.dart`.

## 6. Planned Drift Schema Version

**Locked:** current v5 → target v6.

v6 adds only:

```text
shared_pack_cache
shared_membership_cache
shared_item_cache
shared_pending_mutation
```

The v6 migration:

- does not transform Shared rows because v5 contains none;
- preserves every Personal row byte-for-byte except SQLite-internal layout effects of opening the database;
- does not change Personal domain semantics or Personal table definitions;
- creates no Shared seed data;
- does not treat existing `beforeOpen` Personal seeds as Shared initialization;
- does not create Shared identity, session, access metadata, network request, or remote work;
- does not change general app-startup requirements.

Phase 1b does not edit `schemaVersion`, `MigrationStrategy`, `@DriftDatabase`, generated Drift code, or tests.

## 7. Shared Storage Conventions

### 7.1 Remote identifiers

All `remotePackId`, `remoteMemberId`, `remoteItemId`, and `clientRequestId` values use:

- Drift: `TextColumn` / Dart `String`;
- SQLite: `TEXT`;
- normalization: exact canonical string supplied by the supported remote contract; the local cache does not lowercase or reinterpret it;
- constraint: non-empty and at most 128 Unicode code points (`CHECK(length(value) BETWEEN 1 AND 128)`).

This does not require UUID syntax and does not pre-decide Phase 1e's remote SQL type. The 128-character bound safely accommodates UUIDs and other opaque canonical IDs while rejecting unbounded or empty identifiers.

### 7.2 Versions

`remote_pack_version`, `remote_item_version`, and `remote_snapshot_schema_version` use Drift `IntColumn` / SQLite `INTEGER`.

- Pack and item versions: `1 <= value <= 9223372036854775807`.
- Snapshot schema version in v6 rows: exactly `1`.
- SQLite's signed 64-bit integer and native Dart `int` are the common storage boundary.
- Phase 1e must not emit a version outside that boundary; no wraparound is permitted.
- Exhausting the signed 64-bit range is not a credible v1 product-lifetime event, but overflow still fails validation rather than wrapping.

### 7.3 UTC instants

Every timestamp in the four tables uses:

- Drift: `IntColumn` / Dart `int` at persistence boundary;
- SQLite: `INTEGER`;
- encoding: UTC Unix epoch milliseconds;
- valid database range: `0..253402300799999` (through `9999-12-31T23:59:59.999Z`).

This applies to remote `createdAt`, `updatedAt`, `joinedAt`, `stateAnchorDate`, `completedAt`, cache `lastVerifiedAt`, and pending mutation `createdAt`.

The database stores only absolute instants. It does not store ambiguous local datetimes or timezone-less strings. UI converts an instant to device local timezone. Remote DTO offset presence and UTC/offset validation belong to Phase 1c snapshot validation; Phase 1b locks only integer storage, bounds, and nullability. Existing Personal timestamp semantics do not change.

### 7.4 Fingerprints

Both snapshot and payload fingerprints use:

- Drift `TextColumn` / SQLite `TEXT`;
- normalized lowercase ASCII hexadecimal;
- non-null;
- even length from 32 through 128 characters;
- `CHECK(length(value) BETWEEN 32 AND 128 AND length(value) % 2 = 0 AND value NOT GLOB '*[^0-9a-f]*')`.

This capacity supports 128- through 512-bit digests. Phase 1c owns snapshot canonical ordering, serialization, hash input, algorithm, and same-version comparison. Phase 1d/1e own how a mutation payload fingerprint is derived and matched to logical/remote idempotency behavior. No algorithm is selected here.

Fresh v6 databases contain no fingerprint row because all Shared tables start empty. Every later `shared_pack_cache` row represents a successfully projected full snapshot and therefore requires a fingerprint.

## 8. `shared_pack_cache`

One row is the root of one successfully projected full active Shared Pack snapshot. A local surrogate key provides stable local references; the remote identity remains separately unique.

### 8.1 Column matrix

| SQLite column (planned Drift accessor) | Semantic meaning | Drift / SQLite type | Nullable | Default | PK | FK | Unique | Check | Snapshot source | Owner phase | Notes |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `local_id` (`localId`) | Local surrogate mapping key | `IntColumn` / `INTEGER` | no | auto-increment | yes | — | PK | positive by generated rowid | local | 1b/2b | Never sent remotely |
| `remote_pack_id` (`remotePackId`) | Authoritative Pack identity | `TextColumn` / `TEXT` | no | none | no | — | named unique index | length 1..128 | snapshot root + `pack.remotePackId` | 1b/2b | Exact opaque canonical remote value |
| `title` (`title`) | Pack title | `TextColumn` / `TEXT` | no | none | no | — | no | — | `pack.title` | 1b/2b | Product validation remains remote/Phase 1c |
| `description` (`description`) | Optional Pack description | `TextColumn` / `TEXT` | yes | `NULL` | no | — | no | — | `pack.description` | 1b/2b | Preserves absent description distinctly from empty text |
| `icon_emoji` (`iconEmoji`) | Pack display icon | `TextColumn` / `TEXT` | no | none | no | — | no | `length(icon_emoji) >= 1` | `pack.iconEmoji` | 1b/2b | Presentation metadata, not identity |
| `remote_pack_version` (`remotePackVersion`) | Version of the complete cached active snapshot | `IntColumn` / `INTEGER` | no | none | no | — | no | 1..signed-64 max | `packVersion` | 1b/2b | May advance only after successful full projection; algorithm is 1c/1d |
| `remote_snapshot_schema_version` (`remoteSnapshotSchemaVersion`) | Snapshot protocol schema stored in this row | `IntColumn` / `INTEGER` | no | none | no | — | no | `= 1` | `remoteSnapshotSchemaVersion` | 1b/2b | Unsupported versions never become cache rows |
| `snapshot_fingerprint` (`snapshotFingerprint`) | Fingerprint of complete projected active snapshot | `TextColumn` / `TEXT` | no | none | no | — | no | lowercase hex, even length 32..128 | derived from full snapshot | capacity 1b; calculation 1c | Required for every root row |
| `trust_state` (`trustState`) | Persisted cache trust classification | `TextColumn` / `TEXT` | no | none | no | — | no | IN (`verified`,`needsRevalidation`,`inaccessible`) | runtime/cache result | capacity 1b; transitions 1d | No other persisted values in v6 |
| `trust_failure_reason` (`trustFailureReason`) | Optional bounded machine-readable diagnostic code | `TextColumn` / `TEXT` | yes | `NULL` | no | — | no | null or length 1..64; must be null when trust is `verified` | local runtime result | capacity 1b; vocabulary/transitions 1d | Not user-facing free text; no stack trace or remote response |
| `last_verified_at` (`lastVerifiedAt`) | Latest successful remote acquisition or verification instant | `IntColumn` / `INTEGER` | no | none | no | — | no | UTC epoch-ms range | full snapshot freshness source or `notModified.verifiedAt` | storage 1b; exact source/algorithm 1c | Chosen instead of `lastRefreshedAt`; semantics are unchanged from 07/08 |
| `remote_created_at` (`remoteCreatedAt`) | Remote Pack creation instant | `IntColumn` / `INTEGER` | no | none | no | — | no | UTC epoch-ms range | `pack.createdAt` | 1b/2b | Remote authoritative |
| `remote_updated_at` (`remoteUpdatedAt`) | Remote Pack update instant | `IntColumn` / `INTEGER` | no | none | no | — | no | UTC epoch-ms range | `pack.updatedAt` | 1b/2b | Remote authoritative |

### 8.2 Root behavior

- `remote_pack_id`, not the title or icon, is remote identity.
- An inaccessible Pack retains its root and last-known children. `trust_state = inaccessible` makes it non-operable; whether UI hides or presents it is Phase 1f.
- Retention allows access failure to remain fail-closed without silently losing the only device-local Pack entry. It does not create recovery/discovery capability.
- `trust_failure_reason` is a bounded diagnostic code. Phase 1d owns the allowed vocabulary and when it is set/cleared.
- Trust transitions, mutation unblocking, and recovery sequencing are not specified here.

## 9. `shared_membership_cache`

One row is one membership summary in the active full snapshot. The current caller's membership is persisted on that same row with `is_current_membership`; no `authUserId` is stored in readable Shared cache.

### 9.1 Column matrix

| SQLite column (planned Drift accessor) | Semantic meaning | Drift / SQLite type | Nullable | Default | PK | FK | Unique | Check | Snapshot source | Owner phase | Notes |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `local_id` (`localId`) | Local surrogate key | `IntColumn` / `INTEGER` | no | auto-increment | yes | — | PK | positive rowid | local | 1b/2b | Never remote identity |
| `remote_member_id` (`remoteMemberId`) | Authoritative membership identity within its Pack context | `TextColumn` / `TEXT` | no | none | no | — | composite unique with Pack | length 1..128 | `memberships[].remoteMemberId` / `currentMembership.remoteMemberId` | 1b/2b | Completion actor identity; no unsupported global-uniqueness assumption |
| `remote_pack_id` (`remotePackId`) | Owning Pack identity | `TextColumn` / `TEXT` | no | none | no | `shared_pack_cache.remote_pack_id ON DELETE CASCADE` | composite unique with member | length 1..128 | snapshot Pack identity | 1b/2b | Child cannot exist without root |
| `role` (`role`) | Membership role | `TextColumn` / `TEXT` | no | none | no | — | partial one-owner index by Pack | IN (`owner`,`member`) | membership `role` | 1b/2b | No editor/viewer values |
| `display_name` (`displayName`) | Pack-scoped display label | `TextColumn` / `TEXT` | no | none | no | — | **not unique** | length 1..40 and not blank after SQLite trim | membership `displayName` | 1b/2b | Never identity, authorization, or FK; duplicate names in one Pack are legal |
| `joined_at` (`joinedAt`) | Remote membership join instant | `IntColumn` / `INTEGER` | no | none | no | — | no | UTC epoch-ms range | membership `joinedAt` | 1b/2b | Remote authoritative |
| `is_current_membership` (`isCurrentMembership`) | Marks the snapshot's `currentMembership` row | `BoolColumn` / `INTEGER` | no | `0` | no | — | one partial unique row per Pack when `=1` | IN (0,1) | membership equals `currentMembership` | 1b/2b | At least one current row is validated before projection by Phase 1c |

### 9.2 Membership invariants

- `UNIQUE(remote_pack_id, remote_member_id)` is the parent key for Pack-consistent actor attribution and supports membership-by-Pack lookup.
- A partial unique index on `remote_pack_id WHERE is_current_membership = 1` enforces at most one current membership per Pack.
- Because the current flag is on a row already FK-bound to the Pack, current membership necessarily belongs to that Pack.
- Schema cannot express “at least one current membership” or “exactly one owner” using only ordinary table constraints. Phase 1c must reject a snapshot lacking either. A partial unique owner index enforces the database-enforceable “at most one owner” half.
- No `auth_user_id` column is present. The server-side `unique(remotePackId, authUserId)` invariant belongs to Phase 1e; readable cache does not receive that identity from the snapshot.
- Pack deletion cascades membership deletion. Direct deletion of a membership referenced by an active item actor is restricted by the item composite FK.

## 10. `shared_item_cache`

One row is one active state-based Shared Item in the current full active snapshot. Archived items have no row and no inactive/tombstone representation in v6.

### 10.1 Column matrix

| SQLite column (planned Drift accessor) | Semantic meaning | Drift / SQLite type | Nullable | Default | PK | FK | Unique | Check | Snapshot source | Owner phase | Notes |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `local_id` (`localId`) | Local surrogate key | `IntColumn` / `INTEGER` | no | auto-increment | yes | — | PK | positive rowid | local | 1b/2b | Stable local mapping only |
| `remote_item_id` (`remoteItemId`) | Authoritative Item identity | `TextColumn` / `TEXT` | no | none | no | — | named unique index | length 1..128 | item `remoteItemId` | 1b/2b | Exact opaque remote value |
| `remote_pack_id` (`remotePackId`) | Owning Pack identity | `TextColumn` / `TEXT` | no | none | no | `shared_pack_cache.remote_pack_id ON DELETE CASCADE` | no | length 1..128 | item/snapshot `remotePackId` | 1b/2b | Indexed for active list and FK child lookup |
| `title` (`title`) | Item title | `TextColumn` / `TEXT` | no | none | no | — | no | — | item `title` | 1b/2b | Remote validation owns product limits |
| `description` (`description`) | Optional Item description | `TextColumn` / `TEXT` | yes | `NULL` | no | — | no | — | item `description` | 1b/2b | No Personal field reuse |
| `type` (`type`) | Shared Item kind | `TextColumn` / `TEXT` | no | `'stateBased'` | no | — | no | `= 'stateBased'` | item `type` | 1b/2b | Fixed is rejected |
| `lifecycle_status` (`lifecycleStatus`) | Active-cache lifecycle marker | `TextColumn` / `TEXT` | no | `'active'` | no | — | no | `= 'active'` | item `lifecycleStatus` | 1b/2b | Archived rows are absent, not stored as archived |
| `state_anchor_date` (`stateAnchorDate`) | Required state elapsed anchor | `IntColumn` / `INTEGER` | no | none | no | — | no | UTC epoch-ms range | item `stateAnchorDate` | 1b/2b | Never guessed locally |
| `info_after_minutes` (`infoAfterMinutes`) | Info threshold | `IntColumn` / `INTEGER` | no | none | no | — | no | see threshold constraint | item `infoAfterMinutes` | 1b/2b | Shared-only state-based config |
| `warning_after_minutes` (`warningAfterMinutes`) | Warning threshold | `IntColumn` / `INTEGER` | no | none | no | — | no | see threshold constraint | item `warningAfterMinutes` | 1b/2b | — |
| `danger_after_minutes` (`dangerAfterMinutes`) | Danger threshold | `IntColumn` / `INTEGER` | no | none | no | — | no | see threshold constraint | item `dangerAfterMinutes` | 1b/2b | — |
| `completed_at` (`completedAt`) | Latest authoritative completion instant | `IntColumn` / `INTEGER` | yes | `NULL` | no | — | no | UTC range when non-null; paired-null constraint | item `completedAt` | 1b/2b | No history semantics |
| `completed_by_member_id` (`completedByMemberId`) | Membership that performed latest completion | `TextColumn` / `TEXT` | yes | `NULL` | no | composite with Pack → membership composite key, `ON DELETE RESTRICT` | no | length 1..128 when non-null; paired-null constraint | item `completedByMemberId` | 1b/2b | Cannot point to membership in another Pack |
| `remote_item_version` (`remoteItemVersion`) | Authoritative Item version | `IntColumn` / `INTEGER` | no | none | no | — | no | 1..signed-64 max | item `itemVersion` | 1b/2b | No local increments |
| `remote_created_at` (`remoteCreatedAt`) | Remote Item creation instant | `IntColumn` / `INTEGER` | no | none | no | — | no | UTC epoch-ms range | item `createdAt` | 1b/2b | Remote authoritative |
| `remote_updated_at` (`remoteUpdatedAt`) | Remote Item update instant | `IntColumn` / `INTEGER` | no | none | no | — | no | UTC epoch-ms range | item `updatedAt` | 1b/2b | Remote authoritative |

### 10.2 Threshold maximum and constraints

**Locked maximum:** `5,258,880` minutes, equal to 10 × 366 days × 24 × 60.

Required row constraint:

```sql
CHECK (
  0 <= info_after_minutes
  AND info_after_minutes <= warning_after_minutes
  AND warning_after_minutes <= danger_after_minutes
  AND danger_after_minutes <= 5258880
)
```

Rationale:

- ten leap-year-sized years is deliberately wider than credible v1 household/care reminder intervals;
- it remains far below signed 64-bit SQLite/Dart duration arithmetic limits;
- it prevents corrupt or hostile remote values from becoming impractically large local durations;
- it is enforced by SQLite, not only Flutter validation.

Changing this maximum requires a deliberate later schema/contract revision; it is not deferred.

### 10.3 Completion and exclusion constraints

Required completion constraint:

```sql
CHECK (
  (completed_at IS NULL AND completed_by_member_id IS NULL)
  OR
  (completed_at IS NOT NULL AND completed_by_member_id IS NOT NULL)
)
```

Required actor FK:

```text
(remote_pack_id, completed_by_member_id)
→ shared_membership_cache(remote_pack_id, remote_member_id)
ON DELETE RESTRICT
```

SQLite permits the nullable composite FK when both completion fields are null. When an actor is present, the composite key prevents attribution to a membership from a different Pack.

The table deliberately has no Personal fixed schedule, recurrence, timezone, `ItemOverduePolicy`, skip, undo, defer, history, action record, paused lifecycle, archived browsing, Resource, notification, Widget, or background-sync columns.

## 11. `shared_pending_mutation`

This table stores only the minimum identity of an unresolved logical remote mutation intent. It is not an outbox and contains no retry schedule or executable request body.

### 11.1 Column matrix

| SQLite column (planned Drift accessor) | Semantic meaning | Drift / SQLite type | Nullable | Default | PK | FK | Unique | Check | Remote/source field | Owner phase | Notes |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `local_id` (`localId`) | Local record key | `IntColumn` / `INTEGER` | no | auto-increment | yes | — | PK | positive rowid | local | 1b/2b | Not an outbox sequence |
| `operation_name` (`operationName`) | Remote idempotency operation scope | `TextColumn` / `TEXT` | no | none | no | — | composite with request ID | allowed operation set below | remote operation name | 1b/2b | Matches the `operationName` component of remote idempotency scope |
| `client_request_id` (`clientRequestId`) | One logical mutation intent ID | `TextColumn` / `TEXT` | no | none | no | — | `UNIQUE(operation_name, client_request_id)` | length 1..128 | mutation request | 1b/2b | Local cache does not store `authUserId`; reuse lifecycle is Phase 1d |
| `target_remote_pack_id` (`targetRemotePackId`) | Pack target when known | `TextColumn` / `TEXT` | yes | `NULL` | no | **none** | no | null or length 1..128 | request/response context | 1b/2b | Nullable for create, invite/join before cache, and projection failure without root |
| `payload_fingerprint` (`payloadFingerprint`) | Stable identifier for the intended payload | `TextColumn` / `TEXT` | no | none | no | — | no | lowercase hex, even length 32..128 | derived from logical request payload | capacity 1b; lifecycle/hash owner 1d/1e | Full payload is not stored |
| `created_at` (`createdAt`) | Local intent-record creation instant | `IntColumn` / `INTEGER` | no | none | no | — | no | UTC epoch-ms range | local clock | 1b/2b | Not a retry schedule |
| `status` (`status`) | Unresolved record classification | `TextColumn` / `TEXT` | no | `'awaitingResolution'` | no | — | no | `= 'awaitingResolution'` | local runtime state | capacity 1b; lifecycle 1d | Resolution deletes the row under a future Phase 1d policy |

Allowed `operation_name` values in v6:

```text
createSharedPack
updateSharedPackMetadata
createSharedItem
updateSharedItem
archiveSharedItem
getOrCreateInviteCode
rotateInviteCode
joinSharedPack
completeSharedItem
```

`previewInviteCode` and `getSharedPackSnapshot` are reads and are not logical mutation intents.

### 11.2 Pending-intent boundaries

- `target_remote_pack_id` is nullable and has no FK to `shared_pack_cache`.
- `createSharedPack` has no remote Pack ID before remote success.
- invite/join may occur before any Pack root is projected.
- remote mutation may succeed while local projection fails, leaving no root or leaving an older root.
- A forced FK would either reject required recovery metadata or fabricate a cache root that was never successfully projected.
- `UNIQUE(operation_name, client_request_id)` mirrors the locally available portion of remote idempotency scope (`authUserId + operationName + clientRequestId`) without persisting readable auth identity.
- The table adds no `nextRetryAt`, `retryCount`, automatic retry flag, schedule, lease, job ID, priority, network policy, full response, or full request payload.
- It does not authorize background sending. When to create/delete a row, restart behavior, user-triggered retry, unknown-outcome recovery, ID reuse, and retention are Phase 1d decisions.

## 12. Relationships, Foreign Keys, and Deletion

### 12.1 Relationship diagram

```text
shared_pack_cache.remote_pack_id (UNIQUE)
  ├──< shared_membership_cache.remote_pack_id   ON DELETE CASCADE
  └──< shared_item_cache.remote_pack_id         ON DELETE CASCADE

shared_membership_cache(remote_pack_id, remote_member_id) (UNIQUE)
  └──< shared_item_cache(remote_pack_id, completed_by_member_id)
       ON DELETE RESTRICT; nullable when never completed

shared_pending_mutation.target_remote_pack_id
  ... no FK by design
```

### 12.2 Enforcement and ordering assumptions

- Phase 2b MUST ensure `PRAGMA foreign_keys = ON` for normal connections and migration tests. v6 migration does not disable it.
- Parent insert availability: Pack root before memberships/items; memberships before items with actors.
- Child removal availability: items before memberships; memberships/items before an explicit Pack-root deletion.
- Pack root deletion cascades both child tables. Item actor restriction is satisfied because Pack cascade removes items and memberships as one referential action.
- Membership deletion is restricted while an active item references it. A full snapshot missing that actor while retaining the item is invalid under `07`, not a case for nulling attribution.
- `ON UPDATE` remains `NO ACTION`; remote identities are immutable cache keys, not locally renamed values.

### 12.3 Active-row strategy

v6 locks hard-delete capacity for membership and item rows absent from an accepted full active snapshot:

- no inactive/tombstone column exists;
- archived Items are absent from `shared_item_cache`;
- stale membership/item rows can be physically deleted inside the future projection transaction;
- inaccessible Pack rows are the exception: the last-known root and children are retained and made non-operable through root trust state.

Phase 1c still owns whether and exactly when an accepted snapshot deletes missing rows and the full transaction order. The schema constraint is that it cannot retain missing rows as active through an inactive flag, and it must delete actor-referencing items before their memberships.

## 13. Index and Constraint Register

All indexes below are required and named. Drift-generated anonymous indexes are not sufficient where a stable name is listed; Phase 2b may use Drift index declarations or migration SQL that produces the same SQLite definition.

| Index name | Columns | Unique | Partial condition | Supported query or invariant |
| --- | --- | --- | --- | --- |
| `shared_pack_cache_remote_pack_id_uq` | `remote_pack_id` | yes | — | Remote Pack identity lookup/upsert and FK parent key |
| `shared_pack_cache_trust_state_idx` | `trust_state` | no | — | Device-local Shared Pack list filtering by operable/inaccessible trust class |
| `shared_membership_cache_pack_member_uq` | `remote_pack_id, remote_member_id` | yes | — | Memberships by Pack, duplicate member prevention, and actor composite FK parent |
| `shared_membership_cache_one_current_per_pack_uq` | `remote_pack_id` | yes | `WHERE is_current_membership = 1` | At most one current membership per Pack |
| `shared_membership_cache_one_owner_per_pack_uq` | `remote_pack_id` | yes | `WHERE role = 'owner'` | At most one owner in cached snapshot; Phase 1c validates at least one |
| `shared_item_cache_remote_item_id_uq` | `remote_item_id` | yes | — | Stable remote Item lookup/upsert |
| `shared_item_cache_pack_idx` | `remote_pack_id` | no | — | Active Items by Pack and FK child lookup |
| `shared_pending_mutation_operation_request_uq` | `operation_name, client_request_id` | yes | — | One local unresolved record per logical remote idempotency scope |
| `shared_pending_mutation_status_idx` | `status` | no | — | Find unresolved intents without defining retry ordering |

No v6 index is added for search, speculative sort, realtime, remote discovery, notification, Widget, history, archived browsing, background work, or retry scheduling.

Table checks also lock:

- supported trust/role/type/lifecycle/status values;
- remote ID, diagnostic code, fingerprint, and display-name bounds;
- version and UTC timestamp ranges;
- threshold ordering and maximum;
- completion timestamp/actor paired nullability;
- snapshot schema version 1.

Application validation alone is insufficient; Phase 2b must express these as SQLite constraints and prove invalid writes fail.

## 14. Planned v5→v6 Migration Contract

### 14.1 Preconditions

- Database `user_version`/Drift version is 5.
- Existing registered Personal schema is valid enough for the normal Drift upgrade path.
- Foreign-key enforcement is enabled.
- There are no Shared tables or Shared rows to transform.
- Migration runs without remote identity, network, UI, provider, or Shared application initialization.

### 14.2 Ordered migration steps

Within one migration transaction:

1. Create `shared_pack_cache`, then its named remote-Pack unique index and trust-state index.
2. Create `shared_membership_cache` after the Pack parent key exists.
3. Create all membership indexes, including the composite Pack/member parent key, before creating the actor child FK.
4. Create `shared_item_cache` after both referenced parent keys exist, then its identity and Pack indexes.
5. Create independent `shared_pending_mutation`, then its logical-request and unresolved-status indexes.
6. Let Drift complete the schema-version change only if every DDL statement succeeds.

No Personal table is rebuilt, altered, deleted, updated, or reseeded as part of `_upgradeToV6`. Existing `beforeOpen` may continue ensuring the same Personal seeds after successful migration, but it performs no Shared initialization.

### 14.3 Success and failure

On success:

- schema version is 6;
- all Personal data remains present and semantically unchanged;
- all four Shared tables exist and are empty;
- all named indexes/FKs/checks exist;
- no Shared system row exists.

On any migration error:

- the upgrade transaction rolls back;
- the database open fails and must not be reported as normal startup;
- code must not continue against a partially created v6 schema;
- Personal rows must not be deleted;
- no best-effort downgrade or destructive recreation is authorized.

### 14.4 Fresh v6 creation

`onCreate/createAll` for a fresh future v6 database must create all Personal and four Shared tables with the same constraints/indexes as an upgraded database. Existing Personal `beforeOpen` seeds must still exist. Shared tables and pending intents remain empty; no Shared Pack, membership, identity, or remote work is seeded.

## 15. Required Phase 2b Migration Tests

### 15.1 A — Fresh v6 database

The future test must open a new in-memory/file-backed v6 database and verify:

- every current Personal table exists and remains writable;
- all four Shared tables exist;
- all Shared tables are empty;
- Personal default Pack, app settings, and system StageTracker seeds remain correct;
- there is no Shared seed row;
- named Shared indexes exist in `sqlite_master`;
- `PRAGMA foreign_key_list` and representative invalid inserts prove FKs;
- representative invalid role/trust/type/lifecycle/version/timestamp/fingerprint/threshold/completion rows fail checks;
- valid Pack → memberships → item and nullable-target pending rows can be written.

### 15.2 B — Real v5→v6 upgrade

The test must not simulate migration by opening a fresh current-schema database. It must:

1. Create a genuine v5 schema using a pinned v5 schema fixture/helper, not current `createAll`.
2. Insert representative Personal rows across Pack, Item/action, Resource/rule/action, Stage tracker/rule/record/relation, template/item, and app settings tables.
3. Close the v5 connection.
4. Open the same database file through the v6 `AppDatabase` and execute the actual `onUpgrade(from: 5, to: 6)` path.
5. Verify all representative Personal values and relationships are preserved.
6. Verify all four Shared tables exist and are empty.
7. Verify schema version is 6.
8. Insert a valid Shared graph and pending intent.
9. Prove invalid FK, duplicate remote ID, duplicate current membership, duplicate owner, invalid enum/check, cross-Pack actor, threshold overflow/order, and completion-pair writes are rejected.

Changing only `expect(db.schemaVersion, 5)` to `6` is explicitly not a migration test.

### 15.3 C — Failure safety

A future test must inject or use a controlled failing v6 migration and prove:

- database open reports failure rather than success;
- no normal DAO/application startup proceeds on a partial schema;
- rerunning against the original valid implementation is not blocked by a falsely committed version 6;
- representative Personal rows remain present;
- no partial Shared table/index set is treated as usable.

Test fixture mechanics belong to Phase 2b, but these observable assertions are locked here.

## 16. Backup, Import, Reset, and OS Data Boundary

### 16.1 Current code assessment

- `BackupData` has exactly eight explicit Personal collections: packs, items, resources, stages, stageTrackers, customTemplates, relations, and activityLogs.
- `exportBackupData` explicitly queries Personal tables and builds those collections. It does not enumerate all database tables.
- `replaceUserDataFromBackup` calls an explicit Personal `_clearUserData`, restores Personal seeds, then inserts named Personal tables in dependency order.
- `_clearUserData` is an explicit child-first Personal delete list. It does not execute a broad database wipe or dynamically enumerate tables.

Therefore, the current implementation structure can preserve the Shared boundary by leaving all Shared declarations out of `ReminderDao`, `BackupData`, export lists, import insertion lists, and `_clearUserData`.

### 16.2 Locked operation matrix

| Operation | Personal tables | Shared cache (`pack/member/item`) | Pending mutation | Shared identity/access |
| --- | --- | --- | --- | --- |
| Personal export | Read explicit payload and serialize | Excluded | Excluded | Excluded; no token, credential, membership, invite, or access metadata |
| Personal import | Replace only tables represented by Personal backup; restore Personal seeds | Preserve unchanged | Preserve unchanged | Preserve unchanged; do not synthesize/restore identity or membership |
| Personal reset | Clear explicit Personal user data; restore only Personal system seeds | Preserve unchanged | Preserve unresolved intents | Preserve unchanged; reset is not unlink/sign-out |
| OS-level app-data clear / uninstall | Local Personal data is removed by OS | Local cache is removed by OS | Local pending intents are removed by OS | Device-local anonymous identity/session/access may be lost |

Additional locked rules:

- Shared tables are never added to legacy `BackupData` or backup format v1.
- Personal export never includes Shared identity/session, invite/access metadata, membership, cache, or pending intent.
- Personal import never clears/overwrites Shared rows, creates membership, or restores Shared identity.
- Shared tables and `shared_pending_mutation` are never added to `_clearUserData`.
- Personal reset remains distinct from OS app-data removal.
- v1 does not guarantee recovery after app-data clear, uninstall, device loss, or device change for an unbound anonymous identity.
- Preserving Shared cache does not authorize `listMySharedPacks`, membership discovery, account recovery, or backup-based Shared recovery.

## 17. Accepted Decision Register

| ID | Decision | Rationale | Protected invariant | Consequence for later phase |
| --- | --- | --- | --- | --- |
| SP-CACHE-001 | Use existing `AppDatabase` and SQLite file | Additive v6 plus explicit Personal maintenance lists | One transactional local graph without authority merge | Phase 2b registers Shared types/DAO in host only |
| SP-CACHE-002 | Raise planned Drift schema 5→6 | Four tables are an additive schema change | Honest schema versioning and migration | Phase 2b implements real upgrade tests |
| SP-CACHE-003 | Shared tables/DAO are owned by `features/shared_packs/data/local` | Matches Phase 1a feature boundary | Personal/Shared authority separation | `ReminderDao` remains Personal-only |
| SP-CACHE-004 | Use local integer surrogate PK plus unique opaque remote IDs | Stable local mapping without assuming remote SQL UUID type | Remote identity remains explicit and centralized | Projector upserts by unique remote identity |
| SP-CACHE-005 | Persist current membership as a membership-row boolean with partial uniqueness | Avoids duplicating role/member identity on Pack root | At most one same-Pack current membership | Phase 1c validates exactly one |
| SP-CACHE-006 | Persist trust as `verified/needsRevalidation/inaccessible` plus optional bounded code | Meets runtime cache classifications without state machine | Known-untrusted/inaccessible data can fail closed | Phase 1d owns transitions/reason vocabulary |
| SP-CACHE-007 | Retain inaccessible Pack root and last-known children | Preserves device-local entry while blocking operation | Permission failure is not normal verified cache | Phase 1f chooses hide vs inaccessible UI |
| SP-CACHE-008 | Name freshness column `last_verified_at` | Includes full projection and `notModified` verification | Freshness updates only after authoritative success | Phase 1c maps accepted freshness source |
| SP-CACHE-009 | Store non-null lowercase-hex snapshot fingerprint on Pack root | One fingerprint describes one complete cached version | Same version cannot silently represent arbitrary content | Phase 1c chooses canonicalization/hash algorithm |
| SP-CACHE-010 | Active-only item/membership cache uses hard-delete capacity; no tombstones | Snapshot contract is full active state | Archived/stale rows cannot remain active by flag accident | Phase 1c owns reconciliation steps/order |
| SP-CACHE-011 | Enforce same-Pack actor through composite FK | A member from another Pack cannot be completion actor | Actor identity consistency | Phase 1c inserts memberships before actor Items |
| SP-CACHE-012 | Pair `completedAt` and actor nullability | Partial attribution cannot be stored as normal cache | Completion metadata integrity | Invalid snapshot projection fails |
| SP-CACHE-013 | Set maximum threshold to 5,258,880 minutes | Wide product range with bounded arithmetic/data | Threshold safety is database-enforced | Remote and projector must reject larger values |
| SP-CACHE-014 | Store all instants as bounded UTC epoch milliseconds | Matches current SQLite convention while eliminating ambiguous local time | Cross-device absolute-time consistency | Phase 1c validates DTO offset before mapping |
| SP-CACHE-015 | Pending Pack target is nullable and not FK-bound | Create/join/projection failure can precede root cache | Unknown remote outcome remains representable | Phase 1d owns lifecycle/recovery |
| SP-CACHE-016 | Pending intent stores operation, request ID, payload fingerprint, created time, one unresolved status only | Enough logical identity without executable request | No offline outbox/background queue | Phase 1d decides creation/deletion/retry policy |
| SP-CACHE-017 | Personal backup/import/reset omit or preserve all Shared state | Existing code is explicit-list based | Local maintenance cannot destroy unrecoverable Shared access | Phase 2b adds preservation tests, not payload fields |
| SP-CACHE-018 | SQLite constraints and named indexes enforce core integrity | Flutter validation can be bypassed or fail | Invalid cache cannot be normalized into success | Phase 2b tests every constraint category |

## 18. Rejected Alternatives

| ID | Rejected alternative | Why rejected | Protected invariant | Consequence |
| --- | --- | --- | --- | --- |
| SP-CACHE-R001 | Separate Shared SQLite database | Adds lifecycle/failure coordination without an invariant benefit; explicit DAO ownership already isolates authority | Atomic local Shared graph and simpler migration/maintenance | Remain in existing database |
| SP-CACHE-R002 | Put Shared declarations in Personal `tables.dart` and manage them with `ReminderDao` | Leaks Shared persistence into Personal ownership | Phase 1a dependency boundary | Use Shared-owned table/DAO files |
| SP-CACHE-R003 | Reuse Personal `item_packs` / `items` / actions | Their lifecycle, schedules, local-first writes, Home/Widget/backup consumers are incompatible | Personal/Shared authority separation | Four independent tables only |
| SP-CACHE-R004 | Turn pending mutation into an outbox | Retry fields/body/worker semantics would authorize offline/background sends | Remote-first explicit v1 mutation flow | Store identity metadata only |
| SP-CACHE-R005 | Force pending mutation FK to Pack cache | Create/join and remote-success/projection-failure may have no root | Restart-safe unresolved intent capacity | Nullable opaque target, no FK |
| SP-CACHE-R006 | Store remote `authUserId` for display identity | Not in readable snapshot; technical identity is neither display name nor local cache need | Privacy and display identity rules | Store remoteMemberId/displayName only |
| SP-CACHE-R007 | Add Shared data to Personal backup | Local backup cannot restore remote authority/access and must not contain credentials | Backup authority boundary | Legacy format remains Personal-only |
| SP-CACHE-R008 | Let Personal reset clear Shared cache/pending state | Anonymous v1 has no membership discovery and could lose the only local entry/unknown intent | Shared access preservation | Explicit Personal delete list remains unchanged |
| SP-CACHE-R009 | Depend only on application validation | Corrupt/invalid writes could bypass UI/projector checks | Cache integrity at persistence boundary | Add SQLite checks/FKs/unique constraints |
| SP-CACHE-R010 | Implement projector algorithm in Phase 1b | Ordering, comparison, fingerprint input, and reconciliation belong to Phase 1c | Roadmap ownership and reviewability | This document states only schema constraints/order feasibility |
| SP-CACHE-R011 | Store current role on Pack root instead of marking membership row | Duplicates role/member truth and weakens same-Pack identity proof | One authoritative cached membership summary | Persist one flagged membership row |
| SP-CACHE-R012 | Store archived Items or inactive tombstones in v6 | Active snapshot excludes them and no v1 browsing query exists | Active-only readable cache | Missing/archived rows use hard-delete capacity |

## 19. Deferred Decisions

### 19.1 Phase 1c — Snapshot Projector Design

- snapshot validation procedure;
- remote timestamp offset validation;
- canonical ordering and canonical serialization;
- snapshot fingerprint hash input and algorithm;
- same-version/different-content comparison;
- older response behavior;
- full projection transaction algorithm;
- missing membership/item reconciliation algorithm and exact delete order;
- full-snapshot freshness source;
- `notModified` algorithm.

Phase 1c must fit the locked lowercase-hex 32..128 fingerprint storage and the FK ordering constraints. This document does not decide its algorithm.

### 19.2 Phase 1d — Runtime Coordination Design

- per-Pack lock and request serialization;
- database version guard coordination;
- trust-state transitions and reason-code vocabulary;
- mutation gating and recovery sequencing;
- `clientRequestId` logical lifecycle;
- pending intent create/delete/retention policy;
- app-restart unknown-outcome policy;
- same-intent payload fingerprint derivation/use;
- user-triggered or other retry orchestration.

No deferred item authorizes automatic retry, a background worker, or an outbox.

### 19.3 Phase 1e — Remote Security and RPC Design

- Supabase dependency and SQL schema;
- remote ID SQL type;
- RLS and RPC-only boundaries;
- remote membership/idempotency/invite constraints;
- remote idempotency record and retention;
- concrete remote error catalog;
- remote payload-fingerprint/hash compatibility where needed.

### 19.4 Phase 1f — Application/UI/Test Contract

- `SharedPackApplicationService` API;
- Shared-owned local port method shapes;
- Riverpod state;
- route map and dedicated Shared surfaces;
- inaccessible/revalidation/projection-failure UI states;
- Fake Remote contract;
- full automated test matrix and UAT.

## 20. Explicitly Out of Scope

Phase 1b does not create Shared directories/files, modify production code/schema/tests/dependencies/generated files, add Supabase/SQL/RPC/RLS, add routes/providers/UI, or implement validator/projector/fingerprint/lock/queue/retry behavior.

It also does not add Home, Home Widget, notification, realtime, background sync, history, archived browsing, membership discovery, `listMySharedPacks`, Personal promotion, offline outbox, or automatic mutation retry.

## 21. Phase 1b Review Checklist

- [x] Source specifications and actual repository files were fully cross-checked.
- [x] Existing `AppDatabase` topology and target v6 are locked.
- [x] Shared table and DAO ownership is locked outside Personal files.
- [x] All four table column matrices include SQL names, types, nullability, defaults, keys, checks, source, owner, and rationale.
- [x] Pack, membership, Item, actor, and pending relationships are explicit.
- [x] Current membership, one-owner capacity, and duplicate display-name behavior are explicit.
- [x] Trust state and bounded failure-reason storage are explicit without a transition state machine.
- [x] Fingerprint capacity/format is explicit without choosing the projector algorithm.
- [x] Pending mutation is minimal and cannot function as an outbox.
- [x] Threshold ordering and 5,258,880-minute maximum are database constraints.
- [x] UTC epoch-millisecond storage and nullability are locked.
- [x] Hard-delete active-cache capacity and inaccessible-root retention are explicit.
- [x] Every required index has a name and justification.
- [x] v5→v6 and fresh-v6 migration contracts are explicit.
- [x] Fresh, real-upgrade, invalid-write, and failure-safety tests are required for Phase 2b.
- [x] Personal export/import/reset and OS-level clear are distinguished.
- [x] Accepted, rejected, and deferred decisions use stable IDs/categories.
- [x] No Phase 1c/1d/1e/1f algorithm or application contract is implemented.
- [x] No runtime behavior or production/test file is changed by this phase.

## 22. Exit Criteria

Phase 1b is COMPLETE because:

1. database topology is locked;
2. Shared table ownership is locked;
3. planned schema version is locked;
4. all four table columns/types/nullability are locked;
5. PK/FK/unique/check constraints are locked;
6. current membership persistence is locked;
7. actor membership consistency is locked;
8. trust-state persistence is locked;
9. snapshot fingerprint persistence is locked;
10. pending mutation remains minimal and non-outbox;
11. threshold maximum is locked;
12. UTC timestamp representation is locked;
13. v5→v6 migration is locked;
14. fresh and real migration tests are locked;
15. Personal export excludes Shared state;
16. Personal import preserves Shared state;
17. Personal reset preserves Shared state and unresolved intent;
18. Phase 1c/1d/1e/1f deferrals are explicit;
19. no production schema/code/test/dependency is changed;
20. runtime behavior is unchanged;
21. repository validation must show `git diff --check` passes;
22. final working-tree diff must contain only this Phase 1b document, because the starting tree was clean.

## 23. Next Allowed Step

```text
Phase 1c: Snapshot Projector Design
```

Phase 1b stops here. It does not begin Phase 1c or Phase 2 schema implementation.
