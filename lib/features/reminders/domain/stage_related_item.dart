class StageRelatedItem {
  const StageRelatedItem({
    required this.id,
    required this.stageRecordId,
    required this.itemId,
    required this.createdAt,
    required this.updatedAt,
  });

  final int id;
  final int stageRecordId;
  final int itemId;
  final DateTime createdAt;
  final DateTime updatedAt;
}

class StageRelatedItemSummary {
  const StageRelatedItemSummary({
    this.doneCount = 0,
    this.activeCount = 0,
    this.pausedCount = 0,
    this.skippedCount = 0,
  });

  final int doneCount;
  final int activeCount;
  final int pausedCount;
  final int skippedCount;

  int get totalRelevantCount => doneCount + activeCount;
}
