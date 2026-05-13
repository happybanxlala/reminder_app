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
  $ResourceTemplateItemsTable get resourceTemplateItems =>
      attachedDatabase.resourceTemplateItems;
  $ResourceConsumptionRuleTemplateItemsTable
  get resourceConsumptionRuleTemplateItems =>
      attachedDatabase.resourceConsumptionRuleTemplateItems;
  $ResourcesTable get resources => attachedDatabase.resources;
  $ResourceConsumptionRulesTable get resourceConsumptionRules =>
      attachedDatabase.resourceConsumptionRules;
  $ItemActionRecordsTable get itemActionRecords =>
      attachedDatabase.itemActionRecords;
  $ResourceActionRecordsTable get resourceActionRecords =>
      attachedDatabase.resourceActionRecords;
  $TimelinesTable get timelines => attachedDatabase.timelines;
  $TimelineMilestoneRulesTable get timelineMilestoneRules =>
      attachedDatabase.timelineMilestoneRules;
  $TimelineMilestoneRecordsTable get timelineMilestoneRecords =>
      attachedDatabase.timelineMilestoneRecords;
  $AppSettingsEntriesTable get appSettingsEntries =>
      attachedDatabase.appSettingsEntries;
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
  $$ResourceTemplateItemsTableTableManager get resourceTemplateItems =>
      $$ResourceTemplateItemsTableTableManager(
        _db.attachedDatabase,
        _db.resourceTemplateItems,
      );
  $$ResourceConsumptionRuleTemplateItemsTableTableManager
  get resourceConsumptionRuleTemplateItems =>
      $$ResourceConsumptionRuleTemplateItemsTableTableManager(
        _db.attachedDatabase,
        _db.resourceConsumptionRuleTemplateItems,
      );
  $$ResourcesTableTableManager get resources =>
      $$ResourcesTableTableManager(_db.attachedDatabase, _db.resources);
  $$ResourceConsumptionRulesTableTableManager get resourceConsumptionRules =>
      $$ResourceConsumptionRulesTableTableManager(
        _db.attachedDatabase,
        _db.resourceConsumptionRules,
      );
  $$ItemActionRecordsTableTableManager get itemActionRecords =>
      $$ItemActionRecordsTableTableManager(
        _db.attachedDatabase,
        _db.itemActionRecords,
      );
  $$ResourceActionRecordsTableTableManager get resourceActionRecords =>
      $$ResourceActionRecordsTableTableManager(
        _db.attachedDatabase,
        _db.resourceActionRecords,
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
  $$AppSettingsEntriesTableTableManager get appSettingsEntries =>
      $$AppSettingsEntriesTableTableManager(
        _db.attachedDatabase,
        _db.appSettingsEntries,
      );
}
