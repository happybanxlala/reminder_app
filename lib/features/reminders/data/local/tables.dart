import 'package:drift/drift.dart';

class ReminderSeriesEntries extends Table {
  @override
  String get tableName => 'reminder_series';

  IntColumn get id => integer().autoIncrement()();

  /// 0: pending, 1: stopped, 2: canceled.
  IntColumn get status => integer().withDefault(const Constant(0))();

  TextColumn get title => text()();

  TextColumn get note => text().nullable()();

  /// 1: countdown, 2: count-up.
  IntColumn get timeBasis => integer()();

  /// 1: in-range, 2: immediate, 3: on-point.
  IntColumn get notifyStrategy => integer()();

  IntColumn get remindDays => integer().nullable()();

  /// Null means not recurring; otherwise D25 / W3 / M1 / Y1.
  TextColumn get repeatRule => text().nullable()();

  IntColumn get issueTypeId => integer().nullable()();

  IntColumn get handleTypeId => integer().nullable()();

  IntColumn get createdAt => integer()();

  IntColumn get updatedAt => integer()();
}

class IssueTypes extends Table {
  @override
  String get tableName => 'issue_types';

  IntColumn get id => integer().autoIncrement()();

  TextColumn get name => text()();

  TextColumn get description => text().nullable()();

  IntColumn get createdAt => integer()();

  IntColumn get updatedAt => integer()();
}

class HandleTypes extends Table {
  @override
  String get tableName => 'handle_types';

  IntColumn get id => integer().autoIncrement()();

  TextColumn get name => text()();

  TextColumn get description => text().nullable()();

  IntColumn get createdAt => integer()();

  IntColumn get updatedAt => integer()();
}

class Reminders extends Table {
  @override
  String get tableName => 'reminders';

  IntColumn get id => integer().autoIncrement()();

  IntColumn get seriesId => integer().nullable()();

  IntColumn get previousReminderId => integer().nullable()();

  /// 1: countdown, 2: count-up.
  IntColumn get timeBasis => integer()();

  /// 1: in-range, 2: immediate, 3: on-point.
  IntColumn get notifyStrategy => integer()();

  /// 0: pending, 1: done, 2: skipped, 3: canceled.
  IntColumn get status => integer().withDefault(const Constant(0))();

  TextColumn get title => text()();

  TextColumn get note => text().nullable()();

  IntColumn get remindDays => integer().nullable()();

  TextColumn get remark => text().nullable()();

  IntColumn get dueAt => integer().nullable()();

  IntColumn get startAt => integer()();

  IntColumn get extendAt => integer().nullable()();

  IntColumn get issueTypeId => integer().nullable()();

  IntColumn get handleTypeId => integer().nullable()();

  IntColumn get createdAt => integer()();

  IntColumn get updatedAt => integer()();
}
