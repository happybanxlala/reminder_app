import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reminder_app/features/reminders/data/local/app_database.dart';
import 'package:reminder_app/features/reminders/data/stage_tracker_models.dart';
import 'package:reminder_app/features/reminders/data/stage_tracker_repository.dart';
import 'package:reminder_app/features/reminders/domain/stage_record.dart';
import 'package:reminder_app/features/reminders/domain/stage_rule.dart';

void main() {
  test(
    'stage schedule respects end date and shows multiple generated stages',
    () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);
      final repository = StageTrackerRepository(
        db.reminderDao,
        clock: () => DateTime(2026, 5, 1),
      );

      final trackerId = await repository.createStageTracker(
        StageTrackerInput(
          title: '寶寶成長',
          trackingStartDate: DateTime(2026, 5),
          trackingEndDate: DateTime(2026, 5, 4),
        ),
      );
      await repository.createStageRule(
        trackerId,
        const StageRuleInput(
          type: StageRuleType.everyNDays,
          intervalValue: 1,
          intervalUnit: StageIntervalUnit.days,
        ),
      );

      final detail = await repository.getStageTrackerDetailById(
        trackerId,
        now: DateTime(2026, 5, 1),
      );

      expect(detail!.scheduleStages.map((item) => item.occurrenceDate), [
        DateTime(2026, 5, 2),
        DateTime(2026, 5, 3),
        DateTime(2026, 5, 4),
      ]);
    },
  );

  test(
    'ignored is hidden everywhere but acknowledged remains in schedule',
    () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);
      final repository = StageTrackerRepository(
        db.reminderDao,
        clock: () => DateTime(2026, 5, 1),
      );
      final trackerId = await repository.createStageTracker(
        StageTrackerInput(title: '寶寶成長', trackingStartDate: DateTime(2026, 5)),
      );
      await repository.createStageRule(
        trackerId,
        const StageRuleInput(
          type: StageRuleType.everyNDays,
          intervalValue: 1,
          intervalUnit: StageIntervalUnit.days,
        ),
      );

      var detail = await repository.getStageTrackerDetailById(
        trackerId,
        now: DateTime(2026, 5, 1),
      );
      await repository.acknowledgeOccurrence(detail!.scheduleStages.first);
      detail = await repository.getStageTrackerDetailById(
        trackerId,
        now: DateTime(2026, 5, 1),
      );
      expect(
        detail!.scheduleStages.first.recordStatus,
        StageRecordStatus.acknowledged,
      );
      expect(
        repository.computeHomeAttentionOccurrences(
          trackers: [detail.stageTracker],
          rules: detail.stageRules,
          records: detail.stageRecords,
          now: DateTime(2026, 5, 2),
        ),
        isEmpty,
      );

      await repository.ignoreOccurrence(detail.scheduleStages.first);
      detail = await repository.getStageTrackerDetailById(
        trackerId,
        now: DateTime(2026, 5, 1),
      );
      expect(
        detail!.scheduleStages.any(
          (item) => item.occurrenceDate == DateTime(2026, 5, 2),
        ),
        isFalse,
      );
    },
  );

  test('related item from generated stage creates StageRecord first', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final repository = StageTrackerRepository(
      db.reminderDao,
      clock: () => DateTime(2026, 5, 1),
    );
    final trackerId = await repository.createStageTracker(
      StageTrackerInput(title: '寶寶成長', trackingStartDate: DateTime(2026, 5)),
    );
    await repository.createStageRule(
      trackerId,
      const StageRuleInput(
        type: StageRuleType.everyNMonths,
        intervalValue: 1,
        intervalUnit: StageIntervalUnit.months,
      ),
    );
    final detail = await repository.getStageTrackerDetailById(
      trackerId,
      now: DateTime(2026, 5, 1),
    );

    final itemId = await repository.createRelatedItemFromOccurrence(
      detail!.scheduleStages.first,
      title: '準備副食品',
    );
    final stageRecords = await db.select(db.stageRecords).get();
    final links = await db.select(db.stageRelatedItems).get();

    expect(itemId, greaterThan(0));
    expect(stageRecords, hasLength(1));
    expect(
      stageRecords.single.sourceType,
      StageRecordSourceType.generated.name,
    );
    expect(links.single.stageRecordId, stageRecords.single.id);
    expect(links.single.itemId, itemId);
  });
}
