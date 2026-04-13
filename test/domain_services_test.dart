import 'package:flutter_test/flutter_test.dart';
import 'package:reminder_app/features/reminders/domain/milestone.dart';
import 'package:reminder_app/features/reminders/domain/milestone_reminder_rule.dart';
import 'package:reminder_app/features/reminders/domain/reminder_rule.dart';
import 'package:reminder_app/features/reminders/domain/repeat_rule.dart';
import 'package:reminder_app/features/reminders/domain/task.dart';
import 'package:reminder_app/features/reminders/domain/task_scheduler.dart';
import 'package:reminder_app/features/reminders/domain/task_template.dart';
import 'package:reminder_app/features/reminders/domain/timeline.dart';
import 'package:reminder_app/features/reminders/domain/timeline_calculator.dart';

void main() {
  test('task scheduler classifies today upcoming and overdue correctly', () {
    const scheduler = TaskScheduler();
    final task = Task(
      id: 1,
      templateId: 1,
      kind: TaskKind.recurring,
      titleSnapshot: 'Trash',
      dueDate: DateTime(2026, 4, 12),
      repeatRule: const RepeatRule(unit: RepeatUnit.week, interval: 1),
      reminderRule: const ReminderRule.advance(2),
      status: TaskStatus.pending,
      createdAt: DateTime(2026, 4, 1),
      updatedAt: DateTime(2026, 4, 1),
    );

    expect(scheduler.isUpcoming(task, DateTime(2026, 4, 10)), isTrue);
    expect(scheduler.isInToday(task, DateTime(2026, 4, 12)), isTrue);
    expect(scheduler.isOverdue(task, DateTime(2026, 4, 13)), isTrue);
    expect(scheduler.nextDueDate(task, task.repeatRule), DateTime(2026, 4, 19));
  });

  test(
    'timeline calculator returns display value and today classification',
    () {
      const calculator = TimelineCalculator();
      final timeline = Timeline(
        id: 1,
        title: 'Dating',
        startDate: DateTime(2026, 4, 10),
        displayUnit: TimelineDisplayUnit.day,
        status: TimelineStatus.active,
        milestoneReminderRule: const MilestoneReminderRule.advance(1),
        createdAt: DateTime(2026, 4, 10),
        updatedAt: DateTime(2026, 4, 10),
      );
      final milestone = Milestone(
        id: 1,
        timelineId: 1,
        targetDate: DateTime(2026, 4, 12),
        source: MilestoneSource.ruleBased,
        status: MilestoneStatus.upcoming,
        createdAt: DateTime(2026, 4, 10),
        updatedAt: DateTime(2026, 4, 10),
      );

      expect(calculator.displayValue(timeline, DateTime(2026, 4, 12)), 3);
      expect(
        calculator.isToday(
          milestone,
          timeline.milestoneReminderRule,
          DateTime(2026, 4, 12),
        ),
        isTrue,
      );
      expect(
        calculator.isUpcoming(
          milestone,
          timeline.milestoneReminderRule,
          DateTime(2026, 4, 11),
        ),
        isTrue,
      );
    },
  );

  test('timeline status only allows active and archived', () {
    expect(TimelineStatus.values.map((status) => status.name).toList(), [
      'active',
      'archived',
    ]);
  });
}
