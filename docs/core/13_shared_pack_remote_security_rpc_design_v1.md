# Shared Pack Remote Security & RPC Design v1

## 1. Document Status

- Status: **Phase 1e COMPLETE — documentation-only technical design gate**.
- Repository branch: `ver-1.3.2`.
- Starting HEAD: `e0f7ba9d603ee6d6a7bc724750e0f76e47151b1c` (`define Shared Pack runtime coordination design`).
- Inspection date: 2026-08-05 (Asia/Hong_Kong).
- Starting working tree: clean (`## ver-1.3.2...origin/ver-1.3.2`); no pre-existing user changes.
- Runtime status: unchanged. Shared Pack remains planned and no remote or client implementation exists.
- This document contains proposed SQL shapes and transaction pseudocode only. It is not an executable migration.
- The only next allowed phase is Phase 1f — Application/UI/Test Contract.

Decision vocabulary:

- **Locked**: Phase 3 remote implementation MUST preserve the decision unless an upstream authority is deliberately revised first.
- **Design target**: proposed SQL/pseudocode, not repository implementation evidence.
- **Evidence**: an observation from the inspected repository.
- **Deployment prerequisite**: a security control that Phase 3 must prove in the deployed environment before remote UAT.

## 2. Purpose and Scope

This document locks the Shared Pack v1 Supabase/PostgreSQL remote authority:

- schemas, SQL roles, authoritative tables, constraints, indexes, grants, RLS, and function security;
- the RPC-only client boundary and exact versioned SQL function catalog;
- transaction, lock, Pack/Item version, snapshot, refresh, and concurrency behavior;
- server-owned idempotency equality, claim, exact response replay, and retention;
- invite storage, generation, preview, rotation, join, and brute-force controls;
- stable remote error envelopes, existence policy, diagnostics, privacy, threat mitigations, and future tests.

It does not define Dart application-service signatures, Riverpod state, routes, UI wording, or production SQL. Those remain outside Phase 1e.

## 3. Source Authority

The following sources were fully read and cross-checked:

- `README.md`;
- `docs/core/04_core_model_spec_v1.md`;
- `docs/core/05_home_widget_spec.md`;
- `docs/core/06_shared_pack_direction_spec_v1.md`;
- `docs/core/07_shared_pack_remote_contract_v1.md`;
- `docs/core/08_shared_pack_runtime_consistency_spec_v1.md`;
- `docs/core/09_shared_pack_technical_design_v1.md`;
- `docs/core/10_shared_pack_local_cache_schema_design_v1.md`;
- `docs/core/11_shared_pack_snapshot_projector_design_v1.md`;
- `docs/core/12_shared_pack_runtime_coordination_design_v1.md`;
- `docs/ui/visual_direction.md` and `pubspec.yaml`;
- the required app, Drift, DAO, repository, provider, Widget, migration-test, and backup-test evidence.

Authority order is `06`, `07`, `08`, `04`, `05`, `09`, `10`, `11`, then `12`. Phase 1e found no irreconcilable source conflict and does not revise an upstream source.

## 4. Repository Evidence

Evidence at the start of this phase:

- branch and HEAD exactly match the prompt baseline; recent history ends with the completed Phase 1d commit;
- `AppDatabase.schemaVersion` is 5 and registers only Personal tables and `ReminderDao`;
- there are no production Shared Drift tables, Shared DAO, `lib/features/shared_packs/`, Shared provider, route, UI, auth flow, remote adapter, SQL migration, RPC, or RLS policy;
- `pubspec.yaml` has no Supabase dependency and no new cryptographic dependency;
- `main.dart`, `ReminderApp`, `AppBootstrap`, and `router.dart` contain no Shared identity initialization or Shared route;
- Personal `ItemRepository`, `HomeRepository`, `ReminderDao`, and reminder providers remain Personal/local-first;
- backup export/import/reset enumerate Personal data explicitly; credentials and Shared data are not in the payload;
- Home Widget reads the Personal Home source and mutates through Personal `ItemRepository` only;
- `test/migration_test.dart` is a schema-v5 fresh-database smoke test and `test/backup_service_test.dart` covers Personal backup behavior;
- the required repository search found Shared/Supabase/idempotency terms only in planning documents, not production code.

All SQL objects below are design targets, not current implementation.

## 5. Locked Inputs from Phases 1a–1d

- Shared Pack is remote-authoritative; local Shared Drift is a readable full-snapshot projection.
- v1 has `owner` and `member`; one Pack has exactly one owner and duplicate display names are legal.
- v1 Items are `stateBased` and `active | archived`; no fixed schedule, undo, skip, history, restore, removal, leave, transfer, or Pack delete.
- owner manages Pack metadata, Items, and invites; owner/member can read and complete.
- snapshot-changing successes return mutation result, resulting versions, and one full active snapshot.
- invite state is outside active snapshot and never changes `packVersion`.
- Pack and Item versions are positive signed-64 integers and never wrap.
- `remoteApiContractVersion = 1`; `remoteSnapshotSchemaVersion = 1`.
- SPCS-1/SHA-256 defines client snapshot identity; SPMF-1 defines client logical-payload equality.
- local pending storage is a durable marker with no executable body, no automatic replay, and no automatic TTL.
- an unresolved old request ID cannot silently become a new intent.
- normal Personal startup must not initialize Shared identity or require remote availability.

## 6. Remote Design Goals

1. No Flutter client can directly read or mutate an authoritative Shared table.
2. Every exposed operation authenticates from request context and accepts no caller identity, role, or completion actor.
3. Grants, FORCE RLS, RPC authorization, constraints, and transaction locking all participate.
4. One Pack row is the serialization point for Pack-scoped state and snapshot production.
5. Same idempotency key/payload executes once and replays the original semantic response indefinitely.
6. Every expected failure has a stable, redacted wire code and a declared side-effect guarantee.
7. Invite bearer secrets are never plain at rest or in ordinary logs.
8. Product scope remains exactly Shared Pack v1.

## 7. Explicit Non-goals

No Personal cloud data, profile, discovery, `listMySharedPacks`, activity/action history, outbox, retry queue, realtime table/listener, background sync, Resource, StageTracker, fixed Item, recurrence, membership cap, leave/removal/transfer, Pack archive/delete, restore, multiple active invites, invite expiry, account binding, identity recovery, Home/Widget/notification integration, Dart API, UI, or executable test is added here.

## 8. Supabase Architecture Decision

**Locked:** Shared Pack v1 uses Supabase Auth plus Supabase-hosted PostgreSQL as remote authority. A future Flutter adapter uses the official `supabase_flutter` dependency family. The dependency is added only in Phase 3a; Phase 1e locks no package patch version.

- Anonymous sign-in is lazy and occurs only inside an authorized Shared create/preview/join/identity-required flow.
- A signed-in anonymous Supabase user reaches the Data API as database role `authenticated`, not `anon`.
- `anon` (no signed-in user) receives no Shared RPC execution grant.
- A service-role credential never enters Flutter, mobile platform files, Personal backup, logs, or RPC input.
- Access/refresh tokens, invite codes, remote credentials, and remote access metadata never enter Personal backup.
- `shared_private` is not an exposed Data API schema.
- `public` remains exposed, but only the exact `public.shared_v1_*` wrappers below form the Shared API surface.

## 9. Schema, Role, Ownership, and Migration Topology

### 9.1 Exact schemas and naming

| Purpose | Exact name | Exposure |
| --- | --- | --- |
| Authoritative tables and private helpers | `shared_private` | Not in Supabase Exposed Schemas |
| Versioned client RPC wrappers | `public.shared_v1_*` | Exposed through existing `public` Data API schema |
| Tables | `shared_private.shared_packs`, `shared_memberships`, `shared_items`, `shared_invites`, `shared_idempotency_records`, `shared_rate_limit_counters` | Never direct API objects |
| Private functions | `shared_private.shared_v1_*` | No client `EXECUTE` |

There are no views exposing these tables.

### 9.2 Exact SQL roles

| Role | Attributes and ownership | Runtime privileges |
| --- | --- | --- |
| `shared_storage_owner` | `NOLOGIN NOINHERIT NOBYPASSRLS`; owns `shared_private` and tables | No client grant; migration ownership only |
| `shared_rpc_executor` | `NOLOGIN NOINHERIT NOBYPASSRLS`; owns public wrappers and ordinary helpers | Minimum table privileges required by approved RPCs; subject to FORCE RLS |
| `shared_invite_lookup_executor` | `NOLOGIN NOINHERIT NOBYPASSRLS`; owns two narrowly scoped invite lookup/revalidation helpers | `SELECT` only on Pack/invite data under dedicated FORCE-RLS policies |
| `shared_ops_executor` | `NOLOGIN NOINHERIT NOBYPASSRLS`; owns cleanup/monitor routines not exposed through Data API | Rate-counter cleanup and aggregate monitoring only |

Migration sessions run as the trusted Supabase migration owner (`postgres` in local/deployment tooling), create/alter objects, then assign the above owners. Client roles cannot `SET ROLE` to them. None has `CREATEROLE`, `CREATEDB`, or `BYPASSRLS`.

### 9.3 Default privilege posture

Future migrations execute, in the same transaction as object creation:

```sql
revoke all on schema shared_private from public, anon, authenticated, service_role;
revoke all on all tables in schema shared_private from public, anon, authenticated, service_role;
revoke all on all sequences in schema shared_private from public, anon, authenticated, service_role;
revoke execute on all functions in schema shared_private from public, anon, authenticated, service_role;
alter default privileges in schema shared_private revoke all on tables from public, anon, authenticated, service_role;
alter default privileges in schema shared_private revoke all on sequences from public, anon, authenticated, service_role;
alter default privileges in schema shared_private revoke execute on functions from public, anon, authenticated, service_role;
```

Every new public wrapper immediately revokes `EXECUTE` from `PUBLIC`, `anon`, and `service_role`, then grants only to `authenticated`. This is repeated after any drop/recreate and verified from `information_schema.routine_privileges`.

After the deny baseline, exact positive grants are:

- `USAGE` on `shared_private` to `shared_rpc_executor`, `shared_invite_lookup_executor`, and `shared_ops_executor`; no executor receives `CREATE`;
- `shared_rpc_executor`: only `SELECT`, `INSERT`, and `UPDATE` needed by the approved table/RLS matrix; no `DELETE`, `TRUNCATE`, `REFERENCES`, or `TRIGGER` and no sequence grant is required for UUID keys;
- `shared_invite_lookup_executor`: `SELECT` only on `shared_packs` and `shared_invites`, plus no general function execution;
- `shared_ops_executor`: `SELECT` aggregate metadata and `DELETE` only on expired `shared_rate_limit_counters`, through unexposed fixed routines;
- `authenticated`: `EXECUTE` only on the eleven exact public signatures; it receives no `shared_private` schema usage;
- no positive Shared grant to `PUBLIC`, `anon`, or `service_role`. Trusted migration/backup administration uses a separate audited platform path, not the client RPC grant graph.

### 9.4 Future migration names and ownership

Phase 3 uses `supabase/migrations/YYYYMMDDHHMMSS_shared_pack_v1_NN_<slug>.sql`, ordered:

1. `01_roles_schemas_extensions`;
2. `02_authoritative_tables_constraints_indexes`;
3. `03_rls_grants`;
4. `04_private_validation_crypto_snapshot_idempotency_helpers`;
5. `05_public_rpc_wrappers`;
6. `06_operational_cleanup_and_verification`.

Production SQL begins in Phase 3b/3c, never Phase 2.

## 10. SQL Type, Identity, and Time Conventions

- Pack, membership, Item, invite-record, idempotency-record, and correlation IDs use PostgreSQL `uuid`, generated by database `gen_random_uuid()` unless the request contract supplies the client request UUID.
- `client_request_id` is PostgreSQL `uuid` and must be canonical UUID v4 at the client boundary.
- Flutter treats all remote IDs as opaque canonical lowercase UUID strings. It never derives identity from local IDs or display names.
- `pack_version` and `item_version` use `bigint` with `CHECK (value BETWEEN 1 AND 9223372036854775807)`.
- Every authoritative instant uses `timestamptz`; response serialization is explicit UTC ISO-8601 with `Z`.
- No timezone-less timestamp is accepted or emitted.
- Each RPC captures one `v_now := clock_timestamp()` and uses it for that mutation's authoritative timestamps. Clients never supply authoritative `created_at`, `updated_at`, `joined_at`, `generated_at`, or `completed_at`.
- `clientOccurredAt`, when explicitly present, is parsed as an offset-bearing instant and remains a non-authoritative audit hint.
- Version increment first checks `< 9223372036854775807`; exhaustion returns `versionExhausted` with zero business mutation and never wraps.

## 11. Authoritative Table Designs

All six tables have `ENABLE ROW LEVEL SECURITY` and `FORCE ROW LEVEL SECURITY`. Tables have no client grants. `DELETE` is not granted to `shared_rpc_executor` because v1 exposes no destructive row lifecycle except cache-independent invite invalidation by update.

### 11.1 `shared_private.shared_packs`

| Column | Type | Null/default | Constraints and meaning |
| --- | --- | --- | --- |
| `remote_pack_id` | `uuid` | not null / `gen_random_uuid()` | primary key; opaque Pack ID |
| `title` | `text` | not null | 1–120 Unicode scalars; no NUL/control repair |
| `description` | `text` | null / `NULL` | null distinct from empty; at most 2,000 Unicode scalars |
| `icon_emoji` | `text` | not null | 1–16 Unicode scalars; display metadata, not identity |
| `pack_version` | `bigint` | not null / `1` | positive signed-64 check |
| `created_at` | `timestamptz` | not null / server clock | authoritative UTC instant |
| `updated_at` | `timestamptz` | not null / server clock | authoritative UTC instant |

Indexes: PK on `remote_pack_id`; no title/icon search index. Deletion is `RESTRICT` and no v1 delete RPC exists. Only create, metadata-update, join, and Item-mutation RPCs write it. Snapshot exposes every column. Retention is indefinite while the Pack exists.

### 11.2 `shared_private.shared_memberships`

| Column | Type | Null/default | Constraints and meaning |
| --- | --- | --- | --- |
| `remote_member_id` | `uuid` | not null / `gen_random_uuid()` | primary key |
| `remote_pack_id` | `uuid` | not null | FK to Pack `ON UPDATE RESTRICT ON DELETE RESTRICT` |
| `auth_user_id` | `uuid` | not null | FK to `auth.users(id) ON UPDATE RESTRICT ON DELETE RESTRICT` |
| `role` | `text` | not null | check exactly `owner` or `member` |
| `display_name` | `text` | not null | canonical-trimmed, 1–40 Unicode scalars; not identity/unique |
| `joined_at` | `timestamptz` | not null / server clock | authoritative join instant |

Constraints/indexes:

- `UNIQUE (remote_pack_id, auth_user_id)`;
- `UNIQUE (remote_pack_id, remote_member_id)` for same-Pack actor FK;
- partial unique index `shared_memberships_one_owner_per_pack_uq ON ... (remote_pack_id) WHERE role = 'owner'`;
- index `shared_memberships_auth_user_pack_idx (auth_user_id, remote_pack_id)`;
- deferred constraint trigger validates exactly one owner at transaction commit for every affected Pack.

No update/delete/leave/removal/transfer RPC exists. Create Pack inserts exactly one owner; join inserts role `member`. Display names may duplicate. Snapshot exposes ID, Pack ID where specified, role, display name, and joined time, never `auth_user_id`. Rows retain for Pack lifetime.

### 11.3 `shared_private.shared_items`

| Column | Type | Null/default | Constraints and meaning |
| --- | --- | --- | --- |
| `remote_item_id` | `uuid` | not null / `gen_random_uuid()` | primary key |
| `remote_pack_id` | `uuid` | not null | FK to Pack, delete restricted |
| `title` | `text` | not null | 1–120 Unicode scalars |
| `description` | `text` | null / `NULL` | null distinct from empty; at most 2,000 scalars |
| `item_type` | `text` | not null / `'stateBased'` | check exactly `stateBased` |
| `lifecycle_status` | `text` | not null / `'active'` | check `active` or `archived` |
| `state_anchor_date` | `timestamptz` | not null | authoritative state anchor |
| `info_after_minutes` | `integer` | not null | threshold composite check |
| `warning_after_minutes` | `integer` | not null | threshold composite check |
| `danger_after_minutes` | `integer` | not null | max 5,258,880 |
| `completed_at` | `timestamptz` | null / `NULL` | paired with actor |
| `completed_by_member_id` | `uuid` | null / `NULL` | paired; composite same-Pack FK |
| `item_version` | `bigint` | not null / `1` | positive signed-64 |
| `created_at` | `timestamptz` | not null / server clock | authoritative |
| `updated_at` | `timestamptz` | not null / server clock | authoritative |

Constraints/indexes:

```sql
unique (remote_pack_id, remote_item_id)
check (0 <= info_after_minutes
  and info_after_minutes <= warning_after_minutes
  and warning_after_minutes <= danger_after_minutes
  and danger_after_minutes <= 5258880)
check ((completed_at is null) = (completed_by_member_id is null))
foreign key (remote_pack_id, completed_by_member_id)
  references shared_private.shared_memberships(remote_pack_id, remote_member_id)
  on update restrict on delete restrict
```

Index `shared_items_pack_active_id_idx (remote_pack_id, remote_item_id) WHERE lifecycle_status = 'active'` supports the active snapshot. Archived rows remain authoritative but are omitted from active snapshots and cannot update/complete. `updateSharedItem` never accepts or changes anchor, attribution, type, or lifecycle. `completeSharedItem` is the only general anchor advance. No hard delete or unarchive exists.

### 11.4 `shared_private.shared_invites`

| Column | Type | Null/default | Constraints and meaning |
| --- | --- | --- | --- |
| `remote_invite_id` | `uuid` | not null / `gen_random_uuid()` | primary key |
| `remote_pack_id` | `uuid` | not null | FK to Pack, delete restricted |
| `lookup_digest` | `bytea` | not null | 32-byte HMAC-SHA-256 of canonical code; unique |
| `code_ciphertext` | `bytea` | null | encrypted canonical code; required only while active |
| `key_version` | `smallint` | not null / `1` | positive secret-key version |
| `is_active` | `boolean` | not null / `true` | active/inactive marker |
| `created_at` | `timestamptz` | not null / server clock | authoritative |
| `created_by_member_id` | `uuid` | not null | same-Pack membership FK |
| `invalidated_at` | `timestamptz` | null | paired with invalidator when inactive |
| `invalidated_by_member_id` | `uuid` | null | same-Pack membership FK |

Checks require active rows to have ciphertext and null invalidation fields; inactive rows have null ciphertext and both invalidation fields. A partial unique index on `remote_pack_id WHERE is_active` enforces one active invite per Pack. `lookup_digest` is globally unique so an invalidated code is never reissued. There is no expiry field.

The canonical code is not stored plaintext. Lookup uses a versioned keyed HMAC secret; `getOrCreate` decrypts the active ciphertext with a separate versioned encryption secret. Both secrets live only in an approved server-side secret store and are available only to private helper owners. They never appear in migration source, client, ordinary logs, or backup exports. Rotation atomically clears old ciphertext and retains its digest/invalidation metadata. Invite state is never in the active snapshot and has no Pack-version coupling.

### 11.5 `shared_private.shared_idempotency_records`

| Column | Type | Null/default | Constraints and meaning |
| --- | --- | --- | --- |
| `remote_idempotency_id` | `uuid` | not null / `gen_random_uuid()` | primary key |
| `auth_user_id` | `uuid` | not null | authenticated caller identity |
| `operation_name` | `text` | not null | exact mutation catalog value |
| `client_request_id` | `uuid` | not null | client logical mutation UUID |
| `payload_semantics` | `jsonb` | not null | server-built fixed-shape equality document; invite input represented by keyed digest |
| `payload_digest` | `bytea` | not null | 32-byte SHA-256 over server canonical bytes; comparison accelerator, never sole authority |
| `operation_state` | `text` | not null / `'inProgress'` | check `inProgress` or `completed`; `inProgress` is never intentionally committed |
| `response_ciphertext` | `bytea` | null | encrypted exact completed semantic envelope, success or retained terminal error; required when completed |
| `response_digest` | `bytea` | null | 32-byte integrity digest; paired with completed response |
| `response_key_version` | `smallint` | null | encryption-key version; paired |
| `sensitivity_class` | `text` | not null | `snapshot`, `inviteSecret`, or `membership` |
| `created_at` | `timestamptz` | not null / server clock | claim creation |
| `completed_at` | `timestamptz` | null | set with completed response |

Unique scope is exactly `(auth_user_id, operation_name, client_request_id)`. Indexes are the unique index and `shared_idempotency_created_at_idx (created_at)` for capacity monitoring only. Completed response fields are all-null or all-present. Responses are encrypted at rest because success can contain snapshots, membership data, created IDs, completion attribution, or active invite codes, while a retained terminal error still belongs to a sensitive caller intent.

This table is a server replay ledger, never a client outbox: it has no send schedule, retry count, lease, delivery flag, or background worker semantics. Records do not automatically expire and are excluded from client reads, logs, snapshots, and Personal backup.

### 11.6 `shared_private.shared_rate_limit_counters`

| Column | Type | Null/default | Constraints and meaning |
| --- | --- | --- | --- |
| `auth_user_id` | `uuid` | not null | caller identity |
| `operation_name` | `text` | not null | `previewInviteCode` or `joinSharedPack` |
| `window_started_at` | `timestamptz` | not null | UTC fixed 10-minute bucket |
| `attempt_count` | `integer` | not null / `1` | positive count |
| `last_attempt_at` | `timestamptz` | not null | latest attempt |

Primary key is `(auth_user_id, operation_name, window_started_at)`. Atomic `INSERT ... ON CONFLICT ... DO UPDATE SET attempt_count = attempt_count + 1` prevents lost increments. Rows are operational abuse data, never product membership limits or snapshot content.

### 11.7 Access, owning-RPC, snapshot, deletion, and retention summary

All tables are owned by `shared_storage_owner`; direct clients read/write none of them. “RPC read/write” below means access only through the secured executor/policy path in Sections 13–15.

| Table | RPC readers / writers | Active snapshot | Delete/lifecycle | Retention |
| --- | --- | --- | --- | --- |
| Pack | member snapshot/preview reads; create, metadata, Item, join, completion wrappers write version/metadata | yes | no v1 delete; all dependent FKs restrict | Pack lifetime, indefinite in v1 |
| Membership | member snapshot reads; create Pack/join insert | yes, without auth UID | no update/delete/leave/remove/transfer; Pack/auth FKs restrict | Pack lifetime |
| Item | member snapshot reads; owner create/update/archive; member/owner complete | active only | archive update only; no hard delete/unarchive | archived rows retained for Pack lifetime |
| Invite | owner get/rotate and minimal preview/join lookup; owner wrappers write | no | rotation invalidates, clears ciphertext, retains digest/metadata; no hard delete/expiry | active secret until rotation; invalidation metadata/digest indefinite |
| Idempotency | mutation wrappers only; ops aggregate monitoring only | no | no automatic delete; only a future explicit resolution protocol may remove | indefinite/no TTL |
| Rate counter | preview/join write own bucket; ops aggregate/cleanup | no | hourly ops cleanup may delete rows 24 hours after bucket end | 24 hours after bucket end |

`auth_user_id` in idempotency/rate rows deliberately has no cascading `auth.users` FK: account-row cleanup must not silently erase unresolved replay safety, and expired abuse counters use their own bounded cleanup. Membership keeps the explicit restrictive auth FK because it is authoritative Pack identity. No row lifecycle above is exposed as an additional product operation.

## 12. Constraint and Index Register

| Invariant/query | Database mechanism |
| --- | --- |
| Opaque identities | UUID PKs generated server-side |
| One membership per Pack/auth user | `UNIQUE(remote_pack_id, auth_user_id)` |
| At most/exactly one owner | partial unique index + deferred exactly-one constraint trigger + no v1 owner mutation RPC |
| Same-Pack completion actor | composite FK from Item to membership |
| One active invite | partial unique Pack index |
| Old invite never reissued | unique retained keyed lookup digest |
| Threshold order/max | table check through 5,258,880 |
| Completion pair | paired-null check |
| Positive versions/no wrap | signed-64 checks + pre-increment guard |
| Idempotency scope | unique auth/operation/request key |
| Rate counter concurrency | composite PK and atomic upsert |

Constraints never replace RPC validation, and constraint names/messages never become the wire contract.

## 13. Role, Grant, RLS, and Function Security Model

### 13.1 FORCE-RLS matrix

| Table | RLS/FORCE | Client grants | `shared_rpc_executor` policy | Other runtime policy |
| --- | --- | --- | --- | --- |
| `shared_packs` | enabled/forced | none | select for caller membership; update for caller owner; insert only authenticated execution | invite lookup executor may select minimal source rows |
| `shared_memberships` | enabled/forced | none | select for same-Pack member; insert only `auth_user_id = auth.uid()` and approved role shape | none |
| `shared_items` | enabled/forced | none | select same-Pack member; insert owner; update same-Pack member, with exact owner/member capability enforced again by RPC | none |
| `shared_invites` | enabled/forced | none | select/insert/update caller-owner rows | invite lookup executor may select for digest validation only |
| `shared_idempotency_records` | enabled/forced | none | own `auth_user_id = auth.uid()` only | ops receives aggregate count/size, not payload/response |
| `shared_rate_limit_counters` | enabled/forced | none | own caller counter only | ops may delete expired buckets |

Policies are `TO shared_rpc_executor` (or the named narrow executor), so an accidental direct table grant to `authenticated` still meets default deny. `auth.uid()` is the identity source; null is rejected. The table owner is subject to FORCE RLS and is not the public function owner. No runtime role has `BYPASSRLS`.

The future policies implement these exact semantic predicates with fully qualified private helpers:

- Pack `SELECT`: caller has a membership row for `pack.remote_pack_id`; Pack `UPDATE`: that row has role `owner`; Pack `INSERT`: authenticated create wrapper only.
- Membership `SELECT`: the caller's own row, or `membership.remote_pack_id` equals the wrapper's transaction-local, already-authorized Pack context; `INSERT WITH CHECK`: `auth_user_id = auth.uid()` and the wrapper-selected role shape; no update/delete policy.
- Item `SELECT`: caller has a membership for `item.remote_pack_id`; Item `INSERT`: caller owner; Item `UPDATE`: caller member, while each wrapper additionally enforces owner versus completion capability and column allowlists; no delete policy.
- Invite ordinary `SELECT/INSERT/UPDATE`: caller owner of `invite.remote_pack_id`; no delete policy. The lookup executor sees only active digest candidates through its narrow helper policy.
- Idempotency and rate rows: `row.auth_user_id = auth.uid()` for every allowed command; no client-visible select and no cross-identity operation.

To avoid recursive membership RLS while returning all Pack members, each wrapper clears `shared_private.authorized_pack_id` at entry, performs the own-membership lookup, acquires the Pack lock and caller membership lock, revalidates role, then sets that exact Pack UUID with transaction-local `pg_catalog.set_config(..., true)` immediately before the snapshot builder. The membership policy compares the row Pack to that setting and also requires non-null `auth.uid()`. It is transaction-scoped, reset by every wrapper before use, never accepted as input, and cannot grant direct access because clients have no table/helper privilege. A future pgTAP test must prove that a caller-provided session/header value is ignored and that setting leakage across pooled transactions is impossible.

RLS provides row/cross-Pack containment. RPC code provides operation-specific owner/member authorization, safe sequencing, and field allowlists. Constraints provide graph invariants. Grants provide reachability. No layer is treated as a substitute for another.

### 13.2 Function rules

Every public wrapper:

- is `SECURITY DEFINER`, `VOLATILE`, `PARALLEL UNSAFE`, owned by `shared_rpc_executor`;
- has `SET search_path = ''`;
- fully qualifies every schema, table, type, function, operator-sensitive call, and extension function;
- uses no user-composed identifier, unsafe dynamic SQL, or caller-selected schema/table/column;
- derives identity only from `(select auth.uid())` and never accepts `authUserId`, role, or actor;
- rejects a null caller before idempotency or business mutation;
- revokes `EXECUTE` from `PUBLIC`, `anon`, and `service_role`; grants it only to `authenticated`;
- returns the stable JSON envelope and does not expose raw SQL/constraint errors.

Ordinary private helpers are `SECURITY INVOKER`, have an empty `search_path`, are executable only by `shared_rpc_executor`, and are never exposed. The two invite candidate/revalidation helpers are `SECURITY DEFINER` owned by `shared_invite_lookup_executor`; they have only Pack/invite `SELECT`, return only a candidate Pack ID or minimal preview tuple, never return ciphertext/digest, and are executable only by `shared_rpc_executor`.

### 13.3 SECURITY DEFINER threat analysis

| Threat | Prevention/test obligation |
| --- | --- |
| Mutable `search_path`, temp/function/operator shadowing | empty path, fully qualified references, malicious temp-object pgTAP test |
| Default/public execution | transactional revoke then exact grant; privilege-catalog test |
| Privilege escalation through broad owner | distinct NOBYPASSRLS executor, minimum grants, FORCE RLS, no role switching |
| Caller identity/role/actor spoofing | no such parameters; `auth.uid()` plus membership lookup |
| Cross-Pack IDs | Pack lock, membership authorization, composite Item/actor checks |
| Dynamic-SQL injection | no dynamic SQL; values remain typed parameters |
| Invite enumeration through helper | helper is private, least privilege, minimal return, rate-limited public caller, uniform invalid response |
| Error leakage | expected envelope; caught internal error redaction; correlation only |

`SECURITY INVOKER` public wrappers are rejected because direct client table grants would then be required and would violate RPC-only access.

## 14. RPC-only Boundary

> Flutter clients MUST NOT directly `SELECT`, `INSERT`, `UPDATE`, or `DELETE` authoritative Shared tables. All Shared Pack v1 reads and mutations use the approved `public.shared_v1_*` RPC catalog.

Only `authenticated` can execute wrappers. The `anon` API role, authenticated/non-member callers without operation authorization, and all direct table paths fail closed. Private helpers have no client execute privilege. No overloads, defaulted parameters, generic dispatcher, arbitrary operation name, or unversioned alias are allowed.

## 15. Exact RPC Catalog

All functions return one `jsonb` envelope. Parameters are typed and have no SQL defaults; nullable/presence values are explicit. Every RPC accepts `p_remote_api_contract_version smallint`. Every snapshot-returning mutation also accepts `p_supported_remote_snapshot_schema_version smallint` and validates both versions before its idempotency claim or business mutation.

### 15.1 Catalog summary

| Logical operation | Exact SQL function | Permission | Expected guard | Idempotency | Primary locks after claim |
| --- | --- | --- | --- | --- | --- |
| `createSharedPack` | `public.shared_v1_create_pack` | authenticated caller | none | required | new rows; deferred owner invariant |
| `updateSharedPackMetadata` | `public.shared_v1_update_pack_metadata` | owner | Pack | required | Pack, caller membership |
| `createSharedItem` | `public.shared_v1_create_item` | owner | Pack | required | Pack, caller membership |
| `updateSharedItem` | `public.shared_v1_update_item` | owner | Item | required | Pack, membership, Item |
| `archiveSharedItem` | `public.shared_v1_archive_item` | owner | Item | required | Pack, membership, Item |
| `getOrCreateInviteCode` | `public.shared_v1_get_or_create_invite` | owner | none | required | Pack, membership, active invite |
| `rotateInviteCode` | `public.shared_v1_rotate_invite` | owner | none | required | Pack, membership, active invite |
| `previewInviteCode` | `public.shared_v1_preview_invite` | authenticated | none | read/no | rate counter, candidate Pack share lock, invite revalidation |
| `joinSharedPack` | `public.shared_v1_join_pack` | authenticated non-member | none | required | rate counter, candidate Pack, invite, self membership key |
| `getSharedPackSnapshot` | `public.shared_v1_get_snapshot` | member/owner | known Pack version is refresh hint | read/no | Pack share lock, caller membership |
| `completeSharedItem` | `public.shared_v1_complete_item` | member/owner | Item | required | Pack, membership, Item |

The exact SQL signature is part of each subsection. Parameters intentionally absent from all signatures include `authUserId`, caller role, completion actor/member ID, authoritative server timestamps, arbitrary Item type/lifecycle, and raw server payload fingerprint.

### 15.2 `createSharedPack` → `public.shared_v1_create_pack`

```text
(p_remote_api_contract_version smallint,
 p_supported_remote_snapshot_schema_version smallint,
 p_client_request_id uuid,
 p_title text, p_description text, p_icon_emoji text,
 p_owner_display_name text) returns jsonb
```

Validate versions and fields; canonical-trim owner name; establish idempotency; create Pack at version 1 and one owner membership derived from `auth.uid()` in one transaction; enforce exactly one owner; build snapshot v1; encrypt/persist exact response; commit. It accepts no initial Items. Success data contains Pack, owner membership, `resultingPackVersion = 1`, and full snapshot. Stable failures: unsupported versions, validation, rate limit if an infrastructure precheck applies, idempotency conflict, `internalError`, or transport failure. Only the successful path changes business state.

### 15.3 `updateSharedPackMetadata` → `public.shared_v1_update_pack_metadata`

```text
(p_remote_api_contract_version smallint,
 p_supported_remote_snapshot_schema_version smallint,
 p_client_request_id uuid, p_remote_pack_id uuid,
 p_expected_pack_version bigint,
 p_title text, p_description text, p_icon_emoji text) returns jsonb
```

Claim idempotency; lock Pack; lock/verify caller owner membership; compare expected Pack version; validate allowlisted metadata; guard overflow; update metadata/`updated_at`, increment Pack exactly once; build/store response snapshot. It accepts no membership, Item, identity, or lifecycle field. Success returns authoritative Pack, resulting Pack version, and full snapshot. `staleVersion` has zero mutation.

### 15.4 `createSharedItem` → `public.shared_v1_create_item`

```text
(p_remote_api_contract_version smallint,
 p_supported_remote_snapshot_schema_version smallint,
 p_client_request_id uuid, p_remote_pack_id uuid,
 p_expected_pack_version bigint,
 p_title text, p_description text,
 p_initial_state_anchor_date timestamptz,
 p_info_after_minutes integer,
 p_warning_after_minutes integer,
 p_danger_after_minutes integer) returns jsonb
```

Claim; lock Pack; verify owner; compare Pack version; validate offset-bearing anchor and thresholds; insert one active `stateBased` Item at version 1; increment Pack once; build/store snapshot. No caller Item ID, type choice, completion, actor, or lifecycle is accepted. Success returns new Item ID, `resultingItemVersion = 1`, resulting Pack version, and full snapshot.

### 15.5 `updateSharedItem` → `public.shared_v1_update_item`

```text
(p_remote_api_contract_version smallint,
 p_supported_remote_snapshot_schema_version smallint,
 p_client_request_id uuid, p_remote_pack_id uuid,
 p_remote_item_id uuid, p_expected_item_version bigint,
 p_title text, p_description text,
 p_info_after_minutes integer,
 p_warning_after_minutes integer,
 p_danger_after_minutes integer) returns jsonb
```

Claim; lock Pack; verify owner; lock same-Pack Item; reject archived; compare Item version; validate definition; guard both overflows; update only title/description/thresholds and `updated_at`; increment Item and Pack exactly once; build/store snapshot. No Pack-version guard is accepted here: the upstream request contract intentionally uses Item optimistic concurrency for an existing Item, while the Pack row lock safely serializes its Pack increment. Anchor, attribution, type, and lifecycle cannot change.

### 15.6 `archiveSharedItem` → `public.shared_v1_archive_item`

```text
(p_remote_api_contract_version smallint,
 p_supported_remote_snapshot_schema_version smallint,
 p_client_request_id uuid, p_remote_pack_id uuid,
 p_remote_item_id uuid, p_expected_item_version bigint) returns jsonb
```

Claim; lock Pack; verify owner; lock same-Pack Item; reject already archived; compare Item version; guard both overflows; set lifecycle `archived`, update timestamp, and increment Item/Pack once; build snapshot without the Item; store exact response. A different request ID against an already archived Item returns terminal `itemArchived`; same-ID/same-payload replays the original success.

### 15.7 `getOrCreateInviteCode` → `public.shared_v1_get_or_create_invite`

```text
(p_remote_api_contract_version smallint,
 p_client_request_id uuid, p_remote_pack_id uuid) returns jsonb
```

Claim; lock Pack; verify owner; lock active invite if present. If active, decrypt and return that exact canonical/display code. Otherwise generate/insert one active invite with collision retry. Persist encrypted exact response because a lost response must replay the original code. It has no expected Pack version, snapshot builder, or Pack-version change.

### 15.8 `rotateInviteCode` → `public.shared_v1_rotate_invite`

```text
(p_remote_api_contract_version smallint,
 p_client_request_id uuid, p_remote_pack_id uuid) returns jsonb
```

Claim; lock Pack; verify owner; lock active invite; generate a collision-free new code; atomically mark old inactive, clear old ciphertext, record invalidator, and insert new active invite; store encrypted exact response. It has no expected Pack version, snapshot, or Pack-version change. A same-ID replay returns the original newly generated code even after later rotations.

### 15.9 `previewInviteCode` → `public.shared_v1_preview_invite`

```text
(p_remote_api_contract_version smallint,
 p_invite_code text) returns jsonb
```

Require authenticated identity; increment/check the identity rate counter; server-normalize code; compute keyed digest; perform a non-locking candidate Pack lookup through the private helper; acquire that Pack `FOR SHARE`; revalidate the same active digest inside the Pack lock; then return only Pack title, icon, and `joinAvailability`. If the caller is already a member, return `alreadyMember` without snapshot/member data. No domain state changes; the rate counter changes for success and failure. Invalid/unknown/inactive/rotated codes are indistinguishable.

### 15.10 `joinSharedPack` → `public.shared_v1_join_pack`

```text
(p_remote_api_contract_version smallint,
 p_supported_remote_snapshot_schema_version smallint,
 p_client_request_id uuid,
 p_invite_code text, p_member_display_name text) returns jsonb
```

Claim idempotency before rate limiting so completed same-ID replay always returns the original result. For a first attempt, increment/check the join rate counter; normalize and digest invite; obtain candidate Pack without a lock; lock candidate Pack `FOR UPDATE`; revalidate active invite under that Pack lock; validate canonical display name; lock/check caller membership; if absent insert one self membership with role `member`; guard/increment Pack once; build snapshot containing the member; store exact response. It accepts no Pack ID, expected version, role, auth user, or member ID.

`alreadyMember` is a terminal, no-business-side-effect response for a new idempotency key. It returns no membership or snapshot because the invite may be leaked and v1 has no discovery. A same-ID replay of a successful earlier join returns the original membership/snapshot instead.

### 15.11 `getSharedPackSnapshot` → `public.shared_v1_get_snapshot`

```text
(p_remote_api_contract_version smallint,
 p_remote_pack_id uuid,
 p_known_pack_version bigint,
 p_known_pack_version_present boolean,
 p_supported_remote_snapshot_schema_version smallint) returns jsonb
```

Authenticate; validate schema/API support; acquire Pack `FOR SHARE`; verify current caller membership; read current version in that consistent lock scope. If known-present and exactly equal, return `notModified {remotePackId, packVersion, verifiedAt}` using server UTC. Otherwise invoke the one snapshot builder. It writes no authoritative state and uses no request-arrival ordering. A lower known version is normal refresh, not `staleVersion`.

### 15.12 `completeSharedItem` → `public.shared_v1_complete_item`

```text
(p_remote_api_contract_version smallint,
 p_supported_remote_snapshot_schema_version smallint,
 p_client_request_id uuid, p_remote_pack_id uuid,
 p_remote_item_id uuid, p_expected_item_version bigint,
 p_client_occurred_at_present boolean,
 p_client_occurred_at timestamptz) returns jsonb
```

Claim; lock Pack; lock/verify caller owner/member membership; lock same-Pack Item; reject archived; compare Item version; validate optional timestamp presence/value; guard both overflows; capture authoritative server `completedAt`; set `completed_at = state_anchor_date = server time` and `completed_by_member_id = caller membership`; increment Item/Pack once; build/store snapshot. Caller cannot provide actor or authoritative completion time. `clientOccurredAt` never changes authoritative values.

### 15.13 Common rate-limit and logging behavior

- Only preview/join use the SQL identity brute-force counter in v1. Other operations rely on normal platform/infrastructure RPC abuse controls and idempotency, without inventing a product quota.
- Public wrappers log only operation, semantic result family, duration, versions, redacted correlation, and replay/conflict/rate decision. They never log raw parameters, invite code/digest, response, snapshot, or payload digest.

### 15.14 Per-RPC contract closure

For every catalog row above, the exposed schema is exactly `public`, security mode is `SECURITY DEFINER`, owner/execution role is `shared_rpc_executor`, and the sole client execution grant is `authenticated`; `PUBLIC`, `anon`, and `service_role` are revoked. Exact typed inputs and intentionally omitted identity/role/actor/state fields are stated in Sections 15.2–15.12. `auth.uid()` is mandatory even for a signed-in anonymous user. All authoritative timestamps come from the one server clock captured by the RPC; only `completeSharedItem.clientOccurredAt` is accepted as a non-authoritative hint.

| RPC | Stable operation-specific errors in addition to applicable common errors | Business side-effect guarantee |
| --- | --- | --- |
| create Pack | validation | failure has no Pack/member; retained terminal-error record only after claim |
| update metadata | permission, Pack not found, stale Pack version, validation, version exhaustion | failure has no metadata/version change |
| create Item | permission, Pack not found, stale Pack version, validation/type, version exhaustion | failure has no Item/Pack-version change |
| update Item | permission, Pack/Item not found, archived, stale Item version, validation/type, version exhaustion | failure has no Item/Pack-version change |
| archive Item | permission, Pack/Item not found, archived, stale Item version, version exhaustion | failure has no lifecycle/version change |
| get/create invite | permission, Pack not found, validation/internal crypto failure | failure has no invite change; success never changes Pack version |
| rotate invite | permission, Pack not found, validation/internal crypto failure | failure preserves old active invite; success never changes Pack version |
| preview invite | invalid code, already member, rate limited | no Pack/invite/membership change; rate bookkeeping may commit |
| join Pack | invalid code, already member, rate limited, validation, version exhaustion | failure has no membership/Pack-version change; rate bookkeeping may commit |
| get snapshot | permission, Pack not found | read-only; no idempotency or domain write |
| complete Item | permission, Pack/Item not found, archived, stale Item version, validation, version exhaustion | failure has no anchor/actor/version change |

Common errors are `unsupportedRemoteApiContractVersion`, applicable `unsupportedRemoteSnapshotSchemaVersion`, `idempotencyConflict` for mutations, and redacted `internalError`. Exact envelope, retry, retention, trust, new-intent, and disclosure semantics are in Section 26. A deterministic terminal error after an idempotency claim may retain only its encrypted completed replay record; that bookkeeping is not a business side effect. All other side effects are exactly those stated in the individual mutation sequence.

## 16. Transaction, Idempotency Claim, and Lock Ordering

### 16.1 Common mutation transaction

```text
derive auth.uid; validate contract versions and transport shape
→ build server semantic payload document
→ insert-or-resolve idempotency claim
→ on completed same-payload row: decrypt/verify/return original response
→ on different payload: return idempotencyConflict
→ first attempt: apply operation rate counter when required
→ acquire locks in the global order
→ authorize membership/role
→ validate expected versions and domain invariants
→ guard overflow
→ apply business mutation and version increments
→ build authoritative result/full snapshot where required
→ encrypt and mark replay record completed
→ commit
```

Expected errors are returned as JSON, not raised past the wrapper. After a claim, deterministic terminal failures (`permissionDenied`, authorized not-found/archived, `staleVersion`, domain validation/type failure, `invalidInviteCode`, `alreadyMember`, or `versionExhausted`) finalize and encrypt that exact error envelope as `completed`; same-key/same-payload replay returns it without rechecking state. `rateLimited`, unsupported contract/schema versions, and `internalError` never become a completed idempotency result, so an allowed same-intent retry is not permanently sealed. An unexpected exception inside the guarded core subtransaction rolls back idempotency claim and every business write before a redacted `internalError` envelope is returned. A connection loss before the response remains a client unknown outcome even if the database committed.

### 16.2 Global lock order

All remote implementation follows this order and never acquires an earlier class after a later class:

1. idempotency key row (mutations only);
2. rate-limit counter row (first preview/join attempt only);
3. Pack row (`FOR UPDATE` for mutations, `FOR SHARE` for preview/refresh);
4. caller/target membership rows, ordered by `remote_member_id`;
5. Item rows, ordered by `(remote_pack_id, remote_item_id)`;
6. invite rows, ordered by `remote_invite_id`.

One v1 RPC touches at most one Pack and one Item. It never takes a second Pack lock. Locks are held until commit/rollback.

### 16.3 Pack serialization point

Every snapshot-changing Pack mutation locks `shared_packs` `FOR UPDATE` before membership/Item changes. Invite get/rotate also uses the Pack lock even though it does not change Pack version, so invite/join ordering is explainable. Snapshot refresh/preview uses `FOR SHARE` and therefore cannot read across a concurrently committing Pack mutation/rotation.

Different idempotency IDs for the same Pack serialize at the Pack row. Different Packs can run concurrently. The client per-Pack lane is an additional UX/runtime control, not a remote safety dependency.

### 16.4 Invite/join race

Join and preview begin with a non-locking digest lookup only to discover a candidate Pack. They do not trust it. They then acquire the candidate Pack lock and re-run digest/active/key validation inside that lock. Rotate always locks Pack before invite. Thus no `rotate: Pack → Invite` versus `join: Invite → Pack` inversion exists.

Consequences:

- if rotate commits first, join's revalidation sees the old code inactive and returns `invalidInviteCode`;
- if join owns Pack first, rotate waits; join either commits under the then-active code or rolls back, after which rotate proceeds;
- after rotate commit, a new join/preview cannot succeed with the old code.

### 16.5 Rollback

Any validation, permission, stale-version, overflow, constraint, snapshot-build, encryption, response-persistence, or unexpected core failure rolls back all business rows and version changes. A deterministic terminal expected failure after claim may commit only its completed encrypted error record; a retryable, pre-claim, or unexpected failure rolls back the nonterminal claim. Rate counters may be committed as allowed security bookkeeping when an expected preview/join failure envelope is returned. No path can commit a business mutation without its exact replay response.

## 17. Pack and Item Version Mechanics

Initial values are exactly 1.

| Operation | Guard | Pack version | Item version |
| --- | --- | --- | --- |
| create Pack | none | create at 1 | n/a |
| update metadata | expected Pack | +1 | n/a |
| create Item | expected Pack | +1 | create at 1 |
| update Item | expected Item | +1 | +1 |
| archive Item | expected Item | +1 | +1 |
| join | none | +1 | n/a |
| complete Item | expected Item | +1 | +1 |
| get/create invite | none | unchanged | n/a |
| rotate invite | none | unchanged | n/a |
| preview | none | unchanged | n/a |
| snapshot refresh | known version is hint | unchanged | unchanged |

Version comparison occurs after locks and before mutation. Any mismatch returns `staleVersion` with safe details identifying only `pack` or `item`; it does not disclose current version to an unauthorized caller. The caller must already be authorized before detail is returned. Increment is part of the same update/transaction. `resultingPackVersion` and `resultingItemVersion` come from `UPDATE ... RETURNING`, never local arithmetic in response code. Every returned full snapshot has `fullSnapshot.packVersion == resultingPackVersion`.

## 18. Single Authoritative Snapshot Builder

Exact helper: `shared_private.shared_v1_build_snapshot(p_remote_pack_id uuid, p_current_auth_user_id uuid, p_generated_at timestamptz) returns jsonb`.

- `SECURITY INVOKER`; owned/executable only by `shared_rpc_executor`.
- Called only after the wrapper holds the Pack lock and has established caller membership.
- Uses one SQL statement with fully qualified ordered JSON aggregates.
- Membership order is `remote_member_id::text COLLATE "C"`; Item order is `(remote_pack_id::text, remote_item_id::text) COLLATE "C"`.
- Returns schema version 1, Pack metadata, current membership, all memberships, active state-based Items only, completion actor, all versions, explicit UTC timestamps, and supplied server `generatedAt`.
- Excludes archived Items, invite code/state, `auth_user_id`, token/credential, Personal data, action history, diagnostics, and idempotency metadata.

All create/update/archive/join/complete success, same-ID replay response creation, and full refresh use this one builder. Because all graph mutations hold Pack `FOR UPDATE` and the builder is one statement executed while that lock is held, it cannot assemble a mixed-version graph. Exact replay reads the stored original response and does not invoke the builder again.

## 19. Refresh and `notModified`

`get_snapshot` locks Pack `FOR SHARE`, authorizes, and reads version. The share lock prevents a Pack writer from committing between version verification and builder output. If a present known version equals current, `notModified` contains only Pack ID, current Pack version, and `verifiedAt = server clock`. Otherwise a full snapshot is returned.

- `notModified` never mutates remote domain state or idempotency storage.
- It never means a request arriving later is fresher; it verifies only the supplied version.
- Non-member access is resolved before any version/snapshot detail and returns `permissionDenied`, not existence-rich information.
- Client-side exact three-way handling remains defined by Phase 1c/1d.

## 20. Remote Idempotency Model

### 20.1 Scope and equality authority

The unique key is exactly:

```text
auth.uid() + operationName + clientRequestId
```

The server never trusts a client payload fingerprint, raw JSON hash, serializer output, map ordering, or assertion of equality. Each wrapper validates/canonicalizes typed parameters and constructs a fixed-shape `jsonb` semantic document. Equality requires both:

1. stored and incoming `payload_semantics` are `jsonb`-equal; and
2. the server-computed digest matches.

The document is the authority; the digest is an accelerator/integrity check. A digest collision cannot make unequal documents equal.

### 20.2 Server semantic payload matrix

| Operation | Server equality fields, preserving listed distinctions |
| --- | --- |
| create Pack | exact title, description null/empty, exact icon, canonical owner display name |
| update metadata | exact Pack ID, expected Pack version, exact title, description null/empty, exact icon |
| create Item | exact Pack ID, expected Pack version, exact title, description null/empty, anchor UTC epoch ms, three integers |
| update Item | exact Pack/Item IDs, expected Item version, exact title, description null/empty, three integers |
| archive Item | exact Pack/Item IDs, expected Item version |
| get/create invite | exact Pack ID |
| rotate invite | exact Pack ID |
| join | HMAC of canonical invite code, canonical member display name |
| complete Item | exact Pack/Item IDs, expected Item version, explicit `clientOccurredAt` presence plus UTC epoch ms when present |

This is semantically compatible with Phase 1d SPMF-1: null versus empty, optional absent versus present, exact IDs/versions/instant, display-name trim, invite normalization, and threshold integers remain distinct in the same places. The remote internal JSON/digest encoding need not equal the client digest bytes.

### 20.3 Claim/concurrency pseudocode

```text
semantic = serverCanonicalizeAndValidate(typedInput)

insert idempotency(auth.uid, operation, requestId,
                   semantic, digest, state='inProgress')
on conflict do nothing

if inserted:
  // This transaction owns first execution.
  execute checks and mutation under required locks
  if deterministic terminal expected failure:
    roll back business subtransaction
    encrypt exact error envelope and mark claim completed
  else if success:
    build exact success envelope
    encrypt envelope and integrity digest
    update same row to completed with response and completedAt
  else:
    roll back/delete nonterminal claim
  commit allowed result/bookkeeping
  return envelope

else:
  select matching row for update
  // ON CONFLICT/row lock waits for a concurrent owner to commit or abort.
  if stored semantic != incoming semantic:
    return idempotencyConflict, no mutation
  if state = completed and encrypted response verifies:
    decrypt and return original envelope, no mutation/locks/version change
  otherwise:
    fail closed as internalError; do not mutate
```

If the first transaction aborts, its inserted row and mutation both disappear. A waiting duplicate can then win a new insert/claim and execute once. A completed row contains either the exact success or a specifically retained deterministic terminal error; retryable rate limits, version-negotiation rejection, and internal errors cannot leave a false completed row. The forbidden `check → mutate → insert later` race never exists.

### 20.4 Exact replay

The encrypted response is the original completed semantic envelope. For success it includes the original:

- correlation ID, created Pack/Item/member IDs, authoritative timestamps, actor, archived result, resulting versions;
- complete full snapshot and its original `generatedAt` for snapshot-changing mutations;
- active invite canonical/display code for get/create/rotate;
- join membership and snapshot.

For a retained deterministic terminal error, replay returns the original code, safe details, correlation ID, and side-effect declaration without re-authorizing or re-evaluating current state. Replay never mutates, rebuilds a snapshot from current state, regenerates completion time/code, increments a version, or substitutes a newer snapshot. JSON transport whitespace/key formatting may be regenerated, but values, presence/null semantics, arrays, IDs, timestamps, and response data are exactly the stored original semantic envelope.

## 21. Idempotency Retention Policy

**Locked baseline:** Shared Pack v1 idempotency records do not automatically expire.

- No TTL, age-based delete, partition drop, vacuum job, or “safe retry window” removes a record.
- Cleanup requires a future explicit client-resolution acknowledgement, account-bound recovery protocol, terminal support process, or deliberate revision of the Phase 1d pending lifecycle.
- Until such a protocol exists, an unresolved old ID remains replayable and never silently becomes a new execution.
- Personal reset, app restart, elapsed time, and invite rotation do not authorize deletion.

Operational consequences:

- response ciphertext is TOAST-compressible but full snapshots can be large; monitor row count, relation/TOAST/index size, response-percentiles, and backup growth;
- v1 uses the unique B-tree scope index and created-at monitoring index; no time partition implies expiry;
- future hash partitioning by `auth_user_id` may be introduced through a no-semantic-change migration for scale, but partition lifecycle must remain non-expiring;
- encrypted backups containing the table inherit the no-expiry requirement and restricted operational access;
- data minimization is achieved by fixed semantic payloads, encrypted responses, no raw tokens, and no client/log exposure—not by unsafe deletion.

This intentionally accepts unbounded growth to preserve duplicate-mutation safety. Capacity alarm thresholds and an explicit future resolution protocol are Phase 3 operations/future-spec work; storage pressure is never permission to expire records.

## 22. Invite Storage, Canonicalization, and Generation

### 22.1 Canonical contract

```text
length: 6
alphabet: ABCDEFGHJKMNPQRSTUVWXYZ23456789
display: K7M 4Q9
canonical: K7M4Q9
```

The server independently removes ASCII space U+0020 and ASCII hyphen U+002D, uppercases ASCII `a`–`z`, then requires exactly six characters from the alphabet. Tabs, non-ASCII spaces/dashes, compatibility characters, other punctuation, and all other code points are rejected. No locale case mapping is used.

### 22.2 Storage and key model

- Lookup stores `HMAC-SHA-256(canonicalCode, lookupKeyVersion)`; the canonical value never appears in an index.
- Reproduction stores only PGP symmetric encryption ciphertext using a separate encryption key/version.
- Active code decryption occurs only in the owner get/create wrapper or idempotency replay path.
- Rotation nulls old ciphertext immediately but retains keyed digest and invalidation data forever, preventing old-code reuse.
- Secret retrieval is a Phase 3 deployment prerequisite. Keys are server-side, versioned, independently rotatable, and never embedded in function bodies/migrations.
- A key-rotation migration must keep old decrypt/HMAC keys until every active invite and retained replay response using that version is re-encrypted/re-keyed transactionally.

Hash-only storage is rejected because `getOrCreate` must reproduce the same active code. Plain canonical storage is rejected because database reads/backups would expose a bearer secret unnecessarily.

### 22.3 Secure generation

Private generation uses `pgcrypto.gen_random_bytes()` and rejection sampling over the 31-character alphabet. A byte is accepted only below `floor(256 / 31) * 31 = 248`, then maps by `byte % 31`; this avoids modulo bias. Six accepted values form the code.

Generation never uses time, sequence, Pack ID, UUID text, `random()`, or predictable seeds. Insert collision on unique lookup digest retries with fresh secure bytes, bounded at 128 attempts; exhaustion becomes redacted `internalError` with no invite change. Ordinary logs never contain code, ciphertext, lookup digest, or invite response.

### 22.4 Lifecycle

- one active invite per Pack is a partial unique database invariant;
- get/create returns the existing active code without version change;
- rotate invalidates old and creates new atomically without Pack version change;
- no automatic expiry and no Pack-version coupling exist;
- future invite concurrency, if needed, gets an independent `inviteVersion`, never Pack version.

## 23. Invite Preview and Join Security

Preview returns exactly:

```text
packTitle
packIcon
joinAvailability
```

It returns no description, Pack/member/owner/auth ID, member count/name, Item title/content/state/history, Pack version, invite metadata, or storage detail. Invalid, unknown, inactive, malformed, and rotated codes return the same `invalidInviteCode` envelope and comparable work path. Correlation IDs do not encode cause.

Join:

- requires an authenticated Shared identity;
- repeats server normalization, rate check, Pack lock, and active-invite revalidation;
- canonicalizes display name and derives auth identity;
- never accepts role and always creates `member`;
- uses the unique Pack/auth constraint for duplicate protection;
- increments Pack exactly once and returns a snapshot containing the new membership;
- concurrent join attempts for the same auth user produce one membership; a second new key returns `alreadyMember` with no snapshot, while a same-ID duplicate replays original success.

`alreadyMember` is not discovery: it is only returned after a valid invite is revalidated (or for a direct authorized condition within the wrapper), carries no Pack detail, and is not equivalent to idempotency replay.

## 24. Rate Limiting and Abuse Protection

### 24.1 SQL identity layer

Both successful and failed first attempts count; completed same-ID replay bypasses the counter so idempotency remains exact.

| Operation | Fixed window | Allowed first attempts per auth user | Failure |
| --- | --- | --- | --- |
| preview | 10 minutes UTC | 20 | `rateLimited`, retry-after to bucket end |
| join | 10 minutes UTC | 8 | `rateLimited`, retry-after to bucket end |

The key is `(auth_user_id, operation_name, window_started_at)`. Invite code/digest is never the counter or log key. Counter increment is atomic under concurrency. Rate limiting changes no Pack/Item/invite version and creates no membership.

Rows are retained for 24 hours after window end and deleted hourly by non-exposed `shared_private.shared_v1_cleanup_rate_limits`, executable only by `shared_ops_executor`/trusted scheduler. Counter cleanup is independent from idempotency retention.

### 24.2 Network/infrastructure layer

Phase 3 deployment must add gateway/WAF controls before invite UAT:

- per source IP: 60 previews and 20 joins per rolling 10 minutes;
- project-wide anomaly/velocity alerts for invalid invite ratio and anonymous-identity creation spikes;
- request/body size limits and standard Supabase Auth anonymous-user abuse controls.

The IP layer must return/marshal `rateLimited` without logging code/body. SQL alone cannot resist attackers creating many anonymous identities or a distributed botnet. This residual risk is accepted only with the network layer verified. These are infrastructure abuse limits, not a Pack member cap; v1 defines no product membership maximum.

## 25. Server-side Validation Matrix

| Value | Exact validation/normalization | Failure |
| --- | --- | --- |
| API contract | integer exactly 1 before business work | `unsupportedRemoteApiContractVersion` |
| snapshot support | integer exactly 1 before a snapshot-changing mutation/read | `unsupportedRemoteSnapshotSchemaVersion` |
| remote IDs | typed UUID; Pack/Item relationship checked under lock | validation or authorized not-found code |
| Pack/Item title | 1–120 Unicode scalars, valid text, no server trim/normalization | `validationFailed` |
| description | null or 0–2,000 scalars; null/empty preserved | `validationFailed` |
| icon | 1–16 Unicode scalars | `validationFailed` |
| display name | remove only leading/trailing exact Unicode White_Space set; result 1–40 scalars, not all whitespace; emit trimmed value; no NFC/NFD/case normalization | `validationFailed` |
| role | never accepted from client; internal exact owner/member | `permissionDenied`/internal invariant |
| Item type/lifecycle | create internally stateBased/active; fixed input impossible; update fields allowlisted | `unsupportedItemType` or validation |
| thresholds | exact integers, ordered, 0..5,258,880 | `validationFailed` |
| state anchor | create requires explicit offset-bearing instant; server stores timestamptz | `validationFailed` |
| expected versions | exact positive bigint, compared after lock | `staleVersion` |
| timestamps | explicit `Z`/numeric offset; no timezone-less input; authoritative times server-only | `validationFailed` |
| invite | exact ASCII normalization/alphabet/length | uniform `invalidInviteCode` |
| nullable/presence | typed parameters plus explicit presence boolean; contradictory presence/value rejected | `validationFailed` |
| completion actor/time | never client parameters; derived membership/server clock | `permissionDenied`/validation |
| archived mutation | archive repeat/update/complete reject after authorized lookup | `itemArchived` |
| current membership | membership query by Pack plus `auth.uid()` | `permissionDenied` |
| owner capability | server membership role exactly owner | `permissionDenied` |

Display-name whitespace is exactly Phase 1c's set:

```text
U+0009..U+000D, U+0020, U+0085, U+00A0, U+1680,
U+2000..U+200A, U+2028, U+2029, U+202F, U+205F, U+3000
```

The private validator iterates Unicode scalars/code points and removes this set only at both ends. PostgreSQL `trim()` is not used as a substitute. Duplicate canonical display names remain valid.

## 26. Stable Error Wire Format

### 26.1 Envelope

Success:

```json
{"remoteApiContractVersion":1,"ok":true,"correlationId":"uuid","data":{}}
```

Expected failure:

```json
{"remoteApiContractVersion":1,"ok":false,"correlationId":"uuid","error":{"code":"staleVersion","safeDetails":{"target":"item"},"retryAfterSeconds":null,"sideEffect":"none"}}
```

- RPC semantic envelopes normally arrive as HTTP 200 from PostgREST because the function executed successfully.
- Expected errors are values, not uncaught PostgreSQL exceptions.
- `safeDetails` is a fixed allowlist and may be null; it contains no IDs/versions until authorization permits that detail.
- `retryAfterSeconds` is a nonnegative integer only for `rateLimited`.
- Raw SQLSTATE, constraint/table/function names, English exception messages, stack traces, SQL, and PostgREST details are never product contract.
- A returned redacted `internalError` guarantees its guarded core subtransaction had no business side effect. A transport disconnect, malformed response, or lost response is not such proof and remains client `remoteUnavailable`/`responseDecodeFailed` with unknown-outcome classification after possible dispatch.

Client/application-side classifications `identityUnavailable`, `localValidationFailed`, `remoteUnavailable`, and `responseDecodeFailed` are not normal RPC error codes.

### 26.2 Stable remote error catalog

| Code | Owning RPC/condition | Business side effect | Idempotency record | Retry/trust/new intent | Disclosure/handling seam |
| --- | --- | --- | --- | --- | --- |
| `permissionDenied` | protected RPC; authenticated but unauthorized | none | idempotent mutation retains exact terminal error; read has none | no blind retry; known Pack becomes inaccessible per Phase 1d; new intent unsafe until access recheck | no existence detail |
| `packNotFound` | only after caller was authorized enough to distinguish, or service context | none | idempotent mutation retains exact terminal error; read has none | no retry without recheck; new Pack intent unrelated | never to arbitrary non-member Pack probe |
| `itemNotFound` | authorized Pack member, same-Pack Item absent | none | completed terminal error | refresh; stale-base trust; new mutation after verification | Item detail only after Pack auth |
| `itemArchived` | authorized Pack member, Item archived | none | completed terminal error, unless same-ID prior success replays | refresh; do not retry as new archive/complete | no Item content |
| `staleVersion` | expected Pack/Item mismatch after auth/lock | none | completed terminal error | refresh; new intent only after verified base | detail target pack/item only |
| `validationFailed` | invalid typed/domain field | none | idempotent mutation retains exact terminal error | correct input then new intent | bounded field identifiers, no raw value |
| `unsupportedItemType` | fixed/unknown type reaches a compatible seam | none | completed terminal error | no retry in v1 | no config echo |
| `invalidInviteCode` | malformed/unknown/inactive/rotated | none except rate counter | join retains exact terminal error; preview has none | user may correct with a new intent; subject to limit | uniform anti-enumeration response |
| `alreadyMember` | valid invite but new-key caller already belongs | none except rate counter | join retains exact terminal error | do not create new join; no discovery/snapshot | no Pack/member data |
| `idempotencyConflict` | same scope key, unequal server semantics | none for this attempt; prior outcome not inferred | retain original completed/unresolved record | no retry with changed payload; no safe new intent until resolved | no stored payload/digest |
| `rateLimited` | identity or gateway limit | rate bookkeeping only | first mutation claim is rolled back/deleted; never completed | retry only after hint with same intent ID/payload when still unresolved; trust unchanged | retry-after only |
| `unsupportedRemoteApiContractVersion` | API version !=1 | none | none/rollback | upgrade client; no new intent | supported major may be returned |
| `unsupportedRemoteSnapshotSchemaVersion` | supported snapshot !=1 | none | none/rollback | upgrade client; no mutation sent | supported schema may be returned |
| `versionExhausted` | Pack or Item at signed-64 max | none | completed terminal error | nonretryable/support required; no safe new same mutation intent | no current value required |
| `internalError` | caught unexpected core error after rollback | none | claim/mutation rolled back; never completed | same-ID retry may be allowed; trust unchanged unless response handling fails | correlation only |

An RPC may also be unavailable at the transport layer. The client then uses Phase 1d dispatch certainty and pending rules; it must not infer `internalError` or zero side effect.

## 27. Existence and Enumeration Policy

- Unauthenticated/`anon`: cannot execute functions; no object information.
- Authenticated non-member probing an arbitrary Pack ID: `permissionDenied` whether Pack exists or not.
- Member/owner of a Pack may receive `packNotFound` only when previously established local membership context and server checks make the distinction necessary; otherwise permission denial remains preferred.
- Item existence/archived distinction is returned only after Pack membership authorization. Non-members receive `permissionDenied` before Item lookup detail.
- Invite malformed/unknown/inactive/rotated states collapse to `invalidInviteCode`.
- Duplicate membership from a valid invite returns only `alreadyMember`, never membership/snapshot.
- Preview and join never return internal Pack ID to UI; join resolves it only inside the success snapshot.

Constraint timing and error mapping are reviewed to avoid foreign-key/unique errors becoming covert existence channels.

## 28. Authorization / Permission Matrix

`service role` below means a trusted server-side operational context, never a mobile client. It is not granted client RPC execution and may perform only separately authorized deployment/backup/monitor operations.

| RPC/data | unauthenticated / `anon` | authenticated non-member | member | owner | service role / ops |
| --- | --- | --- | --- | --- | --- |
| create Pack | deny | allowed as new owner | allowed as unrelated new Pack intent | allowed as unrelated new Pack intent | no client RPC grant |
| update Pack metadata | deny | deny | deny | allow | no client RPC grant |
| create/update/archive Item | deny | deny | deny | allow | no client RPC grant |
| complete Item | deny | deny | allow | allow | no client RPC grant |
| get active snapshot/memberships | deny | deny | allow | allow | restricted backup/incident path only |
| get/create/rotate invite | deny | deny | deny | allow | no client RPC grant |
| preview valid invite | deny | minimal preview only | `alreadyMember`, no preview detail | `alreadyMember`, no preview detail | no client RPC grant |
| join valid invite | deny | allow as role member | `alreadyMember`, no mutation | `alreadyMember`, no mutation | no client RPC grant |
| idempotency replay row | deny | own key only through mutation wrapper | own key only through wrapper | own key only through wrapper | aggregate ops only; incident break-glass separately audited |
| rate counter | deny | own through preview/join | own through preview/join | own through preview/join | cleanup/aggregate only |
| direct authoritative table CRUD | deny | deny | deny | deny | no Data API path; trusted migration/ops only |
| private helper execute | deny | deny | deny | deny | exact ops routine only where granted |

UI hiding is irrelevant to authorization. Owner checks always read the server membership row under the Pack lock. Display name never participates.

## 29. Completion Authority

`completeSharedItem` satisfies all of the following in one transaction:

1. caller auth identity is present;
2. idempotency claim/equality succeeds;
3. Pack is locked;
4. caller membership in that Pack is locked and is owner/member;
5. Item is locked by `(remotePackId, remoteItemId)` and is active;
6. expected Item version matches;
7. Pack and Item can increment without overflow;
8. one server instant becomes `completed_at`, `state_anchor_date`, and `updated_at`;
9. actor comes from `remote_member_id` of the authenticated caller membership;
10. Item and Pack each increment once;
11. full snapshot and exact encrypted response are persisted;
12. commit is atomic.

`clientOccurredAt` is only a bounded hint. It does not choose or backdate completion, but its presence/value remains part of idempotency equality. The baseline client may omit it.

## 30. Threat Model

### 30.1 Actors and assets

Actors: unauthenticated callers; authenticated anonymous non-members; members; owners; malicious/modified Flutter clients; callers reusing their own key; cross-Pack attackers; invite holders/leaked-code attackers; compromised service-role environment; and buggy future migrations.

Assets: current Pack/Item graph; membership/auth mapping; invite bearer secret; completion actor/time; version monotonicity; exact idempotency response; auth credentials; and the Personal/local versus Shared/remote authority boundary.

### 30.2 Threat register

| Threat | Prevention | Database invariant | RPC check | Future test | Residual risk |
| --- | --- | --- | --- | --- | --- |
| direct table CRUD | private schema, no grants, not exposed | FORCE RLS default deny | wrappers only | grants/RLS negative tests | privileged DB compromise |
| privilege escalation / member owner mutation | executor RLS + exact grants | role check, one owner | owner membership under lock | member invokes each owner RPC | faulty privileged migration |
| caller impersonates identity/actor | no identity/actor args | membership auth unique + actor FK | derive `auth.uid()`/member ID | forged params impossible/rejected | stolen JWT acts as that identity |
| cross-Pack Item mutation | exact Pack lock/scope | Pack FKs/composite actor FK | authorize Pack before Item detail | mixed Pack/Item IDs | UUID leak still enables probes, not access |
| stale overwrite | optimistic guard + Pack serialization | positive monotonic versions | compare under lock | concurrent stale writes | manual DB writes by privileged operator |
| duplicate completion | atomic idempotency + locks | unique idempotency key | same payload replay | concurrent same ID | different IDs are distinct user intents |
| same ID/different payload | server semantic document | unique scope | full semantic equality | per-field conflict tests | cryptographic failure cannot bypass JSON equality |
| concurrent same-ID race | insert-on-conflict wait/row lock | unique scope | one owner transaction | high-concurrency duplicate | database outage yields unknown client outcome |
| mixed-version snapshot | Pack lock + one-statement builder | versioned Pack root | one helper only | concurrent mutation/refresh | privileged out-of-band writes forbidden |
| invite brute force | 31^6 space, identity/IP limits, uniform errors | keyed digest/index | normalize/rate/revalidate | distributed attempts | botnet/identity-farm risk remains |
| invite rotate/join race | Pack-first common order, revalidation | one active invite | candidate then lock/recheck | both interleavings | already-started join may commit before rotate |
| code leakage/logging | encryption/HMAC, logging denylist | no plaintext column | minimal output only | log-capture scan | authorized owner can intentionally share code |
| replay after retention expiry | no automatic expiry | durable replay ledger | stored exact response | old-ID replay test | unbounded storage |
| SQL injection | typed params, no dynamic SQL | n/a | fully qualified static SQL | hostile strings/temp objects | extension/function vulnerability |
| search-path/operator shadowing | empty path/full qualification | n/a | function definition audit | temp-schema attack test | missed unqualified token caught by review |
| overbroad execute grants | revoke PUBLIC/anon/service | privilege catalog | exact wrapper signatures | routine privilege snapshot | future migration drift |
| service-role leak | never client; private schema/grants | n/a | no service input/path | secret scan/mobile build scan | server environment compromise is high impact |
| error enumeration | authorization-first/uniform invite errors | constraints hidden | stable envelope | existence matrix tests | timing side channels reduced, not eliminated |
| version overflow | bigint checks | check constraints | pre-increment guard | max-value test | Pack becomes read-only until future migration |
| partial commit | one transaction and guarded response storage | FKs/checks/unique | exception rollback | failure injection each step | catastrophic DB fault handled by restore |
| owner disappearance | no removal/transfer/delete API | unique + deferred exactly-one trigger | create/join only | attempted direct role/delete | privileged manual corruption |
| idempotency response tamper | encryption + response digest + RLS | paired completed fields | verify before replay | tamper test | secret compromise |

## 31. Diagnostics, Privacy, and Retention

### 31.1 Allowed semantic events

- operation and stable result family;
- duration and Pack/Item versions (after authorization);
- rate-limit decision and retry-after;
- redacted correlation/Pack/request representation;
- idempotency first execution/replay/conflict;
- authorization denial family;
- unexpected failure correlation ID.

Forbidden in ordinary/persistent logs:

- raw/canonical invite code, lookup digest, ciphertext, or encryption key;
- raw request/response body, SPMF/server payload document/digest, idempotency response, or full snapshot;
- access/refresh/service-role token or JWT;
- display name as technical identity;
- Pack/Item description;
- SQL, table/constraint name, stack trace, or internal exception returned to client.

### 31.2 Separate retention policies

| Data class | Retention |
| --- | --- |
| idempotency records and encrypted response | no automatic expiry; explicit future resolution protocol required |
| rate-limit counters | 24 hours after bucket end; hourly cleanup |
| persistent security diagnostic table | **not created** in v1 |
| project-owned structured security log sink | 30 days, access-controlled, then delete |
| Supabase/PostgreSQL platform logs | target maximum 7 days where plan/config permits; Phase 3 must record actual provider setting; never recovery/audit authority |
| encrypted operational backups | follow idempotency no-expiry capability while they contain the replay ledger; access is break-glass and audited |

The 30-day diagnostic policy never applies to idempotency or rate counters. No log is a membership/activity history product feature.

## 32. Future Phase 3 Implementation Ordering

| Phase | Remote deliverables |
| --- | --- |
| 3a — Supabase and Lazy Identity | add official Flutter dependency; project config/secrets; lazy anonymous identity only; no normal-startup auth |
| 3b — Remote Schema and RLS | roles/schemas/extensions; six tables, constraints, indexes; exact revoke/grants; FORCE RLS policies; migration verification |
| 3c — Version/Snapshot/Idempotency Core | Unicode/time validators; server payload equality; atomic claim/replay encryption; Pack version helper; one snapshot builder; error envelope |
| 3d — Thin Vertical Slice | create Pack, get snapshot/notModified, complete Item with minimal end-to-end security tests |
| 3e — Owner Mutations | metadata, create/update/archive Item and version/permission/concurrency tests |
| 3f — Invite and Join | key provisioning; secure generator/storage; get/rotate/preview/join; SQL rate counter; gateway/WAF prerequisite |
| 3g — Dart Remote Adapter | exact versioned RPC mapping and stable error decoding under Shared-owned remote adapter |
| 3h — Remote Integration Gate | local Supabase/pgTAP suite, threat/permission matrix, transaction races, deployment secret/log/rate checks |

Policies/tables begin in 3b; snapshot/idempotency helpers and core wrappers begin in 3c–3f. Phase 2 contains no production remote SQL.

## 33. Future Automated Test Obligations

### 33.1 Grants, RLS, and functions

- unauthenticated/`anon` cannot execute any wrapper;
- authenticated/anon/service-role Data API cannot direct CRUD private tables;
- only authenticated has exact wrapper execute; no overload/alias/helper execute;
- helper/private schema is not exposed;
- executor roles are NOLOGIN/NOBYPASSRLS and cannot be assumed;
- FORCE RLS remains enabled and policies match this matrix;
- malicious temp objects/search path cannot shadow function/table/operator;
- cross-Pack direct and RPC access fail;
- service credentials/tokens are absent from client artifacts/backups.

### 33.2 Authorization

- owner can every owner mutation; member cannot;
- owner/member can complete and read snapshot;
- non-member cannot read or infer Pack/Item/member graph;
- forged role/auth user/actor/timestamp fields cannot enter signatures or state;
- duplicate display names still map actor by membership ID.

### 33.3 Versions and transactions

- stale Pack/Item guards have zero business side effect;
- each snapshot-changing mutation increments Pack exactly once;
- Item mutations increment Item exactly once;
- invite operations never change Pack version;
- signed-64 maximum returns `versionExhausted` without wrap;
- injected failure at every stage leaves no partial graph/version/completed replay row;
- different IDs same Pack serialize; different Packs can progress.

### 33.4 Snapshot/refresh

- all mutation snapshots use one builder and equal resulting Pack version;
- active snapshot includes all memberships/current membership and active Items only;
- actor, Item/Pack versions, timestamps, and deterministic order are correct;
- no invite/auth UID/token/Personal/history data appears;
- concurrent refresh/mutation cannot produce mixed graph;
- exact known version returns `notModified`; older known version returns full snapshot; neither writes remote state.

### 33.5 Idempotency

- first request executes; sequential/concurrent same payload replays exactly once;
- same key/different payload conflicts for every field distinction;
- different operation or auth user with same UUID is independent;
- replay preserves generatedAt, snapshot, IDs, archived result, actor, completion time, and invite code;
- replay never increments versions or invokes builder/generator;
- failed transaction leaves no false completed row;
- committed `inProgress` is impossible/fails closed;
- no-expiry record remains replayable after arbitrarily advanced test clock;
- encrypted response tamper fails closed without mutation.

### 33.6 Invite/join/abuse

- generated codes meet alphabet/length and statistical rejection-sampling path; collision retries;
- plaintext code absent from table/log capture;
- get/create concurrent calls return one active same code;
- rotation atomically invalidates old, creates one new, and old code never previews/joins/reissues;
- rotate/join interleavings follow Pack-first order without deadlock;
- preview returns only title/icon/availability;
- owner-only get/rotate; member denied;
- duplicate/concurrent joins create one member with role member and one Pack increment;
- join snapshot contains member; new-key `alreadyMember` leaks no graph;
- identity counters are concurrency-safe, count success/failure, return retry-after, clean after 24 hours, and never change Pack version;
- gateway/IP limits and anonymous-identity residual-risk alarms are deployment-tested.

### 33.7 Errors/privacy

- every stable code uses the exact envelope and declared side-effect value;
- unexpected SQL errors redact details and return correlation only after rollback;
- transport loss is not mistaken for returned `internalError`;
- existence matrix prevents Pack/Item/invite enumeration;
- logs contain only allowlisted semantic fields and honor separate retention.

## 34. Manual SQL Threat Review

Reviewers must execute/check:

- [ ] `pg_namespace`, API exposed schemas, table/view/routine catalog exposure;
- [ ] current/default grants for `PUBLIC`, `anon`, `authenticated`, `service_role`, and executor roles;
- [ ] RLS enabled/FORCE, policy role/command/expression, owner/BYPASSRLS attributes;
- [ ] every `SECURITY DEFINER` owner, grants, empty `search_path`, fully qualified dependency, and no dynamic SQL;
- [ ] `auth.uid()` derivation and null/anonymous behavior;
- [ ] owner/member/cross-Pack/actor-spoof checks;
- [ ] service-role and secret absence from client-facing paths;
- [ ] invite plaintext/log/backup exposure and key access;
- [ ] idempotency payload/response access and encryption;
- [ ] stable error redaction/enumeration timing;
- [ ] lock graph/order, deadlock probes, version overflow, transaction rollback;
- [ ] each data class's separate retention/cleanup job.

## 35. Permission Matrix Review Result

The matrix in Section 28 closes every v1 operation for unauthenticated, authenticated non-member, member, owner, and operational service contexts. No permission depends on UI visibility. The review result is **PASS as design target**, contingent on future catalog/pgTAP proof in Phase 3h.

## 36. Transaction / Concurrency Walkthroughs

1. **Create Pack success:** claim → Pack v1 → self owner → exactly-one trigger → snapshot → encrypted response → commit.
2. **Owner creates Item:** claim → Pack lock/owner/Pack guard → Item v1 → Pack +1 → snapshot/replay response.
3. **Member completes:** claim → Pack/member/Item locks → Item guard → server actor/time → Item/Pack +1 → snapshot.
4. **Stale mutation:** locks/auth succeed; version differs; no business write; stable error.
5. **Concurrent same-ID completion:** second waits on unique claim; first commits once; second decrypts original response.
6. **Same ID/different payload:** row locks; JSON semantics differ; conflict; no Item/Pack lock/mutation.
7. **Success plus replay:** original full snapshot/generatedAt/time/actor/versions returned even if Pack has since advanced.
8. **Rotate versus join:** join candidate is untrusted; both converge on Pack-before-invite; lock winner decides; join revalidates.
9. **Two concurrent joins:** Pack lock and Pack/auth unique constraint produce one member; same ID replays, different ID gets `alreadyMember`.
10. **Refresh versus mutation:** share/update Pack locks serialize; result is one consistent pre- or post-mutation state, never mixed.
11. **Pack overflow:** pre-increment guard returns `versionExhausted`; graph and idempotency success state do not change.
12. **Unexpected failure before commit:** guarded subtransaction rolls back claim/business/version/response; redacted internal error or transport unknown follows.

## 37. Accepted Decision Register

| ID | Accepted decision | Protected invariant |
| --- | --- | --- |
| SP-REMOTE-001 | Supabase Auth + PostgreSQL is v1 remote authority; Flutter dependency waits for Phase 3a | one reviewed remote platform |
| SP-REMOTE-002 | Private `shared_private` storage plus public `shared_v1_*` wrappers | auditable API surface |
| SP-REMOTE-003 | Client access is RPC-only with no table/helper grants | remote authority cannot be patched directly |
| SP-REMOTE-004 | Least grants + FORCE RLS + RPC checks + constraints | defense in depth |
| SP-REMOTE-005 | UUID IDs, positive bigint versions, timestamptz server instants | opaque identity/time/version boundary |
| SP-REMOTE-006 | Six-table graph only; no profile/history/outbox | v1 scope containment |
| SP-REMOTE-007 | Unique Pack/auth plus partial/deferred exactly-one owner | membership/owner integrity |
| SP-REMOTE-008 | Composite same-Pack completion actor FK | attribution integrity |
| SP-REMOTE-009 | Global idempotency→counter→Pack→membership→Item→invite lock order | deadlock/race safety |
| SP-REMOTE-010 | Pack row serializes all Pack-scoped state/snapshot operations | monotonic Pack graph |
| SP-REMOTE-011 | Initial versions 1; every specified mutation increments atomically once | no missing/double/wrapped version |
| SP-REMOTE-012 | One locked one-statement snapshot builder | no mixed graph |
| SP-REMOTE-013 | Exact auth/operation/request idempotency scope | correct replay identity |
| SP-REMOTE-014 | Server fixed-shape semantic equality compatible with SPMF-1 | client fingerprint is never authority |
| SP-REMOTE-015 | Encrypted exact original response replay | same-ID recovery fidelity |
| SP-REMOTE-016 | No automatic idempotency expiry | unresolved old ID remains safe |
| SP-REMOTE-017 | Invite uses keyed lookup digest plus decryptable encrypted active code | secrecy plus get/create reproducibility |
| SP-REMOTE-018 | Partial unique one-active invite; invalidated digest retained | old code cannot revive/reissue |
| SP-REMOTE-019 | CSPRNG rejection sampling over exact alphabet | unpredictable unbiased codes |
| SP-REMOTE-020 | Preview returns only title/icon/availability with uniform invalid semantics | bearer preview privacy |
| SP-REMOTE-021 | Join candidate lookup then Pack lock then invite revalidation | rotate/join safety |
| SP-REMOTE-022 | SQL identity limits plus mandatory gateway IP limits | layered brute-force resistance |
| SP-REMOTE-023 | Stable JSON envelope; expected errors never expose SQL | wire stability/privacy |
| SP-REMOTE-024 | No persistent diagnostic table; separate retention classes | data minimization |
| SP-REMOTE-025 | Service role/credentials never enter client/RPC/backup | credential containment |

## 38. Rejected Decision Register

| ID | Rejected decision | Protected invariant |
| --- | --- | --- |
| SP-REMOTE-R001 | direct Flutter table CRUD | RPC authorization/transaction boundary |
| SP-REMOTE-R002 | UI-only authorization | server authority |
| SP-REMOTE-R003 | service-role key in app | total-database credential secrecy |
| SP-REMOTE-R004 | public/exposed authoritative tables | minimal API surface |
| SP-REMOTE-R005 | generic definer function with mutable search path | shadowing/injection safety |
| SP-REMOTE-R006 | caller auth UID/role/actor/time | identity/attribution authority |
| SP-REMOTE-R007 | client fingerprint/raw JSON hash as equality authority | semantic idempotency |
| SP-REMOTE-R008 | check then mutate then insert idempotency | exactly-once race safety |
| SP-REMOTE-R009 | arbitrary 24h/7d/30d idempotency TTL | unresolved replay safety |
| SP-REMOTE-R010 | rebuild replay from current Pack | original outcome fidelity |
| SP-REMOTE-R011 | plain invite code/logging | bearer secrecy |
| SP-REMOTE-R012 | hash-only invite storage | active-code reproducibility |
| SP-REMOTE-R013 | Pack version for invite rotation | active snapshot semantics |
| SP-REMOTE-R014 | invented member limit | product scope |
| SP-REMOTE-R015 | membership discovery/recovery RPC | v1 boundary |
| SP-REMOTE-R016 | background retry/outbox | explicit marker-only runtime |
| SP-REMOTE-R017 | join Invite lock then Pack lock | deadlock/race safety |
| SP-REMOTE-R018 | modulo-biased/predictable code generation | invite entropy |
| SP-REMOTE-R019 | finite diagnostic policy reused for all data | distinct retention purposes |

## 39. Deferred Decisions

No P0 security, version, idempotency, invite, error, or retention decision is TBD.

Only concrete later-phase expression remains:

- Phase 1f: Dart ports/result types, Riverpod/UI/recovery seams, Fake Remote, full application test contract;
- Phase 3: exact extension availability, managed secret-store wiring, deployed gateway/WAF product, provider log-plan setting, SQL query plans, and capacity alert thresholds.

If the deployed platform cannot provide protected server-only invite/replay keys or the required network abuse layer, Phase 3 remote release is NO-GO; it does not weaken this design.

## 40. External Technical References

Official platform mechanics checked for this design:

- Supabase anonymous sign-ins and the `authenticated` database role: https://supabase.com/docs/guides/auth/auth-anonymous
- Supabase database functions, invoker/definer, empty `search_path`, and function grants: https://supabase.com/docs/guides/database/functions
- Supabase Data API grants/RLS/dedicated-schema guidance: https://supabase.com/docs/guides/api/securing-your-api
- Supabase custom/exposed schemas: https://supabase.com/docs/guides/api/using-custom-schemas
- PostgreSQL row security, owner bypass, and FORCE RLS: https://www.postgresql.org/docs/current/ddl-rowsecurity.html
- PostgreSQL safe `SECURITY DEFINER` functions and default PUBLIC execute: https://www.postgresql.org/docs/current/sql-createfunction.html
- PostgreSQL row locks/deadlocks: https://www.postgresql.org/docs/current/explicit-locking.html
- PostgreSQL UUID type/generation: https://www.postgresql.org/docs/current/datatype-uuid.html
- PostgreSQL `pgcrypto` HMAC, random bytes, and symmetric encryption: https://www.postgresql.org/docs/current/pgcrypto.html

These references confirm platform mechanics only. Sections 5–39 are Reminder App project contracts governed by `06`–`12`.

## 41. Explicitly Out of Scope

This phase does not add a dependency, environment key, project URL, secret, remote project configuration, migration file, SQL object, RLS policy, RPC, Dart remote adapter, identity flow, Drift schema/table/DAO, application method, provider, route, UI, Fake Remote, or executable test. It does not change Personal repositories, Home, Widget, notification, backup, or startup.

## 42. Phase 1e Review Checklist

- [x] Actual branch, HEAD, working tree, date, and pre-existing-change state recorded.
- [x] Sources 04–12, UI direction, pubspec, and required implementation evidence cross-checked.
- [x] Supabase/dependency/lazy identity and credential boundary locked.
- [x] Private schema, exposed wrapper naming, roles, ownership, migration naming locked.
- [x] Every authoritative table has exact columns/types/null/defaults/keys/FKs/checks/indexes/deletion/read-write/snapshot/retention behavior.
- [x] Grants, FORCE RLS, policy purposes, owners, executors, helpers, and function threat analysis locked.
- [x] RPC-only boundary and eleven exact versioned function contracts locked.
- [x] Transaction claim, Pack serialization, global lock order, rollback, and invite/join race locked.
- [x] Pack/Item initial/increment/guard/overflow mechanics locked.
- [x] Single consistent snapshot builder and `notModified` behavior locked.
- [x] Server payload equality, concurrent claim, exact encrypted replay, and no-expiry retention locked.
- [x] Invite storage/generation/rotation/preview/join and one-active constraint locked.
- [x] SQL identity and deployment IP rate limits locked without product membership cap.
- [x] Validation, stable error envelope/catalog, and existence policy complete.
- [x] Permission matrix and threat register complete.
- [x] Diagnostics/privacy and separate retention policies complete.
- [x] Phase 3 ordering and future pgTAP/integration obligations complete.
- [x] Accepted/rejected registers complete; no P0 TBD remains.
- [x] Manual SQL threat, permission, and twelve transaction walkthroughs are ready for review.
- [x] No Phase 1f/2/3 implementation or product-scope expansion is present.

## 43. Phase 1e Exit Criteria

Phase 1e is COMPLETE because the design closes schema topology, authoritative storage, RLS/grants/function security, RPC catalog, transaction locks, versions, snapshot consistency, idempotency equality/replay/retention, invite constraints, abuse controls, errors, permissions, threat mitigations, diagnostics, implementation handoff, and future tests without an unresolved P0 decision.

Repository validation must still prove the final diff is documentation-only and `git diff --check` passes.

## 44. Next Step

```text
Next allowed phase:
Phase 1f — Application/UI/Test Contract
```

Phase 1e stops here.
No Supabase dependency, SQL migration, RPC, RLS policy, Dart remote adapter,
identity flow, local schema, provider, route, UI, or executable test is implemented.
