import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:reminder_app/features/reminders/data/item_repository.dart';
import 'package:reminder_app/features/reminders/data/local/app_database.dart';
import 'package:reminder_app/features/reminders/data/local/item_timeline_dao.dart';
import 'package:reminder_app/features/reminders/data/timeline_models.dart';
import 'package:reminder_app/features/reminders/domain/item.dart';
import 'package:reminder_app/features/reminders/domain/item_pack.dart';
import 'package:reminder_app/features/reminders/domain/timeline.dart';
import 'package:reminder_app/features/reminders/domain/timeline_milestone_occurrence.dart';
import 'package:reminder_app/features/reminders/domain/timeline_milestone_record.dart';
import 'package:reminder_app/features/reminders/domain/timeline_milestone_rule.dart';
import 'package:reminder_app/features/reminders/presentation/text/reminder_ui_text.dart';
import 'package:reminder_app/features/reminders/providers/item_providers.dart';
import 'package:reminder_app/features/reminders/providers/timeline_providers.dart';
import 'package:reminder_app/features/reminders/ui/pages/feature_page.dart';

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
        placeholder: ReminderUiText.developerSettingsPlaceholderMessage,
      ),
    ];

    for (final testCase in testCases) {
      await tester.tap(find.byKey(Key('feature-entry-${testCase.key}')));
      await tester.pumpAndSettle();

      expect(find.text(testCase.title), findsNWidgets(2));
      expect(find.text(testCase.placeholder), findsOneWidget);

      await tester.pageBack();
      await tester.pumpAndSettle();
    }
  });

  testWidgets('placeholder pages render title and message', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: DeveloperSettingsPage()));

    expect(
      find.text(ReminderUiText.developerSettingsFeatureTitle),
      findsNWidgets(2),
    );
    expect(
      find.text(ReminderUiText.developerSettingsPlaceholderMessage),
      findsOneWidget,
    );
  });

  testWidgets('items management page only shows default pack items', (
    tester,
  ) async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);

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
        ],
        child: const MaterialApp(home: ItemsManagementPage()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('default-pack-1')), findsOneWidget);
    expect(find.byKey(const Key('add-item-button')), findsOneWidget);
    expect(find.text('Item 1'), findsOneWidget);
    expect(find.text('Item 2'), findsNothing);
  });

  testWidgets('item packs management page lists packs without nested items', (
    tester,
  ) async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);

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
        ],
        child: const MaterialApp(home: ItemPacksManagementPage()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('add-pack-button')), findsOneWidget);
    expect(find.byKey(const Key('pack-section-1')), findsOneWidget);
    expect(find.byKey(const Key('pack-section-2')), findsOneWidget);
    expect(find.text('Cat Care'), findsOneWidget);
    expect(find.text('Item 1'), findsNothing);
    expect(find.text('Item 2'), findsNothing);
  });

  testWidgets('timeline management page shows timeline actions', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
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
        ],
        child: const MaterialApp(home: TimelineManagementPage()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('add-timeline-button')), findsOneWidget);
    expect(find.text('No sugar'), findsOneWidget);
    expect(find.byKey(const Key('timeline-edit-9')), findsOneWidget);
    expect(find.byKey(const Key('timeline-history-9')), findsOneWidget);
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
}) {
  final config = switch (type) {
    ItemType.stateBased => const StateBasedItemConfig(
      expectedInterval: Duration(days: 7),
      warningAfter: Duration(days: 7),
      dangerAfter: Duration(days: 14),
    ),
    ItemType.resourceBased => const ResourceBasedItemConfig(
      estimatedDuration: Duration(days: 30),
      warningBeforeDepletion: Duration(days: 7),
    ),
    ItemType.fixedTime => FixedTimeItemConfig(
      scheduleType: FixedTimeScheduleType.daily,
      anchorDate: DateTime(2026, 4, 10),
    ),
  };
  return ItemBundle(
    item: Item(
      id: id,
      packId: packId,
      title: 'Item $id',
      type: type,
      config: config,
      lastDoneAt: DateTime(2026, 4, 10),
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
