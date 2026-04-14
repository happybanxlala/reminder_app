import 'timeline_milestone_record.dart';

class TimelineMilestoneOccurrence {
  const TimelineMilestoneOccurrence({
    this.recordId,
    required this.timelineId,
    required this.timelineTitle,
    required this.ruleId,
    required this.occurrenceIndex,
    required this.targetDate,
    required this.label,
    required this.status,
    required this.reminderOffsetDays,
    this.notifiedAt,
    this.actedAt,
  });

  final int? recordId;
  final int timelineId;
  final String timelineTitle;
  final int ruleId;
  final int occurrenceIndex;
  final DateTime targetDate;
  final String label;
  final MilestoneStatus status;
  final int reminderOffsetDays;
  final DateTime? notifiedAt;
  final DateTime? actedAt;
}
