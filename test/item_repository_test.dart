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
            expectedInterval: Duration(days: 2),
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

  test('markDone updates lastDoneAt and clears danger state', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final repository = ItemRepository(db.itemTimelineDao);

    final itemId = await repository.createItem(
      ItemInput(
        title: 'Refill water fountain',
        type: ItemType.stateBased,
        config: const StateBasedItemConfig(
          expectedInterval: Duration(days: 1),
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
    expect(after.item.lastDoneAt, DateTime(2026, 4, 14));
    expect(
      repository.statusFor(after.item, now: DateTime(2026, 4, 15)),
      ItemStatus.warning,
    );
  });

  test('watchItemsByStatus filters items by computed status', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final repository = ItemRepository(db.itemTimelineDao);

    await repository.createItem(
      ItemInput(
        title: 'Change pee pad',
        type: ItemType.stateBased,
        config: const StateBasedItemConfig(
          expectedInterval: Duration(days: 1),
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
          expectedInterval: Duration(days: 3),
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
            expectedInterval: Duration(days: 1),
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
            expectedInterval: Duration(days: 1),
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
            expectedInterval: Duration(days: 1),
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
          expectedInterval: Duration(days: 1),
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
          expectedInterval: Duration(days: 1),
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
