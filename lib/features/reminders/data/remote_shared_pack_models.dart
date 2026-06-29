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

class RemoteItemCreateResult {
  const RemoteItemCreateResult({required this.itemId, this.status = 'created'});

  final String itemId;
  final String status;
}

class RemoteItemMutationResult {
  const RemoteItemMutationResult({required this.itemId, required this.status});

  final String itemId;
  final String status;

  bool get isNoOp => status == 'already_archived' || status == 'not_changed';
}

class RemoteResourceCreateResult {
  const RemoteResourceCreateResult({
    required this.resourceId,
    this.status = 'created',
  });

  final String resourceId;
  final String status;
}

class RemoteResourceMutationResult {
  const RemoteResourceMutationResult({
    required this.resourceId,
    required this.status,
  });

  final String resourceId;
  final String status;

  bool get isNoOp => status == 'already_archived' || status == 'not_changed';
}

class RemoteResourceEventResult {
  const RemoteResourceEventResult({
    required this.resourceId,
    required this.eventId,
    required this.status,
    this.currentValue,
    this.updatedAt,
  });

  final String resourceId;
  final String eventId;
  final String status;
  final int? currentValue;
  final DateTime? updatedAt;
}

class RemoteStageTrackerCreateResult {
  const RemoteStageTrackerCreateResult({
    required this.stageTrackerId,
    this.ruleIdsByClientLocalId = const {},
    this.status = 'created',
  });

  final String stageTrackerId;
  final Map<int, String> ruleIdsByClientLocalId;
  final String status;
}

class RemoteStageMutationResult {
  const RemoteStageMutationResult({
    required this.entityId,
    required this.status,
  });

  final String entityId;
  final String status;

  bool get isNoOp => status == 'already_archived' || status == 'not_changed';
}

class RemoteStageAcknowledgementResult {
  const RemoteStageAcknowledgementResult({
    required this.stageRecordId,
    required this.acknowledgementId,
    required this.status,
    required this.acknowledgedAt,
  });

  final String stageRecordId;
  final String acknowledgementId;
  final String status;
  final DateTime acknowledgedAt;
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

class RemotePackInviteState {
  const RemotePackInviteState({
    this.activeInvite,
    this.latestInviteExpired = false,
  });

  final RemotePackInvite? activeInvite;
  final bool latestInviteExpired;

  bool get hasActiveInvite => activeInvite != null;
}

String normalizeInviteCode(String input) {
  return input.trim().toUpperCase().replaceAll(
    RegExp(r'[\s\-\u2010-\u2015\u2212]+'),
    '',
  );
}

String groupedInviteCode(String code) {
  final normalized = normalizeInviteCode(code);
  if (normalized.length <= 3) {
    return normalized;
  }
  return '${normalized.substring(0, 3)} ${normalized.substring(3)}';
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

class RemoteRecoverablePack {
  const RemoteRecoverablePack({
    required this.remotePackId,
    required this.name,
    this.description,
    required this.role,
    required this.memberStatus,
    required this.packStatus,
    required this.hostUserId,
    required this.updatedAt,
  });

  final String remotePackId;
  final String name;
  final String? description;
  final String role;
  final String memberStatus;
  final String packStatus;
  final String hostUserId;
  final DateTime updatedAt;
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
    this.resources = const [],
    this.stageTrackers = const [],
    this.stageRules = const [],
    this.stageRecords = const [],
    this.stageAcknowledgements = const [],
    required this.completions,
    this.resourceEvents = const [],
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
  final List<RemoteResourceSnapshot> resources;
  final List<RemoteStageTrackerSnapshot> stageTrackers;
  final List<RemoteStageRuleSnapshot> stageRules;
  final List<RemoteStageRecordSnapshot> stageRecords;
  final List<RemoteStageAcknowledgementSnapshot> stageAcknowledgements;
  final List<RemoteItemCompletionSnapshot> completions;
  final List<RemoteResourceEventSnapshot> resourceEvents;
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

class RemoteResourceSnapshot {
  const RemoteResourceSnapshot({
    required this.id,
    required this.packId,
    required this.title,
    this.description,
    required this.status,
    required this.type,
    this.timeAnchorDate,
    this.timeDurationDays,
    this.timeExpectedBeforeDays,
    this.timeWarningBeforeDays,
    this.timeDangerBeforeDays,
    this.quantityCurrent,
    this.quantityUnitLabel,
    this.quantityExpectedThreshold,
    this.quantityWarningThreshold,
    this.quantityDangerThreshold,
    this.lastRefilledAt,
    required this.createdByUserId,
    required this.updatedByUserId,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String packId;
  final String title;
  final String? description;
  final String status;
  final String type;
  final DateTime? timeAnchorDate;
  final int? timeDurationDays;
  final int? timeExpectedBeforeDays;
  final int? timeWarningBeforeDays;
  final int? timeDangerBeforeDays;
  final int? quantityCurrent;
  final String? quantityUnitLabel;
  final int? quantityExpectedThreshold;
  final int? quantityWarningThreshold;
  final int? quantityDangerThreshold;
  final DateTime? lastRefilledAt;
  final String createdByUserId;
  final String updatedByUserId;
  final DateTime createdAt;
  final DateTime updatedAt;
}

class RemoteResourceEventSnapshot {
  const RemoteResourceEventSnapshot({
    required this.id,
    required this.packId,
    required this.resourceId,
    required this.actorUserId,
    required this.changeType,
    this.previousValue,
    this.newValue,
    this.deltaValue,
    this.unit,
    this.metadataJson,
    required this.createdAt,
  });

  final String id;
  final String packId;
  final String resourceId;
  final String actorUserId;
  final String changeType;
  final int? previousValue;
  final int? newValue;
  final int? deltaValue;
  final String? unit;
  final Map<String, Object?>? metadataJson;
  final DateTime createdAt;
}

class RemoteStageTrackerSnapshot {
  const RemoteStageTrackerSnapshot({
    required this.id,
    required this.packId,
    required this.title,
    this.subjectName,
    required this.trackingStartDate,
    this.trackingEndDate,
    required this.status,
    required this.createdByUserId,
    required this.updatedByUserId,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String packId;
  final String title;
  final String? subjectName;
  final DateTime trackingStartDate;
  final DateTime? trackingEndDate;
  final String status;
  final String createdByUserId;
  final String updatedByUserId;
  final DateTime createdAt;
  final DateTime updatedAt;
}

class RemoteStageRuleSnapshot {
  const RemoteStageRuleSnapshot({
    required this.id,
    required this.packId,
    required this.stageTrackerId,
    required this.type,
    required this.intervalValue,
    required this.intervalUnit,
    this.labelTemplate,
    this.reminderOffsetDays,
    required this.status,
    required this.createdByUserId,
    required this.updatedByUserId,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String packId;
  final String stageTrackerId;
  final String type;
  final int intervalValue;
  final String intervalUnit;
  final String? labelTemplate;
  final int? reminderOffsetDays;
  final String status;
  final String createdByUserId;
  final String updatedByUserId;
  final DateTime createdAt;
  final DateTime updatedAt;
}

class RemoteStageRecordSnapshot {
  const RemoteStageRecordSnapshot({
    required this.id,
    required this.packId,
    required this.stageTrackerId,
    this.stageRuleId,
    required this.sourceType,
    this.occurrenceIndex,
    required this.occurrenceDate,
    this.relativeAmount,
    this.relativeUnit,
    required this.status,
    required this.label,
    this.note,
    this.reminderOffsetDays,
    required this.createdByUserId,
    required this.updatedByUserId,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String packId;
  final String stageTrackerId;
  final String? stageRuleId;
  final String sourceType;
  final int? occurrenceIndex;
  final DateTime occurrenceDate;
  final int? relativeAmount;
  final String? relativeUnit;
  final String status;
  final String label;
  final String? note;
  final int? reminderOffsetDays;
  final String createdByUserId;
  final String updatedByUserId;
  final DateTime createdAt;
  final DateTime updatedAt;
}

class RemoteStageAcknowledgementSnapshot {
  const RemoteStageAcknowledgementSnapshot({
    required this.id,
    required this.packId,
    required this.stageRecordId,
    required this.userId,
    required this.acknowledgedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String packId;
  final String stageRecordId;
  final String userId;
  final DateTime acknowledgedAt;
  final DateTime createdAt;
  final DateTime updatedAt;
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
