# Supabase Remote Model Spec — Phase 3A

本文件是 Phase 3A 的 Supabase remote data model、RLS policy draft、SQL schema draft 與 Phase 3C POC 邊界規格。

Phase 3A 是設計階段，不是 Supabase integration 實作階段。

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

Phase 3B 可使用 Supabase anonymous auth 建立 remote identity，讓使用者在不綁 Apple / Google / Email 的情況下建立 Shared Pack remote data。

規則：

- Anonymous remote user 可成為 Shared Pack host / member。
- 使用者仍不需要立即綁 Apple / Google / Email。
- Apple / Google / Email binding 是後續資料保護能力，不是建立 Shared Pack 的前置條件。
- Phase 3A 只預留 schema / RLS / mapping 設計，不實作 auth flow。

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
