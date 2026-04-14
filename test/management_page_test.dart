import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reminder_app/features/reminders/data/timeline_models.dart';
import 'package:reminder_app/features/reminders/domain/reminder_rule.dart';
import 'package:reminder_app/features/reminders/domain/task_template.dart';
import 'package:reminder_app/features/reminders/domain/timeline.dart';
import 'package:reminder_app/features/reminders/domain/timeline_milestone_occurrence.dart';
import 'package:reminder_app/features/reminders/domain/timeline_milestone_record.dart';
import 'package:reminder_app/features/reminders/domain/timeline_milestone_rule.dart';
import 'package:reminder_app/features/reminders/providers/task_providers.dart';
import 'package:reminder_app/features/reminders/providers/timeline_providers.dart';
import 'package:reminder_app/features/reminders/ui/pages/management_page.dart';

void main() {
  testWidgets('management page shows explicit template and timeline actions', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          taskTemplatesProvider.overrideWith(
            (ref) => Stream.value([
              _template(1, TaskTemplateStatus.active),
              _template(2, TaskTemplateStatus.paused),
              _template(3, TaskTemplateStatus.archived),
            ]),
          ),
          timelinesProvider.overrideWith(
            (ref) => Stream.value([
              Timeline(
                id: 9,
                title: 'No sugar',
                startDate: DateTime(2026, 4, 10),
                displayUnit: TimelineDisplayUnit.day,
                status: TimelineStatus.active,
                createdAt: DateTime(2026, 4, 1),
                updatedAt: DateTime(2026, 4, 1),
              ),
              Timeline(
                id: 10,
                title: 'No late coffee',
                startDate: DateTime(2026, 4, 10),
                displayUnit: TimelineDisplayUnit.week,
                status: TimelineStatus.archived,
                createdAt: DateTime(2026, 4, 1),
                updatedAt: DateTime(2026, 4, 1),
              ),
            ]),
          ),
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
                milestoneRuleDetails: [
                  TimelineMilestoneRuleDetail(
                    rule: _rule(92, TimelineMilestoneRuleStatus.active),
                    nextMilestone: TimelineMilestoneOccurrence(
                      timelineId: 9,
                      timelineTitle: 'No sugar',
                      ruleId: 92,
                      occurrenceIndex: 1,
                      targetDate: DateTime(2026, 4, 20),
                      label: '第 10天',
                      status: MilestoneStatus.upcoming,
                      reminderOffsetDays: 0,
                    ),
                    historyRecords: const [],
                  ),
                  TimelineMilestoneRuleDetail(
                    rule: _rule(91, TimelineMilestoneRuleStatus.active),
                    nextMilestone: TimelineMilestoneOccurrence(
                      timelineId: 9,
                      timelineTitle: 'No sugar',
                      ruleId: 91,
                      occurrenceIndex: 1,
                      targetDate: DateTime(2026, 5, 10),
                      label: '第 30天',
                      status: MilestoneStatus.upcoming,
                      reminderOffsetDays: 0,
                    ),
                    historyRecords: const [],
                  ),
                ],
                upcomingMilestones: [
                  TimelineMilestoneOccurrence(
                    timelineId: 9,
                    timelineTitle: 'No sugar',
                    ruleId: 92,
                    occurrenceIndex: 1,
                    targetDate: DateTime(2026, 4, 20),
                    label: '第 10天',
                    status: MilestoneStatus.upcoming,
                    reminderOffsetDays: 0,
                  ),
                  TimelineMilestoneOccurrence(
                    timelineId: 9,
                    timelineTitle: 'No sugar',
                    ruleId: 91,
                    occurrenceIndex: 1,
                    targetDate: DateTime(2026, 5, 10),
                    label: '第 30天',
                    status: MilestoneStatus.upcoming,
                    reminderOffsetDays: 0,
                  ),
                  TimelineMilestoneOccurrence(
                    timelineId: 9,
                    timelineTitle: 'No sugar',
                    ruleId: 91,
                    occurrenceIndex: 2,
                    targetDate: DateTime(2026, 6, 9),
                    label: '第 60天',
                    status: MilestoneStatus.upcoming,
                    reminderOffsetDays: 0,
                  ),
                ],
                milestoneHistory: const [],
              ),
            ),
          ),
          timelineDetailProvider(10).overrideWith(
            (ref) => Future.value(
              TimelineDetail(
                timeline: Timeline(
                  id: 10,
                  title: 'No late coffee',
                  startDate: DateTime(2026, 4, 10),
                  displayUnit: TimelineDisplayUnit.week,
                  status: TimelineStatus.archived,
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
        child: const MaterialApp(home: ManagementPage()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('template-edit-1')), findsOneWidget);
    expect(find.byKey(const Key('template-pause-1')), findsOneWidget);
    expect(find.byKey(const Key('template-archive-1')), findsOneWidget);

    expect(find.byKey(const Key('template-resume-2')), findsOneWidget);
    expect(find.byKey(const Key('template-archive-2')), findsOneWidget);
    expect(find.byKey(const Key('template-edit-2')), findsOneWidget);

    expect(find.byKey(const Key('template-edit-3')), findsNothing);
    expect(find.byKey(const Key('template-pause-3')), findsNothing);
    expect(find.byKey(const Key('template-resume-3')), findsNothing);
    expect(find.byKey(const Key('template-archive-3')), findsNothing);

    await tester.scrollUntilVisible(
      find.text('No sugar', skipOffstage: false),
      200,
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('timeline-edit-9')), findsOneWidget);
    expect(find.byKey(const Key('timeline-history-9')), findsOneWidget);
    expect(find.byKey(const Key('timeline-rule-9-92')), findsOneWidget);
    expect(find.byKey(const Key('timeline-rule-9-91')), findsOneWidget);
    expect(find.byKey(const Key('timeline-upcoming-9-92')), findsOneWidget);
    expect(find.byKey(const Key('timeline-upcoming-9-91')), findsOneWidget);
    expect(find.text('每 10 天'), findsOneWidget);
    expect(find.text('每 30 天'), findsOneWidget);
    expect(find.text('第 10天'), findsOneWidget);
    expect(find.text('2026/04/20'), findsOneWidget);
    expect(find.text('第 30天'), findsOneWidget);
    expect(find.text('2026/05/10'), findsOneWidget);
    expect(find.text('第 60天'), findsNothing);

    expect(find.byKey(const Key('timeline-edit-10')), findsNothing);
    expect(find.byKey(const Key('timeline-history-10')), findsOneWidget);
    expect(find.text('目前沒有 upcoming milestone。'), findsOneWidget);

    final firstTile = tester.widget<ListTile>(
      find.byKey(const Key('timeline-upcoming-9-92')),
    );
    final secondTile = tester.widget<ListTile>(
      find.byKey(const Key('timeline-upcoming-9-91')),
    );
    expect((firstTile.title as Text).data, '第 10天');
    expect((secondTile.title as Text).data, '第 30天');
  });
}

TaskTemplate _template(int id, TaskTemplateStatus status) {
  return TaskTemplate(
    id: id,
    title: 'Template $id',
    kind: TaskKind.recurring,
    status: status,
    firstDueDate: DateTime(2026, 4, 10),
    reminderRule: const ReminderRule.onDue(),
    createdAt: DateTime(2026, 4, 1),
    updatedAt: DateTime(2026, 4, 1),
  );
}

TimelineMilestoneRule _rule(int id, TimelineMilestoneRuleStatus status) {
  return TimelineMilestoneRule(
    id: id,
    timelineId: 9,
    type: TimelineMilestoneRuleType.everyNDays,
    intervalValue: id == 92 ? 10 : 30,
    intervalUnit: TimelineMilestoneIntervalUnit.days,
    labelTemplate: '第 {value}{unit}',
    reminderOffsetDays: 0,
    status: status,
    createdAt: DateTime(2026, 4, 1),
    updatedAt: DateTime(2026, 4, 1),
  );
}
