import '../domain/shared_equality.dart';
import '../domain/shared_pack_errors.dart';
import '../domain/shared_pack_ids.dart';
import '../domain/shared_pack_models.dart';
import '../domain/shared_pack_runtime_values.dart';
import 'shared_pack_commands.dart';

final class TrustPresentation extends SharedValue {
  TrustPresentation({
    required this.trust,
    this.reason,
    required this.lastVerifiedAt,
    required this.canRefreshOrRecheck,
    required this.mutationBlocked,
  }) {
    if (trust == SharedCacheTrust.verified && reason != null) {
      throw ArgumentError('Verified trust cannot carry a failure reason');
    }
    if (trust != SharedCacheTrust.verified && reason == null) {
      throw ArgumentError('Untrusted cache requires a stable failure reason');
    }
  }

  final SharedCacheTrust trust;
  final SharedTrustFailureReason? reason;
  final UtcInstant lastVerifiedAt;
  final bool canRefreshOrRecheck;
  final bool mutationBlocked;

  @override
  List<Object?> get equalityFields => [
    trust,
    reason,
    lastVerifiedAt,
    canRefreshOrRecheck,
    mutationBlocked,
  ];
}

enum PendingRecoveryAction { refresh, sameIdReplay, accessRecheck }

final class PendingRecoveryPresentation extends SharedValue {
  PendingRecoveryPresentation({
    required this.operation,
    this.targetRemotePackId,
    required this.createdAt,
    required List<PendingRecoveryAction> availableActions,
  }) : availableActions = List.unmodifiable(availableActions);

  final SharedMutationOperation operation;
  final RemotePackId? targetRemotePackId;
  final UtcInstant createdAt;
  final List<PendingRecoveryAction> availableActions;

  @override
  List<Object?> get equalityFields => [
    operation,
    targetRemotePackId,
    createdAt,
    availableActions,
  ];
}

/// Safe recovery stream value; it exposes no request ID, fingerprint or payload.
final class UnresolvedMutationPresentation extends SharedValue {
  UnresolvedMutationPresentation({
    required List<PendingRecoveryPresentation> entries,
  }) : entries = List.unmodifiable(entries);

  final List<PendingRecoveryPresentation> entries;

  @override
  List<Object?> get equalityFields => [entries];
}

final class SharedPackListEntry extends SharedValue {
  const SharedPackListEntry({
    required this.remotePackId,
    required this.title,
    required this.iconEmoji,
    required this.role,
    required this.trust,
    required this.lastVerifiedAt,
    this.pending,
  });

  final RemotePackId remotePackId;
  final String title;
  final String iconEmoji;
  final SharedRole role;
  final TrustPresentation trust;
  final UtcInstant lastVerifiedAt;
  final PendingRecoveryPresentation? pending;

  @override
  List<Object?> get equalityFields => [
    remotePackId,
    title,
    iconEmoji,
    role,
    trust,
    lastVerifiedAt,
    pending,
  ];
}

typedef SharedPackListSummary = SharedPackListEntry;

final class SharedPackListReadModel extends SharedValue {
  SharedPackListReadModel({
    required List<SharedPackListEntry> packs,
    required this.unresolved,
  }) : packs = List.unmodifiable(packs);

  final List<SharedPackListEntry> packs;
  final UnresolvedMutationPresentation unresolved;

  @override
  List<Object?> get equalityFields => [packs, unresolved];
}

final class CurrentMembershipReadModel extends SharedValue {
  const CurrentMembershipReadModel({
    required this.remoteMemberId,
    required this.displayName,
    required this.role,
  });

  final RemoteMemberId remoteMemberId;
  final String displayName;
  final SharedRole role;

  @override
  List<Object?> get equalityFields => [remoteMemberId, displayName, role];
}

final class SharedMemberReadModel extends SharedValue {
  const SharedMemberReadModel({
    required this.remoteMemberId,
    required this.displayName,
    required this.role,
    required this.joinedAt,
  });

  final RemoteMemberId remoteMemberId;
  final String displayName;
  final SharedRole role;
  final UtcInstant joinedAt;

  @override
  List<Object?> get equalityFields => [
    remoteMemberId,
    displayName,
    role,
    joinedAt,
  ];
}

final class ActorAttributionViewData extends SharedValue {
  const ActorAttributionViewData({
    required this.remoteMemberId,
    required this.displayLabel,
    required this.hasDuplicateDisplayName,
  });

  final RemoteMemberId remoteMemberId;
  final String displayLabel;
  final bool hasDuplicateDisplayName;

  @override
  List<Object?> get equalityFields => [
    remoteMemberId,
    displayLabel,
    hasDuplicateDisplayName,
  ];
}

final class SharedCompletionPresentation extends SharedValue {
  const SharedCompletionPresentation({
    required this.completedAt,
    required this.actor,
  });

  final UtcInstant completedAt;
  final ActorAttributionViewData actor;

  @override
  List<Object?> get equalityFields => [completedAt, actor];
}

final class SharedItemReadModel extends SharedValue {
  const SharedItemReadModel({
    required this.remotePackId,
    required this.remoteItemId,
    required this.title,
    this.description,
    required this.stateAnchorDateUtc,
    required this.thresholds,
    required this.attention,
    this.completion,
    required this.itemVersion,
    required this.createdAt,
    required this.updatedAt,
  });

  final RemotePackId remotePackId;
  final RemoteItemId remoteItemId;
  final String title;
  final String? description;
  final UtcInstant stateAnchorDateUtc;
  final SharedItemThresholds thresholds;
  final SharedItemAttention attention;
  final SharedCompletionPresentation? completion;
  final RemoteItemVersion itemVersion;
  final UtcInstant createdAt;
  final UtcInstant updatedAt;

  @override
  List<Object?> get equalityFields => [
    remotePackId,
    remoteItemId,
    title,
    description,
    stateAnchorDateUtc,
    thresholds,
    attention,
    completion,
    itemVersion,
    createdAt,
    updatedAt,
  ];
}

final class SharedPackDetailReadModel extends SharedValue {
  SharedPackDetailReadModel({
    required this.remotePackId,
    required this.title,
    this.description,
    required this.iconEmoji,
    required this.packVersion,
    required this.currentMembership,
    required List<SharedMemberReadModel> members,
    required List<SharedItemReadModel> activeItems,
    required this.trust,
    this.pending,
    required this.lastVerifiedAt,
  }) : members = List.unmodifiable(members),
       activeItems = List.unmodifiable(activeItems);

  final RemotePackId remotePackId;
  final String title;
  final String? description;
  final String iconEmoji;
  final RemotePackVersion packVersion;
  final CurrentMembershipReadModel currentMembership;
  final List<SharedMemberReadModel> members;
  final List<SharedItemReadModel> activeItems;
  final TrustPresentation trust;
  final PendingRecoveryPresentation? pending;
  final UtcInstant lastVerifiedAt;

  @override
  List<Object?> get equalityFields => [
    remotePackId,
    title,
    description,
    iconEmoji,
    packVersion,
    currentMembership,
    members,
    activeItems,
    trust,
    pending,
    lastVerifiedAt,
  ];
}

enum InviteJoinAvailability { available }

final class InvitePreview extends SharedValue {
  const InvitePreview({
    required this.title,
    required this.iconEmoji,
    required this.joinAvailability,
  });

  final String title;
  final String iconEmoji;
  final InviteJoinAvailability joinAvailability;

  @override
  List<Object?> get equalityFields => [title, iconEmoji, joinAvailability];
}

/// Sensitive invite result that must remain ephemeral and clearable.
final class InviteCodePresentation extends SharedValue {
  InviteCodePresentation({
    required this.normalizedInviteCode,
    required this.displayInviteCode,
  }) {
    if (normalizedInviteCode.isEmpty || displayInviteCode.isEmpty) {
      throw ArgumentError('Invite code presentation cannot be empty');
    }
  }

  final String normalizedInviteCode;
  final String displayInviteCode;

  @override
  List<Object?> get equalityFields => [normalizedInviteCode, displayInviteCode];
}

final class ArchivedSharedItemResult extends SharedValue {
  const ArchivedSharedItemResult({
    required this.remotePackId,
    required this.remoteItemId,
    required this.resultingItemVersion,
    required this.resultingPackVersion,
  });

  final RemotePackId remotePackId;
  final RemoteItemId remoteItemId;
  final RemoteItemVersion resultingItemVersion;
  final RemotePackVersion resultingPackVersion;

  @override
  List<Object?> get equalityFields => [
    remotePackId,
    remoteItemId,
    resultingItemVersion,
    resultingPackVersion,
  ];
}

enum SharedRefreshResultKind { fullSnapshot, notModified, inaccessible }

final class SharedRefreshResultPresentation extends SharedValue {
  const SharedRefreshResultPresentation({
    required this.remotePackId,
    required this.kind,
    required this.packVersion,
    required this.verifiedAt,
  });

  final RemotePackId remotePackId;
  final SharedRefreshResultKind kind;
  final RemotePackVersion packVersion;
  final UtcInstant verifiedAt;

  @override
  List<Object?> get equalityFields => [
    remotePackId,
    kind,
    packVersion,
    verifiedAt,
  ];
}
