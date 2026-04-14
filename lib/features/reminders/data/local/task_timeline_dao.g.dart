// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'task_timeline_dao.dart';

// ignore_for_file: type=lint
mixin _$TaskTimelineDaoMixin on DatabaseAccessor<AppDatabase> {
  $TaskTemplatesTable get taskTemplates => attachedDatabase.taskTemplates;
  $TasksTable get tasks => attachedDatabase.tasks;
  $TimelinesTable get timelines => attachedDatabase.timelines;
  $TimelineMilestoneRulesTable get timelineMilestoneRules =>
      attachedDatabase.timelineMilestoneRules;
  $TimelineMilestoneRecordsTable get timelineMilestoneRecords =>
      attachedDatabase.timelineMilestoneRecords;
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
  $$TimelineMilestoneRulesTableTableManager get timelineMilestoneRules =>
      $$TimelineMilestoneRulesTableTableManager(
        _db.attachedDatabase,
        _db.timelineMilestoneRules,
      );
  $$TimelineMilestoneRecordsTableTableManager get timelineMilestoneRecords =>
      $$TimelineMilestoneRecordsTableTableManager(
        _db.attachedDatabase,
        _db.timelineMilestoneRecords,
      );
}
