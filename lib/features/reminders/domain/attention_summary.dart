class AttentionSummary {
  const AttentionSummary({
    required this.dangerItemCount,
    required this.warningItemCount,
    required this.dangerResourceCount,
    required this.warningResourceCount,
    required this.stageUpcomingCount,
  });

  final int dangerItemCount;
  final int warningItemCount;
  final int dangerResourceCount;
  final int warningResourceCount;
  final int stageUpcomingCount;

  int get dangerCount => dangerItemCount + dangerResourceCount;

  int get warningCount => warningItemCount + warningResourceCount;

  int get totalCount => dangerCount + warningCount + stageUpcomingCount;

  bool get hasAttention => totalCount > 0;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is AttentionSummary &&
        other.dangerItemCount == dangerItemCount &&
        other.warningItemCount == warningItemCount &&
        other.dangerResourceCount == dangerResourceCount &&
        other.warningResourceCount == warningResourceCount &&
        other.stageUpcomingCount == stageUpcomingCount;
  }

  @override
  int get hashCode => Object.hash(
    dangerItemCount,
    warningItemCount,
    dangerResourceCount,
    warningResourceCount,
    stageUpcomingCount,
  );
}
