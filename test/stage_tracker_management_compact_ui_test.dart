import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:reminder_app/app/theme/reminder_theme.dart';
import 'package:reminder_app/features/reminders/data/local/app_database.dart';
import 'package:reminder_app/features/reminders/data/stage_tracker_models.dart';
import 'package:reminder_app/features/reminders/domain/item_pack.dart';
import 'package:reminder_app/features/reminders/domain/stage_occurrence.dart';
import 'package:reminder_app/features/reminders/domain/stage_record.dart';
import 'package:reminder_app/features/reminders/domain/stage_rule.dart';
import 'package:reminder_app/features/reminders/domain/stage_tracker.dart';
import 'package:reminder_app/features/reminders/presentation/text/reminder_ui_text.dart';
import 'package:reminder_app/features/reminders/providers/database_providers.dart';
import 'package:reminder_app/features/reminders/providers/developer_settings_providers.dart';
import 'package:reminder_app/features/reminders/providers/item_providers.dart';
import 'package:reminder_app/features/reminders/providers/stage_tracker_providers.dart';
import 'package:reminder_app/features/reminders/ui/pages/stage_tracker_pages.dart';
import 'package:reminder_app/features/reminders/ui/widgets/reminder_components.dart';

void main() {
  testWidgets(
    'summary card uses effective preview date before reminder window',
    (tester) async {
      final fixture = _stageFixture();

      await _pumpStageTrackerManagement(
        tester,
        previewDate: DateTime(2026, 5, 19),
        trackers: fixture.trackers,
        packs: fixture.packs,
        rules: fixture.rules,
        details: fixture.details,
      );

      expect(
        find.byKey(const Key('stage-tracker-summary-card')),
        findsOneWidget,
      );
      expect(find.text('目前沒有快到的階段。'), findsOneWidget);
      expect(find.text('今日有 1 個階段快到了'), findsNothing);
    },
  );

  testWidgets(
    'summary card shows upcoming and longest tracker from preview date',
    (tester) async {
      final fixture = _stageFixture();

      await _pumpStageTrackerManagement(
        tester,
        previewDate: DateTime(2026, 5, 20),
        trackers: fixture.trackers,
        packs: fixture.packs,
        rules: fixture.rules,
        details: fixture.details,
      );

      expect(find.text('今日有 1 個階段快到了'), findsOneWidget);
      expect(find.text('最久累積：寶寶成長 90 天'), findsOneWidget);
      expect(find.text('最近更新：貓咪照顧 今天進入下一階段'), findsOneWidget);
    },
  );

  testWidgets('summary card shows compact neutral fallback', (tester) async {
    await _pumpStageTrackerManagement(
      tester,
      previewDate: DateTime(2026, 5, 20),
      trackers: const [],
      packs: const [],
      rules: const [],
      details: const {},
    );

    expect(find.byKey(const Key('stage-tracker-summary-card')), findsOneWidget);
    expect(find.text('目前沒有快到的階段。'), findsOneWidget);
    expect(find.text('持續記錄中。'), findsOneWidget);
  });

  testWidgets('stage tracker cards render a 3-column achievement grid', (
    tester,
  ) async {
    final fixture = _stageFixture();
    await _pumpStageTrackerManagement(
      tester,
      previewDate: DateTime(2026, 5, 20),
      trackers: fixture.trackers,
      packs: fixture.packs,
      rules: fixture.rules,
      details: fixture.details,
    );

    final grid = tester.widget<GridView>(
      find.byKey(const Key('stage-tracker-grid')),
    );
    final delegate =
        grid.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;

    expect(delegate.crossAxisCount, 3);
    expect(find.byKey(const Key('stage-tracker-card-1')), findsOneWidget);
    expect(find.byKey(const Key('stage-tracker-emoji-1')), findsOneWidget);
    expect(find.text('🐱'), findsOneWidget);
    expect(find.text('養貓'), findsOneWidget);
    expect(find.text('19天'), findsOneWidget);
    expect(find.text('90天'), findsOneWidget);
    expect(find.text('15天'), findsOneWidget);
    expect(find.text('寶寶'), findsOneWidget);
    expect(find.text('今日'), findsOneWidget);
    expect(find.text('持續記錄中'), findsNothing);
    expect(find.text('第4階'), findsNothing);

    final shortTitle = tester.widget<Text>(
      find.byKey(const Key('stage-tracker-short-title-1')),
    );
    expect(shortTitle.maxLines, 1);
    expect(shortTitle.overflow, TextOverflow.ellipsis);
    final accumulatedDays = tester.widget<Text>(
      find.byKey(const Key('stage-tracker-days-1')),
    );
    expect(accumulatedDays.data, '19天');
    final status = tester.widget<Text>(
      find.byKey(const Key('stage-tracker-status-1')),
    );
    expect(status.data, '今日');
    expect(find.byKey(const Key('stage-tracker-status-2')), findsNothing);

    expect(find.byType(ReminderTimelineDots), findsNothing);
    expect(find.byType(PopupMenuButton), findsNothing);
    expect(find.byType(AlertDialog), findsNothing);
    expect(find.byKey(const Key('stage-tracker-overflow-1')), findsNothing);
  });

  testWidgets('tapping card body navigates to existing detail route', (
    tester,
  ) async {
    final fixture = _stageFixture();
    await _pumpStageTrackerManagement(
      tester,
      previewDate: DateTime(2026, 5, 20),
      trackers: fixture.trackers,
      packs: fixture.packs,
      rules: fixture.rules,
      details: fixture.details,
    );

    await tester.tap(find.byKey(const Key('stage-tracker-card-1')));
    await tester.pumpAndSettle();

    expect(find.text('detail-route-1'), findsOneWidget);
  });

  testWidgets('header uses compact add icon action', (tester) async {
    await _pumpStageTrackerManagement(
      tester,
      previewDate: DateTime(2026, 5, 20),
      trackers: const [],
      packs: const [],
      rules: const [],
      details: const {},
    );

    final addButton = tester.widget<IconButton>(
      find.byKey(const Key('add-stage-tracker-button')),
    );

    expect(addButton.tooltip, ReminderUiText.addStageTracker);
    expect(
      find.widgetWithText(FilledButton, ReminderUiText.addStageTracker),
      findsNothing,
    );
  });

  testWidgets('empty state stays compact', (tester) async {
    await _pumpStageTrackerManagement(
      tester,
      previewDate: DateTime(2026, 5, 20),
      trackers: const [],
      packs: const [],
      rules: const [],
      details: const {},
    );

    expect(find.byKey(const Key('stage-tracker-empty-state')), findsOneWidget);
    expect(find.text('還沒有階段追蹤。'), findsOneWidget);
    expect(find.text('建立第一個追蹤，看看時間累積起來的樣子。'), findsOneWidget);
  });

  testWidgets('3-column achievement grid fits iPhone 15 width', (tester) async {
    final view = tester.view;
    view.physicalSize = const Size(393, 852);
    view.devicePixelRatio = 1;
    addTearDown(() {
      view.resetPhysicalSize();
      view.resetDevicePixelRatio();
    });

    final fixture = _stageFixture();
    await _pumpStageTrackerManagement(
      tester,
      previewDate: DateTime(2026, 5, 20),
      trackers: fixture.trackers,
      packs: fixture.packs,
      rules: fixture.rules,
      details: fixture.details,
    );

    expect(tester.takeException(), isNull);
    expect(find.byType(StageTrackerManagementContent), findsOneWidget);
  });
}

Future<void> _pumpStageTrackerManagement(
  WidgetTester tester, {
  required DateTime previewDate,
  required List<StageTracker> trackers,
  required List<ItemPack> packs,
  required List<StageRule> rules,
  required Map<int, StageTrackerDetail> details,
}) async {
  final db = AppDatabase.forTesting(NativeDatabase.memory());
  final router = GoRouter(
    initialLocation: StageTrackerManagementPage.routePath,
    routes: [
      GoRoute(
        path: StageTrackerManagementPage.routePath,
        name: StageTrackerManagementPage.routeName,
        builder: (context, state) => const StageTrackerManagementContent(),
      ),
      GoRoute(
        path: StageTrackerDetailPage.routePath,
        name: StageTrackerDetailPage.routeName,
        builder: (context, state) =>
            Scaffold(body: Text('detail-route-${state.pathParameters['id']}')),
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
        effectivePreviewDateProvider.overrideWith((ref) => previewDate),
        itemPacksProvider.overrideWith((ref) => Stream.value(packs)),
        stageTrackersProvider.overrideWith((ref) => Stream.value(trackers)),
        stageRulesProvider.overrideWith((ref) => Stream.value(rules)),
        stageRecordsProvider.overrideWith((ref) => Stream.value(const [])),
        stageTrackerDetailProvider.overrideWith((ref, id) async => details[id]),
      ],
      child: MaterialApp.router(
        theme: ReminderTheme.light(),
        routerConfig: router,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

_StageFixture _stageFixture() {
  final catPack = _pack(id: 1, title: '養貓', iconEmoji: '🐱');
  final babyPack = _pack(id: 2, title: '寶寶', iconEmoji: '👶');
  final plantPack = _pack(id: 3, title: '植物', iconEmoji: '🌱');
  final trackers = [
    _tracker(
      id: 1,
      packId: catPack.id,
      title: '貓咪照顧',
      start: DateTime(2026, 5, 1),
    ),
    _tracker(
      id: 2,
      packId: babyPack.id,
      title: '寶寶成長',
      start: DateTime(2026, 2, 19),
    ),
    _tracker(
      id: 3,
      packId: plantPack.id,
      title: '植物觀察',
      start: DateTime(2026, 5, 5),
    ),
  ];
  final rules = [
    _rule(
      id: 101,
      stageTrackerId: 1,
      intervalValue: 19,
      unit: StageIntervalUnit.days,
    ),
  ];
  final details = {
    1: _detail(
      trackers[0],
      next: _occurrence(
        tracker: trackers[0],
        ruleId: 101,
        index: 1,
        date: DateTime(2026, 5, 20),
      ),
    ),
    2: _detail(
      trackers[1],
      next: _occurrence(
        tracker: trackers[1],
        ruleId: 201,
        index: 4,
        date: DateTime(2026, 6, 19),
      ),
    ),
    3: _detail(trackers[2]),
  };

  return _StageFixture(
    packs: [catPack, babyPack, plantPack],
    trackers: trackers,
    rules: rules,
    details: details,
  );
}

ItemPack _pack({
  required int id,
  required String title,
  required String iconEmoji,
}) {
  return ItemPack(
    id: id,
    title: title,
    iconEmoji: iconEmoji,
    status: ItemPackStatus.active,
    isSystemDefault: false,
    createdAt: DateTime(2026, 5),
    updatedAt: DateTime(2026, 5),
  );
}

StageTracker _tracker({
  required int id,
  required int packId,
  required String title,
  required DateTime start,
}) {
  return StageTracker(
    id: id,
    packId: packId,
    title: title,
    trackingStartDate: start,
    status: StageTrackerStatus.active,
    createdAt: DateTime(2026, 5),
    updatedAt: DateTime(2026, 5),
  );
}

StageRule _rule({
  required int id,
  required int stageTrackerId,
  required int intervalValue,
  required StageIntervalUnit unit,
}) {
  return StageRule(
    id: id,
    stageTrackerId: stageTrackerId,
    type: StageRuleType.everyNDays,
    intervalValue: intervalValue,
    intervalUnit: unit,
    status: StageRuleStatus.active,
    createdAt: DateTime(2026, 5),
    updatedAt: DateTime(2026, 5),
  );
}

StageOccurrence _occurrence({
  required StageTracker tracker,
  required int ruleId,
  required int index,
  required DateTime date,
}) {
  return StageOccurrence(
    stageTrackerTitle: tracker.title,
    stageTrackerId: tracker.id,
    stageRuleId: ruleId,
    sourceType: StageRecordSourceType.generated,
    occurrenceIndex: index,
    occurrenceDate: date,
    label: '滿 $index 階',
    reminderOffsetDays: 0,
  );
}

StageTrackerDetail _detail(StageTracker tracker, {StageOccurrence? next}) {
  return StageTrackerDetail(
    stageTracker: tracker,
    stageRules: const [],
    stageRecords: const [],
    dashboardUpcomingStages: next == null ? const [] : [next],
    scheduleStages: const [],
    historyStages: const [],
  );
}

class _StageFixture {
  const _StageFixture({
    required this.packs,
    required this.trackers,
    required this.rules,
    required this.details,
  });

  final List<ItemPack> packs;
  final List<StageTracker> trackers;
  final List<StageRule> rules;
  final Map<int, StageTrackerDetail> details;
}
