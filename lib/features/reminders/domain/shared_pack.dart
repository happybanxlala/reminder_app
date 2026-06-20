enum ItemPackType { personal, shared }

enum PackMemberRole { host, member }

enum PackMemberStatus { active, removed }

enum ResourceEventChangeType { adjust, increment, decrement }

enum LocalUserIdentityKind {
  local,
  anonymousRemote,
  linked,
  placeholder,
  removed,
}

enum AuthProviderType { supabaseAnonymous, apple, google, email }

extension LocalUserIdentityKindStorage on LocalUserIdentityKind {
  String get storageValue {
    return switch (this) {
      LocalUserIdentityKind.local => 'local',
      LocalUserIdentityKind.anonymousRemote => 'anonymous_remote',
      LocalUserIdentityKind.linked => 'linked',
      LocalUserIdentityKind.placeholder => 'placeholder',
      LocalUserIdentityKind.removed => 'removed',
    };
  }

  static LocalUserIdentityKind parse(String value) {
    return switch (value) {
      'anonymous_remote' => LocalUserIdentityKind.anonymousRemote,
      'linked' => LocalUserIdentityKind.linked,
      'placeholder' => LocalUserIdentityKind.placeholder,
      'removed' => LocalUserIdentityKind.removed,
      _ => LocalUserIdentityKind.local,
    };
  }
}

extension AuthProviderTypeStorage on AuthProviderType {
  String get storageValue {
    return switch (this) {
      AuthProviderType.supabaseAnonymous => 'supabase_anonymous',
      AuthProviderType.apple => 'apple',
      AuthProviderType.google => 'google',
      AuthProviderType.email => 'email',
    };
  }

  static AuthProviderType parse(String value) {
    return switch (value) {
      'supabase_anonymous' => AuthProviderType.supabaseAnonymous,
      'apple' => AuthProviderType.apple,
      'google' => AuthProviderType.google,
      'email' => AuthProviderType.email,
      _ => AuthProviderType.supabaseAnonymous,
    };
  }
}

class LocalUser {
  const LocalUser({
    required this.id,
    required this.displayName,
    this.avatarUrl,
    this.identityKind = LocalUserIdentityKind.local,
    this.remoteUserId,
    this.remoteProvider,
    this.isPrimary = false,
    required this.createdAt,
    required this.updatedAt,
    this.linkedAt,
    this.lastSeenAt,
    this.deletedAt,
  });

  final String id;
  final String displayName;
  final String? avatarUrl;
  final LocalUserIdentityKind identityKind;
  final String? remoteUserId;
  final AuthProviderType? remoteProvider;
  final bool isPrimary;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? linkedAt;
  final DateTime? lastSeenAt;
  final DateTime? deletedAt;
}

class AppInstallation {
  const AppInstallation({
    required this.id,
    required this.installationGuid,
    required this.createdAt,
    required this.lastSeenAt,
  });

  final int id;
  final String installationGuid;
  final DateTime createdAt;
  final DateTime lastSeenAt;
}

class PackMember {
  const PackMember({
    required this.packId,
    required this.userId,
    required this.role,
    required this.status,
    required this.joinedAt,
  });

  final int packId;
  final String userId;
  final PackMemberRole role;
  final PackMemberStatus status;
  final DateTime joinedAt;
}

class ItemCompletion {
  const ItemCompletion({
    required this.id,
    required this.itemId,
    required this.packId,
    required this.itemActionRecordId,
    required this.completedByUserId,
    required this.completedAt,
    this.undoneByUserId,
    this.undoneAt,
    this.clientMutationId,
    required this.createdAt,
  });

  final int id;
  final int itemId;
  final int packId;
  final int itemActionRecordId;
  final String completedByUserId;
  final DateTime completedAt;
  final String? undoneByUserId;
  final DateTime? undoneAt;
  final String? clientMutationId;
  final DateTime createdAt;

  bool get isUndone => undoneAt != null;
}

class ResourceEvent {
  const ResourceEvent({
    required this.id,
    required this.resourceId,
    required this.packId,
    required this.actorUserId,
    required this.changeType,
    this.previousValue,
    this.newValue,
    this.deltaValue,
    this.unit,
    required this.createdAt,
    this.metadataJson,
  });

  final int id;
  final int resourceId;
  final int packId;
  final String actorUserId;
  final ResourceEventChangeType changeType;
  final int? previousValue;
  final int? newValue;
  final int? deltaValue;
  final String? unit;
  final DateTime createdAt;
  final String? metadataJson;
}

class StageAcknowledgement {
  const StageAcknowledgement({
    required this.id,
    required this.stageRecordId,
    required this.packId,
    required this.userId,
    required this.acknowledgedAt,
  });

  final int id;
  final int stageRecordId;
  final int packId;
  final String userId;
  final DateTime acknowledgedAt;
}

class ActivityEvent {
  const ActivityEvent({
    required this.id,
    required this.packId,
    required this.actorUserId,
    required this.entityType,
    required this.entityId,
    required this.action,
    this.beforeJson,
    this.afterJson,
    this.metadataJson,
    required this.createdAt,
  });

  final int id;
  final int packId;
  final String actorUserId;
  final String entityType;
  final int entityId;
  final String action;
  final String? beforeJson;
  final String? afterJson;
  final String? metadataJson;
  final DateTime createdAt;
}
