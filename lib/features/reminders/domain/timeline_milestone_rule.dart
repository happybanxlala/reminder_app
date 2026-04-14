enum TimelineMilestoneRuleType { everyNDays, everyNMonths, everyNYears }

enum TimelineMilestoneIntervalUnit { days, months, years }

class TimelineMilestoneRule {
  const TimelineMilestoneRule({
    required this.id,
    required this.timelineId,
    required this.type,
    required this.intervalValue,
    required this.intervalUnit,
    this.labelTemplate,
    required this.reminderOffsetDays,
    required this.isActive,
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
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
}
