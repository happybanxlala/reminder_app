import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reminder_app/features/reminders/data/timeline_repository.dart';
import 'package:reminder_app/features/reminders/domain/milestone_reminder_rule.dart';
import 'package:reminder_app/features/reminders/domain/reminder_rule.dart';
import 'package:reminder_app/features/reminders/domain/task_template.dart';
import 'package:reminder_app/features/reminders/domain/timeline.dart';
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

  testWidgets('timeline form only shows offset for advance milestone rule', (
    tester,
  ) async {
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

    expect(find.byKey(const Key('milestone-offset-field')), findsNothing);

    await tester.tap(find.byKey(const Key('milestone-reminder-rule-field')));
    await tester.pumpAndSettle();
    await tester.tap(find.text(MilestoneReminderRuleType.advance.name).last);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('milestone-offset-field')), findsOneWidget);

    await tester.tap(find.byKey(const Key('milestone-reminder-rule-field')));
    await tester.pumpAndSettle();
    await tester.tap(find.text(MilestoneReminderRuleType.onDay.name).last);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('milestone-offset-field')), findsNothing);
  });

  testWidgets('timeline edit initializes current milestone reminder rule', (
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
                  startDate: DateTime(2026, 4, 20),
                  displayUnit: TimelineDisplayUnit.week,
                  status: TimelineStatus.active,
                  milestoneReminderRule: const MilestoneReminderRule.advance(5),
                  createdAt: DateTime(2026, 4, 1),
                  updatedAt: DateTime(2026, 4, 2),
                ),
                customMilestones: const [],
                ruleBasedMilestones: const [],
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

    expect(find.text(MilestoneReminderRuleType.advance.name), findsOneWidget);
    expect(find.byKey(const Key('milestone-offset-field')), findsOneWidget);
    expect(find.text('5'), findsWidgets);
  });
}
