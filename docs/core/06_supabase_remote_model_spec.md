# Supabase Remote Model Spec — Phase 3A

本文件是 Phase 3A 的 Supabase remote data model、RLS policy draft、SQL schema draft 與 Phase 3C POC 邊界規格。

Phase 3A 是設計階段，不是 Supabase integration 實作階段。

Phase 3B implementation note：Phase 3B implements anonymous Supabase Auth identity linking only. Remote shared pack schema / RLS remains Phase 3C+.

## 1. Purpose

Phase 3A 的目標是先定義 Reminder App 未來 Shared Pack remote model 的安全資料基礎，讓 Phase 3B / 3C 可以在清楚的 Supabase schema 與 RLS 邊界上實作。

本階段不做：

- 不加入 `supabase_flutter` dependency。
- 不初始化 Supabase client。
- 不呼叫 Supabase Auth network。
- 不做 anonymous sign-in、Apple / Google / Email binding。
- 不做 realtime、full sync、background sync。
- 不做 invite code、invite link、QR invite。
- 不自動上傳 local personal data。
- 不把 Personal Pack 自動變成 remote pack。
- 不修改 iOS / Android home widget 行為。
- 不大改 UI。

本階段輸出是文件與 SQL draft。SQL 需要在未來 Phase 3B / 3C 以 Supabase SQL editor 或 local Supabase CLI 實測後，才可視為 production migration。

## 2. Product Principles

> Shared Pack is a shared state and activity history space, not a strict task ownership system.

共同 Pack 重視狀態透明與變更紀錄，而不是嚴格的任務所有權。

Remote model 必須保留這些產品語意：

- `assigned_to` / `assigned_to_user_id` 只是提示，不是權限限制。
- `completed_by` / `completed_by_user_id` 是事實紀錄，不應被 later completion overwrite。
- Resource 使用 event history；current value 是 projection，不是唯一事實來源。
- Stage 使用 per-user acknowledgement，不使用 `completed_by`。
- Activity log 是 remote Shared Pack 的核心資料，不只是 UI 裝飾。

## 3. Identity Model

現有 local identity：

```text
local app_user_id = stable GUID
remote_user_id = nullable
remote_provider = nullable
identity_kind = local / anonymous_remote / linked / placeholder / removed
```

Supabase remote identity：

```text
auth.uid() = Supabase Auth user id
```

核心規則：

- 本機 `local_users.id` 不會被 Supabase Auth uid 取代。
- 本機 `local_users.remote_user_id` 對應 Supabase `auth.users.id`。
- Supabase remote tables 不依賴 local GUID 作為權限身份。
- 權限身份必須以 `auth.uid()` / remote user id 為準。
- 本機 local GUID 可用於 client mapping、backup 與 local history。
- Remote membership 使用 Supabase Auth user id。
- Activity event 可保存 `actor_display_name_snapshot`，讓 removed / deleted user 仍可在歷史紀錄中被理解。

```text
Local app_user_id is a client-side stable identity.
Remote user_id is the server-trusted identity.
They must be linked, not merged.
```

## 4. Anonymous Remote Identity

Phase 3B 使用 Supabase anonymous auth 建立 remote identity，讓使用者在不綁 Apple / Google / Email 的情況下取得 server-recognized user id。

規則：

- Anonymous remote user 可成為 Shared Pack host / member。
- 使用者仍不需要立即綁 Apple / Google / Email。
- Anonymous remote identity 不等同 Apple / Google / Email 綁定保護；換機、sign out 或 reinstall 後可能遺失同一 remote identity。
- UI 應將 Apple / Google / Email 稱為「保護資料」而不是強制登入。
- Apple / Google / Email binding 是後續資料保護能力，不是建立 Shared Pack 的前置條件。
- Local GUID 不是 server credential；Supabase Auth uid 才是 server-trusted identity。
- Phase 3B 不建立 remote profile、remote pack、remote member 或 remote item。

## 5. Remote Entity Scope

Supabase DB 本身就是 remote context，因此 Phase 3A table name 不使用 `remote_` prefix。

Remote table scope：

```text
profiles
packs
pack_members
items
item_completions
resources
resource_events
stages
stage_acknowledgements
activity_events
```

Phase 3A 同時建議未來 local POC 使用 client-side mapping table：

```text
sync_mappings
```

`sync_mappings` 屬於 local sync layer 設計，不是 Supabase remote shared data table。

## 6. Remote ID Strategy

### Option A：在 local tables 加 `remote_id`

優點：

- 查詢直觀。
- 每個 entity 自己知道 remote counterpart。

缺點：

- 需要修改多張 local tables。
- local schema 會過早貼近 sync layer。
- 對 Phase 3 POC 侵入較高。

### Option B：建立通用 `sync_mappings` table

建議 local mapping：

```text
sync_mappings
- id
- local_entity_type
- local_entity_id
- remote_table
- remote_entity_id
- sync_state
- last_pushed_at
- last_pulled_at
- created_at
- updated_at
```

優點：

- 對 local domain schema 侵入較小。
- 適合 Phase 3 POC。
- 可逐步支援更多 entity，不必一次改完所有 local tables。

缺點：

- 查詢需要 join / lookup。
- 長期大量 sync 後可能需要優化或在特定 table 加 projection 欄位。

Phase 3A 建議採用 Option B：Phase 3B / 3C 先用 `sync_mappings` 作為 POC mapping，不立刻把 `remote_id` 加到所有 local domain tables。

## 7. Remote Table Drafts

### 7.1 `profiles`

Purpose：保存 Supabase user profile / display info，不取代 Supabase `auth.users`。

```text
id uuid primary key references auth.users(id)
display_name text
avatar_url text null
identity_kind text
created_at timestamptz
updated_at timestamptz
deleted_at timestamptz null
```

`profiles.id` 必須等於 `auth.uid()`。`identity_kind` 可對應 anonymous / linked / removed 等 display state，但權限仍以 Supabase Auth session 為準。

### 7.2 `packs`

Purpose：remote Shared Pack root。Remote DB 只保存 remote shared packs，Personal Pack 不應自動上傳。

```text
id uuid primary key
name text
description text null
pack_type text
host_user_id uuid references profiles(id)
status text
created_at timestamptz
updated_at timestamptz
archived_at timestamptz null
deleted_at timestamptz null
```

規則：

- Phase 3 remote packs 只接受 `pack_type = shared`。
- `host_user_id` 必須是 pack active host member。
- Destructive actions 應使用 soft delete / archive。
- 建立 pack + host member 建議透過 RPC，避免 root row 與 membership row 不一致。

### 7.3 `pack_members`

Purpose：remote pack membership 與 RLS 核心。

```text
id uuid primary key
pack_id uuid references packs(id)
user_id uuid references profiles(id)
role text
status text
joined_at timestamptz
removed_at timestamptz null
created_at timestamptz
updated_at timestamptz
```

角色：

```text
host
member
viewer
```

Phase 3 最少使用：

```text
host
member
```

Status：

```text
active
removed
```

規則：

- Removed member 不刪 row，歷史仍可追溯。
- Active member 才可讀寫 pack data。
- Viewer role 是否可寫入 item / resource / stage 標記為 future。

### 7.4 `items`

Purpose：remote Shared Pack item。

```text
id uuid primary key
pack_id uuid references packs(id)
title text
note text null
status text
assigned_to_user_id uuid null references profiles(id)
created_by_user_id uuid references profiles(id)
updated_by_user_id uuid references profiles(id)
created_at timestamptz
updated_at timestamptz
archived_at timestamptz null
deleted_at timestamptz null
```

規則：

- `assigned_to_user_id` 只是提示。
- Completion state 由 current active `item_completions` 推導。
- Phase 3A 不使用 `current_completion_id` projection；若未來查詢效能需要，可在 SQL view 或 projection 欄位中補上。

### 7.5 `item_completions`

Purpose：remote item completion fact/history。

```text
id uuid primary key
pack_id uuid references packs(id)
item_id uuid references items(id)
completed_by_user_id uuid references profiles(id)
completed_at timestamptz
undone_by_user_id uuid null references profiles(id)
undone_at timestamptz null
client_mutation_id text null
created_at timestamptz
```

規則：

- Active completion = `undone_at is null`。
- First-write-wins：同一 item 同一時間只能有一個 active completion。
- Remote enforcement 使用 partial unique index：

```sql
create unique index one_active_completion_per_item
on item_completions(item_id)
where undone_at is null;
```

- Undo 不刪除 completion。
- Undo 採用與 local 一致的方式：更新 active completion 的 `undone_by_user_id / undone_at`，並由 `activity_events` 記錄 undo action。
- 不可覆寫 `completed_by_user_id`。

### 7.6 `resources`

Purpose：remote pack resource current projection。

```text
id uuid primary key
pack_id uuid references packs(id)
name text
current_value numeric null
unit text null
warning_threshold numeric null
danger_threshold numeric null
created_by_user_id uuid references profiles(id)
updated_by_user_id uuid references profiles(id)
created_at timestamptz
updated_at timestamptz
archived_at timestamptz null
deleted_at timestamptz null
```

`resources.current_value` 是 projection；事實變更需要寫入 `resource_events`。

### 7.7 `resource_events`

Purpose：resource history / delta / adjust records。

```text
id uuid primary key
pack_id uuid references packs(id)
resource_id uuid references resources(id)
actor_user_id uuid references profiles(id)
change_type text
previous_value numeric null
new_value numeric null
delta_value numeric null
unit text null
base_version integer null
created_at timestamptz
metadata jsonb null
```

`change_type`：

```text
adjust
increment
decrement
```

規則：

- `increment` / `decrement` 是未來可合併的 delta operation。
- `adjust` 是 absolute adjustment，未來 sync 時需要 `base_version` 或 `updated_at` check。
- Phase 3A 只設計，不做完整 conflict resolution。

### 7.8 `stages`

Purpose：remote pack stage / context marker。

```text
id uuid primary key
pack_id uuid references packs(id)
title text
description text null
status text
order_index integer
created_by_user_id uuid references profiles(id)
updated_by_user_id uuid references profiles(id)
created_at timestamptz
updated_at timestamptz
closed_at timestamptz null
deleted_at timestamptz null
```

`status`：

```text
upcoming
active
closed
```

Stage 禁止使用：

```text
completed_by_user_id
completed_at
```

### 7.9 `stage_acknowledgements`

Purpose：per-user acknowledgement / 「知道了」。

```text
id uuid primary key
pack_id uuid references packs(id)
stage_id uuid references stages(id)
user_id uuid references profiles(id)
acknowledged_at timestamptz
created_at timestamptz
updated_at timestamptz
```

規則：

- Unique `(stage_id, user_id)`。
- Repeated acknowledge 更新 `acknowledged_at`，視為 idempotent upsert。
- Acknowledge 不會 close stage。
- Acknowledge 不代表 stage completed。

### 7.10 `activity_events`

Purpose：shared pack transparent activity history。

```text
id uuid primary key
pack_id uuid references packs(id)
actor_user_id uuid null references profiles(id)
actor_display_name_snapshot text null
entity_type text
entity_id uuid
action text
before_json jsonb null
after_json jsonb null
metadata_json jsonb null
created_at timestamptz
```

規則：

- `actor_user_id` 一般應等於 `auth.uid()`。
- System actor 需要明確在 `metadata_json` 標示。
- Activity event 不應由 UI 任意偽造。
- Phase 3A 建議 event 寫入由 server RPC / repository controlled path 管理。
- `actor_display_name_snapshot` 用於日後 removed / deleted user history display。

## 8. RLS Policy Draft

RLS 是 Phase 3A schema 的核心，不是事後補充。所有 exposed Supabase tables 必須 enable RLS。

### 8.1 Helper Functions

建議 helper：

```sql
create or replace function public.is_pack_member(target_pack_id uuid)
returns boolean
language sql
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.pack_members pm
    where pm.pack_id = target_pack_id
      and pm.user_id = auth.uid()
      and pm.status = 'active'
  );
$$;
```

```sql
create or replace function public.is_pack_host(target_pack_id uuid)
returns boolean
language sql
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.pack_members pm
    where pm.pack_id = target_pack_id
      and pm.user_id = auth.uid()
      and pm.role = 'host'
      and pm.status = 'active'
  );
$$;
```

Review risk：

- `security definer` 可避免 helper function 被 `pack_members` 自身 RLS recursion 阻擋。
- Function owner、search path、grant 權限需要在 Supabase SQL editor / local Supabase CLI 實測。
- Helper function 不應暴露繞過 RLS 的任意查詢能力，只回傳 boolean。

### 8.2 `profiles` RLS

- User 可 select 自己 profile。
- Pack member 可 select 同 pack 其他 member 的基本 profile。
- User 只能 update 自己 profile。
- Insert profile 只允許 `auth.uid() = id`。

### 8.3 `packs` RLS

- Active pack member 可 select pack。
- Authenticated user 可 insert `shared` pack，`host_user_id` 必須等於 `auth.uid()`。
- Host 可 update pack settings / archive。
- Member 不可 delete pack。
- Hard delete 不建議開放。
- 建立 pack 與 host membership 若不能用 simple policy 保證一致，應改用 RPC `create_shared_pack`。

### 8.4 `pack_members` RLS

- Active pack member 可 select 同 pack members。
- Host 可 insert / update member status / role。
- Removed member 不可 update pack data。
- Hard delete 不開放。
- User 自己建立 host membership 僅應發生在 pack creation transaction；Phase 3A 建議用 RPC 保證。

### 8.5 `items` RLS

- Active pack member 可 select items。
- Active pack member 可 insert item。
- Active pack member 可 update non-destructive fields。
- Member 不可 hard delete item。
- Host 可 soft delete / archive。
- `assigned_to_user_id` 不限制 completion 權限。

### 8.6 `item_completions` RLS

- Active pack member 可 select completions。
- Active pack member 可 insert completion if item is in same pack。
- Insert `completed_by_user_id` 必須等於 `auth.uid()`。
- Active pack member 可 undo active completion by setting `undone_by_user_id = auth.uid()` and `undone_at = now()`。
- 不可覆寫 `completed_by_user_id`。
- 不可 hard delete completion。
- One active completion per item 由 partial unique index 保證。

### 8.7 `resources` / `resource_events` RLS

- Active pack member 可 select resources / events。
- Active pack member 可 update resource current value via controlled operation。
- `resource_events` insert `actor_user_id` 必須等於 `auth.uid()`。
- 不可 hard delete `resource_events`。
- Resource current value update 與 `resource_event` insert 應考慮用 RPC 保持 transaction。

### 8.8 `stages` / `stage_acknowledgements` RLS

- Active pack member 可 select stages。
- Active pack member 可 acknowledge stage。
- `stage_acknowledgements.user_id` 必須等於 `auth.uid()`。
- Unique `(stage_id, user_id)`。
- Acknowledge 不 close stage。
- Stage 不可 complete。

### 8.9 `activity_events` RLS

- Active pack member 可 select activity events。
- Insert activity events 不應由任意 client 隨便寫。

兩種方案：

1. Client repository controlled insert：Phase 3 POC 較快，但信任 client 產生 event，風險較高。
2. Server RPC / trigger controlled insert：transaction consistency 較好，長期較安全。

Phase 3A 建議：Phase 3 POC 可暫用 repository controlled insert，但長期應改為 RPC / transaction controlled path。

## 9. RPC / Transaction Draft

未來 Phase 3C 可能需要的 RPC：

```text
create_shared_pack(name, client_pack_id?)
complete_item(item_id, client_mutation_id?)
undo_item_completion(completion_id)
adjust_resource(resource_id, new_value, base_version?)
increment_resource(resource_id, delta)
acknowledge_stage(stage_id)
```

適合 RPC 的操作：

- Create pack + host member + activity event。
- Complete item + activity event。
- Undo completion + activity event。
- Resource current value update + resource_event + activity_event。
- Stage acknowledgement + activity_event。

原因：

```text
需要 transaction consistency，避免 current state 與 history/event 分離。
```

## 10. Phase 3C Minimal POC Scope

最小 POC：

1. Supabase anonymous auth。
2. Link local user `remote_user_id`。
3. Create remote profile。
4. Create remote shared pack。
5. Create host pack member。
6. Push minimal items。
7. Complete item remotely。
8. Pull remote pack snapshot。
9. Verify non-member cannot read/write through RLS。

暫不包含：

- Full two-way sync。
- Realtime。
- Invite code。
- Resource conflict merge。
- Stage workflow。
- Push notification。
- Apple / Google / Email binding。

## 11. Security Notes

- All exposed Supabase tables must have RLS enabled。
- Remote pack data must not rely on client-side checks only。
- `auth.uid()` is the server-trusted user identity。
- Local GUID is not a security credential。
- Anon key is not secret；RLS must protect data。
- No auth tokens in backup。
- Removed members retain history but lose write access。
- Activity events need controlled write path。
- Hard delete should be avoided for shared history。

## 12. Open Questions

1. 是否用 RPC 作為所有 shared mutations 的唯一入口？
2. Phase 3C 是否只做 items，resource / stage 延後？
3. Remote id mapping 是否長期維持 `sync_mappings`，或在成熟後為高頻 table 加 `remote_id` projection？
4. `profiles.display_name` 初始值如何產生？
5. Removed / deleted user 顯示「已移除成員」的實際規則。
6. 是否需要 viewer role？
7. Pack host 轉移是否 Phase 3 需要？
8. Activity event 是否用 trigger 自動產生？
9. Resource adjust 的 `base_version` 採 integer version 還是 `updated_at`？
10. 是否用 Supabase local development CLI 驗證 SQL / RLS？

## 13. Phase 3B Manual Test

Phase 3B 只測試 anonymous auth identity bridge，不測 remote pack / sync。

Run with anon key only：

```bash
flutter run \
  --dart-define=SUPABASE_URL=... \
  --dart-define=SUPABASE_ANON_KEY=...
```

Manual flow：

1. 打開 app。
2. 進入 Settings developer debug 區。
3. 查看「此裝置資料」。
4. 按「建立匿名遠端身份」。
5. 確認 `identity_kind` 變成 `anonymous_remote`。
6. 確認 `remote_provider = supabase_anonymous`。
7. 確認 local user id 不變。
8. 關閉重開 app 後，確認 local identity 仍存在。
9. 確認沒有任何 pack 被自動上傳。

Security reminder：

```text
請勿把 service role key 放入 Flutter app。
只可使用 anon key。
```

## 14. Phase 3C Implementation Notes

Phase 3C implements a Remote Shared Pack Minimal POC. It is developer-triggered repository behavior, not automatic sync.

Scope：

```text
local shared pack
-> ensure anonymous remote identity
-> ensure remote profile
-> create remote shared pack
-> create host pack member
-> push minimal items
-> complete remote item
-> pull remote pack snapshot
```

SQL draft：

- `docs/core/sql/phase3c_supabase_minimal_poc.sql`
- This file narrows the Phase 3A draft to `profiles / packs / pack_members / items / item_completions / activity_events` only.
- It includes RLS enable statements, `is_pack_member`, `is_pack_host`, and the Phase 3C RPC functions.
- It intentionally does not create runtime dependencies on `resources`, `resource_events`, `stages`, or `stage_acknowledgements`.

Runtime repository boundary：

- `RemoteSharedPackRepository.ensureRemoteProfile()` uses `ensureAnonymousRemoteIdentity()` and RPC `upsert_current_profile`.
- `createRemoteSharedPackFromLocalPack(localPackId)` requires a local Shared Pack and active local pack membership, then calls RPC `create_shared_pack`.
- `pushMinimalItems(localPackId)` only pushes unmapped active / paused local items in the mapped pack through RPC `create_pack_item`.
- `completeRemoteItemForLocalItem(localItemId)` calls RPC `complete_pack_item`; remote `already_completed` is surfaced as a typed result and does not overwrite local completion history.
- `pullRemotePackSnapshot(remotePackId)` reads remote pack, members, items, active completions, and activity events into DTOs only; it does not merge into local DB.

Local mapping strategy：

- Phase 3C implements local `sync_mappings` instead of adding `remote_id` to every local table.
- Used mappings:
  - `pack -> packs`
  - `item -> items`
- `profiles` are not mapped through `sync_mappings`; `local_users.remoteUserId` stores the Supabase Auth user id reference.
- Backup schema v4 may include `syncMapping` relation rows as references only. Restore does not prove remote access and must not auto pull or push.

Explicit exclusions：

- No full two-way sync.
- No realtime / Postgres Changes.
- No invite code, invite link, or QR invite.
- No resource or stage remote sync.
- No background sync.
- No startup auto-upload.
- No automatic personal pack upload.
- No formal sync UI or pack selector UI.
- No access token, refresh token, session JSON, OAuth credential, service role key, or secret key in backup.

## 15. Phase 3C Manual Setup And Smoke Test

Manual setup：

1. Enable anonymous sign-ins in the Supabase project.
2. Manually apply `docs/core/sql/phase3c_supabase_minimal_poc.sql` in the Supabase SQL editor or local Supabase CLI.
3. Confirm RLS is enabled on `profiles`, `packs`, `pack_members`, `items`, `item_completions`, and `activity_events`.
4. Run Flutter with anon key only:

```bash
flutter run \
  --dart-define=SUPABASE_URL=... \
  --dart-define=SUPABASE_ANON_KEY=...
```

Security reminders：

- Do not use service role key in Flutter.
- Do not hardcode Supabase URL or anon key.
- Do not auto-apply SQL to production.

Manual POC flow：

1. 打開 app。
2. Settings developer debug 區建立匿名遠端身份。
3. 使用 repository / developer harness 確認 remote profile。
4. 選一個 local Shared Pack。
5. 執行 create remote shared pack POC。
6. 執行 push minimal items POC。
7. 在 Supabase dashboard 確認 `packs / pack_members / items / activity_events`。
8. 對其中一個 remote item 執行 complete remote item POC。
9. 確認 `item_completions` 有 active completion。
10. 再次 complete 同一 item，應回傳 `already_completed`，且不覆寫 `completed_by_user_id`。
11. 拉取 remote pack snapshot。
12. 確認沒有 resource / stage 被上傳。
13. 確認沒有 personal pack 被自動上傳。

RLS smoke test：

1. 使用另一個 anonymous user、clean install 或 second test device。
2. 嘗試讀取不是 member 的 remote pack id。
3. 應被 RLS 擋下。
4. 嘗試 complete 不是 member 的 item。
5. 應被 RLS 擋下。

Known risks / open questions：

- Phase 3C SQL is still a draft and must be manually verified before production use.
- Activity event writes are repository/RPC controlled for POC; long term should prefer stricter RPC/trigger-only shared mutation paths.
- Remote undo, invite/member onboarding, resource sync, stage acknowledgement sync, and full conflict handling remain later phases.

## 16. Phase 3D Manual Smoke Test

Phase 3D adds a developer-only Settings surface for manually exercising the Phase 3C Remote Shared Pack POC against a Supabase dev project. It is not production sync UI.

Developer UI scope：

- Shows Supabase config status, identity kind, short local user id, remote provider, short remote user id.
- Uses the first active local Shared Pack as the POC target.
- Shows remote pack mapping status, short remote pack id, last operation result, and latest remote snapshot summary.
- Stores last operation state only in provider / UI memory; it is not persisted.

Manual actions：

1. 建立匿名遠端身份。
2. 建立 / 確認 Remote Profile。
3. 建立遠端共同 Pack POC。
4. 推送 Minimal Items POC。
5. 完成遠端 Item POC。
6. 拉取 Remote Snapshot POC。

Rules：

- No app startup auto upload.
- No automatic personal pack upload.
- No automatic shared pack upload.
- No automatic push / pull.
- No remote snapshot merge into local DB.
- No local completion update from remote completion.
- No invite, realtime, resource sync, stage sync, or conflict engine.

### Supabase Setup

1. 建立 Supabase dev project。
2. 啟用 Anonymous Sign-ins。
3. 在 SQL editor 手動 apply `docs/core/sql/phase3c_supabase_minimal_poc.sql`。
4. 確認 RLS enabled。
5. 只使用 anon key。
6. 不要把 service role key 放入 Flutter app。

### Flutter Run

```bash
flutter run \
  --dart-define=SUPABASE_URL=... \
  --dart-define=SUPABASE_ANON_KEY=...
```

### App Manual Test

1. 打開 app。
2. 建立或準備一個 local shared pack。
3. 進入 Settings developer debug。
4. 確認 Supabase config status = configured。
5. 按「建立匿名遠端身份」。
6. 確認 `identity_kind = anonymous_remote`。
7. 按「建立 / 確認 Remote Profile」。
8. 確認 UI 顯示 local shared pack。
9. 按「建立遠端共同 Pack POC」。
10. 按「推送 Minimal Items POC」。
11. 在 Supabase dashboard 查看 `profiles / packs / pack_members / items / activity_events`。
12. 按「完成遠端 Item POC」。
13. 確認 `item_completions` 出現 active completion。
14. 再按一次完成同一 item，應顯示 already completed，不覆寫 `completed_by_user_id`。
15. 按「拉取 Remote Snapshot POC」。
16. 確認 snapshot 摘要顯示 members / items / completions / activity events。
17. 確認沒有 resources / stages 被上傳。
18. 確認沒有 personal pack 被自動上傳。

### RLS Manual Smoke Test

1. 使用另一部測試裝置 / simulator / clean install / 清除 app data。
2. 使用同一 Supabase project，但產生新的 anonymous remote identity。
3. 不加入原本 remote pack。
4. 嘗試透過 debug / manual SQL / controlled query 讀取原 remote pack。
5. 預期被 RLS 擋下。
6. 嘗試 complete 不是 member 的 item。
7. 預期被 RLS 擋下。

If the app debug UI does not expose a non-member query action, use Supabase SQL editor, REST client, or a temporary test harness to verify the RLS boundary.

### Known Limitations

- Phase 3D is not production sync.
- Remote snapshot does not merge into local DB.
- Remote completion does not update local completion history.
- No invite flow.
- No realtime.
- No resource / stage remote sync.
- No conflict engine.
- POC actions are developer/debug only.

Phase 4 boundary：formal sync UX, invite/member onboarding, realtime, resource/stage sync, and conflict resolution remain future work.

## 17. Phase 4A Remote Invite Code & Membership MVP

Phase 4A adds the first remote collaboration membership loop:

```text
host creates invite code
→ member enters invite code
→ member joins remote pack
→ member pulls remote snapshot
→ member completes remote item
```

It remains a developer/debug POC, not production invite UI or full sync.

### Scope

- Invite code first; no email invite, QR code, magic link, Apple / Google / email binding, or remote pack list.
- Invite defaults are fixed: 7 days, max uses 10, role grant `member`.
- Joined user becomes `member / active`.
- Member can read remote pack snapshot and complete remote item through existing RLS/RPC boundaries.
- No local pack, local item, sync mapping, or local merge is created when joining.

### SQL Draft

Apply after Phase 3C SQL:

```text
docs/core/sql/phase4a_supabase_invite_membership_mvp.sql
```

The Phase 4A SQL adds:

- `pack_invites`
- `create_pack_invite`
- `join_pack_with_invite`
- `revoke_pack_invite`
- RLS policy draft for host-only invite listing/management

Invite code is a temporary bearer secret. Codes are 6 uppercase human-friendly characters from `ABCDEFGHJKLMNPQRSTUVWXYZ23456789`. Remote `pack_invites` stores a host-readable `invite_code` for active invite recovery plus `code_hash` for join lookup. Activity events, local backups, local DB, and sync metadata must not store the full invite code.

Hash strategy:

```text
code_hash = sha256(normalized_invite_code || ':' || pack_id)
```

For join, the RPC normalizes input by trimming, uppercasing, and removing whitespace / hyphen-like separators, then scans active invite rows and compares the computed hash for each invite pack. This keeps the user-facing input to only the invite code for Phase 4A.

### RPC Behavior

- `ensure_active_pack_invite(target_pack_id, expires_in_days default 7, max_uses default 10)` requires `auth.uid()` to be active host of the pack, expires stale active invites, returns the existing active invite if present, otherwise inserts invite metadata, writes `invite_created`, and returns `invite_id / invite_code / expires_at / max_uses`.
- `fetch_pack_invite_state(target_pack_id)` requires active host and returns the current active invite plus whether the latest invite is expired.
- `refresh_pack_invite(target_pack_id, expires_in_days default 7, max_uses default 10)` requires active host, revokes active invites, writes `invite_revoked`, creates a new invite, and returns the new invite.
- `create_pack_invite(target_pack_id, expires_in_days default 7, max_uses default 10)` remains a compatibility wrapper for `ensure_active_pack_invite`.
- `join_pack_with_invite(invite_code)` validates active/unexpired/under-limit invite, requires current profile, creates or reactivates `pack_members` as `member / active`, increments `used_count`, writes `member_joined`, and returns `joined` or `already_member`.
- `revoke_pack_invite(invite_id)` requires active host, marks invite revoked, writes `invite_revoked`, and never hard-deletes invite history.

Security-definer functions must be reviewed before production. They must validate host or invite state before writing `pack_invites` or `pack_members`.

### Developer UI

Settings developer debug `Supabase 遠端 POC` adds:

- `建立 Invite Code POC`
- volatile invite code / expiry / max-use display
- `輸入 Invite Code`
- `加入遠端 Pack POC`
- joined remote pack id display
- snapshot pull using joined remote pack id when present, otherwise local shared pack mapping
- `完成 Snapshot 第一個 Remote Item POC`

The invite code, joined remote pack id, and latest snapshot are provider/UI memory only. They are cleared by app restart and are not written to backup.

### Manual Smoke Test

Supabase setup:

1. 啟用 Anonymous Sign-ins。
2. Apply `docs/core/sql/phase3c_supabase_minimal_poc.sql`。
3. Apply `docs/core/sql/phase4a_supabase_invite_membership_mvp.sql`。
4. 確認 RLS enabled。
5. Flutter app 只使用 anon key；do not put privileged keys in the app.

Host device:

1. Device A / simulator A runs with `SUPABASE_URL` and `SUPABASE_ANON_KEY`.
2. 建立匿名遠端身份。
3. 建立 / 確認 Remote Profile。
4. 準備 local Shared Pack。
5. 建立遠端共同 Pack POC。
6. 推送 Minimal Items POC。
7. 建立 Invite Code POC。
8. 記下 invite code。

Member device:

1. Device B / clean install uses the same Supabase dev project.
2. 建立匿名遠端身份。
3. 建立 / 確認 Remote Profile。
4. 輸入 invite code。
5. 按「加入遠端 Pack POC」。
6. 拉取 Remote Snapshot。
7. 應看到 remote pack / items / activity events。
8. 完成 Snapshot 第一個 Remote Item POC。
9. 再拉取 Snapshot。
10. 應看到 item completion / activity event。

RLS smoke test:

1. 使用第三個 anonymous user。
2. 不輸入 invite code。
3. 嘗試讀取原 remote pack 或 complete 原 pack item。
4. 預期被 RLS 擋下。

Expected boundaries:

- No local pack or item is auto-created.
- Remote snapshot is not merged into local DB.
- Personal packs are not uploaded.
- Resources and stages are not uploaded.
- No realtime, background sync, production invite UI, or conflict engine.

### Follow-Up Boundary

- Phase 4B: developer-only remote snapshot viewer with manual refresh.
- Phase 4C: remote member actions / local import boundary design.
- Phase 4D: realtime soft notification or stronger remote collaboration hardening.

## 18. Phase 4B Remote Pack Viewer MVP

Phase 4B upgrades the Phase 4A snapshot summary into a developer-only Remote Pack Viewer inside Settings `Supabase 遠端 POC`.

It is a viewer MVP, not remote sync. It never writes the pulled snapshot into the local Drift database.

### Product Scope

- Display the currently pulled remote pack snapshot in a readable form.
- Support host flow through local Shared Pack mapping.
- Support member flow through joined remote pack id from invite join.
- Support manual refresh only.
- Keep the surface inside developer/debug Settings; no production remote pack screen.

### Target Strategy

The viewer uses automatic target priority:

1. `joinedRemotePackId` from Phase 4A invite join.
2. First local active Shared Pack remote mapping (`sync_mappings(pack -> packs)`).

The target state is volatile provider/UI state. It is not written to local DB or backup.

### Displayed Snapshot Fields

Pack:

- name
- remote pack id short code
- host user id short code
- status
- created / updated timestamp

Members:

- display name when available
- user id short code fallback
- role
- status

Items:

- title
- short note summary
- status
- assigned user id short code when present
- active completion state
- completed by user id short code and completed timestamp when completed

Activity:

- recent activity events, capped in Settings to keep the debug surface compact
- action
- entity type
- actor display snapshot or actor id short code
- created timestamp

The viewer does not show full JSON diffs, invite code values, tokens, credentials, or secrets.

### Manual Refresh Only

`刷新遠端 Snapshot` calls `pullRemotePackSnapshot(remotePackId)` and updates volatile provider state:

- `lastPulledRemoteSnapshot`
- target type
- last refresh timestamp
- last refresh success/failure

Refresh does not:

- create local pack
- create local items
- create `sync_mappings`
- create local completions
- merge remote completion facts into local history
- schedule background refresh
- subscribe to realtime

### Error States

Developer UI should map typed failures into gentle messages:

- Supabase 尚未設定
- 尚未建立匿名遠端身份
- 尚未有可讀取的遠端 Pack
- 遠端 Pack 不存在或你不是 member
- 遠端資料被 RLS 拒絕
- 網絡連線失敗
- 拉取 Snapshot 失敗

### Phase 4B Manual Smoke Test

Supabase setup:

1. 啟用 Anonymous Sign-ins。
2. Apply `docs/core/sql/phase3c_supabase_minimal_poc.sql`。
3. Apply `docs/core/sql/phase4a_supabase_invite_membership_mvp.sql`。
4. 確認 RLS enabled。
5. 只使用 anon key。
6. 不使用 service role key。

Host flow:

1. 使用 Device A / simulator A。
2. 建立 anonymous remote identity。
3. 建立 Remote Profile。
4. 準備 local Shared Pack。
5. 建立 remote pack POC。
6. 推送 Minimal Items。
7. 建立 Invite Code。
8. 按「刷新遠端 Snapshot」。
9. Viewer 應顯示 pack / members / items / activity。

Member flow:

1. 使用 Device B / simulator B / clean install。
2. 建立 anonymous remote identity。
3. 建立 Remote Profile。
4. 輸入 invite code。
5. 加入 remote pack。
6. 按「刷新遠端 Snapshot」。
7. Viewer 應顯示 pack / members / items / activity。
8. 完成 Snapshot 第一個 Remote Item POC。
9. 再按「刷新遠端 Snapshot」。
10. Viewer 應顯示 completion state / completed_by / completed_at / activity event。

Non-member RLS check:

1. 使用 Device C / clean install。
2. 建立 anonymous remote identity。
3. 不加入 invite。
4. 嘗試用同一 remote pack id 拉 snapshot。
5. 預期被 RLS 擋下。

Expected boundaries:

- 沒有 local pack 被自動建立。
- 沒有 local item 被自動建立。
- Remote snapshot 不 merge local DB。
- Personal pack 不上傳。
- Resources / stages 不上傳。
- 沒有 realtime。
- 沒有 background sync。
- 只有手動 refresh。

### Known Limitations

- Viewer is a developer surface, not a production remote pack UI.
- No remote pack list exists yet.
- No manual remote pack id selector is implemented.
- No member management is implemented.
- No local import / merge policy is implemented.

### Follow-Up Boundary

- Phase 4C can define remote member actions in the developer viewer.
- Phase 4D can explore realtime soft notification or stronger RLS/RPC audit hardening.
- Production remote pack UX remains out of scope until sync and merge rules are designed.

## 19. Phase 4C Remote Member Actions MVP

Phase 4C adds developer-only selected item actions to the Remote Pack Snapshot viewer:

```text
remote snapshot viewer
→ select remote item
→ complete selected remote item
→ undo selected active completion
→ manual refresh
→ viewer shows completed_by / undone activity
```

It is not full sync, realtime, local merge, or production item operation UI.

### Product Scope

- Active remote pack members can complete selected remote items.
- Active remote pack members can undo selected active completions.
- `assigned_to_user_id` remains a hint and does not restrict completion.
- `completed_by_user_id` is factual and must not be overwritten.
- Undo records `undone_by_user_id` and `undone_at`; it does not delete the completion row.
- `activity_events` remain the transparent shared history surface.

### SQL / RPC

Phase 4C SQL is an incremental manual draft:

```text
docs/core/sql/phase4c_supabase_remote_member_actions_mvp.sql
```

Apply it after Phase 3C and Phase 4A SQL.

The SQL adds:

- `undo_pack_item_completion(target_item_id uuid, client_mutation_id text default null)`
- return status `undone` or `already_not_completed`
- active member verification through `is_pack_member`
- `auth.uid()` as the undo actor
- update of `item_completions.undone_by_user_id / undone_at`
- `activity_events(action = item_undone)`

Phase 3C `complete_pack_item` remains the complete path. It already checks active membership, uses `auth.uid()`, returns `already_completed` for active completion, and relies on the partial unique index for first-write-wins.

Direct client update/delete of `item_completions` is not part of the app runtime path. Complete and undo should stay RPC-controlled.

### Viewer State And Actions

The Settings developer viewer keeps selected item state in volatile provider memory:

- selected remote item id
- selected item title
- active completion id
- completed_by user id
- completed_at

Manual refresh preserves selected item if it still exists in the refreshed snapshot. If the selected item is missing, selection is cleared.

Actions:

- `完成選擇的 Remote Item` calls `completeRemoteItemByRemoteId`.
- `復原選擇的 Remote Item` calls `undoRemoteItemByRemoteId`.
- Actions never write local DB and never create local pack, local item, local completion, or `sync_mappings`.
- Actions do not auto-refresh; users press `刷新遠端 Snapshot` to see remote state.

### Error States

Developer UI should map typed failures into gentle messages:

- Supabase 尚未設定
- 請先建立匿名遠端身份
- 尚未選擇 remote item
- 此 Remote Item 尚未完成
- Remote Item 已經完成，不覆寫完成者
- Remote Item 目前未完成，無需復原
- 遠端資料被 RLS 拒絕
- 網絡連線失敗
- 遠端操作失敗，請查看 debug log

### Phase 4C Manual Smoke Test

Supabase setup:

1. 啟用 Anonymous Sign-ins。
2. Apply `docs/core/sql/phase3c_supabase_minimal_poc.sql`。
3. Apply `docs/core/sql/phase4a_supabase_invite_membership_mvp.sql`。
4. Apply `docs/core/sql/phase4c_supabase_remote_member_actions_mvp.sql`。
5. 確認 RLS enabled。
6. 只使用 anon key。
7. 不使用 service role key。

Host flow:

1. 使用 Device A / simulator A。
2. 建立 anonymous remote identity。
3. 建立 Remote Profile。
4. 準備 local Shared Pack。
5. 建立 remote pack POC。
6. 推送 Minimal Items。
7. 建立 Invite Code。
8. 刷新 Remote Snapshot viewer。
9. 確認 items 顯示。

Member flow:

1. 使用 Device B / simulator B / clean install。
2. 建立 anonymous remote identity。
3. 建立 Remote Profile。
4. 輸入 invite code。
5. 加入 remote pack。
6. 刷新 Remote Snapshot viewer。
7. 選擇一個未完成 remote item。
8. 按「完成選擇的 Remote Item」。
9. 再刷新 Remote Snapshot。
10. Viewer 應顯示 completed_by = Device B remote user。
11. Activity 應顯示 `item_completed`。
12. 按「復原選擇的 Remote Item」。
13. 再刷新 Remote Snapshot。
14. Viewer 應顯示 item 回到未完成。
15. Activity 應顯示 `item_undone`。

Host verification:

1. Device A 刷新 Remote Snapshot。
2. 應看到 Device B 的 completed_by / `item_completed` activity。
3. Device B undo 後，Device A 再刷新。
4. 應看到 item 回到未完成，但 activity history 保留。

First-write-wins check:

1. Device A 和 Device B 選同一個未完成 item。
2. Device B 先 complete。
3. Device A 再 complete。
4. Device A 應收到 already completed。
5. completed_by 不應被 Device A 覆寫。

Non-member RLS check:

1. 使用 Device C / clean install。
2. 建立 anonymous remote identity。
3. 不加入 invite。
4. 嘗試拉 snapshot / complete item / undo item。
5. 預期被 RLS 擋下。

Expected boundaries:

- 沒有 local pack 被自動建立。
- 沒有 local item 被自動建立。
- Remote snapshot 不 merge local DB。
- Remote complete / undo 不改 local history。
- Personal pack 不上傳。
- Resources / stages 不上傳。
- 沒有 realtime。
- 沒有 background sync。
- 只有手動 refresh。

### Known Limitations

- The viewer is developer-only.
- No production remote item operation UI exists.
- No local import / merge policy exists.
- No realtime notification exists.
- No resource or stage remote actions exist.

### Follow-Up Boundary

- Phase 4D adds developer-only realtime soft notification.
- Phase 5 can design explicit local import / merge behavior if product scope requires it.

## 20. Phase 4D Realtime Soft Notification POC

Phase 4D adds developer-only realtime soft notification for the Remote Pack Snapshot viewer.

It is advisory only:

```text
remote pack has activity event
→ app receives realtime signal
→ viewer shows remote changes available
→ user manually refreshes snapshot
```

Realtime payload is not source of truth. Snapshot fetch remains the authoritative remote read path.

### Product Scope

- Listen for `activity_events` insert events for the current remote pack.
- Show a soft notification in Settings developer UI.
- Track volatile state: realtime status, target pack id, change count, last action, last actor, last received time, and error message.
- Clear remote-change notification after successful manual snapshot refresh.
- Keep all realtime state out of local DB and backup.

### Realtime Strategy

Phase 4D uses Supabase Postgres Changes on:

```text
public.activity_events
event: INSERT
filter: pack_id = current remote pack id
```

`activity_events` is used because it is the transparent shared-pack history surface. Complete, undo, invite, and member-join paths write activity events, so a single table is enough for soft notification.

Phase 4D does not use Broadcast or Presence.

### SQL / Setup Note

Manual setup file:

```text
docs/core/sql/phase4d_supabase_realtime_soft_notification_poc.sql
```

Apply after Phase 3C, Phase 4A, and Phase 4C SQL. The file adds `public.activity_events` to the Supabase Realtime publication.

Duplicate publication errors are safe to ignore in dev if the table is already enabled. Phase 4D listens to inserts only, so `REPLICA IDENTITY FULL` is intentionally not enabled.

### Subscription Lifecycle

- App startup does not subscribe.
- User explicitly presses `開始監聽遠端變更 POC`.
- No target means status remains disabled and no subscription is created.
- Duplicate subscribe for the same target is a no-op.
- Subscribe to a different target first removes the previous subscription.
- User can press `停止監聽遠端變更 POC`.
- Provider/controller dispose removes active subscription.
- Subscription errors set realtime status to error/unavailable and do not crash.

### Manual Refresh Rule

Realtime signal does not pull snapshot.

Successful `刷新遠端 Snapshot`:

- fetches snapshot through the existing repository path
- updates viewer snapshot state
- clears `hasRemoteChanges`
- resets change count
- keeps the active subscription

Refresh still does not merge local DB, create local pack/items, create completions, or create `sync_mappings`.

### Security / RLS Notes

- App uses only anon key.
- No service role key is stored in Flutter app.
- Realtime payload is advisory and should not be displayed as full JSON.
- Non-members should not receive pack activity signals when RLS / Realtime authorization is correctly configured.
- Even if a client receives a signal, snapshot read remains gated by RLS.
- Tokens, sessions, invite codes, and secrets are not stored in backup or realtime state.

### Phase 4D Manual Smoke Test

Supabase setup:

1. 啟用 Anonymous Sign-ins。
2. Apply `docs/core/sql/phase3c_supabase_minimal_poc.sql`。
3. Apply `docs/core/sql/phase4a_supabase_invite_membership_mvp.sql`。
4. Apply `docs/core/sql/phase4c_supabase_remote_member_actions_mvp.sql`。
5. Apply `docs/core/sql/phase4d_supabase_realtime_soft_notification_poc.sql`。
6. 確認 `activity_events` 已啟用 Realtime。
7. 確認 RLS enabled。
8. 只使用 anon key。
9. 不使用 service role key。

Device A / host flow:

1. 建立 anonymous remote identity。
2. 建立 Remote Profile。
3. 準備 local Shared Pack。
4. 建立 remote pack POC。
5. 推送 Minimal Items。
6. 建立 Invite Code。
7. 刷新 Remote Snapshot viewer。
8. 按「開始監聽遠端變更 POC」。
9. 確認 Realtime 狀態 = 已訂閱。

Device B / member flow:

1. Clean install / second simulator。
2. 建立 anonymous remote identity。
3. 建立 Remote Profile。
4. 輸入 invite code。
5. 加入 remote pack。
6. 刷新 Remote Snapshot viewer。
7. 選擇 remote item。
8. Complete selected remote item。

Expected Device A behavior:

1. Device A 不自動更新 item state。
2. Device A 顯示「遠端有新變更，請刷新 Snapshot」。
3. `remoteChangeCount` 增加。
4. Last action 顯示 `item_completed`。
5. Device A 按「刷新遠端 Snapshot」後才看到 completed_by。
6. Refresh 成功後 notification reset。

Undo check:

1. Device B undo selected remote item。
2. Device A 再次顯示 remote changes available。
3. Device A refresh 後看到 item 回到未完成。
4. Activity 保留 `item_completed` / `item_undone`。

Non-member RLS check:

1. Device C 建立 anonymous remote identity。
2. 不加入 invite。
3. 嘗試 subscribe 同一 remote pack activity events。
4. 預期不收到該 pack signal，或被 RLS / subscription error 擋下。
5. 嘗試 pull snapshot，應被 RLS 擋下。

Expected boundaries:

- Realtime event 不自動 refresh。
- Realtime event 不修改 local DB。
- Realtime event 不修改 viewer item state。
- 只有 manual refresh 重新拉 snapshot。
- 沒有 local pack / item 自動建立。
- Personal packs 不上傳。
- Resources / stages 不上傳。
- 沒有 background sync。

### Known Limitations

- Developer-only POC, not production realtime UI.
- No reconnect/backoff UX beyond Supabase client behavior.
- No unread activity inbox.
- No local import / merge.
- No resource or stage realtime signals.

### Follow-Up Boundary

- Phase 5 can decide whether remote snapshots ever become local imports.
- Production realtime design should review RLS, Realtime authorization, audit semantics, and notification UX separately.

## 21. Phase 4E Remote Collaboration Hardening

Phase 4E hardens the developer-only remote collaboration POC. It does not add new collaboration features.

Goal:

```text
Make the existing remote collaboration POC reliable.
```

### Product Scope

- Review Supabase SQL apply order and idempotency.
- Align RPC return shape with Flutter DTO parsing.
- Document RLS boundaries for members, non-members, removed members, invites, item completion, undo, and realtime activity signals.
- Harden realtime soft notification as advisory state only.
- Tighten developer debug UI friendly failure states.
- Provide an integrated manual smoke test and result log template.

### SQL Apply Order

Manual apply order for a Supabase dev project:

1. `docs/core/sql/phase3c_supabase_minimal_poc.sql`
2. `docs/core/sql/phase4a_supabase_invite_membership_mvp.sql`
3. `docs/core/sql/phase4c_supabase_remote_member_actions_mvp.sql`
4. `docs/core/sql/phase4d_supabase_realtime_soft_notification_poc.sql`
5. `docs/core/sql/phase4e_supabase_remote_collaboration_hardening.sql`
6. `docs/core/sql/phase_remote_grants_rls_repair.sql`

Phase 4E adds an idempotent Realtime publication setup guard for `public.activity_events`. It does not create new tables, resource sync, stage sync, local import, or production UI.

`phase_remote_grants_rls_repair.sql` is an idempotent manual repair patch for Supabase projects where RLS policies exist but the `authenticated` role is missing base table privileges or RPC execute grants. It does not create product features, does not disable RLS, does not grant table access to `anon`, and does not grant hard delete.

### Phase 5J.1 Email Account Binding

Phase 5J.1 adds production Email binding for the current anonymous Supabase session. It does not add SQL, tables, RPCs, RLS policies, provider secrets, Drift schema, or backup schema.

- Email binding uses Supabase Auth Email-change OTP, not Email sign-in. The app must not call `signInWithOtp` for binding because binding must preserve the existing anonymous remote user id.
- Start flow requires a current anonymous Supabase session linked to the local user. It sends the Email-change code with `updateUser(UserAttributes(email: ...))`.
- Verify flow calls `verifyOTP(type: emailChange)` with the Email and OTP code, then fails closed unless the current/returned Supabase UID equals the local `remote_user_id`, the user is no longer anonymous, and Email identity/confirmation can be inferred.
- On verified success, local account protection updates the existing `local_users` row to `identity_kind = linked` and `remote_provider = email`; local user ids, pack ids, item ids, completion actor ids, and activity actor ids are unchanged.
- Supabase Dashboard must enable Email auth and configure the Email change template to expose an OTP token such as `{{ .Token }}`. No deep link or callback is required for this MVP.
- The app never saves Email address, OTP code, access token, refresh token, session JSON, OAuth credential, service-role key, plaintext invite code, or magic-link token in Drift or backup.
- Email binding does not auto-run Phase 5K recovery, pull/import snapshots, flush/retry outbox, upload local-only packs, replay backup data, or create/join remote packs. It only makes the current remote identity recoverable for later explicit recovery.
- Production Apple and Google binding remain unsupported. Account switching, merge behavior, Email sign-in, magic-link login, and background recovery remain later work.

### Phase 5K Remote Membership Recovery

Phase 5K does not add Supabase SQL. It reuses existing `pack_members` RLS, `packs`, and snapshot reads so the current authenticated remote user can discover active remote pack memberships and restore local mirrors manually.

- Discovery queries `pack_members` for the current `auth.uid()`, filters active memberships, and returns only packs visible through existing RLS.
- Product/default recovery is gated by the local account-protection state: only linked/protected remote identities restore by default. Anonymous-unprotected, local-only, missing-session, unsupported, and unavailable states fail closed before discovery.
- Active membership + active pack status is the MVP restore eligibility. Archived/inactive packs are skipped for later optional management; removed members are not recoverable.
- Recovery pulls pack snapshots through the current Supabase session and imports them locally; it does not create memberships, join packs, grant access, upload local-only packs, replay `sync_outbox`, flush/retry outbox, or use service-role privileges.
- Repeated recovery is idempotent through existing `sync_mappings` and import behavior: missing mirrors are created, existing mirrors are refreshed, and duplicate local packs/items/completions/activity rows are not created.
- Backup restore remains local-only and never triggers membership discovery, snapshot pull, import, outbox replay, or remote access recovery. Recovery always depends on the current authenticated remote account, not the backup file.
- No realtime signal, app startup, backup import, widget/notification path, or outbox retry path auto-runs recovery. Phase 5K does not implement member freshness; Phase 5L adds pack-data freshness separately.

### Phase 5L Member Sync Awareness / Pack Freshness

Phase 5L adds a small Supabase SQL patch for per-member pack-data freshness. It stores the latest successful local snapshot import watermark for each active member and exposes RPCs for reporting/querying that state.

SQL file:

- `docs/core/sql/phase5l_member_sync_awareness_mvp.sql`

Remote state:

- `pack_member_sync_states` stores `pack_id`, `user_id`, `last_snapshot_pulled_at`, `last_imported_at`, `last_seen_activity_event_id`, `last_seen_activity_at`, optional sync error fields, and timestamps.
- `unique(pack_id, user_id)` keeps reports idempotent for the same member and pack.
- Latest pack activity is derived from `activity_events` using latest `created_at` plus latest event id. Phase 5L does not add a pack revision or activity sequence.

RPCs:

- `report_pack_snapshot_imported(target_pack_id, latest_activity_event_id, latest_activity_at)` verifies `auth.uid()` is an active member, upserts only the caller's own row, and records the supplied/imported activity watermark.
- `get_pack_member_freshness(target_pack_id)` verifies `auth.uid()` is an active member and returns active same-pack members with conservative statuses: `up_to_date`, `possibly_stale`, `no_sync_report`, or `access_unknown`.

RLS / privacy boundary:

- Active same-pack members can select active-member freshness rows.
- Active members can insert/update only their own sync-state row.
- Removed members and non-members cannot query or report pack freshness.
- The app uses the normal authenticated Supabase client and never requires service-role privileges.
- Freshness is defined as "this app successfully imported pack data"; it is not human attention, member monitoring, presence, or a background heartbeat.

Integration behavior:

- Phase 5H manual refresh reports only after successful safe local import. Failed imports and unsafe partial imports do not report.
- Phase 5K recovery restore reports after each successful imported/refreshed pack.
- Reporting failure is non-blocking and surfaces as `本機已更新，但未能回報同步狀態`; local import remains successful.
- App startup, realtime signals, backup restore, widget/notification summaries, and outbox retry/flush paths do not report freshness.

Manual smoke test:

- `docs/core/manual_tests/phase5l_member_sync_awareness_smoke_test.md`

### Phase 5M Acceptance / Hardening

Phase 5M completes the remote-backed shared pack local-first MVP acceptance pass without adding Supabase schema, RPC, or RLS changes. The Phase 5L SQL patch remains a manual apply step.

- Email protection is current-session Email-change OTP binding only. It is not Email sign-in, magic-link login, account switching, or cross-device session recovery.
- Recovery remains explicit/manual and depends on the current authenticated linked/protected remote session. App startup, realtime signals, backup restore, widget refresh, notification sync, and outbox retry/flush paths do not auto-run recovery.
- Member freshness remains pack-data freshness only. It must not be described as read receipts, presence, attention, online/offline state, device tracking, IP tracking, or location tracking.
- Remote-backed Home, Widget, and Notification behavior remains local-derived. None of those surfaces directly call Supabase.
- Backup remains legacy local-only safety. It does not store credentials, tokens, sessions, OTPs, service-role keys, plaintext invite codes, typed remote metadata, outbox replay data, or remote-backed mirrors.

### RPC Contract Checklist

- `upsert_current_profile` uses `auth.uid()` and returns the current remote profile id.
- `create_shared_pack` is a bootstrap transaction RPC: it uses `auth.uid()` as host, creates the initial host membership, and writes `pack_created`.
- `create_shared_pack` uses `SECURITY DEFINER` because the first host membership cannot satisfy normal membership-based RLS before it exists. It must still use only `auth.uid()` for actor identity and must not accept caller-supplied user ids.
- `create_pack_item` verifies active membership, uses `auth.uid()` for creator/updater, and writes `item_created`.
- `complete_pack_item` verifies active membership, uses `auth.uid()` as `completed_by_user_id`, returns `completed / already_completed`, writes `item_completed`, and relies on the active-completion unique index.
- `undo_pack_item_completion` verifies active membership, returns `undone / already_not_completed`, writes `undone_by_user_id` / `undone_at`, writes `item_undone`, and does not delete completion history.
- `create_pack_invite` is host-only and returns plaintext invite code once; database stores only `code_hash`.
- `join_pack_with_invite` returns `joined / already_member`; a removed member can rejoin only through a valid active invite.
- `revoke_pack_invite` returns `revoked / already_revoked`.
- RPCs must not accept client-supplied actor ids.
- App-callable RPCs explicitly revoke default `public` execute and grant execute to `authenticated`. `anon` execute is not granted unless a future spec explicitly allows an unauthenticated RPC.
- `upsert_current_profile(text)` and `create_shared_pack(text,text)` are `SECURITY DEFINER` bootstrap RPCs with `set search_path = public`; both derive actor identity only from `auth.uid()`, reject null auth, and do not accept caller-supplied user ids.

### RLS Checklist

- Table grants and RLS policies are separate permission layers. Supabase/PostgREST first requires the `authenticated` role to have table privileges; RLS then limits which rows the user can see or mutate.
- Remote/shared pack private tables grant only the minimum required `authenticated` `select / insert / update` table privileges. `activity_events` grants `select / insert` only. No remote/shared pack table grants `delete`.
- `anon` must not receive table privileges for shared pack private data. Flutter uses the Supabase anon key only as a public client key; row access still depends on authenticated sessions plus RLS.
- `profiles`: user can read/write self; active pack members can read active co-members.
- `packs`: active members can read; host can update/archive; no hard delete policy.
- `pack_members`: active members can read same pack; host manages members; join goes through invite RPC.
- `items`: active members can read/create/update allowed fields; completion permission is not limited by `assigned_to_user_id`.
- `item_completions`: active members can read; complete/undo are RPC-controlled; no hard delete policy.
- `pack_invites`: host can select/manage; plaintext invite code is never stored; join goes through RPC.
- `activity_events`: active members can read; POC inserts require active membership and `actor_user_id = auth.uid()`; long-term production should move shared writes behind stricter RPC/trigger paths.

Removed members are not active members and must not read or mutate pack data. A removed member may become active again only by successfully using a valid invite through `join_pack_with_invite`.

### Realtime Advisory Checklist

- App startup does not subscribe.
- User explicitly starts and stops realtime in developer Settings.
- Duplicate subscribe for the same target is a no-op.
- Retargeting removes the old subscription before creating a new one.
- Provider/controller dispose removes active subscription.
- Incoming signal only updates volatile advisory state: change flag, count, last action, actor, and received time.
- Incoming signal does not pull snapshot, mutate viewer items, write local DB, create `sync_mappings`, or enter backup.
- Successful manual snapshot refresh clears the advisory change flag and count.
- Snapshot fetch remains the source of truth and remains RLS-gated.

### Phase 4E Integrated Manual Smoke Test

Supabase setup:

1. 建立 Supabase dev project。
2. 啟用 Anonymous Sign-ins。
3. Apply `docs/core/sql/phase3c_supabase_minimal_poc.sql`。
4. Apply `docs/core/sql/phase4a_supabase_invite_membership_mvp.sql`。
5. Apply `docs/core/sql/phase4c_supabase_remote_member_actions_mvp.sql`。
6. Apply `docs/core/sql/phase4d_supabase_realtime_soft_notification_poc.sql`。
7. Apply `docs/core/sql/phase4e_supabase_remote_collaboration_hardening.sql`。
8. Apply `docs/core/sql/phase_remote_grants_rls_repair.sql`。
9. 確認 RLS enabled。
10. 確認 `activity_events` Realtime publication enabled。
11. Run the grants audit query from `phase_remote_grants_rls_repair.sql` and verify expected `authenticated` privileges are true while delete remains false.
12. Flutter app 只使用 `SUPABASE_URL` / `SUPABASE_ANON_KEY`。
13. 不使用 service role key。

Device A / Host flow:

1. 使用 Device A / simulator A。
2. `flutter run --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...`。
3. 建立 anonymous remote identity。
4. 建立 Remote Profile。
5. 準備一個 local Shared Pack。
6. 建立 remote shared pack POC。
7. 推送 Minimal Items POC。
8. 建立 Invite Code POC。
9. 刷新 Remote Snapshot viewer。
10. 確認 viewer 顯示 pack / members / items / activity。
11. 開始監聽遠端變更 POC。
12. 確認 realtime status = subscribed。

Device B / Member flow:

1. 使用 Device B / simulator B / clean install。
2. 使用同一 Supabase dev project。
3. 建立 anonymous remote identity。
4. 建立 Remote Profile。
5. 輸入 Device A 的 invite code。
6. 加入遠端 Pack POC。
7. 刷新 Remote Snapshot viewer。
8. 確認 viewer 顯示同一個 pack / items / members。
9. 選擇一個未完成 remote item。
10. 完成選擇的 Remote Item。
11. 刷新 viewer。
12. 確認 item `completed_by` = Device B remote user。
13. 復原選擇的 Remote Item。
14. 刷新 viewer。
15. 確認 item 回到未完成。
16. 確認 activity 有 `item_completed` / `item_undone`。

Device A verification:

1. Device B complete item 後，Device A 應收到「遠端有新變更」。
2. Device A 不應自動改 item state。
3. Device A 手動刷新 Snapshot。
4. Device A 應看到 Device B `completed_by`。
5. Device B undo 後，Device A 應再次收到「遠端有新變更」。
6. Device A 手動刷新後 item 回到未完成。
7. Activity history 保留 completed / undone events。

Device C / Non-member RLS test:

1. 使用 Device C / simulator C / clean install。
2. 建立 anonymous remote identity。
3. 建立 Remote Profile。
4. 不輸入 invite code。
5. 嘗試拉 Device A remote pack snapshot。
6. 預期被 RLS 擋下。
7. 嘗試 complete Device A remote item。
8. 預期被 RLS 擋下。
9. 嘗試 undo Device A remote item。
10. 預期被 RLS 擋下。
11. 嘗試 subscribe Device A pack activity events。
12. 預期不應收到 signal，或 subscription/query 被 RLS 擋下。

Expected boundaries:

- Personal pack 不自動上傳。
- Local pack 不自動建立。
- Local items 不自動建立。
- Remote snapshot 不 merge local DB。
- Remote complete / undo 不改 local completion history。
- Realtime signal 不 auto refresh。
- Realtime signal 不改 viewer state。
- 只有 manual refresh 會重新拉 snapshot。
- Backup 不包含 token/session/credential/invite code/realtime volatile state。
- Resources / stages 不上傳。
- Widget 行為不變。

### Smoke Test Log Template

Manual test results should be recorded in:

```text
docs/core/manual_tests/phase4e_remote_collaboration_smoke_test.md
```

### Known Limitations

- Supabase SQL remains manually applied and must be verified in SQL editor or local Supabase CLI.
- RLS and Realtime authorization behavior require real Supabase smoke testing.
- Developer Settings remains a POC surface, not production remote collaboration UI.
- No local import, automatic merge, background sync, formal invite UI, resource sync, or stage sync exists.

### Phase 5 Boundary

Phase 5 may decide whether remote snapshots become local imports, whether activity writes move fully behind RPC/trigger paths, and whether realtime becomes production notification UX. Those decisions are intentionally outside Phase 4E.

Phase 3C-4E define remote POC and collaboration primitives. Phase 5A moves toward remote-backed shared packs as app-level local-first data. Detailed local mirror / outbox / conflict / widget / notification / backup strategy lives in `docs/core/07_remote_backed_shared_pack_sync_spec.md`.
