import '../domain/shared_pack.dart';

enum RemoteSharedPackFailureReason {
  supabaseConfigMissing,
  remoteAuthRequired,
  remoteProfileFailed,
  remotePackAlreadyLinked,
  remotePackCreateFailed,
  remoteInviteNotHost,
  remoteInviteInvalid,
  remoteInviteExpired,
  remoteInviteMaxUsesReached,
  remoteInviteAlreadyRevoked,
  localPackNotShared,
  localUserNotPackMember,
  remoteItemPushFailed,
  remoteItemAlreadyCompleted,
  remoteRlsRejected,
  remoteNetworkFailed,
  remoteUnknownFailure,
  malformedRemoteData,
}

class RemoteSharedPackException implements Exception {
  const RemoteSharedPackException(
    this.reason, [
    this.cause,
    this.operationName,
    this.remoteCode,
  ]);

  final RemoteSharedPackFailureReason reason;
  final Object? cause;
  final String? operationName;
  final String? remoteCode;

  String? get safeDebugMessage {
    final operation = operationName;
    final code = remoteCode;
    if (operation == null || code == null) {
      return null;
    }
    return '$operation 被 Supabase 拒絕：$code';
  }

  @override
  String toString() {
    final debugMessage = safeDebugMessage;
    if (debugMessage != null) {
      return 'RemoteSharedPackException($reason, $debugMessage)';
    }
    return 'RemoteSharedPackException($reason)';
  }
}

class RemotePocResult<T> {
  const RemotePocResult.success(this.value)
    : failureReason = null,
      error = null;

  const RemotePocResult.failure(this.failureReason, [this.error])
    : value = null;

  final T? value;
  final RemoteSharedPackFailureReason? failureReason;
  final Object? error;

  bool get isSuccess => failureReason == null;
}

class RemotePackLinkResult {
  const RemotePackLinkResult({
    required this.remotePackId,
    required this.alreadyLinked,
  });

  final String remotePackId;
  final bool alreadyLinked;
}

class RemoteItemPushSummary {
  const RemoteItemPushSummary({
    required this.pushedCount,
    required this.skippedCount,
    required this.failedCount,
  });

  final int pushedCount;
  final int skippedCount;
  final int failedCount;
}

enum RemoteItemCompletionStatus { completed, alreadyCompleted }

class RemoteItemCompletionResult {
  const RemoteItemCompletionResult({
    required this.status,
    required this.completionId,
    required this.completedByUserId,
    required this.completedAt,
  });

  final RemoteItemCompletionStatus status;
  final String completionId;
  final String completedByUserId;
  final DateTime completedAt;
}

enum RemoteItemUndoStatus { undone, alreadyNotCompleted }

class RemoteItemUndoResult {
  const RemoteItemUndoResult({
    required this.status,
    required this.itemId,
    this.completionId,
    this.undoneByUserId,
    this.undoneAt,
  });

  final RemoteItemUndoStatus status;
  final String itemId;
  final String? completionId;
  final String? undoneByUserId;
  final DateTime? undoneAt;
}

class RemotePackInvite {
  const RemotePackInvite({
    required this.inviteId,
    required this.inviteCode,
    required this.expiresAt,
    required this.maxUses,
  });

  final String inviteId;
  final String inviteCode;
  final DateTime expiresAt;
  final int maxUses;
}

enum RemoteJoinPackStatus { joined, alreadyMember }

class RemoteJoinPackResult {
  const RemoteJoinPackResult({
    required this.status,
    required this.remotePackId,
    required this.memberId,
    required this.role,
  });

  final RemoteJoinPackStatus status;
  final String remotePackId;
  final String memberId;
  final String role;
}

enum RemoteRevokeInviteStatus { revoked, alreadyRevoked }

class RemoteRevokeInviteResult {
  const RemoteRevokeInviteResult({
    required this.status,
    required this.inviteId,
  });

  final RemoteRevokeInviteStatus status;
  final String inviteId;
}

class RemotePackSnapshot {
  const RemotePackSnapshot({
    required this.id,
    required this.name,
    this.description,
    required this.hostUserId,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    required this.members,
    required this.items,
    required this.completions,
    required this.activityEvents,
  });

  final String id;
  final String name;
  final String? description;
  final String hostUserId;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<RemotePackMemberSnapshot> members;
  final List<RemoteItemSnapshot> items;
  final List<RemoteItemCompletionSnapshot> completions;
  final List<RemoteActivityEventSnapshot> activityEvents;
}

class RemotePackMemberSnapshot {
  const RemotePackMemberSnapshot({
    required this.id,
    required this.packId,
    required this.userId,
    this.displayName,
    required this.role,
    required this.status,
    required this.joinedAt,
  });

  final String id;
  final String packId;
  final String userId;
  final String? displayName;
  final String role;
  final String status;
  final DateTime joinedAt;
}

class RemoteItemSnapshot {
  const RemoteItemSnapshot({
    required this.id,
    required this.packId,
    required this.title,
    this.note,
    required this.status,
    this.assignedToUserId,
    required this.createdByUserId,
    required this.updatedByUserId,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String packId;
  final String title;
  final String? note;
  final String status;
  final String? assignedToUserId;
  final String createdByUserId;
  final String updatedByUserId;
  final DateTime createdAt;
  final DateTime updatedAt;
}

class RemoteItemCompletionSnapshot {
  const RemoteItemCompletionSnapshot({
    required this.id,
    required this.packId,
    required this.itemId,
    required this.completedByUserId,
    required this.completedAt,
    this.undoneByUserId,
    this.undoneAt,
    this.clientMutationId,
    required this.createdAt,
  });

  final String id;
  final String packId;
  final String itemId;
  final String completedByUserId;
  final DateTime completedAt;
  final String? undoneByUserId;
  final DateTime? undoneAt;
  final String? clientMutationId;
  final DateTime createdAt;
}

class RemoteActivityEventSnapshot {
  const RemoteActivityEventSnapshot({
    required this.id,
    required this.packId,
    this.actorUserId,
    this.actorDisplayNameSnapshot,
    required this.entityType,
    required this.entityId,
    required this.action,
    this.beforeJson,
    this.afterJson,
    this.metadataJson,
    required this.createdAt,
  });

  final String id;
  final String packId;
  final String? actorUserId;
  final String? actorDisplayNameSnapshot;
  final String entityType;
  final String entityId;
  final String action;
  final Map<String, Object?>? beforeJson;
  final Map<String, Object?>? afterJson;
  final Map<String, Object?>? metadataJson;
  final DateTime createdAt;
}

class RemoteProfile {
  const RemoteProfile({required this.id});

  final String id;
}

extension SyncMappingStateStorage on SyncMappingState {
  String get storageValue => name;
}
