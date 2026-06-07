import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/reminder_backup_service.dart';
import 'database_providers.dart';

final reminderBackupServiceProvider = Provider<ReminderBackupService>((ref) {
  return ReminderBackupService(ref.watch(appDatabaseProvider).reminderDao);
});
