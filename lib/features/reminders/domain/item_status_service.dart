import 'item.dart';

class FixedCycleWindow {
  const FixedCycleWindow({
    required this.anchorDate,
    required this.dueDate,
    required this.isVirtualAdvance,
  });

  final DateTime anchorDate;
  final DateTime dueDate;
  final bool isVirtualAdvance;
}

class ItemStatusService {
  const ItemStatusService();

  ItemStatus classify(Item item, {DateTime? now}) {
    final current = _normalizeDate(now ?? DateTime.now());
    return switch (item.config) {
      FixedItemConfig config => _classifyFixed(
        item.lastDoneAt,
        config,
        now: current,
      ),
      StateBasedItemConfig config => _classifyStateBased(
        config.anchorDate,
        config,
        now: current,
      ),
      ResourceBasedItemConfig config => _classifyResourceBased(
        config,
        now: current,
      ),
      _ => ItemStatus.unknown,
    };
  }

  Duration? elapsedSinceLastDone(Item item, {DateTime? now}) {
    final baseline = switch (item.config) {
      StateBasedItemConfig config => config.anchorDate,
      _ => item.lastDoneAt,
    };
    if (baseline == null) {
      return null;
    }
    final current = _normalizeDate(now ?? DateTime.now());
    final normalizedBaseline = _normalizeDate(baseline);
    if (item.config is StateBasedItemConfig) {
      return Duration(days: _stateDayIndex(normalizedBaseline, current));
    }
    return current.difference(normalizedBaseline);
  }

  FixedCycleWindow? currentFixedCycle(Item item, {DateTime? now}) {
    final config = item.config;
    if (config is! FixedItemConfig) {
      return null;
    }
    return resolveFixedCycle(config, now: now);
  }

  FixedCycleWindow? resolveFixedCycle(FixedItemConfig config, {DateTime? now}) {
    final anchorDate = config.anchorDate == null
        ? null
        : _normalizeDate(config.anchorDate!);
    final dueDate = config.dueDate == null
        ? null
        : _normalizeDate(config.dueDate!);
    if (anchorDate == null || dueDate == null) {
      return null;
    }
    final current = _normalizeDate(now ?? DateTime.now());
    if (config.overduePolicy != ItemOverduePolicy.autoAdvance ||
        !current.isAfter(dueDate)) {
      return FixedCycleWindow(
        anchorDate: anchorDate,
        dueDate: dueDate,
        isVirtualAdvance: false,
      );
    }

    if (config.scheduleType == FixedScheduleType.oneTime) {
      return FixedCycleWindow(
        anchorDate: anchorDate,
        dueDate: dueDate,
        isVirtualAdvance: false,
      );
    }

    final cycleLength = dueDate.difference(anchorDate).inDays;
    var resolvedAnchor = anchorDate;
    var resolvedDue = dueDate;
    var advanced = false;
    while (current.isAfter(resolvedDue)) {
      resolvedAnchor = _advanceDate(resolvedAnchor, config.scheduleType);
      resolvedDue = _advanceDate(
        resolvedDue,
        config.scheduleType,
        fallbackDays: cycleLength,
      );
      advanced = true;
    }
    return FixedCycleWindow(
      anchorDate: resolvedAnchor,
      dueDate: resolvedDue,
      isVirtualAdvance: advanced,
    );
  }

  ItemStatus _classifyStateBased(
    DateTime? lastDoneAt,
    StateBasedItemConfig config, {
    required DateTime now,
  }) {
    if (lastDoneAt == null) {
      return ItemStatus.unknown;
    }
    final normalizedBaseline = _normalizeDate(lastDoneAt);
    final dayIndex = _stateDayIndex(normalizedBaseline, now);
    final warningDay = _maxStateBoundary(config.warningAfter);
    final dangerDay = _maxStateBoundary(config.dangerAfter);

    if (dayIndex >= dangerDay) {
      return ItemStatus.danger;
    }
    if (dayIndex >= warningDay) {
      return ItemStatus.warning;
    }
    return ItemStatus.normal;
  }

  ItemStatus _classifyResourceBased(
    ResourceBasedItemConfig config, {
    required DateTime now,
  }) {
    final remainingDays = resourceRemainingDays(config, now: now);
    if (remainingDays == null) {
      return ItemStatus.unknown;
    }
    if (remainingDays <= config.dangerBefore) {
      return ItemStatus.danger;
    }
    if (remainingDays <= config.warningBefore) {
      return ItemStatus.warning;
    }
    return ItemStatus.normal;
  }

  DateTime? stateBaseline(Item item) {
    final config = item.config;
    if (config is! StateBasedItemConfig) {
      return item.lastDoneAt;
    }
    return config.anchorDate == null
        ? null
        : _normalizeDate(config.anchorDate!);
  }

  int? resourceRemainingDays(ResourceBasedItemConfig config, {DateTime? now}) {
    final anchorDate = config.anchorDate == null
        ? null
        : _normalizeDate(config.anchorDate!);
    if (anchorDate == null || config.durationDays <= 0) {
      return null;
    }
    final current = _normalizeDate(now ?? DateTime.now());
    final elapsedDays = current.difference(anchorDate).inDays;
    return config.durationDays - elapsedDays - 1;
  }

  ItemStatus _classifyFixed(
    DateTime? lastDoneAt,
    FixedItemConfig config, {
    required DateTime now,
  }) {
    final cycle = resolveFixedCycle(config, now: now);
    if (cycle == null) {
      return ItemStatus.unknown;
    }
    final completedAt = lastDoneAt == null ? null : _normalizeDate(lastDoneAt);
    if (now.isBefore(cycle.anchorDate)) {
      return ItemStatus.normal;
    }
    if (_isCompletedWithinCycle(completedAt, cycle)) {
      return ItemStatus.normal;
    }
    if (now.isAfter(cycle.dueDate) &&
        config.overduePolicy == ItemOverduePolicy.waitForAction) {
      return ItemStatus.danger;
    }

    final remainingDays = cycle.dueDate.difference(now).inDays;
    if (remainingDays <= config.dangerBefore.inDays) {
      return ItemStatus.danger;
    }
    if (remainingDays <= config.warningBefore.inDays) {
      return ItemStatus.warning;
    }
    return ItemStatus.normal;
  }

  DateTime nextFixedCycleAnchor(
    FixedCycleWindow cycle,
    FixedItemConfig config,
  ) {
    return _advanceDate(cycle.anchorDate, config.scheduleType);
  }

  DateTime nextFixedCycleDue(FixedCycleWindow cycle, FixedItemConfig config) {
    final fallbackDays = cycle.dueDate.difference(cycle.anchorDate).inDays;
    return _advanceDate(
      cycle.dueDate,
      config.scheduleType,
      fallbackDays: fallbackDays,
    );
  }

  DateTime shiftDateByDelay(DateTime value, int delayDays) {
    return _normalizeDate(value.add(Duration(days: delayDays)));
  }

  bool _isCompletedWithinCycle(DateTime? completedAt, FixedCycleWindow cycle) {
    if (completedAt == null) {
      return false;
    }
    return !completedAt.isBefore(cycle.anchorDate) &&
        !completedAt.isAfter(cycle.dueDate);
  }

  DateTime _advanceDate(
    DateTime value,
    FixedScheduleType scheduleType, {
    int? fallbackDays,
  }) {
    return switch (scheduleType) {
      FixedScheduleType.daily => value.add(const Duration(days: 1)),
      FixedScheduleType.weekly => value.add(const Duration(days: 7)),
      FixedScheduleType.oneTime => value.add(
        Duration(days: (fallbackDays ?? 0) + 1),
      ),
    };
  }

  DateTime _normalizeDate(DateTime value) {
    return DateTime(value.year, value.month, value.day);
  }

  int stateDayIndex(Item item, {DateTime? now}) {
    final baseline = stateBaseline(item);
    if (baseline == null) {
      return 0;
    }
    return _stateDayIndex(
      _normalizeDate(baseline),
      _normalizeDate(now ?? DateTime.now()),
    );
  }

  int _stateDayIndex(DateTime baseline, DateTime now) {
    return now.difference(baseline).inDays + 1;
  }

  int _maxStateBoundary(Duration value) {
    return value.inDays <= 0 ? 1 : value.inDays;
  }
}
