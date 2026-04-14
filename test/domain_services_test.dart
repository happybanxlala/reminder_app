import 'package:flutter_test/flutter_test.dart';
import 'package:reminder_app/features/reminders/domain/reminder_rule.dart';
import 'package:reminder_app/features/reminders/domain/repeat_rule.dart';
import 'package:reminder_app/features/reminders/domain/task.dart';
import 'package:reminder_app/features/reminders/domain/task_scheduler.dart';
import 'package:reminder_app/features/reminders/domain/task_template.dart';
import 'package:reminder_app/features/reminders/domain/timeline.dart';
import 'package:reminder_app/features/reminders/domain/timeline_calculator.dart';
import 'package:reminder_app/features/reminders/domain/timeline_milestone_rule.dart';
import 'package:reminder_app/features/reminders/domain/timeline_milestone_service.dart';

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

  test('timeline calculator returns display value', () {
    const calculator = TimelineCalculator();
    final timeline = Timeline(
      id: 1,
      title: 'Dating',
      startDate: DateTime(2026, 4, 10),
      displayUnit: TimelineDisplayUnit.day,
      status: TimelineStatus.active,
      createdAt: DateTime(2026, 4, 10),
      updatedAt: DateTime(2026, 4, 10),
    );

    expect(calculator.displayValue(timeline, DateTime(2026, 4, 12)), 3);
  });

  test(
    'timeline milestone service computes today and upcoming dynamically',
    () {
      const service = TimelineMilestoneService();
      final timeline = Timeline(
        id: 1,
        title: 'Dating',
        startDate: DateTime(2026, 4, 10),
        displayUnit: TimelineDisplayUnit.day,
        status: TimelineStatus.active,
        createdAt: DateTime(2026, 4, 10),
        updatedAt: DateTime(2026, 4, 10),
      );
      final rule = TimelineMilestoneRule(
        id: 11,
        timelineId: 1,
        type: TimelineMilestoneRuleType.everyNDays,
        intervalValue: 7,
        intervalUnit: TimelineMilestoneIntervalUnit.days,
        labelTemplate: '第 {n} 週',
        reminderOffsetDays: 2,
        isActive: true,
        createdAt: DateTime(2026, 4, 10),
        updatedAt: DateTime(2026, 4, 10),
      );

      final upcoming = service.getUpcomingOccurrences(
        timeline,
        [rule],
        const [],
        TimelineMilestoneRange(
          start: DateTime(2026, 4, 15),
          end: DateTime(2026, 4, 20),
        ),
        now: DateTime(2026, 4, 15),
      );
      final today = service.getTodayOccurrences(
        timeline,
        [rule],
        const [],
        now: DateTime(2026, 4, 16),
      );

      expect(upcoming, hasLength(1));
      expect(upcoming.single.targetDate, DateTime(2026, 4, 16));
      expect(today, hasLength(1));
      expect(today.single.occurrenceIndex, 1);
    },
  );

  test('timeline milestone service clamps month-end dates', () {
    const service = TimelineMilestoneService();
    final timeline = Timeline(
      id: 1,
      title: 'Sober',
      startDate: DateTime(2026, 1, 31),
      displayUnit: TimelineDisplayUnit.month,
      status: TimelineStatus.active,
      createdAt: DateTime(2026, 1, 31),
      updatedAt: DateTime(2026, 1, 31),
    );
    final rule = TimelineMilestoneRule(
      id: 21,
      timelineId: 1,
      type: TimelineMilestoneRuleType.everyNMonths,
      intervalValue: 1,
      intervalUnit: TimelineMilestoneIntervalUnit.months,
      labelTemplate: '第 {n} 個月',
      reminderOffsetDays: 0,
      isActive: true,
      createdAt: DateTime(2026, 1, 31),
      updatedAt: DateTime(2026, 1, 31),
    );

    final next = service.getNextOccurrence(
      rule,
      timeline,
      after: DateTime(2026, 2, 1),
    );

    expect(next, isNotNull);
    expect(next!.targetDate, DateTime(2026, 2, 28));
  });

  test('timeline status only allows active and archived', () {
    expect(TimelineStatus.values.map((status) => status.name).toList(), [
      'active',
      'archived',
    ]);
  });
}
