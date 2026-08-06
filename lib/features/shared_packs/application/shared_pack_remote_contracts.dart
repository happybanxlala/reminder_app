import '../domain/shared_equality.dart';
import '../domain/shared_pack_errors.dart';
import '../domain/shared_pack_ids.dart';
import '../domain/shared_pack_models.dart';
import '../domain/shared_pack_runtime_values.dart';
import 'shared_pack_commands.dart';
import 'shared_pack_outcomes.dart';
import 'shared_pack_read_models.dart';

abstract class SharedRemoteRequest extends SharedValue {
  const SharedRemoteRequest({required this.apiContractVersion});

  final RemoteApiContractVersion apiContractVersion;
}

abstract class SharedSnapshotRemoteRequest extends SharedRemoteRequest {
  const SharedSnapshotRemoteRequest({
    required super.apiContractVersion,
    required this.supportedSnapshotSchemaVersion,
  });

  final RemoteSnapshotSchemaVersion supportedSnapshotSchemaVersion;
}

final class CreatePackRemoteRequest extends SharedSnapshotRemoteRequest {
  const CreatePackRemoteRequest({
    required super.apiContractVersion,
    required super.supportedSnapshotSchemaVersion,
    required this.clientRequestId,
    required this.metadata,
    required this.ownerDisplayName,
  });

  final ClientRequestId clientRequestId;
  final SharedPackMetadataDraft metadata;
  final MembershipDisplayNameInput ownerDisplayName;

  @override
  List<Object?> get equalityFields => [
    apiContractVersion,
    supportedSnapshotSchemaVersion,
    clientRequestId,
    metadata,
    ownerDisplayName,
  ];
}

final class UpdatePackRemoteRequest extends SharedSnapshotRemoteRequest {
  const UpdatePackRemoteRequest({
    required super.apiContractVersion,
    required super.supportedSnapshotSchemaVersion,
    required this.clientRequestId,
    required this.remotePackId,
    required this.expectedPackVersion,
    required this.metadata,
  });

  final ClientRequestId clientRequestId;
  final RemotePackId remotePackId;
  final RemotePackVersion expectedPackVersion;
  final SharedPackMetadataDraft metadata;

  @override
  List<Object?> get equalityFields => [
    apiContractVersion,
    supportedSnapshotSchemaVersion,
    clientRequestId,
    remotePackId,
    expectedPackVersion,
    metadata,
  ];
}

final class CreateItemRemoteRequest extends SharedSnapshotRemoteRequest {
  const CreateItemRemoteRequest({
    required super.apiContractVersion,
    required super.supportedSnapshotSchemaVersion,
    required this.clientRequestId,
    required this.remotePackId,
    required this.expectedPackVersion,
    required this.definition,
    required this.initialStateAnchorUtc,
  });

  final ClientRequestId clientRequestId;
  final RemotePackId remotePackId;
  final RemotePackVersion expectedPackVersion;
  final SharedItemDefinitionDraft definition;
  final UtcInstant initialStateAnchorUtc;

  @override
  List<Object?> get equalityFields => [
    apiContractVersion,
    supportedSnapshotSchemaVersion,
    clientRequestId,
    remotePackId,
    expectedPackVersion,
    definition,
    initialStateAnchorUtc,
  ];
}

final class UpdateItemRemoteRequest extends SharedSnapshotRemoteRequest {
  const UpdateItemRemoteRequest({
    required super.apiContractVersion,
    required super.supportedSnapshotSchemaVersion,
    required this.clientRequestId,
    required this.remotePackId,
    required this.remoteItemId,
    required this.expectedItemVersion,
    required this.definition,
  });

  final ClientRequestId clientRequestId;
  final RemotePackId remotePackId;
  final RemoteItemId remoteItemId;
  final RemoteItemVersion expectedItemVersion;
  final SharedItemDefinitionDraft definition;

  @override
  List<Object?> get equalityFields => [
    apiContractVersion,
    supportedSnapshotSchemaVersion,
    clientRequestId,
    remotePackId,
    remoteItemId,
    expectedItemVersion,
    definition,
  ];
}

final class ArchiveItemRemoteRequest extends SharedSnapshotRemoteRequest {
  const ArchiveItemRemoteRequest({
    required super.apiContractVersion,
    required super.supportedSnapshotSchemaVersion,
    required this.clientRequestId,
    required this.remotePackId,
    required this.remoteItemId,
    required this.expectedItemVersion,
  });

  final ClientRequestId clientRequestId;
  final RemotePackId remotePackId;
  final RemoteItemId remoteItemId;
  final RemoteItemVersion expectedItemVersion;

  @override
  List<Object?> get equalityFields => [
    apiContractVersion,
    supportedSnapshotSchemaVersion,
    clientRequestId,
    remotePackId,
    remoteItemId,
    expectedItemVersion,
  ];
}

final class CompleteItemRemoteRequest extends SharedSnapshotRemoteRequest {
  const CompleteItemRemoteRequest({
    required super.apiContractVersion,
    required super.supportedSnapshotSchemaVersion,
    required this.clientRequestId,
    required this.remotePackId,
    required this.remoteItemId,
    required this.expectedItemVersion,
    this.clientOccurredAt,
  });

  final ClientRequestId clientRequestId;
  final RemotePackId remotePackId;
  final RemoteItemId remoteItemId;
  final RemoteItemVersion expectedItemVersion;
  final UtcInstant? clientOccurredAt;

  @override
  List<Object?> get equalityFields => [
    apiContractVersion,
    supportedSnapshotSchemaVersion,
    clientRequestId,
    remotePackId,
    remoteItemId,
    expectedItemVersion,
    clientOccurredAt,
  ];
}

final class GetInviteRemoteRequest extends SharedRemoteRequest {
  const GetInviteRemoteRequest({
    required super.apiContractVersion,
    required this.clientRequestId,
    required this.remotePackId,
  });

  final ClientRequestId clientRequestId;
  final RemotePackId remotePackId;

  @override
  List<Object?> get equalityFields => [
    apiContractVersion,
    clientRequestId,
    remotePackId,
  ];
}

final class RotateInviteRemoteRequest extends SharedRemoteRequest {
  const RotateInviteRemoteRequest({
    required super.apiContractVersion,
    required this.clientRequestId,
    required this.remotePackId,
  });

  final ClientRequestId clientRequestId;
  final RemotePackId remotePackId;

  @override
  List<Object?> get equalityFields => [
    apiContractVersion,
    clientRequestId,
    remotePackId,
  ];
}

final class PreviewInviteRemoteRequest extends SharedRemoteRequest {
  const PreviewInviteRemoteRequest({
    required super.apiContractVersion,
    required this.userEnteredCode,
  });

  final String userEnteredCode;

  @override
  List<Object?> get equalityFields => [apiContractVersion, userEnteredCode];
}

final class JoinRemoteRequest extends SharedSnapshotRemoteRequest {
  const JoinRemoteRequest({
    required super.apiContractVersion,
    required super.supportedSnapshotSchemaVersion,
    required this.clientRequestId,
    required this.userEnteredCode,
    required this.memberDisplayName,
  });

  final ClientRequestId clientRequestId;
  final String userEnteredCode;
  final MembershipDisplayNameInput memberDisplayName;

  @override
  List<Object?> get equalityFields => [
    apiContractVersion,
    supportedSnapshotSchemaVersion,
    clientRequestId,
    userEnteredCode,
    memberDisplayName,
  ];
}

final class GetSnapshotRemoteRequest extends SharedSnapshotRemoteRequest {
  const GetSnapshotRemoteRequest({
    required super.apiContractVersion,
    required super.supportedSnapshotSchemaVersion,
    required this.remotePackId,
    this.knownPackVersion,
  });

  final RemotePackId remotePackId;
  final RemotePackVersion? knownPackVersion;

  @override
  List<Object?> get equalityFields => [
    apiContractVersion,
    supportedSnapshotSchemaVersion,
    remotePackId,
    knownPackVersion,
  ];
}

sealed class SharedSnapshotMutationResult extends SharedValue {
  const SharedSnapshotMutationResult();
}

final class PackMetadataMutationResult extends SharedSnapshotMutationResult {
  const PackMetadataMutationResult(this.metadata);

  final SharedPackMetadata metadata;

  @override
  List<Object?> get equalityFields => [metadata];
}

final class ItemMutationResult extends SharedSnapshotMutationResult {
  const ItemMutationResult(this.item);

  final SharedStateBasedItem item;

  @override
  List<Object?> get equalityFields => [item];
}

final class ArchivedItemMutationResult extends SharedSnapshotMutationResult {
  const ArchivedItemMutationResult({
    required this.remoteItemId,
    required this.resultingItemVersion,
  });

  final RemoteItemId remoteItemId;
  final RemoteItemVersion resultingItemVersion;

  @override
  List<Object?> get equalityFields => [remoteItemId, resultingItemVersion];
}

final class CompletedItemMutationResult extends SharedSnapshotMutationResult {
  const CompletedItemMutationResult({
    required this.item,
    required this.completedByMemberId,
    required this.completedAt,
  });

  final SharedStateBasedItem item;
  final RemoteMemberId completedByMemberId;
  final UtcInstant completedAt;

  @override
  List<Object?> get equalityFields => [item, completedByMemberId, completedAt];
}

final class CreatePackRemoteSuccess extends SharedValue {
  const CreatePackRemoteSuccess({
    required this.remotePackId,
    required this.ownerMembership,
    required this.authoritativePack,
    required this.resultingPackVersion,
    required this.fullSnapshot,
  });

  final RemotePackId remotePackId;
  final SharedMember ownerMembership;
  final SharedPackMetadata authoritativePack;
  final RemotePackVersion resultingPackVersion;
  final SharedPackSnapshot fullSnapshot;

  @override
  List<Object?> get equalityFields => [
    remotePackId,
    ownerMembership,
    authoritativePack,
    resultingPackVersion,
    fullSnapshot,
  ];
}

final class SnapshotMutationRemoteSuccess extends SharedValue {
  const SnapshotMutationRemoteSuccess({
    required this.result,
    this.resultingItemVersion,
    required this.resultingPackVersion,
    required this.fullSnapshot,
  });

  final SharedSnapshotMutationResult result;
  final RemoteItemVersion? resultingItemVersion;
  final RemotePackVersion resultingPackVersion;
  final SharedPackSnapshot fullSnapshot;

  @override
  List<Object?> get equalityFields => [
    result,
    resultingItemVersion,
    resultingPackVersion,
    fullSnapshot,
  ];
}

final class InviteCodeRemoteSuccess extends SharedValue {
  const InviteCodeRemoteSuccess({
    required this.normalizedInviteCode,
    required this.displayInviteCode,
  });

  final String normalizedInviteCode;
  final String displayInviteCode;

  @override
  List<Object?> get equalityFields => [normalizedInviteCode, displayInviteCode];
}

final class InvitePreviewRemoteSuccess extends SharedValue {
  const InvitePreviewRemoteSuccess(this.preview);

  final InvitePreview preview;

  @override
  List<Object?> get equalityFields => [preview];
}

final class JoinRemoteSuccess extends SharedValue {
  const JoinRemoteSuccess({
    required this.membership,
    required this.resultingPackVersion,
    required this.fullSnapshot,
  });

  final SharedMember membership;
  final RemotePackVersion resultingPackVersion;
  final SharedPackSnapshot fullSnapshot;

  @override
  List<Object?> get equalityFields => [
    membership,
    resultingPackVersion,
    fullSnapshot,
  ];
}

sealed class SnapshotReadRemoteSuccess extends SharedValue {
  const SnapshotReadRemoteSuccess();
}

final class FullSnapshotRemoteSuccess extends SnapshotReadRemoteSuccess {
  const FullSnapshotRemoteSuccess(this.fullSnapshot);

  final SharedPackSnapshot fullSnapshot;

  @override
  List<Object?> get equalityFields => [fullSnapshot];
}

final class NotModifiedRemoteSuccess extends SnapshotReadRemoteSuccess {
  const NotModifiedRemoteSuccess({
    required this.remotePackId,
    required this.packVersion,
    required this.verifiedAt,
  });

  final RemotePackId remotePackId;
  final RemotePackVersion packVersion;
  final UtcInstant verifiedAt;

  @override
  List<Object?> get equalityFields => [remotePackId, packVersion, verifiedAt];
}

enum RemoteErrorTarget { pack, item }

final class SafeRemoteDetails extends SharedValue {
  SafeRemoteDetails({
    this.target,
    List<String> validationFields = const [],
    this.supportedVersion,
  }) : validationFields = List.unmodifiable(validationFields);

  final RemoteErrorTarget? target;
  final List<String> validationFields;
  final int? supportedVersion;

  @override
  List<Object?> get equalityFields => [
    target,
    validationFields,
    supportedVersion,
  ];
}

enum TransportFailureFamily {
  networkUnavailable,
  timeout,
  connectionInterrupted,
  cancelled,
  other,
}

sealed class RemoteCallResult<T> extends SharedValue {
  const RemoteCallResult();
}

final class RemoteSuccess<T> extends RemoteCallResult<T> {
  const RemoteSuccess(this.value, {required this.replayed});

  final T value;
  final bool replayed;

  @override
  List<Object?> get equalityFields => [value, replayed];
}

final class RemoteRejected<T> extends RemoteCallResult<T> {
  const RemoteRejected(this.code, {this.details, this.retryAfter});

  final RemoteErrorCode code;
  final SafeRemoteDetails? details;
  final Duration? retryAfter;

  @override
  List<Object?> get equalityFields => [code, details, retryAfter];
}

final class RemoteTransportFailure<T> extends RemoteCallResult<T> {
  const RemoteTransportFailure({required this.certainty, required this.family});

  final DispatchCertainty certainty;
  final TransportFailureFamily family;

  @override
  List<Object?> get equalityFields => [certainty, family];
}

final class RemoteDecodeFailure<T> extends RemoteCallResult<T> {
  const RemoteDecodeFailure({required this.certainty});

  final DispatchCertainty certainty;

  @override
  List<Object?> get equalityFields => [certainty];
}

/// Application-owned operation-specific remote port. No generic dispatcher.
abstract interface class SharedPackRemoteApi {
  Future<RemoteCallResult<CreatePackRemoteSuccess>> createSharedPack(
    CreatePackRemoteRequest request,
  );

  Future<RemoteCallResult<SnapshotMutationRemoteSuccess>>
  updateSharedPackMetadata(UpdatePackRemoteRequest request);

  Future<RemoteCallResult<SnapshotMutationRemoteSuccess>> createSharedItem(
    CreateItemRemoteRequest request,
  );

  Future<RemoteCallResult<SnapshotMutationRemoteSuccess>> updateSharedItem(
    UpdateItemRemoteRequest request,
  );

  Future<RemoteCallResult<SnapshotMutationRemoteSuccess>> archiveSharedItem(
    ArchiveItemRemoteRequest request,
  );

  Future<RemoteCallResult<InviteCodeRemoteSuccess>> getOrCreateInviteCode(
    GetInviteRemoteRequest request,
  );

  Future<RemoteCallResult<InviteCodeRemoteSuccess>> rotateInviteCode(
    RotateInviteRemoteRequest request,
  );

  Future<RemoteCallResult<InvitePreviewRemoteSuccess>> previewInviteCode(
    PreviewInviteRemoteRequest request,
  );

  Future<RemoteCallResult<JoinRemoteSuccess>> joinSharedPack(
    JoinRemoteRequest request,
  );

  Future<RemoteCallResult<SnapshotReadRemoteSuccess>> getSharedPackSnapshot(
    GetSnapshotRemoteRequest request,
  );

  Future<RemoteCallResult<SnapshotMutationRemoteSuccess>> completeSharedItem(
    CompleteItemRemoteRequest request,
  );
}
