enum StageTrackerStatus { active, archived }

class StageTracker {
  const StageTracker({
    required this.id,
    required this.packId,
    required this.title,
    this.subjectName,
    required this.trackingStartDate,
    this.trackingEndDate,
    required this.status,
    this.isSystemDefault = false,
    this.systemKey,
    this.isHidden = false,
    required this.createdAt,
    required this.updatedAt,
  });

  final int id;
  final int packId;
  final String title;
  final String? subjectName;
  final DateTime trackingStartDate;
  final DateTime? trackingEndDate;
  final StageTrackerStatus status;
  final bool isSystemDefault;
  final String? systemKey;
  final bool isHidden;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool isTrackingRangeCompleted(DateTime now) {
    final end = trackingEndDate;
    if (end == null) {
      return false;
    }
    return _normalizeDate(now).isAfter(_normalizeDate(end));
  }

  DateTime _normalizeDate(DateTime value) {
    return DateTime(value.year, value.month, value.day);
  }
}
