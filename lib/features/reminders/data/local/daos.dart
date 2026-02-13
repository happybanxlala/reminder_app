import 'package:drift/drift.dart';

import '../../domain/repeat_rule.dart';
import 'app_database.dart';
import 'tables.dart';

part 'daos.g.dart';

@DriftAccessor(tables: [Reminders])
class ReminderDao extends DatabaseAccessor<AppDatabase>
    with _$ReminderDaoMixin {
  ReminderDao(super.attachedDatabase);

  static const int _dayMs = 86400000;

  Stream<List<Reminder>> watchAll() {
    return (select(reminders)
          ..where((t) => t.status.isNotValue(3))
          ..orderBy([
            (t) => OrderingTerm.asc(t.status),
            (t) => OrderingTerm.asc(t.dueAt),
            (t) => OrderingTerm.desc(t.updatedAt),
          ]))
        .watch();
  }

  Stream<List<Reminder>> watchActivePending() {
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final dueStartExpr = reminders.dueAt - (reminders.remindDays * const Constant(_dayMs));

    return (select(reminders)
          ..where(
            (t) =>
                t.status.equals(0) &
                (t.dueAt.isNull() | dueStartExpr.isSmallerOrEqualValue(nowMs)),
          )
          ..orderBy([
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
                t.status.equals(0) &
                t.dueAt.isNotNull() &
                t.dueAt.isBiggerOrEqualValue(startMs) &
                t.dueAt.isSmallerThanValue(endMs),
          )
          ..orderBy([(t) => OrderingTerm.asc(t.dueAt)]))
        .watch();
  }

  Stream<List<Reminder>> watchCompletedOrSkipped({int limit = 30}) {
    return (select(reminders)
          ..where((t) => t.status.equals(1) | t.status.equals(2))
          ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)])
          ..limit(limit))
        .watch();
  }

  Stream<Reminder?> watchNextReminder() {
    final query = (select(reminders)
      ..where((t) => t.status.equals(0) & t.dueAt.isNotNull())
      ..orderBy([(t) => OrderingTerm.asc(t.dueAt)])
      ..limit(1));
    return query.watchSingleOrNull();
  }

  Future<Reminder?> getById(int id) {
    return (select(reminders)..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  Future<Reminder?> getEditableById(int id) {
    return (select(reminders)..where((t) => t.id.equals(id) & t.status.equals(0)))
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

  Future<void> complete(int id) => _transitionAndMaybeRepeat(id, 1);

  Future<void> skip(int id) => _transitionAndMaybeRepeat(id, 2);

  Future<void> cancel(int id) => _transitionAndMaybeRepeat(id, 3);

  Future<void> restore(int id) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    await (update(reminders)..where((t) => t.id.equals(id))).write(
      RemindersCompanion(status: const Value(0), updatedAt: Value(now)),
    );
  }

  Future<void> _transitionAndMaybeRepeat(int id, int nextStatus) async {
    await transaction(() async {
      final source = await getById(id);
      if (source == null || source.status != 0) {
        return;
      }

      final now = DateTime.now().millisecondsSinceEpoch;
      await (update(reminders)..where((t) => t.id.equals(id))).write(
        RemindersCompanion(status: Value(nextStatus), updatedAt: Value(now)),
      );

      if (nextStatus == 1 || nextStatus == 2) {
        await createRepeatReminder(source, now);
      }
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
