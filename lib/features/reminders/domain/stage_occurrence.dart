import 'stage_record.dart';
import 'stage_related_item.dart';

class StageOccurrence {
  const StageOccurrence({
    this.stageTrackerTitle,
    this.subjectName,
    this.stageRecordId,
    required this.stageTrackerId,
    this.stageRuleId,
    required this.sourceType,
    this.occurrenceIndex,
    required this.occurrenceDate,
    required this.label,
    this.note,
    required this.reminderOffsetDays,
    this.recordStatus,
    this.relatedItemSummary,
  });

  final String? stageTrackerTitle;
  final String? subjectName;
  final int stageTrackerId;
  final int? stageRuleId;
  final int? stageRecordId;
  final StageRecordSourceType sourceType;
  final int? occurrenceIndex;
  final DateTime occurrenceDate;
  final String label;
  final String? note;
  final int reminderOffsetDays;
  final StageRecordStatus? recordStatus;
  final StageRelatedItemSummary? relatedItemSummary;

  bool get isGenerated => sourceType == StageRecordSourceType.generated;
  bool get isManual => sourceType == StageRecordSourceType.manual;
}
