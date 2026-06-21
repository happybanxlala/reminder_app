-- Reminder App Phase 3C Supabase Remote Shared Pack Minimal POC
-- Manual draft only. Do not auto-apply to production.
-- REVIEW: Validate in Supabase SQL editor or local Supabase CLI before use.
-- Phase 3C scope: profiles, packs, pack_members, items, item_completions,
-- and activity_events only. Resources and stages remain TODO for later phases.

create extension if not exists pgcrypto;

-- ---------------------------------------------------------------------------
-- Tables
-- ---------------------------------------------------------------------------

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  display_name text not null,
  avatar_url text null,
  identity_kind text not null default 'anonymous_remote'
    check (identity_kind in ('anonymous_remote', 'linked', 'placeholder', 'removed')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz null
);

create table if not exists public.packs (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  description text null,
  pack_type text not null default 'shared' check (pack_type = 'shared'),
  host_user_id uuid not null references public.profiles(id),
  status text not null default 'active' check (status in ('active', 'archived')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  archived_at timestamptz null,
  deleted_at timestamptz null
);

create table if not exists public.pack_members (
  id uuid primary key default gen_random_uuid(),
  pack_id uuid not null references public.packs(id) on delete cascade,
  user_id uuid not null references public.profiles(id),
  role text not null check (role in ('host', 'member', 'viewer')),
  status text not null default 'active' check (status in ('active', 'removed')),
  joined_at timestamptz not null default now(),
  removed_at timestamptz null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.items (
  id uuid primary key default gen_random_uuid(),
  pack_id uuid not null references public.packs(id) on delete cascade,
  title text not null,
  note text null,
  status text not null default 'active' check (status in ('active', 'archived', 'deleted')),
  assigned_to_user_id uuid null references public.profiles(id),
  created_by_user_id uuid not null references public.profiles(id),
  updated_by_user_id uuid not null references public.profiles(id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  archived_at timestamptz null,
  deleted_at timestamptz null
);

create table if not exists public.item_completions (
  id uuid primary key default gen_random_uuid(),
  pack_id uuid not null references public.packs(id) on delete cascade,
  item_id uuid not null references public.items(id) on delete cascade,
  completed_by_user_id uuid not null references public.profiles(id),
  completed_at timestamptz not null default now(),
  undone_by_user_id uuid null references public.profiles(id),
  undone_at timestamptz null,
  client_mutation_id text null,
  created_at timestamptz not null default now()
);

create table if not exists public.activity_events (
  id uuid primary key default gen_random_uuid(),
  pack_id uuid not null references public.packs(id) on delete cascade,
  actor_user_id uuid null references public.profiles(id),
  actor_display_name_snapshot text null,
  entity_type text not null,
  entity_id uuid not null,
  action text not null,
  before_json jsonb null,
  after_json jsonb null,
  metadata_json jsonb null,
  created_at timestamptz not null default now()
);

-- ---------------------------------------------------------------------------
-- Indexes
-- ---------------------------------------------------------------------------

create index if not exists profiles_deleted_at_idx
  on public.profiles(deleted_at);

create index if not exists packs_host_user_id_idx
  on public.packs(host_user_id);

create index if not exists packs_status_idx
  on public.packs(status);

create unique index if not exists pack_members_pack_user_unique
  on public.pack_members(pack_id, user_id);

create index if not exists pack_members_user_status_idx
  on public.pack_members(user_id, status);

create index if not exists items_pack_id_idx
  on public.items(pack_id);

create index if not exists items_assigned_to_user_id_idx
  on public.items(assigned_to_user_id)
  where assigned_to_user_id is not null;

create index if not exists item_completions_pack_item_idx
  on public.item_completions(pack_id, item_id);

create unique index if not exists one_active_completion_per_item
  on public.item_completions(item_id)
  where undone_at is null;

create index if not exists activity_events_pack_created_at_idx
  on public.activity_events(pack_id, created_at desc);

-- ---------------------------------------------------------------------------
-- RLS Enablement
-- ---------------------------------------------------------------------------

alter table public.profiles enable row level security;
alter table public.packs enable row level security;
alter table public.pack_members enable row level security;
alter table public.items enable row level security;
alter table public.item_completions enable row level security;
alter table public.activity_events enable row level security;

-- ---------------------------------------------------------------------------
-- Helper Functions
-- ---------------------------------------------------------------------------

-- REVIEW: security definer avoids recursive RLS checks on pack_members.
-- Confirm owner/grants before production. search_path is pinned to public.
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

-- REVIEW: security definer avoids recursive RLS checks on pack_members.
-- Confirm owner/grants before production. search_path is pinned to public.
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

-- ---------------------------------------------------------------------------
-- Policies
-- ---------------------------------------------------------------------------
-- Postgres does not support CREATE POLICY IF NOT EXISTS. Drops make this draft
-- easier to re-run during development.

drop policy if exists "profiles_select_self_or_pack_members" on public.profiles;
create policy "profiles_select_self_or_pack_members"
on public.profiles for select
to authenticated
using (
  id = auth.uid()
  or exists (
    select 1
    from public.pack_members self_pm
    join public.pack_members other_pm on other_pm.pack_id = self_pm.pack_id
    where self_pm.user_id = auth.uid()
      and self_pm.status = 'active'
      and other_pm.user_id = profiles.id
      and other_pm.status = 'active'
  )
);

drop policy if exists "profiles_insert_self" on public.profiles;
create policy "profiles_insert_self"
on public.profiles for insert
to authenticated
with check (id = auth.uid());

drop policy if exists "profiles_update_self" on public.profiles;
create policy "profiles_update_self"
on public.profiles for update
to authenticated
using (id = auth.uid())
with check (id = auth.uid());

drop policy if exists "packs_select_members" on public.packs;
create policy "packs_select_members"
on public.packs for select
to authenticated
using (public.is_pack_member(id));

drop policy if exists "packs_insert_host_self" on public.packs;
create policy "packs_insert_host_self"
on public.packs for insert
to authenticated
with check (host_user_id = auth.uid() and pack_type = 'shared');

drop policy if exists "packs_update_host" on public.packs;
create policy "packs_update_host"
on public.packs for update
to authenticated
using (public.is_pack_host(id))
with check (public.is_pack_host(id));

drop policy if exists "pack_members_select_members" on public.pack_members;
create policy "pack_members_select_members"
on public.pack_members for select
to authenticated
using (public.is_pack_member(pack_id));

drop policy if exists "pack_members_insert_host" on public.pack_members;
create policy "pack_members_insert_host"
on public.pack_members for insert
to authenticated
with check (public.is_pack_host(pack_id));

drop policy if exists "pack_members_update_host" on public.pack_members;
create policy "pack_members_update_host"
on public.pack_members for update
to authenticated
using (public.is_pack_host(pack_id))
with check (public.is_pack_host(pack_id));

drop policy if exists "items_select_members" on public.items;
create policy "items_select_members"
on public.items for select
to authenticated
using (public.is_pack_member(pack_id));

drop policy if exists "items_insert_members" on public.items;
create policy "items_insert_members"
on public.items for insert
to authenticated
with check (
  public.is_pack_member(pack_id)
  and created_by_user_id = auth.uid()
  and updated_by_user_id = auth.uid()
);

drop policy if exists "items_update_members" on public.items;
create policy "items_update_members"
on public.items for update
to authenticated
using (public.is_pack_member(pack_id))
with check (
  public.is_pack_member(pack_id)
  and updated_by_user_id = auth.uid()
  and deleted_at is null
);

drop policy if exists "item_completions_select_members" on public.item_completions;
create policy "item_completions_select_members"
on public.item_completions for select
to authenticated
using (public.is_pack_member(pack_id));

drop policy if exists "item_completions_insert_members" on public.item_completions;
create policy "item_completions_insert_members"
on public.item_completions for insert
to authenticated
with check (
  public.is_pack_member(pack_id)
  and completed_by_user_id = auth.uid()
  and exists (
    select 1 from public.items i
    where i.id = item_id
      and i.pack_id = item_completions.pack_id
      and i.deleted_at is null
  )
);

-- Phase 3C does not expose item_completions update. Remote undo will be a
-- later RPC that updates undone_by_user_id / undone_at without changing
-- completed_by_user_id.

drop policy if exists "activity_events_select_members" on public.activity_events;
create policy "activity_events_select_members"
on public.activity_events for select
to authenticated
using (public.is_pack_member(pack_id));

drop policy if exists "activity_events_insert_members" on public.activity_events;
create policy "activity_events_insert_members"
on public.activity_events for insert
to authenticated
with check (
  public.is_pack_member(pack_id)
  and actor_user_id = auth.uid()
);

-- No hard delete policies are created for packs, pack_members, items,
-- item_completions, or activity_events.

-- ---------------------------------------------------------------------------
-- RPC / Transaction Functions
-- ---------------------------------------------------------------------------

create or replace function public.upsert_current_profile(display_name text)
returns uuid
language plpgsql
security invoker
set search_path = public
as $$
declare
  current_user_id uuid := auth.uid();
begin
  if current_user_id is null then
    raise exception 'auth required';
  end if;

  insert into public.profiles (
    id,
    display_name,
    identity_kind,
    created_at,
    updated_at
  )
  values (
    current_user_id,
    coalesce(nullif(display_name, ''), 'Anonymous'),
    'anonymous_remote',
    now(),
    now()
  )
  on conflict (id) do update
    set display_name = excluded.display_name,
        updated_at = now(),
        deleted_at = null;

  return current_user_id;
end;
$$;

create or replace function public.create_shared_pack(
  pack_name text,
  description text default null
)
returns uuid
language plpgsql
security invoker
set search_path = public
as $$
declare
  current_user_id uuid := auth.uid();
  created_pack_id uuid;
begin
  if current_user_id is null then
    raise exception 'auth required';
  end if;

  insert into public.packs (
    name,
    description,
    pack_type,
    host_user_id,
    status
  )
  values (
    pack_name,
    description,
    'shared',
    current_user_id,
    'active'
  )
  returning id into created_pack_id;

  insert into public.pack_members (
    pack_id,
    user_id,
    role,
    status
  )
  values (
    created_pack_id,
    current_user_id,
    'host',
    'active'
  );

  insert into public.activity_events (
    pack_id,
    actor_user_id,
    entity_type,
    entity_id,
    action,
    after_json
  )
  values (
    created_pack_id,
    current_user_id,
    'pack',
    created_pack_id,
    'pack_created',
    jsonb_build_object('name', pack_name)
  );

  return created_pack_id;
end;
$$;

create or replace function public.create_pack_item(
  pack_id uuid,
  title text,
  note text default null
)
returns uuid
language plpgsql
security invoker
set search_path = public
as $$
declare
  current_user_id uuid := auth.uid();
  created_item_id uuid;
begin
  if current_user_id is null then
    raise exception 'auth required';
  end if;

  if not public.is_pack_member(pack_id) then
    raise exception 'active pack member required';
  end if;

  insert into public.items (
    pack_id,
    title,
    note,
    status,
    created_by_user_id,
    updated_by_user_id
  )
  values (
    pack_id,
    title,
    note,
    'active',
    current_user_id,
    current_user_id
  )
  returning id into created_item_id;

  insert into public.activity_events (
    pack_id,
    actor_user_id,
    entity_type,
    entity_id,
    action,
    after_json
  )
  values (
    pack_id,
    current_user_id,
    'item',
    created_item_id,
    'item_created',
    jsonb_build_object('title', title)
  );

  return created_item_id;
end;
$$;

create or replace function public.complete_pack_item(
  item_id uuid,
  client_mutation_id text default null
)
returns table (
  status text,
  completion_id uuid,
  completed_by_user_id uuid,
  completed_at timestamptz
)
language plpgsql
security invoker
set search_path = public
as $$
declare
  current_user_id uuid := auth.uid();
  target_pack_id uuid;
  existing_completion public.item_completions%rowtype;
  inserted_completion public.item_completions%rowtype;
begin
  if current_user_id is null then
    raise exception 'auth required';
  end if;

  select i.pack_id into target_pack_id
  from public.items i
  where i.id = complete_pack_item.item_id
    and i.deleted_at is null;

  if target_pack_id is null then
    raise exception 'item not found';
  end if;

  if not public.is_pack_member(target_pack_id) then
    raise exception 'active pack member required';
  end if;

  select * into existing_completion
  from public.item_completions ic
  where ic.item_id = complete_pack_item.item_id
    and ic.undone_at is null
  limit 1;

  if existing_completion.id is not null then
    return query select
      'already_completed'::text,
      existing_completion.id,
      existing_completion.completed_by_user_id,
      existing_completion.completed_at;
    return;
  end if;

  insert into public.item_completions (
    pack_id,
    item_id,
    completed_by_user_id,
    client_mutation_id
  )
  values (
    target_pack_id,
    complete_pack_item.item_id,
    current_user_id,
    complete_pack_item.client_mutation_id
  )
  returning * into inserted_completion;

  insert into public.activity_events (
    pack_id,
    actor_user_id,
    entity_type,
    entity_id,
    action,
    metadata_json
  )
  values (
    target_pack_id,
    current_user_id,
    'item',
    complete_pack_item.item_id,
    'item_completed',
    jsonb_build_object('completion_id', inserted_completion.id)
  );

  return query select
    'completed'::text,
    inserted_completion.id,
    inserted_completion.completed_by_user_id,
    inserted_completion.completed_at;

exception when unique_violation then
  select * into existing_completion
  from public.item_completions ic
  where ic.item_id = complete_pack_item.item_id
    and ic.undone_at is null
  limit 1;

  return query select
    'already_completed'::text,
    existing_completion.id,
    existing_completion.completed_by_user_id,
    existing_completion.completed_at;
end;
$$;

-- TODO Phase 3D+: remote undo RPC, invite/member onboarding, resource sync,
-- stage acknowledgement sync, and moving activity event writes behind stricter
-- RPC/trigger-only paths.

-- Manual apply notes:
-- 1. Enable anonymous sign-ins in the Supabase project.
-- 2. Apply this file manually in SQL editor or local Supabase CLI.
-- 3. Confirm RLS is enabled on all exposed tables.
-- 4. Use only the anon key in Flutter via --dart-define.
-- 5. Never place privileged backend credentials or server secrets in the
--    Flutter app.
