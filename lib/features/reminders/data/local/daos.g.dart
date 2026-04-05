// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'daos.dart';

// ignore_for_file: type=lint
mixin _$ReminderDaoMixin on DatabaseAccessor<AppDatabase> {
  $RecurringRemindersTable get recurringReminders =>
      attachedDatabase.recurringReminders;
  $TopicCategoriesTable get topicCategories => attachedDatabase.topicCategories;
  $ActionCategoriesTable get actionCategories =>
      attachedDatabase.actionCategories;
  $RemindersTable get reminders => attachedDatabase.reminders;
  ReminderDaoManager get managers => ReminderDaoManager(this);
}

class ReminderDaoManager {
  final _$ReminderDaoMixin _db;
  ReminderDaoManager(this._db);
  $$RecurringRemindersTableTableManager get recurringReminders =>
      $$RecurringRemindersTableTableManager(
        _db.attachedDatabase,
        _db.recurringReminders,
      );
  $$TopicCategoriesTableTableManager get topicCategories =>
      $$TopicCategoriesTableTableManager(
        _db.attachedDatabase,
        _db.topicCategories,
      );
  $$ActionCategoriesTableTableManager get actionCategories =>
      $$ActionCategoriesTableTableManager(
        _db.attachedDatabase,
        _db.actionCategories,
      );
  $$RemindersTableTableManager get reminders =>
      $$RemindersTableTableManager(_db.attachedDatabase, _db.reminders);
}
