import 'resource.dart';

class TimeResourceRefillResult {
  const TimeResourceRefillResult({
    required this.anchorDate,
    required this.durationDays,
  });

  final DateTime anchorDate;
  final int durationDays;
}

class ResourceRefillService {
  const ResourceRefillService();

  TimeResourceRefillResult refillTimeBased(
    TimeBasedResourceConfig config, {
    required DateTime actionDate,
    required int addedDays,
  }) {
    final normalizedActionDate = _normalizeDate(actionDate);
    if (config.anchorDate == null || config.durationDays <= 0) {
      return TimeResourceRefillResult(
        anchorDate: normalizedActionDate,
        durationDays: addedDays,
      );
    }

    final anchorDate = _normalizeDate(config.anchorDate!);
    final depletionDate = anchorDate.add(
      Duration(days: config.durationDays - 1),
    );
    if (normalizedActionDate.isAfter(depletionDate)) {
      return TimeResourceRefillResult(
        anchorDate: normalizedActionDate,
        durationDays: addedDays,
      );
    }

    final remainingCarryDays =
        depletionDate.difference(normalizedActionDate).inDays + 1;
    return TimeResourceRefillResult(
      anchorDate: normalizedActionDate,
      durationDays: remainingCarryDays + addedDays,
    );
  }

  int refillQuantity(QuantityBasedResourceConfig config, int addedQuantity) {
    return _clampQuantity(config.currentQuantity + addedQuantity);
  }

  int consumeQuantity(QuantityBasedResourceConfig config, int consumeAmount) {
    return _clampQuantity(config.currentQuantity - consumeAmount);
  }

  int adjustQuantity(int newQuantity) {
    return _clampQuantity(newQuantity);
  }

  int _clampQuantity(int value) => value < 0 ? 0 : value;

  DateTime _normalizeDate(DateTime value) {
    return DateTime(value.year, value.month, value.day);
  }
}
