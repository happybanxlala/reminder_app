import 'dart:convert';

import 'package:drift/drift.dart';

import '../domain/remote_backed_recovery.dart';
import '../domain/remote_sync.dart';
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

    final remoteItemId = await _resolveRemoteItemId(mutation, payload);
    final localCompletionId =
        _intPayload(payload, 'localCompletionId') ?? mutation.localEntityId;
    if (remoteItemId == null || localCompletionId == null) {
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
        remoteItemId: remoteItemId,
        message: 'missing_remote_item_mapping',
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

    final resolution = switch (mutation.actionType) {
      SyncOutboxActionType.completeItem => await _retryComplete(
        mutation,
        localCompletionId: localCompletionId,
        remoteItemId: remoteItemId,
      ),
      SyncOutboxActionType.undoItem => await _retryUndo(
        mutation,
        localCompletionId: localCompletionId,
        remoteItemId: remoteItemId,
      ),
    };
    final updated = await _dao.getSyncOutboxEntryById(mutation.id);
    final afterStatus = updated?.status ?? SyncOutboxStatus.failed;
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
    if (completionId == null) {
      return;
    }
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

  Future<void> _markPackAndItemStale(SyncOutboxEntry mutation) async {
    final payload = _decodePayload(mutation.payloadJson);
    final localItemId = _intPayload(payload, 'localItemId');
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
}
