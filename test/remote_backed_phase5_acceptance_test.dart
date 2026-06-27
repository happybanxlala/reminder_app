import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reminder_app/features/reminders/data/account_protection_service.dart';
import 'package:reminder_app/features/reminders/data/auth_repository.dart';
import 'package:reminder_app/features/reminders/data/identity_repository.dart';
import 'package:reminder_app/features/reminders/data/local/app_database.dart';
import 'package:reminder_app/features/reminders/data/reminder_backup_service.dart';
import 'package:reminder_app/features/reminders/domain/account_protection.dart';
import 'package:reminder_app/features/reminders/domain/shared_pack.dart';

void main() {
  test('Phase 5 docs expose acceptance matrix, smoke test, and backlog', () {
    final syncSpec = File(
      'docs/core/07_remote_backed_shared_pack_sync_spec.md',
    ).readAsStringSync();
    final coreSpec = File(
      'docs/core/04_core_model_spec_v1.md',
    ).readAsStringSync();
    final widgetSpec = File(
      'docs/core/05_home_widget_spec.md',
    ).readAsStringSync();
    final remoteSpec = File(
      'docs/core/06_supabase_remote_model_spec.md',
    ).readAsStringSync();
    final smoke = File(
      'docs/core/manual_tests/phase5_remote_backed_shared_pack_acceptance.md',
    ).readAsStringSync();

    expect(syncSpec, contains('Phase 5 Acceptance Matrix'));
    expect(
      syncSpec,
      contains(
        'Phase 5 completes the remote-backed shared pack local-first MVP',
      ),
    );
    expect(syncSpec, contains('Phase 6A：Background Sync Design Spec'));
    expect(syncSpec, contains('None of these are implemented in Phase 5M'));
    expect(
      coreSpec,
      contains(
        'Phase 5M completes the remote-backed shared pack local-first MVP',
      ),
    );
    expect(remoteSpec, contains('Phase 5M Acceptance / Hardening'));
    expect(
      widgetSpec,
      contains('Notification summaries are handled separately by Phase 5G'),
    );

    expect(smoke, contains('Test 1: Anonymous Identity + Email Binding'));
    expect(smoke, contains('Test 7: Backup Legacy'));
    expect(smoke, contains('not full Email sign-in'));
    expect(smoke, contains('no background sync'));
    expect(smoke, contains('no automatic retry'));
    expect(smoke, contains('UI does not say `已讀`, `未讀`, `在線`, or `離線`'));
  });

  test(
    'Email binding acceptance protects only after verification and has no sync side effects',
    () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);
      final identity = IdentityRepository(db.reminderDao);
      final auth = FakeAuthRepository();
      final service = AccountProtectionService(
        identityRepository: identity,
        authRepository: auth,
      );
      final remote = await auth.signInAnonymously();
      final local = await identity.linkRemoteIdentity(
        remoteUserId: remote.remoteUserId,
        provider: AuthProviderType.supabaseAnonymous,
      );

      final started = await service.startEmailBinding('care@example.com');
      final afterCodeSent = await service.getStatus();
      final beforeVerifyBackup = await ReminderBackupService(
        db.reminderDao,
      ).exportJsonString();

      expect(started.status, EmailBindingStartStatus.codeSent);
      expect(
        afterCodeSent.status,
        AccountProtectionStatus.anonymousUnprotected,
      );
      expect(await db.reminderDao.listSyncOutboxEntries(), isEmpty);
      expect(beforeVerifyBackup, isNot(contains('care@example.com')));
      expect(beforeVerifyBackup, isNot(contains('123456')));
      expect(beforeVerifyBackup, isNot(contains('sync_outbox')));

      final verified = await service.verifyEmailBinding(
        email: 'care@example.com',
        code: '123456',
      );
      final updated = await identity.getCurrentAppUser();
      final afterVerifyBackup = await ReminderBackupService(
        db.reminderDao,
      ).exportJsonString();

      expect(verified.status, EmailBindingVerifyStatus.bound);
      expect(verified.snapshot.status, AccountProtectionStatus.linkedProtected);
      expect(updated.id, local.id);
      expect(updated.remoteUserId, remote.remoteUserId);
      expect(updated.remoteProvider, AuthProviderType.email);
      expect(await db.reminderDao.listSyncOutboxEntries(), isEmpty);
      expect(afterVerifyBackup, isNot(contains('care@example.com')));
      expect(afterVerifyBackup, isNot(contains('123456')));
      expect(afterVerifyBackup, isNot(contains('access_token')));
      expect(afterVerifyBackup, isNot(contains('refresh_token')));
      expect(afterVerifyBackup, isNot(contains('session')));
      expect(afterVerifyBackup, isNot(contains('credential')));
      expect(afterVerifyBackup, isNot(contains('service_role')));
      expect(afterVerifyBackup, isNot(contains('token_hash')));
      expect(afterVerifyBackup, isNot(contains('sync_outbox')));
    },
  );
}
