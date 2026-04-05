// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'daos.dart';

// ignore_for_file: type=lint
mixin _$ReminderDaoMixin on DatabaseAccessor<AppDatabase> {
  $ReminderSeriesEntriesTable get reminderSeriesEntries =>
      attachedDatabase.reminderSeriesEntries;
  $IssueTypesTable get issueTypes => attachedDatabase.issueTypes;
  $HandleTypesTable get handleTypes => attachedDatabase.handleTypes;
  $RemindersTable get reminders => attachedDatabase.reminders;
  ReminderDaoManager get managers => ReminderDaoManager(this);
}

class ReminderDaoManager {
  final _$ReminderDaoMixin _db;
  ReminderDaoManager(this._db);
  $$ReminderSeriesEntriesTableTableManager get reminderSeriesEntries =>
      $$ReminderSeriesEntriesTableTableManager(
        _db.attachedDatabase,
        _db.reminderSeriesEntries,
      );
  $$IssueTypesTableTableManager get issueTypes =>
      $$IssueTypesTableTableManager(_db.attachedDatabase, _db.issueTypes);
  $$HandleTypesTableTableManager get handleTypes =>
      $$HandleTypesTableTableManager(_db.attachedDatabase, _db.handleTypes);
  $$RemindersTableTableManager get reminders =>
      $$RemindersTableTableManager(_db.attachedDatabase, _db.reminders);
}
