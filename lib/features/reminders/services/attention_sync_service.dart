import '../data/attention_summary_repository.dart';
import '../data/settings_repository.dart';
import '../domain/attention_summary.dart';
import 'app_badge_service.dart';
import 'reminder_notification_service.dart';

class AttentionSyncService {
  AttentionSyncService({
    required AttentionSummaryRepository repository,
    required SettingsRepository settingsRepository,
    required ReminderNotificationService notificationService,
    required AppBadgeService badgeService,
  }) : _repository = repository,
       _settingsRepository = settingsRepository,
       _notificationService = notificationService,
       _badgeService = badgeService;

  final AttentionSummaryRepository _repository;
  final SettingsRepository _settingsRepository;
  final ReminderNotificationService _notificationService;
  final AppBadgeService _badgeService;

  Future<void> initialize({required void Function() onOpenHome}) async {
    await _notificationService.initialize(onOpenHome: onOpenHome);
    await _notificationService.requestPermissions();
  }

  Future<void> refresh() async {
    final summary = await _repository.getSummary(now: DateTime.now());
    await syncSummary(summary);
  }

  Future<void> syncSummary(AttentionSummary summary) async {
    final settings = await _settingsRepository.getSettings();
    await _notificationService.syncDailyNotification(
      summary,
      reminderTime: settings.notificationReminderTime,
    );
    await _badgeService.syncBadge(summary);
  }
}
