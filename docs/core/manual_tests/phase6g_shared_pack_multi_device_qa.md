# Phase 6G Shared Pack Multi-device QA

This checklist verifies the foreground-only shared-pack MVP on two real devices.
Do not mark this checklist as passed unless Device A and Device B were both run
against the same Supabase dev project.

## Scope

Verify:

- Invite / join.
- Member mirror refresh.
- Item create / update / archive / complete / undo.
- Resource create / update / archive / refill / adjust / decrement.
- StageTracker / StageRule / StageRecord supported sharing and acknowledgement.
- Unified recent activity.
- Pending / syncing / failed / stale / access-lost labels.
- Retry for failed supported mutations.
- SQL scripts can be applied and re-applied on a dev Supabase project.

Out of scope:

- Background sync.
- App-start sync.
- Realtime auto-import.
- Widget remote CRUD.
- Notification remote sync.
- Pack archive / delete / leave.
- Remove member, role management, or ownership transfer.
- Hard delete.
- Complex manual conflict resolution UI.
- New shared dashboard or navigation.

## Setup

1. Install or run the latest app on Device A and Device B.
2. Use the same Supabase dev project for both devices.
3. Confirm both devices use the same Supabase dart-defines.
4. Clear app data on both devices if a clean run is needed.
5. Open the app on both devices.
6. Confirm both devices can create an anonymous shared identity.
7. Confirm production UI does not show Supabase / RPC / outbox / remote-backed / POC wording outside Developer Settings.

## SQL

1. Apply these scripts on a clean Supabase dev project in documented order:
   - Phase 6 item CRUD SQL.
   - Phase 6D Resource SQL.
   - Phase 6E Stage SQL.
2. Re-apply the same scripts.
3. If practical, simulate a partial apply by creating one table without later columns, then re-run the script.
4. Expected:
   - No duplicate policy error.
   - No missing column error.
   - No missing function error.
   - Phase 6E Stage RPCs exist and are callable by authenticated users.
   - No `is_active_pack_member(uuid, uuid)` error appears.

## Invite / Join / Members

Device A:

1. Create a `生活場景`.
2. Open `一起照顧`.
3. Create an invite code.
4. Share or enter the invite code on Device B.

Device B:

1. Open `加入生活場景`.
2. Enter the invite code.
3. Join the pack.
4. Confirm the shared pack appears.
5. Open `一起照顧`.
6. Confirm Device B sees host and self.

Device A:

1. Pull to refresh or press refresh in `一起照顧`.
2. Confirm Device A sees Device B as active member.
3. Confirm member roles show `建立者` / `成員`.
4. Confirm removed members, if any, are not shown in the active list.

## Items

Device A:

1. Create an item in the shared pack.
2. Edit item title and note.
3. Complete the item.
4. Undo completion.
5. Create another item and archive it.
6. Confirm foreground sync attempts occur without Developer Settings.

Device B:

1. Pull to refresh normal UI.
2. Confirm the created item appears with updated title and note.
3. Confirm completion / undo state is correct.
4. Confirm archived item leaves active views while history/activity remains.
5. Create an item.
6. Complete it.
7. Confirm foreground sync attempts occur.

Device A:

1. Pull to refresh normal UI.
2. Confirm Device B’s item and completion appear.

## Resources

Device A:

1. Create a quantity resource.
2. Update resource title or thresholds.
3. Refill or increment it.
4. Adjust it.
5. Decrement it if available in the current UI.
6. Create another resource and archive it.

Device B:

1. Pull to refresh Resource management or Home.
2. Confirm resource create / update / refill / adjust / decrement / archive results.
3. Perform one supported resource action.

Device A:

1. Pull to refresh.
2. Confirm Device B’s resource action appears with correct quantity/history.

## Stages

Device A:

1. Create a StageTracker in the shared pack.
2. Update the StageTracker or supported rule/record fields.
3. Add or update a manual important StageRecord if available.
4. Acknowledge a generated occurrence if available.
5. Archive another supported stage entity if available.

Device B:

1. Pull to refresh StageTracker management/detail.
2. Confirm tracker/rule/record/acknowledgement state appears.
3. Perform one supported Stage action.

Device A:

1. Pull to refresh.
2. Confirm Device B’s Stage action appears.

## Unified Activity

1. Open `最近活動` on both devices.
2. Pull to refresh normal shared-pack surfaces first if needed.
3. Confirm item/resource/stage/member activities appear.
4. Confirm actor names are readable.
5. Confirm unknown actor fallback is `有成員`.
6. Confirm missing entity title fallbacks are:
   - `一個事項`
   - `一個資源`
   - `一個階段`
7. Repeat refresh.
8. Confirm no duplicated activity/history rows appear.

## Sync Status / Retry

1. Create a pending shared mutation if possible.
2. Confirm pending label is `等待同步`.
3. Trigger sync.
4. Confirm syncing label is `正在同步` if visible.
5. Simulate network failure if practical.
6. Confirm failed label is `同步失敗`.
7. Restore network.
8. Tap `重試同步`.
9. Confirm retry succeeds or remains safely failed without rolling back local optimistic data.
10. Trigger a stale state if practical.
11. Confirm stale label is `有新的更新，請刷新`.

## Access Lost

1. Simulate current user removed from the pack if existing dev tooling supports it.
2. Refresh the affected device.
3. Confirm pack/item/resource/stage surfaces show `已無法存取`.
4. Confirm item/resource/stage actions are disabled or fail closed.
5. Confirm history and activity remain readable.
6. Confirm copy does not expose RLS, auth uid, Supabase, or permission wording.

## Result Log

- Date:
- App commit:
- Supabase project:
- Device A:
- Device B:
- SQL clean apply:
- SQL re-apply:
- Invite / join:
- Members:
- Items:
- Resources:
- Stages:
- Unified activity:
- Retry:
- Access lost:
- Notes / bugs:

Codex note: local automated tests can support this checklist, but they do not
count as real-device A/B verification.
