import 'package:drift/drift.dart';

class Reminders extends Table {
  IntColumn get id => integer().autoIncrement()();

  IntColumn get startId => integer().withDefault(const Constant(0))();

  TextColumn get title => text()();

  TextColumn get note => text().nullable()();

  IntColumn get remindDays => integer().withDefault(const Constant(0))();

  /// Epoch milliseconds, nullable when no due date is set.
  IntColumn get dueAt => integer().nullable()();

  /// Null means no recurrence, otherwise D25 / W3 / N1 / Y1.
  TextColumn get repeatRule => text().nullable()();

  /// 0: pending, 1: done, 2: skipped, 3: canceled.
  IntColumn get status => integer().withDefault(const Constant(0))();

  IntColumn get extendAt => integer().nullable()();

  IntColumn get createdAt => integer()();

  IntColumn get updatedAt => integer()();
}
