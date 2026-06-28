import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reminder_app/features/reminders/data/anonymous_remote_identity_service.dart';
import 'package:reminder_app/features/reminders/data/auth_repository.dart';
import 'package:reminder_app/features/reminders/data/identity_repository.dart';
import 'package:reminder_app/features/reminders/data/item_repository.dart';
import 'package:reminder_app/features/reminders/data/local/app_database.dart';
import 'package:reminder_app/features/reminders/data/remote_shared_pack_data_source.dart';
import 'package:reminder_app/features/reminders/data/remote_shared_pack_models.dart';
import 'package:reminder_app/features/reminders/data/remote_shared_pack_repository.dart';
import 'package:reminder_app/features/reminders/data/shared_pack_repository.dart';
import 'package:reminder_app/features/reminders/domain/item.dart';
import 'package:reminder_app/features/reminders/domain/item_pack.dart';
import 'package:reminder_app/features/reminders/domain/remote_pack_freshness.dart';
import 'package:reminder_app/features/reminders/domain/shared_pack.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  test(
    'ensureRemoteProfile links anonymous identity and upserts profile',
    () async {
      final harness = await _Harness.create();
      addTearDown(harness.close);

      final result = await harness.remoteRepository.ensureRemoteProfile();

      expect(result.isSuccess, isTrue);
      expect(result.value!.id, startsWith('fake_supabase_user_'));
      expect(harness.remoteDataSource.profileUpsertCount, 1);
      final user = await harness.identityRepository.getCurrentAppUser();
      expect(user.identityKind, LocalUserIdentityKind.anonymousRemote);
      expect(user.remoteProvider, AuthProviderType.supabaseAnonymous);
    },
  );

  test(
    'missing Supabase config returns typed failure without crashing',
    () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);
      final identityRepository = IdentityRepository(db.reminderDao);
      final repository = RemoteSharedPackRepository(
        dao: db.reminderDao,
        identityRepository: identityRepository,
        anonymousIdentityService: AnonymousRemoteIdentityService(
          identityRepository: identityRepository,
          authRepository: const DisabledAuthRepository(
            RemoteAuthFailureReason.configMissing,
          ),
        ),
        remoteDataSource: const DisabledRemoteSharedPackDataSource(
          RemoteSharedPackFailureReason.supabaseConfigMissing,
        ),
      );

      final result = await repository.ensureRemoteProfile();

      expect(result.isSuccess, isFalse);
      expect(
        result.failureReason,
        RemoteSharedPackFailureReason.supabaseConfigMissing,
      );
    },
  );

  test('profile bootstrap maps Supabase 42501 with safe RPC detail', () {
    final error = mapRemoteSharedPackError(
      const PostgrestException(
        message: 'permission denied for table profiles',
        code: '42501',
      ),
      RemoteSharedPackFailureReason.remoteProfileFailed,
      operationName: 'upsert_current_profile',
    );

    expect(error.reason, RemoteSharedPackFailureReason.remoteRlsRejected);
    expect(error.operationName, 'upsert_current_profile');
    expect(error.remoteCode, '42501');
    expect(
      error.safeDebugMessage,
      'upsert_current_profile 被 Supabase 拒絕：42501',
    );
  });

  test('shared pack bootstrap maps Supabase 42501 with safe RPC detail', () {
    final error = mapRemoteSharedPackError(
      const PostgrestException(
        message: 'permission denied for table packs',
        code: '42501',
      ),
      RemoteSharedPackFailureReason.remotePackCreateFailed,
      operationName: 'create_shared_pack',
    );

    expect(error.reason, RemoteSharedPackFailureReason.remoteRlsRejected);
    expect(error.operationName, 'create_shared_pack');
    expect(error.remoteCode, '42501');
    expect(error.safeDebugMessage, 'create_shared_pack 被 Supabase 拒絕：42501');
  });

  test('shared pack host creates remote pack mapping once', () async {
    final harness = await _Harness.create();
    addTearDown(harness.close);
    final packId = await harness.createSharedPackAsCurrentUser('Cats');

    final first = await harness.remoteRepository
        .createRemoteSharedPackFromLocalPack(packId);
    final second = await harness.remoteRepository
        .createRemoteSharedPackFromLocalPack(packId);

    expect(first.isSuccess, isTrue);
    expect(first.value!.alreadyLinked, isFalse);
    expect(second.isSuccess, isTrue);
    expect(second.value!.alreadyLinked, isTrue);
    expect(harness.remoteDataSource.createdPackCount, 1);
    final mappings = await harness.db.reminderDao.listSyncMappings();
    expect(mappings, hasLength(1));
    expect(mappings.single.localEntityType, 'pack');
    expect(mappings.single.remoteTable, 'packs');
    expect(mappings.single.localEntityId, packId);
    expect(mappings.single.remoteEntityId, first.value!.remotePackId);
  });

  test(
    'remote pack create rejects personal pack and non-member current user',
    () async {
      final harness = await _Harness.create();
      addTearDown(harness.close);
      final personalPackId = await harness.itemRepository.createPack(
        const ItemPackInput(title: 'Personal'),
      );

      final personalResult = await harness.remoteRepository
          .createRemoteSharedPackFromLocalPack(personalPackId);

      expect(personalResult.isSuccess, isFalse);
      expect(
        personalResult.failureReason,
        RemoteSharedPackFailureReason.localPackNotShared,
      );

      final defaultHostSharedPackId = await harness.itemRepository.createPack(
        const ItemPackInput(title: 'Default Host Pack'),
      );
      await SharedPackRepository(
        harness.db.reminderDao,
      ).convertPackToShared(defaultHostSharedPackId);

      final nonMemberResult = await harness.remoteRepository
          .createRemoteSharedPackFromLocalPack(defaultHostSharedPackId);

      expect(nonMemberResult.isSuccess, isFalse);
      expect(
        nonMemberResult.failureReason,
        RemoteSharedPackFailureReason.localUserNotPackMember,
      );
      expect(harness.remoteDataSource.createdPackCount, 0);
    },
  );

  test(
    'pushMinimalItems pushes only unmapped items in the mapped shared pack',
    () async {
      final harness = await _Harness.create();
      addTearDown(harness.close);
      final packId = await harness.createSharedPackAsCurrentUser('House');
      final otherPackId = await harness.itemRepository.createPack(
        const ItemPackInput(title: 'Other'),
      );
      final itemA = await harness.createStateItem(packId, 'Clean sink');
      final itemB = await harness.createStateItem(packId, 'Buy soap');
      await harness.createStateItem(otherPackId, 'Do not push');
      await harness.remoteRepository.createRemoteSharedPackFromLocalPack(
        packId,
      );

      var summary = await harness.remoteRepository.pushMinimalItems(packId);
      summary = await harness.remoteRepository.pushMinimalItems(packId);

      expect(summary.isSuccess, isTrue);
      expect(summary.value!.pushedCount, 0);
      expect(summary.value!.skippedCount, 2);
      expect(summary.value!.failedCount, 0);
      expect(harness.remoteDataSource.createdItems, hasLength(2));
      expect(
        harness.remoteDataSource.createdItems.map((row) => row.title),
        unorderedEquals(['Clean sink', 'Buy soap']),
      );
      final mappings = await harness.db.reminderDao.listSyncMappings();
      expect(
        mappings.where((mapping) => mapping.localEntityType == 'item'),
        hasLength(2),
      );
      expect(
        mappings
            .firstWhere((mapping) => mapping.localEntityId == itemA)
            .remoteEntityId,
        isNot(itemA.toString()),
      );
      expect(
        mappings
            .firstWhere((mapping) => mapping.localEntityId == itemB)
            .remoteEntityId,
        isNot(itemB.toString()),
      );
    },
  );

  test(
    'remote completion does not merge into local completion history',
    () async {
      final harness = await _Harness.create();
      addTearDown(harness.close);
      final packId = await harness.createSharedPackAsCurrentUser('Cats');
      final itemId = await harness.createStateItem(packId, 'Refill food');
      await harness.remoteRepository.createRemoteSharedPackFromLocalPack(
        packId,
      );
      await harness.remoteRepository.pushMinimalItems(packId);

      final completed = await harness.remoteRepository
          .completeRemoteItemForLocalItem(itemId);
      final alreadyCompleted = await harness.remoteRepository
          .completeRemoteItemForLocalItem(itemId);

      expect(completed.isSuccess, isTrue);
      expect(completed.value!.status, RemoteItemCompletionStatus.completed);
      expect(alreadyCompleted.isSuccess, isFalse);
      expect(
        alreadyCompleted.failureReason,
        RemoteSharedPackFailureReason.remoteItemAlreadyCompleted,
      );
      expect(await harness.db.reminderDao.listItemCompletions(itemId), isEmpty);

      final localUser = await harness.identityRepository.getCurrentAppUser();
      await harness.itemRepository.markDone(
        itemId,
        doneAt: DateTime(2026, 6, 21),
        actorUserId: localUser.id,
      );
      final localCompletions = await harness.db.reminderDao.listItemCompletions(
        itemId,
      );
      expect(localCompletions, hasLength(1));
      expect(localCompletions.single.completedByUserId, localUser.id);
    },
  );

  test('remote completion maps RLS rejection to typed failure', () async {
    final harness = await _Harness.create();
    addTearDown(harness.close);
    final packId = await harness.createSharedPackAsCurrentUser('Cats');
    final itemId = await harness.createStateItem(packId, 'Clean bowl');
    await harness.remoteRepository.createRemoteSharedPackFromLocalPack(packId);
    await harness.remoteRepository.pushMinimalItems(packId);
    harness.remoteDataSource.rejectCompletion = true;

    final result = await harness.remoteRepository
        .completeRemoteItemForLocalItem(itemId);

    expect(result.isSuccess, isFalse);
    expect(
      result.failureReason,
      RemoteSharedPackFailureReason.remoteRlsRejected,
    );
  });

  test(
    'pullRemotePackSnapshot parses remote data without writing local DB',
    () async {
      final harness = await _Harness.create();
      addTearDown(harness.close);
      final packId = await harness.createSharedPackAsCurrentUser('Cats');
      final itemId = await harness.createStateItem(packId, 'Clean bowl');
      final link = await harness.remoteRepository
          .createRemoteSharedPackFromLocalPack(packId);
      await harness.remoteRepository.pushMinimalItems(packId);
      await harness.remoteRepository.completeRemoteItemForLocalItem(itemId);

      final result = await harness.remoteRepository.pullRemotePackSnapshot(
        link.value!.remotePackId,
      );

      expect(result.isSuccess, isTrue);
      expect(result.value!.members, hasLength(1));
      expect(result.value!.items, hasLength(1));
      expect(result.value!.completions, hasLength(1));
      expect(result.value!.activityEvents, isNotEmpty);
      final localItems = await harness.itemRepository
          .watchPackManagementItems()
          .first;
      expect(
        localItems.where((bundle) => bundle.item.packId == packId),
        hasLength(1),
      );
    },
  );

  test(
    'reportPackSnapshotImported maps active member report success',
    () async {
      final harness = await _Harness.create();
      addTearDown(harness.close);

      final result = await harness.remoteRepository.reportPackSnapshotImported(
        remotePackId: 'remote_pack_1',
        latestActivityEventId: 'event_1',
        latestActivityAt: DateTime(2026, 6, 21, 12),
      );

      expect(result.succeeded, isTrue);
      expect(harness.remoteDataSource.reportedPackIds, ['remote_pack_1']);
      expect(harness.remoteDataSource.reportedActivityIds, ['event_1']);
    },
  );

  test('reportPackSnapshotImported maps RLS rejection safely', () async {
    final harness = await _Harness.create();
    addTearDown(harness.close);
    harness.remoteDataSource.rejectSnapshotReport = true;

    final result = await harness.remoteRepository.reportPackSnapshotImported(
      remotePackId: 'remote_pack_1',
    );

    expect(result.succeeded, isFalse);
    expect(result.status, RemotePackSnapshotReportStatus.accessDenied);
    expect(result.message, 'accessDenied');
  });

  test('getPackMemberFreshness maps remote freshness rows', () async {
    final harness = await _Harness.create();
    addTearDown(harness.close);
    harness.remoteDataSource.freshnessRows = [
      RemotePackMemberFreshness(
        remoteUserId: 'remote_user_1',
        displayName: 'Ada',
        role: 'host',
        memberStatus: 'active',
        status: RemotePackFreshnessStatus.upToDate,
        lastImportedAt: DateTime(2026, 6, 21, 12),
      ),
      const RemotePackMemberFreshness(
        remoteUserId: 'remote_user_2',
        displayName: 'Ben',
        role: 'member',
        memberStatus: 'active',
        status: RemotePackFreshnessStatus.possiblyStale,
      ),
      const RemotePackMemberFreshness(
        remoteUserId: 'remote_user_3',
        displayName: 'Cy',
        role: 'member',
        memberStatus: 'active',
        status: RemotePackFreshnessStatus.noSyncReport,
      ),
      const RemotePackMemberFreshness(
        remoteUserId: 'remote_user_4',
        displayName: 'Dee',
        role: 'member',
        memberStatus: 'active',
        status: RemotePackFreshnessStatus.accessUnknown,
      ),
    ];

    final result = await harness.remoteRepository.getPackMemberFreshness(
      remotePackId: 'remote_pack_1',
    );

    expect(result.succeeded, isTrue);
    expect(result.members, hasLength(4));
    expect(
      result.members.map((member) => member.status),
      containsAll(RemotePackFreshnessStatus.values),
    );
  });

  test('malformed remote snapshot returns typed failure', () async {
    final harness = await _Harness.create();
    addTearDown(harness.close);
    harness.remoteDataSource.malformedSnapshot = true;

    final result = await harness.remoteRepository.pullRemotePackSnapshot(
      'remote_pack_missing',
    );

    expect(result.isSuccess, isFalse);
    expect(
      result.failureReason,
      RemoteSharedPackFailureReason.malformedRemoteData,
    );
  });

  test(
    'createRemotePackInvite returns invite without local persistence',
    () async {
      final harness = await _Harness.create();
      addTearDown(harness.close);
      final packId = await harness.createSharedPackAsCurrentUser('Cats');
      final link = await harness.remoteRepository
          .createRemoteSharedPackFromLocalPack(packId);

      final result = await harness.remoteRepository.createRemotePackInvite(
        link.value!.remotePackId,
      );

      expect(result.isSuccess, isTrue);
      expect(result.value!.inviteId, 'invite_1');
      expect(result.value!.inviteCode, 'K7M4Q9');
      expect(result.value!.maxUses, 10);
      expect(harness.remoteDataSource.createdInviteCount, 1);
      expect(await harness.db.reminderDao.listSyncMappings(), hasLength(1));
    },
  );

  test('ensureActiveInviteForPack reuses active invite', () async {
    final harness = await _Harness.create();
    addTearDown(harness.close);

    final first = await harness.remoteRepository.ensureActiveInviteForPack(
      'remote_pack_1',
    );
    final second = await harness.remoteRepository.ensureActiveInviteForPack(
      'remote_pack_1',
    );

    expect(first.isSuccess, isTrue);
    expect(first.value!.inviteCode, hasLength(6));
    expect(
      first.value!.inviteCode,
      matches(r'^[ABCDEFGHJKLMNPQRSTUVWXYZ23456789]{6}$'),
    );
    expect(second.value!.inviteId, first.value!.inviteId);
    expect(harness.remoteDataSource.createdInviteCount, 1);
  });

  test('refreshInviteForPack replaces active invite', () async {
    final harness = await _Harness.create();
    addTearDown(harness.close);

    final first = await harness.remoteRepository.ensureActiveInviteForPack(
      'remote_pack_1',
    );
    final refreshed = await harness.remoteRepository.refreshInviteForPack(
      'remote_pack_1',
    );

    expect(refreshed.isSuccess, isTrue);
    expect(refreshed.value!.inviteCode, isNot(first.value!.inviteCode));
    expect(harness.remoteDataSource.revokedInviteIds, [first.value!.inviteId]);
    expect(harness.remoteDataSource.createdInviteCount, 2);
  });

  test('createRemotePackInvite maps host/RLS failures', () async {
    final harness = await _Harness.create();
    addTearDown(harness.close);
    harness.remoteDataSource.rejectInviteCreate = true;

    final result = await harness.remoteRepository.createRemotePackInvite(
      'remote_pack_1',
    );

    expect(result.isSuccess, isFalse);
    expect(
      result.failureReason,
      RemoteSharedPackFailureReason.remoteInviteNotHost,
    );
  });

  test(
    'joinRemotePackWithInvite joins without local pack or mapping',
    () async {
      final harness = await _Harness.create();
      addTearDown(harness.close);

      final result = await harness.remoteRepository.joinRemotePackWithInvite(
        'K7M4Q9',
      );
      harness.remoteDataSource.alreadyMemberOnJoin = true;
      final alreadyMember = await harness.remoteRepository
          .joinRemotePackWithInvite('K7M4Q9');

      expect(result.isSuccess, isTrue);
      expect(result.value!.status, RemoteJoinPackStatus.joined);
      expect(result.value!.remotePackId, 'joined_remote_pack');
      expect(alreadyMember.isSuccess, isTrue);
      expect(alreadyMember.value!.status, RemoteJoinPackStatus.alreadyMember);
      expect(harness.remoteDataSource.joinInviteCount, 2);
      expect(await harness.db.reminderDao.listSyncMappings(), isEmpty);
      final packs = await harness.db.reminderDao.listItemPacks();
      expect(
        packs.where((pack) => pack.title == 'joined_remote_pack'),
        isEmpty,
      );
    },
  );

  test('joinRemotePackWithInvite maps invite failures', () async {
    final harness = await _Harness.create();
    addTearDown(harness.close);

    harness.remoteDataSource.joinFailure =
        RemoteSharedPackFailureReason.remoteInviteInvalid;
    var result = await harness.remoteRepository.joinRemotePackWithInvite('bad');
    expect(
      result.failureReason,
      RemoteSharedPackFailureReason.remoteInviteInvalid,
    );

    harness.remoteDataSource.joinFailure =
        RemoteSharedPackFailureReason.remoteInviteExpired;
    result = await harness.remoteRepository.joinRemotePackWithInvite('old');
    expect(
      result.failureReason,
      RemoteSharedPackFailureReason.remoteInviteExpired,
    );

    harness.remoteDataSource.joinFailure =
        RemoteSharedPackFailureReason.remoteInviteMaxUsesReached;
    result = await harness.remoteRepository.joinRemotePackWithInvite('full');
    expect(
      result.failureReason,
      RemoteSharedPackFailureReason.remoteInviteMaxUsesReached,
    );
  });

  test('revokeRemotePackInvite returns revoked and already revoked', () async {
    final harness = await _Harness.create();
    addTearDown(harness.close);

    final revoked = await harness.remoteRepository.revokeRemotePackInvite(
      'invite_1',
    );
    harness.remoteDataSource.alreadyRevoked = true;
    final alreadyRevoked = await harness.remoteRepository
        .revokeRemotePackInvite('invite_1');

    expect(revoked.isSuccess, isTrue);
    expect(revoked.value!.status, RemoteRevokeInviteStatus.revoked);
    expect(alreadyRevoked.isSuccess, isTrue);
    expect(
      alreadyRevoked.value!.status,
      RemoteRevokeInviteStatus.alreadyRevoked,
    );
  });

  test(
    'completeRemoteItemByRemoteId works without local mapping or history merge',
    () async {
      final harness = await _Harness.create();
      addTearDown(harness.close);
      final packId = await harness.createSharedPackAsCurrentUser('Cats');
      final itemId = await harness.createStateItem(packId, 'Clean bowl');

      final completed = await harness.remoteRepository
          .completeRemoteItemByRemoteId('remote_snapshot_item_1');
      final alreadyCompleted = await harness.remoteRepository
          .completeRemoteItemByRemoteId('remote_snapshot_item_1');

      expect(completed.isSuccess, isTrue);
      expect(completed.value!.status, RemoteItemCompletionStatus.completed);
      expect(alreadyCompleted.isSuccess, isFalse);
      expect(
        alreadyCompleted.failureReason,
        RemoteSharedPackFailureReason.remoteItemAlreadyCompleted,
      );
      expect(await harness.db.reminderDao.listSyncMappings(), isEmpty);
      expect(await harness.db.reminderDao.listItemCompletions(itemId), isEmpty);
    },
  );

  test(
    'undoRemoteItemByRemoteId works without local mapping or history merge',
    () async {
      final harness = await _Harness.create();
      addTearDown(harness.close);
      final packId = await harness.createSharedPackAsCurrentUser('Cats');
      final itemId = await harness.createStateItem(packId, 'Clean bowl');

      await harness.remoteRepository.completeRemoteItemByRemoteId(
        'remote_snapshot_item_1',
      );
      final undone = await harness.remoteRepository.undoRemoteItemByRemoteId(
        'remote_snapshot_item_1',
      );
      final alreadyNotCompleted = await harness.remoteRepository
          .undoRemoteItemByRemoteId('remote_snapshot_item_1');

      expect(undone.isSuccess, isTrue);
      expect(undone.value!.status, RemoteItemUndoStatus.undone);
      expect(alreadyNotCompleted.isSuccess, isTrue);
      expect(
        alreadyNotCompleted.value!.status,
        RemoteItemUndoStatus.alreadyNotCompleted,
      );
      expect(harness.remoteDataSource.undoCount, 2);
      expect(await harness.db.reminderDao.listSyncMappings(), isEmpty);
      expect(await harness.db.reminderDao.listItemCompletions(itemId), isEmpty);
    },
  );

  test('remote undo maps RLS rejection to typed failure', () async {
    final harness = await _Harness.create();
    addTearDown(harness.close);
    harness.remoteDataSource.rejectUndo = true;

    final result = await harness.remoteRepository.undoRemoteItemByRemoteId(
      'remote_snapshot_item_1',
    );

    expect(result.isSuccess, isFalse);
    expect(
      result.failureReason,
      RemoteSharedPackFailureReason.remoteRlsRejected,
    );
  });

  test('PostgREST RPC errors map to typed remote failures', () {
    expect(
      mapRemoteSharedPackError(
        const PostgrestException(message: 'auth required'),
        RemoteSharedPackFailureReason.remoteUnknownFailure,
      ).reason,
      RemoteSharedPackFailureReason.remoteAuthRequired,
    );
    expect(
      mapRemoteSharedPackError(
        const PostgrestException(message: 'profile required'),
        RemoteSharedPackFailureReason.remoteUnknownFailure,
      ).reason,
      RemoteSharedPackFailureReason.remoteProfileFailed,
    );
    expect(
      mapRemoteSharedPackError(
        const PostgrestException(message: 'active pack member required'),
        RemoteSharedPackFailureReason.remoteUnknownFailure,
      ).reason,
      RemoteSharedPackFailureReason.remoteRlsRejected,
    );
    expect(
      mapRemoteSharedPackError(
        const PostgrestException(message: 'invite invalid'),
        RemoteSharedPackFailureReason.remoteUnknownFailure,
      ).reason,
      RemoteSharedPackFailureReason.remoteInviteInvalid,
    );
    expect(
      mapRemoteSharedPackError(
        const PostgrestException(message: 'invite expired'),
        RemoteSharedPackFailureReason.remoteUnknownFailure,
      ).reason,
      RemoteSharedPackFailureReason.remoteInviteExpired,
    );
    expect(
      mapRemoteSharedPackError(
        const PostgrestException(message: 'invite max uses reached'),
        RemoteSharedPackFailureReason.remoteUnknownFailure,
      ).reason,
      RemoteSharedPackFailureReason.remoteInviteMaxUsesReached,
    );
    expect(
      mapRemoteSharedPackError(
        const PostgrestException(message: 'pack host required'),
        RemoteSharedPackFailureReason.remoteUnknownFailure,
      ).reason,
      RemoteSharedPackFailureReason.remoteInviteNotHost,
    );
    expect(
      mapRemoteSharedPackError(
        const PostgrestException(message: 'permission denied', code: '42501'),
        RemoteSharedPackFailureReason.remoteUnknownFailure,
      ).reason,
      RemoteSharedPackFailureReason.remoteRlsRejected,
    );
    expect(
      mapRemoteSharedPackError(
        const PostgrestException(message: 'unexpected remote failure'),
        RemoteSharedPackFailureReason.remoteUnknownFailure,
      ).reason,
      RemoteSharedPackFailureReason.remoteUnknownFailure,
    );
  });
}

class _Harness {
  const _Harness({
    required this.db,
    required this.identityRepository,
    required this.itemRepository,
    required this.remoteRepository,
    required this.remoteDataSource,
  });

  final AppDatabase db;
  final IdentityRepository identityRepository;
  final ItemRepository itemRepository;
  final RemoteSharedPackRepository remoteRepository;
  final _FakeRemoteSharedPackDataSource remoteDataSource;

  static Future<_Harness> create() async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    final identityRepository = IdentityRepository(db.reminderDao);
    await identityRepository.ensureLocalIdentity();
    final itemRepository = ItemRepository(db.reminderDao);
    final remoteDataSource = _FakeRemoteSharedPackDataSource();
    final remoteRepository = RemoteSharedPackRepository(
      dao: db.reminderDao,
      identityRepository: identityRepository,
      anonymousIdentityService: AnonymousRemoteIdentityService(
        identityRepository: identityRepository,
        authRepository: FakeAuthRepository(),
      ),
      remoteDataSource: remoteDataSource,
      clock: () => DateTime(2026, 6, 21, 10),
    );
    return _Harness(
      db: db,
      identityRepository: identityRepository,
      itemRepository: itemRepository,
      remoteRepository: remoteRepository,
      remoteDataSource: remoteDataSource,
    );
  }

  Future<void> close() => db.close();

  Future<int> createSharedPackAsCurrentUser(String title) async {
    final user = await identityRepository.getCurrentAppUser();
    final packId = await itemRepository.createPack(ItemPackInput(title: title));
    final sharedRepository = SharedPackRepository(
      db.reminderDao,
      currentActorId: () async => user.id,
    );
    expect(await sharedRepository.convertPackToShared(packId), isTrue);
    return packId;
  }

  Future<int> createStateItem(int packId, String title) {
    return itemRepository.createItem(
      ItemInput(
        title: title,
        type: ItemType.stateBased,
        config: const StateBasedItemConfig(
          warningAfter: Duration(days: 1),
          dangerAfter: Duration(days: 2),
        ),
        packId: packId,
      ),
    );
  }
}

class _RemoteItemDraft {
  const _RemoteItemDraft({required this.id, required this.title});

  final String id;
  final String title;
}

class _FakeRemoteSharedPackDataSource implements RemoteSharedPackDataSource {
  int profileUpsertCount = 0;
  int createdPackCount = 0;
  int createdInviteCount = 0;
  int joinInviteCount = 0;
  int undoCount = 0;
  final revokedInviteIds = <String>[];
  bool rejectCompletion = false;
  bool rejectUndo = false;
  bool malformedSnapshot = false;
  bool rejectInviteCreate = false;
  bool rejectProfileUpsert = false;
  bool rejectSnapshotReport = false;
  bool alreadyMemberOnJoin = false;
  bool alreadyRevoked = false;
  RemoteSharedPackFailureReason? joinFailure;
  List<RemotePackMemberFreshness> freshnessRows = const [];
  final reportedPackIds = <String>[];
  final reportedActivityIds = <String?>[];
  final createdItems = <_RemoteItemDraft>[];
  final _packs = <String, String>{};
  final _packItems = <String, List<String>>{};
  final _completions = <String, RemoteItemCompletionResult>{};
  final _activeInvites = <String, RemotePackInvite>{};

  @override
  Future<String> upsertCurrentProfile({required String displayName}) async {
    profileUpsertCount += 1;
    if (rejectProfileUpsert) {
      throw const RemoteSharedPackException(
        RemoteSharedPackFailureReason.remoteRlsRejected,
        null,
        'upsert_current_profile',
        '42501',
      );
    }
    return 'fake_supabase_user_profile';
  }

  @override
  Future<String> createSharedPack({
    required String name,
    String? description,
  }) async {
    createdPackCount += 1;
    final id = 'remote_pack_$createdPackCount';
    _packs[id] = name;
    _packItems[id] = <String>[];
    return id;
  }

  @override
  Future<RemotePackInvite> createPackInvite({required String packId}) async {
    return ensureActivePackInvite(packId: packId);
  }

  @override
  Future<RemotePackInviteState> fetchPackInviteState({
    required String packId,
  }) async {
    return RemotePackInviteState(activeInvite: _activeInvites[packId]);
  }

  @override
  Future<RemotePackInvite> ensureActivePackInvite({
    required String packId,
  }) async {
    if (rejectInviteCreate) {
      throw const RemoteSharedPackException(
        RemoteSharedPackFailureReason.remoteInviteNotHost,
      );
    }
    final existing = _activeInvites[packId];
    if (existing != null) {
      return existing;
    }
    createdInviteCount += 1;
    final invite = RemotePackInvite(
      inviteId: 'invite_$createdInviteCount',
      inviteCode: createdInviteCount == 1 ? 'K7M4Q9' : 'P8W6RA',
      expiresAt: DateTime(2026, 6, 28, 10),
      maxUses: 10,
    );
    _activeInvites[packId] = invite;
    return invite;
  }

  @override
  Future<RemotePackInvite> refreshPackInvite({required String packId}) async {
    final existing = _activeInvites.remove(packId);
    if (existing != null) {
      revokedInviteIds.add(existing.inviteId);
    }
    return ensureActivePackInvite(packId: packId);
  }

  @override
  Future<RemoteJoinPackResult> joinPackWithInvite({
    required String inviteCode,
  }) async {
    joinInviteCount += 1;
    final failure = joinFailure;
    if (failure != null) {
      throw RemoteSharedPackException(failure);
    }
    return RemoteJoinPackResult(
      status: alreadyMemberOnJoin
          ? RemoteJoinPackStatus.alreadyMember
          : RemoteJoinPackStatus.joined,
      remotePackId: 'joined_remote_pack',
      memberId: 'joined_member_1',
      role: 'member',
    );
  }

  @override
  Future<List<RemoteRecoverablePack>> fetchActiveMembershipPacks() async {
    return [
      RemoteRecoverablePack(
        remotePackId: 'joined_remote_pack',
        name: 'Joined pack',
        role: 'member',
        memberStatus: 'active',
        packStatus: 'active',
        hostUserId: 'fake_supabase_user_profile',
        updatedAt: DateTime(2026, 6, 21, 10),
      ),
    ];
  }

  @override
  Future<RemoteRevokeInviteResult> revokePackInvite({
    required String inviteId,
  }) async {
    return RemoteRevokeInviteResult(
      status: alreadyRevoked
          ? RemoteRevokeInviteStatus.alreadyRevoked
          : RemoteRevokeInviteStatus.revoked,
      inviteId: inviteId,
    );
  }

  @override
  Future<String> createPackItem({
    required String packId,
    required String title,
    String? note,
  }) async {
    final id = 'remote_item_${createdItems.length + 1}';
    createdItems.add(_RemoteItemDraft(id: id, title: title));
    _packItems.putIfAbsent(packId, () => <String>[]).add(id);
    return id;
  }

  @override
  Future<RemoteItemCreateResult> createPackItemV2({
    required String packId,
    required String title,
    String? note,
    String? clientMutationId,
  }) async {
    return RemoteItemCreateResult(
      itemId: await createPackItem(packId: packId, title: title, note: note),
    );
  }

  @override
  Future<RemoteItemMutationResult> updatePackItem({
    required String itemId,
    required String title,
    String? note,
    String? assignedToUserId,
    String? clientMutationId,
  }) async {
    return RemoteItemMutationResult(itemId: itemId, status: 'updated');
  }

  @override
  Future<RemoteItemMutationResult> archivePackItem({
    required String itemId,
    String? clientMutationId,
  }) async {
    return RemoteItemMutationResult(itemId: itemId, status: 'archived');
  }

  @override
  Future<RemoteItemCompletionResult> completePackItem({
    required String itemId,
    String? clientMutationId,
  }) async {
    if (rejectCompletion) {
      throw const RemoteSharedPackException(
        RemoteSharedPackFailureReason.remoteRlsRejected,
      );
    }
    final existing = _completions[itemId];
    if (existing != null) {
      return RemoteItemCompletionResult(
        status: RemoteItemCompletionStatus.alreadyCompleted,
        completionId: existing.completionId,
        completedByUserId: existing.completedByUserId,
        completedAt: existing.completedAt,
      );
    }
    final completion = RemoteItemCompletionResult(
      status: RemoteItemCompletionStatus.completed,
      completionId: 'remote_completion_${_completions.length + 1}',
      completedByUserId: 'fake_supabase_user_profile',
      completedAt: DateTime(2026, 6, 21, 10),
    );
    _completions[itemId] = completion;
    return completion;
  }

  @override
  Future<RemoteItemUndoResult> undoPackItemCompletion({
    required String itemId,
    String? clientMutationId,
  }) async {
    undoCount += 1;
    if (rejectUndo) {
      throw const RemoteSharedPackException(
        RemoteSharedPackFailureReason.remoteRlsRejected,
      );
    }
    final existing = _completions.remove(itemId);
    if (existing == null) {
      return RemoteItemUndoResult(
        status: RemoteItemUndoStatus.alreadyNotCompleted,
        itemId: itemId,
      );
    }
    return RemoteItemUndoResult(
      status: RemoteItemUndoStatus.undone,
      completionId: existing.completionId,
      itemId: itemId,
      undoneByUserId: 'fake_supabase_user_profile',
      undoneAt: DateTime(2026, 6, 21, 10, 5),
    );
  }

  @override
  Future<RemotePackSnapshot> fetchPackSnapshot(String remotePackId) async {
    if (malformedSnapshot) {
      throw const RemoteSharedPackException(
        RemoteSharedPackFailureReason.malformedRemoteData,
      );
    }
    final itemIds = _packItems[remotePackId] ?? const <String>[];
    return RemotePackSnapshot(
      id: remotePackId,
      name: _packs[remotePackId] ?? 'Remote Pack',
      hostUserId: 'fake_supabase_user_profile',
      status: 'active',
      createdAt: DateTime(2026, 6, 21),
      updatedAt: DateTime(2026, 6, 21),
      members: [
        RemotePackMemberSnapshot(
          id: 'remote_member_1',
          packId: remotePackId,
          userId: 'fake_supabase_user_profile',
          role: 'host',
          status: 'active',
          joinedAt: DateTime(2026, 6, 21),
        ),
      ],
      items: [
        for (final itemId in itemIds)
          RemoteItemSnapshot(
            id: itemId,
            packId: remotePackId,
            title: createdItems.firstWhere((item) => item.id == itemId).title,
            status: 'active',
            createdByUserId: 'fake_supabase_user_profile',
            updatedByUserId: 'fake_supabase_user_profile',
            createdAt: DateTime(2026, 6, 21),
            updatedAt: DateTime(2026, 6, 21),
          ),
      ],
      completions: [
        for (final entry in _completions.entries)
          if (itemIds.contains(entry.key))
            RemoteItemCompletionSnapshot(
              id: entry.value.completionId,
              packId: remotePackId,
              itemId: entry.key,
              completedByUserId: entry.value.completedByUserId,
              completedAt: entry.value.completedAt,
              createdAt: entry.value.completedAt,
            ),
      ],
      activityEvents: [
        RemoteActivityEventSnapshot(
          id: 'remote_activity_1',
          packId: remotePackId,
          actorUserId: 'fake_supabase_user_profile',
          entityType: 'pack',
          entityId: remotePackId,
          action: 'pack_created',
          createdAt: DateTime(2026, 6, 21),
        ),
      ],
    );
  }

  @override
  Future<void> reportPackSnapshotImported({
    required String remotePackId,
    String? latestActivityEventId,
    DateTime? latestActivityAt,
  }) async {
    if (rejectSnapshotReport) {
      throw const RemoteSharedPackException(
        RemoteSharedPackFailureReason.remoteRlsRejected,
      );
    }
    reportedPackIds.add(remotePackId);
    reportedActivityIds.add(latestActivityEventId);
  }

  @override
  Future<List<RemotePackMemberFreshness>> getPackMemberFreshness({
    required String remotePackId,
  }) async {
    return freshnessRows;
  }
}
