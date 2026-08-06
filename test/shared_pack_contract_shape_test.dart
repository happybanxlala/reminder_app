import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:reminder_app/features/shared_packs/application/shared_pack_application_service.dart';
import 'package:reminder_app/features/shared_packs/application/shared_pack_commands.dart';
import 'package:reminder_app/features/shared_packs/application/shared_pack_outcomes.dart';
import 'package:reminder_app/features/shared_packs/application/shared_pack_ports.dart';
import 'package:reminder_app/features/shared_packs/application/shared_pack_queries.dart';
import 'package:reminder_app/features/shared_packs/application/shared_pack_read_models.dart';
import 'package:reminder_app/features/shared_packs/application/shared_pack_remote_contracts.dart';
import 'package:reminder_app/features/shared_packs/application/shared_pack_runtime_types.dart';
import 'package:reminder_app/features/shared_packs/data/remote/shared_pack_remote_dtos.dart';
import 'package:reminder_app/features/shared_packs/domain/shared_pack_errors.dart';
import 'package:reminder_app/features/shared_packs/domain/shared_pack_ids.dart';
import 'package:reminder_app/features/shared_packs/domain/shared_pack_models.dart';
import 'package:reminder_app/features/shared_packs/domain/shared_pack_runtime_values.dart';

void main() {
  test('application facade can be implemented by an independent stub', () {
    final SharedPackApplicationService service = _ApplicationStub();
    expect(service.watchPackList(), emitsDone);
    expect(service.watchRecovery(), emitsDone);
  });

  test('every inward-facing port can be faked independently', () {
    final ports = <Object>[
      _CacheReadPortFake(),
      _ProjectionPortFake(),
      _TrustStatePortFake(),
      _PendingMutationPortFake(),
      _RemoteApiFake(),
      _IdentityServiceFake(),
      _RequestIdSourceFake(),
      _UtcClockFake(),
      _FingerprintServiceFake(),
      _CoordinatorFake(),
      _DiagnosticSinkFake(),
      _MessageMapperFake(),
    ];
    expect(ports, hasLength(12));
  });

  test('remote result variants are exhaustively distinguishable', () {
    String classify(RemoteCallResult<int> result) => switch (result) {
      RemoteSuccess<int>() => 'success',
      RemoteRejected<int>() => 'rejected',
      RemoteTransportFailure<int>() => 'transport',
      RemoteDecodeFailure<int>() => 'decode',
    };

    expect(classify(const RemoteSuccess<int>(1, replayed: false)), 'success');
    expect(
      classify(const RemoteRejected<int>(RemoteErrorCode.permissionDenied)),
      'rejected',
    );
    expect(
      classify(
        const RemoteTransportFailure<int>(
          certainty: DispatchCertainty.mayHaveDispatched,
          family: TransportFailureFamily.timeout,
        ),
      ),
      'transport',
    );
    expect(
      classify(
        const RemoteDecodeFailure<int>(certainty: DispatchCertainty.dispatched),
      ),
      'decode',
    );
  });

  test('remote success and local projection failure stay separate', () {
    const outcome = SharedCommandOutcome<void>(
      dispatch: DispatchCertainty.dispatched,
      remote: RemoteSucceeded(replayed: false),
      local: LocalProjectionOutcome.commitFailure,
      trust: TrustBecameNeedsRevalidation(
        SharedTrustFailureReason.projectionFailed,
      ),
      pending: PendingIntentOutcome.retained,
      next: NextAllowedAction.refreshOrSameIdReplay,
      mayNavigateToNormalDetail: false,
      failure: SharedLocalProjectionFailure(),
    );

    expect(outcome.remote, isA<RemoteSucceeded>());
    expect(outcome.local, LocalProjectionOutcome.commitFailure);
    expect(outcome.mayNavigateToNormalDetail, isFalse);
  });

  test('invite-only and snapshot success contracts are distinct', () {
    const invite = InviteCodeRemoteSuccess(
      normalizedInviteCode: 'K7M4Q9',
      displayInviteCode: 'K7M 4Q9',
    );
    expect(invite, isNot(isA<SnapshotMutationRemoteSuccess>()));
    expect(invite.normalizedInviteCode, 'K7M4Q9');
  });

  test('wire envelopes keep success and stable failure typed', () {
    final success = SharedRemoteSuccessEnvelopeDto<int>(
      remoteApiContractVersion: RemoteApiContractVersion.v1,
      correlationId: 'correlation-1',
      data: 7,
    );
    final failure = SharedRemoteFailureEnvelopeDto<int>(
      remoteApiContractVersion: RemoteApiContractVersion.v1,
      correlationId: 'correlation-2',
      error: const SharedRemoteErrorEnvelopeDto(
        code: RemoteErrorCode.staleVersion,
        sideEffect: SharedRemoteFailureSideEffect.none,
      ),
    );

    expect(success.data, 7);
    expect(failure.error.code, RemoteErrorCode.staleVersion);
    expect(success, isNot(isA<SharedRemoteFailureEnvelopeDto<int>>()));
  });
}

final class _ApplicationStub implements SharedPackApplicationService {
  @override
  Stream<SharedPackListReadModel> watchPackList() => const Stream.empty();

  @override
  Stream<SharedPackDetailReadModel?> watchPackDetail(RemotePackId packId) =>
      const Stream.empty();

  @override
  Stream<UnresolvedMutationPresentation> watchRecovery() =>
      const Stream.empty();

  @override
  Future<SharedCommandOutcome<ArchivedSharedItemResult>> archiveSharedItem(
    ArchiveSharedItemCommand command,
  ) => throw UnsupportedError('stub');

  @override
  Future<SharedCommandOutcome<SharedItemReadModel>> completeSharedItem(
    CompleteSharedItemCommand command,
  ) => throw UnsupportedError('stub');

  @override
  Future<SharedCommandOutcome<SharedItemReadModel>> createSharedItem(
    CreateSharedItemCommand command,
  ) => throw UnsupportedError('stub');

  @override
  Future<SharedCommandOutcome<SharedPackDetailReadModel>> createSharedPack(
    CreateSharedPackCommand command,
  ) => throw UnsupportedError('stub');

  @override
  Future<SharedCommandOutcome<InviteCodePresentation>> getOrCreateInviteCode(
    GetInviteCommand command,
  ) => throw UnsupportedError('stub');

  @override
  Future<SharedCommandOutcome<SharedPackDetailReadModel>> joinSharedPack(
    JoinSharedPackCommand command,
  ) => throw UnsupportedError('stub');

  @override
  Future<SharedQueryOutcome<InvitePreview>> previewInviteCode(
    PreviewInviteQuery query,
  ) => throw UnsupportedError('stub');

  @override
  Future<SharedRefreshOutcome> refreshSharedPack(
    RefreshSharedPackCommand command,
  ) => throw UnsupportedError('stub');

  @override
  Future<SharedCommandOutcome<Object?>> replayUnresolvedMutation(
    ReplayUnresolvedMutationCommand command,
  ) => throw UnsupportedError('stub');

  @override
  Future<SharedCommandOutcome<InviteCodePresentation>> rotateInviteCode(
    RotateInviteCommand command,
  ) => throw UnsupportedError('stub');

  @override
  Future<SharedCommandOutcome<SharedItemReadModel>> updateSharedItem(
    UpdateSharedItemCommand command,
  ) => throw UnsupportedError('stub');

  @override
  Future<SharedCommandOutcome<SharedPackDetailReadModel>>
  updateSharedPackMetadata(UpdateSharedPackMetadataCommand command) =>
      throw UnsupportedError('stub');
}

final class _CacheReadPortFake implements SharedCacheReadPort {
  @override
  Future<SharedLocalPortResult<SharedMutationBase?>> readMutationBase(
    RemotePackId packId,
  ) async => const SharedLocalPortSuccess(null);

  @override
  Stream<SharedPackDetailReadModel?> watchPackDetail(RemotePackId packId) =>
      const Stream.empty();

  @override
  Stream<SharedPackListReadModel> watchPackList() => const Stream.empty();

  @override
  Stream<List<SharedPendingMutationMarker>> watchRecoveryMarkers() =>
      const Stream.empty();
}

final class _ProjectionPortFake implements SharedProjectionPort {
  @override
  Future<LocalProjectionOutcome> projectFullSnapshot(
    SharedPackSnapshot snapshot,
    SharedProjectionSuccessTrust successTrust,
  ) async => LocalProjectionOutcome.committedInitial;

  @override
  Future<LocalProjectionOutcome> verifyNotModified(
    SharedNotModifiedRequestContext context,
    NotModifiedRemoteSuccess response,
    SharedProjectionSuccessTrust successTrust,
  ) async => LocalProjectionOutcome.verifiedNotModified;
}

final class _TrustStatePortFake implements SharedTrustStatePort {
  @override
  Future<SharedLocalPortResult<void>> markInaccessible(
    RemotePackId packId,
    SharedTrustFailureReason reason,
  ) async => const SharedLocalPortSuccess(null);

  @override
  Future<SharedLocalPortResult<void>> markNeedsRevalidation(
    RemotePackId packId,
    SharedTrustFailureReason reason,
  ) async => const SharedLocalPortSuccess(null);

  @override
  Future<SharedLocalPortResult<SharedTrustRecord?>> readTrust(
    RemotePackId packId,
  ) async => const SharedLocalPortSuccess(null);
}

final class _PendingMutationPortFake implements SharedPendingMutationPort {
  @override
  Future<SharedLocalPortResult<List<SharedPendingMutationMarker>>> getByPack(
    RemotePackId packId,
  ) async => const SharedLocalPortSuccess([]);

  @override
  Future<SharedLocalPortResult<SharedPendingMutationMarker?>> getByKey(
    SharedPendingMutationKey key,
  ) async => const SharedLocalPortSuccess(null);

  @override
  Future<SharedLocalPortResult<void>> insert(
    SharedPendingMutationMarker marker,
  ) async => const SharedLocalPortSuccess(null);

  @override
  Future<SharedLocalPortResult<void>> resolve(
    SharedPendingMutationKey key,
    SharedPendingResolutionProof proof,
  ) async => const SharedLocalPortSuccess(null);

  @override
  Future<SharedLocalPortResult<void>> updateLearnedPackTarget(
    SharedPendingMutationKey key,
    RemotePackId packId,
  ) async => const SharedLocalPortSuccess(null);

  @override
  Stream<List<SharedPendingMutationMarker>> watchRecoveryMarkers() =>
      const Stream.empty();
}

final class _RemoteApiFake implements SharedPackRemoteApi {
  Future<RemoteCallResult<T>> _result<T>() async =>
      const RemoteRejected(RemoteErrorCode.internalError);

  @override
  Future<RemoteCallResult<SnapshotMutationRemoteSuccess>> archiveSharedItem(
    ArchiveItemRemoteRequest request,
  ) => _result();

  @override
  Future<RemoteCallResult<SnapshotMutationRemoteSuccess>> completeSharedItem(
    CompleteItemRemoteRequest request,
  ) => _result();

  @override
  Future<RemoteCallResult<SnapshotMutationRemoteSuccess>> createSharedItem(
    CreateItemRemoteRequest request,
  ) => _result();

  @override
  Future<RemoteCallResult<CreatePackRemoteSuccess>> createSharedPack(
    CreatePackRemoteRequest request,
  ) => _result();

  @override
  Future<RemoteCallResult<InviteCodeRemoteSuccess>> getOrCreateInviteCode(
    GetInviteRemoteRequest request,
  ) => _result();

  @override
  Future<RemoteCallResult<SnapshotReadRemoteSuccess>> getSharedPackSnapshot(
    GetSnapshotRemoteRequest request,
  ) => _result();

  @override
  Future<RemoteCallResult<JoinRemoteSuccess>> joinSharedPack(
    JoinRemoteRequest request,
  ) => _result();

  @override
  Future<RemoteCallResult<InvitePreviewRemoteSuccess>> previewInviteCode(
    PreviewInviteRemoteRequest request,
  ) => _result();

  @override
  Future<RemoteCallResult<InviteCodeRemoteSuccess>> rotateInviteCode(
    RotateInviteRemoteRequest request,
  ) => _result();

  @override
  Future<RemoteCallResult<SnapshotMutationRemoteSuccess>> updateSharedItem(
    UpdateItemRemoteRequest request,
  ) => _result();

  @override
  Future<RemoteCallResult<SnapshotMutationRemoteSuccess>>
  updateSharedPackMetadata(UpdatePackRemoteRequest request) => _result();
}

final class _IdentityServiceFake implements SharedIdentityService {
  @override
  Future<SharedIdentityResult> currentIdentity() async =>
      IdentityReady(SharedIdentity(id: SharedIdentityId('identity')));

  @override
  Future<SharedIdentityResult> ensureIdentity() => currentIdentity();
}

final class _RequestIdSourceFake implements SharedRequestIdSource {
  @override
  ClientRequestId nextUuidV4() =>
      ClientRequestId('123e4567-e89b-42d3-a456-426614174000');
}

final class _UtcClockFake implements SharedUtcClock {
  @override
  UtcInstant nowUtc() => UtcInstant(DateTime.utc(2030));
}

final class _FingerprintServiceFake implements SharedPayloadFingerprintService {
  @override
  SharedPayloadFingerprint fingerprint(SharedMutationCommand command) =>
      SharedPayloadFingerprint('00000000000000000000000000000000');
}

final class _CoordinatorFake implements SharedPackCoordinator {
  @override
  Future<T> runInPackLane<T>(RemotePackId packId, Future<T> Function() work) =>
      work();

  @override
  Future<T> runPrePackIntent<T>(
    SharedPrePackIntentKey key,
    Future<T> Function() work,
  ) => work();
}

final class _DiagnosticSinkFake implements SharedDiagnosticSink {
  @override
  FutureOr<void> record(SharedDiagnosticEvent event) {}
}

final class _MessageMapperFake implements SharedUserMessageMapper {
  @override
  SharedUserMessage map(SharedOutcomeView outcome) => const SharedUserMessage(
    category: SharedUserMessageCategory.remoteOutcomeUnknown,
    severity: SharedUserMessageSeverity.recovery,
  );
}
