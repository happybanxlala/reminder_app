import 'package:intl/intl.dart';

import '../../data/home_models.dart';
import '../../data/local/item_timeline_dao.dart';
import '../../domain/attention_policy.dart';
import '../../domain/item_action_record.dart';
import '../../domain/item.dart';
import '../../domain/item_pack.dart';
import '../../domain/repeat_rule.dart';
import '../../domain/repeat_rule_v2.dart';
import '../../domain/resource.dart';
import '../../domain/resource_status_service.dart';
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
      ItemActionType.deferred when payload?['deferDays'] != null =>
        ' • 延後 ${(payload?['deferDays'] as num).toInt()} 天',
      _ => '',
    };
    final remarkText = record.remark == null || record.remark!.isEmpty
        ? ''
        : ' • ${record.remark}';
    return '${itemActionType(record.actionType)} • ${date(record.actionDate)}$payloadText$remarkText';
  }

  static String resourceActionRecord(ResourceActionRecord record) {
    final amountText = record.amount == null ? '' : ' • 數量 ${record.amount}';
    final resultingQuantityText = record.resultingQuantity == null
        ? ''
        : ' • 結果 ${record.resultingQuantity}';
    final addedDaysText = record.addedDays == null
        ? ''
        : ' • 增加 ${record.addedDays} 天';
    final resultingDurationText = record.resultingDurationDays == null
        ? ''
        : ' • 約 ${record.resultingDurationDays} 天';
    final sourceText = record.sourceItemActionRecordId == null
        ? ''
        : ' • 來自完成紀錄 #${record.sourceItemActionRecordId}';
    final remarkText = record.remark == null || record.remark!.isEmpty
        ? ''
        : ' • ${record.remark}';
    return '${resourceActionType(record.actionType)} • ${date(record.actionDate)}$amountText$resultingQuantityText$addedDaysText$resultingDurationText$sourceText$remarkText';
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
      ItemActionType.created => '新增',
      ItemActionType.done => '完成',
      ItemActionType.skipped => '跳過',
      ItemActionType.deferred => '延期',
    };
  }

  static String resourceActionType(ResourceActionType actionType) {
    return switch (actionType) {
      ResourceActionType.created => '新增',
      ResourceActionType.consumed => '消耗',
      ResourceActionType.refilled => '補充',
      ResourceActionType.adjusted => '調整',
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
    final scheduleLabel = fixedScheduleSummary(config);
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
    parts.add(attentionPolicySummary(config));
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
    parts.add(attentionPolicySummary(config));
    return parts.join(' • ');
  }

  static String attentionPolicySummary(ItemConfig config) {
    return switch (config) {
      FixedItemConfig fixed => _fixedAttentionPolicySummary(fixed),
      StateBasedItemConfig state => _stateAttentionPolicySummary(state),
      _ => '',
    };
  }

  static String _fixedAttentionPolicySummary(FixedItemConfig config) {
    final warning = config.warningBefore.inDays;
    final danger = config.dangerBefore.inDays;
    return '${_beforeLabel(warning, fallback: '到期當天開始提醒')} • ${_beforeLabel(danger, fallback: '到期當天加強提醒', suffix: '加強提醒')}';
  }

  static String _stateAttentionPolicySummary(StateBasedItemConfig config) {
    final warning = config.warningAfter.inDays;
    final danger = config.dangerAfter.inDays;
    final warningLabel = warning <= 0 ? '當天開始提醒' : '約第 $warning 天開始提醒';
    return '$warningLabel • 第 $danger 天建議處理';
  }

  static String _beforeLabel(
    int days, {
    required String fallback,
    String suffix = '開始提醒',
  }) {
    if (days <= 0) {
      return fallback;
    }
    return '$days 天前$suffix';
  }

  static String fixedScheduleTypeLabel(FixedScheduleType value) {
    return switch (value) {
      FixedScheduleType.daily => '每天',
      FixedScheduleType.weekly => '每週',
      FixedScheduleType.oneTime => '一次',
      FixedScheduleType.everyXDays => '每 X 天',
      FixedScheduleType.everyXWeeks => '每 X 週',
      FixedScheduleType.monthly => '每月',
    };
  }

  static String formatRepeatRuleSummary(RepeatRule? rule) {
    if (rule == null) {
      return '永不';
    }
    final interval = rule.interval < 1 ? 1 : rule.interval;
    return switch (rule.unit) {
      RepeatUnit.day => interval == 1 ? '每天' : '每 $interval 天',
      RepeatUnit.week => interval == 1 ? '每週' : '每 $interval 週',
      RepeatUnit.month => interval == 1 ? '每月' : '每 $interval 個月',
      RepeatUnit.year => interval == 1 ? '每年' : '每 $interval 年',
    };
  }

  static String formatRepeatRuleDescription(RepeatRule? rule) {
    if (rule == null) {
      return '完成後不會再次出現。';
    }
    final interval = rule.interval < 1 ? 1 : rule.interval;
    return switch (rule.unit) {
      RepeatUnit.day => interval == 1 ? '完成後每天再次出現。' : '完成後 $interval 天再次出現。',
      RepeatUnit.week => interval == 1 ? '完成後每週再次出現。' : '完成後 $interval 週再次出現。',
      RepeatUnit.month =>
        interval == 1 ? '完成後每月再次出現。' : '完成後 $interval 個月再次出現。',
      RepeatUnit.year => interval == 1 ? '完成後每年再次出現。' : '完成後 $interval 年再次出現。',
    };
  }

  static String repeatRuleV2Summary(RepeatRuleV2? rule) {
    if (rule == null) {
      return '永不';
    }
    final base = switch (rule.kind) {
      RepeatRuleV2Kind.simple => formatRepeatRuleSummary(
        RepeatRule(unit: rule.unit, interval: rule.interval),
      ),
      RepeatRuleV2Kind.weeklyWeekdays => _weeklyWeekdaysSummary(rule),
      RepeatRuleV2Kind.monthlyDates => _monthlyDatesSummary(rule),
      RepeatRuleV2Kind.monthlyNthWeekday => _monthlyNthWeekdaySummary(rule),
    };
    return '$base${_repeatEndSummarySuffix(rule.end)}';
  }

  static String repeatRuleV2Description(RepeatRuleV2? rule) {
    if (rule == null) {
      return '完成後不會再次出現。';
    }
    if (rule.kind == RepeatRuleV2Kind.simple) {
      return formatRepeatRuleDescription(
        RepeatRule(unit: rule.unit, interval: rule.interval),
      );
    }
    final body = switch (rule.kind) {
      RepeatRuleV2Kind.simple => '',
      RepeatRuleV2Kind.weeklyWeekdays => _weeklyWeekdaysSummary(rule),
      RepeatRuleV2Kind.monthlyDates => _monthlyDatesSummary(rule),
      RepeatRuleV2Kind.monthlyNthWeekday => _monthlyNthWeekdaySummary(rule),
    };
    return '完成後，$body再次出現。';
  }

  static RepeatRule? repeatRuleFromFixedConfig(FixedItemConfig config) {
    final v2 = repeatRuleV2FromFixedConfig(config);
    return v2?.legacySimpleRule;
  }

  static RepeatRuleV2? repeatRuleV2FromFixedConfig(FixedItemConfig config) {
    if (config.repeatRuleV2 != null) {
      return config.repeatRuleV2;
    }
    final interval = config.scheduleInterval < 1 ? 1 : config.scheduleInterval;
    return switch (config.scheduleType) {
      FixedScheduleType.oneTime => null,
      FixedScheduleType.daily => RepeatRuleV2.simple(
        unit: RepeatUnit.day,
        interval: 1,
      ),
      FixedScheduleType.weekly => RepeatRuleV2.simple(
        unit: RepeatUnit.week,
        interval: 1,
      ),
      FixedScheduleType.everyXDays => RepeatRuleV2.simple(
        unit: RepeatUnit.day,
        interval: interval,
      ),
      FixedScheduleType.everyXWeeks => RepeatRuleV2.simple(
        unit: RepeatUnit.week,
        interval: interval,
      ),
      FixedScheduleType.monthly => RepeatRuleV2.simple(
        unit: RepeatUnit.month,
        interval: interval,
      ),
    };
  }

  static String fixedScheduleSummary(FixedItemConfig config) {
    if (config.repeatRuleV2 != null) {
      return repeatRuleV2Summary(config.repeatRuleV2);
    }
    final interval = config.scheduleInterval < 1 ? 1 : config.scheduleInterval;
    return switch (config.scheduleType) {
      FixedScheduleType.daily => '每天',
      FixedScheduleType.weekly => '每週',
      FixedScheduleType.oneTime => '一次',
      FixedScheduleType.everyXDays => '每 $interval 天',
      FixedScheduleType.everyXWeeks => '每 $interval 週',
      FixedScheduleType.monthly =>
        config.monthlyDay == null ? '每月' : '每月 ${config.monthlyDay} 日',
    };
  }

  static String _weeklyWeekdaysSummary(RepeatRuleV2 rule) {
    if (rule.interval == 1) {
      final weekdayText = rule.weekdays.map(_weekdayShortName).join('、');
      return '每週$weekdayText';
    }
    final weekdayText = _joinChineseList(
      rule.weekdays.map(_weekdayName).toList(growable: false),
    );
    return '每 ${rule.interval} 週的$weekdayText';
  }

  static String _monthlyDatesSummary(RepeatRuleV2 rule) {
    final dateValues = rule.monthDays
        .map((day) => '$day 日')
        .toList(growable: false);
    final dateText = dateValues.length <= 1
        ? dateValues.single
        : '${dateValues.take(dateValues.length - 1).join('、')}和 ${dateValues.last}';
    return rule.interval == 1
        ? '每月 $dateText'
        : '每 ${rule.interval} 個月的 $dateText';
  }

  static String _monthlyNthWeekdaySummary(RepeatRuleV2 rule) {
    final ordinal = switch (rule.monthlyWeekOrdinal!) {
      MonthlyWeekOrdinal.first => '第一個',
      MonthlyWeekOrdinal.second => '第二個',
      MonthlyWeekOrdinal.third => '第三個',
      MonthlyWeekOrdinal.fourth => '第四個',
      MonthlyWeekOrdinal.fifth => '第五個',
      MonthlyWeekOrdinal.last => '最後一個',
    };
    final weekday = _weekdayName(rule.monthlyWeekday!);
    return rule.interval == 1
        ? '每月$ordinal$weekday'
        : '每 ${rule.interval} 個月的$ordinal$weekday';
  }

  static String _repeatEndSummarySuffix(RepeatEndCondition end) {
    return switch (end.type) {
      RepeatEndType.never => '',
      RepeatEndType.onDate => '，直到 ${date(end.untilDate!)}',
      RepeatEndType.afterCount => '，共 ${end.occurrenceCount} 次',
    };
  }

  static String _weekdayName(int weekday) {
    return switch (weekday) {
      DateTime.monday => '星期一',
      DateTime.tuesday => '星期二',
      DateTime.wednesday => '星期三',
      DateTime.thursday => '星期四',
      DateTime.friday => '星期五',
      DateTime.saturday => '星期六',
      DateTime.sunday => '星期日',
      _ => '星期一',
    };
  }

  static String _weekdayShortName(int weekday) {
    return switch (weekday) {
      DateTime.monday => '一',
      DateTime.tuesday => '二',
      DateTime.wednesday => '三',
      DateTime.thursday => '四',
      DateTime.friday => '五',
      DateTime.saturday => '六',
      DateTime.sunday => '日',
      _ => '一',
    };
  }

  static String _joinChineseList(List<String> values) {
    if (values.isEmpty) {
      return '';
    }
    if (values.length == 1) {
      return values.single;
    }
    return '${values.take(values.length - 1).join('、')}和${values.last}';
  }

  static String itemCardBadge(ItemConfig config) {
    return switch (config) {
      FixedItemConfig _ => ReminderUiText.fixedTypeLabel,
      StateBasedItemConfig _ => ReminderUiText.stateBasedTypeLabel,
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
    };
  }

  static String resourceType(ResourceType value) {
    return switch (value) {
      ResourceType.timeBased => '天數估算',
      ResourceType.quantityBased => '數量庫存',
    };
  }

  static String resourceStatus(ResourceStatus status) {
    return switch (status) {
      ResourceStatus.normal => '穩定',
      ResourceStatus.warning => ReminderUiText.warningTab,
      ResourceStatus.danger => ReminderUiText.dangerTab,
      ResourceStatus.unknown => '未建立基準',
    };
  }

  static String resourceSummary(
    Resource resource, {
    DateTime? now,
    ResourceStatusService statusService = const ResourceStatusService(),
  }) {
    return switch (resource.config) {
      TimeBasedResourceConfig config => _timeResourceSummary(
        config,
        now: now,
        statusService: statusService,
      ),
      QuantityBasedResourceConfig config => _quantityResourceSummary(config),
      _ => resource.type.name,
    };
  }

  static String resourceTrailingLabel(
    Resource resource, {
    DateTime? now,
    ResourceStatusService statusService = const ResourceStatusService(),
  }) {
    return switch (resource.config) {
      TimeBasedResourceConfig config => _timeResourceRemainingLabel(
        config,
        now: now,
        statusService: statusService,
      ),
      QuantityBasedResourceConfig config =>
        '剩 ${config.currentQuantity} ${config.unitLabel}',
      _ => '',
    };
  }

  static String _timeResourceSummary(
    TimeBasedResourceConfig config, {
    DateTime? now,
    required ResourceStatusService statusService,
  }) {
    final depletion = statusService.depletionDate(config);
    if (depletion == null) {
      return '預計用完日期尚未建立';
    }
    final remaining = statusService.timeBasedRemainingDays(config, now: now);
    final remainingText = remaining == null
        ? ''
        : ' • 大約剩 ${remaining < 0 ? 0 : remaining} 天';
    return '預計可用到 ${date(depletion)}$remainingText';
  }

  static String _timeResourceRemainingLabel(
    TimeBasedResourceConfig config, {
    DateTime? now,
    required ResourceStatusService statusService,
  }) {
    final remaining = statusService.timeBasedRemainingDays(config, now: now);
    if (remaining == null) {
      return '未建立';
    }
    return '約剩 ${remaining < 0 ? 0 : remaining} 天';
  }

  static String _quantityResourceSummary(QuantityBasedResourceConfig config) {
    return '目前 ${config.currentQuantity} ${config.unitLabel} • 剩 ${config.warningThreshold} ${config.unitLabel}提醒 • 剩 ${config.dangerThreshold} ${config.unitLabel}危急';
  }

  static String usageSpeed(UsageSpeed value) {
    return switch (value) {
      UsageSpeed.low => '慢',
      UsageSpeed.medium => '中等',
      UsageSpeed.high => '快',
    };
  }

  static String reminderTone(ReminderTone value) {
    return switch (value) {
      ReminderTone.gentle => ReminderUiText.reminderToneGentleLabel,
      ReminderTone.standard => ReminderUiText.reminderToneStandardLabel,
      ReminderTone.early => ReminderUiText.reminderToneEarlyLabel,
      ReminderTone.urgent => ReminderUiText.reminderToneUrgentLabel,
    };
  }

  static String reminderToneDescription(ReminderTone value) {
    return switch (value) {
      ReminderTone.gentle => ReminderUiText.reminderToneGentleDescription,
      ReminderTone.standard => ReminderUiText.reminderToneStandardDescription,
      ReminderTone.early => ReminderUiText.reminderToneEarlyDescription,
      ReminderTone.urgent => ReminderUiText.reminderToneUrgentDescription,
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
