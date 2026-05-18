import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reminder_app/features/reminders/data/home_models.dart';
import 'package:reminder_app/features/reminders/data/home_repository.dart';
import 'package:reminder_app/features/reminders/data/item_repository.dart';
import 'package:reminder_app/features/reminders/data/local/app_database.dart';
import 'package:reminder_app/features/reminders/data/resource_repository.dart';
import 'package:reminder_app/features/reminders/data/stage_tracker_models.dart';
import 'package:reminder_app/features/reminders/data/stage_tracker_repository.dart';
import 'package:reminder_app/features/reminders/domain/item.dart';
import 'package:reminder_app/features/reminders/domain/item_action_record.dart';
import 'package:reminder_app/features/reminders/domain/item_pack.dart';
import 'package:reminder_app/features/reminders/domain/resource.dart';

void main() {
  test('danger attention entries include danger items and resources', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final repositories = _repositories(db);
    final packId = await repositories.item.createPack(
      const ItemPackInput(title: 'Home', iconEmoji: '🏠'),
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

    final entries = await repositories.home
        .watchDangerAttentionEntries(now: DateTime(2026, 5, 2))
        .first;

    expect(entries.map((entry) => entry.title), [
      'Clean litter box',
      'Water filter',
    ]);
    expect(entries.map((entry) => entry.packId).toSet(), {packId});
  });

  test(
    'warning attention entries include warning items and resources',
    () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);
      final repositories = _repositories(db);
      final packId = await repositories.item.createPack(
        const ItemPackInput(title: 'Cat', iconEmoji: '🐱'),
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

      final entries = await repositories.home
          .watchWarningAttentionEntries(now: DateTime(2026, 5, 2))
          .first;

      expect(entries.map((entry) => entry.title), ['Brush cat', 'Cat snacks']);
      expect(entries.map((entry) => entry.packId).toSet(), {packId});
    },
  );

  test('stage occurrences stay out of danger and warning entries', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final repositories = _repositories(db);
    final trackerId = await repositories.stage.createStageTracker(
      StageTrackerInput(
        title: 'Baby growth',
        trackingStartDate: DateTime(2026, 5, 1),
      ),
    );
    await repositories.stage.createImportantStage(
      trackerId,
      ManualStageInput(
        label: '滿 1 個月',
        occurrenceDate: DateTime(2026, 5, 2),
        reminderOffsetDays: 0,
      ),
    );

    final upcoming = await repositories.home
        .watchUpcomingStages(now: DateTime(2026, 5, 2))
        .first;
    final danger = await repositories.home
        .watchDangerAttentionEntries(now: DateTime(2026, 5, 2))
        .first;
    final warning = await repositories.home
        .watchWarningAttentionEntries(now: DateTime(2026, 5, 2))
        .first;

    expect(upcoming.map((stage) => stage.label), ['滿 1 個月']);
    expect(danger, isEmpty);
    expect(warning, isEmpty);
  });

  test(
    'today completed entries include unreverted item resource and stage actions',
    () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);
      final repositories = _repositories(
        db,
        stageClock: () => DateTime(2026, 5, 2, 10),
      );
      final packId = await repositories.item.createPack(
        const ItemPackInput(title: 'Care', iconEmoji: '🧴'),
      );

      final itemId = await repositories.item.createItem(
        ItemInput(
          title: 'Clean bowl',
          type: ItemType.stateBased,
          config: const StateBasedItemConfig(
            warningAfter: Duration(days: 1),
            dangerAfter: Duration(days: 2),
          ),
          packId: packId,
        ),
      );
      final resourceId = await repositories.resource.createResource(
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
          occurrenceDate: DateTime(2026, 5, 2),
          reminderOffsetDays: 0,
        ),
      );

      await repositories.item.markDone(itemId, doneAt: DateTime(2026, 5, 2));
      await repositories.resource.refillResource(
        resourceId,
        actionAt: DateTime(2026, 5, 2),
        addedQuantity: 1,
      );
      await repositories.resource.adjustResourceQuantity(
        resourceId,
        actionAt: DateTime(2026, 5, 2),
        newQuantity: 4,
      );
      final stage =
          (await repositories.home
                  .watchUpcomingStages(now: DateTime(2026, 5, 2))
                  .first)
              .single;
      await repositories.stage.acknowledgeOccurrence(stage);

      final entries = await repositories.home
          .watchTodayCompletedEntries(now: DateTime(2026, 5, 2))
          .first;

      expect(entries.map((entry) => entry.title).toSet(), {
        'Clean bowl',
        'Soap',
        '滿 1 天',
      });
      expect(entries.map((entry) => entry.type).toSet(), {
        TodayCompletedEntryType.itemDone,
        TodayCompletedEntryType.resourceRefilled,
        TodayCompletedEntryType.resourceAdjusted,
        TodayCompletedEntryType.stageAcknowledged,
      });
      expect(entries.map((entry) => entry.packId).toSet(), {packId});
    },
  );

  test(
    'today completed entries exclude reverted item done and resource noise',
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
      final resourceId = await repositories.resource.createResource(
        const ResourceInput(
          title: 'Soap',
          type: ResourceType.quantityBased,
          config: QuantityBasedResourceConfig(
            currentQuantity: 1,
            unitLabel: '瓶',
            warningThreshold: 1,
            dangerThreshold: 0,
          ),
        ),
      );
      await repositories.resource.createConsumptionRule(
        ResourceConsumptionRuleInput(itemId: itemId, resourceId: resourceId),
      );

      await repositories.item.markDone(itemId, doneAt: DateTime(2026, 5, 2));
      final doneRecord = (await repositories.item.listActionHistory(
        itemId,
      )).firstWhere((record) => record.actionType == ItemActionType.done);
      await repositories.item.undoDone(
        doneRecord.id,
        undoneAt: DateTime(2026, 5, 2),
      );

      final entries = await repositories.home
          .watchTodayCompletedEntries(now: DateTime(2026, 5, 2))
          .first;

      expect(entries, isEmpty);
    },
  );
}

_RepositorySet _repositories(
  AppDatabase db, {
  DateTime Function()? stageClock,
}) {
  final item = ItemRepository(db.reminderDao);
  final resource = ResourceRepository(db.reminderDao);
  final stage = StageTrackerRepository(db.reminderDao, clock: stageClock);
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
