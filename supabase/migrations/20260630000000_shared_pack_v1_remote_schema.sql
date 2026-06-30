-- Shared Pack v1 remote schema foundation.
-- This migration creates Supabase-side storage and RPC contracts only.
-- Flutter runtime wiring is intentionally out of scope for this phase.

create extension if not exists pgcrypto;

create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create table if not exists public.shared_packs (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  owner_identity_id uuid not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  archived_at timestamptz null
);

create table if not exists public.shared_pack_members (
  id uuid primary key default gen_random_uuid(),
  pack_id uuid not null references public.shared_packs(id) on delete cascade,
  member_identity_id uuid not null,
  role text not null default 'member',
  joined_at timestamptz not null default now(),
  removed_at timestamptz null,
  constraint shared_pack_members_role_check
    check (role in ('owner', 'member'))
);

create unique index if not exists shared_pack_members_active_unique
  on public.shared_pack_members (pack_id, member_identity_id)
  where removed_at is null;

create table if not exists public.shared_pack_invites (
  id uuid primary key default gen_random_uuid(),
  pack_id uuid not null references public.shared_packs(id) on delete cascade,
  code text not null unique,
  created_by_identity_id uuid not null,
  created_at timestamptz not null default now(),
  expires_at timestamptz null,
  revoked_at timestamptz null,
  constraint shared_pack_invites_code_length_check
    check (char_length(code) = 6),
  constraint shared_pack_invites_code_charset_check
    check (code ~ '^[ABCDEFGHJKLMNPQRSTUVWXYZ23456789]{6}$'),
  constraint shared_pack_invites_code_avoids_ambiguous_check
    check (code !~ '[0O1IL]')
);

create table if not exists public.shared_pack_items (
  id uuid primary key default gen_random_uuid(),
  pack_id uuid not null references public.shared_packs(id) on delete cascade,
  title text not null,
  notes text null,
  schedule_payload jsonb null,
  state text not null default 'active',
  last_completed_at timestamptz null,
  updated_by_identity_id uuid null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  archived_at timestamptz null,
  constraint shared_pack_items_state_not_blank_check
    check (length(btrim(state)) > 0)
);

drop trigger if exists shared_packs_set_updated_at on public.shared_packs;
create trigger shared_packs_set_updated_at
before update on public.shared_packs
for each row execute function public.set_updated_at();

drop trigger if exists shared_pack_items_set_updated_at on public.shared_pack_items;
create trigger shared_pack_items_set_updated_at
before update on public.shared_pack_items
for each row execute function public.set_updated_at();

create or replace function public.shared_pack_normalize_invite_code_v1(
  p_invite_code text
)
returns text
language sql
immutable
as $$
  select upper(regexp_replace(coalesce(p_invite_code, ''), '[-[:space:]]+', '', 'g'));
$$;

create or replace function public.shared_pack_identity_matches_v1(
  p_identity_id uuid
)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select auth.uid() is null or auth.uid() = p_identity_id;
$$;

create or replace function public.shared_pack_is_active_member_v1(
  p_pack_id uuid,
  p_identity_id uuid
)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.shared_pack_members m
    where m.pack_id = p_pack_id
      and m.member_identity_id = p_identity_id
      and m.removed_at is null
  );
$$;

create or replace function public.shared_pack_is_owner_v1(
  p_pack_id uuid,
  p_identity_id uuid
)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.shared_pack_members m
    where m.pack_id = p_pack_id
      and m.member_identity_id = p_identity_id
      and m.role = 'owner'
      and m.removed_at is null
  );
$$;

create or replace function public.shared_pack_random_invite_code_v1()
returns text
language plpgsql
volatile
as $$
declare
  v_charset constant text := 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  v_code text := '';
  v_index integer;
begin
  for v_index in 1..6 loop
    v_code := v_code || substr(
      v_charset,
      floor(random() * length(v_charset) + 1)::integer,
      1
    );
  end loop;

  return v_code;
end;
$$;

create or replace function public.shared_pack_create_pack_v1(
  p_pack_name text,
  p_owner_identity_id uuid
)
returns table (
  remote_pack_id uuid,
  pack_name text,
  owner_membership_id uuid
)
language plpgsql
security definer
set search_path = public
as $$
begin
  if not public.shared_pack_identity_matches_v1(p_owner_identity_id) then
    raise exception 'shared_pack.identity_mismatch';
  end if;

  if length(btrim(coalesce(p_pack_name, ''))) = 0 then
    raise exception 'shared_pack.name_required';
  end if;

  insert into public.shared_packs (name, owner_identity_id)
  values (btrim(p_pack_name), p_owner_identity_id)
  returning id, name into remote_pack_id, pack_name;

  insert into public.shared_pack_members (
    pack_id,
    member_identity_id,
    role
  )
  values (
    remote_pack_id,
    p_owner_identity_id,
    'owner'
  )
  returning id into owner_membership_id;

  return next;
end;
$$;

create or replace function public.shared_pack_generate_invite_v1(
  p_pack_id uuid,
  p_requester_identity_id uuid
)
returns table (
  invite_id uuid,
  invite_code text,
  expires_at timestamptz
)
language plpgsql
security definer
set search_path = public
as $$
declare
  v_code text;
  v_attempt integer;
begin
  if not public.shared_pack_identity_matches_v1(p_requester_identity_id) then
    raise exception 'shared_pack.identity_mismatch';
  end if;

  if not public.shared_pack_is_owner_v1(p_pack_id, p_requester_identity_id) then
    raise exception 'shared_pack.owner_required';
  end if;

  select i.id, i.code, i.expires_at
  into invite_id, invite_code, expires_at
  from public.shared_pack_invites i
  where i.pack_id = p_pack_id
    and i.revoked_at is null
    and (i.expires_at is null or i.expires_at > now())
  order by i.created_at desc
  limit 1;

  if invite_id is not null then
    return next;
    return;
  end if;

  for v_attempt in 1..20 loop
    v_code := public.shared_pack_random_invite_code_v1();

    begin
      insert into public.shared_pack_invites (
        pack_id,
        code,
        created_by_identity_id
      )
      values (
        p_pack_id,
        v_code,
        p_requester_identity_id
      )
      returning id, code, shared_pack_invites.expires_at
      into invite_id, invite_code, expires_at;

      return next;
      return;
    exception
      when unique_violation then
        -- Retry on invite code collision.
    end;
  end loop;

  raise exception 'shared_pack.invite_code_generation_failed';
end;
$$;

create or replace function public.shared_pack_preview_invite_v1(
  p_invite_code text
)
returns table (
  remote_pack_id uuid,
  pack_name text,
  is_joinable boolean
)
language plpgsql
security definer
set search_path = public
as $$
declare
  v_code text := public.shared_pack_normalize_invite_code_v1(p_invite_code);
begin
  select p.id,
         p.name,
         (
           i.revoked_at is null
           and (i.expires_at is null or i.expires_at > now())
           and p.archived_at is null
         )
  into remote_pack_id, pack_name, is_joinable
  from public.shared_pack_invites i
  join public.shared_packs p on p.id = i.pack_id
  where i.code = v_code
  limit 1;

  if remote_pack_id is null then
    is_joinable := false;
  end if;

  return next;
end;
$$;

create or replace function public.shared_pack_join_by_invite_v1(
  p_invite_code text,
  p_joiner_identity_id uuid
)
returns table (
  remote_pack_id uuid,
  membership_id uuid,
  pack_name text
)
language plpgsql
security definer
set search_path = public
as $$
declare
  v_code text := public.shared_pack_normalize_invite_code_v1(p_invite_code);
begin
  if not public.shared_pack_identity_matches_v1(p_joiner_identity_id) then
    raise exception 'shared_pack.identity_mismatch';
  end if;

  select p.id, p.name
  into remote_pack_id, pack_name
  from public.shared_pack_invites i
  join public.shared_packs p on p.id = i.pack_id
  where i.code = v_code
    and i.revoked_at is null
    and (i.expires_at is null or i.expires_at > now())
    and p.archived_at is null
  limit 1;

  if remote_pack_id is null then
    raise exception 'shared_pack.invite_not_joinable';
  end if;

  select m.id
  into membership_id
  from public.shared_pack_members m
  where m.pack_id = remote_pack_id
    and m.member_identity_id = p_joiner_identity_id
    and m.removed_at is null
  limit 1;

  if membership_id is null then
    insert into public.shared_pack_members (
      pack_id,
      member_identity_id,
      role
    )
    values (
      remote_pack_id,
      p_joiner_identity_id,
      'member'
    )
    returning id into membership_id;
  end if;

  return next;
end;
$$;

create or replace function public.shared_pack_fetch_snapshot_v1(
  p_pack_id uuid,
  p_requester_identity_id uuid
)
returns table (
  remote_pack_id uuid,
  pack_name text,
  requester_role text,
  items jsonb
)
language plpgsql
security definer
set search_path = public
as $$
begin
  if not public.shared_pack_identity_matches_v1(p_requester_identity_id) then
    raise exception 'shared_pack.identity_mismatch';
  end if;

  if not public.shared_pack_is_active_member_v1(
    p_pack_id,
    p_requester_identity_id
  ) then
    raise exception 'shared_pack.member_required';
  end if;

  select p.id,
         p.name,
         m.role,
         coalesce(
           jsonb_agg(
             jsonb_build_object(
               'id', i.id,
               'title', i.title,
               'notes', i.notes,
               'schedule_payload', i.schedule_payload,
               'state', i.state,
               'last_completed_at', i.last_completed_at,
               'updated_by_identity_id', i.updated_by_identity_id,
               'created_at', i.created_at,
               'updated_at', i.updated_at,
               'archived_at', i.archived_at
             )
             order by i.created_at, i.id
           ) filter (where i.id is not null),
           '[]'::jsonb
         )
  into remote_pack_id, pack_name, requester_role, items
  from public.shared_packs p
  join public.shared_pack_members m
    on m.pack_id = p.id
   and m.member_identity_id = p_requester_identity_id
   and m.removed_at is null
  left join public.shared_pack_items i
    on i.pack_id = p.id
   and i.archived_at is null
  where p.id = p_pack_id
    and p.archived_at is null
  group by p.id, p.name, m.role;

  return next;
end;
$$;

create or replace function public.shared_pack_update_item_state_v1(
  p_item_id uuid,
  p_requester_identity_id uuid,
  p_state text,
  p_completed_at timestamptz default null
)
returns table (
  remote_item_id uuid,
  remote_pack_id uuid,
  state text,
  last_completed_at timestamptz,
  updated_at timestamptz
)
language plpgsql
security definer
set search_path = public
as $$
declare
  v_pack_id uuid;
begin
  if not public.shared_pack_identity_matches_v1(p_requester_identity_id) then
    raise exception 'shared_pack.identity_mismatch';
  end if;

  if length(btrim(coalesce(p_state, ''))) = 0 then
    raise exception 'shared_pack.state_required';
  end if;

  select i.pack_id
  into v_pack_id
  from public.shared_pack_items i
  where i.id = p_item_id
    and i.archived_at is null;

  if v_pack_id is null then
    raise exception 'shared_pack.item_not_found';
  end if;

  if not public.shared_pack_is_active_member_v1(
    v_pack_id,
    p_requester_identity_id
  ) then
    raise exception 'shared_pack.member_required';
  end if;

  update public.shared_pack_items i
  set state = btrim(p_state),
      last_completed_at = p_completed_at,
      updated_by_identity_id = p_requester_identity_id
  where i.id = p_item_id
  returning i.id, i.pack_id, i.state, i.last_completed_at, i.updated_at
  into remote_item_id, remote_pack_id, state, last_completed_at, updated_at;

  return next;
end;
$$;

alter table public.shared_packs enable row level security;
alter table public.shared_pack_members enable row level security;
alter table public.shared_pack_invites enable row level security;
alter table public.shared_pack_items enable row level security;

drop policy if exists shared_packs_select_active_members_v1
  on public.shared_packs;
create policy shared_packs_select_active_members_v1
  on public.shared_packs
  for select
  using (
    public.shared_pack_is_active_member_v1(id, auth.uid())
  );

drop policy if exists shared_pack_members_select_active_members_v1
  on public.shared_pack_members;
create policy shared_pack_members_select_active_members_v1
  on public.shared_pack_members
  for select
  using (
    public.shared_pack_is_active_member_v1(pack_id, auth.uid())
  );

drop policy if exists shared_pack_invites_select_owner_v1
  on public.shared_pack_invites;
create policy shared_pack_invites_select_owner_v1
  on public.shared_pack_invites
  for select
  using (
    public.shared_pack_is_owner_v1(pack_id, auth.uid())
  );

drop policy if exists shared_pack_invites_insert_owner_v1
  on public.shared_pack_invites;
create policy shared_pack_invites_insert_owner_v1
  on public.shared_pack_invites
  for insert
  with check (
    public.shared_pack_is_owner_v1(pack_id, auth.uid())
  );

drop policy if exists shared_pack_invites_update_owner_v1
  on public.shared_pack_invites;
create policy shared_pack_invites_update_owner_v1
  on public.shared_pack_invites
  for update
  using (
    public.shared_pack_is_owner_v1(pack_id, auth.uid())
  )
  with check (
    public.shared_pack_is_owner_v1(pack_id, auth.uid())
  );

drop policy if exists shared_pack_items_select_active_members_v1
  on public.shared_pack_items;
create policy shared_pack_items_select_active_members_v1
  on public.shared_pack_items
  for select
  using (
    public.shared_pack_is_active_member_v1(pack_id, auth.uid())
  );

drop policy if exists shared_pack_items_update_active_members_v1
  on public.shared_pack_items;
create policy shared_pack_items_update_active_members_v1
  on public.shared_pack_items
  for update
  using (
    public.shared_pack_is_active_member_v1(pack_id, auth.uid())
  )
  with check (
    public.shared_pack_is_active_member_v1(pack_id, auth.uid())
  );
