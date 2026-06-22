import 'dart:convert';

import 'package:drift/drift.dart';

import '../domain/item_action_record.dart';
import '../domain/remote_sync.dart';
import '../domain/shared_pack.dart';
import 'identity_repository.dart';
import 'local/app_database.dart';
import 'local/reminder_dao.dart';
import 'remote_shared_pack_repository.dart';
import 'remote_snapshot_import_service.dart';

class RemoteBackedItemActionService {
  const RemoteBackedItemActionService({
    required ReminderDao dao,
    required IdentityRepository identityRepository,
    DateTime Function()? clock,
  }) : _dao = dao,
       _identityRepository = identityRepository,
       _clock = clock ?? DateTime.now;

  final ReminderDao _dao;
  final IdentityRepository _identityRepository;
  final DateTime Function() _clock;

  Future<RemoteBackedItemLocalActionResult> completeRemoteBackedItemLocally(
    int localItemId, {
    String? actorLocalUserId,
    DateTime? doneAt,
  }) async {
    final bundle = await _dao.getItemBundleById(localItemId);
    if (bundle == null) {
      return const RemoteBackedItemLocalActionResult(
        status: RemoteBackedItemLocalActionStatus.failed,
        message: 'missing_item',
      );
    }
    final mapping = await _resolveRemoteItem(bundle.item.id, bundle.pack.id);
    if (mapping.status != null) {
      return RemoteBackedItemLocalActionResult(
        status: mapping.status!,
        localPackId: bundle.pack.id,
        localItemId: bundle.item.id,
      );
    }
    final activeCompletion = await _dao.getActiveItemCompletionForItem(
      localItemId,
    );
    if (activeCompletion != null) {
      return RemoteBackedItemLocalActionResult(
        status: RemoteBackedItemLocalActionStatus.alreadyLocallyCompleted,
        localPackId: bundle.pack.id,
        localItemId: bundle.item.id,
        localCompletionId: activeCompletion.id,
      );
    }
    final actor = await _resolveActor(actorLocalUserId);
    final now = _clock();
    final actionDate = doneAt ?? now;
    final clientMutationId = _clientMutationId('complete', localItemId, now);
    final outbox = await _dao.attachedDatabase.transaction(() async {
      final actionRecordId = await _dao.insertItemActionRecord(
        ItemActionRecordsCompanion.insert(
          itemId: localItemId,
          actionType: ItemActionType.done.name,
          actionDate: actionDate.millisecondsSinceEpoch,
          payload: Value(
            ItemActionRecord.encodePayload({
              'remoteBackedPending': true,
              'syncActionType': SyncOutboxActionType.completeItem.storageValue,
              'clientMutationId': clientMutationId,
              'remoteItemId': mapping.remoteItemId,
              'remotePackId': mapping.remotePackId,
            }),
          ),
          createdAt: now.millisecondsSinceEpoch,
          updatedAt: now.millisecondsSinceEpoch,
        ),
      );
      final completionId = await _dao.insertItemCompletion(
        ItemCompletionsCompanion.insert(
          itemId: localItemId,
          packId: bundle.pack.id,
          itemActionRecordId: actionRecordId,
          completedByUserId: actor.id,
          completedAt: actionDate.millisecondsSinceEpoch,
          clientMutationId: Value(clientMutationId),
          createdAt: now.millisecondsSinceEpoch,
        ),
      );
      await _upsertPendingCompletionMetadata(
        localCompletionId: completionId,
        localItemId: localItemId,
        localPackId: bundle.pack.id,
        remoteItemId: mapping.remoteItemId!,
        remotePackId: mapping.remotePackId!,
        clientMutationId: clientMutationId,
        now: now,
      );
      await _dao.updateRemoteItemSyncMetadata(
        mapping.itemMetadata!.id,
        RemoteItemSyncMetadataCompanion(
          syncState: Value(RemoteItemSyncState.stale.storageValue),
          lastSyncError: const Value(null),
          updatedAt: Value(now.millisecondsSinceEpoch),
        ),
      );
      await _dao.updateRemotePackSyncMetadata(
        mapping.packMetadata!.id,
        RemotePackSyncMetadataCompanion(
          syncState: Value(RemotePackSyncState.stale.storageValue),
          lastSyncError: const Value(null),
          updatedAt: Value(now.millisecondsSinceEpoch),
        ),
      );
      final outboxEntry = await _enqueueMutation(
        actionType: SyncOutboxActionType.completeItem,
        localPackId: bundle.pack.id,
        remotePackId: mapping.remotePackId!,
        localEntityId: completionId,
        remoteItemId: mapping.remoteItemId!,
        localItemId: localItemId,
        localCompletionId: completionId,
        clientMutationId: clientMutationId,
        actor: actor,
        actionAt: actionDate,
      );
      return (outbox: outboxEntry, completionId: completionId);
    });
    return RemoteBackedItemLocalActionResult(
      status: RemoteBackedItemLocalActionStatus.completedPendingSync,
      localPackId: bundle.pack.id,
      localItemId: localItemId,
      localCompletionId: outbox.completionId,
      outboxId: outbox.outbox.id,
      clientMutationId: clientMutationId,
    );
  }

  Future<RemoteBackedItemLocalActionResult> undoRemoteBackedItemLocally(
    int localItemId, {
    String? actorLocalUserId,
    DateTime? undoneAt,
  }) async {
    final bundle = await _dao.getItemBundleById(localItemId);
    if (bundle == null) {
      return const RemoteBackedItemLocalActionResult(
        status: RemoteBackedItemLocalActionStatus.failed,
        message: 'missing_item',
      );
    }
    final mapping = await _resolveRemoteItem(bundle.item.id, bundle.pack.id);
    if (mapping.status != null) {
      return RemoteBackedItemLocalActionResult(
        status: mapping.status!,
        localPackId: bundle.pack.id,
        localItemId: bundle.item.id,
      );
    }
    final activeCompletion = await _dao.getActiveItemCompletionForItem(
      localItemId,
    );
    if (activeCompletion == null) {
      return RemoteBackedItemLocalActionResult(
        status: RemoteBackedItemLocalActionStatus.alreadyLocallyNotCompleted,
        localPackId: bundle.pack.id,
        localItemId: bundle.item.id,
      );
    }
    final actor = await _resolveActor(actorLocalUserId);
    final now = _clock();
    final actionDate = undoneAt ?? now;
    final clientMutationId = _clientMutationId('undo', localItemId, now);
    final outbox = await _dao.attachedDatabase.transaction(() async {
      await _dao.updateItemCompletionFields(
        activeCompletion.id,
        ItemCompletionsCompanion(
          undoneByUserId: Value(actor.id),
          undoneAt: Value(actionDate.millisecondsSinceEpoch),
        ),
      );
      await _upsertPendingCompletionMetadata(
        localCompletionId: activeCompletion.id,
        localItemId: localItemId,
        localPackId: bundle.pack.id,
        remoteItemId: mapping.remoteItemId!,
        remotePackId: mapping.remotePackId!,
        clientMutationId: clientMutationId,
        now: now,
      );
      await _dao.updateRemoteItemSyncMetadata(
        mapping.itemMetadata!.id,
        RemoteItemSyncMetadataCompanion(
          syncState: Value(RemoteItemSyncState.stale.storageValue),
          lastSyncError: const Value(null),
          updatedAt: Value(now.millisecondsSinceEpoch),
        ),
      );
      await _dao.updateRemotePackSyncMetadata(
        mapping.packMetadata!.id,
        RemotePackSyncMetadataCompanion(
          syncState: Value(RemotePackSyncState.stale.storageValue),
          lastSyncError: const Value(null),
          updatedAt: Value(now.millisecondsSinceEpoch),
        ),
      );
      return _enqueueMutation(
        actionType: SyncOutboxActionType.undoItem,
        localPackId: bundle.pack.id,
        remotePackId: mapping.remotePackId!,
        localEntityId: activeCompletion.id,
        remoteItemId: mapping.remoteItemId!,
        localItemId: localItemId,
        localCompletionId: activeCompletion.id,
        clientMutationId: clientMutationId,
        actor: actor,
        actionAt: actionDate,
      );
    });
    return RemoteBackedItemLocalActionResult(
      status: RemoteBackedItemLocalActionStatus.undoPendingSync,
      localPackId: bundle.pack.id,
      localItemId: localItemId,
      localCompletionId: activeCompletion.id,
      outboxId: outbox.id,
      clientMutationId: clientMutationId,
    );
  }

  Future<_RemoteItemMapping> _resolveRemoteItem(
    int localItemId,
    int localPackId,
  ) async {
    final packMetadata = await _dao.getRemotePackSyncMetadataForLocalPack(
      localPackId,
    );
    if (packMetadata == null ||
        packMetadata.syncKind != RemotePackSyncKind.remoteBacked) {
      return const _RemoteItemMapping(
        status: RemoteBackedItemLocalActionStatus.notRemoteBacked,
      );
    }
    if (packMetadata.syncState == RemotePackSyncState.accessLost ||
        packMetadata.syncState == RemotePackSyncState.removed ||
        packMetadata.currentUserRemoteStatus == RemoteUserStatus.removed) {
      return const _RemoteItemMapping(
        status: RemoteBackedItemLocalActionStatus.remoteAccessLost,
      );
    }
    var itemMetadata = await _dao.getRemoteItemSyncMetadataForLocalItem(
      localItemId,
    );
    String? remoteItemId = itemMetadata?.remoteItemId;
    if (remoteItemId == null) {
      final mapping = await _dao.getSyncMapping(
        localEntityType: RemoteSharedPackRepository.localEntityItem,
        localEntityId: localItemId,
        remoteTable: RemoteSharedPackRepository.remoteTableItems,
      );
      remoteItemId = mapping?.remoteEntityId;
      if (remoteItemId != null) {
        itemMetadata = await _dao.getRemoteItemSyncMetadataForRemoteItem(
          remoteItemId,
        );
      }
    }
    if (remoteItemId == null) {
      return const _RemoteItemMapping(
        status: RemoteBackedItemLocalActionStatus.missingRemoteMapping,
      );
    }
    if (itemMetadata == null) {
      return const _RemoteItemMapping(
        status: RemoteBackedItemLocalActionStatus.missingRemoteMapping,
      );
    }
    return _RemoteItemMapping(
      packMetadata: packMetadata,
      itemMetadata: itemMetadata,
      remotePackId: packMetadata.remotePackId,
      remoteItemId: remoteItemId,
    );
  }

  Future<void> _upsertPendingCompletionMetadata({
    required int localCompletionId,
    required int localItemId,
    required int localPackId,
    required String remoteItemId,
    required String remotePackId,
    required String clientMutationId,
    required DateTime now,
  }) async {
    final existing = await _dao
        .getRemoteCompletionSyncMetadataForLocalCompletion(localCompletionId);
    if (existing == null) {
      await _dao.insertRemoteCompletionSyncMetadata(
        RemoteCompletionSyncMetadataCompanion.insert(
          localCompletionId: Value(localCompletionId),
          localItemId: localItemId,
          localPackId: localPackId,
          remoteItemId: remoteItemId,
          remotePackId: remotePackId,
          syncState: RemoteCompletionSyncState.pendingPush.storageValue,
          completionState: RemoteCompletionState.pendingLocal.storageValue,
          clientMutationId: Value(clientMutationId),
          createdAt: now.millisecondsSinceEpoch,
          updatedAt: now.millisecondsSinceEpoch,
        ),
      );
      return;
    }
    await _dao.updateRemoteCompletionSyncMetadata(
      existing.id,
      RemoteCompletionSyncMetadataCompanion(
        syncState: Value(RemoteCompletionSyncState.pendingPush.storageValue),
        completionState: Value(RemoteCompletionState.pendingLocal.storageValue),
        clientMutationId: Value(clientMutationId),
        lastSyncError: const Value(null),
        updatedAt: Value(now.millisecondsSinceEpoch),
      ),
    );
  }

  Future<SyncOutboxEntry> _enqueueMutation({
    required SyncOutboxActionType actionType,
    required int localPackId,
    required String remotePackId,
    required int localEntityId,
    required String remoteItemId,
    required int localItemId,
    required int localCompletionId,
    required String clientMutationId,
    required LocalUser actor,
    required DateTime actionAt,
  }) async {
    final now = _clock();
    final id = await _dao.insertSyncOutbox(
      SyncOutboxCompanion.insert(
        localPackId: localPackId,
        remotePackId: Value(remotePackId),
        localEntityType: RemoteSnapshotImportService.localEntityCompletion,
        localEntityId: Value(localEntityId),
        remoteEntityId: Value(remoteItemId),
        actionType: actionType.storageValue,
        payloadJson: jsonEncode({
          'remotePackId': remotePackId,
          'remoteItemId': remoteItemId,
          'localPackId': localPackId,
          'localItemId': localItemId,
          'localCompletionId': localCompletionId,
          'clientMutationId': clientMutationId,
          'actorLocalUserId': actor.id,
          'actorRemoteUserId': actor.remoteUserId,
          'actionAt': actionAt.toIso8601String(),
        }),
        clientMutationId: clientMutationId,
        actorLocalUserId: actor.id,
        actorRemoteUserId: Value(actor.remoteUserId),
        createdAt: now.millisecondsSinceEpoch,
        updatedAt: now.millisecondsSinceEpoch,
        status: SyncOutboxStatus.pending.storageValue,
      ),
    );
    return (await _dao.getSyncOutboxEntryById(id))!;
  }

  Future<LocalUser> _resolveActor(String? actorLocalUserId) async {
    if (actorLocalUserId != null) {
      final user = await _dao.getLocalUserById(actorLocalUserId);
      if (user != null) {
        return user;
      }
    }
    return _identityRepository.getCurrentAppUser();
  }

  String _clientMutationId(String action, int localItemId, DateTime now) {
    return 'phase5d_${action}_${localItemId}_${now.microsecondsSinceEpoch}';
  }
}

class _RemoteItemMapping {
  const _RemoteItemMapping({
    this.status,
    this.packMetadata,
    this.itemMetadata,
    this.remotePackId,
    this.remoteItemId,
  });

  final RemoteBackedItemLocalActionStatus? status;
  final RemotePackSyncMetadataEntry? packMetadata;
  final RemoteItemSyncMetadataEntry? itemMetadata;
  final String? remotePackId;
  final String? remoteItemId;
}
