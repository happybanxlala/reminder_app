import '../domain/app_settings.dart';
import '../domain/attention_policy.dart';
import 'local/reminder_dao.dart';

class SettingsRepository {
  const SettingsRepository(this._dao);

  final ReminderDao _dao;

  Stream<AppSettings> watchSettings() {
    return _dao.watchAppSettings();
  }

  Future<AppSettings> getSettings() {
    return _dao.getAppSettings();
  }

  Future<void> updateReminderTone(ReminderTone tone) {
    return _dao.updateReminderTone(tone);
  }

  Future<void> updateNotificationReminderTime(String time) {
    return _dao.updateNotificationReminderTime(time);
  }
}
