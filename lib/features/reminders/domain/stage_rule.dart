enum StageRuleType { everyNDays, everyNWeeks, everyNMonths, everyNYears }

enum StageIntervalUnit { days, weeks, months, years }

enum StageRuleStatus { active, paused, archived }

class StageRule {
  const StageRule({
    required this.id,
    required this.stageTrackerId,
    required this.type,
    required this.intervalValue,
    required this.intervalUnit,
    this.labelTemplate,
    this.reminderOffsetDays,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  final int id;
  final int stageTrackerId;
  final StageRuleType type;
  final int intervalValue;
  final StageIntervalUnit intervalUnit;
  final String? labelTemplate;
  final int? reminderOffsetDays;
  final StageRuleStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
}
