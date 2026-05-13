import '../domain/stage_occurrence.dart';
import '../domain/stage_record.dart';
import '../domain/stage_rule.dart';
import '../domain/stage_tracker.dart';

class StageRuleInput {
  const StageRuleInput({
    this.id,
    required this.type,
    required this.intervalValue,
    required this.intervalUnit,
    this.labelTemplate,
    this.reminderOffsetDays,
    this.status = StageRuleStatus.active,
  });

  final int? id;
  final StageRuleType type;
  final int intervalValue;
  final StageIntervalUnit intervalUnit;
  final String? labelTemplate;
  final int? reminderOffsetDays;
  final StageRuleStatus status;
}

class StageTrackerInput {
  const StageTrackerInput({
    required this.title,
    this.subjectName,
    required this.trackingStartDate,
    this.trackingEndDate,
    this.packId,
    this.stageRules = const [],
  });

  final String title;
  final String? subjectName;
  final DateTime trackingStartDate;
  final DateTime? trackingEndDate;
  final int? packId;
  final List<StageRuleInput> stageRules;
}

class ManualStageInput {
  const ManualStageInput({
    required this.label,
    required this.occurrenceDate,
    this.relativeAmount,
    this.relativeUnit,
    this.note,
    this.reminderOffsetDays,
  });

  final String label;
  final DateTime occurrenceDate;
  final int? relativeAmount;
  final StageIntervalUnit? relativeUnit;
  final String? note;
  final int? reminderOffsetDays;
}

class StageTrackerDetail {
  const StageTrackerDetail({
    required this.stageTracker,
    required this.stageRules,
    required this.stageRecords,
    required this.dashboardUpcomingStages,
    required this.scheduleStages,
    required this.historyStages,
  });

  final StageTracker stageTracker;
  final List<StageRule> stageRules;
  final List<StageRecord> stageRecords;
  final List<StageOccurrence> dashboardUpcomingStages;
  final List<StageOccurrence> scheduleStages;
  final List<StageOccurrence> historyStages;

  StageOccurrence? get nextStage =>
      dashboardUpcomingStages.isEmpty ? null : dashboardUpcomingStages.first;
}
