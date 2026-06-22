import 'dart:convert';

import 'package:drift/drift.dart';

import '../domain/remote_sync.dart';
import 'local/app_database.dart';
import 'local/reminder_dao.dart';
import 'remote_shared_pack_models.dart';
import 'remote_shared_pack_repository.dart';
import 'remote_snapshot_import_service.dart';

abstract class RemoteBackedOutboxRemoteClient {
  Future<RemotePocResult<RemoteItemCompletionResult>> completeRemoteItemById(
    String remoteItemId,
  );

  Future<RemotePocResult<RemoteItemUndoResult>> undoRemoteItemById(
    String remoteItemId,
  );
}

class RemoteSharedPackOutboxRemoteClient
    implements RemoteBackedOutboxRemoteClient {
  const RemoteSharedPackOutboxRemoteClient(this._repository);

  final RemoteSharedPackRepository _repository;

  @override
  Future<RemotePocResult<RemoteItemCompletionResult>> completeRemoteItemById(
    String remoteItemId,
  ) {
    return _repository.completeRemoteItemByRemoteId(remoteItemId);
  }

  @override
  Future<RemotePocResult<RemoteItemUndoResult>> undoRemoteItemById(
    String remoteItemId,
  ) {
    return _repository.undoRemoteItemByRemoteId(remoteItemId);
  }
}

class RemoteBackedOutboxFlushService {
  const RemoteBackedOutboxFlushService({
    required ReminderDao dao,
    required RemoteBackedOutboxRemoteClient remoteClient,
    DateTime Function()? clock,
  }) : _dao = dao,
       _remoteClient = remoteClient,
       _clock = clock ?? DateTime.now;

  final ReminderDao _dao;
  final RemoteBackedOutboxRemoteClient _remoteClient;
  final DateTime Function() _clock;

  Future<RemoteBackedOutboxFlushResult>
  flushPendingRemoteBackedMutations() async {
    final pending = await _dao.listPendingSyncOutboxEntries();
    var processed = 0;
    var synced = 0;
    var noOp = 0;
    var conflict = 0;
    var failed = 0;
    RemoteBackedMutationResolution? lastResolution;

    for (final mutation in pending) {
      final resolution = await _processMutation(mutation);
      if (resolution == null) {
        continue;
      }
      processed++;
      lastResolution = resolution;
      switch (resolution) {
        case RemoteBackedMutationResolution.synced:
          synced++;
        case RemoteBackedMutationResolution.alreadyCompletedRemote ||
            RemoteBackedMutationResolution.alreadyNotCompletedRemote:
          noOp++;
        case RemoteBackedMutationResolution.permissionRevoked ||
            RemoteBackedMutationResolution.remoteAccessLost ||
            RemoteBackedMutationResolution.networkFailed ||
            RemoteBackedMutationResolution.remoteAuthRequired ||
            RemoteBackedMutationResolution.configMissing ||
            RemoteBackedMutationResolution.failed:
          failed++;
      }
    }

    return RemoteBackedOutboxFlushResult(
      processed: processed,
      synced: synced,
      noOp: noOp,
      conflict: conflict,
      failed: failed,
      lastResolution: lastResolution,
      message:
          'processed $processed, synced $synced, no_op $noOp, failed $failed',
    );
  }

  Future<RemoteBackedMutationResolution?> _processMutation(
    SyncOutboxEntry mutation,
  ) async {
    if (mutation.status != SyncOutboxStatus.pending) {
      return null;
    }
    final payload = _decodePayload(mutation.payloadJson);
    final remoteItemId = await _resolveRemoteItemId(mutation, payload);
    final localCompletionId =
        _intPayload(payload, 'localCompletionId') ?? mutation.localEntityId;
    if (remoteItemId == null || localCompletionId == null) {
      await _markFailed(
        mutation,
        RemoteBackedMutationResolution.failed,
        'missing_remote_item_mapping',
      );
      return RemoteBackedMutationResolution.failed;
    }

    await _dao.updateSyncOutboxEntry(
      mutation.id,
      SyncOutboxCompanion(
        status: Value(SyncOutboxStatus.syncing.storageValue),
        retryCount: Value(mutation.retryCount + 1),
        lastAttemptAt: Value(_clock().millisecondsSinceEpoch),
        updatedAt: Value(_clock().millisecondsSinceEpoch),
      ),
    );

    return switch (mutation.actionType) {
      SyncOutboxActionType.completeItem => _flushComplete(
        mutation,
        localCompletionId: localCompletionId,
        remoteItemId: remoteItemId,
      ),
      SyncOutboxActionType.undoItem => _flushUndo(
        mutation,
        localCompletionId: localCompletionId,
        remoteItemId: remoteItemId,
      ),
    };
  }

  Future<RemoteBackedMutationResolution> _flushComplete(
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
      if (resolution == RemoteBackedMutationResolution.remoteAccessLost ||
          resolution == RemoteBackedMutationResolution.permissionRevoked) {
        await _markPackAccessLost(mutation, result.failureReason?.name);
      }
      return resolution;
    }
    final completion = result.value!;
    await _dao.updateSyncOutboxEntry(
      mutation.id,
      SyncOutboxCompanion(
        status: Value(SyncOutboxStatus.synced.storageValue),
        resolvedAt: Value(_clock().millisecondsSinceEpoch),
        updatedAt: Value(_clock().millisecondsSinceEpoch),
      ),
    );
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

  Future<RemoteBackedMutationResolution> _flushUndo(
    SyncOutboxEntry mutation, {
    required int localCompletionId,
    required String remoteItemId,
  }) async {
    final result = await _remoteClient.undoRemoteItemById(remoteItemId);
    if (!result.isSuccess) {
      final resolution = _failureResolution(result.failureReason);
      await _markFailed(mutation, resolution, result.failureReason?.name);
      if (resolution == RemoteBackedMutationResolution.remoteAccessLost ||
          resolution == RemoteBackedMutationResolution.permissionRevoked) {
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
    await _dao.updateSyncOutboxEntry(
      mutation.id,
      SyncOutboxCompanion(
        status: Value(SyncOutboxStatus.synced.storageValue),
        resolvedAt: Value(_clock().millisecondsSinceEpoch),
        updatedAt: Value(_clock().millisecondsSinceEpoch),
      ),
    );
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

  Future<void> _markNoOp(
    SyncOutboxEntry mutation,
    int localCompletionId,
    String reason,
  ) async {
    await _dao.updateSyncOutboxEntry(
      mutation.id,
      SyncOutboxCompanion(
        status: Value(SyncOutboxStatus.noOp.storageValue),
        lastError: Value(reason),
        resolvedAt: Value(_clock().millisecondsSinceEpoch),
        updatedAt: Value(_clock().millisecondsSinceEpoch),
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
          updatedAt: Value(_clock().millisecondsSinceEpoch),
        ),
      );
    }
  }

  Future<void> _markFailed(
    SyncOutboxEntry mutation,
    RemoteBackedMutationResolution resolution,
    String? reason,
  ) async {
    await _dao.updateSyncOutboxEntry(
      mutation.id,
      SyncOutboxCompanion(
        status: Value(SyncOutboxStatus.failed.storageValue),
        lastError: Value(reason ?? resolution.name),
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
            lastSyncError: Value(reason ?? resolution.name),
            updatedAt: Value(_clock().millisecondsSinceEpoch),
          ),
        );
      }
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

  Map<String, Object?> _decodePayload(String source) {
    final decoded = jsonDecode(source);
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
