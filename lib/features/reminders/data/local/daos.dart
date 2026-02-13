import 'package:drift/drift.dart';

import '../../domain/repeat_rule.dart';
import 'app_database.dart';
import 'tables.dart';

part 'daos.g.dart';

@DriftAccessor(tables: [Reminders])
class ReminderDao extends DatabaseAccessor<AppDatabase>
    with _$ReminderDaoMixin {
  ReminderDao(super.attachedDatabase);

  Stream<List<Reminder>> watchAll() {
    return (select(reminders)
          ..where((t) => t.isCanceled.equals(false))
          ..orderBy([
            (t) => OrderingTerm.asc(t.isDone),
            (t) => OrderingTerm.asc(t.dueAt),
            (t) => OrderingTerm.desc(t.updatedAt),
          ]))
        .watch();
  }

  Stream<List<Reminder>> watchTodayPending() {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    final startMs = startOfDay.millisecondsSinceEpoch;
    final endMs = endOfDay.millisecondsSinceEpoch;

    return (select(reminders)
          ..where(
            (t) =>
                t.isDone.equals(0) &
                t.isCanceled.equals(false) &
                t.dueAt.isNotNull() &
                t.dueAt.isBiggerOrEqualValue(startMs) &
                t.dueAt.isSmallerThanValue(endMs),
          )
          ..orderBy([(t) => OrderingTerm.asc(t.dueAt)]))
        .watch();
  }

  Stream<Reminder?> watchNextReminder() {
    final query = (select(reminders)
      ..where(
        (t) =>
            t.isDone.equals(0) &
            t.isCanceled.equals(false) &
            t.dueAt.isNotNull(),
      )
      ..orderBy([(t) => OrderingTerm.asc(t.dueAt)])
      ..limit(1));
    return query.watchSingleOrNull();
  }

  Future<Reminder?> getById(int id) {
    return (select(reminders)..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  Future<Reminder?> getEditableById(int id) {
    return (select(reminders)..where(
          (t) =>
              t.id.equals(id) & t.isDone.equals(0) & t.isCanceled.equals(false),
        ))
        .getSingleOrNull();
  }

  Future<int> insertReminder(RemindersCompanion entry) {
    return into(reminders).insert(entry);
  }

  Future<bool> updateReminder(Reminder reminder) {
    return update(reminders).replace(reminder);
  }

  Future<int> deleteReminder(int id) {
    return (delete(reminders)..where((t) => t.id.equals(id))).go();
  }

  Future<void> completeOrSkip(int id, int doneState) async {
    await transaction(() async {
      final source = await getById(id);
      if (source == null) {
        return;
      }
      if (source.isDone != 0 || source.isCanceled) {
        return;
      }

      final now = DateTime.now().millisecondsSinceEpoch;
      await (update(reminders)..where((t) => t.id.equals(id))).write(
        RemindersCompanion(isDone: Value(doneState), updatedAt: Value(now)),
      );

      await createRepeatReminder(source, now);
    });
  }

  Future<int?> createRepeatReminder(Reminder source, int nowEpochMs) async {
    final rule = RepeatRule.parse(source.repeatRule);
    final base = source.extendAt ?? source.dueAt;

    if (rule == null || base == null) {
      return null;
    }

    final nextDueAt = rule.advance(DateTime.fromMillisecondsSinceEpoch(base));

    return insertReminder(
      RemindersCompanion.insert(
        startId: source.startId == 0 ? Value(source.id) : Value(source.startId),
        title: source.title,
        note: Value(source.note),
        remindDays: Value(source.remindDays),
        dueAt: Value(nextDueAt.millisecondsSinceEpoch),
        repeatRule: Value(source.repeatRule),
        extendAt: const Value.absent(),
        createdAt: nowEpochMs,
        updatedAt: nowEpochMs,
      ),
    );
  }

  Future<void> backfillStartId(int id) async {
    await (update(reminders)..where((t) => t.id.equals(id))).write(
      RemindersCompanion(startId: Value(id)),
    );
  }
}
