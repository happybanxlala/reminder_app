import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reminder_app/features/reminders/data/identity_repository.dart';
import 'package:reminder_app/features/reminders/data/item_repository.dart';
import 'package:reminder_app/features/reminders/data/local/app_database.dart';
import 'package:reminder_app/features/reminders/data/remote_backed_pack_refresh_service.dart';
import 'package:reminder_app/features/reminders/data/remote_shared_pack_models.dart';
import 'package:reminder_app/features/reminders/data/remote_snapshot_import_service.dart';
import 'package:reminder_app/features/reminders/domain/item_pack.dart';
import 'package:reminder_app/features/reminders/domain/remote_backed_pack_refresh.dart';
import 'package:reminder_app/features/reminders/domain/remote_pack_freshness.dart';
import 'package:reminder_app/features/reminders/domain/remote_sync.dart';
import 'package:reminder_app/features/reminders/domain/shared_pack.dart';

void main() {
  test(
    'refresh remote-backed pack pulls snapshot and imports mirror',
    () async {
      final env = await _RefreshEnv.create();
      addTearDown(env.close);
      final importResult = await env.importSnapshot();
      var pullCount = 0;
      final service = env.service(
        pullRemotePackSnapshot: (remotePackId) async {
          pullCount += 1;
          return RemotePocResult.success(
            _snapshot(title: 'Updated remote item'),
          );
        },
      );

      final result = await service.refreshPack(importResult.localPackId!);

      expect(result.status, RemoteBackedPackRefreshStatus.refreshed);
      expect(result.summary.updatedItemCount, 1);
      expect(pullCount, 1);
      final metadata = await env.db.reminderDao
          .getRemotePackSyncMetadataForLocalPack(importResult.localPackId!);
      expect(metadata!.syncState, RemotePackSyncState.synced);
      expect(metadata.lastSyncError, isNull);
      final item = (await env.db.select(env.db.items).get()).single;
      expect(item.title, 'Updated remote item');
    },
  );

  test('local-only pack returns notRemoteBacked', () async {
    final env = await _RefreshEnv.create();
    addTearDown(env.close);
    final localPackId = await ItemRepository(
      env.db.reminderDao,
    ).createPack(const ItemPackInput(title: 'Local pack'));

    final result = await env.service().refreshPack(localPackId);

    expect(result.status, RemoteBackedPackRefreshStatus.notRemoteBacked);
    expect(env.pullCount, 0);
  });

  test(
    'remote-backed pack with blank mapping returns missingRemoteMapping',
    () async {
      final env = await _RefreshEnv.create();
      addTearDown(env.close);
      final localPackId = await ItemRepository(
        env.db.reminderDao,
      ).createPack(const ItemPackInput(title: 'Broken remote pack'));
      final now = DateTime(2026, 6, 21).millisecondsSinceEpoch;
      await env.db.reminderDao.insertRemotePackSyncMetadata(
        RemotePackSyncMetadataCompanion.insert(
          localPackId: localPackId,
          remotePackId: '',
          syncKind: RemotePackSyncKind.remoteBacked.storageValue,
          syncState: RemotePackSyncState.stale.storageValue,
          createdAt: now,
          updatedAt: now,
        ),
      );

      final result = await env.service().refreshPack(localPackId);

      expect(result.status, RemoteBackedPackRefreshStatus.missingRemoteMapping);
      expect(env.pullCount, 0);
    },
  );

  test('pull failures map to typed statuses and sanitized metadata', () async {
    final env = await _RefreshEnv.create();
    addTearDown(env.close);
    final importResult = await env.importSnapshot();
    final service = env.service(
      pullRemotePackSnapshot: (_) async => const RemotePocResult.failure(
        RemoteSharedPackFailureReason.remoteNetworkFailed,
        'raw remote uuid 00000000-0000-0000-0000-000000000000',
      ),
    );

    final result = await service.refreshPack(importResult.localPackId!);

    expect(result.status, RemoteBackedPackRefreshStatus.networkFailed);
    final metadata = await env.db.reminderDao
        .getRemotePackSyncMetadataForLocalPack(importResult.localPackId!);
    expect(metadata!.lastSyncError, 'networkFailed');
    expect(metadata.lastSyncError, isNot(contains('00000000')));
  });

  test('partial import marks pack stale and returns partialImport', () async {
    final env = await _RefreshEnv.create();
    addTearDown(env.close);
    final importResult = await env.importSnapshot();
    final service = env.service(
      importRemotePackSnapshot: ({required snapshot, required source}) async {
        return RemoteSnapshotImportResult(
          status: RemoteSnapshotImportStatus.partialImport,
          remotePackId: snapshot.id,
          localPackId: importResult.localPackId,
          itemsUpdated: 1,
          skipped: 1,
          warnings: const ['Skipped activity remote-secret-id'],
        );
      },
    );

    final result = await service.refreshPack(importResult.localPackId!);

    expect(result.status, RemoteBackedPackRefreshStatus.partialImport);
    expect(result.summary.staleAfterRefresh, isTrue);
    final metadata = await env.db.reminderDao
        .getRemotePackSyncMetadataForLocalPack(importResult.localPackId!);
    expect(metadata!.syncState, RemotePackSyncState.stale);
  });

  test('pending outbox is preserved and not retried or flushed', () async {
    final env = await _RefreshEnv.create();
    addTearDown(env.close);
    final importResult = await env.importSnapshot();
    final itemMetadata = await env.db.reminderDao
        .getRemoteItemSyncMetadataForRemoteItem('remote-item-1');
    await env.insertOutbox(
      localPackId: importResult.localPackId!,
      localItemId: itemMetadata!.localItemId,
      status: SyncOutboxStatus.pending,
    );

    final result = await env.service().refreshPack(importResult.localPackId!);

    expect(
      result.status,
      RemoteBackedPackRefreshStatus.hasPendingLocalMutations,
    );
    expect(result.summary.pendingMutationCount, 1);
    expect(result.summary.warnings, contains('尚有等待同步的本機操作'));
    final outbox = await env.db.reminderDao.listSyncOutboxEntries();
    expect(outbox.single.status, SyncOutboxStatus.pending);
    expect(outbox.single.retryCount, 0);
    final metadata = await env.db.reminderDao
        .getRemotePackSyncMetadataForLocalPack(importResult.localPackId!);
    expect(metadata!.syncState, RemotePackSyncState.stale);
    final refreshedItemMetadata = await env.db.reminderDao
        .getRemoteItemSyncMetadataForLocalItem(itemMetadata.localItemId);
    expect(refreshedItemMetadata!.syncState, RemoteItemSyncState.stale);
  });

  test('successful refresh reports imported snapshot watermark', () async {
    final env = await _RefreshEnv.create();
    addTearDown(env.close);
    final importResult = await env.importSnapshot();
    final reports = <String, String?>{};
    final service = env.service(
      pullRemotePackSnapshot: (_) async => RemotePocResult.success(
        _snapshot(
          activityEvents: [
            RemoteActivityEventSnapshot(
              id: 'event-old',
              packId: 'remote-pack-1',
              entityType: 'pack',
              entityId: 'remote-pack-1',
              action: 'pack_created',
              createdAt: DateTime(2026, 6, 21, 10),
            ),
            RemoteActivityEventSnapshot(
              id: 'event-new',
              packId: 'remote-pack-1',
              entityType: 'item',
              entityId: 'remote-item-1',
              action: 'item_updated',
              createdAt: DateTime(2026, 6, 21, 11),
            ),
          ],
        ),
      ),
      reportPackSnapshotImported:
          ({
            required remotePackId,
            latestActivityEventId,
            latestActivityAt,
          }) async {
            reports[remotePackId] = latestActivityEventId;
            return const RemotePackSnapshotReportResult(
              status: RemotePackSnapshotReportStatus.reported,
            );
          },
    );

    final result = await service.refreshPack(importResult.localPackId!);

    expect(result.status, RemoteBackedPackRefreshStatus.refreshed);
    expect(reports, {'remote-pack-1': 'event-new'});
    expect(result.summary.warnings, isNot(contains('本機已更新，但未能回報同步狀態')));
  });

  test('freshness report failure warns without failing refresh', () async {
    final env = await _RefreshEnv.create();
    addTearDown(env.close);
    final importResult = await env.importSnapshot();
    final service = env.service(
      reportPackSnapshotImported:
          ({
            required remotePackId,
            latestActivityEventId,
            latestActivityAt,
          }) async {
            return const RemotePackSnapshotReportResult(
              status: RemotePackSnapshotReportStatus.accessDenied,
            );
          },
    );

    final result = await service.refreshPack(importResult.localPackId!);

    expect(result.status, RemoteBackedPackRefreshStatus.refreshed);
    expect(result.summary.warnings, contains('本機已更新，但未能回報同步狀態'));
  });

  test('access-lost metadata fails closed on RLS rejection', () async {
    final env = await _RefreshEnv.create();
    addTearDown(env.close);
    final importResult = await env.importSnapshot();
    final metadata = await env.db.reminderDao
        .getRemotePackSyncMetadataForLocalPack(importResult.localPackId!);
    await env.db.reminderDao.updateRemotePackSyncMetadata(
      metadata!.id,
      RemotePackSyncMetadataCompanion(
        syncState: Value(RemotePackSyncState.accessLost.storageValue),
      ),
    );
    final service = env.service(
      pullRemotePackSnapshot: (_) async => const RemotePocResult.failure(
        RemoteSharedPackFailureReason.remoteRlsRejected,
      ),
    );

    final result = await service.refreshPack(importResult.localPackId!);

    expect(result.status, RemoteBackedPackRefreshStatus.accessLost);
    final refreshed = await env.db.reminderDao
        .getRemotePackSyncMetadataForLocalPack(importResult.localPackId!);
    expect(refreshed!.syncState, RemotePackSyncState.accessLost);
  });
}

class _RefreshEnv {
  _RefreshEnv._({
    required this.db,
    required this.identity,
    required this.importService,
  });

  final AppDatabase db;
  final IdentityRepository identity;
  final RemoteSnapshotImportService importService;
  int pullCount = 0;

  static Future<_RefreshEnv> create() async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    final identity = IdentityRepository(db.reminderDao);
    await identity.linkRemoteIdentity(
      remoteUserId: 'remote-user-current',
      provider: AuthProviderType.supabaseAnonymous,
    );
    return _RefreshEnv._(
      db: db,
      identity: identity,
      importService: RemoteSnapshotImportService(
        dao: db.reminderDao,
        identityRepository: identity,
        clock: () => DateTime(2026, 6, 21, 12),
      ),
    );
  }

  RemoteBackedPackRefreshService service({
    RemotePackSnapshotPuller? pullRemotePackSnapshot,
    RemotePackSnapshotImporter? importRemotePackSnapshot,
    RemotePackSnapshotImportedReporter? reportPackSnapshotImported,
  }) {
    return RemoteBackedPackRefreshService(
      dao: db.reminderDao,
      pullRemotePackSnapshot:
          pullRemotePackSnapshot ??
          (remotePackId) async {
            pullCount += 1;
            return RemotePocResult.success(_snapshot());
          },
      importRemotePackSnapshot:
          importRemotePackSnapshot ?? importService.importRemotePackSnapshot,
      reportPackSnapshotImported: reportPackSnapshotImported,
      clock: () => DateTime(2026, 6, 21, 13),
    );
  }

  Future<RemoteSnapshotImportResult> importSnapshot() {
    return importService.importRemotePackSnapshot(
      snapshot: _snapshot(),
      source: RemoteSnapshotImportSource.manualDeveloperImport,
    );
  }

  Future<void> insertOutbox({
    required int localPackId,
    required int localItemId,
    required SyncOutboxStatus status,
  }) async {
    final user = await identity.getCurrentAppUser();
    final now = DateTime(2026, 6, 21, 12, 30).millisecondsSinceEpoch;
    await db.reminderDao.insertSyncOutbox(
      SyncOutboxCompanion.insert(
        localPackId: localPackId,
        remotePackId: const Value('remote-pack-1'),
        localEntityType: RemoteSnapshotImportService.localEntityCompletion,
        localEntityId: const Value(1),
        remoteEntityId: const Value('remote-item-1'),
        actionType: SyncOutboxActionType.completeItem.storageValue,
        payloadJson: jsonEncode({
          'remotePackId': 'remote-pack-1',
          'remoteItemId': 'remote-item-1',
          'localPackId': localPackId,
          'localItemId': localItemId,
          'localCompletionId': 1,
          'clientMutationId': 'client-mutation-1',
        }),
        clientMutationId: 'client-mutation-1',
        actorLocalUserId: user.id,
        actorRemoteUserId: Value(user.remoteUserId),
        createdAt: now,
        updatedAt: now,
        status: status.storageValue,
      ),
    );
  }

  Future<void> close() => db.close();
}

RemotePackSnapshot _snapshot({
  String title = 'Remote item',
  List<RemoteActivityEventSnapshot> activityEvents = const [],
}) {
  final created = DateTime(2026, 6, 21, 10);
  final updated = DateTime(2026, 6, 21, 11);
  return RemotePackSnapshot(
    id: 'remote-pack-1',
    name: 'Remote house pack',
    description: 'Imported mirror',
    hostUserId: 'remote-user-current',
    status: 'active',
    createdAt: created,
    updatedAt: updated,
    members: [
      RemotePackMemberSnapshot(
        id: 'remote-member-1',
        packId: 'remote-pack-1',
        userId: 'remote-user-current',
        displayName: 'Current',
        role: 'host',
        status: 'active',
        joinedAt: created,
      ),
    ],
    items: [
      RemoteItemSnapshot(
        id: 'remote-item-1',
        packId: 'remote-pack-1',
        title: title,
        note: 'Read-only mirror',
        status: 'active',
        assignedToUserId: 'remote-user-current',
        createdByUserId: 'remote-user-current',
        updatedByUserId: 'remote-user-current',
        createdAt: created,
        updatedAt: updated,
      ),
    ],
    completions: const [],
    activityEvents: activityEvents,
  );
}
