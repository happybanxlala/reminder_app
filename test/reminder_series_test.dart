import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reminder_app/app/app.dart';
import 'package:reminder_app/features/reminders/data/local/app_database.dart';
import 'package:reminder_app/features/reminders/data/reminder_repository.dart';
import 'package:reminder_app/features/reminders/domain/demo_reminder_draft.dart';
import 'package:reminder_app/features/reminders/domain/reminder.dart';
import 'package:reminder_app/features/reminders/domain/recurring_reminder.dart';
import 'package:reminder_app/features/reminders/ui/pages/reminder_edit_page.dart';
import 'package:reminder_app/features/reminders/ui/pages/reminders_list_page.dart';

void main() {
  testWidgets('recurring reminder tab is available and FAB opens form', (
    tester,
  ) async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [appDatabaseProvider.overrideWithValue(db)],
        child: const ReminderApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('習慣'), findsOneWidget);

    await tester.tap(find.text('習慣'));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('add-recurring-reminder-button')),
      findsOneWidget,
    );
    expect(find.text('新增習慣'), findsOneWidget);

    await tester.tap(find.byKey(const Key('add-recurring-reminder-button')));
    await tester.pumpAndSettle();

    expect(find.text('新增習慣'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.idle();
    await tester.pump();
  });

  testWidgets(
    'recurring reminder create saves template and first reminder together',
    (tester) async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [appDatabaseProvider.overrideWithValue(db)],
          child: MaterialApp(
            home: ReminderEditPage(
              mode: ReminderFormMode.seriesCreate,
              demoDataFactory: _seriesCreateDraft,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.byKey(const Key('random-fill-button')),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.byKey(const Key('random-fill-button')));
      await tester.pump();

      await tester.scrollUntilVisible(
        find.text('儲存'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('儲存'));
      await tester.pumpAndSettle();

      final recurringRows = await db.select(db.recurringReminders).get();
      final reminderRows = await db.select(db.reminders).get();

      expect(recurringRows, hasLength(1));
      expect(reminderRows, hasLength(1));
      expect(recurringRows.single.title, 'Series create');
      expect(recurringRows.single.repeatRule, 'W2');
      expect(reminderRows.single.recurringReminderId, recurringRows.single.id);
      expect(reminderRows.single.title, 'Series create');
      expect(reminderRows.single.status, ReminderStatus.pending);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.idle();
      await tester.pump();
    },
  );

  testWidgets(
    'recurring reminder edit hides date fields and does not update existing reminder snapshot',
    (tester) async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);

      final seed = await _seedPendingRecurringReminder(
        db,
        title: 'Original series',
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appDatabaseProvider.overrideWithValue(db),
            recurringReminderDetailProvider(
              seed.recurringReminderId,
            ).overrideWith(
              (ref) async => RecurringReminderModel(
                id: seed.recurringReminderId,
                status: RecurringReminderStatus.pending,
                title: 'Original series',
                note: null,
                trackingMode: ReminderTrackingMode.countdown,
                triggerMode: ReminderTriggerMode.inRange,
                triggerOffsetDays: 1,
                repeatRule: 'W1',
                createdAt: DateTime(2026, 1, 1),
                updatedAt: DateTime(2026, 1, 1),
              ),
            ),
          ],
          child: MaterialApp(
            home: ReminderEditPage(
              mode: ReminderFormMode.seriesEdit,
              seriesId: seed.recurringReminderId,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('edit-due-at-text')), findsNothing);
      expect(find.byKey(const Key('edit-start-at-text')), findsNothing);

      await tester.enterText(
        find.byKey(const Key('edit-title-field')),
        'Updated series',
      );
      await tester.scrollUntilVisible(
        find.text('儲存'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('儲存'));
      await tester.pumpAndSettle();

      final updatedRecurringReminder = await db.reminderDao
          .getRecurringReminderById(seed.recurringReminderId);
      final reminderRows = await db.select(db.reminders).get();

      expect(updatedRecurringReminder, isNotNull);
      expect(updatedRecurringReminder!.title, 'Updated series');
      expect(
        updatedRecurringReminder.trackingMode,
        ReminderTrackingMode.countdown,
      );
      expect(reminderRows.single.id, seed.reminderId);
      expect(reminderRows.single.title, 'Original series');

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.idle();
      await tester.pump();
    },
  );

  testWidgets(
    'recurring reminder tab supports stop and cancel while preserving stopped/canceled editability rules',
    (tester) async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);

      final pendingStop = await _seedPendingRecurringReminder(
        db,
        title: 'Pending stop',
      );
      final pendingCancel = await _seedPendingRecurringReminder(
        db,
        title: 'Pending cancel',
      );
      final stopped = await _seedRecurringReminderOnly(
        db,
        title: 'Stopped series',
        status: RecurringReminderStatus.stopped,
        updatedAtOffset: 1,
      );
      final canceled = await _seedRecurringReminderOnly(
        db,
        title: 'Canceled series',
        status: RecurringReminderStatus.canceled,
        updatedAtOffset: 0,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [appDatabaseProvider.overrideWithValue(db)],
          child: const MaterialApp(home: RemindersListPage()),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('習慣'));
      await tester.pumpAndSettle();

      expect(
        find.byKey(Key('recurring-edit-button-${stopped.recurringReminderId}')),
        findsOneWidget,
      );
      expect(
        find.byKey(
          Key('recurring-edit-button-${canceled.recurringReminderId}'),
        ),
        findsNothing,
      );

      await tester.tap(
        find.byKey(
          Key('recurring-stop-button-${pendingStop.recurringReminderId}'),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('是'));
      await tester.pumpAndSettle();

      await tester.tap(
        find.byKey(
          Key('recurring-cancel-button-${pendingCancel.recurringReminderId}'),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('是'));
      await tester.pumpAndSettle();

      final stoppedRecurringReminder = await db.reminderDao
          .getRecurringReminderById(pendingStop.recurringReminderId);
      final canceledRecurringReminder = await db.reminderDao
          .getRecurringReminderById(pendingCancel.recurringReminderId);
      final reminderRows = await db.select(db.reminders).get();
      final stoppedReminder = reminderRows.firstWhere(
        (row) => row.id == pendingStop.reminderId,
      );
      final canceledReminder = reminderRows.firstWhere(
        (row) => row.id == pendingCancel.reminderId,
      );

      expect(stoppedRecurringReminder!.status, RecurringReminderStatus.stopped);
      expect(
        canceledRecurringReminder!.status,
        RecurringReminderStatus.canceled,
      );
      expect(stoppedReminder.status, ReminderStatus.canceled);
      expect(canceledReminder.status, ReminderStatus.canceled);

      await tester.tap(
        find.byKey(
          Key('recurring-reactivate-button-${stopped.recurringReminderId}'),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('依今天推算下一次固定時間'));
      await tester.pumpAndSettle();

      final reactivatedRecurringReminder = await db.reminderDao
          .getRecurringReminderById(stopped.recurringReminderId);
      final seriesReminders =
          await (db.select(db.reminders)..where(
                (t) =>
                    t.recurringReminderId.equals(stopped.recurringReminderId),
              ))
              .get();
      final today = DateTime.now();
      final normalizedTodayPlusWeek = DateTime(
        today.year,
        today.month,
        today.day + 7,
      );

      expect(
        reactivatedRecurringReminder!.status,
        RecurringReminderStatus.pending,
      );
      expect(seriesReminders, hasLength(1));
      expect(seriesReminders.single.status, ReminderStatus.pending);
      expect(
        DateTime.fromMillisecondsSinceEpoch(seriesReminders.single.dueAt!),
        normalizedTodayPlusWeek,
      );

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.idle();
      await tester.pump();
    },
  );

  test(
    'recurring reminder repository list is ordered by status then updatedAt and status transitions persist',
    () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);
      final repository = ReminderRepository(db.reminderDao);

      final pendingOlder = await _seedRecurringReminderOnly(
        db,
        title: 'Pending older',
        status: RecurringReminderStatus.pending,
        updatedAtOffset: 1,
      );
      final pendingNewer = await _seedRecurringReminderOnly(
        db,
        title: 'Pending newer',
        status: RecurringReminderStatus.pending,
        updatedAtOffset: 5,
      );
      final stopped = await _seedRecurringReminderOnly(
        db,
        title: 'Stopped',
        status: RecurringReminderStatus.stopped,
        updatedAtOffset: 4,
      );
      final canceled = await _seedRecurringReminderOnly(
        db,
        title: 'Canceled',
        status: RecurringReminderStatus.canceled,
        updatedAtOffset: 3,
      );

      final ordered = await repository.watchAllRecurringReminders().first;

      expect(ordered.map((item) => item.id), [
        pendingNewer.recurringReminderId,
        pendingOlder.recurringReminderId,
        stopped.recurringReminderId,
        canceled.recurringReminderId,
      ]);

      await repository.stopRecurringReminderById(
        pendingNewer.recurringReminderId,
      );
      await repository.cancelRecurringReminderById(
        pendingOlder.recurringReminderId,
      );

      final stoppedRecurringReminder = await db.reminderDao
          .getRecurringReminderById(pendingNewer.recurringReminderId);
      final canceledRecurringReminder = await db.reminderDao
          .getRecurringReminderById(pendingOlder.recurringReminderId);

      expect(stoppedRecurringReminder!.status, RecurringReminderStatus.stopped);
      expect(
        canceledRecurringReminder!.status,
        RecurringReminderStatus.canceled,
      );
    },
  );
}

class _RecurringReminderSeed {
  const _RecurringReminderSeed({
    required this.recurringReminderId,
    this.reminderId,
  });

  final int recurringReminderId;
  final int? reminderId;
}

Future<_RecurringReminderSeed> _seedPendingRecurringReminder(
  AppDatabase db, {
  required String title,
}) async {
  final now = DateTime.now();
  final createdAt = DateTime(
    now.year,
    now.month,
    now.day,
  ).millisecondsSinceEpoch;
  final dueAt = DateTime(
    now.year,
    now.month,
    now.day + 2,
  ).millisecondsSinceEpoch;

  final recurringReminderId = await db
      .into(db.recurringReminders)
      .insert(
        RecurringRemindersCompanion.insert(
          title: title,
          trackingMode: ReminderTrackingMode.countdown,
          triggerMode: ReminderTriggerMode.inRange,
          triggerOffsetDays: const drift.Value(1),
          repeatRule: const drift.Value('W1'),
          createdAt: createdAt,
          updatedAt: createdAt,
        ),
      );

  final reminderId = await db
      .into(db.reminders)
      .insert(
        RemindersCompanion.insert(
          recurringReminderId: drift.Value(recurringReminderId),
          trackingMode: ReminderTrackingMode.countdown,
          triggerMode: ReminderTriggerMode.inRange,
          title: title,
          triggerOffsetDays: const drift.Value(1),
          dueAt: drift.Value(dueAt),
          startAt: createdAt,
          createdAt: createdAt,
          updatedAt: createdAt,
        ),
      );

  return _RecurringReminderSeed(
    recurringReminderId: recurringReminderId,
    reminderId: reminderId,
  );
}

Future<_RecurringReminderSeed> _seedRecurringReminderOnly(
  AppDatabase db, {
  required String title,
  required int status,
  required int updatedAtOffset,
}) async {
  final base = DateTime(2026, 1, 1).millisecondsSinceEpoch;
  final updatedAt = base + (updatedAtOffset * 1000);
  final recurringReminderId = await db
      .into(db.recurringReminders)
      .insert(
        RecurringRemindersCompanion.insert(
          title: title,
          status: drift.Value(status),
          trackingMode: ReminderTrackingMode.countdown,
          triggerMode: ReminderTriggerMode.inRange,
          triggerOffsetDays: const drift.Value(1),
          repeatRule: const drift.Value('W1'),
          createdAt: base,
          updatedAt: updatedAt,
        ),
      );

  return _RecurringReminderSeed(recurringReminderId: recurringReminderId);
}

DemoReminderDraft _seriesCreateDraft() {
  return DemoReminderDraft(
    title: 'Series create',
    note: 'Series note',
    trackingMode: ReminderTrackingMode.countdown,
    triggerMode: ReminderTriggerMode.inRange,
    triggerOffsetDays: 2,
    dueAt: DateTime(2026, 3, 1),
    startAt: DateTime(2026, 2, 20),
    repeatType: 'W',
    repeatInterval: 2,
  );
}
