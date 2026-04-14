import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reminder_app/features/reminders/data/timeline_repository.dart';
import 'package:reminder_app/features/reminders/domain/reminder_rule.dart';
import 'package:reminder_app/features/reminders/domain/task_template.dart';
import 'package:reminder_app/features/reminders/domain/timeline.dart';
import 'package:reminder_app/features/reminders/domain/timeline_milestone_rule.dart';
import 'package:reminder_app/features/reminders/providers/task_providers.dart';
import 'package:reminder_app/features/reminders/providers/timeline_providers.dart';
import 'package:reminder_app/features/reminders/ui/pages/task_timeline_editor_page.dart';

void main() {
  testWidgets(
    'task template form only shows offset for advance reminder rule',
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: const MaterialApp(
            home: TaskTimelineEditorPage(
              mode: TaskTimelineEditorMode.taskTemplateCreate,
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.byKey(const Key('offset-field')), findsNothing);

      await tester.tap(find.byKey(const Key('reminder-rule-field')));
      await tester.pumpAndSettle();
      await tester.tap(find.text(ReminderRuleType.advance.name).last);
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('offset-field')), findsOneWidget);

      await tester.tap(find.byKey(const Key('reminder-rule-field')));
      await tester.pumpAndSettle();
      await tester.tap(find.text(ReminderRuleType.immediate.name).last);
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('offset-field')), findsNothing);
    },
  );

  testWidgets('task template edit initializes current reminder rule', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          taskTemplateDetailProvider(7).overrideWith(
            (ref) => Future.value(
              TaskTemplate(
                id: 7,
                title: 'Weekly trash',
                kind: TaskKind.recurring,
                status: TaskTemplateStatus.active,
                firstDueDate: DateTime(2026, 4, 20),
                reminderRule: const ReminderRule.advance(3),
                createdAt: DateTime(2026, 4, 1),
                updatedAt: DateTime(2026, 4, 2),
              ),
            ),
          ),
        ],
        child: const MaterialApp(
          home: TaskTimelineEditorPage(
            mode: TaskTimelineEditorMode.taskTemplateEdit,
            id: 7,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(ReminderRuleType.advance.name), findsOneWidget);
    expect(find.byKey(const Key('offset-field')), findsOneWidget);
    expect(find.text('3'), findsWidgets);
  });

  testWidgets('timeline form adds milestone rules explicitly', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: const MaterialApp(
          home: TaskTimelineEditorPage(
            mode: TaskTimelineEditorMode.timelineCreate,
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Milestone Rules'), findsOneWidget);
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
    expect(find.text('{n} = 次數, {value} = 累積值, {unit} = 單位'), findsNothing);
    expect(find.text('預覽：第 1天'), findsOneWidget);
    expect(find.textContaining('下一筆：第 1天 • '), findsOneWidget);
    expect(find.text('Upcoming Milestones'), findsNothing);
    expect(find.text('Milestone History'), findsNothing);

    await tester.tap(find.text(TimelineMilestoneRuleType.everyNDays.name).last);
    await tester.pumpAndSettle();
    expect(find.text(TimelineMilestoneRuleType.everyNWeeks.name), findsWidgets);
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

  testWidgets('timeline preview follows active paused switch', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: const MaterialApp(
          home: TaskTimelineEditorPage(
            mode: TaskTimelineEditorMode.timelineCreate,
          ),
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

  testWidgets('timeline edit initializes current milestone rules', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          timelineEditorDetailProvider(9).overrideWith(
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
                rules: [
                  TimelineMilestoneRule(
                    id: 91,
                    timelineId: 9,
                    type: TimelineMilestoneRuleType.everyNMonths,
                    intervalValue: 2,
                    intervalUnit: TimelineMilestoneIntervalUnit.months,
                    labelTemplate: '第 {value}{unit}',
                    reminderOffsetDays: 5,
                    status: TimelineMilestoneRuleStatus.active,
                    createdAt: DateTime(2026, 4, 1),
                    updatedAt: DateTime(2026, 4, 2),
                  ),
                ],
                upcomingOccurrences: const [],
                historyRecords: const [],
              ),
            ),
          ),
        ],
        child: const MaterialApp(
          home: TaskTimelineEditorPage(
            mode: TaskTimelineEditorMode.timelineEdit,
            id: 9,
          ),
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

  testWidgets('paused rule initializes switch off', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          timelineEditorDetailProvider(9).overrideWith(
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
                rules: [
                  TimelineMilestoneRule(
                    id: 91,
                    timelineId: 9,
                    type: TimelineMilestoneRuleType.everyNMonths,
                    intervalValue: 2,
                    intervalUnit: TimelineMilestoneIntervalUnit.months,
                    labelTemplate: '第 {value}{unit}',
                    reminderOffsetDays: 5,
                    status: TimelineMilestoneRuleStatus.paused,
                    createdAt: DateTime(2026, 4, 1),
                    updatedAt: DateTime(2026, 4, 2),
                  ),
                ],
                upcomingOccurrences: const [],
                historyRecords: const [],
              ),
            ),
          ),
        ],
        child: const MaterialApp(
          home: TaskTimelineEditorPage(
            mode: TaskTimelineEditorMode.timelineEdit,
            id: 9,
          ),
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
}
