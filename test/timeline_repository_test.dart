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
          milestoneReminderRule: const MilestoneReminderRule.advance(1),
        ),
      );

      final upcoming = await repository
          .watchUpcomingMilestones(now: DateTime(2026, 4, 9))
          .first;
      final history = await repository.watchMilestoneHistory().first;

      expect(upcoming, hasLength(1));
      expect(history, isEmpty);
      expect(upcoming.single.milestone.targetDate, DateTime(2026, 4, 10));
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

  test(
    'timeline update keeps custom milestones and refreshes rule-based range',
    () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);
      final repository = TimelineRepository(db.reminderDao);

      final timelineId = await repository.createTimeline(
        TimelineInput(
          title: 'Sober',
          startDate: DateTime(2026, 4, 10),
          displayUnit: TimelineDisplayUnit.month,
          milestoneReminderRule: const MilestoneReminderRule.onDay(),
        ),
        customMilestones: [
          MilestoneInput(
            targetDate: DateTime(2026, 5, 1),
            description: '30 days',
            source: MilestoneSource.custom,
          ),
        ],
      );

      final detailBefore = await repository.getTimelineDetailById(timelineId);
      expect(detailBefore, isNotNull);
      expect(detailBefore!.customMilestones, hasLength(1));
      expect(detailBefore.ruleBasedMilestones, hasLength(12));

      await repository.updateTimeline(
        timelineId,
        TimelineInput(
          title: 'Sober',
          startDate: DateTime(2026, 4, 10),
          displayUnit: TimelineDisplayUnit.year,
          milestoneReminderRule: const MilestoneReminderRule.onDay(),
        ),
        customMilestones: [
          MilestoneInput(
            targetDate: DateTime(2026, 6, 1),
            description: '60 days',
            source: MilestoneSource.custom,
          ),
        ],
      );

      final detailAfter = await repository.getTimelineDetailById(timelineId);
      expect(detailAfter, isNotNull);
      expect(detailAfter!.customMilestones, hasLength(1));
      expect(
        detailAfter.customMilestones.single.milestone.description,
        '60 days',
      );
      expect(detailAfter.ruleBasedMilestones, hasLength(1));
    },
  );
}
