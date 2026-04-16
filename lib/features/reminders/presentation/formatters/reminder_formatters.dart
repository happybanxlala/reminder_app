import 'package:intl/intl.dart';

import '../../data/home_models.dart';
import '../../data/local/responsibility_timeline_dao.dart';
import '../../domain/responsibility_item.dart';
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

  static String responsibilitySummary(ResponsibilityItemBundle bundle) {
    return switch (bundle.item.config) {
      FixedTimeItemConfig config => _fixedTimeSummary(config),
      StateBasedItemConfig config => _stateBasedSummary(config),
      ResourceBasedItemConfig config => _resourceBasedSummary(config),
      _ => bundle.item.type.name,
    };
  }

  static String responsibilityHomeSummary(ResponsibilityItemHomeEntry entry) {
    final elapsed = entry.elapsed;
    final elapsedText = elapsed == null ? '尚未完成過' : elapsedLabel(elapsed);
    return '${responsibilityStatus(entry.status)} • $elapsedText';
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

  static String responsibilityStatus(ResponsibilityItemStatus status) {
    return switch (status) {
      ResponsibilityItemStatus.normal => 'normal',
      ResponsibilityItemStatus.warning => 'warning',
      ResponsibilityItemStatus.danger => 'danger',
      ResponsibilityItemStatus.unknown => 'unknown',
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

  static String _fixedTimeSummary(FixedTimeItemConfig config) {
    final scheduleLabel = switch (config.scheduleType) {
      FixedTimeScheduleType.daily => 'daily',
      FixedTimeScheduleType.weekly => 'weekly',
      FixedTimeScheduleType.custom => 'custom',
    };
    final anchorLabel = config.anchorDate == null
        ? null
        : date(config.anchorDate!);
    final parts = <String>[scheduleLabel];
    if (anchorLabel != null) {
      parts.add(anchorLabel);
    }
    if (config.timeOfDay != null && config.timeOfDay!.isNotEmpty) {
      parts.add(config.timeOfDay!);
    }
    return parts.join(' • ');
  }

  static String _stateBasedSummary(StateBasedItemConfig config) {
    return 'expected ${config.expectedInterval.inDays}d • warning ${config.warningAfter.inDays}d • danger ${config.dangerAfter.inDays}d';
  }

  static String _resourceBasedSummary(ResourceBasedItemConfig config) {
    return 'estimate ${config.estimatedDuration.inDays}d • warn before ${config.warningBeforeDepletion.inDays}d';
  }
}
