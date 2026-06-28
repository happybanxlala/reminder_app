# Phase 6B Production Sync Loop Smoke Test

Purpose: verify the foreground production sync loop for existing remote-backed shared-pack item actions. This is not background sync, realtime import, widget remote CRUD, notification remote CRUD, resource sync, or stage sync.

## Device A Host Setup

1. Create a local生活場景.
2. Open `一起照顧`.
3. Create or reuse an active invite code.
4. Confirm no Developer Settings / POC action is needed.

## Device B Join

1. Open生活場景管理.
2. Tap `加入生活場景`.
3. Enter Device A's invite code.
4. Confirm the shared pack appears in the app after join/import.

## Member Visibility

1. On Device A, open `一起照顧` for the shared pack.
2. Tap refresh.
3. Expected copy: `正在更新共同生活場景……`, then `共同生活場景已更新`.
4. Confirm Device B appears as an active member.

## Item Mutation Flush

On Device A, in the shared pack:

1. Create an item.
2. Edit the item title or note.
3. Complete the item.
4. Undo the completion.
5. Archive the item.
6. Confirm each supported action updates local UI immediately.
7. Confirm the app attempts sync without Developer Settings.
8. Confirm Supabase receives the corresponding supported RPC request.

## Device B Refresh / Import

1. On Device B, pull to refresh Home or item management.
2. Confirm the latest item title/note appears.
3. Confirm completion / undo state reflects Device A after refresh.
4. Confirm archived items no longer appear in active lists after refresh.

## Failure / Scope Guards

1. Simulate a temporary network or permission failure.
2. Confirm pending / failed labels remain user-facing: `等待同步` or `同步失敗，稍後會再試`.
3. Confirm optimistic local state is not rolled back.
4. Confirm resource mutations in a shared pack remain guarded.
5. Confirm stage mutations in a shared pack remain guarded.
6. Confirm no realtime, background, widget remote, notification remote, hard-delete, role-management, or conflict UI behavior is required to pass this test.
