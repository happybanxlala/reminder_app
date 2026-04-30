import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../data/local/item_timeline_dao.dart';
import '../../domain/item.dart';
import '../../domain/item_status_service.dart';
import '../formatters/reminder_formatters.dart';
import '../text/reminder_ui_text.dart';

class ManagementItemStatusPresentation {
  const ManagementItemStatusPresentation({
    required this.label,
    required this.color,
    required this.isNotStarted,
    required this.isUnknown,
    required this.isActionable,
    required this.isWarningOrDanger,
  });

  final String label;
  final Color color;
  final bool isNotStarted;
  final bool isUnknown;
  final bool isActionable;
  final bool isWarningOrDanger;
}

class ManagementItemCardViewModel {
  const ManagementItemCardViewModel({
    required this.id,
    required this.title,
    required this.type,
    required this.typeLabel,
    required this.typeIcon,
    required this.packTitle,
    required this.status,
    required this.lifecycle,
    required this.lifecycleLabel,
    required this.updatedAtLabel,
    required this.anchorDateLabel,
    required this.dueDateLabel,
    required this.overduePolicyLabel,
    required this.stateBaselineLabel,
    required this.remainingInventoryLabel,
    required this.availableDaysLabel,
    required this.canComplete,
    required this.canSkip,
    required this.canPause,
    required this.canResume,
    required this.canArchive,
    required this.requireCompletionConfirmation,
  });

  factory ManagementItemCardViewModel.fromBundle(
    ItemBundle bundle, {
    DateTime? now,
    ItemStatusService statusService = const ItemStatusService(),
  }) {
    final item = bundle.item;
    final current = _normalizeDate(now ?? DateTime.now());
    final status = _statusFor(item, now: current, statusService: statusService);
    final lifecycle = item.status;
    final active = lifecycle == ItemLifecycleStatus.active;
    final isResource = item.type == ItemType.resourceBased;

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
    final stateBaseline = _stateBaseline(item);
    final remainingInventory = _remainingInventory(item, now: current);

    return ManagementItemCardViewModel(
      id: item.id,
      title: item.title,
      type: item.type,
      typeLabel: ReminderFormatters.itemType(item.type),
      typeIcon: _typeIcon(item.type),
      packTitle: bundle.pack.isSystemDefault
          ? ReminderUiText.unassignedPackTitle
          : bundle.pack.title,
      status: status,
      lifecycle: lifecycle,
      lifecycleLabel: ReminderFormatters.itemLifecycleStatus(lifecycle),
      updatedAtLabel: ReminderFormatters.date(item.updatedAt),
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
      stateBaselineLabel: stateBaseline == null
          ? null
          : ReminderFormatters.date(stateBaseline),
      remainingInventoryLabel: remainingInventory == null
          ? null
          : '$remainingInventory ${ReminderUiText.inventoryDaysUnit}',
      availableDaysLabel: switch (item.config) {
        ResourceBasedItemConfig config =>
          '${config.durationDays} ${ReminderUiText.inventoryDaysUnit}',
        _ => null,
      },
      canComplete: active && status.isActionable,
      canSkip: active && status.isActionable && !isResource,
      canPause: active,
      canResume: lifecycle == ItemLifecycleStatus.paused,
      canArchive: lifecycle != ItemLifecycleStatus.archived,
      requireCompletionConfirmation:
          item.type == ItemType.stateBased && !status.isWarningOrDanger,
    );
  }

  final int id;
  final String title;
  final ItemType type;
  final String typeLabel;
  final IconData typeIcon;
  final String packTitle;
  final ManagementItemStatusPresentation status;
  final ItemLifecycleStatus lifecycle;
  final String lifecycleLabel;
  final String updatedAtLabel;
  final String? anchorDateLabel;
  final String? dueDateLabel;
  final String? overduePolicyLabel;
  final String? stateBaselineLabel;
  final String? remainingInventoryLabel;
  final String? availableDaysLabel;
  final bool canComplete;
  final bool canSkip;
  final bool canPause;
  final bool canResume;
  final bool canArchive;
  final bool requireCompletionConfirmation;

  bool get isPaused => lifecycle == ItemLifecycleStatus.paused;

  static ManagementItemStatusPresentation _statusFor(
    Item item, {
    required DateTime now,
    required ItemStatusService statusService,
  }) {
    if (item.status == ItemLifecycleStatus.paused) {
      return const ManagementItemStatusPresentation(
        label: ReminderUiText.lifecyclePausedLabel,
        color: Colors.grey,
        isNotStarted: false,
        isUnknown: false,
        isActionable: false,
        isWarningOrDanger: false,
      );
    }

    final anchorDate = _effectiveAnchorDate(
      item,
      now: now,
      statusService: statusService,
    );
    if (anchorDate != null && now.isBefore(anchorDate)) {
      return const ManagementItemStatusPresentation(
        label: ReminderUiText.itemStatusNotStarted,
        color: Colors.grey,
        isNotStarted: true,
        isUnknown: false,
        isActionable: false,
        isWarningOrDanger: false,
      );
    }

    final baseStatus = statusService.classify(item, now: now);
    if (baseStatus == ItemStatus.unknown) {
      return const ManagementItemStatusPresentation(
        label: ReminderUiText.itemStatusUnknownBaseline,
        color: Colors.grey,
        isNotStarted: false,
        isUnknown: true,
        isActionable: true,
        isWarningOrDanger: false,
      );
    }

    return switch (item.config) {
      FixedItemConfig config => _fixedStatus(
        item,
        config,
        status: baseStatus,
        now: now,
        statusService: statusService,
      ),
      StateBasedItemConfig _ => _stateStatus(
        item,
        status: baseStatus,
        now: now,
        statusService: statusService,
      ),
      ResourceBasedItemConfig config => _resourceStatus(
        config,
        status: baseStatus,
        now: now,
        statusService: statusService,
      ),
      _ => const ManagementItemStatusPresentation(
        label: ReminderUiText.itemStatusUnknownBaseline,
        color: Colors.grey,
        isNotStarted: false,
        isUnknown: true,
        isActionable: true,
        isWarningOrDanger: false,
      ),
    };
  }

  static ManagementItemStatusPresentation _fixedStatus(
    Item item,
    FixedItemConfig config, {
    required ItemStatus status,
    required DateTime now,
    required ItemStatusService statusService,
  }) {
    final cycle = statusService.resolveFixedCycle(config, now: now);
    final dueDate = cycle?.dueDate ?? _normalizeNullableDate(config.dueDate);
    if (dueDate == null) {
      return const ManagementItemStatusPresentation(
        label: ReminderUiText.itemStatusUnknownBaseline,
        color: Colors.grey,
        isNotStarted: false,
        isUnknown: true,
        isActionable: true,
        isWarningOrDanger: false,
      );
    }

    if (config.overduePolicy == ItemOverduePolicy.waitForAction &&
        now.isAfter(dueDate) &&
        !_completedWithinWindow(item.lastDoneAt, cycle?.anchorDate, dueDate)) {
      final overdueDays = now.difference(dueDate).inDays;
      return ManagementItemStatusPresentation(
        label:
            '${ReminderUiText.dangerTab}：${ReminderUiText.fixedOverduePrefix}$overdueDays${ReminderUiText.dayUnit}',
        color: Colors.red,
        isNotStarted: false,
        isUnknown: false,
        isActionable: true,
        isWarningOrDanger: true,
      );
    }

    final remainingDays = dueDate.difference(now).inDays;
    return switch (status) {
      ItemStatus.warning => ManagementItemStatusPresentation(
        label:
            '${ReminderUiText.warningTab}：${ReminderUiText.fixedWarningPrefix}$remainingDays${ReminderUiText.dayUnit}',
        color: Colors.orange,
        isNotStarted: false,
        isUnknown: false,
        isActionable: true,
        isWarningOrDanger: true,
      ),
      ItemStatus.danger => ManagementItemStatusPresentation(
        label:
            '${ReminderUiText.dangerTab}：${ReminderUiText.fixedDangerPrefix}$remainingDays${ReminderUiText.dayUnit}',
        color: Colors.red,
        isNotStarted: false,
        isUnknown: false,
        isActionable: true,
        isWarningOrDanger: true,
      ),
      _ => ManagementItemStatusPresentation(
        label:
            '${ReminderUiText.fixedNextDuePrefix}${ReminderFormatters.date(dueDate)}',
        color: Colors.black87,
        isNotStarted: false,
        isUnknown: false,
        isActionable: true,
        isWarningOrDanger: false,
      ),
    };
  }

  static ManagementItemStatusPresentation _stateStatus(
    Item item, {
    required ItemStatus status,
    required DateTime now,
    required ItemStatusService statusService,
  }) {
    final elapsedDays = statusService.stateDayIndex(item, now: now);
    return switch (status) {
      ItemStatus.warning => ManagementItemStatusPresentation(
        label:
            '${ReminderUiText.warningTab}：${ReminderUiText.stateWarningPrefix}$elapsedDays${ReminderUiText.dayWithParticleSuffix}',
        color: Colors.orange,
        isNotStarted: false,
        isUnknown: false,
        isActionable: true,
        isWarningOrDanger: true,
      ),
      ItemStatus.danger => ManagementItemStatusPresentation(
        label:
            '${ReminderUiText.dangerTab}：${ReminderUiText.stateDangerPrefix}$elapsedDays${ReminderUiText.dayWithParticleSuffix}',
        color: Colors.red,
        isNotStarted: false,
        isUnknown: false,
        isActionable: true,
        isWarningOrDanger: true,
      ),
      _ => ManagementItemStatusPresentation(
        label:
            '${ReminderUiText.stateNormalPrefix}$elapsedDays${ReminderUiText.daysAgoSuffix}',
        color: Colors.black87,
        isNotStarted: false,
        isUnknown: false,
        isActionable: true,
        isWarningOrDanger: false,
      ),
    };
  }

  static ManagementItemStatusPresentation _resourceStatus(
    ResourceBasedItemConfig config, {
    required ItemStatus status,
    required DateTime now,
    required ItemStatusService statusService,
  }) {
    final remainingDays = math.max(
      statusService.resourceRemainingDays(config, now: now) ?? 0,
      0,
    );
    return switch (status) {
      ItemStatus.warning => ManagementItemStatusPresentation(
        label:
            '${ReminderUiText.warningTab}：${ReminderUiText.resourceWarningPrefix}$remainingDays${ReminderUiText.dayWithParticleSuffix}',
        color: Colors.orange,
        isNotStarted: false,
        isUnknown: false,
        isActionable: true,
        isWarningOrDanger: true,
      ),
      ItemStatus.danger => ManagementItemStatusPresentation(
        label:
            '${ReminderUiText.dangerTab}：${ReminderUiText.resourceDangerPrefix}$remainingDays${ReminderUiText.inventoryDaysUnit}',
        color: Colors.red,
        isNotStarted: false,
        isUnknown: false,
        isActionable: true,
        isWarningOrDanger: true,
      ),
      _ => ManagementItemStatusPresentation(
        label:
            '${ReminderUiText.resourceNormalPrefix}$remainingDays${ReminderUiText.inventoryDaysUnit}',
        color: Colors.black87,
        isNotStarted: false,
        isUnknown: false,
        isActionable: true,
        isWarningOrDanger: false,
      ),
    };
  }

  static IconData _typeIcon(ItemType type) {
    return switch (type) {
      ItemType.fixed => Icons.schedule_outlined,
      ItemType.stateBased => Icons.gesture_outlined,
      ItemType.resourceBased => Icons.inventory_2_outlined,
    };
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

  static DateTime? _stateBaseline(Item item) {
    return switch (item.config) {
      StateBasedItemConfig config => _normalizeNullableDate(config.anchorDate),
      _ => null,
    };
  }

  static int? _remainingInventory(Item item, {required DateTime now}) {
    final config = item.config;
    if (config is! ResourceBasedItemConfig) {
      return null;
    }
    final remaining = const ItemStatusService().resourceRemainingDays(
      config,
      now: now,
    );
    if (remaining == null) {
      return null;
    }
    return math.max(remaining, 0);
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
