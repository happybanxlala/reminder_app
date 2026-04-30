import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:reminder_app/features/reminders/data/home_models.dart';
import 'package:reminder_app/features/reminders/data/home_repository.dart';
import 'package:reminder_app/features/reminders/data/item_repository.dart';
import 'package:reminder_app/features/reminders/data/local/app_database.dart';
import 'package:reminder_app/features/reminders/data/local/item_timeline_dao.dart';
import 'package:reminder_app/features/reminders/data/timeline_repository.dart';
import 'package:reminder_app/features/reminders/domain/item.dart';
import 'package:reminder_app/features/reminders/domain/item_pack.dart';
import 'package:reminder_app/features/reminders/domain/timeline_milestone_occurrence.dart';
import 'package:reminder_app/features/reminders/domain/timeline_milestone_record.dart';
import 'package:reminder_app/features/reminders/providers/developer_settings_providers.dart';
import 'package:reminder_app/features/reminders/providers/item_providers.dart';
import 'package:reminder_app/features/reminders/presentation/text/reminder_ui_text.dart';
import 'package:reminder_app/features/reminders/providers/home_providers.dart';
import 'package:reminder_app/features/reminders/ui/pages/feature_page.dart';
import 'package:reminder_app/features/reminders/ui/pages/home_page.dart';
import 'package:reminder_app/features/reminders/ui/pages/item_edit_page.dart';

void main() {
  testWidgets('home shows danger warning and upcoming sections', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          dangerHomeEntriesProvider.overrideWith(
            (ref) => Stream.value([
              _itemEntry(title: 'Clean litter box', status: ItemStatus.danger),
            ]),
          ),
          warningHomeEntriesProvider.overrideWith(
            (ref) => Stream.value([
              _itemEntry(
                title: 'Refill water fountain',
                status: ItemStatus.warning,
              ),
            ]),
          ),
          upcomingTimelineMilestonesProvider.overrideWith(
            (ref) => Stream.value([_occurrence(title: 'No sugar')]),
          ),
        ],
        child: const MaterialApp(home: HomePage()),
      ),
    );
    await tester.pump();

    expect(find.text(ReminderUiText.dangerTab), findsOneWidget);
    expect(find.text(ReminderUiText.warningTab), findsOneWidget);
    expect(find.text(ReminderUiText.upcomingSectionTitle), findsOneWidget);
    expect(find.text('Clean litter box'), findsOneWidget);
    expect(find.byKey(const Key('history-button')), findsNothing);
    expect(find.byKey(const Key('quick-add-item-button')), findsNothing);
    expect(find.byKey(const Key('home-add-item-fab')), findsOneWidget);
  });

  testWidgets('home item card is collapsed by default and expands', (
    tester,
  ) async {
    const itemId = 201;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          dangerHomeEntriesProvider.overrideWith(
            (ref) => Stream.value([
              ItemHomeEntry(
                bundle: ItemBundle(
                  item: Item(
                    id: itemId,
                    packId: 1,
                    title: 'Clean litter box',
                    description: '每日清理一次',
                    type: ItemType.stateBased,
                    config: StateBasedItemConfig(
                      anchorDate: DateTime(2026, 4, 8),
                      infoAfter: Duration.zero,
                      warningAfter: Duration(days: 1),
                      dangerAfter: Duration(days: 2),
                    ),
                    createdAt: DateTime(2026, 4, 1),
                    updatedAt: DateTime(2026, 4, 1),
                  ),
                  pack: ItemPack(
                    id: 1,
                    title: 'Home Pack',
                    status: ItemPackStatus.active,
                    isSystemDefault: true,
                    createdAt: DateTime(2026, 4, 1),
                    updatedAt: DateTime(2026, 4, 1),
                  ),
                ),
                status: ItemStatus.danger,
                elapsed: const Duration(days: 3),
              ),
            ]),
          ),
          warningHomeEntriesProvider.overrideWith(
            (ref) => Stream.value(const <ItemHomeEntry>[]),
          ),
          upcomingTimelineMilestonesProvider.overrideWith(
            (ref) => Stream.value(const <TimelineMilestoneOccurrence>[]),
          ),
        ],
        child: const MaterialApp(home: HomePage()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('item-content-201')), findsNothing);

    await tester.tap(find.byKey(const Key('item-expand-201')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('item-content-201')), findsOneWidget);
    expect(find.text('Home Pack'), findsOneWidget);
    expect(find.text('每日清理一次'), findsOneWidget);
    expect(find.text('2026/04/08'), findsOneWidget);
  });

  testWidgets(
    'home item card shows badges, tails, and skip visibility by type',
    (tester) async {
      final entries = [
        ItemHomeEntry(
          bundle: ItemBundle(
            item: Item(
              id: 202,
              packId: 1,
              title: 'Pay rent',
              type: ItemType.fixed,
              config: FixedItemConfig(
                scheduleType: FixedScheduleType.weekly,
                anchorDate: DateTime(2026, 4, 1),
                dueDate: DateTime(2026, 4, 12),
              ),
              createdAt: DateTime(2026, 4, 1),
              updatedAt: DateTime(2026, 4, 1),
            ),
            pack: _defaultPack(),
          ),
          status: ItemStatus.warning,
          elapsed: null,
        ),
        ItemHomeEntry(
          bundle: ItemBundle(
            item: Item(
              id: 203,
              packId: 1,
              title: 'Clean litter box',
              type: ItemType.stateBased,
              config: StateBasedItemConfig(
                anchorDate: DateTime(2026, 4, 8),
                infoAfter: Duration.zero,
                warningAfter: Duration(days: 1),
                dangerAfter: Duration(days: 2),
              ),
              createdAt: DateTime(2026, 4, 1),
              updatedAt: DateTime(2026, 4, 1),
            ),
            pack: _defaultPack(),
          ),
          status: ItemStatus.danger,
          elapsed: const Duration(days: 3),
        ),
        ItemHomeEntry(
          bundle: ItemBundle(
            item: Item(
              id: 204,
              packId: 1,
              title: 'Cat food',
              type: ItemType.resourceBased,
              config: ResourceBasedItemConfig(
                anchorDate: DateTime(2026, 4, 1),
                durationDays: 5,
                warningBefore: 1,
              ),
              createdAt: DateTime(2026, 4, 1),
              updatedAt: DateTime(2026, 4, 1),
            ),
            pack: _defaultPack(),
          ),
          status: ItemStatus.danger,
          elapsed: null,
        ),
      ];

      final container = ProviderContainer(
        overrides: [
          dangerHomeEntriesProvider.overrideWith(
            (ref) => Stream.value(entries),
          ),
          warningHomeEntriesProvider.overrideWith(
            (ref) => Stream.value(const <ItemHomeEntry>[]),
          ),
          upcomingTimelineMilestonesProvider.overrideWith(
            (ref) => Stream.value(const <TimelineMilestoneOccurrence>[]),
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
          child: const MaterialApp(home: HomePage()),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.descendant(
          of: find.byKey(const Key('item-badge-202')),
          matching: find.text(ReminderUiText.fixedTypeLabel),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(const Key('item-badge-203')),
          matching: find.text(ReminderUiText.stateBasedTypeLabel),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(const Key('item-badge-204')),
          matching: find.text(ReminderUiText.resourceBasedTypeLabel),
        ),
        findsOneWidget,
      );
      expect(find.byKey(const Key('item-tail-202')), findsOneWidget);
      expect(find.byKey(const Key('item-tail-203')), findsOneWidget);
      expect(find.byKey(const Key('item-tail-204')), findsOneWidget);
      expect(find.text('剩餘1日'), findsOneWidget);
      expect(find.text('已持續4日'), findsOneWidget);

      await tester.tap(find.byKey(const Key('item-expand-202')));
      await tester.tap(find.byKey(const Key('item-expand-203')));
      await tester.tap(find.byKey(const Key('item-expand-204')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('item-skip-202')), findsOneWidget);
      expect(find.byKey(const Key('item-skip-203')), findsOneWidget);
      expect(find.byKey(const Key('item-skip-204')), findsNothing);
      expect(find.byKey(const Key('item-defer-202')), findsNothing);
      expect(find.byKey(const Key('item-defer-203')), findsNothing);
      expect(find.byKey(const Key('item-defer-204')), findsNothing);
    },
  );

  testWidgets('home fixed item tail shows today due and overdue states', (
    tester,
  ) async {
    final entries = [
      ItemHomeEntry(
        bundle: ItemBundle(
          item: Item(
            id: 207,
            packId: 1,
            title: 'Due today',
            type: ItemType.fixed,
            config: FixedItemConfig(
              scheduleType: FixedScheduleType.oneTime,
              anchorDate: DateTime(2026, 4, 1),
              dueDate: DateTime(2026, 4, 12),
            ),
            createdAt: DateTime(2026, 4, 1),
            updatedAt: DateTime(2026, 4, 1),
          ),
          pack: _defaultPack(),
        ),
        status: ItemStatus.danger,
        elapsed: null,
      ),
      ItemHomeEntry(
        bundle: ItemBundle(
          item: Item(
            id: 208,
            packId: 1,
            title: 'Overdue',
            type: ItemType.fixed,
            config: FixedItemConfig(
              scheduleType: FixedScheduleType.oneTime,
              anchorDate: DateTime(2026, 4, 1),
              dueDate: DateTime(2026, 4, 12),
              overduePolicy: ItemOverduePolicy.waitForAction,
            ),
            createdAt: DateTime(2026, 4, 1),
            updatedAt: DateTime(2026, 4, 1),
          ),
          pack: _defaultPack(),
        ),
        status: ItemStatus.danger,
        elapsed: null,
      ),
    ];
    final container = ProviderContainer(
      overrides: [
        dangerHomeEntriesProvider.overrideWith((ref) => Stream.value(entries)),
        warningHomeEntriesProvider.overrideWith(
          (ref) => Stream.value(const <ItemHomeEntry>[]),
        ),
        upcomingTimelineMilestonesProvider.overrideWith(
          (ref) => Stream.value(const <TimelineMilestoneOccurrence>[]),
        ),
      ],
    );
    addTearDown(container.dispose);

    container.read(developerDateOverrideProvider.notifier).state = DateTime(
      2026,
      4,
      12,
    );
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: HomePage()),
      ),
    );
    await tester.pumpAndSettle();
    final todayTail = tester.widget<Text>(
      find.byKey(const Key('item-tail-207')),
    );
    expect(todayTail.data, '今天到期');

    container.read(developerDateOverrideProvider.notifier).state = DateTime(
      2026,
      4,
      13,
    );
    await tester.pumpAndSettle();
    final overdueTail = tester.widget<Text>(
      find.byKey(const Key('item-tail-208')),
    );
    expect(overdueTail.data, '過期');
  });

  testWidgets('home item card disables completion when item is not started', (
    tester,
  ) async {
    const itemId = 205;
    final container = ProviderContainer(
      overrides: [
        dangerHomeEntriesProvider.overrideWith(
          (ref) => Stream.value([
            ItemHomeEntry(
              bundle: ItemBundle(
                item: Item(
                  id: itemId,
                  packId: 1,
                  title: 'Future task',
                  type: ItemType.stateBased,
                  config: StateBasedItemConfig(
                    anchorDate: DateTime(2026, 4, 30),
                    infoAfter: Duration.zero,
                    warningAfter: Duration(days: 1),
                    dangerAfter: Duration(days: 2),
                  ),
                  createdAt: DateTime(2026, 4, 1),
                  updatedAt: DateTime(2026, 4, 1),
                ),
                pack: _defaultPack(),
              ),
              status: ItemStatus.warning,
              elapsed: null,
            ),
          ]),
        ),
        warningHomeEntriesProvider.overrideWith(
          (ref) => Stream.value(const <ItemHomeEntry>[]),
        ),
        upcomingTimelineMilestonesProvider.overrideWith(
          (ref) => Stream.value(const <TimelineMilestoneOccurrence>[]),
        ),
      ],
    );
    addTearDown(container.dispose);
    container.read(developerDateOverrideProvider.notifier).state = DateTime(
      2026,
      4,
      21,
    );

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: HomePage()),
      ),
    );
    await tester.pumpAndSettle();

    final checkbox = tester.widget<Checkbox>(
      find.byKey(const Key('item-checkbox-205')),
    );
    final header = tester.widget<Container>(
      find.byKey(const Key('item-header-205')),
    );

    expect(checkbox.onChanged, isNull);
    expect(header.color, Colors.white);
    expect(find.byKey(const Key('item-tail-205')), findsNothing);
  });

  testWidgets('home item card shows overdue styling for fixed waitForAction', (
    tester,
  ) async {
    const itemId = 206;
    final container = ProviderContainer(
      overrides: [
        dangerHomeEntriesProvider.overrideWith(
          (ref) => Stream.value([
            ItemHomeEntry(
              bundle: ItemBundle(
                item: Item(
                  id: itemId,
                  packId: 1,
                  title: 'Submit form',
                  type: ItemType.fixed,
                  config: FixedItemConfig(
                    scheduleType: FixedScheduleType.oneTime,
                    anchorDate: DateTime(2026, 4, 10),
                    dueDate: DateTime(2026, 4, 15),
                    overduePolicy: ItemOverduePolicy.waitForAction,
                  ),
                  createdAt: DateTime(2026, 4, 1),
                  updatedAt: DateTime(2026, 4, 1),
                ),
                pack: _defaultPack(),
              ),
              status: ItemStatus.danger,
              elapsed: null,
            ),
          ]),
        ),
        warningHomeEntriesProvider.overrideWith(
          (ref) => Stream.value(const <ItemHomeEntry>[]),
        ),
        upcomingTimelineMilestonesProvider.overrideWith(
          (ref) => Stream.value(const <TimelineMilestoneOccurrence>[]),
        ),
      ],
    );
    addTearDown(container.dispose);
    container.read(developerDateOverrideProvider.notifier).state = DateTime(
      2026,
      4,
      21,
    );

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: HomePage()),
      ),
    );
    await tester.pumpAndSettle();

    final header = tester.widget<Container>(
      find.byKey(const Key('item-header-206')),
    );
    final tail = tester.widget<Text>(find.byKey(const Key('item-tail-206')));

    expect(header.color, const Color(0xFFEF9A9A));
    expect(tail.data, '過期');
  });

  testWidgets('home upcoming section renders timeline milestone items', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          dangerHomeEntriesProvider.overrideWith(
            (ref) => Stream.value(<ItemHomeEntry>[]),
          ),
          warningHomeEntriesProvider.overrideWith(
            (ref) => Stream.value(<ItemHomeEntry>[]),
          ),
          upcomingTimelineMilestonesProvider.overrideWith(
            (ref) => Stream.value([_occurrence(title: 'No sugar')]),
          ),
        ],
        child: const MaterialApp(home: HomePage()),
      ),
    );
    await tester.pump();

    expect(find.text('No sugar'), findsOneWidget);
    expect(find.text(ReminderUiText.milestoneLabel), findsOneWidget);
    expect(find.text('已看過'), findsOneWidget);
    expect(find.text('跳過'), findsOneWidget);
  });

  testWidgets('home feature button navigates to feature page', (tester) async {
    final router = GoRouter(
      initialLocation: HomePage.routePath,
      routes: [
        GoRoute(
          path: HomePage.routePath,
          name: HomePage.routeName,
          builder: (context, state) => const HomePage(),
        ),
        GoRoute(
          path: FeaturePage.routePath,
          name: FeaturePage.routeName,
          builder: (context, state) => const FeaturePage(),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          dangerHomeEntriesProvider.overrideWith(
            (ref) => Stream.value(<ItemHomeEntry>[]),
          ),
          warningHomeEntriesProvider.overrideWith(
            (ref) => Stream.value(<ItemHomeEntry>[]),
          ),
          upcomingTimelineMilestonesProvider.overrideWith(
            (ref) => Stream.value(<TimelineMilestoneOccurrence>[]),
          ),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('feature-button')), findsOneWidget);

    await tester.tap(find.byKey(const Key('feature-button')));
    await tester.pumpAndSettle();

    expect(find.text(ReminderUiText.featurePageTitle), findsOneWidget);
  });

  testWidgets('home add item fab navigates to item create page', (
    tester,
  ) async {
    final router = GoRouter(
      initialLocation: HomePage.routePath,
      routes: [
        GoRoute(
          path: HomePage.routePath,
          name: HomePage.routeName,
          builder: (context, state) => const HomePage(),
        ),
        GoRoute(
          path: ItemEditPage.createRoutePath,
          name: ItemEditPage.createRouteName,
          builder: (context, state) =>
              const Scaffold(body: Text('Create Item Page')),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          dangerHomeEntriesProvider.overrideWith(
            (ref) => Stream.value(<ItemHomeEntry>[]),
          ),
          warningHomeEntriesProvider.overrideWith(
            (ref) => Stream.value(<ItemHomeEntry>[]),
          ),
          upcomingTimelineMilestonesProvider.overrideWith(
            (ref) => Stream.value(<TimelineMilestoneOccurrence>[]),
          ),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('home-add-item-fab')), findsOneWidget);

    await tester.tap(find.byKey(const Key('home-add-item-fab')));
    await tester.pumpAndSettle();

    expect(find.text('Create Item Page'), findsOneWidget);
  });

  testWidgets('home preview updates when developer date override changes', (
    tester,
  ) async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final container = ProviderContainer(
      overrides: [
        homeRepositoryProvider.overrideWith(
          (ref) => _FakeHomeRepository(
            itemRepository: ItemRepository(db.itemTimelineDao),
            timelineRepository: TimelineRepository(db.itemTimelineDao),
          ),
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
        child: const MaterialApp(home: HomePage()),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('Danger 11'), findsOneWidget);

    container.read(developerDateOverrideProvider.notifier).state = DateTime(
      2026,
      4,
      18,
    );
    await tester.pumpAndSettle();

    expect(find.text('Danger 11'), findsNothing);
    expect(find.text('Danger 18'), findsOneWidget);
  });

  testWidgets(
    'home preview follows system preview date when override is null',
    (tester) async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);
      final controller = StreamController<DateTime>.broadcast();
      addTearDown(controller.close);
      final container = ProviderContainer(
        overrides: [
          homeRepositoryProvider.overrideWith(
            (ref) => _FakeHomeRepository(
              itemRepository: ItemRepository(db.itemTimelineDao),
              timelineRepository: TimelineRepository(db.itemTimelineDao),
            ),
          ),
          systemPreviewDateProvider.overrideWith((ref) => controller.stream),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: HomePage()),
        ),
      );

      controller.add(DateTime(2026, 4, 18));
      await tester.pumpAndSettle();
      expect(find.text('Danger 18'), findsOneWidget);

      controller.add(DateTime(2026, 4, 19));
      await tester.pumpAndSettle();
      expect(find.text('Danger 18'), findsNothing);
      expect(find.text('Danger 19'), findsOneWidget);
    },
  );

  testWidgets('home complete action forwards preview date for state baseline', (
    tester,
  ) async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final itemRepository = _RecordingItemRepository(db.itemTimelineDao);
    final previewDate = DateTime(2026, 4, 11);
    const itemId = 101;
    final container = ProviderContainer(
      overrides: [
        itemRepositoryProvider.overrideWith((ref) => itemRepository),
        dangerHomeEntriesProvider.overrideWith(
          (ref) => Stream.value([
            ItemHomeEntry(
              bundle: ItemBundle(
                item: Item(
                  id: itemId,
                  packId: 1,
                  title: 'Clean litter box',
                  type: ItemType.stateBased,
                  config: StateBasedItemConfig(
                    anchorDate: DateTime(2026, 4, 8),
                    infoAfter: Duration(days: 1),
                    warningAfter: Duration(days: 1),
                    dangerAfter: Duration(days: 2),
                  ),
                  createdAt: DateTime(2026, 4, 1),
                  updatedAt: DateTime(2026, 4, 1),
                ),
                pack: ItemPack(
                  id: 1,
                  title: 'Default Item Pack',
                  status: ItemPackStatus.active,
                  isSystemDefault: true,
                  createdAt: DateTime(2026, 4, 1),
                  updatedAt: DateTime(2026, 4, 1),
                ),
              ),
              status: ItemStatus.danger,
              elapsed: const Duration(days: 3),
            ),
          ]),
        ),
        warningHomeEntriesProvider.overrideWith(
          (ref) => Stream.value(const <ItemHomeEntry>[]),
        ),
        upcomingTimelineMilestonesProvider.overrideWith(
          (ref) => Stream.value(const <TimelineMilestoneOccurrence>[]),
        ),
      ],
    );
    addTearDown(container.dispose);
    container.read(developerDateOverrideProvider.notifier).state = previewDate;

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: HomePage()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('item-checkbox-101')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(itemRepository.recordedItemId, itemId);
    expect(itemRepository.recordedDoneAt, previewDate);
  });

  testWidgets('home hides skip for resource items and requires added days', (
    tester,
  ) async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final itemRepository = _RecordingItemRepository(db.itemTimelineDao);
    final previewDate = DateTime(2026, 4, 11);
    const itemId = 102;
    final container = ProviderContainer(
      overrides: [
        itemRepositoryProvider.overrideWith((ref) => itemRepository),
        dangerHomeEntriesProvider.overrideWith(
          (ref) => Stream.value([
            ItemHomeEntry(
              bundle: ItemBundle(
                item: Item(
                  id: itemId,
                  packId: 1,
                  title: 'Cat food',
                  type: ItemType.resourceBased,
                  config: ResourceBasedItemConfig(
                    anchorDate: DateTime(2026, 4, 1),
                    durationDays: 5,
                    warningBefore: 1,
                  ),
                  createdAt: DateTime(2026, 4, 1),
                  updatedAt: DateTime(2026, 4, 1),
                ),
                pack: ItemPack(
                  id: 1,
                  title: 'Default Item Pack',
                  status: ItemPackStatus.active,
                  isSystemDefault: true,
                  createdAt: DateTime(2026, 4, 1),
                  updatedAt: DateTime(2026, 4, 1),
                ),
              ),
              status: ItemStatus.danger,
              elapsed: null,
            ),
          ]),
        ),
        warningHomeEntriesProvider.overrideWith(
          (ref) => Stream.value(const <ItemHomeEntry>[]),
        ),
        upcomingTimelineMilestonesProvider.overrideWith(
          (ref) => Stream.value(const <TimelineMilestoneOccurrence>[]),
        ),
      ],
    );
    addTearDown(container.dispose);
    container.read(developerDateOverrideProvider.notifier).state = previewDate;

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: HomePage()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('剩餘0日'), findsOneWidget);

    await tester.tap(find.byKey(const Key('item-expand-102')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('item-skip-102')), findsNothing);

    await tester.tap(find.byKey(const Key('item-checkbox-102')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).last, '8');
    await tester.tap(find.text(ReminderUiText.saveAction));
    await tester.pumpAndSettle();

    expect(itemRepository.recordedItemId, itemId);
    expect(itemRepository.recordedDoneAt, previewDate);
    expect(itemRepository.recordedAddedDays, 8);
  });
}

ItemHomeEntry _itemEntry({required String title, required ItemStatus status}) {
  final id = title.hashCode;
  return ItemHomeEntry(
    bundle: ItemBundle(
      item: Item(
        id: id,
        packId: 1,
        title: title,
        type: ItemType.stateBased,
        config: StateBasedItemConfig(
          anchorDate: DateTime(2026, 4, 10),
          infoAfter: Duration(days: 1),
          warningAfter: Duration(days: 1),
          dangerAfter: Duration(days: 2),
        ),
        createdAt: DateTime(2026, 4, 1),
        updatedAt: DateTime(2026, 4, 1),
      ),
      pack: ItemPack(
        id: 1,
        title: 'Default Item Pack',
        status: ItemPackStatus.active,
        isSystemDefault: true,
        createdAt: DateTime(2026, 4, 1),
        updatedAt: DateTime(2026, 4, 1),
      ),
    ),
    status: status,
    elapsed: const Duration(days: 5),
  );
}

ItemPack _defaultPack() {
  return ItemPack(
    id: 1,
    title: 'Default Item Pack',
    status: ItemPackStatus.active,
    isSystemDefault: true,
    createdAt: DateTime(2026, 4, 1),
    updatedAt: DateTime(2026, 4, 1),
  );
}

class _FakeHomeRepository extends HomeRepository {
  _FakeHomeRepository({
    required super.itemRepository,
    required super.timelineRepository,
  }) : super();

  @override
  Stream<List<ItemHomeEntry>> watchDangerItems({DateTime? now}) {
    final current = now ?? DateTime.now();
    return Stream.value([
      _itemEntry(title: 'Danger ${current.day}', status: ItemStatus.danger),
    ]);
  }

  @override
  Stream<List<ItemHomeEntry>> watchWarningItems({DateTime? now}) {
    return Stream.value(const <ItemHomeEntry>[]);
  }

  @override
  Stream<List<TimelineMilestoneOccurrence>> watchUpcomingTimelineMilestones({
    DateTime? now,
  }) {
    return Stream.value(const <TimelineMilestoneOccurrence>[]);
  }
}

class _RecordingItemRepository extends ItemRepository {
  _RecordingItemRepository(super.dao);

  int? recordedItemId;
  DateTime? recordedDoneAt;
  int? recordedAddedDays;

  @override
  Future<bool> markDone(
    int id, {
    int? addedDays,
    DateTime? doneAt,
    ItemNextCycleStrategy nextCycleStrategy =
        ItemNextCycleStrategy.keepSchedule,
    String? remark,
  }) async {
    recordedItemId = id;
    recordedDoneAt = doneAt;
    recordedAddedDays = addedDays;
    return true;
  }
}

TimelineMilestoneOccurrence _occurrence({required String title}) {
  final id = title.hashCode;
  return TimelineMilestoneOccurrence(
    recordId: id,
    timelineId: id,
    timelineTitle: title,
    ruleId: id,
    occurrenceIndex: 1,
    targetDate: DateTime(2026, 4, 10),
    label: '第 1 天',
    status: TimelineMilestoneRecordStatus.noticed,
    reminderOffsetDays: 0,
    actedAt: DateTime(2026, 4, 10),
  );
}
