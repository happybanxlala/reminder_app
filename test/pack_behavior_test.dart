import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reminder_app/features/reminders/data/item_repository.dart';
import 'package:reminder_app/features/reminders/data/local/app_database.dart';
import 'package:reminder_app/features/reminders/data/resource_repository.dart';
import 'package:reminder_app/features/reminders/data/stage_tracker_models.dart';
import 'package:reminder_app/features/reminders/data/stage_tracker_repository.dart';
import 'package:reminder_app/features/reminders/domain/item.dart';
import 'package:reminder_app/features/reminders/domain/item_pack.dart';
import 'package:reminder_app/features/reminders/domain/resource.dart';
import 'package:reminder_app/features/reminders/domain/stage_tracker.dart';

void main() {
  test('system default pack exists and cannot be archived', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final repository = ItemRepository(db.reminderDao);

    final packs = await repository.watchPacks(includeArchived: true).first;

    expect(packs.single.title, '一般');
    expect(packs.single.iconEmoji, '📌');
    expect(packs.single.isSystemDefault, isTrue);
    expect(await repository.canArchivePack(packs.single.id), isFalse);
    expect(await repository.archivePackWithContents(packs.single.id), isFalse);
  });

  test('create flows without selected pack use default pack', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final itemRepository = ItemRepository(db.reminderDao);
    final resourceRepository = ResourceRepository(db.reminderDao);
    final stageRepository = StageTrackerRepository(db.reminderDao);

    final itemId = await itemRepository.createItem(
      const ItemInput(
        title: 'Clean fridge',
        type: ItemType.stateBased,
        config: StateBasedItemConfig(
          warningAfter: Duration(days: 7),
          dangerAfter: Duration(days: 14),
        ),
      ),
    );
    final resourceId = await resourceRepository.createResource(
      const ResourceInput(
        title: 'Shampoo',
        type: ResourceType.quantityBased,
        config: QuantityBasedResourceConfig(
          currentQuantity: 1,
          unitLabel: '瓶',
          warningThreshold: 1,
          dangerThreshold: 0,
        ),
      ),
    );
    final trackerId = await stageRepository.createStageTracker(
      StageTrackerInput(title: '寶寶成長', trackingStartDate: DateTime(2026, 5, 1)),
    );

    final defaultPack = (await itemRepository.watchPacks().first).singleWhere(
      (pack) => pack.isSystemDefault,
    );
    final item = await itemRepository.getItemById(itemId);
    final resource = await resourceRepository.getResourceById(resourceId);
    final tracker = await stageRepository.getStageTrackerById(trackerId);

    expect(item!.item.packId, defaultPack.id);
    expect(resource!.resource.packId, defaultPack.id);
    expect(tracker!.packId, defaultPack.id);
  });

  test('stage tracker packId is required at database level', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);

    await expectLater(
      db.customStatement('''
        INSERT INTO stage_trackers (
          title,
          tracking_start_date,
          status,
          created_at,
          updated_at
        ) VALUES ('Missing pack', 1, 'active', 1, 1)
        '''),
      throwsA(isA<SqliteException>()),
    );
  });

  test('custom packs reorder while default stays first', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final repository = ItemRepository(db.reminderDao);

    final cats = await repository.createPack(
      const ItemPackInput(title: '養貓', iconEmoji: '🐱'),
    );
    await repository.createPack(
      const ItemPackInput(title: '家務', iconEmoji: '🏠'),
    );
    final health = await repository.createPack(
      const ItemPackInput(title: '健康', iconEmoji: '🩺'),
    );

    expect(await repository.movePackUp(health), isTrue);
    expect(await repository.movePackDown(cats), isTrue);

    final packs = await repository.watchPacks().first;
    expect(packs.first.title, '一般');
    expect(packs.map((pack) => pack.title), ['一般', '健康', '養貓', '家務']);
  });

  test('archive custom pack with contents archives children', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final itemRepository = ItemRepository(db.reminderDao);
    final resourceRepository = ResourceRepository(db.reminderDao);
    final stageRepository = StageTrackerRepository(db.reminderDao);
    final packId = await itemRepository.createPack(
      const ItemPackInput(title: '家務', iconEmoji: '🏠'),
    );
    final itemId = await itemRepository.createItem(
      ItemInput(
        title: 'Clean sink',
        type: ItemType.stateBased,
        config: const StateBasedItemConfig(
          warningAfter: Duration(days: 3),
          dangerAfter: Duration(days: 5),
        ),
        packId: packId,
      ),
    );
    final pausedItemId = await itemRepository.createItem(
      ItemInput(
        title: 'Paused chore',
        type: ItemType.stateBased,
        config: const StateBasedItemConfig(
          warningAfter: Duration(days: 3),
          dangerAfter: Duration(days: 5),
        ),
        packId: packId,
      ),
    );
    await itemRepository.pauseItem(pausedItemId);
    final resourceId = await resourceRepository.createResource(
      ResourceInput(
        title: 'Soap',
        type: ResourceType.quantityBased,
        config: const QuantityBasedResourceConfig(
          currentQuantity: 1,
          unitLabel: '個',
          warningThreshold: 1,
          dangerThreshold: 0,
        ),
        packId: packId,
      ),
    );
    final trackerId = await stageRepository.createStageTracker(
      StageTrackerInput(
        title: 'Maintenance',
        trackingStartDate: DateTime(2026, 5, 1),
        packId: packId,
      ),
    );

    expect(await itemRepository.archivePackWithContents(packId), isTrue);

    expect(
      (await itemRepository.getItemById(itemId))!.item.status,
      ItemLifecycleStatus.archived,
    );
    expect(
      (await itemRepository.getItemById(pausedItemId))!.item.status,
      ItemLifecycleStatus.archived,
    );
    expect(
      (await resourceRepository.getResourceById(resourceId))!.resource.status,
      ResourceLifecycleStatus.archived,
    );
    expect(
      (await stageRepository.getStageTrackerById(trackerId))!.status,
      StageTrackerStatus.archived,
    );
    expect(await itemRepository.listActionHistory(itemId), isNotEmpty);
  });

  test(
    'archive and move contents to default preserves child lifecycle',
    () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);
      final itemRepository = ItemRepository(db.reminderDao);
      final resourceRepository = ResourceRepository(db.reminderDao);
      final stageRepository = StageTrackerRepository(db.reminderDao);
      final packId = await itemRepository.createPack(
        const ItemPackInput(title: '健康', iconEmoji: '🩺'),
      );
      final itemId = await itemRepository.createItem(
        ItemInput(
          title: 'Stretch',
          type: ItemType.stateBased,
          config: const StateBasedItemConfig(
            warningAfter: Duration(days: 1),
            dangerAfter: Duration(days: 2),
          ),
          packId: packId,
        ),
      );
      await itemRepository.pauseItem(itemId);
      final resourceId = await resourceRepository.createResource(
        ResourceInput(
          title: 'Vitamin',
          type: ResourceType.quantityBased,
          config: const QuantityBasedResourceConfig(
            currentQuantity: 5,
            unitLabel: '粒',
            warningThreshold: 2,
            dangerThreshold: 1,
          ),
          packId: packId,
        ),
      );
      final trackerId = await stageRepository.createStageTracker(
        StageTrackerInput(
          title: 'Recovery',
          trackingStartDate: DateTime(2026, 5, 1),
          packId: packId,
        ),
      );

      expect(
        await itemRepository.archivePackAndMoveContentsToDefault(packId),
        isTrue,
      );

      final defaultPack = (await itemRepository.watchPacks().first).singleWhere(
        (pack) => pack.isSystemDefault,
      );
      final item = await itemRepository.getItemById(itemId);
      final resource = await resourceRepository.getResourceById(resourceId);
      final tracker = await stageRepository.getStageTrackerById(trackerId);
      expect(item!.item.packId, defaultPack.id);
      expect(item.item.status, ItemLifecycleStatus.paused);
      expect(resource!.resource.packId, defaultPack.id);
      expect(resource.resource.status, ResourceLifecycleStatus.active);
      expect(tracker!.packId, defaultPack.id);
      expect(tracker.status, StageTrackerStatus.active);
    },
  );
}
