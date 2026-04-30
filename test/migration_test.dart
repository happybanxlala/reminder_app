import 'package:drift/native.dart';
import 'package:drift/drift.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reminder_app/features/reminders/data/local/app_database.dart';

void main() {
  test(
    'database uses clean drift schema version 1 and core tables are writable',
    () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);

      expect(db.schemaVersion, 1);

      final packId = await db
          .into(db.itemPacks)
          .insert(
            ItemPacksCompanion.insert(
              title: 'Cats',
              description: const Value('Cat care'),
              status: const Value('active'),
              isSystemDefault: const Value(false),
              createdAt: DateTime(2026, 4, 1).millisecondsSinceEpoch,
              updatedAt: DateTime(2026, 4, 1).millisecondsSinceEpoch,
            ),
          );

      final itemId = await db
          .into(db.items)
          .insert(
            ItemsCompanion.insert(
              packId: packId,
              title: 'Clean litter box',
              description: const Value('State based'),
              type: 'stateBased',
              fixedScheduleType: const Value.absent(),
              fixedAnchorDate: const Value.absent(),
              fixedDueDate: const Value.absent(),
              fixedTimeOfDay: const Value.absent(),
              fixedOverduePolicy: const Value.absent(),
              fixedExpectedBeforeMinutes: const Value.absent(),
              fixedWarningBeforeMinutes: const Value.absent(),
              fixedDangerBeforeMinutes: const Value.absent(),
              stateAnchorDate: const Value.absent(),
              stateExpectedAfterMinutes: const Value(2880),
              stateWarningAfterMinutes: const Value(2880),
              stateDangerAfterMinutes: const Value(5760),
              resourceAnchorDate: const Value.absent(),
              resourceDurationDays: const Value.absent(),
              resourceExpectedBeforeDays: const Value.absent(),
              resourceWarningBeforeDays: const Value.absent(),
              resourceDangerBeforeDays: const Value.absent(),
              lastDoneAt: const Value.absent(),
              createdAt: DateTime(2026, 4, 1).millisecondsSinceEpoch,
              updatedAt: DateTime(2026, 4, 1).millisecondsSinceEpoch,
            ),
          );

      final timelineId = await db
          .into(db.timelines)
          .insert(
            TimelinesCompanion.insert(
              title: 'Timeline smoke test',
              startDate: DateTime(2026, 4, 10).millisecondsSinceEpoch,
              displayUnit: 'day',
              status: 'active',
              createdAt: DateTime(2026, 4, 1).millisecondsSinceEpoch,
              updatedAt: DateTime(2026, 4, 1).millisecondsSinceEpoch,
            ),
          );

      final ruleId = await db
          .into(db.timelineMilestoneRules)
          .insert(
            TimelineMilestoneRulesCompanion.insert(
              timelineId: timelineId,
              type: 'every_n_days',
              intervalValue: 1,
              intervalUnit: 'days',
              labelTemplate: const Value('第 {value}{unit}'),
              reminderOffsetDays: const Value(0),
              status: const Value('active'),
              createdAt: DateTime(2026, 4, 1).millisecondsSinceEpoch,
              updatedAt: DateTime(2026, 4, 1).millisecondsSinceEpoch,
            ),
          );

      final recordId = await db
          .into(db.timelineMilestoneRecords)
          .insert(
            TimelineMilestoneRecordsCompanion.insert(
              timelineId: timelineId,
              ruleId: ruleId,
              occurrenceIndex: 1,
              targetDate: DateTime(2026, 4, 10).millisecondsSinceEpoch,
              status: 'noticed',
              actedAt: Value(DateTime(2026, 4, 10).millisecondsSinceEpoch),
              createdAt: DateTime(2026, 4, 1).millisecondsSinceEpoch,
              updatedAt: DateTime(2026, 4, 1).millisecondsSinceEpoch,
            ),
          );

      expect(packId, greaterThan(0));
      expect(itemId, greaterThan(0));
      expect(timelineId, greaterThan(0));
      expect(ruleId, greaterThan(0));
      expect(recordId, greaterThan(0));

      final defaultPacks = await (db.select(
        db.itemPacks,
      )..where((t) => t.isSystemDefault.equals(true))).get();
      final items = await db.select(db.items).get();
      expect(defaultPacks, hasLength(1));
      expect(items.single.status, 'active');
    },
  );
}
