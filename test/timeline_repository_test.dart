import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reminder_app/features/reminders/data/home_query_service.dart';
import 'package:reminder_app/features/reminders/data/local/app_database.dart';
import 'package:reminder_app/features/reminders/data/task_repository.dart';
import 'package:reminder_app/features/reminders/data/timeline_repository.dart';
import 'package:reminder_app/features/reminders/domain/timeline.dart';
import 'package:reminder_app/features/reminders/domain/timeline_milestone_rule.dart';

void main() {
  test(
    'timeline create stores rules but no pre-generated milestone records',
    () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);
      final repository = TimelineRepository(db.taskTimelineDao);

      final timelineId = await repository.createTimeline(
        TimelineInput(
          title: 'No sugar',
          startDate: DateTime(2026, 4, 10),
          displayUnit: TimelineDisplayUnit.day,
          milestoneRules: const [
            TimelineMilestoneRuleInput(
              type: TimelineMilestoneRuleType.everyNDays,
              intervalValue: 1,
              intervalUnit: TimelineMilestoneIntervalUnit.days,
              labelTemplate: '第 {n} 天',
              reminderOffsetDays: 1,
            ),
          ],
        ),
      );

      final rules = await repository.watchMilestoneRules().first;
      final records = await repository.watchMilestoneRecords().first;
      final detail = await repository.getTimelineDetailById(
        timelineId,
        now: DateTime(2026, 4, 9),
      );

      expect(rules, hasLength(1));
      expect(records, isEmpty);
      expect(detail, isNotNull);
      expect(detail!.rules, hasLength(1));
      expect(detail.upcomingOccurrences, hasLength(1));
      expect(
        detail.upcomingOccurrences.single.targetDate,
        DateTime(2026, 4, 10),
      );
    },
  );

  test(
    'noticed occurrence creates milestone record and history entry',
    () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);
      final repository = TimelineRepository(db.taskTimelineDao);

      final timelineId = await repository.createTimeline(
        TimelineInput(
          title: 'Cat adoption',
          startDate: DateTime(2026, 4, 10),
          displayUnit: TimelineDisplayUnit.week,
          milestoneRules: const [
            TimelineMilestoneRuleInput(
              type: TimelineMilestoneRuleType.everyNDays,
              intervalValue: 7,
              intervalUnit: TimelineMilestoneIntervalUnit.days,
              labelTemplate: '第 {n} 週',
              reminderOffsetDays: 1,
            ),
          ],
        ),
      );

      final detail = await repository.getTimelineDetailById(
        timelineId,
        now: DateTime(2026, 4, 15),
      );

      expect(detail, isNotNull);
      expect(detail!.upcomingOccurrences, hasLength(1));

      await repository.noticeOccurrence(detail.upcomingOccurrences.single);

      final history = await repository.watchMilestoneHistory().first;
      expect(history, hasLength(1));
      expect(history.single.record.status.name, 'noticed');
      expect(history.single.record.occurrenceIndex, 1);
    },
  );

  test(
    'inactive rules do not produce occurrences and milestones never go overdue',
    () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);
      final timelineRepository = TimelineRepository(db.taskTimelineDao);
      final homeQueryService = HomeQueryService(
        taskRepository: TaskRepository(db.taskTimelineDao),
        timelineRepository: timelineRepository,
      );

      await timelineRepository.createTimeline(
        TimelineInput(
          title: 'Sober',
          startDate: DateTime(2026, 4, 10),
          displayUnit: TimelineDisplayUnit.month,
          milestoneRules: const [
            TimelineMilestoneRuleInput(
              type: TimelineMilestoneRuleType.everyNMonths,
              intervalValue: 1,
              intervalUnit: TimelineMilestoneIntervalUnit.months,
              labelTemplate: '第 {n} 個月',
              reminderOffsetDays: 5,
              isActive: false,
            ),
            TimelineMilestoneRuleInput(
              type: TimelineMilestoneRuleType.everyNDays,
              intervalValue: 30,
              intervalUnit: TimelineMilestoneIntervalUnit.days,
              labelTemplate: '第 {n} 個 30 天',
              reminderOffsetDays: 3,
            ),
          ],
        ),
      );

      final homeItems = await homeQueryService
          .watchUpcomingItems(now: DateTime(2026, 5, 7))
          .first;
      final overdueTasks = await homeQueryService
          .watchOverdueTasks(now: DateTime(2026, 5, 7))
          .first;

      expect(homeItems.whereType<MilestoneHomeItem>(), hasLength(1));
      expect(overdueTasks, isEmpty);
    },
  );
}
