import 'package:flutter_test/flutter_test.dart';
import 'package:reminder_app/features/reminders/domain/item.dart';
import 'package:reminder_app/features/reminders/domain/item_status_service.dart';
import 'package:reminder_app/features/reminders/domain/timeline.dart';
import 'package:reminder_app/features/reminders/domain/timeline_calculator.dart';
import 'package:reminder_app/features/reminders/domain/timeline_milestone_record.dart';
import 'package:reminder_app/features/reminders/domain/timeline_milestone_rule.dart';
import 'package:reminder_app/features/reminders/domain/timeline_milestone_service.dart';

void main() {
  test('item status service classifies state-based items', () {
    const service = ItemStatusService();
    final item = Item(
      id: 1,
      packId: 1,
      title: 'Trash',
      type: ItemType.stateBased,
      config: StateBasedItemConfig(
        anchorDate: DateTime(2026, 4, 1),
        infoAfter: Duration(days: 7),
        warningAfter: Duration(days: 7),
        dangerAfter: Duration(days: 14),
      ),
      createdAt: DateTime(2026, 4, 1),
      updatedAt: DateTime(2026, 4, 1),
    );

    expect(
      service.classify(item, now: DateTime(2026, 4, 5)),
      ItemStatus.normal,
    );
    expect(
      service.classify(item, now: DateTime(2026, 4, 10)),
      ItemStatus.warning,
    );
    expect(
      service.classify(item, now: DateTime(2026, 4, 16)),
      ItemStatus.danger,
    );
  });

  test('state-based items use anchor date as initial baseline', () {
    const service = ItemStatusService();
    final item = Item(
      id: 10,
      packId: 1,
      title: 'Replace filter',
      type: ItemType.stateBased,
      config: StateBasedItemConfig(
        anchorDate: DateTime(2026, 4, 1),
        infoAfter: const Duration(days: 7),
        warningAfter: const Duration(days: 7),
        dangerAfter: const Duration(days: 14),
      ),
      createdAt: DateTime(2026, 4, 1),
      updatedAt: DateTime(2026, 4, 1),
    );

    expect(
      service.classify(item, now: DateTime(2026, 4, 5)),
      ItemStatus.normal,
    );
  });

  test(
    'state-based warning and danger boundaries are inclusive by day index',
    () {
      const service = ItemStatusService();
      final item = Item(
        id: 11,
        packId: 1,
        title: 'Replace filter',
        type: ItemType.stateBased,
        config: StateBasedItemConfig(
          anchorDate: DateTime(2026, 4, 1),
          infoAfter: Duration.zero,
          warningAfter: Duration(days: 4),
          dangerAfter: Duration(days: 10),
        ),
        createdAt: DateTime(2026, 4, 1),
        updatedAt: DateTime(2026, 4, 1),
      );

      expect(
        service.classify(item, now: DateTime(2026, 4, 3)),
        ItemStatus.normal,
      );
      expect(
        service.classify(item, now: DateTime(2026, 4, 4)),
        ItemStatus.warning,
      );
      expect(
        service.classify(item, now: DateTime(2026, 4, 10)),
        ItemStatus.danger,
      );
    },
  );

  test('fixed auto-advance resolves preview cycle to next round', () {
    const service = ItemStatusService();
    final cycle = service.resolveFixedCycle(
      FixedItemConfig(
        scheduleType: FixedScheduleType.daily,
        anchorDate: DateTime(2026, 4, 1),
        dueDate: DateTime(2026, 4, 1),
        overduePolicy: ItemOverduePolicy.autoAdvance,
      ),
      now: DateTime(2026, 4, 3),
    );

    expect(cycle, isNotNull);
    expect(cycle!.anchorDate, DateTime(2026, 4, 3));
    expect(cycle.dueDate, DateTime(2026, 4, 3));
    expect(cycle.isVirtualAdvance, isTrue);
  });

  test('item status service classifies resource-based items', () {
    const service = ItemStatusService();
    final item = Item(
      id: 2,
      packId: 1,
      title: 'Cat food',
      type: ItemType.resourceBased,
      config: ResourceBasedItemConfig(
        anchorDate: DateTime(2026, 4, 1),
        durationDays: 30,
        warningBefore: 7,
      ),
      lastDoneAt: DateTime(2026, 4, 1),
      createdAt: DateTime(2026, 4, 1),
      updatedAt: DateTime(2026, 4, 1),
    );

    expect(
      service.classify(item, now: DateTime(2026, 4, 20)),
      ItemStatus.normal,
    );
    expect(
      service.classify(item, now: DateTime(2026, 4, 25)),
      ItemStatus.warning,
    );
    expect(
      service.classify(item, now: DateTime(2026, 5, 2)),
      ItemStatus.danger,
    );
  });

  test('resource-based depletion day is already danger', () {
    const service = ItemStatusService();
    final item = Item(
      id: 3,
      packId: 1,
      title: 'Cat food',
      type: ItemType.resourceBased,
      config: ResourceBasedItemConfig(
        anchorDate: DateTime(2026, 4, 1),
        durationDays: 5,
      ),
      createdAt: DateTime(2026, 4, 1),
      updatedAt: DateTime(2026, 4, 1),
    );

    expect(
      service.classify(item, now: DateTime(2026, 4, 5)),
      ItemStatus.danger,
    );
  });

  test('timeline calculator returns display value', () {
    const calculator = TimelineCalculator();
    final timeline = Timeline(
      id: 1,
      title: 'Dating',
      startDate: DateTime(2026, 4, 10),
      displayUnit: TimelineDisplayUnit.day,
      status: TimelineStatus.active,
      createdAt: DateTime(2026, 4, 10),
      updatedAt: DateTime(2026, 4, 10),
    );

    expect(calculator.displayValue(timeline, DateTime(2026, 4, 12)), 3);
  });

  test(
    'timeline milestone service computes today and upcoming dynamically',
    () {
      const service = TimelineMilestoneService();
      final timeline = Timeline(
        id: 1,
        title: 'Dating',
        startDate: DateTime(2026, 4, 10),
        displayUnit: TimelineDisplayUnit.day,
        status: TimelineStatus.active,
        createdAt: DateTime(2026, 4, 10),
        updatedAt: DateTime(2026, 4, 10),
      );
      final rule = TimelineMilestoneRule(
        id: 11,
        timelineId: 1,
        type: TimelineMilestoneRuleType.everyNDays,
        intervalValue: 7,
        intervalUnit: TimelineMilestoneIntervalUnit.days,
        labelTemplate: '第 {value}{unit}',
        reminderOffsetDays: 2,
        status: TimelineMilestoneRuleStatus.active,
        createdAt: DateTime(2026, 4, 10),
        updatedAt: DateTime(2026, 4, 10),
      );

      final upcoming = service.getUpcomingOccurrences(
        timeline,
        [rule],
        const [],
        TimelineMilestoneRange(
          start: DateTime(2026, 4, 15),
          end: DateTime(2026, 4, 20),
        ),
        now: DateTime(2026, 4, 15),
      );
      final today = service.getTodayOccurrences(
        timeline,
        [rule],
        const [],
        now: DateTime(2026, 4, 16),
      );

      expect(upcoming, hasLength(1));
      expect(upcoming.single.targetDate, DateTime(2026, 4, 16));
      expect(upcoming.single.label, '第 7天');
      expect(today, hasLength(1));
      expect(today.single.occurrenceIndex, 1);
      expect(today.single.label, '第 7天');
    },
  );

  test(
    'timeline milestone service merges persisted records into occurrences',
    () {
      const service = TimelineMilestoneService();
      final timeline = Timeline(
        id: 1,
        title: 'Reading',
        startDate: DateTime(2026, 4, 10),
        displayUnit: TimelineDisplayUnit.day,
        status: TimelineStatus.active,
        createdAt: DateTime(2026, 4, 10),
        updatedAt: DateTime(2026, 4, 10),
      );
      final rule = TimelineMilestoneRule(
        id: 11,
        timelineId: 1,
        type: TimelineMilestoneRuleType.everyNDays,
        intervalValue: 10,
        intervalUnit: TimelineMilestoneIntervalUnit.days,
        labelTemplate: '第 {value}{unit}',
        reminderOffsetDays: 0,
        status: TimelineMilestoneRuleStatus.active,
        createdAt: DateTime(2026, 4, 1),
        updatedAt: DateTime(2026, 4, 1),
      );
      final record = TimelineMilestoneRecord(
        id: 1,
        timelineId: 1,
        ruleId: 11,
        occurrenceIndex: 1,
        targetDate: DateTime(2026, 4, 19),
        status: TimelineMilestoneRecordStatus.noticed,
        actedAt: DateTime(2026, 4, 19),
        createdAt: DateTime(2026, 4, 19),
        updatedAt: DateTime(2026, 4, 19),
      );

      final occurrences = service.mergeOccurrencesWithRecords(
        timeline,
        [rule],
        [record],
        TimelineMilestoneRange(
          start: DateTime(2026, 4, 18),
          end: DateTime(2026, 4, 21),
        ),
      );

      expect(occurrences, hasLength(1));
      expect(occurrences.single.status, TimelineMilestoneRecordStatus.noticed);
    },
  );
}
