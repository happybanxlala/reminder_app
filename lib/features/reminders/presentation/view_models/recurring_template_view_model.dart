import '../../domain/recurring_reminder.dart';
import '../../domain/reminder.dart';
import '../../domain/repeat_rule.dart';
import '../formatters/reminder_formatters.dart';
import '../text/reminder_ui_text.dart';

class RecurringReminderItemViewModel {
  const RecurringReminderItemViewModel({
    required this.id,
    required this.title,
    required this.statusLabel,
    required this.typeLabel,
    required this.summaryText,
    required this.isPending,
    required this.isStopped,
    required this.isCanceled,
    required this.isFixedTime,
    this.repeatRule,
  });

  factory RecurringReminderItemViewModel.fromDomain(
    RecurringReminderModel reminder,
  ) {
    return RecurringReminderItemViewModel(
      id: reminder.id,
      title: reminder.title,
      statusLabel: ReminderFormatters.recurringReminderStatusLabel(
        reminder.status,
      ),
      typeLabel: ReminderUiText.trackingModeLabel(reminder.trackingMode),
      summaryText: ReminderFormatters.recurringTemplateSummary(reminder),
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
  final String typeLabel;
  final String summaryText;
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
