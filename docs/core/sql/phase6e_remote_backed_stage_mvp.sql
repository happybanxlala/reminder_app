-- Phase 6E Remote-backed Stage Sharing MVP
-- Production StageTracker-oriented schema. The older draft `stages` model is
-- intentionally unused because the local app model is StageTracker/Rule/Record.

create table if not exists public.stage_trackers (
  id uuid primary key default gen_random_uuid(),
  pack_id uuid not null references public.packs(id) on delete cascade,
  title text not null,
  subject_name text,
  tracking_start_date date not null,
  tracking_end_date date,
  status text not null default 'active' check (status in ('active', 'archived', 'deleted')),
  created_by_user_id uuid not null references public.profiles(id),
  updated_by_user_id uuid not null references public.profiles(id),
  client_mutation_id text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  archived_at timestamptz,
  deleted_at timestamptz,
  unique (pack_id, client_mutation_id)
);

create table if not exists public.stage_rules (
  id uuid primary key default gen_random_uuid(),
  pack_id uuid not null references public.packs(id) on delete cascade,
  stage_tracker_id uuid not null references public.stage_trackers(id) on delete cascade,
  type text not null,
  interval_value integer not null,
  interval_unit text not null check (interval_unit in ('days', 'weeks', 'months', 'years')),
  label_template text,
  reminder_offset_days integer,
  status text not null default 'active' check (status in ('active', 'paused', 'archived', 'deleted')),
  created_by_user_id uuid not null references public.profiles(id),
  updated_by_user_id uuid not null references public.profiles(id),
  client_mutation_id text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  archived_at timestamptz,
  deleted_at timestamptz,
  unique (pack_id, client_mutation_id)
);

create table if not exists public.stage_records (
  id uuid primary key default gen_random_uuid(),
  pack_id uuid not null references public.packs(id) on delete cascade,
  stage_tracker_id uuid not null references public.stage_trackers(id) on delete cascade,
  stage_rule_id uuid references public.stage_rules(id) on delete set null,
  source_type text not null check (source_type in ('generated', 'manual')),
  occurrence_index integer,
  occurrence_date date not null,
  relative_amount integer,
  relative_unit text check (relative_unit in ('days', 'weeks', 'months', 'years')),
  status text not null default 'normal' check (status in ('normal', 'acknowledged', 'ignored', 'archived', 'deleted')),
  label text not null,
  note text,
  reminder_offset_days integer,
  created_by_user_id uuid not null references public.profiles(id),
  updated_by_user_id uuid not null references public.profiles(id),
  client_mutation_id text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  archived_at timestamptz,
  deleted_at timestamptz,
  unique (pack_id, client_mutation_id)
);

create table if not exists public.stage_acknowledgements (
  id uuid primary key default gen_random_uuid(),
  pack_id uuid not null references public.packs(id) on delete cascade,
  stage_record_id uuid not null references public.stage_records(id) on delete cascade,
  user_id uuid not null references public.profiles(id),
  acknowledged_at timestamptz not null default now(),
  client_mutation_id text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (stage_record_id, user_id),
  unique (pack_id, client_mutation_id)
);

alter table public.stage_trackers add column if not exists pack_id uuid references public.packs(id) on delete cascade;
alter table public.stage_trackers add column if not exists title text;
alter table public.stage_trackers add column if not exists subject_name text;
alter table public.stage_trackers add column if not exists tracking_start_date date;
alter table public.stage_trackers add column if not exists tracking_end_date date;
alter table public.stage_trackers add column if not exists status text not null default 'active';
alter table public.stage_trackers add column if not exists created_by_user_id uuid references public.profiles(id);
alter table public.stage_trackers add column if not exists updated_by_user_id uuid references public.profiles(id);
alter table public.stage_trackers add column if not exists client_mutation_id text;
alter table public.stage_trackers add column if not exists created_at timestamptz not null default now();
alter table public.stage_trackers add column if not exists updated_at timestamptz not null default now();
alter table public.stage_trackers add column if not exists archived_at timestamptz;
alter table public.stage_trackers add column if not exists deleted_at timestamptz;

alter table public.stage_rules add column if not exists pack_id uuid references public.packs(id) on delete cascade;
alter table public.stage_rules add column if not exists stage_tracker_id uuid references public.stage_trackers(id) on delete cascade;
alter table public.stage_rules add column if not exists type text;
alter table public.stage_rules add column if not exists interval_value integer;
alter table public.stage_rules add column if not exists interval_unit text;
alter table public.stage_rules add column if not exists label_template text;
alter table public.stage_rules add column if not exists reminder_offset_days integer;
alter table public.stage_rules add column if not exists status text not null default 'active';
alter table public.stage_rules add column if not exists created_by_user_id uuid references public.profiles(id);
alter table public.stage_rules add column if not exists updated_by_user_id uuid references public.profiles(id);
alter table public.stage_rules add column if not exists client_mutation_id text;
alter table public.stage_rules add column if not exists created_at timestamptz not null default now();
alter table public.stage_rules add column if not exists updated_at timestamptz not null default now();
alter table public.stage_rules add column if not exists archived_at timestamptz;
alter table public.stage_rules add column if not exists deleted_at timestamptz;

alter table public.stage_records add column if not exists pack_id uuid references public.packs(id) on delete cascade;
alter table public.stage_records add column if not exists stage_tracker_id uuid references public.stage_trackers(id) on delete cascade;
alter table public.stage_records add column if not exists stage_rule_id uuid references public.stage_rules(id) on delete set null;
alter table public.stage_records add column if not exists source_type text;
alter table public.stage_records add column if not exists occurrence_index integer;
alter table public.stage_records add column if not exists occurrence_date date;
alter table public.stage_records add column if not exists relative_amount integer;
alter table public.stage_records add column if not exists relative_unit text;
alter table public.stage_records add column if not exists status text not null default 'normal';
alter table public.stage_records add column if not exists label text;
alter table public.stage_records add column if not exists note text;
alter table public.stage_records add column if not exists reminder_offset_days integer;
alter table public.stage_records add column if not exists created_by_user_id uuid references public.profiles(id);
alter table public.stage_records add column if not exists updated_by_user_id uuid references public.profiles(id);
alter table public.stage_records add column if not exists client_mutation_id text;
alter table public.stage_records add column if not exists created_at timestamptz not null default now();
alter table public.stage_records add column if not exists updated_at timestamptz not null default now();
alter table public.stage_records add column if not exists archived_at timestamptz;
alter table public.stage_records add column if not exists deleted_at timestamptz;

alter table public.stage_acknowledgements add column if not exists pack_id uuid references public.packs(id) on delete cascade;
alter table public.stage_acknowledgements add column if not exists stage_record_id uuid references public.stage_records(id) on delete cascade;
alter table public.stage_acknowledgements add column if not exists user_id uuid references public.profiles(id);
alter table public.stage_acknowledgements add column if not exists acknowledged_at timestamptz not null default now();
alter table public.stage_acknowledgements add column if not exists client_mutation_id text;
alter table public.stage_acknowledgements add column if not exists created_at timestamptz not null default now();
alter table public.stage_acknowledgements add column if not exists updated_at timestamptz not null default now();

create unique index if not exists stage_trackers_client_mutation_unique
  on public.stage_trackers(pack_id, client_mutation_id)
  where client_mutation_id is not null;
create unique index if not exists stage_rules_client_mutation_unique
  on public.stage_rules(pack_id, client_mutation_id)
  where client_mutation_id is not null;
create unique index if not exists stage_records_client_mutation_unique
  on public.stage_records(pack_id, client_mutation_id)
  where client_mutation_id is not null;
create unique index if not exists stage_acknowledgements_record_user_unique
  on public.stage_acknowledgements(stage_record_id, user_id);
create unique index if not exists stage_acknowledgements_client_mutation_unique
  on public.stage_acknowledgements(pack_id, client_mutation_id)
  where client_mutation_id is not null;

alter table public.stage_trackers enable row level security;
alter table public.stage_rules enable row level security;
alter table public.stage_records enable row level security;
alter table public.stage_acknowledgements enable row level security;

drop policy if exists "stage_trackers_active_members_read"
  on public.stage_trackers;
create policy "stage_trackers_active_members_read"
  on public.stage_trackers for select
  using (public.is_pack_member(pack_id));

drop policy if exists "stage_rules_active_members_read"
  on public.stage_rules;
create policy "stage_rules_active_members_read"
  on public.stage_rules for select
  using (public.is_pack_member(pack_id));

drop policy if exists "stage_records_active_members_read"
  on public.stage_records;
create policy "stage_records_active_members_read"
  on public.stage_records for select
  using (public.is_pack_member(pack_id));

drop policy if exists "stage_acknowledgements_active_members_read"
  on public.stage_acknowledgements;
create policy "stage_acknowledgements_active_members_read"
  on public.stage_acknowledgements for select
  using (public.is_pack_member(pack_id));

create or replace function public.create_pack_stage_tracker(
  target_pack_id uuid,
  title text,
  subject_name text default null,
  tracking_start_date date default current_date,
  tracking_end_date date default null,
  initial_rules_json jsonb default '[]'::jsonb,
  client_mutation_id text default null
)
returns table(status text, stage_tracker_id uuid, rule_ids_by_client_local_id jsonb)
language plpgsql
security definer
set search_path = public
as $$
declare
  existing_tracker public.stage_trackers%rowtype;
  inserted_tracker public.stage_trackers%rowtype;
  inserted_rule public.stage_rules%rowtype;
  rule_entry jsonb;
  rule_ids jsonb := '{}'::jsonb;
begin
  if auth.uid() is null then
    raise exception 'remote_auth_required' using errcode = '28000';
  end if;
  if not public.is_pack_member(target_pack_id) then
    raise exception 'not_active_pack_member' using errcode = '42501';
  end if;
  if nullif(btrim(title), '') is null then
    raise exception 'stage_tracker_title_required' using errcode = '22023';
  end if;

  if client_mutation_id is not null then
    select * into existing_tracker
      from public.stage_trackers
     where pack_id = target_pack_id
       and client_mutation_id = create_pack_stage_tracker.client_mutation_id
     order by created_at asc
     limit 1;
    if found then
      return query select 'already_created'::text, existing_tracker.id, '{}'::jsonb;
      return;
    end if;
  end if;

  insert into public.stage_trackers (
    pack_id, title, subject_name, tracking_start_date, tracking_end_date,
    status, created_by_user_id, updated_by_user_id, client_mutation_id,
    created_at, updated_at
  )
  values (
    target_pack_id, btrim(title), nullif(btrim(subject_name), ''),
    tracking_start_date, tracking_end_date, 'active', auth.uid(), auth.uid(),
    client_mutation_id, now(), now()
  )
  returning * into inserted_tracker;

  for rule_entry in select * from jsonb_array_elements(coalesce(initial_rules_json, '[]'::jsonb))
  loop
    insert into public.stage_rules (
      pack_id, stage_tracker_id, type, interval_value, interval_unit,
      label_template, reminder_offset_days, status, created_by_user_id,
      updated_by_user_id, client_mutation_id, created_at, updated_at
    )
    values (
      target_pack_id, inserted_tracker.id,
      coalesce(nullif(rule_entry ->> 'type', ''), 'every_n_days'),
      coalesce(nullif(rule_entry ->> 'intervalValue', '')::integer, 1),
      coalesce(nullif(rule_entry ->> 'intervalUnit', ''), 'days'),
      nullif(rule_entry ->> 'labelTemplate', ''),
      nullif(rule_entry ->> 'reminderOffsetDays', '')::integer,
      coalesce(nullif(rule_entry ->> 'status', ''), 'active'),
      auth.uid(), auth.uid(),
      client_mutation_id || ':rule:' || coalesce(rule_entry ->> 'localStageRuleId', gen_random_uuid()::text),
      now(), now()
    )
    returning * into inserted_rule;

    if rule_entry ? 'localStageRuleId' then
      rule_ids := rule_ids || jsonb_build_object(rule_entry ->> 'localStageRuleId', inserted_rule.id);
    end if;
  end loop;

  insert into public.activity_events (
    id, pack_id, actor_user_id, entity_type, entity_id, action, after_json,
    metadata_json, created_at
  )
  values (
    gen_random_uuid(), target_pack_id, auth.uid(), 'stage_tracker',
    inserted_tracker.id, 'stage_tracker_created',
    jsonb_build_object('title', inserted_tracker.title),
    jsonb_build_object('client_mutation_id', client_mutation_id),
    now()
  );

  return query select 'created'::text, inserted_tracker.id, rule_ids;
end;
$$;

create or replace function public.update_pack_stage_tracker(
  target_stage_tracker_id uuid,
  title text,
  subject_name text default null,
  tracking_start_date date default current_date,
  tracking_end_date date default null,
  client_mutation_id text default null
)
returns table(status text, stage_tracker_id uuid)
language plpgsql
security definer
set search_path = public
as $$
declare
  tracker public.stage_trackers%rowtype;
  before_payload jsonb;
begin
  if auth.uid() is null then
    raise exception 'remote_auth_required' using errcode = '28000';
  end if;
  select * into tracker from public.stage_trackers where id = target_stage_tracker_id;
  if not found then
    raise exception 'stage_tracker_not_found' using errcode = '02000';
  end if;
  if not public.is_pack_member(tracker.pack_id) then
    raise exception 'not_active_pack_member' using errcode = '42501';
  end if;
  if tracker.archived_at is not null or tracker.status = 'archived' then
    return query select 'already_archived'::text, tracker.id;
    return;
  end if;
  if nullif(btrim(title), '') is null then
    raise exception 'stage_tracker_title_required' using errcode = '22023';
  end if;

  before_payload := jsonb_build_object('title', tracker.title);
  update public.stage_trackers
     set title = btrim(update_pack_stage_tracker.title),
         subject_name = nullif(btrim(update_pack_stage_tracker.subject_name), ''),
         tracking_start_date = update_pack_stage_tracker.tracking_start_date,
         tracking_end_date = update_pack_stage_tracker.tracking_end_date,
         updated_by_user_id = auth.uid(),
         updated_at = now()
   where id = target_stage_tracker_id
   returning * into tracker;

  insert into public.activity_events (
    id, pack_id, actor_user_id, entity_type, entity_id, action,
    before_json, after_json, metadata_json, created_at
  )
  values (
    gen_random_uuid(), tracker.pack_id, auth.uid(), 'stage_tracker',
    tracker.id, 'stage_tracker_updated', before_payload,
    jsonb_build_object('title', tracker.title),
    jsonb_build_object('client_mutation_id', client_mutation_id),
    now()
  );

  return query select 'updated'::text, tracker.id;
end;
$$;

create or replace function public.archive_pack_stage_tracker(
  target_stage_tracker_id uuid,
  client_mutation_id text default null
)
returns table(status text, stage_tracker_id uuid)
language plpgsql
security definer
set search_path = public
as $$
declare
  tracker public.stage_trackers%rowtype;
begin
  if auth.uid() is null then
    raise exception 'remote_auth_required' using errcode = '28000';
  end if;
  select * into tracker from public.stage_trackers where id = target_stage_tracker_id;
  if not found then
    raise exception 'stage_tracker_not_found' using errcode = '02000';
  end if;
  if not public.is_pack_member(tracker.pack_id) then
    raise exception 'not_active_pack_member' using errcode = '42501';
  end if;
  if tracker.archived_at is not null or tracker.status = 'archived' then
    return query select 'already_archived'::text, tracker.id;
    return;
  end if;

  update public.stage_trackers
     set status = 'archived',
         archived_at = now(),
         updated_by_user_id = auth.uid(),
         updated_at = now()
   where id = target_stage_tracker_id
   returning * into tracker;

  insert into public.activity_events (
    id, pack_id, actor_user_id, entity_type, entity_id, action,
    metadata_json, created_at
  )
  values (
    gen_random_uuid(), tracker.pack_id, auth.uid(), 'stage_tracker',
    tracker.id, 'stage_tracker_archived',
    jsonb_build_object('client_mutation_id', client_mutation_id),
    now()
  );

  return query select 'archived'::text, tracker.id;
end;
$$;

create or replace function public.create_pack_stage_rule(
  target_stage_tracker_id uuid,
  fields_json jsonb default '{}'::jsonb,
  client_mutation_id text default null
)
returns table(status text, stage_rule_id uuid)
language plpgsql
security definer
set search_path = public
as $$
declare
  tracker public.stage_trackers%rowtype;
  rule_row public.stage_rules%rowtype;
begin
  if auth.uid() is null then
    raise exception 'remote_auth_required' using errcode = '28000';
  end if;
  select * into tracker from public.stage_trackers where id = target_stage_tracker_id;
  if not found then
    raise exception 'stage_tracker_not_found' using errcode = '02000';
  end if;
  if not public.is_pack_member(tracker.pack_id) then
    raise exception 'not_active_pack_member' using errcode = '42501';
  end if;
  if client_mutation_id is not null then
    select * into rule_row
      from public.stage_rules
     where pack_id = tracker.pack_id
       and client_mutation_id = create_pack_stage_rule.client_mutation_id
     order by created_at asc
     limit 1;
    if found then
      return query select 'already_created'::text, rule_row.id;
      return;
    end if;
  end if;

  insert into public.stage_rules (
    pack_id, stage_tracker_id, type, interval_value, interval_unit,
    label_template, reminder_offset_days, status, created_by_user_id,
    updated_by_user_id, client_mutation_id, created_at, updated_at
  )
  values (
    tracker.pack_id, tracker.id,
    coalesce(nullif(fields_json ->> 'type', ''), 'every_n_days'),
    coalesce(nullif(fields_json ->> 'intervalValue', '')::integer, 1),
    coalesce(nullif(fields_json ->> 'intervalUnit', ''), 'days'),
    nullif(fields_json ->> 'labelTemplate', ''),
    nullif(fields_json ->> 'reminderOffsetDays', '')::integer,
    coalesce(nullif(fields_json ->> 'status', ''), 'active'),
    auth.uid(), auth.uid(), client_mutation_id, now(), now()
  )
  returning * into rule_row;

  insert into public.activity_events (
    id, pack_id, actor_user_id, entity_type, entity_id, action,
    after_json, metadata_json, created_at
  )
  values (
    gen_random_uuid(), rule_row.pack_id, auth.uid(), 'stage_rule',
    rule_row.id, 'stage_tracker_updated',
    jsonb_build_object('stage_tracker_id', rule_row.stage_tracker_id),
    jsonb_build_object('client_mutation_id', client_mutation_id),
    now()
  );

  return query select 'created'::text, rule_row.id;
end;
$$;

create or replace function public.update_pack_stage_rule(
  target_stage_rule_id uuid,
  fields_json jsonb default '{}'::jsonb,
  client_mutation_id text default null
)
returns table(status text, stage_rule_id uuid)
language plpgsql
security definer
set search_path = public
as $$
declare
  rule_row public.stage_rules%rowtype;
begin
  if auth.uid() is null then
    raise exception 'remote_auth_required' using errcode = '28000';
  end if;
  select * into rule_row from public.stage_rules where id = target_stage_rule_id;
  if not found then
    raise exception 'stage_rule_not_found' using errcode = '02000';
  end if;
  if not public.is_pack_member(rule_row.pack_id) then
    raise exception 'not_active_pack_member' using errcode = '42501';
  end if;
  if rule_row.archived_at is not null or rule_row.status = 'archived' then
    return query select 'already_archived'::text, rule_row.id;
    return;
  end if;

  update public.stage_rules
     set type = coalesce(nullif(fields_json ->> 'type', ''), rule_row.type),
         interval_value = coalesce(nullif(fields_json ->> 'intervalValue', '')::integer, rule_row.interval_value),
         interval_unit = coalesce(nullif(fields_json ->> 'intervalUnit', ''), rule_row.interval_unit),
         label_template = nullif(fields_json ->> 'labelTemplate', ''),
         reminder_offset_days = nullif(fields_json ->> 'reminderOffsetDays', '')::integer,
         status = coalesce(nullif(fields_json ->> 'status', ''), rule_row.status),
         updated_by_user_id = auth.uid(),
         updated_at = now()
   where id = target_stage_rule_id
   returning * into rule_row;

  insert into public.activity_events (
    id, pack_id, actor_user_id, entity_type, entity_id, action,
    after_json, metadata_json, created_at
  )
  values (
    gen_random_uuid(), rule_row.pack_id, auth.uid(), 'stage_rule',
    rule_row.id, 'stage_rule_updated',
    jsonb_build_object('status', rule_row.status),
    jsonb_build_object('client_mutation_id', client_mutation_id),
    now()
  );

  return query select 'updated'::text, rule_row.id;
end;
$$;

create or replace function public.update_pack_stage_rule_status(
  target_stage_rule_id uuid,
  target_status text,
  client_mutation_id text default null
)
returns table(status text, stage_rule_id uuid)
language plpgsql
security definer
set search_path = public
as $$
declare
  rule_row public.stage_rules%rowtype;
begin
  if auth.uid() is null then
    raise exception 'remote_auth_required' using errcode = '28000';
  end if;
  select * into rule_row from public.stage_rules where id = target_stage_rule_id;
  if not found then
    raise exception 'stage_rule_not_found' using errcode = '02000';
  end if;
  if not public.is_pack_member(rule_row.pack_id) then
    raise exception 'not_active_pack_member' using errcode = '42501';
  end if;

  update public.stage_rules
     set status = target_status,
         archived_at = case
           when target_status = 'archived' then coalesce(rule_row.archived_at, now())
           else rule_row.archived_at
         end,
         updated_by_user_id = auth.uid(),
         updated_at = now()
   where id = target_stage_rule_id
   returning * into rule_row;

  insert into public.activity_events (
    id, pack_id, actor_user_id, entity_type, entity_id, action,
    after_json, metadata_json, created_at
  )
  values (
    gen_random_uuid(), rule_row.pack_id, auth.uid(), 'stage_rule',
    rule_row.id,
    case when target_status = 'archived' then 'stage_rule_archived' else 'stage_rule_updated' end,
    jsonb_build_object('status', rule_row.status),
    jsonb_build_object('client_mutation_id', client_mutation_id),
    now()
  );

  return query select 'updated'::text, rule_row.id;
end;
$$;

create or replace function public.create_pack_stage_record(
  target_stage_tracker_id uuid,
  target_stage_rule_id uuid default null,
  fields_json jsonb default '{}'::jsonb,
  client_mutation_id text default null
)
returns table(status text, stage_record_id uuid)
language plpgsql
security definer
set search_path = public
as $$
declare
  tracker public.stage_trackers%rowtype;
  record_row public.stage_records%rowtype;
begin
  if auth.uid() is null then
    raise exception 'remote_auth_required' using errcode = '28000';
  end if;
  select * into tracker from public.stage_trackers where id = target_stage_tracker_id;
  if not found then
    raise exception 'stage_tracker_not_found' using errcode = '02000';
  end if;
  if not public.is_pack_member(tracker.pack_id) then
    raise exception 'not_active_pack_member' using errcode = '42501';
  end if;
  if target_stage_rule_id is not null and not exists (
    select 1
      from public.stage_rules
     where id = target_stage_rule_id
       and pack_id = tracker.pack_id
       and stage_tracker_id = tracker.id
  ) then
    raise exception 'stage_rule_not_found' using errcode = '02000';
  end if;

  if client_mutation_id is not null then
    select * into record_row
      from public.stage_records
     where pack_id = tracker.pack_id
       and client_mutation_id = create_pack_stage_record.client_mutation_id
     order by created_at asc
     limit 1;
    if found then
      return query select 'already_created'::text, record_row.id;
      return;
    end if;
  end if;

  insert into public.stage_records (
    pack_id, stage_tracker_id, stage_rule_id, source_type, occurrence_index,
    occurrence_date, relative_amount, relative_unit, status, label, note,
    reminder_offset_days, created_by_user_id, updated_by_user_id,
    client_mutation_id, created_at, updated_at
  )
  values (
    tracker.pack_id, tracker.id, target_stage_rule_id,
    coalesce(nullif(fields_json ->> 'sourceType', ''), 'manual'),
    nullif(fields_json ->> 'occurrenceIndex', '')::integer,
    coalesce(nullif(fields_json ->> 'occurrenceDate', '')::date, current_date),
    nullif(fields_json ->> 'relativeAmount', '')::integer,
    nullif(fields_json ->> 'relativeUnit', ''),
    coalesce(nullif(fields_json ->> 'status', ''), 'normal'),
    coalesce(nullif(fields_json ->> 'label', ''), '階段'),
    nullif(fields_json ->> 'note', ''),
    nullif(fields_json ->> 'reminderOffsetDays', '')::integer,
    auth.uid(), auth.uid(), client_mutation_id, now(), now()
  )
  returning * into record_row;

  insert into public.activity_events (
    id, pack_id, actor_user_id, entity_type, entity_id, action,
    after_json, metadata_json, created_at
  )
  values (
    gen_random_uuid(), record_row.pack_id, auth.uid(), 'stage_record',
    record_row.id, 'stage_tracker_updated',
    jsonb_build_object('label', record_row.label),
    jsonb_build_object('client_mutation_id', client_mutation_id),
    now()
  );

  return query select 'created'::text, record_row.id;
end;
$$;

create or replace function public.update_pack_stage_record(
  target_stage_record_id uuid,
  fields_json jsonb default '{}'::jsonb,
  client_mutation_id text default null
)
returns table(status text, stage_record_id uuid)
language plpgsql
security definer
set search_path = public
as $$
declare
  record_row public.stage_records%rowtype;
begin
  if auth.uid() is null then
    raise exception 'remote_auth_required' using errcode = '28000';
  end if;
  select * into record_row from public.stage_records where id = target_stage_record_id;
  if not found then
    raise exception 'stage_record_not_found' using errcode = '02000';
  end if;
  if not public.is_pack_member(record_row.pack_id) then
    raise exception 'not_active_pack_member' using errcode = '42501';
  end if;
  if record_row.archived_at is not null or record_row.status = 'archived' then
    return query select 'already_archived'::text, record_row.id;
    return;
  end if;

  update public.stage_records
     set source_type = coalesce(nullif(fields_json ->> 'sourceType', ''), record_row.source_type),
         occurrence_index = coalesce(nullif(fields_json ->> 'occurrenceIndex', '')::integer, record_row.occurrence_index),
         occurrence_date = coalesce(nullif(fields_json ->> 'occurrenceDate', '')::date, record_row.occurrence_date),
         relative_amount = nullif(fields_json ->> 'relativeAmount', '')::integer,
         relative_unit = nullif(fields_json ->> 'relativeUnit', ''),
         status = coalesce(nullif(fields_json ->> 'status', ''), record_row.status),
         label = coalesce(nullif(fields_json ->> 'label', ''), record_row.label),
         note = nullif(fields_json ->> 'note', ''),
         reminder_offset_days = nullif(fields_json ->> 'reminderOffsetDays', '')::integer,
         updated_by_user_id = auth.uid(),
         updated_at = now()
   where id = target_stage_record_id
   returning * into record_row;

  insert into public.activity_events (
    id, pack_id, actor_user_id, entity_type, entity_id, action,
    after_json, metadata_json, created_at
  )
  values (
    gen_random_uuid(), record_row.pack_id, auth.uid(), 'stage_record',
    record_row.id, 'stage_record_updated',
    jsonb_build_object('label', record_row.label, 'status', record_row.status),
    jsonb_build_object('client_mutation_id', client_mutation_id),
    now()
  );

  return query select 'updated'::text, record_row.id;
end;
$$;

create or replace function public.archive_pack_stage_record(
  target_stage_record_id uuid,
  client_mutation_id text default null
)
returns table(status text, stage_record_id uuid)
language plpgsql
security definer
set search_path = public
as $$
declare
  record_row public.stage_records%rowtype;
begin
  if auth.uid() is null then
    raise exception 'remote_auth_required' using errcode = '28000';
  end if;
  select * into record_row from public.stage_records where id = target_stage_record_id;
  if not found then
    raise exception 'stage_record_not_found' using errcode = '02000';
  end if;
  if not public.is_pack_member(record_row.pack_id) then
    raise exception 'not_active_pack_member' using errcode = '42501';
  end if;
  if record_row.archived_at is not null or record_row.status = 'archived' then
    return query select 'already_archived'::text, record_row.id;
    return;
  end if;

  update public.stage_records
     set status = 'archived',
         archived_at = now(),
         updated_by_user_id = auth.uid(),
         updated_at = now()
   where id = target_stage_record_id
   returning * into record_row;

  insert into public.activity_events (
    id, pack_id, actor_user_id, entity_type, entity_id, action,
    metadata_json, created_at
  )
  values (
    gen_random_uuid(), record_row.pack_id, auth.uid(), 'stage_record',
    record_row.id, 'stage_record_archived',
    jsonb_build_object('client_mutation_id', client_mutation_id),
    now()
  );

  return query select 'archived'::text, record_row.id;
end;
$$;

create or replace function public.acknowledge_pack_stage_record(
  target_stage_record_id uuid,
  client_mutation_id text default null
)
returns table(status text, stage_record_id uuid, acknowledgement_id uuid, acknowledged_at timestamptz)
language plpgsql
security definer
set search_path = public
as $$
declare
  record_row public.stage_records%rowtype;
  ack_row public.stage_acknowledgements%rowtype;
begin
  if auth.uid() is null then
    raise exception 'remote_auth_required' using errcode = '28000';
  end if;
  select * into record_row from public.stage_records where id = target_stage_record_id;
  if not found then
    raise exception 'stage_record_not_found' using errcode = '02000';
  end if;
  if not public.is_pack_member(record_row.pack_id) then
    raise exception 'not_active_pack_member' using errcode = '42501';
  end if;
  if record_row.archived_at is not null or record_row.status = 'archived' then
    raise exception 'stage_record_archived' using errcode = '22023';
  end if;

  if client_mutation_id is not null then
    select * into ack_row
      from public.stage_acknowledgements
     where pack_id = record_row.pack_id
       and client_mutation_id = acknowledge_pack_stage_record.client_mutation_id
     order by created_at asc
     limit 1;
    if found then
      return query select 'already_acknowledged'::text, ack_row.stage_record_id, ack_row.id, ack_row.acknowledged_at;
      return;
    end if;
  end if;

  insert into public.stage_acknowledgements (
    pack_id, stage_record_id, user_id, acknowledged_at, client_mutation_id,
    created_at, updated_at
  )
  values (
    record_row.pack_id, record_row.id, auth.uid(), now(), client_mutation_id,
    now(), now()
  )
  on conflict (stage_record_id, user_id) do update
     set acknowledged_at = excluded.acknowledged_at,
         client_mutation_id = coalesce(excluded.client_mutation_id, public.stage_acknowledgements.client_mutation_id),
         updated_at = now()
  returning * into ack_row;

  update public.stage_records
     set status = 'acknowledged',
         updated_by_user_id = auth.uid(),
         updated_at = now()
   where id = record_row.id;

  insert into public.activity_events (
    id, pack_id, actor_user_id, entity_type, entity_id, action,
    metadata_json, created_at
  )
  values (
    gen_random_uuid(), record_row.pack_id, auth.uid(), 'stage_record',
    record_row.id, 'stage_acknowledged',
    jsonb_build_object('client_mutation_id', client_mutation_id),
    now()
  );

  return query select 'acknowledged'::text, record_row.id, ack_row.id, ack_row.acknowledged_at;
end;
$$;

grant select on public.stage_trackers to authenticated;
grant select on public.stage_rules to authenticated;
grant select on public.stage_records to authenticated;
grant select on public.stage_acknowledgements to authenticated;

revoke all on function public.create_pack_stage_tracker(uuid, text, text, date, date, jsonb, text) from public;
grant execute on function public.create_pack_stage_tracker(uuid, text, text, date, date, jsonb, text) to authenticated;

revoke all on function public.update_pack_stage_tracker(uuid, text, text, date, date, text) from public;
grant execute on function public.update_pack_stage_tracker(uuid, text, text, date, date, text) to authenticated;

revoke all on function public.archive_pack_stage_tracker(uuid, text) from public;
grant execute on function public.archive_pack_stage_tracker(uuid, text) to authenticated;

revoke all on function public.create_pack_stage_rule(uuid, jsonb, text) from public;
grant execute on function public.create_pack_stage_rule(uuid, jsonb, text) to authenticated;

revoke all on function public.update_pack_stage_rule(uuid, jsonb, text) from public;
grant execute on function public.update_pack_stage_rule(uuid, jsonb, text) to authenticated;

revoke all on function public.update_pack_stage_rule_status(uuid, text, text) from public;
grant execute on function public.update_pack_stage_rule_status(uuid, text, text) to authenticated;

revoke all on function public.create_pack_stage_record(uuid, uuid, jsonb, text) from public;
grant execute on function public.create_pack_stage_record(uuid, uuid, jsonb, text) to authenticated;

revoke all on function public.update_pack_stage_record(uuid, jsonb, text) from public;
grant execute on function public.update_pack_stage_record(uuid, jsonb, text) to authenticated;

revoke all on function public.archive_pack_stage_record(uuid, text) from public;
grant execute on function public.archive_pack_stage_record(uuid, text) to authenticated;

revoke all on function public.acknowledge_pack_stage_record(uuid, text) from public;
grant execute on function public.acknowledge_pack_stage_record(uuid, text) to authenticated;
