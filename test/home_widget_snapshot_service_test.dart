import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reminder_app/features/home_widget/application/home_widget_snapshot_service.dart';
import 'package:reminder_app/features/home_widget/data/home_widget_entry.dart';
import 'package:reminder_app/features/home_widget/data/home_widget_tab.dart';
import 'package:reminder_app/features/reminders/data/home_repository.dart';
import 'package:reminder_app/features/reminders/data/item_repository.dart';
import 'package:reminder_app/features/reminders/data/local/app_database.dart';
import 'package:reminder_app/features/reminders/data/resource_repository.dart';
import 'package:reminder_app/features/reminders/data/stage_tracker_repository.dart';
import 'package:reminder_app/features/reminders/domain/item.dart';
import 'package:reminder_app/features/reminders/domain/item_pack.dart';
import 'package:reminder_app/features/reminders/domain/remote_sync.dart';
import 'package:reminder_app/features/reminders/domain/resource.dart';
import 'package:reminder_app/features/reminders/data/stage_tracker_models.dart';

void main() {
  test('snapshot maps Home sections to widget tabs and actions', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final repositories = _repositories(db);
    final now = DateTime(2026, 5, 2);
    final packId = await repositories.item.createPack(
      const ItemPackInput(title: 'Care', iconEmoji: '🧴'),
    );

    await repositories.item.createItem(
      ItemInput(
        title: 'Clean litter box',
        type: ItemType.stateBased,
        config: StateBasedItemConfig(
          anchorDate: DateTime(2026, 5, 1),
          warningAfter: const Duration(days: 1),
          dangerAfter: const Duration(days: 2),
        ),
        packId: packId,
      ),
    );
    await repositories.resource.createResource(
      ResourceInput(
        title: 'Water filter',
        type: ResourceType.quantityBased,
        config: const QuantityBasedResourceConfig(
          currentQuantity: 1,
          unitLabel: '個',
          warningThreshold: 2,
          dangerThreshold: 1,
        ),
        packId: packId,
      ),
    );
    await repositories.item.createItem(
      ItemInput(
        title: 'Brush cat',
        type: ItemType.stateBased,
        config: StateBasedItemConfig(
          anchorDate: DateTime(2026, 5, 1),
          warningAfter: const Duration(days: 2),
          dangerAfter: const Duration(days: 5),
        ),
        packId: packId,
      ),
    );
    await repositories.resource.createResource(
      ResourceInput(
        title: 'Cat snacks',
        type: ResourceType.quantityBased,
        config: const QuantityBasedResourceConfig(
          currentQuantity: 2,
          unitLabel: '包',
          warningThreshold: 2,
          dangerThreshold: 1,
        ),
        packId: packId,
      ),
    );

    final completedItemId = await repositories.item.createItem(
      ItemInput(
        title: 'Clean bowl',
        type: ItemType.fixed,
        config: FixedItemConfig(
          scheduleType: FixedScheduleType.oneTime,
          dueDate: DateTime(2026, 5, 10),
          warningBefore: Duration.zero,
          dangerBefore: Duration.zero,
        ),
        packId: packId,
      ),
    );
    final completedResourceId = await repositories.resource.createResource(
      ResourceInput(
        title: 'Soap',
        type: ResourceType.quantityBased,
        config: const QuantityBasedResourceConfig(
          currentQuantity: 1,
          unitLabel: '瓶',
          warningThreshold: 1,
          dangerThreshold: 0,
        ),
        packId: packId,
      ),
    );
    final trackerId = await repositories.stage.createStageTracker(
      StageTrackerInput(
        title: 'Baby growth',
        trackingStartDate: DateTime(2026, 5, 1),
        packId: packId,
      ),
    );
    await repositories.stage.createImportantStage(
      trackerId,
      ManualStageInput(
        label: '滿 1 天',
        occurrenceDate: now,
        reminderOffsetDays: 0,
      ),
    );
    await repositories.item.markDone(completedItemId, doneAt: now);
    await repositories.resource.refillResource(
      completedResourceId,
      actionAt: now,
      addedQuantity: 1,
    );
    final stage =
        (await repositories.home.watchUpcomingStages(now: now).first).single;
    await repositories.stage.acknowledgeOccurrence(stage);

    final snapshot = await HomeWidgetSnapshotService(
      homeRepository: repositories.home,
      currentDate: now,
      clock: () => DateTime(2026, 6, 10, 9),
    ).buildSnapshot(selectedTab: HomeWidgetTabId.attention);

    expect(snapshot.selectedTab, HomeWidgetTabId.attention);

    final needsHandling = _tab(snapshot.tabs, HomeWidgetTabId.needsHandling);
    expect(needsHandling.label, '需要處理');
    expect(needsHandling.entries.map((entry) => entry.title), [
      'Clean litter box',
      'Water filter',
    ]);
    expect(needsHandling.entries.first.buttonText, '完成');
    expect(needsHandling.entries.first.action, HomeWidgetEntryAction.complete);
    expect(needsHandling.entries.first.displayIcon, '🧴');
    expect(needsHandling.entries.last.buttonText, isNull);
    expect(needsHandling.entries.last.canAct, isFalse);
    expect(needsHandling.entries.last.displayIcon, '🧴');

    final attention = _tab(snapshot.tabs, HomeWidgetTabId.attention);
    expect(attention.label, '要留意');
    expect(attention.entries.map((entry) => entry.title), [
      'Brush cat',
      'Cat snacks',
    ]);
    expect(attention.entries.map((entry) => entry.displayIcon), ['🧴', '🧴']);

    final completed = _tab(snapshot.tabs, HomeWidgetTabId.todayCompleted);
    expect(completed.label, '今天已完成');
    expect(completed.entries.map((entry) => entry.title).toSet(), {
      'Clean bowl',
      'Soap',
      '滿 1 天',
    });
    final completedItem = completed.entries.firstWhere(
      (entry) => entry.title == 'Clean bowl',
    );
    expect(completedItem.buttonText, '復原');
    expect(completedItem.action, HomeWidgetEntryAction.undo);
    expect(completedItem.canAct, isTrue);

    for (final tab in snapshot.tabs) {
      for (final entry in tab.entries) {
        expect(entry.statusText, isNot(anyOf('danger', 'warning', 'itemDone')));
      }
    }
  });

  test(
    'snapshot includes eligible remote-backed item rows in Phase 5F',
    () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);
      final repositories = _repositories(db);
      final now = DateTime(2026, 5, 2);
      final packId = await repositories.item.createPack(
        const ItemPackInput(title: 'Shared', iconEmoji: '🤝'),
      );
      final remoteItemId = await repositories.item.createItem(
        ItemInput(
          title: 'Remote litter box',
          type: ItemType.stateBased,
          config: StateBasedItemConfig(
            anchorDate: DateTime(2026, 5, 1),
            warningAfter: const Duration(days: 1),
            dangerAfter: const Duration(days: 2),
          ),
          packId: packId,
        ),
      );
      await _markRemoteBacked(
        db,
        localPackId: packId,
        localItemId: remoteItemId,
      );
      await repositories.item.createItem(
        ItemInput(
          title: 'Local litter box',
          type: ItemType.stateBased,
          config: StateBasedItemConfig(
            anchorDate: DateTime(2026, 5, 1),
            warningAfter: const Duration(days: 1),
            dangerAfter: const Duration(days: 2),
          ),
          packId: packId,
        ),
      );

      final snapshot = await HomeWidgetSnapshotService(
        homeRepository: repositories.home,
        currentDate: now,
      ).buildSnapshot();

      final needsHandling = _tab(snapshot.tabs, HomeWidgetTabId.needsHandling);
      expect(needsHandling.entries.map((entry) => entry.title), [
        'Remote litter box',
        'Local litter box',
      ]);
      final remote = needsHandling.entries.first;
      expect(remote.isRemoteBacked, isTrue);
      expect(remote.syncStatus, HomeWidgetEntrySyncStatus.none);
      expect(remote.canAct, isTrue);
    },
  );

  test('snapshot includes remote-backed sync states', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final repositories = _repositories(db);
    final now = DateTime(2026, 5, 2);
    final pendingPackId = await repositories.item.createPack(
      const ItemPackInput(title: 'Pending Shared', iconEmoji: '🤝'),
    );
    final failedPackId = await repositories.item.createPack(
      const ItemPackInput(title: 'Failed Shared', iconEmoji: '🤝'),
    );
    final stalePackId = await repositories.item.createPack(
      const ItemPackInput(title: 'Stale Shared', iconEmoji: '🤝'),
    );
    final accessLostPackId = await repositories.item.createPack(
      const ItemPackInput(title: 'Access Lost Shared', iconEmoji: '🤝'),
    );
    final pendingItemId = await _createDangerItem(
      repositories,
      title: 'Pending remote',
      packId: pendingPackId,
    );
    final failedItemId = await _createDangerItem(
      repositories,
      title: 'Failed remote',
      packId: failedPackId,
    );
    final staleItemId = await _createDangerItem(
      repositories,
      title: 'Stale remote',
      packId: stalePackId,
    );
    final accessLostItemId = await _createDangerItem(
      repositories,
      title: 'Access lost remote',
      packId: accessLostPackId,
    );
    await _markRemoteBacked(
      db,
      localPackId: pendingPackId,
      localItemId: pendingItemId,
    );
    await _markRemoteBacked(
      db,
      localPackId: failedPackId,
      localItemId: failedItemId,
    );
    await _markRemoteBacked(
      db,
      localPackId: stalePackId,
      localItemId: staleItemId,
      packState: RemotePackSyncState.stale,
    );
    await _markRemoteBacked(
      db,
      localPackId: accessLostPackId,
      localItemId: accessLostItemId,
      packState: RemotePackSyncState.accessLost,
    );
    await _insertOutbox(
      db,
      localPackId: pendingPackId,
      localItemId: pendingItemId,
      status: SyncOutboxStatus.pending,
      actionType: SyncOutboxActionType.completeItem,
    );
    await _insertOutbox(
      db,
      localPackId: failedPackId,
      localItemId: failedItemId,
      status: SyncOutboxStatus.failed,
      actionType: SyncOutboxActionType.undoItem,
    );

    final snapshot = await HomeWidgetSnapshotService(
      homeRepository: repositories.home,
      currentDate: now,
    ).buildSnapshot();

    final entries = {
      for (final entry in _tab(
        snapshot.tabs,
        HomeWidgetTabId.needsHandling,
      ).entries)
        entry.title: entry,
    };

    expect(
      entries['Pending remote']!.syncStatus,
      HomeWidgetEntrySyncStatus.pending,
    );
    expect(entries['Pending remote']!.syncLabel, '等待同步');
    expect(entries['Pending remote']!.hasPendingMutation, isTrue);
    expect(entries['Pending remote']!.pendingAction, 'complete_item');
    expect(
      entries['Failed remote']!.syncStatus,
      HomeWidgetEntrySyncStatus.failed,
    );
    expect(entries['Failed remote']!.syncLabel, '同步失敗');
    expect(entries['Failed remote']!.pendingAction, 'undo_item');
    expect(
      entries['Stale remote']!.syncStatus,
      HomeWidgetEntrySyncStatus.stale,
    );
    expect(entries['Stale remote']!.syncLabel, '遠端狀態可能已更新');
    expect(
      entries['Access lost remote']!.syncStatus,
      HomeWidgetEntrySyncStatus.accessLost,
    );
    expect(entries['Access lost remote']!.syncLabel, '已失去遠端存取權');
    expect(entries['Access lost remote']!.canAct, isFalse);
    expect(entries['Access lost remote']!.actionDisabledReason, '已失去遠端存取權');
  });

  test('remote-backed warning and today-completed rows are eligible', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final repositories = _repositories(db);
    final now = DateTime(2026, 5, 2);
    final packId = await repositories.item.createPack(
      const ItemPackInput(title: 'Shared', iconEmoji: '🤝'),
    );
    final warningItemId = await repositories.item.createItem(
      ItemInput(
        title: 'Remote brush cat',
        type: ItemType.stateBased,
        config: StateBasedItemConfig(
          anchorDate: DateTime(2026, 5, 1),
          warningAfter: const Duration(days: 2),
          dangerAfter: const Duration(days: 5),
        ),
        packId: packId,
      ),
    );
    final completedItemId = await repositories.item.createItem(
      ItemInput(
        title: 'Remote clean bowl',
        type: ItemType.fixed,
        config: FixedItemConfig(
          scheduleType: FixedScheduleType.oneTime,
          dueDate: DateTime(2026, 5, 10),
          warningBefore: Duration.zero,
          dangerBefore: Duration.zero,
        ),
        packId: packId,
      ),
    );
    expect(
      await repositories.item.markDone(completedItemId, doneAt: now),
      isTrue,
    );
    await _markRemoteBacked(
      db,
      localPackId: packId,
      localItemId: warningItemId,
    );
    await _markRemoteBacked(
      db,
      localPackId: packId,
      localItemId: completedItemId,
    );

    final snapshot = await HomeWidgetSnapshotService(
      homeRepository: repositories.home,
      currentDate: now,
    ).buildSnapshot();

    final attention = _tab(snapshot.tabs, HomeWidgetTabId.attention);
    expect(
      attention.entries.map((entry) => entry.title),
      contains('Remote brush cat'),
    );
    final completed = _tab(snapshot.tabs, HomeWidgetTabId.todayCompleted);
    expect(
      completed.entries.map((entry) => entry.title),
      contains('Remote clean bowl'),
    );
  });
}

HomeWidgetTab _tab(List<HomeWidgetTab> tabs, HomeWidgetTabId id) {
  return tabs.firstWhere((tab) => tab.id == id);
}

Future<void> _markRemoteBacked(
  AppDatabase db, {
  required int localPackId,
  required int localItemId,
  RemotePackSyncState packState = RemotePackSyncState.synced,
  RemoteItemSyncState itemState = RemoteItemSyncState.synced,
}) async {
  final now = DateTime(2026, 5, 2).millisecondsSinceEpoch;
  final existingPackMetadata = await db.reminderDao
      .getRemotePackSyncMetadataForLocalPack(localPackId);
  if (existingPackMetadata == null) {
    await db.reminderDao.insertRemotePackSyncMetadata(
      RemotePackSyncMetadataCompanion.insert(
        localPackId: localPackId,
        remotePackId: 'remote-pack-$localPackId',
        syncKind: RemotePackSyncKind.remoteBacked.storageValue,
        syncState: packState.storageValue,
        createdAt: now,
        updatedAt: now,
      ),
    );
  } else {
    await db.reminderDao.updateRemotePackSyncMetadata(
      existingPackMetadata.id,
      RemotePackSyncMetadataCompanion(
        syncState: Value(packState.storageValue),
        updatedAt: Value(now),
      ),
    );
  }
  await db.reminderDao.insertRemoteItemSyncMetadata(
    RemoteItemSyncMetadataCompanion.insert(
      localItemId: localItemId,
      localPackId: localPackId,
      remoteItemId: 'remote-item-$localItemId',
      remotePackId: 'remote-pack-$localPackId',
      syncState: itemState.storageValue,
      createdAt: now,
      updatedAt: now,
    ),
  );
}

Future<int> _createDangerItem(
  _RepositorySet repositories, {
  required String title,
  required int packId,
}) {
  return repositories.item.createItem(
    ItemInput(
      title: title,
      type: ItemType.stateBased,
      config: StateBasedItemConfig(
        anchorDate: DateTime(2026, 5, 1),
        warningAfter: const Duration(days: 1),
        dangerAfter: const Duration(days: 2),
      ),
      packId: packId,
    ),
  );
}

Future<void> _insertOutbox(
  AppDatabase db, {
  required int localPackId,
  required int localItemId,
  required SyncOutboxStatus status,
  required SyncOutboxActionType actionType,
}) async {
  final now = DateTime(2026, 5, 2).millisecondsSinceEpoch;
  await db.reminderDao.insertSyncOutbox(
    SyncOutboxCompanion.insert(
      localPackId: localPackId,
      remotePackId: Value('remote-pack-$localPackId'),
      localEntityType: 'item_completion',
      localEntityId: Value(localItemId),
      remoteEntityId: Value('remote-item-$localItemId'),
      actionType: actionType.storageValue,
      payloadJson: jsonEncode({
        'localItemId': localItemId,
        'localPackId': localPackId,
        'remoteItemId': 'remote-item-$localItemId',
        'remotePackId': 'remote-pack-$localPackId',
      }),
      clientMutationId: 'mutation-$localItemId',
      actorLocalUserId: AppDatabase.defaultHostUserId,
      createdAt: now,
      updatedAt: now,
      status: status.storageValue,
    ),
  );
}

_RepositorySet _repositories(AppDatabase db) {
  final item = ItemRepository(db.reminderDao);
  final resource = ResourceRepository(db.reminderDao);
  final stage = StageTrackerRepository(
    db.reminderDao,
    clock: () => DateTime(2026, 5, 2, 10),
  );
  return _RepositorySet(
    item: item,
    resource: resource,
    stage: stage,
    home: HomeRepository(
      itemRepository: item,
      resourceRepository: resource,
      stageTrackerRepository: stage,
    ),
  );
}

class _RepositorySet {
  const _RepositorySet({
    required this.item,
    required this.resource,
    required this.stage,
    required this.home,
  });

  final ItemRepository item;
  final ResourceRepository resource;
  final StageTrackerRepository stage;
  final HomeRepository home;
}
