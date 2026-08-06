import '../domain/shared_pack_ids.dart';
import 'shared_pack_commands.dart';
import 'shared_pack_outcomes.dart';
import 'shared_pack_queries.dart';
import 'shared_pack_read_models.dart';

/// Sole application facade for Shared Pack reads, commands and recovery.
abstract interface class SharedPackApplicationService {
  Stream<SharedPackListReadModel> watchPackList();

  Stream<SharedPackDetailReadModel?> watchPackDetail(RemotePackId packId);

  Stream<UnresolvedMutationPresentation> watchRecovery();

  Future<SharedCommandOutcome<SharedPackDetailReadModel>> createSharedPack(
    CreateSharedPackCommand command,
  );

  Future<SharedCommandOutcome<SharedPackDetailReadModel>>
  updateSharedPackMetadata(UpdateSharedPackMetadataCommand command);

  Future<SharedCommandOutcome<SharedItemReadModel>> createSharedItem(
    CreateSharedItemCommand command,
  );

  Future<SharedCommandOutcome<SharedItemReadModel>> updateSharedItem(
    UpdateSharedItemCommand command,
  );

  Future<SharedCommandOutcome<ArchivedSharedItemResult>> archiveSharedItem(
    ArchiveSharedItemCommand command,
  );

  Future<SharedCommandOutcome<SharedItemReadModel>> completeSharedItem(
    CompleteSharedItemCommand command,
  );

  Future<SharedCommandOutcome<InviteCodePresentation>> getOrCreateInviteCode(
    GetInviteCommand command,
  );

  Future<SharedCommandOutcome<InviteCodePresentation>> rotateInviteCode(
    RotateInviteCommand command,
  );

  Future<SharedQueryOutcome<InvitePreview>> previewInviteCode(
    PreviewInviteQuery query,
  );

  Future<SharedCommandOutcome<SharedPackDetailReadModel>> joinSharedPack(
    JoinSharedPackCommand command,
  );

  Future<SharedRefreshOutcome> refreshSharedPack(
    RefreshSharedPackCommand command,
  );

  Future<SharedCommandOutcome<Object?>> replayUnresolvedMutation(
    ReplayUnresolvedMutationCommand command,
  );
}
