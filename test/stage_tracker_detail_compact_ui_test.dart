import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:reminder_app/app/theme/reminder_theme.dart';
import 'package:reminder_app/features/reminders/data/item_repository.dart';
import 'package:reminder_app/features/reminders/data/local/app_database.dart';
import 'package:reminder_app/features/reminders/data/local/reminder_dao.dart';
import 'package:reminder_app/features/reminders/data/stage_tracker_models.dart';
import 'package:reminder_app/features/reminders/data/stage_tracker_repository.dart';
import 'package:reminder_app/features/reminders/domain/item.dart';
import 'package:reminder_app/features/reminders/domain/item_pack.dart';
import 'package:reminder_app/features/reminders/domain/stage_occurrence.dart';
import 'package:reminder_app/features/reminders/domain/stage_record.dart';
import 'package:reminder_app/features/reminders/domain/stage_related_item.dart';
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

  testWidgets('detail overflow edits tracker and confirms archive', (
    tester,
  ) async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    final repository = _RecordingStageTrackerRepository(
      db,
      detail: _detailWithPendingAndUpcoming(
        tracker: _tracker(
          subjectName: '小米',
          trackingEndDate: DateTime(2026, 12, 31),
        ),
      ),
    );
    await _pumpDetail(
      tester,
      detail: repository.detail!,
      database: db,
      repository: repository,
      packs: [_pack()],
    );

    await tester.tap(find.byKey(const Key('stage-tracker-detail-overflow')));
    await tester.pumpAndSettle();

    expect(find.text(ReminderUiText.editStageTracker), findsOneWidget);
    expect(find.text(ReminderUiText.stageTrackerTimelineTitle), findsOneWidget);
    expect(find.text(ReminderUiText.archiveStageTracker), findsOneWidget);
    final archiveText = tester.widget<Text>(
      find.byKey(const Key('stage-tracker-archive-menu-text')),
    );
    expect(archiveText.style?.color, ReminderTheme.light().colorScheme.error);

    await tester.tap(find.text(ReminderUiText.editStageTracker));
    await tester.pumpAndSettle();

    expect(
      find.text(ReminderUiText.stageTrackerBasicSectionTitle),
      findsOneWidget,
    );
    expect(
      find.text(ReminderUiText.stageTrackerAdvancedSectionTitle),
      findsOneWidget,
    );
    expect(find.text(ReminderUiText.trackingStartDateEditHelp), findsOneWidget);
    expect(
      _editableTextValue(tester, const Key('stage-tracker-title-field')),
      '寶寶成長',
    );
    expect(
      _editableTextValue(tester, const Key('stage-tracker-subject-field')),
      '小米',
    );
    expect(find.text('👶 寶寶'), findsOneWidget);
    expect(find.text('2026/05/01'), findsWidgets);
    expect(find.text('2026/12/31'), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('stage-tracker-title-field')),
      '成長追蹤',
    );
    await tester.tap(
      find.widgetWithText(FilledButton, ReminderUiText.saveAction),
    );
    await tester.pumpAndSettle();

    expect(repository.updatedTrackers.single.title, '成長追蹤');
    expect(find.text('成長追蹤'), findsOneWidget);

    await tester.tap(find.byKey(const Key('stage-tracker-detail-overflow')));
    await tester.pumpAndSettle();
    await tester.tap(find.text(ReminderUiText.archiveStageTracker));
    await tester.pumpAndSettle();

    expect(find.text(ReminderUiText.archiveStageTrackerTitle), findsOneWidget);
    await tester.tap(
      find.text(
        MaterialLocalizations.of(
          tester.element(find.byType(AlertDialog)),
        ).cancelButtonLabel,
      ),
    );
    await tester.pumpAndSettle();
    expect(repository.archiveTrackerCalls, 0);

    await tester.tap(find.byKey(const Key('stage-tracker-detail-overflow')));
    await tester.pumpAndSettle();
    await tester.tap(find.text(ReminderUiText.archiveStageTracker));
    await tester.pumpAndSettle();
    await tester.tap(
      find.widgetWithText(TextButton, ReminderUiText.archiveAction),
    );
    await tester.pumpAndSettle();

    expect(repository.archiveTrackerCalls, 1);
    expect(find.text('overview'), findsOneWidget);
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

  testWidgets('upcoming rows are compact without related action buttons', (
    tester,
  ) async {
    await _pumpDetail(tester, detail: _detailWithPendingAndUpcoming());

    expect(find.byType(ReminderIconBubble), findsNothing);
    expect(find.byType(ListTile), findsNothing);
    expect(
      find.byKey(const Key('detail-add-related-rule-101-1')),
      findsNothing,
    );
    expect(
      find.byKey(const Key('detail-view-related-record-302')),
      findsNothing,
    );
    expect(
      find.byKey(const Key('detail-recurring-occurrence-icon-rule-201-1')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('detail-recurring-occurrence-icon-record-302')),
      findsNothing,
    );
    expect(find.textContaining('相關提醒：1 / 2 已完成'), findsOneWidget);
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
      findsNothing,
    );
  });

  testWidgets('upcoming occurrence rows expand to compact related reminders', (
    tester,
  ) async {
    final relatedEntry = _relatedEntry(1, title: '準備針卡');
    await _pumpDetail(
      tester,
      detail: _detailWithPendingAndUpcoming(),
      relatedEntries: {
        302: [relatedEntry],
      },
    );

    final generatedRow = find.byKey(
      const Key('detail-stage-occurrence-body-rule-201-1'),
    );
    final manualRow = find.byKey(
      const Key('detail-stage-occurrence-body-record-302'),
    );

    await tester.ensureVisible(generatedRow);
    await tester.tap(generatedRow);
    await tester.pumpAndSettle();
    expect(find.text(ReminderUiText.noRelatedReminders), findsOneWidget);
    expect(find.text(ReminderUiText.addRelatedReminder), findsOneWidget);

    await tester.ensureVisible(manualRow);
    await tester.tap(manualRow);
    await tester.pumpAndSettle();
    await tester.ensureVisible(
      find.byKey(const Key('stage-related-expanded-record-302')),
    );
    await tester.pumpAndSettle();
    expect(
      find.text(ReminderUiText.relatedItemsTitle, skipOffstage: false),
      findsOneWidget,
    );
    expect(find.text('準備針卡'), findsOneWidget);
    expect(find.textContaining('2026/06/01'), findsWidgets);
    expect(find.text(ReminderUiText.addRelatedReminder), findsWidgets);

    await tester.ensureVisible(generatedRow);
    await tester.tap(generatedRow);
    await tester.pumpAndSettle();
    expect(find.text(ReminderUiText.noRelatedReminders), findsNothing);
    expect(find.text('準備針卡'), findsOneWidget);
  });

  testWidgets('expanded related reminder row opens item summary dialog', (
    tester,
  ) async {
    await _pumpDetail(
      tester,
      detail: _detailWithPendingAndUpcoming(),
      relatedEntries: {
        302: [_relatedEntry(1, title: '準備針卡')],
      },
    );

    await tester.tap(
      find.byKey(const Key('detail-stage-occurrence-body-record-302')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('stage-related-item-1')));
    await tester.pumpAndSettle();

    expect(find.text(ReminderUiText.itemDetailTitle), findsOneWidget);
    expect(find.text('準備針卡'), findsWidgets);
    expect(find.byType(ListTile), findsNothing);
  });

  testWidgets(
    'expanded create related button opens dialog and keeps row side clean',
    (tester) async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      final repository = _RecordingStageTrackerRepository(
        db,
        detail: _detailWithPendingAndUpcoming(),
      );
      await _pumpDetail(
        tester,
        detail: repository.detail!,
        database: db,
        repository: repository,
      );

      await tester.tap(
        find.byKey(const Key('detail-stage-occurrence-body-record-302')),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const Key('stage-related-create-record-302')),
      );
      await tester.pumpAndSettle();

      expect(find.text(ReminderUiText.addRelatedReminder), findsWidgets);
      expect(find.byIcon(Icons.visibility_outlined), findsNothing);
      expect(
        find.byKey(const Key('detail-manual-stage-overflow-record-302')),
        findsOneWidget,
      );
    },
  );

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
    expect(find.text('第{value}{unit}'), findsNothing);
    expect(find.text('下一階段：成貓期・2026/05/21・明天'), findsOneWidget);
  });

  testWidgets('stage rule rows show resolved next occurrence fallback', (
    tester,
  ) async {
    final tracker = _tracker();
    final firstRule = StageRule(
      id: 501,
      stageTrackerId: tracker.id,
      type: StageRuleType.everyNDays,
      intervalValue: 2,
      intervalUnit: StageIntervalUnit.days,
      labelTemplate: '由到{value}{unit}',
      status: StageRuleStatus.active,
      createdAt: DateTime(2026, 5),
      updatedAt: DateTime(2026, 5),
    );
    final secondRule = StageRule(
      id: 502,
      stageTrackerId: tracker.id,
      type: StageRuleType.everyNWeeks,
      intervalValue: 1,
      intervalUnit: StageIntervalUnit.weeks,
      labelTemplate: '第{value}{unit}',
      status: StageRuleStatus.active,
      createdAt: DateTime(2026, 5),
      updatedAt: DateTime(2026, 5),
    );

    await _pumpDetail(
      tester,
      detail: StageTrackerDetail(
        stageTracker: tracker,
        stageRules: [firstRule, secondRule],
        stageRecords: const [],
        dashboardUpcomingStages: const [],
        scheduleStages: [
          _generatedOccurrence(
            tracker,
            ruleId: firstRule.id,
            index: 1,
            date: DateTime(2026, 5, 24),
            label: '由到2天',
          ),
        ],
        historyStages: const [],
      ),
    );

    expect(find.text('由到{value}{unit}'), findsNothing);
    expect(find.text('第{value}{unit}'), findsNothing);
    expect(find.text('下一階段：由到2天・2026/05/24・4天後'), findsOneWidget);
    expect(find.text('尚未安排下一階段・啟用中'), findsOneWidget);
  });

  testWidgets('stage rule overflow supports edit pause resume and archive', (
    tester,
  ) async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    final repository = _RecordingStageTrackerRepository(
      db,
      detail: _detailWithPendingAndUpcoming(),
    );
    await _pumpDetail(
      tester,
      detail: repository.detail!,
      database: db,
      repository: repository,
    );

    await tester.tap(find.byKey(const Key('stage-rule-overflow-201')));
    await tester.pumpAndSettle();

    expect(find.text('規則管理尚未支援'), findsNothing);
    expect(find.text('建立下一輪提醒'), findsNothing);
    expect(find.text(ReminderUiText.editStageRule), findsOneWidget);
    expect(find.text(ReminderUiText.pauseStageRule), findsOneWidget);
    expect(find.text(ReminderUiText.archiveStageRule), findsOneWidget);

    await tester.tap(find.text(ReminderUiText.editStageRule));
    await tester.pumpAndSettle();
    expect(
      _editableTextValue(tester, const Key('stage-rule-interval-field')),
      '1',
    );
    await tester.enterText(
      find.byKey(const Key('stage-rule-interval-field')),
      '2',
    );
    await tester.tap(
      find.widgetWithText(FilledButton, ReminderUiText.saveAction),
    );
    await tester.pumpAndSettle();
    expect(repository.updatedRules.single.intervalValue, 2);

    await tester.tap(find.byKey(const Key('stage-rule-overflow-201')));
    await tester.pumpAndSettle();
    await tester.tap(find.text(ReminderUiText.pauseStageRule));
    await tester.pumpAndSettle();
    expect(repository.ruleStatuses.last, StageRuleStatus.paused);

    await tester.tap(find.byKey(const Key('stage-rule-overflow-201')));
    await tester.pumpAndSettle();
    expect(find.text(ReminderUiText.resumeStageRule), findsOneWidget);
    await tester.tap(find.text(ReminderUiText.resumeStageRule));
    await tester.pumpAndSettle();
    expect(repository.ruleStatuses.last, StageRuleStatus.active);

    await tester.tap(find.byKey(const Key('stage-rule-overflow-201')));
    await tester.pumpAndSettle();
    await tester.tap(find.text(ReminderUiText.archiveStageRule));
    await tester.pumpAndSettle();
    expect(find.text(ReminderUiText.archiveStageRuleTitle), findsOneWidget);
    await tester.tap(
      find.widgetWithText(TextButton, ReminderUiText.archiveAction),
    );
    await tester.pumpAndSettle();
    expect(repository.ruleStatuses.last, StageRuleStatus.archived);
  });

  testWidgets('stage rule rows do not expand next occurrence context', (
    tester,
  ) async {
    await _pumpDetail(tester, detail: _detailWithPendingAndUpcoming());

    await tester.tap(find.text('每 1 週'));
    await tester.pumpAndSettle();

    expect(find.text('下一輪階段'), findsNothing);
    expect(find.text('建立下一輪提醒'), findsNothing);
    expect(find.byKey(const Key('stage-rule-expanded-201')), findsNothing);
    expect(
      find.byKey(const Key('stage-rule-next-related-count-201')),
      findsNothing,
    );
    expect(find.text('相關提醒 0'), findsNothing);
    expect(find.text('成貓期'), findsOneWidget);

    await tester.tap(find.byKey(const Key('stage-rule-overflow-201')));
    await tester.pumpAndSettle();
    expect(find.text('建立下一輪提醒'), findsNothing);
    expect(find.text(ReminderUiText.editStageRule), findsOneWidget);
    expect(find.text(ReminderUiText.pauseStageRule), findsOneWidget);
    expect(find.text(ReminderUiText.archiveStageRule), findsOneWidget);
  });

  testWidgets('paused rule stays compact without next reminder creation', (
    tester,
  ) async {
    await _pumpDetail(tester, detail: _detailWithPausedRule());

    await tester.tap(find.text('每 1 週'));
    await tester.pumpAndSettle();

    expect(find.text('下一輪階段'), findsNothing);
    expect(find.text('建立下一輪提醒'), findsNothing);
    expect(find.byKey(const Key('stage-rule-expanded-201')), findsNothing);

    await tester.tap(find.byKey(const Key('stage-rule-overflow-201')));
    await tester.pumpAndSettle();
    expect(find.text('建立下一輪提醒'), findsNothing);
    expect(find.text(ReminderUiText.resumeStageRule), findsOneWidget);
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
      findsNothing,
    );
    expect(
      find.byKey(const Key('timeline-view-related-record-302')),
      findsNothing,
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
    expect(find.textContaining('相關提醒：1 / 2 已完成'), findsWidgets);

    await tester.tap(find.text('成貓期'));
    await tester.pumpAndSettle();
    expect(find.text(ReminderUiText.noRelatedReminders), findsNothing);
  });

  testWidgets('manual important stage timeline rows expose management menu', (
    tester,
  ) async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    final repository = _RecordingStageTrackerRepository(
      db,
      detail: _detailWithPendingAndUpcoming(),
    );
    await _pumpTimeline(
      tester,
      detail: repository.detail!,
      database: db,
      repository: repository,
    );

    expect(
      find.byKey(const Key('timeline-manual-stage-overflow-record-302')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('timeline-manual-stage-overflow-rule-101-1')),
      findsNothing,
    );

    await tester.tap(
      find.byKey(const Key('timeline-manual-stage-overflow-record-302')),
    );
    await tester.pumpAndSettle();

    expect(find.text(ReminderUiText.addRelatedReminder), findsOneWidget);
    expect(find.text(ReminderUiText.editImportantStage), findsOneWidget);
    expect(find.text(ReminderUiText.archiveImportantStage), findsOneWidget);

    await tester.tap(find.text(ReminderUiText.addRelatedReminder));
    await tester.pumpAndSettle();
    expect(find.text('建立相關提醒'), findsOneWidget);

    await tester.tap(find.text(ReminderUiText.closeAction));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const Key('timeline-manual-stage-overflow-record-302')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text(ReminderUiText.editImportantStage));
    await tester.pumpAndSettle();
    expect(
      _editableTextValue(tester, const Key('important-stage-title-field')),
      '疫苗提醒',
    );
    await tester.enterText(
      find.byKey(const Key('important-stage-title-field')),
      '疫苗回診',
    );
    await tester.tap(
      find.widgetWithText(FilledButton, ReminderUiText.saveAction),
    );
    await tester.pumpAndSettle();
    expect(repository.updatedImportantStages.single.label, '疫苗回診');

    await tester.tap(
      find.byKey(const Key('timeline-manual-stage-overflow-record-302')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text(ReminderUiText.archiveImportantStage));
    await tester.pumpAndSettle();
    expect(
      find.text(ReminderUiText.archiveImportantStageTitle),
      findsOneWidget,
    );
    await tester.tap(
      find.widgetWithText(TextButton, ReminderUiText.archiveAction),
    );
    await tester.pumpAndSettle();

    expect(repository.archivedImportantStageIds.single, 302);
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

  testWidgets('long recurring upcoming title with icon fits phone width', (
    tester,
  ) async {
    final view = tester.view;
    view.physicalSize = const Size(393, 852);
    view.devicePixelRatio = 1;
    addTearDown(() {
      view.resetPhysicalSize();
      view.resetDevicePixelRatio();
    });
    final tracker = _tracker();

    await _pumpDetail(
      tester,
      detail: StageTrackerDetail(
        stageTracker: tracker,
        stageRules: const [],
        stageRecords: const [],
        dashboardUpcomingStages: [
          _generatedOccurrence(
            tracker,
            ruleId: 901,
            index: 1,
            date: DateTime(2026, 5, 21),
            label: '這是一個非常非常長但仍然應該保留循環圖示並用省略號收斂的階段名稱',
          ),
        ],
        scheduleStages: const [],
        historyStages: const [],
      ),
    );

    final title = tester.widget<Text>(
      find.text('這是一個非常非常長但仍然應該保留循環圖示並用省略號收斂的階段名稱'),
    );
    expect(title.maxLines, 1);
    expect(title.overflow, TextOverflow.ellipsis);
    expect(
      find.byKey(const Key('detail-recurring-occurrence-icon-rule-901-1')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}

Future<void> _pumpDetail(
  WidgetTester tester, {
  required StageTrackerDetail detail,
  AppDatabase? database,
  StageTrackerRepository? repository,
  List<ItemPack> packs = const [],
  Map<int, List<StageRelatedItemEntry>> relatedEntries = const {},
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
        activeItemPacksProvider.overrideWith((ref) => Stream.value(packs)),
        effectivePreviewDateProvider.overrideWith(
          (ref) => DateTime(2026, 5, 20),
        ),
        stageTrackerDetailProvider.overrideWith((ref, id) async {
          if (repository case _RecordingStageTrackerRepository recording) {
            return recording.detail ?? detail;
          }
          return detail;
        }),
        stageRelatedItemEntriesProvider.overrideWith(
          (ref, stageRecordId) async =>
              relatedEntries[stageRecordId] ?? const <StageRelatedItemEntry>[],
        ),
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
  AppDatabase? database,
  StageTrackerRepository? repository,
}) async {
  final db = database ?? AppDatabase.forTesting(NativeDatabase.memory());
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
        if (repository != null)
          stageTrackerRepositoryProvider.overrideWithValue(repository),
        effectivePreviewDateProvider.overrideWith(
          (ref) => DateTime(2026, 5, 20),
        ),
        stageTrackerDetailProvider.overrideWith((ref, id) async {
          if (repository case _RecordingStageTrackerRepository recording) {
            return recording.detail ?? detail;
          }
          return detail;
        }),
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
  _RecordingStageTrackerRepository(AppDatabase db, {this.detail})
    : super(db.reminderDao, itemRepository: ItemRepository(db.reminderDao));

  StageTrackerDetail? detail;
  final importantStages = <ManualStageInput>[];
  final stageRules = <StageRuleInput>[];
  final updatedTrackers = <StageTrackerInput>[];
  final updatedRules = <StageRuleInput>[];
  final updatedImportantStages = <ManualStageInput>[];
  final ruleStatuses = <StageRuleStatus>[];
  final archivedImportantStageIds = <int>[];
  final relatedReminderOccurrences = <StageOccurrence>[];
  int archiveTrackerCalls = 0;

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

  @override
  Future<bool> updateStageTracker(int id, StageTrackerInput input) async {
    updatedTrackers.add(input);
    final current = detail;
    if (current == null || current.stageTracker.id != id) {
      return false;
    }
    detail = StageTrackerDetail(
      stageTracker: StageTracker(
        id: current.stageTracker.id,
        packId: input.packId ?? current.stageTracker.packId,
        title: input.title,
        subjectName: input.subjectName,
        trackingStartDate: input.trackingStartDate,
        trackingEndDate: input.trackingEndDate,
        status: current.stageTracker.status,
        createdAt: current.stageTracker.createdAt,
        updatedAt: DateTime(2026, 5, 21),
      ),
      stageRules: current.stageRules,
      stageRecords: current.stageRecords,
      dashboardUpcomingStages: current.dashboardUpcomingStages,
      scheduleStages: current.scheduleStages,
      historyStages: current.historyStages,
    );
    return true;
  }

  @override
  Future<bool> archiveStageTracker(int id) async {
    archiveTrackerCalls += 1;
    return true;
  }

  @override
  Future<bool> updateStageRule(int id, StageRuleInput input) async {
    updatedRules.add(input);
    final current = detail;
    if (current == null) {
      return false;
    }
    detail = _replaceRule(
      current,
      id,
      (rule) => StageRule(
        id: rule.id,
        stageTrackerId: rule.stageTrackerId,
        type: input.type,
        intervalValue: input.intervalValue,
        intervalUnit: input.intervalUnit,
        labelTemplate: input.labelTemplate,
        reminderOffsetDays: input.reminderOffsetDays,
        status: rule.status,
        createdAt: rule.createdAt,
        updatedAt: DateTime(2026, 5, 21),
      ),
    );
    return true;
  }

  @override
  Future<bool> updateStageRuleStatus(int id, StageRuleStatus status) async {
    ruleStatuses.add(status);
    final current = detail;
    if (current == null) {
      return false;
    }
    detail = _replaceRule(
      current,
      id,
      (rule) => StageRule(
        id: rule.id,
        stageTrackerId: rule.stageTrackerId,
        type: rule.type,
        intervalValue: rule.intervalValue,
        intervalUnit: rule.intervalUnit,
        labelTemplate: rule.labelTemplate,
        reminderOffsetDays: rule.reminderOffsetDays,
        status: status,
        createdAt: rule.createdAt,
        updatedAt: DateTime(2026, 5, 21),
      ),
    );
    return true;
  }

  @override
  Future<bool> updateImportantStage(
    int stageRecordId,
    ManualStageInput input,
  ) async {
    updatedImportantStages.add(input);
    return true;
  }

  @override
  Future<bool> deleteOrArchiveImportantStage(int stageRecordId) async {
    archivedImportantStageIds.add(stageRecordId);
    return true;
  }

  @override
  Future<int> createRelatedItemFromOccurrence(
    StageOccurrence occurrence, {
    required String title,
    String? description,
    DateTime? dueDate,
    int? packId,
  }) async {
    relatedReminderOccurrences.add(occurrence);
    return 1;
  }
}

StageTrackerDetail _replaceRule(
  StageTrackerDetail detail,
  int id,
  StageRule Function(StageRule rule) replace,
) {
  return StageTrackerDetail(
    stageTracker: detail.stageTracker,
    stageRules: [
      for (final rule in detail.stageRules)
        rule.id == id ? replace(rule) : rule,
    ],
    stageRecords: detail.stageRecords,
    dashboardUpcomingStages: detail.dashboardUpcomingStages,
    scheduleStages: detail.scheduleStages,
    historyStages: detail.historyStages,
  );
}

StageTrackerDetail _detailWithPendingAndUpcoming({StageTracker? tracker}) {
  final currentTracker = tracker ?? _tracker();
  final next = _generatedOccurrence(
    currentTracker,
    ruleId: 201,
    index: 1,
    date: DateTime(2026, 5, 21),
    label: '成貓期',
  );
  final related = _manualOccurrence(
    currentTracker,
    recordId: 302,
    date: DateTime(2026, 6, 1),
    label: '疫苗提醒',
    summary: const StageRelatedItemSummary(doneCount: 1, activeCount: 1),
  );
  final later = _generatedOccurrence(
    currentTracker,
    ruleId: 201,
    index: 2,
    date: DateTime(2026, 5, 23),
    label: '兩週後',
  );
  return StageTrackerDetail(
    stageTracker: currentTracker,
    stageRules: [
      StageRule(
        id: 201,
        stageTrackerId: currentTracker.id,
        type: StageRuleType.everyNWeeks,
        intervalValue: 1,
        intervalUnit: StageIntervalUnit.weeks,
        labelTemplate: '第{value}{unit}',
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
        currentTracker,
        recordId: 401,
        date: DateTime(2026, 5, 18),
        label: '滿 18 天',
        status: StageRecordStatus.normal,
      ),
      _manualOccurrence(
        currentTracker,
        recordId: 402,
        date: DateTime(2026, 5, 10),
        label: '滿 10 天',
        status: StageRecordStatus.acknowledged,
      ),
    ],
  );
}

StageTrackerDetail _detailWithPausedRule() {
  final detail = _detailWithPendingAndUpcoming();
  return StageTrackerDetail(
    stageTracker: detail.stageTracker,
    stageRules: [
      StageRule(
        id: 201,
        stageTrackerId: detail.stageTracker.id,
        type: StageRuleType.everyNWeeks,
        intervalValue: 1,
        intervalUnit: StageIntervalUnit.weeks,
        labelTemplate: '第{value}{unit}',
        status: StageRuleStatus.paused,
        createdAt: DateTime(2026, 5),
        updatedAt: DateTime(2026, 5),
      ),
    ],
    stageRecords: detail.stageRecords,
    dashboardUpcomingStages: detail.dashboardUpcomingStages,
    scheduleStages: detail.scheduleStages,
    historyStages: detail.historyStages,
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

StageTracker _tracker({String? subjectName, DateTime? trackingEndDate}) {
  return StageTracker(
    id: 1,
    packId: 1,
    title: '寶寶成長',
    subjectName: subjectName,
    trackingStartDate: DateTime(2026, 5, 1),
    trackingEndDate: trackingEndDate,
    status: StageTrackerStatus.active,
    createdAt: DateTime(2026, 5),
    updatedAt: DateTime(2026, 5),
  );
}

ItemPack _pack() {
  return ItemPack(
    id: 1,
    title: '寶寶',
    iconEmoji: '👶',
    orderIndex: 1,
    status: ItemPackStatus.active,
    isSystemDefault: false,
    createdAt: DateTime(2026, 5),
    updatedAt: DateTime(2026, 5),
  );
}

StageRelatedItemEntry _relatedEntry(int id, {required String title}) {
  return StageRelatedItemEntry(
    relatedItemId: id,
    bundle: ItemBundle(
      item: Item(
        id: id,
        packId: 1,
        title: title,
        type: ItemType.fixed,
        config: FixedItemConfig(
          scheduleType: FixedScheduleType.oneTime,
          anchorDate: DateTime(2026, 6, 1),
          dueDate: DateTime(2026, 6, 1),
        ),
        createdAt: DateTime(2026, 5),
        updatedAt: DateTime(2026, 5),
      ),
      pack: _pack(),
    ),
    hasDoneAction: false,
    hasSkippedAction: false,
  );
}

String _editableTextValue(WidgetTester tester, Key fieldKey) {
  final editable = tester.widget<EditableText>(
    find.descendant(
      of: find.byKey(fieldKey),
      matching: find.byType(EditableText),
    ),
  );
  return editable.controller.text;
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
