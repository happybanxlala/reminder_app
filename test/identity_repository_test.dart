import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reminder_app/features/reminders/data/auth_repository.dart';
import 'package:reminder_app/features/reminders/data/identity_repository.dart';
import 'package:reminder_app/features/reminders/data/local/app_database.dart';
import 'package:reminder_app/features/reminders/domain/shared_pack.dart';

void main() {
  test('ensureLocalIdentity creates one stable local GUID user', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final repository = IdentityRepository(db.reminderDao);

    final first = await repository.ensureLocalIdentity();
    final second = await repository.ensureLocalIdentity();
    final users = await db.reminderDao.listLocalUsers();
    final installation = await repository.ensureAppInstallation();

    expect(first.id, second.id);
    expect(first.id, matches(RegExp(r'^[0-9a-f-]{36}$')));
    expect(first.identityKind, LocalUserIdentityKind.local);
    expect(first.isPrimary, isTrue);
    expect(users.where((user) => user.isPrimary), hasLength(1));
    expect(installation.installationGuid, matches(RegExp(r'^[0-9a-f-]{36}$')));
  });

  test(
    'linkRemoteIdentity keeps local id stable and sets remote fields',
    () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);
      final repository = IdentityRepository(db.reminderDao);

      final local = await repository.ensureLocalIdentity();
      final anonymous = await repository.linkRemoteIdentity(
        remoteUserId: 'fake_supabase_user_123',
        provider: AuthProviderType.supabaseAnonymous,
      );
      final linked = await repository.linkRemoteIdentity(
        remoteUserId: 'fake_apple_user_123',
        provider: AuthProviderType.apple,
      );

      expect(anonymous.id, local.id);
      expect(anonymous.remoteUserId, 'fake_supabase_user_123');
      expect(anonymous.remoteProvider, AuthProviderType.supabaseAnonymous);
      expect(anonymous.identityKind, LocalUserIdentityKind.anonymousRemote);
      expect(linked.id, local.id);
      expect(linked.remoteProvider, AuthProviderType.apple);
      expect(linked.identityKind, LocalUserIdentityKind.linked);
    },
  );

  test('FakeAuthRepository returns fake identities without tokens', () async {
    final auth = FakeAuthRepository();

    final anonymous = await auth.signInAnonymously();
    final google = await auth.linkWithGoogle();

    expect(anonymous.remoteUserId, startsWith('fake_supabase_user_'));
    expect(anonymous.provider, AuthProviderType.supabaseAnonymous);
    expect(google.remoteUserId, startsWith('fake_google_user_'));
    expect(google.provider, AuthProviderType.google);
    expect(
      (await auth.getCurrentRemoteIdentity())?.remoteUserId,
      google.remoteUserId,
    );
  });
}
