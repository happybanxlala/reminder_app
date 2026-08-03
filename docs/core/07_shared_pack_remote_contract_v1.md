# 07 Shared Pack Remote Contract v1

Status: planned / not implemented.

No Supabase dependency, table, RPC or production API exists yet unless verified in current repository. This document is a future implementation contract for Shared Pack Phase 1. It must not be read as evidence that remote auth, remote tables, RPCs, Shared Drift cache tables, or Shared Pack UI already exist.

## 1. Purpose

本文件定義 Shared Pack v1 的 planned remote boundary。產品範圍以 `docs/core/06_shared_pack_direction_spec_v1.md` 為準；現有 core/local model 以 `docs/core/04_core_model_spec_v1.md` 為準；Home Widget exclusion 以 `docs/core/05_home_widget_spec.md` 為準。

v1 remote contract 只支援：

- 建立新的 Shared Pack。
- `ItemType.stateBased` Shared Item definition 與 current-state read/write。
- Owner 建立、修改、封存 Shared Items。
- Owner 更新 Shared Pack metadata。
- invite code get-or-create、rotate、preview、join。
- Pack-scoped member `displayName`。
- Shared Item `done` write。
- minimum actor attribution。
- manual full snapshot refresh。
- authoritative result projection into independent Shared Drift readable cache。

v1 remote contract 不支援 `ItemType.fixed`、fixed schedule、recurring calendar semantics、Pack timezone、undo、skip、defer、full action history、Personal Pack conversion、Home / Widget / notification integration 或 legacy backup recovery。

## 2. Architecture Boundary

Planned application boundary：

```text
UI
→ SharedPackApplicationService
→ SharedPackRemoteApi
→ remote RPC / API
→ authoritative response
→ SharedPackCacheProjector
→ independent Shared Drift cache
→ provider refresh
```

禁止：

- UI 直接呼叫 Supabase。
- controller 直接呼叫 Supabase。
- native Widget 直接呼叫 Shared API。
- `SharedPackCacheProjector` 寫入 Personal `item_packs`、`items` 或 `item_action_records`。
- `SharedPackRemoteApi` 直接回傳 Personal domain models。
- Shared DTO 直接成為 Personal domain model。
- remote request 分散在不同 page、provider 或 controller。

`SharedPackApplicationService` 負責 local validation、呼叫 remote API、處理 authoritative response、交給 projector 更新 local cache。`SharedPackRemoteApi` 是 remote request catalog 的唯一技術入口。`SharedPackCacheProjector` 負責把 Shared remote DTO 投影成 independent Shared Drift readable cache。Shared cache repositories 只能服務 Shared Pack dedicated surface，不可被現有 Personal repositories 自動讀取。

## 3. Shared DTO Boundary

Shared DTO 必須與 Personal domain model 分離。Phase 1 可以決定實際 Dart class names，但語意不得混入現有 Personal `Item` / `ItemConfig` / `ItemActionRecord`。

### 3.1 Shared Pack DTO

Shared Pack metadata 至少包含：

- `remotePackId`
- `title`
- `description`
- `iconEmoji`
- `packVersion`
- `createdAt`
- `updatedAt`

### 3.2 Shared Membership DTO

Shared Pack membership 至少包含：

- `remoteMemberId`
- `remotePackId`
- `role`
- `displayName`
- `joinedAt`

`authUserId` 是 server-side technical identity，不可回傳成 UI display name。`displayName` 是 Pack-scoped，不代表 global profile。

### 3.3 Shared state-based Item DTO

Shared Item v1 只允許：

```text
type = stateBased
```

Shared state-based Item DTO 至少包含：

- `remoteItemId`
- `remotePackId`
- `title`
- `description`
- `type`
- `lifecycleStatus`
- `stateAnchorDate`
- `infoAfterMinutes`
- `warningAfterMinutes`
- `dangerAfterMinutes`
- `completedAt`
- `completedByMemberId`
- `itemVersion`
- `createdAt`
- `updatedAt`

v1 不接受 Personal `FixedItemConfig` 或任何 fixed schedule config。Archived Shared Items 不出現在 active snapshot 中。

## 4. Version Contract

Shared Pack v1 必須明確區分 Item 與 Pack 的 version。

### 4.1 `itemVersion`

每個 Shared Item 有獨立 `itemVersion`。以下 mutation 增加 `itemVersion`：

- `updateSharedItem`
- `completeSharedItem`
- `archiveSharedItem`
- 其他未來會改變 Item authoritative state 的 mutation

Mutation input 使用 `expectedItemVersion`。Mutation output 使用 `resultingItemVersion`。

### 4.2 `packVersion`

每個 Shared Pack 有 `packVersion`。任何會改變 Shared Pack snapshot current state 的 mutation 都增加 `packVersion`，包括：

- Pack metadata update
- membership change
- Shared Item create
- Shared Item update
- Shared Item archive
- Shared Item complete
- invite state if invite state is included in snapshot current state

Mutation input 使用 `expectedPackVersion` when the caller already has a Pack snapshot. Mutation output 使用 `resultingPackVersion`。Snapshot output 使用 `packVersion`。

### 4.3 `knownPackVersion`

`getSharedPackSnapshot` input 可以包含 `knownPackVersion`。用途只限：

- remote 回傳完整 snapshot。
- 或在完全未變更時回傳 `notModified`。

Client 比 remote 舊是正常 refresh 情況，不是 error。`staleVersion` 只屬於 mutation optimistic concurrency error。

## 5. Idempotency Contract

所有 remote mutation 使用 `clientRequestId`。

Idempotency scope：

```text
authUserId
+ operationName
+ clientRequestId
```

Remote behavior：

- Same key + same payload：回傳第一次 mutation 的原 authoritative result，不可再次執行 mutation，不可當成普通錯誤。
- Same key + different payload：回傳 `idempotencyConflict`。
- New key：正常執行 mutation。

Remote 必須保存足以 replay 原 response 的 idempotency record，或採用可提供相同行為的 atomic design。Phase 0.5 不決定 record retention duration；Phase 1 technical design 必須定義。

所有 mutation expected errors 可包含 `idempotencyConflict`。不可用模糊 duplicate request error 取代 replay semantics。

## 6. Snapshot Contract

`getSharedPackSnapshot` 回傳的是某個 Shared Pack 在某個 `packVersion` 下的完整 active current-state projection。

Snapshot 不是：

- incremental patch。
- action history。
- local backup。
- Personal Pack conversion payload。
- Supabase token 或 credential 容器。
- Personal / Shared 完整雲端統一模型。

v1 snapshot 至少包含：

- `remoteSnapshotSchemaVersion`
- `remotePackId`
- `packVersion`
- `generatedAt`
- pack metadata
- current caller membership
- membership summary
- active Shared Items
- minimum completion metadata

Archived Shared Items 不在 active snapshot 中。Snapshot membership summary 至少包含 `remoteMemberId`、`displayName`、`role`。UI 透過 `completedByMemberId` 對應 membership summary 顯示 actor attribution。

## 7. Snapshot Projection Contract

`SharedPackCacheProjector` 必須在單一 Drift transaction 內投影完整 active snapshot：

1. validate `remoteSnapshotSchemaVersion`
2. validate `remotePackId`
3. validate snapshot identity consistency
4. upsert `shared_pack_cache`
5. upsert `shared_membership_cache` rows
6. upsert all returned `shared_item_cache` rows
7. remove or deactivate membership cache rows absent from authoritative snapshot
8. remove or deactivate Shared Item cache rows absent from authoritative snapshot
9. update `remoteItemVersion` values
10. update `remotePackVersion`
11. update `lastRefreshedAt`
12. commit

若任何 validation、mapping 或 write 失敗：

- rollback 整個 transaction。
- 保留 refresh 前 cache。
- 不更新 `lastRefreshedAt`。
- 不顯示 partial snapshot。

遠端 active snapshot 中不存在的 local Shared Item，不可永久保留為 active stale Item。Projector 必須刪除或標記 inactive；Phase 1 technical design 可選 hard-delete cache row 或保留 tombstone，但 UI 不可再顯示為 active。Membership cache rows 同樣適用。

若 refresh 回傳 `permissionDenied` 或 `packNotFound`，client 不可繼續把舊 cache 顯示成可操作 Shared Pack。Planned data-layer behavior：

```text
shared_pack_cache.accessState = inaccessible
```

UI 應從正常 Shared Pack list 隱藏，或顯示不可存取狀態並禁止 action。Phase 1 technical design 必須選定實際 UI handling，但 data layer 必須 fail closed。

## 8. Planned Request Catalog

本章只定義 planned requests，不代表任何 RPC、table、file 或 Supabase function 已存在。

All mutation requests:

- include `clientRequestId`
- use the idempotency contract in Section 5
- validate permission server-side
- validate `expectedItemVersion` or `expectedPackVersion` when applicable
- return authoritative result
- project local cache only after remote success
- are called through `SharedPackApplicationService`

### 8.1 createSharedPack

Purpose: 建立新的 Shared Pack 與 owner membership。

Caller: Shared Pack owner flow through `SharedPackApplicationService`。

Auth requirement: `SharedIdentityService.ensureIdentity()` succeeds before request。

Input:

- `clientRequestId`
- `title`
- `description`
- `iconEmoji`
- `ownerDisplayName`
- optional initial state-based Shared Item definitions

Version guard:

- `expectedPackVersion` not applicable because the Pack does not exist yet.
- Initial state-based Shared Items start with server-assigned `itemVersion`.
- Created Pack starts with server-assigned `packVersion`.

Output:

- `remotePackId`
- owner membership with `remoteMemberId`, `displayName`, `role`
- authoritative pack metadata
- `packVersion`
- initial active snapshot or projection fragment

Remote side effect:

- Create Shared Pack.
- Create owner membership with Pack-scoped `ownerDisplayName`.
- Create initial state-based Shared Items if provided.
- Create idempotency record for replay.

Local cache projection:

- Project authoritative result into `shared_pack_cache`, `shared_membership_cache`, and `shared_item_cache`.
- Set `lastRefreshedAt` only after projection transaction commits.
- Do not write Personal `item_packs` or `items`.

Expected errors:

- `identityUnavailable`
- `validationFailed`
- `idempotencyConflict`
- `rateLimited`
- `remoteUnavailable`

Manual test:

- Device A obtains anonymous remote identity only when entering create flow, creates a Shared Pack with an owner display name, and sees it in the Shared Pack list after local cache projection.

### 8.2 updateSharedPackMetadata

Purpose: Owner 修改 Shared Pack title、description 或 icon metadata。

Caller: owner settings flow through `SharedPackApplicationService`。

Input:

- `clientRequestId`
- `remotePackId`
- `expectedPackVersion`
- `title`
- `description`
- `iconEmoji`

Output:

- authoritative pack metadata
- `resultingPackVersion`

Remote side effect:

- Verify owner permission.
- Verify `expectedPackVersion`.
- Update metadata atomically.
- Increase `packVersion`.

Local cache projection:

- Project authoritative metadata into `shared_pack_cache`.
- Update `remotePackVersion` after remote success.
- Refresh Shared Pack providers.

Expected errors:

- `identityUnavailable`
- `permissionDenied`
- `packNotFound`
- `staleVersion`
- `validationFailed`
- `idempotencyConflict`
- `rateLimited`
- `remoteUnavailable`

Manual test:

- Owner updates title on Device A; Device A projects the authoritative metadata after success, and Device B sees the new metadata after manual snapshot refresh.

### 8.3 createSharedItem

Purpose: Owner 在既有 Shared Pack 中建立新的 state-based Shared Item。

Caller: owner item management flow through `SharedPackApplicationService`。

Input:

- `clientRequestId`
- `remotePackId`
- `expectedPackVersion`
- `title`
- `description`
- state-based config: `stateAnchorDate`, `infoAfterMinutes`, `warningAfterMinutes`, `dangerAfterMinutes`

Output:

- authoritative Shared Item
- `resultingItemVersion`
- `resultingPackVersion`

Remote side effect:

- Verify owner permission.
- Verify `expectedPackVersion`.
- Reject any fixed Item config.
- Create active state-based Shared Item atomically.
- Increase `packVersion`.

Local cache projection:

- Insert / update returned row in `shared_item_cache`.
- Update `remoteItemVersion` and `remotePackVersion`.
- Do not write Personal `items`.

Expected errors:

- `identityUnavailable`
- `permissionDenied`
- `packNotFound`
- `staleVersion`
- `validationFailed`
- `unsupportedItemType`
- `idempotencyConflict`
- `rateLimited`
- `remoteUnavailable`

Manual test:

- Owner creates a state-based Shared Item; member cannot create one; member sees the new active Item after refresh.

### 8.4 updateSharedItem

Purpose: Owner 修改 Shared Item definition。

Caller: owner item management flow through `SharedPackApplicationService`。

Input:

- `clientRequestId`
- `remotePackId`
- `remoteItemId`
- `expectedItemVersion`
- `title`
- `description`
- state-based config: `stateAnchorDate`, `infoAfterMinutes`, `warningAfterMinutes`, `dangerAfterMinutes`

Output:

- authoritative Shared Item
- `resultingItemVersion`
- `resultingPackVersion`

Remote side effect:

- Verify owner permission.
- Verify `expectedItemVersion`.
- Reject archived Item mutation.
- Reject any fixed Item config.
- Update state-based Shared Item definition atomically.
- Increase `itemVersion`.
- Increase `packVersion`.

Local cache projection:

- Update returned row in `shared_item_cache`.
- Update `remoteItemVersion` and `remotePackVersion`.

Expected errors:

- `identityUnavailable`
- `permissionDenied`
- `packNotFound`
- `itemNotFound`
- `itemArchived`
- `staleVersion`
- `validationFailed`
- `unsupportedItemType`
- `idempotencyConflict`
- `rateLimited`
- `remoteUnavailable`

Manual test:

- Owner edits a threshold; member cannot edit; refresh returns the authoritative edited Item with increased Item and Pack versions.

### 8.5 archiveSharedItem

Purpose: Owner 封存 Shared Item definition。

Caller: owner item management flow through `SharedPackApplicationService`。

Input:

- `clientRequestId`
- `remotePackId`
- `remoteItemId`
- `expectedItemVersion`

Output:

- archived `remoteItemId`
- `resultingItemVersion`
- `resultingPackVersion`

Remote side effect:

- Verify owner permission.
- Verify `expectedItemVersion`.
- Mark Item archived atomically.
- Increase `itemVersion`.
- Increase `packVersion`.

Local cache projection:

- Remove or mark the row inactive in `shared_item_cache`.
- Update `remotePackVersion`.
- Active snapshot after archive must not return the archived Item.

Expected errors:

- `identityUnavailable`
- `permissionDenied`
- `packNotFound`
- `itemNotFound`
- `itemArchived`
- `staleVersion`
- `idempotencyConflict`
- `rateLimited`
- `remoteUnavailable`

Manual test:

- Owner archives an Item; member cannot archive; after refresh the archived Item is absent from the active Shared Item list.

### 8.6 getOrCreateInviteCode

Purpose: Owner 取得目前 active invite code；若沒有 active code，建立一個。

Caller: owner invite flow through `SharedPackApplicationService`。

Input:

- `clientRequestId`
- `remotePackId`
- `expectedPackVersion`

Output:

- normalized invite code
- display invite code
- `resultingPackVersion`

Remote side effect:

- Verify owner permission.
- If active code exists, return the same code.
- If no active code exists, create one.
- Do not invalidate an existing active code.
- Do not log canonical invite code in general logs.
- Increase `packVersion` only if invite state is part of snapshot current state and a new active code is created.

Local cache projection:

- Store only non-sensitive invite presentation state if needed.
- Do not store invite code as recovery credential.

Expected errors:

- `identityUnavailable`
- `permissionDenied`
- `packNotFound`
- `staleVersion`
- `idempotencyConflict`
- `rateLimited`
- `remoteUnavailable`

Manual test:

- Owner opens invite flow twice and receives the same active display code while it remains active.

### 8.7 rotateInviteCode

Purpose: Owner 手動 rotate invite code。

Caller: owner invite flow through `SharedPackApplicationService`。

Input:

- `clientRequestId`
- `remotePackId`
- `expectedPackVersion`

Output:

- new normalized invite code
- new display invite code
- `resultingPackVersion`

Remote side effect:

- Verify owner permission.
- Create a new code.
- Atomically invalidate the old active code.
- Do not support multiple parallel active codes.
- Do not log canonical invite code in general logs.
- Increase `packVersion` if invite state is part of snapshot current state.

Local cache projection:

- Store only non-sensitive invite presentation state if needed.
- Do not store invite code as recovery credential.

Expected errors:

- `identityUnavailable`
- `permissionDenied`
- `packNotFound`
- `staleVersion`
- `idempotencyConflict`
- `rateLimited`
- `remoteUnavailable`

Manual test:

- Owner rotates code; old code immediately fails preview / join; new code previews the Pack.

### 8.8 previewInviteCode

Purpose: Joiner checks what Shared Pack an invite code points to before joining.

Caller: joiner invite entry flow through `SharedPackApplicationService`。

Auth requirement: `SharedIdentityService.ensureIdentity()` succeeds before request。

Input:

- invite code entered by user
- supported preview contract version if Phase 1 needs one

Output:

- preview pack title
- preview pack icon
- join availability

Privacy:

- Pack title and icon are data visible to anyone holding a valid invite code.
- Do not return member names.
- Do not return owner identity.
- Do not return Shared Item titles or content.
- Do not return completion history.

Remote side effect:

- None, except audit / rate-limit counters.
- Normalize invite code again in the server-side atomic path.
- Apply rate limiting / brute-force protection.

Local cache projection:

- No persistent domain cache before join.

Expected errors:

- `identityUnavailable`
- `invalidInviteCode`
- `alreadyMember`
- `rateLimited`
- `remoteUnavailable`

Manual test:

- Device B enters Device A's code and sees only Pack title, icon, and join availability before joining.

### 8.9 joinSharedPack

Purpose: Joiner becomes a member of the invited Shared Pack.

Caller: joiner confirmation flow through `SharedPackApplicationService`。

Auth requirement: `SharedIdentityService.ensureIdentity()` succeeds before request。

Input:

- `clientRequestId`
- invite code entered by user
- `memberDisplayName`

Version guard:

- `expectedPackVersion` is not required because the joiner only has an invite preview and is not yet a member.
- Server must still perform duplicate membership protection atomically.

Output:

- `remotePackId`
- member membership summary
- full initial Shared Pack snapshot
- `packVersion`

Remote side effect:

- Normalize invite code again in the server-side atomic path.
- Atomically validate invite.
- Create membership with Pack-scoped `memberDisplayName`.
- Prevent duplicate membership.
- Increase `packVersion`.
- Apply rate limiting / brute-force protection.

Local cache projection:

- Project returned full snapshot into independent Shared cache.
- Set `lastRefreshedAt` only after projection transaction commits.

Expected errors:

- `identityUnavailable`
- `invalidInviteCode`
- `alreadyMember`
- `validationFailed`
- `idempotencyConflict`
- `rateLimited`
- `remoteUnavailable`

Manual test:

- Device B previews invite code, confirms join with a display name, and sees the Shared Pack in Shared Pack list after full snapshot projection.

### 8.10 getSharedPackSnapshot

Purpose: Manual refresh for Shared Pack active current state.

Caller: Shared Pack detail refresh action and app-level Shared Pack refresh flow through `SharedPackApplicationService`。

Input:

- `remotePackId`
- `knownPackVersion?`
- `supportedRemoteSnapshotSchemaVersion`

Output:

- full snapshot as defined in Section 6

Alternative output:

- `notModified`

Remote side effect:

- None, except audit / rate-limit counters.

Local cache projection:

- On full snapshot: use Snapshot Projection Contract in Section 7.
- On `notModified`: do not rewrite cache; Phase 1 technical design must decide whether `lastRefreshedAt` updates for a verified not-modified response.
- On `permissionDenied` or `packNotFound`: set `shared_pack_cache.accessState = inaccessible` through fail-closed handling.

Expected errors:

- `identityUnavailable`
- `permissionDenied`
- `packNotFound`
- `unsupportedRemoteSnapshotSchemaVersion`
- `rateLimited`
- `remoteUnavailable`

Manual test:

- Device B taps refresh after Device A completes an item and sees the authoritative result, or gets `notModified` when its known Pack version is current.

### 8.11 completeSharedItem

Purpose: Complete one Shared Item through remote authoritative write.

Caller: Shared Item list `done` action through `SharedPackApplicationService`。

Input:

- `clientRequestId`
- `remotePackId`
- `remoteItemId`
- `expectedItemVersion`
- optional `clientOccurredAt` for audit / diagnostic hint

Output:

- authoritative Shared Item
- `completedByMemberId`
- `completedAt`
- `resultingItemVersion`
- `resultingPackVersion`

Remote side effect:

- Verify caller has owner or member membership.
- Derive `completedByMemberId` from authenticated caller membership; do not trust client actor id.
- Verify `expectedItemVersion`.
- Reject archived Item.
- Generate authoritative `completedAt` on server.
- Update `stateAnchorDate` from authoritative `completedAt`.
- Record minimum completion metadata.
- Increase `itemVersion`.
- Increase `packVersion`.
- Return authoritative result.

Local cache projection:

- Only after remote success, project authoritative Shared Item into `shared_item_cache`.
- Update `remoteItemVersion` and `remotePackVersion`.
- Refresh Shared Pack providers.
- Do not insert Personal `ItemActionRecord`.

Expected errors:

- `identityUnavailable`
- `permissionDenied`
- `packNotFound`
- `itemNotFound`
- `itemArchived`
- `staleVersion`
- `idempotencyConflict`
- `rateLimited`
- `remoteUnavailable`

Manual test:

- Device A completes Shared Item; local cache updates only after remote success; Device B sees the same `completedByMemberId`, display name mapping, `completedAt`, Item version, and Pack version after manual refresh.

## 9. Independent Shared Drift Cache

Shared Pack v1 planned cache does not reuse existing Personal tables:

```text
shared_pack_cache
shared_membership_cache
shared_item_cache
```

Existing tables remain Personal / local-first only:

```text
item_packs
items
item_action_records
```

Principles:

- Shared Items v1 do not enter existing Home.
- Shared Items v1 do not enter global Item management.
- Shared Items v1 do not enter notification scheduling.
- Shared Items v1 do not enter Home Widget.
- Shared Items v1 do not enter Personal backup.
- Shared Items v1 cannot be read by existing Personal repository queries.
- `shared_pack_cache.localId + remotePackId` can carry Pack mapping.
- `shared_item_cache.localId + remoteItemId` can carry Item mapping.
- Extra mapping tables are not a default requirement; Phase 1 technical design may add one only with a clear reason.
- Remote ID mapping remains concentrated in Shared Pack data layer.

Phase 0.5 does not define exact SQL, Drift Dart table classes, indexes, foreign keys, migrations, or cache tombstone strategy.

## 10. Security Requirements

本章只定義規格，不實作。

Requirements:

- RLS required.
- membership-scoped read / write.
- owner-only requests must verify owner membership server-side.
- invite lookup / join must use atomic server-side path.
- invite code normalization must run server-side in the atomic path.
- `previewInviteCode` and `joinSharedPack` require rate limiting / brute-force protection.
- active invite code canonical value must not appear in general logs.
- service role key must not enter client.
- Supabase access token, refresh token or other credential must not enter backup.
- Preview returns only minimal Pack metadata: title, icon, join availability.
- Pack-scoped `displayName` is display metadata only and must not be used for authentication.
- Server must not trust client actor id.
- `completedByMemberId` must be derived from authenticated caller membership.
- Authoritative `completedAt` must be generated by server.
- Anonymous identity uses lazy initialization through Shared Pack flows only.
- Membership recovery must wait for account binding / identity upgrade spec and is not v1.

## 11. Backup Boundary

現有 JSON backup 是 legacy local export / import。

Shared Pack remote access 不由 local backup 恢復。Shared Pack cache、membership、invite code、remote identity mapping 與 credential 不應被當成傳統 backup recovery data。

未綁定帳號時，local backup 可保護 Personal local data。已綁定帳號後的長期方向是 Personal / Shared active data 由帳號與 remote membership 恢復。

Phase 0.5 不修改現有 backup production code。

## 12. Manual Acceptance Scenario

Device A:

1. 準備建立 Shared Pack 時 lazy initialize anonymous remote identity.
2. 建立 Shared Pack and owner membership with `ownerDisplayName`.
3. 建立 state-based Shared Item.
4. get-or-create invite code.
5. complete Shared Item.
6. remote 成功後 A local Shared cache 更新.

Device B:

1. 準備 preview invite code 時 lazy initialize anonymous remote identity.
2. 輸入 invite code.
3. 預覽 Pack title / icon only.
4. 確認加入並提供 `memberDisplayName`.
5. 手動 refresh.
6. 看見 A 完成後的 authoritative result and display name attribution.

Acceptance notes:

- A mutation 時，資料先寫到 remote authoritative layer。
- A local Drift cache 只在 remote 成功後更新。
- B 手動 refresh 時，資料從 `getSharedPackSnapshot` 取得完整 active snapshot。
- B local Drift cache 只在 snapshot validate + transaction projection 成功後更新。
- Widget、Home、notification、backup 與 Personal Pack data flow 不參與 v1 驗收。
