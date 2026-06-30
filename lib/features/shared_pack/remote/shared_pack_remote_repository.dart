import 'shared_pack_remote_dto.dart';

abstract class SharedPackRemoteRepository {
  const SharedPackRemoteRepository();

  Future<CreateSharedPackRemoteResponse> createPack(
    CreateSharedPackRemoteRequest request,
  );

  Future<GenerateSharedPackInviteRemoteResponse> generateInvite(
    GenerateSharedPackInviteRemoteRequest request,
  );

  Future<PreviewSharedPackInviteRemoteResponse> previewInvite(
    PreviewSharedPackInviteRemoteRequest request,
  );

  Future<JoinSharedPackByInviteRemoteResponse> joinByInvite(
    JoinSharedPackByInviteRemoteRequest request,
  );

  Future<FetchSharedPackSnapshotRemoteResponse> fetchSnapshot(
    FetchSharedPackSnapshotRemoteRequest request,
  );

  Future<UpdateSharedPackItemStateRemoteResponse> updateItemState(
    UpdateSharedPackItemStateRemoteRequest request,
  );
}
