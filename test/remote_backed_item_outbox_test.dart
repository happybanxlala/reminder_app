import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reminder_app/features/reminders/data/identity_repository.dart';
import 'package:reminder_app/features/reminders/data/item_repository.dart';
import 'package:reminder_app/features/reminders/data/local/app_database.dart';
import 'package:reminder_app/features/reminders/data/remote_backed_item_action_service.dart';
import 'package:reminder_app/features/reminders/data/remote_backed_outbox_flush_service.dart';
import 'package:reminder_app/features/reminders/data/remote_shared_pack_models.dart';
import 'package:reminder_app/features/reminders/data/remote_snapshot_import_service.dart';
import 'package:reminder_app/features/reminders/domain/remote_sync.dart';
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
  _FakeRemoteClient({this.completeResult, this.undoResult});

  RemotePocResult<RemoteItemCompletionResult>? completeResult;
  RemotePocResult<RemoteItemUndoResult>? undoResult;
  int completeCalls = 0;
  int undoCalls = 0;

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
