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
  pendingPush,
  syncing,
  importing,
  synced,
  stale,
  failed,
  conflict,
  archived,
  deleted,
}

enum RemoteResourceSyncState {
  linked,
  pendingImport,
  pendingPush,
  syncing,
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

enum SyncOutboxActionType {
  completeItem,
  undoItem,
  createItem,
  updateItem,
  archiveItem,
  createResource,
  updateResource,
  archiveResource,
  resourceIncrement,
  resourceAdjust,
  resourceDecrement,
}

enum SyncOutboxStatus {
  pending,
  syncing,
  synced,
  failed,
  conflict,
  cancelled,
  noOp,
}

enum RemoteBackedItemLocalActionStatus {
  completedPendingSync,
  undoPendingSync,
  alreadyLocallyCompleted,
  alreadyLocallyNotCompleted,
  notRemoteBacked,
  missingRemoteMapping,
  remoteAccessLost,
  unsupported,
  failed,
}

enum RemoteBackedMutationResolution {
  synced,
  alreadyCompletedRemote,
  alreadyNotCompletedRemote,
  permissionRevoked,
  remoteAccessLost,
  networkFailed,
  remoteAuthRequired,
  configMissing,
  failed,
}

class RemoteBackedItemLocalActionResult {
  const RemoteBackedItemLocalActionResult({
    required this.status,
    this.localPackId,
    this.localItemId,
    this.localCompletionId,
    this.outboxId,
    this.clientMutationId,
    this.message,
  });

  final RemoteBackedItemLocalActionStatus status;
  final int? localPackId;
  final int? localItemId;
  final int? localCompletionId;
  final int? outboxId;
  final String? clientMutationId;
  final String? message;

  bool get queued =>
      status == RemoteBackedItemLocalActionStatus.completedPendingSync ||
      status == RemoteBackedItemLocalActionStatus.undoPendingSync;
}

class RemoteBackedOutboxFlushResult {
  const RemoteBackedOutboxFlushResult({
    required this.processed,
    required this.synced,
    required this.noOp,
    required this.conflict,
    required this.failed,
    this.lastResolution,
    this.message,
  });

  final int processed;
  final int synced;
  final int noOp;
  final int conflict;
  final int failed;
  final RemoteBackedMutationResolution? lastResolution;
  final String? message;
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
      RemoteItemSyncState.pendingPush => 'pending_push',
      RemoteItemSyncState.syncing => 'syncing',
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
      'pending_push' => RemoteItemSyncState.pendingPush,
      'syncing' => RemoteItemSyncState.syncing,
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

extension RemoteResourceSyncStateStorage on RemoteResourceSyncState {
  String get storageValue {
    return switch (this) {
      RemoteResourceSyncState.linked => 'linked',
      RemoteResourceSyncState.pendingImport => 'pending_import',
      RemoteResourceSyncState.pendingPush => 'pending_push',
      RemoteResourceSyncState.syncing => 'syncing',
      RemoteResourceSyncState.importing => 'importing',
      RemoteResourceSyncState.synced => 'synced',
      RemoteResourceSyncState.stale => 'stale',
      RemoteResourceSyncState.failed => 'failed',
      RemoteResourceSyncState.conflict => 'conflict',
      RemoteResourceSyncState.archived => 'archived',
      RemoteResourceSyncState.deleted => 'deleted',
    };
  }

  static RemoteResourceSyncState parse(String value) {
    return switch (value) {
      'pending_import' => RemoteResourceSyncState.pendingImport,
      'pending_push' => RemoteResourceSyncState.pendingPush,
      'syncing' => RemoteResourceSyncState.syncing,
      'importing' => RemoteResourceSyncState.importing,
      'synced' => RemoteResourceSyncState.synced,
      'stale' => RemoteResourceSyncState.stale,
      'failed' => RemoteResourceSyncState.failed,
      'conflict' => RemoteResourceSyncState.conflict,
      'archived' => RemoteResourceSyncState.archived,
      'deleted' => RemoteResourceSyncState.deleted,
      _ => RemoteResourceSyncState.linked,
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
      SyncOutboxActionType.createItem => 'create_item',
      SyncOutboxActionType.updateItem => 'update_item',
      SyncOutboxActionType.archiveItem => 'archive_item',
      SyncOutboxActionType.createResource => 'create_resource',
      SyncOutboxActionType.updateResource => 'update_resource',
      SyncOutboxActionType.archiveResource => 'archive_resource',
      SyncOutboxActionType.resourceIncrement => 'resource_increment',
      SyncOutboxActionType.resourceAdjust => 'resource_adjust',
      SyncOutboxActionType.resourceDecrement => 'resource_decrement',
    };
  }

  static SyncOutboxActionType parse(String value) {
    return switch (value) {
      'undo_item' => SyncOutboxActionType.undoItem,
      'create_item' => SyncOutboxActionType.createItem,
      'update_item' => SyncOutboxActionType.updateItem,
      'archive_item' => SyncOutboxActionType.archiveItem,
      'create_resource' => SyncOutboxActionType.createResource,
      'update_resource' => SyncOutboxActionType.updateResource,
      'archive_resource' => SyncOutboxActionType.archiveResource,
      'resource_increment' => SyncOutboxActionType.resourceIncrement,
      'resource_adjust' => SyncOutboxActionType.resourceAdjust,
      'resource_decrement' => SyncOutboxActionType.resourceDecrement,
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

class RemoteResourceSyncMetadataEntry {
  const RemoteResourceSyncMetadataEntry({
    required this.id,
    required this.localResourceId,
    required this.localPackId,
    required this.remoteResourceId,
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
  final int localResourceId;
  final int localPackId;
  final String remoteResourceId;
  final String remotePackId;
  final RemoteResourceSyncState syncState;
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
