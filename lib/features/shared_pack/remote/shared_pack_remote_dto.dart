import 'shared_pack_remote_request_ids.dart';

class CreateSharedPackRemoteRequest {
  const CreateSharedPackRemoteRequest({
    this.requestId = SharedPackRemoteRequestIds.createPackV1,
  });

  final String requestId;
}

class CreateSharedPackRemoteResponse {
  const CreateSharedPackRemoteResponse({
    this.requestId = SharedPackRemoteRequestIds.createPackV1,
    this.remotePackId,
  });

  final String requestId;
  final String? remotePackId;
}

class GenerateSharedPackInviteRemoteRequest {
  const GenerateSharedPackInviteRemoteRequest({
    this.requestId = SharedPackRemoteRequestIds.generateInviteV1,
    this.remotePackId,
  });

  final String requestId;
  final String? remotePackId;
}

class GenerateSharedPackInviteRemoteResponse {
  const GenerateSharedPackInviteRemoteResponse({
    this.requestId = SharedPackRemoteRequestIds.generateInviteV1,
    this.remotePackId,
    this.inviteCode,
  });

  final String requestId;
  final String? remotePackId;
  final String? inviteCode;
}

class PreviewSharedPackInviteRemoteRequest {
  const PreviewSharedPackInviteRemoteRequest({
    this.requestId = SharedPackRemoteRequestIds.previewInviteV1,
    this.inviteCode,
  });

  final String requestId;
  final String? inviteCode;
}

class PreviewSharedPackInviteRemoteResponse {
  const PreviewSharedPackInviteRemoteResponse({
    this.requestId = SharedPackRemoteRequestIds.previewInviteV1,
    this.remotePackId,
  });

  final String requestId;
  final String? remotePackId;
}

class JoinSharedPackByInviteRemoteRequest {
  const JoinSharedPackByInviteRemoteRequest({
    this.requestId = SharedPackRemoteRequestIds.joinByInviteV1,
    this.inviteCode,
  });

  final String requestId;
  final String? inviteCode;
}

class JoinSharedPackByInviteRemoteResponse {
  const JoinSharedPackByInviteRemoteResponse({
    this.requestId = SharedPackRemoteRequestIds.joinByInviteV1,
    this.remotePackId,
  });

  final String requestId;
  final String? remotePackId;
}

class FetchSharedPackSnapshotRemoteRequest {
  const FetchSharedPackSnapshotRemoteRequest({
    this.requestId = SharedPackRemoteRequestIds.fetchSnapshotV1,
    this.remotePackId,
  });

  final String requestId;
  final String? remotePackId;
}

class FetchSharedPackSnapshotRemoteResponse {
  const FetchSharedPackSnapshotRemoteResponse({
    this.requestId = SharedPackRemoteRequestIds.fetchSnapshotV1,
    this.remotePackId,
  });

  final String requestId;
  final String? remotePackId;
}

class UpdateSharedPackItemStateRemoteRequest {
  const UpdateSharedPackItemStateRemoteRequest({
    this.requestId = SharedPackRemoteRequestIds.updateItemStateV1,
    this.remotePackId,
    this.remoteItemId,
  });

  final String requestId;
  final String? remotePackId;
  final String? remoteItemId;
}

class UpdateSharedPackItemStateRemoteResponse {
  const UpdateSharedPackItemStateRemoteResponse({
    this.requestId = SharedPackRemoteRequestIds.updateItemStateV1,
    this.remotePackId,
    this.remoteItemId,
  });

  final String requestId;
  final String? remotePackId;
  final String? remoteItemId;
}
