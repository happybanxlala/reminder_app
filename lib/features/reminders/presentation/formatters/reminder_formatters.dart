import 'package:intl/intl.dart';

import '../../domain/recurring_reminder.dart';
import '../../domain/reminder.dart';
import '../../domain/repeat_rule.dart';
import '../text/reminder_ui_text.dart';

class ReminderFormatters {
  const ReminderFormatters._();

  static String shortDate(DateTime value) {
    return DateFormat('yyyy/MM/dd').format(value.toLocal());
  }

  static String categoryLabel({
    required String? topicCategoryName,
    required String? actionCategoryName,
  }) {
    if (topicCategoryName == null && actionCategoryName == null) {
      return '';
    }
    if (topicCategoryName != null && actionCategoryName != null) {
      return '$topicCategoryName / $actionCategoryName';
    }
    return topicCategoryName ?? actionCategoryName ?? '';
  }

  static String remainingLabel(ReminderModel reminder, {DateTime? now}) {
    final current = now ?? DateTime.now();
    if (reminder.trackingMode == ReminderTrackingMode.accumulation) {
      final today = DateTime(current.year, current.month, current.day);
      final start = DateTime(
        reminder.startAt.year,
        reminder.startAt.month,
        reminder.startAt.day,
      );
      final accumulated = today.difference(start).inDays;
      if (accumulated <= 0) {
        return '今天開始';
      }
      return '已累積 $accumulated 天';
    }

    final effectiveDueAt = reminder.deferredDueAt ?? reminder.dueAt;
    if (effectiveDueAt == null) {
      return ReminderUiText.unsetFixedTime;
    }

    final today = DateTime(current.year, current.month, current.day);
    final due = DateTime(
      effectiveDueAt.year,
      effectiveDueAt.month,
      effectiveDueAt.day,
    );
    final diff = due.difference(today).inDays;

    if (diff > 0) {
      return '剩餘 $diff 天';
    }
    if (diff == 0) {
      final endOfDueDay = due.add(const Duration(days: 1));
      final remainingHours = endOfDueDay.difference(current).inHours;
      final safeHours = remainingHours <= 0 ? 1 : remainingHours;
      return '剩餘 $safeHours 小時';
    }
    return '逾期 ${diff.abs()} 天';
  }

  static String pendingPrimaryText(ReminderModel reminder, {DateTime? now}) {
    final current = now ?? DateTime.now();
    final today = DateTime(current.year, current.month, current.day);

    if (reminder.trackingMode == ReminderTrackingMode.accumulation) {
      final start = DateTime(
        reminder.startAt.year,
        reminder.startAt.month,
        reminder.startAt.day,
      );
      final diffDays = today.difference(start).inDays;
      final dayCount = diffDays < 0 ? 1 : diffDays + 1;
      return '${ReminderUiText.reminderCardOrdinalPrefix} $dayCount ${ReminderUiText.reminderCardDayUnit}';
    }

    final effectiveDueAt = reminder.deferredDueAt ?? reminder.dueAt;
    if (effectiveDueAt == null) {
      return ReminderUiText.unsetFixedTime;
    }
    final due = DateTime(
      effectiveDueAt.year,
      effectiveDueAt.month,
      effectiveDueAt.day,
    );
    final diff = due.difference(today).inDays;
    if (diff == 0) {
      return ReminderUiText.reminderCardToday;
    }
    if (diff == 1) {
      return ReminderUiText.reminderCardTomorrow;
    }
    if (diff > 1) {
      return '${ReminderUiText.reminderCardRemainingPrefix} $diff ${ReminderUiText.reminderCardDayUnit}';
    }
    return '${ReminderUiText.reminderCardOverduePrefix} ${diff.abs()} ${ReminderUiText.reminderCardDayUnit}';
  }

  static String pendingSecondaryText(ReminderModel reminder) {
    if (reminder.trackingMode == ReminderTrackingMode.accumulation) {
      return '${ReminderUiText.reminderCardStartDatePrefix} ${shortDate(reminder.startAt)}';
    }

    final repeatSummary = repeatRuleSummary(reminder.repeatRule);
    return repeatSummary == ReminderUiText.unset
        ? ReminderUiText.reminderCardRuleFallback
        : repeatSummary;
  }

  static String pendingMetaText(ReminderModel reminder) {
    final category = categoryLabel(
      topicCategoryName: reminder.topicCategoryName,
      actionCategoryName: reminder.actionCategoryName,
    );
    if (category.isNotEmpty) {
      return category;
    }

    if (reminder.trackingMode == ReminderTrackingMode.countdown) {
      final effectiveDueAt = reminder.deferredDueAt ?? reminder.dueAt;
      if (effectiveDueAt != null) {
        return shortDate(effectiveDueAt);
      }
    }

    return '${ReminderUiText.reminderCardStartedOnPrefix} ${shortDate(reminder.startAt)}';
  }

  static String repeatRuleSummary(String? repeatRule) {
    final rule = RepeatRule.parse(repeatRule);
    if (rule == null) {
      return repeatRule == null || repeatRule.isEmpty
          ? ReminderUiText.unset
          : repeatRule;
    }

    final unit = switch (rule.kind) {
      'D' => '天',
      'W' => '週',
      'M' => '月',
      'Y' => '年',
      _ => '',
    };
    if (unit.isEmpty) {
      return repeatRule ?? ReminderUiText.unset;
    }
    if (rule.interval == 1) {
      return '每$unit';
    }
    return '每 ${rule.interval} $unit';
  }

  static String recurringReminderStatusLabel(int status) {
    switch (status) {
      case RecurringReminderStatus.pending:
        return '進行中';
      case RecurringReminderStatus.stopped:
        return '已停止';
      case RecurringReminderStatus.canceled:
        return '已取消';
      default:
        return '未知狀態';
    }
  }

  static String recurringTemplateSummary(RecurringReminderModel reminder) {
    final repeatSummary = repeatRuleSummary(reminder.repeatRule);
    final category = categoryLabel(
      topicCategoryName: reminder.topicCategoryName,
      actionCategoryName: reminder.actionCategoryName,
    );
    final parts = <String>[
      repeatSummary == ReminderUiText.unset
          ? ReminderUiText.reminderTemplateDefaultSummary
          : repeatSummary,
      if (category.isNotEmpty)
        '${ReminderUiText.reminderTemplateCategoryPrefix} $category',
    ];
    return parts.join('  •  ');
  }

  static String historySubtitle(ReminderModel reminder) {
    final updatedAtText = DateFormat(
      'yyyy/MM/dd HH:mm',
    ).format(reminder.updatedAt.toLocal());
    final isFixedTime = reminder.trackingMode == ReminderTrackingMode.countdown;
    final dateText = isFixedTime
        ? (reminder.dueAt == null
              ? ReminderUiText.unsetFixedTime
              : DateFormat('yyyy/MM/dd').format(reminder.dueAt!.toLocal()))
        : DateFormat('yyyy/MM/dd').format(reminder.startAt.toLocal());
    final category = categoryLabel(
      topicCategoryName: reminder.topicCategoryName,
      actionCategoryName: reminder.actionCategoryName,
    );

    return [
      '狀態: ${reminder.isDone ? 'Done' : 'Skipped'}',
      '時間設定: ${ReminderUiText.trackingModeLabel(reminder.trackingMode)}',
      '更新: $updatedAtText',
      isFixedTime ? '固定日期: $dateText' : '開始日期: $dateText',
      if (category.isNotEmpty) '分類: $category',
    ].join('\n');
  }
}
