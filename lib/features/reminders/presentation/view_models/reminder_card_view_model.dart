import '../../domain/reminder.dart';
import '../formatters/reminder_formatters.dart';
import '../text/reminder_ui_text.dart';

class PendingReminderItemViewModel {
  const PendingReminderItemViewModel({
    required this.id,
    required this.title,
    required this.primaryText,
    required this.secondaryText,
    required this.metaText,
    required this.isDone,
    required this.canDefer,
    required this.isRecurring,
  });

  factory PendingReminderItemViewModel.fromDomain(
    ReminderModel reminder, {
    DateTime? now,
  }) {
    return PendingReminderItemViewModel(
      id: reminder.id,
      title: reminder.title,
      primaryText: ReminderFormatters.pendingPrimaryText(reminder, now: now),
      secondaryText: ReminderFormatters.pendingSecondaryText(reminder),
      metaText: ReminderFormatters.pendingMetaText(reminder),
      isDone: reminder.isDone,
      canDefer: reminder.trackingMode == ReminderTrackingMode.countdown,
      isRecurring: reminder.isRecurring,
    );
  }

  final int id;
  final String title;
  final String primaryText;
  final String secondaryText;
  final String metaText;
  final bool isDone;
  final bool canDefer;
  final bool isRecurring;
}

class CompletedPendingReminderItemViewModel {
  const CompletedPendingReminderItemViewModel({
    required this.id,
    required this.title,
    required this.subtitle,
  });

  factory CompletedPendingReminderItemViewModel.fromDomain(
    ReminderModel reminder,
  ) {
    return CompletedPendingReminderItemViewModel(
      id: reminder.id,
      title: reminder.title,
      subtitle: ReminderUiText.stagedCompletedSubtitle,
    );
  }

  factory CompletedPendingReminderItemViewModel.fromPending(
    PendingReminderItemViewModel reminder,
  ) {
    return CompletedPendingReminderItemViewModel(
      id: reminder.id,
      title: reminder.title,
      subtitle: ReminderUiText.stagedCompletedSubtitle,
    );
  }

  final int id;
  final String title;
  final String subtitle;
}

class HistoryReminderItemViewModel {
  const HistoryReminderItemViewModel({
    required this.title,
    required this.subtitle,
    required this.isDone,
  });

  factory HistoryReminderItemViewModel.fromDomain(ReminderModel reminder) {
    return HistoryReminderItemViewModel(
      title: reminder.title,
      isDone: reminder.isDone,
      subtitle: ReminderFormatters.historySubtitle(reminder),
    );
  }

  final String title;
  final String subtitle;
  final bool isDone;
}
