import 'shared_pack_remote_api.dart';
import 'shared_pack_remote_dto.dart';

class SharedPackRemoteRepository {
  const SharedPackRemoteRepository(this._api);

  final SharedPackRemoteApi _api;

  Future<CreateSharedPackRemoteResponse> createPack(
    CreateSharedPackRemoteRequest request,
  ) {
    return _api.createPack(request);
  }

  Future<GenerateSharedPackInviteRemoteResponse> generateInvite(
    GenerateSharedPackInviteRemoteRequest request,
  ) {
    return _api.generateInvite(request);
  }

  Future<PreviewSharedPackInviteRemoteResponse> previewInvite(
    PreviewSharedPackInviteRemoteRequest request,
  ) {
    return _api.previewInvite(request);
  }

  Future<JoinSharedPackByInviteRemoteResponse> joinByInvite(
    JoinSharedPackByInviteRemoteRequest request,
  ) {
    return _api.joinByInvite(request);
  }

  Future<FetchSharedPackSnapshotRemoteResponse> fetchSnapshot(
    FetchSharedPackSnapshotRemoteRequest request,
  ) {
    return _api.fetchSnapshot(request);
  }

  Future<UpdateSharedPackItemStateRemoteResponse> updateItemState(
    UpdateSharedPackItemStateRemoteRequest request,
  ) {
    return _api.updateItemState(request);
  }
}
