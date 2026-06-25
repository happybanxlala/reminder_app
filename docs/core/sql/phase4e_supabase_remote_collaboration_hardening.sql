-- Reminder App Phase 4E Supabase Remote Collaboration Hardening
-- Manual incremental patch only. Do not auto-apply to production.
--
-- Apply order:
--   1. docs/core/sql/phase3c_supabase_minimal_poc.sql
--   2. docs/core/sql/phase4a_supabase_invite_membership_mvp.sql
--   3. docs/core/sql/phase4c_supabase_remote_member_actions_mvp.sql
--   4. docs/core/sql/phase4d_supabase_realtime_soft_notification_poc.sql
--   5. docs/core/sql/phase4e_supabase_remote_collaboration_hardening.sql
--
-- Phase 4E does not create new product features. It hardens the developer-only
-- remote collaboration POC contract and manual smoke-test flow.
--
-- RPC contract checklist:
-- - Actor-sensitive RPCs must use auth.uid(), never client-supplied actor ids.
-- - complete_pack_item returns completed / already_completed and keeps
--   completed_by_user_id factual.
-- - undo_pack_item_completion returns undone / already_not_completed and never
--   deletes item_completions.
-- - join_pack_with_invite returns joined / already_member. A removed member can
--   rejoin only through a valid active invite.
-- - ensure_active_pack_invite returns the existing active invite or creates one.
-- - fetch_pack_invite_state returns the current host-readable active invite.
-- - refresh_pack_invite revokes the previous active invite before creating one.
-- - revoke_pack_invite returns revoked / already_revoked.
-- - invite codes are bearer secrets. Remote pack_invites may store host-readable
--   plaintext for active invite recovery, but plaintext invite codes must not be
--   persisted in activity_events, backup, sync metadata, or local DB. In short:
--   plaintext invite codes must not be persisted outside host-readable remote
--   invite rows.
--
-- RLS checklist:
-- - Active pack members can read pack data.
-- - Non-members and removed members must not read or mutate pack data.
-- - Hosts manage invites and destructive pack settings.
-- - Direct activity_events inserts remain a POC path only and must keep
--   actor_user_id = auth.uid(); long-term production writes should move behind
--   RPC / trigger controlled paths.
--
-- Realtime checklist:
-- - Realtime is advisory only and is not a source of truth.
-- - Realtime signals must not auto refresh, mutate viewer item state, merge local DB, create local pack/items, create sync_mappings, or write backup.
-- - Manual snapshot refresh remains the authoritative remote read path.
--
-- App security checklist:
-- - Flutter app uses only SUPABASE_URL and SUPABASE_ANON_KEY.
-- - Never place privileged backend credentials or server secrets in the
--   Flutter app.
-- - Do not hardcode project URL or anon key in source.

-- Idempotent Phase 4D realtime publication setup.
-- REVIEW: Validate in Supabase SQL editor or local Supabase CLI. If the
-- supabase_realtime publication does not exist, enable Realtime for the project
-- first or use the Supabase dashboard table toggle.
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
