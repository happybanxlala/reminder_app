import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reminder_app/features/reminders/data/local/app_database.dart';
import 'package:reminder_app/features/reminders/data/item_repository.dart';
import 'package:reminder_app/features/reminders/domain/item_action_record.dart';
import 'package:reminder_app/features/reminders/domain/item.dart';
import 'package:reminder_app/features/reminders/domain/item_pack.dart';
import 'package:reminder_app/features/reminders/domain/item_pack_template.dart';

void main() {
  test(
    'creating an item provisions the default pack and round-trips mapping',
    () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);
      final repository = ItemRepository(db.itemTimelineDao);

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
      expect(packs.single.title, 'Default Item Pack');
      expect(packs.single.status, ItemPackStatus.active);
      expect(packs.single.isSystemDefault, isTrue);
      expect(item!.pack.id, packs.single.id);
      expect(item.item.title, 'Clean litter box');
      expect(item.item.status, ItemLifecycleStatus.active);
      expect(item.item.type, ItemType.stateBased);
      expect(item.item.config, isA<StateBasedItemConfig>());
      expect(history, hasLength(1));
      expect(history.single.actionType, ItemActionType.created);
    },
  );

  test('state-based anchor date seeds initial baseline snapshot', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final repository = ItemRepository(db.itemTimelineDao);

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
      final repository = ItemRepository(db.itemTimelineDao);

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
      final repository = ItemRepository(db.itemTimelineDao, clock: () => now);

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
    final repository = ItemRepository(db.itemTimelineDao);

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

  test('markDone(resourceBased, addedDays) updates refill snapshot', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final repository = ItemRepository(db.itemTimelineDao);

    final itemId = await repository.createItem(
      ItemInput(
        title: 'Cat food',
        type: ItemType.resourceBased,
        config: ResourceBasedItemConfig(
          anchorDate: DateTime(2026, 4, 1),
          durationDays: 5,
          warningBefore: 1,
        ),
      ),
    );

    expect(
      await repository.markDone(itemId, doneAt: DateTime(2026, 4, 5)),
      isFalse,
    );
    expect(
      await repository.markDone(
        itemId,
        doneAt: DateTime(2026, 4, 5),
        addedDays: 9,
      ),
      isTrue,
    );

    final item = await repository.getItemById(itemId);
    final history = await repository.listActionHistory(itemId);
    expect(item, isNotNull);
    expect(item!.item.lastDoneAt, DateTime(2026, 4, 5));
    expect(
      (item.item.config as ResourceBasedItemConfig).anchorDate,
      DateTime(2026, 4, 5),
    );
    expect((item.item.config as ResourceBasedItemConfig).durationDays, 10);
    final doneRecord = history.firstWhere(
      (record) => record.actionType == ItemActionType.done,
    );
    expect(doneRecord.payload?['addedDays'], 9);
  });

  test(
    'resource-based completion carries remaining days from completion day',
    () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);
      final repository = ItemRepository(db.itemTimelineDao);

      final itemId = await repository.createItem(
        ItemInput(
          title: 'Cat food',
          type: ItemType.resourceBased,
          config: ResourceBasedItemConfig(
            anchorDate: DateTime(2026, 4, 1),
            durationDays: 10,
            warningBefore: 1,
          ),
        ),
      );

      expect(
        await repository.markDone(
          itemId,
          doneAt: DateTime(2026, 4, 9),
          addedDays: 2,
        ),
        isTrue,
      );

      final item = await repository.getItemById(itemId);
      expect(item, isNotNull);
      expect(
        (item!.item.config as ResourceBasedItemConfig).anchorDate,
        DateTime(2026, 4, 9),
      );
      expect((item.item.config as ResourceBasedItemConfig).durationDays, 4);
    },
  );

  test(
    'resource-based completion after depletion starts new cycle on action day',
    () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);
      final repository = ItemRepository(db.itemTimelineDao);

      final itemId = await repository.createItem(
        ItemInput(
          title: 'Cat food',
          type: ItemType.resourceBased,
          config: ResourceBasedItemConfig(
            anchorDate: DateTime(2026, 4, 1),
            durationDays: 5,
            warningBefore: 1,
          ),
        ),
      );

      expect(
        await repository.markDone(
          itemId,
          doneAt: DateTime(2026, 4, 7),
          addedDays: 3,
        ),
        isTrue,
      );

      final item = await repository.getItemById(itemId);
      expect(item, isNotNull);
      expect(
        (item!.item.config as ResourceBasedItemConfig).anchorDate,
        DateTime(2026, 4, 7),
      );
      expect((item.item.config as ResourceBasedItemConfig).durationDays, 3);
    },
  );

  test('skip(resourceBased) must fail', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final repository = ItemRepository(db.itemTimelineDao);

    final itemId = await repository.createItem(
      ItemInput(
        title: 'Cat food',
        type: ItemType.resourceBased,
        config: ResourceBasedItemConfig(
          anchorDate: DateTime(2026, 4, 1),
          durationDays: 5,
          warningBefore: 1,
        ),
      ),
    );

    expect(
      await repository.skip(itemId, actionAt: DateTime(2026, 4, 5)),
      isFalse,
    );
    expect(
      (await repository.listActionHistory(
        itemId,
      )).where((record) => record.actionType != ItemActionType.created),
      isEmpty,
    );
  });

  test('defer is disabled and does not write action history', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final repository = ItemRepository(db.itemTimelineDao);

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
      final repository = ItemRepository(db.itemTimelineDao);

      final itemId = await repository.createItem(
        ItemInput(
          title: 'Cat food',
          type: ItemType.resourceBased,
          config: ResourceBasedItemConfig(
            anchorDate: DateTime(2026, 4, 1),
            durationDays: 5,
            warningBefore: 1,
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
      expect(after.item.type, ItemType.resourceBased);
    },
  );

  test(
    'updateItem preserves fixed stored dates when editing non-schedule fields',
    () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);
      final repository = ItemRepository(db.itemTimelineDao);

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

  test('fixed custom schedule fields round-trip through repository', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final repository = ItemRepository(db.itemTimelineDao);

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

  test(
    'create, update, and archive pack round-trip with visibility rules',
    () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);
      final repository = ItemRepository(db.itemTimelineDao);

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
      final repository = ItemRepository(db.itemTimelineDao);

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
      final repository = ItemRepository(db.itemTimelineDao);

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
    'applyTemplate creates a new pack with initialized item baselines',
    () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);
      final now = DateTime(2026, 4, 10, 9, 0);
      final repository = ItemRepository(db.itemTimelineDao, clock: () => now);

      final template = (await repository.watchTemplates().first).firstWhere(
        (template) => template.id == 'builtin-cat-care',
      );
      final packId = await repository.applyTemplate(template);

      final pack = await repository.getPackById(packId);
      final items = await repository.watchPackManagementItems().first;
      final packItems = items
          .where((bundle) => bundle.item.packId == packId)
          .toList(growable: false);

      expect(pack!.title, '彩月島貓奴指南(模版)');
      expect(packItems, hasLength(template.items.length));
      final water = packItems.firstWhere(
        (bundle) => bundle.item.title == '飲水機加水',
      );
      final waterConfig = water.item.config as FixedItemConfig;
      expect(waterConfig.scheduleType, FixedScheduleType.everyXDays);
      expect(waterConfig.scheduleInterval, 3);
      expect(waterConfig.anchorDate, DateTime(2026, 4, 10));
      expect(waterConfig.dueDate, DateTime(2026, 4, 12));

      final inventory = packItems.firstWhere(
        (bundle) => bundle.item.title == '補充貓乾糧',
      );
      final inventoryConfig = inventory.item.config as ResourceBasedItemConfig;
      expect(inventoryConfig.anchorDate, isNull);
      expect(inventoryConfig.durationDays, 0);
    },
  );

  test(
    'savePackAsTemplate stores managed items and delete removes it',
    () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);
      final repository = ItemRepository(db.itemTimelineDao);

      final packId = await repository.createPack(
        const ItemPackInput(title: 'Cat Care', description: 'Daily care'),
      );
      await repository.createItem(
        ItemInput(
          title: 'Brush teeth',
          description: 'Weekly',
          type: ItemType.stateBased,
          packId: packId,
          config: const StateBasedItemConfig(
            warningAfter: Duration(days: 7),
            dangerAfter: Duration(days: 10),
          ),
        ),
      );
      final archivedId = await repository.createItem(
        ItemInput(
          title: 'Old task',
          type: ItemType.stateBased,
          packId: packId,
          config: const StateBasedItemConfig(
            warningAfter: Duration(days: 1),
            dangerAfter: Duration(days: 2),
          ),
        ),
      );
      await repository.archiveItem(archivedId);

      final templateId = await repository.savePackAsTemplate(
        packId,
        const ItemPackTemplateInput(
          name: 'My cat template',
          category: '照料貓咪',
          description: 'Reusable',
        ),
      );

      expect(templateId, isNotNull);
      final templates = await repository.watchTemplates().first;
      final custom = templates.firstWhere(
        (template) => template.id == 'custom-$templateId',
      );
      expect(custom.source, ItemPackTemplateSource.custom);
      expect(custom.items.map((item) => item.title), ['Brush teeth']);

      expect(await repository.deleteCustomTemplate(custom.id), isTrue);
      final afterDelete = await repository.watchTemplates().first;
      expect(
        afterDelete.where((template) => template.id == custom.id),
        isEmpty,
      );
    },
  );

  test('system default pack cannot be edited or archived', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final repository = ItemRepository(db.itemTimelineDao);

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
      final repository = ItemRepository(db.itemTimelineDao);

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
    final repository = ItemRepository(db.itemTimelineDao);

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
      final repository = ItemRepository(db.itemTimelineDao, clock: () => now);

      final packId = await repository.createPack(
        const ItemPackInput(title: 'Cat Care'),
      );
      final foodId = await repository.createItem(
        ItemInput(
          title: 'Cat food',
          type: ItemType.resourceBased,
          packId: packId,
          config: ResourceBasedItemConfig(
            anchorDate: DateTime(2026, 4, 1),
            durationDays: 5,
            warningBefore: 1,
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
      await repository.markDone(
        foodId,
        doneAt: DateTime(2026, 5, 1),
        addedDays: 3,
      );

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
