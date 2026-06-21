import 'package:drift/drift.dart' hide isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reminder_app/features/reminders/data/local/app_database.dart';
import 'package:reminder_app/features/reminders/data/remote_sync_repository.dart';
import 'package:reminder_app/features/reminders/domain/remote_sync.dart';
import 'package:reminder_app/features/reminders/domain/shared_pack.dart';

void main() {
  test('remote sync metadata can be created, queried, and updated', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final seed = await _seedRemoteSyncLocalData(db);
    final repository = RemoteSyncRepository(
      db.reminderDao,
      clock: () => DateTime(2026, 6, 20, 9),
    );

    final packMetadata = await repository.createRemoteBackedPackMetadata(
      localPackId: seed.packId,
      remotePackId: 'remote-pack-1',
      currentUserRemoteRole: RemoteUserRole.host,
      currentUserRemoteStatus: RemoteUserStatus.active,
    );
    expect(packMetadata.localPackId, seed.packId);
    expect(packMetadata.remotePackId, 'remote-pack-1');
    expect(packMetadata.syncKind, RemotePackSyncKind.remoteBacked);
    expect(packMetadata.syncState, RemotePackSyncState.linked);
    expect(
      await repository.getMetadataForRemotePack('remote-pack-1'),
      isNotNull,
    );
    expect(
      await repository.watchMetadataForLocalPack(seed.packId).first,
      isNotNull,
    );

    expect(await repository.markPackStale(seed.packId), isTrue);
    expect(
      (await repository.getMetadataForLocalPack(seed.packId))!.syncState,
      RemotePackSyncState.stale,
    );
    expect(
      await repository.markPackAccessLost(seed.packId, error: 'removed'),
      isTrue,
    );
    final accessLost = await repository.getMetadataForLocalPack(seed.packId);
    expect(accessLost!.syncState, RemotePackSyncState.accessLost);
    expect(accessLost.currentUserRemoteStatus, RemoteUserStatus.removed);
    expect(accessLost.lastSyncError, 'removed');

    final itemMetadata = await repository.createRemoteItemMetadata(
      localItemId: seed.itemId,
      localPackId: seed.packId,
      remoteItemId: 'remote-item-1',
      remotePackId: 'remote-pack-1',
      remoteStatus: 'active',
    );
    expect(itemMetadata.localItemId, seed.itemId);
    expect(itemMetadata.remoteItemId, 'remote-item-1');
    expect(
      await repository.getMetadataForRemoteItem('remote-item-1'),
      isNotNull,
    );
    expect(
      await repository.updateItemSyncState(
        seed.itemId,
        RemoteItemSyncState.failed,
        lastSyncError: 'network',
      ),
      isTrue,
    );
    expect(
      (await repository.getMetadataForLocalItem(seed.itemId))!.lastSyncError,
      'network',
    );
    expect(await repository.markRemoteItemArchived(seed.itemId), isTrue);
    final archived = await repository.getMetadataForLocalItem(seed.itemId);
    expect(archived!.syncState, RemoteItemSyncState.archived);
    expect(archived.remoteStatus, 'archived');

    final completion = await repository.createCompletionSyncMetadata(
      localCompletionId: seed.completionId,
      localItemId: seed.itemId,
      localPackId: seed.packId,
      remoteItemId: 'remote-item-1',
      remotePackId: 'remote-pack-1',
      clientMutationId: 'completion-mutation-1',
    );
    expect(completion.completionState, RemoteCompletionState.pendingLocal);
    expect(
      await repository.markCompletionConfirmedRemote(
        completion.id,
        remoteCompletionId: 'remote-completion-1',
        remoteCompletedByUserId: 'remote-user-1',
        remoteCompletedAt: DateTime(2026, 6, 20, 9, 5),
      ),
      isTrue,
    );
    final confirmed = await db.reminderDao.getRemoteCompletionSyncMetadataById(
      completion.id,
    );
    expect(confirmed!.syncState, RemoteCompletionSyncState.synced);
    expect(confirmed.completionState, RemoteCompletionState.confirmedRemote);
    expect(confirmed.remoteCompletedByUserId, 'remote-user-1');

    final noOp = await repository.createCompletionSyncMetadata(
      localItemId: seed.itemId,
      localPackId: seed.packId,
      remoteItemId: 'remote-item-1',
      remotePackId: 'remote-pack-1',
      clientMutationId: 'completion-mutation-2',
    );
    expect(await repository.markCompletionNoOp(noOp.id), isTrue);
    expect(
      (await db.reminderDao.getRemoteCompletionSyncMetadataById(
        noOp.id,
      ))!.completionState,
      RemoteCompletionState.noOp,
    );

    final conflict = await repository.createCompletionSyncMetadata(
      localItemId: seed.itemId,
      localPackId: seed.packId,
      remoteItemId: 'remote-item-1',
      remotePackId: 'remote-pack-1',
      clientMutationId: 'completion-mutation-3',
    );
    expect(
      await repository.markCompletionConflict(conflict.id, error: 'archived'),
      isTrue,
    );
    final conflictRow = await db.reminderDao
        .getRemoteCompletionSyncMetadataById(conflict.id);
    expect(conflictRow!.completionState, RemoteCompletionState.conflict);
    expect(conflictRow.lastSyncError, 'archived');
  });

  test('sync outbox supports pending mutation lifecycle locally', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final seed = await _seedRemoteSyncLocalData(db);
    final repository = RemoteSyncRepository(
      db.reminderDao,
      clock: () => DateTime(2026, 6, 20, 10),
    );

    final complete = await repository.enqueuePendingMutation(
      localPackId: seed.packId,
      remotePackId: 'remote-pack-1',
      localEntityType: 'item',
      localEntityId: seed.itemId,
      remoteEntityId: 'remote-item-1',
      actionType: SyncOutboxActionType.completeItem,
      payloadJson: '{"action":"complete"}',
      clientMutationId: 'outbox-complete-1',
      actorLocalUserId: AppDatabase.defaultHostUserId,
      actorRemoteUserId: 'remote-user-host',
    );
    final undo = await repository.enqueuePendingMutation(
      localPackId: seed.packId,
      remotePackId: 'remote-pack-1',
      localEntityType: 'item',
      localEntityId: seed.itemId,
      remoteEntityId: 'remote-item-1',
      actionType: SyncOutboxActionType.undoItem,
      payloadJson: '{"action":"undo"}',
      clientMutationId: 'outbox-undo-1',
      actorLocalUserId: AppDatabase.defaultHostUserId,
      actorRemoteUserId: 'remote-user-host',
    );

    expect(complete.actionType, SyncOutboxActionType.completeItem);
    expect(undo.actionType, SyncOutboxActionType.undoItem);
    expect(await repository.getPendingMutations(), hasLength(2));
    expect(
      await repository.watchPendingMutationsForPack(seed.packId).first,
      hasLength(2),
    );

    await expectLater(
      repository.enqueuePendingMutation(
        localPackId: seed.packId,
        localEntityType: 'item',
        localEntityId: seed.itemId,
        actionType: SyncOutboxActionType.completeItem,
        payloadJson: '{}',
        clientMutationId: 'outbox-complete-1',
        actorLocalUserId: AppDatabase.defaultHostUserId,
      ),
      throwsA(isA<Exception>()),
    );

    expect(await repository.markMutationSyncing(complete.id), isTrue);
    var completeRow = await db.reminderDao.getSyncOutboxEntryById(complete.id);
    expect(completeRow!.status, SyncOutboxStatus.syncing);
    expect(completeRow.retryCount, 1);

    expect(
      await repository.markMutationFailed(complete.id, 'network timeout'),
      isTrue,
    );
    completeRow = await db.reminderDao.getSyncOutboxEntryById(complete.id);
    expect(completeRow!.status, SyncOutboxStatus.failed);
    expect(completeRow.lastError, 'network timeout');

    expect(await repository.markMutationSynced(complete.id), isTrue);
    completeRow = await db.reminderDao.getSyncOutboxEntryById(complete.id);
    expect(completeRow!.status, SyncOutboxStatus.synced);
    expect(completeRow.resolvedAt, isNotNull);

    expect(
      await repository.markMutationConflict(undo.id, error: 'archived'),
      isTrue,
    );
    var undoRow = await db.reminderDao.getSyncOutboxEntryById(undo.id);
    expect(undoRow!.status, SyncOutboxStatus.conflict);
    expect(undoRow.lastError, 'archived');

    final noOp = await repository.enqueuePendingMutation(
      localPackId: seed.packId,
      localEntityType: 'item',
      localEntityId: seed.itemId,
      actionType: SyncOutboxActionType.completeItem,
      payloadJson: '{}',
      clientMutationId: 'outbox-no-op-1',
      actorLocalUserId: AppDatabase.defaultHostUserId,
    );
    expect(await repository.markMutationNoOp(noOp.id), isTrue);
    expect(
      (await db.reminderDao.getSyncOutboxEntryById(noOp.id))!.status,
      SyncOutboxStatus.noOp,
    );

    final cancelled = await repository.enqueuePendingMutation(
      localPackId: seed.packId,
      localEntityType: 'item',
      localEntityId: seed.itemId,
      actionType: SyncOutboxActionType.undoItem,
      payloadJson: '{}',
      clientMutationId: 'outbox-cancel-1',
      actorLocalUserId: AppDatabase.defaultHostUserId,
    );
    expect(await repository.cancelMutation(cancelled.id), isTrue);
    final cancelledRow = await db.reminderDao.getSyncOutboxEntryById(
      cancelled.id,
    );
    expect(cancelledRow!.status, SyncOutboxStatus.cancelled);
    expect(cancelledRow.cancelledAt, isNotNull);
  });
}

Future<_RemoteSyncSeed> _seedRemoteSyncLocalData(AppDatabase db) async {
  final now = DateTime(2026, 6, 20).millisecondsSinceEpoch;
  final packId = await db
      .into(db.itemPacks)
      .insert(
        ItemPacksCompanion.insert(
          title: 'Remote foundation pack',
          packType: Value(ItemPackType.shared.name),
          hostUserId: const Value(AppDatabase.defaultHostUserId),
          createdAt: now,
          updatedAt: now,
        ),
      );
  final itemId = await db
      .into(db.items)
      .insert(
        ItemsCompanion.insert(
          packId: packId,
          title: 'Remote item',
          type: 'stateBased',
          stateExpectedAfterMinutes: const Value(1440),
          stateWarningAfterMinutes: const Value(1440),
          stateDangerAfterMinutes: const Value(2880),
          createdAt: now,
          updatedAt: now,
        ),
      );
  final actionId = await db
      .into(db.itemActionRecords)
      .insert(
        ItemActionRecordsCompanion.insert(
          itemId: itemId,
          actionType: 'done',
          actionDate: now,
          createdAt: now,
          updatedAt: now,
        ),
      );
  final completionId = await db
      .into(db.itemCompletions)
      .insert(
        ItemCompletionsCompanion.insert(
          itemId: itemId,
          packId: packId,
          itemActionRecordId: actionId,
          completedByUserId: AppDatabase.defaultHostUserId,
          completedAt: now,
          createdAt: now,
        ),
      );
  return _RemoteSyncSeed(
    packId: packId,
    itemId: itemId,
    completionId: completionId,
  );
}

class _RemoteSyncSeed {
  const _RemoteSyncSeed({
    required this.packId,
    required this.itemId,
    required this.completionId,
  });

  final int packId;
  final int itemId;
  final int completionId;
}
