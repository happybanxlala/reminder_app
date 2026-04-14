import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reminder_app/features/reminders/data/local/task_timeline_dao.dart';
import 'package:reminder_app/features/reminders/data/timeline_models.dart';
import 'package:reminder_app/features/reminders/domain/timeline.dart';
import 'package:reminder_app/features/reminders/domain/timeline_milestone_record.dart';
import 'package:reminder_app/features/reminders/domain/timeline_milestone_rule.dart';
import 'package:reminder_app/features/reminders/providers/timeline_providers.dart';
import 'package:reminder_app/features/reminders/ui/pages/timeline_milestone_history_page.dart';

void main() {
  testWidgets(
    'timeline milestone history page only shows the timeline history',
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            timelineDetailProvider(9).overrideWith(
              (ref) => Future.value(
                TimelineDetail(
                  timeline: Timeline(
                    id: 9,
                    title: 'No sugar',
                    startDate: DateTime(2026, 4, 10),
                    displayUnit: TimelineDisplayUnit.day,
                    status: TimelineStatus.active,
                    createdAt: DateTime(2026, 4, 1),
                    updatedAt: DateTime(2026, 4, 1),
                  ),
                  milestoneRuleDetails: const [],
                  upcomingMilestones: const [],
                  milestoneHistory: [_historyBundle(9)],
                ),
              ),
            ),
          ],
          child: const MaterialApp(
            home: TimelineMilestoneHistoryPage(timelineId: 9),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('No sugar · Milestone History'), findsOneWidget);
      expect(find.byKey(const Key('timeline-history-9')), findsOneWidget);
      expect(find.textContaining('noticed'), findsOneWidget);
      expect(find.text('Upcoming Milestones'), findsNothing);
    },
  );

  testWidgets('timeline milestone history page shows empty state', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          timelineDetailProvider(10).overrideWith(
            (ref) => Future.value(
              TimelineDetail(
                timeline: Timeline(
                  id: 10,
                  title: 'No coffee',
                  startDate: DateTime(2026, 4, 10),
                  displayUnit: TimelineDisplayUnit.week,
                  status: TimelineStatus.active,
                  createdAt: DateTime(2026, 4, 1),
                  updatedAt: DateTime(2026, 4, 1),
                ),
                milestoneRuleDetails: const [],
                upcomingMilestones: const [],
                milestoneHistory: const [],
              ),
            ),
          ),
        ],
        child: const MaterialApp(
          home: TimelineMilestoneHistoryPage(timelineId: 10),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('此 Timeline 目前沒有 milestone history。'), findsOneWidget);
  });
}

TimelineMilestoneRecordBundle _historyBundle(int id) {
  return TimelineMilestoneRecordBundle(
    record: TimelineMilestoneRecord(
      id: id,
      timelineId: id,
      ruleId: id,
      occurrenceIndex: 1,
      targetDate: DateTime(2026, 5, 10),
      status: MilestoneStatus.noticed,
      actedAt: DateTime(2026, 5, 10),
      createdAt: DateTime(2026, 4, 1),
      updatedAt: DateTime(2026, 5, 10),
    ),
    rule: TimelineMilestoneRule(
      id: id,
      timelineId: id,
      type: TimelineMilestoneRuleType.everyNDays,
      intervalValue: 30,
      intervalUnit: TimelineMilestoneIntervalUnit.days,
      labelTemplate: '第 {value}{unit}',
      reminderOffsetDays: 0,
      status: TimelineMilestoneRuleStatus.archived,
      createdAt: DateTime(2026, 4, 1),
      updatedAt: DateTime(2026, 4, 1),
    ),
    timeline: Timeline(
      id: id,
      title: 'No sugar',
      startDate: DateTime(2026, 4, 10),
      displayUnit: TimelineDisplayUnit.day,
      status: TimelineStatus.active,
      createdAt: DateTime(2026, 4, 1),
      updatedAt: DateTime(2026, 4, 1),
    ),
  );
}
