import 'package:drift/drift.dart';

class Reminders extends Table {
  TextColumn get id => text()();

  TextColumn get title => text()();

  TextColumn get note => text().nullable()();

  /// Epoch milliseconds, nullable when no due date is set.
  IntColumn get dueAt => integer().nullable()();

  IntColumn get repeatRule => integer().withDefault(const Constant(0))();

  BoolColumn get isDone => boolean().withDefault(const Constant(false))();

  IntColumn get createdAt => integer()();

  IntColumn get updatedAt => integer()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
