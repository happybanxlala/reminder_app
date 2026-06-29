---
This document defines the Phase 5A remote-backed shared pack sync model.
Phase 5A is specification only and does not implement schema, sync engine, UI, widget, notification, or account binding.
---

# Remote-backed Shared Pack Sync Spec

## 1. Purpose

Phase 5A 定義 remote-backed shared pack 如何正式進入 local app model。

本 spec 覆蓋：

- local mirror
- sync outbox / pending action
- completion / activity history
- conflict / no-op handling
- main screen / widget / notification boundary
- realtime 在 Phase 5 的角色
- backup legacy / account binding recovery 策略

Phase 5A only defines the model. It does not implement schema, sync engine, UI, widget, notification, background sync, local import, full two-way sync, or account binding.

## 2. Terminology

| Term | 定義 |
| --- | --- |
| `local-only pack` | 只存在本機 Drift DB 的 Pack。它可以是 personal 或本機 shared simulation，但沒有 remote source of truth。 |
| `remote-backed shared pack` | 產品語意上是 Shared Pack，並且有 Supabase remote pack 作為多人共享事實來源。本機保存 local record / mirror 以支援 app UX、離線操作與查詢。 |
| `local mirror` | 本機對 remote pack / item / completion / activity 的映射資料。Mirror 用於 UI、widget、notification、離線與查詢，但不是獨立 fork。 |
| `remote source of truth` | Supabase remote DB 中的 pack、member、item、completion、activity 事實。多人一致性以 remote 為準。 |
| `sync mapping` | local id 與 remote id 的對應關係，例如 local pack id 對 remote pack uuid。可由 `sync_mappings` 或未來 sync metadata 表達。 |
| `sync outbox` | 本機保存尚未成功送到 remote 的 mutation queue。也可命名為 `pending_mutations`。 |
| `pending action` | 使用者在本機對 remote-backed pack 做了需要同步到 remote 的操作，但尚未成功提交到 Supabase。 |
| `confirmed remote activity` | 已由 Supabase 接受並成為 remote activity / completion history 的事實。 |
| `pending local activity` | 本機先記錄、尚未被 remote 確認的 activity。用於 UI 即時回應與離線狀態。 |
| `snapshot cache` | 最近一次 remote snapshot 的本機快取或投影。它可用來判斷 stale / refresh，但不取代正式 mirror。 |
| `sync status` | local entity 或 pending action 的同步狀態，例如 `pending_push`、`synced`、`failed`、`conflict`。 |
| `conflict` | 本機 pending action 與 remote truth 無法直接套用，例如 item 已被 archived 或使用者 membership 已被 removed。 |
| `no-op` | 操作送到 remote 後不需要改變 remote truth，例如 item 已由別人完成或已經沒有 active completion 可 undo。 |
| `retry` | failed / transient error action 之後再次嘗試提交 remote。 |
| `account binding` | 將 anonymous remote identity 綁定 Apple / Google / Email 等可恢復身份，用於換機或重裝後恢復 remote-backed data access。 |
| `legacy backup` | 既有 manual JSON backup。長期將退居 legacy path；它不保存 credential，也不授予 remote access。 |

## 3. Product Decisions

使用者已確認：

1. 加入 remote pack 後，本機要建立 local record，因為 local record 是使用者個人的活動紀錄基礎。
2. Remote pack 在 app 內是 Shared Pack；使用者不需要分辨 local shared pack 與 remote shared pack。
3. Remote item 等於 local item 的產品語意；remote item 需要 mirror / import 成本機 item。
4. Remote completion / activity 要寫入 local completion history / activity。
5. Remote-backed pack 會出現在主畫面與 today / upcoming / warning / danger 相關查詢。
6. Remote-backed pack 會出現在 widget；Phase 5A 只定義規則。
7. Remote-backed item 能觸發 local notification；Phase 5A 只定義規則。
8. 離線時可操作 remote-backed pack，恢復連線後同步到 remote。
9. Local pending action / sync outbox 需要保存。
10. Manual backup 將逐步成為 legacy / deprecated path，長期改以 account binding 恢復 remote-backed data。

## 4. Core Principle

> Remote-backed shared pack uses local-first UX with remote source of truth.

規則：

- 使用者操作時，app 優先回應本機狀態。
- Local DB 需要保存 mirror / pending activity，支援離線、Home 查詢、widget snapshot、notification scheduling。
- Supabase remote DB 是 shared truth，負責多人一致性。
- Local mirror 不能任意覆寫 remote truth。
- Sync engine 需要把本機 pending actions 送到 remote，並把 remote confirmed events 拉回本機。
- Local mirror is not an independent fork.

## 5. Local Record Strategy

加入或建立 remote-backed shared pack 後，本機應建立 local records。

規則：

- 本機仍建立 `ItemPack` record。
- 產品語意上 `ItemPack.packType` 仍是 `shared`。
- 工程上可用 sync metadata 或 `sync_mappings` 區分 `local-only shared pack` 與 `remote-backed shared pack`。
- Local id 是 app 內部穩定 id；remote id 不取代 local id。
- 必須保留：`local id != remote id`。
- Remote pack id mapping 到 local pack id 應透過 `sync_mappings` 或未來 pack sync metadata 表達。
- `pack_members` 應能表示 remote members 的 local mirror。已知 remote user 可對應 `local_users.remoteUserId`；未知或已移除 user 可建立 placeholder / removed local user，以保留歷史。
- Removed member 不應刪除歷史 actor。可用 `PackMember.status = removed` 或 local user `identityKind = removed` 表示。
- Current device user 的 remote role / membership status 應保存為 sync metadata，供 UI、widget、notification 與 action eligibility 判斷。

## 6. Remote-backed Pack Identity

Remote-backed pack identity 至少需要以下概念：

```text
local_pack_id
remote_pack_id
sync_state
current_user_remote_role
current_user_remote_status
last_remote_snapshot_at
last_successful_sync_at
last_sync_error
```

Phase 5B 可透過新 table、擴充 `sync_mappings` metadata、或 pack-specific sync metadata 實作。Phase 5A 不寫死 Drift schema。

語意：

- `local_pack_id`：本機 `ItemPack.id`，供 app domain / UI / widget / notification 使用。
- `remote_pack_id`：Supabase `packs.id`，供 remote fetch / mutation 使用。
- `sync_state`：pack mirror 的同步狀態。
- `current_user_remote_role`：目前 remote user 在該 pack 的角色，例如 host / member / viewer。
- `current_user_remote_status`：目前 remote membership 狀態，例如 active / removed。
- `last_remote_snapshot_at`：最近取得 remote snapshot 的時間。
- `last_successful_sync_at`：最近一次成功 push 或 pull 的時間。
- `last_sync_error`：最近一次 sync failure 的摘要，不保存 secret。

## 7. Remote-backed Item Mirror

Remote item 需要 mirror / import 成 local item。

規則：

- Remote item import 後建立 local `Item`。
- Local item id 不等於 remote item id。
- Mapping 透過 `sync_mappings` 或 item sync metadata 表達。
- Remote item title / note / status / schedule 應 mirror 到 local item 可查詢欄位。
- `assigned_to` 仍只是提示，不限制誰能 complete / undo。
- Remote item archived / deleted 後，本機 mirror 應從 active views 移除，建議 soft archive，而不是 hard delete local history。
- Remote item 被移除時，local item 應保留 mapping 與 history，以便 activity / completion history 可被理解。

Product meaning:

```text
remote item = local item
```

Implementation rule:

```text
local_id and remote_id remain separate.
```

## 8. Completion / Activity History Model

Remote completion 必須寫入 local completion history / activity。

需要區分：

- `pending local completion`：本機先完成，尚未被 remote 確認。
- `confirmed remote completion`：本機 action 已由 remote 接受。
- `remote imported completion`：其他 member 或其他裝置完成後，本機從 remote pull 回來。
- `undone completion`：completion history 保留，並記錄 undo actor / time。
- `conflict/no-op completion attempt`：本機 attempt 未成為 remote truth。

規則：

- `completed_by` 代表事實紀錄。
- `undone_by` 代表復原事實。
- Undo 不刪除 completion history。
- Remote confirmed completion 應 mirror 到 local history。
- 離線本機完成先建立 pending local activity。
- Remote confirmed 後，pending local activity 轉為 confirmed remote activity。
- 如果 remote 已由別人完成，本機 pending completion 應變成 no-op / conflict，而不是覆寫 `completed_by`。
- Completion history must preserve who actually completed remotely.

Phase 5B 需要決定 pending local activity 是否與 confirmed activity 使用同一 table 加 sync metadata，或使用 outbox / activity projection 分離。

## 9. Sync Outbox / Pending Actions

Pending action 是：

```text
使用者在本機對 remote-backed pack 做了需要同步到 remote 的操作，
但該操作尚未成功提交到 Supabase，
因此需要保存在本機 outbox。
```

建議模型：

```text
sync_outbox / pending_mutations
- id
- local_pack_id
- remote_pack_id
- local_entity_type
- local_entity_id
- remote_entity_id nullable
- action_type
- payload_json
- client_mutation_id
- actor_local_user_id
- actor_remote_user_id nullable
- base_remote_version nullable
- created_at
- updated_at
- status: pending / syncing / synced / failed / conflict / cancelled
- retry_count
- last_error
```

Phase 5 初期 action types：

```text
complete_item
undo_item
```

Remote-backed CRUD Boundary Phase 1 action types：

```text
create_item
update_item
archive_item
```

Future action types：

```text
resource_increment
resource_adjust
stage_acknowledge
```

規則：

- Outbox row 必須可以 retry。
- `client_mutation_id` 用於 idempotency / duplicate handling。
- `actor_local_user_id` 保留本機 history actor。
- `actor_remote_user_id` 在有 remote identity 時保存；沒有時 action 不應送出 remote。
- `payload_json` 不保存 secret、token、session、plaintext invite code。
- `last_error` 是 debug / UI 摘要，不保存 credential 或 full remote payload。
- Phase 5A 不實作 outbox table。

## 10. Sync Status Model

建議 sync status：

| Status | 語意 |
| --- | --- |
| `local_only` | 只存在本機，不連 remote。 |
| `remote_backed` | 有 remote source of truth 與 local mirror。 |
| `pending_push` | 本機有待送出的 action。 |
| `syncing` | 正在送出或拉取。 |
| `synced` | 本機 mirror 與最近 remote truth 已對齊。 |
| `failed` | 同步失敗，可重試或需要使用者操作。 |
| `conflict` | 本機 pending action 與 remote truth 衝突，不能自動套用。 |
| `stale` | 本機資料可能落後 remote，需 refresh / pull。 |
| `removed` | Current user 已失去 remote membership 或 pack access。 |

Future UI display：

- `pending_push`：等待同步
- `syncing`：同步中
- `synced`：已同步
- `failed`：同步失敗
- `conflict`：需要處理
- `stale`：有遠端更新
- `removed`：已無存取權

Phase 5A 不實作 UI。

## 11. Conflict / No-op Rules

### Case A：兩人同時完成同一 item

- Remote first-write-wins。
- 先到 Supabase 的 completion 成為 `completed_by`。
- 後到的 complete action 回 `already_completed`。
- 本機 pending action 應標記 no-op / conflict。
- 本機狀態以 remote confirmed completion 為準。

### Case B：本機離線 complete，但上線時 remote 已完成

- Pending complete 不覆寫 remote `completed_by`。
- Sync 後拉 remote snapshot。
- Pending action 標記 no-op / resolved_by_remote。
- Local history 顯示 remote confirmed completion。
- 可保留本機 attempt activity 作為 pending / cancelled 記錄；是否展示需後續產品決策。

### Case C：本機離線 undo，但 remote 已被 undo

- Undo action 回 `already_not_completed`。
- Pending action 標記 no-op / resolved_by_remote。
- Local mirror 以 remote 未完成狀態為準。

### Case D：本機離線操作時 member 被 removed

- Remote RPC 應被拒絕。
- Pending action 標記 failed / permission_revoked。
- Local pack 應進入 removed / read-only / access lost 狀態。
- Widget actions 與 notification actions 應停止。

### Case E：remote item 被 archived/deleted while local has pending action

- Pending action 應標記 conflict / failed。
- Local mirror 應依 remote truth archive / remove from active views。
- Pending action 不應重新建立 remote item 或覆寫 remote archived / deleted state。

## 12. Main Screen Integration Boundary

Remote-backed pack 會出現在主畫面。

規則：

- Remote-backed item mirror 後可參與 today / upcoming / warning / danger 查詢。
- Pending local state 可先反映在主畫面，但需有 sync status。
- Stale remote data 需要可被標記，避免使用者誤以為資料已最新。
- Access lost / removed member 時，items 應從 active query 移除或標記不可操作。
- Home 查詢仍應讀 local model，不直接查 Supabase。
- Phase 5A 不實作 main screen integration。

## 13. Widget Integration Boundary

Remote-backed pack 會出現在 widget。

規則：

- Widget 不直接連 Supabase。
- Widget 只讀 Flutter 產生的本機 snapshot / widget cache。
- Remote-backed items 需要先 mirror 到 local DB，再進入 widget snapshot。
- Widget action 對 remote-backed item 應寫入 local pending action / sync outbox。
- Widget action 不應直接呼叫 Supabase。
- 如果 remote access lost，widget item 應移除或 disabled。
- Phase 5A 不實作 widget integration。

## 14. Notification Integration Boundary

Remote-backed item 能觸發 local notification。

規則：

- Notification scheduling 基於 local mirror。
- Remote item due / schedule changed 後，本機需重新排程。
- Remote item completed / archived / access lost 後，本機需取消或更新 notification。
- 離線狀態下 notification 可基於最後 local mirror 觸發。
- Notification action 對 remote-backed item 應寫入 sync outbox，不直接打 Supabase。
- Phase 5A 不實作 notification integration。

## 15. Realtime Role in Sync

> Realtime is a hint, not source of truth.

規則：

- 收到 realtime signal 可標記 remote pack stale。
- 收到 signal 不直接修改 local item / completion。
- 收到 signal 可觸發 user-visible refresh indicator。
- Snapshot fetch / sync pull 仍是資料更新來源。
- 未來是否允許 background pull 需另行設計。
- Phase 5 初期仍以 explicit sync / manual refresh 為主。

## 16. Account Binding & Backup Deprecation Strategy

Manual backup is expected to become legacy for remote-backed shared packs.

過渡策略：

- Short term：manual backup 保留為 legacy，不新增 remote-backed sync 能力。
- Medium term：Email OTP binding protects the current anonymous session; Apple / Google binding remains later work.
- Long term：remote-backed data 以 account binding recovery 為主。
- Until production-grade cross-device account recovery is complete, backup must not be removed.
- Backup must not include Supabase tokens, sessions, credentials, service role keys, secret keys, or plaintext invite codes.
- Backup 可保存 `remote_pack_id` / `sync_mappings` 等 remote references，但它們是 reference-only。
- Restore 後不自動取得 remote access。
- Restore 後需要重新登入 / 綁定帳號 / 驗證 membership。
- Remote references in backup do not grant access.

## 17. Security / Privacy Rules

- Service role key 永不進 app、文件範例或 backup。
- Flutter app 只使用 anon key。
- RLS 仍然是 remote data boundary；table grants 與 RLS policy 是兩層權限，`authenticated` role 必須先具備必要 table grants，RLS 才能套用 row-level 限制。
- `anon` role 不取得 shared pack private data table grants；invite、profile、pack、item、completion、resource、stage、activity access 都必須透過 authenticated session 與 RLS / RPC 邊界。
- Manual Supabase apply must include `docs/core/sql/phase_remote_grants_rls_repair.sql` and its grants audit query before validating remote-backed shared pack / invite flows.
- Local mirror 可能包含 shared pack private data，因此要視為敏感本機資料。
- Removed member 後，本機 cache / mirror 需進入 access lost / removed handling；是否保留 read-only history 是 open question。
- Backup 不保存 tokens、sessions、credentials、service role keys、secret keys。
- Invite code 不明文持久化。
- Activity history 不應保存 secrets。
- Realtime payload 只作 advisory，不應當作完整資料顯示或保存。

## 18. Phase 5 Implementation Roadmap

### Phase 5B：Local Schema for Remote-backed Packs

- Pack sync metadata
- Item sync metadata
- Completion sync metadata
- `sync_outbox` / `pending_mutations`
- Migration
- Backup legacy rules

Phase 5B implementation note:

- Adds local schema foundation only: `remote_pack_sync_metadata`, `remote_item_sync_metadata`, `remote_completion_sync_metadata`, and `sync_outbox`.
- Keeps existing `sync_mappings` unchanged as the generic local / remote id mapping used by Phase 3C-4E POC paths.
- Uses typed metadata tables for remote-backed sync state, current user remote role/status, archive/access-lost flags, timestamps, and local error summaries.
- Uses `sync_outbox` for pending local mutations such as `complete_item` and `undo_item`; Phase 5B does not send these rows to Supabase.
- Bumps Drift schema and migrates by creating empty metadata/outbox tables only. Existing local packs, items, completions, activity, and `sync_mappings` are not converted or modified.
- Manual backup remains legacy. Phase 5B does not export sync outbox rows or typed remote sync metadata; existing `sync_mappings` remain reference-only and do not grant remote access after restore.
- Restore/reset must not replay pending mutations, auto pull, auto push, resume realtime, or create remote access.

### Phase 5C：Read-only Remote Import / Local Mirror

- Remote snapshot import into local DB
- Remote-backed pack appears in app
- No offline mutation yet
- No widget / notification yet

Phase 5C is the next boundary for intentionally creating local mirror records from remote snapshots. Phase 5B schema must not infer product remote-backed state from old POC `sync_mappings`.

Phase 5C implementation note:

- Adds `RemoteSnapshotImportService.importRemotePackSnapshot(snapshot, source)` for manual import of an already-fetched `RemotePackSnapshot`.
- Does not call Supabase, refresh snapshots, process `sync_outbox`, auto pull, auto push, touch widget cache, schedule notifications, or change Supabase SQL.
- Reuses Drift schema version 9; no migration or generated schema bump is required.
- Finds an existing local mirror through `sync_mappings(pack -> packs)` or `remote_pack_sync_metadata.remote_pack_id`; otherwise creates a local `ItemPack` with `packType = shared`.
- Creates/reuses `local_users` for remote members. The current local user is reused when its `remote_user_id` matches; unknown remote users become placeholder local users with display-name snapshots when available.
- Upserts `pack_members` with mirrored role/status. Remote roles unsupported by the local enum are represented as local `member` until a richer local role model exists.
- Imports remote items as local `items`; local integer IDs never equal remote UUIDs. Mapping remains in `sync_mappings` and `remote_item_sync_metadata`.
- Uses `stateBased` schedule defaults with no due schedule when the Phase 3C/4 snapshot does not include enough schedule fields. This avoids inventing local notification or widget timing.
- Imports remote completions as local `ItemActionRecord(done)` plus `ItemCompletion`, preserving the actual remote `completed_by` in `remote_completion_sync_metadata`. Imported completions do not create pending completions, current-user completions, or outbox rows.
- Imports activity only when the remote entity can be mapped to a local integer entity id (`pack`, `item`, or `item_completion`). Unmappable activity is skipped with warnings.
- Adds repository-level read-only guards: `ItemRepository.markDone` and `undoDone` return `false` for packs whose metadata has `syncKind = remote_backed`.
- Manual backup remains legacy. Imported remote-backed mirror packs and their dependent item, completion, activity, member, placeholder-user, and mirror `sync_mappings` records are excluded from backup export. Typed metadata and `sync_outbox` remain excluded.
- Restore/reset continues to avoid replaying pending mutations, pulling, pushing, or granting remote access.

Phase 5C UI note:

- The existing developer-only Supabase Remote POC section may import the currently stored `lastPulledRemoteSnapshot` through a compact manual action.
- The import action must not refresh the snapshot or call a remote data source.

Phase 5C boundary:

- Imported active items may naturally appear in local queries, but user mutation is blocked until Phase 5D.
- Widget and notification integrations remain future work. If imported items appear in existing read paths, widget actions and notification actions still must not complete/undo remote-backed items locally until outbox behavior exists.

### Phase 5D：Complete / Undo Outbox

- Local complete / undo remote-backed item
- Write pending action
- Sync to Supabase RPC
- Resolve `completed` / `alreadyCompleted` / `undone` / `alreadyNotCompleted`

Phase 5D implementation note:

- Reuses Drift schema version 9; no migration is required.
- Replaces the Phase 5C fail-closed app route with `RemoteBackedItemActionService` for app-wired `ItemRepository.markDone` / `undoDone`.
- Local-only packs keep the existing local-only completion / undo behavior.
- Remote-backed complete creates an optimistic local `ItemActionRecord(done)`, `ItemCompletion`, `remote_completion_sync_metadata(completionState = pendingLocal, syncState = pendingPush)`, and `sync_outbox(actionType = complete_item)`.
- Remote-backed undo preserves the original completion history, marks the local completion undone optimistically, sets completion metadata back to `pendingLocal`, and creates `sync_outbox(actionType = undo_item)`.
- `sync_outbox.payloadJson` stores `remotePackId`, `remoteItemId`, `localPackId`, `localItemId`, `localCompletionId`, `clientMutationId`, action timestamp, and actor ids.
- Local complete / undo does not call Supabase, refresh/import snapshots, update widget cache, schedule notifications, or enqueue resource/stage sync.
- `RemoteBackedOutboxFlushService` is manual only. It processes pending `complete_item` / `undo_item`, marks rows `syncing`, calls existing Supabase RPC wrappers, then marks rows `synced`, `no_op`, or `failed`.
- `completed` maps to outbox `synced` and completion metadata `confirmedRemote`.
- `alreadyCompleted` maps to outbox `no_op`, completion metadata `noOp`, and stale pack/item metadata. It must not overwrite remote `completed_by`.
- `undone` maps to outbox `synced` and completion metadata `undoneRemote`, preserving original `completed_by`.
- `alreadyNotCompleted` maps to outbox `no_op`, completion metadata `noOp`, and stale pack/item metadata.
- RLS / removed-member style failures mark the outbox `failed` and mark pack metadata `accessLost` when appropriate.
- Network/config/auth failures mark the outbox `failed`; Phase 5D does not auto retry.
- Developer-only Settings POC may show outbox counts and expose a manual flush button. This is not production sync UI.
- Backup remains legacy and non-replayable: `sync_outbox`, typed remote metadata, retry state, and imported remote-backed mirror rows remain excluded from manual backup.
- Restore/reset must not replay, flush, pull, push, resume realtime, or grant remote access.
- Widget and notification behavior are unchanged in Phase 5D.

### Phase 5E：Main Screen Integration

- Remote-backed items in today / upcoming / warning / danger
- Pending / stale / sync status display rules

Phase 5E implementation note:

- Reuses Drift schema version 9; no migration or generated Drift changes are required.
- Home continues to derive section membership from local mirror records and existing `ItemStatusService` classification. Phase 5E does not invent schedule / due data when the remote snapshot did not provide enough local schedule fields.
- Imported remote-backed active items can appear in Home warning / danger sections when their local mirror data classifies into those sections.
- `ItemHomeEntry` / item card read models carry a local sync overlay derived from `remote_pack_sync_metadata`, `remote_item_sync_metadata`, and `sync_outbox`.
- Home card labels are intentionally compact: `等待同步`, `同步失敗`, `有新的更新，請刷新`, and `已無法存取`.
- App-wired Home complete / today-completed undo keep using `ItemRepository.markDone` / `undoDone`; remote-backed rows route to the Phase 5D local outbox path and do not call Supabase immediately.
- Local-only actions that do not yet have remote-backed semantics, such as skip/edit/delete/archive entry points on Home cards, remain hidden or disabled for remote-backed rows.
- Widget integration is handled by Phase 5F. Phase 5E itself does not make widget snapshots remote-backed aware.
- Notification integration is handled by Phase 5G. Phase 5E itself does not make notification summaries remote-backed aware.
- Backup remains legacy and unchanged: remote-backed mirror rows, typed sync metadata, and `sync_outbox` are not exported or replayed.

### Phase 5F：Remote-backed Home Widget Integration

- Widget reads remote-backed local mirror rows only through the Flutter-generated widget snapshot/cache.
- Widget danger / warning / today-completed tabs may include remote-backed item rows when existing local HomeRepository classification already includes them.
- Widget row snapshots carry compact sync state: `等待同步`, `同步失敗`, `有新的更新，請刷新`, and `已無法存取`.
- Widget complete / undo actions delegate back to `ItemRepository.markDone` / `undoDone`, which routes remote-backed rows to the Phase 5D local outbox path and writes `sync_outbox`.
- Widget never calls Supabase, flushes outbox, imports remote snapshots, processes realtime payloads, stores credentials, or schedules notifications.
- Access-lost or missing-mapping remote-backed widget actions fail closed. Access-lost rows may remain visible as disabled/read-only rows.
- Backup remains legacy and unchanged: widget cache is not a remote source of truth, and `sync_outbox`, typed sync metadata, credentials, sessions, tokens, plaintext invite codes, and remote-backed mirror rows are not exported for replay.
- Notification summary integration is handled by Phase 5G and remains outside widget/native code.

### Phase 5G：Remote-backed Notification Integration

- Current notification infrastructure is daily attention summary only. Phase 5G does not add item-level due reminders or notification complete / undo action buttons.
- Notification summaries read local HomeRepository warning / danger entries and local sync metadata only. They never call Supabase, flush `sync_outbox`, import remote snapshots, or process realtime payloads.
- Remote-backed local mirror items may contribute to notification summary totals when existing local Home classification already includes them.
- Remote-backed mirrors without local warning / danger classification, including unscheduled imports with insufficient schedule data, are not forced into notifications.
- Access-lost remote-backed items are excluded from actionable notification totals but preserve `已無法存取` summary metadata.
- Pending `complete_item` rows are not re-counted as active attention, avoiding repeated reminders after a local pending complete. The summary preserves `等待同步`.
- Failed and stale rows may remain in notification totals when local Home classification still includes them. The summary preserves `同步失敗` and `有新的更新，請刷新`.
- Notification payload remains local app navigation metadata only. It must not store Supabase tokens, sessions, credentials, service role keys, plaintext invite codes, full remote snapshots, or raw remote errors.
- Widget behavior from Phase 5F is unchanged. Notification summary changes must not alter widget snapshot eligibility or widget action routing.
- Backup remains legacy and unchanged: notification summary state is derived, not a remote source of truth, and backup still excludes `sync_outbox`, typed sync metadata, credentials, sessions, tokens, plaintext invite codes, and remote-backed mirror rows.
- Notification action routing through `ItemRepository.markDone` / `undoDone` remains a future phase because no platform-safe notification action bridge exists yet.

### Phase 5H：Manual Remote Refresh / Pull Import

- Productionizes a manual refresh path for remote-backed shared packs.
- Reuses `RemoteSharedPackRepository.pullRemotePackSnapshot(remotePackId)` for remote snapshot pull and `RemoteSnapshotImportService.importRemotePackSnapshot(snapshot, source)` for local mirror import.
- Adds a typed refresh result that reports status, imported / updated item, completion, and activity counts, pending / failed local mutation counts, stale-before / stale-after flags, and friendly warnings.
- Product entry lives inside the existing `一起照顧` bottom sheet for remote-backed packs as `刷新共享狀態`. Local-only packs do not show this action.
- Developer Settings keeps separate pull/import POC actions and adds a combined refresh/import POC action.
- Manual refresh may pull remote truth while pending outbox rows exist, but it never flushes outbox, retries failed mutations, pushes local mutations, or deletes pending / failed / conflict / no-op rows.
- Successful import clears stale state where safe. Partial import or unresolved local outbox keeps the pack stale and may mark affected local item metadata stale. Access-lost / removed state is preserved unless remote access is confirmed restored.
- Widget cache refresh, notification summary refresh, and badge refresh are best-effort derived updates from local DB only. Widget and notification layers still never call Supabase, flush outbox, import snapshots, process realtime payloads, or parse remote snapshot data.
- Realtime remains hint-only: realtime signals may indicate remote changes, but they do not auto pull, auto import, or auto flush. A successful manual refresh can clear the developer POC volatile remote-change hint.
- Backup remains legacy and non-replayable: `sync_outbox`, typed remote metadata, credentials, sessions, tokens, plaintext invite codes, and remote-backed mirror rows remain excluded, and restore does not auto refresh, pull, import, flush, or grant remote access.

### Phase 5I：Retry / Failure Recovery UX & Sync Hardening

- Adds a local recovery taxonomy over existing `sync_outbox` status, `last_error`, pack access state, and typed remote sync metadata. No Drift schema bump, backup schema bump, Supabase SQL/RPC/table change, widget native change, or notification scheduling change is required.
- Recovery state distinguishes pending/syncing, retryable failed, non-retryable failed, no-op, conflict, cancelled, stale pack, and access-lost pack cases.
- Retryability is derived conservatively. Failed rows with sanitized config/auth/network errors such as `supabaseConfigMissing`, `remoteAuthRequired`, `remoteNetworkFailed`, or `networkFailed` are retryable only while pack access is not lost.
- Access-lost/RLS/member-removed failures, missing mappings, malformed payloads, unknown failed errors, `no_op`, `conflict`, and `cancelled` are non-retryable from the manual retry path.
- Adds manual retry APIs for one failed mutation, all failed mutations in a local pack, and all retryable failed mutations. Manual retry reuses the existing remote complete/undo client path and never pulls/imports snapshots, refreshes remote packs, schedules notifications, updates widget state from remote data, or runs automatically at startup/realtime.
- Successful retry marks the outbox `synced`, updates completion metadata to `confirmedRemote` or `undoneRemote`, and marks pack/item metadata stale so the user can manually refresh remote truth.
- `alreadyCompleted` and `alreadyNotCompleted` remain `no_op`, mark pack/item stale, and must not overwrite remote `completed_by`.
- Retry failure leaves the row `failed`, increments retry metadata through `retry_count` / `last_attempt_at`, and stores only sanitized `last_error` values. Access-lost retry failures mark pack metadata `accessLost`.
- Home/product stale, no-op, and conflict copy is more actionable as `需要刷新共同資料`. Home does not add card buttons in Phase 5I.
- Product-facing manual retry lives in the existing `一起照顧` sheet as `重試同步`, shown only when that remote-backed pack has retryable failed mutations. Friendly snackbars must not include raw exceptions, full UUIDs, tokens, sessions, secrets, or invite codes.
- Developer Settings adds a `Remote-backed Recovery` panel with recovery counts plus `Retry retryable failed mutations POC` and `Refresh stale remote-backed packs POC`. Existing flush and manual refresh tools remain.
- Widget behavior from Phase 5F is unchanged: widget snapshot and action code do not call Supabase or run retry. Notification behavior from Phase 5G is unchanged: notification summary code remains local-summary only and does not retry or flush.
- Realtime remains hint-only and never auto-retries. Backup remains legacy and non-replayable: `sync_outbox`, retry state, typed remote metadata, credentials, sessions, tokens, plaintext invite codes, and remote-backed mirror rows remain excluded, and restore does not replay, retry, pull, import, flush, or grant remote access.

### Phase 5J：Account Binding & Backup Legacy Transition

- Adds account protection status foundation for remote-backed recovery without a Drift schema bump, backup schema bump, or Supabase SQL/RPC/table change.
- Existing `local_users.remote_user_id`, `remote_provider`, `identity_kind`, and `linked_at` remain the local account protection record. Local user ids and local entity ids are never replaced by remote ids.
- `AccountProtectionService` derives local-only, anonymous-unprotected, linked-protected, missing-session, unsupported, and unavailable states from the current local user plus Supabase/AuthRepository current identity.
- Production Supabase auth remains anonymous-first. Apple, Google, and provider-agnostic Email binding interfaces exist as foundation; Phase 5J.1 adds the first production Email OTP binding flow while Apple / Google remain unsupported.
- Successful fake/provider test binding updates the existing local user to `identityKind = linked` with a non-anonymous provider; it does not merge local data, upload local-only packs, create remote packs, join packs, pull/import snapshots, or replay `sync_outbox`.
- Settings shows account protection status and copy that distinguishes anonymous unprotected identity from linked protected identity.
- Manual backup is labeled as legacy local backup. Copy clarifies that backup protects local data only and does not restore remote-backed shared pack access.
- Backup schema remains unchanged. Backup still excludes Supabase tokens, sessions, credentials, service-role keys, plaintext invite codes, typed remote metadata, `sync_outbox`, retry state, and remote-backed mirror rows. Restore still does not pull, import, flush, retry, replay, create remote access, or grant membership.

### Phase 5J.1：Email Account Binding MVP

- Adds a two-step Email binding flow for the current anonymous Supabase session. The flow sends an Email-change OTP with `updateUser(UserAttributes(email: ...))` and verifies it with `verifyOTP(type: emailChange)`.
- The flow is binding, not login. It never calls `signInWithOtp`, never switches accounts, and never stores Email address, OTP code, token, session, credential, service-role key, magic-link token, or plaintext invite code in Drift or backup.
- Start requires the local user to already be linked to the current anonymous remote identity. Local-only, missing-session, already non-anonymous, unsupported, unavailable, and invalid-Email states fail closed with friendly copy.
- Verify succeeds only if Supabase still returns the same remote UID, the user is no longer anonymous, and Email identity/confirmation can be safely inferred. If the UID changes, the app returns `uidChangedUnsafe` and does not mutate the local user.
- On success, `AccountProtectionService.verifyEmailBinding` updates the existing local user to `identityKind = linked` and `remoteProvider = email`. Local app user ids, shared pack ids, item ids, completion actor ids, activity actor ids, mappings, metadata, and outbox rows are unchanged.
- Settings shows Email as available in the account protection sheet and keeps Apple / Google as planned/unsupported. Successful Email binding enables Phase 5K recovery affordances through normal account-protection provider invalidation, but recovery is not run automatically.
- Supabase Dashboard must enable Email auth and configure the Email change template to expose `{{ .Token }}`. No app deep link/callback is required for the OTP MVP.
- Phase 5J.1 does not add Drift schema, backup schema, Supabase SQL/RPC/table changes, automatic recovery, snapshot pull/import, outbox flush/retry, local upload, backup replay, account switching, resource sync, stage sync, or merge/conflict UI.

### Phase 5K：Remote Membership Discovery & Recovery Restore

- Adds explicit recovery of active remote pack memberships for linked/protected remote identities. Discovery reads remote memberships through existing Supabase RLS and does not create membership or grant access.
- Product/default recovery fails closed for anonymous-unprotected, local-only, missing-session, unsupported, or unavailable account states before remote discovery. Developer POC tooling may still expose diagnostics, but product restore is account-protected by default.
- Recovery restore pulls each eligible active pack snapshot through the current Supabase session and imports it through `RemoteSnapshotImportService.importRemotePackSnapshot(source: joinedRemotePack)`. Active membership + active pack status is the MVP eligibility rule; archived/inactive packs are skipped for future optional management, and removed memberships are not recovered.
- Recovery uses a current-session snapshot pull path so it does not create or replace the local user with a new anonymous remote identity.
- Recovery restore is idempotent through existing remote mapping/import behavior: new mirrors are created and existing mirrors can be updated, but local ids are not replaced by remote ids.
- Recovery does not replay backup, replay outbox, flush pending mutations, retry failed mutations, push local data, auto pull at startup, auto import on realtime, or merge local-only packs into remote packs. Pending local mutations remain local pending state and may be surfaced as recovery warnings.
- After successful recovery import, Home naturally updates from local DB invalidation, while widget and notification refresh use existing best-effort local-only refresh services. These surfaces never call Supabase.
- Backup remains legacy and non-replayable. Restore still does not pull, import, report sync state, create remote packs, join packs, grant membership, or regain remote access by itself.
- No Drift schema bump, backup schema bump, Supabase SQL/RPC/table change, widget behavior change, notification behavior change, resource sync, stage sync, account switching UI, or production OAuth provider flow is added.
- Settings exposes a protected-account recovery entry plus `Restore active remote memberships POC` under `Remote-backed Recovery` for manual smoke testing. Product UI does not expose raw remote ids, raw exceptions, tokens, sessions, credentials, service-role keys, or plaintext invite codes.

### Phase 5L：Member Sync Awareness / Pack Freshness

- Adds pack-data freshness for active members of remote-backed shared packs. This is defined as "this app successfully imported pack data" and must not be framed as human attention, member monitoring, or presence.
- Adds Supabase SQL patch `docs/core/sql/phase5l_member_sync_awareness_mvp.sql` with `pack_member_sync_states`, `unique(pack_id, user_id)`, active-member RLS, and two RPCs:
  - `report_pack_snapshot_imported(target_pack_id, latest_activity_event_id, latest_activity_at)`
  - `get_pack_member_freshness(target_pack_id)`
- Latest pack activity uses `activity_events` latest `created_at` plus event id. Phase 5L does not add a remote revision, sequence, or `activities_behind` count.
- Freshness statuses are conservative: `up_to_date`, `possibly_stale`, `no_sync_report`, and `access_unknown`.
- Manual refresh reports freshness only after successful safe local imports. Failed imports and unsafe partial imports do not report.
- Membership recovery reports after each successful imported/refreshed pack. Account-blocked, discovery-failed, or import-failed recovery does not report.
- Reporting failure never rolls back local import or changes the main refresh/recovery success status. It appends the friendly warning `本機已更新，但未能回報同步狀態`.
- Product UI uses the existing `一起照顧` sheet and shows `成員同步狀態` with display names and labels:
  - `已更新至最新資料`
  - `可能未取得最新資料`
  - `尚未回報取得此 Pack 資料`
  - `狀態未確認`
  - `上次更新共同資料：...` when `last_imported_at` exists
- Developer Settings adds POC actions to refresh member freshness and report the current pack as imported. Developer UI may show short ids only.
- Home, widget, and notification surfaces remain local-derived. They do not query member freshness or call Supabase.
- Backup remains legacy and non-replayable. Restore does not report sync state, pull/import remote snapshots, flush/retry outbox, replay backup data, create remote access, or grant membership.
- Phase 5L does not add Drift schema changes, backup schema changes, app-startup report, realtime-triggered report, background sync, automatic retry, outbox flush, account switching, resource sync, stage sync, remote edit/delete/archive sync, or full two-way sync.

### Phase 5M：Acceptance / Hardening

Phase 5M completes the remote-backed shared pack local-first MVP. It is an acceptance, hardening, regression cleanup, documentation convergence, and manual smoke-test finalization pass. It does not add a new sync engine or new remote-backed capability.

#### Phase 5 Acceptance Matrix

| Area | Accepted behavior |
| --- | --- |
| Remote identity / account | Anonymous remote identity can be created and is shown as unprotected. Email binding protects the current anonymous Supabase session only after verified Email-change OTP. `AccountProtectionStatus.linkedProtected` is not set at code-sent time. Apple / Google remain planned/unsupported. Local user id remains stable, `remote_user_id` remains a remote reference, and UID change during Email binding fails closed. |
| Remote-backed pack lifecycle | Remote-backed packs can be created/joined through existing flows, remote snapshots can be pulled, and snapshots can be imported as local mirrors. Existing mirror import/recovery refreshes without duplicate local packs. Repeated recovery is idempotent. Active remote memberships can be discovered for linked/protected users; anonymous, local-only, missing-session, inactive, archived, and removed-member cases fail closed or are skipped. |
| Home / Widget / Notification | Remote-backed local mirror items appear in Home, Widget, and notification summaries where existing local classification supports them. Complete/undo actions route through `ItemRepository` and the outbox. Home, Widget, and Notification surfaces do not call Supabase directly. Pending, failed, stale, access-lost, and needs-refresh labels are compact and safe. |
| Sync / outbox / recovery | Remote-backed complete creates `complete_item`; undo creates `undo_item`. Manual flush and manual retry remain user/developer-triggered. Retry skips non-retryable, conflict, and no-op rows by default. Manual refresh pulls/imports snapshots but does not flush or retry outbox. Email binding does not recover, refresh, flush, or retry. Recovery restore does not flush, retry, push, upload local-only packs, or replay backup data. |
| Member freshness | Successful manual refresh and successful recovery import report snapshot-imported watermarks. Failed imports and unsafe partial imports do not report. Reporting failure adds `本機已更新，但未能回報同步狀態` and does not roll back local import. Freshness statuses are `up_to_date`, `possibly_stale`, `no_sync_report`, and `access_unknown`. UI wording avoids read/unread, online/offline, device, IP, and location semantics. |
| Backup / restore | Backup is `本機備份（Legacy）` and is local-only. It does not export Supabase token/session/credential/service-role key, OTP/magic-link token, plaintext invite code, typed remote metadata, outbox replay data, or remote-backed mirrors. Restore does not grant remote access, auto recover, auto pull/import/flush/retry, report sync state, or replay outbox. Old backup schemas remain restorable. |

#### Phase 5 Manual Smoke Test

The consolidated end-to-end smoke test lives at:

- `docs/core/manual_tests/phase5_remote_backed_shared_pack_acceptance.md`

It covers anonymous identity plus Email binding, create/join/import, Home / Widget / Notification display, complete/undo outbox, manual refresh, protected-account recovery, member freshness, and legacy backup boundaries.

#### Phase 5 Completion Note

Phase 5 completes the remote-backed shared pack local-first MVP. It intentionally stops before background sync, automatic retry, account switching, full conflict resolution, remote item edit/delete/archive sync, resource/stage remote sync, Apple / Google binding, and production-grade cross-device account management.

### Remote-backed CRUD Boundary Phase 1：Item Create / Basic Update / Archive

- Adds local-first `sync_outbox` support for `create_item`, `update_item`, and `archive_item`.
- `create_item` writes a local optimistic item plus pending remote item metadata, then flushes through `create_pack_item_v2`.
- `update_item` is limited to title, note, and assigned-user hint. Pack moves, schedule/config changes, attention policy changes, and resource binding changes are rejected for remote-backed items.
- `archive_item` soft-archives the local item optimistically, then flushes through `archive_pack_item`.
- Manual flush / retry remains explicit. No background sync, startup sync, realtime import, or automatic retry is added.
- Pack update/archive, item skip/pause/resume/move/assign, resource CRUD, and stage CRUD fail closed for remote-backed packs so local mirrors are not silently forked.
- Supabase RPC draft lives in `docs/core/sql/phase6_remote_backed_item_crud_mvp.sql`.

### Phase 6B：Production Foreground Sync Loop

- Adds `RemoteBackedSyncCoordinator` as the production glue between existing local-first outbox writes, outbox flush, and remote snapshot refresh/import.
- Supported production actions are remote-backed item create, basic update, archive, complete, and undo. Each action writes local state first, enqueues `sync_outbox`, then normal UI flow starts a best-effort foreground flush.
- Home, item management, pack management, and `一起照顧` refresh flows flush pending mutations first, then refresh each visible remote-backed pack sequentially through `RemoteBackedPackRefreshService.refreshPack(localPackId)`.
- Refresh/import preserves unresolved pending or failed local outbox state using the existing refresh service stale/pending handling. Failed flushes do not roll back optimistic local state.
- Member visibility uses the existing snapshot/member mirror: opening or refreshing `一起照顧` pulls/imports the remote pack snapshot so newly joined active members can appear in the member list.
- Production copy remains user-facing: `等待同步`, `正在同步`, `同步失敗，稍後會再試`, `共同生活場景已更新`, and `暫時無法更新共同生活場景`. Production UI must not expose Supabase, RPC, outbox, mutation, remote-backed, sync metadata, or POC wording.
- Phase 6B does not add resource sync, stage sync, realtime auto-sync, background sync, startup sync, widget remote CRUD, notification remote actions, hard delete, member role management, complex conflict UI, or a new shared-pack dashboard.
- Manual verification lives in `docs/core/manual_tests/phase6b_production_sync_loop_smoke_test.md`.

### Phase 6C：Pack + Items Sharing MVP

- Hardens the existing foreground-only Pack + Items shared path. Supported shared entities are pack membership mirror, item create / basic update / archive, item complete / undo, and basic item activity/history.
- Remote snapshot fetch/import includes completion rows with `undone_at`. Import updates existing local completions and marks the local done action reverted when a remote undo is imported, while preserving `completed_by` and `undone_by` actors.
- Member import preserves display name, active/removed status, and host/member roles. The `一起照顧` member list reads active local mirror members only, so removed members remain history but do not appear in the active care list.
- Imported remote item activity events are idempotently mapped through sync mappings and can be projected as user-facing messages for `item_created`, `item_updated`, `item_archived`, `item_completed`, and `item_undone`.
- Sync labels are compact and production-facing: `等待同步`, `正在同步`, `同步失敗`, `有新的更新，請刷新`, and `已無法存取`. Healthy synced rows stay quiet.
- Remote-backed pack metadata editing and pack archive/delete/leave remain guarded with copy that explains shared scene details cannot be changed yet, while item create/edit/archive/complete/undo remain supported.
- Phase 6C does not add resource sharing, stage sharing, realtime auto-import, background sync, app-start sync, widget remote CRUD, notification remote sync, hard delete, member role management/removal, ownership transfer, complex conflict UI, or a shared dashboard redesign.
- Manual verification lives in `docs/core/manual_tests/phase6c_pack_items_sharing_mvp_smoke_test.md`.

### Phase 6D：Resource Sharing MVP

- Adds foreground-only Resource sharing for remote-backed packs. Supported Resource operations are create, basic update, archive, quantity increment, quantity decrement, quantity adjust, and refill.
- Supported Resource actions are local-first: `ResourceRepository` updates Drift optimistically, writes `sync_outbox`, and normal UI flow starts a best-effort `RemoteBackedSyncCoordinator.syncAfterRemoteBackedMutation(localPackId)` flush.
- New Resource outbox actions are `create_resource`, `update_resource`, `archive_resource`, `resource_increment`, `resource_adjust`, and `resource_decrement`. Flush/retry updates `remote_resource_sync_metadata`, sync mappings, pack stale state, retryable failure state, and access-lost state.
- Remote snapshot refresh imports `resources` and `resource_events` idempotently, maps remote Resource ids through `sync_mappings`, preserves local id != remote id, updates local Resource mirrors, and projects Resource events into local Resource history.
- Imported `activity_events` with `entity_type = resource` map through Resource sync mappings and can render actor-based messages such as `{name} 新增了「{resourceTitle}」`, `{name} 補充了「{resourceTitle}」`, `{name} 調整了「{resourceTitle}」`, `{name} 扣除了「{resourceTitle}」`, and `{name} 封存了「{resourceTitle}」`.
- Resource sync labels match item labels and stay quiet when healthy: `等待同步`, `正在同步`, `同步失敗`, `有新的更新，請刷新`, and `已無法存取`. Access-lost Resource rows disable Resource actions.
- Item-linked Resource consumption remains guarded. Creating or editing item-resource bindings in remote-backed packs fails closed with `共同生活場景暫時未支援這個資源操作`, and remote-backed item completion does not silently perform local-only Resource consumption.
- Phase 6D does not add Stage sharing, hard delete, Resource pack move, Resource type change, pack/member management, realtime auto-import, background sync, app-start sync, widget remote CRUD, notification remote sync, item-linked atomic completion/consumption, or a new dashboard.
- Supabase RPC draft lives in `docs/core/sql/phase6d_remote_backed_resource_mvp.sql`.
- Manual verification lives in `docs/core/manual_tests/phase6d_resource_sharing_mvp_smoke_test.md`.

### Phase 6E：Stage Sharing MVP

- Adds foreground-only Stage sharing for remote-backed packs. Supported Stage operations are StageTracker create / basic update / archive, StageRule create / update / status change, manual important StageRecord create / update / soft archive, and generated occurrence acknowledgement.
- Supported Stage actions are local-first: `StageTrackerRepository` updates Drift optimistically, writes `sync_outbox`, and normal UI flow may start `RemoteBackedSyncCoordinator.syncAfterRemoteBackedMutation(localPackId)` without blocking navigation or rolling back optimistic state.
- New Stage outbox actions are `create_stage_tracker`, `update_stage_tracker`, `archive_stage_tracker`, `create_stage_rule`, `update_stage_rule`, `update_stage_rule_status`, `create_stage_record`, `update_stage_record`, `archive_stage_record`, and `stage_acknowledge`. Flush/retry updates `remote_stage_sync_metadata`, sync mappings, pack stale state, retryable failure state, and access-lost state.
- Remote snapshot refresh imports `stage_trackers`, `stage_rules`, `stage_records`, and `stage_acknowledgements` idempotently, maps remote ids through `sync_mappings`, preserves local id != remote id, and preserves pending/failed local mutation state for later retry/refresh.
- Imported `activity_events` with `entity_type = stage_tracker`, `stage_rule`, or `stage_record` map through Stage sync mappings and can render actor-based messages such as `{name} 新增了「{stageTitle}」`, `{name} 更新了「{stageTitle}」`, `{name} 確認了「{stageTitle}」`, and `{name} 封存了「{stageTitle}」`.
- Stage sync labels match item/resource labels and stay quiet when healthy: `等待同步`, `正在同步`, `同步失敗`, `有新的更新，請刷新`, and `已無法存取`. Access-lost Stage rows disable Stage actions.
- StageTracker pack move, generated occurrence ignore, related item creation from StageOccurrence, hard delete, progress/checkpoint/reset, widget remote CRUD, notification remote sync, realtime auto-import, background sync, app-start sync, pack/member management, and old legacy `stages` draft semantics remain out of scope or guarded.
- Supabase RPC draft lives in `docs/core/sql/phase6e_remote_backed_stage_mvp.sql`.
- Manual verification lives in `docs/core/manual_tests/phase6e_stage_sharing_mvp_smoke_test.md`.

### Phase 6F：Unified Activity / Sync Hardening

- The existing activity route is now the unified production activity feed for supported shared `activity_events`; it does not add a new dashboard, route, or navigation surface.
- Activity projection covers item, resource, stage, member, and pack-visible events only when backed by existing local/remote data. Actor fallback is `有成員`; missing entity titles fall back to `一個事項`, `一個資源`, or `一個階段`.
- Projection dedupe is display-layer safe: remote activity ids are unique, matching client mutation ids collapse pending/confirmed duplicates, and no-client-mutation duplicates collapse only for the same entity/action/actor within a short timestamp window. Historical local rows are not deleted in Phase 6F.
- Sync status copy is unified across pack, item, resource, stage, Home, management, and shared-care surfaces: `等待同步`, `正在同步`, `同步失敗`, `有新的更新，請刷新`, `已無法存取`, transient `已更新`, and failure copy `暫時無法更新，請稍後再試`.
- Failed item/resource/stage rows can retry through production UI by reusing the existing pack retry path. Retry never rolls back local optimistic data in Phase 6F; success invalidates local surfaces and access-lost failures stop unsafe retry.
- Access-lost packs keep historical local data and activity readable while item/resource/stage actions are disabled and repositories continue to fail closed.
- Stale refresh remains foreground-only: refresh flushes pending local mutations first, imports the snapshot, clears stale only when safe, and keeps stale/pending/failed labels when unresolved local mutations remain.
- Phase 6F hardens Phase 6D/6E SQL scripts for repeated and partial application by adding defensive `alter table ... add column if not exists`, idempotent indexes, and policy drops before recreation.
- Phase 6F still does not add background sync, app-start sync, realtime auto-import, widget remote CRUD, notification remote sync, complex conflict UI, pack CRUD, member role management, hard delete, or a new shared dashboard.
- Manual verification lives in `docs/core/manual_tests/phase6f_unified_activity_sync_hardening_smoke_test.md`.

### Phase 6G：Multi-device QA / Polish

- Phase 6G is the focused production-readiness pass for the existing shared-pack MVP. It does not add a new domain area or new navigation.
- Supported production flows remain invite/join, member mirror refresh, item sharing, resource sharing, stage sharing, unified activity, foreground sync, manual pull-to-refresh, retry for failed supported mutations, and access-lost read-only behavior.
- User-facing stale/access-lost copy is aligned across Home, widget snapshots, notification summaries, pack/item/resource/stage surfaces, shared care, and unified activity: `有新的更新，請刷新` and `已無法存取`.
- Production shared surfaces avoid raw Supabase / RPC / outbox / remote-backed / POC wording. Developer Settings may keep explicit debug labels, but normal user flows do not depend on `RemotePocController`.
- Phase 6G completes the Phase 6E Stage SQL production draft by defining all app-called Stage RPCs with `auth.uid()`, active membership through `is_pack_member`, idempotent `client_mutation_id`, activity events, and soft archive semantics.
- Manual verification lives in `docs/core/manual_tests/phase6g_shared_pack_multi_device_qa.md`.
- Phase 6G still does not add background sync, app-start sync, realtime auto-import, widget remote CRUD, notification remote sync, pack archive/delete/leave, remove member, role management, ownership transfer, complex conflict UI, hard delete, or a shared dashboard redesign.

### Phase 6 Backlog

None of these are implemented in Phase 5M. Phase 6B foreground production sync loop, Phase 6C Pack + Items sharing MVP, Phase 6D Resource sharing MVP, Phase 6E Stage sharing MVP, Phase 6F unified activity / sync hardening, and Phase 6G multi-device QA / polish are now implemented after Phase 5M. Remaining later phases:

- Historical backlog marker retained for Phase 5 acceptance: Phase 6A：Background Sync Design Spec. Background sync remains later work and is not part of Phase 6B, 6C, or 6D.
- Additional later work：automatic/background sync, app-start sync, realtime auto-import, widget remote CRUD, notification remote sync, hard delete, member role management/removal, ownership transfer, account switching, local/remote merge, backup legacy removal, richer notification scheduling, notification action bridge, richer freshness history/management, and full two-way sync.

## 19. Open Questions

1. Remote-backed pack 被 removed member 後，本機是否保留 read-only history？
2. Pending local attempt 是否要顯示在 activity log？
3. Remote item schedule model 是否已足夠支援主畫面 / notification？
4. Widget 是否應顯示 sync failed / pending 狀態？
5. Notification action 離線後同步失敗時，如何提醒使用者？
6. Backup legacy UI 何時隱藏？
7. Apple / Google binding should follow which provider first after Email OTP binding?
8. Pending local activity 與 confirmed remote activity 是否共用 `activity_events`，或以 projection / outbox 分離？
9. Removed member 的 local mirror 是否應清除 shared content，或只停止 active query / action？
10. Resource / stage sync 是否要跟 item completion sync 同一 outbox 模型？
