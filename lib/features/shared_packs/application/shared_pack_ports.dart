import 'dart:async';

import '../domain/shared_pack_errors.dart';
import '../domain/shared_pack_ids.dart';
import '../domain/shared_pack_models.dart';
import '../domain/shared_pack_runtime_values.dart';
import 'shared_pack_commands.dart';
import 'shared_pack_outcomes.dart';
import 'shared_pack_read_models.dart';
import 'shared_pack_remote_contracts.dart';
import 'shared_pack_runtime_types.dart';

abstract interface class SharedCacheReadPort {
  Stream<SharedPackListReadModel> watchPackList();

  Stream<SharedPackDetailReadModel?> watchPackDetail(RemotePackId packId);

  Future<SharedLocalPortResult<SharedMutationBase?>> readMutationBase(
    RemotePackId packId,
  );

  Stream<List<SharedPendingMutationMarker>> watchRecoveryMarkers();
}

abstract interface class SharedProjectionPort {
  Future<LocalProjectionOutcome> projectFullSnapshot(
    SharedPackSnapshot snapshot,
    SharedProjectionSuccessTrust successTrust,
  );

  Future<LocalProjectionOutcome> verifyNotModified(
    SharedNotModifiedRequestContext context,
    NotModifiedRemoteSuccess response,
    SharedProjectionSuccessTrust successTrust,
  );
}

abstract interface class SharedTrustStatePort {
  Future<SharedLocalPortResult<SharedTrustRecord?>> readTrust(
    RemotePackId packId,
  );

  Future<SharedLocalPortResult<void>> markNeedsRevalidation(
    RemotePackId packId,
    SharedTrustFailureReason reason,
  );

  Future<SharedLocalPortResult<void>> markInaccessible(
    RemotePackId packId,
    SharedTrustFailureReason reason,
  );
}

abstract interface class SharedPendingMutationPort {
  Future<SharedLocalPortResult<void>> insert(
    SharedPendingMutationMarker marker,
  );

  Future<SharedLocalPortResult<SharedPendingMutationMarker?>> getByKey(
    SharedPendingMutationKey key,
  );

  Future<SharedLocalPortResult<List<SharedPendingMutationMarker>>> getByPack(
    RemotePackId packId,
  );

  Future<SharedLocalPortResult<void>> updateLearnedPackTarget(
    SharedPendingMutationKey key,
    RemotePackId packId,
  );

  Stream<List<SharedPendingMutationMarker>> watchRecoveryMarkers();

  Future<SharedLocalPortResult<void>> resolve(
    SharedPendingMutationKey key,
    SharedPendingResolutionProof proof,
  );
}

abstract interface class SharedIdentityService {
  Future<SharedIdentityResult> currentIdentity();

  Future<SharedIdentityResult> ensureIdentity();
}

abstract interface class SharedRequestIdSource {
  ClientRequestId nextUuidV4();
}

abstract interface class SharedUtcClock {
  UtcInstant nowUtc();
}

abstract interface class SharedPayloadFingerprintService {
  SharedPayloadFingerprint fingerprint(SharedMutationCommand command);
}

abstract interface class SharedPackCoordinator {
  Future<T> runInPackLane<T>(RemotePackId packId, Future<T> Function() work);

  Future<T> runPrePackIntent<T>(
    SharedPrePackIntentKey key,
    Future<T> Function() work,
  );
}

abstract interface class SharedDiagnosticSink {
  FutureOr<void> record(SharedDiagnosticEvent event);
}

abstract interface class SharedDiagnosticRedactor {
  SharedDiagnosticEvent redact({
    required SharedDiagnosticEventType type,
    required String operation,
    RemotePackId? packId,
    ClientRequestId? requestId,
    RemotePackVersion? packVersion,
    RemoteItemVersion? itemVersion,
    required String stableCode,
    Duration? duration,
    required String correlationId,
  });
}

abstract interface class SharedUserMessageMapper {
  SharedUserMessage map(SharedOutcomeView outcome);
}
