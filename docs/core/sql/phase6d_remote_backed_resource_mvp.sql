-- Phase 6D remote-backed Resource sharing MVP.
--
-- Apply after the Phase 3C / 4E shared pack SQL foundation and Phase 6 item
-- CRUD patch. This patch adds Resource current projections, Resource event
-- history, and controlled RPCs for the local-first sync_outbox path.
-- It does not add Stage sharing, hard delete, background sync, realtime import,
-- widget remote CRUD, notification remote sync, member management, or conflict UI.

create table if not exists public.resources (
  id uuid primary key default gen_random_uuid(),
  pack_id uuid not null references public.packs(id),
  title text not null,
  description text null,
  status text not null default 'active',
  type text not null,
  time_anchor_date timestamptz null,
  time_duration_days integer null,
  time_expected_before_days integer null,
  time_warning_before_days integer null,
  time_danger_before_days integer null,
  quantity_current integer null,
  quantity_unit_label text null,
  quantity_expected_threshold integer null,
  quantity_warning_threshold integer null,
  quantity_danger_threshold integer null,
  last_refilled_at timestamptz null,
  created_by_user_id uuid not null references public.profiles(id),
  updated_by_user_id uuid not null references public.profiles(id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  archived_at timestamptz null,
  deleted_at timestamptz null
);

create table if not exists public.resource_events (
  id uuid primary key default gen_random_uuid(),
  pack_id uuid not null references public.packs(id),
  resource_id uuid not null references public.resources(id),
  actor_user_id uuid not null references public.profiles(id),
  change_type text not null,
  previous_value integer null,
  new_value integer null,
  delta_value integer null,
  unit text null,
  client_mutation_id text null,
  created_at timestamptz not null default now(),
  metadata_json jsonb null
);

create unique index if not exists resource_events_client_mutation_unique
  on public.resource_events(pack_id, client_mutation_id)
  where client_mutation_id is not null;

alter table public.resources enable row level security;
alter table public.resource_events enable row level security;

drop policy if exists "active members can read resources" on public.resources;
create policy "active members can read resources"
  on public.resources for select
  using (public.is_pack_member(pack_id));

drop policy if exists "active members can read resource events" on public.resource_events;
create policy "active members can read resource events"
  on public.resource_events for select
  using (public.is_pack_member(pack_id));

grant select, insert, update on public.resources to authenticated;
grant select, insert on public.resource_events to authenticated;

create or replace function public.resource_config_value(
  config jsonb,
  key text
) returns integer
language sql
immutable
as $$
  select case
    when config ? key and nullif(config ->> key, '') is not null
      then (config ->> key)::integer
    else null
  end
$$;

create or replace function public.create_pack_resource(
  target_pack_id uuid,
  title text,
  description text default null,
  resource_type text default 'quantityBased',
  config_json jsonb default '{}'::jsonb,
  client_mutation_id text default null
)
returns table(status text, resource_id uuid)
language plpgsql
security definer
set search_path = public
as $$
declare
  existing_event public.activity_events%rowtype;
  inserted_resource public.resources%rowtype;
begin
  if auth.uid() is null then
    raise exception 'remote_auth_required' using errcode = '28000';
  end if;
  if not public.is_pack_member(target_pack_id) then
    raise exception 'not_active_pack_member' using errcode = '42501';
  end if;
  if nullif(btrim(title), '') is null then
    raise exception 'resource_title_required' using errcode = '22023';
  end if;

  if client_mutation_id is not null then
    select * into existing_event
      from public.activity_events
     where pack_id = target_pack_id
       and action = 'resource_created'
       and metadata_json ->> 'client_mutation_id' = client_mutation_id
     order by created_at asc
     limit 1;
    if found then
      return query select 'already_created'::text, existing_event.entity_id;
      return;
    end if;
  end if;

  insert into public.resources (
    pack_id, title, description, status, type,
    time_anchor_date, time_duration_days, time_expected_before_days,
    time_warning_before_days, time_danger_before_days,
    quantity_current, quantity_unit_label, quantity_expected_threshold,
    quantity_warning_threshold, quantity_danger_threshold, last_refilled_at,
    created_by_user_id, updated_by_user_id, created_at, updated_at
  )
  values (
    target_pack_id, btrim(title), description, 'active', resource_type,
    nullif(config_json ->> 'timeAnchorDate', '')::timestamptz,
    public.resource_config_value(config_json, 'timeDurationDays'),
    public.resource_config_value(config_json, 'timeExpectedBeforeDays'),
    public.resource_config_value(config_json, 'timeWarningBeforeDays'),
    public.resource_config_value(config_json, 'timeDangerBeforeDays'),
    public.resource_config_value(config_json, 'quantityCurrent'),
    config_json ->> 'quantityUnitLabel',
    public.resource_config_value(config_json, 'quantityExpectedThreshold'),
    public.resource_config_value(config_json, 'quantityWarningThreshold'),
    public.resource_config_value(config_json, 'quantityDangerThreshold'),
    now(),
    auth.uid(), auth.uid(), now(), now()
  )
  returning * into inserted_resource;

  insert into public.activity_events (
    id, pack_id, actor_user_id, entity_type, entity_id, action, after_json,
    metadata_json, created_at
  )
  values (
    gen_random_uuid(), target_pack_id, auth.uid(), 'resource',
    inserted_resource.id, 'resource_created',
    jsonb_build_object('title', inserted_resource.title),
    jsonb_build_object('client_mutation_id', client_mutation_id),
    now()
  );

  return query select 'created'::text, inserted_resource.id;
end;
$$;

create or replace function public.update_pack_resource(
  target_resource_id uuid,
  title text,
  description text default null,
  config_json jsonb default '{}'::jsonb,
  client_mutation_id text default null
)
returns table(status text, resource_id uuid)
language plpgsql
security definer
set search_path = public
as $$
declare
  existing_resource public.resources%rowtype;
  before_payload jsonb;
begin
  if auth.uid() is null then
    raise exception 'remote_auth_required' using errcode = '28000';
  end if;
  select * into existing_resource from public.resources where id = target_resource_id;
  if not found then
    raise exception 'resource_not_found' using errcode = '02000';
  end if;
  if not public.is_pack_member(existing_resource.pack_id) then
    raise exception 'not_active_pack_member' using errcode = '42501';
  end if;
  if existing_resource.archived_at is not null or existing_resource.status = 'archived' then
    return query select 'already_archived'::text, existing_resource.id;
    return;
  end if;

  before_payload := jsonb_build_object('title', existing_resource.title);

  update public.resources
     set title = btrim(update_pack_resource.title),
         description = update_pack_resource.description,
         time_anchor_date = coalesce(nullif(config_json ->> 'timeAnchorDate', '')::timestamptz, time_anchor_date),
         time_duration_days = coalesce(public.resource_config_value(config_json, 'timeDurationDays'), time_duration_days),
         time_expected_before_days = public.resource_config_value(config_json, 'timeExpectedBeforeDays'),
         time_warning_before_days = public.resource_config_value(config_json, 'timeWarningBeforeDays'),
         time_danger_before_days = public.resource_config_value(config_json, 'timeDangerBeforeDays'),
         quantity_current = coalesce(public.resource_config_value(config_json, 'quantityCurrent'), quantity_current),
         quantity_unit_label = coalesce(config_json ->> 'quantityUnitLabel', quantity_unit_label),
         quantity_expected_threshold = public.resource_config_value(config_json, 'quantityExpectedThreshold'),
         quantity_warning_threshold = public.resource_config_value(config_json, 'quantityWarningThreshold'),
         quantity_danger_threshold = public.resource_config_value(config_json, 'quantityDangerThreshold'),
         updated_by_user_id = auth.uid(),
         updated_at = now()
   where id = target_resource_id
   returning * into existing_resource;

  insert into public.activity_events (
    id, pack_id, actor_user_id, entity_type, entity_id, action,
    before_json, after_json, metadata_json, created_at
  )
  values (
    gen_random_uuid(), existing_resource.pack_id, auth.uid(), 'resource',
    existing_resource.id, 'resource_updated', before_payload,
    jsonb_build_object('title', existing_resource.title),
    jsonb_build_object('client_mutation_id', client_mutation_id),
    now()
  );

  return query select 'updated'::text, existing_resource.id;
end;
$$;

create or replace function public.archive_pack_resource(
  target_resource_id uuid,
  client_mutation_id text default null
)
returns table(status text, resource_id uuid)
language plpgsql
security definer
set search_path = public
as $$
declare
  existing_resource public.resources%rowtype;
begin
  if auth.uid() is null then
    raise exception 'remote_auth_required' using errcode = '28000';
  end if;
  select * into existing_resource from public.resources where id = target_resource_id;
  if not found then
    raise exception 'resource_not_found' using errcode = '02000';
  end if;
  if not public.is_pack_member(existing_resource.pack_id) then
    raise exception 'not_active_pack_member' using errcode = '42501';
  end if;
  if existing_resource.archived_at is not null or existing_resource.status = 'archived' then
    return query select 'already_archived'::text, existing_resource.id;
    return;
  end if;

  update public.resources
     set status = 'archived',
         archived_at = now(),
         updated_by_user_id = auth.uid(),
         updated_at = now()
   where id = target_resource_id
   returning * into existing_resource;

  insert into public.activity_events (
    id, pack_id, actor_user_id, entity_type, entity_id, action,
    metadata_json, created_at
  )
  values (
    gen_random_uuid(), existing_resource.pack_id, auth.uid(), 'resource',
    existing_resource.id, 'resource_archived',
    jsonb_build_object('client_mutation_id', client_mutation_id),
    now()
  );

  return query select 'archived'::text, existing_resource.id;
end;
$$;

create or replace function public.apply_resource_event(
  target_resource_id uuid,
  change_type text,
  delta_value integer default null,
  new_value integer default null,
  unit text default null,
  client_mutation_id text default null,
  metadata_json jsonb default '{}'::jsonb
)
returns table(status text, resource_id uuid, event_id uuid, current_value integer, updated_at timestamptz)
language plpgsql
security definer
set search_path = public
as $$
declare
  existing_resource public.resources%rowtype;
  existing_event public.resource_events%rowtype;
  previous_value integer;
  resulting_value integer;
  inserted_event public.resource_events%rowtype;
begin
  if auth.uid() is null then
    raise exception 'remote_auth_required' using errcode = '28000';
  end if;
  select * into existing_resource from public.resources where id = target_resource_id;
  if not found then
    raise exception 'resource_not_found' using errcode = '02000';
  end if;
  if not public.is_pack_member(existing_resource.pack_id) then
    raise exception 'not_active_pack_member' using errcode = '42501';
  end if;
  if existing_resource.archived_at is not null or existing_resource.status = 'archived' then
    raise exception 'resource_archived' using errcode = '22023';
  end if;

  if client_mutation_id is not null then
    select * into existing_event
      from public.resource_events
     where pack_id = existing_resource.pack_id
       and client_mutation_id = apply_resource_event.client_mutation_id
     order by created_at asc
     limit 1;
    if found then
      return query
        select 'already_applied'::text, existing_event.resource_id,
               existing_event.id, existing_event.new_value, existing_event.created_at;
      return;
    end if;
  end if;

  previous_value := coalesce(existing_resource.quantity_current, existing_resource.time_duration_days);
  resulting_value := case
    when change_type = 'adjust' then new_value
    when delta_value is not null then greatest(coalesce(previous_value, 0) + delta_value, 0)
    else new_value
  end;

  update public.resources
     set quantity_current = case
           when existing_resource.type = 'quantityBased' then resulting_value
           else quantity_current
         end,
         time_duration_days = case
           when existing_resource.type = 'timeBased' then resulting_value
           else time_duration_days
         end,
         last_refilled_at = case
           when change_type = 'increment' then now()
           else last_refilled_at
         end,
         updated_by_user_id = auth.uid(),
         updated_at = now()
   where id = target_resource_id
   returning * into existing_resource;

  insert into public.resource_events (
    id, pack_id, resource_id, actor_user_id, change_type, previous_value,
    new_value, delta_value, unit, client_mutation_id, metadata_json, created_at
  )
  values (
    gen_random_uuid(), existing_resource.pack_id, existing_resource.id,
    auth.uid(), change_type, previous_value, resulting_value, delta_value,
    unit, client_mutation_id, metadata_json, now()
  )
  returning * into inserted_event;

  insert into public.activity_events (
    id, pack_id, actor_user_id, entity_type, entity_id, action,
    before_json, after_json, metadata_json, created_at
  )
  values (
    gen_random_uuid(), existing_resource.pack_id, auth.uid(), 'resource',
    existing_resource.id,
    case
      when change_type = 'increment' then 'resource_incremented'
      when change_type = 'decrement' then 'resource_decremented'
      else 'resource_adjusted'
    end,
    jsonb_build_object('value', previous_value),
    jsonb_build_object('value', resulting_value),
    jsonb_build_object('client_mutation_id', client_mutation_id),
    now()
  );

  return query
    select 'applied'::text, existing_resource.id, inserted_event.id,
           resulting_value, existing_resource.updated_at;
end;
$$;
