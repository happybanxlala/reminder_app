-- Reminder App Phase 4D Supabase Realtime Soft Notification POC
-- Manual setup note only. Do not auto-apply to production.
-- Apply after:
--   1. docs/core/sql/phase3c_supabase_minimal_poc.sql
--   2. docs/core/sql/phase4a_supabase_invite_membership_mvp.sql
--   3. docs/core/sql/phase4c_supabase_remote_member_actions_mvp.sql
--
-- Phase 4D uses Realtime Postgres Changes on public.activity_events INSERT as
-- an advisory soft notification signal. The app must still fetch the remote
-- snapshot manually after notification; realtime payload is not source of truth.
-- Realtime signal must not auto-refresh, merge local data, write local DB,
-- create sync mappings, or mutate viewer item/completion state directly.
--
-- REVIEW: Validate in Supabase SQL editor or local Supabase CLI before use.
-- REVIEW: The block below is idempotent. If public.activity_events is already
-- in the supabase_realtime publication, it does nothing.
-- REVIEW: Phase 4D listens to INSERT only and does not need previous row data,
-- so REPLICA IDENTITY FULL is intentionally not enabled here.

do $$
begin
  if exists (
    select 1
    from pg_publication
    where pubname = 'supabase_realtime'
  ) and not exists (
    select 1
    from pg_publication_tables
    where pubname = 'supabase_realtime'
      and schemaname = 'public'
      and tablename = 'activity_events'
  ) then
    execute 'alter publication supabase_realtime add table public.activity_events';
  end if;
end;
$$;
