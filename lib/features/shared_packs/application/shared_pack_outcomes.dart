import '../domain/shared_equality.dart';
import '../domain/shared_pack_errors.dart';
import '../domain/shared_pack_models.dart';
import 'shared_pack_read_models.dart';

enum DispatchCertainty {
  notAttempted,
  confirmedNotDispatched,
  mayHaveDispatched,
  dispatched,
}

enum LocalProjectionOutcome {
  notRequired,
  committedInitial,
  committedNewer,
  verifiedSameVersion,
  ignoredOlder,
  verifiedNotModified,
  invalidSnapshot,
  unsupportedSnapshot,
  sameVersionConflict,
  integrityFailure,
  commitFailure,
  staleNotModified,
  missingNotModified,
  invalidNotModified,
}

enum PendingIntentOutcome {
  notCreated,
  insertedThenResolved,
  retained,
  deletedNoDispatch,
  retainedFingerprintMismatch,
  retainedIdempotencyConflict,
}

enum NextAllowedAction {
  correctInput,
  retryIdentity,
  newIntent,
  refresh,
  sameIdReplay,
  refreshOrSameIdReplay,
  accessRecheck,
  waitRetryAfter,
  updateApp,
  none,
}

sealed class RemoteSemanticOutcome extends SharedValue {
  const RemoteSemanticOutcome();
}

final class RemoteNotApplicable extends RemoteSemanticOutcome {
  const RemoteNotApplicable();

  @override
  List<Object?> get equalityFields => const [];
}

final class RemoteRejectedNoSideEffect extends RemoteSemanticOutcome {
  const RemoteRejectedNoSideEffect(this.code);

  final RemoteErrorCode code;

  @override
  List<Object?> get equalityFields => [code];
}

final class RemoteSucceeded extends RemoteSemanticOutcome {
  const RemoteSucceeded({required this.replayed});

  final bool replayed;

  @override
  List<Object?> get equalityFields => [replayed];
}

final class RemoteOutcomeUnknown extends RemoteSemanticOutcome {
  const RemoteOutcomeUnknown();

  @override
  List<Object?> get equalityFields => const [];
}

final class RemoteIdempotencyConflict extends RemoteSemanticOutcome {
  const RemoteIdempotencyConflict();

  @override
  List<Object?> get equalityFields => const [];
}

sealed class TrustOutcome extends SharedValue {
  const TrustOutcome();
}

final class TrustUnchanged extends TrustOutcome {
  const TrustUnchanged(this.state);

  final SharedCacheTrust state;

  @override
  List<Object?> get equalityFields => [state];
}

final class TrustBecameVerified extends TrustOutcome {
  const TrustBecameVerified();

  @override
  List<Object?> get equalityFields => const [];
}

final class TrustBecameNeedsRevalidation extends TrustOutcome {
  const TrustBecameNeedsRevalidation(this.reason);

  final SharedTrustFailureReason reason;

  @override
  List<Object?> get equalityFields => [reason];
}

final class TrustBecameInaccessible extends TrustOutcome {
  const TrustBecameInaccessible(this.reason);

  final SharedTrustFailureReason reason;

  @override
  List<Object?> get equalityFields => [reason];
}

final class TrustDurableMarkFailedEffectiveBlock extends TrustOutcome {
  const TrustDurableMarkFailedEffectiveBlock();

  @override
  List<Object?> get equalityFields => const [];
}

/// Immutable six-axis application command result from the Phase 1f contract.
final class SharedCommandOutcome<T> extends SharedValue {
  const SharedCommandOutcome({
    required this.dispatch,
    required this.remote,
    required this.local,
    required this.trust,
    required this.pending,
    required this.next,
    this.value,
    required this.mayNavigateToNormalDetail,
    this.failure,
  });

  final DispatchCertainty dispatch;
  final RemoteSemanticOutcome remote;
  final LocalProjectionOutcome local;
  final TrustOutcome trust;
  final PendingIntentOutcome pending;
  final NextAllowedAction next;
  final T? value;
  final bool mayNavigateToNormalDetail;
  final SharedApplicationFailure? failure;

  @override
  List<Object?> get equalityFields => [
    dispatch,
    remote,
    local,
    trust,
    pending,
    next,
    value,
    mayNavigateToNormalDetail,
    failure,
  ];
}

sealed class SharedQueryOutcome<T> extends SharedValue {
  const SharedQueryOutcome();
}

final class SharedQuerySuccess<T> extends SharedQueryOutcome<T> {
  const SharedQuerySuccess(this.value);

  final T value;

  @override
  List<Object?> get equalityFields => [value];
}

final class SharedQueryFailure<T> extends SharedQueryOutcome<T> {
  const SharedQueryFailure(this.failure);

  final SharedApplicationFailure failure;

  @override
  List<Object?> get equalityFields => [failure];
}

final class SharedRefreshOutcome extends SharedValue {
  const SharedRefreshOutcome({
    required this.dispatch,
    required this.remote,
    required this.local,
    required this.trust,
    required this.next,
    this.presentation,
    this.failure,
  });

  final DispatchCertainty dispatch;
  final RemoteSemanticOutcome remote;
  final LocalProjectionOutcome local;
  final TrustOutcome trust;
  final NextAllowedAction next;
  final SharedRefreshResultPresentation? presentation;
  final SharedApplicationFailure? failure;

  @override
  List<Object?> get equalityFields => [
    dispatch,
    remote,
    local,
    trust,
    next,
    presentation,
    failure,
  ];
}
