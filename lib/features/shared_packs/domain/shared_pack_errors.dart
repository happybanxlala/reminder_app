import 'shared_equality.dart';

/// Exact persisted trust-failure vocabulary owned by the runtime contract.
enum SharedTrustFailureReason {
  remoteOutcomeUnknown,
  projectionFailed,
  snapshotValidationFailed,
  unsupportedSnapshotSchema,
  sameVersionContentConflict,
  snapshotIntegrityFailed,
  staleMutationBase,
  permissionDenied,
  packNotFound,
}

/// Stable remote semantic error catalog. These are values, not exceptions.
enum RemoteErrorCode {
  permissionDenied,
  packNotFound,
  itemNotFound,
  itemArchived,
  staleVersion,
  validationFailed,
  unsupportedItemType,
  invalidInviteCode,
  alreadyMember,
  idempotencyConflict,
  rateLimited,
  unsupportedRemoteApiContractVersion,
  unsupportedRemoteSnapshotSchemaVersion,
  versionExhausted,
  internalError,
}

sealed class SharedApplicationFailure extends SharedValue {
  const SharedApplicationFailure();
}

final class SharedValidationFailure extends SharedApplicationFailure {
  const SharedValidationFailure(this.field);

  final String field;

  @override
  List<Object?> get equalityFields => [field];
}

final class SharedIdentityFailure extends SharedApplicationFailure {
  const SharedIdentityFailure();

  @override
  List<Object?> get equalityFields => const [];
}

enum SharedPreDispatchFailureFamily {
  identityUnavailable,
  localValidationFailed,
  transportConfirmedNoSend,
}

final class SharedPreDispatchFailure extends SharedApplicationFailure {
  const SharedPreDispatchFailure(this.family);

  final SharedPreDispatchFailureFamily family;

  @override
  List<Object?> get equalityFields => [family];
}

final class SharedTrustRequiredFailure extends SharedApplicationFailure {
  const SharedTrustRequiredFailure(this.reason);

  final SharedTrustFailureReason reason;

  @override
  List<Object?> get equalityFields => [reason];
}

final class SharedInaccessibleFailure extends SharedApplicationFailure {
  const SharedInaccessibleFailure(this.reason);

  final SharedTrustFailureReason reason;

  @override
  List<Object?> get equalityFields => [reason];
}

final class SharedRemoteRejectedFailure extends SharedApplicationFailure {
  const SharedRemoteRejectedFailure(this.code, {this.retryAfter});

  final RemoteErrorCode code;
  final Duration? retryAfter;

  @override
  List<Object?> get equalityFields => [code, retryAfter];
}

final class SharedOutcomeUncertainFailure extends SharedApplicationFailure {
  const SharedOutcomeUncertainFailure();

  @override
  List<Object?> get equalityFields => const [];
}

enum SharedContractFailureFamily {
  invalidRemoteEnvelope,
  responseDecodeFailed,
  snapshotValidationFailed,
  unsupportedSnapshotSchema,
  sameVersionContentConflict,
  snapshotIntegrityFailed,
}

final class SharedContractFailure extends SharedApplicationFailure {
  const SharedContractFailure(this.family);

  final SharedContractFailureFamily family;

  @override
  List<Object?> get equalityFields => [family];
}

final class SharedLocalProjectionFailure extends SharedApplicationFailure {
  const SharedLocalProjectionFailure();

  @override
  List<Object?> get equalityFields => const [];
}
