import 'package:intl/intl.dart';

import '../domain/demo_reminder_draft.dart';
import '../domain/reminder.dart';
import '../domain/recurring_reminder.dart';
import '../domain/repeat_rule.dart';

class ReminderUiText {
  const ReminderUiText._();

  static const appTitle = '任務';
  static const task = '任務';
  static const habit = '習慣';
  static const habitTemplate = '習慣模板';

  static const pendingTab = '進行中';
  static const historyTab = '完成/跳過';
  static const addTask = '新增任務';
  static const addHabit = '新增習慣';
  static const editTask = '編輯任務';
  static const editHabit = '編輯習慣';
  static const viewHabit = '檢視習慣';
  static const trackingModeField = '時間設定';
  static const triggerModeField = '通知方式';
  static const fixedTimeField = '固定時間';
  static const startDateField = '開始日期';
  static const unset = '未設定';
  static const unsetFixedTime = '未設定固定時間';
  static const noPendingTasks = '目前沒有進行中的任務。';
  static const noHistoryTasks = '目前沒有完成或跳過的任務。';
  static const noHabits = '目前沒有習慣。';
  static const cancelTask = '取消任務';
  static const deferTask = '延期任務';
  static const restorePendingTitle = '恢復未完成';
  static const restorePendingMessage = '確定要把這筆任務恢復為未完成嗎？';
  static const stopHabit = '暫停習慣';
  static const cancelHabit = '取消習慣';
  static const reactivateHabit = '重新啟用習慣';
  static const fixedTimeRequired = '固定時間任務需要設定時間';
  static const habitRepeatRuleRequired = '習慣需要設定重複規則';

  static String trackingModeLabel(int trackingMode) {
    return trackingMode == ReminderTrackingMode.countdown ? '固定時間' : '從某天開始';
  }

  static String triggerModeLabel({
    required int trackingMode,
    required int triggerMode,
  }) {
    if (trackingMode == ReminderTrackingMode.accumulation) {
      return '累積達標後提醒';
    }

    switch (triggerMode) {
      case ReminderTriggerMode.inRange:
        return '進入提醒範圍時';
      case ReminderTriggerMode.immediate:
        return '建立後立即提醒';
      case ReminderTriggerMode.onPoint:
        return '固定時間才提醒';
      default:
        return '未知方式';
    }
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
}

class ReminderTrackingModeOption {
  const ReminderTrackingModeOption({required this.value, required this.label});

  final int value;
  final String label;

  static List<ReminderTrackingModeOption> get values {
    return [
      ReminderTrackingModeOption(
        value: ReminderTrackingMode.countdown,
        label: ReminderUiText.trackingModeLabel(ReminderTrackingMode.countdown),
      ),
      ReminderTrackingModeOption(
        value: ReminderTrackingMode.accumulation,
        label: ReminderUiText.trackingModeLabel(
          ReminderTrackingMode.accumulation,
        ),
      ),
    ];
  }
}

class ReminderTriggerModeOption {
  const ReminderTriggerModeOption({required this.value, required this.label});

  final int value;
  final String label;

  static List<ReminderTriggerModeOption> forTrackingMode(int trackingMode) {
    if (trackingMode == ReminderTrackingMode.accumulation) {
      return [
        ReminderTriggerModeOption(
          value: ReminderTriggerMode.inRange,
          label: ReminderUiText.triggerModeLabel(
            trackingMode: trackingMode,
            triggerMode: ReminderTriggerMode.inRange,
          ),
        ),
      ];
    }

    return [
      ReminderTriggerModeOption(
        value: ReminderTriggerMode.inRange,
        label: ReminderUiText.triggerModeLabel(
          trackingMode: trackingMode,
          triggerMode: ReminderTriggerMode.inRange,
        ),
      ),
      ReminderTriggerModeOption(
        value: ReminderTriggerMode.immediate,
        label: ReminderUiText.triggerModeLabel(
          trackingMode: trackingMode,
          triggerMode: ReminderTriggerMode.immediate,
        ),
      ),
      ReminderTriggerModeOption(
        value: ReminderTriggerMode.onPoint,
        label: ReminderUiText.triggerModeLabel(
          trackingMode: trackingMode,
          triggerMode: ReminderTriggerMode.onPoint,
        ),
      ),
    ];
  }
}

class PendingReminderItemViewModel {
  const PendingReminderItemViewModel({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.isDone,
    required this.canDefer,
    required this.isRecurring,
  });

  factory PendingReminderItemViewModel.fromDomain(
    ReminderModel reminder, {
    DateTime? now,
  }) {
    final category = ReminderUiText.categoryLabel(
      topicCategoryName: reminder.topicCategoryName,
      actionCategoryName: reminder.actionCategoryName,
    );
    final lines = <String>[
      ReminderUiText.trackingModeLabel(reminder.trackingMode),
      _remainingLabel(reminder, now: now),
      if (category.isNotEmpty) category,
    ];

    return PendingReminderItemViewModel(
      id: reminder.id,
      title: reminder.title,
      subtitle: lines.join('\n'),
      isDone: reminder.isDone,
      canDefer: reminder.trackingMode == ReminderTrackingMode.countdown,
      isRecurring: reminder.isRecurring,
    );
  }

  final int id;
  final String title;
  final String subtitle;
  final bool isDone;
  final bool canDefer;
  final bool isRecurring;
}

class CompletedPendingReminderItemViewModel {
  const CompletedPendingReminderItemViewModel({
    required this.id,
    required this.title,
  });

  factory CompletedPendingReminderItemViewModel.fromDomain(
    ReminderModel reminder,
  ) {
    return CompletedPendingReminderItemViewModel(
      id: reminder.id,
      title: reminder.title,
    );
  }

  final int id;
  final String title;
}

class HistoryReminderItemViewModel {
  const HistoryReminderItemViewModel({
    required this.title,
    required this.subtitle,
    required this.isDone,
  });

  factory HistoryReminderItemViewModel.fromDomain(ReminderModel reminder) {
    final updatedAtText = DateFormat(
      'yyyy/MM/dd HH:mm',
    ).format(reminder.updatedAt.toLocal());
    final isFixedTime = reminder.trackingMode == ReminderTrackingMode.countdown;
    final timeText = isFixedTime
        ? (reminder.dueAt == null
              ? ReminderUiText.unsetFixedTime
              : DateFormat(
                  'yyyy/MM/dd HH:mm',
                ).format(reminder.dueAt!.toLocal()))
        : DateFormat('yyyy/MM/dd HH:mm').format(reminder.startAt.toLocal());
    final category = ReminderUiText.categoryLabel(
      topicCategoryName: reminder.topicCategoryName,
      actionCategoryName: reminder.actionCategoryName,
    );

    return HistoryReminderItemViewModel(
      title: reminder.title,
      isDone: reminder.isDone,
      subtitle: [
        '狀態: ${reminder.isDone ? 'Done' : 'Skipped'}',
        '時間設定: ${ReminderUiText.trackingModeLabel(reminder.trackingMode)}',
        '更新: $updatedAtText',
        isFixedTime ? '固定時間: $timeText' : '開始日期: $timeText',
        if (category.isNotEmpty) '分類: $category',
      ].join('\n'),
    );
  }

  final String title;
  final String subtitle;
  final bool isDone;
}

class RecurringReminderItemViewModel {
  const RecurringReminderItemViewModel({
    required this.id,
    required this.title,
    required this.statusLabel,
    required this.trackingModeLabel,
    required this.repeatRuleLabel,
    required this.categoryLabel,
    required this.isPending,
    required this.isStopped,
    required this.isCanceled,
    required this.isFixedTime,
    this.repeatRule,
  });

  factory RecurringReminderItemViewModel.fromDomain(
    RecurringReminderModel reminder,
  ) {
    final category = ReminderUiText.categoryLabel(
      topicCategoryName: reminder.topicCategoryName,
      actionCategoryName: reminder.actionCategoryName,
    );

    return RecurringReminderItemViewModel(
      id: reminder.id,
      title: reminder.title,
      statusLabel: _recurringReminderStatusLabel(reminder.status),
      trackingModeLabel: ReminderUiText.trackingModeLabel(
        reminder.trackingMode,
      ),
      repeatRuleLabel: reminder.repeatRule ?? ReminderUiText.unset,
      categoryLabel: category,
      isPending: reminder.status == RecurringReminderStatus.pending,
      isStopped: reminder.status == RecurringReminderStatus.stopped,
      isCanceled: reminder.status == RecurringReminderStatus.canceled,
      isFixedTime: reminder.trackingMode == ReminderTrackingMode.countdown,
      repeatRule: reminder.repeatRule,
    );
  }

  final int id;
  final String title;
  final String statusLabel;
  final String trackingModeLabel;
  final String repeatRuleLabel;
  final String categoryLabel;
  final bool isPending;
  final bool isStopped;
  final bool isCanceled;
  final bool isFixedTime;
  final String? repeatRule;

  DateTime nextFixedTimeFrom(DateTime today) {
    final rule = RepeatRule.parse(repeatRule);
    if (rule == null) {
      return today;
    }
    return rule.advance(today);
  }
}

class ReminderFormDraft {
  const ReminderFormDraft({
    required this.title,
    this.note,
    required this.trackingMode,
    required this.triggerMode,
    required this.triggerOffsetDays,
    this.repeatRule,
    this.dueAt,
    this.startAt,
    this.topicCategoryId,
    this.actionCategoryId,
    this.readOnly = false,
  });

  factory ReminderFormDraft.createDefault() {
    return ReminderFormDraft(
      title: '',
      note: null,
      trackingMode: ReminderTrackingMode.countdown,
      triggerMode: ReminderTriggerMode.inRange,
      triggerOffsetDays: 0,
      startAt: DateTime.now(),
    );
  }

  factory ReminderFormDraft.fromReminder(ReminderModel reminder) {
    return ReminderFormDraft(
      title: reminder.title,
      note: reminder.note,
      trackingMode: reminder.trackingMode,
      triggerMode: reminder.triggerMode,
      triggerOffsetDays: reminder.triggerOffsetDays ?? 0,
      repeatRule: reminder.repeatRule,
      dueAt: reminder.dueAt,
      startAt: reminder.startAt,
      topicCategoryId: reminder.topicCategoryId,
      actionCategoryId: reminder.actionCategoryId,
    );
  }

  factory ReminderFormDraft.fromRecurringReminder(
    RecurringReminderModel reminder,
  ) {
    return ReminderFormDraft(
      title: reminder.title,
      note: reminder.note,
      trackingMode: reminder.trackingMode,
      triggerMode: reminder.triggerMode,
      triggerOffsetDays: reminder.triggerOffsetDays ?? 0,
      repeatRule: reminder.repeatRule,
      topicCategoryId: reminder.topicCategoryId,
      actionCategoryId: reminder.actionCategoryId,
      readOnly: reminder.status == RecurringReminderStatus.canceled,
    );
  }

  factory ReminderFormDraft.fromDemo(DemoReminderDraft draft) {
    return ReminderFormDraft(
      title: draft.title,
      note: draft.note,
      trackingMode: draft.trackingMode,
      triggerMode: draft.triggerMode,
      triggerOffsetDays: draft.triggerOffsetDays,
      repeatRule: _repeatRuleFromDemoDraft(draft),
      dueAt: draft.dueAt,
      startAt: draft.startAt,
    );
  }

  final String title;
  final String? note;
  final int trackingMode;
  final int triggerMode;
  final int triggerOffsetDays;
  final String? repeatRule;
  final DateTime? dueAt;
  final DateTime? startAt;
  final int? topicCategoryId;
  final int? actionCategoryId;
  final bool readOnly;
}

String _remainingLabel(ReminderModel reminder, {DateTime? now}) {
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

String _recurringReminderStatusLabel(int status) {
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

String? _repeatRuleFromDemoDraft(DemoReminderDraft draft) {
  if (draft.repeatType == null) {
    return null;
  }
  return '${draft.repeatType}${draft.repeatInterval}';
}
