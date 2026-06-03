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
      expect(find.text('最久累積：寶寶成長 第91天'), findsOneWidget);
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
    expect(find.text('貓咪照顧'), findsOneWidget);
    expect(find.text('養貓'), findsNothing);
    expect(find.text('第20天'), findsOneWidget);
    expect(find.text('第91天'), findsOneWidget);
    expect(find.text('第16天'), findsOneWidget);
    expect(find.text('寶寶成長'), findsWidgets);
    expect(find.text('今天'), findsOneWidget);
    expect(find.text('持續中'), findsNothing);
    expect(find.text('第4階'), findsNothing);

    final shortTitle = tester.widget<Text>(
      find.byKey(const Key('stage-tracker-short-title-1')),
    );
    expect(shortTitle.maxLines, 1);
    expect(shortTitle.overflow, TextOverflow.ellipsis);
    final accumulatedDays = tester.widget<Text>(
      find.byKey(const Key('stage-tracker-days-1')),
    );
    expect(accumulatedDays.data, '第20天');
    final status = tester.widget<Text>(
      find.byKey(const Key('stage-tracker-status-1')),
    );
    expect(status.data, '今天');
    expect(find.byKey(const Key('stage-tracker-status-2')), findsNothing);
    expect(find.byKey(const Key('stage-tracker-status-3')), findsNothing);

    expect(find.byType(ReminderTimelineDots), findsNothing);
    expect(find.byType(PopupMenuButton), findsNothing);
    expect(find.byType(AlertDialog), findsNothing);
    expect(find.byKey(const Key('stage-tracker-overflow-1')), findsNothing);
  });

  testWidgets('tracker cards keep tracker titles and nearest status labels', (
    tester,
  ) async {
    final previewDate = DateTime(2026, 5, 20);
    final packs = [
      _pack(id: 1, title: '工作', iconEmoji: '💼'),
      _pack(id: 2, title: '貓', iconEmoji: '🐱'),
      _pack(id: 3, title: '植', iconEmoji: '🌱'),
      _pack(id: 4, title: '空', iconEmoji: '📌'),
      _pack(id: 5, title: '舊', iconEmoji: '🗂️'),
      _pack(id: 6, title: '停', iconEmoji: '⏹️'),
    ];
    final trackers = [
      _tracker(
        id: 1,
        packId: 1,
        title: 'ReminderApp',
        start: DateTime(2026, 5, 25),
      ),
      _tracker(id: 2, packId: 2, title: '貓咪成長', start: DateTime(2026, 5, 15)),
      _tracker(id: 3, packId: 3, title: '植物觀察', start: DateTime(2026, 1, 12)),
      _tracker(id: 4, packId: 4, title: '', start: DateTime(2026, 5, 1)),
      _tracker(
        id: 5,
        packId: 5,
        title: '封存追蹤',
        start: DateTime(2026, 5, 1),
        status: StageTrackerStatus.archived,
      ),
      _tracker(
        id: 6,
        packId: 6,
        title: '停止追蹤',
        start: DateTime(2026, 5, 1),
        end: DateTime(2026, 5, 10),
      ),
    ];
    final attentionOccurrences = [
      _occurrence(tracker: trackers[0], ruleId: 1, index: 1, date: previewDate),
      _occurrence(
        tracker: trackers[1],
        ruleId: 2,
        index: 1,
        date: previewDate.add(const Duration(days: 1)),
      ),
      _occurrence(
        tracker: trackers[2],
        ruleId: 3,
        index: 1,
        date: previewDate.add(const Duration(days: 3)),
      ),
    ];
    await _pumpStageTrackerManagement(
      tester,
      previewDate: previewDate,
      trackers: trackers,
      packs: packs,
      rules: const [],
      details: {for (final tracker in trackers) tracker.id: _detail(tracker)},
      attentionOccurrences: attentionOccurrences,
    );

    expect(find.text('第1天'), findsOneWidget);
    expect(find.text('第129天'), findsOneWidget);
    expect(find.text('ReminderApp'), findsOneWidget);
    expect(find.text('工作'), findsNothing);
    expect(
      tester
          .widget<Text>(find.byKey(const Key('stage-tracker-short-title-4')))
          .data,
      ReminderUiText.stageTrackerLabel,
    );

    expect(
      tester.widget<Text>(find.byKey(const Key('stage-tracker-status-1'))).data,
      '今天',
    );
    expect(
      tester.widget<Text>(find.byKey(const Key('stage-tracker-status-2'))).data,
      '明天',
    );
    expect(
      tester.widget<Text>(find.byKey(const Key('stage-tracker-status-3'))).data,
      '3天後',
    );
    expect(find.byKey(const Key('stage-tracker-status-4')), findsNothing);
    expect(find.byKey(const Key('stage-tracker-status-5')), findsNothing);
    expect(find.byKey(const Key('stage-tracker-status-6')), findsNothing);
    expect(find.text('持續中'), findsNothing);
    expect(find.text('已封存'), findsNothing);
    expect(find.text('已停止'), findsNothing);

    expect(find.byType(ReminderTimelineDots), findsNothing);
  });

  testWidgets('tracker cards use next rule occurrence as nearest status', (
    tester,
  ) async {
    final previewDate = DateTime(2026, 5, 20);
    final pack = _pack(id: 1, title: '植物', iconEmoji: '🌱');
    final tracker = _tracker(
      id: 1,
      packId: pack.id,
      title: '植物觀察',
      start: DateTime(2026, 5, 18),
    );

    await _pumpStageTrackerManagement(
      tester,
      previewDate: previewDate,
      trackers: [tracker],
      packs: [pack],
      rules: [
        _rule(
          id: 101,
          stageTrackerId: tracker.id,
          intervalValue: 3,
          unit: StageIntervalUnit.days,
        ),
      ],
      details: {tracker.id: _detail(tracker)},
    );

    expect(find.text('植物觀察'), findsOneWidget);
    expect(
      tester.widget<Text>(find.byKey(const Key('stage-tracker-status-1'))).data,
      '明天',
    );
    expect(find.text('滿 1 階'), findsNothing);
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

  testWidgets('overview uses content add action and dashed onboarding card', (
    tester,
  ) async {
    await _pumpStageTrackerManagement(
      tester,
      previewDate: DateTime(2026, 5, 20),
      trackers: const [],
      packs: const [],
      rules: const [],
      details: const {},
    );

    expect(find.byKey(const Key('add-stage-tracker-button')), findsNothing);
    expect(
      find.byKey(const Key('stage-tracker-content-add-button')),
      findsOneWidget,
    );
    expect(find.byType(RefreshIndicator), findsOneWidget);
    expect(
      find.byKey(const Key('stage-tracker-dashed-add-card')),
      findsOneWidget,
    );
    expect(
      find.widgetWithText(FilledButton, ReminderUiText.addStageTracker),
      findsNothing,
    );
  });

  testWidgets('create dialog uses editor sections and live preview', (
    tester,
  ) async {
    final fixture = _stageFixture();
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    final repository = _RecordingStageTrackerRepository(db);
    await _pumpStageTrackerManagement(
      tester,
      previewDate: DateTime(2026, 5, 20),
      trackers: const [],
      packs: fixture.packs,
      rules: const [],
      details: const {},
      database: db,
      repository: repository,
    );

    await tester.tap(find.byKey(const Key('stage-tracker-content-add-button')));
    await tester.pumpAndSettle();

    expect(find.text(ReminderUiText.addStageTracker), findsAtLeastNWidgets(1));
    expect(find.byKey(const Key('stage-tracker-preview-card')), findsOneWidget);
    expect(
      find.text(ReminderUiText.stageTrackerPreviewFallbackTitle),
      findsOneWidget,
    );
    expect(
      find.text(ReminderUiText.stageTrackerBasicSectionTitle),
      findsOneWidget,
    );
    expect(
      find.text(ReminderUiText.stageTrackerTrackingSettingsTitle),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('stage-tracker-pack-picker-row')),
      findsOneWidget,
    );
    expect(find.byType(DropdownButtonFormField<int?>), findsNothing);
    expect(
      find.byKey(const Key('stage-tracker-start-date-row')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('stage-tracker-end-date-row')), findsNothing);

    await tester.enterText(
      find.byKey(const Key('stage-tracker-title-field')),
      '貓咪成長',
    );
    await tester.pump();
    expect(
      tester
          .widget<Text>(find.byKey(const Key('stage-tracker-preview-title')))
          .data,
      '貓咪成長',
    );

    await tester.enterText(
      find.byKey(const Key('stage-tracker-subject-field')),
      '小咪',
    );
    await tester.pump();
    expect(find.text('追蹤對象：小咪'), findsOneWidget);

    await tester.tap(find.byKey(const Key('stage-tracker-pack-picker-row')));
    await tester.pumpAndSettle();
    expect(find.text(ReminderUiText.unassignedPackOption), findsWidgets);
    expect(find.text(ReminderUiText.systemDefaultPackLabel), findsNothing);
    await tester.tap(find.text('🐱 養貓').last);
    await tester.pumpAndSettle();

    expect(find.text('🐱'), findsOneWidget);
    expect(find.text('追蹤對象：小咪'), findsOneWidget);

    await tester.ensureVisible(
      find.byKey(const Key('stage-tracker-advanced-toggle')),
    );
    await tester.tap(find.byKey(const Key('stage-tracker-advanced-toggle')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('stage-tracker-end-date-row')), findsOneWidget);

    await tester.tap(
      find.widgetWithText(FilledButton, ReminderUiText.saveAction),
    );
    await tester.pumpAndSettle();

    expect(repository.createdTrackers.single.title, '貓咪成長');
    expect(repository.createdTrackers.single.subjectName, '小咪');
    expect(repository.createdTrackers.single.packId, 1);
    expect(repository.createdTrackers.single.trackingStartDate.hour, 0);
  });

  testWidgets('create dialog validates title and selects inline created pack', (
    tester,
  ) async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    final repository = _RecordingStageTrackerRepository(db);
    await _pumpStageTrackerManagement(
      tester,
      previewDate: DateTime(2026, 5, 20),
      trackers: const [],
      packs: const [],
      rules: const [],
      details: const {},
      database: db,
      repository: repository,
    );

    await tester.tap(find.byKey(const Key('stage-tracker-dashed-add-card')));
    await tester.pumpAndSettle();
    await tester.tap(
      find.widgetWithText(FilledButton, ReminderUiText.saveAction),
    );
    await tester.pumpAndSettle();
    expect(
      find.text(ReminderUiText.stageTrackerNameRequiredError),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const Key('stage-tracker-pack-picker-row')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('stage-tracker-add-pack-button')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('pack-title-field')), '貓家庭');
    await tester.pump();
    await tester.tap(find.byKey(const Key('pack-save-button')));
    await tester.pumpAndSettle();

    expect(find.text('🐱 貓家庭'), findsWidgets);

    await tester.enterText(
      find.byKey(const Key('stage-tracker-title-field')),
      '成長紀錄',
    );
    await tester.tap(
      find.widgetWithText(FilledButton, ReminderUiText.saveAction),
    );
    await tester.pumpAndSettle();

    expect(repository.createdTrackers.single.packId, isNotNull);
  });

  testWidgets('edit dialog shows system default pack as general', (
    tester,
  ) async {
    final systemPack = _pack(
      id: 1,
      title: 'Default Item Pack',
      iconEmoji: '📌',
      isSystemDefault: true,
    );
    final catPack = _pack(id: 2, title: '養貓', iconEmoji: '🐱');
    final tracker = _tracker(
      id: 7,
      packId: systemPack.id,
      title: '一般追蹤',
      start: DateTime(2026, 5, 1),
    );

    await _pumpStageTrackerDetail(
      tester,
      previewDate: DateTime(2026, 5, 20),
      detail: _detail(tracker),
      packs: [systemPack, catPack],
    );

    await tester.tap(find.byKey(const Key('stage-tracker-detail-overflow')));
    await tester.pumpAndSettle();
    await tester.tap(find.text(ReminderUiText.editStageTracker));
    await tester.pumpAndSettle();

    expect(find.text(ReminderUiText.systemDefaultPackLabel), findsWidgets);
    expect(find.text(ReminderUiText.unassignedPackOption), findsNothing);

    await tester.tap(find.byKey(const Key('stage-tracker-pack-picker-row')));
    await tester.pumpAndSettle();

    expect(find.text(ReminderUiText.systemDefaultPackLabel), findsWidgets);
    expect(find.text(ReminderUiText.unassignedPackOption), findsNothing);
  });

  testWidgets('dashed add card replaces empty state', (tester) async {
    await _pumpStageTrackerManagement(
      tester,
      previewDate: DateTime(2026, 5, 20),
      trackers: const [],
      packs: const [],
      rules: const [],
      details: const {},
    );

    expect(find.byKey(const Key('stage-tracker-empty-state')), findsNothing);
    expect(
      find.byKey(const Key('stage-tracker-dashed-add-card')),
      findsOneWidget,
    );
    expect(find.text(ReminderUiText.addStageTrackerCardTitle), findsOneWidget);
    expect(
      find.text(ReminderUiText.addStageTrackerCardSubtitle),
      findsOneWidget,
    );
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
    final longTitleTracker = _tracker(
      id: 9,
      packId: fixture.packs.first.id,
      title: '這是一個非常非常長但仍然應該用省略號收斂的階段追蹤標題',
      start: DateTime(2026, 5, 1),
    );
    await _pumpStageTrackerManagement(
      tester,
      previewDate: DateTime(2026, 5, 20),
      trackers: [longTitleTracker, ...fixture.trackers],
      packs: fixture.packs,
      rules: fixture.rules,
      details: {
        longTitleTracker.id: _detail(longTitleTracker),
        ...fixture.details,
      },
    );

    expect(tester.takeException(), isNull);
    expect(find.byType(StageTrackerManagementContent), findsOneWidget);
    final longTitle = tester.widget<Text>(
      find.byKey(const Key('stage-tracker-short-title-9')),
    );
    expect(longTitle.maxLines, 1);
    expect(longTitle.overflow, TextOverflow.ellipsis);
  });
}

Future<void> _pumpStageTrackerManagement(
  WidgetTester tester, {
  required DateTime previewDate,
  required List<StageTracker> trackers,
  required List<ItemPack> packs,
  required List<StageRule> rules,
  required Map<int, StageTrackerDetail> details,
  List<StageOccurrence>? attentionOccurrences,
  AppDatabase? database,
  StageTrackerRepository? repository,
}) async {
  final db = database ?? AppDatabase.forTesting(NativeDatabase.memory());
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
        if (repository != null)
          stageTrackerRepositoryProvider.overrideWithValue(repository),
        effectivePreviewDateProvider.overrideWith((ref) => previewDate),
        activeItemPacksProvider.overrideWith((ref) => Stream.value(packs)),
        itemPacksProvider.overrideWith((ref) => Stream.value(packs)),
        stageTrackersProvider.overrideWith((ref) => Stream.value(trackers)),
        stageRulesProvider.overrideWith((ref) => Stream.value(rules)),
        stageRecordsProvider.overrideWith((ref) => Stream.value(const [])),
        if (attentionOccurrences != null)
          stageTrackerAttentionOccurrencesProvider.overrideWith(
            (ref) => AsyncData(attentionOccurrences),
          ),
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

Future<void> _pumpStageTrackerDetail(
  WidgetTester tester, {
  required DateTime previewDate,
  required StageTrackerDetail detail,
  required List<ItemPack> packs,
}) async {
  final db = AppDatabase.forTesting(NativeDatabase.memory());
  final router = GoRouter(
    initialLocation: '/stage-tracker/${detail.stageTracker.id}',
    routes: [
      GoRoute(
        path: StageTrackerManagementPage.routePath,
        name: StageTrackerManagementPage.routeName,
        builder: (context, state) => const StageTrackerManagementContent(),
      ),
      GoRoute(
        path: StageTrackerDetailPage.routePath,
        name: StageTrackerDetailPage.routeName,
        builder: (context, state) => StageTrackerDetailPage(
          stageTrackerId: int.parse(state.pathParameters['id']!),
        ),
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
        activeItemPacksProvider.overrideWith((ref) => Stream.value(packs)),
        itemPacksProvider.overrideWith((ref) => Stream.value(packs)),
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

  final createdTrackers = <StageTrackerInput>[];

  @override
  Future<int> createStageTracker(StageTrackerInput input) async {
    createdTrackers.add(input);
    return 99;
  }
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
  bool isSystemDefault = false,
}) {
  return ItemPack(
    id: id,
    title: title,
    iconEmoji: iconEmoji,
    status: ItemPackStatus.active,
    isSystemDefault: isSystemDefault,
    createdAt: DateTime(2026, 5),
    updatedAt: DateTime(2026, 5),
  );
}

StageTracker _tracker({
  required int id,
  required int packId,
  required String title,
  required DateTime start,
  DateTime? end,
  StageTrackerStatus status = StageTrackerStatus.active,
}) {
  return StageTracker(
    id: id,
    packId: packId,
    title: title,
    trackingStartDate: start,
    trackingEndDate: end,
    status: status,
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
