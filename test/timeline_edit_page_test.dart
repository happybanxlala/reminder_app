import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:reminder_app/features/reminders/data/local/app_database.dart';
import 'package:reminder_app/features/reminders/data/timeline_models.dart';
import 'package:reminder_app/features/reminders/data/timeline_repository.dart';
import 'package:reminder_app/features/reminders/domain/timeline.dart';
import 'package:reminder_app/features/reminders/domain/timeline_milestone_rule.dart';
import 'package:reminder_app/features/reminders/presentation/text/reminder_ui_text.dart';
import 'package:reminder_app/features/reminders/providers/timeline_providers.dart';
import 'package:reminder_app/features/reminders/ui/pages/timeline_edit_page.dart';

void main() {
  testWidgets('timeline editor adds milestone rules explicitly', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        child: const MaterialApp(
          home: TimelineEditPage(mode: TimelineEditMode.create),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Milestone Rules'), findsOneWidget);
    expect(
      find.text('Timeline 持有的是 milestone rule；milestone 是規則推導出的時間事件。'),
      findsOneWidget,
    );
    expect(find.text('尚未設定 milestone rule。'), findsOneWidget);

    await tester.tap(find.byKey(const Key('add-rule-button')));
    await tester.pumpAndSettle();

    expect(
      find.text(TimelineMilestoneRuleType.everyNDays.name),
      findsOneWidget,
    );
    expect(find.text('第 {value}{unit}'), findsOneWidget);
    expect(find.text('Reminder Offset Days'), findsOneWidget);
    expect(find.text('次數'), findsOneWidget);
    expect(find.text('累積值'), findsOneWidget);
    expect(find.text('單位'), findsOneWidget);
    expect(find.text('預覽：第 1天'), findsOneWidget);
    expect(find.textContaining('下一筆：第 1天 • '), findsOneWidget);

    await tester.tap(find.text(TimelineMilestoneRuleType.everyNDays.name).last);
    await tester.pumpAndSettle();
    await tester.tap(
      find.text(TimelineMilestoneRuleType.everyNWeeks.name).last,
    );
    await tester.pumpAndSettle();

    expect(
      find.text(TimelineMilestoneRuleType.everyNWeeks.name),
      findsOneWidget,
    );
    expect(find.text('預覽：第 1週'), findsOneWidget);
    expect(find.textContaining('下一筆：第 1週 • '), findsOneWidget);

    await tester.ensureVisible(find.widgetWithText(OutlinedButton, '次數'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(OutlinedButton, '次數'));
    await tester.pumpAndSettle();

    expect(find.text('第 {value}{unit}{n}'), findsOneWidget);
  });

  testWidgets('timeline editor preview follows active paused switch', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        child: const MaterialApp(
          home: TimelineEditPage(mode: TimelineEditMode.create),
        ),
      ),
    );
    await tester.pump();

    await tester.tap(find.byKey(const Key('add-rule-button')));
    await tester.pumpAndSettle();

    expect(find.text('預覽：第 1天'), findsOneWidget);
    expect(find.textContaining('下一筆：第 1天 • '), findsOneWidget);

    await tester.ensureVisible(find.byType(Switch));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();

    expect(find.text('預覽：目前無法產生下一筆 milestone'), findsOneWidget);
    expect(find.text('下一筆：目前無法產生 upcoming milestone'), findsOneWidget);
  });

  testWidgets('timeline editor loads current milestone rules', (tester) async {
    final rule = _rule(TimelineMilestoneRuleStatus.active);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          timelineDetailProvider(9).overrideWith(
            (ref) => Future.value(
              TimelineDetail(
                timeline: Timeline(
                  id: 9,
                  title: 'No sugar',
                  startDate: DateTime(2099, 4, 20),
                  displayUnit: TimelineDisplayUnit.week,
                  status: TimelineStatus.active,
                  createdAt: DateTime(2026, 4, 1),
                  updatedAt: DateTime(2026, 4, 2),
                ),
                milestoneRuleDetails: [
                  TimelineMilestoneRuleDetail(
                    rule: rule,
                    nextMilestone: null,
                    historyRecords: const [],
                  ),
                ],
                upcomingMilestones: const [],
                milestoneHistory: const [],
              ),
            ),
          ),
        ],
        child: const MaterialApp(
          home: TimelineEditPage(mode: TimelineEditMode.edit, id: 9),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.text(TimelineMilestoneRuleType.everyNMonths.name),
      findsOneWidget,
    );
    expect(find.text('5'), findsWidgets);
    expect(find.text('第 {value}{unit}'), findsOneWidget);
    expect(find.text('預覽：第 2個月'), findsOneWidget);
    expect(find.textContaining('下一筆：第 2個月 • '), findsOneWidget);
  });

  testWidgets('paused milestone rule loads switch off', (tester) async {
    final rule = _rule(TimelineMilestoneRuleStatus.paused);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          timelineDetailProvider(9).overrideWith(
            (ref) => Future.value(
              TimelineDetail(
                timeline: Timeline(
                  id: 9,
                  title: 'No sugar',
                  startDate: DateTime(2099, 4, 20),
                  displayUnit: TimelineDisplayUnit.week,
                  status: TimelineStatus.active,
                  createdAt: DateTime(2026, 4, 1),
                  updatedAt: DateTime(2026, 4, 2),
                ),
                milestoneRuleDetails: [
                  TimelineMilestoneRuleDetail(
                    rule: rule,
                    nextMilestone: null,
                    historyRecords: const [],
                  ),
                ],
                upcomingMilestones: const [],
                milestoneHistory: const [],
              ),
            ),
          ),
        ],
        child: const MaterialApp(
          home: TimelineEditPage(mode: TimelineEditMode.edit, id: 9),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final switchTile = tester.widget<SwitchListTile>(
      find.byKey(const Key('rule-active-91')),
    );
    expect(switchTile.value, isFalse);
    expect(find.text('預覽：目前無法產生下一筆 milestone'), findsOneWidget);
  });

  testWidgets('edit keeps page open when target timeline no longer exists', (
    tester,
  ) async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final repository = TimelineRepository(db.itemTimelineDao);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          timelineRepositoryProvider.overrideWith((ref) => repository),
        ],
        child: const MaterialApp(
          home: TimelineEditPage(mode: TimelineEditMode.edit, id: 404),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('title-field')),
      'Lost timeline',
    );
    await tester.tap(find.byKey(const Key('save-button')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text(ReminderUiText.editTimeline), findsOneWidget);
    expect(find.text(ReminderUiText.timelineSaveFailedMessage), findsOneWidget);
  });
}

TimelineMilestoneRule _rule(TimelineMilestoneRuleStatus status) {
  return TimelineMilestoneRule(
    id: 91,
    timelineId: 9,
    type: TimelineMilestoneRuleType.everyNMonths,
    intervalValue: 2,
    intervalUnit: TimelineMilestoneIntervalUnit.months,
    labelTemplate: '第 {value}{unit}',
    reminderOffsetDays: 5,
    status: status,
    createdAt: DateTime(2026, 4, 1),
    updatedAt: DateTime(2026, 4, 2),
  );
}
