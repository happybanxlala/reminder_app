// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'responsibility_timeline_dao.dart';

// ignore_for_file: type=lint
mixin _$ResponsibilityTimelineDaoMixin on DatabaseAccessor<AppDatabase> {
  $ResponsibilityPacksTable get responsibilityPacks =>
      attachedDatabase.responsibilityPacks;
  $ResponsibilityItemsTable get responsibilityItems =>
      attachedDatabase.responsibilityItems;
  $TimelinesTable get timelines => attachedDatabase.timelines;
  $TimelineMilestoneRulesTable get timelineMilestoneRules =>
      attachedDatabase.timelineMilestoneRules;
  $TimelineMilestoneRecordsTable get timelineMilestoneRecords =>
      attachedDatabase.timelineMilestoneRecords;
  ResponsibilityTimelineDaoManager get managers =>
      ResponsibilityTimelineDaoManager(this);
}

class ResponsibilityTimelineDaoManager {
  final _$ResponsibilityTimelineDaoMixin _db;
  ResponsibilityTimelineDaoManager(this._db);
  $$ResponsibilityPacksTableTableManager get responsibilityPacks =>
      $$ResponsibilityPacksTableTableManager(
        _db.attachedDatabase,
        _db.responsibilityPacks,
      );
  $$ResponsibilityItemsTableTableManager get responsibilityItems =>
      $$ResponsibilityItemsTableTableManager(
        _db.attachedDatabase,
        _db.responsibilityItems,
      );
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
