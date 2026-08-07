import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:reminder_app/features/reminders/data/local/app_database.dart';
import 'package:reminder_app/features/shared_packs/application/shared_pack_ports.dart';
import 'package:reminder_app/features/shared_packs/domain/shared_pack_runtime_values.dart';

const sharedTestFingerprint = '0123456789abcdef0123456789abcdef';
const sharedTestNowEpochMs = 1893553445000; // 2030-01-02T03:04:05Z

final class FixedSharedUtcClock implements SharedUtcClock {
  FixedSharedUtcClock(this.instant);

  final UtcInstant instant;

  @override
  UtcInstant nowUtc() => instant;
}

Future<AppDatabase> openSharedPackTestDatabase() async {
  final database = AppDatabase.forTesting(
    NativeDatabase.memory(
      setup: (sqlite) => sqlite.execute('PRAGMA foreign_keys = ON'),
    ),
  );
  await database.customSelect('SELECT 1').getSingle();
  return database;
}

Future<void> insertProjectedPack(
  AppDatabase database, {
  required String packId,
  String title = 'Shared Pack',
  String? description = 'Projected cache fixture',
  String icon = '🤝',
  int packVersion = 7,
  String trust = 'verified',
  String? reason,
  int lastVerifiedAt = sharedTestNowEpochMs,
}) async {
  await database.sharedPackCacheDao.insertPack(
    SharedPackCacheCompanion.insert(
      remotePackId: packId,
      title: title,
      description: Value(description),
      iconEmoji: icon,
      remotePackVersion: packVersion,
      remoteSnapshotSchemaVersion: 1,
      snapshotFingerprint: sharedTestFingerprint,
      trustState: trust,
      trustFailureReason: Value(reason),
      lastVerifiedAt: lastVerifiedAt,
      remoteCreatedAt: lastVerifiedAt - 1000,
      remoteUpdatedAt: lastVerifiedAt,
    ),
  );
}

Future<void> insertProjectedMembership(
  AppDatabase database, {
  required String packId,
  required String memberId,
  required String role,
  required String displayName,
  bool isCurrent = false,
  int joinedAt = sharedTestNowEpochMs,
}) async {
  await database.sharedPackCacheDao.insertMembership(
    SharedMembershipCacheCompanion.insert(
      remoteMemberId: memberId,
      remotePackId: packId,
      role: role,
      displayName: displayName,
      joinedAt: joinedAt,
      isCurrentMembership: Value(isCurrent),
    ),
  );
}

Future<void> insertProjectedItem(
  AppDatabase database, {
  required String packId,
  required String itemId,
  String title = 'Shared Item',
  String? description = 'State-based fixture',
  int stateAnchorAt = sharedTestNowEpochMs,
  int infoAfterMinutes = 5,
  int warningAfterMinutes = 10,
  int dangerAfterMinutes = 20,
  int? completedAt,
  String? completedBy,
  int itemVersion = 3,
  int createdAt = sharedTestNowEpochMs,
  int updatedAt = sharedTestNowEpochMs,
}) async {
  await database.sharedPackCacheDao.insertItem(
    SharedItemCacheCompanion.insert(
      remoteItemId: itemId,
      remotePackId: packId,
      title: title,
      description: Value(description),
      stateAnchorDate: stateAnchorAt,
      infoAfterMinutes: infoAfterMinutes,
      warningAfterMinutes: warningAfterMinutes,
      dangerAfterMinutes: dangerAfterMinutes,
      completedAt: Value(completedAt),
      completedByMemberId: Value(completedBy),
      remoteItemVersion: itemVersion,
      remoteCreatedAt: createdAt,
      remoteUpdatedAt: updatedAt,
    ),
  );
}

Future<void> insertPendingMarker(
  AppDatabase database, {
  required String operation,
  required String requestId,
  String? targetPackId,
  String fingerprint = sharedTestFingerprint,
  int createdAt = sharedTestNowEpochMs,
}) async {
  await database.sharedPackCacheDao.insertPendingMutation(
    SharedPendingMutationCompanion.insert(
      operationName: operation,
      clientRequestId: requestId,
      targetRemotePackId: Value(targetPackId),
      payloadFingerprint: fingerprint,
      createdAt: createdAt,
    ),
  );
}

Future<void> insertCoherentProjectedPack(
  AppDatabase database, {
  required String packId,
  String title = 'Shared Pack',
  String ownerId = 'owner',
  String ownerName = 'Owner',
  String? currentMemberId,
  String currentMemberName = 'Current Member',
  String trust = 'verified',
  String? reason,
}) {
  return database.transaction(() async {
    await insertProjectedPack(
      database,
      packId: packId,
      title: title,
      trust: trust,
      reason: reason,
    );
    await insertProjectedMembership(
      database,
      packId: packId,
      memberId: ownerId,
      role: 'owner',
      displayName: ownerName,
      isCurrent: currentMemberId == null,
    );
    if (currentMemberId != null) {
      await insertProjectedMembership(
        database,
        packId: packId,
        memberId: currentMemberId,
        role: 'member',
        displayName: currentMemberName,
        isCurrent: true,
      );
    }
  });
}
