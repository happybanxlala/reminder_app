import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reminder_app/features/reminders/data/identity_repository.dart';
import 'package:reminder_app/features/reminders/data/item_repository.dart';
import 'package:reminder_app/features/reminders/data/local/app_database.dart';
import 'package:reminder_app/features/reminders/data/remote_backed_item_action_service.dart';
import 'package:reminder_app/features/reminders/data/remote_backed_outbox_flush_service.dart';
import 'package:reminder_app/features/reminders/data/remote_backed_outbox_retry_service.dart';
import 'package:reminder_app/features/reminders/data/remote_shared_pack_models.dart';
import 'package:reminder_app/features/reminders/data/remote_shared_pack_repository.dart';
import 'package:reminder_app/features/reminders/data/remote_snapshot_import_service.dart';
import 'package:reminder_app/features/reminders/data/resource_repository.dart';
import 'package:reminder_app/features/reminders/data/stage_tracker_models.dart';
import 'package:reminder_app/features/reminders/data/stage_tracker_repository.dart';
import 'package:reminder_app/features/reminders/domain/item.dart';
import 'package:reminder_app/features/reminders/domain/item_pack.dart';
import 'package:reminder_app/features/reminders/domain/remote_backed_recovery.dart';
import 'package:reminder_app/features/reminders/domain/remote_sync.dart';
import 'package:reminder_app/features/reminders/domain/resource.dart';
import 'package:reminder_app/features/reminders/domain/shared_pack.dart';

void main() {
  test(
    'remote-backed complete creates pending completion and outbox',
    () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);
      final env = await _seedRemoteBackedMirror(db, withCompletion: false);

      final result = await env.actionService.completeRemoteBackedItemLocally(
        env.localItemId,
        actorLocalUserId: env.currentUser.id,
        doneAt: DateTime(2026, 6, 22, 9),
      );

      expect(
        result.status,
        RemoteBackedItemLocalActionStatus.completedPendingSync,
      );
      final completions = await db.reminderDao.listItemCompletions(
        env.localItemId,
      );
      expect(completions, hasLength(1));
      final metadata = await db.reminderDao
          .getRemoteCompletionSyncMetadataForLocalCompletion(
            completions.single.id,
          );
      expect(metadata!.completionState, RemoteCompletionState.pendingLocal);
      expect(metadata.syncState, RemoteCompletionSyncState.pendingPush);
      final outbox = await db.reminderDao.listPendingSyncOutboxEntries();
      expect(outbox, hasLength(1));
      expect(outbox.single.actionType, SyncOutboxActionType.completeItem);
      expect(outbox.single.remoteEntityId, 'remote-item-1');
      expect(outbox.single.clientMutationId, isNotEmpty);
    },
  );

  test(
    'remote-backed undo preserves completion history and enqueues outbox',
    () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);
      final env = await _seedRemoteBackedMirror(db, withCompletion: true);
      final completion = (await db.reminderDao.listItemCompletions(
        env.localItemId,
      )).single;

      final result = await env.actionService.undoRemoteBackedItemLocally(
        env.localItemId,
        actorLocalUserId: env.currentUser.id,
        undoneAt: DateTime(2026, 6, 22, 10),
      );

      expect(result.status, RemoteBackedItemLocalActionStatus.undoPendingSync);
      final updated = (await db.reminderDao.listItemCompletions(
        env.localItemId,
      )).single;
      expect(updated.id, completion.id);
      expect(updated.completedByUserId, completion.completedByUserId);
      expect(updated.undoneByUserId, env.currentUser.id);
      final metadata = await db.reminderDao
          .getRemoteCompletionSyncMetadataForLocalCompletion(completion.id);
      expect(metadata!.completionState, RemoteCompletionState.pendingLocal);
      final outbox = await db.reminderDao.listPendingSyncOutboxEntries();
      expect(outbox.single.actionType, SyncOutboxActionType.undoItem);
    },
  );

  test(
    'ItemRepository routes remote-backed markDone and undoDone to outbox',
    () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);
      final env = await _seedRemoteBackedMirror(db, withCompletion: false);
      final repository = ItemRepository(
        db.reminderDao,
        remoteBackedItemActionService: env.actionService,
        currentActorId: () async => env.currentUser.id,
      );

      expect(await repository.markDone(env.localItemId), isTrue);
      final outbox = await db.reminderDao.listPendingSyncOutboxEntries();
      expect(outbox.single.actionType, SyncOutboxActionType.completeItem);
      final doneRecord = (await db.select(db.itemActionRecords).get()).single;
      expect(await repository.undoDone(doneRecord.id), isTrue);
      final entries = await db.reminderDao.listSyncOutboxEntries();
      expect(
        entries.map((e) => e.actionType),
        contains(SyncOutboxActionType.undoItem),
      );
    },
  );

  test(
    'remote-backed create item is local-first and flushes to remote',
    () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);
      final env = await _seedRemoteBackedMirror(db, withCompletion: false);
      final repository = ItemRepository(
        db.reminderDao,
        remoteBackedItemActionService: env.actionService,
        currentActorId: () async => env.currentUser.id,
      );

      final itemId = await repository.createItem(
        ItemInput(
          title: 'Buy litter',
          description: 'Shared note',
          type: ItemType.stateBased,
          config: const StateBasedItemConfig(
            warningAfter: Duration(days: 3),
            dangerAfter: Duration(days: 5),
          ),
          packId: env.localPackId,
        ),
      );

      final metadata = await db.reminderDao
          .getRemoteItemSyncMetadataForLocalItem(itemId);
      expect(metadata!.syncState, RemoteItemSyncState.pendingPush);
      expect(metadata.remoteItemId, startsWith('pending:'));
      final outbox = await db.reminderDao.listPendingSyncOutboxEntries();
      expect(outbox.single.actionType, SyncOutboxActionType.createItem);
      final payload = jsonDecode(outbox.single.payloadJson) as Map;
      expect((payload['fields'] as Map)['title'], 'Buy litter');

      final remote = _FakeRemoteClient(
        createResult: const RemotePocResult.success(
          RemoteItemCreateResult(itemId: 'remote-created-item'),
        ),
      );
      final result = await RemoteBackedOutboxFlushService(
        dao: db.reminderDao,
        remoteClient: remote,
      ).flushPendingRemoteBackedMutations();

      expect(result.synced, 1);
      expect(remote.createCalls, 1);
      final mapping = await db.reminderDao.getSyncMapping(
        localEntityType: RemoteSharedPackRepository.localEntityItem,
        localEntityId: itemId,
        remoteTable: RemoteSharedPackRepository.remoteTableItems,
      );
      expect(mapping!.remoteEntityId, 'remote-created-item');
      final updatedMetadata = await db.reminderDao
          .getRemoteItemSyncMetadataForLocalItem(itemId);
      expect(updatedMetadata!.remoteItemId, 'remote-created-item');
    },
  );

  test('remote-backed update item enqueues basic field mutation', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final env = await _seedRemoteBackedMirror(db, withCompletion: false);
    final repository = ItemRepository(
      db.reminderDao,
      remoteBackedItemActionService: env.actionService,
      currentActorId: () async => env.currentUser.id,
    );
    final bundle = (await repository.getItemById(env.localItemId))!;

    final updated = await repository.updateItem(
      env.localItemId,
      ItemInput(
        title: 'Updated remote mirror',
        description: 'Updated note',
        type: bundle.item.type,
        config: bundle.item.config,
        attentionPolicySource: bundle.item.attentionPolicySource,
        packId: bundle.item.packId,
      ),
    );

    expect(updated, isTrue);
    final local = (await repository.getItemById(env.localItemId))!.item;
    expect(local.title, 'Updated remote mirror');
    final outbox = await db.reminderDao.listPendingSyncOutboxEntries();
    expect(outbox.single.actionType, SyncOutboxActionType.updateItem);
    final remote = _FakeRemoteClient(
      updateResult: const RemotePocResult.success(
        RemoteItemMutationResult(itemId: 'remote-item-1', status: 'updated'),
      ),
    );
    final result = await RemoteBackedOutboxFlushService(
      dao: db.reminderDao,
      remoteClient: remote,
    ).flushPendingRemoteBackedMutations();

    expect(result.synced, 1);
    expect(remote.updateCalls, 1);
  });

  test('remote-backed archive item enqueues archive mutation', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final env = await _seedRemoteBackedMirror(db, withCompletion: false);
    final repository = ItemRepository(
      db.reminderDao,
      remoteBackedItemActionService: env.actionService,
      currentActorId: () async => env.currentUser.id,
    );

    expect(await repository.archiveItem(env.localItemId), isTrue);
    final local = (await repository.getItemById(env.localItemId))!.item;
    expect(local.status, ItemLifecycleStatus.archived);
    final outbox = await db.reminderDao.listPendingSyncOutboxEntries();
    expect(outbox.single.actionType, SyncOutboxActionType.archiveItem);

    final remote = _FakeRemoteClient(
      archiveResult: const RemotePocResult.success(
        RemoteItemMutationResult(itemId: 'remote-item-1', status: 'archived'),
      ),
    );
    final result = await RemoteBackedOutboxFlushService(
      dao: db.reminderDao,
      remoteClient: remote,
    ).flushPendingRemoteBackedMutations();

    expect(result.synced, 1);
    expect(remote.archiveCalls, 1);
  });

  test(
    'remote-backed unsupported CRUD fails closed without local mutation',
    () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);
      final env = await _seedRemoteBackedMirror(db, withCompletion: false);
      final repository = ItemRepository(
        db.reminderDao,
        remoteBackedItemActionService: env.actionService,
        currentActorId: () async => env.currentUser.id,
      );
      final packBefore = (await repository.getPackById(env.localPackId))!;

      expect(
        await repository.updatePack(
          env.localPackId,
          const ItemPackInput(title: 'Changed', iconEmoji: '🏠'),
        ),
        isFalse,
      );
      expect(
        await repository.archivePackWithContents(env.localPackId),
        isFalse,
      );
      expect(await repository.skip(env.localItemId), isFalse);
      expect(await repository.pauseItem(env.localItemId), isFalse);
      final packAfter = (await repository.getPackById(env.localPackId))!;
      expect(packAfter.title, packBefore.title);
      expect(packAfter.status, packBefore.status);

      final resourceRepository = ResourceRepository(db.reminderDao);
      await expectLater(
        resourceRepository.createResource(
          ResourceInput(
            title: 'Litter',
            type: ResourceType.quantityBased,
            config: const QuantityBasedResourceConfig(
              currentQuantity: 1,
              unitLabel: 'bag',
            ),
            packId: env.localPackId,
          ),
        ),
        throwsA(isA<StateError>()),
      );

      final stageRepository = StageTrackerRepository(db.reminderDao);
      await expectLater(
        stageRepository.createStageTracker(
          StageTrackerInput(
            title: 'Kitten growth',
            trackingStartDate: DateTime(2026, 6, 1),
            packId: env.localPackId,
          ),
        ),
        throwsA(isA<StateError>()),
      );
    },
  );

  test('local action returns typed no-op and failure states', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final env = await _seedRemoteBackedMirror(db, withCompletion: true);

    final alreadyComplete = await env.actionService
        .completeRemoteBackedItemLocally(
          env.localItemId,
          actorLocalUserId: env.currentUser.id,
        );
    expect(
      alreadyComplete.status,
      RemoteBackedItemLocalActionStatus.alreadyLocallyCompleted,
    );

    final packMetadata = await db.reminderDao
        .getRemotePackSyncMetadataForLocalPack(env.localPackId);
    await db.reminderDao.updateRemotePackSyncMetadata(
      packMetadata!.id,
      RemotePackSyncMetadataCompanion(
        syncState: Value(RemotePackSyncState.accessLost.storageValue),
      ),
    );
    final accessLost = await env.actionService.undoRemoteBackedItemLocally(
      env.localItemId,
      actorLocalUserId: env.currentUser.id,
    );
    expect(
      accessLost.status,
      RemoteBackedItemLocalActionStatus.remoteAccessLost,
    );
  });

  test(
    'flush complete success marks outbox synced and metadata confirmed',
    () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);
      final env = await _seedRemoteBackedMirror(db, withCompletion: false);
      await env.actionService.completeRemoteBackedItemLocally(env.localItemId);
      final fake = _FakeRemoteClient(
        completeResult: RemotePocResult.success(
          RemoteItemCompletionResult(
            status: RemoteItemCompletionStatus.completed,
            completionId: 'remote-completion-new',
            completedByUserId: 'remote-user-current',
            completedAt: DateTime(2026, 6, 22, 9, 5),
          ),
        ),
      );

      final result = await RemoteBackedOutboxFlushService(
        dao: db.reminderDao,
        remoteClient: fake,
      ).flushPendingRemoteBackedMutations();

      expect(result.synced, 1);
      expect(fake.completeCalls, 1);
      final outbox = await db.reminderDao.listSyncOutboxEntries();
      expect(outbox.single.status, SyncOutboxStatus.synced);
      final completion = (await db.reminderDao.listItemCompletions(
        env.localItemId,
      )).single;
      final metadata = await db.reminderDao
          .getRemoteCompletionSyncMetadataForLocalCompletion(completion.id);
      expect(metadata!.completionState, RemoteCompletionState.confirmedRemote);
      expect(metadata.remoteCompletionId, 'remote-completion-new');

      await RemoteBackedOutboxFlushService(
        dao: db.reminderDao,
        remoteClient: fake,
      ).flushPendingRemoteBackedMutations();
      expect(fake.completeCalls, 1);
    },
  );

  test(
    'flush complete alreadyCompleted maps to no-op without overwrite',
    () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);
      final env = await _seedRemoteBackedMirror(db, withCompletion: false);
      await env.actionService.completeRemoteBackedItemLocally(env.localItemId);
      final completion = (await db.reminderDao.listItemCompletions(
        env.localItemId,
      )).single;
      final metadata = await db.reminderDao
          .getRemoteCompletionSyncMetadataForLocalCompletion(completion.id);
      await db.reminderDao.updateRemoteCompletionSyncMetadata(
        metadata!.id,
        RemoteCompletionSyncMetadataCompanion(
          remoteCompletedByUserId: const Value('remote-user-other'),
        ),
      );
      final fake = _FakeRemoteClient(
        completeResult: RemotePocResult.failure(
          RemoteSharedPackFailureReason.remoteItemAlreadyCompleted,
          RemoteItemCompletionResult(
            status: RemoteItemCompletionStatus.alreadyCompleted,
            completionId: 'remote-existing',
            completedByUserId: 'remote-user-current',
            completedAt: DateTime(2026, 6, 22, 9),
          ),
        ),
      );

      final result = await RemoteBackedOutboxFlushService(
        dao: db.reminderDao,
        remoteClient: fake,
      ).flushPendingRemoteBackedMutations();

      expect(result.noOp, 1);
      final outbox = await db.reminderDao.listSyncOutboxEntries();
      expect(outbox.single.status, SyncOutboxStatus.noOp);
      final updated = await db.reminderDao
          .getRemoteCompletionSyncMetadataForLocalCompletion(completion.id);
      expect(updated!.completionState, RemoteCompletionState.noOp);
      expect(updated.remoteCompletedByUserId, 'remote-user-other');
    },
  );

  test('flush undo success and alreadyNotCompleted mapping', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final env = await _seedRemoteBackedMirror(db, withCompletion: true);
    await env.actionService.undoRemoteBackedItemLocally(env.localItemId);
    final fake = _FakeRemoteClient(
      undoResult: RemotePocResult.success(
        RemoteItemUndoResult(
          status: RemoteItemUndoStatus.undone,
          itemId: 'remote-item-1',
          completionId: 'remote-completion-1',
          undoneByUserId: 'remote-user-current',
          undoneAt: DateTime(2026, 6, 22, 10),
        ),
      ),
    );

    final success = await RemoteBackedOutboxFlushService(
      dao: db.reminderDao,
      remoteClient: fake,
    ).flushPendingRemoteBackedMutations();

    expect(success.synced, 1);
    final completion = (await db.reminderDao.listItemCompletions(
      env.localItemId,
    )).single;
    var metadata = await db.reminderDao
        .getRemoteCompletionSyncMetadataForLocalCompletion(completion.id);
    expect(metadata!.completionState, RemoteCompletionState.undoneRemote);
    expect(metadata.remoteCompletedByUserId, 'remote-user-other');

    final env2 = await _seedRemoteBackedMirror(
      db,
      withCompletion: true,
      remotePackId: 'remote-pack-2',
      remoteItemId: 'remote-item-2',
      remoteCompletionId: 'remote-completion-2',
    );
    await env2.actionService.undoRemoteBackedItemLocally(env2.localItemId);
    fake.undoResult = RemotePocResult.success(
      const RemoteItemUndoResult(
        status: RemoteItemUndoStatus.alreadyNotCompleted,
        itemId: 'remote-item-2',
      ),
    );

    final noOp = await RemoteBackedOutboxFlushService(
      dao: db.reminderDao,
      remoteClient: fake,
    ).flushPendingRemoteBackedMutations();

    expect(noOp.noOp, 1);
    final entries = await db.reminderDao.listSyncOutboxEntries();
    expect(
      entries.where((entry) => entry.status == SyncOutboxStatus.noOp),
      isNotEmpty,
    );
    final completion2 = (await db.reminderDao.listItemCompletions(
      env2.localItemId,
    )).single;
    metadata = await db.reminderDao
        .getRemoteCompletionSyncMetadataForLocalCompletion(completion2.id);
    expect(metadata!.completionState, RemoteCompletionState.noOp);
  });

  test(
    'flush failures are friendly and mark access lost when applicable',
    () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);
      final env = await _seedRemoteBackedMirror(db, withCompletion: false);
      await env.actionService.completeRemoteBackedItemLocally(env.localItemId);
      final fake = _FakeRemoteClient(
        completeResult: const RemotePocResult.failure(
          RemoteSharedPackFailureReason.remoteRlsRejected,
        ),
      );

      final result = await RemoteBackedOutboxFlushService(
        dao: db.reminderDao,
        remoteClient: fake,
      ).flushPendingRemoteBackedMutations();

      expect(result.failed, 1);
      final outbox = await db.reminderDao.listSyncOutboxEntries();
      expect(outbox.single.status, SyncOutboxStatus.failed);
      expect(outbox.single.lastError, 'remoteRlsRejected');
      final packMetadata = await db.reminderDao
          .getRemotePackSyncMetadataForLocalPack(env.localPackId);
      expect(packMetadata!.syncState, RemotePackSyncState.accessLost);
    },
  );

  test('manual retry failed complete succeeds through remote client', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final env = await _seedRemoteBackedMirror(db, withCompletion: false);
    await env.actionService.completeRemoteBackedItemLocally(env.localItemId);
    final mutation =
        (await db.reminderDao.listPendingSyncOutboxEntries()).single;
    await db.reminderDao.updateSyncOutboxEntry(
      mutation.id,
      SyncOutboxCompanion(
        status: Value(SyncOutboxStatus.failed.storageValue),
        lastError: const Value('remoteNetworkFailed'),
      ),
    );
    final fake = _FakeRemoteClient(
      completeResult: RemotePocResult.success(
        RemoteItemCompletionResult(
          status: RemoteItemCompletionStatus.completed,
          completionId: 'retry-completion-1',
          completedByUserId: 'remote-user-current',
          completedAt: DateTime(2026, 6, 22, 11),
        ),
      ),
    );

    final result = await RemoteBackedOutboxRetryService(
      dao: db.reminderDao,
      remoteClient: fake,
    ).retryAllRetryableFailedMutations();

    expect(result.retriedCount, 1);
    expect(result.syncedCount, 1);
    expect(result.needsRefreshCount, 1);
    expect(fake.completeCalls, 1);
    final outbox = await db.reminderDao.listSyncOutboxEntries();
    expect(outbox.single.status, SyncOutboxStatus.synced);
    expect(outbox.single.retryCount, 1);
    final completion = (await db.reminderDao.listItemCompletions(
      env.localItemId,
    )).single;
    final metadata = await db.reminderDao
        .getRemoteCompletionSyncMetadataForLocalCompletion(completion.id);
    expect(metadata!.completionState, RemoteCompletionState.confirmedRemote);
    expect(metadata.remoteCompletionId, 'retry-completion-1');
    final packMetadata = await db.reminderDao
        .getRemotePackSyncMetadataForLocalPack(env.localPackId);
    expect(packMetadata!.syncState, RemotePackSyncState.stale);
  });

  test('manual retry failed undo succeeds through remote client', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final env = await _seedRemoteBackedMirror(db, withCompletion: true);
    await env.actionService.undoRemoteBackedItemLocally(env.localItemId);
    final mutation =
        (await db.reminderDao.listPendingSyncOutboxEntries()).single;
    await db.reminderDao.updateSyncOutboxEntry(
      mutation.id,
      SyncOutboxCompanion(
        status: Value(SyncOutboxStatus.failed.storageValue),
        lastError: const Value('networkFailed'),
      ),
    );
    final fake = _FakeRemoteClient(
      undoResult: RemotePocResult.success(
        RemoteItemUndoResult(
          status: RemoteItemUndoStatus.undone,
          itemId: 'remote-item-1',
          completionId: 'remote-completion-1',
          undoneByUserId: 'remote-user-current',
          undoneAt: DateTime(2026, 6, 22, 11),
        ),
      ),
    );

    final result = await RemoteBackedOutboxRetryService(
      dao: db.reminderDao,
      remoteClient: fake,
    ).retryFailedMutationsForPack(env.localPackId);

    expect(result.syncedCount, 1);
    expect(fake.undoCalls, 1);
    final completion = (await db.reminderDao.listItemCompletions(
      env.localItemId,
    )).single;
    final metadata = await db.reminderDao
        .getRemoteCompletionSyncMetadataForLocalCompletion(completion.id);
    expect(metadata!.completionState, RemoteCompletionState.undoneRemote);
    expect(metadata.remoteCompletedByUserId, 'remote-user-other');
  });

  test('manual retry skips non-retryable and access-lost mutations', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final env = await _seedRemoteBackedMirror(db, withCompletion: false);
    await env.actionService.completeRemoteBackedItemLocally(env.localItemId);
    final mutation =
        (await db.reminderDao.listPendingSyncOutboxEntries()).single;
    await db.reminderDao.updateSyncOutboxEntry(
      mutation.id,
      SyncOutboxCompanion(
        status: Value(SyncOutboxStatus.failed.storageValue),
        lastError: const Value('remoteUnknownFailure'),
      ),
    );
    final fake = _FakeRemoteClient(
      completeResult: RemotePocResult.success(
        RemoteItemCompletionResult(
          status: RemoteItemCompletionStatus.completed,
          completionId: 'should-not-send',
          completedByUserId: 'remote-user-current',
          completedAt: DateTime(2026, 6, 22, 11),
        ),
      ),
    );

    var result = await RemoteBackedOutboxRetryService(
      dao: db.reminderDao,
      remoteClient: fake,
    ).retryAllRetryableFailedMutations();

    expect(result.skippedCount, 1);
    expect(fake.completeCalls, 0);
    var outbox = await db.reminderDao.listSyncOutboxEntries();
    expect(outbox.single.status, SyncOutboxStatus.failed);

    final packMetadata = await db.reminderDao
        .getRemotePackSyncMetadataForLocalPack(env.localPackId);
    await db.reminderDao.updateRemotePackSyncMetadata(
      packMetadata!.id,
      RemotePackSyncMetadataCompanion(
        syncState: Value(RemotePackSyncState.accessLost.storageValue),
        currentUserRemoteStatus: Value(RemoteUserStatus.removed.storageValue),
      ),
    );
    await db.reminderDao.updateSyncOutboxEntry(
      mutation.id,
      SyncOutboxCompanion(lastError: const Value('remoteNetworkFailed')),
    );

    result = await RemoteBackedOutboxRetryService(
      dao: db.reminderDao,
      remoteClient: fake,
    ).retryFailedMutation(mutation.id);

    expect(result.skippedCount, 1);
    expect(result.accessLostCount, 1);
    expect(fake.completeCalls, 0);
    outbox = await db.reminderDao.listSyncOutboxEntries();
    expect(outbox.single.status, SyncOutboxStatus.failed);
  });

  test('manual retry fail-closes missing remote mapping', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final now = DateTime(2026, 6, 22).millisecondsSinceEpoch;
    final packId = await ItemRepository(
      db.reminderDao,
    ).createPack(const ItemPackInput(title: 'Broken remote pack'));
    await db.reminderDao.insertRemotePackSyncMetadata(
      RemotePackSyncMetadataCompanion.insert(
        localPackId: packId,
        remotePackId: 'remote-pack-broken',
        syncKind: RemotePackSyncKind.remoteBacked.storageValue,
        syncState: RemotePackSyncState.synced.storageValue,
        createdAt: now,
        updatedAt: now,
      ),
    );
    final mutationId = await db.reminderDao.insertSyncOutbox(
      SyncOutboxCompanion.insert(
        localPackId: packId,
        remotePackId: const Value('remote-pack-broken'),
        localEntityType: 'item_completion',
        localEntityId: const Value(999),
        actionType: SyncOutboxActionType.completeItem.storageValue,
        payloadJson: jsonEncode({'localPackId': packId}),
        clientMutationId: 'missing-mapping',
        actorLocalUserId: AppDatabase.defaultHostUserId,
        createdAt: now,
        updatedAt: now,
        status: SyncOutboxStatus.failed.storageValue,
        lastError: const Value('remoteNetworkFailed'),
      ),
    );
    final fake = _FakeRemoteClient();

    final result = await RemoteBackedOutboxRetryService(
      dao: db.reminderDao,
      remoteClient: fake,
    ).retryFailedMutation(mutationId);

    expect(result.failedCount, 1);
    expect(fake.completeCalls, 0);
    final outbox = await db.reminderDao.getSyncOutboxEntryById(mutationId);
    expect(outbox!.status, SyncOutboxStatus.failed);
    expect(outbox.lastError, 'missing_remote_item_mapping');
  });

  test('recovery classifier maps retryable and terminal states', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final env = await _seedRemoteBackedMirror(db, withCompletion: false);
    await env.actionService.completeRemoteBackedItemLocally(env.localItemId);
    final mutation =
        (await db.reminderDao.listPendingSyncOutboxEntries()).single;

    var view = RemoteBackedRecoveryClassifier.classifyMutation(mutation);
    expect(view.recoveryState, RemoteBackedRecoveryState.pending);
    expect(view.canRetry, isFalse);

    await db.reminderDao.updateSyncOutboxEntry(
      mutation.id,
      SyncOutboxCompanion(
        status: Value(SyncOutboxStatus.failed.storageValue),
        lastError: const Value('remoteNetworkFailed'),
      ),
    );
    final failed = await db.reminderDao.getSyncOutboxEntryById(mutation.id);
    view = RemoteBackedRecoveryClassifier.classifyMutation(failed!);
    expect(view.recoveryState, RemoteBackedRecoveryState.retryableFailed);
    expect(view.canRetry, isTrue);

    await db.reminderDao.updateSyncOutboxEntry(
      mutation.id,
      SyncOutboxCompanion(
        status: Value(SyncOutboxStatus.noOp.storageValue),
        lastError: const Value('already_completed_remote'),
      ),
    );
    final noOp = await db.reminderDao.getSyncOutboxEntryById(mutation.id);
    view = RemoteBackedRecoveryClassifier.classifyMutation(noOp!);
    expect(view.recoveryState, RemoteBackedRecoveryState.noOp);
    expect(view.needsRefresh, isTrue);

    final packMetadata = await db.reminderDao
        .getRemotePackSyncMetadataForLocalPack(env.localPackId);
    await db.reminderDao.updateRemotePackSyncMetadata(
      packMetadata!.id,
      RemotePackSyncMetadataCompanion(
        syncState: Value(RemotePackSyncState.accessLost.storageValue),
      ),
    );
    final accessLostMetadata = await db.reminderDao
        .getRemotePackSyncMetadataForLocalPack(env.localPackId);
    view = RemoteBackedRecoveryClassifier.classifyMutation(
      noOp,
      packMetadata: accessLostMetadata,
    );
    expect(view.recoveryState, RemoteBackedRecoveryState.accessLost);
    expect(view.canRetry, isFalse);
  });
}

Future<_RemoteMirrorEnv> _seedRemoteBackedMirror(
  AppDatabase db, {
  required bool withCompletion,
  String remotePackId = 'remote-pack-1',
  String remoteItemId = 'remote-item-1',
  String remoteCompletionId = 'remote-completion-1',
}) async {
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
    snapshot: _snapshot(
      withCompletion: withCompletion,
      remotePackId: remotePackId,
      remoteItemId: remoteItemId,
      remoteCompletionId: remoteCompletionId,
    ),
    source: RemoteSnapshotImportSource.manualDeveloperImport,
  );
  final itemMapping = await db.reminderDao.getSyncMappingByRemote(
    localEntityType: 'item',
    remoteTable: 'items',
    remoteEntityId: remoteItemId,
  );
  return _RemoteMirrorEnv(
    currentUser: currentUser,
    localPackId: importResult.localPackId!,
    localItemId: itemMapping!.localEntityId,
    actionService: RemoteBackedItemActionService(
      dao: db.reminderDao,
      identityRepository: identity,
    ),
  );
}

RemotePackSnapshot _snapshot({
  required bool withCompletion,
  required String remotePackId,
  required String remoteItemId,
  required String remoteCompletionId,
}) {
  final created = DateTime(2026, 6, 21, 10);
  final updated = DateTime(2026, 6, 21, 11);
  return RemotePackSnapshot(
    id: remotePackId,
    name: 'Remote house pack $remotePackId',
    description: 'Imported mirror',
    hostUserId: 'remote-user-current',
    status: 'active',
    createdAt: created,
    updatedAt: updated,
    members: [
      RemotePackMemberSnapshot(
        id: '$remotePackId-member-1',
        packId: remotePackId,
        userId: 'remote-user-current',
        displayName: 'Current',
        role: 'host',
        status: 'active',
        joinedAt: created,
      ),
      RemotePackMemberSnapshot(
        id: '$remotePackId-member-2',
        packId: remotePackId,
        userId: 'remote-user-other',
        displayName: 'Other',
        role: 'member',
        status: 'active',
        joinedAt: created,
      ),
    ],
    items: [
      RemoteItemSnapshot(
        id: remoteItemId,
        packId: remotePackId,
        title: 'Remote item $remoteItemId',
        note: 'Read-only mirror',
        status: 'active',
        assignedToUserId: 'remote-user-other',
        createdByUserId: 'remote-user-current',
        updatedByUserId: 'remote-user-current',
        createdAt: created,
        updatedAt: updated,
      ),
    ],
    completions: withCompletion
        ? [
            RemoteItemCompletionSnapshot(
              id: remoteCompletionId,
              packId: remotePackId,
              itemId: remoteItemId,
              completedByUserId: 'remote-user-other',
              completedAt: DateTime(2026, 6, 21, 11, 5),
              createdAt: DateTime(2026, 6, 21, 11, 5),
            ),
          ]
        : const [],
    activityEvents: const [],
  );
}

class _RemoteMirrorEnv {
  const _RemoteMirrorEnv({
    required this.currentUser,
    required this.localPackId,
    required this.localItemId,
    required this.actionService,
  });

  final LocalUser currentUser;
  final int localPackId;
  final int localItemId;
  final RemoteBackedItemActionService actionService;
}

class _FakeRemoteClient implements RemoteBackedOutboxRemoteClient {
  _FakeRemoteClient({
    this.createResult,
    this.updateResult,
    this.archiveResult,
    this.completeResult,
    this.undoResult,
  });

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
    return archiveResult ??
        const RemotePocResult.failure(
          RemoteSharedPackFailureReason.remoteUnknownFailure,
        );
  }

  @override
  Future<RemotePocResult<RemoteItemCompletionResult>> completeRemoteItemById(
    String remoteItemId,
  ) async {
    completeCalls++;
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
    return undoResult ??
        const RemotePocResult.failure(
          RemoteSharedPackFailureReason.remoteUnknownFailure,
        );
  }
}
