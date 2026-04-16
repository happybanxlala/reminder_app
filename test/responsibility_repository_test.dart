import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reminder_app/features/reminders/data/local/app_database.dart';
import 'package:reminder_app/features/reminders/data/responsibility_repository.dart';
import 'package:reminder_app/features/reminders/domain/responsibility_item.dart';
import 'package:reminder_app/features/reminders/domain/responsibility_pack.dart';

void main() {
  test(
    'creating an item provisions the default pack and round-trips mapping',
    () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);
      final repository = ResponsibilityRepository(db.responsibilityTimelineDao);

      final itemId = await repository.createItem(
        ResponsibilityItemInput(
          title: 'Clean litter box',
          description: 'Cat hygiene',
          type: ResponsibilityItemType.stateBased,
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
      expect(packs.single.title, 'Default Responsibility Pack');
      expect(packs.single.status, ResponsibilityPackStatus.active);
      expect(packs.single.isSystemDefault, isTrue);
      expect(item!.pack.id, packs.single.id);
      expect(item.item.title, 'Clean litter box');
      expect(item.item.type, ResponsibilityItemType.stateBased);
      expect(item.item.config, isA<StateBasedItemConfig>());
    },
  );

  test('markDone updates lastDoneAt and clears danger state', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final repository = ResponsibilityRepository(db.responsibilityTimelineDao);

    final itemId = await repository.createItem(
      ResponsibilityItemInput(
        title: 'Refill water fountain',
        type: ResponsibilityItemType.stateBased,
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
      ResponsibilityItemStatus.unknown,
    );

    await repository.markDone(itemId, doneAt: DateTime(2026, 4, 14));

    final after = (await repository.watchItems().first).single;
    expect(after.item.lastDoneAt, DateTime(2026, 4, 14));
    expect(
      repository.statusFor(after.item, now: DateTime(2026, 4, 15)),
      ResponsibilityItemStatus.warning,
    );
  });

  test(
    'watchItemsByStatus filters responsibility items by computed status',
    () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);
      final repository = ResponsibilityRepository(db.responsibilityTimelineDao);

      await repository.createItem(
        ResponsibilityItemInput(
          title: 'Change pee pad',
          type: ResponsibilityItemType.stateBased,
          config: const StateBasedItemConfig(
            expectedInterval: Duration(days: 1),
            warningAfter: Duration(days: 1),
            dangerAfter: Duration(days: 2),
          ),
        ),
      );
      await repository.createItem(
        ResponsibilityItemInput(
          title: 'Brush cat',
          type: ResponsibilityItemType.stateBased,
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
          .watchItemsByStatus(
            ResponsibilityItemStatus.danger,
            now: DateTime(2026, 4, 15),
          )
          .first;
      final warning = await repository
          .watchItemsByStatus(
            ResponsibilityItemStatus.warning,
            now: DateTime(2026, 4, 15),
          )
          .first;

      expect(danger.map((item) => item.item.title), ['Change pee pad']);
      expect(warning.map((item) => item.item.title), ['Brush cat']);
    },
  );

  test(
    'create, update, and archive pack round-trip with visibility rules',
    () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);
      final repository = ResponsibilityRepository(db.responsibilityTimelineDao);

      final packId = await repository.createPack(
        const ResponsibilityPackInput(
          title: 'Cat Care',
          description: 'Cleaning duties',
        ),
      );

      final created = await repository.getPackById(packId);
      expect(created, isNotNull);
      expect(created!.status, ResponsibilityPackStatus.active);
      expect(created.isSystemDefault, isFalse);

      final updated = await repository.updatePack(
        packId,
        const ResponsibilityPackInput(
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
        ResponsibilityPackStatus.archived,
      );
    },
  );

  test('system default pack cannot be edited or archived', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final repository = ResponsibilityRepository(db.responsibilityTimelineDao);

    final defaultPack =
        (await repository.watchPacks(includeArchived: true).first).singleWhere(
          (item) => item.isSystemDefault,
        );

    expect(
      await repository.updatePack(
        defaultPack.id,
        const ResponsibilityPackInput(title: 'Renamed'),
      ),
      isFalse,
    );
    expect(await repository.canArchivePack(defaultPack.id), isFalse);
    expect(await repository.archivePack(defaultPack.id), isFalse);
  });

  test('non-empty pack cannot be archived', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final repository = ResponsibilityRepository(db.responsibilityTimelineDao);

    final packId = await repository.createPack(
      const ResponsibilityPackInput(title: 'Food'),
    );
    await repository.createItem(
      ResponsibilityItemInput(
        title: 'Refill bowls',
        type: ResponsibilityItemType.stateBased,
        config: const StateBasedItemConfig(
          expectedInterval: Duration(days: 1),
          warningAfter: Duration(days: 1),
          dangerAfter: Duration(days: 2),
        ),
        packId: packId,
      ),
    );

    expect(await repository.canArchivePack(packId), isFalse);
    expect(await repository.archivePack(packId), isFalse);
  });
}
