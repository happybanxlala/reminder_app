import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:reminder_app/features/reminders/data/attention_summary_repository.dart';
import 'package:reminder_app/features/reminders/data/home_models.dart';
import 'package:reminder_app/features/reminders/data/home_repository.dart';
import 'package:reminder_app/features/reminders/data/local/item_timeline_dao.dart';
import 'package:reminder_app/features/reminders/domain/attention_summary.dart';
import 'package:reminder_app/features/reminders/domain/item.dart';
import 'package:reminder_app/features/reminders/domain/item_pack.dart';
import 'package:reminder_app/features/reminders/domain/timeline_milestone_occurrence.dart';
import 'package:reminder_app/features/reminders/domain/timeline_milestone_record.dart';
import 'package:reminder_app/features/reminders/services/app_badge_service.dart';
import 'package:reminder_app/features/reminders/services/attention_sync_service.dart';
import 'package:reminder_app/features/reminders/services/reminder_notification_service.dart';
import 'package:timezone/timezone.dart' as tz;

void main() {
  test('attention summary totalCount sums all attention buckets', () {
    const summary = AttentionSummary(
      dangerCount: 2,
      warningCount: 3,
      timelineUpcomingCount: 4,
    );

    expect(summary.totalCount, 9);
    expect(summary.hasAttention, isTrue);
  });

  test(
    'attention summary repository keeps danger warning timeline counts',
    () async {
      final repository = AttentionSummaryRepository(
        homeRepository: _FakeHomeAttentionSource(
          dangerItems: [_itemEntry(id: 1, status: ItemStatus.danger)],
          warningItems: [
            _itemEntry(id: 2, status: ItemStatus.warning),
            _itemEntry(id: 3, status: ItemStatus.warning),
          ],
          timelineMilestones: [
            _occurrence(id: 1),
            _occurrence(id: 2),
            _occurrence(id: 3),
          ],
        ),
      );

      final summary = await repository.getSummary(now: DateTime(2026, 5, 1));

      expect(summary.dangerCount, 1);
      expect(summary.warningCount, 2);
      expect(summary.timelineUpcomingCount, 3);
      expect(summary.totalCount, 6);
    },
  );

  test('totalCount == 0 cancels notification and clears badge', () async {
    final notificationClient = _FakeNotificationClient();
    final badgeClient = _FakeBadgeClient();
    final service = AttentionSyncService(
      repository: AttentionSummaryRepository(
        homeRepository: const _FakeHomeAttentionSource(),
      ),
      notificationService: ReminderNotificationService(
        client: notificationClient,
        timeZoneResolver: const _FakeTimeZoneResolver('Etc/UTC'),
        clock: () => DateTime.utc(2026, 5, 1, 8, 0),
      ),
      badgeService: AppBadgeService(client: badgeClient),
    );

    await service.initialize(onOpenHome: () {});
    await service.syncSummary(
      const AttentionSummary(
        dangerCount: 0,
        warningCount: 0,
        timelineUpcomingCount: 0,
      ),
    );

    expect(notificationClient.cancelledIds, [
      ReminderNotificationService.attentionNotificationId,
    ]);
    expect(notificationClient.scheduled, isEmpty);
    expect(badgeClient.updatedCounts, [0]);
  });

  test(
    'totalCount > 0 schedules next 09:00 notification and updates badge',
    () async {
      final notificationClient = _FakeNotificationClient();
      final badgeClient = _FakeBadgeClient();
      final service = AttentionSyncService(
        repository: AttentionSummaryRepository(
          homeRepository: const _FakeHomeAttentionSource(),
        ),
        notificationService: ReminderNotificationService(
          client: notificationClient,
          timeZoneResolver: const _FakeTimeZoneResolver('Etc/UTC'),
          clock: () => DateTime.utc(2026, 5, 1, 10, 30),
        ),
        badgeService: AppBadgeService(client: badgeClient),
      );

      await service.initialize(onOpenHome: () {});
      await service.syncSummary(
        const AttentionSummary(
          dangerCount: 2,
          warningCount: 1,
          timelineUpcomingCount: 3,
        ),
      );

      expect(notificationClient.cancelledIds, isEmpty);
      expect(notificationClient.scheduled, hasLength(1));
      expect(notificationClient.scheduled.single.id, 9001);
      expect(notificationClient.scheduled.single.title, '今天有 6 件事需要處理');
      expect(notificationClient.scheduled.single.body, '打開看看哪些事情需要留意');
      final scheduledDate = notificationClient.scheduled.single.scheduledDate;
      expect(scheduledDate.year, 2026);
      expect(scheduledDate.month, 5);
      expect(scheduledDate.day, 2);
      expect(scheduledDate.hour, 9);
      expect(scheduledDate.minute, 0);
      expect(badgeClient.updatedCounts, [6]);
    },
  );

  test(
    'attention implementation does not introduce Task legacy model names',
    () async {
      final directory = Directory('lib/features/reminders');
      final files = await directory
          .list(recursive: true)
          .where((entity) => entity is File && entity.path.endsWith('.dart'))
          .cast<File>()
          .toList();

      final forbidden = RegExp(
        r'\b(TaskTemplate|TaskInstance)\b|class\s+Task\b',
      );

      for (final file in files) {
        final content = await file.readAsString();
        expect(
          forbidden.hasMatch(content),
          isFalse,
          reason: 'legacy task naming found in ${file.path}',
        );
      }
    },
  );
}

class _FakeHomeAttentionSource implements HomeAttentionSource {
  const _FakeHomeAttentionSource({
    this.dangerItems = const [],
    this.warningItems = const [],
    this.timelineMilestones = const [],
  });

  final List<ItemHomeEntry> dangerItems;
  final List<ItemHomeEntry> warningItems;
  final List<TimelineMilestoneOccurrence> timelineMilestones;

  @override
  Stream<List<ItemHomeEntry>> watchDangerItems({DateTime? now}) {
    return Stream.value(dangerItems);
  }

  @override
  Stream<List<TimelineMilestoneOccurrence>> watchUpcomingTimelineMilestones({
    DateTime? now,
  }) {
    return Stream.value(timelineMilestones);
  }

  @override
  Stream<List<ItemHomeEntry>> watchWarningItems({DateTime? now}) {
    return Stream.value(warningItems);
  }
}

class _FakeNotificationClient implements ReminderNotificationClient {
  final List<int> cancelledIds = [];
  final List<_ScheduledNotification> scheduled = [];

  @override
  Future<void> cancel(int id) async {
    cancelledIds.add(id);
  }

  @override
  Future<void> initialize({required onDidReceiveNotificationResponse}) async {}

  @override
  Future<void> requestPermissions() async {}

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

class _FakeBadgeClient implements AppBadgeClient {
  final bool supported = true;
  final List<int> updatedCounts = [];

  @override
  Future<bool> isSupported() async => supported;

  @override
  Future<void> updateBadge(int count) async {
    updatedCounts.add(count);
  }
}

class _FakeTimeZoneResolver implements LocalTimeZoneResolver {
  const _FakeTimeZoneResolver(this.timeZoneName);

  final String timeZoneName;

  @override
  Future<String?> getLocalTimeZoneName() async => timeZoneName;
}

ItemHomeEntry _itemEntry({required int id, required ItemStatus status}) {
  return ItemHomeEntry(
    bundle: ItemBundle(
      item: Item(
        id: id,
        packId: 1,
        title: 'Item $id',
        type: ItemType.stateBased,
        config: StateBasedItemConfig(
          anchorDate: DateTime(2026, 4, 1),
          infoAfter: Duration.zero,
          warningAfter: const Duration(days: 1),
          dangerAfter: const Duration(days: 2),
        ),
        createdAt: DateTime(2026, 4, 1),
        updatedAt: DateTime(2026, 4, 1),
      ),
      pack: ItemPack(
        id: 1,
        title: 'Pack',
        status: ItemPackStatus.active,
        isSystemDefault: true,
        createdAt: DateTime(2026, 4, 1),
        updatedAt: DateTime(2026, 4, 1),
      ),
    ),
    status: status,
    elapsed: const Duration(days: 3),
  );
}

TimelineMilestoneOccurrence _occurrence({required int id}) {
  return TimelineMilestoneOccurrence(
    timelineId: 1,
    timelineTitle: 'Timeline',
    ruleId: id,
    occurrenceIndex: id,
    targetDate: DateTime(2026, 5, id),
    label: 'Milestone $id',
    status: TimelineMilestoneRecordStatus.upcoming,
    reminderOffsetDays: 3,
  );
}
