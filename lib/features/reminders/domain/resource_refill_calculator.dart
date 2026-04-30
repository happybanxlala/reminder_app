import 'item.dart';

class ResourceRefillResult {
  const ResourceRefillResult({
    required this.anchorDate,
    required this.durationDays,
    required this.lastDoneAt,
  });

  final DateTime anchorDate;
  final int durationDays;
  final DateTime lastDoneAt;
}

class ResourceRefillCalculator {
  const ResourceRefillCalculator();

  ResourceRefillResult refill(
    ResourceBasedItemConfig config, {
    required DateTime actionDate,
    required int addedDays,
  }) {
    final normalizedActionDate = _normalizeDate(actionDate);
    if (config.anchorDate == null || config.durationDays <= 0) {
      return ResourceRefillResult(
        anchorDate: normalizedActionDate,
        durationDays: addedDays,
        lastDoneAt: normalizedActionDate,
      );
    }

    final anchorDate = _normalizeDate(config.anchorDate!);
    final depletionDate = anchorDate.add(
      Duration(days: config.durationDays - 1),
    );
    if (normalizedActionDate.isAfter(depletionDate)) {
      return ResourceRefillResult(
        anchorDate: normalizedActionDate,
        durationDays: addedDays,
        lastDoneAt: normalizedActionDate,
      );
    }

    final remainingCarryDays =
        depletionDate.difference(normalizedActionDate).inDays + 1;
    return ResourceRefillResult(
      anchorDate: normalizedActionDate,
      durationDays:
          (remainingCarryDays < 0 ? 0 : remainingCarryDays) + addedDays,
      lastDoneAt: normalizedActionDate,
    );
  }

  DateTime _normalizeDate(DateTime value) {
    return DateTime(value.year, value.month, value.day);
  }
}
