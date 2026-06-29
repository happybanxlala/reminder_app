import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/remote_pack_freshness.dart';
import 'remote_shared_pack_models.dart';
import 'supabase_config.dart';

abstract class RemoteSharedPackDataSource {
  Future<String> upsertCurrentProfile({required String displayName});
  Future<String> createSharedPack({required String name, String? description});
  Future<RemotePackInvite> createPackInvite({required String packId});
  Future<RemotePackInviteState> fetchPackInviteState({required String packId});
  Future<RemotePackInvite> ensureActivePackInvite({required String packId});
  Future<RemotePackInvite> refreshPackInvite({required String packId});
  Future<RemoteJoinPackResult> joinPackWithInvite({required String inviteCode});
  Future<List<RemoteRecoverablePack>> fetchActiveMembershipPacks();
  Future<RemoteRevokeInviteResult> revokePackInvite({required String inviteId});
  Future<String> createPackItem({
    required String packId,
    required String title,
    String? note,
  });
  Future<RemoteItemCreateResult> createPackItemV2({
    required String packId,
    required String title,
    String? note,
    String? clientMutationId,
  });
  Future<RemoteItemMutationResult> updatePackItem({
    required String itemId,
    required String title,
    String? note,
    String? assignedToUserId,
    String? clientMutationId,
  });
  Future<RemoteItemMutationResult> archivePackItem({
    required String itemId,
    String? clientMutationId,
  });
  Future<RemoteResourceCreateResult> createPackResource({
    required String packId,
    required String title,
    String? description,
    required String type,
    Map<String, Object?>? config,
    String? clientMutationId,
  }) {
    throw const RemoteSharedPackException(
      RemoteSharedPackFailureReason.remoteUnknownFailure,
    );
  }

  Future<RemoteResourceMutationResult> updatePackResource({
    required String resourceId,
    required String title,
    String? description,
    Map<String, Object?>? config,
    String? clientMutationId,
  }) {
    throw const RemoteSharedPackException(
      RemoteSharedPackFailureReason.remoteUnknownFailure,
    );
  }

  Future<RemoteResourceMutationResult> archivePackResource({
    required String resourceId,
    String? clientMutationId,
  }) {
    throw const RemoteSharedPackException(
      RemoteSharedPackFailureReason.remoteUnknownFailure,
    );
  }

  Future<RemoteResourceEventResult> applyResourceEvent({
    required String resourceId,
    required String changeType,
    int? deltaValue,
    int? newValue,
    String? unit,
    String? clientMutationId,
    Map<String, Object?>? metadata,
  }) {
    throw const RemoteSharedPackException(
      RemoteSharedPackFailureReason.remoteUnknownFailure,
    );
  }

  Future<RemoteStageTrackerCreateResult> createPackStageTracker({
    required String packId,
    required String title,
    String? subjectName,
    required DateTime trackingStartDate,
    DateTime? trackingEndDate,
    List<Map<String, Object?>> initialRules = const [],
    String? clientMutationId,
  }) {
    throw const RemoteSharedPackException(
      RemoteSharedPackFailureReason.remoteUnknownFailure,
    );
  }

  Future<RemoteStageMutationResult> updatePackStageTracker({
    required String stageTrackerId,
    required String title,
    String? subjectName,
    required DateTime trackingStartDate,
    DateTime? trackingEndDate,
    String? clientMutationId,
  }) {
    throw const RemoteSharedPackException(
      RemoteSharedPackFailureReason.remoteUnknownFailure,
    );
  }

  Future<RemoteStageMutationResult> archivePackStageTracker({
    required String stageTrackerId,
    String? clientMutationId,
  }) {
    throw const RemoteSharedPackException(
      RemoteSharedPackFailureReason.remoteUnknownFailure,
    );
  }

  Future<RemoteStageMutationResult> createPackStageRule({
    required String stageTrackerId,
    required Map<String, Object?> fields,
    String? clientMutationId,
  }) {
    throw const RemoteSharedPackException(
      RemoteSharedPackFailureReason.remoteUnknownFailure,
    );
  }

  Future<RemoteStageMutationResult> updatePackStageRule({
    required String stageRuleId,
    required Map<String, Object?> fields,
    String? clientMutationId,
  }) {
    throw const RemoteSharedPackException(
      RemoteSharedPackFailureReason.remoteUnknownFailure,
    );
  }

  Future<RemoteStageMutationResult> updatePackStageRuleStatus({
    required String stageRuleId,
    required String status,
    String? clientMutationId,
  }) {
    throw const RemoteSharedPackException(
      RemoteSharedPackFailureReason.remoteUnknownFailure,
    );
  }

  Future<RemoteStageMutationResult> createPackStageRecord({
    required String stageTrackerId,
    String? stageRuleId,
    required Map<String, Object?> fields,
    String? clientMutationId,
  }) {
    throw const RemoteSharedPackException(
      RemoteSharedPackFailureReason.remoteUnknownFailure,
    );
  }

  Future<RemoteStageMutationResult> updatePackStageRecord({
    required String stageRecordId,
    required Map<String, Object?> fields,
    String? clientMutationId,
  }) {
    throw const RemoteSharedPackException(
      RemoteSharedPackFailureReason.remoteUnknownFailure,
    );
  }

  Future<RemoteStageMutationResult> archivePackStageRecord({
    required String stageRecordId,
    String? clientMutationId,
  }) {
    throw const RemoteSharedPackException(
      RemoteSharedPackFailureReason.remoteUnknownFailure,
    );
  }

  Future<RemoteStageAcknowledgementResult> acknowledgePackStageRecord({
    required String stageRecordId,
    String? clientMutationId,
  }) {
    throw const RemoteSharedPackException(
      RemoteSharedPackFailureReason.remoteUnknownFailure,
    );
  }

  Future<RemoteItemCompletionResult> completePackItem({
    required String itemId,
    String? clientMutationId,
  });
  Future<RemoteItemUndoResult> undoPackItemCompletion({
    required String itemId,
    String? clientMutationId,
  });
  Future<RemotePackSnapshot> fetchPackSnapshot(String remotePackId);
  Future<void> reportPackSnapshotImported({
    required String remotePackId,
    String? latestActivityEventId,
    DateTime? latestActivityAt,
  });
  Future<List<RemotePackMemberFreshness>> getPackMemberFreshness({
    required String remotePackId,
  });
}

class DisabledRemoteSharedPackDataSource implements RemoteSharedPackDataSource {
  const DisabledRemoteSharedPackDataSource(this.reason);

  final RemoteSharedPackFailureReason reason;

  @override
  Future<String> upsertCurrentProfile({required String displayName}) {
    throw RemoteSharedPackException(reason);
  }

  @override
  Future<String> createSharedPack({required String name, String? description}) {
    throw RemoteSharedPackException(reason);
  }

  @override
  Future<RemotePackInvite> createPackInvite({required String packId}) {
    throw RemoteSharedPackException(reason);
  }

  @override
  Future<RemotePackInviteState> fetchPackInviteState({required String packId}) {
    throw RemoteSharedPackException(reason);
  }

  @override
  Future<RemotePackInvite> ensureActivePackInvite({required String packId}) {
    throw RemoteSharedPackException(reason);
  }

  @override
  Future<RemotePackInvite> refreshPackInvite({required String packId}) {
    throw RemoteSharedPackException(reason);
  }

  @override
  Future<RemoteJoinPackResult> joinPackWithInvite({
    required String inviteCode,
  }) {
    throw RemoteSharedPackException(reason);
  }

  @override
  Future<List<RemoteRecoverablePack>> fetchActiveMembershipPacks() {
    throw RemoteSharedPackException(reason);
  }

  @override
  Future<RemoteRevokeInviteResult> revokePackInvite({
    required String inviteId,
  }) {
    throw RemoteSharedPackException(reason);
  }

  @override
  Future<String> createPackItem({
    required String packId,
    required String title,
    String? note,
  }) {
    throw RemoteSharedPackException(reason);
  }

  @override
  Future<RemoteItemCreateResult> createPackItemV2({
    required String packId,
    required String title,
    String? note,
    String? clientMutationId,
  }) {
    throw RemoteSharedPackException(reason);
  }

  @override
  Future<RemoteItemMutationResult> updatePackItem({
    required String itemId,
    required String title,
    String? note,
    String? assignedToUserId,
    String? clientMutationId,
  }) {
    throw RemoteSharedPackException(reason);
  }

  @override
  Future<RemoteItemMutationResult> archivePackItem({
    required String itemId,
    String? clientMutationId,
  }) {
    throw RemoteSharedPackException(reason);
  }

  @override
  Future<RemoteResourceCreateResult> createPackResource({
    required String packId,
    required String title,
    String? description,
    required String type,
    Map<String, Object?>? config,
    String? clientMutationId,
  }) {
    throw RemoteSharedPackException(reason);
  }

  @override
  Future<RemoteResourceMutationResult> updatePackResource({
    required String resourceId,
    required String title,
    String? description,
    Map<String, Object?>? config,
    String? clientMutationId,
  }) {
    throw RemoteSharedPackException(reason);
  }

  @override
  Future<RemoteResourceMutationResult> archivePackResource({
    required String resourceId,
    String? clientMutationId,
  }) {
    throw RemoteSharedPackException(reason);
  }

  @override
  Future<RemoteResourceEventResult> applyResourceEvent({
    required String resourceId,
    required String changeType,
    int? deltaValue,
    int? newValue,
    String? unit,
    String? clientMutationId,
    Map<String, Object?>? metadata,
  }) {
    throw RemoteSharedPackException(reason);
  }

  @override
  Future<RemoteStageTrackerCreateResult> createPackStageTracker({
    required String packId,
    required String title,
    String? subjectName,
    required DateTime trackingStartDate,
    DateTime? trackingEndDate,
    List<Map<String, Object?>> initialRules = const [],
    String? clientMutationId,
  }) {
    throw RemoteSharedPackException(reason);
  }

  @override
  Future<RemoteStageMutationResult> updatePackStageTracker({
    required String stageTrackerId,
    required String title,
    String? subjectName,
    required DateTime trackingStartDate,
    DateTime? trackingEndDate,
    String? clientMutationId,
  }) {
    throw RemoteSharedPackException(reason);
  }

  @override
  Future<RemoteStageMutationResult> archivePackStageTracker({
    required String stageTrackerId,
    String? clientMutationId,
  }) {
    throw RemoteSharedPackException(reason);
  }

  @override
  Future<RemoteStageMutationResult> createPackStageRule({
    required String stageTrackerId,
    required Map<String, Object?> fields,
    String? clientMutationId,
  }) {
    throw RemoteSharedPackException(reason);
  }

  @override
  Future<RemoteStageMutationResult> updatePackStageRule({
    required String stageRuleId,
    required Map<String, Object?> fields,
    String? clientMutationId,
  }) {
    throw RemoteSharedPackException(reason);
  }

  @override
  Future<RemoteStageMutationResult> updatePackStageRuleStatus({
    required String stageRuleId,
    required String status,
    String? clientMutationId,
  }) {
    throw RemoteSharedPackException(reason);
  }

  @override
  Future<RemoteStageMutationResult> createPackStageRecord({
    required String stageTrackerId,
    String? stageRuleId,
    required Map<String, Object?> fields,
    String? clientMutationId,
  }) {
    throw RemoteSharedPackException(reason);
  }

  @override
  Future<RemoteStageMutationResult> updatePackStageRecord({
    required String stageRecordId,
    required Map<String, Object?> fields,
    String? clientMutationId,
  }) {
    throw RemoteSharedPackException(reason);
  }

  @override
  Future<RemoteStageMutationResult> archivePackStageRecord({
    required String stageRecordId,
    String? clientMutationId,
  }) {
    throw RemoteSharedPackException(reason);
  }

  @override
  Future<RemoteStageAcknowledgementResult> acknowledgePackStageRecord({
    required String stageRecordId,
    String? clientMutationId,
  }) {
    throw RemoteSharedPackException(reason);
  }

  @override
  Future<RemoteItemCompletionResult> completePackItem({
    required String itemId,
    String? clientMutationId,
  }) {
    throw RemoteSharedPackException(reason);
  }

  @override
  Future<RemoteItemUndoResult> undoPackItemCompletion({
    required String itemId,
    String? clientMutationId,
  }) {
    throw RemoteSharedPackException(reason);
  }

  @override
  Future<RemotePackSnapshot> fetchPackSnapshot(String remotePackId) {
    throw RemoteSharedPackException(reason);
  }

  @override
  Future<void> reportPackSnapshotImported({
    required String remotePackId,
    String? latestActivityEventId,
    DateTime? latestActivityAt,
  }) {
    throw RemoteSharedPackException(reason);
  }

  @override
  Future<List<RemotePackMemberFreshness>> getPackMemberFreshness({
    required String remotePackId,
  }) {
    throw RemoteSharedPackException(reason);
  }
}

class SupabaseRemoteSharedPackDataSource implements RemoteSharedPackDataSource {
  const SupabaseRemoteSharedPackDataSource(this._runtime);

  final SupabaseRuntime _runtime;

  SupabaseClient get _client {
    final client = _runtime.client;
    if (client == null) {
      final reason = _runtime.status == SupabaseRuntimeStatus.missingConfig
          ? RemoteSharedPackFailureReason.supabaseConfigMissing
          : RemoteSharedPackFailureReason.remoteNetworkFailed;
      throw RemoteSharedPackException(reason, _runtime.error);
    }
    return client;
  }

  @override
  Future<String> upsertCurrentProfile({required String displayName}) async {
    try {
      final result = await _client.rpc(
        'upsert_current_profile',
        params: {'display_name': displayName},
      );
      return _stringRpcResult(result, 'id');
    } catch (error) {
      throw _mapError(
        error,
        RemoteSharedPackFailureReason.remoteProfileFailed,
        operationName: 'upsert_current_profile',
      );
    }
  }

  @override
  Future<String> createSharedPack({
    required String name,
    String? description,
  }) async {
    try {
      final result = await _client.rpc(
        'create_shared_pack',
        params: {'pack_name': name, 'description': description},
      );
      return _stringRpcResult(result, 'pack_id');
    } catch (error) {
      throw _mapError(
        error,
        RemoteSharedPackFailureReason.remotePackCreateFailed,
        operationName: 'create_shared_pack',
      );
    }
  }

  @override
  Future<RemotePackInvite> createPackInvite({required String packId}) async {
    return ensureActivePackInvite(packId: packId);
  }

  @override
  Future<RemotePackInviteState> fetchPackInviteState({
    required String packId,
  }) async {
    try {
      final result = await _client.rpc(
        'fetch_pack_invite_state',
        params: {'target_pack_id': packId},
      );
      final row = _mapRpcResult(result);
      final inviteId = _optionalString(row, 'invite_id');
      return RemotePackInviteState(
        activeInvite: inviteId == null
            ? null
            : RemotePackInvite(
                inviteId: inviteId,
                inviteCode: _requiredString(row, 'invite_code'),
                expiresAt: _requiredDate(row, 'expires_at'),
                maxUses: _requiredInt(row, 'max_uses'),
              ),
        latestInviteExpired: _optionalBool(row, 'latest_invite_expired'),
      );
    } catch (error) {
      throw _mapError(
        error,
        RemoteSharedPackFailureReason.remoteInviteNotHost,
        operationName: 'fetch_pack_invite_state',
      );
    }
  }

  @override
  Future<RemotePackInvite> ensureActivePackInvite({
    required String packId,
  }) async {
    try {
      final result = await _client.rpc(
        'ensure_active_pack_invite',
        params: {
          'target_pack_id': packId,
          'expires_in_days': 7,
          'max_uses_limit': 10,
        },
      );
      final row = _mapRpcResult(result);
      return RemotePackInvite(
        inviteId: _requiredString(row, 'invite_id'),
        inviteCode: _requiredString(row, 'invite_code'),
        expiresAt: _requiredDate(row, 'expires_at'),
        maxUses: _requiredInt(row, 'max_uses'),
      );
    } catch (error) {
      throw _mapError(
        error,
        RemoteSharedPackFailureReason.remoteInviteNotHost,
        operationName: 'ensure_active_pack_invite',
      );
    }
  }

  @override
  Future<RemotePackInvite> refreshPackInvite({required String packId}) async {
    try {
      final result = await _client.rpc(
        'refresh_pack_invite',
        params: {
          'target_pack_id': packId,
          'expires_in_days': 7,
          'max_uses_limit': 10,
        },
      );
      final row = _mapRpcResult(result);
      return RemotePackInvite(
        inviteId: _requiredString(row, 'invite_id'),
        inviteCode: _requiredString(row, 'invite_code'),
        expiresAt: _requiredDate(row, 'expires_at'),
        maxUses: _requiredInt(row, 'max_uses'),
      );
    } catch (error) {
      throw _mapError(
        error,
        RemoteSharedPackFailureReason.remoteInviteNotHost,
        operationName: 'refresh_pack_invite',
      );
    }
  }

  @override
  Future<RemoteJoinPackResult> joinPackWithInvite({
    required String inviteCode,
  }) async {
    try {
      final result = await _client.rpc(
        'join_pack_with_invite',
        params: {'invite_code': inviteCode},
      );
      final row = _mapRpcResult(result);
      final status = _requiredString(row, 'status');
      return RemoteJoinPackResult(
        status: status == 'already_member'
            ? RemoteJoinPackStatus.alreadyMember
            : RemoteJoinPackStatus.joined,
        remotePackId: _requiredString(row, 'pack_id'),
        memberId: _requiredString(row, 'member_id'),
        role: _requiredString(row, 'role'),
      );
    } catch (error) {
      throw _mapError(
        error,
        RemoteSharedPackFailureReason.remoteInviteInvalid,
        operationName: 'join_pack_with_invite',
      );
    }
  }

  @override
  Future<List<RemoteRecoverablePack>> fetchActiveMembershipPacks() async {
    try {
      final currentUserId = _client.auth.currentUser?.id;
      if (currentUserId == null || currentUserId.isEmpty) {
        throw const RemoteSharedPackException(
          RemoteSharedPackFailureReason.remoteAuthRequired,
        );
      }
      final rows = await _client
          .from('pack_members')
          .select(
            'pack_id, role, status, packs(id, name, description, host_user_id, status, updated_at)',
          )
          .eq('user_id', currentUserId)
          .eq('status', 'active')
          .order('joined_at');
      return _listOfMaps(
        rows,
      ).map(_recoverablePackFromMembershipRow).toList(growable: false);
    } catch (error) {
      throw _mapError(
        error,
        RemoteSharedPackFailureReason.remoteUnknownFailure,
        operationName: 'fetch_active_membership_packs',
      );
    }
  }

  @override
  Future<RemoteRevokeInviteResult> revokePackInvite({
    required String inviteId,
  }) async {
    try {
      final result = await _client.rpc(
        'revoke_pack_invite',
        params: {'target_invite_id': inviteId},
      );
      final row = _mapRpcResult(result);
      final status = _requiredString(row, 'status');
      return RemoteRevokeInviteResult(
        status: status == 'already_revoked'
            ? RemoteRevokeInviteStatus.alreadyRevoked
            : RemoteRevokeInviteStatus.revoked,
        inviteId: _requiredString(row, 'invite_id'),
      );
    } catch (error) {
      throw _mapError(
        error,
        RemoteSharedPackFailureReason.remoteInviteNotHost,
        operationName: 'revoke_pack_invite',
      );
    }
  }

  @override
  Future<String> createPackItem({
    required String packId,
    required String title,
    String? note,
  }) async {
    try {
      final result = await _client.rpc(
        'create_pack_item',
        params: {'pack_id': packId, 'title': title, 'note': note},
      );
      return _stringRpcResult(result, 'item_id');
    } catch (error) {
      throw _mapError(
        error,
        RemoteSharedPackFailureReason.remoteItemPushFailed,
        operationName: 'create_pack_item',
      );
    }
  }

  @override
  Future<RemoteItemCreateResult> createPackItemV2({
    required String packId,
    required String title,
    String? note,
    String? clientMutationId,
  }) async {
    try {
      final result = await _client.rpc(
        'create_pack_item_v2',
        params: {
          'target_pack_id': packId,
          'title': title,
          'note': note,
          'client_mutation_id': clientMutationId,
        },
      );
      final row = _mapRpcResult(result);
      return RemoteItemCreateResult(
        itemId: _requiredString(row, 'item_id'),
        status: _optionalString(row, 'status') ?? 'created',
      );
    } catch (error) {
      throw _mapError(
        error,
        RemoteSharedPackFailureReason.remoteItemPushFailed,
        operationName: 'create_pack_item_v2',
      );
    }
  }

  @override
  Future<RemoteItemMutationResult> updatePackItem({
    required String itemId,
    required String title,
    String? note,
    String? assignedToUserId,
    String? clientMutationId,
  }) async {
    try {
      final result = await _client.rpc(
        'update_pack_item',
        params: {
          'target_item_id': itemId,
          'title': title,
          'note': note,
          'assigned_to_user_id': assignedToUserId,
          'client_mutation_id': clientMutationId,
        },
      );
      final row = _mapRpcResult(result);
      return RemoteItemMutationResult(
        itemId: _requiredString(row, 'item_id'),
        status: _optionalString(row, 'status') ?? 'updated',
      );
    } catch (error) {
      throw _mapError(
        error,
        RemoteSharedPackFailureReason.remoteUnknownFailure,
        operationName: 'update_pack_item',
      );
    }
  }

  @override
  Future<RemoteItemMutationResult> archivePackItem({
    required String itemId,
    String? clientMutationId,
  }) async {
    try {
      final result = await _client.rpc(
        'archive_pack_item',
        params: {
          'target_item_id': itemId,
          'client_mutation_id': clientMutationId,
        },
      );
      final row = _mapRpcResult(result);
      return RemoteItemMutationResult(
        itemId: _requiredString(row, 'item_id'),
        status: _optionalString(row, 'status') ?? 'archived',
      );
    } catch (error) {
      throw _mapError(
        error,
        RemoteSharedPackFailureReason.remoteUnknownFailure,
        operationName: 'archive_pack_item',
      );
    }
  }

  @override
  Future<RemoteResourceCreateResult> createPackResource({
    required String packId,
    required String title,
    String? description,
    required String type,
    Map<String, Object?>? config,
    String? clientMutationId,
  }) async {
    try {
      final result = await _client.rpc(
        'create_pack_resource',
        params: {
          'target_pack_id': packId,
          'title': title,
          'description': description,
          'resource_type': type,
          'config_json': config,
          'client_mutation_id': clientMutationId,
        },
      );
      final row = _mapRpcResult(result);
      return RemoteResourceCreateResult(
        resourceId: _requiredString(row, 'resource_id'),
        status: _optionalString(row, 'status') ?? 'created',
      );
    } catch (error) {
      throw _mapError(
        error,
        RemoteSharedPackFailureReason.remoteUnknownFailure,
        operationName: 'create_pack_resource',
      );
    }
  }

  @override
  Future<RemoteResourceMutationResult> updatePackResource({
    required String resourceId,
    required String title,
    String? description,
    Map<String, Object?>? config,
    String? clientMutationId,
  }) async {
    try {
      final result = await _client.rpc(
        'update_pack_resource',
        params: {
          'target_resource_id': resourceId,
          'title': title,
          'description': description,
          'config_json': config,
          'client_mutation_id': clientMutationId,
        },
      );
      final row = _mapRpcResult(result);
      return RemoteResourceMutationResult(
        resourceId: _requiredString(row, 'resource_id'),
        status: _optionalString(row, 'status') ?? 'updated',
      );
    } catch (error) {
      throw _mapError(
        error,
        RemoteSharedPackFailureReason.remoteUnknownFailure,
        operationName: 'update_pack_resource',
      );
    }
  }

  @override
  Future<RemoteResourceMutationResult> archivePackResource({
    required String resourceId,
    String? clientMutationId,
  }) async {
    try {
      final result = await _client.rpc(
        'archive_pack_resource',
        params: {
          'target_resource_id': resourceId,
          'client_mutation_id': clientMutationId,
        },
      );
      final row = _mapRpcResult(result);
      return RemoteResourceMutationResult(
        resourceId: _requiredString(row, 'resource_id'),
        status: _optionalString(row, 'status') ?? 'archived',
      );
    } catch (error) {
      throw _mapError(
        error,
        RemoteSharedPackFailureReason.remoteUnknownFailure,
        operationName: 'archive_pack_resource',
      );
    }
  }

  @override
  Future<RemoteResourceEventResult> applyResourceEvent({
    required String resourceId,
    required String changeType,
    int? deltaValue,
    int? newValue,
    String? unit,
    String? clientMutationId,
    Map<String, Object?>? metadata,
  }) async {
    try {
      final result = await _client.rpc(
        'apply_resource_event',
        params: {
          'target_resource_id': resourceId,
          'change_type': changeType,
          'delta_value': deltaValue,
          'new_value': newValue,
          'unit': unit,
          'client_mutation_id': clientMutationId,
          'metadata_json': metadata,
        },
      );
      final row = _mapRpcResult(result);
      return RemoteResourceEventResult(
        resourceId: _requiredString(row, 'resource_id'),
        eventId: _requiredString(row, 'event_id'),
        status: _optionalString(row, 'status') ?? 'applied',
        currentValue: _optionalInt(row, 'current_value'),
        updatedAt: _optionalDate(row, 'updated_at'),
      );
    } catch (error) {
      throw _mapError(
        error,
        RemoteSharedPackFailureReason.remoteUnknownFailure,
        operationName: 'apply_resource_event',
      );
    }
  }

  @override
  Future<RemoteStageTrackerCreateResult> createPackStageTracker({
    required String packId,
    required String title,
    String? subjectName,
    required DateTime trackingStartDate,
    DateTime? trackingEndDate,
    List<Map<String, Object?>> initialRules = const [],
    String? clientMutationId,
  }) async {
    try {
      final result = await _client.rpc(
        'create_pack_stage_tracker',
        params: {
          'target_pack_id': packId,
          'title': title,
          'subject_name': subjectName,
          'tracking_start_date': trackingStartDate.toIso8601String(),
          'tracking_end_date': trackingEndDate?.toIso8601String(),
          'initial_rules_json': initialRules,
          'client_mutation_id': clientMutationId,
        },
      );
      final row = _mapRpcResult(result);
      return RemoteStageTrackerCreateResult(
        stageTrackerId: _requiredString(row, 'stage_tracker_id'),
        ruleIdsByClientLocalId: _stageRuleIdsByClientLocalId(
          row['rule_ids_by_client_local_id'],
        ),
        status: _optionalString(row, 'status') ?? 'created',
      );
    } catch (error) {
      throw _mapError(
        error,
        RemoteSharedPackFailureReason.remoteUnknownFailure,
        operationName: 'create_pack_stage_tracker',
      );
    }
  }

  @override
  Future<RemoteStageMutationResult> updatePackStageTracker({
    required String stageTrackerId,
    required String title,
    String? subjectName,
    required DateTime trackingStartDate,
    DateTime? trackingEndDate,
    String? clientMutationId,
  }) async {
    try {
      final result = await _client.rpc(
        'update_pack_stage_tracker',
        params: {
          'target_stage_tracker_id': stageTrackerId,
          'title': title,
          'subject_name': subjectName,
          'tracking_start_date': trackingStartDate.toIso8601String(),
          'tracking_end_date': trackingEndDate?.toIso8601String(),
          'client_mutation_id': clientMutationId,
        },
      );
      final row = _mapRpcResult(result);
      return RemoteStageMutationResult(
        entityId: _requiredString(row, 'stage_tracker_id'),
        status: _optionalString(row, 'status') ?? 'updated',
      );
    } catch (error) {
      throw _mapError(
        error,
        RemoteSharedPackFailureReason.remoteUnknownFailure,
        operationName: 'update_pack_stage_tracker',
      );
    }
  }

  @override
  Future<RemoteStageMutationResult> archivePackStageTracker({
    required String stageTrackerId,
    String? clientMutationId,
  }) async {
    try {
      final result = await _client.rpc(
        'archive_pack_stage_tracker',
        params: {
          'target_stage_tracker_id': stageTrackerId,
          'client_mutation_id': clientMutationId,
        },
      );
      final row = _mapRpcResult(result);
      return RemoteStageMutationResult(
        entityId: _requiredString(row, 'stage_tracker_id'),
        status: _optionalString(row, 'status') ?? 'archived',
      );
    } catch (error) {
      throw _mapError(
        error,
        RemoteSharedPackFailureReason.remoteUnknownFailure,
        operationName: 'archive_pack_stage_tracker',
      );
    }
  }

  @override
  Future<RemoteStageMutationResult> createPackStageRule({
    required String stageTrackerId,
    required Map<String, Object?> fields,
    String? clientMutationId,
  }) async {
    try {
      final result = await _client.rpc(
        'create_pack_stage_rule',
        params: {
          'target_stage_tracker_id': stageTrackerId,
          'fields_json': fields,
          'client_mutation_id': clientMutationId,
        },
      );
      final row = _mapRpcResult(result);
      return RemoteStageMutationResult(
        entityId: _requiredString(row, 'stage_rule_id'),
        status: _optionalString(row, 'status') ?? 'created',
      );
    } catch (error) {
      throw _mapError(
        error,
        RemoteSharedPackFailureReason.remoteUnknownFailure,
        operationName: 'create_pack_stage_rule',
      );
    }
  }

  @override
  Future<RemoteStageMutationResult> updatePackStageRule({
    required String stageRuleId,
    required Map<String, Object?> fields,
    String? clientMutationId,
  }) async {
    try {
      final result = await _client.rpc(
        'update_pack_stage_rule',
        params: {
          'target_stage_rule_id': stageRuleId,
          'fields_json': fields,
          'client_mutation_id': clientMutationId,
        },
      );
      final row = _mapRpcResult(result);
      return RemoteStageMutationResult(
        entityId: _requiredString(row, 'stage_rule_id'),
        status: _optionalString(row, 'status') ?? 'updated',
      );
    } catch (error) {
      throw _mapError(
        error,
        RemoteSharedPackFailureReason.remoteUnknownFailure,
        operationName: 'update_pack_stage_rule',
      );
    }
  }

  @override
  Future<RemoteStageMutationResult> updatePackStageRuleStatus({
    required String stageRuleId,
    required String status,
    String? clientMutationId,
  }) async {
    try {
      final result = await _client.rpc(
        'update_pack_stage_rule_status',
        params: {
          'target_stage_rule_id': stageRuleId,
          'target_status': status,
          'client_mutation_id': clientMutationId,
        },
      );
      final row = _mapRpcResult(result);
      return RemoteStageMutationResult(
        entityId: _requiredString(row, 'stage_rule_id'),
        status: _optionalString(row, 'status') ?? 'updated',
      );
    } catch (error) {
      throw _mapError(
        error,
        RemoteSharedPackFailureReason.remoteUnknownFailure,
        operationName: 'update_pack_stage_rule_status',
      );
    }
  }

  @override
  Future<RemoteStageMutationResult> createPackStageRecord({
    required String stageTrackerId,
    String? stageRuleId,
    required Map<String, Object?> fields,
    String? clientMutationId,
  }) async {
    try {
      final result = await _client.rpc(
        'create_pack_stage_record',
        params: {
          'target_stage_tracker_id': stageTrackerId,
          'target_stage_rule_id': stageRuleId,
          'fields_json': fields,
          'client_mutation_id': clientMutationId,
        },
      );
      final row = _mapRpcResult(result);
      return RemoteStageMutationResult(
        entityId: _requiredString(row, 'stage_record_id'),
        status: _optionalString(row, 'status') ?? 'created',
      );
    } catch (error) {
      throw _mapError(
        error,
        RemoteSharedPackFailureReason.remoteUnknownFailure,
        operationName: 'create_pack_stage_record',
      );
    }
  }

  @override
  Future<RemoteStageMutationResult> updatePackStageRecord({
    required String stageRecordId,
    required Map<String, Object?> fields,
    String? clientMutationId,
  }) async {
    try {
      final result = await _client.rpc(
        'update_pack_stage_record',
        params: {
          'target_stage_record_id': stageRecordId,
          'fields_json': fields,
          'client_mutation_id': clientMutationId,
        },
      );
      final row = _mapRpcResult(result);
      return RemoteStageMutationResult(
        entityId: _requiredString(row, 'stage_record_id'),
        status: _optionalString(row, 'status') ?? 'updated',
      );
    } catch (error) {
      throw _mapError(
        error,
        RemoteSharedPackFailureReason.remoteUnknownFailure,
        operationName: 'update_pack_stage_record',
      );
    }
  }

  @override
  Future<RemoteStageMutationResult> archivePackStageRecord({
    required String stageRecordId,
    String? clientMutationId,
  }) async {
    try {
      final result = await _client.rpc(
        'archive_pack_stage_record',
        params: {
          'target_stage_record_id': stageRecordId,
          'client_mutation_id': clientMutationId,
        },
      );
      final row = _mapRpcResult(result);
      return RemoteStageMutationResult(
        entityId: _requiredString(row, 'stage_record_id'),
        status: _optionalString(row, 'status') ?? 'archived',
      );
    } catch (error) {
      throw _mapError(
        error,
        RemoteSharedPackFailureReason.remoteUnknownFailure,
        operationName: 'archive_pack_stage_record',
      );
    }
  }

  @override
  Future<RemoteStageAcknowledgementResult> acknowledgePackStageRecord({
    required String stageRecordId,
    String? clientMutationId,
  }) async {
    try {
      final result = await _client.rpc(
        'acknowledge_pack_stage_record',
        params: {
          'target_stage_record_id': stageRecordId,
          'client_mutation_id': clientMutationId,
        },
      );
      final row = _mapRpcResult(result);
      return RemoteStageAcknowledgementResult(
        stageRecordId: _requiredString(row, 'stage_record_id'),
        acknowledgementId: _requiredString(row, 'acknowledgement_id'),
        status: _optionalString(row, 'status') ?? 'acknowledged',
        acknowledgedAt: _requiredDate(row, 'acknowledged_at'),
      );
    } catch (error) {
      throw _mapError(
        error,
        RemoteSharedPackFailureReason.remoteUnknownFailure,
        operationName: 'acknowledge_pack_stage_record',
      );
    }
  }

  @override
  Future<RemoteItemCompletionResult> completePackItem({
    required String itemId,
    String? clientMutationId,
  }) async {
    try {
      final result = await _client.rpc(
        'complete_pack_item',
        params: {'item_id': itemId, 'client_mutation_id': clientMutationId},
      );
      final row = _mapRpcResult(result);
      final status = _requiredString(row, 'status');
      return RemoteItemCompletionResult(
        status: status == 'already_completed'
            ? RemoteItemCompletionStatus.alreadyCompleted
            : RemoteItemCompletionStatus.completed,
        completionId: _requiredString(row, 'completion_id'),
        completedByUserId: _requiredString(row, 'completed_by_user_id'),
        completedAt: _requiredDate(row, 'completed_at'),
      );
    } catch (error) {
      throw _mapError(
        error,
        RemoteSharedPackFailureReason.remoteUnknownFailure,
        operationName: 'complete_pack_item',
      );
    }
  }

  @override
  Future<RemoteItemUndoResult> undoPackItemCompletion({
    required String itemId,
    String? clientMutationId,
  }) async {
    try {
      final result = await _client.rpc(
        'undo_pack_item_completion',
        params: {
          'target_item_id': itemId,
          'client_mutation_id': clientMutationId,
        },
      );
      final row = _mapRpcResult(result);
      final status = _requiredString(row, 'status');
      return RemoteItemUndoResult(
        status: status == 'already_not_completed'
            ? RemoteItemUndoStatus.alreadyNotCompleted
            : RemoteItemUndoStatus.undone,
        itemId: _requiredString(row, 'item_id'),
        completionId: _optionalString(row, 'completion_id'),
        undoneByUserId: row['undone_by_user_id'] as String?,
        undoneAt: _optionalDate(row, 'undone_at'),
      );
    } catch (error) {
      throw _mapError(
        error,
        RemoteSharedPackFailureReason.remoteUnknownFailure,
        operationName: 'undo_pack_item_completion',
      );
    }
  }

  @override
  Future<RemotePackSnapshot> fetchPackSnapshot(String remotePackId) async {
    try {
      final pack = await _client
          .from('packs')
          .select()
          .eq('id', remotePackId)
          .single();
      final members = await _client
          .from('pack_members')
          .select('*, profiles(display_name)')
          .eq('pack_id', remotePackId)
          .order('joined_at');
      final items = await _client
          .from('items')
          .select()
          .eq('pack_id', remotePackId)
          .order('created_at');
      final resources = await _client
          .from('resources')
          .select()
          .eq('pack_id', remotePackId)
          .order('created_at');
      final stageTrackers = await _client
          .from('stage_trackers')
          .select()
          .eq('pack_id', remotePackId)
          .order('created_at');
      final stageRules = await _client
          .from('stage_rules')
          .select()
          .eq('pack_id', remotePackId)
          .order('created_at');
      final stageRecords = await _client
          .from('stage_records')
          .select()
          .eq('pack_id', remotePackId)
          .order('occurrence_date');
      final stageAcknowledgements = await _client
          .from('stage_acknowledgements')
          .select()
          .eq('pack_id', remotePackId)
          .order('acknowledged_at');
      final completions = await _client
          .from('item_completions')
          .select()
          .eq('pack_id', remotePackId)
          .order('completed_at');
      final resourceEvents = await _client
          .from('resource_events')
          .select()
          .eq('pack_id', remotePackId)
          .order('created_at');
      final events = await _client
          .from('activity_events')
          .select()
          .eq('pack_id', remotePackId)
          .order('created_at');
      return _snapshotFromRows(
        pack: Map<String, Object?>.from(pack),
        members: _listOfMaps(members),
        items: _listOfMaps(items),
        resources: _listOfMaps(resources),
        stageTrackers: _listOfMaps(stageTrackers),
        stageRules: _listOfMaps(stageRules),
        stageRecords: _listOfMaps(stageRecords),
        stageAcknowledgements: _listOfMaps(stageAcknowledgements),
        completions: _listOfMaps(completions),
        resourceEvents: _listOfMaps(resourceEvents),
        events: _listOfMaps(events),
      );
    } catch (error) {
      throw _mapError(error, RemoteSharedPackFailureReason.malformedRemoteData);
    }
  }

  @override
  Future<void> reportPackSnapshotImported({
    required String remotePackId,
    String? latestActivityEventId,
    DateTime? latestActivityAt,
  }) async {
    try {
      await _client.rpc(
        'report_pack_snapshot_imported',
        params: {
          'target_pack_id': remotePackId,
          'latest_activity_event_id': latestActivityEventId,
          'latest_activity_at': latestActivityAt?.toUtc().toIso8601String(),
        },
      );
    } catch (error) {
      throw _mapError(
        error,
        RemoteSharedPackFailureReason.remoteUnknownFailure,
        operationName: 'report_pack_snapshot_imported',
      );
    }
  }

  @override
  Future<List<RemotePackMemberFreshness>> getPackMemberFreshness({
    required String remotePackId,
  }) async {
    try {
      final result = await _client.rpc(
        'get_pack_member_freshness',
        params: {'target_pack_id': remotePackId},
      );
      return _listOfMaps(result).map(_freshnessFromRow).toList(growable: false);
    } catch (error) {
      throw _mapError(
        error,
        RemoteSharedPackFailureReason.remoteUnknownFailure,
        operationName: 'get_pack_member_freshness',
      );
    }
  }
}

String _stringRpcResult(Object? result, String key) {
  if (result is String) {
    return result;
  }
  if (result is Map) {
    final value = result[key] ?? result['id'];
    if (value is String) {
      return value;
    }
  }
  if (result is List && result.isNotEmpty) {
    return _stringRpcResult(result.first, key);
  }
  throw const RemoteSharedPackException(
    RemoteSharedPackFailureReason.malformedRemoteData,
  );
}

Map<String, Object?> _mapRpcResult(Object? result) {
  if (result is Map) {
    return Map<String, Object?>.from(result);
  }
  if (result is List && result.isNotEmpty && result.first is Map) {
    return Map<String, Object?>.from(result.first as Map);
  }
  throw const RemoteSharedPackException(
    RemoteSharedPackFailureReason.malformedRemoteData,
  );
}

Map<int, String> _stageRuleIdsByClientLocalId(Object? value) {
  if (value == null) {
    return const {};
  }
  if (value is Map) {
    return {
      for (final entry in value.entries)
        if (int.tryParse(entry.key.toString()) != null && entry.value is String)
          int.parse(entry.key.toString()): entry.value as String,
    };
  }
  throw const RemoteSharedPackException(
    RemoteSharedPackFailureReason.malformedRemoteData,
  );
}

List<Map<String, Object?>> _listOfMaps(Object? result) {
  if (result is! List) {
    throw const RemoteSharedPackException(
      RemoteSharedPackFailureReason.malformedRemoteData,
    );
  }
  return [
    for (final item in result)
      if (item is Map)
        Map<String, Object?>.from(item)
      else
        throw const RemoteSharedPackException(
          RemoteSharedPackFailureReason.malformedRemoteData,
        ),
  ];
}

RemotePackSnapshot _snapshotFromRows({
  required Map<String, Object?> pack,
  required List<Map<String, Object?>> members,
  required List<Map<String, Object?>> items,
  required List<Map<String, Object?>> resources,
  required List<Map<String, Object?>> stageTrackers,
  required List<Map<String, Object?>> stageRules,
  required List<Map<String, Object?>> stageRecords,
  required List<Map<String, Object?>> stageAcknowledgements,
  required List<Map<String, Object?>> completions,
  required List<Map<String, Object?>> resourceEvents,
  required List<Map<String, Object?>> events,
}) {
  return RemotePackSnapshot(
    id: _requiredString(pack, 'id'),
    name: _requiredString(pack, 'name'),
    description: pack['description'] as String?,
    hostUserId: _requiredString(pack, 'host_user_id'),
    status: _requiredString(pack, 'status'),
    createdAt: _requiredDate(pack, 'created_at'),
    updatedAt: _requiredDate(pack, 'updated_at'),
    members: members.map(_memberFromRow).toList(growable: false),
    items: items.map(_itemFromRow).toList(growable: false),
    resources: resources.map(_resourceFromRow).toList(growable: false),
    stageTrackers: stageTrackers
        .map(_stageTrackerFromRow)
        .toList(growable: false),
    stageRules: stageRules.map(_stageRuleFromRow).toList(growable: false),
    stageRecords: stageRecords.map(_stageRecordFromRow).toList(growable: false),
    stageAcknowledgements: stageAcknowledgements
        .map(_stageAcknowledgementFromRow)
        .toList(growable: false),
    completions: completions.map(_completionFromRow).toList(growable: false),
    resourceEvents: resourceEvents
        .map(_resourceEventFromRow)
        .toList(growable: false),
    activityEvents: events.map(_activityEventFromRow).toList(growable: false),
  );
}

RemotePackMemberSnapshot _memberFromRow(Map<String, Object?> row) {
  return RemotePackMemberSnapshot(
    id: _requiredString(row, 'id'),
    packId: _requiredString(row, 'pack_id'),
    userId: _requiredString(row, 'user_id'),
    displayName: _optionalDisplayName(row),
    role: _requiredString(row, 'role'),
    status: _requiredString(row, 'status'),
    joinedAt: _requiredDate(row, 'joined_at'),
  );
}

RemoteRecoverablePack _recoverablePackFromMembershipRow(
  Map<String, Object?> row,
) {
  final pack = row['packs'];
  if (pack is! Map) {
    throw const RemoteSharedPackException(
      RemoteSharedPackFailureReason.malformedRemoteData,
    );
  }
  final packRow = Map<String, Object?>.from(pack);
  return RemoteRecoverablePack(
    remotePackId: _requiredString(packRow, 'id'),
    name: _requiredString(packRow, 'name'),
    description: packRow['description'] as String?,
    role: _requiredString(row, 'role'),
    memberStatus: _requiredString(row, 'status'),
    packStatus: _requiredString(packRow, 'status'),
    hostUserId: _requiredString(packRow, 'host_user_id'),
    updatedAt: _requiredDate(packRow, 'updated_at'),
  );
}

String? _optionalDisplayName(Map<String, Object?> row) {
  final direct = row['display_name'];
  if (direct is String && direct.isNotEmpty) {
    return direct;
  }
  final profile = row['profiles'];
  if (profile is Map) {
    final value = profile['display_name'];
    if (value is String && value.isNotEmpty) {
      return value;
    }
  }
  return null;
}

RemoteItemSnapshot _itemFromRow(Map<String, Object?> row) {
  return RemoteItemSnapshot(
    id: _requiredString(row, 'id'),
    packId: _requiredString(row, 'pack_id'),
    title: _requiredString(row, 'title'),
    note: row['note'] as String?,
    status: _requiredString(row, 'status'),
    assignedToUserId: row['assigned_to_user_id'] as String?,
    createdByUserId: _requiredString(row, 'created_by_user_id'),
    updatedByUserId: _requiredString(row, 'updated_by_user_id'),
    createdAt: _requiredDate(row, 'created_at'),
    updatedAt: _requiredDate(row, 'updated_at'),
  );
}

RemoteItemCompletionSnapshot _completionFromRow(Map<String, Object?> row) {
  return RemoteItemCompletionSnapshot(
    id: _requiredString(row, 'id'),
    packId: _requiredString(row, 'pack_id'),
    itemId: _requiredString(row, 'item_id'),
    completedByUserId: _requiredString(row, 'completed_by_user_id'),
    completedAt: _requiredDate(row, 'completed_at'),
    undoneByUserId: row['undone_by_user_id'] as String?,
    undoneAt: _optionalDate(row, 'undone_at'),
    clientMutationId: row['client_mutation_id'] as String?,
    createdAt: _requiredDate(row, 'created_at'),
  );
}

RemoteResourceSnapshot _resourceFromRow(Map<String, Object?> row) {
  return RemoteResourceSnapshot(
    id: _requiredString(row, 'id'),
    packId: _requiredString(row, 'pack_id'),
    title: _requiredString(row, 'title', fallbackKey: 'name'),
    description: row['description'] as String?,
    status: _requiredString(row, 'status'),
    type: _requiredString(row, 'type'),
    timeAnchorDate: _optionalDate(row, 'time_anchor_date'),
    timeDurationDays: _optionalInt(row, 'time_duration_days'),
    timeExpectedBeforeDays: _optionalInt(row, 'time_expected_before_days'),
    timeWarningBeforeDays: _optionalInt(row, 'time_warning_before_days'),
    timeDangerBeforeDays: _optionalInt(row, 'time_danger_before_days'),
    quantityCurrent:
        _optionalInt(row, 'quantity_current') ??
        _optionalInt(row, 'current_value'),
    quantityUnitLabel:
        row['quantity_unit_label'] as String? ?? row['unit'] as String?,
    quantityExpectedThreshold: _optionalInt(row, 'quantity_expected_threshold'),
    quantityWarningThreshold:
        _optionalInt(row, 'quantity_warning_threshold') ??
        _optionalInt(row, 'warning_threshold'),
    quantityDangerThreshold:
        _optionalInt(row, 'quantity_danger_threshold') ??
        _optionalInt(row, 'danger_threshold'),
    lastRefilledAt: _optionalDate(row, 'last_refilled_at'),
    createdByUserId: _requiredString(row, 'created_by_user_id'),
    updatedByUserId: _requiredString(row, 'updated_by_user_id'),
    createdAt: _requiredDate(row, 'created_at'),
    updatedAt: _requiredDate(row, 'updated_at'),
  );
}

RemoteResourceEventSnapshot _resourceEventFromRow(Map<String, Object?> row) {
  return RemoteResourceEventSnapshot(
    id: _requiredString(row, 'id'),
    packId: _requiredString(row, 'pack_id'),
    resourceId: _requiredString(row, 'resource_id'),
    actorUserId: _requiredString(row, 'actor_user_id'),
    changeType: _requiredString(row, 'change_type'),
    previousValue: _optionalInt(row, 'previous_value'),
    newValue: _optionalInt(row, 'new_value'),
    deltaValue: _optionalInt(row, 'delta_value'),
    unit: row['unit'] as String?,
    metadataJson: _jsonMap(row['metadata_json']),
    createdAt: _requiredDate(row, 'created_at'),
  );
}

RemoteStageTrackerSnapshot _stageTrackerFromRow(Map<String, Object?> row) {
  return RemoteStageTrackerSnapshot(
    id: _requiredString(row, 'id'),
    packId: _requiredString(row, 'pack_id'),
    title: _requiredString(row, 'title'),
    subjectName: row['subject_name'] as String?,
    trackingStartDate: _requiredDate(row, 'tracking_start_date'),
    trackingEndDate: _optionalDate(row, 'tracking_end_date'),
    status: _requiredString(row, 'status'),
    createdByUserId: _requiredString(row, 'created_by_user_id'),
    updatedByUserId: _requiredString(row, 'updated_by_user_id'),
    createdAt: _requiredDate(row, 'created_at'),
    updatedAt: _requiredDate(row, 'updated_at'),
  );
}

RemoteStageRuleSnapshot _stageRuleFromRow(Map<String, Object?> row) {
  return RemoteStageRuleSnapshot(
    id: _requiredString(row, 'id'),
    packId: _requiredString(row, 'pack_id'),
    stageTrackerId: _requiredString(row, 'stage_tracker_id'),
    type: _requiredString(row, 'type'),
    intervalValue: _optionalInt(row, 'interval_value') ?? 1,
    intervalUnit: _requiredString(row, 'interval_unit'),
    labelTemplate: row['label_template'] as String?,
    reminderOffsetDays: _optionalInt(row, 'reminder_offset_days'),
    status: _requiredString(row, 'status'),
    createdByUserId: _requiredString(row, 'created_by_user_id'),
    updatedByUserId: _requiredString(row, 'updated_by_user_id'),
    createdAt: _requiredDate(row, 'created_at'),
    updatedAt: _requiredDate(row, 'updated_at'),
  );
}

RemoteStageRecordSnapshot _stageRecordFromRow(Map<String, Object?> row) {
  return RemoteStageRecordSnapshot(
    id: _requiredString(row, 'id'),
    packId: _requiredString(row, 'pack_id'),
    stageTrackerId: _requiredString(row, 'stage_tracker_id'),
    stageRuleId: row['stage_rule_id'] as String?,
    sourceType: _requiredString(row, 'source_type'),
    occurrenceIndex: _optionalInt(row, 'occurrence_index'),
    occurrenceDate: _requiredDate(row, 'occurrence_date'),
    relativeAmount: _optionalInt(row, 'relative_amount'),
    relativeUnit: row['relative_unit'] as String?,
    status: _requiredString(row, 'status'),
    label: _requiredString(row, 'label'),
    note: row['note'] as String?,
    reminderOffsetDays: _optionalInt(row, 'reminder_offset_days'),
    createdByUserId: _requiredString(row, 'created_by_user_id'),
    updatedByUserId: _requiredString(row, 'updated_by_user_id'),
    createdAt: _requiredDate(row, 'created_at'),
    updatedAt: _requiredDate(row, 'updated_at'),
  );
}

RemoteStageAcknowledgementSnapshot _stageAcknowledgementFromRow(
  Map<String, Object?> row,
) {
  return RemoteStageAcknowledgementSnapshot(
    id: _requiredString(row, 'id'),
    packId: _requiredString(row, 'pack_id'),
    stageRecordId: _requiredString(row, 'stage_record_id'),
    userId: _requiredString(row, 'user_id'),
    acknowledgedAt: _requiredDate(row, 'acknowledged_at'),
    createdAt: _requiredDate(row, 'created_at'),
    updatedAt: _requiredDate(row, 'updated_at'),
  );
}

RemoteActivityEventSnapshot _activityEventFromRow(Map<String, Object?> row) {
  return RemoteActivityEventSnapshot(
    id: _requiredString(row, 'id'),
    packId: _requiredString(row, 'pack_id'),
    actorUserId: row['actor_user_id'] as String?,
    actorDisplayNameSnapshot: row['actor_display_name_snapshot'] as String?,
    entityType: _requiredString(row, 'entity_type'),
    entityId: _requiredString(row, 'entity_id'),
    action: _requiredString(row, 'action'),
    beforeJson: _jsonMap(row['before_json']),
    afterJson: _jsonMap(row['after_json']),
    metadataJson: _jsonMap(row['metadata_json']),
    createdAt: _requiredDate(row, 'created_at'),
  );
}

RemotePackMemberFreshness _freshnessFromRow(Map<String, Object?> row) {
  return RemotePackMemberFreshness(
    remoteUserId: _requiredString(row, 'user_id'),
    displayName: _optionalString(row, 'display_name'),
    role: _requiredString(row, 'role'),
    memberStatus: _requiredString(row, 'member_status'),
    status: _freshnessStatus(_requiredString(row, 'freshness_status')),
    latestActivityEventId: _optionalString(row, 'latest_activity_event_id'),
    latestActivityAt: _optionalDate(row, 'latest_activity_at'),
    lastImportedAt: _optionalDate(row, 'last_imported_at'),
    lastSeenActivityEventId: _optionalString(
      row,
      'last_seen_activity_event_id',
    ),
    lastSeenActivityAt: _optionalDate(row, 'last_seen_activity_at'),
  );
}

RemotePackFreshnessStatus _freshnessStatus(String value) {
  return switch (value) {
    'up_to_date' => RemotePackFreshnessStatus.upToDate,
    'possibly_stale' => RemotePackFreshnessStatus.possiblyStale,
    'no_sync_report' => RemotePackFreshnessStatus.noSyncReport,
    _ => RemotePackFreshnessStatus.accessUnknown,
  };
}

String? _optionalString(Map<String, Object?> row, String key) {
  final value = row[key];
  if (value is String && value.isNotEmpty) {
    return value;
  }
  return null;
}

bool _optionalBool(Map<String, Object?> row, String key) {
  final value = row[key];
  if (value is bool) {
    return value;
  }
  return false;
}

String _requiredString(
  Map<String, Object?> row,
  String key, {
  String? fallbackKey,
}) {
  final value = row[key] ?? (fallbackKey == null ? null : row[fallbackKey]);
  if (value is String && value.isNotEmpty) {
    return value;
  }
  throw const RemoteSharedPackException(
    RemoteSharedPackFailureReason.malformedRemoteData,
  );
}

DateTime _requiredDate(Map<String, Object?> row, String key) {
  final value = _optionalDate(row, key);
  if (value != null) {
    return value;
  }
  throw const RemoteSharedPackException(
    RemoteSharedPackFailureReason.malformedRemoteData,
  );
}

int _requiredInt(Map<String, Object?> row, String key) {
  final value = row[key];
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  throw const RemoteSharedPackException(
    RemoteSharedPackFailureReason.malformedRemoteData,
  );
}

int? _optionalInt(Map<String, Object?> row, String key) {
  final value = row[key];
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  return null;
}

DateTime? _optionalDate(Map<String, Object?> row, String key) {
  final value = row[key];
  if (value == null) {
    return null;
  }
  if (value is DateTime) {
    return value;
  }
  if (value is String) {
    return DateTime.tryParse(value);
  }
  throw const RemoteSharedPackException(
    RemoteSharedPackFailureReason.malformedRemoteData,
  );
}

Map<String, Object?>? _jsonMap(Object? value) {
  if (value == null) {
    return null;
  }
  if (value is Map) {
    return Map<String, Object?>.from(value);
  }
  throw const RemoteSharedPackException(
    RemoteSharedPackFailureReason.malformedRemoteData,
  );
}

RemoteSharedPackException mapRemoteSharedPackError(
  Object error,
  RemoteSharedPackFailureReason fallback, {
  String? operationName,
}) {
  if (error is RemoteSharedPackException) {
    return error;
  }
  if (error is PostgrestException) {
    final status = error.code;
    if (status == '42501' || status == '403' || status == 'PGRST301') {
      return RemoteSharedPackException(
        RemoteSharedPackFailureReason.remoteRlsRejected,
        error,
        operationName,
        status,
      );
    }
    final message = error.message.toLowerCase();
    if (message.contains('auth required')) {
      return RemoteSharedPackException(
        RemoteSharedPackFailureReason.remoteAuthRequired,
        error,
        operationName,
        status,
      );
    }
    if (message.contains('profile required')) {
      return RemoteSharedPackException(
        RemoteSharedPackFailureReason.remoteProfileFailed,
        error,
        operationName,
        status,
      );
    }
    if (message.contains('active pack member required') ||
        message.contains('item not found')) {
      return RemoteSharedPackException(
        RemoteSharedPackFailureReason.remoteRlsRejected,
        error,
        operationName,
        status,
      );
    }
    if (message.contains('invite expired')) {
      return RemoteSharedPackException(
        RemoteSharedPackFailureReason.remoteInviteExpired,
        error,
        operationName,
        status,
      );
    }
    if (message.contains('invite max uses reached')) {
      return RemoteSharedPackException(
        RemoteSharedPackFailureReason.remoteInviteMaxUsesReached,
        error,
        operationName,
        status,
      );
    }
    if (message.contains('invite invalid')) {
      return RemoteSharedPackException(
        RemoteSharedPackFailureReason.remoteInviteInvalid,
        error,
        operationName,
        status,
      );
    }
    if (message.contains('already revoked')) {
      return RemoteSharedPackException(
        RemoteSharedPackFailureReason.remoteInviteAlreadyRevoked,
        error,
        operationName,
        status,
      );
    }
    if (message.contains('pack host required')) {
      return RemoteSharedPackException(
        RemoteSharedPackFailureReason.remoteInviteNotHost,
        error,
        operationName,
        status,
      );
    }
    return RemoteSharedPackException(fallback, error, operationName, status);
  }
  return RemoteSharedPackException(fallback, error);
}

RemoteSharedPackException _mapError(
  Object error,
  RemoteSharedPackFailureReason fallback, {
  String? operationName,
}) {
  return mapRemoteSharedPackError(
    error,
    fallback,
    operationName: operationName,
  );
}
