import 'package:drift/drift.dart';

const sharedPackCacheIndexStatements = <String>[
  '''
  CREATE UNIQUE INDEX IF NOT EXISTS shared_pack_cache_remote_pack_id_uq
  ON shared_pack_cache(remote_pack_id)
  ''',
  '''
  CREATE INDEX IF NOT EXISTS shared_pack_cache_trust_state_idx
  ON shared_pack_cache(trust_state)
  ''',
];

const sharedMembershipCacheIndexStatements = <String>[
  '''
  CREATE UNIQUE INDEX IF NOT EXISTS shared_membership_cache_pack_member_uq
  ON shared_membership_cache(remote_pack_id, remote_member_id)
  ''',
  '''
  CREATE UNIQUE INDEX IF NOT EXISTS shared_membership_cache_one_current_per_pack_uq
  ON shared_membership_cache(remote_pack_id)
  WHERE is_current_membership = 1
  ''',
  '''
  CREATE UNIQUE INDEX IF NOT EXISTS shared_membership_cache_one_owner_per_pack_uq
  ON shared_membership_cache(remote_pack_id)
  WHERE role = 'owner'
  ''',
];

const sharedItemCacheIndexStatements = <String>[
  '''
  CREATE UNIQUE INDEX IF NOT EXISTS shared_item_cache_pack_item_uq
  ON shared_item_cache(remote_pack_id, remote_item_id)
  ''',
];

const sharedPendingMutationIndexStatements = <String>[
  '''
  CREATE UNIQUE INDEX IF NOT EXISTS shared_pending_mutation_operation_request_uq
  ON shared_pending_mutation(operation_name, client_request_id)
  ''',
];

@DataClassName('SharedPackCacheRow')
class SharedPackCache extends Table {
  @override
  String get tableName => 'shared_pack_cache';

  IntColumn get localId => integer().autoIncrement()();
  TextColumn get remotePackId => text()();
  TextColumn get title => text()();
  TextColumn get description => text().nullable()();
  TextColumn get iconEmoji => text()();
  IntColumn get remotePackVersion => integer()();
  IntColumn get remoteSnapshotSchemaVersion => integer()();
  TextColumn get snapshotFingerprint => text()();
  TextColumn get trustState => text()();
  TextColumn get trustFailureReason => text().nullable()();
  IntColumn get lastVerifiedAt => integer()();
  IntColumn get remoteCreatedAt => integer()();
  IntColumn get remoteUpdatedAt => integer()();

  @override
  List<String> get customConstraints => const [
    'CHECK (length(remote_pack_id) BETWEEN 1 AND 128)',
    'CHECK (length(icon_emoji) >= 1)',
    'CHECK (remote_pack_version BETWEEN 1 AND 9223372036854775807)',
    'CHECK (remote_snapshot_schema_version = 1)',
    'CHECK (length(snapshot_fingerprint) BETWEEN 32 AND 128 '
        'AND length(snapshot_fingerprint) % 2 = 0 '
        "AND snapshot_fingerprint NOT GLOB '*[^0-9a-f]*')",
    "CHECK (trust_state IN ('verified', 'needsRevalidation', 'inaccessible'))",
    'CHECK (trust_failure_reason IS NULL '
        'OR length(trust_failure_reason) BETWEEN 1 AND 64)',
    "CHECK (trust_state <> 'verified' OR trust_failure_reason IS NULL)",
    'CHECK (last_verified_at BETWEEN 0 AND 253402300799999)',
    'CHECK (remote_created_at BETWEEN 0 AND 253402300799999)',
    'CHECK (remote_updated_at BETWEEN 0 AND 253402300799999)',
  ];
}

@DataClassName('SharedMembershipCacheRow')
class SharedMembershipCache extends Table {
  @override
  String get tableName => 'shared_membership_cache';

  IntColumn get localId => integer().autoIncrement()();
  TextColumn get remoteMemberId => text()();
  TextColumn get remotePackId => text()();
  TextColumn get role => text()();
  TextColumn get displayName => text()();
  IntColumn get joinedAt => integer()();
  BoolColumn get isCurrentMembership =>
      boolean().withDefault(const Constant(false))();

  @override
  List<String> get customConstraints => const [
    'CHECK (length(remote_member_id) BETWEEN 1 AND 128)',
    'CHECK (length(remote_pack_id) BETWEEN 1 AND 128)',
    "CHECK (role IN ('owner', 'member'))",
    "CHECK (length(display_name) BETWEEN 1 AND 40 AND trim(display_name, ' ') <> '')",
    'CHECK (joined_at BETWEEN 0 AND 253402300799999)',
    'CHECK (is_current_membership IN (0, 1))',
    'FOREIGN KEY (remote_pack_id) REFERENCES '
        'shared_pack_cache(remote_pack_id) ON DELETE CASCADE',
  ];
}

@DataClassName('SharedItemCacheRow')
class SharedItemCache extends Table {
  @override
  String get tableName => 'shared_item_cache';

  IntColumn get localId => integer().autoIncrement()();
  TextColumn get remoteItemId => text()();
  TextColumn get remotePackId => text()();
  TextColumn get title => text()();
  TextColumn get description => text().nullable()();
  TextColumn get type => text().withDefault(const Constant('stateBased'))();
  TextColumn get lifecycleStatus =>
      text().withDefault(const Constant('active'))();
  IntColumn get stateAnchorDate => integer()();
  IntColumn get infoAfterMinutes => integer()();
  IntColumn get warningAfterMinutes => integer()();
  IntColumn get dangerAfterMinutes => integer()();
  IntColumn get completedAt => integer().nullable()();
  TextColumn get completedByMemberId => text().nullable()();
  IntColumn get remoteItemVersion => integer()();
  IntColumn get remoteCreatedAt => integer()();
  IntColumn get remoteUpdatedAt => integer()();

  @override
  List<String> get customConstraints => const [
    'CHECK (length(remote_item_id) BETWEEN 1 AND 128)',
    'CHECK (length(remote_pack_id) BETWEEN 1 AND 128)',
    "CHECK (type = 'stateBased')",
    "CHECK (lifecycle_status = 'active')",
    'CHECK (state_anchor_date BETWEEN 0 AND 253402300799999)',
    'CHECK (0 <= info_after_minutes '
        'AND info_after_minutes <= warning_after_minutes '
        'AND warning_after_minutes <= danger_after_minutes '
        'AND danger_after_minutes <= 5258880)',
    'CHECK (completed_at IS NULL '
        'OR completed_at BETWEEN 0 AND 253402300799999)',
    'CHECK (completed_by_member_id IS NULL '
        'OR length(completed_by_member_id) BETWEEN 1 AND 128)',
    'CHECK ((completed_at IS NULL AND completed_by_member_id IS NULL) '
        'OR (completed_at IS NOT NULL AND completed_by_member_id IS NOT NULL))',
    'CHECK (remote_item_version BETWEEN 1 AND 9223372036854775807)',
    'CHECK (remote_created_at BETWEEN 0 AND 253402300799999)',
    'CHECK (remote_updated_at BETWEEN 0 AND 253402300799999)',
    'FOREIGN KEY (remote_pack_id) REFERENCES '
        'shared_pack_cache(remote_pack_id) ON DELETE CASCADE',
    'FOREIGN KEY (remote_pack_id, completed_by_member_id) REFERENCES '
        'shared_membership_cache(remote_pack_id, remote_member_id) '
        'ON DELETE RESTRICT',
  ];
}

@DataClassName('SharedPendingMutationRow')
class SharedPendingMutation extends Table {
  @override
  String get tableName => 'shared_pending_mutation';

  IntColumn get localId => integer().autoIncrement()();
  TextColumn get operationName => text()();
  TextColumn get clientRequestId => text()();
  TextColumn get targetRemotePackId => text().nullable()();
  TextColumn get payloadFingerprint => text()();
  IntColumn get createdAt => integer()();
  TextColumn get status =>
      text().withDefault(const Constant('awaitingResolution'))();

  @override
  List<String> get customConstraints => const [
    "CHECK (operation_name IN ('createSharedPack', "
        "'updateSharedPackMetadata', 'createSharedItem', 'updateSharedItem', "
        "'archiveSharedItem', 'getOrCreateInviteCode', 'rotateInviteCode', "
        "'joinSharedPack', 'completeSharedItem'))",
    'CHECK (length(client_request_id) BETWEEN 1 AND 128)',
    'CHECK (target_remote_pack_id IS NULL '
        'OR length(target_remote_pack_id) BETWEEN 1 AND 128)',
    'CHECK (length(payload_fingerprint) BETWEEN 32 AND 128 '
        'AND length(payload_fingerprint) % 2 = 0 '
        "AND payload_fingerprint NOT GLOB '*[^0-9a-f]*')",
    'CHECK (created_at BETWEEN 0 AND 253402300799999)',
    "CHECK (status = 'awaitingResolution')",
  ];
}
