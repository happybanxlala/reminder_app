import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reminder_app/features/reminders/domain/attention_summary.dart';
import 'package:reminder_app/features/reminders/services/reminder_notification_service.dart';
import 'package:timezone/timezone.dart' as tz;

void main() {
  test(
    'daily notification includes compact sync labels and safe payload',
    () async {
      final client = _FakeNotificationClient();
      final service = ReminderNotificationService(
        client: client,
        timeZoneResolver: const _FakeTimeZoneResolver(),
        clock: () => DateTime(2026, 5, 1, 8),
      );
      await service.initialize(onOpenHome: () {});

      await service.syncDailyNotification(
        const AttentionSummary(
          dangerItemCount: 1,
          warningItemCount: 1,
          dangerResourceCount: 0,
          warningResourceCount: 0,
          stageUpcomingCount: 0,
          remoteBackedItemCount: 2,
          pendingSyncItemCount: 1,
          failedSyncItemCount: 1,
          notificationSyncLabels: ['等待同步', '同步失敗'],
        ),
      );

      expect(client.scheduled, hasLength(1));
      final scheduled = client.scheduled.single;
      expect(scheduled.id, ReminderNotificationService.attentionNotificationId);
      expect(scheduled.title, '今天有 2 項需要留意');
      expect(scheduled.body, contains('等待同步'));
      expect(scheduled.body, contains('同步失敗'));
      expect(scheduled.payload, ReminderNotificationService.attentionPayload);
      expect(scheduled.payload, isNot(contains('token')));
      expect(scheduled.payload, isNot(contains('session')));
      expect(scheduled.payload, isNot(contains('credential')));
      expect(scheduled.payload, isNot(contains('service_role')));
      expect(scheduled.payload, isNot(contains('invite')));
    },
  );

  test('daily notification cancels when summary has no attention', () async {
    final client = _FakeNotificationClient();
    final service = ReminderNotificationService(
      client: client,
      timeZoneResolver: const _FakeTimeZoneResolver(),
      clock: () => DateTime(2026, 5, 1, 8),
    );
    await service.initialize(onOpenHome: () {});

    await service.syncDailyNotification(
      const AttentionSummary(
        dangerItemCount: 0,
        warningItemCount: 0,
        dangerResourceCount: 0,
        warningResourceCount: 0,
        stageUpcomingCount: 0,
        remoteBackedItemCount: 1,
        accessLostRemoteBackedItemCount: 1,
        notificationSyncLabels: ['已失去遠端存取權'],
      ),
    );

    expect(client.scheduled, isEmpty);
    expect(client.cancelled, [
      ReminderNotificationService.attentionNotificationId,
    ]);
  });
}

class _FakeNotificationClient implements ReminderNotificationClient {
  final scheduled = <_ScheduledNotification>[];
  final cancelled = <int>[];

  @override
  Future<void> initialize({
    required DidReceiveNotificationResponseCallback
    onDidReceiveNotificationResponse,
  }) async {}

  @override
  Future<void> schedule({
    required int id,
    required String title,
    required String body,
    required tz.TZDateTime scheduledDate,
    required String payload,
  }) async {
    scheduled.add(
      _ScheduledNotification(
        id: id,
        title: title,
        body: body,
        scheduledDate: scheduledDate,
        payload: payload,
      ),
    );
  }

  @override
  Future<void> cancel(int id) async {
    cancelled.add(id);
  }

  @override
  Future<void> requestPermissions() async {}
}

class _ScheduledNotification {
  const _ScheduledNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.scheduledDate,
    required this.payload,
  });

  final int id;
  final String title;
  final String body;
  final tz.TZDateTime scheduledDate;
  final String payload;
}

class _FakeTimeZoneResolver implements LocalTimeZoneResolver {
  const _FakeTimeZoneResolver();

  @override
  Future<String?> getLocalTimeZoneName() async => null;
}
