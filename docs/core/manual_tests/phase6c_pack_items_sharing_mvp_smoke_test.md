# Phase 6C Pack + Items Sharing MVP Smoke Test

Purpose: verify that foreground refresh makes shared pack members, shared item changes, completion/undo state, and basic item activity understandable across two devices. This test does not require realtime import, background sync, widget remote CRUD, notification remote sync, resource sharing, or stage sharing.

## Device A Host Setup

1. Create a生活場景.
2. Open `一起照顧`.
3. Create or reuse an active invite code.
4. Confirm the sheet uses user-facing copy and does not mention Supabase, RPC, outbox, metadata, or POC.

## Device B Join

1. Open生活場景管理.
2. Tap `加入生活場景`.
3. Enter Device A's invite code.
4. Confirm the shared pack appears after join/import.
5. Open `一起照顧`, refresh, and confirm the host appears as an active member.

## Member Visibility

On Device A:

1. Open `一起照顧` for the shared pack.
2. Tap refresh.
3. Confirm B appears as an active member.
4. Expected member copy: `目前只有你可以看到這個生活場景` when alone, or `{memberCount} 人正在一起照顧這個生活場景` when shared.
5. If refresh fails, confirm existing local members remain visible and the message is `暫時無法更新成員，請稍後再試`.

## Device A To Device B Item Sharing

On Device A:

1. Create an item in the shared pack.
2. Edit the item title and note.
3. Complete the item.
4. Undo the completion.
5. Archive another shared item if available.
6. Confirm each action updates local UI immediately and attempts foreground sync without Developer Settings.

On Device B:

1. Pull to refresh Home or item management.
2. Confirm the created item appears with the latest title/note.
3. Confirm completion state appears after complete refresh.
4. Confirm undo removes the active completion after refresh while preserving history.
5. Confirm archived items no longer appear in active lists.
6. Open item activity and confirm basic actor messages appear, such as `{name} 新增了「{itemTitle}」` and `{name} 完成了「{itemTitle}」`.

## Device B To Device A Item Sharing

On Device B:

1. Create an item in the shared pack.
2. Edit title/note.
3. Complete the item.

On Device A:

1. Pull to refresh Home or item management.
2. Confirm B-created item appears.
3. Confirm B completion is visible and completion actor is not rewritten as A.
4. Confirm basic item activity shows B's display name when available.

## Sync Status And Retry

1. Simulate offline or temporary remote failure during a shared item mutation.
2. Confirm pending/syncing/failed/stale/access-lost labels are compact: `等待同步`, `正在同步`, `同步失敗`, `有新的更新，請刷新`, `已無法存取`.
3. Confirm healthy synced rows do not constantly show `已同步`.
4. Confirm `重試同步` remains available from `一起照顧` when a failed retryable mutation exists.

## Scope Guards

1. Try editing shared pack metadata; confirm it is blocked with `共同生活場景暫時未支援修改場景資料。你仍可以新增、編輯、封存、完成或復原事項。`
2. Confirm shared pack archive/delete/leave/member management is not added.
3. Confirm resource mutations in the shared pack remain guarded.
4. Confirm stage mutations in the shared pack remain guarded.
5. Confirm widget actions, notification actions, realtime import, background sync, hard delete, complex conflict UI, and shared dashboard redesign are not required to pass this test.
