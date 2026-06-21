-- Reminder App Phase 4A Supabase Remote Invite Code & Membership MVP
-- Manual incremental draft only. Apply after phase3c_supabase_minimal_poc.sql.
-- Do not auto-apply to production.
-- REVIEW: Validate in Supabase SQL editor or local Supabase CLI before use.
-- Invite code is a temporary bearer secret. Only code_hash is stored.
-- Activity events and local backups must never store the full invite code.

create extension if not exists pgcrypto;
-- REVIEW: Supabase SQL editor must allow pgcrypto. This SQL is manually
-- applied by a project operator.

-- ---------------------------------------------------------------------------
-- Table
-- ---------------------------------------------------------------------------

create table if not exists public.pack_invites (
  id uuid primary key default gen_random_uuid(),
  pack_id uuid not null references public.packs(id) on delete cascade,
  code_hash text not null,
  created_by_user_id uuid not null references public.profiles(id),
  role_to_grant text not null default 'member'
    check (role_to_grant in ('member')),
  status text not null default 'active'
    check (status in ('active', 'revoked', 'expired')),
  expires_at timestamptz not null,
  max_uses integer not null default 10 check (max_uses > 0),
  used_count integer not null default 0 check (used_count >= 0),
  created_at timestamptz not null default now(),
  revoked_at timestamptz null,
  metadata jsonb null,
  check (expires_at > created_at),
  check (used_count <= max_uses)
);

create index if not exists pack_invites_pack_id_idx
  on public.pack_invites(pack_id);

create unique index if not exists pack_invites_code_hash_unique_idx
  on public.pack_invites(code_hash);

create index if not exists pack_invites_status_expires_idx
  on public.pack_invites(status, expires_at);

-- ---------------------------------------------------------------------------
-- RLS
-- ---------------------------------------------------------------------------

alter table public.pack_invites enable row level security;

-- Postgres does not support CREATE POLICY IF NOT EXISTS. Drops make this draft
-- easier to re-run during development.

drop policy if exists "pack_invites_select_host" on public.pack_invites;
create policy "pack_invites_select_host"
on public.pack_invites for select
to authenticated
using (public.is_pack_host(pack_id));

drop policy if exists "pack_invites_insert_blocked" on public.pack_invites;
create policy "pack_invites_insert_blocked"
on public.pack_invites for insert
to authenticated
with check (false);

drop policy if exists "pack_invites_update_host" on public.pack_invites;
create policy "pack_invites_update_host"
on public.pack_invites for update
to authenticated
using (public.is_pack_host(pack_id))
with check (public.is_pack_host(pack_id));

-- No delete policy: invites are revoked, not hard-deleted.
-- Ordinary members do not need invite list access in Phase 4A.
-- Joining by invite code must happen through join_pack_with_invite().

-- REVIEW: pack_members direct insert remains host-only from Phase 3C. The join
-- RPC below uses security definer and must validate invite state before it
-- creates/reactivates membership.

-- ---------------------------------------------------------------------------
-- Helpers
-- ---------------------------------------------------------------------------

create or replace function public.hash_pack_invite_code(
  invite_code text,
  target_pack_id uuid
)
returns text
language sql
security invoker
set search_path = public
as $$
  select encode(
    digest(upper(regexp_replace(invite_code, '[[:space:]]+', '', 'g')) || ':' || target_pack_id::text, 'sha256'),
    'hex'
  );
$$;

create or replace function public.generate_pack_invite_code()
returns text
language plpgsql
security invoker
set search_path = public
as $$
declare
  raw_code text;
begin
  raw_code := upper(encode(gen_random_bytes(6), 'hex'));
  return substring(raw_code from 1 for 4) || '-' ||
         substring(raw_code from 5 for 4) || '-' ||
         substring(raw_code from 9 for 4);
end;
$$;

-- ---------------------------------------------------------------------------
-- RPC / Transaction Functions
-- ---------------------------------------------------------------------------

-- REVIEW: security definer is used so the RPC can insert invite rows while
-- direct client inserts remain blocked. The function validates host membership.
create or replace function public.create_pack_invite(
  target_pack_id uuid,
  expires_in_days integer default 7,
  max_uses_limit integer default 10
)
returns table (
  invite_id uuid,
  invite_code text,
  expires_at timestamptz,
  max_uses integer
)
language plpgsql
security definer
set search_path = public
as $$
declare
  current_user_id uuid := auth.uid();
  generated_code text;
  generated_hash text;
  created_invite_id uuid;
  created_expires_at timestamptz;
  resolved_max_uses integer;
  attempts integer := 0;
begin
  if current_user_id is null then
    raise exception 'auth required';
  end if;

  if not public.is_pack_host(target_pack_id) then
    raise exception 'pack host required';
  end if;

  if expires_in_days is null or expires_in_days <= 0 then
    expires_in_days := 7;
  end if;

  resolved_max_uses := coalesce(nullif(max_uses_limit, 0), 10);
  if resolved_max_uses < 0 then
    resolved_max_uses := 10;
  end if;

  loop
    attempts := attempts + 1;
    generated_code := public.generate_pack_invite_code();
    generated_hash := public.hash_pack_invite_code(generated_code, target_pack_id);
    begin
      insert into public.pack_invites (
        pack_id,
        code_hash,
        created_by_user_id,
        role_to_grant,
        status,
        expires_at,
        max_uses,
        used_count,
        metadata
      )
      values (
        target_pack_id,
        generated_hash,
        current_user_id,
        'member',
        'active',
        now() + make_interval(days => expires_in_days),
        resolved_max_uses,
        0,
        jsonb_build_object('version', 'phase4a')
      )
      returning id, pack_invites.expires_at
      into created_invite_id, created_expires_at;
      exit;
    exception when unique_violation then
      if attempts >= 5 then
        raise;
      end if;
    end;
  end loop;

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
    'pack_invite',
    created_invite_id,
    'invite_created',
    jsonb_build_object('max_uses', resolved_max_uses, 'expires_at', created_expires_at)
  );

  return query select
    created_invite_id,
    generated_code,
    created_expires_at,
    resolved_max_uses;
end;
$$;

-- REVIEW: security definer is used for the membership transaction. It must not
-- grant access unless the invite is active, unexpired, and under max_uses.
create or replace function public.join_pack_with_invite(invite_code text)
returns table (
  status text,
  pack_id uuid,
  member_id uuid,
  role text
)
language plpgsql
security definer
set search_path = public
as $$
declare
  current_user_id uuid := auth.uid();
  normalized_code text;
  target_invite public.pack_invites%rowtype;
  existing_member public.pack_members%rowtype;
  joined_member_id uuid;
begin
  if current_user_id is null then
    raise exception 'auth required';
  end if;

  normalized_code := upper(regexp_replace(coalesce(invite_code, ''), '[[:space:]]+', '', 'g'));
  if normalized_code = '' then
    raise exception 'invite invalid';
  end if;

  select pi.*
  into target_invite
  from public.pack_invites pi
  where pi.code_hash = public.hash_pack_invite_code(normalized_code, pi.pack_id)
  order by pi.created_at desc
  limit 1;

  if target_invite.id is null then
    raise exception 'invite invalid';
  end if;

  if target_invite.status <> 'active' then
    raise exception 'invite invalid';
  end if;

  if target_invite.expires_at <= now() then
    update public.pack_invites
    set status = 'expired'
    where id = target_invite.id
      and status = 'active';
    raise exception 'invite expired';
  end if;

  if target_invite.used_count >= target_invite.max_uses then
    raise exception 'invite max uses reached';
  end if;

  if not exists (select 1 from public.profiles p where p.id = current_user_id) then
    raise exception 'profile required';
  end if;

  select pm.*
  into existing_member
  from public.pack_members pm
  where pm.pack_id = target_invite.pack_id
    and pm.user_id = current_user_id
  limit 1;

  if existing_member.id is not null and existing_member.status = 'active' then
    return query select
      'already_member'::text,
      target_invite.pack_id,
      existing_member.id,
      existing_member.role;
    return;
  end if;

  if existing_member.id is not null then
    update public.pack_members
    set role = 'member',
        status = 'active',
        joined_at = now(),
        removed_at = null,
        updated_at = now()
    where id = existing_member.id
    returning id into joined_member_id;
  else
    insert into public.pack_members (
      pack_id,
      user_id,
      role,
      status
    )
    values (
      target_invite.pack_id,
      current_user_id,
      'member',
      'active'
    )
    returning id into joined_member_id;
  end if;

  update public.pack_invites
  set used_count = used_count + 1
  where id = target_invite.id;

  insert into public.activity_events (
    pack_id,
    actor_user_id,
    entity_type,
    entity_id,
    action,
    metadata_json
  )
  values (
    target_invite.pack_id,
    current_user_id,
    'pack_member',
    joined_member_id,
    'member_joined',
    jsonb_build_object('via', 'invite_code')
  );

  return query select
    'joined'::text,
    target_invite.pack_id,
    joined_member_id,
    'member'::text;
end;
$$;

-- REVIEW: security definer is used so host revocation can be transactionally
-- logged while hard delete remains unavailable.
create or replace function public.revoke_pack_invite(target_invite_id uuid)
returns table (
  status text,
  invite_id uuid
)
language plpgsql
security definer
set search_path = public
as $$
declare
  current_user_id uuid := auth.uid();
  target_invite public.pack_invites%rowtype;
begin
  if current_user_id is null then
    raise exception 'auth required';
  end if;

  select pi.*
  into target_invite
  from public.pack_invites pi
  where pi.id = target_invite_id;

  if target_invite.id is null then
    raise exception 'invite invalid';
  end if;

  if not public.is_pack_host(target_invite.pack_id) then
    raise exception 'pack host required';
  end if;

  if target_invite.status = 'revoked' then
    return query select 'already_revoked'::text, target_invite.id;
    return;
  end if;

  update public.pack_invites
  set status = 'revoked',
      revoked_at = now()
  where id = target_invite.id;

  insert into public.activity_events (
    pack_id,
    actor_user_id,
    entity_type,
    entity_id,
    action
  )
  values (
    target_invite.pack_id,
    current_user_id,
    'pack_invite',
    target_invite.id,
    'invite_revoked'
  );

  return query select 'revoked'::text, target_invite.id;
end;
$$;

-- Phase 4A intentionally does not add resources, stages, realtime, production
-- invite UI, or local merge support.
