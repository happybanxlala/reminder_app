-- Shared Pack v1 RPC smoke test.
--
-- Manual/local execution artifact only. Run after applying:
-- supabase/migrations/20260630000000_shared_pack_v1_remote_schema.sql
--
-- Example:
--   psql "$DATABASE_URL" -v ON_ERROR_STOP=1 \
--     -f supabase/tests/shared_pack_v1_rpc_smoke_test.sql
--
-- The script runs inside a transaction and rolls back at the end.

\set ON_ERROR_STOP on

begin;

do $$
declare
  v_owner_identity_id uuid := '00000000-0000-4000-8000-000000000001';
  v_joiner_identity_id uuid := '00000000-0000-4000-8000-000000000002';
  v_outsider_identity_id uuid := '00000000-0000-4000-8000-000000000003';
  v_pack_id uuid;
  v_owner_membership_id uuid;
  v_joiner_membership_id uuid;
  v_invite_id uuid;
  v_invite_code text;
  v_item_id uuid;
  v_completed_at timestamptz := '2026-06-30 12:00:00+00';
  v_membership_count integer;
  v_snapshot record;
  v_preview record;
  v_join record;
  v_update record;
  v_invalid_invite_failed boolean := false;
  v_non_member_fetch_failed boolean := false;
  v_non_member_update_failed boolean := false;
  v_invalid_insert_failed boolean := false;
  v_item_state text;
begin
  -- Happy path: create pack.
  select remote_pack_id, owner_membership_id
  into v_pack_id, v_owner_membership_id
  from public.shared_pack_create_pack_v1(
    'Phase 3C Smoke Pack',
    v_owner_identity_id
  );

  if v_pack_id is null or v_owner_membership_id is null then
    raise exception 'create pack did not return pack and owner membership';
  end if;

  select count(*)
  into v_membership_count
  from public.shared_pack_members
  where pack_id = v_pack_id
    and member_identity_id = v_owner_identity_id
    and role = 'owner'
    and removed_at is null;

  if v_membership_count <> 1 then
    raise exception 'create pack did not create exactly one owner membership';
  end if;

  -- Happy path: generate invite.
  select invite_id, invite_code
  into v_invite_id, v_invite_code
  from public.shared_pack_generate_invite_v1(
    v_pack_id,
    v_owner_identity_id
  );

  if v_invite_id is null then
    raise exception 'generate invite did not return invite id';
  end if;

  if char_length(v_invite_code) <> 6 then
    raise exception 'invite code is not 6 characters: %', v_invite_code;
  end if;

  if v_invite_code !~ '^[ABCDEFGHJKMNPQRSTUVWXYZ23456789]{6}$' then
    raise exception 'invite code uses characters outside allowed set: %',
      v_invite_code;
  end if;

  if v_invite_code ~ '[0O1IL]' then
    raise exception 'invite code contains ambiguous characters: %',
      v_invite_code;
  end if;

  -- Happy path: preview invite. Spaces/hyphens are accepted for query input.
  select *
  into v_preview
  from public.shared_pack_preview_invite_v1(
    substr(v_invite_code, 1, 3) || ' ' || substr(v_invite_code, 4, 3)
  );

  if v_preview.remote_pack_id is distinct from v_pack_id
     or v_preview.pack_name <> 'Phase 3C Smoke Pack'
     or v_preview.is_joinable is not true then
    raise exception 'preview invite did not return the expected pack';
  end if;

  -- Happy path: join by invite.
  select *
  into v_join
  from public.shared_pack_join_by_invite_v1(
    substr(v_invite_code, 1, 3) || '-' || substr(v_invite_code, 4, 3),
    v_joiner_identity_id
  );

  v_joiner_membership_id := v_join.membership_id;

  if v_join.remote_pack_id is distinct from v_pack_id
     or v_joiner_membership_id is null then
    raise exception 'join by invite did not return expected membership';
  end if;

  -- Happy path: repeated join is idempotent and does not create duplicates.
  perform *
  from public.shared_pack_join_by_invite_v1(
    v_invite_code,
    v_joiner_identity_id
  );

  select count(*)
  into v_membership_count
  from public.shared_pack_members
  where pack_id = v_pack_id
    and member_identity_id = v_joiner_identity_id
    and removed_at is null;

  if v_membership_count <> 1 then
    raise exception 'repeated join created duplicate active membership';
  end if;

  -- Happy path: prepare item as SQL smoke test setup.
  insert into public.shared_pack_items (
    pack_id,
    title,
    state,
    updated_by_identity_id
  )
  values (
    v_pack_id,
    'Phase 3C Smoke Item',
    'active',
    v_owner_identity_id
  )
  returning id into v_item_id;

  -- Happy path: fetch snapshot as owner.
  select *
  into v_snapshot
  from public.shared_pack_fetch_snapshot_v1(
    v_pack_id,
    v_owner_identity_id
  );

  if v_snapshot.remote_pack_id is distinct from v_pack_id
     or v_snapshot.requester_role <> 'owner' then
    raise exception 'owner fetch snapshot returned wrong metadata';
  end if;

  if not exists (
    select 1
    from jsonb_array_elements(v_snapshot.items) item
    where item ->> 'id' = v_item_id::text
      and item ->> 'title' = 'Phase 3C Smoke Item'
      and item ->> 'state' = 'active'
  ) then
    raise exception 'owner snapshot does not include prepared item';
  end if;

  -- Happy path: fetch snapshot as joiner.
  select *
  into v_snapshot
  from public.shared_pack_fetch_snapshot_v1(
    v_pack_id,
    v_joiner_identity_id
  );

  if v_snapshot.remote_pack_id is distinct from v_pack_id
     or v_snapshot.requester_role <> 'member' then
    raise exception 'joiner fetch snapshot returned wrong metadata';
  end if;

  -- Happy path: update item state.
  select *
  into v_update
  from public.shared_pack_update_item_state_v1(
    v_item_id,
    v_joiner_identity_id,
    'done',
    v_completed_at
  );

  if v_update.remote_item_id is distinct from v_item_id
     or v_update.state <> 'done'
     or v_update.last_completed_at is distinct from v_completed_at then
    raise exception 'update item state returned wrong state';
  end if;

  select state
  into v_item_state
  from public.shared_pack_items
  where id = v_item_id
    and updated_by_identity_id = v_joiner_identity_id
    and last_completed_at = v_completed_at;

  if v_item_state <> 'done' then
    raise exception 'item state was not persisted after update';
  end if;

  -- Happy path: fetch snapshot again and confirm state changed.
  select *
  into v_snapshot
  from public.shared_pack_fetch_snapshot_v1(
    v_pack_id,
    v_owner_identity_id
  );

  if not exists (
    select 1
    from jsonb_array_elements(v_snapshot.items) item
    where item ->> 'id' = v_item_id::text
      and item ->> 'state' = 'done'
  ) then
    raise exception 'updated state is not visible in later snapshot';
  end if;

  -- Negative case: invalid invite preview returns not joinable/no target data.
  select *
  into v_preview
  from public.shared_pack_preview_invite_v1('BAD000');

  if v_preview.remote_pack_id is not null
     or coalesce(v_preview.is_joinable, false) is not false then
    raise exception 'invalid invite preview returned joinable data';
  end if;

  -- Negative case: invalid invite join fails and creates no membership.
  begin
    perform *
    from public.shared_pack_join_by_invite_v1(
      'BAD000',
      v_outsider_identity_id
    );
  exception
    when others then
      v_invalid_invite_failed := true;
  end;

  if not v_invalid_invite_failed then
    raise exception 'invalid invite join did not fail';
  end if;

  select count(*)
  into v_membership_count
  from public.shared_pack_members
  where pack_id = v_pack_id
    and member_identity_id = v_outsider_identity_id
    and removed_at is null;

  if v_membership_count <> 0 then
    raise exception 'invalid invite join created outsider membership';
  end if;

  -- Negative case: non-member fetch fails.
  begin
    perform *
    from public.shared_pack_fetch_snapshot_v1(
      v_pack_id,
      v_outsider_identity_id
    );
  exception
    when others then
      v_non_member_fetch_failed := true;
  end;

  if not v_non_member_fetch_failed then
    raise exception 'non-member fetch did not fail';
  end if;

  -- Negative case: non-member update fails and item state remains unchanged.
  begin
    perform *
    from public.shared_pack_update_item_state_v1(
      v_item_id,
      v_outsider_identity_id,
      'skipped',
      null
    );
  exception
    when others then
      v_non_member_update_failed := true;
  end;

  if not v_non_member_update_failed then
    raise exception 'non-member update did not fail';
  end if;

  select state
  into v_item_state
  from public.shared_pack_items
  where id = v_item_id;

  if v_item_state <> 'done' then
    raise exception 'non-member update changed item state';
  end if;

  -- Negative case: invalid invite code constraint rejects direct insert.
  begin
    insert into public.shared_pack_invites (
      pack_id,
      code,
      created_by_identity_id
    )
    values (
      v_pack_id,
      'O01ILX',
      v_owner_identity_id
    );
  exception
    when check_violation then
      v_invalid_insert_failed := true;
  end;

  if not v_invalid_insert_failed then
    raise exception 'invalid invite code constraint did not reject insert';
  end if;
end;
$$;

rollback;
