import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/app_badge_service.dart';
import '../services/attention_sync_service.dart';
import '../services/reminder_notification_service.dart';
import 'attention_summary_providers.dart';

final reminderNotificationClientProvider = Provider<ReminderNotificationClient>(
  (ref) {
    return FlutterReminderNotificationClient();
  },
);

final localTimeZoneResolverProvider = Provider<LocalTimeZoneResolver>((ref) {
  return FlutterLocalTimeZoneResolver();
});

final reminderNotificationServiceProvider =
    Provider<ReminderNotificationService>((ref) {
      return ReminderNotificationService(
        client: ref.watch(reminderNotificationClientProvider),
        timeZoneResolver: ref.watch(localTimeZoneResolverProvider),
      );
    });

final appBadgeClientProvider = Provider<AppBadgeClient>((ref) {
  return AppBadgePlusClient();
});

final appBadgeServiceProvider = Provider<AppBadgeService>((ref) {
  return AppBadgeService(client: ref.watch(appBadgeClientProvider));
});

final attentionSyncServiceProvider = Provider<AttentionSyncService>((ref) {
  return AttentionSyncService(
    repository: ref.watch(attentionSummaryRepositoryProvider),
    notificationService: ref.watch(reminderNotificationServiceProvider),
    badgeService: ref.watch(appBadgeServiceProvider),
  );
});
