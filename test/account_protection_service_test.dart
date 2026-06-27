import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reminder_app/features/reminders/data/account_protection_service.dart';
import 'package:reminder_app/features/reminders/data/auth_repository.dart';
import 'package:reminder_app/features/reminders/data/identity_repository.dart';
import 'package:reminder_app/features/reminders/data/local/app_database.dart';
import 'package:reminder_app/features/reminders/domain/account_protection.dart';
import 'package:reminder_app/features/reminders/domain/shared_pack.dart';

void main() {
  test('local-only user reports localOnly', () async {
    final env = await _Env.create();
    addTearDown(env.close);

    final status = await env.service.getStatus();

    expect(status.status, AccountProtectionStatus.localOnly);
    expect(status.localUser.remoteUserId, isNull);
  });

  test('anonymous remote identity reports anonymousUnprotected', () async {
    final env = await _Env.create();
    addTearDown(env.close);
    final identity = await env.auth.signInAnonymously();
    await env.identity.linkRemoteIdentity(
      remoteUserId: identity.remoteUserId,
      provider: AuthProviderType.supabaseAnonymous,
    );

    final status = await env.service.getStatus();

    expect(status.status, AccountProtectionStatus.anonymousUnprotected);
    expect(status.currentRemoteIsAnonymous, isTrue);
  });

  test(
    'fake provider binding keeps local id stable and marks linked',
    () async {
      final env = await _Env.create();
      addTearDown(env.close);
      final local = await env.identity.ensureLocalIdentity();

      final outcome = await env.service.bindWithProvider(
        AccountBindingProvider.apple,
      );

      expect(outcome.result, AccountBindingResult.linked);
      expect(outcome.snapshot.status, AccountProtectionStatus.linkedProtected);
      final updated = await env.identity.getCurrentAppUser();
      expect(updated.id, local.id);
      expect(updated.identityKind, LocalUserIdentityKind.linked);
      expect(updated.remoteProvider, AuthProviderType.apple);
      expect(updated.remoteUserId, startsWith('fake_apple_user_'));
    },
  );

  test('unsupported provider does not mutate local user', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final identity = IdentityRepository(db.reminderDao);
    final service = AccountProtectionService(
      identityRepository: identity,
      authRepository: const DisabledAuthRepository(
        RemoteAuthFailureReason.unavailable,
      ),
    );
    final local = await identity.ensureLocalIdentity();

    final outcome = await service.bindWithProvider(
      AccountBindingProvider.email,
    );

    expect(outcome.result, AccountBindingResult.unsupported);
    final updated = await identity.getCurrentAppUser();
    expect(updated.id, local.id);
    expect(updated.identityKind, LocalUserIdentityKind.local);
    expect(updated.remoteUserId, isNull);
  });

  test('config missing binding failure is typed safely', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final identity = IdentityRepository(db.reminderDao);
    final service = AccountProtectionService(
      identityRepository: identity,
      authRepository: const _ConfigMissingBindingAuthRepository(),
    );

    final outcome = await service.bindWithProvider(
      AccountBindingProvider.email,
    );

    expect(outcome.result, AccountBindingResult.configMissing);
    final updated = await identity.getCurrentAppUser();
    expect(updated.identityKind, LocalUserIdentityKind.local);
    expect(updated.remoteUserId, isNull);
  });

  test('current remote identity failure reports unavailable status', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final identity = IdentityRepository(db.reminderDao);
    final service = AccountProtectionService(
      identityRepository: identity,
      authRepository: const _ThrowingCurrentAuthRepository(),
    );

    final status = await service.getStatus();

    expect(status.status, AccountProtectionStatus.unavailable);
    expect(status.currentRemoteUserId, isNull);
  });

  test('missing remote session returns remoteSessionMissing', () async {
    final env = await _Env.create();
    addTearDown(env.close);
    await env.identity.linkRemoteIdentity(
      remoteUserId: 'lost-remote-user',
      provider: AuthProviderType.supabaseAnonymous,
    );

    final status = await env.service.getStatus();
    final outcome = await env.service.bindWithProvider(
      AccountBindingProvider.google,
    );

    expect(status.status, AccountProtectionStatus.remoteSessionMissing);
    expect(outcome.result, AccountBindingResult.remoteSessionMissing);
  });

  test(
    'email binding start validates email and leaves user anonymous',
    () async {
      final env = await _Env.create();
      addTearDown(env.close);
      final remote = await env.auth.signInAnonymously();
      await env.identity.linkRemoteIdentity(
        remoteUserId: remote.remoteUserId,
        provider: AuthProviderType.supabaseAnonymous,
      );

      final invalid = await env.service.startEmailBinding('not-an-email');
      final started = await env.service.startEmailBinding('USER@example.COM ');
      final status = await env.service.getStatus();

      expect(invalid.status, EmailBindingStartStatus.emailInvalid);
      expect(started.status, EmailBindingStartStatus.codeSent);
      expect(started.normalizedEmail, 'user@example.com');
      expect(status.status, AccountProtectionStatus.anonymousUnprotected);
    },
  );

  test(
    'email binding verify links same remote user without changing local id',
    () async {
      final env = await _Env.create();
      addTearDown(env.close);
      final local = await env.identity.ensureLocalIdentity();
      final remote = await env.auth.signInAnonymously();
      await env.identity.linkRemoteIdentity(
        remoteUserId: remote.remoteUserId,
        provider: AuthProviderType.supabaseAnonymous,
      );

      final started = await env.service.startEmailBinding('user@example.com');
      final verified = await env.service.verifyEmailBinding(
        email: 'user@example.com',
        code: '123456',
      );

      expect(started.status, EmailBindingStartStatus.codeSent);
      expect(verified.status, EmailBindingVerifyStatus.bound);
      expect(verified.snapshot.status, AccountProtectionStatus.linkedProtected);
      final updated = await env.identity.getCurrentAppUser();
      expect(updated.id, local.id);
      expect(updated.remoteUserId, remote.remoteUserId);
      expect(updated.remoteProvider, AuthProviderType.email);
      expect(updated.identityKind, LocalUserIdentityKind.linked);
    },
  );

  test('email binding verify maps invalid and expired code safely', () async {
    final env = await _Env.create();
    addTearDown(env.close);
    final remote = await env.auth.signInAnonymously();
    await env.identity.linkRemoteIdentity(
      remoteUserId: remote.remoteUserId,
      provider: AuthProviderType.supabaseAnonymous,
    );
    await env.service.startEmailBinding('user@example.com');

    final invalid = await env.service.verifyEmailBinding(
      email: 'user@example.com',
      code: '000000',
    );
    final expired = await env.service.verifyEmailBinding(
      email: 'user@example.com',
      code: 'expired',
    );
    final updated = await env.identity.getCurrentAppUser();

    expect(invalid.status, EmailBindingVerifyStatus.invalidCode);
    expect(expired.status, EmailBindingVerifyStatus.expiredCode);
    expect(updated.identityKind, LocalUserIdentityKind.anonymousRemote);
    expect(updated.remoteProvider, AuthProviderType.supabaseAnonymous);
  });

  test('email binding fails closed when verified uid changes', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final identity = IdentityRepository(db.reminderDao);
    await identity.linkRemoteIdentity(
      remoteUserId: 'anonymous-remote-user',
      provider: AuthProviderType.supabaseAnonymous,
    );
    final service = AccountProtectionService(
      identityRepository: identity,
      authRepository: const _UidChangingEmailAuthRepository(),
    );

    final outcome = await service.verifyEmailBinding(
      email: 'user@example.com',
      code: '123456',
    );
    final updated = await identity.getCurrentAppUser();

    expect(outcome.status, EmailBindingVerifyStatus.uidChangedUnsafe);
    expect(updated.identityKind, LocalUserIdentityKind.anonymousRemote);
    expect(updated.remoteProvider, AuthProviderType.supabaseAnonymous);
  });
}

class _ThrowingCurrentAuthRepository implements AuthRepository {
  const _ThrowingCurrentAuthRepository();

  @override
  Future<RemoteIdentity?> getCurrentRemoteIdentity() {
    throw const RemoteAuthException(RemoteAuthFailureReason.unavailable);
  }

  @override
  Future<RemoteIdentity> signInAnonymously() {
    throw const RemoteAuthException(RemoteAuthFailureReason.unavailable);
  }

  @override
  Future<RemoteIdentity> linkWithApple() {
    throw const RemoteAuthException(RemoteAuthFailureReason.unsupported);
  }

  @override
  Future<RemoteIdentity> linkWithGoogle() {
    throw const RemoteAuthException(RemoteAuthFailureReason.unsupported);
  }

  @override
  Future<RemoteIdentity> linkWithEmail() {
    throw const RemoteAuthException(RemoteAuthFailureReason.unsupported);
  }

  @override
  Future<EmailBindingStartRemoteResult> startEmailBinding(String email) {
    throw const RemoteAuthException(RemoteAuthFailureReason.unsupported);
  }

  @override
  Future<RemoteIdentity> verifyEmailBinding({
    required String email,
    required String code,
  }) {
    throw const RemoteAuthException(RemoteAuthFailureReason.unsupported);
  }

  @override
  Future<void> signOut() async {}
}

class _ConfigMissingBindingAuthRepository implements AuthRepository {
  const _ConfigMissingBindingAuthRepository();

  @override
  Future<RemoteIdentity?> getCurrentRemoteIdentity() async => null;

  @override
  Future<RemoteIdentity> signInAnonymously() {
    throw const RemoteAuthException(RemoteAuthFailureReason.configMissing);
  }

  @override
  Future<RemoteIdentity> linkWithApple() {
    throw const RemoteAuthException(RemoteAuthFailureReason.configMissing);
  }

  @override
  Future<RemoteIdentity> linkWithGoogle() {
    throw const RemoteAuthException(RemoteAuthFailureReason.configMissing);
  }

  @override
  Future<RemoteIdentity> linkWithEmail() {
    throw const RemoteAuthException(RemoteAuthFailureReason.configMissing);
  }

  @override
  Future<EmailBindingStartRemoteResult> startEmailBinding(String email) {
    throw const RemoteAuthException(RemoteAuthFailureReason.configMissing);
  }

  @override
  Future<RemoteIdentity> verifyEmailBinding({
    required String email,
    required String code,
  }) {
    throw const RemoteAuthException(RemoteAuthFailureReason.configMissing);
  }

  @override
  Future<void> signOut() async {}
}

class _UidChangingEmailAuthRepository implements AuthRepository {
  const _UidChangingEmailAuthRepository();

  @override
  Future<RemoteIdentity?> getCurrentRemoteIdentity() async {
    return const RemoteIdentity(
      remoteUserId: 'anonymous-remote-user',
      provider: AuthProviderType.supabaseAnonymous,
      isAnonymous: true,
    );
  }

  @override
  Future<RemoteIdentity> signInAnonymously() {
    throw const RemoteAuthException(RemoteAuthFailureReason.unsupported);
  }

  @override
  Future<RemoteIdentity> linkWithApple() {
    throw const RemoteAuthException(RemoteAuthFailureReason.unsupported);
  }

  @override
  Future<RemoteIdentity> linkWithGoogle() {
    throw const RemoteAuthException(RemoteAuthFailureReason.unsupported);
  }

  @override
  Future<RemoteIdentity> linkWithEmail() {
    throw const RemoteAuthException(RemoteAuthFailureReason.unsupported);
  }

  @override
  Future<EmailBindingStartRemoteResult> startEmailBinding(String email) async {
    return EmailBindingStartRemoteResult(
      remoteUserId: 'anonymous-remote-user',
      email: email,
    );
  }

  @override
  Future<RemoteIdentity> verifyEmailBinding({
    required String email,
    required String code,
  }) async {
    return const RemoteIdentity(
      remoteUserId: 'different-remote-user',
      provider: AuthProviderType.email,
      isAnonymous: false,
    );
  }

  @override
  Future<void> signOut() async {}
}

class _Env {
  const _Env({
    required this.db,
    required this.identity,
    required this.auth,
    required this.service,
  });

  final AppDatabase db;
  final IdentityRepository identity;
  final FakeAuthRepository auth;
  final AccountProtectionService service;

  static Future<_Env> create() async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    final identity = IdentityRepository(db.reminderDao);
    final auth = FakeAuthRepository();
    final service = AccountProtectionService(
      identityRepository: identity,
      authRepository: auth,
    );
    await identity.ensureLocalIdentity();
    return _Env(db: db, identity: identity, auth: auth, service: service);
  }

  Future<void> close() => db.close();
}
