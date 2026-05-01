import '../data/attention_summary_repository.dart';
import '../domain/attention_summary.dart';
import 'app_badge_service.dart';
import 'reminder_notification_service.dart';

class AttentionSyncService {
  AttentionSyncService({
    required AttentionSummaryRepository repository,
    required ReminderNotificationService notificationService,
    required AppBadgeService badgeService,
  }) : _repository = repository,
       _notificationService = notificationService,
       _badgeService = badgeService;

  final AttentionSummaryRepository _repository;
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
    await _notificationService.syncDailyNotification(summary);
    await _badgeService.syncBadge(summary);
  }
}
