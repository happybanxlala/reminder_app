class AttentionSummary {
  const AttentionSummary({
    required this.dangerCount,
    required this.warningCount,
    required this.timelineUpcomingCount,
  });

  final int dangerCount;
  final int warningCount;
  final int timelineUpcomingCount;

  int get totalCount => dangerCount + warningCount + timelineUpcomingCount;

  bool get hasAttention => totalCount > 0;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is AttentionSummary &&
        other.dangerCount == dangerCount &&
        other.warningCount == warningCount &&
        other.timelineUpcomingCount == timelineUpcomingCount;
  }

  @override
  int get hashCode =>
      Object.hash(dangerCount, warningCount, timelineUpcomingCount);
}
