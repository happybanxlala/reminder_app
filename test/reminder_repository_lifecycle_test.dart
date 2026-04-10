import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reminder_app/features/reminders/data/local/app_database.dart';
import 'package:reminder_app/features/reminders/data/reminder_repository.dart';
import 'package:reminder_app/features/reminders/domain/reminder.dart';
import 'package:reminder_app/features/reminders/domain/recurring_reminder.dart';

void main() {
  test('recurring done creates next occurrence in repository', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final repository = ReminderRepository(db.reminderDao);
    final seed = await _seedPendingRecurringReminder(db, title: 'Done series');

    await repository.complete(seed.reminderId!);

    final reminders = await _recurringRemindersFor(
      db,
      seed.recurringReminderId,
    );

    expect(reminders, hasLength(2));
    expect(reminders.first.status, ReminderStatus.done);
    expect(reminders.last.status, ReminderStatus.pending);
    expect(reminders.last.previousOccurrenceId, reminders.first.id);
  });

  test('recurring skip creates next occurrence in repository', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final repository = ReminderRepository(db.reminderDao);
    final seed = await _seedPendingRecurringReminder(db, title: 'Skip series');

    await repository.skip(seed.reminderId!);

    final reminders = await _recurringRemindersFor(
      db,
      seed.recurringReminderId,
    );

    expect(reminders, hasLength(2));
    expect(reminders.first.status, ReminderStatus.skipped);
    expect(reminders.last.status, ReminderStatus.pending);
  });

  test(
    'recurring cancel does not create next occurrence in repository',
    () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);
      final repository = ReminderRepository(db.reminderDao);
      final seed = await _seedPendingRecurringReminder(
        db,
        title: 'Cancel series',
      );

      await repository.cancel(seed.reminderId!);

      final reminders = await _recurringRemindersFor(
        db,
        seed.recurringReminderId,
      );
      final recurringReminder = await db.reminderDao.getRecurringReminderById(
        seed.recurringReminderId,
      );

      expect(reminders, hasLength(1));
      expect(reminders.single.status, ReminderStatus.canceled);
      expect(recurringReminder!.status, RecurringReminderStatus.stopped);
    },
  );

  test('stop recurring cancels pending reminders in repository', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final repository = ReminderRepository(db.reminderDao);
    final seed = await _seedPendingRecurringReminder(db, title: 'Stop series');

    await repository.stopRecurringReminderById(seed.recurringReminderId);

    final recurringReminder = await db.reminderDao.getRecurringReminderById(
      seed.recurringReminderId,
    );
    final reminders = await _recurringRemindersFor(
      db,
      seed.recurringReminderId,
    );

    expect(recurringReminder!.status, RecurringReminderStatus.stopped);
    expect(reminders.single.status, ReminderStatus.canceled);
  });

  test(
    'reactivate recurring creates new pending reminder in repository',
    () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);
      final repository = ReminderRepository(db.reminderDao);
      final seed = await _seedPendingRecurringReminder(
        db,
        title: 'Reactivate series',
      );

      await repository.stopRecurringReminderById(seed.recurringReminderId);

      final reactivatedReminderId = await repository
          .reactivateRecurringReminderById(
            seed.recurringReminderId,
            dueAt: DateTime(2026, 4, 1),
          );

      final reminders = await _recurringRemindersFor(
        db,
        seed.recurringReminderId,
      );
      final pendingReminders = reminders.where(
        (reminder) => reminder.status == ReminderStatus.pending,
      );
      final canceledReminders = reminders.where(
        (reminder) => reminder.status == ReminderStatus.canceled,
      );

      expect(reactivatedReminderId, isNotNull);
      expect(reminders, hasLength(2));
      expect(canceledReminders, hasLength(1));
      expect(pendingReminders, hasLength(1));
      expect(pendingReminders.single.id, reactivatedReminderId);
      expect(
        DateTime.fromMillisecondsSinceEpoch(pendingReminders.single.dueAt!),
        DateTime(2026, 4, 1),
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

Future<List<Reminder>> _recurringRemindersFor(
  AppDatabase db,
  int recurringReminderId,
) {
  return (db.select(db.reminders)
        ..where((t) => t.recurringReminderId.equals(recurringReminderId))
        ..orderBy([(t) => drift.OrderingTerm.asc(t.id)]))
      .get();
}
