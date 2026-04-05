import 'package:drift/drift.dart';

class RecurringReminders extends Table {
  @override
  String get tableName => 'recurring_reminders';

  IntColumn get id => integer().autoIncrement()();

  /// 0: pending, 1: stopped, 2: canceled.
  IntColumn get status => integer().withDefault(const Constant(0))();

  TextColumn get title => text()();

  TextColumn get note => text().nullable()();

  /// 1: countdown, 2: count-up.
  IntColumn get trackingMode => integer()();

  /// 1: in-range, 2: immediate, 3: on-point.
  IntColumn get triggerMode => integer()();

  IntColumn get triggerOffsetDays => integer().nullable()();

  /// Null means not recurring; otherwise D25 / W3 / M1 / Y1.
  TextColumn get repeatRule => text().nullable()();

  IntColumn get topicCategoryId => integer().nullable()();

  IntColumn get actionCategoryId => integer().nullable()();

  IntColumn get createdAt => integer()();

  IntColumn get updatedAt => integer()();
}

class TopicCategories extends Table {
  @override
  String get tableName => 'topic_categories';

  IntColumn get id => integer().autoIncrement()();

  TextColumn get name => text()();

  TextColumn get description => text().nullable()();

  IntColumn get createdAt => integer()();

  IntColumn get updatedAt => integer()();
}

class ActionCategories extends Table {
  @override
  String get tableName => 'action_categories';

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

  IntColumn get recurringReminderId => integer().nullable()();

  IntColumn get previousOccurrenceId => integer().nullable()();

  /// 1: countdown, 2: count-up.
  IntColumn get trackingMode => integer()();

  /// 1: in-range, 2: immediate, 3: on-point.
  IntColumn get triggerMode => integer()();

  /// 0: pending, 1: done, 2: skipped, 3: canceled.
  IntColumn get status => integer().withDefault(const Constant(0))();

  TextColumn get title => text()();

  TextColumn get note => text().nullable()();

  IntColumn get triggerOffsetDays => integer().nullable()();

  TextColumn get statusNote => text().nullable()();

  IntColumn get dueAt => integer().nullable()();

  IntColumn get startAt => integer()();

  IntColumn get deferredDueAt => integer().nullable()();

  IntColumn get topicCategoryId => integer().nullable()();

  IntColumn get actionCategoryId => integer().nullable()();

  IntColumn get createdAt => integer()();

  IntColumn get updatedAt => integer()();
}
