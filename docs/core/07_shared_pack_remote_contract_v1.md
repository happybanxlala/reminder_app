# 07 Shared Pack Remote Contract v1

Status: planned contract / not implemented.

No Supabase dependency, table, RPC or production API exists yet unless verified in current repository. This document is a future implementation contract for Shared Pack Phase 1. It must not be read as evidence that remote auth, remote tables, RPCs, Shared Drift cache tables, or Shared Pack UI already exist.

## 1. Purpose

本文件定義 Shared Pack v1 的 planned remote boundary。產品範圍以 `docs/core/06_shared_pack_direction_spec_v1.md` 為準；現有 core/local model 以 `docs/core/04_core_model_spec_v1.md` 為準；Home Widget exclusion 以 `docs/core/05_home_widget_spec.md` 為準；client runtime consistency、response ordering、cache trust 與 failure semantics 以 `docs/core/08_shared_pack_runtime_consistency_spec_v1.md` 為準。

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
- authoritative full snapshot projection into independent Shared Drift readable cache。

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

When multiple valid responses overlap or return out of order, the runtime monotonicity, cache trust, and recovery rules are defined by `docs/core/08_shared_pack_runtime_consistency_spec_v1.md`。

## 3. Protocol Versions

Shared Pack v1 鎖定：

```text
remoteApiContractVersion = 1
remoteSnapshotSchemaVersion = 1
```

`remoteApiContractVersion` 表示 Shared Pack remote request / response contract major version。Phase 1 client 和 remote implementation 必須共同使用 version `1`。Breaking contract change 必須增加 major version 或先更新 spec。

`remoteSnapshotSchemaVersion` 表示 Shared Pack full active snapshot schema。所有 mutation full snapshot 與 manual refresh snapshot 都使用 version `1`。Client 只可投影明確支援的 snapshot version；unsupported version 必須 fail closed，不得嘗試部分解析。

## 4. Shared DTO Boundary

Shared DTO 必須與 Personal domain model 分離。Phase 1 可以決定實際 Dart class names，但語意不得混入現有 Personal `Item` / `ItemConfig` / `ItemActionRecord`。

### 4.1 Shared Pack DTO

Shared Pack metadata 至少包含：

- `remotePackId`
- `title`
- `description`
- `iconEmoji`
- `packVersion`
- `createdAt`
- `updatedAt`

### 4.2 Shared Membership DTO

Shared Pack membership 至少包含：

- `remoteMemberId`
- `remotePackId`
- `role`
- `displayName`
- `joinedAt`

`authUserId` 是 server-side technical identity，不可回傳成 UI display name。`displayName` 是 Pack-scoped，不代表 global profile。

Membership invariants：

1. 一個 Shared Pack v1 恰好有一個 owner。
2. 同一 `authUserId` 在同一 `remotePackId` 最多一個 membership。
3. owner membership 在 v1 不可 leave。
4. owner membership 在 v1 不可被移除。
5. member removal 不屬於 v1。
6. owner transfer 不屬於 v1。
7. 同一 Pack 同一時間最多一個 active invite code。

Phase 1 technical design 應建立相等於 `unique(remotePackId, authUserId)` 的 database invariant。Active invite code 應有相等於 one active invite per `remotePackId` 的 database invariant。

`ownerDisplayName` 與 `memberDisplayName` validation：

- trim leading / trailing whitespace。
- trim 後不可為空。
- 不能只包含空白。
- 最大 40 Unicode code points。
- 可包含空格、中文、英文、數字及一般 emoji。
- 不可使用 `authUserId` / Supabase UID 作 fallback 公開名稱。

Pack 內 `displayName` 不要求唯一，允許多位成員使用相同顯示名稱。真正 identity 使用 `remoteMemberId`；不可用 `displayName` 作 authentication、authorization、foreign key、completion actor identity 或 membership uniqueness。

Actor attribution：

```text
completedByMemberId
→ membership summary remoteMemberId
→ displayName
```

### 4.3 Shared state-based Item DTO

Shared Item v1 只允許：

```text
type = stateBased
lifecycleStatus = active | archived
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

Active snapshot 中的 Shared Item 必須使用 `lifecycleStatus = active`。Archived Shared Items 不出現在 active snapshot 中。Restore / unarchive 不屬於 v1。

v1 不接受 Personal `FixedItemConfig` 或任何 fixed schedule config。

## 5. Version Contract

Shared Pack v1 必須明確區分 Item 與 Pack 的 version。

### 5.1 `itemVersion`

每個 Shared Item 有獨立 `itemVersion`。以下 mutation 增加 `itemVersion`：

- `createSharedItem`
- `updateSharedItem`
- `completeSharedItem`
- `archiveSharedItem`
- 其他未來會改變 Item authoritative state 的 mutation

Mutation input 使用 `expectedItemVersion` where applicable。Mutation output 使用 `resultingItemVersion`。

### 5.2 `packVersion`

每個 Shared Pack 有 `packVersion`。任何會改變 Shared Pack active current-state snapshot 的 mutation 都增加 `packVersion`，包括：

- `createSharedPack`
- `updateSharedPackMetadata`
- `createSharedItem`
- `updateSharedItem`
- `archiveSharedItem`
- `joinSharedPack`
- `completeSharedItem`

Invite state 不屬於 active Shared Pack snapshot。`getOrCreateInviteCode` 與 `rotateInviteCode` 不影響 `packVersion`，不使用 `expectedPackVersion`，也不回傳 `resultingPackVersion`。

Mutation input 使用 `expectedPackVersion` when the caller already has a Pack snapshot and the mutation changes active current-state snapshot. Mutation output 使用 `resultingPackVersion`。Snapshot output 使用 `packVersion`。

`remotePackVersion` in local cache 只代表「目前本機完整 cache 所對應的完整 Pack snapshot version」。Client 不可只投影單一 mutation fragment 後就把 `remotePackVersion` 更新至 `resultingPackVersion`。
At runtime, `remotePackVersion` must be monotonic as defined by `08`; a lower-version snapshot response cannot overwrite a higher-version cache.

### 5.3 `knownPackVersion`

`getSharedPackSnapshot` input 可以包含 `knownPackVersion`。用途只限：

- remote 回傳完整 snapshot。
- 或在完全未變更時回傳 `notModified`。

Client 比 remote 舊是正常 refresh 情況，不是 error。`staleVersion` 只屬於 mutation optimistic concurrency error。

## 6. Idempotency Contract

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

Remote 必須保存足以 replay 原 response 的 idempotency record，或採用可提供相同行為的 atomic design。對 snapshot-changing mutation，idempotency replay 必須 replay original authoritative mutation result + original full snapshot response，或 replay 一個能保證投影到同一 authoritative resulting state 的等價 response。Phase 1 technical design 必須定義。
Client retry intent semantics, including timeout handling and `clientRequestId` reuse for the same logical mutation, are defined by `08`。

所有 mutation expected errors 可包含 `idempotencyConflict`。不可用模糊 duplicate request error 取代 replay semantics。

## 7. Snapshot Contract

`SharedPackSnapshotV1` 是某個 Shared Pack 在某個 `packVersion` 下的完整 active current-state projection。Mutation full snapshot 與 `getSharedPackSnapshot` manual refresh 必須使用相同 schema。

Semantic shape：

```text
SharedPackSnapshotV1
- remoteSnapshotSchemaVersion = 1
- remotePackId
- packVersion
- generatedAt
- pack
- currentMembership
- memberships
- items
```

`pack`：

```text
- remotePackId
- title
- description
- iconEmoji
- createdAt
- updatedAt
```

`currentMembership`：

```text
- remoteMemberId
- remotePackId
- role
- displayName
- joinedAt
```

`memberships[]` summary：

```text
- remoteMemberId
- displayName
- role
- joinedAt
```

`items[]` contains only active state-based Shared Items：

```text
- remoteItemId
- remotePackId
- title
- description
- type = stateBased
- lifecycleStatus = active
- stateAnchorDate
- infoAfterMinutes
- warningAfterMinutes
- dangerAfterMinutes
- completedAt
- completedByMemberId
- itemVersion
- createdAt
- updatedAt
```

Snapshot 不是：

- incremental patch。
- action history。
- local backup。
- Personal Pack conversion payload。
- Supabase token 或 credential 容器。
- Personal / Shared 完整雲端統一模型。

Archived Shared Items 不在 active snapshot 中。UI 透過 `completedByMemberId` 對應 membership summary 顯示 actor attribution。

### 7.1 Snapshot Integrity

Snapshot 必須滿足：

- `remoteSnapshotSchemaVersion == 1`。
- all `item.remotePackId == snapshot.remotePackId`。
- all membership rows correspond to snapshot Pack。
- `currentMembership` 必須存在於 `memberships`。
- `completedByMemberId` 若非 null，必須能在 `memberships` 找到。
- every item uses `type = stateBased`。
- every item uses `lifecycleStatus = active`。
- `stateAnchorDate` 不可為 null。
- thresholds 符合 Section 8 invariant。
- timestamps 必須是 valid UTC instants。

任一 invariant 失敗：

- client 不可 partial project。
- projector rollback。
- `lastRefreshedAt` 不更新。
- 回報 snapshot validation failure。

## 8. Validation And Timestamp Semantics

Remote 是 authoritative layer，因此所有 Shared Item config 必須在 server-side 驗證。

Threshold invariant：

```text
0 <= infoAfterMinutes
infoAfterMinutes <= warningAfterMinutes
warningAfterMinutes <= dangerAfterMinutes
```

所有 threshold values 必須：

- 是整數。
- 不可為 null。
- 不可為負數。
- 不可超出 Phase 1 technical design 設定的合理 database range。

Phase 1 可決定實際最大值，但不可只依賴 Flutter validation。

`createSharedItem` 必須提供 `initialStateAnchorDate`。Remote 必須驗證 timestamp 格式、canonicalize 為 UTC instant、保存為 `stateAnchorDate`，且不接受無 anchor 的 active Shared Item。

`updateSharedItem` 只可修改 definition：`title`、`description`、`infoAfterMinutes`、`warningAfterMinutes`、`dangerAfterMinutes`。它不可接受 `stateAnchorDate`、`initialStateAnchorDate`、`completedAt`、`completedByMemberId` 或 `lifecycleStatus`。

`completeSharedItem` 是 v1 唯一可更新一般 Item state anchor 的操作：

```text
authoritative completedAt = server-generated UTC timestamp
stateAnchorDate = authoritative completedAt
completedByMemberId = caller membership remoteMemberId
```

Shared Pack v1 所有 authoritative timestamps 使用 UTC instant。適用：

- `createdAt`
- `updatedAt`
- `joinedAt`
- `generatedAt`
- `stateAnchorDate`
- `completedAt`
- `lastRefreshedAt`
- `clientOccurredAt`

Remote database 使用 timezone-aware UTC timestamp semantics，不保存不含 timezone 的 ambiguous local datetime。Server-generated timestamps 由 server/database clock 產生。

DTO timestamps 使用 ISO-8601 UTC，例如：

```text
2026-08-04T03:00:00Z
```

不可傳輸沒有 offset 的 timestamp，例如：

```text
2026-08-04T03:00:00
```

Drift Shared cache 保存 UTC `DateTime` instant。Decode DTO 時必須確認 timestamp 包含 UTC / offset，不可把 remote UTC timestamp 當作 device local time 直接保存。

UI 顯示時轉換為裝置 local timezone。`completedAt` 顯示可使用裝置 locale；跨裝置看到的 absolute instant 必須一致。

State elapsed calculation 使用：

```text
currentInstantUtc - stateAnchorDateUtc
```

不使用 calendar date-only subtraction。

`clientOccurredAt` 只可作 audit / diagnostic hint，不可決定 authoritative completion time，不可覆蓋 server-generated `completedAt`，可由 remote 忽略。

若 remote data 違反 invariant，snapshot build 必須失敗或標示 server integrity error。Client 不可自行猜測 anchor，也不可把 invalid Item 投影成正常 active Item。

## 9. Snapshot Projection Contract

`SharedPackCacheProjector` 必須在單一 Drift transaction 內投影完整 active snapshot：

1. validate `remoteSnapshotSchemaVersion`
2. validate `remotePackId`
3. validate snapshot identity consistency
4. validate membership, lifecycle, threshold and timestamp invariants
5. upsert `shared_pack_cache`
6. upsert `shared_membership_cache` rows
7. upsert all returned `shared_item_cache` rows
8. remove or deactivate membership cache rows absent from authoritative snapshot
9. remove or deactivate Shared Item cache rows absent from authoritative snapshot
10. update `remoteItemVersion` values
11. update `remotePackVersion`
12. update `lastRefreshedAt`
13. commit

若任何 validation、mapping 或 write 失敗：

- rollback 整個 transaction。
- 保留 refresh 前 cache。
- 不更新 `remotePackVersion`。
- 不更新 `lastRefreshedAt`。
- 不顯示 partial snapshot。

遠端 active snapshot 中不存在的 local Shared Item，不可永久保留為 active stale Item。Projector 必須刪除或標記 inactive；Phase 1 technical design 可選 hard-delete cache row 或保留 tombstone，但 UI 不可再顯示為 active。Membership cache rows 同樣適用。

若 refresh 回傳 `permissionDenied` 或 `packNotFound`，client 不可繼續把舊 cache 顯示成可操作 Shared Pack。Planned data-layer behavior：

```text
shared_pack_cache.accessState = inaccessible
```

UI 應從正常 Shared Pack list 隱藏，或顯示不可存取狀態並禁止 action。Phase 1 technical design 必須選定實際 UI handling，但 data layer 必須 fail closed。

`lastRefreshedAt` 在 v1 表示最近一次成功從 remote 取得或驗證 Shared Pack current state 的 UTC 時間。它包括：

- full snapshot projection 成功。
- mutation full snapshot projection 成功。
- manual refresh 回傳 `notModified`。

它不包括：

- request 開始時間。
- remote failure。
- validation failure。
- projection rollback。
- permission denied。
- pack not found。
- unsupported snapshot version。

Phase 1 technical design 可評估是否把欄位命名為 `lastVerifiedAt`；

## 10. Snapshot-returning Mutation Standard

所有會改變 Shared Pack active current-state snapshot 的 mutation，都必須回傳：

```text
authoritative mutation result
+ resultingPackVersion
+ fullSnapshot
```

`fullSnapshot.packVersion` 必須等於 `resultingPackVersion`。適用 requests：

- `createSharedPack`
- `updateSharedPackMetadata`
- `createSharedItem`
- `updateSharedItem`
- `archiveSharedItem`
- `joinSharedPack`
- `completeSharedItem`

Client mutation flow：

```text
User mutation
→ SharedPackApplicationService
→ SharedPackRemoteApi mutation request
→ remote permission / version / idempotency validation
→ remote atomic mutation
→ remote builds full active snapshot at resultingPackVersion
→ response returns mutation result + full snapshot
→ SharedPackCacheProjector validates full snapshot
→ single Drift transaction reconciliation
→ commit
→ update remotePackVersion / lastRefreshedAt
→ provider refresh
→ UI refresh
```

強制規則：

- client 不可只投影單一 mutation fragment 後，就把 `remotePackVersion` 更新至 `resultingPackVersion`。
- `remotePackVersion` 只代表目前本機完整 cache 所對應的完整 Pack snapshot version。
- mutation response 的 full snapshot 必須使用與 manual refresh 相同的 snapshot schema。
- mutation snapshot projection 必須使用與 `getSharedPackSnapshot` 相同的 `SharedPackCacheProjector`。
- projection 失敗時必須 rollback，本機不可宣稱已套用新的 `packVersion`。
- UI 不可在 remote 成功但 local full projection 失敗時，把 cache 當成最新狀態。
- v1 不建立 partial delta merge engine。

Mutation-specific authoritative result 可用於 UI feedback，但 cache truth 必須來自 full snapshot projection。

## 11. Planned Request Catalog

本章只定義 planned requests，不代表任何 RPC、table、file 或 Supabase function 已存在。

All mutation requests:

- include `clientRequestId`
- use the idempotency contract in Section 6
- validate permission server-side
- validate `expectedItemVersion` or `expectedPackVersion` when applicable
- return authoritative result
- project local cache only after remote success
- are called through `SharedPackApplicationService`

Snapshot-changing mutation requests additionally follow Section 10 and return `fullSnapshot`.

### 11.1 createSharedPack

Purpose: 建立新的 Shared Pack 與 owner membership。

Caller: Shared Pack owner flow through `SharedPackApplicationService`。

Auth requirement: `SharedIdentityService.ensureIdentity()` succeeds before request。

Input:

- `clientRequestId`
- `title`
- `description`
- `iconEmoji`
- `ownerDisplayName`

v1 不支援 initial Items in `createSharedPack`。為了維持 v1 RPC atomic scope 簡單，建立流程是：

```text
createSharedPack
→ createSharedItem
→ createSharedItem
```

Version guard:

- `expectedPackVersion` not applicable because the Pack does not exist yet.
- Created Pack starts with server-assigned `packVersion`.

Output:

- `remotePackId`
- owner membership with `remoteMemberId`, `remotePackId`, `displayName`, `role`, `joinedAt`
- authoritative pack metadata
- `resultingPackVersion`
- `fullSnapshot`

Initial full snapshot：

- 包含 Pack。
- 包含 owner membership。
- Items list 可為空。
- `fullSnapshot.packVersion == resultingPackVersion`。

Remote side effect:

- Validate `ownerDisplayName`.
- Create Shared Pack.
- Create exactly one owner membership with Pack-scoped `ownerDisplayName`.
- Increase `packVersion`.
- Build full active snapshot at `resultingPackVersion`.
- Create idempotency record for replay.

Local cache projection:

- Project returned full snapshot through `SharedPackCacheProjector`.
- Set `lastRefreshedAt` only after projection transaction commits.
- Do not write Personal `item_packs` or `items`.

Expected errors:

- `identityUnavailable`
- `validationFailed`
- `idempotencyConflict`
- `rateLimited`
- `remoteUnavailable`

Manual test:

- Device A obtains anonymous remote identity only when entering create flow, creates a Shared Pack with an owner display name, and sees it in the Shared Pack list after full snapshot projection.

### 11.2 updateSharedPackMetadata

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
- `fullSnapshot`

Remote side effect:

- Verify owner permission.
- Verify `expectedPackVersion`.
- Update metadata atomically.
- Increase `packVersion`.
- Build full active snapshot at `resultingPackVersion`.

Local cache projection:

- Project returned full snapshot through `SharedPackCacheProjector`.
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

- Owner updates title on Device A; Device A projects the returned full snapshot after success, and Device B sees the new metadata after manual snapshot refresh.

### 11.3 createSharedItem

Purpose: Owner 在既有 Shared Pack 中建立新的 state-based Shared Item。

Caller: owner item management flow through `SharedPackApplicationService`。

Input:

- `clientRequestId`
- `remotePackId`
- `expectedPackVersion`
- `title`
- `description`
- `initialStateAnchorDate`
- `infoAfterMinutes`
- `warningAfterMinutes`
- `dangerAfterMinutes`

Output:

- `authoritativeSharedItem`
- `resultingItemVersion`
- `resultingPackVersion`
- `fullSnapshot`

Remote side effect:

- Verify owner permission.
- Verify `expectedPackVersion`.
- Reject any fixed Item config.
- Validate thresholds.
- Validate `initialStateAnchorDate`.
- Canonicalize `initialStateAnchorDate` as UTC and store it as `stateAnchorDate`.
- Create active state-based Shared Item atomically.
- Increase `itemVersion`.
- Increase `packVersion`.
- Build full active snapshot at `resultingPackVersion`.

Local cache projection:

- Project returned full snapshot through `SharedPackCacheProjector`.
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

- Owner creates a state-based Shared Item with `initialStateAnchorDate`; member cannot create one; member sees the new active Item after refresh.

### 11.4 updateSharedItem

Purpose: Owner 修改 Shared Item definition。

Caller: owner item management flow through `SharedPackApplicationService`。

Input:

- `clientRequestId`
- `remotePackId`
- `remoteItemId`
- `expectedItemVersion`
- `title`
- `description`
- `infoAfterMinutes`
- `warningAfterMinutes`
- `dangerAfterMinutes`

Input must not include:

- `stateAnchorDate`
- `initialStateAnchorDate`
- `completedAt`
- `completedByMemberId`
- `lifecycleStatus`

Output:

- `authoritativeSharedItem`
- `resultingItemVersion`
- `resultingPackVersion`
- `fullSnapshot`

Remote side effect:

- Verify owner permission.
- Verify `expectedItemVersion`.
- Reject archived Item mutation.
- Reject any fixed Item config.
- Validate thresholds.
- Update only Shared Item definition atomically.
- Do not modify `stateAnchorDate`.
- Do not modify completion attribution.
- Increase `itemVersion`.
- Increase `packVersion`.
- Build full active snapshot at `resultingPackVersion`.

Local cache projection:

- Project returned full snapshot through `SharedPackCacheProjector`.

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

- Owner edits a threshold; member cannot edit; refresh returns the authoritative edited Item with the same `stateAnchorDate` and increased Item and Pack versions.

### 11.5 archiveSharedItem

Purpose: Owner 封存 Shared Item definition。

Caller: owner item management flow through `SharedPackApplicationService`。

Input:

- `clientRequestId`
- `remotePackId`
- `remoteItemId`
- `expectedItemVersion`

Output:

- archived `remoteItemId`
- `lifecycleStatus = archived`
- `resultingItemVersion`
- `resultingPackVersion`
- `fullSnapshot`

Remote side effect:

- Verify owner permission.
- Verify `expectedItemVersion`.
- Mark Item archived atomically.
- Increase `itemVersion`.
- Increase `packVersion`.
- Build full active snapshot at `resultingPackVersion`.
- Ensure `fullSnapshot.items` does not contain the archived Item.

Repeated archive of an already archived Item may return an idempotent result or `itemArchived`; Phase 1 technical design must keep the response semantics explainable.

Local cache projection:

- Project returned full snapshot through `SharedPackCacheProjector`.
- Archived Item must not appear in the active Shared Item list after projection.

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

- Owner archives an Item; member cannot archive; after full snapshot projection the archived Item is absent from the active Shared Item list.

### 11.6 getOrCreateInviteCode

Purpose: Owner 取得目前 active invite code；若沒有 active code，建立一個。

Caller: owner invite flow through `SharedPackApplicationService`。

Input:

- `clientRequestId`
- `remotePackId`

Output:

- `normalizedInviteCode`
- `displayInviteCode`

Remote side effect:

- Verify owner permission.
- If active code exists, return the same code.
- If no active code exists, create one atomically.
- Do not invalidate an existing active code.
- Ensure one active invite code per Pack.
- Do not log canonical invite code in general logs.
- Do not change `packVersion`.

Local cache projection:

- No active snapshot projection.
- Store only non-sensitive invite presentation state if needed.
- Do not store invite code as recovery credential.

Expected errors:

- `identityUnavailable`
- `permissionDenied`
- `packNotFound`
- `idempotencyConflict`
- `rateLimited`
- `remoteUnavailable`

Manual test:

- Owner opens invite flow twice and receives the same active display code while it remains active; Pack version does not change.

### 11.7 rotateInviteCode

Purpose: Owner 手動 rotate invite code。

Caller: owner invite flow through `SharedPackApplicationService`。

Input:

- `clientRequestId`
- `remotePackId`

Output:

- `normalizedInviteCode`
- `displayInviteCode`

Remote side effect:

- Verify owner permission.
- Create a new code atomically.
- Atomically invalidate the old active code.
- Ensure one active invite code per Pack.
- Do not log canonical invite code in general logs.
- Do not change `packVersion`.

Local cache projection:

- No active snapshot projection.
- Store only non-sensitive invite presentation state if needed.
- Do not store invite code as recovery credential.

Expected errors:

- `identityUnavailable`
- `permissionDenied`
- `packNotFound`
- `idempotencyConflict`
- `rateLimited`
- `remoteUnavailable`

Manual test:

- Owner rotates code; old code immediately fails preview / join; new code previews the Pack; Pack version does not change.

### 11.8 previewInviteCode

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

### 11.9 joinSharedPack

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

- membership
- `resultingPackVersion`
- `fullSnapshot`

Remote side effect:

- Normalize invite code again in the server-side atomic path.
- Atomically validate invite.
- Validate `memberDisplayName`.
- Create membership with Pack-scoped `memberDisplayName`.
- Prevent duplicate membership by `remotePackId + authUserId`.
- Increase `packVersion`.
- Build full active snapshot at `resultingPackVersion`.
- Apply rate limiting / brute-force protection.

Returned full snapshot 必須包含加入後的 membership summary。

Local cache projection:

- Project returned full snapshot through `SharedPackCacheProjector`.
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

### 11.10 getSharedPackSnapshot

Purpose: Manual refresh for Shared Pack active current state.

Caller: Shared Pack detail refresh action and app-level Shared Pack refresh flow through `SharedPackApplicationService`。

Input:

- `remotePackId`
- `knownPackVersion?`
- `supportedRemoteSnapshotSchemaVersion`

Output:

- `fullSnapshot`

Alternative output:

```text
notModified {
  remotePackId
  packVersion
  verifiedAt
}
```

`verifiedAt` is server response UTC timestamp.

Remote side effect:

- None, except audit / rate-limit counters.

Local cache projection:

- On full snapshot: use Snapshot Projection Contract in Section 9.
- On `notModified`: update `shared_pack_cache.lastRefreshedAt = verifiedAt`; do not rewrite `shared_membership_cache`; do not rewrite `shared_item_cache`; do not change `remotePackVersion`.
- On `permissionDenied` or `packNotFound`: set `shared_pack_cache.accessState = inaccessible` through fail-closed handling.

If full snapshot projection fails after remote mutation success, remote state must be treated as changed while local cache remains unadvanced; recovery and mutation blocking semantics follow `08`。

Expected errors:

- `identityUnavailable`
- `permissionDenied`
- `packNotFound`
- `unsupportedRemoteSnapshotSchemaVersion`
- `rateLimited`
- `remoteUnavailable`

Manual test:

- Device B taps refresh after Device A completes an item and sees the authoritative result, or gets `notModified` when its known Pack version is current and `lastRefreshedAt` updates to `verifiedAt`.

### 11.11 completeSharedItem

Purpose: Complete one Shared Item through remote authoritative write.

Caller: Shared Item list `done` action through `SharedPackApplicationService`。

Input:

- `clientRequestId`
- `remotePackId`
- `remoteItemId`
- `expectedItemVersion`
- optional `clientOccurredAt` for audit / diagnostic hint

Output:

- `authoritativeSharedItem`
- `completedByMemberId`
- `completedAt`
- `resultingItemVersion`
- `resultingPackVersion`
- `fullSnapshot`

Remote side effect:

- Verify caller has owner or member membership.
- Derive `completedByMemberId` from authenticated caller membership; do not trust client actor id.
- Verify `expectedItemVersion`.
- Reject archived Item.
- Generate authoritative `completedAt` on server as UTC instant.
- Set `stateAnchorDate = completedAt`.
- Record minimum completion metadata.
- Increase `itemVersion`.
- Increase `packVersion`.
- Build full active snapshot at `resultingPackVersion`.

Local cache projection:

- Project returned full snapshot through `SharedPackCacheProjector`.
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

- Device A completes Shared Item; local cache updates only after full snapshot projection; Device B sees the same `completedByMemberId`, display name mapping, `completedAt`, Item version, and Pack version after manual refresh.

## 12. Independent Shared Drift Cache

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
- `remotePackVersion` represents the complete local active snapshot version, not the last mutation result seen.
- `lastRefreshedAt` includes successful full snapshot projection, successful mutation full snapshot projection, and successful `notModified` verification.

Personal local data reset must not clear:

- `shared_pack_cache`
- `shared_membership_cache`
- `shared_item_cache`
- anonymous remote identity/session
- Shared Pack remote access metadata

Shared Pack reset / unlink / sign-out / clear Shared cache requires a future independent specification covering membership retention, identity/session retention, cache rebuild method, and account binding / recovery path.

## 13. Security Requirements

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

## 14. Backup And Reset Boundary

現有 JSON backup 是 legacy local export / import。

Shared Pack remote access 不由 local backup 恢復。Shared Pack cache、membership、invite code、remote identity mapping 與 credential 不應被當成傳統 backup recovery data。

Existing Settings data reset must be understood as Reset Personal local data:

- 清除 Personal local domain data。
- 重建 Personal system default Pack。
- 重建 Personal app settings / system records。
- 保留 Shared cache。
- 保留 anonymous identity/session。
- 保留 Shared Pack remote access metadata。

未綁定帳號時，local backup 可保護 Personal local data。已綁定帳號後的長期方向是 Personal / Shared active data 由帳號與 remote membership 恢復。

## 15. Manual Acceptance Scenario

Device A:

1. 準備建立 Shared Pack 時 lazy initialize anonymous remote identity.
2. 建立 Shared Pack and owner membership with `ownerDisplayName`.
3. 建立 state-based Shared Item with `initialStateAnchorDate`.
4. get-or-create invite code without changing `packVersion`.
5. complete Shared Item.
6. remote 成功後 A local Shared cache 透過 returned full snapshot 更新.

Device B:

1. 準備 preview invite code 時 lazy initialize anonymous remote identity.
2. 輸入 invite code.
3. 預覽 Pack title / icon only.
4. 確認加入並提供 `memberDisplayName`.
5. 手動 refresh.
6. 看見 A 完成後的 authoritative result and display name attribution.
7. 再次 refresh 若回傳 `notModified`，更新 `lastRefreshedAt`。

Acceptance notes:

- A mutation 時，資料先寫到 remote authoritative layer。
- A local Drift cache 只在 remote 成功並完成 full snapshot projection 後更新。
- B 手動 refresh 時，資料從 `getSharedPackSnapshot` 取得完整 active snapshot，或透過 `notModified` 驗證現有 snapshot。
- B local Drift cache 只在 snapshot validate + transaction projection 成功後更新。
- Widget、Home、notification、backup 與 Personal Pack data flow 不參與 v1 驗收。
