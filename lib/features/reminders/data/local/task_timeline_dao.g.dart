// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'task_timeline_dao.dart';

// ignore_for_file: type=lint
mixin _$TaskTimelineDaoMixin on DatabaseAccessor<AppDatabase> {
  $TaskTemplatesTable get taskTemplates => attachedDatabase.taskTemplates;
  $TasksTable get tasks => attachedDatabase.tasks;
  $TimelinesTable get timelines => attachedDatabase.timelines;
  $MilestonesTable get milestones => attachedDatabase.milestones;
  TaskTimelineDaoManager get managers => TaskTimelineDaoManager(this);
}

class TaskTimelineDaoManager {
  final _$TaskTimelineDaoMixin _db;
  TaskTimelineDaoManager(this._db);
  $$TaskTemplatesTableTableManager get taskTemplates =>
      $$TaskTemplatesTableTableManager(_db.attachedDatabase, _db.taskTemplates);
  $$TasksTableTableManager get tasks =>
      $$TasksTableTableManager(_db.attachedDatabase, _db.tasks);
  $$TimelinesTableTableManager get timelines =>
      $$TimelinesTableTableManager(_db.attachedDatabase, _db.timelines);
  $$MilestonesTableTableManager get milestones =>
      $$MilestonesTableTableManager(_db.attachedDatabase, _db.milestones);
}
