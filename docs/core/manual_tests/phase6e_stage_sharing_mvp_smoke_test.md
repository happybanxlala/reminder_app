# Phase 6E Stage Sharing MVP Smoke Test

Date: 2026-06-29

Scope: foreground-only remote-backed shared-pack Stage sharing. Do not verify background sync, realtime import, widget remote CRUD, notification actions, member management, hard delete, progress/checkpoint/reset, or generated occurrence ignore.

## Setup

1. Device A and Device B use separate local installs.
2. Device A creates a shared生活場景 and opens `一起照顧`.
3. Device B joins with the invite code.
4. On both devices, manually refresh `一起照顧` and confirm active members appear.

## StageTracker And Rules

1. On Device A, create a StageTracker in the shared生活場景 with at least one recurring StageRule.
2. Confirm the local row appears immediately and shows no technical wording.
3. Trigger foreground sync by leaving the save flow or manually refreshing a shared surface.
4. On Device B, pull-to-refresh the StageTracker management page.
5. Confirm the StageTracker and StageRule appear with matching title, subject, start date, and rule interval.
6. On Device A, edit the StageTracker basic fields and a StageRule.
7. Refresh Device B and confirm the updated fields import once.
8. Archive a StageRule or StageTracker on Device A, refresh Device B, and confirm active views exclude archived rows while history remains available where the app exposes it.

## Manual Important Stage

1. On Device A, add a manual important StageRecord.
2. Refresh Device B and confirm it appears in the Stage timeline/history.
3. Edit the manual StageRecord on Device A.
4. Refresh Device B and confirm label, note, date, and reminder offset match.
5. Archive the manual StageRecord on Device A.
6. Refresh Device B and confirm active/upcoming views exclude it.

## Generated Occurrence Acknowledgement

1. On Device A, acknowledge a generated StageOccurrence from Home or Stage detail.
2. Confirm it appears in today completed/history locally.
3. Refresh Device B.
4. Confirm the acknowledgement state imports with Device A as actor where activity/history displays actor names.
5. Repeat refresh on Device B and confirm no duplicate acknowledgement or duplicate activity row appears.

## B-To-A Direction

1. On Device B, create or edit a supported Stage entity.
2. Let foreground sync run or trigger a manual refresh.
3. Refresh Device A and confirm Device B’s change imports.

## Activity And Status

1. Confirm Stage activity copy is user-facing:
   - `{name} 新增了「{stageTitle}」`
   - `{name} 更新了「{stageTitle}」`
   - `{name} 確認了「{stageTitle}」`
   - `{name} 封存了「{stageTitle}」`
2. Simulate network failure during a Stage mutation.
3. Confirm the row can show `同步失敗` and remains retryable through the existing retry path.
4. Restore connectivity, retry/refresh, and confirm the row syncs or becomes stale for refresh.

## Guards

1. Try moving a StageTracker to another Pack in a remote-backed shared pack. It should be blocked.
2. Try generated occurrence ignore in a remote-backed shared pack. It should be blocked.
3. Try creating a related Item from a StageOccurrence in a remote-backed shared pack. It should be blocked with `共同生活場景暫時未支援這個階段操作`.
4. Confirm widget actions, notification actions, realtime advisory state, and background sync behavior are unchanged.
