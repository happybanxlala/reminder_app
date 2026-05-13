import 'resource.dart';

class ResourceStatusService {
  const ResourceStatusService();

  ResourceStatus classify(Resource resource, {DateTime? now}) {
    return switch (resource.config) {
      TimeBasedResourceConfig config => classifyTimeBased(config, now: now),
      QuantityBasedResourceConfig config => classifyQuantityBased(config),
      _ => ResourceStatus.unknown,
    };
  }

  ResourceStatus classifyTimeBased(
    TimeBasedResourceConfig config, {
    DateTime? now,
  }) {
    final remainingDays = timeBasedRemainingDays(config, now: now);
    if (remainingDays == null) {
      return ResourceStatus.unknown;
    }
    if (remainingDays <= config.dangerBeforeDays) {
      return ResourceStatus.danger;
    }
    if (remainingDays <= config.warningBeforeDays) {
      return ResourceStatus.warning;
    }
    return ResourceStatus.normal;
  }

  ResourceStatus classifyQuantityBased(QuantityBasedResourceConfig config) {
    if (config.currentQuantity < 0) {
      return ResourceStatus.unknown;
    }
    if (config.currentQuantity <= config.dangerThreshold) {
      return ResourceStatus.danger;
    }
    if (config.currentQuantity <= config.warningThreshold) {
      return ResourceStatus.warning;
    }
    return ResourceStatus.normal;
  }

  int? timeBasedRemainingDays(TimeBasedResourceConfig config, {DateTime? now}) {
    final anchorDate = config.anchorDate == null
        ? null
        : _normalizeDate(config.anchorDate!);
    if (anchorDate == null || config.durationDays <= 0) {
      return null;
    }
    final current = _normalizeDate(now ?? DateTime.now());
    final depletionDate = anchorDate.add(
      Duration(days: config.durationDays - 1),
    );
    return depletionDate.difference(current).inDays;
  }

  DateTime? depletionDate(TimeBasedResourceConfig config) {
    if (config.anchorDate == null || config.durationDays <= 0) {
      return null;
    }
    return _normalizeDate(
      config.anchorDate!,
    ).add(Duration(days: config.durationDays - 1));
  }

  DateTime _normalizeDate(DateTime value) {
    return DateTime(value.year, value.month, value.day);
  }
}
