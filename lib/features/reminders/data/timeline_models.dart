import '../domain/timeline.dart';
import '../domain/timeline_milestone_occurrence.dart';
import '../domain/timeline_milestone_rule.dart';
import 'local/task_timeline_dao.dart';

class TimelineMilestoneRuleInput {
  const TimelineMilestoneRuleInput({
    this.id,
    required this.type,
    required this.intervalValue,
    required this.intervalUnit,
    this.labelTemplate,
    this.reminderOffsetDays = 0,
    this.status = TimelineMilestoneRuleStatus.active,
  });

  final int? id;
  final TimelineMilestoneRuleType type;
  final int intervalValue;
  final TimelineMilestoneIntervalUnit intervalUnit;
  final String? labelTemplate;
  final int reminderOffsetDays;
  final TimelineMilestoneRuleStatus status;
}

class TimelineInput {
  const TimelineInput({
    required this.title,
    required this.startDate,
    required this.displayUnit,
    this.milestoneRules = const [],
  });

  final String title;
  final DateTime startDate;
  final TimelineDisplayUnit displayUnit;
  final List<TimelineMilestoneRuleInput> milestoneRules;
}

class TimelineMilestoneRuleDetail {
  const TimelineMilestoneRuleDetail({
    required this.rule,
    required this.nextMilestone,
    required this.historyRecords,
  });

  final TimelineMilestoneRule rule;
  final TimelineMilestoneOccurrence? nextMilestone;
  final List<TimelineMilestoneRecordBundle> historyRecords;
}

class TimelineDetail {
  const TimelineDetail({
    required this.timeline,
    required this.milestoneRuleDetails,
    required this.upcomingMilestones,
    required this.milestoneHistory,
  });

  final Timeline timeline;
  final List<TimelineMilestoneRuleDetail> milestoneRuleDetails;
  final List<TimelineMilestoneOccurrence> upcomingMilestones;
  final List<TimelineMilestoneRecordBundle> milestoneHistory;
}
