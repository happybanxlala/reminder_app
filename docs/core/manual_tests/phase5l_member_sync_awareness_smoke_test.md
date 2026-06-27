# Phase 5L Member Sync Awareness Smoke Test

Purpose: verify remote-backed shared pack freshness reporting after safe local imports.

## Setup

1. Apply SQL through `docs/core/sql/phase5l_member_sync_awareness_mvp.sql`.
2. App A signs in and has an active remote-backed shared pack with at least two active members.
3. App B signs in as another active member of the same pack.
4. App B runs a safe manual refresh or recovery restore so the local mirror is imported.

## Reporting

1. Confirm the app reports the successful import through `report_pack_snapshot_imported`.
2. If reporting fails, local import still succeeds and the app shows `本機已更新，但未能回報同步狀態`.
3. Do not trigger report from app startup alone.
4. Do not trigger report from realtime signal alone.
5. Do not trigger report from backup restore.

## Freshness Query

1. App A opens `一起照顧` for the same remote-backed pack.
2. Confirm the member section shows `成員同步狀態`.
3. Confirm labels use only pack freshness language:
   - `已更新至最新資料`
   - `可能未取得最新資料`
   - `尚未回報取得此 Pack 資料`
   - `狀態未確認`
4. Confirm `上次更新共同資料：...` appears only when `last_imported_at` exists.
5. Confirm developer Settings can run `get_pack_member_freshness`.

## RLS Checks

1. Active same-pack members can call `get_pack_member_freshness`.
2. Removed members cannot report import state.
3. Non-members cannot query pack freshness.
4. A member can upsert only their own `pack_member_sync_states` row.

## Boundaries

- no auto refresh
- no background sync
- no automatic retry
- no outbox flush
- no backup replay
- no service role key
- no token/session/credential export
- no plaintext invite code in local backup
