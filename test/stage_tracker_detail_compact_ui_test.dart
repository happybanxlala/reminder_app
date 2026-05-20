import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:reminder_app/app/theme/reminder_theme.dart';
import 'package:reminder_app/features/reminders/data/item_repository.dart';
import 'package:reminder_app/features/reminders/data/local/app_database.dart';
import 'package:reminder_app/features/reminders/data/stage_tracker_models.dart';
import 'package:reminder_app/features/reminders/data/stage_tracker_repository.dart';
import 'package:reminder_app/features/reminders/domain/stage_occurrence.dart';
import 'package:reminder_app/features/reminders/domain/stage_record.dart';
import 'package:reminder_app/features/reminders/domain/stage_related_item.dart';
import 'package:reminder_app/features/reminders/domain/stage_rule.dart';
import 'package:reminder_app/features/reminders/domain/stage_tracker.dart';
import 'package:reminder_app/features/reminders/providers/database_providers.dart';
import 'package:reminder_app/features/reminders/providers/developer_settings_providers.dart';
import 'package:reminder_app/features/reminders/providers/stage_tracker_providers.dart';
import 'package:reminder_app/features/reminders/ui/pages/stage_tracker_pages.dart';
import 'package:reminder_app/features/reminders/ui/widgets/reminder_components.dart';

void main() {
  testWidgets('detail app bar has back and overflow without fixed title', (
    tester,
  ) async {
    await _pumpDetail(tester, detail: _detailWithPendingAndUpcoming());

    expect(find.byType(BackButton), findsOneWidget);
    expect(
      find.byKey(const Key('stage-tracker-detail-overflow')),
      findsOneWidget,
    );
    expect(find.text('階段追蹤'), findsNothing);

    await tester.tap(find.byKey(const Key('stage-tracker-detail-overflow')));
    await tester.pumpAndSettle();

    expect(find.text('完整時間線'), findsOneWidget);

    await tester.tap(find.text('完整時間線'));
    await tester.pumpAndSettle();

    expect(find.text('完整時間線'), findsOneWidget);
    expect(
      find.byKey(const Key('stage-tracker-timeline-page')),
      findsOneWidget,
    );
  });

  testWidgets('compact hero shows title, accumulated days, pending and next', (
    tester,
  ) async {
    await _pumpDetail(tester, detail: _detailWithPendingAndUpcoming());

    expect(find.byKey(const Key('stage-tracker-detail-hero')), findsOneWidget);
    expect(find.text('寶寶成長'), findsOneWidget);
    expect(find.text('已累積 19 天'), findsOneWidget);
    expect(find.text('待確認：滿 18 天'), findsOneWidget);
    expect(find.textContaining('最近經歷'), findsNothing);
    expect(find.text('下一階段：成貓期・明日'), findsOneWidget);
    expect(find.byType(ReminderTimelineDots), findsNothing);
    expect(find.text('開始'), findsNothing);
    expect(find.text('現在'), findsNothing);
    expect(find.text('下一步'), findsNothing);
    expect(find.text('之後'), findsNothing);
  });

  testWidgets(
    'compact hero shows acknowledged occurrence as recent experience',
    (tester) async {
      await _pumpDetail(tester, detail: _detailAcknowledgedOnly());

      expect(find.text('最近經歷：滿 10 天'), findsOneWidget);
      expect(find.textContaining('待確認'), findsNothing);
    },
  );

  testWidgets('upcoming section is merged and de-duplicated', (tester) async {
    await _pumpDetail(tester, detail: _detailWithPendingAndUpcoming());

    expect(find.text('即將到來'), findsOneWidget);
    expect(find.text('下一個階段'), findsNothing);
    expect(find.text('即將到來的階段'), findsNothing);
    expect(find.text('成貓期'), findsOneWidget);
    expect(find.text('疫苗提醒'), findsOneWidget);
  });

  testWidgets('upcoming rows are compact and switch related action icons', (
    tester,
  ) async {
    await _pumpDetail(tester, detail: _detailWithPendingAndUpcoming());

    expect(find.byType(ReminderIconBubble), findsNothing);
    expect(find.byType(ListTile), findsNothing);
    expect(
      find.byKey(const Key('detail-add-related-rule-101-1')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('detail-view-related-record-302')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const Key('detail-view-related-record-302')));
    await tester.pumpAndSettle();

    expect(find.text('相關提醒'), findsOneWidget);
    expect(find.text('相關提醒：1 / 2 已完成'), findsOneWidget);

    await tester.tap(find.text('關閉'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('detail-add-related-rule-101-1')));
    await tester.pumpAndSettle();

    expect(find.text('建立相關提醒'), findsOneWidget);
  });

  testWidgets('zero related item summary is hidden from compact rows', (
    tester,
  ) async {
    final tracker = _tracker();
    await _pumpDetail(
      tester,
      detail: StageTrackerDetail(
        stageTracker: tracker,
        stageRules: const [],
        stageRecords: const [],
        dashboardUpcomingStages: [
          _manualOccurrence(
            tracker,
            recordId: 303,
            date: DateTime(2026, 5, 21),
            label: '沒有相關提醒的階段',
            summary: const StageRelatedItemSummary(),
          ),
        ],
        scheduleStages: const [],
        historyStages: const [],
      ),
    );

    expect(find.textContaining('相關提醒：0 / 0'), findsNothing);
    expect(
      find.byKey(const Key('detail-add-related-record-303')),
      findsOneWidget,
    );
  });

  testWidgets('large action buttons are replaced by compact add-stage entry', (
    tester,
  ) async {
    await _pumpDetail(tester, detail: _detailWithPendingAndUpcoming());

    expect(find.byKey(const Key('detail-add-stage-action')), findsOneWidget);
    expect(find.widgetWithText(FilledButton, '加入重複階段'), findsNothing);
    expect(find.widgetWithText(FilledButton, '新增重要階段'), findsNothing);
    expect(find.widgetWithText(OutlinedButton, '查看完整時間表'), findsNothing);
    expect(find.widgetWithText(OutlinedButton, '查看歷史'), findsNothing);

    await tester.tap(find.byKey(const Key('detail-add-stage-action')));
    await tester.pumpAndSettle();

    expect(find.text('加入階段'), findsWidgets);
    expect(find.text('重要階段'), findsOneWidget);
    expect(find.text('重複階段'), findsWidgets);
    expect(find.byKey(const Key('add-important-stage-choice')), findsNothing);
    expect(find.byKey(const Key('add-stage-rule-choice')), findsNothing);
  });

  testWidgets('stage entry dialog submits important and recurring stages', (
    tester,
  ) async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    final repository = _RecordingStageTrackerRepository(db);
    await _pumpDetail(
      tester,
      detail: _emptyDetail(),
      database: db,
      repository: repository,
    );

    await tester.tap(find.byKey(const Key('detail-add-stage-action')));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.enterText(
      find.byKey(const Key('important-stage-title-field')),
      '第一次回診',
    );
    await tester.tap(find.text('新增重要階段'));
    await tester.pump(const Duration(milliseconds: 500));

    expect(repository.importantStages.single.label, '第一次回診');

    await tester.tap(find.byKey(const Key('detail-add-stage-action')));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.widgetWithText(Tab, '重複階段'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('stage-rule-interval-field')),
      '2',
    );
    await tester.tap(find.widgetWithText(FilledButton, '加入重複階段'));
    await tester.pump(const Duration(milliseconds: 500));

    expect(repository.stageRules.single.intervalValue, 2);
  });

  testWidgets(
    'repeat-rule empty state opens stage entry dialog on recurring tab',
    (tester) async {
      await _pumpDetail(tester, detail: _emptyDetail());

      await tester.tap(find.byKey(const Key('stage-rule-empty-add-action')));
      await tester.pumpAndSettle();

      expect(find.text('加入階段'), findsWidgets);
      expect(
        find.byKey(const Key('stage-rule-interval-field')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('important-stage-title-field')),
        findsNothing,
      );
    },
  );

  testWidgets('stage rules use compact rows with overflow only', (
    tester,
  ) async {
    await _pumpDetail(tester, detail: _detailWithPendingAndUpcoming());

    expect(find.byKey(const Key('stage-rule-row-201')), findsOneWidget);
    expect(find.byKey(const Key('stage-rule-overflow-201')), findsOneWidget);
    expect(find.byIcon(Icons.edit_outlined), findsNothing);
    expect(find.byIcon(Icons.pause_outlined), findsNothing);
  });

  testWidgets('timeline page groups, sorts, de-duplicates, and shows actions', (
    tester,
  ) async {
    await _pumpTimeline(tester, detail: _detailWithPendingAndUpcoming());

    expect(find.text('完整時間線'), findsOneWidget);
    expect(find.text('即將到來'), findsOneWidget);
    expect(find.text('已經歷'), findsOneWidget);
    expect(find.text('成貓期'), findsOneWidget);
    expect(find.text('兩週後'), findsOneWidget);
    expect(find.text('疫苗提醒'), findsOneWidget);
    expect(find.textContaining('重要階段'), findsWidgets);
    expect(find.textContaining('重複階段'), findsWidgets);
    expect(find.textContaining('相關提醒：1 / 2 已完成'), findsOneWidget);
    expect(
      find.byKey(const Key('timeline-add-related-rule-101-1')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('timeline-view-related-record-302')),
      findsOneWidget,
    );

    final upcomingLabels = tester
        .widgetList<Text>(
          find.descendant(
            of: find.byKey(const Key('stage-tracker-timeline-page')),
            matching: find.byType(Text),
          ),
        )
        .map((widget) => widget.data)
        .whereType<String>()
        .toList();
    expect(
      upcomingLabels.indexOf('成貓期'),
      lessThan(upcomingLabels.indexOf('兩週後')),
    );
    expect(
      upcomingLabels.indexOf('兩週後'),
      lessThan(upcomingLabels.indexOf('疫苗提醒')),
    );
    expect(
      upcomingLabels.indexOf('滿 18 天'),
      lessThan(upcomingLabels.indexOf('滿 10 天')),
    );

    await tester.tap(find.byKey(const Key('timeline-view-related-record-302')));
    await tester.pumpAndSettle();

    expect(find.text('相關提醒'), findsOneWidget);
    expect(find.textContaining('相關提醒：1 / 2 已完成'), findsWidgets);
  });

  testWidgets('legacy schedule and history routes still render', (
    tester,
  ) async {
    await _pumpLegacyRoutes(tester, detail: _detailWithPendingAndUpcoming());

    expect(find.text('legacy-root'), findsOneWidget);

    await tester.tap(find.text('open schedule'));
    await tester.pumpAndSettle();
    expect(find.text('完整時間表'), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();

    await tester.tap(find.text('open history'));
    await tester.pumpAndSettle();
    expect(find.text('階段追蹤紀錄'), findsOneWidget);
  });

  testWidgets('compact empty states fit phone width', (tester) async {
    final view = tester.view;
    view.physicalSize = const Size(393, 852);
    view.devicePixelRatio = 1;
    addTearDown(() {
      view.resetPhysicalSize();
      view.resetDevicePixelRatio();
    });

    await _pumpDetail(tester, detail: _emptyDetail());

    expect(find.byKey(const Key('detail-upcoming-empty')), findsOneWidget);
    expect(find.byKey(const Key('stage-rule-empty-state')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

Future<void> _pumpDetail(
  WidgetTester tester, {
  required StageTrackerDetail detail,
  AppDatabase? database,
  StageTrackerRepository? repository,
}) async {
  final db = database ?? AppDatabase.forTesting(NativeDatabase.memory());
  final router = GoRouter(
    initialLocation: '/root',
    routes: [
      GoRoute(
        path: '/root',
        builder: (context, state) => Scaffold(
          body: Center(
            child: FilledButton(
              onPressed: () => context.pushNamed(
                StageTrackerDetailPage.routeName,
                pathParameters: {'id': '1'},
              ),
              child: const Text('open detail'),
            ),
          ),
        ),
      ),
      GoRoute(
        path: StageTrackerDetailPage.routePath,
        name: StageTrackerDetailPage.routeName,
        builder: (context, state) =>
            const StageTrackerDetailPage(stageTrackerId: 1),
      ),
      GoRoute(
        path: StageTrackerTimelinePage.routePath,
        name: StageTrackerTimelinePage.routeName,
        builder: (context, state) =>
            const StageTrackerTimelinePage(stageTrackerId: 1),
      ),
      GoRoute(
        path: StageTrackerSchedulePage.routePath,
        name: StageTrackerSchedulePage.routeName,
        builder: (context, state) => Scaffold(
          body: Text('schedule-route-${state.pathParameters['id']}'),
        ),
      ),
      GoRoute(
        path: StageTrackerManagementPage.routePath,
        name: StageTrackerManagementPage.routeName,
        builder: (context, state) => const Scaffold(body: Text('overview')),
      ),
    ],
  );
  addTearDown(() async {
    router.dispose();
    await db.close();
  });

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        if (repository != null)
          stageTrackerRepositoryProvider.overrideWithValue(repository),
        effectivePreviewDateProvider.overrideWith(
          (ref) => DateTime(2026, 5, 20),
        ),
        stageTrackerDetailProvider.overrideWith((ref, id) async => detail),
      ],
      child: MaterialApp.router(
        theme: ReminderTheme.light(),
        routerConfig: router,
      ),
    ),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.text('open detail'));
  await tester.pumpAndSettle();
}

Future<void> _pumpTimeline(
  WidgetTester tester, {
  required StageTrackerDetail detail,
}) async {
  final db = AppDatabase.forTesting(NativeDatabase.memory());
  final router = GoRouter(
    initialLocation: '/stage-tracker/1/timeline',
    routes: [
      GoRoute(
        path: StageTrackerTimelinePage.routePath,
        name: StageTrackerTimelinePage.routeName,
        builder: (context, state) =>
            const StageTrackerTimelinePage(stageTrackerId: 1),
      ),
    ],
  );
  addTearDown(() async {
    router.dispose();
    await db.close();
  });

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        effectivePreviewDateProvider.overrideWith(
          (ref) => DateTime(2026, 5, 20),
        ),
        stageTrackerDetailProvider.overrideWith((ref, id) async => detail),
      ],
      child: MaterialApp.router(
        theme: ReminderTheme.light(),
        routerConfig: router,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _pumpLegacyRoutes(
  WidgetTester tester, {
  required StageTrackerDetail detail,
}) async {
  final db = AppDatabase.forTesting(NativeDatabase.memory());
  final router = GoRouter(
    initialLocation: '/legacy-root',
    routes: [
      GoRoute(
        path: '/legacy-root',
        builder: (context, state) => Scaffold(
          body: Column(
            children: [
              const Text('legacy-root'),
              TextButton(
                onPressed: () => context.pushNamed(
                  StageTrackerSchedulePage.routeName,
                  pathParameters: {'id': '1'},
                ),
                child: const Text('open schedule'),
              ),
              TextButton(
                onPressed: () => context.pushNamed(
                  StageTrackerHistoryPage.routeName,
                  pathParameters: {'id': '1'},
                ),
                child: const Text('open history'),
              ),
            ],
          ),
        ),
      ),
      GoRoute(
        path: StageTrackerSchedulePage.routePath,
        name: StageTrackerSchedulePage.routeName,
        builder: (context, state) =>
            const StageTrackerSchedulePage(stageTrackerId: 1),
      ),
      GoRoute(
        path: StageTrackerHistoryPage.routePath,
        name: StageTrackerHistoryPage.routeName,
        builder: (context, state) =>
            const StageTrackerHistoryPage(stageTrackerId: 1),
      ),
    ],
  );
  addTearDown(() async {
    router.dispose();
    await db.close();
  });

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        effectivePreviewDateProvider.overrideWith(
          (ref) => DateTime(2026, 5, 20),
        ),
        stageTrackerDetailProvider.overrideWith((ref, id) async => detail),
      ],
      child: MaterialApp.router(
        theme: ReminderTheme.light(),
        routerConfig: router,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

class _RecordingStageTrackerRepository extends StageTrackerRepository {
  _RecordingStageTrackerRepository(AppDatabase db)
    : super(db.reminderDao, itemRepository: ItemRepository(db.reminderDao));

  final importantStages = <ManualStageInput>[];
  final stageRules = <StageRuleInput>[];

  @override
  Future<int> createImportantStage(
    int stageTrackerId,
    ManualStageInput input,
  ) async {
    importantStages.add(input);
    return importantStages.length;
  }

  @override
  Future<int> createStageRule(int stageTrackerId, StageRuleInput input) async {
    stageRules.add(input);
    return stageRules.length;
  }
}

StageTrackerDetail _detailWithPendingAndUpcoming() {
  final tracker = _tracker();
  final next = _generatedOccurrence(
    tracker,
    ruleId: 101,
    index: 1,
    date: DateTime(2026, 5, 21),
    label: '成貓期',
  );
  final related = _manualOccurrence(
    tracker,
    recordId: 302,
    date: DateTime(2026, 6, 1),
    label: '疫苗提醒',
    summary: const StageRelatedItemSummary(doneCount: 1, activeCount: 1),
  );
  final later = _generatedOccurrence(
    tracker,
    ruleId: 101,
    index: 2,
    date: DateTime(2026, 5, 23),
    label: '兩週後',
  );
  return StageTrackerDetail(
    stageTracker: tracker,
    stageRules: [
      StageRule(
        id: 201,
        stageTrackerId: tracker.id,
        type: StageRuleType.everyNWeeks,
        intervalValue: 1,
        intervalUnit: StageIntervalUnit.weeks,
        labelTemplate: '第 {value} {unit}',
        status: StageRuleStatus.active,
        createdAt: DateTime(2026, 5),
        updatedAt: DateTime(2026, 5),
      ),
    ],
    stageRecords: const [],
    dashboardUpcomingStages: [next, related],
    scheduleStages: [next, later],
    historyStages: [
      _manualOccurrence(
        tracker,
        recordId: 401,
        date: DateTime(2026, 5, 18),
        label: '滿 18 天',
        status: StageRecordStatus.normal,
      ),
      _manualOccurrence(
        tracker,
        recordId: 402,
        date: DateTime(2026, 5, 10),
        label: '滿 10 天',
        status: StageRecordStatus.acknowledged,
      ),
    ],
  );
}

StageTrackerDetail _detailAcknowledgedOnly() {
  final tracker = _tracker();
  return StageTrackerDetail(
    stageTracker: tracker,
    stageRules: const [],
    stageRecords: const [],
    dashboardUpcomingStages: const [],
    scheduleStages: const [],
    historyStages: [
      _manualOccurrence(
        tracker,
        recordId: 402,
        date: DateTime(2026, 5, 10),
        label: '滿 10 天',
        status: StageRecordStatus.acknowledged,
      ),
    ],
  );
}

StageTrackerDetail _emptyDetail() {
  return StageTrackerDetail(
    stageTracker: _tracker(),
    stageRules: const [],
    stageRecords: const [],
    dashboardUpcomingStages: const [],
    scheduleStages: const [],
    historyStages: const [],
  );
}

StageTracker _tracker() {
  return StageTracker(
    id: 1,
    packId: 1,
    title: '寶寶成長',
    trackingStartDate: DateTime(2026, 5, 1),
    status: StageTrackerStatus.active,
    createdAt: DateTime(2026, 5),
    updatedAt: DateTime(2026, 5),
  );
}

StageOccurrence _generatedOccurrence(
  StageTracker tracker, {
  required int ruleId,
  required int index,
  required DateTime date,
  required String label,
}) {
  return StageOccurrence(
    stageTrackerId: tracker.id,
    stageTrackerTitle: tracker.title,
    stageRuleId: ruleId,
    sourceType: StageRecordSourceType.generated,
    occurrenceIndex: index,
    occurrenceDate: date,
    label: label,
    reminderOffsetDays: 0,
  );
}

StageOccurrence _manualOccurrence(
  StageTracker tracker, {
  required int recordId,
  required DateTime date,
  required String label,
  StageRecordStatus status = StageRecordStatus.normal,
  StageRelatedItemSummary? summary,
}) {
  return StageOccurrence(
    stageTrackerId: tracker.id,
    stageTrackerTitle: tracker.title,
    stageRecordId: recordId,
    sourceType: StageRecordSourceType.manual,
    occurrenceDate: date,
    label: label,
    reminderOffsetDays: 0,
    recordStatus: status,
    relatedItemSummary: summary,
  );
}
