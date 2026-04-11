enum MilestoneSource { ruleBased, custom }

enum MilestoneStatus { upcoming, noticed, skipped }

class Milestone {
  const Milestone({
    required this.id,
    required this.timelineId,
    required this.targetDate,
    this.description,
    required this.source,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  final int id;
  final int timelineId;
  final DateTime targetDate;
  final String? description;
  final MilestoneSource source;
  final MilestoneStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
}
