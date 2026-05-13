class AttentionSummary {
  const AttentionSummary({
    required this.dangerCount,
    required this.warningCount,
    required this.stageUpcomingCount,
  });

  final int dangerCount;
  final int warningCount;
  final int stageUpcomingCount;

  int get totalCount => dangerCount + warningCount + stageUpcomingCount;

  bool get hasAttention => totalCount > 0;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is AttentionSummary &&
        other.dangerCount == dangerCount &&
        other.warningCount == warningCount &&
        other.stageUpcomingCount == stageUpcomingCount;
  }

  @override
  int get hashCode =>
      Object.hash(dangerCount, warningCount, stageUpcomingCount);
}
