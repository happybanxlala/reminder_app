import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reminder_app/features/reminders/data/local/app_database.dart';
import 'package:reminder_app/features/reminders/data/reminder_repository.dart';
import 'package:reminder_app/features/reminders/domain/milestone.dart';
import 'package:reminder_app/features/reminders/domain/milestone_reminder_rule.dart';
import 'package:reminder_app/features/reminders/domain/timeline.dart';

void main() {
  test(
    'timeline creates rule-based milestones and never produces overdue items',
    () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);
      final repository = TimelineRepository(db.reminderDao);

      await repository.createTimeline(
        TimelineInput(
          title: 'No sugar',
          startDate: DateTime(2026, 4, 10),
          displayUnit: TimelineDisplayUnit.day,
          milestoneReminderRule: const MilestoneReminderRule.onDay(),
        ),
      );

      final upcoming = await repository
          .watchUpcomingMilestones(now: DateTime(2026, 4, 9))
          .first;
      final history = await repository.watchMilestoneHistory().first;

      expect(upcoming, isNotEmpty);
      expect(history, isEmpty);
    },
  );

  test(
    'noticed and skipped milestones go to history without generating next milestone',
    () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);
      final repository = TimelineRepository(db.reminderDao);

      await repository.createTimeline(
        TimelineInput(
          title: 'Cat adoption',
          startDate: DateTime(2026, 4, 10),
          displayUnit: TimelineDisplayUnit.week,
          milestoneReminderRule: const MilestoneReminderRule.onDay(),
        ),
      );

      final milestone =
          (await repository
                  .watchTodayMilestones(now: DateTime(2026, 4, 10))
                  .first)
              .single;
      await repository.noticeMilestone(milestone.milestone.id);

      final history = await repository.watchMilestoneHistory().first;
      expect(history, hasLength(1));
      expect(history.single.milestone.status, MilestoneStatus.noticed);
    },
  );
}
