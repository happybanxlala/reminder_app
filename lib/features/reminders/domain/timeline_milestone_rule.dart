enum TimelineMilestoneRuleType {
  everyNDays,
  everyNWeeks,
  everyNMonths,
  everyNYears,
}

enum TimelineMilestoneIntervalUnit { days, weeks, months, years }

enum TimelineMilestoneRuleStatus { active, paused, archived }

class TimelineMilestoneRule {
  const TimelineMilestoneRule({
    required this.id,
    required this.timelineId,
    required this.type,
    required this.intervalValue,
    required this.intervalUnit,
    this.labelTemplate,
    required this.reminderOffsetDays,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  final int id;
  final int timelineId;
  final TimelineMilestoneRuleType type;
  final int intervalValue;
  final TimelineMilestoneIntervalUnit intervalUnit;
  final String? labelTemplate;
  final int reminderOffsetDays;
  final TimelineMilestoneRuleStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
}
