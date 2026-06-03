import 'package:drift/native.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:reminder_app/features/reminders/data/local/app_database.dart';
import 'package:reminder_app/features/reminders/data/item_repository.dart';
import 'package:reminder_app/features/reminders/domain/attention_policy.dart';
import 'package:reminder_app/features/reminders/domain/fixed_schedule_validator.dart';
import 'package:reminder_app/features/reminders/domain/item_action_record.dart';
import 'package:reminder_app/features/reminders/domain/item.dart';
import 'package:reminder_app/features/reminders/domain/item_pack.dart';
import 'package:reminder_app/features/reminders/domain/repeat_rule.dart';
import 'package:reminder_app/features/reminders/domain/repeat_rule_v2.dart';
import 'package:reminder_app/features/reminders/domain/resource.dart';
import 'package:reminder_app/features/reminders/data/resource_repository.dart';

void main() {
  test(
    'creating an item provisions the default pack and round-trips mapping',
    () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);
      final repository = ItemRepository(db.reminderDao);

      final itemId = await repository.createItem(
        ItemInput(
          title: 'Clean litter box',
          description: 'Cat hygiene',
          type: ItemType.stateBased,
          config: const StateBasedItemConfig(
            infoAfter: Duration(days: 2),
            warningAfter: Duration(days: 2),
            dangerAfter: Duration(days: 4),
          ),
        ),
      );

      final item = await repository.getItemById(itemId);
      final packs = await repository.watchPacks().first;
      final history = await repository.listActionHistory(itemId);

      expect(item, isNotNull);
      expect(packs, hasLength(1));
      expect(packs.single.title, '一般');
      expect(packs.single.iconEmoji, '📌');
      expect(packs.single.status, ItemPackStatus.active);
      expect(packs.single.isSystemDefault, isTrue);
      expect(item!.pack.id, packs.single.id);
      expect(item.item.title, 'Clean litter box');
      expect(item.item.status, ItemLifecycleStatus.active);
      expect(item.item.type, ItemType.stateBased);
      expect(
        item.item.attentionPolicySource,
        AttentionPolicySource.systemDefault,
      );
      expect(item.item.config, isA<StateBasedItemConfig>());
      expect(history, hasLength(1));
      expect(history.single.actionType, ItemActionType.created);
    },
  );

  test('state-based anchor date seeds initial baseline snapshot', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final repository = ItemRepository(db.reminderDao);

    final itemId = await repository.createItem(
      ItemInput(
        title: 'Replace filter',
        type: ItemType.stateBased,
        config: StateBasedItemConfig(
          anchorDate: DateTime(2026, 4, 1),
          infoAfter: const Duration(days: 7),
          warningAfter: const Duration(days: 7),
          dangerAfter: const Duration(days: 14),
        ),
      ),
    );

    final item = await repository.getItemById(itemId);
    expect(item, isNotNull);
    expect(item!.item.lastDoneAt, isNull);
    expect(
      (item.item.config as StateBasedItemConfig).anchorDate,
      DateTime(2026, 4, 1),
    );
  });

  test(
    'markDone(stateBased) updates stateAnchorDate and resets day index from day 1',
    () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);
      final repository = ItemRepository(db.reminderDao);

      final itemId = await repository.createItem(
        ItemInput(
          title: 'Refill water fountain',
          type: ItemType.stateBased,
          config: const StateBasedItemConfig(
            infoAfter: Duration(days: 1),
            warningAfter: Duration(days: 1),
            dangerAfter: Duration(days: 2),
          ),
        ),
      );

      final before = (await repository.watchItems().first).single;
      expect(
        repository.statusFor(before.item, now: DateTime(2026, 4, 15)),
        ItemStatus.unknown,
      );

      await repository.markDone(itemId, doneAt: DateTime(2026, 4, 14));

      final after = (await repository.watchItems().first).single;
      expect(after.item.lastDoneAt, isNull);
      expect(
        (after.item.config as StateBasedItemConfig).anchorDate,
        DateTime(2026, 4, 14),
      );
      expect(
        repository.statusFor(after.item, now: DateTime(2026, 4, 14)),
        ItemStatus.warning,
      );
    },
  );

  test(
    'preview date actions use preview actionDate but real updatedAt',
    () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);
      var now = DateTime(2026, 4, 1, 9, 0);
      final repository = ItemRepository(db.reminderDao, clock: () => now);

      final itemId = await repository.createItem(
        ItemInput(
          title: 'Preview-safe completion',
          type: ItemType.stateBased,
          config: const StateBasedItemConfig(
            infoAfter: Duration(days: 1),
            warningAfter: Duration(days: 1),
            dangerAfter: Duration(days: 2),
          ),
        ),
      );
      final before = await repository.getItemById(itemId);
      final previewDate = DateTime(2026, 4, 14, 15, 30);
      now = DateTime(2026, 4, 20, 10, 45);

      await repository.markDone(itemId, doneAt: previewDate);

      final after = await repository.getItemById(itemId);
      final history = await repository.listActionHistory(itemId);
      expect(before, isNotNull);
      expect(after, isNotNull);
      expect(history, hasLength(2));
      final doneRecord = history.firstWhere(
        (record) => record.actionType == ItemActionType.done,
      );
      expect(after!.item.lastDoneAt, isNull);
      expect(
        (after.item.config as StateBasedItemConfig).anchorDate,
        DateTime(2026, 4, 14),
      );
      expect(after.item.updatedAt, now);
      expect(after.item.updatedAt.isBefore(before!.item.updatedAt), isFalse);
      expect(doneRecord.actionDate, DateTime(2026, 4, 14));
      expect(doneRecord.updatedAt, now);
      expect(doneRecord.createdAt, now);
    },
  );

  test('watchItemsByStatus filters items by computed status', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final repository = ItemRepository(db.reminderDao);

    await repository.createItem(
      ItemInput(
        title: 'Change pee pad',
        type: ItemType.stateBased,
        config: const StateBasedItemConfig(
          infoAfter: Duration(days: 1),
          warningAfter: Duration(days: 1),
          dangerAfter: Duration(days: 2),
        ),
      ),
    );
    await repository.createItem(
      ItemInput(
        title: 'Brush cat',
        type: ItemType.stateBased,
        config: const StateBasedItemConfig(
          infoAfter: Duration(days: 3),
          warningAfter: Duration(days: 3),
          dangerAfter: Duration(days: 6),
        ),
      ),
    );

    final items = await repository.watchItems().first;
    final byTitle = {for (final item in items) item.item.title: item.item.id};
    await repository.markDone(
      byTitle['Change pee pad']!,
      doneAt: DateTime(2026, 4, 10),
    );
    await repository.markDone(
      byTitle['Brush cat']!,
      doneAt: DateTime(2026, 4, 12),
    );

    final danger = await repository
        .watchItemsByStatus(ItemStatus.danger, now: DateTime(2026, 4, 15))
        .first;
    final warning = await repository
        .watchItemsByStatus(ItemStatus.warning, now: DateTime(2026, 4, 15))
        .first;

    expect(danger.map((item) => item.item.title), ['Change pee pad']);
    expect(warning.map((item) => item.item.title), ['Brush cat']);
  });

  test('markDone consumes quantity resource through enabled rule', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final repository = ItemRepository(db.reminderDao);
    final resourceRepository = ResourceRepository(db.reminderDao);

    final itemId = await repository.createItem(
      const ItemInput(
        title: 'Replace water filter',
        type: ItemType.stateBased,
        config: StateBasedItemConfig(
          warningAfter: Duration(days: 12),
          dangerAfter: Duration(days: 14),
        ),
      ),
    );
    final resourceId = await resourceRepository.createResource(
      const ResourceInput(
        title: 'Water filter',
        type: ResourceType.quantityBased,
        config: QuantityBasedResourceConfig(
          currentQuantity: 5,
          unitLabel: '個',
          warningThreshold: 2,
          dangerThreshold: 1,
        ),
      ),
    );
    await resourceRepository.createConsumptionRule(
      ResourceConsumptionRuleInput(
        itemId: itemId,
        resourceId: resourceId,
        consumeAmount: 1,
      ),
    );

    expect(
      await repository.markDone(itemId, doneAt: DateTime(2026, 4, 5)),
      isTrue,
    );

    final resource = await resourceRepository.getResourceById(resourceId);
    final history = await resourceRepository.listActionHistory(resourceId);
    final itemHistory = await repository.listActionHistory(itemId);
    expect(resource, isNotNull);
    expect(
      (resource!.resource.config as QuantityBasedResourceConfig)
          .currentQuantity,
      4,
    );
    final consumedRecord = history.firstWhere(
      (record) => record.actionType == ResourceActionType.consumed,
    );
    final actualDoneRecord = itemHistory.firstWhere(
      (record) => record.actionType == ItemActionType.done,
    );
    expect(consumedRecord.resultingQuantity, 4);
    expect(consumedRecord.sourceItemActionRecordId, actualDoneRecord.id);
  });

  test(
    'undoDone reverts item done record and restores item snapshot',
    () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);
      final repository = ItemRepository(db.reminderDao);

      final itemId = await repository.createItem(
        ItemInput(
          title: 'Clean fountain',
          type: ItemType.stateBased,
          config: StateBasedItemConfig(
            anchorDate: DateTime(2026, 4, 1),
            warningAfter: const Duration(days: 2),
            dangerAfter: const Duration(days: 4),
          ),
        ),
      );

      expect(
        await repository.markDone(itemId, doneAt: DateTime(2026, 4, 5)),
        isTrue,
      );
      final doneRecord = (await repository.listActionHistory(
        itemId,
      )).firstWhere((record) => record.actionType == ItemActionType.done);
      expect(
        await repository.undoDone(
          doneRecord.id,
          revertedAt: DateTime(2026, 4, 6),
        ),
        isTrue,
      );

      final item = await repository.getItemById(itemId);
      final history = await repository.listActionHistory(itemId);
      final revertedDone = history.firstWhere(
        (record) => record.id == doneRecord.id,
      );
      final revertRecord = history.firstWhere(
        (record) => record.actionType == ItemActionType.reverted,
      );

      expect(
        (item!.item.config as StateBasedItemConfig).anchorDate,
        DateTime(2026, 4, 1),
      );
      expect(revertedDone.isReverted, isTrue);
      expect(revertedDone.revertedAt, DateTime(2026, 4, 6));
      expect(revertedDone.revertedByActionRecordId, revertRecord.id);
      expect(revertRecord.payload?['reason'], 'undo_done');
      expect(revertRecord.payload?['revertedActionRecordId'], doneRecord.id);
    },
  );

  test(
    'undoDone restores consumed quantity resource and hides reverted pair from history',
    () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);
      final repository = ItemRepository(db.reminderDao);
      final resourceRepository = ResourceRepository(db.reminderDao);

      final itemId = await repository.createItem(
        const ItemInput(
          title: 'Replace filter',
          type: ItemType.stateBased,
          config: StateBasedItemConfig(
            warningAfter: Duration(days: 12),
            dangerAfter: Duration(days: 14),
          ),
        ),
      );
      final resourceId = await resourceRepository.createResource(
        const ResourceInput(
          title: 'Filter',
          type: ResourceType.quantityBased,
          config: QuantityBasedResourceConfig(
            currentQuantity: 5,
            unitLabel: '個',
            warningThreshold: 2,
            dangerThreshold: 1,
          ),
        ),
      );
      final ruleId = await resourceRepository.createConsumptionRule(
        ResourceConsumptionRuleInput(
          itemId: itemId,
          resourceId: resourceId,
          consumeAmount: 2,
        ),
      );

      expect(
        await repository.markDone(itemId, doneAt: DateTime(2026, 4, 5)),
        isTrue,
      );
      await resourceRepository.disableConsumptionRule(ruleId);
      expect(await resourceRepository.archiveResource(resourceId), isTrue);
      final doneRecord = (await repository.listActionHistory(
        itemId,
      )).firstWhere((record) => record.actionType == ItemActionType.done);

      expect(
        await repository.undoDone(
          doneRecord.id,
          revertedAt: DateTime(2026, 4, 6),
        ),
        isTrue,
      );

      final resource = await resourceRepository.getResourceById(resourceId);
      final visibleHistory = await resourceRepository.listActionHistory(
        resourceId,
      );
      final fullHistory = await resourceRepository.listActionHistory(
        resourceId,
        includeReverted: true,
      );
      final consumedRecord = fullHistory.firstWhere(
        (record) => record.actionType == ResourceActionType.consumed,
      );
      final compensationRecord = fullHistory.firstWhere(
        (record) => record.actionType == ResourceActionType.reverted,
      );

      expect(
        (resource!.resource.config as QuantityBasedResourceConfig)
            .currentQuantity,
        5,
      );
      expect(consumedRecord.isReverted, isTrue);
      expect(consumedRecord.revertedByActionRecordId, compensationRecord.id);
      expect(compensationRecord.amount, 2);
      expect(compensationRecord.resultingQuantity, 5);
      expect(visibleHistory.map((record) => record.actionType), [
        ResourceActionType.created,
      ]);
    },
  );

  test(
    'undoDone rolls back item changes when resource compensation fails',
    () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);
      final repository = ItemRepository(db.reminderDao);
      final resourceRepository = ResourceRepository(db.reminderDao);

      final itemId = await repository.createItem(
        const ItemInput(
          title: 'Clean bowl',
          type: ItemType.stateBased,
          config: StateBasedItemConfig(
            warningAfter: Duration(days: 1),
            dangerAfter: Duration(days: 2),
          ),
        ),
      );
      final resourceId = await resourceRepository.createResource(
        ResourceInput(
          title: 'Time resource',
          type: ResourceType.timeBased,
          config: TimeBasedResourceConfig(
            anchorDate: DateTime(2026, 4, 1),
            durationDays: 10,
          ),
        ),
      );
      await repository.markDone(itemId, doneAt: DateTime(2026, 4, 5));
      final doneRecord = (await repository.listActionHistory(
        itemId,
      )).firstWhere((record) => record.actionType == ItemActionType.done);
      await db.reminderDao.insertResourceActionRecord(
        ResourceActionRecordsCompanion.insert(
          resourceId: resourceId,
          actionType: ResourceActionType.consumed.name,
          actionDate: DateTime(2026, 4, 5).millisecondsSinceEpoch,
          amount: const Value(1),
          sourceItemActionRecordId: Value(doneRecord.id),
          createdAt: DateTime(2026, 4, 5).millisecondsSinceEpoch,
          updatedAt: DateTime(2026, 4, 5).millisecondsSinceEpoch,
        ),
      );

      expect(
        await repository.undoDone(
          doneRecord.id,
          revertedAt: DateTime(2026, 4, 6),
        ),
        isFalse,
      );

      final history = await repository.listActionHistory(itemId);
      final unchangedDone = history.firstWhere(
        (record) => record.id == doneRecord.id,
      );
      expect(unchangedDone.isReverted, isFalse);
      expect(
        history.any((record) => record.actionType == ItemActionType.reverted),
        isFalse,
      );
    },
  );

  test('refill quantity resource writes resulting quantity', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final repository = ResourceRepository(db.reminderDao);

    final resourceId = await repository.createResource(
      const ResourceInput(
        title: 'Filter',
        type: ResourceType.quantityBased,
        config: QuantityBasedResourceConfig(
          currentQuantity: 2,
          unitLabel: '個',
          warningThreshold: 2,
          dangerThreshold: 1,
        ),
      ),
    );

    expect(
      await repository.refillResource(
        resourceId,
        actionAt: DateTime(2026, 4, 5),
        addedQuantity: 5,
      ),
      isTrue,
    );

    final resource = await repository.getResourceById(resourceId);
    final history = await repository.listActionHistory(resourceId);
    expect(
      (resource!.resource.config as QuantityBasedResourceConfig)
          .currentQuantity,
      7,
    );
    expect(
      history.any(
        (record) =>
            record.actionType == ResourceActionType.refilled &&
            record.resultingQuantity == 7,
      ),
      isTrue,
    );
  });

  test('refill time resource carries days before depletion only', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final repository = ResourceRepository(db.reminderDao);

    final beforeId = await repository.createResource(
      ResourceInput(
        title: 'Shampoo',
        type: ResourceType.timeBased,
        config: TimeBasedResourceConfig(
          anchorDate: DateTime(2026, 4, 1),
          durationDays: 10,
          warningBeforeDays: 3,
          dangerBeforeDays: 1,
        ),
      ),
    );
    await repository.refillResource(
      beforeId,
      actionAt: DateTime(2026, 4, 9),
      addedDays: 2,
    );
    final before = await repository.getResourceById(beforeId);
    expect(
      (before!.resource.config as TimeBasedResourceConfig).durationDays,
      4,
    );

    final afterId = await repository.createResource(
      ResourceInput(
        title: 'Soap',
        type: ResourceType.timeBased,
        config: TimeBasedResourceConfig(
          anchorDate: DateTime(2026, 4, 1),
          durationDays: 5,
          warningBeforeDays: 1,
          dangerBeforeDays: 0,
        ),
      ),
    );
    await repository.refillResource(
      afterId,
      actionAt: DateTime(2026, 4, 7),
      addedDays: 3,
    );
    final after = await repository.getResourceById(afterId);
    expect((after!.resource.config as TimeBasedResourceConfig).durationDays, 3);
  });

  test('defer is disabled and does not write action history', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final repository = ItemRepository(db.reminderDao);

    final itemId = await repository.createItem(
      ItemInput(
        title: 'Pay rent',
        type: ItemType.fixed,
        config: FixedItemConfig(
          scheduleType: FixedScheduleType.weekly,
          anchorDate: DateTime(2026, 4, 1),
          dueDate: DateTime(2026, 4, 7),
        ),
      ),
    );

    final before = await repository.getItemById(itemId);
    expect(
      await repository.defer(
        itemId,
        deferDays: 3,
        actionAt: DateTime(2026, 4, 5),
      ),
      isFalse,
    );

    final after = await repository.getItemById(itemId);
    expect(after, isNotNull);
    expect(
      (after!.item.config as FixedItemConfig).anchorDate,
      (before!.item.config as FixedItemConfig).anchorDate,
    );
    expect(
      (after.item.config as FixedItemConfig).dueDate,
      (before.item.config as FixedItemConfig).dueDate,
    );
    expect(
      (await repository.listActionHistory(
        itemId,
      )).where((record) => record.actionType != ItemActionType.created),
      isEmpty,
    );
  });

  test(
    'updateItem rejects item type changes and preserves existing item',
    () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);
      final repository = ItemRepository(db.reminderDao);

      final itemId = await repository.createItem(
        ItemInput(
          title: 'Cat food',
          type: ItemType.stateBased,
          config: StateBasedItemConfig(
            warningAfter: Duration(days: 3),
            dangerAfter: Duration(days: 5),
          ),
        ),
      );

      expect(
        await repository.updateItem(
          itemId,
          ItemInput(
            title: 'Changed type',
            type: ItemType.fixed,
            config: FixedItemConfig(
              scheduleType: FixedScheduleType.oneTime,
              anchorDate: DateTime(2026, 4, 2),
              dueDate: DateTime(2026, 4, 3),
            ),
          ),
        ),
        isFalse,
      );

      final after = await repository.getItemById(itemId);
      expect(after, isNotNull);
      expect(after!.item.title, 'Cat food');
      expect(after.item.type, ItemType.stateBased);
    },
  );

  test(
    'updateItem preserves fixed stored dates when editing non-schedule fields',
    () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);
      final repository = ItemRepository(db.reminderDao);

      final itemId = await repository.createItem(
        ItemInput(
          title: 'Pay rent',
          description: 'old note',
          type: ItemType.fixed,
          config: FixedItemConfig(
            scheduleType: FixedScheduleType.daily,
            anchorDate: DateTime(2026, 4, 1),
            dueDate: DateTime(2026, 4, 1),
            overduePolicy: ItemOverduePolicy.autoAdvance,
          ),
        ),
      );

      expect(
        await repository.updateItem(
          itemId,
          ItemInput(
            title: 'Pay rent updated',
            description: 'new note',
            type: ItemType.fixed,
            config: FixedItemConfig(
              scheduleType: FixedScheduleType.daily,
              anchorDate: DateTime(2026, 4, 1),
              dueDate: DateTime(2026, 4, 1),
              overduePolicy: ItemOverduePolicy.autoAdvance,
            ),
          ),
        ),
        isTrue,
      );

      final after = await repository.getItemById(itemId);
      expect(after, isNotNull);
      expect(after!.item.title, 'Pay rent updated');
      expect(after.item.description, 'new note');
      expect(
        (after.item.config as FixedItemConfig).anchorDate,
        DateTime(2026, 4, 1),
      );
      expect(
        (after.item.config as FixedItemConfig).dueDate,
        DateTime(2026, 4, 1),
      );
    },
  );

  test('updateItem stores customized attention policy source', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final repository = ItemRepository(db.reminderDao);

    final itemId = await repository.createItem(
      ItemInput(
        title: 'Replace filter',
        type: ItemType.stateBased,
        config: const StateBasedItemConfig(
          warningAfter: Duration(days: 7),
          dangerAfter: Duration(days: 14),
        ),
      ),
    );

    expect(
      await repository.updateItem(
        itemId,
        ItemInput(
          title: 'Replace filter',
          type: ItemType.stateBased,
          attentionPolicySource: AttentionPolicySource.userCustomized,
          config: const StateBasedItemConfig(
            warningAfter: Duration(days: 5),
            dangerAfter: Duration(days: 9),
          ),
        ),
      ),
      isTrue,
    );

    final updated = await repository.getItemById(itemId);
    expect(
      updated!.item.attentionPolicySource,
      AttentionPolicySource.userCustomized,
    );
    final config = updated.item.config as StateBasedItemConfig;
    expect(config.warningAfter, const Duration(days: 5));
    expect(config.dangerAfter, const Duration(days: 9));
  });

  test('fixed custom schedule fields round-trip through repository', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final repository = ItemRepository(db.reminderDao);

    final itemId = await repository.createItem(
      ItemInput(
        title: 'Water plants',
        type: ItemType.fixed,
        config: FixedItemConfig(
          scheduleType: FixedScheduleType.everyXWeeks,
          scheduleInterval: 2,
          anchorDate: DateTime(2026, 4, 1),
          dueDate: DateTime(2026, 4, 14),
        ),
      ),
    );

    final item = await repository.getItemById(itemId);
    final config = item!.item.config as FixedItemConfig;
    expect(config.scheduleType, FixedScheduleType.everyXWeeks);
    expect(config.scheduleInterval, 2);
    expect(config.anchorDate, DateTime(2026, 4, 1));
    expect(config.dueDate, DateTime(2026, 4, 14));

    expect(
      await repository.updateItem(
        itemId,
        ItemInput(
          title: 'Water plants',
          type: ItemType.fixed,
          config: FixedItemConfig(
            scheduleType: FixedScheduleType.monthly,
            scheduleInterval: 1,
            monthlyDay: 31,
            anchorDate: DateTime(2026, 1, 31),
            dueDate: DateTime(2026, 1, 31),
          ),
        ),
      ),
      isTrue,
    );

    final updated = await repository.getItemById(itemId);
    final updatedConfig = updated!.item.config as FixedItemConfig;
    expect(updatedConfig.scheduleType, FixedScheduleType.monthly);
    expect(updatedConfig.monthlyDay, 31);
  });

  test('fixed due-only item stores anchor date equal to due date', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final repository = ItemRepository(db.reminderDao);

    final itemId = await repository.createItem(
      ItemInput(
        title: 'Pay rent',
        type: ItemType.fixed,
        config: FixedItemConfig(
          scheduleType: FixedScheduleType.weekly,
          anchorDate: DateTime(2026, 4, 8),
          dueDate: DateTime(2026, 4, 8),
        ),
      ),
    );

    final config =
        (await repository.getItemById(itemId))!.item.config as FixedItemConfig;
    expect(config.anchorDate, DateTime(2026, 4, 8));
    expect(config.dueDate, DateTime(2026, 4, 8));
  });

  test('fixed lead-window item stores anchor date before due date', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final repository = ItemRepository(db.reminderDao);

    final itemId = await repository.createItem(
      ItemInput(
        title: 'Prepare payment',
        type: ItemType.fixed,
        config: FixedItemConfig(
          scheduleType: FixedScheduleType.weekly,
          anchorDate: DateTime(2026, 4, 5),
          dueDate: DateTime(2026, 4, 8),
        ),
      ),
    );

    final config =
        (await repository.getItemById(itemId))!.item.config as FixedItemConfig;
    expect(config.anchorDate, DateTime(2026, 4, 5));
    expect(config.dueDate, DateTime(2026, 4, 8));
  });

  test('fixed overlapping schedule is blocked on create and update', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final repository = ItemRepository(db.reminderDao);

    await expectLater(
      repository.createItem(
        ItemInput(
          title: 'Too long window',
          type: ItemType.fixed,
          config: FixedItemConfig(
            scheduleType: FixedScheduleType.weekly,
            anchorDate: DateTime(2026, 4, 1),
            dueDate: DateTime(2026, 4, 8),
          ),
        ),
      ),
      throwsA(
        isA<StateError>().having(
          (error) => error.message,
          'message',
          FixedScheduleValidator.overlapErrorMessage,
        ),
      ),
    );

    final itemId = await repository.createItem(
      ItemInput(
        title: 'Valid window',
        type: ItemType.fixed,
        config: FixedItemConfig(
          scheduleType: FixedScheduleType.weekly,
          anchorDate: DateTime(2026, 4, 5),
          dueDate: DateTime(2026, 4, 8),
        ),
      ),
    );

    await expectLater(
      repository.updateItem(
        itemId,
        ItemInput(
          title: 'Invalid update',
          type: ItemType.fixed,
          config: FixedItemConfig(
            scheduleType: FixedScheduleType.weekly,
            anchorDate: DateTime(2026, 4, 1),
            dueDate: DateTime(2026, 4, 8),
          ),
        ),
      ),
      throwsA(isA<StateError>()),
    );
  });

  test(
    'fixed monthly overlap uses next anchor date instead of 30-day count',
    () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);
      final repository = ItemRepository(db.reminderDao);

      await expectLater(
        repository.createItem(
          ItemInput(
            title: 'Month end task',
            type: ItemType.fixed,
            config: FixedItemConfig(
              scheduleType: FixedScheduleType.monthly,
              scheduleInterval: 1,
              monthlyDay: 31,
              anchorDate: DateTime(2026, 1, 2),
              dueDate: DateTime(2026, 1, 31),
            ),
          ),
        ),
        throwsA(
          isA<StateError>().having(
            (error) => error.message,
            'message',
            FixedScheduleValidator.overlapErrorMessage,
          ),
        ),
      );

      final itemId = await repository.createItem(
        ItemInput(
          title: 'Month end valid task',
          type: ItemType.fixed,
          config: FixedItemConfig(
            scheduleType: FixedScheduleType.monthly,
            scheduleInterval: 1,
            monthlyDay: 31,
            anchorDate: DateTime(2026, 1, 4),
            dueDate: DateTime(2026, 1, 31),
          ),
        ),
      );
      expect(await repository.getItemById(itemId), isNotNull);
    },
  );

  test(
    'fixed advanced repeat rule persists and advances after completion',
    () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);
      final repository = ItemRepository(db.reminderDao);

      final itemId = await repository.createItem(
        ItemInput(
          title: 'Medication',
          type: ItemType.fixed,
          config: FixedItemConfig(
            scheduleType: FixedScheduleType.weekly,
            repeatRuleV2: RepeatRuleV2.weeklyWeekdays(
              interval: 2,
              weekdays: const [DateTime.wednesday],
              end: const RepeatEndCondition.afterCount(2),
            ),
            anchorDate: DateTime(2026, 4, 1),
            dueDate: DateTime(2026, 4, 1),
          ),
        ),
      );

      final created = await repository.getItemById(itemId);
      final createdConfig = created!.item.config as FixedItemConfig;
      expect(createdConfig.repeatRuleV2, isNotNull);
      expect(createdConfig.repeatRuleV2!.weekdays, [DateTime.wednesday]);

      expect(
        await repository.markDone(itemId, doneAt: DateTime(2026, 4, 1)),
        isTrue,
      );

      final updated = await repository.getItemById(itemId);
      final updatedConfig = updated!.item.config as FixedItemConfig;
      expect(updatedConfig.dueDate, DateTime(2026, 4, 15));
      expect(updatedConfig.anchorDate, DateTime(2026, 4, 15));
      expect(updatedConfig.repeatRuleV2!.completedCount, 1);
    },
  );

  test('fixed repeat completion preserves lead window in next cycle', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final repository = ItemRepository(db.reminderDao);

    final itemId = await repository.createItem(
      ItemInput(
        title: 'Prepare medication',
        type: ItemType.fixed,
        config: FixedItemConfig(
          scheduleType: FixedScheduleType.weekly,
          repeatRuleV2: RepeatRuleV2.simple(unit: RepeatUnit.week, interval: 1),
          anchorDate: DateTime(2026, 4, 6),
          dueDate: DateTime(2026, 4, 8),
        ),
      ),
    );

    expect(
      await repository.markDone(itemId, doneAt: DateTime(2026, 4, 8)),
      isTrue,
    );

    final updated = await repository.getItemById(itemId);
    final config = updated!.item.config as FixedItemConfig;
    expect(config.dueDate, DateTime(2026, 4, 15));
    expect(config.anchorDate, DateTime(2026, 4, 13));
  });

  test(
    'create, update, and archive pack round-trip with visibility rules',
    () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);
      final repository = ItemRepository(db.reminderDao);

      final packId = await repository.createPack(
        const ItemPackInput(title: 'Cat Care', description: 'Cleaning duties'),
      );

      final created = await repository.getPackById(packId);
      expect(created, isNotNull);
      expect(created!.status, ItemPackStatus.active);
      expect(created.isSystemDefault, isFalse);

      final updated = await repository.updatePack(
        packId,
        const ItemPackInput(
          title: 'Cat Care Updated',
          description: 'Feeding and cleanup',
        ),
      );
      expect(updated, isTrue);

      final renamed = await repository.getPackById(packId);
      expect(renamed!.title, 'Cat Care Updated');

      expect(await repository.canArchivePack(packId), isTrue);
      expect(await repository.archivePack(packId), isTrue);

      final activePacks = await repository.watchPacks().first;
      final allPacks = await repository.watchPacks(includeArchived: true).first;

      expect(activePacks.any((item) => item.id == packId), isFalse);
      expect(
        allPacks.firstWhere((item) => item.id == packId).status,
        ItemPackStatus.archived,
      );
    },
  );

  test(
    'createItemWithOptionalNewPack creates pack and item in one call',
    () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);
      final repository = ItemRepository(db.reminderDao);

      final itemId = await repository.createItemWithOptionalNewPack(
        item: ItemInput(
          title: 'Sweep floor',
          type: ItemType.stateBased,
          config: const StateBasedItemConfig(
            infoAfter: Duration(days: 1),
            warningAfter: Duration(days: 1),
            dangerAfter: Duration(days: 2),
          ),
        ),
        newPack: const ItemPackInput(title: 'Housework'),
      );

      final item = await repository.getItemById(itemId);
      final packs = await repository.watchPacks(includeArchived: true).first;
      final history = await repository.listActionHistory(itemId);
      expect(item, isNotNull);
      expect(item!.pack.title, 'Housework');
      expect(packs.where((pack) => pack.title == 'Housework'), hasLength(1));
      expect(history.single.actionType, ItemActionType.created);
    },
  );

  test(
    'createItemWithOptionalNewPack uses existing pack when no new pack is passed',
    () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);
      final repository = ItemRepository(db.reminderDao);

      final packId = await repository.createPack(
        const ItemPackInput(title: 'Cat Care'),
      );
      final itemId = await repository.createItemWithOptionalNewPack(
        item: ItemInput(
          title: 'Clean bowl',
          type: ItemType.stateBased,
          config: const StateBasedItemConfig(
            infoAfter: Duration(days: 1),
            warningAfter: Duration(days: 1),
            dangerAfter: Duration(days: 2),
          ),
          packId: packId,
        ),
      );

      final item = await repository.getItemById(itemId);
      final history = await repository.listActionHistory(itemId);
      expect(item, isNotNull);
      expect(item!.pack.id, packId);
      expect(item.pack.title, 'Cat Care');
      expect(history.single.actionType, ItemActionType.created);
    },
  );

  test(
    'createItem creates existing resource binding in same transaction',
    () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);
      final repository = ItemRepository(db.reminderDao);
      final resourceRepository = ResourceRepository(db.reminderDao);

      final packId = await repository.createPack(
        const ItemPackInput(title: 'Housework'),
      );
      final resourceId = await resourceRepository.createResource(
        ResourceInput(
          title: 'Water filter',
          type: ResourceType.quantityBased,
          config: const QuantityBasedResourceConfig(
            currentQuantity: 5,
            unitLabel: '個',
            warningThreshold: 2,
            dangerThreshold: 1,
          ),
          packId: packId,
        ),
      );

      final itemId = await repository.createItem(
        ItemInput(
          title: 'Replace filter',
          type: ItemType.stateBased,
          config: const StateBasedItemConfig(
            warningAfter: Duration(days: 12),
            dangerAfter: Duration(days: 14),
          ),
          packId: packId,
        ),
        resourceBindings: [
          ItemResourceBindingInput.existing(resourceId: resourceId),
        ],
      );

      final rules = await resourceRepository.listRulesForItem(itemId);
      expect(rules, hasLength(1));
      expect(rules.single.resourceId, resourceId);
      expect(rules.single.consumeAmount, 1);
    },
  );

  test(
    'createItemWithOptionalNewPack creates quantity resource and binding',
    () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);
      final repository = ItemRepository(db.reminderDao);
      final resourceRepository = ResourceRepository(db.reminderDao);

      final itemId = await repository.createItemWithOptionalNewPack(
        item: const ItemInput(
          title: 'Replace filter',
          type: ItemType.stateBased,
          config: StateBasedItemConfig(
            warningAfter: Duration(days: 12),
            dangerAfter: Duration(days: 14),
          ),
        ),
        newPack: const ItemPackInput(title: 'Water'),
        resourceBindings: const [
          ItemResourceBindingInput.newResource(
            resource: ResourceInput(
              title: 'Water filter',
              type: ResourceType.quantityBased,
              config: QuantityBasedResourceConfig(
                currentQuantity: 5,
                unitLabel: '個',
                warningThreshold: 2,
                dangerThreshold: 1,
              ),
            ),
          ),
        ],
      );

      final rules = await resourceRepository.listRulesForItem(itemId);
      final resources = await resourceRepository.watchResources().first;
      final resource = resources.singleWhere(
        (bundle) => bundle.resource.title == 'Water filter',
      );
      final history = await resourceRepository.listActionHistory(
        resource.resource.id,
      );
      expect(rules, hasLength(1));
      expect(rules.single.resourceId, resource.resource.id);
      expect(resource.pack.title, 'Water');
      expect(
        history.any(
          (record) => record.actionType == ResourceActionType.created,
        ),
        isTrue,
      );
    },
  );

  test(
    'createItem resource binding failure rolls back item creation',
    () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);
      final repository = ItemRepository(db.reminderDao);
      final resourceRepository = ResourceRepository(db.reminderDao);

      final itemPackId = await repository.createPack(
        const ItemPackInput(title: 'Items'),
      );
      final resourcePackId = await repository.createPack(
        const ItemPackInput(title: 'Resources'),
      );
      final resourceId = await resourceRepository.createResource(
        ResourceInput(
          title: 'Filter',
          type: ResourceType.quantityBased,
          config: const QuantityBasedResourceConfig(
            currentQuantity: 5,
            unitLabel: '個',
            warningThreshold: 2,
            dangerThreshold: 1,
          ),
          packId: resourcePackId,
        ),
      );
      final beforeItems = await repository.watchPackManagementItems().first;

      await expectLater(
        repository.createItem(
          ItemInput(
            title: 'Replace filter',
            type: ItemType.stateBased,
            config: const StateBasedItemConfig(
              warningAfter: Duration(days: 12),
              dangerAfter: Duration(days: 14),
            ),
            packId: itemPackId,
          ),
          resourceBindings: [
            ItemResourceBindingInput.existing(resourceId: resourceId),
          ],
        ),
        throwsStateError,
      );

      final afterItems = await repository.watchPackManagementItems().first;
      final rules = await db.select(db.resourceConsumptionRules).get();
      expect(resourcePackId, greaterThan(0));
      expect(afterItems.length, beforeItems.length);
      expect(rules, isEmpty);
    },
  );

  test('archived quantity resource is not consumed by markDone', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final repository = ItemRepository(db.reminderDao);
    final resourceRepository = ResourceRepository(db.reminderDao);

    final itemId = await repository.createItem(
      const ItemInput(
        title: 'Replace filter',
        type: ItemType.stateBased,
        config: StateBasedItemConfig(
          warningAfter: Duration(days: 12),
          dangerAfter: Duration(days: 14),
        ),
      ),
    );
    final resourceId = await resourceRepository.createResource(
      const ResourceInput(
        title: 'Filter',
        type: ResourceType.quantityBased,
        config: QuantityBasedResourceConfig(
          currentQuantity: 5,
          unitLabel: '個',
          warningThreshold: 2,
          dangerThreshold: 1,
        ),
      ),
    );
    await resourceRepository.createConsumptionRule(
      ResourceConsumptionRuleInput(itemId: itemId, resourceId: resourceId),
    );
    expect(await resourceRepository.archiveResource(resourceId), isTrue);

    await repository.markDone(itemId, doneAt: DateTime(2026, 4, 5));

    final resource = await resourceRepository.getResourceById(resourceId);
    final history = await resourceRepository.listActionHistory(resourceId);
    expect(
      (resource!.resource.config as QuantityBasedResourceConfig)
          .currentQuantity,
      5,
    );
    expect(
      history.any((record) => record.actionType == ResourceActionType.consumed),
      isFalse,
    );
  });

  test('system default pack cannot be edited or archived', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final repository = ItemRepository(db.reminderDao);

    final defaultPack =
        (await repository.watchPacks(includeArchived: true).first).singleWhere(
          (item) => item.isSystemDefault,
        );

    expect(
      await repository.updatePack(
        defaultPack.id,
        const ItemPackInput(title: 'Renamed'),
      ),
      isFalse,
    );
    expect(await repository.canArchivePack(defaultPack.id), isFalse);
    expect(await repository.archivePack(defaultPack.id), isFalse);
  });

  test(
    'watchItems and pack management queries filter item lifecycle',
    () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);
      final repository = ItemRepository(db.reminderDao);

      final activeId = await repository.createItem(
        ItemInput(
          title: 'Active item',
          type: ItemType.stateBased,
          config: const StateBasedItemConfig(
            infoAfter: Duration(days: 1),
            warningAfter: Duration(days: 1),
            dangerAfter: Duration(days: 2),
          ),
        ),
      );
      final pausedId = await repository.createItem(
        ItemInput(
          title: 'Paused item',
          type: ItemType.stateBased,
          config: const StateBasedItemConfig(
            infoAfter: Duration(days: 1),
            warningAfter: Duration(days: 1),
            dangerAfter: Duration(days: 2),
          ),
        ),
      );
      final archivedId = await repository.createItem(
        ItemInput(
          title: 'Archived item',
          type: ItemType.stateBased,
          config: const StateBasedItemConfig(
            infoAfter: Duration(days: 1),
            warningAfter: Duration(days: 1),
            dangerAfter: Duration(days: 2),
          ),
        ),
      );

      expect(await repository.pauseItem(pausedId), isTrue);
      expect(await repository.archiveItem(archivedId), isTrue);

      final activeItems = await repository.watchItems().first;
      final managedItems = await repository.watchPackManagementItems().first;

      expect(activeItems.map((item) => item.item.title), ['Active item']);
      expect(managedItems.map((item) => item.item.title), [
        'Paused item',
        'Active item',
      ]);
      expect(await repository.resumeItem(activeId), isFalse);
    },
  );

  test('archivePack archives items inside the pack', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final repository = ItemRepository(db.reminderDao);

    final packId = await repository.createPack(
      const ItemPackInput(title: 'Food'),
    );
    final activeId = await repository.createItem(
      ItemInput(
        title: 'Refill bowls',
        type: ItemType.stateBased,
        config: const StateBasedItemConfig(
          infoAfter: Duration(days: 1),
          warningAfter: Duration(days: 1),
          dangerAfter: Duration(days: 2),
        ),
        packId: packId,
      ),
    );
    final pausedId = await repository.createItem(
      ItemInput(
        title: 'Clean storage',
        type: ItemType.stateBased,
        config: const StateBasedItemConfig(
          infoAfter: Duration(days: 1),
          warningAfter: Duration(days: 1),
          dangerAfter: Duration(days: 2),
        ),
        packId: packId,
      ),
    );

    expect(await repository.pauseItem(pausedId), isTrue);
    expect(await repository.countPackManagedItems(packId), 2);
    expect(await repository.archivePack(packId), isTrue);

    final archivedPack = await repository.getPackById(packId);
    final activeItems = await repository.watchItems().first;
    final managedItems = await repository.watchPackManagementItems().first;
    final archivedActive = await repository.getItemById(activeId);
    final archivedPaused = await repository.getItemById(pausedId);

    expect(archivedPack!.status, ItemPackStatus.archived);
    expect(activeItems.where((item) => item.item.packId == packId), isEmpty);
    expect(managedItems.where((item) => item.item.packId == packId), isEmpty);
    expect(archivedActive!.item.status, ItemLifecycleStatus.archived);
    expect(archivedPaused!.item.status, ItemLifecycleStatus.archived);
  });

  test(
    'activity feed returns recent and older major actions with search',
    () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);
      var now = DateTime(2026, 4, 1, 9, 0);
      final repository = ItemRepository(db.reminderDao, clock: () => now);

      final packId = await repository.createPack(
        const ItemPackInput(title: 'Cat Care'),
      );
      final foodId = await repository.createItem(
        ItemInput(
          title: 'Cat food',
          type: ItemType.stateBased,
          packId: packId,
          config: StateBasedItemConfig(
            warningAfter: Duration(days: 1),
            dangerAfter: Duration(days: 2),
          ),
        ),
      );

      now = DateTime(2026, 4, 2, 9, 0);
      final litterId = await repository.createItem(
        ItemInput(
          title: 'Clean litter',
          type: ItemType.stateBased,
          config: const StateBasedItemConfig(
            infoAfter: Duration(days: 1),
            warningAfter: Duration(days: 1),
            dangerAfter: Duration(days: 2),
          ),
        ),
      );

      await repository.markDone(litterId, doneAt: DateTime(2026, 4, 10));
      await repository.skip(litterId, actionAt: DateTime(2026, 4, 20));

      now = DateTime(2026, 5, 1, 9, 0);
      await repository.markDone(foodId, doneAt: DateTime(2026, 5, 1));

      final recentFeed = await repository.listActivityFeed(
        now: DateTime(2026, 5, 1),
        recentDays: 30,
      );
      final olderFeed = await repository.listActivityFeed(
        now: DateTime(2026, 5, 1),
        actionDateBefore: DateTime(2026, 4, 2),
      );
      final packSearch = await repository.listActivityFeed(
        now: DateTime(2026, 5, 1),
        recentDays: 30,
        query: 'Cat Care',
      );
      final actionSearch = await repository.listActivityFeed(
        now: DateTime(2026, 5, 1),
        recentDays: 30,
        query: '跳過',
      );
      final itemSearch = await repository.listActivityFeed(
        now: DateTime(2026, 5, 1),
        recentDays: 30,
        query: 'litter',
      );

      expect(
        recentFeed.map((entry) => entry.record.actionType),
        everyElement(isIn(ItemRepository.majorActivityActionTypes)),
      );
      expect(recentFeed.map((entry) => entry.itemTitle), contains('Cat food'));
      expect(recentFeed.map((entry) => entry.packTitle), contains('Cat Care'));
      expect(
        recentFeed.any(
          (entry) =>
              entry.record.actionType == ItemActionType.skipped &&
              entry.record.actionDate == DateTime(2026, 4, 20),
        ),
        isTrue,
      );
      expect(
        recentFeed.any(
          (entry) => entry.record.actionDate == DateTime(2026, 4, 1),
        ),
        isFalse,
      );
      expect(
        olderFeed.any(
          (entry) => entry.record.actionDate == DateTime(2026, 4, 1),
        ),
        isTrue,
      );
      expect(packSearch.map((entry) => entry.packTitle).toSet(), {'Cat Care'});
      expect(actionSearch.map((entry) => entry.record.actionType).toSet(), {
        ItemActionType.skipped,
      });
      expect(itemSearch.map((entry) => entry.itemTitle).toSet(), {
        'Clean litter',
      });
    },
  );
}
