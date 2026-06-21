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
}
