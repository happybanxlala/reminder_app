import 'recurring_reminder.dart';

export 'recurring_reminder.dart';

/// Legacy alias kept for a staged rename from "series" to "recurring reminder".
/// New code should use [RecurringReminderStatus] directly.
@Deprecated(
  'Legacy alias during the ReminderSeries -> RecurringReminder transition. Use RecurringReminderStatus instead.',
)
typedef ReminderSeriesStatus = RecurringReminderStatus;

/// Legacy alias kept for a staged rename from "series" to "recurring reminder".
/// New code should use [RecurringReminderModel] directly.
@Deprecated(
  'Legacy alias during the ReminderSeries -> RecurringReminder transition. Use RecurringReminderModel instead.',
)
typedef ReminderSeriesModel = RecurringReminderModel;
