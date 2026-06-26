class AttentionSummary {
  const AttentionSummary({
    required this.dangerItemCount,
    required this.warningItemCount,
    required this.dangerResourceCount,
    required this.warningResourceCount,
    required this.stageUpcomingCount,
    this.remoteBackedItemCount = 0,
    this.pendingSyncItemCount = 0,
    this.failedSyncItemCount = 0,
    this.staleSyncItemCount = 0,
    this.accessLostRemoteBackedItemCount = 0,
    this.notificationSyncLabels = const <String>[],
  });

  final int dangerItemCount;
  final int warningItemCount;
  final int dangerResourceCount;
  final int warningResourceCount;
  final int stageUpcomingCount;
  final int remoteBackedItemCount;
  final int pendingSyncItemCount;
  final int failedSyncItemCount;
  final int staleSyncItemCount;
  final int accessLostRemoteBackedItemCount;
  final List<String> notificationSyncLabels;

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
        other.stageUpcomingCount == stageUpcomingCount &&
        other.remoteBackedItemCount == remoteBackedItemCount &&
        other.pendingSyncItemCount == pendingSyncItemCount &&
        other.failedSyncItemCount == failedSyncItemCount &&
        other.staleSyncItemCount == staleSyncItemCount &&
        other.accessLostRemoteBackedItemCount ==
            accessLostRemoteBackedItemCount &&
        _listEquals(other.notificationSyncLabels, notificationSyncLabels);
  }

  @override
  int get hashCode => Object.hash(
    dangerItemCount,
    warningItemCount,
    dangerResourceCount,
    warningResourceCount,
    stageUpcomingCount,
    remoteBackedItemCount,
    pendingSyncItemCount,
    failedSyncItemCount,
    staleSyncItemCount,
    accessLostRemoteBackedItemCount,
    Object.hashAll(notificationSyncLabels),
  );

  static bool _listEquals(List<String> a, List<String> b) {
    if (identical(a, b)) {
      return true;
    }
    if (a.length != b.length) {
      return false;
    }
    for (var index = 0; index < a.length; index++) {
      if (a[index] != b[index]) {
        return false;
      }
    }
    return true;
  }
}
