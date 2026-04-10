import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reminder_app/features/reminders/data/local/app_database.dart';
import 'package:reminder_app/features/reminders/data/reminder_repository.dart';
import 'package:reminder_app/features/reminders/domain/reminder.dart';
import 'package:reminder_app/features/reminders/domain/recurring_reminder.dart';
import 'package:reminder_app/features/reminders/ui/pages/reminders_list_page.dart';

void main() {
  testWidgets(
    'staged completion does not create next recurring reminder until leaving pending tab',
    (tester) async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);

      final reminderId = await _seedRecurringReminder(db);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [appDatabaseProvider.overrideWithValue(db)],
          child: const MaterialApp(home: RemindersListPage()),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byType(Checkbox).first);
      await tester.pumpAndSettle();

      expect(find.text('已完成（可恢復）'), findsOneWidget);

      final stagedRows = await db.select(db.reminders).get();
      expect(stagedRows, hasLength(1));
      expect(stagedRows.single.id, reminderId);
      expect(stagedRows.single.status, ReminderStatus.pending);

      await tester.tap(find.text('完成/跳過'));
      await tester.pumpAndSettle();

      final committedRows = await db.select(db.reminders).get();
      expect(committedRows, hasLength(2));

      final original = committedRows.firstWhere((row) => row.id == reminderId);
      final generated = committedRows.firstWhere((row) => row.id != reminderId);

      expect(original.status, ReminderStatus.done);
      expect(generated.status, ReminderStatus.pending);
      expect(generated.previousOccurrenceId, reminderId);
      expect(generated.recurringReminderId, original.recurringReminderId);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.idle();
      await tester.pump();
    },
  );

  testWidgets(
    'restoring staged completion keeps recurring reminder uncommitted',
    (tester) async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);

      final reminderId = await _seedRecurringReminder(db);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [appDatabaseProvider.overrideWithValue(db)],
          child: const MaterialApp(home: RemindersListPage()),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byType(Checkbox).first);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Weekly task'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('是'));
      await tester.pumpAndSettle();

      final rows = await db.select(db.reminders).get();
      expect(rows, hasLength(1));
      expect(rows.single.id, reminderId);
      expect(rows.single.status, ReminderStatus.pending);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.idle();
      await tester.pump();
    },
  );

  testWidgets('manual batch commit button commits staged recurring reminders', (
    tester,
  ) async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);

    final reminderId = await _seedRecurringReminder(db);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [appDatabaseProvider.overrideWithValue(db)],
        child: const MaterialApp(home: RemindersListPage()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('commit-staged-button')), findsNothing);

    await tester.tap(find.byType(Checkbox).first);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('commit-staged-button')), findsOneWidget);

    await tester.tap(find.byKey(const Key('commit-staged-button')));
    await tester.pumpAndSettle();

    final committedRows = await db.select(db.reminders).get();
    expect(committedRows, hasLength(2));

    final original = committedRows.firstWhere((row) => row.id == reminderId);
    final generated = committedRows.firstWhere((row) => row.id != reminderId);

    expect(original.status, ReminderStatus.done);
    expect(generated.status, ReminderStatus.pending);
    expect(find.byKey(const Key('commit-staged-button')), findsNothing);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.idle();
    await tester.pump();
  });

  testWidgets(
    'canceling a recurring reminder warns the user and pauses its series',
    (tester) async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);

      final reminderId = await _seedRecurringReminder(db);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [appDatabaseProvider.overrideWithValue(db)],
          child: const MaterialApp(home: RemindersListPage()),
        ),
      );
      await tester.pumpAndSettle();

      await tester.drag(
        find.byKey(ValueKey('pending-$reminderId')),
        const Offset(-600, 0),
      );
      await tester.pumpAndSettle();

      expect(find.text('取消任務'), findsOneWidget);
      expect(find.textContaining('這會同時暫停所屬習慣'), findsOneWidget);

      await tester.tap(find.text('是'));
      await tester.pumpAndSettle();

      final reminderRows = await db.select(db.reminders).get();
      final recurringRows = await db.select(db.recurringReminders).get();

      expect(reminderRows.single.status, ReminderStatus.canceled);
      expect(recurringRows.single.status, RecurringReminderStatus.stopped);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.idle();
      await tester.pump();
    },
  );

  testWidgets(
    'deferring a countdown reminder updates deferred due date and removes it from active list when outside trigger range',
    (tester) async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);

      final reminderId = await _seedRecurringReminder(db);
      final originalReminder = await (db.select(
        db.reminders,
      )..where((t) => t.id.equals(reminderId))).getSingle();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [appDatabaseProvider.overrideWithValue(db)],
          child: const MaterialApp(home: RemindersListPage()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Weekly task'), findsOneWidget);

      await tester.tap(find.byKey(ValueKey('defer-$reminderId')));
      await tester.pumpAndSettle();

      expect(find.text('延期任務'), findsOneWidget);
      await tester.enterText(find.byKey(const Key('defer-days-field')), '5');
      await tester.tap(find.text('確認'));
      await tester.pumpAndSettle();

      expect(find.text('Weekly task'), findsNothing);
      expect(find.text('目前沒有進行中的任務。'), findsOneWidget);

      final updatedReminder = await (db.select(
        db.reminders,
      )..where((t) => t.id.equals(reminderId))).getSingle();
      final expectedDeferredDueAt = DateTime.fromMillisecondsSinceEpoch(
        originalReminder.dueAt!,
      ).add(const Duration(days: 5)).millisecondsSinceEpoch;

      expect(updatedReminder.deferredDueAt, expectedDeferredDueAt);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.idle();
      await tester.pump();
    },
  );
}

Future<int> _seedRecurringReminder(AppDatabase db) async {
  final now = DateTime.now();
  final dueAt = DateTime(now.year, now.month, now.day + 1);
  final createdAt = DateTime(
    now.year,
    now.month,
    now.day,
  ).millisecondsSinceEpoch;

  final recurringReminderId = await db
      .into(db.recurringReminders)
      .insert(
        RecurringRemindersCompanion.insert(
          title: 'Weekly task',
          trackingMode: ReminderTrackingMode.countdown,
          triggerMode: ReminderTriggerMode.inRange,
          triggerOffsetDays: const drift.Value(2),
          repeatRule: const drift.Value('W1'),
          createdAt: createdAt,
          updatedAt: createdAt,
        ),
      );

  return db
      .into(db.reminders)
      .insert(
        RemindersCompanion.insert(
          recurringReminderId: drift.Value(recurringReminderId),
          trackingMode: ReminderTrackingMode.countdown,
          triggerMode: ReminderTriggerMode.inRange,
          title: 'Weekly task',
          triggerOffsetDays: const drift.Value(2),
          dueAt: drift.Value(dueAt.millisecondsSinceEpoch),
          startAt: createdAt,
          createdAt: createdAt,
          updatedAt: createdAt,
        ),
      );
}
