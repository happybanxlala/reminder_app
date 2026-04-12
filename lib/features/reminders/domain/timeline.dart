import 'milestone_reminder_rule.dart';

enum TimelineDisplayUnit { day, week, month, year }

enum TimelineStatus { active, archived }

class Timeline {
  const Timeline({
    required this.id,
    required this.title,
    required this.startDate,
    required this.displayUnit,
    required this.status,
    required this.milestoneReminderRule,
    required this.createdAt,
    required this.updatedAt,
  });

  final int id;
  final String title;
  final DateTime startDate;
  final TimelineDisplayUnit displayUnit;
  final TimelineStatus status;
  final MilestoneReminderRule milestoneReminderRule;
  final DateTime createdAt;
  final DateTime updatedAt;
}
