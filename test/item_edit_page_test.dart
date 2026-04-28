import 'package:drift/native.dart';
import 'package:drift/drift.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reminder_app/features/reminders/data/item_repository.dart';
import 'package:reminder_app/features/reminders/data/local/app_database.dart';
import 'package:reminder_app/features/reminders/data/local/item_timeline_dao.dart';
import 'package:reminder_app/features/reminders/domain/item.dart';
import 'package:reminder_app/features/reminders/domain/item_pack.dart';
import 'package:reminder_app/features/reminders/presentation/text/reminder_ui_text.dart';
import 'package:reminder_app/features/reminders/providers/developer_settings_providers.dart';
import 'package:reminder_app/features/reminders/providers/item_providers.dart';
import 'package:reminder_app/features/reminders/ui/pages/item_edit_page.dart';

void main() {
  testWidgets('item editor toggles fields by item type', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          activeItemPacksProvider.overrideWith(
            (ref) => Stream.value([
              ItemPack(
                id: 1,
                title: 'Default Item Pack',
                status: ItemPackStatus.active,
                isSystemDefault: true,
                createdAt: DateTime(2026, 4, 1),
                updatedAt: DateTime(2026, 4, 1),
              ),
              ItemPack(
                id: 2,
                title: 'Cat Care',
                status: ItemPackStatus.active,
                isSystemDefault: false,
                createdAt: DateTime(2026, 4, 1),
                updatedAt: DateTime(2026, 4, 2),
              ),
            ]),
          ),
        ],
        child: MaterialApp(home: ItemEditPage(mode: ItemEditMode.create)),
      ),
    );
    await tester.pump();

    expect(find.byKey(const Key('state-anchor-date-field')), findsOneWidget);
    expect(find.byKey(const Key('warning-after-field')), findsOneWidget);
    expect(find.byKey(const Key('estimated-duration-field')), findsNothing);
    expect(find.byKey(const Key('pack-field')), findsOneWidget);

    await tester.tap(find.text(ItemType.stateBased.name));
    await tester.pumpAndSettle();
    await tester.tap(find.text(ItemType.resourceBased.name).last);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('warning-after-field')), findsNothing);
    expect(find.byKey(const Key('estimated-duration-field')), findsOneWidget);
  });

  testWidgets('editor loads existing state-based item', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          activeItemPacksProvider.overrideWith(
            (ref) => Stream.value([
              ItemPack(
                id: 1,
                title: 'Default Item Pack',
                status: ItemPackStatus.active,
                isSystemDefault: true,
                createdAt: DateTime(2026, 4, 1),
                updatedAt: DateTime(2026, 4, 2),
              ),
            ]),
          ),
          itemProvider(7).overrideWith(
            (ref) => Future.value(
              ItemBundle(
                item: Item(
                  id: 7,
                  packId: 1,
                  title: 'Weekly grooming',
                  description: 'Brush and trim',
                  type: ItemType.stateBased,
                  config: StateBasedItemConfig(
                    anchorDate: DateTime(2026, 4, 1),
                    infoAfter: Duration(days: 7),
                    warningAfter: Duration(days: 7),
                    dangerAfter: Duration(days: 14),
                  ),
                  createdAt: DateTime(2026, 4, 1),
                  updatedAt: DateTime(2026, 4, 2),
                ),
                pack: ItemPack(
                  id: 1,
                  title: 'Default Item Pack',
                  status: ItemPackStatus.active,
                  isSystemDefault: true,
                  createdAt: DateTime(2026, 4, 1),
                  updatedAt: DateTime(2026, 4, 2),
                ),
              ),
            ),
          ),
        ],
        child: const MaterialApp(
          home: ItemEditPage(mode: ItemEditMode.edit, id: 7),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Weekly grooming'), findsOneWidget);
    expect(find.text('Brush and trim'), findsOneWidget);
    expect(find.text('7'), findsWidgets);
    expect(find.text('2026/04/01'), findsOneWidget);
    expect(find.byKey(const Key('danger-after-field')), findsOneWidget);
    expect(find.text('Default Item Pack (系統預設)'), findsOneWidget);
  });

  testWidgets('editor keeps archived current pack visible while editing', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          activeItemPacksProvider.overrideWith(
            (ref) => Stream.value([
              ItemPack(
                id: 1,
                title: 'Active Pack',
                status: ItemPackStatus.active,
                isSystemDefault: false,
                createdAt: DateTime(2026, 4, 1),
                updatedAt: DateTime(2026, 4, 2),
              ),
            ]),
          ),
          itemProvider(8).overrideWith(
            (ref) => Future.value(
              ItemBundle(
                item: Item(
                  id: 8,
                  packId: 2,
                  title: 'Archived owner',
                  type: ItemType.resourceBased,
                  config: ResourceBasedItemConfig(
                    anchorDate: DateTime(2026, 4, 1),
                    durationDays: 30,
                    warningBefore: 7,
                  ),
                  createdAt: DateTime(2026, 4, 1),
                  updatedAt: DateTime(2026, 4, 2),
                ),
                pack: ItemPack(
                  id: 2,
                  title: 'Archived Pack',
                  status: ItemPackStatus.archived,
                  isSystemDefault: false,
                  createdAt: DateTime(2026, 4, 1),
                  updatedAt: DateTime(2026, 4, 2),
                ),
              ),
            ),
          ),
        ],
        child: const MaterialApp(
          home: ItemEditPage(mode: ItemEditMode.edit, id: 8),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Archived Pack (archived)'), findsOneWidget);
  });

  testWidgets('locked pack mode hides pack field and saves into locked pack', (
    tester,
  ) async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final repository = ItemRepository(db.itemTimelineDao);
    final now = DateTime(2026, 4, 1).millisecondsSinceEpoch;

    await db
        .into(db.itemPacks)
        .insert(
          ItemPacksCompanion.insert(
            title: 'Default Item Pack',
            status: const Value('active'),
            isSystemDefault: const Value(true),
            createdAt: now,
            updatedAt: now,
          ),
        );
    await repository.createPack(
      const ItemPackInput(title: 'Cat Care', description: 'Other pack'),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          itemRepositoryProvider.overrideWith((ref) => repository),
          activeItemPacksProvider.overrideWith(
            (ref) => Stream.value([
              ItemPack(
                id: 1,
                title: 'Default Item Pack',
                status: ItemPackStatus.active,
                isSystemDefault: true,
                createdAt: DateTime(2026, 4, 1),
                updatedAt: DateTime(2026, 4, 1),
              ),
              ItemPack(
                id: 2,
                title: 'Cat Care',
                status: ItemPackStatus.active,
                isSystemDefault: false,
                createdAt: DateTime(2026, 4, 1),
                updatedAt: DateTime(2026, 4, 1),
              ),
            ]),
          ),
        ],
        child: const MaterialApp(
          home: ItemEditPage(mode: ItemEditMode.create, lockedPackId: 1),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('pack-field')), findsNothing);

    await tester.enterText(find.byType(TextFormField).first, 'Locked item');
    await tester.ensureVisible(find.byKey(const Key('save-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('save-button')));
    await tester.pumpAndSettle();

    final items = await db.select(db.items).get();
    expect(items.single.title, 'Locked item');
    expect(items.single.packId, 1);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets('locked pack edit hides pack field and loads item data', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          activeItemPacksProvider.overrideWith(
            (ref) => Stream.value([
              ItemPack(
                id: 1,
                title: 'Default Item Pack',
                status: ItemPackStatus.active,
                isSystemDefault: true,
                createdAt: DateTime(2026, 4, 1),
                updatedAt: DateTime(2026, 4, 1),
              ),
            ]),
          ),
          itemProvider(9).overrideWith(
            (ref) => Future.value(
              ItemBundle(
                item: Item(
                  id: 9,
                  packId: 1,
                  title: 'Weekly grooming',
                  description: 'Brush and trim',
                  type: ItemType.stateBased,
                  config: StateBasedItemConfig(
                    anchorDate: DateTime(2026, 4, 1),
                    infoAfter: Duration(days: 7),
                    warningAfter: Duration(days: 7),
                    dangerAfter: Duration(days: 14),
                  ),
                  createdAt: DateTime(2026, 4, 1),
                  updatedAt: DateTime(2026, 4, 2),
                ),
                pack: ItemPack(
                  id: 1,
                  title: 'Default Item Pack',
                  status: ItemPackStatus.active,
                  isSystemDefault: true,
                  createdAt: DateTime(2026, 4, 1),
                  updatedAt: DateTime(2026, 4, 2),
                ),
              ),
            ),
          ),
        ],
        child: const MaterialApp(
          home: ItemEditPage(mode: ItemEditMode.edit, id: 9, lockedPackId: 1),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('pack-field')), findsNothing);
    expect(find.text('Weekly grooming'), findsOneWidget);
    expect(find.text('Brush and trim'), findsOneWidget);
  });

  testWidgets('editor resolves fixed cycle dates from preview snapshot', (
    tester,
  ) async {
    final container = ProviderContainer(
      overrides: [
        activeItemPacksProvider.overrideWith(
          (ref) => Stream.value([
            ItemPack(
              id: 1,
              title: 'Default Item Pack',
              status: ItemPackStatus.active,
              isSystemDefault: true,
              createdAt: DateTime(2026, 4, 1),
              updatedAt: DateTime(2026, 4, 2),
            ),
          ]),
        ),
        itemProvider(10).overrideWith(
          (ref) => Future.value(
            ItemBundle(
              item: Item(
                id: 10,
                packId: 1,
                title: 'Daily task',
                type: ItemType.fixed,
                config: FixedItemConfig(
                  scheduleType: FixedScheduleType.daily,
                  anchorDate: DateTime(2026, 4, 1),
                  dueDate: DateTime(2026, 4, 1),
                  overduePolicy: ItemOverduePolicy.autoAdvance,
                ),
                createdAt: DateTime(2026, 4, 1),
                updatedAt: DateTime(2026, 4, 2),
              ),
              pack: ItemPack(
                id: 1,
                title: 'Default Item Pack',
                status: ItemPackStatus.active,
                isSystemDefault: true,
                createdAt: DateTime(2026, 4, 1),
                updatedAt: DateTime(2026, 4, 2),
              ),
            ),
          ),
        ),
      ],
    );
    addTearDown(container.dispose);
    container.read(developerDateOverrideProvider.notifier).state = DateTime(
      2026,
      4,
      3,
    );

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: ItemEditPage(mode: ItemEditMode.edit, id: 10),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('2026/04/03'), findsNWidgets(2));
    expect(find.text('2026/04/01'), findsNothing);
  });

  testWidgets('locked fixed item edit also uses preview snapshot dates', (
    tester,
  ) async {
    final container = ProviderContainer(
      overrides: [
        activeItemPacksProvider.overrideWith(
          (ref) => Stream.value([
            ItemPack(
              id: 1,
              title: 'Default Item Pack',
              status: ItemPackStatus.active,
              isSystemDefault: true,
              createdAt: DateTime(2026, 4, 1),
              updatedAt: DateTime(2026, 4, 2),
            ),
          ]),
        ),
        itemProvider(11).overrideWith(
          (ref) => Future.value(
            ItemBundle(
              item: Item(
                id: 11,
                packId: 1,
                title: 'Locked daily task',
                type: ItemType.fixed,
                config: FixedItemConfig(
                  scheduleType: FixedScheduleType.daily,
                  anchorDate: DateTime(2026, 4, 1),
                  dueDate: DateTime(2026, 4, 1),
                  overduePolicy: ItemOverduePolicy.autoAdvance,
                ),
                createdAt: DateTime(2026, 4, 1),
                updatedAt: DateTime(2026, 4, 2),
              ),
              pack: ItemPack(
                id: 1,
                title: 'Default Item Pack',
                status: ItemPackStatus.active,
                isSystemDefault: true,
                createdAt: DateTime(2026, 4, 1),
                updatedAt: DateTime(2026, 4, 2),
              ),
            ),
          ),
        ),
      ],
    );
    addTearDown(container.dispose);
    container.read(developerDateOverrideProvider.notifier).state = DateTime(
      2026,
      4,
      3,
    );

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: ItemEditPage(mode: ItemEditMode.edit, id: 11, lockedPackId: 1),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('pack-field')), findsNothing);
    expect(find.text('2026/04/03'), findsNWidgets(2));
    expect(find.text('2026/04/01'), findsNothing);
  });

  testWidgets('edit page still renders when target item no longer exists', (
    tester,
  ) async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final repository = ItemRepository(db.itemTimelineDao);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          itemRepositoryProvider.overrideWith((ref) => repository),
          activeItemPacksProvider.overrideWith(
            (ref) => Stream.value([
              ItemPack(
                id: 1,
                title: 'Default Item Pack',
                status: ItemPackStatus.active,
                isSystemDefault: true,
                createdAt: DateTime(2026, 4, 1),
                updatedAt: DateTime(2026, 4, 1),
              ),
            ]),
          ),
        ],
        child: const MaterialApp(
          home: ItemEditPage(mode: ItemEditMode.edit, id: 404),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(ReminderUiText.editItem), findsOneWidget);
    expect(find.byKey(const Key('title-field')), findsOneWidget);
  });
}
