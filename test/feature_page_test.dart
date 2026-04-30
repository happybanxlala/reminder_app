import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:reminder_app/features/reminders/data/item_repository.dart';
import 'package:reminder_app/features/reminders/data/local/app_database.dart';
import 'package:reminder_app/features/reminders/data/local/item_timeline_dao.dart';
import 'package:reminder_app/features/reminders/data/timeline_models.dart';
import 'package:reminder_app/features/reminders/data/timeline_repository.dart';
import 'package:reminder_app/features/reminders/domain/item.dart';
import 'package:reminder_app/features/reminders/domain/item_pack.dart';
import 'package:reminder_app/features/reminders/domain/timeline.dart';
import 'package:reminder_app/features/reminders/domain/timeline_milestone_occurrence.dart';
import 'package:reminder_app/features/reminders/domain/timeline_milestone_record.dart';
import 'package:reminder_app/features/reminders/domain/timeline_milestone_rule.dart';
import 'package:reminder_app/features/reminders/presentation/formatters/reminder_formatters.dart';
import 'package:reminder_app/features/reminders/presentation/text/reminder_ui_text.dart';
import 'package:reminder_app/features/reminders/providers/developer_settings_providers.dart';
import 'package:reminder_app/features/reminders/providers/item_providers.dart';
import 'package:reminder_app/features/reminders/providers/timeline_providers.dart';
import 'package:reminder_app/features/reminders/ui/pages/feature_page.dart';

void main() {
  testWidgets('feature page shows integrated management entry set', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: FeaturePage()));

    expect(find.text(ReminderUiText.itemActivityFeatureTitle), findsOneWidget);
    expect(
      find.text(ReminderUiText.itemsManagementFeatureTitle),
      findsOneWidget,
    );
    expect(
      find.text(ReminderUiText.itemPacksManagementFeatureTitle),
      findsNothing,
    );
    expect(
      find.text(ReminderUiText.timelineManagementFeatureTitle),
      findsOneWidget,
    );
    expect(find.text(ReminderUiText.userSettingsFeatureTitle), findsOneWidget);
    expect(
      find.text(ReminderUiText.developerSettingsFeatureTitle),
      findsOneWidget,
    );
  });

  testWidgets(
    'feature page routes visible entries and old packs route aliases',
    (tester) async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);

      final router = GoRouter(
        initialLocation: FeaturePage.routePath,
        routes: [
          GoRoute(
            path: FeaturePage.routePath,
            name: FeaturePage.routeName,
            builder: (context, state) => const FeaturePage(),
          ),
          GoRoute(
            path: ItemActivityPage.routePath,
            name: ItemActivityPage.routeName,
            builder: (context, state) => const ItemActivityPage(),
          ),
          GoRoute(
            path: ItemsManagementPage.routePath,
            name: ItemsManagementPage.routeName,
            builder: (context, state) => const ItemsManagementPage(),
          ),
          GoRoute(
            path: ItemPacksManagementPage.routePath,
            name: ItemPacksManagementPage.routeName,
            builder: (context, state) => const ItemPacksManagementPage(),
          ),
          GoRoute(
            path: TimelineManagementPage.routePath,
            name: TimelineManagementPage.routeName,
            builder: (context, state) => const TimelineManagementPage(),
          ),
          GoRoute(
            path: SettingsPage.routePath,
            name: SettingsPage.routeName,
            builder: (context, state) => const SettingsPage(),
          ),
          GoRoute(
            path: DeveloperSettingsPage.routePath,
            name: DeveloperSettingsPage.routeName,
            builder: (context, state) => const DeveloperSettingsPage(),
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            itemRepositoryProvider.overrideWith(
              (ref) => ItemRepository(db.itemTimelineDao),
            ),
            systemPreviewDateProvider.overrideWith(
              (ref) => Stream.value(DateTime(2026, 4, 11)),
            ),
            activeItemPacksProvider.overrideWith(
              (ref) => Stream.value([
                _pack(1, title: 'Default Item Pack', isSystemDefault: true),
                _pack(2, title: 'Cat Care'),
              ]),
            ),
            packManagementItemsProvider.overrideWith(
              (ref) => Stream.value([
                _itemBundle(1, ItemType.stateBased),
                _itemBundle(
                  2,
                  ItemType.resourceBased,
                  packId: 2,
                  packTitle: 'Cat Care',
                ),
              ]),
            ),
            timelinesProvider.overrideWith(
              (ref) => Stream.value([
                Timeline(
                  id: 9,
                  title: 'No sugar',
                  startDate: DateTime(2026, 4, 10),
                  displayUnit: TimelineDisplayUnit.day,
                  status: TimelineStatus.active,
                  createdAt: DateTime(2026, 4, 1),
                  updatedAt: DateTime(2026, 4, 1),
                ),
              ]),
            ),
            previewTimelineDetailProvider(
              9,
            ).overrideWith((ref) => Future.value(_timelineDetail())),
          ],
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();

      final visibleRoutes = <_FeatureRouteCase>[
        const _FeatureRouteCase(
          key: 'item-activity',
          title: ReminderUiText.itemActivityFeatureTitle,
          placeholder: ReminderUiText.noRecentActivity,
        ),
        const _FeatureRouteCase(
          key: 'items-management',
          title: ReminderUiText.itemsManagementFeatureTitle,
          placeholder: ReminderUiText.unassignedPackTitle,
        ),
        const _FeatureRouteCase(
          key: 'timeline-management',
          title: ReminderUiText.timelineManagementFeatureTitle,
          placeholder: 'No sugar',
        ),
        const _FeatureRouteCase(
          key: 'settings',
          title: ReminderUiText.userSettingsFeatureTitle,
          placeholder: ReminderUiText.userSettingsPlaceholderMessage,
        ),
        const _FeatureRouteCase(
          key: 'developer-settings',
          title: ReminderUiText.developerSettingsFeatureTitle,
          placeholder: ReminderUiText.developerPreviewDateCurrentLabel,
        ),
      ];

      for (final testCase in visibleRoutes) {
        await tester.tap(find.byKey(Key('feature-entry-${testCase.key}')));
        await tester.pumpAndSettle();

        expect(find.text(testCase.title), findsAtLeastNWidgets(1));
        expect(find.text(testCase.placeholder), findsOneWidget);

        await tester.pageBack();
        await tester.pumpAndSettle();
      }
    },
  );

  testWidgets('old item packs page renders the integrated management page', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          systemPreviewDateProvider.overrideWith(
            (ref) => Stream.value(DateTime(2026, 4, 11)),
          ),
          activeItemPacksProvider.overrideWith(
            (ref) => Stream.value([
              _pack(1, title: 'Default Item Pack', isSystemDefault: true),
            ]),
          ),
          packManagementItemsProvider.overrideWith(
            (ref) => Stream.value([_itemBundle(1, ItemType.stateBased)]),
          ),
        ],
        child: const MaterialApp(home: ItemPacksManagementPage()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(ReminderUiText.itemsManagementFeatureTitle), findsWidgets);
    expect(find.text(ReminderUiText.unassignedPackTitle), findsOneWidget);
  });

  testWidgets(
    'item activity page shows recent activity, loads older records, supports search, and opens summary dialog',
    (tester) async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);
      var now = DateTime(2026, 4, 1, 9, 0);
      final repository = ItemRepository(db.itemTimelineDao, clock: () => now);
      final packId = await repository.createPack(
        const ItemPackInput(title: 'Cat Care'),
      );

      for (var index = 0; index < 21; index += 1) {
        now = DateTime(2026, 4, index + 10, 9, 0);
        await repository.createItem(
          ItemInput(
            title: 'Recent $index',
            type: ItemType.stateBased,
            packId: index.isEven ? packId : null,
            config: const StateBasedItemConfig(
              infoAfter: Duration(days: 1),
              warningAfter: Duration(days: 1),
              dangerAfter: Duration(days: 2),
            ),
          ),
        );
      }

      now = DateTime(2026, 3, 1, 8, 0);
      await repository.createItem(
        ItemInput(
          title: 'Old entry',
          type: ItemType.stateBased,
          config: const StateBasedItemConfig(
            infoAfter: Duration(days: 1),
            warningAfter: Duration(days: 1),
            dangerAfter: Duration(days: 2),
          ),
        ),
      );

      final container = ProviderContainer(
        overrides: [
          itemRepositoryProvider.overrideWith((ref) => repository),
          systemPreviewDateProvider.overrideWith(
            (ref) => Stream.value(DateTime(2026, 5, 1)),
          ),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: ItemActivityPage()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Recent 19'), findsOneWidget);
      expect(find.text('Recent 0'), findsNothing);
      expect(find.text('Old entry'), findsNothing);

      await tester.tap(find.text('Recent 19'));
      await tester.pumpAndSettle();
      expect(find.text(ReminderUiText.itemDetailTitle), findsOneWidget);
      expect(find.text(ReminderUiText.itemHistoryAction), findsNothing);
      await tester.tap(find.text(ReminderUiText.closeAction));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('item-activity-search-field')),
        'Cat Care',
      );
      await tester.pumpAndSettle();

      expect(find.text('Recent 18'), findsOneWidget);
      expect(find.text('Recent 19'), findsNothing);
      expect(find.text('Old entry'), findsNothing);

      await tester.tap(find.byKey(const Key('item-activity-search-clear')));
      await tester.pumpAndSettle();
      expect(find.text('Recent 19'), findsOneWidget);
    },
  );

  testWidgets('developer settings page updates and resets preview date', (
    tester,
  ) async {
    final today = normalizePreviewDate(DateTime.now());
    final selectedDate = DateTime(2026, 5, 2);

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: DeveloperSettingsPage(
            pickDate: (context, initialDate) async => selectedDate,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.text(ReminderUiText.developerSettingsFeatureTitle),
      findsOneWidget,
    );
    expect(find.text(ReminderFormatters.date(today)), findsOneWidget);
    expect(
      find.text(ReminderUiText.developerPreviewDateOverrideDisabled),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const Key('pick-preview-date-button')));
    await tester.pumpAndSettle();

    expect(
      find.text(ReminderFormatters.date(normalizePreviewDate(selectedDate))),
      findsOneWidget,
    );
    expect(
      find.text(ReminderUiText.developerPreviewDateOverrideEnabled),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const Key('reset-preview-date-button')));
    await tester.pumpAndSettle();

    expect(find.text(ReminderFormatters.date(today)), findsOneWidget);
    expect(
      find.text(ReminderUiText.developerPreviewDateOverrideDisabled),
      findsOneWidget,
    );
  });

  testWidgets('developer settings page follows system preview date updates', (
    tester,
  ) async {
    final controller = StreamController<DateTime>.broadcast();
    addTearDown(controller.close);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          systemPreviewDateProvider.overrideWith((ref) => controller.stream),
        ],
        child: const MaterialApp(home: DeveloperSettingsPage()),
      ),
    );

    controller.add(DateTime(2026, 4, 18));
    await tester.pumpAndSettle();

    expect(find.text('2026/04/18'), findsOneWidget);

    controller.add(DateTime(2026, 4, 19));
    await tester.pumpAndSettle();

    expect(find.text('2026/04/18'), findsNothing);
    expect(find.text('2026/04/19'), findsOneWidget);
  });

  testWidgets('items management groups are collapsed by default', (
    tester,
  ) async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final container = ProviderContainer(
      overrides: [
        itemRepositoryProvider.overrideWith(
          (ref) => ItemRepository(db.itemTimelineDao),
        ),
        systemPreviewDateProvider.overrideWith(
          (ref) => Stream.value(DateTime(2026, 4, 11)),
        ),
        activeItemPacksProvider.overrideWith(
          (ref) => Stream.value([
            _pack(1, title: 'Default Item Pack', isSystemDefault: true),
            _pack(2, title: 'Cat Care'),
          ]),
        ),
        packManagementItemsProvider.overrideWith(
          (ref) => Stream.value([
            _itemBundle(1, ItemType.stateBased),
            _itemBundle(
              2,
              ItemType.resourceBased,
              packId: 2,
              packTitle: 'Cat Care',
            ),
          ]),
        ),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: ItemsManagementPage()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('add-item-button')), findsOneWidget);
    expect(find.text(ReminderUiText.unassignedPackTitle), findsOneWidget);
    expect(find.text('Cat Care'), findsOneWidget);
    expect(find.text('Item 1'), findsNothing);
    expect(find.text('Item 2'), findsNothing);

    await tester.tap(find.byKey(const Key('pack-toggle-1')));
    await tester.pumpAndSettle();
    expect(find.text('Item 1'), findsOneWidget);
    expect(find.text('Item 2'), findsNothing);
    expect(find.byKey(const Key('item-edit-1')), findsOneWidget);
    expect(find.byKey(const Key('item-overflow-1')), findsOneWidget);
    expect(find.text(ReminderUiText.viewAllAction), findsNothing);

    await tester.tap(find.byKey(const Key('pack-toggle-2')));
    await tester.pumpAndSettle();
    expect(find.text('Item 2'), findsOneWidget);
  });

  testWidgets('items management card tap opens details dialog', (tester) async {
    final container = ProviderContainer(
      overrides: [
        systemPreviewDateProvider.overrideWith(
          (ref) => Stream.value(DateTime(2026, 4, 11)),
        ),
        activeItemPacksProvider.overrideWith(
          (ref) => Stream.value([
            _pack(1, title: 'Default Item Pack', isSystemDefault: true),
          ]),
        ),
        packManagementItemsProvider.overrideWith(
          (ref) => Stream.value([_itemBundle(1, ItemType.stateBased)]),
        ),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: ItemsManagementPage()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('pack-toggle-1')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('item-card-1')));
    await tester.pumpAndSettle();

    expect(find.text(ReminderUiText.itemDetailTitle), findsOneWidget);
    expect(
      find.text(ReminderUiText.unassignedPackTitle),
      findsAtLeastNWidgets(1),
    );
    expect(find.text('2026/04/10'), findsAtLeastNWidgets(1));
    await tester.tap(find.text(ReminderUiText.closeAction));
    await tester.pumpAndSettle();
    expect(find.text(ReminderUiText.itemDetailTitle), findsNothing);
  });

  testWidgets(
    'items management complete action requires confirm for normal state item and forwards preview date',
    (tester) async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);
      final repository = _RecordingItemRepository(db.itemTimelineDao);
      final previewDate = DateTime(2026, 4, 11);
      final container = ProviderContainer(
        overrides: [
          itemRepositoryProvider.overrideWith((ref) => repository),
          systemPreviewDateProvider.overrideWith(
            (ref) => Stream.value(previewDate),
          ),
          activeItemPacksProvider.overrideWith(
            (ref) => Stream.value([
              _pack(1, title: 'Default Item Pack', isSystemDefault: true),
            ]),
          ),
          packManagementItemsProvider.overrideWith(
            (ref) => Stream.value([_itemBundle(1, ItemType.stateBased)]),
          ),
        ],
      );
      addTearDown(container.dispose);
      container.read(developerDateOverrideProvider.notifier).state =
          previewDate;

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: ItemsManagementPage()),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('pack-toggle-1')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('item-overflow-1')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('item-menu-complete-1')));
      await tester.pumpAndSettle();

      expect(
        find.text(ReminderUiText.stateCompleteConfirmTitle),
        findsOneWidget,
      );
      await tester.tap(find.text(ReminderUiText.completeAction).last);
      await tester.pumpAndSettle();

      expect(repository.recordedItemId, 1);
      expect(repository.recordedDoneAt, previewDate);
      expect(repository.markDoneCount, 1);
    },
  );

  testWidgets(
    'items management disables complete and skip before anchor date',
    (tester) async {
      final container = ProviderContainer(
        overrides: [
          systemPreviewDateProvider.overrideWith(
            (ref) => Stream.value(DateTime(2026, 4, 11)),
          ),
          activeItemPacksProvider.overrideWith(
            (ref) => Stream.value([
              _pack(1, title: 'Default Item Pack', isSystemDefault: true),
            ]),
          ),
          packManagementItemsProvider.overrideWith(
            (ref) => Stream.value([
              _itemBundle(
                1,
                ItemType.fixed,
                config: FixedItemConfig(
                  scheduleType: FixedScheduleType.weekly,
                  anchorDate: DateTime(2026, 4, 20),
                  dueDate: DateTime(2026, 4, 27),
                ),
              ),
            ]),
          ),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: ItemsManagementPage()),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('pack-toggle-1')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('item-overflow-1')));
      await tester.pumpAndSettle();

      final completeTile = tester.widget<ListTile>(
        find.descendant(
          of: find.byKey(const Key('item-menu-complete-1')),
          matching: find.byType(ListTile),
        ),
      );
      final skipTile = tester.widget<ListTile>(
        find.descendant(
          of: find.byKey(const Key('item-menu-skip-1')),
          matching: find.byType(ListTile),
        ),
      );

      expect(completeTile.enabled, isFalse);
      expect(skipTile.enabled, isFalse);
    },
  );

  testWidgets('paused items show resume only after expansion', (tester) async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final repository = _RecordingItemRepository(db.itemTimelineDao);
    final container = ProviderContainer(
      overrides: [
        itemRepositoryProvider.overrideWith((ref) => repository),
        systemPreviewDateProvider.overrideWith(
          (ref) => Stream.value(DateTime(2026, 4, 11)),
        ),
        activeItemPacksProvider.overrideWith(
          (ref) => Stream.value([
            _pack(1, title: 'Default Item Pack', isSystemDefault: true),
            _pack(2, title: 'Cat Care'),
          ]),
        ),
        packManagementItemsProvider.overrideWith(
          (ref) => Stream.value([
            _itemBundle(
              3,
              ItemType.stateBased,
              packId: 2,
              packTitle: 'Cat Care',
              lifecycleStatus: ItemLifecycleStatus.paused,
            ),
          ]),
        ),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: ItemsManagementPage()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('pack-toggle-2')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('item-overflow-3')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('item-menu-resume-3')), findsOneWidget);
    expect(find.byKey(const Key('item-menu-pause-3')), findsNothing);
    expect(
      tester
          .widget<ListTile>(
            find.descendant(
              of: find.byKey(const Key('item-menu-complete-3')),
              matching: find.byType(ListTile),
            ),
          )
          .enabled,
      isFalse,
    );
    expect(
      tester
          .widget<ListTile>(
            find.descendant(
              of: find.byKey(const Key('item-menu-skip-3')),
              matching: find.byType(ListTile),
            ),
          )
          .enabled,
      isFalse,
    );
  });

  testWidgets('resource items disable skip and require added days dialog', (
    tester,
  ) async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final repository = _RecordingItemRepository(db.itemTimelineDao);
    final previewDate = DateTime(2026, 4, 11);
    final container = ProviderContainer(
      overrides: [
        itemRepositoryProvider.overrideWith((ref) => repository),
        systemPreviewDateProvider.overrideWith(
          (ref) => Stream.value(previewDate),
        ),
        activeItemPacksProvider.overrideWith(
          (ref) => Stream.value([
            _pack(1, title: 'Default Item Pack', isSystemDefault: true),
          ]),
        ),
        packManagementItemsProvider.overrideWith(
          (ref) => Stream.value([_itemBundle(3, ItemType.resourceBased)]),
        ),
      ],
    );
    addTearDown(container.dispose);
    container.read(developerDateOverrideProvider.notifier).state = previewDate;

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: ItemsManagementPage()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('pack-toggle-1')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('item-overflow-3')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('item-menu-skip-3')), findsOneWidget);
    expect(
      tester
          .widget<ListTile>(
            find.descendant(
              of: find.byKey(const Key('item-menu-skip-3')),
              matching: find.byType(ListTile),
            ),
          )
          .enabled,
      isFalse,
    );

    await tester.tap(find.byKey(const Key('item-menu-complete-3')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).last, '12');
    await tester.tap(find.text(ReminderUiText.saveAction));
    await tester.pumpAndSettle();

    expect(repository.recordedItemId, 3);
    expect(repository.recordedDoneAt, previewDate);
    expect(repository.recordedAddedDays, 12);
  });

  testWidgets('timeline management page shows timeline actions', (
    tester,
  ) async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final container = ProviderContainer(
      overrides: [
        timelineRepositoryProvider.overrideWith(
          (ref) => _FakeTimelineRepository(db.itemTimelineDao),
        ),
      ],
    );
    addTearDown(container.dispose);
    container.read(developerDateOverrideProvider.notifier).state = DateTime(
      2026,
      4,
      11,
    );

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: TimelineManagementPage()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('add-timeline-button')), findsOneWidget);
    expect(find.text('No sugar'), findsOneWidget);
    expect(find.byKey(const Key('timeline-edit-9')), findsOneWidget);
    expect(find.byKey(const Key('timeline-history-9')), findsOneWidget);
    expect(find.text('第 10天'), findsOneWidget);
    expect(find.text('2026/04/20'), findsOneWidget);

    container.read(developerDateOverrideProvider.notifier).state = DateTime(
      2026,
      4,
      21,
    );
    await tester.pumpAndSettle();

    expect(find.text('第 20天'), findsOneWidget);
    expect(find.text('2026/04/30'), findsOneWidget);
  });
}

class _FeatureRouteCase {
  const _FeatureRouteCase({
    required this.key,
    required this.title,
    required this.placeholder,
  });

  final String key;
  final String title;
  final String placeholder;
}

ItemBundle _itemBundle(
  int id,
  ItemType type, {
  int packId = 1,
  String packTitle = 'Default Item Pack',
  ItemLifecycleStatus lifecycleStatus = ItemLifecycleStatus.active,
  ItemConfig? config,
  String? title,
  DateTime? lastDoneAt,
  DateTime? updatedAt,
}) {
  final resolvedConfig =
      config ??
      switch (type) {
        ItemType.stateBased => StateBasedItemConfig(
          anchorDate: DateTime(2026, 4, 10),
          infoAfter: Duration(days: 7),
          warningAfter: Duration(days: 7),
          dangerAfter: Duration(days: 14),
        ),
        ItemType.resourceBased => ResourceBasedItemConfig(
          anchorDate: DateTime(2026, 4, 10),
          durationDays: 30,
          warningBefore: 7,
        ),
        ItemType.fixed => FixedTimeItemConfig(
          scheduleType: FixedTimeScheduleType.daily,
          anchorDate: DateTime(2026, 4, 10),
          dueDate: DateTime(2026, 4, 10),
        ),
      };
  return ItemBundle(
    item: Item(
      id: id,
      packId: packId,
      title: title ?? 'Item $id',
      status: lifecycleStatus,
      type: type,
      config: resolvedConfig,
      lastDoneAt: lastDoneAt,
      createdAt: DateTime(2026, 4, 1),
      updatedAt: updatedAt ?? DateTime(2026, 4, 1),
    ),
    pack: _pack(packId, title: packTitle, isSystemDefault: packId == 1),
  );
}

ItemPack _pack(int id, {required String title, bool isSystemDefault = false}) {
  return ItemPack(
    id: id,
    title: title,
    status: ItemPackStatus.active,
    isSystemDefault: isSystemDefault,
    createdAt: DateTime(2026, 4, 1),
    updatedAt: DateTime(2026, 4, 1),
  );
}

TimelineDetail _timelineDetail() {
  return TimelineDetail(
    timeline: Timeline(
      id: 9,
      title: 'No sugar',
      startDate: DateTime(2026, 4, 10),
      displayUnit: TimelineDisplayUnit.day,
      status: TimelineStatus.active,
      createdAt: DateTime(2026, 4, 1),
      updatedAt: DateTime(2026, 4, 1),
    ),
    milestoneRuleDetails: [
      TimelineMilestoneRuleDetail(
        rule: _rule(92, TimelineMilestoneRuleStatus.active),
        nextMilestone: TimelineMilestoneOccurrence(
          timelineId: 9,
          timelineTitle: 'No sugar',
          ruleId: 92,
          occurrenceIndex: 1,
          targetDate: DateTime(2026, 4, 20),
          label: '第 10天',
          status: TimelineMilestoneRecordStatus.upcoming,
          reminderOffsetDays: 0,
        ),
        historyRecords: const [],
      ),
    ],
    upcomingMilestones: [
      TimelineMilestoneOccurrence(
        timelineId: 9,
        timelineTitle: 'No sugar',
        ruleId: 92,
        occurrenceIndex: 1,
        targetDate: DateTime(2026, 4, 20),
        label: '第 10天',
        status: TimelineMilestoneRecordStatus.upcoming,
        reminderOffsetDays: 0,
      ),
    ],
    milestoneHistory: const [],
  );
}

class _RecordingItemRepository extends ItemRepository {
  _RecordingItemRepository(super.dao);

  int? recordedItemId;
  DateTime? recordedDoneAt;
  int? recordedAddedDays;
  int? recordedSkipItemId;
  DateTime? recordedSkipAt;
  int? recordedPauseItemId;
  int? recordedResumeItemId;
  int? recordedArchiveItemId;
  int markDoneCount = 0;

  @override
  Future<bool> markDone(
    int id, {
    int? addedDays,
    DateTime? doneAt,
    ItemNextCycleStrategy nextCycleStrategy =
        ItemNextCycleStrategy.keepSchedule,
    String? remark,
  }) async {
    markDoneCount += 1;
    recordedItemId = id;
    recordedDoneAt = doneAt;
    recordedAddedDays = addedDays;
    return true;
  }

  @override
  Future<bool> skip(
    int id, {
    DateTime? actionAt,
    String? remark,
    ItemNextCycleStrategy nextCycleStrategy =
        ItemNextCycleStrategy.keepSchedule,
  }) async {
    recordedSkipItemId = id;
    recordedSkipAt = actionAt;
    return true;
  }

  @override
  Future<bool> pauseItem(int id) async {
    recordedPauseItemId = id;
    return true;
  }

  @override
  Future<bool> resumeItem(int id) async {
    recordedResumeItemId = id;
    return true;
  }

  @override
  Future<bool> archiveItem(int id) async {
    recordedArchiveItemId = id;
    return true;
  }
}

TimelineMilestoneRule _rule(int id, TimelineMilestoneRuleStatus status) {
  return TimelineMilestoneRule(
    id: id,
    timelineId: 9,
    type: TimelineMilestoneRuleType.everyNDays,
    intervalValue: 10,
    intervalUnit: TimelineMilestoneIntervalUnit.days,
    labelTemplate: '第 {value}{unit}',
    reminderOffsetDays: 0,
    status: status,
    createdAt: DateTime(2026, 4, 1),
    updatedAt: DateTime(2026, 4, 1),
  );
}

class _FakeTimelineRepository extends TimelineRepository {
  _FakeTimelineRepository(super.dao);

  static final Timeline _timeline = Timeline(
    id: 9,
    title: 'No sugar',
    startDate: DateTime(2026, 4, 10),
    displayUnit: TimelineDisplayUnit.day,
    status: TimelineStatus.active,
    createdAt: DateTime(2026, 4, 1),
    updatedAt: DateTime(2026, 4, 1),
  );

  @override
  Stream<List<Timeline>> watchTimelines() => Stream.value([_timeline]);

  @override
  Future<TimelineDetail?> getTimelineDetailById(int id, {DateTime? now}) async {
    final previewDate = normalizePreviewDate(now ?? DateTime.now());
    final targetDate = previewDate.day <= 15
        ? DateTime(2026, 4, 20)
        : DateTime(2026, 4, 30);
    final label = previewDate.day <= 15 ? '第 10天' : '第 20天';

    return TimelineDetail(
      timeline: _timeline,
      milestoneRuleDetails: [
        TimelineMilestoneRuleDetail(
          rule: _rule(92, TimelineMilestoneRuleStatus.active),
          nextMilestone: TimelineMilestoneOccurrence(
            timelineId: 9,
            timelineTitle: 'No sugar',
            ruleId: 92,
            occurrenceIndex: 1,
            targetDate: targetDate,
            label: label,
            status: TimelineMilestoneRecordStatus.upcoming,
            reminderOffsetDays: 0,
          ),
          historyRecords: const [],
        ),
      ],
      upcomingMilestones: [
        TimelineMilestoneOccurrence(
          timelineId: 9,
          timelineTitle: 'No sugar',
          ruleId: 92,
          occurrenceIndex: 1,
          targetDate: targetDate,
          label: label,
          status: TimelineMilestoneRecordStatus.upcoming,
          reminderOffsetDays: 0,
        ),
      ],
      milestoneHistory: const [],
    );
  }
}
