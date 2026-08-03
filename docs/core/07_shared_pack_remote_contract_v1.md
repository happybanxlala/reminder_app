# 07 Shared Pack Remote Contract v1

Status: planned / not implemented.

No Supabase dependency, table, RPC or production API exists yet unless verified in current repository. This document is a future implementation contract for Shared Pack Phase 1. It must not be read as evidence that remote auth, remote tables, RPCs, mapping tables, or Shared Pack UI already exist.

## 1. Purpose

本文件定義 Shared Pack v1 的 planned remote boundary。產品範圍以 `docs/core/06_shared_pack_direction_spec_v1.md` 為準；現有 core/local model 以 `docs/core/04_core_model_spec_v1.md` 為準。

v1 remote contract 只支援：

- 建立新的 Shared Pack。
- invite code owner / joiner flow。
- Shared Item current-state read。
- Shared Item `done` write。
- actor attribution。
- manual refresh。
- authoritative result projection into local Drift readable cache。

## 2. Architecture Boundary

Planned application boundary：

```text
UI
→ SharedPackApplicationService
→ SharedPackRemoteApi
→ remote RPC / API
→ authoritative response
→ SharedPackCacheProjector
→ Drift transaction
→ provider refresh
```

禁止：

- UI 直接呼叫 Supabase。
- controller 直接呼叫 Supabase。
- native Widget 直接呼叫 Shared API。
- remote DTO 直接成為 domain model。
- remote request 分散在不同 page、provider 或 controller。

`SharedPackApplicationService` 負責 local validation、呼叫 remote API、處理 authoritative response、交給 projector 更新 local cache。`SharedPackRemoteApi` 是 remote request catalog 的唯一技術入口。`SharedPackCacheProjector` 負責把 remote current-state DTO 投影成 local Drift readable cache。

## 3. Planned Request Catalog

本章只定義 planned requests，不代表任何 RPC、table、file 或 Supabase function 已存在。

### 3.1 createSharedPack

Purpose: 建立新的 Shared Pack 與 owner membership。

Caller: Shared Pack owner flow through `SharedPackApplicationService`。

Auth requirement: successful anonymous remote identity。

Input:

- `clientRequestId`
- pack title
- pack icon / metadata
- optional initial Shared Item definitions

Output:

- remote pack id
- owner membership summary
- created pack metadata
- remote version / resulting version
- initial snapshot fragment suitable for local projection

Remote side effect:

- 建立 Shared Pack。
- 建立 owner membership。
- 建立 initial Shared Items if provided。

Local cache update:

- Create / update local readable Shared Pack cache。
- Write centralized `shared_pack_mapping` and `shared_item_mapping` planned records。
- Set `lastRefreshedAt` and remote versions after remote success。

Expected errors:

- identityUnavailable
- validationFailed
- duplicateClientRequest
- rateLimited
- permissionDenied
- remoteUnavailable

Manual test:

- Device A obtains anonymous remote identity, creates a new Shared Pack, sees it in Shared Pack list after local cache projection.

### 3.2 generateInviteCode

Purpose: Owner creates or retrieves an invite code for one Shared Pack.

Caller: owner invite flow inside Shared Pack detail / members area。

Auth requirement: anonymous remote identity with owner membership for the target pack。

Input:

- `clientRequestId`
- `remotePackId`
- optional expiry setting if v1 explicitly enables it

Output:

- normalized invite code
- display invite code
- optional expiresAt
- remote version / resulting version

Remote side effect:

- Create or refresh an invite code scoped to one Shared Pack.

Local cache update:

- Store only non-sensitive invite presentation state if needed.
- Do not store invite code as recovery credential.

Expected errors:

- identityUnavailable
- permissionDenied
- packNotFound
- rateLimited
- remoteUnavailable

Manual test:

- Owner opens Shared Pack detail, generates code, shares display code such as `K7M 4Q9`.

### 3.3 previewInviteCode

Purpose: Joiner checks what Shared Pack an invite code points to before joining.

Caller: joiner invite entry flow。

Auth requirement: successful anonymous remote identity。

Input:

- normalized invite code

Output:

- preview pack name
- preview pack icon / metadata
- membership availability
- optional expiresAt

Remote side effect:

- None, except planned audit / rate-limit counters.

Local cache update:

- No persistent domain cache required before join.

Expected errors:

- identityUnavailable
- invalidInviteCode
- inviteExpired
- alreadyMember
- rateLimited
- remoteUnavailable

Manual test:

- Device B enters Device A's code and sees the correct Shared Pack preview without joining yet.

### 3.4 joinSharedPack

Purpose: Joiner becomes a member of the invited Shared Pack.

Caller: joiner confirmation flow。

Auth requirement: successful anonymous remote identity。

Input:

- `clientRequestId`
- normalized invite code

Output:

- remote pack id
- member membership summary
- remote version / resulting version
- initial Shared Pack snapshot

Remote side effect:

- Atomically validate invite code and create member membership.

Local cache update:

- Project returned Shared Pack snapshot into local Drift readable cache.
- Write centralized mapping records.
- Set `lastRefreshedAt`.

Expected errors:

- identityUnavailable
- invalidInviteCode
- inviteExpired
- alreadyMember
- membershipLimitReached
- rateLimited
- remoteUnavailable

Manual test:

- Device B previews invite code, confirms join, sees the Shared Pack in Shared Pack list.

### 3.5 getSharedPackSnapshot

Purpose: Manual refresh for Shared Pack current state.

Caller: Shared Pack detail refresh action and app-level Shared Pack refresh flow。

Auth requirement: anonymous remote identity with owner or member membership。

Input:

- `remotePackId`
- optional known `remoteVersion`
- supported `remoteSnapshotSchemaVersion`

Output:

- `remoteSnapshotSchemaVersion`
- pack metadata
- membership summary
- Shared Items
- minimum completion metadata
- authoritative remote version

Remote side effect:

- None, except planned audit / rate-limit counters.

Local cache update:

- Validate `remoteSnapshotSchemaVersion`.
- Map DTO to local readable cache.
- Update centralized mapping remote versions.
- Update `lastRefreshedAt`.

Expected errors:

- identityUnavailable
- permissionDenied
- packNotFound
- unsupportedRemoteSnapshotSchemaVersion
- staleClientVersion if expected by API shape
- rateLimited
- remoteUnavailable

Manual test:

- Device B taps refresh after Device A completes an item and sees the authoritative result.

### 3.6 completeSharedItem

Purpose: Complete one Shared Item through remote authoritative write.

Caller: Shared Item list `done` action。

Auth requirement: anonymous remote identity with owner or member membership。

Input:

- `clientRequestId`
- `remotePackId`
- `remoteItemId`
- `expectedVersion`
- completion timestamp

Output:

- authoritative Shared Item result
- actor attribution
- resulting item version
- resulting pack version
- optional snapshot fragment

Remote side effect:

- Atomically mark Shared Item done if caller is a member and `expectedVersion` is acceptable.
- Record minimum completion metadata, including who completed it.

Local cache update:

- Only after remote success, project authoritative result into local Drift readable cache.
- Update mapping remote version.
- Refresh providers.

Expected errors:

- identityUnavailable
- permissionDenied
- packNotFound
- itemNotFound
- itemArchived
- staleVersion
- duplicateClientRequest
- rateLimited
- remoteUnavailable

Manual test:

- Device A completes Shared Item, local cache updates only after remote success, Device B sees the same result after manual refresh.

## 4. Write Flow

```text
User action
→ local validation
→ completeSharedItem
→ remote atomic success
→ authoritative result
→ update local Drift cache
→ UI refresh
```

v1 不做：

- local-first optimistic write。
- outbox。
- background retry。
- automatic merge。
- full conflict resolution engine。

失敗時 UI 應呈現 calm failure state，local Drift cache 不應假裝完成成功。

## 5. Read Flow

```text
User taps refresh
→ getSharedPackSnapshot
→ validate remoteSnapshotSchemaVersion
→ map DTO
→ Drift transaction
→ update mapping / lastRefreshedAt
→ UI refresh
```

Snapshot refresh 是 manual current-state read，不是 realtime sync，也不是 background sync。

## 6. Correctness Requirements

即使 v1 不做完整 conflict resolution，仍必須保留最低 correctness requirements：

- `clientRequestId`
- idempotency
- `expectedVersion`
- authoritative `resultingVersion`
- `staleVersion` error

目的：

- 避免重複完成。
- 避免 stale overwrite。
- 讓使用者在 remote request 重送、網路重試或雙裝置操作時得到可解釋結果。

這些 requirement 不代表 v1 要建立完整 sync engine、offline outbox、automatic merge 或 complex action history。

## 7. Snapshot Semantics

Shared Pack snapshot 是 remote current-state read model。

它不是：

- 用來把 Personal Pack 轉為 Shared Pack 的格式。
- local backup。
- full action history。
- Supabase token 或 credential 容器。
- Personal / Shared 完整雲端統一模型。

v1 snapshot 只包含：

- Pack metadata。
- membership summary。
- Items。
- 最低限度 completion metadata。

Snapshot 必須包含 `remoteSnapshotSchemaVersion`，client 必須驗證版本後才可投影到 local Drift cache。

## 8. Planned Security Requirements

本章只定義規格，不實作。

Requirements:

- RLS required。
- membership-scoped read / write。
- invite lookup / join 應由 atomic server-side RPC 處理。
- invite code normalization。
- rate limiting / brute-force protection。
- invite code 不可出現在一般 log。
- service role key 不可進入 client。
- Supabase access token、refresh token 或其他 credential 不可進入 backup。
- membership recovery 需等待 account binding / identity upgrade 規格，不屬於 v1。

## 9. Backup Boundary

現有 JSON backup 是 legacy local export / import。

Shared Pack remote access 不由 local backup 恢復。Shared Pack cache、membership、invite code、remote mapping 與 credential 不應被當成傳統 backup recovery data。

未綁定帳號時，local backup 可保護 Personal local data。已綁定帳號後的長期方向是 Personal / Shared active data 由帳號與 remote membership 恢復。

Phase 0 不修改現有 backup production code。

## 10. Manual Acceptance Scenario

Device A:

1. 建立 Shared Pack。
2. 建立或取得 invite code。
3. 完成 Shared Item。
4. remote 成功後 A local cache 更新。

Device B:

1. 輸入 invite code。
2. 預覽並加入 Pack。
3. 手動 refresh。
4. 看見 A 完成後的 authoritative result。

Acceptance notes:

- A 完成 Item 時，資料先寫到 remote authoritative layer。
- A local Drift cache 只在 remote 成功後更新。
- B 手動 refresh 時，資料從 `getSharedPackSnapshot` 取得。
- B local Drift cache 只在 snapshot validate + projection 成功後更新。
- Widget、Home、notification、backup 與 Personal Pack data flow 不參與 v1 驗收。
