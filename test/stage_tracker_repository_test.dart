import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reminder_app/features/reminders/data/item_repository.dart';
import 'package:reminder_app/features/reminders/data/local/app_database.dart';
import 'package:reminder_app/features/reminders/data/stage_tracker_models.dart';
import 'package:reminder_app/features/reminders/data/stage_tracker_repository.dart';
import 'package:reminder_app/features/reminders/domain/stage_record.dart';
import 'package:reminder_app/features/reminders/domain/stage_rule.dart';
import 'package:reminder_app/features/reminders/domain/stage_tracker.dart';

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

  test('createStageRule does not materialize StageRecord', () async {
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
        intervalValue: 30,
        intervalUnit: StageIntervalUnit.days,
      ),
    );

    final stageRecords = await db.select(db.stageRecords).get();
    final detail = await repository.getStageTrackerDetailById(
      trackerId,
      now: DateTime(2026, 5, 1),
    );

    expect(stageRecords, isEmpty);
    expect(detail!.stageRules, hasLength(1));
    expect(detail.dashboardUpcomingStages, hasLength(1));
    expect(detail.dashboardUpcomingStages.single.stageRecordId, isNull);
  });

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
    expect(stageRecords.single.stageRuleId, detail.stageRules.single.id);
    expect(
      stageRecords.single.occurrenceIndex,
      detail.scheduleStages.first.occurrenceIndex,
    );
    expect(links.single.stageRecordId, stageRecords.single.id);
    expect(links.single.itemId, itemId);
  });

  test(
    'related item entries exclude archived items and expose action flags',
    () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);
      final itemRepository = ItemRepository(db.reminderDao);
      final repository = StageTrackerRepository(
        db.reminderDao,
        itemRepository: itemRepository,
        clock: () => DateTime(2026, 5, 1),
      );
      final trackerId = await repository.createStageTracker(
        StageTrackerInput(title: '寶寶成長', trackingStartDate: DateTime(2026, 5)),
      );
      final stageRecordId = await repository.createImportantStage(
        trackerId,
        ManualStageInput(label: '回診', occurrenceDate: DateTime(2026, 6, 1)),
      );
      final detail = await repository.getStageTrackerDetailById(
        trackerId,
        now: DateTime(2026, 5, 1),
      );
      final occurrence = detail!.dashboardUpcomingStages.firstWhere(
        (item) => item.stageRecordId == stageRecordId,
      );

      final doneId = await repository.createRelatedItemFromOccurrence(
        occurrence,
        title: '準備針卡',
      );
      final skippedId = await repository.createRelatedItemFromOccurrence(
        occurrence,
        title: '買補品',
      );
      final archivedId = await repository.createRelatedItemFromOccurrence(
        occurrence,
        title: '已封存提醒',
      );
      await itemRepository.markDone(doneId, doneAt: DateTime(2026, 5, 1));
      await itemRepository.skip(skippedId, actionAt: DateTime(2026, 5, 1));
      await itemRepository.archiveItem(archivedId);

      final entries = await repository.getRelatedItemEntriesForStageRecord(
        stageRecordId,
      );

      expect(entries.map((entry) => entry.bundle.item.title), ['準備針卡', '買補品']);
      expect(entries.first.hasDoneAction, isTrue);
      expect(entries.first.hasSkippedAction, isFalse);
      expect(entries.last.hasDoneAction, isFalse);
      expect(entries.last.hasSkippedAction, isTrue);
    },
  );

  test(
    'updateStageTracker updates editable fields and preserves rules and status',
    () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);
      final repository = StageTrackerRepository(
        db.reminderDao,
        clock: () => DateTime(2026, 5, 21),
      );
      final trackerId = await repository.createStageTracker(
        StageTrackerInput(title: '寶寶成長', trackingStartDate: DateTime(2026, 5)),
      );
      await repository.createStageRule(
        trackerId,
        const StageRuleInput(
          type: StageRuleType.everyNDays,
          intervalValue: 7,
          intervalUnit: StageIntervalUnit.days,
        ),
      );
      await repository.createImportantStage(
        trackerId,
        ManualStageInput(label: '回診', occurrenceDate: DateTime(2026, 5, 30)),
      );

      final updated = await repository.updateStageTracker(
        trackerId,
        StageTrackerInput(
          title: '成長追蹤',
          subjectName: '小米',
          trackingStartDate: DateTime(2026, 4, 30, 12),
          trackingEndDate: DateTime(2026, 12, 31, 12),
        ),
      );
      final detail = await repository.getStageTrackerDetailById(trackerId);

      expect(updated, isTrue);
      expect(detail!.stageTracker.title, '成長追蹤');
      expect(detail.stageTracker.subjectName, '小米');
      expect(detail.stageTracker.trackingStartDate, DateTime(2026, 4, 30));
      expect(detail.stageTracker.trackingEndDate, DateTime(2026, 12, 31));
      expect(detail.stageTracker.status, StageTrackerStatus.active);
      expect(detail.stageRules, hasLength(1));
      expect(detail.stageRecords, hasLength(1));

      await repository.archiveStageTracker(trackerId);
      expect(
        await repository.updateStageTracker(
          trackerId,
          StageTrackerInput(
            title: '不可更新',
            trackingStartDate: DateTime(2026, 1, 1),
          ),
        ),
        isFalse,
      );
      expect(
        await repository.updateStageTracker(
          999,
          StageTrackerInput(
            title: '不存在',
            trackingStartDate: DateTime(2026, 1, 1),
          ),
        ),
        isFalse,
      );
    },
  );

  test(
    'updateStageRule edits fields and status affects visible detail',
    () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);
      final repository = StageTrackerRepository(
        db.reminderDao,
        clock: () => DateTime(2026, 5, 21),
      );
      final trackerId = await repository.createStageTracker(
        StageTrackerInput(title: '寶寶成長', trackingStartDate: DateTime(2026, 5)),
      );
      final ruleId = await repository.createStageRule(
        trackerId,
        const StageRuleInput(
          type: StageRuleType.everyNDays,
          intervalValue: 7,
          intervalUnit: StageIntervalUnit.days,
        ),
      );

      expect(
        await repository.updateStageRule(
          ruleId,
          const StageRuleInput(
            type: StageRuleType.everyNWeeks,
            intervalValue: 2,
            intervalUnit: StageIntervalUnit.weeks,
            labelTemplate: '第 {value} 週',
            reminderOffsetDays: 3,
          ),
        ),
        isTrue,
      );
      var detail = await repository.getStageTrackerDetailById(trackerId);
      expect(detail!.stageRules.single.intervalValue, 2);
      expect(detail.stageRules.single.intervalUnit, StageIntervalUnit.weeks);
      expect(detail.stageRules.single.labelTemplate, '第 {value} 週');
      expect(detail.stageRules.single.reminderOffsetDays, 3);
      expect(detail.stageRules.single.status, StageRuleStatus.active);

      expect(
        await repository.updateStageRuleStatus(ruleId, StageRuleStatus.paused),
        isTrue,
      );
      detail = await repository.getStageTrackerDetailById(trackerId);
      expect(detail!.stageRules.single.status, StageRuleStatus.paused);

      expect(
        await repository.updateStageRuleStatus(ruleId, StageRuleStatus.active),
        isTrue,
      );
      detail = await repository.getStageTrackerDetailById(trackerId);
      expect(detail!.stageRules.single.status, StageRuleStatus.active);

      expect(
        await repository.updateStageRuleStatus(
          ruleId,
          StageRuleStatus.archived,
        ),
        isTrue,
      );
      detail = await repository.getStageTrackerDetailById(trackerId);
      expect(detail!.stageRules, isEmpty);
    },
  );

  test(
    'updateImportantStage only updates non-archived manual records',
    () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);
      final repository = StageTrackerRepository(
        db.reminderDao,
        clock: () => DateTime(2026, 5, 21),
      );
      final trackerId = await repository.createStageTracker(
        StageTrackerInput(title: '寶寶成長', trackingStartDate: DateTime(2026, 5)),
      );
      final manualId = await repository.createImportantStage(
        trackerId,
        ManualStageInput(
          label: '回診',
          occurrenceDate: DateTime(2026, 5, 20),
          note: '原備註',
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
        now: DateTime(2026, 5, 21),
      );
      await repository.acknowledgeOccurrence(detail!.scheduleStages.first);
      final generatedRecord = (await db.select(db.stageRecords).get())
          .singleWhere(
            (row) => row.sourceType == StageRecordSourceType.generated.name,
          );

      expect(
        await repository.updateImportantStage(
          manualId,
          ManualStageInput(
            label: '第一次回診',
            occurrenceDate: DateTime(2026, 5, 22),
            note: '更新備註',
            reminderOffsetDays: 2,
          ),
        ),
        isTrue,
      );
      var record = await db.reminderDao.getStageRecordById(manualId);
      expect(record!.label, '第一次回診');
      expect(record.occurrenceDate, DateTime(2026, 5, 22));
      expect(record.note, '更新備註');
      expect(record.reminderOffsetDays, 2);

      expect(
        await repository.updateImportantStage(
          generatedRecord.id,
          ManualStageInput(label: '不可更新', occurrenceDate: DateTime(2026)),
        ),
        isFalse,
      );

      await repository.deleteOrArchiveImportantStage(manualId);
      expect(
        await repository.updateImportantStage(
          manualId,
          ManualStageInput(label: '已封存', occurrenceDate: DateTime(2026)),
        ),
        isFalse,
      );
    },
  );
}
