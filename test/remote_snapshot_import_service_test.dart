import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reminder_app/features/reminders/data/identity_repository.dart';
import 'package:reminder_app/features/reminders/data/item_repository.dart';
import 'package:reminder_app/features/reminders/data/local/app_database.dart';
import 'package:reminder_app/features/reminders/data/remote_shared_pack_models.dart';
import 'package:reminder_app/features/reminders/data/remote_snapshot_import_service.dart';
import 'package:reminder_app/features/reminders/data/reminder_backup_service.dart';
import 'package:reminder_app/features/reminders/domain/item.dart';
import 'package:reminder_app/features/reminders/domain/item_action_record.dart';
import 'package:reminder_app/features/reminders/domain/remote_sync.dart';
import 'package:reminder_app/features/reminders/domain/shared_pack.dart';

void main() {
  test('imports a joined remote snapshot into a local mirror', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final identity = IdentityRepository(db.reminderDao);
    await identity.linkRemoteIdentity(
      remoteUserId: 'remote-user-current',
      provider: AuthProviderType.supabaseAnonymous,
    );
    final service = RemoteSnapshotImportService(
      dao: db.reminderDao,
      identityRepository: identity,
      clock: () => DateTime(2026, 6, 21, 12),
    );

    final result = await service.importRemotePackSnapshot(
      snapshot: _snapshot(),
      source: RemoteSnapshotImportSource.joinedRemotePack,
    );

    expect(result.status, RemoteSnapshotImportStatus.success);
    expect(result.localPackId, isNotNull);
    final packMetadata = await db.reminderDao
        .getRemotePackSyncMetadataForRemotePack('remote-pack-1');
    expect(packMetadata, isNotNull);
    expect(packMetadata!.syncKind, RemotePackSyncKind.remoteBacked);
    expect(packMetadata.syncState, RemotePackSyncState.synced);

    final packMembers = await db.reminderDao.listPackMembers(
      result.localPackId!,
    );
    expect(packMembers, hasLength(2));
    expect(
      packMembers.map((member) => member.status),
      everyElement(isA<PackMemberStatus>()),
    );

    final itemMapping = await db.reminderDao.getSyncMappingByRemote(
      localEntityType: 'item',
      remoteTable: 'items',
      remoteEntityId: 'remote-item-1',
    );
    expect(itemMapping, isNotNull);
    final itemMetadata = await db.reminderDao
        .getRemoteItemSyncMetadataForRemoteItem('remote-item-1');
    expect(itemMetadata!.syncState, RemoteItemSyncState.synced);

    final completionMetadata = await db.reminderDao
        .getRemoteCompletionSyncMetadataForRemoteCompletion(
          'remote-completion-1',
        );
    expect(completionMetadata, isNotNull);
    expect(
      completionMetadata!.completionState,
      RemoteCompletionState.remoteImported,
    );
    expect(completionMetadata.remoteCompletedByUserId, 'remote-user-other');
    expect(await db.reminderDao.listPendingSyncOutboxEntries(), isEmpty);

    final activity = await db.reminderDao.listActivityEventsForPack(
      result.localPackId!,
    );
    expect(activity, hasLength(1));
    expect(activity.single.metadataJson, contains('remote-activity-1'));
  });

  test('re-importing the same snapshot is idempotent', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final identity = IdentityRepository(db.reminderDao);
    await identity.linkRemoteIdentity(
      remoteUserId: 'remote-user-current',
      provider: AuthProviderType.supabaseAnonymous,
    );
    final service = RemoteSnapshotImportService(
      dao: db.reminderDao,
      identityRepository: identity,
    );

    final first = await service.importRemotePackSnapshot(
      snapshot: _snapshot(),
      source: RemoteSnapshotImportSource.manualDeveloperImport,
    );
    final second = await service.importRemotePackSnapshot(
      snapshot: _snapshot(),
      source: RemoteSnapshotImportSource.manualDeveloperImport,
    );

    expect(second.status, RemoteSnapshotImportStatus.updatedExistingMirror);
    expect(second.localPackId, first.localPackId);
    final mirrorPacks = (await db.select(db.itemPacks).get()).where(
      (pack) => !pack.isSystemDefault,
    );
    expect(mirrorPacks, hasLength(1));
    expect(await db.select(db.items).get(), hasLength(1));
    expect(await db.select(db.itemCompletions).get(), hasLength(1));
    expect(await db.select(db.activityEvents).get(), hasLength(1));
  });

  test(
    'remote-backed imported items are read-only for local done and undo',
    () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);
      final identity = IdentityRepository(db.reminderDao);
      await identity.linkRemoteIdentity(
        remoteUserId: 'remote-user-current',
        provider: AuthProviderType.supabaseAnonymous,
      );
      final service = RemoteSnapshotImportService(
        dao: db.reminderDao,
        identityRepository: identity,
      );
      final importResult = await service.importRemotePackSnapshot(
        snapshot: _snapshot(),
        source: RemoteSnapshotImportSource.manualDeveloperImport,
      );
      final itemMapping = await db.reminderDao.getSyncMappingByRemote(
        localEntityType: 'item',
        remoteTable: 'items',
        remoteEntityId: 'remote-item-1',
      );
      final itemRepository = ItemRepository(db.reminderDao);

      expect(
        await itemRepository.markDone(itemMapping!.localEntityId),
        isFalse,
      );

      final doneRecord = (await db.select(db.itemActionRecords).get()).single;
      expect(doneRecord.actionType, ItemActionType.done.name);
      expect(await itemRepository.undoDone(doneRecord.id), isFalse);

      final localItemId = await itemRepository.createItem(
        const ItemInput(
          title: 'Local-only item',
          type: ItemType.stateBased,
          config: StateBasedItemConfig(
            warningAfter: Duration(days: 1),
            dangerAfter: Duration(days: 2),
          ),
        ),
      );
      expect(await itemRepository.markDone(localItemId), isTrue);
      expect(importResult.localPackId, isNotNull);
    },
  );

  test(
    'manual backup excludes imported remote-backed mirror records',
    () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);
      final identity = IdentityRepository(db.reminderDao);
      await identity.linkRemoteIdentity(
        remoteUserId: 'remote-user-current',
        provider: AuthProviderType.supabaseAnonymous,
      );
      final service = RemoteSnapshotImportService(
        dao: db.reminderDao,
        identityRepository: identity,
      );
      await service.importRemotePackSnapshot(
        snapshot: _snapshot(),
        source: RemoteSnapshotImportSource.manualDeveloperImport,
      );

      final exported = await ReminderBackupService(
        db.reminderDao,
      ).exportJsonString(exportedAt: DateTime(2026, 6, 21, 13));
      final json = jsonDecode(exported) as Map<String, Object?>;
      final data = json['data'] as Map<String, Object?>;

      expect(data['packs'], isEmpty);
      expect(data['items'], isEmpty);
      expect(exported, isNot(contains('remote-pack-1')));
      expect(exported, isNot(contains('remote-item-1')));
      expect(exported, isNot(contains('remote-completion-1')));
      expect(exported, isNot(contains('remote-activity-1')));
      expect(exported, isNot(contains('sync_outbox')));
    },
  );
}

RemotePackSnapshot _snapshot() {
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
      RemotePackMemberSnapshot(
        id: 'remote-member-2',
        packId: 'remote-pack-1',
        userId: 'remote-user-other',
        displayName: 'Other',
        role: 'member',
        status: 'active',
        joinedAt: created,
      ),
    ],
    items: [
      RemoteItemSnapshot(
        id: 'remote-item-1',
        packId: 'remote-pack-1',
        title: 'Remote item',
        note: 'Read-only mirror',
        status: 'active',
        assignedToUserId: 'remote-user-other',
        createdByUserId: 'remote-user-current',
        updatedByUserId: 'remote-user-current',
        createdAt: created,
        updatedAt: updated,
      ),
    ],
    completions: [
      RemoteItemCompletionSnapshot(
        id: 'remote-completion-1',
        packId: 'remote-pack-1',
        itemId: 'remote-item-1',
        completedByUserId: 'remote-user-other',
        completedAt: DateTime(2026, 6, 21, 11, 5),
        createdAt: DateTime(2026, 6, 21, 11, 5),
      ),
    ],
    activityEvents: [
      RemoteActivityEventSnapshot(
        id: 'remote-activity-1',
        packId: 'remote-pack-1',
        actorUserId: 'remote-user-other',
        actorDisplayNameSnapshot: 'Other',
        entityType: 'item',
        entityId: 'remote-item-1',
        action: 'completed',
        metadataJson: const {'source': 'test'},
        createdAt: DateTime(2026, 6, 21, 11, 6),
      ),
    ],
  );
}
