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
import 'package:reminder_app/features/reminders/ui/pages/item_edit_page.dart';

void main() {
  testWidgets('feature page shows all feature entries', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: FeaturePage()));

    expect(find.text(ReminderUiText.itemActivityFeatureTitle), findsOneWidget);
    expect(
      find.text(ReminderUiText.itemsManagementFeatureTitle),
      findsOneWidget,
    );
    expect(
      find.text(ReminderUiText.itemPacksManagementFeatureTitle),
      findsOneWidget,
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

  testWidgets('feature page routes each entry to its placeholder page', (
    tester,
  ) async {
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
          activeItemPacksProvider.overrideWith(
            (ref) => Stream.value([
              _pack(1, title: 'Default Item Pack', isSystemDefault: true),
              _pack(2, title: 'Cat Care'),
            ]),
          ),
          itemsProvider.overrideWith(
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
          timelineDetailProvider(9).overrideWith(
            (ref) => Future.value(
              TimelineDetail(
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
              ),
            ),
          ),
          previewTimelineDetailProvider(9).overrideWith(
            (ref) => Future.value(
              TimelineDetail(
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
              ),
            ),
          ),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    final testCases = <_FeatureRouteCase>[
      const _FeatureRouteCase(
        key: 'item-activity',
        title: ReminderUiText.itemActivityFeatureTitle,
        placeholder: ReminderUiText.itemActivityPlaceholderMessage,
      ),
      const _FeatureRouteCase(
        key: 'items-management',
        title: ReminderUiText.itemsManagementFeatureTitle,
        placeholder: 'Item 1',
      ),
      const _FeatureRouteCase(
        key: 'item-packs-management',
        title: ReminderUiText.itemPacksManagementFeatureTitle,
        placeholder: 'Cat Care',
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

    for (final testCase in testCases) {
      await tester.tap(find.byKey(Key('feature-entry-${testCase.key}')));
      await tester.pumpAndSettle();

      expect(find.text(testCase.title), findsAtLeastNWidgets(1));
      expect(find.text(testCase.placeholder), findsOneWidget);

      await tester.pageBack();
      await tester.pumpAndSettle();
    }
  });

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

  testWidgets('items management page only shows default pack items', (
    tester,
  ) async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final container = ProviderContainer(
      overrides: [
        itemRepositoryProvider.overrideWith(
          (ref) => ItemRepository(db.itemTimelineDao),
        ),
        activeItemPacksProvider.overrideWith(
          (ref) => Stream.value([
            _pack(1, title: 'Default Item Pack', isSystemDefault: true),
            _pack(2, title: 'Cat Care'),
          ]),
        ),
        itemsProvider.overrideWith(
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
    container.read(developerDateOverrideProvider.notifier).state = DateTime(
      2026,
      4,
      11,
    );

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: ItemsManagementPage()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('default-pack-1')), findsOneWidget);
    expect(find.byKey(const Key('add-item-button')), findsOneWidget);
    expect(find.text('Item 1'), findsOneWidget);
    expect(find.text('Item 2'), findsNothing);
    expect(find.text('穩定'), findsOneWidget);

    container.read(developerDateOverrideProvider.notifier).state = DateTime(
      2026,
      4,
      25,
    );
    await tester.pumpAndSettle();

    expect(find.text('快變糟'), findsOneWidget);
  });

  testWidgets(
    'items management complete action forwards preview date for state baseline',
    (tester) async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);
      final repository = _RecordingItemRepository(db.itemTimelineDao);
      final previewDate = DateTime(2026, 4, 11);
      const itemId = 1;
      final container = ProviderContainer(
        overrides: [
          itemRepositoryProvider.overrideWith((ref) => repository),
          activeItemPacksProvider.overrideWith(
            (ref) => Stream.value([
              _pack(1, title: 'Default Item Pack', isSystemDefault: true),
            ]),
          ),
          itemsProvider.overrideWith(
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

      await tester.tap(find.byKey(Key('item-done-$itemId')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(repository.recordedItemId, itemId);
      expect(repository.recordedDoneAt, previewDate);
    },
  );

  testWidgets(
    'items management hides skip for resource items and requires added days',
    (tester) async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);
      final repository = _RecordingItemRepository(db.itemTimelineDao);
      final previewDate = DateTime(2026, 4, 11);
      const itemId = 3;
      final container = ProviderContainer(
        overrides: [
          itemRepositoryProvider.overrideWith((ref) => repository),
          activeItemPacksProvider.overrideWith(
            (ref) => Stream.value([
              _pack(1, title: 'Default Item Pack', isSystemDefault: true),
            ]),
          ),
          itemsProvider.overrideWith(
            (ref) =>
                Stream.value([_itemBundle(itemId, ItemType.resourceBased)]),
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

      expect(find.byKey(Key('item-skip-$itemId')), findsNothing);

      await tester.tap(find.byKey(Key('item-done-$itemId')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField).last, '12');
      await tester.tap(find.text(ReminderUiText.saveAction));
      await tester.pumpAndSettle();

      expect(repository.recordedItemId, itemId);
      expect(repository.recordedDoneAt, previewDate);
      expect(repository.recordedAddedDays, 12);
    },
  );

  testWidgets('items management routes add and edit into locked pack editor', (
    tester,
  ) async {
    final router = GoRouter(
      initialLocation: ItemsManagementPage.routePath,
      routes: [
        GoRoute(
          path: ItemsManagementPage.routePath,
          name: ItemsManagementPage.routeName,
          builder: (context, state) => const ItemsManagementPage(),
        ),
        GoRoute(
          path: ItemEditPage.createRoutePath,
          name: ItemEditPage.createRouteName,
          builder: (context, state) => ItemEditPage(
            mode: ItemEditMode.create,
            lockedPackId: state.extra as int?,
          ),
        ),
        GoRoute(
          path: ItemEditPage.editRoutePath,
          name: ItemEditPage.editRouteName,
          builder: (context, state) => ItemEditPage(
            mode: ItemEditMode.edit,
            id: int.parse(state.pathParameters['id']!),
            lockedPackId: state.extra as int?,
          ),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          activeItemPacksProvider.overrideWith(
            (ref) => Stream.value([
              _pack(1, title: 'Default Item Pack', isSystemDefault: true),
              _pack(2, title: 'Cat Care'),
            ]),
          ),
          itemsProvider.overrideWith(
            (ref) => Stream.value([_itemBundle(1, ItemType.stateBased)]),
          ),
          itemProvider(1).overrideWith(
            (ref) => Future.value(_itemBundle(1, ItemType.stateBased)),
          ),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('add-item-button')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('pack-field')), findsNothing);

    await tester.pageBack();
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('item-edit-1')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('pack-field')), findsNothing);
  });

  testWidgets(
    'item packs management page shows nested active and paused items',
    (tester) async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);
      final container = ProviderContainer(
        overrides: [
          itemRepositoryProvider.overrideWith(
            (ref) => ItemRepository(db.itemTimelineDao),
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
      container.read(developerDateOverrideProvider.notifier).state = DateTime(
        2026,
        4,
        11,
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: ItemPacksManagementPage()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('add-pack-button')), findsOneWidget);
      expect(find.byKey(const Key('pack-section-1')), findsOneWidget);
      expect(find.byKey(const Key('pack-section-2')), findsOneWidget);
      expect(find.text('Cat Care'), findsOneWidget);
      expect(find.text('Item 1'), findsOneWidget);
      expect(find.text('Item 2'), findsOneWidget);
      expect(find.text('Item 3'), findsOneWidget);
      expect(find.byKey(const Key('pack-add-item-2')), findsOneWidget);
      expect(find.byKey(const Key('pack-item-edit-2')), findsOneWidget);
      expect(find.byKey(const Key('pack-item-pause-2')), findsOneWidget);
      expect(find.byKey(const Key('pack-item-resume-3')), findsOneWidget);
    },
  );

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
}) {
  final config = switch (type) {
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
      title: 'Item $id',
      status: lifecycleStatus,
      type: type,
      config: config,
      createdAt: DateTime(2026, 4, 1),
      updatedAt: DateTime(2026, 4, 1),
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
