import 'package:drift/drift.dart';

import 'app_database.dart';
import 'tables.dart';

part 'daos.g.dart';

@DriftAccessor(tables: [Reminders])
class ReminderDao extends DatabaseAccessor<AppDatabase> with _$ReminderDaoMixin {
  ReminderDao(super.attachedDatabase);

  Stream<List<Reminder>> watchAll() {
    return (select(reminders)
          ..orderBy([(table) => OrderingTerm.desc(table.updatedAt)]))
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
            (table) =>
                table.isDone.equals(false) &
                table.dueAt.isBiggerOrEqualValue(startMs) &
                table.dueAt.isSmallerThanValue(endMs),
          )
          ..orderBy([(table) => OrderingTerm.asc(table.dueAt)]))
        .watch();
  }

  Future<Reminder?> getById(String id) {
    return (select(reminders)..where((table) => table.id.equals(id)))
        .getSingleOrNull();
  }

  Future<int> insert(RemindersCompanion entry) {
    return into(reminders).insert(entry, mode: InsertMode.insertOrReplace);
  }

  Future<bool> update(Reminder reminder) {
    return super.update(reminders).replace(reminder);
  }

  Future<int> delete(String id) {
    return (super.delete(reminders)..where((table) => table.id.equals(id))).go();
  }
}
