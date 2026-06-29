import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reminder_app/features/reminders/data/identity_repository.dart';
import 'package:reminder_app/features/reminders/data/item_repository.dart';
import 'package:reminder_app/features/reminders/data/local/app_database.dart';
import 'package:reminder_app/features/reminders/data/remote_backed_item_action_service.dart';
import 'package:reminder_app/features/reminders/data/remote_backed_outbox_flush_service.dart';
import 'package:reminder_app/features/reminders/data/remote_backed_pack_refresh_service.dart';
import 'package:reminder_app/features/reminders/data/remote_shared_pack_models.dart';
import 'package:reminder_app/features/reminders/data/remote_snapshot_import_service.dart';
import 'package:reminder_app/features/reminders/domain/item.dart';
import 'package:reminder_app/features/reminders/domain/item_action_record.dart';
import 'package:reminder_app/features/reminders/domain/remote_sync.dart';
import 'package:reminder_app/features/reminders/domain/shared_pack.dart';
import 'package:reminder_app/features/reminders/providers/remote_backed_sync_coordinator.dart';

void main() {
  test(
    'coordinator flushes remote-backed create item after local save',
    () async {
      final env = await _SyncEnv.create();
      addTearDown(env.close);
      final newItemId = await env.itemRepository.createItem(
        ItemInput(
          title: 'New shared item',
          description: 'Created locally first',
          type: ItemType.stateBased,
          config: _stateConfig(),
          packId: env.localPackId,
        ),
      );

      final pending = await env.db.reminderDao.listPendingSyncOutboxEntries();
      expect(pending.single.actionType, SyncOutboxActionType.createItem);
      expect(await env.itemRepository.getItemById(newItemId), isNotNull);

      env.remoteClient.createResult = const RemotePocResult.success(
        RemoteItemCreateResult(itemId: 'remote-created-item'),
      );
      final result = await env.coordinator.syncAfterRemoteBackedMutation(
        env.localPackId,
      );

      expect(result.status, RemoteBackedSyncStatus.synced);
      expect(env.remoteClient.createCalls, 1);
      final outbox = await env.db.reminderDao.listSyncOutboxEntries();
      expect(outbox.single.status, SyncOutboxStatus.synced);
      final metadata = await env.db.reminderDao
          .getRemoteItemSyncMetadataForRemoteItem('remote-created-item');
      expect(metadata!.localItemId, newItemId);
    },
  );

  test(
    'coordinator flushes remote-backed update item after local save',
    () async {
      final env = await _SyncEnv.create();
      addTearDown(env.close);
      final existing = (await env.itemRepository.getItemById(env.localItemId))!;
      final updated = await env.itemRepository.updateItem(
        env.localItemId,
        ItemInput(
          title: 'Updated shared item',
          description: 'Updated note',
          type: existing.item.type,
          config: existing.item.config,
          packId: env.localPackId,
        ),
      );

      expect(updated, isTrue);
      final pending = await env.db.reminderDao.listPendingSyncOutboxEntries();
      expect(pending.single.actionType, SyncOutboxActionType.updateItem);

      env.remoteClient.updateResult = const RemotePocResult.success(
        RemoteItemMutationResult(itemId: 'remote-item-1', status: 'updated'),
      );
      final result = await env.coordinator.syncAfterRemoteBackedMutation(
        env.localPackId,
      );

      expect(result.status, RemoteBackedSyncStatus.synced);
      expect(env.remoteClient.updateCalls, 1);
      final outbox = await env.db.reminderDao.listSyncOutboxEntries();
      expect(outbox.single.status, SyncOutboxStatus.synced);
    },
  );

  test(
    'coordinator flushes remote-backed archive item after local save',
    () async {
      final env = await _SyncEnv.create();
      addTearDown(env.close);
      final archived = await env.itemRepository.archiveItem(env.localItemId);

      expect(archived, isTrue);
      final pending = await env.db.reminderDao.listPendingSyncOutboxEntries();
      expect(pending.single.actionType, SyncOutboxActionType.archiveItem);

      env.remoteClient.archiveResult = const RemotePocResult.success(
        RemoteItemMutationResult(itemId: 'remote-item-1', status: 'archived'),
      );
      final result = await env.coordinator.syncAfterRemoteBackedMutation(
        env.localPackId,
      );

      expect(result.status, RemoteBackedSyncStatus.synced);
      expect(env.remoteClient.archiveCalls, 1);
      final outbox = await env.db.reminderDao.listSyncOutboxEntries();
      expect(outbox.single.status, SyncOutboxStatus.synced);
    },
  );

  test(
    'coordinator flushes remote-backed complete item after local action',
    () async {
      final env = await _SyncEnv.create();
      addTearDown(env.close);
      final completed = await env.itemRepository.markDone(
        env.localItemId,
        doneAt: DateTime(2026, 6, 22, 9),
      );

      expect(completed, isTrue);
      final pending = await env.db.reminderDao.listPendingSyncOutboxEntries();
      expect(pending.single.actionType, SyncOutboxActionType.completeItem);
      final actions = await env.db.reminderDao.listItemActionRecordsForItem(
        env.localItemId,
      );
      expect(actions.single.actionType, ItemActionType.done);

      env.remoteClient.completeResult = RemotePocResult.success(
        RemoteItemCompletionResult(
          status: RemoteItemCompletionStatus.completed,
          completionId: 'remote-completion-new',
          completedByUserId: 'remote-user-current',
          completedAt: DateTime(2026, 6, 22, 9),
        ),
      );
      final result = await env.coordinator.syncAfterRemoteBackedMutation(
        env.localPackId,
      );

      expect(result.status, RemoteBackedSyncStatus.synced);
      expect(env.remoteClient.completeCalls, 1);
    },
  );

  test(
    'coordinator flushes remote-backed undo item after local action',
    () async {
      final env = await _SyncEnv.create(withCompletion: true);
      addTearDown(env.close);
      final actions = await env.db.reminderDao.listItemActionRecordsForItem(
        env.localItemId,
      );
      final undone = await env.itemRepository.undoDone(
        actions.single.id,
        revertedAt: DateTime(2026, 6, 22, 10),
      );

      expect(undone, isTrue);
      final pending = await env.db.reminderDao.listPendingSyncOutboxEntries();
      expect(pending.single.actionType, SyncOutboxActionType.undoItem);

      env.remoteClient.undoResult = const RemotePocResult.success(
        RemoteItemUndoResult(
          status: RemoteItemUndoStatus.undone,
          itemId: 'remote-item-1',
          completionId: 'remote-completion-1',
        ),
      );
      final result = await env.coordinator.syncAfterRemoteBackedMutation(
        env.localPackId,
      );

      expect(result.status, RemoteBackedSyncStatus.synced);
      expect(env.remoteClient.undoCalls, 1);
    },
  );

  test(
    'coordinator refresh imports remote item completion and member mirror',
    () async {
      final env = await _SyncEnv.create();
      addTearDown(env.close);
      env.nextSnapshot = _snapshot(
        title: 'Remote updated title',
        note: 'Remote updated note',
        withCompletion: true,
        includeOtherMember: true,
      );

      final result = await env.coordinator.refreshRemoteBackedPack(
        env.localPackId,
      );

      expect(result.status, RemoteBackedSyncStatus.refreshed);
      final item = (await env.itemRepository.getItemById(
        env.localItemId,
      ))!.item;
      expect(item.title, 'Remote updated title');
      expect(item.description, 'Remote updated note');
      final actions = await env.db.reminderDao.listItemActionRecordsForItem(
        env.localItemId,
      );
      expect(actions.single.actionType, ItemActionType.done);
      final members = await env.db.reminderDao.listPackMembers(env.localPackId);
      expect(
        members.where((member) => member.status.name == 'active'),
        hasLength(2),
      );
    },
  );

  test(
    'refresh flushes pending create before pulling remote snapshot',
    () async {
      final env = await _SyncEnv.create();
      addTearDown(env.close);
      final newItemId = await env.itemRepository.createItem(
        ItemInput(
          title: 'Pending local create',
          description: 'Must flush before pull',
          type: ItemType.stateBased,
          config: _stateConfig(),
          packId: env.localPackId,
        ),
      );
      env.remoteClient.createResult = const RemotePocResult.success(
        RemoteItemCreateResult(itemId: 'remote-created-before-refresh'),
      );
      env.nextSnapshot = _snapshot(
        extraItems: [
          _remoteItemSnapshot(
            id: 'remote-created-before-refresh',
            title: 'Pending local create',
            note: 'Must flush before pull',
          ),
        ],
      );

      final result = await env.coordinator.refreshRemoteBackedPack(
        env.localPackId,
      );

      expect(result.status, RemoteBackedSyncStatus.refreshed);
      expect(env.operations, ['create', 'pull']);
      expect(env.remoteClient.createCalls, 1);
      expect(env.pullCalls, 1);
      final outbox = await env.db.reminderDao.listSyncOutboxEntries();
      expect(outbox.single.status, SyncOutboxStatus.synced);
      final metadata = await env.db.reminderDao
          .getRemoteItemSyncMetadataForLocalItem(newItemId);
      expect(metadata!.remoteItemId, 'remote-created-before-refresh');
      expect(metadata.syncState, RemoteItemSyncState.synced);
    },
  );

  test(
    'refresh does not pull when pre-refresh flush leaves failed mutation',
    () async {
      final env = await _SyncEnv.create();
      addTearDown(env.close);
      final existing = (await env.itemRepository.getItemById(env.localItemId))!;
      await env.itemRepository.updateItem(
        env.localItemId,
        ItemInput(
          title: 'Pending local title',
          description: 'Pending local note',
          type: existing.item.type,
          config: existing.item.config,
          packId: env.localPackId,
        ),
      );
      env.nextSnapshot = _snapshot(
        title: 'Remote stale title',
        note: 'Remote stale note',
      );

      final result = await env.coordinator.refreshRemoteBackedPack(
        env.localPackId,
      );

      expect(result.status, RemoteBackedSyncStatus.failed);
      expect(env.operations, ['update']);
      expect(env.remoteClient.updateCalls, 1);
      expect(env.pullCalls, 0);
      final local = (await env.itemRepository.getItemById(
        env.localItemId,
      ))!.item;
      expect(local.title, 'Pending local title');
      expect(local.description, 'Pending local note');
      final outbox = await env.db.reminderDao.listSyncOutboxEntries();
      expect(outbox.single.status, SyncOutboxStatus.failed);
    },
  );

  test(
    'pull-to-refresh imports remote-created item into local mirror',
    () async {
      final env = await _SyncEnv.create();
      addTearDown(env.close);
      env.nextSnapshot = _snapshot(
        extraItems: [
          _remoteItemSnapshot(
            id: 'remote-item-created-on-a',
            title: 'Created on A',
            note: 'Visible on B after refresh',
          ),
        ],
      );

      final result = await env.coordinator.refreshRemoteBackedPack(
        env.localPackId,
      );

      expect(result.status, RemoteBackedSyncStatus.refreshed);
      expect(env.operations, ['pull']);
      final mapping = await env.db.reminderDao.getSyncMappingByRemote(
        localEntityType: 'item',
        remoteTable: 'items',
        remoteEntityId: 'remote-item-created-on-a',
      );
      expect(mapping, isNotNull);
      final imported = (await env.itemRepository.getItemById(
        mapping!.localEntityId,
      ))!.item;
      expect(imported.title, 'Created on A');
      expect(imported.description, 'Visible on B after refresh');
    },
  );

  test('pull-to-refresh imports remote-updated item title and note', () async {
    final env = await _SyncEnv.create();
    addTearDown(env.close);
    env.nextSnapshot = _snapshot(
      title: 'Updated on A',
      note: 'Updated note on A',
    );

    final result = await env.coordinator.refreshRemoteBackedPack(
      env.localPackId,
    );

    expect(result.status, RemoteBackedSyncStatus.refreshed);
    expect(env.operations, ['pull']);
    final imported = (await env.itemRepository.getItemById(
      env.localItemId,
    ))!.item;
    expect(imported.title, 'Updated on A');
    expect(imported.description, 'Updated note on A');
    final metadata = await env.db.reminderDao
        .getRemoteItemSyncMetadataForLocalItem(env.localItemId);
    expect(metadata!.syncState, RemoteItemSyncState.synced);
    expect(metadata.lastPulledAt, isNotNull);
  });

  test('coordinator flush failure keeps failed sync state visible', () async {
    final env = await _SyncEnv.create();
    addTearDown(env.close);
    await env.itemRepository.markDone(env.localItemId);

    final result = await env.coordinator.syncAfterRemoteBackedMutation(
      env.localPackId,
    );

    expect(result.status, RemoteBackedSyncStatus.failed);
    final outbox = await env.db.reminderDao.listSyncOutboxEntries();
    expect(outbox.single.status, SyncOutboxStatus.failed);
    expect(outbox.single.lastError, 'remoteUnknownFailure');
  });
}

StateBasedItemConfig _stateConfig() {
  return StateBasedItemConfig(
    anchorDate: DateTime(2026, 6, 20),
    warningAfter: const Duration(days: 2),
    dangerAfter: const Duration(days: 4),
  );
}

class _SyncEnv {
  _SyncEnv({
    required this.db,
    required this.itemRepository,
    required this.coordinator,
    required this.remoteClient,
    required this.localPackId,
    required this.localItemId,
    required this.operations,
  });

  final AppDatabase db;
  final ItemRepository itemRepository;
  final RemoteBackedSyncCoordinator coordinator;
  final _FakeRemoteClient remoteClient;
  final int localPackId;
  final int localItemId;
  final List<String> operations;
  RemotePackSnapshot? nextSnapshot;
  int pullCalls = 0;

  static Future<_SyncEnv> create({bool withCompletion = false}) async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    final identity = IdentityRepository(db.reminderDao);
    final currentUser = await identity.linkRemoteIdentity(
      remoteUserId: 'remote-user-current',
      provider: AuthProviderType.supabaseAnonymous,
    );
    final importService = RemoteSnapshotImportService(
      dao: db.reminderDao,
      identityRepository: identity,
    );
    final importResult = await importService.importRemotePackSnapshot(
      snapshot: _snapshot(withCompletion: withCompletion),
      source: RemoteSnapshotImportSource.manualDeveloperImport,
    );
    final itemMapping = await db.reminderDao.getSyncMappingByRemote(
      localEntityType: 'item',
      remoteTable: 'items',
      remoteEntityId: 'remote-item-1',
    );
    final actionService = RemoteBackedItemActionService(
      dao: db.reminderDao,
      identityRepository: identity,
    );
    final itemRepository = ItemRepository(
      db.reminderDao,
      remoteBackedItemActionService: actionService,
      currentActorId: () async => currentUser.id,
    );
    final operations = <String>[];
    final remoteClient = _FakeRemoteClient(operations);
    late final _SyncEnv env;
    final coordinator = RemoteBackedSyncCoordinator(
      dao: db.reminderDao,
      flushService: RemoteBackedOutboxFlushService(
        dao: db.reminderDao,
        remoteClient: remoteClient,
      ),
      refreshService: RemoteBackedPackRefreshService(
        dao: db.reminderDao,
        pullRemotePackSnapshot: (_) async {
          env.pullCalls++;
          operations.add('pull');
          return RemotePocResult.success(env.nextSnapshot ?? _snapshot());
        },
        importRemotePackSnapshot: importService.importRemotePackSnapshot,
      ),
    );
    env = _SyncEnv(
      db: db,
      itemRepository: itemRepository,
      coordinator: coordinator,
      remoteClient: remoteClient,
      localPackId: importResult.localPackId!,
      localItemId: itemMapping!.localEntityId,
      operations: operations,
    );
    return env;
  }

  Future<void> close() => db.close();
}

RemotePackSnapshot _snapshot({
  String title = 'Remote item',
  String note = 'Remote note',
  bool withCompletion = false,
  bool includeOtherMember = false,
  List<RemoteItemSnapshot> extraItems = const [],
}) {
  final created = DateTime(2026, 6, 21, 10);
  final updated = DateTime(2026, 6, 21, 11);
  return RemotePackSnapshot(
    id: 'remote-pack-1',
    name: 'Remote house pack',
    description: 'Shared mirror',
    hostUserId: 'remote-user-current',
    status: 'active',
    createdAt: created,
    updatedAt: updated,
    members: [
      RemotePackMemberSnapshot(
        id: 'remote-pack-1-member-current',
        packId: 'remote-pack-1',
        userId: 'remote-user-current',
        displayName: 'Current',
        role: 'host',
        status: 'active',
        joinedAt: created,
      ),
      if (includeOtherMember)
        RemotePackMemberSnapshot(
          id: 'remote-pack-1-member-other',
          packId: 'remote-pack-1',
          userId: 'remote-user-other',
          displayName: 'Other',
          role: 'member',
          status: 'active',
          joinedAt: created,
        ),
    ],
    items: [
      _remoteItemSnapshot(id: 'remote-item-1', title: title, note: note),
      ...extraItems,
    ],
    completions: withCompletion
        ? [
            RemoteItemCompletionSnapshot(
              id: 'remote-completion-1',
              packId: 'remote-pack-1',
              itemId: 'remote-item-1',
              completedByUserId: 'remote-user-current',
              completedAt: updated,
              createdAt: updated,
            ),
          ]
        : const [],
    activityEvents: const [],
  );
}

RemoteItemSnapshot _remoteItemSnapshot({
  required String id,
  required String title,
  String? note,
}) {
  final created = DateTime(2026, 6, 21, 10);
  final updated = DateTime(2026, 6, 21, 11);
  return RemoteItemSnapshot(
    id: id,
    packId: 'remote-pack-1',
    title: title,
    note: note,
    status: 'active',
    assignedToUserId: null,
    createdByUserId: 'remote-user-current',
    updatedByUserId: 'remote-user-current',
    createdAt: created,
    updatedAt: updated,
  );
}

class _FakeRemoteClient implements RemoteBackedOutboxRemoteClient {
  _FakeRemoteClient(this.operations);

  final List<String> operations;
  RemotePocResult<RemoteItemCreateResult>? createResult;
  RemotePocResult<RemoteItemMutationResult>? updateResult;
  RemotePocResult<RemoteItemMutationResult>? archiveResult;
  RemotePocResult<RemoteItemCompletionResult>? completeResult;
  RemotePocResult<RemoteItemUndoResult>? undoResult;
  int createCalls = 0;
  int updateCalls = 0;
  int archiveCalls = 0;
  int completeCalls = 0;
  int undoCalls = 0;

  @override
  Future<RemotePocResult<RemoteItemCreateResult>> createRemoteItemForPack({
    required String remotePackId,
    required String title,
    String? note,
    String? clientMutationId,
  }) async {
    createCalls++;
    operations.add('create');
    return createResult ??
        const RemotePocResult.failure(
          RemoteSharedPackFailureReason.remoteUnknownFailure,
        );
  }

  @override
  Future<RemotePocResult<RemoteItemMutationResult>> updateRemoteItemById({
    required String remoteItemId,
    required String title,
    String? note,
    String? assignedToUserId,
    String? clientMutationId,
  }) async {
    updateCalls++;
    operations.add('update');
    return updateResult ??
        const RemotePocResult.failure(
          RemoteSharedPackFailureReason.remoteUnknownFailure,
        );
  }

  @override
  Future<RemotePocResult<RemoteItemMutationResult>> archiveRemoteItemById({
    required String remoteItemId,
    String? clientMutationId,
  }) async {
    archiveCalls++;
    operations.add('archive');
    return archiveResult ??
        const RemotePocResult.failure(
          RemoteSharedPackFailureReason.remoteUnknownFailure,
        );
  }

  @override
  Future<RemotePocResult<RemoteResourceCreateResult>>
  createRemoteResourceForPack({
    required String remotePackId,
    required String title,
    String? description,
    required String type,
    Map<String, Object?>? config,
    String? clientMutationId,
  }) async {
    return const RemotePocResult.failure(
      RemoteSharedPackFailureReason.remoteUnknownFailure,
    );
  }

  @override
  Future<RemotePocResult<RemoteResourceMutationResult>>
  updateRemoteResourceById({
    required String remoteResourceId,
    required String title,
    String? description,
    Map<String, Object?>? config,
    String? clientMutationId,
  }) async {
    return const RemotePocResult.failure(
      RemoteSharedPackFailureReason.remoteUnknownFailure,
    );
  }

  @override
  Future<RemotePocResult<RemoteResourceMutationResult>>
  archiveRemoteResourceById({
    required String remoteResourceId,
    String? clientMutationId,
  }) async {
    return const RemotePocResult.failure(
      RemoteSharedPackFailureReason.remoteUnknownFailure,
    );
  }

  @override
  Future<RemotePocResult<RemoteResourceEventResult>>
  applyRemoteResourceEventById({
    required String remoteResourceId,
    required String changeType,
    int? deltaValue,
    int? newValue,
    String? unit,
    String? clientMutationId,
    Map<String, Object?>? metadata,
  }) async {
    return const RemotePocResult.failure(
      RemoteSharedPackFailureReason.remoteUnknownFailure,
    );
  }

  @override
  Future<RemotePocResult<RemoteStageTrackerCreateResult>>
  createRemoteStageTrackerForPack({
    required String remotePackId,
    required String title,
    String? subjectName,
    required DateTime trackingStartDate,
    DateTime? trackingEndDate,
    List<Map<String, Object?>> initialRules = const [],
    String? clientMutationId,
  }) async {
    return const RemotePocResult.failure(
      RemoteSharedPackFailureReason.remoteUnknownFailure,
    );
  }

  @override
  Future<RemotePocResult<RemoteStageMutationResult>>
  updateRemoteStageTrackerById({
    required String remoteStageTrackerId,
    required String title,
    String? subjectName,
    required DateTime trackingStartDate,
    DateTime? trackingEndDate,
    String? clientMutationId,
  }) async {
    return const RemotePocResult.failure(
      RemoteSharedPackFailureReason.remoteUnknownFailure,
    );
  }

  @override
  Future<RemotePocResult<RemoteStageMutationResult>>
  archiveRemoteStageTrackerById({
    required String remoteStageTrackerId,
    String? clientMutationId,
  }) async {
    return const RemotePocResult.failure(
      RemoteSharedPackFailureReason.remoteUnknownFailure,
    );
  }

  @override
  Future<RemotePocResult<RemoteStageMutationResult>>
  createRemoteStageRuleByTrackerId({
    required String remoteStageTrackerId,
    required Map<String, Object?> fields,
    String? clientMutationId,
  }) async {
    return const RemotePocResult.failure(
      RemoteSharedPackFailureReason.remoteUnknownFailure,
    );
  }

  @override
  Future<RemotePocResult<RemoteStageMutationResult>> updateRemoteStageRuleById({
    required String remoteStageRuleId,
    required Map<String, Object?> fields,
    String? clientMutationId,
  }) async {
    return const RemotePocResult.failure(
      RemoteSharedPackFailureReason.remoteUnknownFailure,
    );
  }

  @override
  Future<RemotePocResult<RemoteStageMutationResult>>
  updateRemoteStageRuleStatusById({
    required String remoteStageRuleId,
    required String status,
    String? clientMutationId,
  }) async {
    return const RemotePocResult.failure(
      RemoteSharedPackFailureReason.remoteUnknownFailure,
    );
  }

  @override
  Future<RemotePocResult<RemoteStageMutationResult>>
  createRemoteStageRecordByTrackerId({
    required String remoteStageTrackerId,
    String? remoteStageRuleId,
    required Map<String, Object?> fields,
    String? clientMutationId,
  }) async {
    return const RemotePocResult.failure(
      RemoteSharedPackFailureReason.remoteUnknownFailure,
    );
  }

  @override
  Future<RemotePocResult<RemoteStageMutationResult>>
  updateRemoteStageRecordById({
    required String remoteStageRecordId,
    required Map<String, Object?> fields,
    String? clientMutationId,
  }) async {
    return const RemotePocResult.failure(
      RemoteSharedPackFailureReason.remoteUnknownFailure,
    );
  }

  @override
  Future<RemotePocResult<RemoteStageMutationResult>>
  archiveRemoteStageRecordById({
    required String remoteStageRecordId,
    String? clientMutationId,
  }) async {
    return const RemotePocResult.failure(
      RemoteSharedPackFailureReason.remoteUnknownFailure,
    );
  }

  @override
  Future<RemotePocResult<RemoteStageAcknowledgementResult>>
  acknowledgeRemoteStageRecordById({
    required String remoteStageRecordId,
    String? clientMutationId,
  }) async {
    return const RemotePocResult.failure(
      RemoteSharedPackFailureReason.remoteUnknownFailure,
    );
  }

  @override
  Future<RemotePocResult<RemoteItemCompletionResult>> completeRemoteItemById(
    String remoteItemId,
  ) async {
    completeCalls++;
    operations.add('complete');
    return completeResult ??
        const RemotePocResult.failure(
          RemoteSharedPackFailureReason.remoteUnknownFailure,
        );
  }

  @override
  Future<RemotePocResult<RemoteItemUndoResult>> undoRemoteItemById(
    String remoteItemId,
  ) async {
    undoCalls++;
    operations.add('undo');
    return undoResult ??
        const RemotePocResult.failure(
          RemoteSharedPackFailureReason.remoteUnknownFailure,
        );
  }
}
