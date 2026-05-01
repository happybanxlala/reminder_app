// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'item_timeline_dao.dart';

// ignore_for_file: type=lint
mixin _$ItemTimelineDaoMixin on DatabaseAccessor<AppDatabase> {
  $ItemPacksTable get itemPacks => attachedDatabase.itemPacks;
  $ItemsTable get items => attachedDatabase.items;
  $ItemPackTemplatesTable get itemPackTemplates =>
      attachedDatabase.itemPackTemplates;
  $ItemTemplateItemsTable get itemTemplateItems =>
      attachedDatabase.itemTemplateItems;
  $ItemActionRecordsTable get itemActionRecords =>
      attachedDatabase.itemActionRecords;
  $TimelinesTable get timelines => attachedDatabase.timelines;
  $TimelineMilestoneRulesTable get timelineMilestoneRules =>
      attachedDatabase.timelineMilestoneRules;
  $TimelineMilestoneRecordsTable get timelineMilestoneRecords =>
      attachedDatabase.timelineMilestoneRecords;
  ItemTimelineDaoManager get managers => ItemTimelineDaoManager(this);
}

class ItemTimelineDaoManager {
  final _$ItemTimelineDaoMixin _db;
  ItemTimelineDaoManager(this._db);
  $$ItemPacksTableTableManager get itemPacks =>
      $$ItemPacksTableTableManager(_db.attachedDatabase, _db.itemPacks);
  $$ItemsTableTableManager get items =>
      $$ItemsTableTableManager(_db.attachedDatabase, _db.items);
  $$ItemPackTemplatesTableTableManager get itemPackTemplates =>
      $$ItemPackTemplatesTableTableManager(
        _db.attachedDatabase,
        _db.itemPackTemplates,
      );
  $$ItemTemplateItemsTableTableManager get itemTemplateItems =>
      $$ItemTemplateItemsTableTableManager(
        _db.attachedDatabase,
        _db.itemTemplateItems,
      );
  $$ItemActionRecordsTableTableManager get itemActionRecords =>
      $$ItemActionRecordsTableTableManager(
        _db.attachedDatabase,
        _db.itemActionRecords,
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
