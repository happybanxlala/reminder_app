import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reminder_app/features/reminders/data/home_query_service.dart';
import 'package:reminder_app/features/reminders/data/local/task_timeline_dao.dart';
import 'package:reminder_app/features/reminders/domain/reminder_rule.dart';
import 'package:reminder_app/features/reminders/domain/task.dart';
import 'package:reminder_app/features/reminders/domain/task_template.dart';
import 'package:reminder_app/features/reminders/domain/timeline.dart';
import 'package:reminder_app/features/reminders/domain/timeline_milestone_occurrence.dart';
import 'package:reminder_app/features/reminders/domain/timeline_milestone_record.dart';
import 'package:reminder_app/features/reminders/domain/timeline_milestone_rule.dart';
import 'package:reminder_app/features/reminders/providers/history_providers.dart';
import 'package:reminder_app/features/reminders/providers/home_providers.dart';
import 'package:reminder_app/features/reminders/providers/task_providers.dart';
import 'package:reminder_app/features/reminders/ui/pages/history_page.dart';
import 'package:reminder_app/features/reminders/ui/pages/home_page.dart';

void main() {
  testWidgets('home shows only today upcoming overdue tabs', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          todayHomeItemsProvider.overrideWith(
            (ref) => Stream.value([
              TaskHomeItem(_taskBundle(title: 'Laundry')),
              MilestoneHomeItem(_occurrence(title: 'No sugar')),
            ]),
          ),
          upcomingHomeItemsProvider.overrideWith(
            (ref) => Stream.value(<HomeItem>[]),
          ),
          overdueTasksProvider.overrideWith(
            (ref) => Stream.value(<TaskBundle>[]),
          ),
        ],
        child: const MaterialApp(home: HomePage()),
      ),
    );
    await tester.pump();

    expect(find.text('Today'), findsOneWidget);
    expect(find.text('Upcoming'), findsOneWidget);
    expect(find.text('Overdue'), findsOneWidget);
    expect(find.text('History'), findsNothing);
    expect(find.text('Laundry'), findsOneWidget);
    expect(find.text('No sugar'), findsOneWidget);
  });

  testWidgets('overdue tab only renders task items', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          todayHomeItemsProvider.overrideWith(
            (ref) => Stream.value(<HomeItem>[]),
          ),
          upcomingHomeItemsProvider.overrideWith(
            (ref) => Stream.value(<HomeItem>[]),
          ),
          overdueTasksProvider.overrideWith(
            (ref) => Stream.value([_taskBundle(title: 'Old task')]),
          ),
        ],
        child: const MaterialApp(home: HomePage()),
      ),
    );
    await tester.pump();

    await tester.tap(find.text('Overdue', skipOffstage: false).last);
    await tester.pumpAndSettle();

    expect(find.text('Old task'), findsOneWidget);
    expect(find.text('Milestone'), findsNothing);
    expect(find.text('完成'), findsOneWidget);
    expect(find.text('跳過'), findsOneWidget);
    expect(find.text('延期 1 天'), findsOneWidget);
    expect(find.text('取消'), findsOneWidget);
  });

  testWidgets('history page paginates task and milestone sections', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          taskHistoryProvider.overrideWith(
            (ref) => Stream.value(
              List.generate(11, (index) => _taskBundle(title: 'Task $index')),
            ),
          ),
          milestoneHistoryProvider.overrideWith(
            (ref) => Stream.value(
              List.generate(
                11,
                (index) => _milestoneRecordBundle(title: 'Timeline $index'),
              ),
            ),
          ),
        ],
        child: const MaterialApp(home: HistoryPage()),
      ),
    );
    await tester.pump();

    expect(find.text('Task History'), findsOneWidget);
    expect(find.text('Task 0'), findsOneWidget);
    expect(find.text('Task 9'), findsOneWidget);
    expect(find.text('Task 10'), findsNothing);
    expect(find.textContaining('最後更新'), findsWidgets);

    await tester.ensureVisible(find.byKey(const Key('task-history-next')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('task-history-next')));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView), const Offset(0, 600));
    await tester.pumpAndSettle();

    expect(find.text('2 / 2'), findsWidgets);
    expect(find.text('Task 10'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Milestone History', skipOffstage: false),
      400,
    );
    await tester.pumpAndSettle();

    expect(find.text('Milestone History'), findsOneWidget);
  });
}

TaskBundle _taskBundle({required String title}) {
  final id = title.hashCode;
  return TaskBundle(
    task: Task(
      id: id,
      templateId: 1,
      kind: TaskKind.oneTime,
      titleSnapshot: title,
      dueDate: DateTime(2026, 4, 10),
      reminderRule: const ReminderRule.onDue(),
      status: TaskStatus.done,
      createdAt: DateTime(2026, 4, 1),
      updatedAt: DateTime(2026, 4, 1),
      resolvedAt: DateTime(2026, 4, 10),
    ),
    template: TaskTemplate(
      id: id,
      title: title,
      kind: TaskKind.oneTime,
      status: TaskTemplateStatus.active,
      firstDueDate: DateTime(2026, 4, 10),
      reminderRule: const ReminderRule.onDue(),
      createdAt: DateTime(2026, 4, 1),
      updatedAt: DateTime(2026, 4, 1),
    ),
  );
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
    status: MilestoneStatus.noticed,
    reminderOffsetDays: 0,
    actedAt: DateTime(2026, 4, 10),
  );
}

TimelineMilestoneRecordBundle _milestoneRecordBundle({required String title}) {
  final id = title.hashCode;
  return TimelineMilestoneRecordBundle(
    record: TimelineMilestoneRecord(
      id: id,
      timelineId: id,
      ruleId: id,
      occurrenceIndex: 1,
      targetDate: DateTime(2026, 4, 10),
      status: MilestoneStatus.noticed,
      actedAt: DateTime(2026, 4, 10),
      createdAt: DateTime(2026, 4, 1),
      updatedAt: DateTime(2026, 4, 1),
    ),
    rule: TimelineMilestoneRule(
      id: id,
      timelineId: id,
      type: TimelineMilestoneRuleType.everyNDays,
      intervalValue: 30,
      intervalUnit: TimelineMilestoneIntervalUnit.days,
      labelTemplate: '第 {n} 個 30 天',
      reminderOffsetDays: 0,
      status: TimelineMilestoneRuleStatus.active,
      createdAt: DateTime(2026, 4, 1),
      updatedAt: DateTime(2026, 4, 1),
    ),
    timeline: Timeline(
      id: id,
      title: title,
      startDate: DateTime(2026, 4, 1),
      displayUnit: TimelineDisplayUnit.day,
      status: TimelineStatus.active,
      createdAt: DateTime(2026, 4, 1),
      updatedAt: DateTime(2026, 4, 1),
    ),
  );
}
