import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reminder_app/features/reminders/data/default_pack_templates.dart';
import 'package:reminder_app/features/reminders/data/item_repository.dart';
import 'package:reminder_app/features/reminders/data/local/app_database.dart';
import 'package:reminder_app/features/reminders/data/pack_template_repository.dart';
import 'package:reminder_app/features/reminders/data/resource_repository.dart';
import 'package:reminder_app/features/reminders/domain/item.dart';
import 'package:reminder_app/features/reminders/domain/item_pack.dart';
import 'package:reminder_app/features/reminders/domain/pack_template.dart';
import 'package:reminder_app/features/reminders/domain/resource.dart';

void main() {
  test(
    'default pack templates include expected templates and item configs',
    () {
      expect(defaultPackTemplates.map((template) => template.templateName), [
        '家務',
        '個人護理',
        '養貓',
      ]);
      expect(defaultPackTemplates[0].items, hasLength(5));
      expect(defaultPackTemplates[1].items, hasLength(5));
      expect(defaultPackTemplates[2].items, hasLength(6));
      for (final template in defaultPackTemplates) {
        expect(template.source, PackTemplateSource.defaultTemplate);
        for (final item in template.items) {
          expect(item.title.trim(), isNotEmpty);
          expect(item.config.type, item.type);
        }
      }
    },
  );

  test(
    'creating default templates creates exact pack names and no history',
    () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);
      final itemRepository = ItemRepository(
        db.reminderDao,
        clock: () => DateTime(2026, 5, 10, 12),
      );

      for (final template in defaultPackTemplates) {
        final result = await itemRepository.createPackFromTemplate(template);
        expect(result.packName, '${template.templateName}(模版)');
        expect(result.itemIds, hasLength(template.items.length));

        final pack = await itemRepository.getPackById(result.packId);
        expect(pack!.title, result.packName);
        expect(pack.iconEmoji, template.iconEmoji);

        for (final itemId in result.itemIds) {
          final bundle = await itemRepository.getItemById(itemId);
          expect(bundle, isNotNull);
          expect(bundle!.item.packId, result.packId);
          expect(bundle.item.config.type, bundle.item.type);
          expect(await itemRepository.listActionHistory(itemId), isEmpty);
          expect(
            await db.reminderDao.listConsumptionRulesForItem(itemId),
            isEmpty,
          );
        }
      }
    },
  );

  test('duplicate template pack names are allowed without suffix', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final itemRepository = ItemRepository(db.reminderDao);
    final template = defaultPackTemplates.first;

    await itemRepository.createPackFromTemplate(template);
    await itemRepository.createPackFromTemplate(template);

    final packs = await itemRepository.watchPacks().first;
    expect(packs.where((pack) => pack.title == '家務(模版)'), hasLength(2));
  });

  test(
    'custom template stores active item schedule and excludes bindings',
    () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);
      final itemRepository = ItemRepository(
        db.reminderDao,
        clock: () => DateTime(2026, 5, 10, 12),
      );
      final resourceRepository = ResourceRepository(db.reminderDao);
      final templateRepository = PackTemplateRepository(
        db.reminderDao,
        clock: () => DateTime(2026, 5, 10, 12),
      );
      final packId = await itemRepository.createPack(
        const ItemPackInput(
          title: '小咪照顧',
          iconEmoji: '🐱',
          description: '日常照顧',
        ),
      );
      final resourceId = await resourceRepository.createResource(
        ResourceInput(
          title: '貓砂',
          type: ResourceType.quantityBased,
          config: const QuantityBasedResourceConfig(
            currentQuantity: 5,
            unitLabel: '包',
            warningThreshold: 2,
            dangerThreshold: 1,
          ),
          packId: packId,
        ),
      );
      await itemRepository.createItem(
        ItemInput(
          title: '清貓砂',
          type: ItemType.fixed,
          config: const FixedItemConfig(
            scheduleType: FixedScheduleType.everyXDays,
            scheduleInterval: 2,
            warningBefore: Duration(days: 1),
          ),
          packId: packId,
        ),
        resourceBindings: [
          ItemResourceBindingInput.existing(resourceId: resourceId),
        ],
      );
      final archivedItemId = await itemRepository.createItem(
        ItemInput(
          title: '已封存',
          type: ItemType.stateBased,
          config: const StateBasedItemConfig(
            warningAfter: Duration(days: 1),
            dangerAfter: Duration(days: 2),
          ),
          packId: packId,
        ),
      );
      await itemRepository.archiveItem(archivedItemId);

      await templateRepository.savePackAsTemplate(
        packId: packId,
        templateName: '小咪照顧',
      );
      final custom = await templateRepository.watchCustomTemplates().first;

      expect(custom, hasLength(1));
      expect(custom.single.templateName, '小咪照顧');
      expect(custom.single.iconEmoji, '🐱');
      expect(custom.single.description, '日常照顧');
      expect(custom.single.items.map((item) => item.title), ['清貓砂']);
      expect(custom.single.items.single.config, isA<FixedItemConfig>());

      final created = await itemRepository.createPackFromTemplate(
        custom.single,
      );
      expect(created.packName, '小咪照顧(模版)');
      expect(created.itemIds, hasLength(1));
      expect(
        await db.reminderDao.listConsumptionRulesForItem(
          created.itemIds.single,
        ),
        isEmpty,
      );
      expect(
        await itemRepository.listActionHistory(created.itemIds.single),
        isEmpty,
      );
    },
  );

  test(
    'saving custom template rejects blank name and packs without active items',
    () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);
      final itemRepository = ItemRepository(db.reminderDao);
      final templateRepository = PackTemplateRepository(db.reminderDao);
      final packId = await itemRepository.createPack(
        const ItemPackInput(title: '空生活場景', iconEmoji: '🏷️'),
      );

      await expectLater(
        templateRepository.savePackAsTemplate(packId: packId, templateName: ''),
        throwsA(isA<StateError>()),
      );
      await expectLater(
        templateRepository.savePackAsTemplate(
          packId: packId,
          templateName: '空生活場景',
        ),
        throwsA(isA<StateError>()),
      );
    },
  );
}
