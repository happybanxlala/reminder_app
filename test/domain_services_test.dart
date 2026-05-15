import 'package:flutter_test/flutter_test.dart';
import 'package:reminder_app/features/reminders/domain/item.dart';
import 'package:reminder_app/features/reminders/domain/item_status_service.dart';
import 'package:reminder_app/features/reminders/domain/resource.dart';
import 'package:reminder_app/features/reminders/domain/resource_status_service.dart';
import 'package:reminder_app/features/reminders/domain/stage_occurrence_service.dart';
import 'package:reminder_app/features/reminders/domain/stage_record.dart';
import 'package:reminder_app/features/reminders/domain/stage_rule.dart';
import 'package:reminder_app/features/reminders/domain/stage_tracker.dart';

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

  test('fixed every X days advances by configured interval', () {
    const service = ItemStatusService();
    final cycle = service.resolveFixedCycle(
      FixedItemConfig(
        scheduleType: FixedScheduleType.everyXDays,
        scheduleInterval: 3,
        anchorDate: DateTime(2026, 4, 1),
        dueDate: DateTime(2026, 4, 3),
        overduePolicy: ItemOverduePolicy.autoAdvance,
      ),
      now: DateTime(2026, 4, 5),
    );

    expect(cycle, isNotNull);
    expect(cycle!.anchorDate, DateTime(2026, 4, 4));
    expect(cycle.dueDate, DateTime(2026, 4, 6));
  });

  test('fixed monthly schedule clamps missing day to month end', () {
    const service = ItemStatusService();
    final cycle = service.resolveFixedCycle(
      FixedItemConfig(
        scheduleType: FixedScheduleType.monthly,
        monthlyDay: 31,
        anchorDate: DateTime(2026, 1, 31),
        dueDate: DateTime(2026, 1, 31),
        overduePolicy: ItemOverduePolicy.autoAdvance,
      ),
      now: DateTime(2026, 2, 15),
    );

    expect(cycle, isNotNull);
    expect(cycle!.anchorDate, DateTime(2026, 2, 28));
    expect(cycle.dueDate, DateTime(2026, 2, 28));
  });

  test('fixed waitForAction does not auto-advance every X weeks', () {
    const service = ItemStatusService();
    final item = Item(
      id: 12,
      packId: 1,
      title: 'Refill feeder',
      type: ItemType.fixed,
      config: FixedItemConfig(
        scheduleType: FixedScheduleType.everyXWeeks,
        scheduleInterval: 2,
        anchorDate: DateTime(2026, 4, 1),
        dueDate: DateTime(2026, 4, 14),
        overduePolicy: ItemOverduePolicy.waitForAction,
      ),
      createdAt: DateTime(2026, 4, 1),
      updatedAt: DateTime(2026, 4, 1),
    );

    expect(
      service.classify(item, now: DateTime(2026, 4, 20)),
      ItemStatus.danger,
    );
    expect(
      service.currentFixedCycle(item, now: DateTime(2026, 4, 20))!.dueDate,
      DateTime(2026, 4, 14),
    );
  });

  test('resource status service classifies time-based resources', () {
    const service = ResourceStatusService();
    final config = TimeBasedResourceConfig(
      anchorDate: DateTime(2026, 4, 1),
      durationDays: 5,
      warningBeforeDays: 2,
      dangerBeforeDays: 1,
    );

    expect(
      service.classifyTimeBased(config, now: DateTime(2026, 4, 1)),
      ResourceStatus.normal,
    );
    expect(
      service.classifyTimeBased(config, now: DateTime(2026, 4, 3)),
      ResourceStatus.warning,
    );
    expect(
      service.classifyTimeBased(config, now: DateTime(2026, 4, 4)),
      ResourceStatus.danger,
    );
    expect(
      service.classifyTimeBased(config, now: DateTime(2026, 4, 5)),
      ResourceStatus.danger,
    );
  });

  test('resource status service classifies quantity-based resources', () {
    const service = ResourceStatusService();

    expect(
      service.classifyQuantityBased(
        const QuantityBasedResourceConfig(
          currentQuantity: 5,
          unitLabel: '個',
          warningThreshold: 2,
          dangerThreshold: 1,
        ),
      ),
      ResourceStatus.normal,
    );
    expect(
      service.classifyQuantityBased(
        const QuantityBasedResourceConfig(
          currentQuantity: 2,
          unitLabel: '個',
          warningThreshold: 2,
          dangerThreshold: 1,
        ),
      ),
      ResourceStatus.warning,
    );
    expect(
      service.classifyQuantityBased(
        const QuantityBasedResourceConfig(
          currentQuantity: 1,
          unitLabel: '個',
          warningThreshold: 2,
          dangerThreshold: 1,
        ),
      ),
      ResourceStatus.danger,
    );
  });

  test('stage occurrence service computes upcoming dynamically', () {
    const service = StageOccurrenceService();
    final tracker = StageTracker(
      id: 1,
      packId: 1,
      title: 'Dating',
      trackingStartDate: DateTime(2026, 4, 10),
      status: StageTrackerStatus.active,
      createdAt: DateTime(2026, 4, 10),
      updatedAt: DateTime(2026, 4, 10),
    );
    final rule = StageRule(
      id: 11,
      stageTrackerId: 1,
      type: StageRuleType.everyNDays,
      intervalValue: 7,
      intervalUnit: StageIntervalUnit.days,
      labelTemplate: '滿 {value}{unit}',
      reminderOffsetDays: 2,
      status: StageRuleStatus.active,
      createdAt: DateTime(2026, 4, 10),
      updatedAt: DateTime(2026, 4, 10),
    );

    final upcoming = service.getHomeAttentionOccurrences(
      tracker,
      [rule],
      const [],
      StageOccurrenceRange(
        start: DateTime(2026, 4, 15),
        end: DateTime(2026, 4, 20),
      ),
      now: DateTime(2026, 4, 15),
    );

    expect(upcoming, hasLength(1));
    expect(upcoming.single.occurrenceDate, DateTime(2026, 4, 17));
    expect(upcoming.single.label, '滿 7天');
  });

  test(
    'stage occurrence service hides ignored but keeps acknowledged outside home',
    () {
      const service = StageOccurrenceService();
      final tracker = StageTracker(
        id: 1,
        packId: 1,
        title: 'Reading',
        trackingStartDate: DateTime(2026, 4, 10),
        status: StageTrackerStatus.active,
        createdAt: DateTime(2026, 4, 10),
        updatedAt: DateTime(2026, 4, 10),
      );
      final rule = StageRule(
        id: 11,
        stageTrackerId: 1,
        type: StageRuleType.everyNDays,
        intervalValue: 10,
        intervalUnit: StageIntervalUnit.days,
        labelTemplate: '滿 {value}{unit}',
        reminderOffsetDays: 0,
        status: StageRuleStatus.active,
        createdAt: DateTime(2026, 4, 1),
        updatedAt: DateTime(2026, 4, 1),
      );
      final record = StageRecord(
        id: 1,
        stageTrackerId: 1,
        stageRuleId: 11,
        sourceType: StageRecordSourceType.generated,
        occurrenceIndex: 1,
        occurrenceDate: DateTime(2026, 4, 20),
        status: StageRecordStatus.acknowledged,
        label: '滿 10天',
        createdAt: DateTime(2026, 4, 19),
        updatedAt: DateTime(2026, 4, 19),
      );

      final schedule = service.mergeOccurrencesWithRecords(
        tracker,
        [rule],
        [record],
        StageOccurrenceRange(
          start: DateTime(2026, 4, 18),
          end: DateTime(2026, 4, 21),
        ),
      );
      final home = service.getHomeAttentionOccurrences(
        tracker,
        [rule],
        [record],
        StageOccurrenceRange(
          start: DateTime(2026, 4, 18),
          end: DateTime(2026, 4, 21),
        ),
        now: DateTime(2026, 4, 20),
      );

      expect(schedule, hasLength(1));
      expect(schedule.single.recordStatus, StageRecordStatus.acknowledged);
      expect(home, isEmpty);
    },
  );
}
