import '../../domain/shared_equality.dart';
import '../../domain/shared_pack_errors.dart';
import '../../domain/shared_pack_ids.dart';
import '../../domain/shared_pack_models.dart';
import '../../domain/shared_pack_runtime_values.dart';
import '../../application/shared_pack_remote_contracts.dart';

sealed class SharedRemoteEnvelopeDto<T> extends SharedValue {
  const SharedRemoteEnvelopeDto({
    required this.remoteApiContractVersion,
    required this.correlationId,
  });

  final RemoteApiContractVersion remoteApiContractVersion;
  final String correlationId;
}

final class SharedRemoteSuccessEnvelopeDto<T>
    extends SharedRemoteEnvelopeDto<T> {
  const SharedRemoteSuccessEnvelopeDto({
    required super.remoteApiContractVersion,
    required super.correlationId,
    required this.data,
  });

  final T data;

  @override
  List<Object?> get equalityFields => [
    remoteApiContractVersion,
    correlationId,
    data,
  ];
}

enum SharedRemoteFailureSideEffect { none }

final class SharedRemoteErrorEnvelopeDto extends SharedValue {
  const SharedRemoteErrorEnvelopeDto({
    required this.code,
    this.safeDetails,
    this.retryAfter,
    this.sideEffect = SharedRemoteFailureSideEffect.none,
  });

  final RemoteErrorCode code;
  final SafeRemoteDetails? safeDetails;
  final Duration? retryAfter;
  final SharedRemoteFailureSideEffect sideEffect;

  @override
  List<Object?> get equalityFields => [
    code,
    safeDetails,
    retryAfter,
    sideEffect,
  ];
}

final class SharedRemoteFailureEnvelopeDto<T>
    extends SharedRemoteEnvelopeDto<T> {
  const SharedRemoteFailureEnvelopeDto({
    required super.remoteApiContractVersion,
    required super.correlationId,
    required this.error,
  });

  final SharedRemoteErrorEnvelopeDto error;

  @override
  List<Object?> get equalityFields => [
    remoteApiContractVersion,
    correlationId,
    error,
  ];
}

/// Strictly decoded transport DTOs. JSON decoding is intentionally Phase 2d.
final class SharedPackRemoteDto extends SharedValue {
  const SharedPackRemoteDto({
    required this.remotePackId,
    required this.title,
    this.description,
    required this.iconEmoji,
    required this.packVersion,
    required this.createdAt,
    required this.updatedAt,
  });

  final RemotePackId remotePackId;
  final String title;
  final String? description;
  final String iconEmoji;
  final RemotePackVersion packVersion;
  final UtcInstant createdAt;
  final UtcInstant updatedAt;

  @override
  List<Object?> get equalityFields => [
    remotePackId,
    title,
    description,
    iconEmoji,
    packVersion,
    createdAt,
    updatedAt,
  ];
}

final class SharedPackSnapshotMetadataDto extends SharedValue {
  const SharedPackSnapshotMetadataDto({
    required this.remotePackId,
    required this.title,
    this.description,
    required this.iconEmoji,
    required this.createdAt,
    required this.updatedAt,
  });

  final RemotePackId remotePackId;
  final String title;
  final String? description;
  final String iconEmoji;
  final UtcInstant createdAt;
  final UtcInstant updatedAt;

  @override
  List<Object?> get equalityFields => [
    remotePackId,
    title,
    description,
    iconEmoji,
    createdAt,
    updatedAt,
  ];
}

final class SharedMembershipRemoteDto extends SharedValue {
  const SharedMembershipRemoteDto({
    required this.remoteMemberId,
    required this.remotePackId,
    required this.role,
    required this.displayName,
    required this.joinedAt,
  });

  final RemoteMemberId remoteMemberId;
  final RemotePackId remotePackId;
  final SharedRole role;
  final String displayName;
  final UtcInstant joinedAt;

  @override
  List<Object?> get equalityFields => [
    remoteMemberId,
    remotePackId,
    role,
    displayName,
    joinedAt,
  ];
}

final class SharedMembershipSummaryRemoteDto extends SharedValue {
  const SharedMembershipSummaryRemoteDto({
    required this.remoteMemberId,
    required this.displayName,
    required this.role,
    required this.joinedAt,
  });

  final RemoteMemberId remoteMemberId;
  final String displayName;
  final SharedRole role;
  final UtcInstant joinedAt;

  @override
  List<Object?> get equalityFields => [
    remoteMemberId,
    displayName,
    role,
    joinedAt,
  ];
}

final class SharedItemRemoteDto extends SharedValue {
  const SharedItemRemoteDto({
    required this.remoteItemId,
    required this.remotePackId,
    required this.title,
    this.description,
    required this.type,
    required this.lifecycleStatus,
    required this.stateAnchorDate,
    required this.infoAfterMinutes,
    required this.warningAfterMinutes,
    required this.dangerAfterMinutes,
    this.completedAt,
    this.completedByMemberId,
    required this.itemVersion,
    required this.createdAt,
    required this.updatedAt,
  });

  final RemoteItemId remoteItemId;
  final RemotePackId remotePackId;
  final String title;
  final String? description;
  final SharedItemType type;
  final SharedItemLifecycle lifecycleStatus;
  final UtcInstant stateAnchorDate;
  final int infoAfterMinutes;
  final int warningAfterMinutes;
  final int dangerAfterMinutes;
  final UtcInstant? completedAt;
  final RemoteMemberId? completedByMemberId;
  final RemoteItemVersion itemVersion;
  final UtcInstant createdAt;
  final UtcInstant updatedAt;

  @override
  List<Object?> get equalityFields => [
    remoteItemId,
    remotePackId,
    title,
    description,
    type,
    lifecycleStatus,
    stateAnchorDate,
    infoAfterMinutes,
    warningAfterMinutes,
    dangerAfterMinutes,
    completedAt,
    completedByMemberId,
    itemVersion,
    createdAt,
    updatedAt,
  ];
}

final class SharedPackSnapshotDtoV1 extends SharedValue {
  SharedPackSnapshotDtoV1({
    required this.remoteSnapshotSchemaVersion,
    required this.remotePackId,
    required this.packVersion,
    required this.generatedAt,
    required this.pack,
    required this.currentMembership,
    required List<SharedMembershipSummaryRemoteDto> memberships,
    required List<SharedItemRemoteDto> items,
  }) : memberships = List.unmodifiable(memberships),
       items = List.unmodifiable(items);

  final RemoteSnapshotSchemaVersion remoteSnapshotSchemaVersion;
  final RemotePackId remotePackId;
  final RemotePackVersion packVersion;
  final UtcInstant generatedAt;
  final SharedPackSnapshotMetadataDto pack;
  final SharedMembershipRemoteDto currentMembership;
  final List<SharedMembershipSummaryRemoteDto> memberships;
  final List<SharedItemRemoteDto> items;

  @override
  List<Object?> get equalityFields => [
    remoteSnapshotSchemaVersion,
    remotePackId,
    packVersion,
    generatedAt,
    pack,
    currentMembership,
    memberships,
    items,
  ];
}

sealed class SharedSnapshotReadResponseDto extends SharedValue {
  const SharedSnapshotReadResponseDto();
}

final class SharedFullSnapshotResponseDto
    extends SharedSnapshotReadResponseDto {
  const SharedFullSnapshotResponseDto(this.snapshot);

  final SharedPackSnapshotDtoV1 snapshot;

  @override
  List<Object?> get equalityFields => [snapshot];
}

final class SharedNotModifiedResponseDto extends SharedSnapshotReadResponseDto {
  const SharedNotModifiedResponseDto({
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
