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
import '../text/reminder_ui_text.dart';

class ReminderFormatters {
  const ReminderFormatters._();

  static String date(DateTime value) {
    return DateFormat('yyyy/MM/dd').format(value.toLocal());
  }

  static String dateTime(DateTime value) {
    return DateFormat('yyyy/MM/dd HH:mm').format(value.toLocal());
  }

  static String itemSummary(ItemBundle bundle) {
    return switch (bundle.item.config) {
      FixedItemConfig config => _fixedSummary(config),
      StateBasedItemConfig config => _stateBasedSummary(config),
      ResourceBasedItemConfig config => _resourceBasedSummary(config),
      _ => bundle.item.type.name,
    };
  }

  static String itemHomeSummary(ItemHomeEntry entry) {
    return '${entry.bundle.pack.title} • ${itemStatus(entry.status)} • ${itemSummary(entry.bundle)}';
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
    return '${bundle.record.status.name} • $label • ${date(bundle.record.targetDate)}';
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
      TimelineMilestoneRuleStatus.active => 'active',
      TimelineMilestoneRuleStatus.paused => 'paused',
      TimelineMilestoneRuleStatus.archived => 'archived',
    };
  }

  static String timelineSummary(Timeline timeline) {
    return '${date(timeline.startDate)} • ${displayUnitLabel(timeline.displayUnit)}';
  }

  static String timelineStatus(TimelineStatus status) {
    return switch (status) {
      TimelineStatus.active => 'active',
      TimelineStatus.archived => 'archived',
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
      TimelineMilestoneRecordStatus.upcoming => 'upcoming',
      TimelineMilestoneRecordStatus.noticed => 'noticed',
      TimelineMilestoneRecordStatus.skipped => 'skipped',
    };
  }

  static String itemStatus(ItemStatus status) {
    return switch (status) {
      ItemStatus.normal => '穩定',
      ItemStatus.warning => '需留意',
      ItemStatus.danger => '快變糟',
      ItemStatus.unknown => '未建立基準',
    };
  }

  static String itemLifecycleStatus(ItemLifecycleStatus status) {
    return switch (status) {
      ItemLifecycleStatus.active => 'active',
      ItemLifecycleStatus.paused => 'paused',
      ItemLifecycleStatus.archived => 'archived',
    };
  }

  static String itemPackStatus(ItemPackStatus status) {
    return switch (status) {
      ItemPackStatus.active => 'active',
      ItemPackStatus.archived => 'archived',
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

  static String _fixedSummary(FixedItemConfig config) {
    final scheduleLabel = switch (config.scheduleType) {
      FixedScheduleType.daily => '每天',
      FixedScheduleType.weekly => '每週',
      FixedScheduleType.custom => '自訂',
    };
    final anchorLabel = config.anchorDate == null
        ? null
        : date(config.anchorDate!);
    final dueLabel = config.dueDate == null ? null : date(config.dueDate!);
    final overdueLabel = switch (config.overduePolicy) {
      ItemOverduePolicy.autoAdvance => '逾期自動進下一輪',
      ItemOverduePolicy.waitForAction => '逾期等待處理',
    };
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
    parts.add(overdueLabel);
    return parts.join(' • ');
  }

  static String _stateBasedSummary(StateBasedItemConfig config) {
    return '基準 ${config.expectedAfter.inDays} 天 • 留意 ${config.warningAfter.inDays} 天 • 變糟 ${config.dangerAfter.inDays} 天';
  }

  static String _resourceBasedSummary(ResourceBasedItemConfig config) {
    final anchor = config.anchorDate == null ? '未建立' : date(config.anchorDate!);
    return '起點 $anchor • 可維持 ${config.durationDays} 天 • 留意前 ${config.warningBefore} 天';
  }
}
