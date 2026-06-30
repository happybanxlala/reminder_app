import 'shared_pack_remote_request_ids.dart';

class SharedPackRemoteException implements Exception {
  const SharedPackRemoteException({
    required this.requestId,
    required this.operation,
    required this.message,
    this.cause,
  });

  final String requestId;
  final String operation;
  final String message;
  final Object? cause;

  @override
  String toString() {
    final causeText = cause == null ? '' : ' Cause: ${cause.runtimeType}';
    return 'SharedPackRemoteException($requestId, $operation): $message$causeText';
  }
}

class CreateSharedPackRemoteRequest {
  const CreateSharedPackRemoteRequest({
    required this.name,
    required this.ownerIdentityId,
    this.requestId = SharedPackRemoteRequestIds.createPackV1,
  });

  final String requestId;
  final String name;
  final String ownerIdentityId;
}

class CreateSharedPackRemoteResponse {
  const CreateSharedPackRemoteResponse({
    required this.remotePackId,
    required this.name,
    required this.ownerMembershipId,
    this.requestId = SharedPackRemoteRequestIds.createPackV1,
  });

  final String requestId;
  final String remotePackId;
  final String name;
  final String ownerMembershipId;
}

class GenerateSharedPackInviteRemoteRequest {
  const GenerateSharedPackInviteRemoteRequest({
    required this.remotePackId,
    required this.requesterIdentityId,
    this.requestId = SharedPackRemoteRequestIds.generateInviteV1,
  });

  final String requestId;
  final String remotePackId;
  final String requesterIdentityId;
}

class GenerateSharedPackInviteRemoteResponse {
  const GenerateSharedPackInviteRemoteResponse({
    required this.inviteId,
    required this.inviteCode,
    required this.expiresAt,
    this.requestId = SharedPackRemoteRequestIds.generateInviteV1,
  });

  final String requestId;
  final String inviteId;
  final String inviteCode;
  final DateTime? expiresAt;
}

class PreviewSharedPackInviteRemoteRequest {
  const PreviewSharedPackInviteRemoteRequest({
    required this.inviteCode,
    this.requestId = SharedPackRemoteRequestIds.previewInviteV1,
  });

  final String requestId;
  final String inviteCode;
}

class PreviewSharedPackInviteRemoteResponse {
  const PreviewSharedPackInviteRemoteResponse({
    required this.remotePackId,
    required this.packName,
    required this.isJoinable,
    this.requestId = SharedPackRemoteRequestIds.previewInviteV1,
  });

  final String requestId;
  final String? remotePackId;
  final String? packName;
  final bool isJoinable;
}

class JoinSharedPackByInviteRemoteRequest {
  const JoinSharedPackByInviteRemoteRequest({
    required this.inviteCode,
    required this.joinerIdentityId,
    this.requestId = SharedPackRemoteRequestIds.joinByInviteV1,
  });

  final String requestId;
  final String inviteCode;
  final String joinerIdentityId;
}

class JoinSharedPackByInviteRemoteResponse {
  const JoinSharedPackByInviteRemoteResponse({
    required this.remotePackId,
    required this.membershipId,
    required this.packName,
    this.requestId = SharedPackRemoteRequestIds.joinByInviteV1,
  });

  final String requestId;
  final String remotePackId;
  final String membershipId;
  final String packName;
}

class FetchSharedPackSnapshotRemoteRequest {
  const FetchSharedPackSnapshotRemoteRequest({
    required this.remotePackId,
    required this.requesterIdentityId,
    this.requestId = SharedPackRemoteRequestIds.fetchSnapshotV1,
  });

  final String requestId;
  final String remotePackId;
  final String requesterIdentityId;
}

class FetchSharedPackSnapshotRemoteResponse {
  const FetchSharedPackSnapshotRemoteResponse({
    required this.remotePackId,
    required this.packName,
    required this.requesterRole,
    required this.items,
    this.requestId = SharedPackRemoteRequestIds.fetchSnapshotV1,
  });

  final String requestId;
  final String remotePackId;
  final String packName;
  final String requesterRole;
  final List<SharedPackSnapshotItemRemoteDto> items;
}

class SharedPackSnapshotItemRemoteDto {
  const SharedPackSnapshotItemRemoteDto({
    required this.remoteItemId,
    required this.title,
    required this.state,
    required this.createdAt,
    required this.updatedAt,
    this.notes,
    this.schedulePayload,
    this.lastCompletedAt,
    this.updatedByIdentityId,
    this.archivedAt,
  });

  final String remoteItemId;
  final String title;
  final String? notes;
  final Map<String, dynamic>? schedulePayload;
  final String state;
  final DateTime? lastCompletedAt;
  final String? updatedByIdentityId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? archivedAt;
}

class UpdateSharedPackItemStateRemoteRequest {
  const UpdateSharedPackItemStateRemoteRequest({
    required this.remoteItemId,
    required this.requesterIdentityId,
    required this.newState,
    this.completedAt,
    this.requestId = SharedPackRemoteRequestIds.updateItemStateV1,
  });

  final String requestId;
  final String remoteItemId;
  final String requesterIdentityId;
  final String newState;
  final DateTime? completedAt;
}

class UpdateSharedPackItemStateRemoteResponse {
  const UpdateSharedPackItemStateRemoteResponse({
    required this.remoteItemId,
    required this.remotePackId,
    required this.state,
    required this.lastCompletedAt,
    required this.updatedAt,
    this.requestId = SharedPackRemoteRequestIds.updateItemStateV1,
  });

  final String requestId;
  final String remoteItemId;
  final String remotePackId;
  final String state;
  final DateTime? lastCompletedAt;
  final DateTime updatedAt;
}
