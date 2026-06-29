import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Phase SQL files exist and document manual apply order', () {
    final files = [
      'docs/core/sql/phase3c_supabase_minimal_poc.sql',
      'docs/core/sql/phase4a_supabase_invite_membership_mvp.sql',
      'docs/core/sql/phase4c_supabase_remote_member_actions_mvp.sql',
      'docs/core/sql/phase4d_supabase_realtime_soft_notification_poc.sql',
      'docs/core/sql/phase4e_supabase_remote_collaboration_hardening.sql',
      'docs/core/sql/phase5l_member_sync_awareness_mvp.sql',
    ];

    for (final path in files) {
      expect(File(path).existsSync(), isTrue, reason: path);
    }

    final phase4e = File(files.last).readAsStringSync().toLowerCase();
    expect(phase4e, contains('apply order'));
    expect(phase4e, contains('phase3c_supabase_minimal_poc.sql'));
    expect(phase4e, contains('phase4a_supabase_invite_membership_mvp.sql'));
    expect(phase4e, contains('phase4c_supabase_remote_member_actions_mvp.sql'));
    expect(
      phase4e,
      contains('phase4d_supabase_realtime_soft_notification_poc.sql'),
    );
    expect(
      phase4e,
      contains('phase4e_supabase_remote_collaboration_hardening.sql'),
    );
    final phase5l = File(files.last).readAsStringSync().toLowerCase();
    expect(phase5l, contains('apply order'));
    expect(phase5l, contains('manual incremental patch'));
    expect(phase5l, contains('do not auto-apply to production'));
    expect(phase5l, contains('phase5l_member_sync_awareness_mvp.sql'));
  });

  test('Remote grants repair SQL covers authenticated privileges safely', () {
    final file = File('docs/core/sql/phase_remote_grants_rls_repair.sql');

    expect(file.existsSync(), isTrue);
    final sql = file.readAsStringSync();
    final lower = sql.toLowerCase();

    const readWriteTables = [
      'profiles',
      'packs',
      'pack_members',
      'items',
      'item_completions',
      'resources',
      'resource_events',
      'stages',
      'stage_acknowledgements',
      'pack_invites',
    ];
    for (final table in readWriteTables) {
      expect(
        lower,
        contains(
          'grant select, insert, update on table public.$table to authenticated',
        ),
        reason: table,
      );
    }
    expect(
      lower,
      contains(
        'grant select, insert on table public.activity_events to authenticated',
      ),
    );

    expect(lower, isNot(contains(' to anon')));
    expect(lower, isNot(contains('grant delete')));
    expect(lower, isNot(contains('disable row level security')));
    expect(lower, isNot(contains('service_role')));
    expect(lower, isNot(contains('service role key')));
    expect(lower, isNot(contains('secret key')));
  });

  test('Remote grants repair SQL locks function execute grants', () {
    final lower = File(
      'docs/core/sql/phase_remote_grants_rls_repair.sql',
    ).readAsStringSync().toLowerCase();

    const functions = [
      'upsert_current_profile(text)',
      'create_shared_pack(text, text)',
      'create_pack_item(uuid, text, text)',
      'complete_pack_item(uuid, text)',
      'undo_pack_item_completion(uuid, text)',
      'create_pack_invite(uuid, integer, integer)',
      'ensure_active_pack_invite(uuid, integer, integer)',
      'fetch_pack_invite_state(uuid)',
      'refresh_pack_invite(uuid, integer, integer)',
      'join_pack_with_invite(text)',
      'revoke_pack_invite(uuid)',
      'is_pack_member(uuid)',
      'is_pack_host(uuid)',
      'hash_pack_invite_code(text, uuid)',
      'generate_pack_invite_code()',
    ];

    for (final function in functions) {
      expect(
        lower,
        contains('revoke all on function public.$function from public'),
        reason: function,
      );
      expect(
        lower,
        contains('grant execute on function public.$function to authenticated'),
        reason: function,
      );
    }

    expect(lower, contains('security definer'));
    expect(lower, contains('set search_path = public'));
    expect(lower, contains('current_user_id uuid := auth.uid()'));
    expect(lower, contains('auth required'));
    expect(lower, isNot(contains('upsert_current_profile(user_id')));
    expect(lower, isNot(contains('user_id uuid,')));
  });

  test('Remote grants repair SQL makes create_shared_pack safe definer RPC', () {
    final lower = File(
      'docs/core/sql/phase_remote_grants_rls_repair.sql',
    ).readAsStringSync().toLowerCase();
    final match = RegExp(
      r'create or replace function public\.create_shared_pack[\s\S]*?comment on function public\.create_shared_pack',
    ).firstMatch(lower);

    expect(match, isNotNull);
    final functionSql = match!.group(0)!;

    expect(functionSql, contains('pack_name text'));
    expect(functionSql, contains('description text default null'));
    expect(functionSql, contains('security definer'));
    expect(functionSql, contains('set search_path = public'));
    expect(functionSql, contains('current_user_id uuid := auth.uid()'));
    expect(functionSql, contains("raise exception 'auth required'"));
    expect(functionSql, contains('host_user_id'));
    expect(functionSql, contains('current_user_id'));
    expect(functionSql, contains('public.pack_members'));
    expect(functionSql, contains('user_id'));
    expect(functionSql, contains("'host'"));
    expect(functionSql, contains('public.activity_events'));
    expect(functionSql, contains('actor_user_id'));
    expect(functionSql, isNot(contains('create_shared_pack(user_id')));
    expect(functionSql, isNot(contains('user_id uuid,')));
    expect(functionSql, isNot(contains('target_user_id')));
    expect(functionSql, isNot(contains('caller_user_id')));
  });

  test('Remote grants repair SQL includes manual privilege audit query', () {
    final lower = File(
      'docs/core/sql/phase_remote_grants_rls_repair.sql',
    ).readAsStringSync().toLowerCase();

    expect(lower, contains("has_table_privilege('authenticated'"));
    expect(lower, contains("'select') as can_select"));
    expect(lower, contains("'insert') as can_insert"));
    expect(lower, contains("'update') as can_update"));
    expect(lower, contains("'delete') as can_delete"));
    expect(lower, contains('information_schema.tables'));
    expect(lower, contains('pg_get_function_identity_arguments'));
    expect(lower, contains('p.prosecdef as is_security_definer'));
    expect(lower, contains("has_function_privilege('anon', p.oid, 'execute')"));
    expect(
      lower,
      contains("has_function_privilege('authenticated', p.oid, 'execute')"),
    );
  });

  test('Phase 3C SQL draft contains RLS and RPC contract boundaries', () {
    final file = File('docs/core/sql/phase3c_supabase_minimal_poc.sql');

    expect(file.existsSync(), isTrue);
    final lower = file.readAsStringSync().toLowerCase();

    expect(lower, contains('create extension if not exists pgcrypto'));
    expect(lower, contains('enable row level security'));
    expect(lower, contains('create or replace function public.is_pack_member'));
    expect(lower, contains('create or replace function public.is_pack_host'));
    expect(lower, contains('set search_path = public'));
    expect(lower, contains('auth.uid()'));
    expect(lower, contains('complete_pack_item'));
    expect(lower, contains('already_completed'));
    expect(lower, contains('one_active_completion_per_item'));
    expect(lower, isNot(contains('service_role')));
    expect(lower, isNot(contains('service role key')));
    expect(lower, isNot(contains('secret key')));
  });

  test('Phase 4A invite SQL draft contains required safety boundaries', () {
    final file = File(
      'docs/core/sql/phase4a_supabase_invite_membership_mvp.sql',
    );

    expect(file.existsSync(), isTrue);
    final sql = file.readAsStringSync();
    final lower = sql.toLowerCase();

    expect(lower, contains('pack_invites'));
    expect(lower, contains('create_pack_invite'));
    expect(lower, contains('ensure_active_pack_invite'));
    expect(lower, contains('fetch_pack_invite_state'));
    expect(lower, contains('refresh_pack_invite'));
    expect(lower, contains('join_pack_with_invite'));
    expect(lower, contains('revoke_pack_invite'));
    expect(lower, contains('enable row level security'));
    expect(lower, contains('invite_code'));
    expect(lower, contains('code_hash'));
    expect(lower, contains('digest('));
    expect(lower, contains('pack_invites_one_active_per_pack_idx'));
    expect(lower, contains('abcdefghjklmnpqrstuvwxyz23456789'));
    expect(lower, contains('public.pack_invites.invite_code is null'));
    expect(lower, contains('public.pack_invites.expires_at <= now()'));
    expect(lower, contains('auth.uid()'));
    expect(lower, contains('already_member'));
    expect(lower, contains('invite_created'));
    expect(lower, isNot(contains("'invite_code', generated_code")));
    expect(lower, isNot(contains('"invite_code", generated_code')));
    expect(lower, isNot(contains('service_role')));
    expect(lower, isNot(contains('service role key')));
    expect(lower, isNot(contains('secret key')));
  });

  test('Phase 4C member action SQL draft contains undo safety boundaries', () {
    final file = File(
      'docs/core/sql/phase4c_supabase_remote_member_actions_mvp.sql',
    );

    expect(file.existsSync(), isTrue);
    final sql = file.readAsStringSync();
    final lower = sql.toLowerCase();

    expect(lower, contains('undo_pack_item_completion'));
    expect(lower, contains('auth.uid()'));
    expect(lower, contains('is_pack_member'));
    expect(lower, contains('undone_by_user_id'));
    expect(lower, contains('undone_at'));
    expect(lower, contains('already_not_completed'));
    expect(lower, contains('item_undone'));
    expect(lower, contains('direct completion'));
    expect(lower, contains('not allowed'));
    expect(lower, isNot(contains('delete from public.item_completions')));
    expect(lower, isNot(contains('service_role')));
    expect(lower, isNot(contains('service role key')));
    expect(lower, isNot(contains('secret key')));
  });

  test('Phase 4D realtime SQL draft documents soft notification setup', () {
    final file = File(
      'docs/core/sql/phase4d_supabase_realtime_soft_notification_poc.sql',
    );

    expect(file.existsSync(), isTrue);
    final sql = file.readAsStringSync();
    final lower = sql.toLowerCase();

    expect(lower, contains('activity_events'));
    expect(lower, contains('supabase_realtime'));
    expect(lower, contains('alter publication'));
    expect(lower, contains('soft notification'));
    expect(lower, contains('manual'));
    expect(lower, contains('source of truth'));
    expect(
      lower,
      contains('replica identity full is intentionally not enabled'),
    );
    expect(lower, isNot(contains('service_role')));
    expect(lower, isNot(contains('service role key')));
    expect(lower, isNot(contains('secret key')));
  });

  test('Phase 4E hardening SQL keeps realtime setup idempotent', () {
    final file = File(
      'docs/core/sql/phase4e_supabase_remote_collaboration_hardening.sql',
    );

    expect(file.existsSync(), isTrue);
    final lower = file.readAsStringSync().toLowerCase();

    expect(lower, contains('pg_publication_tables'));
    expect(lower, contains('supabase_realtime'));
    expect(lower, contains('activity_events'));
    expect(lower, contains('auth.uid()'));
    expect(lower, contains('advisory only'));
    expect(lower, contains('not a source of truth'));
    expect(lower, contains('must not auto refresh'));
    expect(lower, contains('merge local db'));
    expect(lower, contains('plaintext invite codes must not be persisted'));
    expect(lower, contains('only supabase_url and supabase_anon_key'));
    expect(lower, isNot(contains('service_role')));
    expect(lower, isNot(contains('service role key')));
    expect(lower, isNot(contains('secret key')));
  });

  test('Phase 4E manual smoke test template covers host member RLS flow', () {
    final file = File(
      'docs/core/manual_tests/phase4e_remote_collaboration_smoke_test.md',
    );

    expect(file.existsSync(), isTrue);
    final lower = file.readAsStringSync().toLowerCase();

    expect(lower, contains('device a host flow'));
    expect(lower, contains('device b member flow'));
    expect(lower, contains('device c rls'));
    expect(lower, contains('sql apply'));
    expect(lower, contains('realtime subscribed'));
    expect(lower, contains('no local merge'));
    expect(lower, contains('no auto refresh'));
    expect(lower, contains('no token/session/credential'));
  });

  test('Phase 5L SQL adds member sync state with active-member RLS', () {
    final file = File('docs/core/sql/phase5l_member_sync_awareness_mvp.sql');

    expect(file.existsSync(), isTrue);
    final lower = file.readAsStringSync().toLowerCase();

    expect(
      lower,
      contains('create table if not exists public.pack_member_sync_states'),
    );
    expect(lower, contains('pack_id uuid not null references public.packs'));
    expect(lower, contains('user_id uuid not null references public.profiles'));
    expect(lower, contains('last_snapshot_pulled_at'));
    expect(lower, contains('last_imported_at'));
    expect(lower, contains('last_seen_activity_event_id'));
    expect(lower, contains('last_seen_activity_at'));
    expect(lower, contains('pack_member_sync_states_pack_user_unique'));
    expect(
      lower,
      contains(
        'alter table public.pack_member_sync_states enable row level security',
      ),
    );
    expect(lower, contains('for select'));
    expect(lower, contains('for insert'));
    expect(lower, contains('for update'));
    expect(lower, contains('caller.user_id = auth.uid()'));
    expect(lower, contains("caller.status = 'active'"));
    expect(lower, contains('user_id = auth.uid()'));
    expect(
      lower,
      contains(
        'grant select, insert, update on table public.pack_member_sync_states',
      ),
    );
    expect(lower, isNot(contains('grant delete')));
    expect(lower, isNot(contains('service_role')));
    expect(lower, isNot(contains('service role key')));
    expect(lower, isNot(contains('plain invite')));
    expect(lower, isNot(contains('device')));
    expect(lower, isNot(contains('ip address')));
    expect(lower, isNot(contains('location')));
  });

  test('Phase 5L SQL defines reporting and freshness RPCs safely', () {
    final lower = File(
      'docs/core/sql/phase5l_member_sync_awareness_mvp.sql',
    ).readAsStringSync().toLowerCase();

    expect(lower, contains('report_pack_snapshot_imported'));
    expect(lower, contains('get_pack_member_freshness'));
    expect(lower, contains('current_user_id uuid := auth.uid()'));
    expect(lower, contains("raise exception 'auth required'"));
    expect(lower, contains('public.is_pack_member(target_pack_id)'));
    expect(lower, contains('on conflict (pack_id, user_id) do update'));
    expect(lower, contains("'up_to_date'::text"));
    expect(lower, contains("'possibly_stale'::text"));
    expect(lower, contains("'no_sync_report'::text"));
    expect(
      lower,
      contains('revoke all on function public.report_pack_snapshot_imported'),
    );
    expect(
      lower,
      contains(
        'grant execute on function public.report_pack_snapshot_imported',
      ),
    );
    expect(
      lower,
      contains('revoke all on function public.get_pack_member_freshness'),
    );
    expect(
      lower,
      contains('grant execute on function public.get_pack_member_freshness'),
    );
    expect(lower, isNot(contains('service_role')));
    expect(lower, isNot(contains('service role key')));
    expect(lower, isNot(contains('read receipt')));
    expect(lower, isNot(contains('online')));
    expect(lower, isNot(contains('offline')));
  });

  test('Phase 5L manual smoke test documents boundaries', () {
    final file = File(
      'docs/core/manual_tests/phase5l_member_sync_awareness_smoke_test.md',
    );

    expect(file.existsSync(), isTrue);
    final lower = file.readAsStringSync().toLowerCase();

    expect(lower, contains('phase 5l'));
    expect(lower, contains('pack freshness'));
    expect(lower, contains('report_pack_snapshot_imported'));
    expect(lower, contains('get_pack_member_freshness'));
    expect(lower, contains('本機已更新，但未能回報同步狀態'));
    expect(lower, contains('no auto refresh'));
    expect(lower, contains('no background sync'));
    expect(lower, contains('no outbox flush'));
    expect(lower, isNot(contains('已讀')));
    expect(lower, isNot(contains('未讀')));
    expect(lower, isNot(contains('在線')));
    expect(lower, isNot(contains('離線')));
    expect(lower, isNot(contains('device')));
    expect(lower, isNot(contains('ip')));
    expect(lower, isNot(contains('location')));
  });

  test('Phase 6D Resource SQL is partial-apply safe', () {
    final lower = File(
      'docs/core/sql/phase6d_remote_backed_resource_mvp.sql',
    ).readAsStringSync().toLowerCase();

    expect(lower, contains('create table if not exists public.resources'));
    expect(
      lower,
      contains('create table if not exists public.resource_events'),
    );
    for (final column in [
      'pack_id',
      'resource_id',
      'actor_user_id',
      'change_type',
      'client_mutation_id',
      'metadata_json',
    ]) {
      expect(
        lower,
        contains(
          'alter table public.resource_events add column if not exists $column',
        ),
        reason: column,
      );
    }
    expect(
      lower.indexOf(
        'alter table public.resource_events add column if not exists client_mutation_id',
      ),
      lessThan(lower.indexOf('resource_events_client_mutation_unique')),
    );
    expect(
      lower,
      isNot(contains('create or replace function public.start_background')),
    );
    expect(
      lower,
      isNot(contains('create or replace function public.apply_widget')),
    );
  });

  test('Phase 6E Stage SQL is partial-apply safe', () {
    final lower = File(
      'docs/core/sql/phase6e_remote_backed_stage_mvp.sql',
    ).readAsStringSync().toLowerCase();

    for (final table in [
      'stage_trackers',
      'stage_rules',
      'stage_records',
      'stage_acknowledgements',
    ]) {
      expect(lower, contains('create table if not exists public.$table'));
      expect(
        lower,
        contains('alter table public.$table add column if not exists pack_id'),
        reason: table,
      );
    }
    expect(
      lower.indexOf(
        'alter table public.stage_acknowledgements add column if not exists client_mutation_id',
      ),
      lessThan(lower.indexOf('stage_acknowledgements_client_mutation_unique')),
    );
    expect(
      lower,
      contains('drop policy if exists "stage_trackers_active_members_read"'),
    );
    expect(
      lower,
      isNot(contains('create or replace function public.start_background')),
    );
    expect(
      lower,
      isNot(contains('create or replace function public.apply_widget')),
    );
  });

  test('Phase 6E Stage SQL defines production app-called RPCs', () {
    final lower = File(
      'docs/core/sql/phase6e_remote_backed_stage_mvp.sql',
    ).readAsStringSync().toLowerCase();

    const functions = [
      'create_pack_stage_tracker(uuid, text, text, date, date, jsonb, text)',
      'update_pack_stage_tracker(uuid, text, text, date, date, text)',
      'archive_pack_stage_tracker(uuid, text)',
      'create_pack_stage_rule(uuid, jsonb, text)',
      'update_pack_stage_rule(uuid, jsonb, text)',
      'update_pack_stage_rule_status(uuid, text, text)',
      'create_pack_stage_record(uuid, uuid, jsonb, text)',
      'update_pack_stage_record(uuid, jsonb, text)',
      'archive_pack_stage_record(uuid, text)',
      'acknowledge_pack_stage_record(uuid, text)',
    ];
    for (final function in functions) {
      final name = function.substring(0, function.indexOf('('));
      expect(
        lower,
        contains('create or replace function public.$name'),
        reason: name,
      );
      expect(
        lower,
        contains('revoke all on function public.$function from public'),
        reason: function,
      );
      expect(
        lower,
        contains('grant execute on function public.$function to authenticated'),
        reason: function,
      );
    }

    expect(lower, contains('auth.uid()'));
    expect(lower, contains('public.is_pack_member('));
    expect(lower, isNot(contains('is_active_pack_member')));
    expect(lower, contains('client_mutation_id'));
    expect(lower, contains('activity_events'));
    expect(lower, contains('stage_tracker_created'));
    expect(lower, contains('stage_acknowledged'));
    expect(lower, isNot(contains('service_role')));
    expect(lower, isNot(contains('service role key')));
    expect(lower, isNot(contains('secret key')));
  });
}
