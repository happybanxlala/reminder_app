import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
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
}
