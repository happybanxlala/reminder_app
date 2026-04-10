import '../../domain/reminder.dart';

class ReminderUiText {
  const ReminderUiText._();

  static const appTitle = '任務';
  static const task = '任務';
  static const habit = '習慣';
  static const habitTemplate = '習慣模板';

  static const todayTab = '今天';
  static const upcomingTab = '接下來';
  static const completedTab = '已完成';
  static const habitTab = '習慣';
  static const pendingTab = upcomingTab;
  static const historyTab = completedTab;
  static const settingsTab = habitTab;
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
  static const unsetFixedTime = '未設定日期';
  static const noTodayTasks = '今天沒有要處理的任務。';
  static const noUpcomingTasks = '接下來沒有進行中的任務。';
  static const noPendingTasks = noUpcomingTasks;
  static const noHistoryTasks = '目前沒有完成或跳過的任務。';
  static const noHabits = '目前沒有提醒模板。';
  static const cancelTask = '取消任務';
  static const deferTask = '延期任務';
  static const skipAction = '略過';
  static const cancelAction = '取消';
  static const editAction = '編輯';
  static const stopAction = '暫停';
  static const reactivateAction = '啟用';
  static const confirmNo = '否';
  static const confirmYes = '是';
  static const cancelActionButton = '取消';
  static const confirmActionButton = '確認';
  static const deferTooltip = '延期';
  static const stagedCompletedHeader = '已完成（可恢復）';
  static const stagedCompletedSubtitle = '已完成，點一下可恢復';
  static const historyRecentHint = '僅顯示近期 30 筆資料';
  static const restorePendingTitle = '恢復未完成';
  static const restorePendingMessage = '確定要把這筆任務恢復為未完成嗎？';
  static const stopHabit = '暫停習慣';
  static const cancelHabit = '取消習慣';
  static const reactivateHabit = '重新啟用習慣';
  static const fixedTimeRequired = '固定時間任務需要設定日期';
  static const habitRepeatRuleRequired = '習慣需要設定重複規則';
  static const reminderCardStartToday = '今天開始';
  static const reminderCardToday = '今天';
  static const reminderCardTomorrow = '明天';
  static const reminderCardOverduePrefix = '逾期';
  static const reminderCardRemainingPrefix = '剩';
  static const reminderCardDayUnit = '天';
  static const reminderCardOrdinalPrefix = '第';
  static const reminderCardStartedOnPrefix = '開始於';
  static const reminderCardRuleFallback = '單次提醒';
  static const reminderCardStartDatePrefix = '起始日';
  static const reminderTemplateDefaultSummary = '尚未設定規則';
  static const reminderTemplateCategoryPrefix = '分類';

  static String deferredDaysMessage(int days) => '$deferTask $days 天';

  static String cancelTaskMessage({required bool isRecurring}) {
    if (!isRecurring) {
      return '確定要取消這筆任務嗎？';
    }
    return '確定要取消這筆任務嗎？\n這會同時暫停所屬習慣，並取消這個習慣目前所有未完成任務。';
  }

  static String recurringActionMessage(String actionLabel) {
    return '確定要$actionLabel這個習慣嗎？\n這會同時取消目前這個習慣所有未完成任務。';
  }

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
