-- Reminder App Phase 4C Supabase Remote Member Actions MVP
-- Manual draft only. Do not auto-apply to production.
-- Apply after:
--   1. docs/core/sql/phase3c_supabase_minimal_poc.sql
--   2. docs/core/sql/phase4a_supabase_invite_membership_mvp.sql
--
-- Phase 4C adds remote item undo for developer-only Remote Pack Viewer
-- actions. It does not add full sync, realtime, local merge, resources, stages,
-- or production item operation UI.
--
-- REVIEW: Validate in Supabase SQL editor or local Supabase CLI before use.
-- REVIEW: This function is intentionally RPC-controlled. Direct
-- item_completions delete, completed_by overwrite, and direct completion
-- update are not allowed by the Phase 3C policies.

-- ---------------------------------------------------------------------------
-- RPC: undo active item completion
-- ---------------------------------------------------------------------------

create or replace function public.undo_pack_item_completion(
  target_item_id uuid,
  client_mutation_id text default null
)
returns table (
  status text,
  completion_id uuid,
  item_id uuid,
  undone_by_user_id uuid,
  undone_at timestamptz
)
language plpgsql
security invoker
set search_path = public
as $$
declare
  current_user_id uuid := auth.uid();
  target_pack_id uuid;
  active_completion public.item_completions%rowtype;
  updated_completion public.item_completions%rowtype;
  undo_time timestamptz := now();
begin
  if current_user_id is null then
    raise exception 'auth required';
  end if;

  select i.pack_id into target_pack_id
  from public.items i
  where i.id = undo_pack_item_completion.target_item_id
    and i.deleted_at is null;

  if target_pack_id is null then
    raise exception 'item not found';
  end if;

  if not public.is_pack_member(target_pack_id) then
    raise exception 'active pack member required';
  end if;

  select * into active_completion
  from public.item_completions ic
  where ic.item_id = undo_pack_item_completion.target_item_id
    and ic.undone_at is null
  order by ic.completed_at desc
  limit 1
  for update;

  if active_completion.id is null then
    return query select
      'already_not_completed'::text,
      null::uuid,
      undo_pack_item_completion.target_item_id,
      null::uuid,
      null::timestamptz;
    return;
  end if;

  update public.item_completions
  set
    undone_by_user_id = current_user_id,
    undone_at = undo_time
  where id = active_completion.id
    and undone_at is null
  returning * into updated_completion;

  if updated_completion.id is null then
    return query select
      'already_not_completed'::text,
      null::uuid,
      undo_pack_item_completion.target_item_id,
      null::uuid,
      null::timestamptz;
    return;
  end if;

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
    undo_pack_item_completion.target_item_id,
    'item_undone',
    jsonb_build_object(
      'completion_id', updated_completion.id,
      'client_mutation_id', undo_pack_item_completion.client_mutation_id
    )
  );

  return query select
    'undone'::text,
    updated_completion.id,
    updated_completion.item_id,
    updated_completion.undone_by_user_id,
    updated_completion.undone_at;
end;
$$;

comment on function public.undo_pack_item_completion(uuid, text) is
  'Phase 4C RPC-controlled remote item undo. Active pack members may undo active completion history without deleting item_completions or overwriting completed_by_user_id.';
