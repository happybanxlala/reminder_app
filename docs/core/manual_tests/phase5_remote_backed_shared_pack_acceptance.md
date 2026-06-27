# Phase 5 Remote-backed Shared Pack Acceptance Smoke Test

Purpose: verify Phase 5 as a local-first remote-backed shared pack MVP. This smoke test must not be interpreted as background sync, automatic recovery, full Email sign-in, account switching, read receipts, or full two-way sync.

## Test 1: Anonymous Identity + Email Binding

1. Fresh install.
2. Start the app with `SUPABASE_URL` and `SUPABASE_ANON_KEY` dart-defines.
3. Create an anonymous remote identity.
4. Confirm Settings shows `匿名遠端身份，未受保護`.
5. Open account protection and bind Email with the OTP code.
6. Confirm Settings shows `帳號已受保護`, `已綁定 Email`, and `你的共同 Pack 可透過此 Email 找回`.
7. Confirm the local user id is unchanged.
8. Confirm `remote_user_id` is unchanged when Supabase keeps the same UID.
9. Confirm `恢復共同 Pack` becomes available after provider refresh.
10. Confirm there is no auto recovery, auto refresh, or auto outbox flush.

Phase 5J.1 limitation: Email binding is current-session Email-change OTP binding. It is not full Email sign-in on a new device, magic-link login, or production cross-device session recovery.

## Test 2: Create / Join Remote-backed Pack

1. Device A creates or confirms a remote-backed shared pack.
2. Device B joins through the existing invite flow, or uses protected-account recovery when an eligible protected session already exists.
3. Pull the remote snapshot.
4. Import the local mirror.
5. Confirm Home shows eligible remote-backed items.
6. Confirm the Home Widget snapshot includes eligible remote-backed items.
7. Confirm notification summary behavior remains local-derived and safe.

## Test 3: Complete / Undo Outbox

1. Complete a remote-backed item from Home.
2. Confirm local state becomes pending.
3. Confirm a `sync_outbox` `complete_item` mutation exists.
4. Confirm Home, Widget, and Notification layers did not directly call Supabase.
5. Manually flush outbox.
6. Confirm synced, no-op, conflict, or failed result is handled safely.
7. Undo the item.
8. Confirm a `sync_outbox` `undo_item` mutation exists.
9. Manually flush again.

## Test 4: Manual Refresh

1. Host changes a remote-backed pack.
2. Member sees stale / needs-refresh state where applicable.
3. Member taps manual refresh.
4. App pulls the snapshot and imports the local mirror.
5. Home, Widget, and Notification update from the local mirror only.
6. Refresh does not flush outbox.
7. Refresh does not retry failed mutations.

## Test 5: Protected-account Recovery

1. Device A has an Email-linked protected account and an active remote-backed pack.
2. Device B is a clean install.
3. Device B must already have a valid protected remote session under the implemented MVP constraints. Phase 5J.1 alone does not provide full Email sign-in on a new device.
4. Device B manually triggers `恢復共同 Pack`.
5. Active memberships are discovered through the current authenticated remote session.
6. Active packs are restored/imported.
7. Re-running recovery creates no duplicate local packs/items/completions/activity/mappings.
8. Anonymous, local-only, and missing-session recovery fail closed.

## Test 6: Member Freshness

1. Device A host has a remote-backed shared pack.
2. Device B member has imported the same pack.
3. Host changes the pack and creates activity.
4. Before B refreshes, freshness may show B as `可能未取得最新資料`.
5. B manually refreshes.
6. B reports successful import.
7. A refreshes member freshness and sees B as `已更新至最新資料`.
8. A member with no report shows `尚未回報取得此 Pack 資料`.
9. UI does not say `已讀`, `未讀`, `在線`, or `離線`.

## Test 7: Backup Legacy

1. Export backup.
2. Inspect backup does not contain Supabase token/session/credential/service-role key/OTP/magic-link token/plaintext invite code.
3. Restore backup.
4. Confirm restore does not grant remote access.
5. Confirm restore does not auto recover remote packs.
6. Confirm restore does not replay outbox.
7. Confirm backup copy says local-only / legacy.

## Boundaries

- no background sync
- no automatic retry
- no automatic refresh
- no automatic recovery restore
- no realtime payload as source of truth
- no account switching
- no Apple / Google binding
- no resource / stage remote sync
- no remote item edit / delete / archive sync
- no read receipts, online/offline presence, device tracking, IP tracking, or location tracking
