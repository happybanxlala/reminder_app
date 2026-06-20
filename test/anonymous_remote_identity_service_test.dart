import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reminder_app/features/reminders/data/anonymous_remote_identity_service.dart';
import 'package:reminder_app/features/reminders/data/auth_repository.dart';
import 'package:reminder_app/features/reminders/data/identity_repository.dart';
import 'package:reminder_app/features/reminders/data/item_repository.dart';
import 'package:reminder_app/features/reminders/data/local/app_database.dart';
import 'package:reminder_app/features/reminders/data/shared_pack_repository.dart';
import 'package:reminder_app/features/reminders/domain/item.dart';
import 'package:reminder_app/features/reminders/domain/item_pack.dart';
import 'package:reminder_app/features/reminders/domain/shared_pack.dart';

void main() {
  test(
    'missing Supabase config returns configMissing without crashing',
    () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);
      final identityRepository = IdentityRepository(db.reminderDao);
      final service = AnonymousRemoteIdentityService(
        identityRepository: identityRepository,
        authRepository: const DisabledAuthRepository(
          RemoteAuthFailureReason.configMissing,
        ),
      );

      final result = await service.ensureAnonymousRemoteIdentity();
      final localUser = await identityRepository.getCurrentAppUser();

      expect(result.status, AnonymousRemoteIdentityStatus.configMissing);
      expect(localUser.identityKind, LocalUserIdentityKind.local);
      expect(localUser.remoteUserId, isNull);
    },
  );

  test('successful anonymous auth links existing local user', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final identityRepository = IdentityRepository(db.reminderDao);
    final localUser = await identityRepository.ensureLocalIdentity();
    final authRepository = _CountingAuthRepository(
      remoteUserId: 'supabase-user-123',
    );
    final service = AnonymousRemoteIdentityService(
      identityRepository: identityRepository,
      authRepository: authRepository,
    );

    final result = await service.ensureAnonymousRemoteIdentity();

    expect(result.status, AnonymousRemoteIdentityStatus.success);
    expect(result.user?.id, localUser.id);
    expect(result.user?.remoteUserId, 'supabase-user-123');
    expect(result.user?.remoteProvider, AuthProviderType.supabaseAnonymous);
    expect(result.user?.identityKind, LocalUserIdentityKind.anonymousRemote);
    expect(result.user?.linkedAt, isNotNull);
    expect(authRepository.signInCalls, 1);
  });

  test('already linked user does not sign in again', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final identityRepository = IdentityRepository(db.reminderDao);
    final localUser = await identityRepository.linkRemoteIdentity(
      remoteUserId: 'existing-supabase-user',
      provider: AuthProviderType.supabaseAnonymous,
    );
    final authRepository = _CountingAuthRepository(remoteUserId: 'new-user');
    final service = AnonymousRemoteIdentityService(
      identityRepository: identityRepository,
      authRepository: authRepository,
    );

    final result = await service.ensureAnonymousRemoteIdentity();

    expect(result.status, AnonymousRemoteIdentityStatus.alreadyLinked);
    expect(result.user?.id, localUser.id);
    expect(result.user?.remoteUserId, 'existing-supabase-user');
    expect(authRepository.signInCalls, 0);
  });

  test('remote auth failure returns typed failure', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final identityRepository = IdentityRepository(db.reminderDao);
    final service = AnonymousRemoteIdentityService(
      identityRepository: identityRepository,
      authRepository: const _FailingAuthRepository(),
    );

    final result = await service.ensureAnonymousRemoteIdentity();

    expect(result.status, AnonymousRemoteIdentityStatus.remoteAuthFailed);
    expect((await identityRepository.getCurrentAppUser()).remoteUserId, isNull);
  });

  test('linking remote identity keeps shared local actor history', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final identityRepository = IdentityRepository(db.reminderDao);
    final localUser = await identityRepository.ensureLocalIdentity();
    Future<String> currentActor() async =>
        (await identityRepository.getCurrentAppUser()).id;
    final itemRepository = ItemRepository(
      db.reminderDao,
      currentActorId: currentActor,
    );
    final sharedRepository = SharedPackRepository(
      db.reminderDao,
      currentActorId: currentActor,
    );
    final packId = await itemRepository.createPack(
      const ItemPackInput(title: 'Shared remote identity'),
    );
    expect(await sharedRepository.convertPackToShared(packId), isTrue);
    final itemId = await itemRepository.createItem(
      ItemInput(
        title: 'Clean',
        type: ItemType.stateBased,
        config: const StateBasedItemConfig(
          warningAfter: Duration(days: 1),
          dangerAfter: Duration(days: 2),
        ),
        packId: packId,
      ),
    );
    expect(await itemRepository.markDone(itemId), isTrue);

    final service = AnonymousRemoteIdentityService(
      identityRepository: identityRepository,
      authRepository: _CountingAuthRepository(remoteUserId: 'remote-user'),
    );
    final result = await service.ensureAnonymousRemoteIdentity();

    expect(result.status, AnonymousRemoteIdentityStatus.success);
    expect(
      await db.reminderDao.getPackMember(packId: packId, userId: localUser.id),
      isNotNull,
    );
    final completions = await db.reminderDao.listItemCompletions(itemId);
    expect(completions.single.completedByUserId, localUser.id);
    final activity = await db.reminderDao.listActivityEventsForPack(packId);
    expect(
      activity.map((event) => event.actorUserId),
      everyElement(localUser.id),
    );
    expect(result.user?.remoteUserId, isNot(localUser.id));
  });

  test(
    'missing Supabase config does not block personal item completion',
    () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);
      final identityRepository = IdentityRepository(db.reminderDao);
      final service = AnonymousRemoteIdentityService(
        identityRepository: identityRepository,
        authRepository: const DisabledAuthRepository(
          RemoteAuthFailureReason.configMissing,
        ),
      );
      final itemRepository = ItemRepository(
        db.reminderDao,
        currentActorId: () async =>
            (await identityRepository.getCurrentAppUser()).id,
      );

      expect(
        (await service.ensureAnonymousRemoteIdentity()).status,
        AnonymousRemoteIdentityStatus.configMissing,
      );
      final itemId = await itemRepository.createItem(
        const ItemInput(
          title: 'Personal task',
          type: ItemType.stateBased,
          config: StateBasedItemConfig(
            warningAfter: Duration(days: 1),
            dangerAfter: Duration(days: 2),
          ),
        ),
      );

      expect(await itemRepository.markDone(itemId), isTrue);
    },
  );
}

class _CountingAuthRepository implements AuthRepository {
  _CountingAuthRepository({required this.remoteUserId});

  final String remoteUserId;
  int signInCalls = 0;

  @override
  Future<RemoteIdentity?> getCurrentRemoteIdentity() async => null;

  @override
  Future<RemoteIdentity> signInAnonymously() async {
    signInCalls++;
    return RemoteIdentity(
      remoteUserId: remoteUserId,
      provider: AuthProviderType.supabaseAnonymous,
      isAnonymous: true,
    );
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
  Future<void> signOut() async {}
}

class _FailingAuthRepository implements AuthRepository {
  const _FailingAuthRepository();

  @override
  Future<RemoteIdentity?> getCurrentRemoteIdentity() async => null;

  @override
  Future<RemoteIdentity> signInAnonymously() {
    throw const RemoteAuthException(RemoteAuthFailureReason.remoteAuthFailed);
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
  Future<void> signOut() async {}
}
