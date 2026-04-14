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
        labelTemplate: '第 {value}{unit}',
        reminderOffsetDays: 2,
        status: TimelineMilestoneRuleStatus.active,
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
      expect(upcoming.single.label, '第 7天');
      expect(today, hasLength(1));
      expect(today.single.occurrenceIndex, 1);
      expect(today.single.label, '第 7天');
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
      labelTemplate: '第 {value}{unit}',
      reminderOffsetDays: 0,
      status: TimelineMilestoneRuleStatus.active,
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
    expect(next.label, '第 1個月');
  });

  test(
    'timeline milestone service formats placeholders for all rule types',
    () {
      const service = TimelineMilestoneService();

      final dayRule = TimelineMilestoneRule(
        id: 1,
        timelineId: 1,
        type: TimelineMilestoneRuleType.everyNDays,
        intervalValue: 30,
        intervalUnit: TimelineMilestoneIntervalUnit.days,
        labelTemplate: '第 {n}次，第 {value}{unit}',
        reminderOffsetDays: 0,
        status: TimelineMilestoneRuleStatus.active,
        createdAt: DateTime(2026, 4, 1),
        updatedAt: DateTime(2026, 4, 1),
      );
      final weekRule = TimelineMilestoneRule(
        id: 4,
        timelineId: 1,
        type: TimelineMilestoneRuleType.everyNWeeks,
        intervalValue: 2,
        intervalUnit: TimelineMilestoneIntervalUnit.weeks,
        labelTemplate: '第 {n}次，第 {value}{unit}',
        reminderOffsetDays: 0,
        status: TimelineMilestoneRuleStatus.active,
        createdAt: DateTime(2026, 4, 1),
        updatedAt: DateTime(2026, 4, 1),
      );
      final monthRule = TimelineMilestoneRule(
        id: 2,
        timelineId: 1,
        type: TimelineMilestoneRuleType.everyNMonths,
        intervalValue: 2,
        intervalUnit: TimelineMilestoneIntervalUnit.months,
        labelTemplate: '第 {value}{unit}',
        reminderOffsetDays: 0,
        status: TimelineMilestoneRuleStatus.active,
        createdAt: DateTime(2026, 4, 1),
        updatedAt: DateTime(2026, 4, 1),
      );
      final yearRule = TimelineMilestoneRule(
        id: 3,
        timelineId: 1,
        type: TimelineMilestoneRuleType.everyNYears,
        intervalValue: 1,
        intervalUnit: TimelineMilestoneIntervalUnit.years,
        labelTemplate: '第 {value}{unit}',
        reminderOffsetDays: 0,
        status: TimelineMilestoneRuleStatus.active,
        createdAt: DateTime(2026, 4, 1),
        updatedAt: DateTime(2026, 4, 1),
      );

      expect(service.occurrenceCount(dayRule, 2), 2);
      expect(service.accumulatedValue(dayRule, 2), 60);
      expect(service.displayUnitLabel(dayRule), '天');
      expect(service.formatLabel(dayRule, 2), '第 2次，第 60天');
      expect(service.occurrenceCount(weekRule, 1), 1);
      expect(service.accumulatedValue(weekRule, 1), 2);
      expect(service.displayUnitLabel(weekRule), '週');
      expect(service.formatLabel(weekRule, 1), '第 1次，第 2週');
      expect(service.formatLabel(monthRule, 1), '第 2個月');
      expect(service.formatLabel(yearRule, 1), '第 1年');
    },
  );

  test('timeline status only allows active and archived', () {
    expect(TimelineStatus.values.map((status) => status.name).toList(), [
      'active',
      'archived',
    ]);
  });

  test('paused and archived milestone rules do not produce occurrences', () {
    const service = TimelineMilestoneService();
    final timeline = Timeline(
      id: 1,
      title: 'Reading',
      startDate: DateTime(2026, 4, 10),
      displayUnit: TimelineDisplayUnit.day,
      status: TimelineStatus.active,
      createdAt: DateTime(2026, 4, 10),
      updatedAt: DateTime(2026, 4, 10),
    );
    final pausedRule = TimelineMilestoneRule(
      id: 11,
      timelineId: 1,
      type: TimelineMilestoneRuleType.everyNDays,
      intervalValue: 10,
      intervalUnit: TimelineMilestoneIntervalUnit.days,
      labelTemplate: '第 {value}{unit}',
      reminderOffsetDays: 0,
      status: TimelineMilestoneRuleStatus.paused,
      createdAt: DateTime(2026, 4, 1),
      updatedAt: DateTime(2026, 4, 1),
    );
    final archivedRule = TimelineMilestoneRule(
      id: 12,
      timelineId: 1,
      type: TimelineMilestoneRuleType.everyNDays,
      intervalValue: 20,
      intervalUnit: TimelineMilestoneIntervalUnit.days,
      labelTemplate: '第 {value}{unit}',
      reminderOffsetDays: 0,
      status: TimelineMilestoneRuleStatus.archived,
      createdAt: DateTime(2026, 4, 1),
      updatedAt: DateTime(2026, 4, 1),
    );

    expect(
      service.getNextOccurrence(
        pausedRule,
        timeline,
        after: DateTime(2026, 4, 10),
      ),
      isNull,
    );
    expect(
      service.getNextOccurrence(
        archivedRule,
        timeline,
        after: DateTime(2026, 4, 10),
      ),
      isNull,
    );
  });
}
