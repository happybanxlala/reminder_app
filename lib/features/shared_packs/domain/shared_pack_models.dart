import 'shared_equality.dart';
import 'shared_pack_ids.dart';
import 'shared_pack_runtime_values.dart';

enum SharedRole { owner, member }

enum SharedCacheTrust { verified, needsRevalidation, inaccessible }

enum SharedItemType { stateBased }

enum SharedItemLifecycle { active, archived }

enum SharedItemAttention { normal, warning, danger }

final class SharedPackMetadata extends SharedValue {
  SharedPackMetadata({
    required this.remotePackId,
    required this.title,
    this.description,
    required this.iconEmoji,
    required this.packVersion,
    required this.createdAt,
    required this.updatedAt,
  }) {
    validateSharedTitle(title, 'title');
    validateSharedDescription(description);
    validateSharedIcon(iconEmoji);
  }

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

final class SharedMember extends SharedValue {
  SharedMember({
    required this.remoteMemberId,
    required this.remotePackId,
    required this.role,
    required this.displayName,
    required this.joinedAt,
  }) {
    validateCanonicalDisplayName(displayName);
  }

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

final class SharedItemThresholds extends SharedValue {
  SharedItemThresholds({
    required this.infoAfterMinutes,
    required this.warningAfterMinutes,
    required this.dangerAfterMinutes,
  }) {
    if (infoAfterMinutes < 0 ||
        infoAfterMinutes > warningAfterMinutes ||
        warningAfterMinutes > dangerAfterMinutes ||
        dangerAfterMinutes > sharedMaximumThresholdMinutes) {
      throw ArgumentError('Shared Item thresholds are outside the v1 range');
    }
  }

  final int infoAfterMinutes;
  final int warningAfterMinutes;
  final int dangerAfterMinutes;

  @override
  List<Object?> get equalityFields => [
    infoAfterMinutes,
    warningAfterMinutes,
    dangerAfterMinutes,
  ];
}

final class SharedCompletion extends SharedValue {
  const SharedCompletion({required this.completedAt, required this.actorId});

  final UtcInstant completedAt;
  final RemoteMemberId actorId;

  @override
  List<Object?> get equalityFields => [completedAt, actorId];
}

/// Independent Shared state-based Item; it is not a Personal Item subtype.
final class SharedStateBasedItem extends SharedValue {
  SharedStateBasedItem({
    required this.remoteItemId,
    required this.remotePackId,
    required this.title,
    this.description,
    this.type = SharedItemType.stateBased,
    required this.lifecycle,
    required this.stateAnchorDateUtc,
    required this.thresholds,
    this.completion,
    required this.itemVersion,
    required this.createdAt,
    required this.updatedAt,
  }) {
    validateSharedTitle(title, 'title');
    validateSharedDescription(description);
  }

  final RemoteItemId remoteItemId;
  final RemotePackId remotePackId;
  final String title;
  final String? description;
  final SharedItemType type;
  final SharedItemLifecycle lifecycle;
  final UtcInstant stateAnchorDateUtc;
  final SharedItemThresholds thresholds;
  final SharedCompletion? completion;
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
    lifecycle,
    stateAnchorDateUtc,
    thresholds,
    completion,
    itemVersion,
    createdAt,
    updatedAt,
  ];
}

final class SharedPackSnapshot extends SharedValue {
  SharedPackSnapshot({
    required this.schemaVersion,
    required this.remotePackId,
    required this.packVersion,
    required this.generatedAt,
    required this.pack,
    required this.currentMembership,
    required List<SharedMember> memberships,
    required List<SharedStateBasedItem> items,
  }) : memberships = List.unmodifiable(memberships),
       items = List.unmodifiable(items);

  final RemoteSnapshotSchemaVersion schemaVersion;
  final RemotePackId remotePackId;
  final RemotePackVersion packVersion;
  final UtcInstant generatedAt;
  final SharedPackMetadata pack;
  final SharedMember currentMembership;
  final List<SharedMember> memberships;
  final List<SharedStateBasedItem> items;

  @override
  List<Object?> get equalityFields => [
    schemaVersion,
    remotePackId,
    packVersion,
    generatedAt,
    pack,
    currentMembership,
    memberships,
    items,
  ];
}

void validateSharedTitle(String value, String label) {
  if (value.runes.isEmpty || value.runes.length > 120) {
    throw ArgumentError.value(
      value,
      label,
      'must contain 1–120 Unicode scalars',
    );
  }
}

void validateSharedDescription(String? value) {
  if (value != null && value.runes.length > 2000) {
    throw ArgumentError.value(value, 'description', 'exceeds 2,000 scalars');
  }
}

void validateSharedIcon(String value) {
  if (value.runes.isEmpty || value.runes.length > 16) {
    throw ArgumentError.value(value, 'iconEmoji', 'must contain 1–16 scalars');
  }
}

String canonicalizeDisplayName(String input) {
  final runes = input.runes.toList(growable: false);
  var start = 0;
  var end = runes.length;
  while (start < end && _isLockedWhitespace(runes[start])) {
    start++;
  }
  while (end > start && _isLockedWhitespace(runes[end - 1])) {
    end--;
  }
  return String.fromCharCodes(runes.sublist(start, end));
}

void validateCanonicalDisplayName(String value) {
  if (value != canonicalizeDisplayName(value) ||
      value.runes.isEmpty ||
      value.runes.length > 40) {
    throw ArgumentError.value(
      value,
      'displayName',
      'must be canonical-trimmed and contain 1–40 Unicode scalars',
    );
  }
}

bool _isLockedWhitespace(int rune) =>
    (rune >= 0x0009 && rune <= 0x000d) ||
    rune == 0x0020 ||
    rune == 0x0085 ||
    rune == 0x00a0 ||
    rune == 0x1680 ||
    (rune >= 0x2000 && rune <= 0x200a) ||
    rune == 0x2028 ||
    rune == 0x2029 ||
    rune == 0x202f ||
    rune == 0x205f ||
    rune == 0x3000;
