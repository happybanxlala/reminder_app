import 'dart:convert';

import 'package:drift/drift.dart';

import '../domain/remote_sync.dart';
import '../domain/shared_pack.dart';
import 'local/app_database.dart';
import 'local/reminder_dao.dart';
import 'remote_shared_pack_models.dart';
import 'remote_shared_pack_repository.dart';
import 'remote_snapshot_import_service.dart';

abstract class RemoteBackedOutboxRemoteClient {
  Future<RemotePocResult<RemoteItemCreateResult>> createRemoteItemForPack({
    required String remotePackId,
    required String title,
    String? note,
    String? clientMutationId,
  });

  Future<RemotePocResult<RemoteItemMutationResult>> updateRemoteItemById({
    required String remoteItemId,
    required String title,
    String? note,
    String? assignedToUserId,
    String? clientMutationId,
  });

  Future<RemotePocResult<RemoteItemMutationResult>> archiveRemoteItemById({
    required String remoteItemId,
    String? clientMutationId,
  });

  Future<RemotePocResult<RemoteResourceCreateResult>>
  createRemoteResourceForPack({
    required String remotePackId,
    required String title,
    String? description,
    required String type,
    Map<String, Object?>? config,
    String? clientMutationId,
  }) {
    return Future.value(
      const RemotePocResult<RemoteResourceCreateResult>.failure(
        RemoteSharedPackFailureReason.remoteUnknownFailure,
      ),
    );
  }

  Future<RemotePocResult<RemoteResourceMutationResult>>
  updateRemoteResourceById({
    required String remoteResourceId,
    required String title,
    String? description,
    Map<String, Object?>? config,
    String? clientMutationId,
  }) {
    return Future.value(
      const RemotePocResult<RemoteResourceMutationResult>.failure(
        RemoteSharedPackFailureReason.remoteUnknownFailure,
      ),
    );
  }

  Future<RemotePocResult<RemoteResourceMutationResult>>
  archiveRemoteResourceById({
    required String remoteResourceId,
    String? clientMutationId,
  }) {
    return Future.value(
      const RemotePocResult<RemoteResourceMutationResult>.failure(
        RemoteSharedPackFailureReason.remoteUnknownFailure,
      ),
    );
  }

  Future<RemotePocResult<RemoteResourceEventResult>>
  applyRemoteResourceEventById({
    required String remoteResourceId,
    required String changeType,
    int? deltaValue,
    int? newValue,
    String? unit,
    String? clientMutationId,
    Map<String, Object?>? metadata,
  }) {
    return Future.value(
      const RemotePocResult<RemoteResourceEventResult>.failure(
        RemoteSharedPackFailureReason.remoteUnknownFailure,
      ),
    );
  }

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
  Future<RemotePocResult<RemoteItemCreateResult>> createRemoteItemForPack({
    required String remotePackId,
    required String title,
    String? note,
    String? clientMutationId,
  }) {
    return _repository.createRemoteItemForPack(
      remotePackId: remotePackId,
      title: title,
      note: note,
      clientMutationId: clientMutationId,
    );
  }

  @override
  Future<RemotePocResult<RemoteItemMutationResult>> updateRemoteItemById({
    required String remoteItemId,
    required String title,
    String? note,
    String? assignedToUserId,
    String? clientMutationId,
  }) {
    return _repository.updateRemoteItemByRemoteId(
      remoteItemId: remoteItemId,
      title: title,
      note: note,
      assignedToUserId: assignedToUserId,
      clientMutationId: clientMutationId,
    );
  }

  @override
  Future<RemotePocResult<RemoteItemMutationResult>> archiveRemoteItemById({
    required String remoteItemId,
    String? clientMutationId,
  }) {
    return _repository.archiveRemoteItemByRemoteId(
      remoteItemId: remoteItemId,
      clientMutationId: clientMutationId,
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
  }) {
    return _repository.createRemoteResourceForPack(
      remotePackId: remotePackId,
      title: title,
      description: description,
      type: type,
      config: config,
      clientMutationId: clientMutationId,
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
  }) {
    return _repository.updateRemoteResourceByRemoteId(
      remoteResourceId: remoteResourceId,
      title: title,
      description: description,
      config: config,
      clientMutationId: clientMutationId,
    );
  }

  @override
  Future<RemotePocResult<RemoteResourceMutationResult>>
  archiveRemoteResourceById({
    required String remoteResourceId,
    String? clientMutationId,
  }) {
    return _repository.archiveRemoteResourceByRemoteId(
      remoteResourceId: remoteResourceId,
      clientMutationId: clientMutationId,
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
  }) {
    return _repository.applyRemoteResourceEventByRemoteId(
      remoteResourceId: remoteResourceId,
      changeType: changeType,
      deltaValue: deltaValue,
      newValue: newValue,
      unit: unit,
      clientMutationId: clientMutationId,
      metadata: metadata,
    );
  }

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
    if (mutation.actionType == SyncOutboxActionType.createItem) {
      final remotePackId =
          mutation.remotePackId ?? _stringPayload(payload, 'remotePackId');
      final localItemId =
          _intPayload(payload, 'localItemId') ?? mutation.localEntityId;
      final fields = _mapPayload(payload, 'fields');
      final title = _stringPayload(fields, 'title');
      if (remotePackId == null || localItemId == null || title == null) {
        await _markFailed(
          mutation,
          RemoteBackedMutationResolution.failed,
          'malformed_create_item_payload',
        );
        return RemoteBackedMutationResolution.failed;
      }
      await _markSyncing(mutation);
      return _flushCreateItem(
        mutation,
        remotePackId: remotePackId,
        localItemId: localItemId,
        title: title,
        note: _stringPayload(fields, 'note'),
      );
    }
    if (mutation.actionType == SyncOutboxActionType.createResource) {
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
        await _markFailed(
          mutation,
          RemoteBackedMutationResolution.failed,
          'malformed_create_resource_payload',
        );
        return RemoteBackedMutationResolution.failed;
      }
      await _markSyncing(mutation);
      return _flushCreateResource(
        mutation,
        remotePackId: remotePackId,
        localResourceId: localResourceId,
        title: title,
        description: _stringPayload(fields, 'description'),
        type: type,
        config: _mapPayload(fields, 'config'),
      );
    }
    if (_isResourceMutation(mutation.actionType)) {
      final remoteResourceId = await _resolveRemoteResourceId(
        mutation,
        payload,
      );
      final localResourceId = _intPayload(payload, 'localResourceId');
      if (remoteResourceId == null) {
        await _markFailed(
          mutation,
          RemoteBackedMutationResolution.failed,
          'missing_remote_resource_mapping',
        );
        return RemoteBackedMutationResolution.failed;
      }
      await _markSyncing(mutation);
      return switch (mutation.actionType) {
        SyncOutboxActionType.updateResource => _flushUpdateResource(
          mutation,
          remoteResourceId: remoteResourceId,
          localResourceId: localResourceId,
          fields: _mapPayload(payload, 'fields'),
        ),
        SyncOutboxActionType.archiveResource => _flushArchiveResource(
          mutation,
          remoteResourceId: remoteResourceId,
          localResourceId: localResourceId,
        ),
        SyncOutboxActionType.resourceIncrement ||
        SyncOutboxActionType.resourceAdjust ||
        SyncOutboxActionType.resourceDecrement => _flushResourceEvent(
          mutation,
          remoteResourceId: remoteResourceId,
          localResourceId: localResourceId,
          event: _mapPayload(payload, 'event'),
        ),
        _ => throw StateError('unreachable'),
      };
    }

    final remoteItemId = await _resolveRemoteItemId(mutation, payload);
    final localCompletionId = _intPayload(payload, 'localCompletionId');
    final localItemId = _intPayload(payload, 'localItemId');
    if (remoteItemId == null) {
      await _markFailed(
        mutation,
        RemoteBackedMutationResolution.failed,
        'missing_remote_item_mapping',
      );
      return RemoteBackedMutationResolution.failed;
    }

    await _markSyncing(mutation);

    return switch (mutation.actionType) {
      SyncOutboxActionType.updateItem => _flushUpdateItem(
        mutation,
        remoteItemId: remoteItemId,
        localItemId: localItemId,
        fields: _mapPayload(payload, 'fields'),
      ),
      SyncOutboxActionType.archiveItem => _flushArchiveItem(
        mutation,
        remoteItemId: remoteItemId,
        localItemId: localItemId,
      ),
      SyncOutboxActionType.completeItem => _flushComplete(
        mutation,
        localCompletionId: localCompletionId ?? mutation.localEntityId!,
        remoteItemId: remoteItemId,
      ),
      SyncOutboxActionType.undoItem => _flushUndo(
        mutation,
        localCompletionId: localCompletionId ?? mutation.localEntityId!,
        remoteItemId: remoteItemId,
      ),
      SyncOutboxActionType.createResource ||
      SyncOutboxActionType.updateResource ||
      SyncOutboxActionType.archiveResource ||
      SyncOutboxActionType.resourceIncrement ||
      SyncOutboxActionType.resourceAdjust ||
      SyncOutboxActionType.resourceDecrement => throw StateError('unreachable'),
      SyncOutboxActionType.createItem => throw StateError('unreachable'),
    };
  }

  bool _isResourceMutation(SyncOutboxActionType actionType) {
    return switch (actionType) {
      SyncOutboxActionType.updateResource ||
      SyncOutboxActionType.archiveResource ||
      SyncOutboxActionType.resourceIncrement ||
      SyncOutboxActionType.resourceAdjust ||
      SyncOutboxActionType.resourceDecrement => true,
      _ => false,
    };
  }

  Future<void> _markSyncing(SyncOutboxEntry mutation) {
    final now = _clock().millisecondsSinceEpoch;
    return _dao.updateSyncOutboxEntry(
      mutation.id,
      SyncOutboxCompanion(
        status: Value(SyncOutboxStatus.syncing.storageValue),
        retryCount: Value(mutation.retryCount + 1),
        lastAttemptAt: Value(now),
        updatedAt: Value(now),
      ),
    );
  }

  Future<RemoteBackedMutationResolution> _flushCreateItem(
    SyncOutboxEntry mutation, {
    required String remotePackId,
    required int localItemId,
    required String title,
    String? note,
  }) async {
    final result = await _remoteClient.createRemoteItemForPack(
      remotePackId: remotePackId,
      title: title,
      note: note,
      clientMutationId: mutation.clientMutationId,
    );
    if (!result.isSuccess) {
      final resolution = _failureResolution(result.failureReason);
      await _markFailed(mutation, resolution, result.failureReason?.name);
      if (resolution == RemoteBackedMutationResolution.remoteAccessLost ||
          resolution == RemoteBackedMutationResolution.permissionRevoked) {
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
      if (metadata == null) {
        await _dao.insertRemoteItemSyncMetadata(
          RemoteItemSyncMetadataCompanion.insert(
            localItemId: localItemId,
            localPackId: mutation.localPackId,
            remoteItemId: created.itemId,
            remotePackId: remotePackId,
            syncState: RemoteItemSyncState.stale.storageValue,
            remoteStatus: const Value('active'),
            lastPushedAt: Value(now),
            createdAt: now,
            updatedAt: now,
          ),
        );
      } else {
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

  Future<RemoteBackedMutationResolution> _flushCreateResource(
    SyncOutboxEntry mutation, {
    required String remotePackId,
    required int localResourceId,
    required String title,
    String? description,
    required String type,
    required Map<String, Object?> config,
  }) async {
    final result = await _remoteClient.createRemoteResourceForPack(
      remotePackId: remotePackId,
      title: title,
      description: description,
      type: type,
      config: config,
      clientMutationId: mutation.clientMutationId,
    );
    if (!result.isSuccess) {
      final resolution = _failureResolution(result.failureReason);
      await _markFailed(mutation, resolution, result.failureReason?.name);
      if (resolution == RemoteBackedMutationResolution.remoteAccessLost ||
          resolution == RemoteBackedMutationResolution.permissionRevoked) {
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
      if (metadata == null) {
        await _dao.insertRemoteResourceSyncMetadata(
          RemoteResourceSyncMetadataCompanion.insert(
            localResourceId: localResourceId,
            localPackId: mutation.localPackId,
            remoteResourceId: created.resourceId,
            remotePackId: remotePackId,
            syncState: RemoteResourceSyncState.stale.storageValue,
            remoteStatus: const Value('active'),
            lastPushedAt: Value(now),
            createdAt: now,
            updatedAt: now,
          ),
        );
      } else {
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

  Future<RemoteBackedMutationResolution> _flushUpdateItem(
    SyncOutboxEntry mutation, {
    required String remoteItemId,
    required int? localItemId,
    required Map<String, Object?> fields,
  }) async {
    final title = _stringPayload(fields, 'title');
    if (title == null) {
      await _markFailed(
        mutation,
        RemoteBackedMutationResolution.failed,
        'malformed_update_item_payload',
      );
      return RemoteBackedMutationResolution.failed;
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
      if (resolution == RemoteBackedMutationResolution.remoteAccessLost ||
          resolution == RemoteBackedMutationResolution.permissionRevoked) {
        await _markPackAccessLost(mutation, result.failureReason?.name);
      }
      return resolution;
    }
    await _markItemMutationSynced(
      mutation,
      localItemId: localItemId,
      remoteStatus: 'active',
    );
    return RemoteBackedMutationResolution.synced;
  }

  Future<RemoteBackedMutationResolution> _flushArchiveItem(
    SyncOutboxEntry mutation, {
    required String remoteItemId,
    required int? localItemId,
  }) async {
    final result = await _remoteClient.archiveRemoteItemById(
      remoteItemId: remoteItemId,
      clientMutationId: mutation.clientMutationId,
    );
    if (!result.isSuccess) {
      final resolution = _failureResolution(result.failureReason);
      await _markFailed(mutation, resolution, result.failureReason?.name);
      if (resolution == RemoteBackedMutationResolution.remoteAccessLost ||
          resolution == RemoteBackedMutationResolution.permissionRevoked) {
        await _markPackAccessLost(mutation, result.failureReason?.name);
      }
      return resolution;
    }
    await _markItemMutationSynced(
      mutation,
      localItemId: localItemId,
      remoteStatus: 'archived',
      itemState: RemoteItemSyncState.archived,
    );
    return RemoteBackedMutationResolution.synced;
  }

  Future<RemoteBackedMutationResolution> _flushUpdateResource(
    SyncOutboxEntry mutation, {
    required String remoteResourceId,
    required int? localResourceId,
    required Map<String, Object?> fields,
  }) async {
    final title = _stringPayload(fields, 'title');
    if (title == null) {
      await _markFailed(
        mutation,
        RemoteBackedMutationResolution.failed,
        'malformed_update_resource_payload',
      );
      return RemoteBackedMutationResolution.failed;
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
      if (resolution == RemoteBackedMutationResolution.remoteAccessLost ||
          resolution == RemoteBackedMutationResolution.permissionRevoked) {
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

  Future<RemoteBackedMutationResolution> _flushArchiveResource(
    SyncOutboxEntry mutation, {
    required String remoteResourceId,
    required int? localResourceId,
  }) async {
    final result = await _remoteClient.archiveRemoteResourceById(
      remoteResourceId: remoteResourceId,
      clientMutationId: mutation.clientMutationId,
    );
    if (!result.isSuccess) {
      final resolution = _failureResolution(result.failureReason);
      await _markFailed(mutation, resolution, result.failureReason?.name);
      if (resolution == RemoteBackedMutationResolution.remoteAccessLost ||
          resolution == RemoteBackedMutationResolution.permissionRevoked) {
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

  Future<RemoteBackedMutationResolution> _flushResourceEvent(
    SyncOutboxEntry mutation, {
    required String remoteResourceId,
    required int? localResourceId,
    required Map<String, Object?> event,
  }) async {
    final changeType = _stringPayload(event, 'changeType');
    if (changeType == null) {
      await _markFailed(
        mutation,
        RemoteBackedMutationResolution.failed,
        'malformed_resource_event_payload',
      );
      return RemoteBackedMutationResolution.failed;
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
      if (resolution == RemoteBackedMutationResolution.remoteAccessLost ||
          resolution == RemoteBackedMutationResolution.permissionRevoked) {
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
            lastSyncError: Value(reason ?? resolution.name),
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
