-- Reminder App Phase 3A Supabase Remote Model / RLS Draft
-- This is a design draft, not a production migration.
-- REVIEW: Validate in Supabase SQL editor or local Supabase CLI before use.

-- Supabase projects commonly provide gen_random_uuid().
-- REVIEW: Some environments may already have this extension enabled.
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
  pack_type text not null default 'shared'
    check (pack_type = 'shared'),
  host_user_id uuid not null references public.profiles(id),
  status text not null default 'active'
    check (status in ('active', 'archived')),
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
  status text not null default 'active'
    check (status in ('active', 'removed')),
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
  status text not null default 'active'
    check (status in ('active', 'archived', 'deleted')),
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

create table if not exists public.resources (
  id uuid primary key default gen_random_uuid(),
  pack_id uuid not null references public.packs(id) on delete cascade,
  name text not null,
  current_value numeric null,
  unit text null,
  warning_threshold numeric null,
  danger_threshold numeric null,
  version integer not null default 0,
  created_by_user_id uuid not null references public.profiles(id),
  updated_by_user_id uuid not null references public.profiles(id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  archived_at timestamptz null,
  deleted_at timestamptz null
);

create table if not exists public.resource_events (
  id uuid primary key default gen_random_uuid(),
  pack_id uuid not null references public.packs(id) on delete cascade,
  resource_id uuid not null references public.resources(id) on delete cascade,
  actor_user_id uuid not null references public.profiles(id),
  change_type text not null check (change_type in ('adjust', 'increment', 'decrement')),
  previous_value numeric null,
  new_value numeric null,
  delta_value numeric null,
  unit text null,
  base_version integer null,
  created_at timestamptz not null default now(),
  metadata jsonb null
);

create table if not exists public.stages (
  id uuid primary key default gen_random_uuid(),
  pack_id uuid not null references public.packs(id) on delete cascade,
  title text not null,
  description text null,
  status text not null default 'upcoming'
    check (status in ('upcoming', 'active', 'closed')),
  order_index integer not null default 0,
  created_by_user_id uuid not null references public.profiles(id),
  updated_by_user_id uuid not null references public.profiles(id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  closed_at timestamptz null,
  deleted_at timestamptz null
);

create table if not exists public.stage_acknowledgements (
  id uuid primary key default gen_random_uuid(),
  pack_id uuid not null references public.packs(id) on delete cascade,
  stage_id uuid not null references public.stages(id) on delete cascade,
  user_id uuid not null references public.profiles(id),
  acknowledged_at timestamptz not null default now(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
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

create index if not exists resources_pack_id_idx
  on public.resources(pack_id);

create index if not exists resource_events_resource_id_idx
  on public.resource_events(resource_id, created_at desc);

create index if not exists stages_pack_id_idx
  on public.stages(pack_id);

create unique index if not exists stage_acknowledgements_stage_user_unique
  on public.stage_acknowledgements(stage_id, user_id);

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
alter table public.resources enable row level security;
alter table public.resource_events enable row level security;
alter table public.stages enable row level security;
alter table public.stage_acknowledgements enable row level security;
alter table public.activity_events enable row level security;

-- ---------------------------------------------------------------------------
-- Helper Functions
-- ---------------------------------------------------------------------------

-- REVIEW: security definer is used to avoid recursive RLS checks on pack_members.
-- Confirm function owner and grants before production use.
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
-- Postgres does not support CREATE POLICY IF NOT EXISTS. These drops make the
-- draft easier to re-run during local experimentation.

-- profiles
drop policy if exists "profiles_select_self_or_pack_members" on public.profiles;
create policy "profiles_select_self_or_pack_members"
on public.profiles
for select
to authenticated
using (
  id = auth.uid()
  or exists (
    select 1
    from public.pack_members target_member
    where target_member.user_id = profiles.id
      and public.is_pack_member(target_member.pack_id)
  )
);

drop policy if exists "profiles_insert_self" on public.profiles;
create policy "profiles_insert_self"
on public.profiles
for insert
to authenticated
with check (id = auth.uid());

drop policy if exists "profiles_update_self" on public.profiles;
create policy "profiles_update_self"
on public.profiles
for update
to authenticated
using (id = auth.uid())
with check (id = auth.uid());

-- packs
drop policy if exists "packs_select_active_members" on public.packs;
create policy "packs_select_active_members"
on public.packs
for select
to authenticated
using (public.is_pack_member(id));

drop policy if exists "packs_insert_self_host" on public.packs;
create policy "packs_insert_self_host"
on public.packs
for insert
to authenticated
with check (
  pack_type = 'shared'
  and host_user_id = auth.uid()
);

drop policy if exists "packs_update_host" on public.packs;
create policy "packs_update_host"
on public.packs
for update
to authenticated
using (public.is_pack_host(id))
with check (public.is_pack_host(id));

-- REVIEW: no delete policy by design. Shared pack destructive behavior should
-- be archive / soft delete.

-- pack_members
drop policy if exists "pack_members_select_active_members" on public.pack_members;
create policy "pack_members_select_active_members"
on public.pack_members
for select
to authenticated
using (public.is_pack_member(pack_id));

drop policy if exists "pack_members_insert_host_managed" on public.pack_members;
create policy "pack_members_insert_host_managed"
on public.pack_members
for insert
to authenticated
with check (
  public.is_pack_host(pack_id)
  or (
    user_id = auth.uid()
    and role = 'host'
    and status = 'active'
    and exists (
      select 1
      from public.packs p
      where p.id = pack_id
        and p.host_user_id = auth.uid()
    )
  )
);

drop policy if exists "pack_members_update_host" on public.pack_members;
create policy "pack_members_update_host"
on public.pack_members
for update
to authenticated
using (public.is_pack_host(pack_id))
with check (public.is_pack_host(pack_id));

-- REVIEW: host membership creation is safer through RPC create_shared_pack()
-- because simple RLS policies cannot guarantee pack + host row consistency.

-- items
drop policy if exists "items_select_active_members" on public.items;
create policy "items_select_active_members"
on public.items
for select
to authenticated
using (public.is_pack_member(pack_id));

drop policy if exists "items_insert_active_members" on public.items;
create policy "items_insert_active_members"
on public.items
for insert
to authenticated
with check (
  public.is_pack_member(pack_id)
  and created_by_user_id = auth.uid()
  and updated_by_user_id = auth.uid()
);

drop policy if exists "items_update_active_members" on public.items;
create policy "items_update_active_members"
on public.items
for update
to authenticated
using (public.is_pack_member(pack_id))
with check (
  public.is_pack_member(pack_id)
  and updated_by_user_id = auth.uid()
);

-- TODO: Enforce host-only archive / soft delete through RPC or trigger if
-- member edits should be limited to non-destructive fields.
-- No hard delete policy.

-- item_completions
drop policy if exists "item_completions_select_active_members" on public.item_completions;
create policy "item_completions_select_active_members"
on public.item_completions
for select
to authenticated
using (public.is_pack_member(pack_id));

drop policy if exists "item_completions_insert_active_members" on public.item_completions;
create policy "item_completions_insert_active_members"
on public.item_completions
for insert
to authenticated
with check (
  public.is_pack_member(pack_id)
  and completed_by_user_id = auth.uid()
  and undone_by_user_id is null
  and undone_at is null
  and exists (
    select 1
    from public.items i
    where i.id = item_id
      and i.pack_id = item_completions.pack_id
  )
);

drop policy if exists "item_completions_update_undo_active_members" on public.item_completions;
create policy "item_completions_update_undo_active_members"
on public.item_completions
for update
to authenticated
using (
  public.is_pack_member(pack_id)
  and undone_at is null
)
with check (
  public.is_pack_member(pack_id)
  and completed_by_user_id is not null
  and undone_by_user_id = auth.uid()
  and undone_at is not null
);

-- REVIEW: RLS cannot fully express "only update undone_by_user_id / undone_at"
-- or "completed_by_user_id is unchanged". Use RPC/trigger for production.
-- No hard delete policy.

-- resources
drop policy if exists "resources_select_active_members" on public.resources;
create policy "resources_select_active_members"
on public.resources
for select
to authenticated
using (public.is_pack_member(pack_id));

drop policy if exists "resources_insert_active_members" on public.resources;
create policy "resources_insert_active_members"
on public.resources
for insert
to authenticated
with check (
  public.is_pack_member(pack_id)
  and created_by_user_id = auth.uid()
  and updated_by_user_id = auth.uid()
);

drop policy if exists "resources_update_active_members" on public.resources;
create policy "resources_update_active_members"
on public.resources
for update
to authenticated
using (public.is_pack_member(pack_id))
with check (
  public.is_pack_member(pack_id)
  and updated_by_user_id = auth.uid()
);

-- TODO: Prefer RPC for current_value + resource_events transaction.
-- No hard delete policy.

-- resource_events
drop policy if exists "resource_events_select_active_members" on public.resource_events;
create policy "resource_events_select_active_members"
on public.resource_events
for select
to authenticated
using (public.is_pack_member(pack_id));

drop policy if exists "resource_events_insert_active_members" on public.resource_events;
create policy "resource_events_insert_active_members"
on public.resource_events
for insert
to authenticated
with check (
  public.is_pack_member(pack_id)
  and actor_user_id = auth.uid()
  and exists (
    select 1
    from public.resources r
    where r.id = resource_id
      and r.pack_id = resource_events.pack_id
  )
);

-- No update/delete policy. Resource events are factual history.

-- stages
drop policy if exists "stages_select_active_members" on public.stages;
create policy "stages_select_active_members"
on public.stages
for select
to authenticated
using (public.is_pack_member(pack_id));

drop policy if exists "stages_insert_active_members" on public.stages;
create policy "stages_insert_active_members"
on public.stages
for insert
to authenticated
with check (
  public.is_pack_member(pack_id)
  and created_by_user_id = auth.uid()
  and updated_by_user_id = auth.uid()
);

drop policy if exists "stages_update_active_members" on public.stages;
create policy "stages_update_active_members"
on public.stages
for update
to authenticated
using (public.is_pack_member(pack_id))
with check (
  public.is_pack_member(pack_id)
  and updated_by_user_id = auth.uid()
);

-- REVIEW: stages must not gain completed_by_user_id / completed_at semantics.
-- No hard delete policy.

-- stage_acknowledgements
drop policy if exists "stage_acknowledgements_select_active_members" on public.stage_acknowledgements;
create policy "stage_acknowledgements_select_active_members"
on public.stage_acknowledgements
for select
to authenticated
using (public.is_pack_member(pack_id));

drop policy if exists "stage_acknowledgements_insert_self" on public.stage_acknowledgements;
create policy "stage_acknowledgements_insert_self"
on public.stage_acknowledgements
for insert
to authenticated
with check (
  public.is_pack_member(pack_id)
  and user_id = auth.uid()
  and exists (
    select 1
    from public.stages s
    where s.id = stage_id
      and s.pack_id = stage_acknowledgements.pack_id
  )
);

drop policy if exists "stage_acknowledgements_update_self" on public.stage_acknowledgements;
create policy "stage_acknowledgements_update_self"
on public.stage_acknowledgements
for update
to authenticated
using (
  public.is_pack_member(pack_id)
  and user_id = auth.uid()
)
with check (
  public.is_pack_member(pack_id)
  and user_id = auth.uid()
);

-- activity_events
drop policy if exists "activity_events_select_active_members" on public.activity_events;
create policy "activity_events_select_active_members"
on public.activity_events
for select
to authenticated
using (public.is_pack_member(pack_id));

drop policy if exists "activity_events_insert_repository_controlled" on public.activity_events;
create policy "activity_events_insert_repository_controlled"
on public.activity_events
for insert
to authenticated
with check (
  public.is_pack_member(pack_id)
  and (
    actor_user_id = auth.uid()
    or (
      actor_user_id is null
      and metadata_json ? 'system_actor'
    )
  )
);

-- REVIEW: repository-controlled activity inserts are acceptable for Phase 3 POC
-- only. Long-term shared mutations should create activity rows through RPC or
-- trigger-controlled transaction paths.
-- No update/delete policy.

-- ---------------------------------------------------------------------------
-- RPC / Transaction TODOs
-- ---------------------------------------------------------------------------

-- TODO: create_shared_pack(name text, client_pack_id text default null)
-- Should insert packs + host pack_members + activity_events in one transaction.

-- TODO: complete_item(item_id uuid, client_mutation_id text default null)
-- Should rely on one_active_completion_per_item and insert activity_events.

-- TODO: undo_item_completion(completion_id uuid)
-- Should update undone_by_user_id / undone_at and insert activity_events.

-- TODO: adjust_resource(resource_id uuid, new_value numeric, base_version integer default null)
-- Should check base version, update resources.current_value/version, insert
-- resource_events, and insert activity_events in one transaction.

-- TODO: increment_resource(resource_id uuid, delta numeric)
-- Should update projection, insert resource_events(change_type = 'increment'),
-- and insert activity_events in one transaction.

-- TODO: decrement_resource(resource_id uuid, delta numeric)
-- Should update projection, insert resource_events(change_type = 'decrement'),
-- and insert activity_events in one transaction.

-- TODO: acknowledge_stage(stage_id uuid)
-- Should upsert stage_acknowledgements(stage_id, auth.uid()) and insert
-- activity_events in one transaction.

-- ---------------------------------------------------------------------------
-- Local sync mapping note
-- ---------------------------------------------------------------------------

-- Phase 3B/3C POC should prefer a local sync_mappings table instead of adding
-- remote_id columns to every local Drift table. That table is local-only and is
-- intentionally not created in this Supabase remote schema draft.
