import '../domain/shared_equality.dart';
import '../domain/shared_pack_errors.dart';
import '../domain/shared_pack_ids.dart';
import '../domain/shared_pack_models.dart';
import '../domain/shared_pack_runtime_values.dart';
import 'shared_pack_commands.dart';
import 'shared_pack_outcomes.dart';

enum SharedRemoteOperation {
  createSharedPack,
  updateSharedPackMetadata,
  createSharedItem,
  updateSharedItem,
  archiveSharedItem,
  completeSharedItem,
  getOrCreateInviteCode,
  rotateInviteCode,
  previewInviteCode,
  joinSharedPack,
  getSharedPackSnapshot,
}

final class SharedItemVersionBase extends SharedValue {
  const SharedItemVersionBase({
    required this.remoteItemId,
    required this.itemVersion,
  });

  final RemoteItemId remoteItemId;
  final RemoteItemVersion itemVersion;

  @override
  List<Object?> get equalityFields => [remoteItemId, itemVersion];
}

final class SharedMutationBase extends SharedValue {
  SharedMutationBase({
    required this.remotePackId,
    required this.packVersion,
    required this.trust,
    required this.currentRole,
    required List<SharedItemVersionBase> itemVersions,
    required this.hasUnresolvedMutation,
  }) : itemVersions = List.unmodifiable(itemVersions);

  final RemotePackId remotePackId;
  final RemotePackVersion packVersion;
  final SharedCacheTrust trust;
  final SharedRole currentRole;
  final List<SharedItemVersionBase> itemVersions;
  final bool hasUnresolvedMutation;

  @override
  List<Object?> get equalityFields => [
    remotePackId,
    packVersion,
    trust,
    currentRole,
    itemVersions,
    hasUnresolvedMutation,
  ];
}

final class SharedTrustRecord extends SharedValue {
  SharedTrustRecord({required this.state, this.reason}) {
    if ((state == SharedCacheTrust.verified) != (reason == null)) {
      throw ArgumentError('Verified is the only trust state without a reason');
    }
  }

  final SharedCacheTrust state;
  final SharedTrustFailureReason? reason;

  @override
  List<Object?> get equalityFields => [state, reason];
}

enum SharedPendingMutationStatus { awaitingResolution }

final class SharedPendingMutationKey extends SharedValue {
  const SharedPendingMutationKey({
    required this.operation,
    required this.clientRequestId,
  });

  final SharedMutationOperation operation;
  final ClientRequestId clientRequestId;

  @override
  List<Object?> get equalityFields => [operation, clientRequestId];
}

/// Durable marker contract. It deliberately contains no executable payload.
final class SharedPendingMutationMarker extends SharedValue {
  const SharedPendingMutationMarker({
    required this.operation,
    required this.clientRequestId,
    required this.payloadFingerprint,
    this.targetRemotePackId,
    required this.createdAt,
    this.status = SharedPendingMutationStatus.awaitingResolution,
  });

  final SharedMutationOperation operation;
  final ClientRequestId clientRequestId;
  final SharedPayloadFingerprint payloadFingerprint;
  final RemotePackId? targetRemotePackId;
  final UtcInstant createdAt;
  final SharedPendingMutationStatus status;

  SharedPendingMutationKey get key => SharedPendingMutationKey(
    operation: operation,
    clientRequestId: clientRequestId,
  );

  @override
  List<Object?> get equalityFields => [
    operation,
    clientRequestId,
    payloadFingerprint,
    targetRemotePackId,
    createdAt,
    status,
  ];
}

sealed class SharedPendingResolutionProof extends SharedValue {
  const SharedPendingResolutionProof();
}

final class ProjectionCommittedProof extends SharedPendingResolutionProof {
  const ProjectionCommittedProof();

  @override
  List<Object?> get equalityFields => const [];
}

final class ConfirmedNoDispatchProof extends SharedPendingResolutionProof {
  const ConfirmedNoDispatchProof();

  @override
  List<Object?> get equalityFields => const [];
}

final class TerminalRemoteRejectionProof extends SharedPendingResolutionProof {
  const TerminalRemoteRejectionProof(this.code);

  final RemoteErrorCode code;

  @override
  List<Object?> get equalityFields => [code];
}

final class InviteResultHandledProof extends SharedPendingResolutionProof {
  const InviteResultHandledProof();

  @override
  List<Object?> get equalityFields => const [];
}

final class EffectSatisfiedProof extends SharedPendingResolutionProof {
  const EffectSatisfiedProof();

  @override
  List<Object?> get equalityFields => const [];
}

final class SharedNotModifiedRequestContext extends SharedValue {
  const SharedNotModifiedRequestContext({
    required this.remotePackId,
    required this.sentKnownPackVersion,
  });

  final RemotePackId remotePackId;
  final RemotePackVersion sentKnownPackVersion;

  @override
  List<Object?> get equalityFields => [remotePackId, sentKnownPackVersion];
}

enum SharedProjectionSuccessTrust { verified }

sealed class SharedLocalPortResult<T> extends SharedValue {
  const SharedLocalPortResult();
}

final class SharedLocalPortSuccess<T> extends SharedLocalPortResult<T> {
  const SharedLocalPortSuccess(this.value);

  final T value;

  @override
  List<Object?> get equalityFields => [value];
}

final class SharedLocalPortFailure<T> extends SharedLocalPortResult<T> {
  const SharedLocalPortFailure(this.family);

  final SharedLocalPortFailureFamily family;

  @override
  List<Object?> get equalityFields => [family];
}

enum SharedLocalPortFailureFamily { readFailed, writeFailed, commitFailed }

final class SharedIdentity extends SharedValue {
  const SharedIdentity({required this.id});

  final SharedIdentityId id;

  @override
  List<Object?> get equalityFields => [id];
}

sealed class SharedIdentityResult extends SharedValue {
  const SharedIdentityResult();
}

final class IdentityReady extends SharedIdentityResult {
  const IdentityReady(this.identity);

  final SharedIdentity identity;

  @override
  List<Object?> get equalityFields => [identity];
}

final class IdentityUnavailable extends SharedIdentityResult {
  const IdentityUnavailable();

  @override
  List<Object?> get equalityFields => const [];
}

final class SharedPrePackIntentKey extends SharedValue {
  const SharedPrePackIntentKey({
    required this.operation,
    required this.clientRequestId,
  });

  final SharedMutationOperation operation;
  final ClientRequestId clientRequestId;

  @override
  List<Object?> get equalityFields => [operation, clientRequestId];
}

enum SharedDiagnosticEventType {
  laneQueued,
  laneAcquired,
  laneReleased,
  pendingInserted,
  pendingRetained,
  pendingResolved,
  dispatchNotAttempted,
  dispatchConfirmedNoSend,
  dispatchAmbiguous,
  remoteSemanticResult,
  projectorOutcome,
  trustTransition,
  sameIdReplay,
  duplicateCoalesced,
  fingerprintMismatch,
  recoveryProofAccepted,
  recoveryProofRejected,
  uiActionCategory,
}

/// Allowlisted diagnostic event; all identifier fields are already redacted.
final class SharedDiagnosticEvent extends SharedValue {
  SharedDiagnosticEvent({
    required this.type,
    required this.operation,
    this.redactedPackId,
    this.redactedRequestId,
    this.packVersion,
    this.itemVersion,
    required this.stableCode,
    this.duration,
    required this.correlationId,
  }) {
    if (operation.isEmpty || stableCode.isEmpty || correlationId.isEmpty) {
      throw ArgumentError('Diagnostic identifiers must not be empty');
    }
  }

  final SharedDiagnosticEventType type;
  final String operation;
  final String? redactedPackId;
  final String? redactedRequestId;
  final RemotePackVersion? packVersion;
  final RemoteItemVersion? itemVersion;
  final String stableCode;
  final Duration? duration;
  final String correlationId;

  @override
  List<Object?> get equalityFields => [
    type,
    operation,
    redactedPackId,
    redactedRequestId,
    packVersion,
    itemVersion,
    stableCode,
    duration,
    correlationId,
  ];
}

enum SharedUserMessageCategory {
  needsRevalidation,
  remoteOutcomeUnknown,
  remoteSuccessLocalFailure,
  staleMutationBase,
  inaccessible,
  identityUnavailable,
  rateLimited,
  unsupportedApi,
  unsupportedSnapshot,
  invalidInvite,
  alreadyMember,
  validationField,
  confirmedNoDispatchTransport,
  mayHaveDispatchedTransport,
  idempotencyConflict,
  internalReturnedNoEffect,
}

enum SharedUserMessageSeverity { neutral, recovery, error }

final class SharedUserMessage extends SharedValue {
  const SharedUserMessage({required this.category, required this.severity});

  final SharedUserMessageCategory category;
  final SharedUserMessageSeverity severity;

  @override
  List<Object?> get equalityFields => [category, severity];
}

final class SharedOutcomeView extends SharedValue {
  const SharedOutcomeView({
    required this.dispatch,
    required this.remote,
    required this.local,
    required this.trust,
    required this.next,
  });

  final DispatchCertainty dispatch;
  final RemoteSemanticOutcome remote;
  final LocalProjectionOutcome local;
  final TrustOutcome trust;
  final NextAllowedAction next;

  @override
  List<Object?> get equalityFields => [dispatch, remote, local, trust, next];
}
