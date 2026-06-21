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
import 'package:reminder_app/features/reminders/domain/shared_pack.dart';

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
  bool rejectCompletion = false;
  bool malformedSnapshot = false;
  final createdItems = <_RemoteItemDraft>[];
  final _packs = <String, String>{};
  final _packItems = <String, List<String>>{};
  final _completions = <String, RemoteItemCompletionResult>{};

  @override
  Future<String> upsertCurrentProfile({required String displayName}) async {
    profileUpsertCount += 1;
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
}
