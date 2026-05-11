import 'attention_policy.dart';

class AppSettings {
  const AppSettings({
    this.reminderTone = ReminderTone.standard,
    required this.updatedAt,
  });

  final ReminderTone reminderTone;
  final DateTime updatedAt;
}
