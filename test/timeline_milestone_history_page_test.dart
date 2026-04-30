import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reminder_app/features/reminders/data/local/item_timeline_dao.dart';
import 'package:reminder_app/features/reminders/data/timeline_models.dart';
import 'package:reminder_app/features/reminders/domain/timeline.dart';
import 'package:reminder_app/features/reminders/domain/timeline_milestone_record.dart';
import 'package:reminder_app/features/reminders/domain/timeline_milestone_rule.dart';
import 'package:reminder_app/features/reminders/presentation/text/reminder_ui_text.dart';
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

      expect(
        find.text('No sugar · ${ReminderUiText.milestoneHistoryTitle}'),
        findsOneWidget,
      );
      expect(find.byKey(const Key('timeline-history-9')), findsOneWidget);
      expect(find.textContaining('已看過'), findsOneWidget);
      expect(find.text(ReminderUiText.upcomingMilestonesTitle), findsNothing);
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

    expect(
      find.text(ReminderUiText.noTimelineMilestoneHistory),
      findsOneWidget,
    );
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
      status: TimelineMilestoneRecordStatus.noticed,
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
