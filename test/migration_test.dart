import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reminder_app/features/reminders/data/local/app_database.dart';

void main() {
  test(
    'database uses new schema version and new tables are writable',
    () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);

      expect(db.schemaVersion, 6);

      final templateId = await db
          .into(db.taskTemplates)
          .insert(
            TaskTemplatesCompanion.insert(
              title: 'Schema smoke test',
              kind: 'oneTime',
              status: 'active',
              firstDueDate: DateTime(2026, 4, 10).millisecondsSinceEpoch,
              reminderRule: 'onDue',
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
              milestoneReminderRule: 'onDay',
              createdAt: DateTime(2026, 4, 1).millisecondsSinceEpoch,
              updatedAt: DateTime(2026, 4, 1).millisecondsSinceEpoch,
            ),
          );

      expect(templateId, greaterThan(0));
      expect(timelineId, greaterThan(0));
    },
  );
}
