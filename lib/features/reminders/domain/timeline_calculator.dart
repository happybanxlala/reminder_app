import 'milestone.dart';
import 'milestone_reminder_rule.dart';
import 'timeline.dart';

class TimelineCalculator {
  const TimelineCalculator();

  int displayValue(Timeline timeline, DateTime now) {
    final start = DateTime(
      timeline.startDate.year,
      timeline.startDate.month,
      timeline.startDate.day,
    );
    final today = DateTime(now.year, now.month, now.day);
    final days = today.difference(start).inDays + 1;
    final safeDays = days < 1 ? 1 : days;
    return switch (timeline.displayUnit) {
      TimelineDisplayUnit.day => safeDays,
      TimelineDisplayUnit.week => ((safeDays - 1) ~/ 7) + 1,
      TimelineDisplayUnit.month =>
        ((today.year - start.year) * 12 + today.month - start.month) + 1,
      TimelineDisplayUnit.year => (today.year - start.year) + 1,
    };
  }

  DateTime reminderDate(
    Milestone milestone,
    MilestoneReminderRule reminderRule,
  ) {
    return switch (reminderRule.type) {
      MilestoneReminderRuleType.advance => milestone.targetDate.subtract(
        Duration(days: reminderRule.offsetDays ?? 0),
      ),
      MilestoneReminderRuleType.onDay => milestone.targetDate,
    };
  }

  bool isToday(
    Milestone milestone,
    MilestoneReminderRule reminderRule,
    DateTime now,
  ) {
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    return milestone.status == MilestoneStatus.upcoming &&
        !milestone.targetDate.isBefore(today) &&
        milestone.targetDate.isBefore(tomorrow);
  }

  bool isUpcoming(
    Milestone milestone,
    MilestoneReminderRule reminderRule,
    DateTime now,
  ) {
    final today = DateTime(now.year, now.month, now.day);
    if (milestone.status != MilestoneStatus.upcoming ||
        !milestone.targetDate.isAfter(today)) {
      return false;
    }

    return switch (reminderRule.type) {
      MilestoneReminderRuleType.advance => !today.isBefore(
        reminderDate(milestone, reminderRule),
      ),
      MilestoneReminderRuleType.onDay => false,
    };
  }
}
