# 08 Shared Pack Runtime Consistency Spec v1

Status: planned runtime consistency contract / not implemented.

This document defines Shared Pack v1 client runtime consistency, response ordering, cache trust, and failure semantics. It does not mean any runtime implementation, Shared Drift cache table, remote API, Supabase dependency, auth flow, route, provider, repository, mutex, queue, SQL, RPC, or UI implementation already exists.

## 1. Status And Authority

`08` is a planned contract for Phase 1 technical design and acceptance tests. It does not replace the existing authority split:

- Product scope, role permissions, version roadmap, and success standard are defined by `docs/core/06_shared_pack_direction_spec_v1.md`.
- Remote request / response shape, snapshot schema, idempotency remote behavior, projection contract, and security requirements are defined by `docs/core/07_shared_pack_remote_contract_v1.md`.
- Existing Personal/local-first core model and the Personal / Shared boundary are defined by `docs/core/04_core_model_spec_v1.md`.
- Runtime ordering, cache trust, freshness, and client failure semantics are defined by this document.

If scope conflicts, `06` wins. If remote request or response shape conflicts, `07` wins. If Personal boundary conflicts, `04` wins. `08` only clarifies how the v1 client must behave when valid planned requests overlap, fail, replay, or return in an order different from request order.

## 2. Core Runtime Principles

Shared Pack v1 runtime behavior is governed by these principles:

- Remote authoritative state has priority over local Shared cache.
- Local Shared cache is a readable projection, not mutation authority.
- A cache may claim a `remotePackVersion` only after full snapshot validation and transaction projection succeed.
- Response arrival order is not authoritative version order.
- Request start time does not decide which snapshot is newer.
- The client must not partial project a snapshot and then update `remotePackVersion`.
- A known-untrusted cache, including cache left behind after projection failure, must not continue as a safe mutation base.
- Remote success and local projection success are separate outcomes.
- Recovery must use the existing `getSharedPackSnapshot` contract and must not introduce hidden product capability.

## 3. Snapshot Version Monotonicity

The client must compare every incoming full snapshot against the currently cached `remotePackVersion` for the same `remotePackId` before the incoming snapshot becomes cache truth.

If:

```text
incomingSnapshot.packVersion < cachedRemotePackVersion
```

the incoming snapshot must not:

- overwrite the newer cache.
- decrease `remotePackVersion`.
- restore the Shared Pack to an older authoritative state.
- roll back Item, membership, or Pack metadata because an older response arrived late.
- update `lastRefreshedAt` as proof of a newer state.

If:

```text
incomingSnapshot.packVersion == cachedRemotePackVersion
```

the incoming snapshot may be treated as the same authoritative state only when the active snapshot content is identical under the supported snapshot schema. If the same Pack version has different active snapshot content, the client must fail closed as an integrity / contract failure. It must not arbitrarily choose one snapshot to project, must not update freshness trust, and must not hide the failure as a normal refresh result.

Phase 0.7 locks the monotonic invariant only. Phase 1 may implement it with request serialization, a per-Pack lock, transaction comparison guard, or another mechanism that preserves the same observable behavior.

## 4. Concurrent Request And Response Ordering

When mutation requests, manual refresh, and idempotency replay overlap for the same Pack, freshness is decided by authoritative `packVersion`.

Runtime rules:

- Do not use request issue order to decide freshness.
- Do not use response arrival order to decide freshness.
- A lower-version full snapshot must not overwrite a higher-version cache.
- `notModified` applies only when remote has verified the `knownPackVersion` supplied by the client for that request.
- A `notModified` response whose request `knownPackVersion` no longer equals the currently cached `remotePackVersion` must not update freshness trust for the current cache.
- If a response depends on a local base that has since been replaced by another successful projection, the response still must pass version monotonicity before it can affect cache truth.
- Phase 1 may serialize same-Pack mutations, but even serialized mutation handling must enforce the no-version-regression contract in the projector / cache write path.

This document does not specify mutex, queue, isolate, transaction, provider, or repository implementation.

## 5. Mutation Intent And `clientRequestId`

`clientRequestId` identifies one logical mutation intent.

Client semantics:

- Each logical mutation intent must use one `clientRequestId`.
- Transport retry for the same intent must reuse the same `clientRequestId`.
- Timeout, temporary disconnection, app-level cancellation, or lost response must not automatically become a new user intent.
- A new `clientRequestId` is used only when the user clearly starts a new operation.
- Same idempotency key plus same payload follows `07`: replay the original authoritative result and do not execute the mutation again.
- Same idempotency key plus different payload follows `07`: return `idempotencyConflict`.
- The client must not blindly generate a new ID and redo `createSharedPack`, `createSharedItem`, `joinSharedPack`, `completeSharedItem`, or another mutation while the remote outcome of the original intent is unknown.

Phase 0.7 does not define where pending IDs are stored. Whether an unconfirmed mutation intent and its `clientRequestId` must survive app restart is a deferred Phase 1 technical decision, not a mandate to add offline outbox or background mutation queue.

## 6. Remote Success, Local Projection Failure

The client must distinguish:

```text
remote mutation failure
```

from:

```text
remote mutation succeeded
but local full snapshot projection failed
```

For remote mutation failure, authoritative remote state was not changed by that failed request, except for allowed audit / rate-limit / idempotency bookkeeping.

For remote mutation success followed by local projection failure:

- Remote authoritative state has changed.
- The client must not tell the user the remote mutation did not happen.
- Local cache must not update to the new `remotePackVersion`.
- Local cache must not be treated as the latest authoritative projection.
- The Pack must enter a trust state that requires revalidation / resync before more mutation.
- Until an authoritative snapshot is fetched and projected successfully, known-stale cache must not be used as mutation base.
- Recovery should use the existing `getSharedPackSnapshot` contract.
- Recovery must not add a new product RPC, hidden discovery API, realtime sync, outbox, or merge engine.

This document does not require a specific field name such as `requiresRefresh`, `outOfSync`, or `projectionFailed`. It locks observable behavior and action boundaries.

## 7. Cache Trust And Action Boundary

Shared Pack v1 client state must distinguish at least these semantics:

1. Verified cache: the last full snapshot projection or `notModified` verification succeeded, the cache has not been marked untrusted, and allowed actions may proceed subject to role/version validation.
2. Needs revalidation cache: the last successful snapshot may still be displayed as last-known data, but the cache is known to need revalidation and must not be used for further mutation until refresh succeeds.
3. Inaccessible cache: `permissionDenied` or `packNotFound` means the Pack is not available to the current local Shared access state.

Required behavior:

- Stale by time does not automatically mean invalid.
- Known projection failure is different from a cache that simply has not refreshed recently.
- `permissionDenied` and `packNotFound` must fail closed.
- An inaccessible Pack must not continue to appear as a normal operable Shared Pack.
- Whether the UI hides the Pack from list or shows an inaccessible state is a Phase 1 UI design decision.
- Personal data reset must not interpret Shared Pack cache or access metadata as user-deleted Personal data. The preservation boundary remains as defined by `04`, `06`, and `07`.

## 8. Refresh And Freshness Semantics

`lastRefreshedAt` keeps the meaning already defined in `04`, `06`, and `07`: the latest successful remote acquisition or remote verification of Shared Pack current state.

It may update only after:

- full snapshot validation and projection commit succeed.
- mutation returned full snapshot validation and projection commit succeed.
- `notModified` returns after remote verifies the supplied `knownPackVersion`; use remote `verifiedAt`.
- the `notModified` request's `knownPackVersion` still matches the currently cached `remotePackVersion`.

It must not update because of:

- request start time.
- remote failure.
- validation failure.
- projection rollback.
- permission failure.
- `packNotFound`.
- unsupported snapshot version.
- an older response that would make freshness move backward.

For full snapshots, Phase 1 may decide the exact timestamp source as long as it represents remote state successfully obtained or verified, not request start time. Timestamp naming can be reconsidered in Phase 1, but the locked semantics must remain.

## 9. Shared Pack List Boundary

Shared Pack v1 list is:

> The local Shared cache list on this device for Packs that previously completed `createSharedPack` or `joinSharedPack` and then successfully completed full snapshot projection.

It is not:

- remote membership discovery.
- account recovery.
- `listMySharedPacks`.
- anonymous identity migration.
- device replacement recovery.

Therefore, building the Phase 1 Shared Pack list does not authorize adding a membership discovery request or recovery API. A Pack can appear in the list only through the local projected cache boundary already authorized by `04`, `06`, and `07`.

## 10. Explicit Runtime Invariants

The Phase 1 implementation and tests must preserve these invariants:

1. `remotePackVersion` never decreases.
2. The same Pack version must represent the same authoritative active snapshot.
3. Old response arrival cannot overwrite newer cache.
4. Partial snapshot cannot become cache truth.
5. Projection failure cannot advance cache version.
6. Remote success cannot be represented as confirmed remote failure.
7. Known-untrusted cache cannot be used as mutation base.
8. The same logical retry reuses the same `clientRequestId` within the guaranteed retry boundary.
9. Invite requests remain outside Pack snapshot versioning.
10. Personal reset preserves Shared access state as defined by `04`, `06`, and `07`.
11. Runtime recovery cannot introduce a new product capability or hidden remote discovery API.

## 11. Scenario-Based Acceptance Tests

These scenarios are contract inputs for Phase 1 technical design and tests. They describe expected behavior, not current implementation.

### Scenario A - Older Refresh Arrives Late

Given local cache has successfully projected Pack version 11.
When an earlier refresh response later returns a full snapshot at Pack version 10.
Then version 10 must not overwrite cache.
And `remotePackVersion` remains 11.
And Items, membership, and metadata remain at the version 11 projection.

### Scenario B - Mutation And Refresh Cross

Given a mutation returns a full snapshot at Pack version 8.
And a refresh returns a full snapshot at Pack version 9.
When the two responses arrive in any order.
Then the final cache must not be lower than version 9.
And a late version 8 projection attempt must not overwrite version 9.

### Scenario C - Remote Success, Projection Failure

Given `completeSharedItem` succeeds remotely.
And the returned full snapshot cannot be validated or projected locally.
Then local cache version must not update.
And the UI / application must not treat the operation as safe to redo as a new mutation.
And the Pack must require authoritative snapshot refresh before further mutation.
And recovery uses `getSharedPackSnapshot`.

### Scenario D - Timeout And Retry

Given a mutation request is sent and the client times out before receiving the response.
When the client retries the same logical intent.
Then it reuses the same `clientRequestId` and the same payload.
And remote idempotency replay returns the original authoritative result.
And the mutation is not executed a second time.

### Scenario E - Idempotency Payload Conflict

Given the same operation and `clientRequestId` are reused with a different payload.
When the request reaches remote.
Then remote returns `idempotencyConflict`.
And the client must not treat it as successful replay.

### Scenario F - Same Version, Different Content

Given local cache has Pack version 12.
When another snapshot for Pack version 12 arrives with different active snapshot content.
Then the client must fail closed.
And it must not arbitrarily project either snapshot.
And it must not increase freshness trust.

### Scenario G - `notModified`

Given the client sends a `knownPackVersion` equal to remote Pack version.
When remote returns `notModified` with `verifiedAt`.
Then the client updates only `lastRefreshedAt`.
And it does not rewrite Item or membership rows.
And it does not change `remotePackVersion`.

### Scenario H - Permission Lost

Given a refresh returns `permissionDenied` or `packNotFound`.
When the client handles the response.
Then the Pack uses inaccessible semantics.
And the old cache must not continue to display as a normal operable Pack.
And mutation actions for that Pack are disabled or blocked.

## 12. Deferred Phase 1 Technical Decisions

The following are intentionally left to Phase 1 technical design, provided the decisions preserve this contract:

- per-Pack mutex, queue, or transaction guard.
- request serialization implementation.
- pending `clientRequestId` storage.
- whether unconfirmed mutation intent survives app restart.
- cache trust state enum, column, DTO, or provider shape.
- whether projection response is temporarily stored for local retry.
- automatic refresh or manual retry orchestration.
- Shared Drift table types, indexes, and foreign keys.
- hard-delete cache row or tombstone strategy.
- RPC, SQL, RLS, and Supabase implementation.
- Dart DTO, repository, service, and provider naming.
- logging and diagnostic mechanism.
- UI presentation for stale, inaccessible, or recovering states.
- exact full snapshot freshness timestamp field mapping, as long as it follows the locked semantics.

This list preserves implementation flexibility. It must not be used to weaken the runtime invariants or to introduce new Shared Pack v1 product capabilities.

## 13. Phase 0.7 Completion Standard

Shared Pack Phase 0.7 documentation-only runtime consistency contract is complete when:

1. Runtime ambiguity that could cause incompatible implementation, cache corruption, duplicate mutation, security violation, or scope expansion has been closed.
2. Required invariants are explicitly defined.
3. Key race and failure scenarios have consistent expected results.
4. Remaining questions can be decided by Phase 1 technical design without violating this contract.
5. No production implementation changes are introduced.

Shared Pack Phase 0.7 documentation-only runtime consistency contract is complete.
The documentation is sufficiently stable to enter Phase 1 technical design.
