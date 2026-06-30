import 'package:supabase/supabase.dart';

import 'shared_pack_remote_dto.dart';
import 'shared_pack_remote_mapper.dart';
import 'shared_pack_remote_request_ids.dart';

abstract class SharedPackRpcClient {
  Future<Object?> rpc(String functionName, {Map<String, dynamic>? params});
}

class SharedPackRemoteApi {
  const SharedPackRemoteApi(this._rpcClient);

  SharedPackRemoteApi.fromSupabaseClient(SupabaseClient client)
    : this(_SupabaseSharedPackRpcClient(client));

  final SharedPackRpcClient _rpcClient;

  Future<CreateSharedPackRemoteResponse> createPack(
    CreateSharedPackRemoteRequest request,
  ) async {
    const operation = 'shared_pack_create_pack_v1';
    final row = await _callSingleRow(
      operation: operation,
      requestId: request.requestId,
      params: {
        'p_pack_name': request.name,
        'p_owner_identity_id': request.ownerIdentityId,
      },
    );

    return CreateSharedPackRemoteResponse(
      requestId: request.requestId,
      remotePackId: SharedPackRemoteMapper.requiredString(
        row,
        'remote_pack_id',
        requestId: request.requestId,
        operation: operation,
      ),
      name: SharedPackRemoteMapper.requiredString(
        row,
        'pack_name',
        requestId: request.requestId,
        operation: operation,
      ),
      ownerMembershipId: SharedPackRemoteMapper.requiredString(
        row,
        'owner_membership_id',
        requestId: request.requestId,
        operation: operation,
      ),
    );
  }

  Future<GenerateSharedPackInviteRemoteResponse> generateInvite(
    GenerateSharedPackInviteRemoteRequest request,
  ) async {
    const operation = 'shared_pack_generate_invite_v1';
    final row = await _callSingleRow(
      operation: operation,
      requestId: request.requestId,
      params: {
        'p_pack_id': request.remotePackId,
        'p_requester_identity_id': request.requesterIdentityId,
      },
    );

    return GenerateSharedPackInviteRemoteResponse(
      requestId: request.requestId,
      inviteId: SharedPackRemoteMapper.requiredString(
        row,
        'invite_id',
        requestId: request.requestId,
        operation: operation,
      ),
      inviteCode: SharedPackRemoteMapper.requiredString(
        row,
        'invite_code',
        requestId: request.requestId,
        operation: operation,
      ),
      expiresAt: SharedPackRemoteMapper.optionalDateTime(row, 'expires_at'),
    );
  }

  Future<PreviewSharedPackInviteRemoteResponse> previewInvite(
    PreviewSharedPackInviteRemoteRequest request,
  ) async {
    const operation = 'shared_pack_preview_invite_v1';
    final row = await _callSingleRow(
      operation: operation,
      requestId: request.requestId,
      params: {
        'p_invite_code': SharedPackRemoteMapper.normalizeInviteCode(
          request.inviteCode,
        ),
      },
    );

    return PreviewSharedPackInviteRemoteResponse(
      requestId: request.requestId,
      remotePackId: SharedPackRemoteMapper.optionalString(
        row,
        'remote_pack_id',
      ),
      packName: SharedPackRemoteMapper.optionalString(row, 'pack_name'),
      isJoinable: SharedPackRemoteMapper.requiredBool(
        row,
        'is_joinable',
        requestId: request.requestId,
        operation: operation,
      ),
    );
  }

  Future<JoinSharedPackByInviteRemoteResponse> joinByInvite(
    JoinSharedPackByInviteRemoteRequest request,
  ) async {
    const operation = 'shared_pack_join_by_invite_v1';
    final row = await _callSingleRow(
      operation: operation,
      requestId: request.requestId,
      params: {
        'p_invite_code': SharedPackRemoteMapper.normalizeInviteCode(
          request.inviteCode,
        ),
        'p_joiner_identity_id': request.joinerIdentityId,
      },
    );

    return JoinSharedPackByInviteRemoteResponse(
      requestId: request.requestId,
      remotePackId: SharedPackRemoteMapper.requiredString(
        row,
        'remote_pack_id',
        requestId: request.requestId,
        operation: operation,
      ),
      membershipId: SharedPackRemoteMapper.requiredString(
        row,
        'membership_id',
        requestId: request.requestId,
        operation: operation,
      ),
      packName: SharedPackRemoteMapper.requiredString(
        row,
        'pack_name',
        requestId: request.requestId,
        operation: operation,
      ),
    );
  }

  Future<FetchSharedPackSnapshotRemoteResponse> fetchSnapshot(
    FetchSharedPackSnapshotRemoteRequest request,
  ) async {
    const operation = 'shared_pack_fetch_snapshot_v1';
    final row = await _callSingleRow(
      operation: operation,
      requestId: request.requestId,
      params: {
        'p_pack_id': request.remotePackId,
        'p_requester_identity_id': request.requesterIdentityId,
      },
    );

    return FetchSharedPackSnapshotRemoteResponse(
      requestId: request.requestId,
      remotePackId: SharedPackRemoteMapper.requiredString(
        row,
        'remote_pack_id',
        requestId: request.requestId,
        operation: operation,
      ),
      packName: SharedPackRemoteMapper.requiredString(
        row,
        'pack_name',
        requestId: request.requestId,
        operation: operation,
      ),
      requesterRole: SharedPackRemoteMapper.requiredString(
        row,
        'requester_role',
        requestId: request.requestId,
        operation: operation,
      ),
      items: SharedPackRemoteMapper.snapshotItems(
        row['items'],
        requestId: request.requestId,
        operation: operation,
      ),
    );
  }

  Future<UpdateSharedPackItemStateRemoteResponse> updateItemState(
    UpdateSharedPackItemStateRemoteRequest request,
  ) async {
    const operation = 'shared_pack_update_item_state_v1';
    final row = await _callSingleRow(
      operation: operation,
      requestId: request.requestId,
      params: {
        'p_item_id': request.remoteItemId,
        'p_requester_identity_id': request.requesterIdentityId,
        'p_state': request.newState,
        'p_completed_at': request.completedAt?.toIso8601String(),
      },
    );

    return UpdateSharedPackItemStateRemoteResponse(
      requestId: request.requestId,
      remoteItemId: SharedPackRemoteMapper.requiredString(
        row,
        'remote_item_id',
        requestId: request.requestId,
        operation: operation,
      ),
      remotePackId: SharedPackRemoteMapper.requiredString(
        row,
        'remote_pack_id',
        requestId: request.requestId,
        operation: operation,
      ),
      state: SharedPackRemoteMapper.requiredString(
        row,
        'state',
        requestId: request.requestId,
        operation: operation,
      ),
      lastCompletedAt: SharedPackRemoteMapper.optionalDateTime(
        row,
        'last_completed_at',
      ),
      updatedAt: SharedPackRemoteMapper.requiredDateTime(
        row,
        'updated_at',
        requestId: request.requestId,
        operation: operation,
      ),
    );
  }

  Future<Map<String, dynamic>> _callSingleRow({
    required String operation,
    required String requestId,
    required Map<String, dynamic> params,
  }) async {
    try {
      final response = await _rpcClient.rpc(operation, params: params);
      return SharedPackRemoteMapper.singleRow(
        response,
        requestId: requestId,
        operation: operation,
      );
    } on SharedPackRemoteException {
      rethrow;
    } catch (error) {
      throw SharedPackRemoteException(
        requestId: requestId,
        operation: operation,
        message: 'Shared Pack RPC failed.',
        cause: error,
      );
    }
  }

  static const requestIdsByOperation = <String, String>{
    'shared_pack_create_pack_v1': SharedPackRemoteRequestIds.createPackV1,
    'shared_pack_generate_invite_v1':
        SharedPackRemoteRequestIds.generateInviteV1,
    'shared_pack_preview_invite_v1': SharedPackRemoteRequestIds.previewInviteV1,
    'shared_pack_join_by_invite_v1': SharedPackRemoteRequestIds.joinByInviteV1,
    'shared_pack_fetch_snapshot_v1': SharedPackRemoteRequestIds.fetchSnapshotV1,
    'shared_pack_update_item_state_v1':
        SharedPackRemoteRequestIds.updateItemStateV1,
  };
}

class _SupabaseSharedPackRpcClient implements SharedPackRpcClient {
  const _SupabaseSharedPackRpcClient(this._client);

  final SupabaseClient _client;

  @override
  Future<Object?> rpc(String functionName, {Map<String, dynamic>? params}) {
    return _client.rpc(functionName, params: params);
  }
}
