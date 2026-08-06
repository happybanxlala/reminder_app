import '../domain/shared_equality.dart';
import '../domain/shared_pack_ids.dart';
import '../domain/shared_pack_models.dart';
import '../domain/shared_pack_runtime_values.dart';

enum SharedMutationOperation {
  createSharedPack,
  updateSharedPackMetadata,
  createSharedItem,
  updateSharedItem,
  archiveSharedItem,
  completeSharedItem,
  getOrCreateInviteCode,
  rotateInviteCode,
  joinSharedPack,
}

final class SharedPackMetadataDraft extends SharedValue {
  SharedPackMetadataDraft({
    required this.title,
    this.description,
    required this.iconEmoji,
  }) {
    validateSharedTitle(title, 'title');
    validateSharedDescription(description);
    validateSharedIcon(iconEmoji);
  }

  final String title;
  final String? description;
  final String iconEmoji;

  @override
  List<Object?> get equalityFields => [title, description, iconEmoji];
}

final class SharedItemDefinitionDraft extends SharedValue {
  SharedItemDefinitionDraft({
    required this.title,
    this.description,
    required this.thresholds,
  }) {
    validateSharedTitle(title, 'title');
    validateSharedDescription(description);
  }

  final String title;
  final String? description;
  final SharedItemThresholds thresholds;

  @override
  List<Object?> get equalityFields => [title, description, thresholds];
}

final class MembershipDisplayNameInput extends SharedValue {
  MembershipDisplayNameInput(String value)
    : value = canonicalizeDisplayName(value) {
    validateCanonicalDisplayName(this.value);
  }

  final String value;

  @override
  List<Object?> get equalityFields => [value];
}

sealed class SharedMutationCommand extends SharedValue {
  const SharedMutationCommand();

  SharedMutationOperation get operation;
}

final class CreateSharedPackCommand extends SharedMutationCommand {
  const CreateSharedPackCommand({
    required this.metadata,
    required this.ownerDisplayName,
  });

  final SharedPackMetadataDraft metadata;
  final MembershipDisplayNameInput ownerDisplayName;

  @override
  SharedMutationOperation get operation =>
      SharedMutationOperation.createSharedPack;

  @override
  List<Object?> get equalityFields => [metadata, ownerDisplayName];
}

final class UpdateSharedPackMetadataCommand extends SharedMutationCommand {
  const UpdateSharedPackMetadataCommand({
    required this.remotePackId,
    required this.expectedPackVersion,
    required this.metadata,
  });

  final RemotePackId remotePackId;
  final RemotePackVersion expectedPackVersion;
  final SharedPackMetadataDraft metadata;

  @override
  SharedMutationOperation get operation =>
      SharedMutationOperation.updateSharedPackMetadata;

  @override
  List<Object?> get equalityFields => [
    remotePackId,
    expectedPackVersion,
    metadata,
  ];
}

final class CreateSharedItemCommand extends SharedMutationCommand {
  const CreateSharedItemCommand({
    required this.remotePackId,
    required this.expectedPackVersion,
    required this.definition,
    required this.initialStateAnchorUtc,
  });

  final RemotePackId remotePackId;
  final RemotePackVersion expectedPackVersion;
  final SharedItemDefinitionDraft definition;
  final UtcInstant initialStateAnchorUtc;

  @override
  SharedMutationOperation get operation =>
      SharedMutationOperation.createSharedItem;

  @override
  List<Object?> get equalityFields => [
    remotePackId,
    expectedPackVersion,
    definition,
    initialStateAnchorUtc,
  ];
}

final class UpdateSharedItemCommand extends SharedMutationCommand {
  const UpdateSharedItemCommand({
    required this.remotePackId,
    required this.remoteItemId,
    required this.expectedItemVersion,
    required this.definition,
  });

  final RemotePackId remotePackId;
  final RemoteItemId remoteItemId;
  final RemoteItemVersion expectedItemVersion;
  final SharedItemDefinitionDraft definition;

  @override
  SharedMutationOperation get operation =>
      SharedMutationOperation.updateSharedItem;

  @override
  List<Object?> get equalityFields => [
    remotePackId,
    remoteItemId,
    expectedItemVersion,
    definition,
  ];
}

final class ArchiveSharedItemCommand extends SharedMutationCommand {
  const ArchiveSharedItemCommand({
    required this.remotePackId,
    required this.remoteItemId,
    required this.expectedItemVersion,
  });

  final RemotePackId remotePackId;
  final RemoteItemId remoteItemId;
  final RemoteItemVersion expectedItemVersion;

  @override
  SharedMutationOperation get operation =>
      SharedMutationOperation.archiveSharedItem;

  @override
  List<Object?> get equalityFields => [
    remotePackId,
    remoteItemId,
    expectedItemVersion,
  ];
}

final class CompleteSharedItemCommand extends SharedMutationCommand {
  const CompleteSharedItemCommand({
    required this.remotePackId,
    required this.remoteItemId,
    required this.expectedItemVersion,
  });

  final RemotePackId remotePackId;
  final RemoteItemId remoteItemId;
  final RemoteItemVersion expectedItemVersion;

  @override
  SharedMutationOperation get operation =>
      SharedMutationOperation.completeSharedItem;

  @override
  List<Object?> get equalityFields => [
    remotePackId,
    remoteItemId,
    expectedItemVersion,
  ];
}

final class GetInviteCommand extends SharedMutationCommand {
  const GetInviteCommand({required this.remotePackId});

  final RemotePackId remotePackId;

  @override
  SharedMutationOperation get operation =>
      SharedMutationOperation.getOrCreateInviteCode;

  @override
  List<Object?> get equalityFields => [remotePackId];
}

final class RotateInviteCommand extends SharedMutationCommand {
  const RotateInviteCommand({
    required this.remotePackId,
    required this.confirmed,
  });

  final RemotePackId remotePackId;
  final bool confirmed;

  @override
  SharedMutationOperation get operation =>
      SharedMutationOperation.rotateInviteCode;

  @override
  List<Object?> get equalityFields => [remotePackId, confirmed];
}

final class JoinSharedPackCommand extends SharedMutationCommand {
  const JoinSharedPackCommand({
    required this.userEnteredCode,
    required this.memberDisplayName,
  });

  final String userEnteredCode;
  final MembershipDisplayNameInput memberDisplayName;

  @override
  SharedMutationOperation get operation =>
      SharedMutationOperation.joinSharedPack;

  @override
  List<Object?> get equalityFields => [userEnteredCode, memberDisplayName];
}

final class RefreshSharedPackCommand extends SharedValue {
  const RefreshSharedPackCommand({required this.remotePackId});

  final RemotePackId remotePackId;

  @override
  List<Object?> get equalityFields => [remotePackId];
}

final class ReplayUnresolvedMutationCommand extends SharedValue {
  ReplayUnresolvedMutationCommand({
    required this.operation,
    required this.clientRequestId,
    required this.reconstructedSemanticCommand,
  }) {
    if (operation != reconstructedSemanticCommand.operation) {
      throw ArgumentError('Replay operation must match reconstructed command');
    }
  }

  final SharedMutationOperation operation;
  final ClientRequestId clientRequestId;
  final SharedMutationCommand reconstructedSemanticCommand;

  @override
  List<Object?> get equalityFields => [
    operation,
    clientRequestId,
    reconstructedSemanticCommand,
  ];
}
