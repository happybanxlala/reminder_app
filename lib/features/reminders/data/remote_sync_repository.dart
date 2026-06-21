import 'package:drift/drift.dart';

import '../domain/remote_sync.dart';
import 'local/app_database.dart';
import 'local/reminder_dao.dart';

class RemoteSyncRepository {
  const RemoteSyncRepository(this._dao, {DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  final ReminderDao _dao;
  final DateTime Function() _clock;

  Future<RemotePackSyncMetadataEntry> createRemoteBackedPackMetadata({
    required int localPackId,
    required String remotePackId,
    RemotePackSyncState syncState = RemotePackSyncState.linked,
    RemoteUserRole? currentUserRemoteRole,
    RemoteUserStatus? currentUserRemoteStatus,
  }) async {
    final now = _nowMillis();
    await _dao.insertRemotePackSyncMetadata(
      RemotePackSyncMetadataCompanion.insert(
        localPackId: localPackId,
        remotePackId: remotePackId,
        syncKind: RemotePackSyncKind.remoteBacked.storageValue,
        syncState: syncState.storageValue,
        currentUserRemoteRole: Value(currentUserRemoteRole?.storageValue),
        currentUserRemoteStatus: Value(currentUserRemoteStatus?.storageValue),
        createdAt: now,
        updatedAt: now,
      ),
    );
    return (await getMetadataForLocalPack(localPackId))!;
  }

  Future<RemotePackSyncMetadataEntry?> getMetadataForLocalPack(
    int localPackId,
  ) {
    return _dao.getRemotePackSyncMetadataForLocalPack(localPackId);
  }

  Future<RemotePackSyncMetadataEntry?> getMetadataForRemotePack(
    String remotePackId,
  ) {
    return _dao.getRemotePackSyncMetadataForRemotePack(remotePackId);
  }

  Stream<RemotePackSyncMetadataEntry?> watchMetadataForLocalPack(
    int localPackId,
  ) {
    return _dao.watchRemotePackSyncMetadataForLocalPack(localPackId);
  }

  Future<bool> updatePackSyncState(
    int localPackId,
    RemotePackSyncState syncState, {
    String? lastSyncError,
  }) async {
    final metadata = await getMetadataForLocalPack(localPackId);
    if (metadata == null) {
      return false;
    }
    return _dao.updateRemotePackSyncMetadata(
      metadata.id,
      RemotePackSyncMetadataCompanion(
        syncState: Value(syncState.storageValue),
        lastSyncError: Value(lastSyncError),
        updatedAt: Value(_nowMillis()),
      ),
    );
  }

  Future<bool> markPackStale(int localPackId) {
    return updatePackSyncState(localPackId, RemotePackSyncState.stale);
  }

  Future<bool> markPackAccessLost(int localPackId, {String? error}) async {
    final metadata = await getMetadataForLocalPack(localPackId);
    if (metadata == null) {
      return false;
    }
    final now = _nowMillis();
    return _dao.updateRemotePackSyncMetadata(
      metadata.id,
      RemotePackSyncMetadataCompanion(
        syncState: Value(RemotePackSyncState.accessLost.storageValue),
        currentUserRemoteStatus: Value(RemoteUserStatus.removed.storageValue),
        lastSyncError: Value(error),
        accessLostAt: Value(now),
        updatedAt: Value(now),
      ),
    );
  }

  Future<RemoteItemSyncMetadataEntry> createRemoteItemMetadata({
    required int localItemId,
    required int localPackId,
    required String remoteItemId,
    required String remotePackId,
    RemoteItemSyncState syncState = RemoteItemSyncState.linked,
    String? remoteStatus,
    DateTime? remoteUpdatedAt,
  }) async {
    final now = _nowMillis();
    await _dao.insertRemoteItemSyncMetadata(
      RemoteItemSyncMetadataCompanion.insert(
        localItemId: localItemId,
        localPackId: localPackId,
        remoteItemId: remoteItemId,
        remotePackId: remotePackId,
        syncState: syncState.storageValue,
        remoteStatus: Value(remoteStatus),
        remoteUpdatedAt: Value(_millis(remoteUpdatedAt)),
        createdAt: now,
        updatedAt: now,
      ),
    );
    return (await getMetadataForLocalItem(localItemId))!;
  }

  Future<RemoteItemSyncMetadataEntry?> getMetadataForLocalItem(
    int localItemId,
  ) {
    return _dao.getRemoteItemSyncMetadataForLocalItem(localItemId);
  }

  Future<RemoteItemSyncMetadataEntry?> getMetadataForRemoteItem(
    String remoteItemId,
  ) {
    return _dao.getRemoteItemSyncMetadataForRemoteItem(remoteItemId);
  }

  Future<bool> updateItemSyncState(
    int localItemId,
    RemoteItemSyncState syncState, {
    String? lastSyncError,
  }) async {
    final metadata = await getMetadataForLocalItem(localItemId);
    if (metadata == null) {
      return false;
    }
    return _dao.updateRemoteItemSyncMetadata(
      metadata.id,
      RemoteItemSyncMetadataCompanion(
        syncState: Value(syncState.storageValue),
        lastSyncError: Value(lastSyncError),
        updatedAt: Value(_nowMillis()),
      ),
    );
  }

  Future<bool> markRemoteItemArchived(int localItemId) async {
    final metadata = await getMetadataForLocalItem(localItemId);
    if (metadata == null) {
      return false;
    }
    final now = _nowMillis();
    return _dao.updateRemoteItemSyncMetadata(
      metadata.id,
      RemoteItemSyncMetadataCompanion(
        syncState: Value(RemoteItemSyncState.archived.storageValue),
        remoteStatus: const Value('archived'),
        archivedAt: Value(now),
        updatedAt: Value(now),
      ),
    );
  }

  Future<RemoteCompletionSyncMetadataEntry> createCompletionSyncMetadata({
    int? localCompletionId,
    required int localItemId,
    required int localPackId,
    String? remoteCompletionId,
    required String remoteItemId,
    required String remotePackId,
    RemoteCompletionSyncState syncState = RemoteCompletionSyncState.pendingPush,
    RemoteCompletionState completionState = RemoteCompletionState.pendingLocal,
    String? clientMutationId,
    String? remoteCompletedByUserId,
    DateTime? remoteCompletedAt,
  }) async {
    final now = _nowMillis();
    final id = await _dao.insertRemoteCompletionSyncMetadata(
      RemoteCompletionSyncMetadataCompanion.insert(
        localCompletionId: Value(localCompletionId),
        localItemId: localItemId,
        localPackId: localPackId,
        remoteCompletionId: Value(remoteCompletionId),
        remoteItemId: remoteItemId,
        remotePackId: remotePackId,
        syncState: syncState.storageValue,
        completionState: completionState.storageValue,
        clientMutationId: Value(clientMutationId),
        remoteCompletedByUserId: Value(remoteCompletedByUserId),
        remoteCompletedAt: Value(_millis(remoteCompletedAt)),
        createdAt: now,
        updatedAt: now,
      ),
    );
    return (await _dao.getRemoteCompletionSyncMetadataById(id))!;
  }

  Future<bool> markCompletionConfirmedRemote(
    int metadataId, {
    required String remoteCompletionId,
    required String remoteCompletedByUserId,
    required DateTime remoteCompletedAt,
  }) {
    final now = _nowMillis();
    return _dao.updateRemoteCompletionSyncMetadata(
      metadataId,
      RemoteCompletionSyncMetadataCompanion(
        remoteCompletionId: Value(remoteCompletionId),
        remoteCompletedByUserId: Value(remoteCompletedByUserId),
        remoteCompletedAt: Value(remoteCompletedAt.millisecondsSinceEpoch),
        syncState: Value(RemoteCompletionSyncState.synced.storageValue),
        completionState: Value(
          RemoteCompletionState.confirmedRemote.storageValue,
        ),
        lastPushedAt: Value(now),
        updatedAt: Value(now),
      ),
    );
  }

  Future<bool> markCompletionNoOp(int metadataId, {String? error}) {
    final now = _nowMillis();
    return _dao.updateRemoteCompletionSyncMetadata(
      metadataId,
      RemoteCompletionSyncMetadataCompanion(
        syncState: Value(RemoteCompletionSyncState.noOp.storageValue),
        completionState: Value(RemoteCompletionState.noOp.storageValue),
        lastSyncError: Value(error),
        updatedAt: Value(now),
      ),
    );
  }

  Future<bool> markCompletionConflict(int metadataId, {String? error}) {
    final now = _nowMillis();
    return _dao.updateRemoteCompletionSyncMetadata(
      metadataId,
      RemoteCompletionSyncMetadataCompanion(
        syncState: Value(RemoteCompletionSyncState.conflict.storageValue),
        completionState: Value(RemoteCompletionState.conflict.storageValue),
        lastSyncError: Value(error),
        updatedAt: Value(now),
      ),
    );
  }

  Future<SyncOutboxEntry> enqueuePendingMutation({
    required int localPackId,
    String? remotePackId,
    required String localEntityType,
    int? localEntityId,
    String? remoteEntityId,
    required SyncOutboxActionType actionType,
    required String payloadJson,
    required String clientMutationId,
    required String actorLocalUserId,
    String? actorRemoteUserId,
    String? baseRemoteVersion,
  }) async {
    final now = _nowMillis();
    final id = await _dao.insertSyncOutbox(
      SyncOutboxCompanion.insert(
        localPackId: localPackId,
        remotePackId: Value(remotePackId),
        localEntityType: localEntityType,
        localEntityId: Value(localEntityId),
        remoteEntityId: Value(remoteEntityId),
        actionType: actionType.storageValue,
        payloadJson: payloadJson,
        clientMutationId: clientMutationId,
        actorLocalUserId: actorLocalUserId,
        actorRemoteUserId: Value(actorRemoteUserId),
        baseRemoteVersion: Value(baseRemoteVersion),
        createdAt: now,
        updatedAt: now,
        status: SyncOutboxStatus.pending.storageValue,
      ),
    );
    return (await _dao.getSyncOutboxEntryById(id))!;
  }

  Future<List<SyncOutboxEntry>> getPendingMutations() {
    return _dao.listPendingSyncOutboxEntries();
  }

  Stream<List<SyncOutboxEntry>> watchPendingMutationsForPack(int localPackId) {
    return _dao.watchSyncOutboxEntriesForPack(localPackId);
  }

  Future<bool> markMutationSyncing(int mutationId) async {
    final mutation = await _dao.getSyncOutboxEntryById(mutationId);
    if (mutation == null) {
      return false;
    }
    final now = _nowMillis();
    return _dao.updateSyncOutboxEntry(
      mutationId,
      SyncOutboxCompanion(
        status: Value(SyncOutboxStatus.syncing.storageValue),
        retryCount: Value(mutation.retryCount + 1),
        lastAttemptAt: Value(now),
        updatedAt: Value(now),
      ),
    );
  }

  Future<bool> markMutationSynced(int mutationId) {
    return _markMutationResolved(mutationId, SyncOutboxStatus.synced);
  }

  Future<bool> markMutationFailed(int mutationId, String error) {
    final now = _nowMillis();
    return _dao.updateSyncOutboxEntry(
      mutationId,
      SyncOutboxCompanion(
        status: Value(SyncOutboxStatus.failed.storageValue),
        lastError: Value(error),
        updatedAt: Value(now),
      ),
    );
  }

  Future<bool> markMutationConflict(int mutationId, {String? error}) {
    final now = _nowMillis();
    return _dao.updateSyncOutboxEntry(
      mutationId,
      SyncOutboxCompanion(
        status: Value(SyncOutboxStatus.conflict.storageValue),
        lastError: Value(error),
        resolvedAt: Value(now),
        updatedAt: Value(now),
      ),
    );
  }

  Future<bool> markMutationNoOp(int mutationId, {String? error}) {
    final now = _nowMillis();
    return _dao.updateSyncOutboxEntry(
      mutationId,
      SyncOutboxCompanion(
        status: Value(SyncOutboxStatus.noOp.storageValue),
        lastError: Value(error),
        resolvedAt: Value(now),
        updatedAt: Value(now),
      ),
    );
  }

  Future<bool> cancelMutation(int mutationId) {
    final now = _nowMillis();
    return _dao.updateSyncOutboxEntry(
      mutationId,
      SyncOutboxCompanion(
        status: Value(SyncOutboxStatus.cancelled.storageValue),
        cancelledAt: Value(now),
        updatedAt: Value(now),
      ),
    );
  }

  Future<bool> _markMutationResolved(int mutationId, SyncOutboxStatus status) {
    final now = _nowMillis();
    return _dao.updateSyncOutboxEntry(
      mutationId,
      SyncOutboxCompanion(
        status: Value(status.storageValue),
        resolvedAt: Value(now),
        updatedAt: Value(now),
      ),
    );
  }

  int _nowMillis() => _clock().millisecondsSinceEpoch;

  int? _millis(DateTime? value) => value?.millisecondsSinceEpoch;
}
