import 'package:flutter_test/flutter_test.dart';
import 'package:reminder_app/features/shared_pack/remote/shared_pack_remote_api.dart';
import 'package:reminder_app/features/shared_pack/remote/shared_pack_remote_dto.dart';
import 'package:reminder_app/features/shared_pack/remote/shared_pack_remote_repository.dart';
import 'package:reminder_app/features/shared_pack/remote/shared_pack_remote_request_ids.dart';

void main() {
  group('SharedPackRemoteApi', () {
    test('createPack calls RPC with params and parses response', () async {
      final rpcClient = _FakeRpcClient([
        _RpcResponse('shared_pack_create_pack_v1', [
          {
            'remote_pack_id': _packId,
            'pack_name': 'Family Care',
            'owner_membership_id': _ownerMembershipId,
          },
        ]),
      ]);
      final api = SharedPackRemoteApi(rpcClient);

      final response = await api.createPack(
        const CreateSharedPackRemoteRequest(
          name: 'Family Care',
          ownerIdentityId: _ownerIdentityId,
        ),
      );

      expect(response.requestId, SharedPackRemoteRequestIds.createPackV1);
      expect(response.remotePackId, _packId);
      expect(response.name, 'Family Care');
      expect(response.ownerMembershipId, _ownerMembershipId);
      expect(rpcClient.calls.single.functionName, 'shared_pack_create_pack_v1');
      expect(rpcClient.calls.single.params, {
        'p_pack_name': 'Family Care',
        'p_owner_identity_id': _ownerIdentityId,
      });
    });

    test('generateInvite calls RPC with params and parses response', () async {
      final rpcClient = _FakeRpcClient([
        _RpcResponse('shared_pack_generate_invite_v1', [
          {
            'invite_id': _inviteId,
            'invite_code': 'K7M4Q9',
            'expires_at': '2026-07-02T12:00:00.000Z',
          },
        ]),
      ]);
      final api = SharedPackRemoteApi(rpcClient);

      final response = await api.generateInvite(
        const GenerateSharedPackInviteRemoteRequest(
          remotePackId: _packId,
          requesterIdentityId: _ownerIdentityId,
        ),
      );

      expect(response.requestId, SharedPackRemoteRequestIds.generateInviteV1);
      expect(response.inviteId, _inviteId);
      expect(response.inviteCode, 'K7M4Q9');
      expect(response.expiresAt, DateTime.utc(2026, 7, 2, 12));
      expect(
        rpcClient.calls.single.functionName,
        'shared_pack_generate_invite_v1',
      );
      expect(rpcClient.calls.single.params, {
        'p_pack_id': _packId,
        'p_requester_identity_id': _ownerIdentityId,
      });
    });

    test('previewInvite normalizes spaced invite code', () async {
      final rpcClient = _FakeRpcClient([
        _RpcResponse('shared_pack_preview_invite_v1', [
          {
            'remote_pack_id': _packId,
            'pack_name': 'Family Care',
            'is_joinable': true,
          },
        ]),
      ]);
      final api = SharedPackRemoteApi(rpcClient);

      final response = await api.previewInvite(
        const PreviewSharedPackInviteRemoteRequest(inviteCode: 'k7m 4q9'),
      );

      expect(response.requestId, SharedPackRemoteRequestIds.previewInviteV1);
      expect(response.remotePackId, _packId);
      expect(response.packName, 'Family Care');
      expect(response.isJoinable, isTrue);
      expect(rpcClient.calls.single.params, {'p_invite_code': 'K7M4Q9'});
    });

    test('joinByInvite normalizes hyphenated invite code', () async {
      final rpcClient = _FakeRpcClient([
        _RpcResponse('shared_pack_join_by_invite_v1', [
          {
            'remote_pack_id': _packId,
            'membership_id': _memberMembershipId,
            'pack_name': 'Family Care',
          },
        ]),
      ]);
      final api = SharedPackRemoteApi(rpcClient);

      final response = await api.joinByInvite(
        const JoinSharedPackByInviteRemoteRequest(
          inviteCode: 'k7m-4q9',
          joinerIdentityId: _joinerIdentityId,
        ),
      );

      expect(response.requestId, SharedPackRemoteRequestIds.joinByInviteV1);
      expect(response.remotePackId, _packId);
      expect(response.membershipId, _memberMembershipId);
      expect(response.packName, 'Family Care');
      expect(rpcClient.calls.single.params, {
        'p_invite_code': 'K7M4Q9',
        'p_joiner_identity_id': _joinerIdentityId,
      });
    });

    test('fetchSnapshot parses pack metadata and items', () async {
      final rpcClient = _FakeRpcClient([
        _RpcResponse('shared_pack_fetch_snapshot_v1', [
          {
            'remote_pack_id': _packId,
            'pack_name': 'Family Care',
            'requester_role': 'owner',
            'items': [
              {
                'id': _itemId,
                'title': 'Medication',
                'notes': 'After dinner',
                'schedule_payload': {'kind': 'daily'},
                'state': 'done',
                'last_completed_at': '2026-07-01T11:30:00.000Z',
                'updated_by_identity_id': _ownerIdentityId,
                'created_at': '2026-07-01T10:00:00.000Z',
                'updated_at': '2026-07-01T11:30:00.000Z',
                'archived_at': null,
              },
            ],
          },
        ]),
      ]);
      final api = SharedPackRemoteApi(rpcClient);

      final response = await api.fetchSnapshot(
        const FetchSharedPackSnapshotRemoteRequest(
          remotePackId: _packId,
          requesterIdentityId: _ownerIdentityId,
        ),
      );

      expect(response.requestId, SharedPackRemoteRequestIds.fetchSnapshotV1);
      expect(response.remotePackId, _packId);
      expect(response.packName, 'Family Care');
      expect(response.requesterRole, 'owner');
      expect(response.items, hasLength(1));
      expect(response.items.single.remoteItemId, _itemId);
      expect(response.items.single.schedulePayload, {'kind': 'daily'});
      expect(
        response.items.single.lastCompletedAt,
        DateTime.utc(2026, 7, 1, 11, 30),
      );
      expect(rpcClient.calls.single.params, {
        'p_pack_id': _packId,
        'p_requester_identity_id': _ownerIdentityId,
      });
    });

    test(
      'updateItemState calls RPC with params and parses timestamps',
      () async {
        final completedAt = DateTime.utc(2026, 7, 1, 12);
        final rpcClient = _FakeRpcClient([
          _RpcResponse('shared_pack_update_item_state_v1', [
            {
              'remote_item_id': _itemId,
              'remote_pack_id': _packId,
              'state': 'done',
              'last_completed_at': '2026-07-01T12:00:00.000Z',
              'updated_at': '2026-07-01T12:01:00.000Z',
            },
          ]),
        ]);
        final api = SharedPackRemoteApi(rpcClient);

        final response = await api.updateItemState(
          UpdateSharedPackItemStateRemoteRequest(
            remoteItemId: _itemId,
            requesterIdentityId: _ownerIdentityId,
            newState: 'done',
            completedAt: completedAt,
          ),
        );

        expect(
          response.requestId,
          SharedPackRemoteRequestIds.updateItemStateV1,
        );
        expect(response.remoteItemId, _itemId);
        expect(response.remotePackId, _packId);
        expect(response.state, 'done');
        expect(response.lastCompletedAt, completedAt);
        expect(response.updatedAt, DateTime.utc(2026, 7, 1, 12, 1));
        expect(rpcClient.calls.single.params, {
          'p_item_id': _itemId,
          'p_requester_identity_id': _ownerIdentityId,
          'p_state': 'done',
          'p_completed_at': completedAt.toIso8601String(),
        });
      },
    );

    test('wraps RPC failure with request ID', () async {
      final api = SharedPackRemoteApi(
        _FakeRpcClient([_RpcResponse.error(StateError('rpc failed'))]),
      );

      expect(
        () => api.createPack(
          const CreateSharedPackRemoteRequest(
            name: 'Family Care',
            ownerIdentityId: _ownerIdentityId,
          ),
        ),
        throwsA(
          isA<SharedPackRemoteException>()
              .having(
                (error) => error.requestId,
                'requestId',
                SharedPackRemoteRequestIds.createPackV1,
              )
              .having(
                (error) => error.operation,
                'operation',
                'shared_pack_create_pack_v1',
              )
              .having((error) => error.cause, 'cause', isA<StateError>()),
        ),
      );
    });

    test('wraps invalid response fields with request ID', () async {
      final api = SharedPackRemoteApi(
        _FakeRpcClient([
          const _RpcResponse('shared_pack_create_pack_v1', [
            {'remote_pack_id': _packId},
          ]),
        ]),
      );

      expect(
        () => api.createPack(
          const CreateSharedPackRemoteRequest(
            name: 'Family Care',
            ownerIdentityId: _ownerIdentityId,
          ),
        ),
        throwsA(
          isA<SharedPackRemoteException>()
              .having(
                (error) => error.requestId,
                'requestId',
                SharedPackRemoteRequestIds.createPackV1,
              )
              .having(
                (error) => error.operation,
                'operation',
                'shared_pack_create_pack_v1',
              ),
        ),
      );
    });

    test('documents request IDs by operation', () {
      expect(SharedPackRemoteApi.requestIdsByOperation, {
        'shared_pack_create_pack_v1': SharedPackRemoteRequestIds.createPackV1,
        'shared_pack_generate_invite_v1':
            SharedPackRemoteRequestIds.generateInviteV1,
        'shared_pack_preview_invite_v1':
            SharedPackRemoteRequestIds.previewInviteV1,
        'shared_pack_join_by_invite_v1':
            SharedPackRemoteRequestIds.joinByInviteV1,
        'shared_pack_fetch_snapshot_v1':
            SharedPackRemoteRequestIds.fetchSnapshotV1,
        'shared_pack_update_item_state_v1':
            SharedPackRemoteRequestIds.updateItemStateV1,
      });
    });
  });

  group('SharedPackRemoteRepository', () {
    test('forwards calls to the remote API', () async {
      final rpcClient = _FakeRpcClient([
        _RpcResponse('shared_pack_preview_invite_v1', [
          {
            'remote_pack_id': _packId,
            'pack_name': 'Family Care',
            'is_joinable': true,
          },
        ]),
      ]);
      final repository = SharedPackRemoteRepository(
        SharedPackRemoteApi(rpcClient),
      );

      final response = await repository.previewInvite(
        const PreviewSharedPackInviteRemoteRequest(inviteCode: 'k7m 4q9'),
      );

      expect(response.remotePackId, _packId);
      expect(
        rpcClient.calls.single.functionName,
        'shared_pack_preview_invite_v1',
      );
    });
  });
}

const _packId = '00000000-0000-4000-8000-000000000010';
const _itemId = '00000000-0000-4000-8000-000000000020';
const _inviteId = '00000000-0000-4000-8000-000000000030';
const _ownerMembershipId = '00000000-0000-4000-8000-000000000040';
const _memberMembershipId = '00000000-0000-4000-8000-000000000050';
const _ownerIdentityId = '00000000-0000-4000-8000-000000000001';
const _joinerIdentityId = '00000000-0000-4000-8000-000000000002';

class _FakeRpcClient implements SharedPackRpcClient {
  _FakeRpcClient(this._responses);

  final List<_RpcResponse> _responses;
  final calls = <_RpcCall>[];

  @override
  Future<Object?> rpc(
    String functionName, {
    Map<String, dynamic>? params,
  }) async {
    calls.add(_RpcCall(functionName, params));
    final response = _responses[calls.length - 1];
    if (response.error != null) {
      throw response.error!;
    }
    expect(functionName, response.functionName);
    return response.body;
  }
}

class _RpcCall {
  const _RpcCall(this.functionName, this.params);

  final String functionName;
  final Map<String, dynamic>? params;
}

class _RpcResponse {
  const _RpcResponse(this.functionName, this.body) : error = null;

  const _RpcResponse.error(this.error) : functionName = 'error', body = null;

  final String functionName;
  final Object? body;
  final Object? error;
}
