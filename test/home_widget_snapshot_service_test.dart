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
    expect(needsHandling.entries.last.buttonText, isNull);
    expect(needsHandling.entries.last.canAct, isFalse);

    final attention = _tab(snapshot.tabs, HomeWidgetTabId.attention);
    expect(attention.label, '要留意');
    expect(attention.entries.map((entry) => entry.title), [
      'Brush cat',
      'Cat snacks',
    ]);

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
}

HomeWidgetTab _tab(List<HomeWidgetTab> tabs, HomeWidgetTabId id) {
  return tabs.firstWhere((tab) => tab.id == id);
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
