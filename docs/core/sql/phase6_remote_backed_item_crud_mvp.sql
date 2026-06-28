-- Phase 6 remote-backed item CRUD MVP.
--
-- Apply after the Phase 3C / 4E remote shared pack SQL foundation.
-- This patch adds controlled item create/update/archive RPCs for the
-- local-first sync_outbox path. It does not add resource sync, stage sync,
-- hard delete, background sync, automatic retry, or conflict-resolution UI.

create or replace function public.create_pack_item_v2(
  target_pack_id uuid,
  title text,
  note text default null,
  client_mutation_id text default null
)
returns table(status text, item_id uuid)
language plpgsql
security definer
set search_path = public
as $$
declare
  existing_event public.activity_events%rowtype;
  inserted_item public.items%rowtype;
begin
  if auth.uid() is null then
    raise exception 'remote_auth_required' using errcode = '28000';
  end if;

  if not public.is_pack_member(target_pack_id) then
    raise exception 'not_active_pack_member' using errcode = '42501';
  end if;

  if nullif(btrim(title), '') is null then
    raise exception 'item_title_required' using errcode = '22023';
  end if;

  if client_mutation_id is not null then
    select *
      into existing_event
      from public.activity_events
     where pack_id = target_pack_id
       and action = 'item_created'
       and metadata_json ->> 'client_mutation_id' = client_mutation_id
     order by created_at asc
     limit 1;

    if found then
      return query select 'already_created'::text, existing_event.entity_id;
      return;
    end if;
  end if;

  insert into public.items (
    id,
    pack_id,
    title,
    note,
    status,
    created_by_user_id,
    updated_by_user_id,
    created_at,
    updated_at
  )
  values (
    gen_random_uuid(),
    target_pack_id,
    btrim(title),
    note,
    'active',
    auth.uid(),
    auth.uid(),
    now(),
    now()
  )
  returning * into inserted_item;

  insert into public.activity_events (
    id,
    pack_id,
    actor_user_id,
    entity_type,
    entity_id,
    action,
    after_json,
    metadata_json,
    created_at
  )
  values (
    gen_random_uuid(),
    target_pack_id,
    auth.uid(),
    'item',
    inserted_item.id,
    'item_created',
    jsonb_build_object('title', inserted_item.title, 'note', inserted_item.note),
    jsonb_build_object('client_mutation_id', client_mutation_id),
    now()
  );

  return query select 'created'::text, inserted_item.id;
end;
$$;

create or replace function public.update_pack_item(
  target_item_id uuid,
  title text,
  note text default null,
  assigned_to_user_id uuid default null,
  client_mutation_id text default null
)
returns table(status text, item_id uuid)
language plpgsql
security definer
set search_path = public
as $$
declare
  existing_item public.items%rowtype;
  before_payload jsonb;
begin
  if auth.uid() is null then
    raise exception 'remote_auth_required' using errcode = '28000';
  end if;

  select * into existing_item
    from public.items
   where id = target_item_id;

  if not found then
    raise exception 'item_not_found' using errcode = '02000';
  end if;

  if not public.is_pack_member(existing_item.pack_id) then
    raise exception 'not_active_pack_member' using errcode = '42501';
  end if;

  if existing_item.deleted_at is not null then
    return query select 'deleted'::text, existing_item.id;
    return;
  end if;

  if existing_item.archived_at is not null or existing_item.status = 'archived' then
    return query select 'already_archived'::text, existing_item.id;
    return;
  end if;

  if nullif(btrim(title), '') is null then
    raise exception 'item_title_required' using errcode = '22023';
  end if;

  before_payload := jsonb_build_object(
    'title', existing_item.title,
    'note', existing_item.note,
    'assigned_to_user_id', existing_item.assigned_to_user_id
  );

  update public.items
     set title = btrim(update_pack_item.title),
         note = update_pack_item.note,
         assigned_to_user_id = update_pack_item.assigned_to_user_id,
         updated_by_user_id = auth.uid(),
         updated_at = now()
   where id = target_item_id
   returning * into existing_item;

  insert into public.activity_events (
    id,
    pack_id,
    actor_user_id,
    entity_type,
    entity_id,
    action,
    before_json,
    after_json,
    metadata_json,
    created_at
  )
  values (
    gen_random_uuid(),
    existing_item.pack_id,
    auth.uid(),
    'item',
    existing_item.id,
    'item_updated',
    before_payload,
    jsonb_build_object(
      'title', existing_item.title,
      'note', existing_item.note,
      'assigned_to_user_id', existing_item.assigned_to_user_id
    ),
    jsonb_build_object('client_mutation_id', client_mutation_id),
    now()
  );

  return query select 'updated'::text, existing_item.id;
end;
$$;

create or replace function public.archive_pack_item(
  target_item_id uuid,
  client_mutation_id text default null
)
returns table(status text, item_id uuid)
language plpgsql
security definer
set search_path = public
as $$
declare
  existing_item public.items%rowtype;
begin
  if auth.uid() is null then
    raise exception 'remote_auth_required' using errcode = '28000';
  end if;

  select * into existing_item
    from public.items
   where id = target_item_id;

  if not found then
    raise exception 'item_not_found' using errcode = '02000';
  end if;

  if not public.is_pack_member(existing_item.pack_id) then
    raise exception 'not_active_pack_member' using errcode = '42501';
  end if;

  if existing_item.deleted_at is not null then
    return query select 'deleted'::text, existing_item.id;
    return;
  end if;

  if existing_item.archived_at is not null or existing_item.status = 'archived' then
    return query select 'already_archived'::text, existing_item.id;
    return;
  end if;

  update public.items
     set status = 'archived',
         archived_at = now(),
         updated_by_user_id = auth.uid(),
         updated_at = now()
   where id = target_item_id
   returning * into existing_item;

  insert into public.activity_events (
    id,
    pack_id,
    actor_user_id,
    entity_type,
    entity_id,
    action,
    before_json,
    after_json,
    metadata_json,
    created_at
  )
  values (
    gen_random_uuid(),
    existing_item.pack_id,
    auth.uid(),
    'item',
    existing_item.id,
    'item_archived',
    jsonb_build_object('status', 'active'),
    jsonb_build_object('status', 'archived'),
    jsonb_build_object('client_mutation_id', client_mutation_id),
    now()
  );

  return query select 'archived'::text, existing_item.id;
end;
$$;

revoke all on function public.create_pack_item_v2(uuid, text, text, text) from public;
grant execute on function public.create_pack_item_v2(uuid, text, text, text) to authenticated;

revoke all on function public.update_pack_item(uuid, text, text, uuid, text) from public;
grant execute on function public.update_pack_item(uuid, text, text, uuid, text) to authenticated;

revoke all on function public.archive_pack_item(uuid, text) from public;
grant execute on function public.archive_pack_item(uuid, text) to authenticated;
