import 'package:intl/intl.dart';

import '../../data/local/task_timeline_dao.dart';
import '../../domain/reminder_rule.dart';
import '../../domain/repeat_rule.dart';
import '../../domain/task_template.dart';
import '../../domain/timeline.dart';
import '../../domain/timeline_milestone_occurrence.dart';
import '../../domain/timeline_milestone_record.dart';
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

  static String taskSummary(TaskBundle bundle) {
    final task = bundle.task;
    final rule = task.repeatRule;
    final repeatText = rule == null ? '單次' : repeatRule(rule);
    return '${date(task.effectiveDueDate)} • $repeatText • ${reminderRule(task.reminderRule)}';
  }

  static String taskHistory(TaskBundle bundle) {
    return '${bundle.task.status.name} • ${date(bundle.task.effectiveDueDate)}';
  }

  static String taskHistoryUpdatedAt(TaskBundle bundle) {
    return '${ReminderUiText.updatedAtLabel}：${dateTime(bundle.task.updatedAt)}';
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

  static String templateSummary(
    RepeatRule? repeatRuleValue,
    ReminderRule reminder,
  ) {
    final repeatText = repeatRuleValue == null
        ? 'one-time'
        : repeatRule(repeatRuleValue);
    return '$repeatText • ${reminderRule(reminder)}';
  }

  static String timelineSummary(Timeline timeline) {
    return '${date(timeline.startDate)} • ${displayUnitLabel(timeline.displayUnit)}';
  }

  static String taskTemplateStatus(TaskTemplateStatus status) {
    return switch (status) {
      TaskTemplateStatus.active => 'active',
      TaskTemplateStatus.paused => 'paused',
      TaskTemplateStatus.archived => 'archived',
    };
  }

  static String timelineStatus(TimelineStatus status) {
    return switch (status) {
      TimelineStatus.active => 'active',
      TimelineStatus.archived => 'archived',
    };
  }

  static String repeatRule(RepeatRule rule) {
    final unit = switch (rule.unit) {
      RepeatUnit.day => 'day',
      RepeatUnit.week => 'week',
      RepeatUnit.month => 'month',
      RepeatUnit.year => 'year',
    };
    if (rule.interval == 1) {
      return 'every $unit';
    }
    return 'every ${rule.interval} ${unit}s';
  }

  static String reminderRule(ReminderRule rule) {
    return switch (rule.type) {
      ReminderRuleType.advance => '提前 ${rule.offsetDays ?? 0} 天',
      ReminderRuleType.onDue => '到期當天',
      ReminderRuleType.immediate => '建立後立即',
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

  static String milestoneStatus(MilestoneStatus value) {
    return switch (value) {
      MilestoneStatus.upcoming => 'upcoming',
      MilestoneStatus.noticed => 'noticed',
      MilestoneStatus.skipped => 'skipped',
    };
  }
}
