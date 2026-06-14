import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reminder_app/features/home_widget/application/home_widget_action_service.dart';
import 'package:reminder_app/features/home_widget/application/home_widget_snapshot_service.dart';
import 'package:reminder_app/features/home_widget/data/home_widget_entry.dart';
import 'package:reminder_app/features/home_widget/data/home_widget_snapshot.dart';
import 'package:reminder_app/features/home_widget/data/home_widget_snapshot_store.dart';
import 'package:reminder_app/features/home_widget/data/home_widget_tab.dart';
import 'package:reminder_app/features/reminders/data/home_repository.dart';
import 'package:reminder_app/features/reminders/data/item_repository.dart';
import 'package:reminder_app/features/reminders/data/local/app_database.dart';
import 'package:reminder_app/features/reminders/data/resource_repository.dart';
import 'package:reminder_app/features/reminders/data/stage_tracker_repository.dart';
import 'package:reminder_app/features/reminders/domain/item.dart';
import 'package:reminder_app/features/reminders/domain/item_action_record.dart';

void main() {
  test(
    'refreshSnapshot writes snapshot and switchTab updates selected tab',
    () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);
      final repositories = _repositories(db);
      final store = _MemoryHomeWidgetSnapshotStore();
      final service = _actionService(repositories, store);

      final snapshot = await service.refreshSnapshot();
      expect(snapshot.selectedTab, HomeWidgetTabId.needsHandling);
      expect((await store.readSnapshot())?.schemaVersion, 1);

      final switched = await service.switchTab(HomeWidgetTabId.todayCompleted);
      expect(switched.selectedTab, HomeWidgetTabId.todayCompleted);
      expect(
        (await store.readSnapshot())?.selectedTab,
        HomeWidgetTabId.todayCompleted,
      );
    },
  );

  test(
    'completeEntry delegates to item repository for actionable item row',
    () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);
      final repositories = _repositories(db);
      final itemId = await repositories.item.createItem(
        ItemInput(
          title: 'Clean litter box',
          type: ItemType.stateBased,
          config: StateBasedItemConfig(
            anchorDate: DateTime(2026, 5, 1),
            warningAfter: const Duration(days: 1),
            dangerAfter: const Duration(days: 2),
          ),
        ),
      );
      final store = _MemoryHomeWidgetSnapshotStore();
      final service = _actionService(repositories, store);

      final snapshot = await service.refreshSnapshot();
      final entry = snapshot.findEntry('item-$itemId')!;

      expect(await service.completeEntry(entry.entryId), isTrue);
      final history = await repositories.item.listActionHistory(itemId);
      expect(
        history.any((record) => record.actionType == ItemActionType.done),
        isTrue,
      );
    },
  );

  test(
    'undoCompletedEntry delegates to item repository only for undo rows',
    () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);
      final repositories = _repositories(db);
      final itemId = await repositories.item.createItem(
        const ItemInput(
          title: 'Clean bowl',
          type: ItemType.stateBased,
          config: StateBasedItemConfig(
            warningAfter: Duration(days: 1),
            dangerAfter: Duration(days: 2),
          ),
        ),
      );
      await repositories.item.markDone(itemId, doneAt: DateTime(2026, 5, 2));
      final store = _MemoryHomeWidgetSnapshotStore();
      final service = _actionService(repositories, store);

      final snapshot = await service.refreshSnapshot(
        selectedTab: HomeWidgetTabId.todayCompleted,
      );
      final entry = snapshot.findEntry(
        snapshot.tabs
            .firstWhere((tab) => tab.id == HomeWidgetTabId.todayCompleted)
            .entries
            .single
            .entryId,
      )!;

      expect(await service.undoCompletedEntry(entry.entryId), isTrue);
      final history = await repositories.item.listActionHistory(itemId);
      final doneRecord = history.firstWhere(
        (record) => record.actionType == ItemActionType.done,
      );
      expect(doneRecord.isReverted, isTrue);
    },
  );

  test('unsupported or missing entry ids return false', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final repositories = _repositories(db);
    final store = _MemoryHomeWidgetSnapshotStore();
    final service = _actionService(repositories, store);

    await service.refreshSnapshot();

    expect(await service.completeEntry('missing-entry'), isFalse);
    expect(await service.undoCompletedEntry('missing-entry'), isFalse);
  });

  test(
    'resource and stage rows remain display-only for widget actions',
    () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);
      final repositories = _repositories(db);
      final store = _MemoryHomeWidgetSnapshotStore();
      store.snapshot = HomeWidgetSnapshot(
        schemaVersion: HomeWidgetSnapshot.currentSchemaVersion,
        updatedAt: DateTime(2026, 6, 10, 9),
        selectedTab: HomeWidgetTabId.needsHandling,
        tabs: const [
          HomeWidgetTab(
            id: HomeWidgetTabId.needsHandling,
            label: '需要處理',
            count: 1,
            entries: [
              HomeWidgetEntry(
                entryId: 'resource-1',
                type: HomeWidgetEntryType.resourceAttention,
                targetId: 1,
                title: 'Water filter',
                statusText: '剩餘 1 個',
                buttonText: '完成',
                action: HomeWidgetEntryAction.complete,
                canAct: true,
              ),
            ],
          ),
          HomeWidgetTab(
            id: HomeWidgetTabId.todayCompleted,
            label: '今天已完成',
            count: 2,
            entries: [
              HomeWidgetEntry(
                entryId: 'completed-resource-1',
                type: HomeWidgetEntryType.completedResource,
                targetId: 1,
                actionRecordId: 1,
                title: 'Soap',
                statusText: '已補充',
                buttonText: '復原',
                action: HomeWidgetEntryAction.undo,
                canAct: true,
              ),
              HomeWidgetEntry(
                entryId: 'completed-stage-1',
                type: HomeWidgetEntryType.completedStage,
                actionRecordId: 2,
                title: '滿 1 天',
                statusText: '知道了',
                buttonText: '復原',
                action: HomeWidgetEntryAction.undo,
                canAct: true,
              ),
            ],
          ),
        ],
      );
      final service = _actionService(repositories, store);

      expect(await service.completeEntry('resource-1'), isFalse);
      expect(await service.undoCompletedEntry('completed-resource-1'), isFalse);
      expect(await service.undoCompletedEntry('completed-stage-1'), isFalse);
    },
  );

  test('completed item without undo eligibility cannot be undone', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final repositories = _repositories(db);
    final store = _MemoryHomeWidgetSnapshotStore();
    store.snapshot = HomeWidgetSnapshot(
      schemaVersion: HomeWidgetSnapshot.currentSchemaVersion,
      updatedAt: DateTime(2026, 6, 10, 9),
      selectedTab: HomeWidgetTabId.todayCompleted,
      tabs: const [
        HomeWidgetTab(
          id: HomeWidgetTabId.todayCompleted,
          label: '今天已完成',
          count: 1,
          entries: [
            HomeWidgetEntry(
              entryId: 'item-done-1',
              type: HomeWidgetEntryType.completedItem,
              targetId: 1,
              actionRecordId: 1,
              title: 'Clean bowl',
              statusText: '完成',
              canAct: false,
            ),
          ],
        ),
      ],
    );
    final service = _actionService(repositories, store);

    expect(await service.undoCompletedEntry('item-done-1'), isFalse);
  });
}

HomeWidgetActionService _actionService(
  _RepositorySet repositories,
  HomeWidgetSnapshotStore store,
) {
  final currentDate = DateTime(2026, 5, 2);
  return HomeWidgetActionService(
    snapshotService: HomeWidgetSnapshotService(
      homeRepository: repositories.home,
      currentDate: currentDate,
      clock: () => DateTime(2026, 6, 10, 9),
    ),
    snapshotStore: store,
    itemRepository: repositories.item,
    currentDate: currentDate,
  );
}

_RepositorySet _repositories(AppDatabase db) {
  final item = ItemRepository(db.reminderDao);
  final resource = ResourceRepository(db.reminderDao);
  final stage = StageTrackerRepository(db.reminderDao);
  return _RepositorySet(
    item: item,
    home: HomeRepository(
      itemRepository: item,
      resourceRepository: resource,
      stageTrackerRepository: stage,
    ),
  );
}

class _RepositorySet {
  const _RepositorySet({required this.item, required this.home});

  final ItemRepository item;
  final HomeRepository home;
}

class _MemoryHomeWidgetSnapshotStore implements HomeWidgetSnapshotStore {
  HomeWidgetSnapshot? snapshot;

  @override
  Future<HomeWidgetSnapshot?> readSnapshot() async => snapshot;

  @override
  Future<void> writeSnapshot(HomeWidgetSnapshot snapshot) async {
    this.snapshot = snapshot;
  }
}
