# Phase 6F Unified Activity / Sync Hardening Smoke Test

## Purpose

Verify that remote-backed shared packs show consistent activity, sync status, retry, stale refresh, and access-lost behavior across already-supported shared items, resources, and stages.

Phase 6F remains foreground-only. Do not verify background sync, app-start sync, realtime auto-import, widget remote CRUD, notification remote sync, member role management, pack archive/delete/leave, hard delete, or a new shared dashboard.

## Device A Setup

1. Create a shared生活場景 and invite Device B.
2. Create one shared item, one shared resource, and one shared stage tracker.
3. Complete the item.
4. Refill or adjust the resource.
5. Update or acknowledge the stage.
6. Confirm foreground sync attempts run after each supported action.

## Device B Refresh

1. Join the shared生活場景.
2. Pull to refresh from normal UI.
3. Confirm the item, resource, and stage appear.
4. Confirm item completion, resource event, and stage event are visible.
5. Open `最近活動`.
6. Confirm actor-aware messages use Device A display name.
7. Pull to refresh repeatedly.
8. Confirm activity/history rows are not duplicated.

## Device B Mutates

1. Perform one supported item action.
2. Perform one supported resource action.
3. Perform one supported stage action.
4. Confirm foreground sync attempts run.

## Device A Refresh

1. Pull to refresh from normal UI.
2. Confirm Device B actions appear.
3. Open `最近活動`.
4. Confirm actor-aware messages use Device B display name.
5. Repeat refresh and confirm no duplicated activity/history.

## Failure / Retry

1. Simulate a failed shared item/resource/stage mutation or temporarily disable network.
2. Confirm the row shows `同步失敗`.
3. Restore network.
4. Tap `重試同步` from a normal production surface.
5. Confirm successful retry clears failed state, or failed retry keeps optimistic local data and shows friendly failure copy.

## Access Lost

1. Simulate current user removed/access lost if existing tooling supports it.
2. Confirm pack/item/resource/stage surfaces show `已無法存取`.
3. Confirm unsafe item/resource/stage actions are disabled.
4. Confirm local historical data and `最近活動` remain readable where safe.

## Stale Refresh

1. Trigger a remote change from another device.
2. Confirm stale copy is `有新的更新，請刷新` when visible.
3. Pull to refresh.
4. Confirm pending local changes are not overwritten.
5. Confirm stale clears only after successful refresh with no unresolved pending/failed local mutations.
