import 'attention_policy.dart';

class AppSettings {
  const AppSettings({
    this.reminderTone = ReminderTone.standard,
    this.notificationReminderTime = '09:00',
    required this.updatedAt,
  });

  final ReminderTone reminderTone;
  final String notificationReminderTime;
  final DateTime updatedAt;
}
