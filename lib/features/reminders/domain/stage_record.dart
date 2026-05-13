import 'stage_rule.dart';

enum StageRecordSourceType { generated, manual }

enum StageRecordStatus { normal, acknowledged, ignored, archived }

class StageRecord {
  const StageRecord({
    required this.id,
    required this.stageTrackerId,
    this.stageRuleId,
    required this.sourceType,
    this.occurrenceIndex,
    required this.occurrenceDate,
    this.relativeAmount,
    this.relativeUnit,
    required this.status,
    required this.label,
    this.note,
    this.reminderOffsetDays,
    required this.createdAt,
    required this.updatedAt,
  });

  final int id;
  final int stageTrackerId;
  final int? stageRuleId;
  final StageRecordSourceType sourceType;
  final int? occurrenceIndex;
  final DateTime occurrenceDate;
  final int? relativeAmount;
  final StageIntervalUnit? relativeUnit;
  final StageRecordStatus status;
  final String label;
  final String? note;
  final int? reminderOffsetDays;
  final DateTime createdAt;
  final DateTime updatedAt;
}
