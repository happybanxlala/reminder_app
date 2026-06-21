import 'package:supabase_flutter/supabase_flutter.dart';

import 'remote_shared_pack_models.dart';
import 'supabase_config.dart';

abstract class RemoteSharedPackDataSource {
  Future<String> upsertCurrentProfile({required String displayName});
  Future<String> createSharedPack({required String name, String? description});
  Future<RemotePackInvite> createPackInvite({required String packId});
  Future<RemoteJoinPackResult> joinPackWithInvite({required String inviteCode});
  Future<RemoteRevokeInviteResult> revokePackInvite({required String inviteId});
  Future<String> createPackItem({
    required String packId,
    required String title,
    String? note,
  });
  Future<RemoteItemCompletionResult> completePackItem({
    required String itemId,
    String? clientMutationId,
  });
  Future<RemoteItemUndoResult> undoPackItemCompletion({
    required String itemId,
    String? clientMutationId,
  });
  Future<RemotePackSnapshot> fetchPackSnapshot(String remotePackId);
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
  Future<RemoteJoinPackResult> joinPackWithInvite({
    required String inviteCode,
  }) {
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
      throw _mapError(error, RemoteSharedPackFailureReason.remoteProfileFailed);
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
      );
    }
  }

  @override
  Future<RemotePackInvite> createPackInvite({required String packId}) async {
    try {
      final result = await _client.rpc(
        'create_pack_invite',
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
      throw _mapError(error, RemoteSharedPackFailureReason.remoteInviteNotHost);
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
      throw _mapError(error, RemoteSharedPackFailureReason.remoteInviteInvalid);
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
      throw _mapError(error, RemoteSharedPackFailureReason.remoteInviteNotHost);
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
      final completions = await _client
          .from('item_completions')
          .select()
          .eq('pack_id', remotePackId)
          .filter('undone_at', 'is', null)
          .order('completed_at');
      final events = await _client
          .from('activity_events')
          .select()
          .eq('pack_id', remotePackId)
          .order('created_at');
      return _snapshotFromRows(
        pack: Map<String, Object?>.from(pack),
        members: _listOfMaps(members),
        items: _listOfMaps(items),
        completions: _listOfMaps(completions),
        events: _listOfMaps(events),
      );
    } catch (error) {
      throw _mapError(error, RemoteSharedPackFailureReason.malformedRemoteData);
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
  required List<Map<String, Object?>> completions,
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
    completions: completions.map(_completionFromRow).toList(growable: false),
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

String? _optionalString(Map<String, Object?> row, String key) {
  final value = row[key];
  if (value is String && value.isNotEmpty) {
    return value;
  }
  return null;
}

String _requiredString(Map<String, Object?> row, String key) {
  final value = row[key];
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
  RemoteSharedPackFailureReason fallback,
) {
  if (error is RemoteSharedPackException) {
    return error;
  }
  if (error is PostgrestException) {
    final status = error.code;
    if (status == '42501' || status == 'PGRST301') {
      return RemoteSharedPackException(
        RemoteSharedPackFailureReason.remoteRlsRejected,
        error,
      );
    }
    final message = error.message.toLowerCase();
    if (message.contains('auth required')) {
      return RemoteSharedPackException(
        RemoteSharedPackFailureReason.remoteAuthRequired,
        error,
      );
    }
    if (message.contains('profile required')) {
      return RemoteSharedPackException(
        RemoteSharedPackFailureReason.remoteProfileFailed,
        error,
      );
    }
    if (message.contains('active pack member required') ||
        message.contains('item not found')) {
      return RemoteSharedPackException(
        RemoteSharedPackFailureReason.remoteRlsRejected,
        error,
      );
    }
    if (message.contains('invite expired')) {
      return RemoteSharedPackException(
        RemoteSharedPackFailureReason.remoteInviteExpired,
        error,
      );
    }
    if (message.contains('invite max uses reached')) {
      return RemoteSharedPackException(
        RemoteSharedPackFailureReason.remoteInviteMaxUsesReached,
        error,
      );
    }
    if (message.contains('invite invalid')) {
      return RemoteSharedPackException(
        RemoteSharedPackFailureReason.remoteInviteInvalid,
        error,
      );
    }
    if (message.contains('already revoked')) {
      return RemoteSharedPackException(
        RemoteSharedPackFailureReason.remoteInviteAlreadyRevoked,
        error,
      );
    }
    if (message.contains('pack host required')) {
      return RemoteSharedPackException(
        RemoteSharedPackFailureReason.remoteInviteNotHost,
        error,
      );
    }
    return RemoteSharedPackException(fallback, error);
  }
  return RemoteSharedPackException(fallback, error);
}

RemoteSharedPackException _mapError(
  Object error,
  RemoteSharedPackFailureReason fallback,
) {
  return mapRemoteSharedPackError(error, fallback);
}
