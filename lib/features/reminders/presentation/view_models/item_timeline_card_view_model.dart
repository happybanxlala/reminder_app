import '../../data/home_models.dart';
import '../../domain/item.dart';
import '../../domain/item_status_service.dart';
import '../../domain/timeline_milestone_occurrence.dart';
import '../formatters/reminder_formatters.dart';

enum ItemCardDisplayState {
  notStarted,
  normal,
  warning,
  danger,
  overdue,
  unknown,
}

class ItemCardViewModel {
  const ItemCardViewModel({
    required this.id,
    required this.title,
    required this.packTitle,
    required this.badgeLabel,
    required this.displayState,
    required this.canComplete,
    required this.canSkip,
    this.trailingLabel,
    this.note,
    this.anchorDateLabel,
    this.dueDateLabel,
    this.overduePolicyLabel,
    this.isExpanded = false,
  });

  factory ItemCardViewModel.fromEntry(
    ItemHomeEntry entry, {
    DateTime? now,
    ItemStatusService statusService = const ItemStatusService(),
  }) {
    final item = entry.bundle.item;
    final current = _normalizeDate(now ?? DateTime.now());
    final anchorDate = _effectiveAnchorDate(
      item,
      now: current,
      statusService: statusService,
    );
    final dueDate = _effectiveDueDate(
      item,
      now: current,
      statusService: statusService,
    );
    final displayState = _displayStateFor(
      entry,
      now: current,
      anchorDate: anchorDate,
      dueDate: dueDate,
    );

    return ItemCardViewModel(
      id: item.id,
      title: item.title,
      packTitle: entry.bundle.pack.title,
      note: item.description?.trim().isEmpty ?? true
          ? null
          : item.description!.trim(),
      badgeLabel: ReminderFormatters.itemCardBadge(item.config),
      trailingLabel: _trailingLabelFor(
        item,
        now: current,
        statusService: statusService,
      ),
      anchorDateLabel: anchorDate == null
          ? null
          : ReminderFormatters.date(anchorDate),
      dueDateLabel: dueDate == null ? null : ReminderFormatters.date(dueDate),
      overduePolicyLabel: switch (item.config) {
        FixedItemConfig config => ReminderFormatters.itemOverduePolicy(
          config.overduePolicy,
        ),
        _ => null,
      },
      displayState: displayState,
      canComplete: displayState != ItemCardDisplayState.notStarted,
      canSkip: item.type != ItemType.resourceBased,
    );
  }

  final int id;
  final String title;
  final String packTitle;
  final String? trailingLabel;
  final String? note;
  final String badgeLabel;
  final String? anchorDateLabel;
  final String? dueDateLabel;
  final String? overduePolicyLabel;
  final ItemCardDisplayState displayState;
  final bool isExpanded;
  final bool canComplete;
  final bool canSkip;

  ItemCardViewModel copyWith({bool? isExpanded}) {
    return ItemCardViewModel(
      id: id,
      title: title,
      packTitle: packTitle,
      trailingLabel: trailingLabel,
      note: note,
      badgeLabel: badgeLabel,
      anchorDateLabel: anchorDateLabel,
      dueDateLabel: dueDateLabel,
      overduePolicyLabel: overduePolicyLabel,
      displayState: displayState,
      isExpanded: isExpanded ?? this.isExpanded,
      canComplete: canComplete,
      canSkip: canSkip,
    );
  }

  static DateTime? _effectiveAnchorDate(
    Item item, {
    required DateTime now,
    required ItemStatusService statusService,
  }) {
    return switch (item.config) {
      FixedItemConfig config =>
        statusService.resolveFixedCycle(config, now: now)?.anchorDate ??
            _normalizeNullableDate(config.anchorDate),
      StateBasedItemConfig config => _normalizeNullableDate(config.anchorDate),
      ResourceBasedItemConfig config => _normalizeNullableDate(
        config.anchorDate,
      ),
      _ => null,
    };
  }

  static DateTime? _effectiveDueDate(
    Item item, {
    required DateTime now,
    required ItemStatusService statusService,
  }) {
    return switch (item.config) {
      FixedItemConfig config =>
        statusService.resolveFixedCycle(config, now: now)?.dueDate ??
            _normalizeNullableDate(config.dueDate),
      _ => null,
    };
  }

  static ItemCardDisplayState _displayStateFor(
    ItemHomeEntry entry, {
    required DateTime now,
    required DateTime? anchorDate,
    required DateTime? dueDate,
  }) {
    if (anchorDate != null && now.isBefore(anchorDate)) {
      return ItemCardDisplayState.notStarted;
    }

    final item = entry.bundle.item;
    final config = item.config;
    if (config is FixedItemConfig &&
        config.overduePolicy == ItemOverduePolicy.waitForAction &&
        dueDate != null &&
        now.isAfter(dueDate) &&
        !_completedWithinWindow(item.lastDoneAt, anchorDate, dueDate)) {
      return ItemCardDisplayState.overdue;
    }

    return switch (entry.status) {
      ItemStatus.normal => ItemCardDisplayState.normal,
      ItemStatus.warning => ItemCardDisplayState.warning,
      ItemStatus.danger => ItemCardDisplayState.danger,
      ItemStatus.unknown => ItemCardDisplayState.unknown,
    };
  }

  static String? _trailingLabelFor(
    Item item, {
    required DateTime now,
    required ItemStatusService statusService,
  }) {
    final config = item.config;
    if (config is FixedItemConfig) {
      final dueDate =
          statusService.resolveFixedCycle(config, now: now)?.dueDate ??
          _normalizeNullableDate(config.dueDate);
      if (dueDate == null) {
        return null;
      }
      final remainingDays = dueDate.difference(now).inDays;
      if (remainingDays > 0) {
        return '剩餘$remainingDays日';
      }
      if (remainingDays == 0) {
        return '今天到期';
      }
      return '過期';
    }
    if (config is StateBasedItemConfig) {
      final dayIndex = statusService.stateDayIndex(item, now: now);
      if (dayIndex <= 0) {
        return null;
      }
      return '已持續$dayIndex日';
    }
    if (config is! ResourceBasedItemConfig) {
      return null;
    }
    final remainingDays = statusService.resourceRemainingDays(config, now: now);
    if (remainingDays == null) {
      return null;
    }
    final safeRemainingDays = remainingDays < 0 ? 0 : remainingDays;
    return '剩餘$safeRemainingDays日';
  }

  static bool _completedWithinWindow(
    DateTime? completedAt,
    DateTime? anchorDate,
    DateTime dueDate,
  ) {
    if (completedAt == null || anchorDate == null) {
      return false;
    }
    final completed = _normalizeDate(completedAt);
    return !completed.isBefore(anchorDate) && !completed.isAfter(dueDate);
  }

  static DateTime _normalizeDate(DateTime value) {
    return DateTime(value.year, value.month, value.day);
  }

  static DateTime? _normalizeNullableDate(DateTime? value) {
    if (value == null) {
      return null;
    }
    return _normalizeDate(value);
  }
}

class MilestoneCardViewModel {
  const MilestoneCardViewModel({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.status,
  });

  factory MilestoneCardViewModel.fromOccurrence(
    TimelineMilestoneOccurrence occurrence,
  ) {
    return MilestoneCardViewModel(
      id:
          occurrence.recordId ??
          Object.hash(
            occurrence.timelineId,
            occurrence.ruleId,
            occurrence.occurrenceIndex,
          ),
      title: occurrence.timelineTitle,
      subtitle: ReminderFormatters.milestoneSummary(occurrence),
      status: occurrence.status.name,
    );
  }

  final int id;
  final String title;
  final String subtitle;
  final String status;
}
