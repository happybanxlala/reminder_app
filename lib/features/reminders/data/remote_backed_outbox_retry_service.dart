import 'dart:convert';

import 'package:drift/drift.dart';

import '../domain/remote_backed_recovery.dart';
import '../domain/remote_sync.dart';
import '../domain/shared_pack.dart';
import 'local/app_database.dart';
import 'local/reminder_dao.dart';
import 'remote_backed_outbox_flush_service.dart';
import 'remote_shared_pack_models.dart';
import 'remote_shared_pack_repository.dart';
import 'remote_snapshot_import_service.dart';

class RemoteBackedOutboxRetryService {
  const RemoteBackedOutboxRetryService({
    required ReminderDao dao,
    required RemoteBackedOutboxRemoteClient remoteClient,
    DateTime Function()? clock,
  }) : _dao = dao,
       _remoteClient = remoteClient,
       _clock = clock ?? DateTime.now;

  final ReminderDao _dao;
  final RemoteBackedOutboxRemoteClient _remoteClient;
  final DateTime Function() _clock;

  Future<RemoteBackedRetrySummary> retryFailedMutation(int mutationId) async {
    final mutation = await _dao.getSyncOutboxEntryById(mutationId);
    if (mutation == null) {
      return const RemoteBackedRetrySummary(skippedCount: 1);
    }
    final result = await _retryMutationIfEligible(mutation);
    return _summaryFromResults([result]);
  }

  Future<RemoteBackedRetrySummary> retryFailedMutationsForPack(
    int localPackId,
  ) async {
    final entries = await _dao.listSyncOutboxEntries(
      statuses: const {SyncOutboxStatus.failed},
    );
    final results = <RemoteBackedRetryMutationResult>[];
    for (final entry in entries.where((e) => e.localPackId == localPackId)) {
      results.add(await _retryMutationIfEligible(entry));
    }
    return _summaryFromResults(results);
  }

  Future<RemoteBackedRetrySummary> retryAllRetryableFailedMutations() async {
    final entries = await _dao.listSyncOutboxEntries(
      statuses: const {SyncOutboxStatus.failed},
    );
    final results = <RemoteBackedRetryMutationResult>[];
    for (final entry in entries) {
      results.add(await _retryMutationIfEligible(entry));
    }
    return _summaryFromResults(results);
  }

  Future<RemoteBackedRetryMutationResult> _retryMutationIfEligible(
    SyncOutboxEntry mutation,
  ) async {
    final payload = _decodePayload(mutation.payloadJson);
    final localItemId = _intPayload(payload, 'localItemId');
    final packMetadata = await _dao.getRemotePackSyncMetadataForLocalPack(
      mutation.localPackId,
    );
    final recovery = RemoteBackedRecoveryClassifier.classifyMutation(
      mutation,
      packMetadata: packMetadata,
      localItemId: localItemId,
    );
    if (!recovery.canRetry) {
      return RemoteBackedRetryMutationResult(
        mutationId: mutation.id,
        actionType: mutation.actionType,
        result: RemoteBackedRecoveryResult.skipped,
        beforeStatus: mutation.status,
        afterStatus: mutation.status,
        localPackId: mutation.localPackId,
        localItemId: localItemId,
        remoteItemId: mutation.remoteEntityId,
        message: recovery.problem.name,
      );
    }

    final now = _clock().millisecondsSinceEpoch;
    await _dao.updateSyncOutboxEntry(
      mutation.id,
      SyncOutboxCompanion(
        status: Value(SyncOutboxStatus.syncing.storageValue),
        retryCount: Value(mutation.retryCount + 1),
        lastAttemptAt: Value(now),
        updatedAt: Value(now),
      ),
    );

    final resolution = await _retryRemoteMutation(mutation, payload);
    if (resolution == null) {
      await _markFailed(
        mutation,
        RemoteBackedMutationResolution.failed,
        'missing_remote_item_mapping',
      );
      final updated = await _dao.getSyncOutboxEntryById(mutation.id);
      return RemoteBackedRetryMutationResult(
        mutationId: mutation.id,
        actionType: mutation.actionType,
        result: RemoteBackedRecoveryResult.missingMapping,
        beforeStatus: mutation.status,
        afterStatus: updated?.status ?? SyncOutboxStatus.failed,
        localPackId: mutation.localPackId,
        localItemId: localItemId,
        remoteItemId: mutation.remoteEntityId,
        message: 'missing_remote_item_mapping',
      );
    }

    final updated = await _dao.getSyncOutboxEntryById(mutation.id);
    final afterStatus = updated?.status ?? SyncOutboxStatus.failed;
    final remoteItemId = await _resolveRemoteItemId(mutation, payload);
    return RemoteBackedRetryMutationResult(
      mutationId: mutation.id,
      actionType: mutation.actionType,
      result: _resultForResolution(resolution),
      beforeStatus: mutation.status,
      afterStatus: afterStatus,
      localPackId: mutation.localPackId,
      localItemId: localItemId,
      remoteItemId: remoteItemId,
      message: resolution.name,
    );
  }

  Future<RemoteBackedMutationResolution?> _retryRemoteMutation(
    SyncOutboxEntry mutation,
    Map<String, Object?> payload,
  ) async {
    return switch (mutation.actionType) {
      SyncOutboxActionType.createItem => await _retryCreateItem(
        mutation,
        payload,
      ),
      SyncOutboxActionType.updateItem => await _retryUpdateItem(
        mutation,
        payload,
      ),
      SyncOutboxActionType.archiveItem => await _retryArchiveItem(
        mutation,
        payload,
      ),
      SyncOutboxActionType.completeItem => await _retryCompletionMutation(
        mutation,
        payload,
        isUndo: false,
      ),
      SyncOutboxActionType.undoItem => await _retryCompletionMutation(
        mutation,
        payload,
        isUndo: true,
      ),
      SyncOutboxActionType.createResource => await _retryCreateResource(
        mutation,
        payload,
      ),
      SyncOutboxActionType.updateResource => await _retryUpdateResource(
        mutation,
        payload,
      ),
      SyncOutboxActionType.archiveResource => await _retryArchiveResource(
        mutation,
        payload,
      ),
      SyncOutboxActionType.resourceIncrement ||
      SyncOutboxActionType.resourceAdjust ||
      SyncOutboxActionType.resourceDecrement => await _retryResourceEvent(
        mutation,
        payload,
      ),
    };
  }

  Future<RemoteBackedMutationResolution?> _retryCompletionMutation(
    SyncOutboxEntry mutation,
    Map<String, Object?> payload, {
    required bool isUndo,
  }) async {
    final remoteItemId = await _resolveRemoteItemId(mutation, payload);
    final localCompletionId =
        _intPayload(payload, 'localCompletionId') ?? mutation.localEntityId;
    if (remoteItemId == null || localCompletionId == null) {
      return null;
    }
    return isUndo
        ? _retryUndo(
            mutation,
            localCompletionId: localCompletionId,
            remoteItemId: remoteItemId,
          )
        : _retryComplete(
            mutation,
            localCompletionId: localCompletionId,
            remoteItemId: remoteItemId,
          );
  }

  Future<RemoteBackedMutationResolution?> _retryCreateItem(
    SyncOutboxEntry mutation,
    Map<String, Object?> payload,
  ) async {
    final remotePackId =
        mutation.remotePackId ?? _stringPayload(payload, 'remotePackId');
    final localItemId =
        _intPayload(payload, 'localItemId') ?? mutation.localEntityId;
    final fields = _mapPayload(payload, 'fields');
    final title = _stringPayload(fields, 'title');
    if (remotePackId == null || localItemId == null || title == null) {
      return null;
    }
    final result = await _remoteClient.createRemoteItemForPack(
      remotePackId: remotePackId,
      title: title,
      note: _stringPayload(fields, 'note'),
      clientMutationId: mutation.clientMutationId,
    );
    if (!result.isSuccess) {
      final resolution = _failureResolution(result.failureReason);
      await _markFailed(mutation, resolution, result.failureReason?.name);
      if (_isAccessLostResolution(resolution)) {
        await _markPackAccessLost(mutation, result.failureReason?.name);
      }
      return resolution;
    }
    final created = result.value!;
    final now = _clock().millisecondsSinceEpoch;
    await _dao.attachedDatabase.transaction(() async {
      await _dao.upsertSyncMapping(
        SyncMappingsCompanion.insert(
          localEntityType: RemoteSharedPackRepository.localEntityItem,
          localEntityId: localItemId,
          remoteTable: RemoteSharedPackRepository.remoteTableItems,
          remoteEntityId: created.itemId,
          syncState: SyncMappingState.pushed.storageValue,
          lastPushedAt: Value(now),
          createdAt: now,
          updatedAt: now,
        ),
      );
      final metadata = await _dao.getRemoteItemSyncMetadataForLocalItem(
        localItemId,
      );
      if (metadata != null) {
        await _dao.updateRemoteItemSyncMetadata(
          metadata.id,
          RemoteItemSyncMetadataCompanion(
            remoteItemId: Value(created.itemId),
            remotePackId: Value(remotePackId),
            syncState: Value(RemoteItemSyncState.stale.storageValue),
            remoteStatus: const Value('active'),
            lastPushedAt: Value(now),
            lastSyncError: const Value(null),
            updatedAt: Value(now),
          ),
        );
      }
      await _dao.updateSyncOutboxEntry(
        mutation.id,
        SyncOutboxCompanion(
          remoteEntityId: Value(created.itemId),
          status: Value(SyncOutboxStatus.synced.storageValue),
          resolvedAt: Value(now),
          lastError: const Value(null),
          updatedAt: Value(now),
        ),
      );
    });
    await _markPackAndItemStale(mutation, localItemIdOverride: localItemId);
    return RemoteBackedMutationResolution.synced;
  }

  Future<RemoteBackedMutationResolution?> _retryCreateResource(
    SyncOutboxEntry mutation,
    Map<String, Object?> payload,
  ) async {
    final remotePackId =
        mutation.remotePackId ?? _stringPayload(payload, 'remotePackId');
    final localResourceId =
        _intPayload(payload, 'localResourceId') ?? mutation.localEntityId;
    final fields = _mapPayload(payload, 'fields');
    final title = _stringPayload(fields, 'title');
    final type = _stringPayload(fields, 'type');
    if (remotePackId == null ||
        localResourceId == null ||
        title == null ||
        type == null) {
      return null;
    }
    final result = await _remoteClient.createRemoteResourceForPack(
      remotePackId: remotePackId,
      title: title,
      description: _stringPayload(fields, 'description'),
      type: type,
      config: _mapPayload(fields, 'config'),
      clientMutationId: mutation.clientMutationId,
    );
    if (!result.isSuccess) {
      final resolution = _failureResolution(result.failureReason);
      await _markFailed(mutation, resolution, result.failureReason?.name);
      if (_isAccessLostResolution(resolution)) {
        await _markPackAccessLost(mutation, result.failureReason?.name);
      }
      return resolution;
    }
    final created = result.value!;
    final now = _clock().millisecondsSinceEpoch;
    await _dao.attachedDatabase.transaction(() async {
      await _dao.upsertSyncMapping(
        SyncMappingsCompanion.insert(
          localEntityType: RemoteSharedPackRepository.localEntityResource,
          localEntityId: localResourceId,
          remoteTable: RemoteSharedPackRepository.remoteTableResources,
          remoteEntityId: created.resourceId,
          syncState: SyncMappingState.pushed.storageValue,
          lastPushedAt: Value(now),
          createdAt: now,
          updatedAt: now,
        ),
      );
      final metadata = await _dao.getRemoteResourceSyncMetadataForLocalResource(
        localResourceId,
      );
      if (metadata != null) {
        await _dao.updateRemoteResourceSyncMetadata(
          metadata.id,
          RemoteResourceSyncMetadataCompanion(
            remoteResourceId: Value(created.resourceId),
            remotePackId: Value(remotePackId),
            syncState: Value(RemoteResourceSyncState.stale.storageValue),
            remoteStatus: const Value('active'),
            lastPushedAt: Value(now),
            lastSyncError: const Value(null),
            updatedAt: Value(now),
          ),
        );
      }
      await _dao.updateSyncOutboxEntry(
        mutation.id,
        SyncOutboxCompanion(
          remoteEntityId: Value(created.resourceId),
          status: Value(SyncOutboxStatus.synced.storageValue),
          resolvedAt: Value(now),
          lastError: const Value(null),
          updatedAt: Value(now),
        ),
      );
    });
    await _markPackAndResourceStale(
      mutation,
      localResourceIdOverride: localResourceId,
    );
    return RemoteBackedMutationResolution.synced;
  }

  Future<RemoteBackedMutationResolution?> _retryUpdateItem(
    SyncOutboxEntry mutation,
    Map<String, Object?> payload,
  ) async {
    final remoteItemId = await _resolveRemoteItemId(mutation, payload);
    final fields = _mapPayload(payload, 'fields');
    final title = _stringPayload(fields, 'title');
    if (remoteItemId == null || title == null) {
      return null;
    }
    final result = await _remoteClient.updateRemoteItemById(
      remoteItemId: remoteItemId,
      title: title,
      note: _stringPayload(fields, 'note'),
      assignedToUserId: _stringPayload(fields, 'assignedToUserId'),
      clientMutationId: mutation.clientMutationId,
    );
    if (!result.isSuccess) {
      final resolution = _failureResolution(result.failureReason);
      await _markFailed(mutation, resolution, result.failureReason?.name);
      if (_isAccessLostResolution(resolution)) {
        await _markPackAccessLost(mutation, result.failureReason?.name);
      }
      return resolution;
    }
    await _markItemMutationSynced(
      mutation,
      localItemId: _intPayload(payload, 'localItemId'),
      remoteStatus: 'active',
    );
    return RemoteBackedMutationResolution.synced;
  }

  Future<RemoteBackedMutationResolution?> _retryUpdateResource(
    SyncOutboxEntry mutation,
    Map<String, Object?> payload,
  ) async {
    final remoteResourceId = await _resolveRemoteResourceId(mutation, payload);
    final localResourceId = _intPayload(payload, 'localResourceId');
    final fields = _mapPayload(payload, 'fields');
    final title = _stringPayload(fields, 'title');
    if (remoteResourceId == null || title == null) {
      return null;
    }
    final result = await _remoteClient.updateRemoteResourceById(
      remoteResourceId: remoteResourceId,
      title: title,
      description: _stringPayload(fields, 'description'),
      config: _mapPayload(fields, 'config'),
      clientMutationId: mutation.clientMutationId,
    );
    if (!result.isSuccess) {
      final resolution = _failureResolution(result.failureReason);
      await _markFailed(mutation, resolution, result.failureReason?.name);
      if (_isAccessLostResolution(resolution)) {
        await _markPackAccessLost(mutation, result.failureReason?.name);
      }
      return resolution;
    }
    await _markResourceMutationSynced(
      mutation,
      localResourceId: localResourceId,
      remoteStatus: 'active',
    );
    return RemoteBackedMutationResolution.synced;
  }

  Future<RemoteBackedMutationResolution?> _retryArchiveResource(
    SyncOutboxEntry mutation,
    Map<String, Object?> payload,
  ) async {
    final remoteResourceId = await _resolveRemoteResourceId(mutation, payload);
    final localResourceId = _intPayload(payload, 'localResourceId');
    if (remoteResourceId == null) {
      return null;
    }
    final result = await _remoteClient.archiveRemoteResourceById(
      remoteResourceId: remoteResourceId,
      clientMutationId: mutation.clientMutationId,
    );
    if (!result.isSuccess) {
      final resolution = _failureResolution(result.failureReason);
      await _markFailed(mutation, resolution, result.failureReason?.name);
      if (_isAccessLostResolution(resolution)) {
        await _markPackAccessLost(mutation, result.failureReason?.name);
      }
      return resolution;
    }
    await _markResourceMutationSynced(
      mutation,
      localResourceId: localResourceId,
      remoteStatus: 'archived',
      resourceState: RemoteResourceSyncState.archived,
    );
    return RemoteBackedMutationResolution.synced;
  }

  Future<RemoteBackedMutationResolution?> _retryResourceEvent(
    SyncOutboxEntry mutation,
    Map<String, Object?> payload,
  ) async {
    final remoteResourceId = await _resolveRemoteResourceId(mutation, payload);
    final localResourceId = _intPayload(payload, 'localResourceId');
    final event = _mapPayload(payload, 'event');
    final changeType = _stringPayload(event, 'changeType');
    if (remoteResourceId == null || changeType == null) {
      return null;
    }
    final result = await _remoteClient.applyRemoteResourceEventById(
      remoteResourceId: remoteResourceId,
      changeType: changeType,
      deltaValue: _intPayload(event, 'deltaValue'),
      newValue: _intPayload(event, 'newValue'),
      unit: _stringPayload(event, 'unit'),
      clientMutationId: mutation.clientMutationId,
      metadata: _mapPayload(event, 'metadata'),
    );
    if (!result.isSuccess) {
      final resolution = _failureResolution(result.failureReason);
      await _markFailed(mutation, resolution, result.failureReason?.name);
      if (_isAccessLostResolution(resolution)) {
        await _markPackAccessLost(mutation, result.failureReason?.name);
      }
      return resolution;
    }
    await _markResourceMutationSynced(
      mutation,
      localResourceId: localResourceId,
      remoteStatus: 'active',
    );
    return RemoteBackedMutationResolution.synced;
  }

  Future<RemoteBackedMutationResolution?> _retryArchiveItem(
    SyncOutboxEntry mutation,
    Map<String, Object?> payload,
  ) async {
    final remoteItemId = await _resolveRemoteItemId(mutation, payload);
    if (remoteItemId == null) {
      return null;
    }
    final result = await _remoteClient.archiveRemoteItemById(
      remoteItemId: remoteItemId,
      clientMutationId: mutation.clientMutationId,
    );
    if (!result.isSuccess) {
      final resolution = _failureResolution(result.failureReason);
      await _markFailed(mutation, resolution, result.failureReason?.name);
      if (_isAccessLostResolution(resolution)) {
        await _markPackAccessLost(mutation, result.failureReason?.name);
      }
      return resolution;
    }
    await _markItemMutationSynced(
      mutation,
      localItemId: _intPayload(payload, 'localItemId'),
      remoteStatus: 'archived',
      itemState: RemoteItemSyncState.archived,
    );
    return RemoteBackedMutationResolution.synced;
  }

  Future<RemoteBackedMutationResolution> _retryComplete(
    SyncOutboxEntry mutation, {
    required int localCompletionId,
    required String remoteItemId,
  }) async {
    final result = await _remoteClient.completeRemoteItemById(remoteItemId);
    if (!result.isSuccess) {
      if (result.failureReason ==
              RemoteSharedPackFailureReason.remoteItemAlreadyCompleted &&
          result.error is RemoteItemCompletionResult) {
        await _markNoOp(
          mutation,
          localCompletionId,
          'already_completed_remote',
        );
        await _markPackAndItemStale(mutation);
        return RemoteBackedMutationResolution.alreadyCompletedRemote;
      }
      final resolution = _failureResolution(result.failureReason);
      await _markFailed(mutation, resolution, result.failureReason?.name);
      if (_isAccessLostResolution(resolution)) {
        await _markPackAccessLost(mutation, result.failureReason?.name);
      }
      return resolution;
    }

    final completion = result.value!;
    await _markSynced(mutation);
    final metadata = await _dao
        .getRemoteCompletionSyncMetadataForLocalCompletion(localCompletionId);
    if (metadata != null) {
      await _dao.updateRemoteCompletionSyncMetadata(
        metadata.id,
        RemoteCompletionSyncMetadataCompanion(
          remoteCompletionId: Value(completion.completionId),
          remoteCompletedByUserId: Value(completion.completedByUserId),
          remoteCompletedAt: Value(
            completion.completedAt.millisecondsSinceEpoch,
          ),
          syncState: Value(RemoteCompletionSyncState.synced.storageValue),
          completionState: Value(
            RemoteCompletionState.confirmedRemote.storageValue,
          ),
          lastPushedAt: Value(_clock().millisecondsSinceEpoch),
          lastSyncError: const Value(null),
          updatedAt: Value(_clock().millisecondsSinceEpoch),
        ),
      );
    }
    await _markPackAndItemStale(mutation);
    return RemoteBackedMutationResolution.synced;
  }

  Future<RemoteBackedMutationResolution> _retryUndo(
    SyncOutboxEntry mutation, {
    required int localCompletionId,
    required String remoteItemId,
  }) async {
    final result = await _remoteClient.undoRemoteItemById(remoteItemId);
    if (!result.isSuccess) {
      final resolution = _failureResolution(result.failureReason);
      await _markFailed(mutation, resolution, result.failureReason?.name);
      if (_isAccessLostResolution(resolution)) {
        await _markPackAccessLost(mutation, result.failureReason?.name);
      }
      return resolution;
    }

    final undo = result.value!;
    if (undo.status == RemoteItemUndoStatus.alreadyNotCompleted) {
      await _markNoOp(mutation, localCompletionId, 'already_not_completed');
      await _markPackAndItemStale(mutation);
      return RemoteBackedMutationResolution.alreadyNotCompletedRemote;
    }

    await _markSynced(mutation);
    final metadata = await _dao
        .getRemoteCompletionSyncMetadataForLocalCompletion(localCompletionId);
    if (metadata != null) {
      await _dao.updateRemoteCompletionSyncMetadata(
        metadata.id,
        RemoteCompletionSyncMetadataCompanion(
          remoteCompletionId: Value(
            undo.completionId ?? metadata.remoteCompletionId,
          ),
          remoteUndoneByUserId: Value(undo.undoneByUserId),
          remoteUndoneAt: Value(undo.undoneAt?.millisecondsSinceEpoch),
          syncState: Value(RemoteCompletionSyncState.synced.storageValue),
          completionState: Value(
            RemoteCompletionState.undoneRemote.storageValue,
          ),
          lastPushedAt: Value(_clock().millisecondsSinceEpoch),
          lastSyncError: const Value(null),
          updatedAt: Value(_clock().millisecondsSinceEpoch),
        ),
      );
    }
    await _markPackAndItemStale(mutation);
    return RemoteBackedMutationResolution.synced;
  }

  Future<void> _markSynced(SyncOutboxEntry mutation) {
    final now = _clock().millisecondsSinceEpoch;
    return _dao.updateSyncOutboxEntry(
      mutation.id,
      SyncOutboxCompanion(
        status: Value(SyncOutboxStatus.synced.storageValue),
        resolvedAt: Value(now),
        lastError: const Value(null),
        updatedAt: Value(now),
      ),
    );
  }

  Future<void> _markNoOp(
    SyncOutboxEntry mutation,
    int localCompletionId,
    String reason,
  ) async {
    final now = _clock().millisecondsSinceEpoch;
    await _dao.updateSyncOutboxEntry(
      mutation.id,
      SyncOutboxCompanion(
        status: Value(SyncOutboxStatus.noOp.storageValue),
        lastError: Value(reason),
        resolvedAt: Value(now),
        updatedAt: Value(now),
      ),
    );
    final metadata = await _dao
        .getRemoteCompletionSyncMetadataForLocalCompletion(localCompletionId);
    if (metadata != null) {
      await _dao.updateRemoteCompletionSyncMetadata(
        metadata.id,
        RemoteCompletionSyncMetadataCompanion(
          syncState: Value(RemoteCompletionSyncState.noOp.storageValue),
          completionState: Value(RemoteCompletionState.noOp.storageValue),
          lastSyncError: Value(reason),
          updatedAt: Value(now),
        ),
      );
    }
  }

  Future<void> _markItemMutationSynced(
    SyncOutboxEntry mutation, {
    required int? localItemId,
    required String remoteStatus,
    RemoteItemSyncState itemState = RemoteItemSyncState.stale,
  }) async {
    final now = _clock().millisecondsSinceEpoch;
    await _dao.updateSyncOutboxEntry(
      mutation.id,
      SyncOutboxCompanion(
        status: Value(SyncOutboxStatus.synced.storageValue),
        resolvedAt: Value(now),
        lastError: const Value(null),
        updatedAt: Value(now),
      ),
    );
    if (localItemId != null) {
      final metadata = await _dao.getRemoteItemSyncMetadataForLocalItem(
        localItemId,
      );
      if (metadata != null) {
        await _dao.updateRemoteItemSyncMetadata(
          metadata.id,
          RemoteItemSyncMetadataCompanion(
            syncState: Value(itemState.storageValue),
            remoteStatus: Value(remoteStatus),
            lastPushedAt: Value(now),
            lastSyncError: const Value(null),
            archivedAt: itemState == RemoteItemSyncState.archived
                ? Value(now)
                : const Value.absent(),
            updatedAt: Value(now),
          ),
        );
      }
    }
    await _markPackAndItemStale(mutation, localItemIdOverride: localItemId);
  }

  Future<void> _markResourceMutationSynced(
    SyncOutboxEntry mutation, {
    required int? localResourceId,
    required String remoteStatus,
    RemoteResourceSyncState resourceState = RemoteResourceSyncState.stale,
  }) async {
    final now = _clock().millisecondsSinceEpoch;
    await _dao.updateSyncOutboxEntry(
      mutation.id,
      SyncOutboxCompanion(
        status: Value(SyncOutboxStatus.synced.storageValue),
        resolvedAt: Value(now),
        lastError: const Value(null),
        updatedAt: Value(now),
      ),
    );
    if (localResourceId != null) {
      final metadata = await _dao.getRemoteResourceSyncMetadataForLocalResource(
        localResourceId,
      );
      if (metadata != null) {
        await _dao.updateRemoteResourceSyncMetadata(
          metadata.id,
          RemoteResourceSyncMetadataCompanion(
            syncState: Value(resourceState.storageValue),
            remoteStatus: Value(remoteStatus),
            lastPushedAt: Value(now),
            lastSyncError: const Value(null),
            archivedAt: resourceState == RemoteResourceSyncState.archived
                ? Value(now)
                : const Value.absent(),
            updatedAt: Value(now),
          ),
        );
      }
    }
    await _markPackAndResourceStale(
      mutation,
      localResourceIdOverride: localResourceId,
    );
  }

  Future<void> _markFailed(
    SyncOutboxEntry mutation,
    RemoteBackedMutationResolution resolution,
    String? reason,
  ) async {
    final safeReason = reason ?? resolution.name;
    await _dao.updateSyncOutboxEntry(
      mutation.id,
      SyncOutboxCompanion(
        status: Value(SyncOutboxStatus.failed.storageValue),
        lastError: Value(safeReason),
        updatedAt: Value(_clock().millisecondsSinceEpoch),
      ),
    );
    final payload = _decodePayload(mutation.payloadJson);
    final completionId =
        _intPayload(payload, 'localCompletionId') ?? mutation.localEntityId;
    if (completionId != null) {
      final metadata = await _dao
          .getRemoteCompletionSyncMetadataForLocalCompletion(completionId);
      if (metadata != null) {
        await _dao.updateRemoteCompletionSyncMetadata(
          metadata.id,
          RemoteCompletionSyncMetadataCompanion(
            syncState: Value(RemoteCompletionSyncState.failed.storageValue),
            completionState: Value(RemoteCompletionState.failed.storageValue),
            lastSyncError: Value(safeReason),
            updatedAt: Value(_clock().millisecondsSinceEpoch),
          ),
        );
      }
    }
    final localResourceId =
        _intPayload(payload, 'localResourceId') ??
        (mutation.localEntityType ==
                RemoteSharedPackRepository.localEntityResource
            ? mutation.localEntityId
            : null);
    if (localResourceId != null) {
      final metadata = await _dao.getRemoteResourceSyncMetadataForLocalResource(
        localResourceId,
      );
      if (metadata != null) {
        await _dao.updateRemoteResourceSyncMetadata(
          metadata.id,
          RemoteResourceSyncMetadataCompanion(
            syncState: Value(RemoteResourceSyncState.failed.storageValue),
            lastSyncError: Value(safeReason),
            updatedAt: Value(_clock().millisecondsSinceEpoch),
          ),
        );
      }
    }
  }

  Future<void> _markPackAndItemStale(
    SyncOutboxEntry mutation, {
    int? localItemIdOverride,
  }) async {
    final payload = _decodePayload(mutation.payloadJson);
    final localItemId =
        localItemIdOverride ?? _intPayload(payload, 'localItemId');
    if (localItemId != null) {
      final itemMetadata = await _dao.getRemoteItemSyncMetadataForLocalItem(
        localItemId,
      );
      if (itemMetadata != null) {
        await _dao.updateRemoteItemSyncMetadata(
          itemMetadata.id,
          RemoteItemSyncMetadataCompanion(
            syncState: Value(RemoteItemSyncState.stale.storageValue),
            updatedAt: Value(_clock().millisecondsSinceEpoch),
          ),
        );
      }
    }
    final packMetadata = await _dao.getRemotePackSyncMetadataForLocalPack(
      mutation.localPackId,
    );
    if (packMetadata != null) {
      await _dao.updateRemotePackSyncMetadata(
        packMetadata.id,
        RemotePackSyncMetadataCompanion(
          syncState: Value(RemotePackSyncState.stale.storageValue),
          updatedAt: Value(_clock().millisecondsSinceEpoch),
        ),
      );
    }
  }

  Future<void> _markPackAndResourceStale(
    SyncOutboxEntry mutation, {
    int? localResourceIdOverride,
  }) async {
    final payload = _decodePayload(mutation.payloadJson);
    final localResourceId =
        localResourceIdOverride ?? _intPayload(payload, 'localResourceId');
    if (localResourceId != null) {
      final resourceMetadata = await _dao
          .getRemoteResourceSyncMetadataForLocalResource(localResourceId);
      if (resourceMetadata != null) {
        await _dao.updateRemoteResourceSyncMetadata(
          resourceMetadata.id,
          RemoteResourceSyncMetadataCompanion(
            syncState: Value(RemoteResourceSyncState.stale.storageValue),
            updatedAt: Value(_clock().millisecondsSinceEpoch),
          ),
        );
      }
    }
    final packMetadata = await _dao.getRemotePackSyncMetadataForLocalPack(
      mutation.localPackId,
    );
    if (packMetadata != null) {
      await _dao.updateRemotePackSyncMetadata(
        packMetadata.id,
        RemotePackSyncMetadataCompanion(
          syncState: Value(RemotePackSyncState.stale.storageValue),
          updatedAt: Value(_clock().millisecondsSinceEpoch),
        ),
      );
    }
  }

  Future<void> _markPackAccessLost(
    SyncOutboxEntry mutation,
    String? reason,
  ) async {
    final packMetadata = await _dao.getRemotePackSyncMetadataForLocalPack(
      mutation.localPackId,
    );
    if (packMetadata == null) {
      return;
    }
    await _dao.updateRemotePackSyncMetadata(
      packMetadata.id,
      RemotePackSyncMetadataCompanion(
        syncState: Value(RemotePackSyncState.accessLost.storageValue),
        currentUserRemoteStatus: Value(RemoteUserStatus.removed.storageValue),
        lastSyncError: Value(reason),
        accessLostAt: Value(_clock().millisecondsSinceEpoch),
        updatedAt: Value(_clock().millisecondsSinceEpoch),
      ),
    );
  }

  Future<String?> _resolveRemoteItemId(
    SyncOutboxEntry mutation,
    Map<String, Object?> payload,
  ) async {
    if (mutation.remoteEntityId != null) {
      return mutation.remoteEntityId;
    }
    final payloadRemoteItemId = payload['remoteItemId'];
    if (payloadRemoteItemId is String && payloadRemoteItemId.isNotEmpty) {
      return payloadRemoteItemId;
    }
    final localItemId = _intPayload(payload, 'localItemId');
    if (localItemId != null) {
      final itemMetadata = await _dao.getRemoteItemSyncMetadataForLocalItem(
        localItemId,
      );
      if (itemMetadata != null) {
        return itemMetadata.remoteItemId;
      }
      final mapping = await _dao.getSyncMapping(
        localEntityType: RemoteSharedPackRepository.localEntityItem,
        localEntityId: localItemId,
        remoteTable: RemoteSharedPackRepository.remoteTableItems,
      );
      return mapping?.remoteEntityId;
    }
    final completionId = mutation.localEntityId;
    if (completionId != null &&
        mutation.localEntityType ==
            RemoteSnapshotImportService.localEntityCompletion) {
      final metadata = await _dao
          .getRemoteCompletionSyncMetadataForLocalCompletion(completionId);
      return metadata?.remoteItemId;
    }
    return null;
  }

  Future<String?> _resolveRemoteResourceId(
    SyncOutboxEntry mutation,
    Map<String, Object?> payload,
  ) async {
    if (mutation.remoteEntityId != null) {
      return mutation.remoteEntityId;
    }
    final payloadRemoteResourceId = payload['remoteResourceId'];
    if (payloadRemoteResourceId is String &&
        payloadRemoteResourceId.isNotEmpty) {
      return payloadRemoteResourceId;
    }
    final localResourceId = _intPayload(payload, 'localResourceId');
    if (localResourceId != null) {
      final resourceMetadata = await _dao
          .getRemoteResourceSyncMetadataForLocalResource(localResourceId);
      if (resourceMetadata != null) {
        return resourceMetadata.remoteResourceId;
      }
      final mapping = await _dao.getSyncMapping(
        localEntityType: RemoteSharedPackRepository.localEntityResource,
        localEntityId: localResourceId,
        remoteTable: RemoteSharedPackRepository.remoteTableResources,
      );
      return mapping?.remoteEntityId;
    }
    return null;
  }

  RemoteBackedMutationResolution _failureResolution(
    RemoteSharedPackFailureReason? reason,
  ) {
    return switch (reason) {
      RemoteSharedPackFailureReason.supabaseConfigMissing =>
        RemoteBackedMutationResolution.configMissing,
      RemoteSharedPackFailureReason.remoteAuthRequired =>
        RemoteBackedMutationResolution.remoteAuthRequired,
      RemoteSharedPackFailureReason.remoteNetworkFailed =>
        RemoteBackedMutationResolution.networkFailed,
      RemoteSharedPackFailureReason.remoteRlsRejected ||
      RemoteSharedPackFailureReason.localUserNotPackMember =>
        RemoteBackedMutationResolution.remoteAccessLost,
      RemoteSharedPackFailureReason.remoteInviteNotHost =>
        RemoteBackedMutationResolution.permissionRevoked,
      _ => RemoteBackedMutationResolution.failed,
    };
  }

  bool _isAccessLostResolution(RemoteBackedMutationResolution resolution) {
    return resolution == RemoteBackedMutationResolution.remoteAccessLost ||
        resolution == RemoteBackedMutationResolution.permissionRevoked;
  }

  RemoteBackedRecoveryResult _resultForResolution(
    RemoteBackedMutationResolution resolution,
  ) {
    return switch (resolution) {
      RemoteBackedMutationResolution.synced =>
        RemoteBackedRecoveryResult.synced,
      RemoteBackedMutationResolution.alreadyCompletedRemote ||
      RemoteBackedMutationResolution.alreadyNotCompletedRemote =>
        RemoteBackedRecoveryResult.noOp,
      RemoteBackedMutationResolution.remoteAccessLost ||
      RemoteBackedMutationResolution.permissionRevoked =>
        RemoteBackedRecoveryResult.accessLost,
      RemoteBackedMutationResolution.configMissing ||
      RemoteBackedMutationResolution.remoteAuthRequired ||
      RemoteBackedMutationResolution.networkFailed ||
      RemoteBackedMutationResolution.failed =>
        RemoteBackedRecoveryResult.failed,
    };
  }

  RemoteBackedRetrySummary _summaryFromResults(
    List<RemoteBackedRetryMutationResult> results,
  ) {
    var retried = 0;
    var synced = 0;
    var failed = 0;
    var noOp = 0;
    var skipped = 0;
    var accessLost = 0;
    var needsRefresh = 0;
    for (final result in results) {
      switch (result.result) {
        case RemoteBackedRecoveryResult.synced:
          retried++;
          synced++;
          needsRefresh++;
        case RemoteBackedRecoveryResult.noOp:
          retried++;
          noOp++;
          needsRefresh++;
        case RemoteBackedRecoveryResult.failed:
        case RemoteBackedRecoveryResult.missingMapping:
          retried++;
          failed++;
        case RemoteBackedRecoveryResult.accessLost:
          if (result.beforeStatus == SyncOutboxStatus.failed) {
            retried++;
          }
          accessLost++;
        case RemoteBackedRecoveryResult.skipped:
          skipped++;
          if (result.message == RemoteBackedSyncProblem.accessLost.name) {
            accessLost++;
          }
        case RemoteBackedRecoveryResult.retried:
          retried++;
      }
    }
    return RemoteBackedRetrySummary(
      processedCount: results.length,
      retriedCount: retried,
      syncedCount: synced,
      failedCount: failed,
      noOpCount: noOp,
      skippedCount: skipped,
      accessLostCount: accessLost,
      needsRefreshCount: needsRefresh,
      results: results,
    );
  }

  Map<String, Object?> _decodePayload(String source) {
    final Object? decoded;
    try {
      decoded = jsonDecode(source);
    } catch (_) {
      return const {};
    }
    if (decoded is Map<String, Object?>) {
      return decoded;
    }
    if (decoded is Map<String, dynamic>) {
      return Map<String, Object?>.from(decoded);
    }
    return const {};
  }

  int? _intPayload(Map<String, Object?> payload, String key) {
    final value = payload[key];
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    return null;
  }

  String? _stringPayload(Map<String, Object?> payload, String key) {
    final value = payload[key];
    if (value is String && value.isNotEmpty) {
      return value;
    }
    return null;
  }

  Map<String, Object?> _mapPayload(Map<String, Object?> payload, String key) {
    final value = payload[key];
    if (value is Map<String, Object?>) {
      return value;
    }
    if (value is Map<String, dynamic>) {
      return Map<String, Object?>.from(value);
    }
    if (value is Map) {
      return Map<String, Object?>.from(value);
    }
    return const {};
  }
}
