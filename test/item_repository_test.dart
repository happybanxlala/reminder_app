import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reminder_app/features/reminders/data/local/app_database.dart';
import 'package:reminder_app/features/reminders/data/item_repository.dart';
import 'package:reminder_app/features/reminders/domain/item.dart';
import 'package:reminder_app/features/reminders/domain/item_pack.dart';

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
    'markDone updates state anchor date and resets day index from day 1',
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
    'markDone uses preview date for state anchor date and real time for updatedAt',
    () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);
      final repository = ItemRepository(db.itemTimelineDao);

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

      await repository.markDone(itemId, doneAt: previewDate);

      final after = await repository.getItemById(itemId);
      expect(before, isNotNull);
      expect(after, isNotNull);
      expect(after!.item.lastDoneAt, isNull);
      expect(
        (after.item.config as StateBasedItemConfig).anchorDate,
        DateTime(2026, 4, 14),
      );
      expect(after.item.updatedAt, isNot(DateTime(2026, 4, 14)));
      expect(after.item.updatedAt.isBefore(before!.item.updatedAt), isFalse);
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

  test('resource-based completion requires added days', () async {
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
    expect(history.single.payload?['addedDays'], 9);
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

  test('resource-based items cannot be skipped', () async {
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
    expect(await repository.listActionHistory(itemId), isEmpty);
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

  test('archiving a pack cascades items to archived', () async {
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
}
