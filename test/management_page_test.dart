import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reminder_app/features/reminders/domain/milestone_reminder_rule.dart';
import 'package:reminder_app/features/reminders/domain/reminder_rule.dart';
import 'package:reminder_app/features/reminders/domain/task_template.dart';
import 'package:reminder_app/features/reminders/domain/timeline.dart';
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
                milestoneReminderRule: const MilestoneReminderRule.onDay(),
                createdAt: DateTime(2026, 4, 1),
                updatedAt: DateTime(2026, 4, 1),
              ),
            ]),
          ),
        ],
        child: const MaterialApp(home: ManagementPage()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('No sugar', skipOffstage: false),
      200,
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

    expect(find.byKey(const Key('timeline-edit-9')), findsOneWidget);
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
