-- Reminder App Phase 5L Member Sync Awareness / Pack Freshness MVP
-- Manual incremental patch only. Do not auto-apply to production.
--
-- Apply order:
--   1. docs/core/sql/phase3c_supabase_minimal_poc.sql
--   2. docs/core/sql/phase4a_supabase_invite_membership_mvp.sql
--   3. docs/core/sql/phase4c_supabase_remote_member_actions_mvp.sql
--   4. docs/core/sql/phase4d_supabase_realtime_soft_notification_poc.sql
--   5. docs/core/sql/phase4e_supabase_remote_collaboration_hardening.sql
--   6. docs/core/sql/phase5l_member_sync_awareness_mvp.sql
--
-- Phase 5L stores per-member pack data import watermarks. It is pack-data
-- freshness only: no human-attention semantics, no presence, no heartbeat,
-- and no background worker.
--
-- REVIEW: Validate in Supabase SQL editor or local Supabase CLI before use.

create table if not exists public.pack_member_sync_states (
  id uuid primary key default gen_random_uuid(),
  pack_id uuid not null references public.packs(id) on delete cascade,
  user_id uuid not null references public.profiles(id) on delete cascade,
  last_snapshot_pulled_at timestamptz,
  last_imported_at timestamptz,
  last_seen_activity_event_id uuid references public.activity_events(id)
    on delete set null,
  last_seen_activity_at timestamptz,
  last_successful_push_at timestamptz,
  last_sync_error_at timestamptz,
  last_sync_error_code text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint pack_member_sync_states_pack_user_unique unique (pack_id, user_id)
);

create index if not exists pack_member_sync_states_pack_idx
  on public.pack_member_sync_states(pack_id);

create index if not exists pack_member_sync_states_user_idx
  on public.pack_member_sync_states(user_id);

alter table public.pack_member_sync_states enable row level security;

drop policy if exists "Active same-pack members read sync states"
  on public.pack_member_sync_states;
create policy "Active same-pack members read sync states"
  on public.pack_member_sync_states
  for select
  using (
    exists (
      select 1
      from public.pack_members caller
      where caller.pack_id = pack_member_sync_states.pack_id
        and caller.user_id = auth.uid()
        and caller.status = 'active'
    )
    and exists (
      select 1
      from public.pack_members target_member
      where target_member.pack_id = pack_member_sync_states.pack_id
        and target_member.user_id = pack_member_sync_states.user_id
        and target_member.status = 'active'
    )
  );

drop policy if exists "Active members insert own sync state"
  on public.pack_member_sync_states;
create policy "Active members insert own sync state"
  on public.pack_member_sync_states
  for insert
  with check (
    user_id = auth.uid()
    and exists (
      select 1
      from public.pack_members caller
      where caller.pack_id = pack_member_sync_states.pack_id
        and caller.user_id = auth.uid()
        and caller.status = 'active'
    )
  );

drop policy if exists "Active members update own sync state"
  on public.pack_member_sync_states;
create policy "Active members update own sync state"
  on public.pack_member_sync_states
  for update
  using (
    user_id = auth.uid()
    and exists (
      select 1
      from public.pack_members caller
      where caller.pack_id = pack_member_sync_states.pack_id
        and caller.user_id = auth.uid()
        and caller.status = 'active'
    )
  )
  with check (
    user_id = auth.uid()
    and exists (
      select 1
      from public.pack_members caller
      where caller.pack_id = pack_member_sync_states.pack_id
        and caller.user_id = auth.uid()
        and caller.status = 'active'
    )
  );

create or replace function public.report_pack_snapshot_imported(
  target_pack_id uuid,
  latest_activity_event_id uuid default null,
  latest_activity_at timestamptz default null
)
returns table (
  status text,
  pack_id uuid,
  user_id uuid,
  last_imported_at timestamptz,
  last_seen_activity_event_id uuid,
  last_seen_activity_at timestamptz
)
language plpgsql
security invoker
set search_path = public
as $$
declare
  current_user_id uuid := auth.uid();
  latest_event public.activity_events%rowtype;
  imported_at timestamptz := now();
  resolved_event_id uuid := report_pack_snapshot_imported.latest_activity_event_id;
  resolved_activity_at timestamptz := report_pack_snapshot_imported.latest_activity_at;
  upserted public.pack_member_sync_states%rowtype;
begin
  if current_user_id is null then
    raise exception 'auth required';
  end if;

  if not public.is_pack_member(target_pack_id) then
    raise exception 'active pack member required';
  end if;

  if resolved_event_id is not null then
    select * into latest_event
    from public.activity_events ae
    where ae.id = resolved_event_id
      and ae.pack_id = target_pack_id;

    if latest_event.id is null then
      raise exception 'activity event not found';
    end if;

    resolved_activity_at := coalesce(resolved_activity_at, latest_event.created_at);
  elsif resolved_activity_at is null then
    select * into latest_event
    from public.activity_events ae
    where ae.pack_id = target_pack_id
    order by ae.created_at desc, ae.id desc
    limit 1;

    resolved_event_id := latest_event.id;
    resolved_activity_at := latest_event.created_at;
  end if;

  insert into public.pack_member_sync_states (
    pack_id,
    user_id,
    last_snapshot_pulled_at,
    last_imported_at,
    last_seen_activity_event_id,
    last_seen_activity_at,
    last_sync_error_at,
    last_sync_error_code,
    created_at,
    updated_at
  )
  values (
    target_pack_id,
    current_user_id,
    imported_at,
    imported_at,
    resolved_event_id,
    resolved_activity_at,
    null,
    null,
    imported_at,
    imported_at
  )
  on conflict (pack_id, user_id) do update
  set
    last_snapshot_pulled_at = excluded.last_snapshot_pulled_at,
    last_imported_at = excluded.last_imported_at,
    last_seen_activity_event_id = excluded.last_seen_activity_event_id,
    last_seen_activity_at = excluded.last_seen_activity_at,
    last_sync_error_at = null,
    last_sync_error_code = null,
    updated_at = excluded.updated_at
  returning * into upserted;

  return query select
    'reported'::text,
    upserted.pack_id,
    upserted.user_id,
    upserted.last_imported_at,
    upserted.last_seen_activity_event_id,
    upserted.last_seen_activity_at;
end;
$$;

comment on function public.report_pack_snapshot_imported(uuid, uuid, timestamptz) is
  'Phase 5L RPC. Active members report that this app imported pack data up to the supplied activity watermark.';

create or replace function public.get_pack_member_freshness(
  target_pack_id uuid
)
returns table (
  user_id uuid,
  display_name text,
  role text,
  member_status text,
  latest_activity_event_id uuid,
  latest_activity_at timestamptz,
  last_imported_at timestamptz,
  last_seen_activity_event_id uuid,
  last_seen_activity_at timestamptz,
  freshness_status text
)
language plpgsql
security invoker
set search_path = public
as $$
declare
  current_user_id uuid := auth.uid();
  latest_event public.activity_events%rowtype;
begin
  if current_user_id is null then
    raise exception 'auth required';
  end if;

  if not public.is_pack_member(target_pack_id) then
    raise exception 'active pack member required';
  end if;

  select * into latest_event
  from public.activity_events ae
  where ae.pack_id = target_pack_id
  order by ae.created_at desc, ae.id desc
  limit 1;

  return query
  select
    pm.user_id,
    p.display_name,
    pm.role,
    pm.status,
    latest_event.id,
    latest_event.created_at,
    state.last_imported_at,
    state.last_seen_activity_event_id,
    state.last_seen_activity_at,
    case
      when state.id is null or state.last_imported_at is null then
        'no_sync_report'::text
      when latest_event.id is null then
        'up_to_date'::text
      when state.last_seen_activity_at is null then
        'possibly_stale'::text
      when state.last_seen_activity_at >= latest_event.created_at then
        'up_to_date'::text
      else
        'possibly_stale'::text
    end
  from public.pack_members pm
  left join public.profiles p on p.id = pm.user_id
  left join public.pack_member_sync_states state
    on state.pack_id = pm.pack_id
   and state.user_id = pm.user_id
  where pm.pack_id = target_pack_id
    and pm.status = 'active'
  order by pm.joined_at, pm.user_id;
end;
$$;

comment on function public.get_pack_member_freshness(uuid) is
  'Phase 5L RPC. Active members query conservative pack-data freshness for active members in the same pack.';

grant select, insert, update on table public.pack_member_sync_states
  to authenticated;

revoke all on function public.report_pack_snapshot_imported(uuid, uuid, timestamptz)
  from public;
grant execute on function public.report_pack_snapshot_imported(uuid, uuid, timestamptz)
  to authenticated;

revoke all on function public.get_pack_member_freshness(uuid) from public;
grant execute on function public.get_pack_member_freshness(uuid)
  to authenticated;
