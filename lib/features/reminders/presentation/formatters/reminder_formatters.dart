import 'package:intl/intl.dart';

import '../../data/home_models.dart';
import '../../data/local/item_timeline_dao.dart';
import '../../domain/item_action_record.dart';
import '../../domain/item.dart';
import '../../domain/item_pack.dart';
import '../../domain/timeline.dart';
import '../../domain/timeline_milestone_occurrence.dart';
import '../../domain/timeline_milestone_record.dart';
import '../../domain/timeline_milestone_rule.dart';
import '../../domain/timeline_milestone_service.dart';
import '../../domain/item_status_service.dart';
import '../text/reminder_ui_text.dart';

class ReminderFormatters {
  const ReminderFormatters._();

  static String date(DateTime value) {
    return DateFormat('yyyy/MM/dd').format(value.toLocal());
  }

  static String dateTime(DateTime value) {
    return DateFormat('yyyy/MM/dd HH:mm').format(value.toLocal());
  }

  static String itemSummary(
    ItemBundle bundle, {
    DateTime? now,
    ItemStatusService statusService = const ItemStatusService(),
  }) {
    return switch (bundle.item.config) {
      FixedItemConfig config => _fixedSummary(
        config,
        now: now,
        statusService: statusService,
      ),
      StateBasedItemConfig config => _stateBasedSummary(config),
      ResourceBasedItemConfig config => _resourceBasedSummary(config),
      _ => bundle.item.type.name,
    };
  }

  static String itemHomeSummary(
    ItemHomeEntry entry, {
    DateTime? now,
    ItemStatusService statusService = const ItemStatusService(),
  }) {
    return '${entry.bundle.pack.title} • ${itemStatus(entry.status)} • ${itemSummary(entry.bundle, now: now, statusService: statusService)}';
  }

  static String itemActionRecord(ItemActionRecord record) {
    final payload = record.payload;
    final payloadText = switch (record.actionType) {
      ItemActionType.done when payload?['addedDays'] != null =>
        ' • 補充 ${(payload?['addedDays'] as num).toInt()} 天',
      ItemActionType.deferred when payload?['deferDays'] != null =>
        ' • 延後 ${(payload?['deferDays'] as num).toInt()} 天',
      _ => '',
    };
    final remarkText = record.remark == null || record.remark!.isEmpty
        ? ''
        : ' • ${record.remark}';
    return '${itemActionType(record.actionType)} • ${date(record.actionDate)}$payloadText$remarkText';
  }

  static String milestoneSummary(TimelineMilestoneOccurrence occurrence) {
    return '${occurrence.label} • ${date(occurrence.targetDate)}';
  }

  static String milestoneHistory(
    TimelineMilestoneRecordBundle bundle, {
    TimelineMilestoneService service = const TimelineMilestoneService(),
  }) {
    final label = service.formatLabel(
      bundle.rule,
      bundle.record.occurrenceIndex,
    );
    return '${milestoneStatus(bundle.record.status)} • $label • ${date(bundle.record.targetDate)}';
  }

  static String milestoneHistoryUpdatedAt(
    TimelineMilestoneRecordBundle bundle,
  ) {
    return '${ReminderUiText.updatedAtLabel}：${dateTime(bundle.record.updatedAt)}';
  }

  static String timelineMilestoneRuleSummary(TimelineMilestoneRule rule) {
    final unit = switch (rule.intervalUnit) {
      TimelineMilestoneIntervalUnit.days => '天',
      TimelineMilestoneIntervalUnit.weeks => '週',
      TimelineMilestoneIntervalUnit.months => '個月',
      TimelineMilestoneIntervalUnit.years => '年',
    };
    return '每 ${rule.intervalValue} $unit';
  }

  static String timelineMilestoneRuleStatus(
    TimelineMilestoneRuleStatus status,
  ) {
    return switch (status) {
      TimelineMilestoneRuleStatus.active => '啟用中',
      TimelineMilestoneRuleStatus.paused => '已暫停',
      TimelineMilestoneRuleStatus.archived => '已封存',
    };
  }

  static String timelineSummary(Timeline timeline) {
    return '${date(timeline.startDate)} • ${displayUnitLabel(timeline.displayUnit)}';
  }

  static String timelineStatus(TimelineStatus status) {
    return switch (status) {
      TimelineStatus.active => '啟用中',
      TimelineStatus.archived => '已封存',
    };
  }

  static String displayUnitLabel(TimelineDisplayUnit value) {
    return switch (value) {
      TimelineDisplayUnit.day => '天',
      TimelineDisplayUnit.week => '週',
      TimelineDisplayUnit.month => '月',
      TimelineDisplayUnit.year => '年',
    };
  }

  static String milestoneStatus(TimelineMilestoneRecordStatus value) {
    return switch (value) {
      TimelineMilestoneRecordStatus.upcoming => '即將到來',
      TimelineMilestoneRecordStatus.noticed => '已看過',
      TimelineMilestoneRecordStatus.skipped => '已跳過',
    };
  }

  static String itemStatus(ItemStatus status) {
    return switch (status) {
      ItemStatus.normal => '穩定',
      ItemStatus.warning => ReminderUiText.warningTab,
      ItemStatus.danger => ReminderUiText.dangerTab,
      ItemStatus.unknown => '未建立基準',
    };
  }

  static String itemLifecycleStatus(ItemLifecycleStatus status) {
    return switch (status) {
      ItemLifecycleStatus.active => '啟用中',
      ItemLifecycleStatus.paused => '已暫停',
      ItemLifecycleStatus.archived => '已封存',
    };
  }

  static String itemPackStatus(ItemPackStatus status) {
    return switch (status) {
      ItemPackStatus.active => '啟用中',
      ItemPackStatus.archived => '已封存',
    };
  }

  static String itemActionType(ItemActionType actionType) {
    return switch (actionType) {
      ItemActionType.done => '完成',
      ItemActionType.skipped => '跳過',
      ItemActionType.deferred => '延期',
    };
  }

  static String elapsedLabel(Duration value) {
    if (value.inDays >= 1) {
      return '${value.inDays} 天未完成';
    }
    if (value.inHours >= 1) {
      return '${value.inHours} 小時未完成';
    }
    return '${value.inMinutes} 分鐘未完成';
  }

  static String _fixedSummary(
    FixedItemConfig config, {
    DateTime? now,
    required ItemStatusService statusService,
  }) {
    final scheduleLabel = fixedScheduleTypeLabel(config.scheduleType);
    final resolvedCycle = statusService.resolveFixedCycle(config, now: now);
    final anchorLabel = resolvedCycle == null
        ? (config.anchorDate == null ? null : date(config.anchorDate!))
        : date(resolvedCycle.anchorDate);
    final dueLabel = resolvedCycle == null
        ? (config.dueDate == null ? null : date(config.dueDate!))
        : date(resolvedCycle.dueDate);
    final overdueLabel = itemOverduePolicy(config.overduePolicy);
    final parts = <String>[scheduleLabel];
    if (anchorLabel != null) {
      parts.add('起點 $anchorLabel');
    }
    if (dueLabel != null) {
      parts.add('到期 $dueLabel');
    }
    if (config.timeOfDay != null && config.timeOfDay!.isNotEmpty) {
      parts.add(config.timeOfDay!);
    }
    if (resolvedCycle?.isVirtualAdvance ?? false) {
      parts.add('目前顯示下一輪');
    }
    parts.add(overdueLabel);
    return parts.join(' • ');
  }

  static String _stateBasedSummary(StateBasedItemConfig config) {
    final parts = <String>[];
    if (config.anchorDate != null) {
      parts.add('起點 ${date(config.anchorDate!)}');
    }
    parts.add('留意 ${config.warningAfter.inDays} 天');
    parts.add('變糟 ${config.dangerAfter.inDays} 天');
    return parts.join(' • ');
  }

  static String _resourceBasedSummary(ResourceBasedItemConfig config) {
    final anchor = config.anchorDate == null ? '未建立' : date(config.anchorDate!);
    return '起點 $anchor • 可維持 ${config.durationDays} 天（含起點） • 留意前 ${config.warningBefore} 天';
  }

  static String fixedScheduleTypeLabel(FixedScheduleType value) {
    return switch (value) {
      FixedScheduleType.daily => '每天',
      FixedScheduleType.weekly => '每週',
      FixedScheduleType.oneTime => '一次',
    };
  }

  static String itemCardBadge(ItemConfig config) {
    return switch (config) {
      FixedItemConfig _ => ReminderUiText.fixedTypeLabel,
      StateBasedItemConfig _ => ReminderUiText.stateBasedTypeLabel,
      ResourceBasedItemConfig _ => ReminderUiText.resourceBasedTypeLabel,
      _ => '未知',
    };
  }

  static String itemOverduePolicy(ItemOverduePolicy value) {
    return switch (value) {
      ItemOverduePolicy.autoAdvance => '逾期自動進下一輪',
      ItemOverduePolicy.waitForAction => '逾期等待處理',
    };
  }

  static String itemType(ItemType value) {
    return switch (value) {
      ItemType.fixed => ReminderUiText.fixedTypeLabel,
      ItemType.stateBased => ReminderUiText.stateBasedTypeLabel,
      ItemType.resourceBased => ReminderUiText.resourceBasedTypeLabel,
    };
  }

  static String timelineMilestoneRuleType(TimelineMilestoneRuleType value) {
    return switch (value) {
      TimelineMilestoneRuleType.everyNDays => '每 N 天',
      TimelineMilestoneRuleType.everyNWeeks => '每 N 週',
      TimelineMilestoneRuleType.everyNMonths => '每 N 個月',
      TimelineMilestoneRuleType.everyNYears => '每 N 年',
    };
  }
}
