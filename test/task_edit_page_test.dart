import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reminder_app/features/reminders/domain/reminder_rule.dart';
import 'package:reminder_app/features/reminders/domain/task_template.dart';
import 'package:reminder_app/features/reminders/providers/task_providers.dart';
import 'package:reminder_app/features/reminders/ui/pages/task_edit_page.dart';

void main() {
  testWidgets(
    'task template editor only shows offset for advance reminder rule',
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: const MaterialApp(
            home: TaskEditPage(mode: TaskEditMode.taskTemplateCreate),
          ),
        ),
      );
      await tester.pump();

      expect(find.byKey(const Key('offset-field')), findsNothing);

      await tester.tap(find.byKey(const Key('reminder-rule-field')));
      await tester.pumpAndSettle();
      await tester.tap(find.text(ReminderRuleType.advance.name).last);
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('offset-field')), findsOneWidget);

      await tester.tap(find.byKey(const Key('reminder-rule-field')));
      await tester.pumpAndSettle();
      await tester.tap(find.text(ReminderRuleType.immediate.name).last);
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('offset-field')), findsNothing);
    },
  );

  testWidgets('task template editor loads the current reminder rule', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          taskTemplateProvider(7).overrideWith(
            (ref) => Future.value(
              TaskTemplate(
                id: 7,
                title: 'Weekly trash',
                kind: TaskKind.recurring,
                status: TaskTemplateStatus.active,
                firstDueDate: DateTime(2026, 4, 20),
                reminderRule: const ReminderRule.advance(3),
                createdAt: DateTime(2026, 4, 1),
                updatedAt: DateTime(2026, 4, 2),
              ),
            ),
          ),
        ],
        child: const MaterialApp(
          home: TaskEditPage(mode: TaskEditMode.taskTemplateEdit, id: 7),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(ReminderRuleType.advance.name), findsOneWidget);
    expect(find.byKey(const Key('offset-field')), findsOneWidget);
    expect(find.text('3'), findsWidgets);
  });
}
