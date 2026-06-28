# Phase 6D Resource Sharing MVP Smoke Test

Use two app installs signed in to different active remote users. Apply the existing remote shared-pack SQL in order, including `docs/core/sql/phase6_remote_backed_item_crud_mvp.sql` and `docs/core/sql/phase6d_remote_backed_resource_mvp.sql`.

## Device A Creates Shared Context

1. Device A creates or opens a remote-backed shared pack.
2. Device A invites Device B.
3. Device B joins with the invite code.
4. Device A opens `一起照顧` and refreshes.
5. Expected: Device B appears as an active member. Removed members, if any, do not appear in the active list.

## Resource Create / Update / Archive

1. Device A creates a quantity Resource in the shared pack.
2. Device A waits briefly or triggers normal foreground sync.
3. Device B pull-to-refreshes Resource management or the shared pack.
4. Expected: Device B sees the Resource title, description, quantity, unit, and thresholds.
5. Device A edits the Resource title or basic fields.
6. Device B refreshes.
7. Expected: Device B sees the edited Resource.
8. Device A archives the Resource.
9. Device B refreshes.
10. Expected: the Resource leaves active Resource views while history/activity remains available where shown.

## Resource Refill / Adjust

1. Device A creates or opens an active shared Resource.
2. Device A increments or refills the Resource.
3. Device B refreshes.
4. Expected: Device B sees the updated quantity or time projection and one matching history row.
5. Device B adjusts or decrements the Resource.
6. Device A refreshes.
7. Expected: Device A sees Device B's change and actor attribution in Resource history/activity where displayed.
8. Repeat refresh on both devices.
9. Expected: Resource events and activity rows are not duplicated.

## Status / Retry / Access Lost

1. Temporarily make Device A unable to flush a supported Resource mutation, then perform a Resource edit.
2. Expected: local optimistic state remains visible and the row can show `同步失敗`.
3. Restore access and use the existing retry path where failed shared mutations are visible.
4. Expected: retry succeeds or leaves a friendly failed state without raw technical wording.
5. Remove Device B from the pack remotely, then try a Resource action on Device B after refresh/failure.
6. Expected: Resource actions are disabled or fail closed with `已無法存取`.

## Guarded Scope

1. Try creating or editing an item-resource binding inside the shared pack.
2. Expected: the action fails closed with `共同生活場景暫時未支援這個資源操作`.
3. Complete a remote-backed item that would consume a Resource in a local-only pack.
4. Expected: shared Resource quantity is not silently changed locally.
5. Try Stage mutations in the shared pack.
6. Expected: Stage sharing remains guarded.
7. Confirm widget, notification, realtime import, background sync, Resource hard delete, Resource pack move, Resource type change, and pack/member management behavior are unchanged.
