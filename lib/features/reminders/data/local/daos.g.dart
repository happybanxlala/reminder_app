// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'daos.dart';

// ignore_for_file: type=lint
mixin _$ReminderDaoMixin on DatabaseAccessor<AppDatabase> {
  $TaskTemplatesTable get taskTemplates => attachedDatabase.taskTemplates;
  $TasksTable get tasks => attachedDatabase.tasks;
  $TimelinesTable get timelines => attachedDatabase.timelines;
  $MilestonesTable get milestones => attachedDatabase.milestones;
  ReminderDaoManager get managers => ReminderDaoManager(this);
}

class ReminderDaoManager {
  final _$ReminderDaoMixin _db;
  ReminderDaoManager(this._db);
  $$TaskTemplatesTableTableManager get taskTemplates =>
      $$TaskTemplatesTableTableManager(_db.attachedDatabase, _db.taskTemplates);
  $$TasksTableTableManager get tasks =>
      $$TasksTableTableManager(_db.attachedDatabase, _db.tasks);
  $$TimelinesTableTableManager get timelines =>
      $$TimelinesTableTableManager(_db.attachedDatabase, _db.timelines);
  $$MilestonesTableTableManager get milestones =>
      $$MilestonesTableTableManager(_db.attachedDatabase, _db.milestones);
}
