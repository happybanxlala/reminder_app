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
import 'package:reminder_app/features/reminders/domain/resource.dart';
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

  test('import updates remote undone completion into local history', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final identity = IdentityRepository(db.reminderDao);
    final currentUser = await identity.linkRemoteIdentity(
      remoteUserId: 'remote-user-current',
      provider: AuthProviderType.supabaseAnonymous,
    );
    final service = RemoteSnapshotImportService(
      dao: db.reminderDao,
      identityRepository: identity,
      clock: () => DateTime(2026, 6, 21, 12),
    );

    final first = await service.importRemotePackSnapshot(
      snapshot: _snapshot(),
      source: RemoteSnapshotImportSource.joinedRemotePack,
    );
    final itemMapping = await db.reminderDao.getSyncMappingByRemote(
      localEntityType: 'item',
      remoteTable: 'items',
      remoteEntityId: 'remote-item-1',
    );
    expect(first.succeeded, isTrue);
    expect(itemMapping, isNotNull);

    final undoneAt = DateTime(2026, 6, 21, 11, 30);
    final second = await service.importRemotePackSnapshot(
      snapshot: _snapshot(
        completions: [
          RemoteItemCompletionSnapshot(
            id: 'remote-completion-1',
            packId: 'remote-pack-1',
            itemId: 'remote-item-1',
            completedByUserId: 'remote-user-other',
            completedAt: DateTime(2026, 6, 21, 11, 5),
            undoneByUserId: 'remote-user-current',
            undoneAt: undoneAt,
            createdAt: DateTime(2026, 6, 21, 11, 5),
          ),
        ],
        activityEvents: [
          RemoteActivityEventSnapshot(
            id: 'remote-activity-undone',
            packId: 'remote-pack-1',
            actorUserId: 'remote-user-current',
            actorDisplayNameSnapshot: 'Current',
            entityType: 'item',
            entityId: 'remote-item-1',
            action: 'item_undone',
            createdAt: undoneAt,
          ),
        ],
      ),
      source: RemoteSnapshotImportSource.localMappedPack,
    );

    expect(second.succeeded, isTrue);
    final completions = await db.reminderDao.listItemCompletions(
      itemMapping!.localEntityId,
    );
    expect(completions.single.undoneByUserId, currentUser.id);
    expect(completions.single.undoneAt, undoneAt);
    final actions = await db.reminderDao.listItemActionRecordsForItem(
      itemMapping.localEntityId,
    );
    final done = actions.singleWhere(
      (record) => record.actionType == ItemActionType.done,
    );
    final reverted = actions.singleWhere(
      (record) => record.actionType == ItemActionType.reverted,
    );
    expect(done.isReverted, isTrue);
    expect(done.revertedAt, undoneAt);
    expect(done.revertedByActionRecordId, reverted.id);
  });

  test('import marks missing active members as removed', () async {
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
      source: RemoteSnapshotImportSource.joinedRemotePack,
    );
    final second = await service.importRemotePackSnapshot(
      snapshot: _snapshot(
        members: [
          RemotePackMemberSnapshot(
            id: 'remote-member-1',
            packId: 'remote-pack-1',
            userId: 'remote-user-current',
            displayName: 'Current',
            role: 'host',
            status: 'active',
            joinedAt: DateTime(2026, 6, 21, 10),
          ),
        ],
      ),
      source: RemoteSnapshotImportSource.localMappedPack,
    );

    expect(first.localPackId, isNotNull);
    expect(second.succeeded, isTrue);
    final members = await db.reminderDao.listPackMembers(first.localPackId!);
    expect(
      members.where((member) => member.status == PackMemberStatus.active),
      hasLength(1),
    );
    expect(
      members.where((member) => member.status == PackMemberStatus.removed),
      hasLength(1),
    );
  });

  test(
    'shared item activity projection is actor-aware and idempotent',
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
      final repository = ItemRepository(db.reminderDao);
      final snapshot = _snapshot(
        activityEvents: [
          RemoteActivityEventSnapshot(
            id: 'remote-activity-created',
            packId: 'remote-pack-1',
            actorUserId: 'remote-user-other',
            actorDisplayNameSnapshot: 'Other',
            entityType: 'item',
            entityId: 'remote-item-1',
            action: 'item_created',
            createdAt: DateTime(2026, 6, 21, 11, 6),
          ),
        ],
      );

      await service.importRemotePackSnapshot(
        snapshot: snapshot,
        source: RemoteSnapshotImportSource.joinedRemotePack,
      );
      await service.importRemotePackSnapshot(
        snapshot: snapshot,
        source: RemoteSnapshotImportSource.localMappedPack,
      );

      final entries = await repository.listSharedItemActivityFeed(
        now: DateTime(2026, 6, 21, 12),
        recentDays: 30,
      );
      expect(entries, hasLength(1));
      expect(entries.single.actorDisplayName, 'Other');
      expect(entries.single.itemTitle, 'Remote item');
      expect(entries.single.event.action, 'item_created');
    },
  );

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

  test('imports remote resources and resource events idempotently', () async {
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
    final snapshot = _snapshot(
      resources: [
        RemoteResourceSnapshot(
          id: 'remote-resource-1',
          packId: 'remote-pack-1',
          title: 'Cat food',
          status: 'active',
          type: ResourceType.quantityBased.name,
          quantityCurrent: 5,
          quantityUnitLabel: '包',
          quantityWarningThreshold: 1,
          quantityDangerThreshold: 0,
          createdByUserId: 'remote-user-current',
          updatedByUserId: 'remote-user-other',
          createdAt: DateTime(2026, 6, 21, 10),
          updatedAt: DateTime(2026, 6, 21, 11),
        ),
      ],
      resourceEvents: [
        RemoteResourceEventSnapshot(
          id: 'remote-resource-event-1',
          packId: 'remote-pack-1',
          resourceId: 'remote-resource-1',
          actorUserId: 'remote-user-other',
          changeType: ResourceEventChangeType.increment.name,
          previousValue: 3,
          newValue: 5,
          deltaValue: 2,
          unit: '包',
          metadataJson: const {'resource_action': 'refilled'},
          createdAt: DateTime(2026, 6, 21, 11, 10),
        ),
      ],
      activityEvents: [
        RemoteActivityEventSnapshot(
          id: 'remote-resource-activity-1',
          packId: 'remote-pack-1',
          actorUserId: 'remote-user-other',
          actorDisplayNameSnapshot: 'Other',
          entityType: 'resource',
          entityId: 'remote-resource-1',
          action: 'resource_incremented',
          createdAt: DateTime(2026, 6, 21, 11, 11),
        ),
      ],
    );

    await service.importRemotePackSnapshot(
      snapshot: snapshot,
      source: RemoteSnapshotImportSource.manualDeveloperImport,
    );
    await service.importRemotePackSnapshot(
      snapshot: snapshot,
      source: RemoteSnapshotImportSource.manualDeveloperImport,
    );

    final mapping = await db.reminderDao.getSyncMappingByRemote(
      localEntityType: 'resource',
      remoteTable: 'resources',
      remoteEntityId: 'remote-resource-1',
    );
    expect(mapping, isNotNull);
    final bundle = await db.reminderDao.getResourceBundleById(
      mapping!.localEntityId,
    );
    expect(bundle!.resource.title, 'Cat food');
    expect(
      (bundle.resource.config as QuantityBasedResourceConfig).currentQuantity,
      5,
    );
    final events = await db.reminderDao.listResourceEventsForResource(
      mapping.localEntityId,
    );
    expect(events, hasLength(1));
    expect(events.single.deltaValue, 2);
    final actions = await db.reminderDao.listResourceActionRecordsForResource(
      mapping.localEntityId,
    );
    expect(actions, hasLength(1));
    expect(actions.single.actionType, ResourceActionType.refilled);
  });
}

RemotePackSnapshot _snapshot({
  List<RemotePackMemberSnapshot>? members,
  List<RemoteResourceSnapshot>? resources,
  List<RemoteItemCompletionSnapshot>? completions,
  List<RemoteResourceEventSnapshot>? resourceEvents,
  List<RemoteActivityEventSnapshot>? activityEvents,
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
    members:
        members ??
        [
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
    resources: resources ?? const [],
    completions:
        completions ??
        [
          RemoteItemCompletionSnapshot(
            id: 'remote-completion-1',
            packId: 'remote-pack-1',
            itemId: 'remote-item-1',
            completedByUserId: 'remote-user-other',
            completedAt: DateTime(2026, 6, 21, 11, 5),
            createdAt: DateTime(2026, 6, 21, 11, 5),
          ),
        ],
    resourceEvents: resourceEvents ?? const [],
    activityEvents:
        activityEvents ??
        [
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
