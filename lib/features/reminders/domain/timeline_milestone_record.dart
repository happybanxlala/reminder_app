enum TimelineMilestoneRecordStatus { upcoming, noticed, skipped }

class TimelineMilestoneRecord {
  const TimelineMilestoneRecord({
    required this.id,
    required this.timelineId,
    required this.ruleId,
    required this.occurrenceIndex,
    required this.targetDate,
    required this.status,
    this.notifiedAt,
    this.actedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  final int id;
  final int timelineId;
  final int ruleId;
  final int occurrenceIndex;
  final DateTime targetDate;
  final TimelineMilestoneRecordStatus status;
  final DateTime? notifiedAt;
  final DateTime? actedAt;
  final DateTime createdAt;
  final DateTime updatedAt;
}
