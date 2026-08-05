# Shared Pack Snapshot Projector Design v1

## 1. Document Status

- Status: **Phase 1c COMPLETE — documentation-only technical design gate**.
- Repository baseline: branch `ver-1.3.2`, starting HEAD `cf6812c6d48758174dd42cae6382a3e77270ecf4`, inspected on 2026-08-05.
- Starting working tree: clean; no pre-existing user changes were present.
- Runtime status: unchanged. This phase adds no production code, Dart type, dependency, table, DAO, migration, route, provider, UI, generated file, or test.
- Planned local schema remains `driftSchemaVersion = 6`; supported `remoteSnapshotSchemaVersion` remains exactly `1`.
- This document locks the Phase 1c projector contract. It does not begin Phase 1d or any Phase 2 implementation.

Decision vocabulary:

- **Locked**: later design and implementation MUST preserve the decision unless the owning upstream specification is deliberately revised first.
- **Deferred**: the named later phase owns the decision; this document supplies only the seam it needs.
- **Evidence**: a repository observation, not a claim that planned Shared Pack behavior exists.

## 2. Purpose and Scope

This document defines how one authoritative `SharedPackSnapshotV1` becomes one complete, deterministic, monotonic local readable projection. It locks:

- the input and validation boundary;
- UTC timestamp decode and canonicalization;
- the canonical semantic document, ordering, serialization, and SHA-256 fingerprint;
- version and same-version-content acceptance;
- the atomic Pack/membership/Item projection transaction;
- hard-delete reconciliation and foreign-key-safe ordering;
- full-snapshot freshness mapping;
- the narrow `notModified` database operation;
- semantic outcomes, scenario behavior, and future Phase 2d/2e test obligations.

The design applies to every authoritative full-snapshot source:

- `createSharedPack`;
- `updateSharedPackMetadata`;
- `createSharedItem`;
- `updateSharedItem`;
- `archiveSharedItem`;
- `joinSharedPack`;
- `completeSharedItem`;
- idempotency replay of any snapshot-changing mutation;
- `getSharedPackSnapshot` when it returns a full snapshot.

Invite-only responses (`getOrCreateInviteCode`, `rotateInviteCode`, and `previewInviteCode`) never enter this projector. The projector never accepts a mutation fragment as cache truth.

## 3. Source Authority

The following sources were read and cross-checked:

- `README.md`;
- `docs/core/04_core_model_spec_v1.md`;
- `docs/core/05_home_widget_spec.md`;
- `docs/core/06_shared_pack_direction_spec_v1.md`;
- `docs/core/07_shared_pack_remote_contract_v1.md`;
- `docs/core/08_shared_pack_runtime_consistency_spec_v1.md`;
- `docs/core/09_shared_pack_technical_design_v1.md`;
- `docs/core/10_shared_pack_local_cache_schema_design_v1.md`;
- `pubspec.yaml`;
- the current `AppDatabase`, Personal Drift tables, `ReminderDao`, database provider, migration test, and backup service test.

Conflict authority is:

1. `06` for Shared Pack v1 product scope, roles, capabilities, and exclusions;
2. `07` for remote DTO, snapshot, request/response, version, full-snapshot, and `notModified` contracts;
3. `08` for monotonicity, response ordering, cache trust, freshness, and projection-failure semantics;
4. `04` for the Personal/local-first domain and Personal/Shared boundary;
5. `05` for the Home Widget exclusion;
6. `09` for feature ownership, dependency direction, and the single-projector boundary;
7. `10` for the locked local schema, constraints, UTC storage, fingerprint capacity, and hard-delete capacity.

Phase 1c does not revise any of those sources. No irreconcilable source conflict was found.

## 4. Current Repository Evidence

The repository commands at the start of this phase reported:

```text
branch: ver-1.3.2
HEAD: cf6812c6d48758174dd42cae6382a3e77270ecf4
working tree: clean
recent history:
cf6812c clarify Shared Pack cache schema boundaries
36291a7 define Shared Pack local cache schema design
ffc4bdc docs: define Shared Pack Phase 1a architecture boundary
e870540 define Shared Pack runtime consistency contract
339bc1c docs: close Shared Pack Phase 0.5 contracts
```

Repository inspection also established:

- the target `docs/core/11_shared_pack_snapshot_projector_design_v1.md` did not exist and had no file history;
- `AppDatabase.schemaVersion` is currently 5 and registers only Personal tables plus `ReminderDao`;
- `tables.dart` and `ReminderDao` contain only Personal/local-first persistence;
- `appDatabaseProvider` only constructs the current `AppDatabase`;
- `test/migration_test.dart` is a fresh current-schema smoke test, not a v5→v6 historical migration test;
- backup export/import/reset operate explicit Personal collections and explicit Personal delete/insert lists;
- `pubspec.yaml` has no Supabase or cryptographic hash dependency;
- searches of `pubspec.yaml`, `lib/`, `test/`, `android/`, and `ios/` found no production `SharedPack`, `shared_pack`, `remotePackVersion`, `remoteSnapshotSchemaVersion`, `snapshotFingerprint`, `lastVerifiedAt`, `lastRefreshedAt`, `notModified`, `clientRequestId`, or Supabase implementation.

The README still summarizes Shared Pack as planned and references the Phase 0.7 documentation status, while `09` and `10` record later completed design gates. That status-summary lag does not contradict runtime evidence and is not changed in this documentation-only phase. Older baseline commits recorded inside `09` and `10` are historical baselines, not the Phase 1c starting HEAD.

## 5. Locked Inputs from Phases 1a/1b

Phase 1c adapts to, and does not reopen, these decisions:

- Shared Pack is remote-authoritative; local Shared cache is only a readable projection.
- All full-snapshot sources use one Shared-owned projector boundary.
- Planned v6 tables are `shared_pack_cache`, `shared_membership_cache`, `shared_item_cache`, and `shared_pending_mutation` in the existing database host.
- Projector writes are limited to the first three cache tables. It does not write pending intents.
- Pack identity is exact `remotePackId`.
- Membership identity is `(remotePackId, remoteMemberId)`.
- Item identity is `(remotePackId, remoteItemId)`; bare `remoteItemId` is never sufficient.
- Remote IDs are exact opaque canonical strings of 1–128 Unicode code points and are never lowercased, case-folded, normalized, or reinterpreted.
- Pack and Item versions are integers in `1..9223372036854775807`.
- Snapshot schema version is exactly 1.
- Persisted timestamps are UTC Unix epoch milliseconds in `0..253402300799999`.
- `snapshot_fingerprint` is non-null lowercase ASCII hexadecimal of even length 32–128.
- `trust_state` storage values are `verified`, `needsRevalidation`, and `inaccessible`; Phase 1d owns transitions.
- Freshness is stored as `shared_pack_cache.last_verified_at`.
- Threshold maximum is 5,258,880 minutes.
- Current membership is represented by `is_current_membership` on the membership row.
- Partial unique indexes enforce at most one current membership and at most one owner per Pack; the projector validates exactly one of each.
- Completion timestamp and actor are both null or both non-null, and actor attribution uses the same-Pack composite FK.
- Membership and Item caches are active-only and use hard deletion; there is no inactive flag or tombstone.
- Inaccessible-root retention is not ordinary full-snapshot reconciliation and is owned by Phase 1d handling.
- The projector never writes Personal `item_packs`, `items`, `item_action_records`, or any other Personal table.

## 6. Design Goals

The projector design MUST:

1. make invalid or unsupported snapshots incapable of becoming cache truth;
2. give semantically identical active snapshots identical fingerprints across input order, timestamp offsets, processes, and conforming runtimes;
3. make one accepted Pack version describe one complete active graph and one fingerprint;
4. preserve monotonically non-decreasing `remotePackVersion` under late or concurrent responses;
5. reconcile one Pack atomically without affecting another Pack or Personal data;
6. satisfy all foreign keys and partial unique indexes without disabling them;
7. preserve local surrogate IDs for retained remote identities;
8. make freshness remote-evidence-based and monotonically non-decreasing;
9. distinguish remote success from local projection outcome;
10. provide directly executable future test contracts without locking a formal Dart API.

## 7. Explicit Non-goals

Phase 1c does not design or implement:

- a formal Dart method signature, result class, port, repository, or application service;
- a per-Pack lock, request queue, request serialization, retry worker, or automatic/manual retry orchestration;
- the full trust-state transition table or `trust_failure_reason` vocabulary;
- pending mutation creation, deletion, retention, restart replay, or `clientRequestId` lifecycle;
- remote SQL, RLS, RPCs, snapshot builders, idempotency storage, or remote hashing;
- Riverpod state, routes, UI wording, screens, Fake Remote API, or UAT wiring;
- realtime, background sync, an outbox, membership discovery, or `listMySharedPacks`;
- Home, Home Widget, notifications, Personal backup, Personal reset mutation, or Personal repository integration;
- fixed Shared Items, Pack timezone, recurrence, skip, defer, undo, action history, archived browsing, or restore.

## 8. Snapshot Processing Pipeline

### 8.1 Two-stage input boundary

The transport adapter and projector boundary are separate, but both are fail-closed:

1. **Strict transport decode** owns JSON/protocol syntax, required field presence, duplicate object-key rejection, declared primitive/container types, integer token decode without precision loss, and preservation of the original timestamp lexeme or equivalent proof that an explicit offset was present. It produces a Shared-specific decoded DTO, never a Personal domain model.
2. **Projector semantic preparation** owns the full validation in this document, UTC conversion, canonical sorting, canonical semantic-document construction, and fingerprint calculation. Its successful internal result is a validated, immutable semantic snapshot plus prepared rows and fingerprint.
3. **Transactional projection** owns the in-database root reread, version/fingerprint and owner-continuity guards, graph reconciliation, freshness update, and atomic commit.

This is a semantic boundary, not a locked Dart class or method signature. A future implementation may represent strict decode and semantic preparation with separate types or one private pipeline, provided invalid input cannot reach writes.

### 8.2 Required order

```text
strict transport decode
→ pure snapshot validation
→ UTC instant canonicalization and epoch-range validation
→ duplicate/integrity validation
→ canonical sorting
→ canonical semantic serialization
→ SHA-256 fingerprint preparation
→ begin one Drift transaction
→ reread and guard current Pack root/content continuity
→ apply or return a no-write outcome
→ commit
→ expose the committed outcome
```

All validation and fingerprint work that depends only on the incoming response MUST complete before opening the write transaction. Owner continuity and version/fingerprint acceptance depend on the current database and therefore run inside the transaction, before the first write.

The projector MUST NOT fill missing fields, guess an anchor or timestamp, trim/repair a string, drop an invalid child, deduplicate rows, or continue with partial success.

## 9. Snapshot Validation Contract

Validation is exhaustive: implementations should collect safe diagnostics if useful, but one failure rejects the whole snapshot. Unsupported schema is a distinct outcome from other validation failure.

### 9.1 Envelope

Validate in this order:

1. `remoteSnapshotSchemaVersion` is present as an exact integer and equals 1. Any other value fails closed as unsupported schema.
2. Snapshot `remotePackId` satisfies the exact remote-ID contract.
3. `packVersion` is an exact integer in `1..9223372036854775807`.
4. `generatedAt` is an ISO-8601 timestamp with `Z` or an explicit numeric UTC offset, parses to an instant, and maps into the locked epoch range.
5. `pack`, `currentMembership`, `memberships`, and `items` are present in their v1 shapes; arrays may be empty only where allowed below. Memberships cannot be empty because exactly one owner/current member is required. Items may be empty.

For a snapshot-changing mutation or idempotency replay envelope, strict decode/semantic preparation MUST additionally prove `resultingPackVersion == fullSnapshot.packVersion` before calling the transactional projector. Any envelope Pack ID repeated outside the snapshot must also equal `fullSnapshot.remotePackId`. Mutation-specific result fields remain feedback, not cache truth. A manual full refresh has no `resultingPackVersion` and uses the snapshot envelope directly.

### 9.2 Pack identity and metadata

- `snapshot.remotePackId == pack.remotePackId` by exact string equality.
- Any decoded v1 transport field that repeats snapshot Pack or version identity MUST equal the envelope value. A future schema may not silently introduce a contradictory duplicate.
- `pack.remotePackId`, title, icon, timestamps, and description presence/nullability match the v1 DTO shape.
- `pack.iconEmoji` is non-empty because the locked cache has `length(icon_emoji) >= 1`; an empty value is rejected before a database write.
- Pack title and description remain subject to remote product validation. This phase invents no title/description length limit.
- IDs, text, or emoji are not case-folded, normalized, trimmed, repaired, or substituted.

### 9.3 Memberships

- Interpret each membership summary in the envelope Pack context. If its transport shape includes `remotePackId`, it must exactly equal the snapshot Pack ID.
- Every `remoteMemberId` satisfies the remote-ID contract.
- No two entries have the same `remoteMemberId` within this snapshot Pack. Detect duplicates before sorting; never deduplicate.
- `role` is exactly `owner` or `member`.
- Exactly one membership has `role = owner`.
- Exactly one membership corresponds to `currentMembership`.
- `currentMembership.remotePackId` exactly equals `snapshot.remotePackId`.
- `currentMembership.remoteMemberId` identifies exactly one membership summary.
- That summary exactly matches `currentMembership` for `role`, `displayName`, and canonical `joinedAt` instant. Timestamp lexemes may differ when they represent the same instant.
- Duplicate display names are valid and do not affect identity checks.
- Every `joinedAt` passes timestamp validation.
- Every display name satisfies Section 10.

### 9.4 Items

For every Item:

- `item.remotePackId` exactly equals `snapshot.remotePackId`.
- `(remotePackId, remoteItemId)` is unique in the input. Duplicate detection happens before sorting and never uses a bare Item ID outside Pack context.
- `remoteItemId` satisfies the remote-ID contract.
- `type` is exactly `stateBased`.
- `lifecycleStatus` is exactly `active`. An archived Item in an active snapshot rejects the whole snapshot; it is not skipped.
- `stateAnchorDate` is non-null and passes timestamp validation.
- `itemVersion` is an exact integer in `1..9223372036854775807`.
- `infoAfterMinutes`, `warningAfterMinutes`, and `dangerAfterMinutes` are exact integers, not floating-point or numeric strings, and satisfy:

```text
0 <= infoAfterMinutes
infoAfterMinutes <= warningAfterMinutes
warningAfterMinutes <= dangerAfterMinutes
dangerAfterMinutes <= 5,258,880
```

- `completedAt` and `completedByMemberId` are either both null or both non-null.
- A non-null `completedAt` passes timestamp validation.
- A non-null `completedByMemberId` satisfies the ID contract and resolves to a membership in this same snapshot Pack.
- Unknown/cross-Pack actors reject the snapshot; the projector never clears or rewrites attribution.
- Item `createdAt` and `updatedAt` pass timestamp validation.
- Title and description follow their declared type/nullability. No undocumented length limit is added.

### 9.5 Structural versus product validation

The projector enforces all structural, type, identity, referential-integrity, enum, range, pair-nullability, canonical-display-name, and cache-compatibility rules explicitly locked upstream. It also rejects values that are guaranteed to violate a locked SQLite constraint, such as an empty `iconEmoji`.

The remote server remains responsible for product rules whose precise limits are not in `06`–`10`, including any future Pack/Item title, description, or icon repertoire policy. The projector does not invent arbitrary limits, reinterpret an accepted remote string, or treat SQLite's absence of a product constraint as authority to repair data.

## 10. Remote ID and String Validation

### 10.1 Unicode scalar contract

Every decoded string MUST be a well-formed sequence of Unicode scalar values. Reject unpaired UTF-16 surrogates or any decoder representation that cannot round-trip to valid UTF-8. “Unicode code points” in this contract means the count of decoded Unicode scalar values, not UTF-8 bytes and not UTF-16 code units.

Remote IDs:

- contain 1–128 Unicode scalar values;
- use exact code-point equality;
- receive no Unicode normalization, case folding, trimming, syntax reinterpretation, UUID parsing, or locale-aware comparison.

### 10.2 Normative whitespace set

For display-name validation, “Unicode whitespace” is exactly this stable White_Space code-point set:

```text
U+0009..U+000D, U+0020, U+0085, U+00A0, U+1680,
U+2000..U+200A, U+2028, U+2029, U+202F, U+205F, U+3000
```

A membership `displayName` is valid only when:

- it contains 1–40 Unicode scalar values;
- its first and last scalar are not in the whitespace set;
- it contains at least one scalar not in the whitespace set.

The projector validates that the remote value is already trimmed/canonical. It MUST NOT trim and accept a different value. Interior whitespace, duplicate names, Chinese, Latin text, numbers, and well-formed emoji are allowed. No Dart package is selected in Phase 1c; Phase 2d must implement exactly these semantics.

### 10.3 Presence and textual equality

Null, empty string, missing field, and a non-empty string are distinct protocol states. Required fields must be present. Nullable description fields may be explicit null or strings, and null must remain distinct from `""`. No Unicode normalization or whitespace repair occurs for any authoritative string.

## 11. UTC Timestamp Decode and Canonicalization

Apply this procedure independently to `generatedAt`, Pack `createdAt`/`updatedAt`, membership `joinedAt`, and Item `stateAnchorDate`, `completedAt` when present, `createdAt`, and `updatedAt`:

1. Require the transport lexeme to end in uppercase `Z` or an explicit numeric offset in ISO-8601 form (`±HH:MM`). A lowercase `z` or timezone-less lexeme is invalid even if a runtime parser would accept or interpret it locally.
2. Parse the calendar/time and offset strictly. Invalid dates, invalid offsets, leap-second forms unsupported by the selected runtime contract, trailing junk, and precision that cannot be represented as an exact millisecond are rejected rather than rounded.
3. Convert the represented instant to UTC.
4. Convert to an integer count of milliseconds since `1970-01-01T00:00:00Z`.
5. Require `0 <= epochMilliseconds <= 253402300799999`.
6. Use that epoch-millisecond integer for persistence and canonical fingerprint input.

Equivalent instants with different offsets canonicalize identically. For example, `2026-08-05T00:00:00Z` and `2026-08-05T08:00:00+08:00` both become `1785888000000`.

The projector MUST NOT:

- interpret remote UTC as device local time;
- use device timezone in decode or canonicalization;
- substitute request start, local receive, or device-current time for a remote field;
- add `createdAt <= updatedAt`, `generatedAt >= updatedAt`, completion/anchor equality, or other temporal-order rules not expressly locked by the source contracts.

## 12. Canonical Semantic Snapshot

The normative fingerprint input is a new semantic document named here as `SharedPackCanonicalSnapshotV1`. It is not raw remote JSON, a DTO dump, a cache-row dump, or a Dart object string.

### 12.1 Exact document shape

The canonical document has exactly these keys in exactly this order:

```text
{
  "remoteSnapshotSchemaVersion": integer,
  "remotePackId": string,
  "packVersion": integer,
  "pack": {
    "remotePackId": string,
    "title": string,
    "description": string | null,
    "iconEmoji": string,
    "createdAtEpochMs": integer,
    "updatedAtEpochMs": integer
  },
  "currentMembershipRemoteMemberId": string,
  "memberships": [
    {
      "remoteMemberId": string,
      "role": "owner" | "member",
      "displayName": string,
      "joinedAtEpochMs": integer
    }
  ],
  "items": [
    {
      "remotePackId": string,
      "remoteItemId": string,
      "title": string,
      "description": string | null,
      "type": "stateBased",
      "lifecycleStatus": "active",
      "stateAnchorDateEpochMs": integer,
      "infoAfterMinutes": integer,
      "warningAfterMinutes": integer,
      "dangerAfterMinutes": integer,
      "completedAtEpochMs": integer | null,
      "completedByMemberId": string | null,
      "itemVersion": integer,
      "createdAtEpochMs": integer,
      "updatedAtEpochMs": integer
    }
  ]
}
```

Membership summaries do not repeat `remotePackId` because their Pack context is the validated root. Items retain `remotePackId` because Item identity and every local operation are explicitly Pack-scoped. Current membership appears once as an identity marker; its full authoritative fields already appear in the membership list and were proven equal during validation.

### 12.2 Included content

The document includes:

- `remoteSnapshotSchemaVersion`, root `remotePackId`, and `packVersion`;
- all Pack authoritative metadata: ID, exact title, nullable description, exact icon, created instant, and updated instant;
- current membership identity;
- every authoritative membership field supplied in the summary: ID, role, exact display name, and joined instant;
- every active Item authoritative field: Pack-scoped identity, exact title, nullable description, type, lifecycle, anchor, thresholds, completion attribution, Item version, created instant, and updated instant.

### 12.3 Excluded content

The document excludes:

- `generatedAt`;
- `lastVerifiedAt` / upstream `lastRefreshedAt`;
- local surrogate IDs;
- local trust state or failure reason;
- request start/issue time and response arrival/receive time;
- `clientRequestId` or pending-mutation state;
- mutation-specific result/feedback envelopes;
- invite code or invite state;
- transport array order, raw JSON key order, formatting, and whitespace;
- UI/provider state and all Personal-domain values.

`generatedAt` is remote freshness evidence for a successfully accepted full response, not active state content at a Pack version. Different `generatedAt` values therefore do not change the fingerprint, though a later one may advance `last_verified_at` after acceptance.

## 13. Canonical Ordering

After duplicate validation and before serialization:

- sort memberships ascending by exact `remoteMemberId`;
- sort Items ascending by the complete tuple `(remotePackId, remoteItemId)`.

Each string comparison encodes the exact, non-normalized Unicode scalar sequence as UTF-8 and compares unsigned bytes lexicographically. At the first differing byte, the smaller byte sorts first; if one byte sequence is an exact prefix, the shorter sequence sorts first. No locale, collation, case fold, Unicode normalization, display name, local ID, or incoming array position participates.

Duplicate identity is a validation failure before sorting. Sorting MUST NOT deduplicate. Two semantically identical snapshots with different transport array orders therefore produce identical canonical arrays and fingerprints.

## 14. Canonical Serialization

### 14.1 SPCS-1 profile

Phase 1c selects the language-independent **Shared Pack Canonical Serialization profile 1 (`SPCS-1`)**, a deliberately narrow canonical JSON profile. It avoids relying on unordered map iteration or floating-point JSON implementations while retaining readable test vectors.

SPCS-1 rules are normative:

1. Serialize the exact document shape and key order in Section 12. No extra or omitted key is permitted; nullable keys are emitted with `null` rather than omitted.
2. Emit `{`, `}`, `[`, `]`, `:`, and `,` with no insignificant whitespace, indentation, or line break.
3. Encode integer values as the shortest base-10 JSON integer token: `0` or a non-zero leading digit followed by digits. Values in this schema are non-negative; no plus sign, decimal point, exponent, leading zero, or floating conversion is allowed. Implementations must preserve the full signed-64 version range exactly.
4. Encode null as the four ASCII bytes `null`.
5. Encode strings as JSON strings. Escape quotation mark as `\"`, reverse solidus as `\\`, and U+0008/U+0009/U+000A/U+000C/U+000D as `\b`, `\t`, `\n`, `\f`, `\r`. Encode other U+0000..U+001F controls as lowercase `\u00xx`. Emit every other Unicode scalar directly as UTF-8; do not escape it merely for ASCII output and do not escape `/`.
6. Reject non-scalar strings before serialization. Do not perform NFC/NFD/NFKC/NFKD normalization.
7. Arrays are already sorted under Section 13.
8. Encode the resulting character stream as UTF-8 without BOM.

Map insertion/iteration order is irrelevant because a conforming serializer emits fields explicitly in the locked order. Raw JSON, generic DTO encoders, and runtime `toString()` are not canonical inputs unless they are separately proven to implement SPCS-1 exactly.

### 14.2 Integer interoperability

SPCS-1 intentionally permits exact integer tokens through signed 64-bit maximum. A runtime that normally decodes JSON numbers through IEEE-754 binary64 MUST use an exact-integer path or decimal-token representation for canonicalization. Precision-losing conversion is a validation/implementation failure, not a reason to change the fingerprint.

## 15. Snapshot Fingerprint Algorithm

The algorithm is locked as:

```text
canonicalBytes = UTF8(SPCS-1(SharedPackCanonicalSnapshotV1))
digestBytes = SHA-256(canonicalBytes)
snapshotFingerprint = lowercaseHex(digestBytes)
```

Output is exactly 64 lowercase ASCII hexadecimal characters (`[0-9a-f]{64}`), satisfying the Phase 1b storage constraint. Hex encoding uses two lowercase digits per digest byte in digest order.

No salt, key, device value, randomized runtime hash, transport metadata, or local metadata participates. Phase 2d may add a cryptographic package only as an implementation requirement; Phase 1c does not modify `pubspec.yaml`.

### 15.1 Canonical semantic example

Two valid transport snapshots may differ as follows:

```text
Snapshot X:
  generatedAt = 2026-08-05T00:05:00Z
  memberships order = [member-b, member-a]
  items order = [item-z, item-a]
  pack.createdAt = 2026-08-05T08:00:00+08:00
  member-a.joinedAt = 2026-08-05T08:01:00+08:00

Snapshot Y:
  generatedAt = 2026-08-05T00:06:00Z
  memberships order = [member-a, member-b]
  items order = [item-a, item-z]
  pack.createdAt = 2026-08-05T00:00:00Z
  member-a.joinedAt = 2026-08-05T00:01:00Z
```

Assume all other authoritative fields are identical, Pack description is null, `item-a.description` is the empty string, and current membership is `member-b`. Both inputs validate and produce this same illustrative SPCS-1 document (shown with line breaks only for readability; hashed bytes contain none):

```json
{"remoteSnapshotSchemaVersion":1,"remotePackId":"pack-A","packVersion":12,"pack":{"remotePackId":"pack-A","title":"Home","description":null,"iconEmoji":"🏠","createdAtEpochMs":1785888000000,"updatedAtEpochMs":1785888060000},"currentMembershipRemoteMemberId":"member-b","memberships":[{"remoteMemberId":"member-a","role":"owner","displayName":"阿明","joinedAtEpochMs":1785888060000},{"remoteMemberId":"member-b","role":"member","displayName":"May","joinedAtEpochMs":1785888120000}],"items":[{"remotePackId":"pack-A","remoteItemId":"item-a","title":"Water plants","description":"","type":"stateBased","lifecycleStatus":"active","stateAnchorDateEpochMs":1785888000000,"infoAfterMinutes":60,"warningAfterMinutes":120,"dangerAfterMinutes":180,"completedAtEpochMs":null,"completedByMemberId":null,"itemVersion":3,"createdAtEpochMs":1785888000000,"updatedAtEpochMs":1785888060000},{"remotePackId":"pack-A","remoteItemId":"item-z","title":"Clean filter","description":null,"type":"stateBased","lifecycleStatus":"active","stateAnchorDateEpochMs":1785888000000,"infoAfterMinutes":1440,"warningAfterMinutes":2880,"dangerAfterMinutes":4320,"completedAtEpochMs":1785888120000,"completedByMemberId":"member-b","itemVersion":7,"createdAtEpochMs":1785888000000,"updatedAtEpochMs":1785888120000}]}
```

Normative hash input is the exact no-whitespace UTF-8 byte sequence represented by that one-line JSON. Its documented result is intentionally:

```text
<sha256-lowercase-hex-of-canonical-bytes>
```

The example demonstrates that input array order, equivalent timestamp offsets, and `generatedAt` do not affect the fingerprint. It also demonstrates that null and empty description remain distinct and that current membership is represented only by a validated identity marker. A variant changing `item-a.description` from `""` to null would produce different canonical bytes and fingerprint.

## 16. Version Acceptance Matrix

Pure validation, canonicalization, and fingerprint calculation happen before this matrix. Inside one database transaction, reread the current `shared_pack_cache` root by exact `remotePackId` and apply:

| Current root | Incoming relation | Additional guard | Database effect | Semantic outcome |
| --- | --- | --- | --- | --- |
| absent | n/a | valid full snapshot | create complete graph; server-assigned version need not be 1 | projected initial snapshot |
| present | incoming > cached | cached owner ID equals incoming owner ID | atomic full reconciliation; advance only at commit | projected newer snapshot |
| present | incoming = cached | incoming fingerprint equals stored fingerprint | no Pack/member/Item authoritative rewrite; freshness may advance by max | verified identical same-version snapshot |
| present | incoming = cached | fingerprint differs | no writes, including freshness | same-version content conflict |
| present | incoming < cached | none | no writes, deletion, or freshness update | ignored older snapshot |

For an existing root, a different incoming owner ID is a contract/integrity failure even at a newer version. Owner transfer and owner removal are outside Shared Pack v1; accepting a changed owner would silently implement an excluded capability. This owner-continuity guard runs inside the transaction before writes. It does not prevent the initial snapshot from establishing its one validated owner.

The root/version/fingerprint/owner guard MUST use the state reread inside the same transaction. A transaction-external precheck may be used only as an optimization and cannot authorize writes. A future per-Pack lock in Phase 1d is additive defense, never a replacement for this guard.

Same-version identical handling computes and compares the incoming fingerprint even if an outer layer believes content is unchanged. It does not rewrite children or metadata and never changes version/fingerprint. It may set:

```text
last_verified_at = max(existingLastVerifiedAt, incoming.generatedAtEpochMs)
```

Same-version conflict, older response, owner discontinuity, validation failure, unsupported schema, or local write failure do not update freshness.

## 17. Full Projection Transaction Algorithm

### 17.1 Prepared input

Before starting the transaction, prepare:

- validated exact Pack identity and version;
- validated Pack row values;
- memberships sorted canonically, with exactly one owner and current marker;
- Items sorted canonically, with resolved same-Pack actors;
- incoming membership and Item composite-key sets;
- all timestamps as bounded UTC epoch milliseconds;
- SPCS-1 bytes and the 64-character SHA-256 fingerprint;
- `incomingLastVerifiedAt = generatedAtEpochMs`.

### 17.2 Normative pseudocode

```text
prepare(snapshot):
  decoded = strictDecode(snapshot)
  semantic = validateAndCanonicalize(decoded)
  fingerprint = sha256Hex(spcs1(semantic))

transaction(remotePackId):
  currentRoot = readRootForPack(remotePackId)

  if currentRoot exists:
    if incomingVersion < currentRoot.version:
      return ignoredOlderSnapshot                    // no writes
    if incomingVersion == currentRoot.version:
      if fingerprint != currentRoot.fingerprint:
        return sameVersionContentConflict             // no writes
      update last_verified_at to max(existing, generatedAt)
      return verifiedIdenticalSameVersion

    cachedOwner = readExactlyOneCachedOwner(remotePackId)
    if cachedOwner is missing/ambiguous or cachedOwner.id != incomingOwner.id:
      return snapshotIntegrityFailure                 // no writes

  if currentRoot absent:
    insert complete root with incoming metadata/version/schema/fingerprint,
      trust_state = verified, trust_failure_reason = null,
      last_verified_at = generatedAt                  // uncommitted FK parent
  else:
    leave existing root authoritative fields unchanged until finalization

  clear is_current_membership for existing rows of this Pack
  upsert incoming memberships by (remotePackId, remoteMemberId),
    preserving local_id and assigning exact role/displayName/joinedAt/current flag
  upsert incoming Items by (remotePackId, remoteItemId),
    preserving local_id and assigning all authoritative fields
  delete stale Items for this Pack by composite identity
  delete stale memberships for this Pack by composite identity

  if currentRoot existed:
    update root metadata/schema/version/fingerprint,
      last_verified_at = max(existing, generatedAt)
    // Phase 1d owns trust transition/reason clearing for an existing root

  commit
  return projectedInitial or projectedNewer
```

### 17.3 Root insertion and finalization

On an initial projection, the Pack root must exist before FK children and every root column is non-null. Therefore the transaction inserts the complete final root values before children. This does not expose partial truth: the row and its version/fingerprint/freshness remain uncommitted and roll back if any later write fails.

For an existing root, authoritative metadata, schema version, snapshot fingerprint, Pack version, and freshness remain unchanged until child reconciliation succeeds, then are finalized in one update immediately before commit.

No cache update is reported externally until the transaction commits. Any exception from a write, constraint, connection, or commit rolls back Pack root, children, version, fingerprint, and freshness together.

### 17.4 Scope guards

Every select, update, upsert, and delete is scoped by exact `remotePackId`. Membership and Item operations use their full composite identity. The transaction never deletes all rows in the database, never reconciles a second Pack, never accesses Personal tables, and never inserts a Personal action record.

## 18. Membership Constraint Staging

The schema has two partial unique indexes: one current membership and one owner per Pack.

Current-membership staging is locked as:

1. after root availability and acceptance guards, set `is_current_membership = 0` for all existing memberships of this Pack only;
2. upsert each incoming membership by `(remotePackId, remoteMemberId)` with its final role and current flag;
3. because validation proved exactly one current identity, exactly one final row receives `1`;
4. any failure rolls back the temporary zero-current state.

Owner staging is intentionally different:

- initial snapshots have exactly one validated owner and no old owner row;
- existing snapshots first prove inside the transaction that the cached owner identity equals the incoming owner identity;
- the owner row is updated in place by its composite identity, not inserted under another ID;
- every other incoming membership has role `member`;
- stale memberships are deleted only after Items.

This avoids a transient second owner without temporarily rewriting roles or permitting owner transfer. A missing/ambiguous cached owner or changed owner identity fails closed; it is not repaired by demoting/promoting rows. Foreign keys and partial indexes remain enabled throughout.

## 19. Missing-row Reconciliation and Delete Order

An accepted newer full snapshot's membership and Item arrays are the complete active sets for that Pack.

Locked behavior:

- upsert retained/incoming membership rows by `(remotePackId, remoteMemberId)` and preserve `local_id`;
- upsert retained/incoming Item rows by `(remotePackId, remoteItemId)` and preserve `local_id`;
- an incoming Item actor's membership is available before the Item upsert;
- local Items whose Pack-scoped identity is absent from the incoming set are hard-deleted;
- local memberships whose Pack-scoped identity is absent are hard-deleted only after stale Items;
- an archived remote Item is represented by absence from the active snapshot and consequent hard deletion;
- no tombstone or inactive marker is created;
- no unconditional delete-and-reinsert of retained rows is allowed merely for convenience;
- no operation uses bare `remoteItemId`.

Normative order:

```text
read and guard current root
→ prepare/ensure Pack root
→ clear old current-membership flags for this Pack
→ upsert incoming memberships
→ upsert incoming Items
→ delete stale Items
→ delete stale memberships
→ finalize existing Pack metadata/version/fingerprint/freshness
→ commit
```

Upserting incoming Items before deleting stale Items is safe because all incoming actor memberships are already present and stale memberships still exist. Deleting stale Items before stale memberships satisfies `ON DELETE RESTRICT`. Invalid input that retains an Item but omits its actor fails pure validation before this sequence and is never “fixed” by delete order.

## 20. Freshness Mapping

The upstream `lastRefreshedAt` semantic maps to the locked local column:

```text
upstream latest successful remote acquisition/verification
→ shared_pack_cache.last_verified_at
```

For an accepted full snapshot:

```text
candidate = canonical epoch milliseconds of snapshot.generatedAt
newLastVerifiedAt =
  candidate                                      if no root exists
  max(existingLastVerifiedAt, candidate)         otherwise
```

Use only remote `generatedAt`. Do not use request start, response receive, device-current time, or device timezone. The freshness value becomes durable only with the successful transaction commit.

Validation failure, unsupported schema, owner discontinuity, same-version conflict, older response, write/commit failure, and rollback never update freshness. A same-version identical snapshot may advance freshness without rewriting authoritative rows. An older `generatedAt` never moves it backward.

## 21. `notModified` Algorithm

`notModified` is a separate narrow verification operation. It is not a full snapshot and never enters canonicalization or fingerprint calculation.

### 21.1 Input and pure validation

Request context contains exact `remotePackId` and the exact integer `sentKnownPackVersion`. Response contains `remotePackId`, `packVersion`, and `verifiedAt`.

Before the transaction:

1. validate request and response Pack IDs under the remote-ID contract;
2. require response Pack ID to exactly equal the request target;
3. validate both versions in the signed-64 positive range;
4. require `response.packVersion == sentKnownPackVersion`;
5. require `verifiedAt` to have `Z` or explicit numeric offset, convert it to UTC epoch milliseconds, and enforce the storage range.

Failure of any check is a validation/contract failure and writes nothing.

### 21.2 Transaction guard and update

```text
transaction(requestPackId):
  root = read root by exact requestPackId

  if root absent:
    return missingCacheNotModifiedIgnored           // no row created

  if root.remotePackVersion != sentKnownPackVersion:
    return staleBaseNotModifiedIgnored              // no freshness update

  // pure validation already proved response version == sent version
  update only root.last_verified_at =
    max(root.last_verified_at, verifiedAtEpochMs)
  commit
  return validNotModifiedVerification
```

Successful verification requires all three versions to match:

```text
response.packVersion
== sentKnownPackVersion
== current cached remotePackVersion
```

It does not rewrite Pack metadata, membership rows, Item rows, version, schema version, fingerprint, or children; it creates/deletes nothing. Phase 1d owns whether this evidence changes `needsRevalidation` to `verified`, clears a failure reason, or reopens mutation.

## 22. Projection Outcomes and Failure Boundary

Future implementations need semantic distinctions at least equivalent to:

- projected initial snapshot;
- projected newer snapshot;
- verified identical same-version snapshot;
- ignored older snapshot;
- same-version content conflict;
- snapshot validation failure;
- unsupported snapshot schema;
- owner-continuity/integrity failure;
- local projection/write/commit failure;
- valid `notModified` verification;
- stale-base `notModified` ignored;
- missing-cache `notModified` ignored;
- invalid `notModified` contract response.

These are semantic outcomes, not UI wording and not a locked Dart enum. Persisted trust transitions and reason codes belong to Phase 1d; formal application/port result types belong to Phase 1f.

If a remote mutation succeeded and local projection failed, the projector reports only the local projection outcome. It MUST NOT rewrite remote success as remote failure, claim that the mutation did not happen, automatically retry, or advance cache truth. Projector scope excludes refresh orchestration, locks, pending intent, mutation gating, and recovery sequencing.

## 23. Phase 1d Trust/Coordination Handoff

The non-null `trust_state` column creates a narrow cross-phase seam:

- an initial root created by a fully valid, successfully committed snapshot must use the minimum legal initial value `verified` and `trust_failure_reason = null`;
- successful newer/identical full-snapshot acceptance and valid `notModified` produce remote-verification success evidence;
- same-version conflict, owner discontinuity, validation failure, unsupported schema, or local projection failure produce evidence that success cannot be claimed;
- older full snapshots and stale/missing-cache `notModified` are no-write outcomes, not verification of the current cache.

Phase 1d must lock:

- per-Pack mutex and request serialization;
- coordination outside the database transaction;
- trust-state transitions among `verified`, `needsRevalidation`, and `inaccessible`;
- `trust_failure_reason` vocabulary and clearing rules;
- mutation gating and recovery sequencing;
- pending mutation lifecycle, `clientRequestId` reuse, restart behavior, and retry policy.

For an existing root, this document does not silently clear or change trust fields during projection. Phase 1d must define how success/failure evidence and the atomic cache operation compose so no caller observes a committed graph with an inconsistent trust transition. If Phase 1d needs additional atomic updates, it must preserve the Phase 1c acceptance, graph, and rollback invariants without adding columns in Phase 1c.

## 24. Scenario Walkthroughs

### 24.1 Scenario A — Older refresh arrives late

- Starting cache: Pack P version 11 with fingerprint F11, children C11, freshness T11.
- Incoming response: valid full snapshot for P version 10; canonical fingerprint is F10.
- Validation result: succeeds; canonicalization/fingerprint complete before transaction.
- Version decision: transaction rereads 11; 10 < 11.
- Transaction writes: none.
- Rows deleted/preserved: no rows deleted; root and C11 are preserved byte-for-byte.
- Final version: 11.
- Final fingerprint: F11.
- Freshness effect: remains T11.
- Projector semantic outcome: ignored older snapshot.
- Phase 1d follow-up: optional diagnostics only; no trust transition is defined here.

### 24.2 Scenario B — Mutation and refresh cross

- Starting cache: version below 8.
- Incoming response: mutation snapshot version 8 with F8 and refresh snapshot version 9 with F9, in either arrival order.
- Validation result: each response independently validates and fingerprints.
- Version decision: each transaction rereads current root. If 8 commits first, 9 then projects. If 9 commits first, late 8 is ignored.
- Transaction writes: at most the accepted graph transactions; version 8 never writes over committed 9.
- Rows deleted/preserved: reconciliation follows each accepted snapshot; after 9 commits, its complete active row set is preserved and an arriving 8 deletes nothing.
- Final version: 9.
- Final fingerprint: F9.
- Freshness effect: the accepted version-9 `generatedAt` may advance freshness by max; late version 8 cannot change it.
- Projector semantic outcome: projected newer version 9; version 8 is either an earlier projection followed by 9 or ignored older.
- Phase 1d follow-up: may serialize/lock operations, but transaction guard remains mandatory.

### 24.3 Scenario F — Same version, different content

- Starting cache: version 12, fingerprint F12, freshness T12.
- Incoming response: valid version 12 with fingerprint F12x where F12x != F12.
- Validation result: succeeds; mismatch is detected at transactional acceptance.
- Version decision: equal version, different content, fail closed.
- Transaction writes: none.
- Rows deleted/preserved: all existing root/children preserved; no incoming row is projected.
- Final version: 12.
- Final fingerprint: F12.
- Freshness effect: remains T12.
- Projector semantic outcome: same-version content conflict.
- Phase 1d follow-up: owns trust transition/recovery/mutation gating and reason code.

### 24.4 Scenario G — Valid `notModified`

- Starting cache: version 12, fingerprint F12, children C12, freshness T12; request sent known version 12.
- Incoming response: valid matching Pack ID, version 12, and `verifiedAt` TV.
- Validation result: succeeds, including response version equals sent known version.
- Version decision: transaction confirms current root still version 12.
- Transaction writes: update only `last_verified_at = max(T12, TV)`.
- Rows deleted/preserved: no deletion; metadata, C12, version, and fingerprint remain unchanged.
- Final version: 12.
- Final fingerprint: F12.
- Freshness effect: becomes `max(T12, TV)`.
- Projector semantic outcome: valid `notModified` verification.
- Phase 1d follow-up: owns trust recovery effects.

### 24.5 Stale `notModified`

- Starting cache: request sent at version 12, then cache advances to version 13 with F13/C13/T13 before response.
- Incoming response: `notModified` says matching Pack/version 12 with valid `verifiedAt` TV.
- Validation result: request/response pair is internally valid.
- Version decision: transaction rereads 13, which differs from sent 12.
- Transaction writes: none.
- Rows deleted/preserved: C13 and root are preserved; no row is created/deleted.
- Final version: 13.
- Final fingerprint: F13.
- Freshness effect: remains T13; TV is not evidence for version 13.
- Projector semantic outcome: stale-base `notModified` ignored.
- Phase 1d follow-up: no current-cache verification evidence is produced.

### 24.6 Projection write failure

- Starting cache: complete old graph V/F/T.
- Incoming response: valid newer full snapshot V2/F2 with generated freshness T2.
- Validation result: succeeds.
- Version decision: V2 > V and is accepted inside the transaction.
- Transaction writes: controlled failure interrupts an Item upsert after root/membership work; transaction rolls back.
- Rows deleted/preserved: every attempted insert/update/delete is undone; all old children remain.
- Final version: V.
- Final fingerprint: F.
- Freshness effect: remains T.
- Projector semantic outcome: local projection/write failure; remote mutation success, if any, remains remote success.
- Phase 1d follow-up: mark/recover/gate semantics and authoritative refresh orchestration.

### 24.7 Missing Item/archive reconciliation

- Starting cache: version V/F/T with Items A and B.
- Incoming response: valid newer active snapshot V2/F2 contains only A and has generated freshness T2.
- Validation result: succeeds.
- Version decision: V2 > V.
- Transaction writes: upsert A in place, hard-delete B by Pack-scoped key, then finalize root.
- Rows deleted/preserved: B deleted; A preserved with its local surrogate ID and updated fields; no tombstone/archived row created.
- Final version: V2.
- Final fingerprint: F2.
- Freshness effect: becomes `max(T, T2)`.
- Projector semantic outcome: projected newer snapshot.
- Phase 1d follow-up: normal success evidence.

### 24.8 Missing membership with stale actor Item

- Starting cache: version V/F/T; Item B references membership M2.
- Incoming response: valid newer snapshot V2/F2/T2 omits both B and M2.
- Validation result: succeeds because no retained incoming Item references M2.
- Version decision: V2 > V.
- Transaction writes: upsert incoming graph, delete B, delete M2, then finalize root; FK stays enabled.
- Rows deleted/preserved: B is deleted before M2; all retained rows keep their local IDs.
- Final version: V2.
- Final fingerprint: F2.
- Freshness effect: becomes `max(T, T2)`.
- Projector semantic outcome: projected newer snapshot.
- Phase 1d follow-up: normal success evidence.

### 24.9 Invalid missing actor

- Starting cache: version V/F, children C, freshness T.
- Incoming response: retains B with `completedByMemberId = M2` but memberships omit M2.
- Validation result: fails before a write transaction begins.
- Version decision: not reached; incoming version is not accepted.
- Transaction writes: none.
- Rows deleted/preserved: all C preserved; actor is not nulled and no row is repaired.
- Final version: V.
- Final fingerprint: F.
- Freshness effect: remains T.
- Projector semantic outcome: snapshot validation failure.
- Phase 1d follow-up: trust/gating/recovery handling.

### 24.10 Array-order equivalence

- Starting cache: absent initially, then version 12/F12/C12/T12 after the first response.
- Incoming response: a second version-12 snapshot with identical semantic fields but reversed membership/Item array order and generated freshness T2.
- Validation result: succeeds; canonical sorted arrays and SPCS-1 bytes equal the first response.
- Version decision: equal version and equal fingerprint.
- Transaction writes: only `last_verified_at = max(T12, T2)` may be written.
- Rows deleted/preserved: C12 preserved; no child rewrite/deletion.
- Final version: 12.
- Final fingerprint: F12 for both inputs.
- Freshness effect: becomes `max(T12, T2)`.
- Projector semantic outcome: verified identical same-version snapshot.
- Phase 1d follow-up: may consume success evidence only.

### 24.11 Generated-time equivalence

- Starting cache: version 12/F12/C12 with freshness T12 from the first full snapshot.
- Incoming response: same version/content with a different valid `generatedAt` T2.
- Validation result: succeeds; `generatedAt` is excluded, so canonical fingerprint remains F12.
- Version decision: equal version and equal fingerprint.
- Transaction writes: only max-freshness update is eligible.
- Rows deleted/preserved: C12 preserved with no authoritative-row rewrite.
- Final version: 12.
- Final fingerprint: F12.
- Freshness effect: becomes `max(T12, T2)`; an older T2 cannot decrease it.
- Projector semantic outcome: verified identical same-version snapshot.
- Phase 1d follow-up: success evidence remains separate from trust transition.

### 24.12 Offset equivalence

- Starting cache: absent for the first input, then version 12/F12/C12/T12.
- Incoming response: a second otherwise identical version-12 snapshot replaces one authoritative timestamp lexeme `2026-08-05T00:00:00Z` with `2026-08-05T08:00:00+08:00` and has generated freshness T2.
- Validation result: both offsets are explicit/in range and both instants canonicalize to `1785888000000`.
- Version decision: equal version and equal fingerprint.
- Transaction writes: only max-freshness update may occur.
- Rows deleted/preserved: C12 preserved with no child rewrite/deletion.
- Final version: 12.
- Final fingerprint: F12 for both offset spellings.
- Freshness effect: becomes `max(T12, T2)`.
- Projector semantic outcome: verified identical same-version snapshot.
- Phase 1d follow-up: no special handling.

### 24.13 Owner identity changes on a newer version

- Starting cache: version V/F/C/T with owner M1.
- Incoming response: otherwise valid newer snapshot V2/F2 with exactly one owner M2 and generated freshness T2.
- Validation result: pure snapshot validation succeeds in isolation.
- Version decision: V2 is newer, but the in-transaction owner-continuity guard rejects M1 != M2.
- Transaction writes: none; no owner demotion/promotion is staged.
- Rows deleted/preserved: all C including M1 are preserved; M2 is not inserted.
- Final version: V.
- Final fingerprint: F.
- Freshness effect: remains T.
- Projector semantic outcome: owner-continuity/integrity failure.
- Phase 1d follow-up: trust/gating/recovery handling; supporting owner transfer requires an upstream v1.x contract revision.

## 25. Future Phase 2d/2e Test Contract

### 25.1 Phase 2d validator tests

- supported schema accepted; unsupported schema rejected distinctly;
- timezone-less timestamp rejected;
- explicit offset timestamp converted correctly to UTC;
- sub-millisecond/non-exact timestamp and epoch underflow/overflow rejected;
- equivalent offset instants accepted as equal;
- malformed Unicode/unpaired surrogate rejected;
- remote ID empty/over-128 rejected and exact case preserved;
- duplicate membership ID rejected;
- zero and multiple owners rejected;
- zero/multiple/missing current membership rejected;
- current membership Pack mismatch or summary role/displayName/joinedAt mismatch rejected;
- duplicate display names accepted;
- leading/trailing, all-blank Unicode display name rejected using the exact whitespace set;
- over-40-scalar display name rejected, including code-unit/code-point edge cases;
- duplicate Item tuple rejected;
- same `remoteItemId` under different Pack contexts is not treated as one cache identity;
- fixed and archived Items rejected;
- missing state anchor rejected;
- non-integer, misordered, negative, and above-5,258,880 thresholds rejected;
- completion pair mismatch and unknown/cross-Pack actor rejected;
- empty icon rejected before persistence;
- no invented title/description limit and null/empty preservation.

### 25.2 Phase 2d canonicalization/fingerprint tests

- membership and Item array order independence;
- raw transport JSON key order/formatting independence;
- exact UTF-8 byte ordering for IDs, including non-ASCII and prefix cases;
- equivalent offset timestamps produce identical epoch values/fingerprint;
- different `generatedAt` produces the same fingerprint;
- null versus empty string produces different canonical bytes/fingerprint;
- every authoritative content change produces a different fingerprint with collision caveat understood;
- current membership marker change produces a different fingerprint;
- local ID/trust/failure/freshness/request metadata changes do not affect fingerprint;
- SPCS-1 escaping/key order/integer encoding matches golden UTF-8 vectors;
- int64 versions retain exact decimal value without binary64 precision loss;
- SHA-256 output is exactly 64 lowercase hex characters;
- output is stable across repeated runs, processes, and at least two conforming implementation paths/golden vectors.

### 25.3 Phase 2e projector tests

- initial projection with server-assigned version greater than 1;
- newer projection;
- older response ignored with zero writes/freshness change;
- same-version/same-fingerprint performs no child or metadata rewrite and advances freshness only by max;
- same-version/different-fingerprint fails closed;
- newer snapshot changing owner identity fails closed;
- all writes roll back on injected Pack, membership, Item, delete, finalization, and commit failures;
- stale Items hard-delete; stale memberships delete after Items;
- new actor membership exists before Item upsert;
- local surrogate IDs survive retained-row upserts;
- current membership changes without transient partial-index collision;
- owner partial index stays enabled and owner is updated in place;
- no cross-Pack read/update/delete;
- every Item operation uses `(remotePackId, remoteItemId)`;
- same bare Item ID in two Packs affects only the target Pack;
- root/version/fingerprint/freshness advance only on successful commit;
- initial root insertion rolls back with child failure;
- Personal tables and `shared_pending_mutation` remain untouched;
- no archived/tombstone row is produced.

### 25.4 Phase 2e `notModified` tests

- exact request/response/cache version match updates freshness only;
- cache advanced since request produces no write;
- response version mismatch produces no write/contract failure;
- response Pack mismatch rejected;
- missing root creates no row;
- stale `verifiedAt` does not move freshness backward;
- invalid/timezone-less/out-of-range `verifiedAt` rejected;
- no Pack metadata, child, fingerprint, schema-version, or Pack-version write;
- transaction reread, not transaction-external state, decides validity.

## 26. Accepted Decision Register

| ID | Decision | Rationale | Protected invariant | Consequence for implementation phase |
| --- | --- | --- | --- | --- |
| SP-PROJ-001 | One projector accepts every authoritative full-snapshot source | All sources represent the same full active truth | No mutation-specific partial cache | Phase 2e routes all full responses through one implementation |
| SP-PROJ-002 | Strict decode and complete semantic validation precede cache writes | Invalid input cannot become partial truth | Validate before cache truth | Phase 2d supplies decoded/validated Shared DTO boundary |
| SP-PROJ-003 | Support exactly snapshot schema 1 | Partial forward parsing is unsafe | Fail closed on unsupported shape | Unsupported schema is a distinct outcome |
| SP-PROJ-004 | Timestamps require `Z` or numeric offset | Timezone-less input is ambiguous | Cross-device instant consistency | Decoder retains offset-presence evidence |
| SP-PROJ-005 | Canonical timestamps are bounded UTC epoch-millisecond integers | Equivalent offsets need one representation | Stable persistence and fingerprint | Phase 2d rejects rounding/overflow |
| SP-PROJ-006 | Remote strings remain exact Unicode scalars; display names use the locked whitespace set | Runtime trim/normalization differs | Identity and display fidelity | Phase 2d implements scalar/whitespace validation exactly |
| SP-PROJ-007 | Memberships sort by exact-ID UTF-8 byte order | Array/display order is non-authoritative | Deterministic membership content | Sort only after duplicate rejection |
| SP-PROJ-008 | Items sort by `(remotePackId, remoteItemId)` UTF-8 byte tuple | Item identity is Pack-scoped | Deterministic, scoped Item content | No bare-ID sorting/operation |
| SP-PROJ-009 | SPCS-1 fixed-key canonical JSON is the serialization | Generic map/JSON output can vary | Cross-runtime deterministic bytes | Phase 2d implements/golden-tests exact profile |
| SP-PROJ-010 | SHA-256 lowercase hex fingerprints SPCS-1 UTF-8 bytes | Stable standard digest fits v6 | One comparable content marker per version | Future dependency may be added only in Phase 2d |
| SP-PROJ-011 | `generatedAt` is excluded from fingerprint | It is freshness evidence, not versioned active content | Same content/version remains identical | It only feeds accepted freshness |
| SP-PROJ-012 | Local/trust/freshness/request/invite metadata is excluded | Local/runtime evidence is not remote active state | Device-independent content identity | Cache metadata changes never re-fingerprint |
| SP-PROJ-013 | Same version requires fingerprint equality | Version alone cannot prove content identity | One version means one content graph | Equal/same is no-child-rewrite verification |
| SP-PROJ-014 | Same-version different content fails closed | Last-writer-wins hides contract corruption | No arbitrary truth selection | No writes/freshness; report conflict |
| SP-PROJ-015 | Older snapshots are ignored completely | Arrival order is not authority order | Pack version monotonicity | No row/delete/freshness write |
| SP-PROJ-016 | Root/version/fingerprint/owner guards run inside transaction | External checks race | Acceptance is based on current committed truth | Phase 2e rereads before first write |
| SP-PROJ-017 | Full graph projection is one atomic transaction | A version describes a complete graph | No partial readable truth | Any failure rolls back all fields/rows |
| SP-PROJ-018 | Initial root may be inserted uncommitted before FK children | Required root columns/FKs need a parent | FK safety without partial exposure | Child failure rolls back initial root |
| SP-PROJ-019 | Missing active rows are hard-deleted | v6 has no inactive/tombstone storage | Cache equals full active set | Reconcile only target Pack |
| SP-PROJ-020 | Stale Items delete before stale memberships | Items may reference actors | Foreign-key integrity | FK remains enabled |
| SP-PROJ-021 | All Item operations use Pack-scoped composite identity | Bare ID is not globally unique | No cross-Pack corruption | DAO methods require both IDs |
| SP-PROJ-022 | Full snapshot freshness uses remote `generatedAt` and max | Local timing is not verification evidence | Freshness never decreases | Commit with accepted projection only |
| SP-PROJ-023 | `notModified` updates only freshness on exact three-way version match | Response verifies only its request base | Newer cache is not falsely refreshed | Missing/stale base are no-write outcomes |
| SP-PROJ-024 | Same-version identical snapshot does not rewrite authoritative rows/children | Content is already projected | Stable local IDs and minimal writes | Only max freshness may update |
| SP-PROJ-025 | Invalid snapshots are never repaired, deduplicated, or partially projected | Repair would invent authority | Remote full snapshot remains atomic | Whole snapshot fails |
| SP-PROJ-026 | Existing owner identity must remain stable | Owner transfer/removal is outside v1 | No excluded lifecycle capability | New owner ID is integrity failure |
| SP-PROJ-027 | Current uniqueness is staged by clearing flags; owner is guarded and updated in place | Partial unique indexes must remain active | Constraint-safe reconciliation | No FK/index disabling or owner transfer staging |
| SP-PROJ-028 | Trust transitions are deferred to Phase 1d | Phase 1c owns evidence/transactions, not coordination state machine | Roadmap ownership | Existing trust composition must be defined next |

## 27. Rejected Alternatives

The following are explicitly rejected:

- hashing the raw JSON response or depending on transport key order/whitespace;
- including `generatedAt` in the fingerprint;
- hashing Dart/object `toString()` or a randomized/runtime-specific hash;
- depending on incoming membership/Item array order;
- sorting memberships by display name;
- Unicode-normalizing, case-folding, trimming, or repairing authoritative strings;
- deduplicating invalid identities and continuing;
- dropping only an invalid child and projecting the rest;
- directly patching a mutation fragment;
- updating `remotePackVersion`, fingerprint, or freshness before the complete transaction can commit;
- comparing version only outside the transaction;
- allowing a lower version to update freshness;
- same-version/different-content last-writer-wins;
- rewriting all children for same-version identical input or `notModified`;
- letting stale `notModified` refresh a newer cache;
- creating a root for missing-cache `notModified`;
- deleting memberships before actor Items;
- identifying an Item by bare `remoteItemId`;
- deleting and reinserting all retained rows merely for convenience;
- storing archived rows or tombstones despite the Phase 1b schema;
- disabling foreign keys or partial unique indexes during projection;
- accepting a changed owner as an implicit v1 transfer;
- updating Personal tables or pending mutation state;
- implementing a per-Pack lock, retry, request queue, or trust state machine in Phase 1c.

## 28. Deferred Decisions

### Phase 1d — Runtime Coordination Design

- per-Pack mutex/lock and request serialization;
- concurrent-operation coordination outside the transaction;
- trust-state transition table and `trust_failure_reason` vocabulary;
- mutation gating and recovery sequencing;
- pending mutation lifecycle and `clientRequestId` reuse lifecycle;
- app restart classification and behavior;
- retry orchestration and automatic/manual recovery policy.

### Phase 1e — Remote Security and RPC Design

- Supabase dependency, remote SQL, RLS, and RPCs;
- remote snapshot-builder implementation and transaction consistency;
- remote ID/idempotency storage and retention;
- remote fingerprint/hash compatibility if later required.

### Phase 1f — Application/UI/Test Contract

- formal application-service and local-port method signatures;
- formal result types and remote/local outcome composition;
- Riverpod state, route map, UI wording/states, and dedicated screens;
- Fake Remote API and final integration/UAT matrix.

### Phase 2d

- validator, canonicalizer, SPCS-1 serializer, and fingerprint Dart implementation;
- actual cryptographic dependency;
- unit/golden tests.

### Phase 2e

- Drift projector/DAO transaction implementation;
- constraint-safe reconciliation and `notModified` write operation;
- failure-injection and actual transaction tests.

## 29. Explicitly Out of Scope

This phase does not add or design per-Pack lock implementation, request queues, pending-storage revisions, retry/background workers, automatic refresh scheduling, offline outbox, realtime, Supabase, SQL, RPC, RLS, account binding, identity recovery, membership discovery, `listMySharedPacks`, Personal promotion, fixed Shared Items, Pack timezone, recurring schedule, skip, defer, undo, action history, Home aggregation, Widget, notifications, Shared reset/unlink, UI, routes, providers, production code, or executable tests.

## 30. Phase 1c Review Checklist

- [x] All specified source and repository evidence was inspected.
- [x] Actual branch, HEAD, and clean starting tree are recorded.
- [x] Only the target Phase 1c document is added.
- [x] Validation is precise enough for Phase 2d tests.
- [x] Offset/UTC/epoch mapping and exact Unicode whitespace/scalar semantics are locked.
- [x] Canonical included/excluded fields, ordering, serialization, and SHA-256 are unambiguous.
- [x] `generatedAt` is excluded from fingerprint and used only as accepted full-snapshot freshness evidence.
- [x] Same-version conflict fails closed; older responses write nothing.
- [x] Acceptance guard rereads root/version/fingerprint/owner inside the transaction.
- [x] Projection is one atomic Pack-scoped transaction.
- [x] Root/FK and current/owner partial-index staging are safe.
- [x] Memberships precede actor Items; stale Items precede stale memberships.
- [x] Every Item identity operation uses `(remotePackId, remoteItemId)`.
- [x] Freshness uses remote evidence and never decreases.
- [x] `notModified` requires exact request/response/cache version agreement and writes only freshness.
- [x] Remote success and local projection outcome remain distinct.
- [x] Trust, coordination, pending intent, lock, retry, and recovery policy remain Phase 1d work.
- [x] Required scenarios and future Phase 2d/2e test obligations are covered.
- [x] Accepted/rejected/deferred registers are complete and no Shared Pack v1 scope is expanded.
- [x] No source spec, runtime, dependency, schema, generated file, or test is changed.

## 31. Exit Criteria

Phase 1c is COMPLETE when repository validation confirms this document is the only new phase artifact and `git diff --check` passes. The design above locks:

1. snapshot validation and unsupported-schema behavior;
2. remote timestamp offset validation and bounded UTC mapping;
3. canonical semantic snapshot and exact field presence;
4. deterministic membership/Item ordering;
5. SPCS-1 canonical serialization;
6. SHA-256 input/output and exclusions;
7. same-version conflict and identical-content handling;
8. older-response no-write behavior;
9. atomic full projection and in-transaction guards;
10. owner/current partial-index handling;
11. hard-delete reconciliation and Item-before-membership delete order;
12. full-snapshot freshness source and non-decrease rule;
13. exact-match-only `notModified` behavior;
14. projection outcomes and remote/local failure separation;
15. executable future Phase 2d/2e tests and later-phase deferrals.

No runtime/code/schema/test/dependency behavior is changed, and no Phase 1d or Phase 2 work is authorized by this document.

## 32. Next Allowed Step

```text
Next allowed step:
Phase 1d: Runtime Coordination Design
```

Phase 1c stops here.
It does not begin Phase 1d or Phase 2 implementation.
