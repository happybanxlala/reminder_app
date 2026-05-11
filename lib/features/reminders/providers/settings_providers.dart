import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/settings_repository.dart';
import '../domain/app_settings.dart';
import '../domain/attention_policy.dart';
import 'database_providers.dart';

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  return SettingsRepository(ref.watch(appDatabaseProvider).itemTimelineDao);
});

final appSettingsProvider = StreamProvider<AppSettings>((ref) {
  return ref.watch(settingsRepositoryProvider).watchSettings();
});

final reminderToneProvider = Provider<ReminderTone>((ref) {
  return ref
      .watch(appSettingsProvider)
      .maybeWhen(
        data: (settings) => settings.reminderTone,
        orElse: () => ReminderTone.standard,
      );
});
