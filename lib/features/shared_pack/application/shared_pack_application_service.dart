import '../data/shared_pack_cache_projection_service.dart';
import '../remote/shared_pack_remote_dto.dart';
import '../remote/shared_pack_remote_repository.dart';
import '../remote/shared_pack_remote_request_ids.dart';
import 'shared_pack_application_result.dart';
import 'shared_pack_identity_provider.dart';

class SharedPackApplicationService {
  const SharedPackApplicationService({
    required SharedPackRemoteRepository remoteRepository,
    required SharedPackCacheProjectionService cacheProjectionService,
    required SharedPackIdentityProvider identityProvider,
  }) : _remoteRepository = remoteRepository,
       _cacheProjectionService = cacheProjectionService,
       _identityProvider = identityProvider;

  final SharedPackRemoteRepository _remoteRepository;
  final SharedPackCacheProjectionService _cacheProjectionService;
  final SharedPackIdentityProvider _identityProvider;

  Future<SharedPackApplicationResult<CreateSharedPackApplicationSuccess>>
  createSharedPack({required String packName}) async {
    final normalizedPackName = packName.trim();
    if (normalizedPackName.isEmpty) {
      return _failure(
        code: SharedPackApplicationErrorCode.invalidInput,
        message: 'Shared Pack name is required.',
      );
    }

    final identity =
        await _currentIdentity<CreateSharedPackApplicationSuccess>();
    if (identity.result != null) {
      return identity.result!;
    }

    const requestId = SharedPackRemoteRequestIds.createPackV1;
    late final CreateSharedPackRemoteResponse remoteResponse;
    try {
      remoteResponse = await _remoteRepository.createPack(
        CreateSharedPackRemoteRequest(
          name: normalizedPackName,
          ownerIdentityId: identity.value!,
        ),
      );
    } on SharedPackRemoteException catch (error) {
      return _remoteFailure(error);
    } catch (error) {
      return _failure(
        code: SharedPackApplicationErrorCode.remoteFailure,
        message: 'Shared Pack create request failed.',
        requestId: requestId,
        cause: error,
      );
    }

    try {
      final projection = await _cacheProjectionService.projectPackShell(
        remotePackId: remoteResponse.remotePackId,
        packName: remoteResponse.name,
      );

      return SharedPackApplicationResult.success(
        CreateSharedPackApplicationSuccess(
          remoteResponse: remoteResponse,
          projection: projection,
        ),
      );
    } catch (error) {
      return _failure(
        code: SharedPackApplicationErrorCode.projectionFailure,
        message: 'Shared Pack create projection failed.',
        requestId: requestId,
        cause: error,
      );
    }
  }

  Future<SharedPackApplicationResult<GenerateSharedPackInviteRemoteResponse>>
  generateInvite({int? localPackId, String? remotePackId}) async {
    final resolvedRemotePackId =
        await _resolveRemotePackId<GenerateSharedPackInviteRemoteResponse>(
          localPackId: localPackId,
          remotePackId: remotePackId,
        );
    if (resolvedRemotePackId.result != null) {
      return resolvedRemotePackId.result!;
    }

    final identity =
        await _currentIdentity<GenerateSharedPackInviteRemoteResponse>();
    if (identity.result != null) {
      return identity.result!;
    }

    const requestId = SharedPackRemoteRequestIds.generateInviteV1;
    try {
      final remoteResponse = await _remoteRepository.generateInvite(
        GenerateSharedPackInviteRemoteRequest(
          remotePackId: resolvedRemotePackId.value!,
          requesterIdentityId: identity.value!,
        ),
      );
      return SharedPackApplicationResult.success(remoteResponse);
    } on SharedPackRemoteException catch (error) {
      return _remoteFailure(error);
    } catch (error) {
      return _failure(
        code: SharedPackApplicationErrorCode.remoteFailure,
        message: 'Shared Pack invite generation failed.',
        requestId: requestId,
        cause: error,
      );
    }
  }

  Future<SharedPackApplicationResult<PreviewSharedPackInviteRemoteResponse>>
  previewInvite({required String inviteCode}) async {
    if (inviteCode.trim().isEmpty) {
      return _failure(
        code: SharedPackApplicationErrorCode.invalidInput,
        message: 'Shared Pack invite code is required.',
      );
    }

    const requestId = SharedPackRemoteRequestIds.previewInviteV1;
    try {
      final remoteResponse = await _remoteRepository.previewInvite(
        PreviewSharedPackInviteRemoteRequest(inviteCode: inviteCode),
      );
      return SharedPackApplicationResult.success(remoteResponse);
    } on SharedPackRemoteException catch (error) {
      return _remoteFailure(error);
    } catch (error) {
      return _failure(
        code: SharedPackApplicationErrorCode.remoteFailure,
        message: 'Shared Pack invite preview failed.',
        requestId: requestId,
        cause: error,
      );
    }
  }

  Future<SharedPackApplicationResult<JoinSharedPackApplicationSuccess>>
  joinByInvite({required String inviteCode}) async {
    if (inviteCode.trim().isEmpty) {
      return _failure(
        code: SharedPackApplicationErrorCode.invalidInput,
        message: 'Shared Pack invite code is required.',
      );
    }

    final identity = await _currentIdentity<JoinSharedPackApplicationSuccess>();
    if (identity.result != null) {
      return identity.result!;
    }

    const requestId = SharedPackRemoteRequestIds.joinByInviteV1;
    late final JoinSharedPackByInviteRemoteResponse remoteResponse;
    try {
      remoteResponse = await _remoteRepository.joinByInvite(
        JoinSharedPackByInviteRemoteRequest(
          inviteCode: inviteCode,
          joinerIdentityId: identity.value!,
        ),
      );
    } on SharedPackRemoteException catch (error) {
      return _remoteFailure(error);
    } catch (error) {
      return _failure(
        code: SharedPackApplicationErrorCode.remoteFailure,
        message: 'Shared Pack join request failed.',
        requestId: requestId,
        cause: error,
      );
    }

    try {
      final projection = await _cacheProjectionService.projectPackShell(
        remotePackId: remoteResponse.remotePackId,
        packName: remoteResponse.packName,
      );

      return SharedPackApplicationResult.success(
        JoinSharedPackApplicationSuccess(
          remoteResponse: remoteResponse,
          projection: projection,
          refreshRecommended: true,
        ),
      );
    } catch (error) {
      return _failure(
        code: SharedPackApplicationErrorCode.projectionFailure,
        message: 'Shared Pack join projection failed.',
        requestId: requestId,
        cause: error,
      );
    }
  }

  Future<SharedPackApplicationResult<SharedPackCacheProjectionResult>>
  refreshSharedPack({int? localPackId, String? remotePackId}) async {
    final resolvedRemotePackId =
        await _resolveRemotePackId<SharedPackCacheProjectionResult>(
          localPackId: localPackId,
          remotePackId: remotePackId,
        );
    if (resolvedRemotePackId.result != null) {
      return resolvedRemotePackId.result!;
    }

    final identity = await _currentIdentity<SharedPackCacheProjectionResult>();
    if (identity.result != null) {
      return identity.result!;
    }

    const requestId = SharedPackRemoteRequestIds.fetchSnapshotV1;
    late final FetchSharedPackSnapshotRemoteResponse remoteResponse;
    try {
      remoteResponse = await _remoteRepository.fetchSnapshot(
        FetchSharedPackSnapshotRemoteRequest(
          remotePackId: resolvedRemotePackId.value!,
          requesterIdentityId: identity.value!,
        ),
      );
    } on SharedPackRemoteException catch (error) {
      return _remoteFailure(error);
    } catch (error) {
      return _failure(
        code: SharedPackApplicationErrorCode.remoteFailure,
        message: 'Shared Pack snapshot request failed.',
        requestId: requestId,
        cause: error,
      );
    }

    try {
      final projection = await _cacheProjectionService.projectSnapshot(
        remoteResponse,
      );
      return SharedPackApplicationResult.success(projection);
    } catch (error) {
      return _failure(
        code: SharedPackApplicationErrorCode.projectionFailure,
        message: 'Shared Pack snapshot projection failed.',
        requestId: requestId,
        cause: error,
      );
    }
  }

  Future<SharedPackApplicationResult<SharedPackItemStateProjectionResult>>
  updateSharedItemState({
    int? localItemId,
    String? remoteItemId,
    required String newState,
    DateTime? completedAt,
  }) async {
    final normalizedState = newState.trim();
    if (normalizedState.isEmpty) {
      return _failure(
        code: SharedPackApplicationErrorCode.invalidInput,
        message: 'Shared Pack item state is required.',
      );
    }

    final resolvedRemoteItemId =
        await _resolveRemoteItemId<SharedPackItemStateProjectionResult>(
          localItemId: localItemId,
          remoteItemId: remoteItemId,
        );
    if (resolvedRemoteItemId.result != null) {
      return resolvedRemoteItemId.result!;
    }

    final identity =
        await _currentIdentity<SharedPackItemStateProjectionResult>();
    if (identity.result != null) {
      return identity.result!;
    }

    const requestId = SharedPackRemoteRequestIds.updateItemStateV1;
    late final UpdateSharedPackItemStateRemoteResponse remoteResponse;
    try {
      remoteResponse = await _remoteRepository.updateItemState(
        UpdateSharedPackItemStateRemoteRequest(
          remoteItemId: resolvedRemoteItemId.value!,
          requesterIdentityId: identity.value!,
          newState: normalizedState,
          completedAt: completedAt,
        ),
      );
    } on SharedPackRemoteException catch (error) {
      return _remoteFailure(error);
    } catch (error) {
      return _failure(
        code: SharedPackApplicationErrorCode.remoteFailure,
        message: 'Shared Pack item-state request failed.',
        requestId: requestId,
        cause: error,
      );
    }

    try {
      final projection = await _cacheProjectionService.projectItemState(
        remoteResponse,
      );
      return SharedPackApplicationResult.success(projection);
    } catch (error) {
      return _failure(
        code: SharedPackApplicationErrorCode.projectionFailure,
        message: 'Shared Pack item-state projection failed.',
        requestId: requestId,
        cause: error,
      );
    }
  }

  Future<_Resolution<T>> _currentIdentity<T>() async {
    try {
      final identityId = (await _identityProvider.currentIdentityId()).trim();
      if (identityId.isEmpty) {
        return _Resolution.result(
          _failure(
            code: SharedPackApplicationErrorCode.missingIdentity,
            message: 'Shared Pack identity is unavailable.',
          ),
        );
      }
      return _Resolution.value(identityId);
    } catch (error) {
      return _Resolution.result(
        _failure(
          code: SharedPackApplicationErrorCode.missingIdentity,
          message: 'Shared Pack identity is unavailable.',
          cause: error,
        ),
      );
    }
  }

  Future<_Resolution<T>> _resolveRemotePackId<T>({
    int? localPackId,
    String? remotePackId,
  }) async {
    final normalizedRemotePackId = remotePackId?.trim();
    if (normalizedRemotePackId != null && normalizedRemotePackId.isNotEmpty) {
      return _Resolution.value(normalizedRemotePackId);
    }

    if (localPackId == null) {
      return _Resolution.result(
        _failure(
          code: SharedPackApplicationErrorCode.invalidInput,
          message: 'Shared Pack id is required.',
        ),
      );
    }

    final mapping = await _cacheProjectionService
        .resolveRemotePackMappingByLocalPackId(localPackId);
    if (mapping == null) {
      return _Resolution.result(
        _failure(
          code: SharedPackApplicationErrorCode.missingPackMapping,
          message: 'Shared Pack mapping is unavailable.',
        ),
      );
    }

    return _Resolution.value(mapping.remotePackId);
  }

  Future<_Resolution<T>> _resolveRemoteItemId<T>({
    int? localItemId,
    String? remoteItemId,
  }) async {
    final normalizedRemoteItemId = remoteItemId?.trim();
    if (normalizedRemoteItemId != null && normalizedRemoteItemId.isNotEmpty) {
      return _Resolution.value(normalizedRemoteItemId);
    }

    if (localItemId == null) {
      return _Resolution.result(
        _failure(
          code: SharedPackApplicationErrorCode.invalidInput,
          message: 'Shared Pack item id is required.',
        ),
      );
    }

    final mapping = await _cacheProjectionService
        .resolveRemoteItemMappingByLocalItemId(localItemId);
    if (mapping == null) {
      return _Resolution.result(
        _failure(
          code: SharedPackApplicationErrorCode.missingItemMapping,
          message: 'Shared Pack item mapping is unavailable.',
        ),
      );
    }

    return _Resolution.value(mapping.remoteItemId);
  }

  SharedPackApplicationResult<T> _remoteFailure<T>(
    SharedPackRemoteException error,
  ) {
    return _failure(
      code: SharedPackApplicationErrorCode.remoteFailure,
      message: 'Shared Pack remote request failed.',
      requestId: error.requestId,
      cause: error,
    );
  }

  SharedPackApplicationResult<T> _failure<T>({
    required SharedPackApplicationErrorCode code,
    required String message,
    String? requestId,
    Object? cause,
  }) {
    return SharedPackApplicationResult.failure(
      SharedPackApplicationError(
        code: code,
        message: message,
        requestId: requestId,
        cause: cause,
      ),
    );
  }
}

class CreateSharedPackApplicationSuccess {
  const CreateSharedPackApplicationSuccess({
    required this.remoteResponse,
    required this.projection,
  });

  final CreateSharedPackRemoteResponse remoteResponse;
  final SharedPackPackShellProjectionResult projection;
}

class JoinSharedPackApplicationSuccess {
  const JoinSharedPackApplicationSuccess({
    required this.remoteResponse,
    required this.projection,
    required this.refreshRecommended,
  });

  final JoinSharedPackByInviteRemoteResponse remoteResponse;
  final SharedPackPackShellProjectionResult projection;
  final bool refreshRecommended;
}

class _Resolution<T> {
  const _Resolution._({this.value, this.result});

  factory _Resolution.value(String value) => _Resolution._(value: value);

  factory _Resolution.result(SharedPackApplicationResult<T> result) {
    return _Resolution._(result: result);
  }

  final String? value;
  final SharedPackApplicationResult<T>? result;
}
