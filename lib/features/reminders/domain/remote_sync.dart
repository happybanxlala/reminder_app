enum RemotePackSyncKind { localOnly, remoteBacked }

enum RemotePackSyncState {
  linked,
  pendingImport,
  importing,
  synced,
  stale,
  failed,
  conflict,
  accessLost,
  removed,
}

enum RemoteUserRole { host, member, viewer }

enum RemoteUserStatus { active, removed, pending, unknown }

enum RemoteItemSyncState {
  linked,
  pendingImport,
  importing,
  synced,
  stale,
  failed,
  conflict,
  archived,
  deleted,
}

enum RemoteCompletionSyncState {
  pendingPush,
  syncing,
  synced,
  failed,
  conflict,
  noOp,
}

enum RemoteCompletionState {
  pendingLocal,
  confirmedRemote,
  remoteImported,
  undoneRemote,
  noOp,
  conflict,
  failed,
}

enum SyncOutboxActionType { completeItem, undoItem }

enum SyncOutboxStatus {
  pending,
  syncing,
  synced,
  failed,
  conflict,
  cancelled,
  noOp,
}

extension RemotePackSyncKindStorage on RemotePackSyncKind {
  String get storageValue {
    return switch (this) {
      RemotePackSyncKind.localOnly => 'local_only',
      RemotePackSyncKind.remoteBacked => 'remote_backed',
    };
  }

  static RemotePackSyncKind parse(String value) {
    return switch (value) {
      'remote_backed' => RemotePackSyncKind.remoteBacked,
      _ => RemotePackSyncKind.localOnly,
    };
  }
}

extension RemotePackSyncStateStorage on RemotePackSyncState {
  String get storageValue {
    return switch (this) {
      RemotePackSyncState.linked => 'linked',
      RemotePackSyncState.pendingImport => 'pending_import',
      RemotePackSyncState.importing => 'importing',
      RemotePackSyncState.synced => 'synced',
      RemotePackSyncState.stale => 'stale',
      RemotePackSyncState.failed => 'failed',
      RemotePackSyncState.conflict => 'conflict',
      RemotePackSyncState.accessLost => 'access_lost',
      RemotePackSyncState.removed => 'removed',
    };
  }

  static RemotePackSyncState parse(String value) {
    return switch (value) {
      'pending_import' => RemotePackSyncState.pendingImport,
      'importing' => RemotePackSyncState.importing,
      'synced' => RemotePackSyncState.synced,
      'stale' => RemotePackSyncState.stale,
      'failed' => RemotePackSyncState.failed,
      'conflict' => RemotePackSyncState.conflict,
      'access_lost' => RemotePackSyncState.accessLost,
      'removed' => RemotePackSyncState.removed,
      _ => RemotePackSyncState.linked,
    };
  }
}

extension RemoteUserRoleStorage on RemoteUserRole {
  String get storageValue => name;

  static RemoteUserRole parse(String value) {
    return switch (value) {
      'member' => RemoteUserRole.member,
      'viewer' => RemoteUserRole.viewer,
      _ => RemoteUserRole.host,
    };
  }
}

extension RemoteUserStatusStorage on RemoteUserStatus {
  String get storageValue => name;

  static RemoteUserStatus parse(String value) {
    return switch (value) {
      'removed' => RemoteUserStatus.removed,
      'pending' => RemoteUserStatus.pending,
      'unknown' => RemoteUserStatus.unknown,
      _ => RemoteUserStatus.active,
    };
  }
}

extension RemoteItemSyncStateStorage on RemoteItemSyncState {
  String get storageValue {
    return switch (this) {
      RemoteItemSyncState.linked => 'linked',
      RemoteItemSyncState.pendingImport => 'pending_import',
      RemoteItemSyncState.importing => 'importing',
      RemoteItemSyncState.synced => 'synced',
      RemoteItemSyncState.stale => 'stale',
      RemoteItemSyncState.failed => 'failed',
      RemoteItemSyncState.conflict => 'conflict',
      RemoteItemSyncState.archived => 'archived',
      RemoteItemSyncState.deleted => 'deleted',
    };
  }

  static RemoteItemSyncState parse(String value) {
    return switch (value) {
      'pending_import' => RemoteItemSyncState.pendingImport,
      'importing' => RemoteItemSyncState.importing,
      'synced' => RemoteItemSyncState.synced,
      'stale' => RemoteItemSyncState.stale,
      'failed' => RemoteItemSyncState.failed,
      'conflict' => RemoteItemSyncState.conflict,
      'archived' => RemoteItemSyncState.archived,
      'deleted' => RemoteItemSyncState.deleted,
      _ => RemoteItemSyncState.linked,
    };
  }
}

extension RemoteCompletionSyncStateStorage on RemoteCompletionSyncState {
  String get storageValue {
    return switch (this) {
      RemoteCompletionSyncState.pendingPush => 'pending_push',
      RemoteCompletionSyncState.syncing => 'syncing',
      RemoteCompletionSyncState.synced => 'synced',
      RemoteCompletionSyncState.failed => 'failed',
      RemoteCompletionSyncState.conflict => 'conflict',
      RemoteCompletionSyncState.noOp => 'no_op',
    };
  }

  static RemoteCompletionSyncState parse(String value) {
    return switch (value) {
      'syncing' => RemoteCompletionSyncState.syncing,
      'synced' => RemoteCompletionSyncState.synced,
      'failed' => RemoteCompletionSyncState.failed,
      'conflict' => RemoteCompletionSyncState.conflict,
      'no_op' => RemoteCompletionSyncState.noOp,
      _ => RemoteCompletionSyncState.pendingPush,
    };
  }
}

extension RemoteCompletionStateStorage on RemoteCompletionState {
  String get storageValue {
    return switch (this) {
      RemoteCompletionState.pendingLocal => 'pending_local',
      RemoteCompletionState.confirmedRemote => 'confirmed_remote',
      RemoteCompletionState.remoteImported => 'remote_imported',
      RemoteCompletionState.undoneRemote => 'undone_remote',
      RemoteCompletionState.noOp => 'no_op',
      RemoteCompletionState.conflict => 'conflict',
      RemoteCompletionState.failed => 'failed',
    };
  }

  static RemoteCompletionState parse(String value) {
    return switch (value) {
      'confirmed_remote' => RemoteCompletionState.confirmedRemote,
      'remote_imported' => RemoteCompletionState.remoteImported,
      'undone_remote' => RemoteCompletionState.undoneRemote,
      'no_op' => RemoteCompletionState.noOp,
      'conflict' => RemoteCompletionState.conflict,
      'failed' => RemoteCompletionState.failed,
      _ => RemoteCompletionState.pendingLocal,
    };
  }
}

extension SyncOutboxActionTypeStorage on SyncOutboxActionType {
  String get storageValue {
    return switch (this) {
      SyncOutboxActionType.completeItem => 'complete_item',
      SyncOutboxActionType.undoItem => 'undo_item',
    };
  }

  static SyncOutboxActionType parse(String value) {
    return switch (value) {
      'undo_item' => SyncOutboxActionType.undoItem,
      _ => SyncOutboxActionType.completeItem,
    };
  }
}

extension SyncOutboxStatusStorage on SyncOutboxStatus {
  String get storageValue {
    return switch (this) {
      SyncOutboxStatus.pending => 'pending',
      SyncOutboxStatus.syncing => 'syncing',
      SyncOutboxStatus.synced => 'synced',
      SyncOutboxStatus.failed => 'failed',
      SyncOutboxStatus.conflict => 'conflict',
      SyncOutboxStatus.cancelled => 'cancelled',
      SyncOutboxStatus.noOp => 'no_op',
    };
  }

  static SyncOutboxStatus parse(String value) {
    return switch (value) {
      'syncing' => SyncOutboxStatus.syncing,
      'synced' => SyncOutboxStatus.synced,
      'failed' => SyncOutboxStatus.failed,
      'conflict' => SyncOutboxStatus.conflict,
      'cancelled' => SyncOutboxStatus.cancelled,
      'no_op' => SyncOutboxStatus.noOp,
      _ => SyncOutboxStatus.pending,
    };
  }
}

class RemotePackSyncMetadataEntry {
  const RemotePackSyncMetadataEntry({
    required this.id,
    required this.localPackId,
    required this.remotePackId,
    required this.syncKind,
    required this.syncState,
    this.currentUserRemoteRole,
    this.currentUserRemoteStatus,
    this.lastRemoteSnapshotAt,
    this.lastSuccessfulSyncAt,
    this.lastSyncError,
    required this.createdAt,
    required this.updatedAt,
    this.removedAt,
    this.accessLostAt,
  });

  final int id;
  final int localPackId;
  final String remotePackId;
  final RemotePackSyncKind syncKind;
  final RemotePackSyncState syncState;
  final RemoteUserRole? currentUserRemoteRole;
  final RemoteUserStatus? currentUserRemoteStatus;
  final DateTime? lastRemoteSnapshotAt;
  final DateTime? lastSuccessfulSyncAt;
  final String? lastSyncError;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? removedAt;
  final DateTime? accessLostAt;
}

class RemoteItemSyncMetadataEntry {
  const RemoteItemSyncMetadataEntry({
    required this.id,
    required this.localItemId,
    required this.localPackId,
    required this.remoteItemId,
    required this.remotePackId,
    required this.syncState,
    this.remoteStatus,
    this.remoteUpdatedAt,
    this.lastPulledAt,
    this.lastPushedAt,
    this.lastSyncError,
    required this.createdAt,
    required this.updatedAt,
    this.archivedAt,
    this.deletedAt,
  });

  final int id;
  final int localItemId;
  final int localPackId;
  final String remoteItemId;
  final String remotePackId;
  final RemoteItemSyncState syncState;
  final String? remoteStatus;
  final DateTime? remoteUpdatedAt;
  final DateTime? lastPulledAt;
  final DateTime? lastPushedAt;
  final String? lastSyncError;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? archivedAt;
  final DateTime? deletedAt;
}

class RemoteCompletionSyncMetadataEntry {
  const RemoteCompletionSyncMetadataEntry({
    required this.id,
    this.localCompletionId,
    required this.localItemId,
    required this.localPackId,
    this.remoteCompletionId,
    required this.remoteItemId,
    required this.remotePackId,
    required this.syncState,
    required this.completionState,
    this.clientMutationId,
    this.remoteCompletedByUserId,
    this.remoteCompletedAt,
    this.remoteUndoneByUserId,
    this.remoteUndoneAt,
    this.lastPulledAt,
    this.lastPushedAt,
    this.lastSyncError,
    required this.createdAt,
    required this.updatedAt,
  });

  final int id;
  final int? localCompletionId;
  final int localItemId;
  final int localPackId;
  final String? remoteCompletionId;
  final String remoteItemId;
  final String remotePackId;
  final RemoteCompletionSyncState syncState;
  final RemoteCompletionState completionState;
  final String? clientMutationId;
  final String? remoteCompletedByUserId;
  final DateTime? remoteCompletedAt;
  final String? remoteUndoneByUserId;
  final DateTime? remoteUndoneAt;
  final DateTime? lastPulledAt;
  final DateTime? lastPushedAt;
  final String? lastSyncError;
  final DateTime createdAt;
  final DateTime updatedAt;
}

class SyncOutboxEntry {
  const SyncOutboxEntry({
    required this.id,
    required this.localPackId,
    this.remotePackId,
    required this.localEntityType,
    this.localEntityId,
    this.remoteEntityId,
    required this.actionType,
    required this.payloadJson,
    required this.clientMutationId,
    required this.actorLocalUserId,
    this.actorRemoteUserId,
    this.baseRemoteVersion,
    required this.createdAt,
    required this.updatedAt,
    required this.status,
    required this.retryCount,
    this.lastAttemptAt,
    this.lastError,
    this.resolvedAt,
    this.cancelledAt,
  });

  final int id;
  final int localPackId;
  final String? remotePackId;
  final String localEntityType;
  final int? localEntityId;
  final String? remoteEntityId;
  final SyncOutboxActionType actionType;
  final String payloadJson;
  final String clientMutationId;
  final String actorLocalUserId;
  final String? actorRemoteUserId;
  final String? baseRemoteVersion;
  final DateTime createdAt;
  final DateTime updatedAt;
  final SyncOutboxStatus status;
  final int retryCount;
  final DateTime? lastAttemptAt;
  final String? lastError;
  final DateTime? resolvedAt;
  final DateTime? cancelledAt;
}
