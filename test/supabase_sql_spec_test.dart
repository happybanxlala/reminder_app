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
    expect(lower, contains('join_pack_with_invite'));
    expect(lower, contains('revoke_pack_invite'));
    expect(lower, contains('enable row level security'));
    expect(lower, contains('code_hash'));
    expect(lower, contains('digest('));
    expect(lower, contains('only code_hash is stored'));
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
}
