import 'package:drift/native.dart';
import 'package:drift/drift.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reminder_app/features/reminders/data/item_repository.dart';
import 'package:reminder_app/features/reminders/data/local/app_database.dart';
import 'package:reminder_app/features/reminders/data/local/reminder_dao.dart';
import 'package:reminder_app/features/reminders/domain/attention_policy.dart';
import 'package:reminder_app/features/reminders/domain/item.dart';
import 'package:reminder_app/features/reminders/domain/item_pack.dart';
import 'package:reminder_app/features/reminders/domain/resource.dart';
import 'package:reminder_app/features/reminders/presentation/text/reminder_ui_text.dart';
import 'package:reminder_app/features/reminders/providers/item_providers.dart';
import 'package:reminder_app/features/reminders/providers/resource_providers.dart';
import 'package:reminder_app/features/reminders/providers/settings_providers.dart';
import 'package:reminder_app/features/reminders/ui/pages/item_edit_page.dart';

void main() {
  testWidgets('create page uses editor form shell and Chinese basic fields', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ..._emptyResourceOverrides(),
          reminderToneProvider.overrideWith((ref) => ReminderTone.standard),
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
        child: const MaterialApp(home: ItemEditPage(mode: ItemEditMode.create)),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('editor-bottom-save-bar')), findsOneWidget);
    expect(find.byKey(const Key('cancel-button')), findsNothing);
    expect(find.byKey(const Key('editor-section-basic-info')), findsOneWidget);
    expect(find.text(ReminderUiText.basicInfoSectionTitle), findsOneWidget);
    expect(find.text(ReminderUiText.itemTitleFieldLabel), findsOneWidget);
    expect(find.text(ReminderUiText.itemNoteFieldLabel), findsOneWidget);
    expect(find.text('Title'), findsNothing);
    expect(find.text('Note'), findsNothing);
    expect(find.byKey(const Key('pack-picker-row')), findsOneWidget);
    expect(find.byKey(const Key('item-type-field')), findsNothing);
    expect(find.byKey(const Key('item-type-fixed-card')), findsOneWidget);
    expect(find.byKey(const Key('item-type-state-based-card')), findsOneWidget);
    expect(find.byKey(const Key('warning-after-field')), findsNothing);
    expect(find.byKey(const Key('danger-after-field')), findsNothing);
    expect(
      find.byKey(const Key('editor-section-resource-binding')),
      findsNothing,
    );
  });

  testWidgets('create page fits iPhone 15 width smoke test', (tester) async {
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ..._emptyResourceOverrides(),
          reminderToneProvider.overrideWith((ref) => ReminderTone.standard),
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
        child: const MaterialApp(home: ItemEditPage(mode: ItemEditMode.create)),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), null);
  });

  testWidgets('item editor toggles fields by item type', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ..._emptyResourceOverrides(),
          reminderToneProvider.overrideWith((ref) => ReminderTone.standard),
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

    expect(find.byKey(const Key('item-type-field')), findsNothing);
    expect(find.byKey(const Key('item-type-state-based-card')), findsOneWidget);
    expect(find.byKey(const Key('item-type-fixed-card')), findsOneWidget);
    expect(find.byKey(const Key('pack-picker-row')), findsOneWidget);

    await tester.tap(find.byKey(const Key('pack-picker-row')));
    await tester.pumpAndSettle();
    expect(find.text('Default Item Pack'), findsNothing);
    expect(find.text('🏷️ Cat Care').last, findsOneWidget);
    await tester.tap(find.text('🏷️ Cat Care').last);
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.byKey(const Key('expected-interval-field')),
      120,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('state-anchor-date-row')), findsOneWidget);
    expect(find.byKey(const Key('expected-interval-field')), findsOneWidget);
    expect(find.byKey(const Key('warning-after-field')), findsNothing);
    expect(find.byKey(const Key('danger-after-field')), findsNothing);
    expect(find.byKey(const Key('estimated-duration-field')), findsNothing);

    await tester.drag(find.byType(ListView), const Offset(0, 500));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('item-type-fixed-card')));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(const Key('fixed-repeat-row')),
      120,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(find.text('庫存'), findsNothing);
    expect(find.byKey(const Key('resource-danger-before-field')), findsNothing);
    expect(find.text(ReminderUiText.repeatRuleLabel), findsOneWidget);
    expect(find.byKey(const Key('fixed-anchor-date-row')), findsOneWidget);
    expect(find.byKey(const Key('fixed-due-date-row')), findsOneWidget);
    expect(find.byKey(const Key('fixed-overdue-policy-row')), findsOneWidget);
    expect(find.byKey(const Key('fixed-warning-before-field')), findsNothing);
    expect(find.byKey(const Key('fixed-danger-before-field')), findsNothing);
  });

  testWidgets('fixed repeat row opens custom stepper and updates summary', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ..._emptyResourceOverrides(),
          reminderToneProvider.overrideWith((ref) => ReminderTone.standard),
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
        child: const MaterialApp(home: ItemEditPage(mode: ItemEditMode.create)),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('item-type-fixed-card')));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(const Key('fixed-repeat-row')),
      120,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('fixed-repeat-row')), findsOneWidget);
    expect(
      find.byKey(const Key('fixed-schedule-interval-field')),
      findsNothing,
    );
    expect(find.text('每 X 天'), findsNothing);
    expect(find.text(ReminderUiText.repeatRuleLabel), findsOneWidget);
    expect(find.text('每天'), findsOneWidget);

    await tester.tap(find.byKey(const Key('fixed-anchor-date-row')));
    await tester.pumpAndSettle();
    expect(find.byType(DatePickerDialog), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('fixed-repeat-row')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('repeat-option-custom')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('repeat-interval-increment')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('repeat-interval-increment')));
    await tester.pumpAndSettle();
    expect(find.text('3 天'), findsOneWidget);
    expect(find.text('完成後， 3 天再次出現。'), findsNothing);
    expect(find.text('完成後 3 天再次出現。'), findsOneWidget);

    await tester.tap(find.byKey(const Key('repeat-save-custom')));
    await tester.pumpAndSettle();

    expect(find.text('每 3 天'), findsOneWidget);
  });

  testWidgets('editor loads existing state-based item', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ..._emptyResourceOverrides(),
          reminderToneProvider.overrideWith((ref) => ReminderTone.standard),
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

    expect(find.byKey(const Key('editor-bottom-save-bar')), findsOneWidget);
    expect(find.byKey(const Key('cancel-button')), findsNothing);
    expect(find.text('Weekly grooming'), findsOneWidget);
    expect(find.text('Brush and trim'), findsOneWidget);
    expect(find.text('2026/04/01'), findsOneWidget);
    expect(find.byKey(const Key('expected-interval-field')), findsOneWidget);
    expect(
      tester
          .widget<TextFormField>(
            find.byKey(const Key('expected-interval-field')),
          )
          .controller!
          .text,
      '14',
    );
    expect(find.byKey(const Key('danger-after-field')), findsNothing);
    expect(find.byKey(const Key('pack-picker-row')), findsNothing);
    expect(find.byKey(const Key('pack-readonly')), findsOneWidget);
    expect(find.text('📌 一般'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.byKey(const Key('editor-section-toggle-advanced-settings')),
      120,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const Key('editor-section-toggle-advanced-settings')),
      findsOneWidget,
    );
  });

  testWidgets('editor keeps archived current pack visible while editing', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ..._emptyResourceOverrides(),
          reminderToneProvider.overrideWith((ref) => ReminderTone.standard),
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
                  type: ItemType.stateBased,
                  config: StateBasedItemConfig(
                    anchorDate: DateTime(2026, 4, 1),
                    warningAfter: Duration(days: 7),
                    dangerAfter: Duration(days: 14),
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

    expect(
      find.text('🏷️ Archived Pack (${ReminderUiText.archivedPackSuffix})'),
      findsOneWidget,
    );
  });

  testWidgets('locked pack mode hides pack field and saves into locked pack', (
    tester,
  ) async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final repository = ItemRepository(db.reminderDao);
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
          ..._emptyResourceOverrides(),
          itemRepositoryProvider.overrideWith((ref) => repository),
          reminderToneProvider.overrideWith((ref) => ReminderTone.standard),
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

    expect(find.byKey(const Key('pack-picker-row')), findsNothing);

    await tester.enterText(find.byType(TextFormField).first, 'Locked item');
    await tester.scrollUntilVisible(
      find.byKey(const Key('expected-interval-field')),
      120,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('expected-interval-field')),
      '21',
    );
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.byKey(const Key('save-button')));
    await tester.pump(const Duration(milliseconds: 300));

    final items = (await tester.runAsync(() => db.select(db.items).get()))!;
    expect(items.single.title, 'Locked item');
    expect(items.single.packId, 1);
    expect(items.single.stateWarningAfterMinutes, Duration(days: 17).inMinutes);
    expect(items.single.stateDangerAfterMinutes, Duration(days: 21).inMinutes);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets('create flow uses global reminder tone when deriving policy', (
    tester,
  ) async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final repository = ItemRepository(db.reminderDao);
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

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ..._emptyResourceOverrides(),
          itemRepositoryProvider.overrideWith((ref) => repository),
          reminderToneProvider.overrideWith((ref) => ReminderTone.urgent),
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
          home: ItemEditPage(mode: ItemEditMode.create, lockedPackId: 1),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await tester.enterText(find.byType(TextFormField).first, 'Urgent item');
    await tester.scrollUntilVisible(
      find.byKey(const Key('expected-interval-field')),
      120,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('expected-interval-field')),
      '21',
    );
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.byKey(const Key('save-button')));
    await tester.pump(const Duration(milliseconds: 300));

    final item = (await tester.runAsync(() => repository.getItemById(1)))!.item;
    final config = item.config as StateBasedItemConfig;
    expect(config.warningAfter, const Duration(days: 13));
    expect(config.dangerAfter, const Duration(days: 19));
    expect(item.attentionPolicySource, AttentionPolicySource.systemDefault);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets('advanced policy section saves custom thresholds and source', (
    tester,
  ) async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final repository = ItemRepository(db.reminderDao);
    final itemId = await repository.createItem(
      ItemInput(
        title: 'Custom attention',
        type: ItemType.stateBased,
        config: StateBasedItemConfig(
          anchorDate: DateTime(2026, 4, 1),
          warningAfter: const Duration(days: 7),
          dangerAfter: const Duration(days: 14),
        ),
      ),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ..._emptyResourceOverrides(),
          itemRepositoryProvider.overrideWith((ref) => repository),
          reminderToneProvider.overrideWith((ref) => ReminderTone.standard),
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
        child: MaterialApp(
          home: ItemEditPage(mode: ItemEditMode.edit, id: itemId),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('warning-after-field')), findsNothing);
    await tester.scrollUntilVisible(
      find.byKey(const Key('editor-section-toggle-advanced-settings')),
      120,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const Key('editor-section-toggle-advanced-settings')),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(
      find.byKey(const Key('attention-policy-custom-switch')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('attention-policy-custom-switch')));
    await tester.pumpAndSettle();

    expect(find.text(ReminderUiText.warningTimingLabel), findsOneWidget);
    expect(find.text(ReminderUiText.dangerTimingLabel), findsOneWidget);
    await tester.enterText(
      find.byKey(const Key('attention-warning-field')),
      '5',
    );
    await tester.enterText(
      find.byKey(const Key('attention-danger-field')),
      '9',
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('save-button')));
    await tester.pump(const Duration(milliseconds: 300));

    final updated = (await tester.runAsync(
      () => repository.getItemById(itemId),
    ))!.item;
    final config = updated.config as StateBasedItemConfig;
    expect(updated.attentionPolicySource, AttentionPolicySource.userCustomized);
    expect(config.warningAfter, const Duration(days: 5));
    expect(config.dangerAfter, const Duration(days: 9));

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets('advanced policy can switch back to system default derivation', (
    tester,
  ) async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final repository = ItemRepository(db.reminderDao);
    final itemId = await repository.createItem(
      ItemInput(
        title: 'Return to default',
        type: ItemType.stateBased,
        attentionPolicySource: AttentionPolicySource.userCustomized,
        config: StateBasedItemConfig(
          anchorDate: DateTime(2026, 4, 1),
          warningAfter: const Duration(days: 5),
          dangerAfter: const Duration(days: 9),
        ),
      ),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ..._emptyResourceOverrides(),
          itemRepositoryProvider.overrideWith((ref) => repository),
          reminderToneProvider.overrideWith((ref) => ReminderTone.standard),
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
        child: MaterialApp(
          home: ItemEditPage(mode: ItemEditMode.edit, id: itemId),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('expected-interval-field')),
      '21',
    );
    await tester.scrollUntilVisible(
      find.byKey(const Key('editor-section-toggle-advanced-settings')),
      120,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const Key('editor-section-toggle-advanced-settings')),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(
      find.byKey(const Key('attention-policy-custom-switch')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('attention-policy-custom-switch')));
    await tester.pumpAndSettle();
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('save-button')));
    await tester.pump(const Duration(milliseconds: 300));

    final updated = (await tester.runAsync(
      () => repository.getItemById(itemId),
    ))!.item;
    final config = updated.config as StateBasedItemConfig;
    expect(updated.attentionPolicySource, AttentionPolicySource.systemDefault);
    expect(config.warningAfter, const Duration(days: 17));
    expect(config.dangerAfter, const Duration(days: 21));

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets('locked pack edit hides pack field and loads item data', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ..._emptyResourceOverrides(),
          reminderToneProvider.overrideWith((ref) => ReminderTone.standard),
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

    expect(find.byKey(const Key('pack-picker-row')), findsNothing);
    expect(find.byKey(const Key('pack-readonly')), findsOneWidget);
    expect(find.text('Weekly grooming'), findsOneWidget);
    expect(find.text('Brush and trim'), findsOneWidget);
    expect(find.byKey(const Key('item-type-field')), findsNothing);
    expect(find.byKey(const Key('item-type-readonly')), findsOneWidget);
  });

  testWidgets('editor keeps fixed item stored dates instead of preview cycle', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ..._emptyResourceOverrides(),
          reminderToneProvider.overrideWith((ref) => ReminderTone.standard),
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
                  title: 'Daily item',
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
        child: const MaterialApp(
          home: ItemEditPage(mode: ItemEditMode.edit, id: 10),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('2026/04/01'), findsNWidgets(2));
    expect(find.text('2026/04/03'), findsNothing);
  });

  testWidgets('edit resource consumption renders compact editor rows', (
    tester,
  ) async {
    final pack = ItemPack(
      id: 1,
      title: 'Default Item Pack',
      status: ItemPackStatus.active,
      isSystemDefault: true,
      createdAt: DateTime(2026, 4, 1),
      updatedAt: DateTime(2026, 4, 1),
    );
    final resource = Resource(
      id: 9,
      packId: pack.id,
      title: 'Water filter',
      type: ResourceType.quantityBased,
      config: const QuantityBasedResourceConfig(
        currentQuantity: 5,
        unitLabel: '個',
        warningThreshold: 2,
        dangerThreshold: 1,
      ),
      createdAt: DateTime(2026, 4, 1),
      updatedAt: DateTime(2026, 4, 1),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          reminderToneProvider.overrideWith((ref) => ReminderTone.standard),
          activeItemPacksProvider.overrideWith((ref) => Stream.value([pack])),
          resourcesProvider.overrideWith(
            (ref) =>
                Stream.value([ResourceBundle(resource: resource, pack: pack)]),
          ),
          itemConsumptionRulesProvider.overrideWith(
            (ref, itemId) => Stream.value([
              ResourceConsumptionRule(
                id: 3,
                resourceId: resource.id,
                itemId: 10,
                consumeAmount: 2,
                createdAt: DateTime(2026, 4, 1),
                updatedAt: DateTime(2026, 4, 1),
              ),
            ]),
          ),
          itemProvider(10).overrideWith(
            (ref) => Future.value(
              ItemBundle(
                item: Item(
                  id: 10,
                  packId: pack.id,
                  title: 'Daily item',
                  type: ItemType.fixed,
                  config: FixedItemConfig(
                    scheduleType: FixedScheduleType.daily,
                    anchorDate: DateTime(2026, 4, 1),
                    dueDate: DateTime(2026, 4, 1),
                  ),
                  createdAt: DateTime(2026, 4, 1),
                  updatedAt: DateTime(2026, 4, 1),
                ),
                pack: pack,
              ),
            ),
          ),
        ],
        child: const MaterialApp(
          home: ItemEditPage(mode: ItemEditMode.edit, id: 10),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.byKey(const Key('editor-section-toggle-resource-consumption')),
      120,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(
      find.byKey(const Key('editor-section-toggle-resource-consumption')),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('resource-consumption-section')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('resource-consumption-row-0')), findsOneWidget);
    expect(find.text('Water filter'), findsOneWidget);
    expect(
      find.text('${ReminderUiText.resourceBindingConsumePrefix} 2 個'),
      findsOneWidget,
    );
  });

  testWidgets('locked fixed item edit also keeps stored dates', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ..._emptyResourceOverrides(),
          reminderToneProvider.overrideWith((ref) => ReminderTone.standard),
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
                  title: 'Locked daily item',
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
        child: const MaterialApp(
          home: ItemEditPage(mode: ItemEditMode.edit, id: 11, lockedPackId: 1),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('pack-picker-row')), findsNothing);
    expect(find.byKey(const Key('pack-readonly')), findsOneWidget);
    expect(find.byKey(const Key('item-type-readonly')), findsOneWidget);
    expect(find.text('2026/04/01'), findsNWidgets(2));
    expect(find.text('2026/04/03'), findsNothing);
  });

  testWidgets('edit back exits immediately when there are no changes', (
    tester,
  ) async {
    await _pumpEditableItemRoute(tester);

    expect(find.byKey(const Key('cancel-button')), findsNothing);
    await tester.pageBack();
    await tester.pumpAndSettle();

    expect(find.text('Home'), findsOneWidget);
    expect(find.text(ReminderUiText.discardChangesTitle), findsNothing);
  });

  testWidgets('edit back asks before discarding changes', (tester) async {
    await _pumpEditableItemRoute(tester);

    await tester.enterText(find.byKey(const Key('title-field')), 'Changed');
    await tester.pumpAndSettle();
    await tester.pageBack();
    await tester.pumpAndSettle();

    expect(find.text(ReminderUiText.discardChangesTitle), findsOneWidget);
    await tester.tap(find.widgetWithText(TextButton, 'Cancel'));
    await tester.pumpAndSettle();
    expect(find.text(ReminderUiText.itemEditorEditTitle), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.text(ReminderUiText.discardChangesAction));
    await tester.pumpAndSettle();

    expect(find.text('Home'), findsOneWidget);
  });

  testWidgets('system back asks before discarding edited item changes', (
    tester,
  ) async {
    await _pumpEditableItemRoute(tester);

    await tester.enterText(find.byKey(const Key('note-field')), 'Changed note');
    await tester.pumpAndSettle();
    await tester.pageBack();
    await tester.pumpAndSettle();

    expect(find.text(ReminderUiText.discardChangesTitle), findsOneWidget);
    await tester.tap(find.text(ReminderUiText.discardChangesAction));
    await tester.pumpAndSettle();

    expect(find.text('Home'), findsOneWidget);
  });

  testWidgets('edit page still renders when target item no longer exists', (
    tester,
  ) async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final repository = ItemRepository(db.reminderDao);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ..._emptyResourceOverrides(),
          itemRepositoryProvider.overrideWith((ref) => repository),
          reminderToneProvider.overrideWith((ref) => ReminderTone.standard),
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

    expect(find.text(ReminderUiText.itemEditorEditTitle), findsOneWidget);
    expect(find.byKey(const Key('title-field')), findsOneWidget);
  });

  testWidgets('create page records existing resource binding only on save', (
    tester,
  ) async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final repository = _RecordingCreateItemRepository(db.reminderDao);
    final pack = ItemPack(
      id: 1,
      title: 'Default Item Pack',
      status: ItemPackStatus.active,
      isSystemDefault: true,
      createdAt: DateTime(2026, 4, 1),
      updatedAt: DateTime(2026, 4, 1),
    );
    final resource = Resource(
      id: 7,
      packId: pack.id,
      title: 'Water filter',
      type: ResourceType.quantityBased,
      config: const QuantityBasedResourceConfig(
        currentQuantity: 5,
        unitLabel: '個',
        warningThreshold: 2,
        dangerThreshold: 1,
      ),
      createdAt: DateTime(2026, 4, 1),
      updatedAt: DateTime(2026, 4, 1),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          itemRepositoryProvider.overrideWith((ref) => repository),
          reminderToneProvider.overrideWith((ref) => ReminderTone.standard),
          activeItemPacksProvider.overrideWith((ref) => Stream.value([pack])),
          resourcesProvider.overrideWith(
            (ref) =>
                Stream.value([ResourceBundle(resource: resource, pack: pack)]),
          ),
        ],
        child: const MaterialApp(home: ItemEditPage(mode: ItemEditMode.create)),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('title-field')),
      'Replace filter',
    );
    await tester.scrollUntilVisible(
      find.byKey(const Key('editor-section-toggle-resource-binding')),
      120,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const Key('editor-section-toggle-resource-binding')),
    );
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView), const Offset(0, -300));
    await tester.pump();
    await tester.ensureVisible(
      find.byKey(const Key('add-resource-binding-draft-button')),
    );
    final addBindingButton = tester.widget<TextButton>(
      find.byKey(const Key('add-resource-binding-draft-button')),
    );
    expect(
      find.text(ReminderUiText.resourceBindingEmptySummary),
      findsOneWidget,
    );
    addBindingButton.onPressed!();
    await tester.pumpAndSettle();
    expect(repository.recordedBindings, null);

    await tester.tap(find.byKey(const Key('resource-binding-save-button')));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(const Key('resource-binding-summary')),
      120,
      scrollable: find.byType(Scrollable).first,
    );
    expect(
      find.text('1 ${ReminderUiText.resourceBindingCountSuffix}'),
      findsOneWidget,
    );
    await tester.scrollUntilVisible(
      find.byKey(const Key('resource-binding-row-0')),
      120,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.byKey(const Key('resource-binding-row-0')), findsOneWidget);
    expect(find.text('Water filter'), findsOneWidget);
    expect(
      find.text('${ReminderUiText.resourceBindingConsumePrefix} 1 個'),
      findsOneWidget,
    );

    await tester.drag(find.byType(ListView), const Offset(0, -600));
    await tester.pump();
    await tester.tap(find.byKey(const Key('save-button')));
    await tester.pumpAndSettle();

    expect(repository.recordedInput?.title, 'Replace filter');
    expect(repository.recordedBindings, hasLength(1));
    expect(repository.recordedBindings!.single.existingResourceId, resource.id);
  });
}

List<Override> _emptyResourceOverrides() {
  return [
    resourcesProvider.overrideWith(
      (ref) => Stream.value(const <ResourceBundle>[]),
    ),
    itemConsumptionRulesProvider.overrideWith(
      (ref, itemId) => Stream.value(const <ResourceConsumptionRule>[]),
    ),
  ];
}

class _RecordingCreateItemRepository extends ItemRepository {
  _RecordingCreateItemRepository(super.dao);

  ItemInput? recordedInput;
  List<ItemResourceBindingInput>? recordedBindings;

  @override
  Future<int> createItem(
    ItemInput input, {
    List<ItemResourceBindingInput> resourceBindings = const [],
  }) async {
    recordedInput = input;
    recordedBindings = resourceBindings;
    return 42;
  }
}

Future<void> _pumpEditableItemRoute(WidgetTester tester) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        ..._emptyResourceOverrides(),
        reminderToneProvider.overrideWith((ref) => ReminderTone.standard),
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
        itemProvider(21).overrideWith(
          (ref) => Future.value(
            ItemBundle(
              item: Item(
                id: 21,
                packId: 1,
                title: 'Editable item',
                description: 'Original note',
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
      child: MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              key: const Key('open-editor'),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (context) =>
                        const ItemEditPage(mode: ItemEditMode.edit, id: 21),
                  ),
                );
              },
              child: const Text('Home'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const Key('open-editor')));
  await tester.pumpAndSettle();
}
