import 'item.dart';

class ItemStatusService {
  const ItemStatusService();

  ItemStatus classify(Item item, {DateTime? now}) {
    final current = _normalizeDate(now ?? DateTime.now());
    return switch (item.config) {
      FixedTimeItemConfig config => _classifyFixedTime(
        item.lastDoneAt,
        config,
        now: current,
      ),
      StateBasedItemConfig config => _classifyStateBased(
        item.lastDoneAt,
        config,
        now: current,
      ),
      ResourceBasedItemConfig config => _classifyResourceBased(
        item.lastDoneAt,
        config,
        now: current,
      ),
      _ => ItemStatus.unknown,
    };
  }

  Duration? elapsedSinceLastDone(Item item, {DateTime? now}) {
    final lastDoneAt = item.lastDoneAt;
    if (lastDoneAt == null) {
      return null;
    }
    return _normalizeDate(
      now ?? DateTime.now(),
    ).difference(_normalizeDate(lastDoneAt));
  }

  ItemStatus _classifyStateBased(
    DateTime? lastDoneAt,
    StateBasedItemConfig config, {
    required DateTime now,
  }) {
    if (lastDoneAt == null) {
      return ItemStatus.unknown;
    }

    final elapsed = now.difference(_normalizeDate(lastDoneAt));
    final normalBoundary = _maxDuration(
      config.expectedInterval,
      config.warningAfter,
    );
    final dangerBoundary = _maxDuration(config.dangerAfter, normalBoundary);

    if (elapsed < normalBoundary) {
      return ItemStatus.normal;
    }
    if (elapsed < dangerBoundary) {
      return ItemStatus.warning;
    }
    return ItemStatus.danger;
  }

  ItemStatus _classifyResourceBased(
    DateTime? lastDoneAt,
    ResourceBasedItemConfig config, {
    required DateTime now,
  }) {
    if (lastDoneAt == null) {
      return ItemStatus.unknown;
    }

    final elapsed = now.difference(_normalizeDate(lastDoneAt));
    final warningBoundary =
        config.estimatedDuration - config.warningBeforeDepletion;

    if (elapsed <
        (warningBoundary.isNegative ? Duration.zero : warningBoundary)) {
      return ItemStatus.normal;
    }
    if (elapsed < config.estimatedDuration) {
      return ItemStatus.warning;
    }
    return ItemStatus.danger;
  }

  ItemStatus _classifyFixedTime(
    DateTime? lastDoneAt,
    FixedTimeItemConfig config, {
    required DateTime now,
  }) {
    final anchorDate = config.anchorDate == null
        ? null
        : _normalizeDate(config.anchorDate!);
    if (anchorDate == null) {
      return ItemStatus.unknown;
    }

    final completedAt = lastDoneAt == null ? null : _normalizeDate(lastDoneAt);
    return switch (config.scheduleType) {
      FixedTimeScheduleType.daily => _classifyDailyFixedTime(
        completedAt,
        anchorDate: anchorDate,
        now: now,
      ),
      FixedTimeScheduleType.weekly => _classifyWeeklyFixedTime(
        completedAt,
        anchorDate: anchorDate,
        now: now,
      ),
      FixedTimeScheduleType.custom => _classifyCustomFixedTime(
        completedAt,
        anchorDate: anchorDate,
        now: now,
      ),
    };
  }

  ItemStatus _classifyDailyFixedTime(
    DateTime? completedAt, {
    required DateTime anchorDate,
    required DateTime now,
  }) {
    if (now.isBefore(anchorDate)) {
      return ItemStatus.normal;
    }
    if (_isCompletedOnOrAfter(completedAt, now)) {
      return ItemStatus.normal;
    }
    if (completedAt != null &&
        _sameDate(
          _normalizeDate(completedAt),
          now.subtract(const Duration(days: 1)),
        )) {
      return ItemStatus.warning;
    }
    return ItemStatus.danger;
  }

  ItemStatus _classifyWeeklyFixedTime(
    DateTime? completedAt, {
    required DateTime anchorDate,
    required DateTime now,
  }) {
    if (now.isBefore(anchorDate)) {
      return ItemStatus.normal;
    }

    final cycleStart = _latestWeeklyCycleStart(anchorDate, now);
    if (_isCompletedOnOrAfter(completedAt, cycleStart)) {
      return ItemStatus.normal;
    }
    if (_sameDate(now, cycleStart)) {
      return ItemStatus.warning;
    }
    return ItemStatus.danger;
  }

  ItemStatus _classifyCustomFixedTime(
    DateTime? completedAt, {
    required DateTime anchorDate,
    required DateTime now,
  }) {
    if (_isCompletedOnOrAfter(completedAt, anchorDate)) {
      return ItemStatus.normal;
    }
    if (now.isBefore(anchorDate)) {
      return ItemStatus.normal;
    }
    if (_sameDate(now, anchorDate)) {
      return ItemStatus.warning;
    }
    return ItemStatus.danger;
  }

  DateTime _latestWeeklyCycleStart(DateTime anchorDate, DateTime now) {
    final difference = now.difference(anchorDate).inDays;
    final weeks = difference ~/ 7;
    return anchorDate.add(Duration(days: weeks * 7));
  }

  bool _isCompletedOnOrAfter(DateTime? completedAt, DateTime cycleStart) {
    if (completedAt == null) {
      return false;
    }
    return !_normalizeDate(completedAt).isBefore(_normalizeDate(cycleStart));
  }

  bool _sameDate(DateTime left, DateTime right) {
    return left.year == right.year &&
        left.month == right.month &&
        left.day == right.day;
  }

  DateTime _normalizeDate(DateTime value) {
    return DateTime(value.year, value.month, value.day);
  }

  Duration _maxDuration(Duration left, Duration right) {
    return left >= right ? left : right;
  }
}
