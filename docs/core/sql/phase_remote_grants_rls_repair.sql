-- Reminder App Supabase Remote Grants / RLS Repair
-- Manual idempotent patch only. Do not auto-apply to production.
--
-- Apply after the remote shared-pack SQL phases currently used by the project:
--   1. docs/core/sql/phase3c_supabase_minimal_poc.sql
--   2. docs/core/sql/phase4a_supabase_invite_membership_mvp.sql
--   3. docs/core/sql/phase4c_supabase_remote_member_actions_mvp.sql
--   4. docs/core/sql/phase4d_supabase_realtime_soft_notification_poc.sql
--   5. docs/core/sql/phase4e_supabase_remote_collaboration_hardening.sql
--
-- This patch repairs table and function privileges for the authenticated role.
-- It does not disable RLS, does not grant shared-pack private data access to
-- anon, does not add hard-delete privileges, and does not require privileged
-- app credentials.

-- ---------------------------------------------------------------------------
-- Profile bootstrap RPC
-- ---------------------------------------------------------------------------

create or replace function public.upsert_current_profile(display_name text)
returns uuid
language plpgsql
security definer
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

comment on function public.upsert_current_profile(text) is
  'Bootstrap current authenticated user profile from auth.uid(); callers cannot provide arbitrary user ids.';

-- ---------------------------------------------------------------------------
-- Shared pack bootstrap transaction RPC
-- ---------------------------------------------------------------------------

create or replace function public.create_shared_pack(
  pack_name text,
  description text default null
)
returns uuid
language plpgsql
security definer
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

comment on function public.create_shared_pack(text, text) is
  'Bootstrap transaction RPC for creating a shared pack and current-user host membership from auth.uid(); callers cannot provide arbitrary user ids.';

-- ---------------------------------------------------------------------------
-- Table grants
-- ---------------------------------------------------------------------------

grant select, insert, update on table public.profiles to authenticated;
grant select, insert, update on table public.packs to authenticated;
grant select, insert, update on table public.pack_members to authenticated;
grant select, insert, update on table public.items to authenticated;
grant select, insert, update on table public.item_completions to authenticated;
grant select, insert, update on table public.resources to authenticated;
grant select, insert, update on table public.resource_events to authenticated;
grant select, insert, update on table public.stages to authenticated;
grant select, insert, update on table public.stage_acknowledgements to authenticated;
grant select, insert on table public.activity_events to authenticated;
grant select, insert, update on table public.pack_invites to authenticated;

-- ---------------------------------------------------------------------------
-- Function execute grants
-- ---------------------------------------------------------------------------

revoke all on function public.upsert_current_profile(text) from public;
grant execute on function public.upsert_current_profile(text) to authenticated;

revoke all on function public.create_shared_pack(text, text) from public;
grant execute on function public.create_shared_pack(text, text) to authenticated;

revoke all on function public.create_pack_item(uuid, text, text) from public;
grant execute on function public.create_pack_item(uuid, text, text) to authenticated;

revoke all on function public.complete_pack_item(uuid, text) from public;
grant execute on function public.complete_pack_item(uuid, text) to authenticated;

revoke all on function public.undo_pack_item_completion(uuid, text) from public;
grant execute on function public.undo_pack_item_completion(uuid, text) to authenticated;

revoke all on function public.create_pack_invite(uuid, integer, integer) from public;
grant execute on function public.create_pack_invite(uuid, integer, integer) to authenticated;

revoke all on function public.ensure_active_pack_invite(uuid, integer, integer) from public;
grant execute on function public.ensure_active_pack_invite(uuid, integer, integer) to authenticated;

revoke all on function public.fetch_pack_invite_state(uuid) from public;
grant execute on function public.fetch_pack_invite_state(uuid) to authenticated;

revoke all on function public.refresh_pack_invite(uuid, integer, integer) from public;
grant execute on function public.refresh_pack_invite(uuid, integer, integer) to authenticated;

revoke all on function public.join_pack_with_invite(text) from public;
grant execute on function public.join_pack_with_invite(text) to authenticated;

revoke all on function public.revoke_pack_invite(uuid) from public;
grant execute on function public.revoke_pack_invite(uuid) to authenticated;

revoke all on function public.is_pack_member(uuid) from public;
grant execute on function public.is_pack_member(uuid) to authenticated;

revoke all on function public.is_pack_host(uuid) from public;
grant execute on function public.is_pack_host(uuid) to authenticated;

revoke all on function public.hash_pack_invite_code(text, uuid) from public;
grant execute on function public.hash_pack_invite_code(text, uuid) to authenticated;

revoke all on function public.generate_pack_invite_code() from public;
grant execute on function public.generate_pack_invite_code() to authenticated;

-- ---------------------------------------------------------------------------
-- Manual audit query
-- ---------------------------------------------------------------------------
-- Run this after applying the patch in Supabase SQL Editor:
--
-- select
--   table_name,
--   has_table_privilege('authenticated', 'public.' || table_name, 'SELECT') as can_select,
--   has_table_privilege('authenticated', 'public.' || table_name, 'INSERT') as can_insert,
--   has_table_privilege('authenticated', 'public.' || table_name, 'UPDATE') as can_update,
--   has_table_privilege('authenticated', 'public.' || table_name, 'DELETE') as can_delete
-- from information_schema.tables
-- where table_schema = 'public'
--   and table_type = 'BASE TABLE'
-- order by table_name;
--
-- Verify create_shared_pack after applying this patch:
--
-- select
--   p.proname,
--   pg_get_function_identity_arguments(p.oid) as signature,
--   p.prosecdef as is_security_definer,
--   has_function_privilege('anon', p.oid, 'EXECUTE') as anon_can_execute,
--   has_function_privilege('authenticated', p.oid, 'EXECUTE') as authenticated_can_execute,
--   p.proconfig as function_config
-- from pg_proc p
-- join pg_namespace n on n.oid = p.pronamespace
-- where n.nspname = 'public'
--   and p.proname = 'create_shared_pack';
