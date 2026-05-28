import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reminder_app/features/reminders/data/local/app_database.dart';
import 'package:reminder_app/features/reminders/data/settings_repository.dart';
import 'package:reminder_app/features/reminders/domain/attention_policy.dart';

void main() {
  test('settings repository defaults reminder tone to standard', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final repository = SettingsRepository(db.reminderDao);

    final settings = await repository.getSettings();

    expect(settings.reminderTone, ReminderTone.standard);
    expect(settings.notificationReminderTime, '09:00');
  });

  test(
    'settings repository persists and emits reminder tone changes',
    () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);
      final repository = SettingsRepository(db.reminderDao);

      final emitted = <ReminderTone>[];
      final subscription = repository
          .watchSettings()
          .map((settings) => settings.reminderTone)
          .listen(emitted.add);
      addTearDown(subscription.cancel);

      await repository.updateReminderTone(ReminderTone.early);
      await expectLater(
        repository.watchSettings().map((settings) => settings.reminderTone),
        emits(ReminderTone.early),
      );

      final settings = await repository.getSettings();
      expect(settings.reminderTone, ReminderTone.early);
      expect(emitted, contains(ReminderTone.early));
    },
  );

  test('settings repository persists notification reminder time', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final repository = SettingsRepository(db.reminderDao);

    await repository.updateNotificationReminderTime('20:30');

    final settings = await repository.getSettings();
    expect(settings.notificationReminderTime, '20:30');
    expect(settings.reminderTone, ReminderTone.standard);
  });
}
