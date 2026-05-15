// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'reminder_dao.dart';

// ignore_for_file: type=lint
mixin _$ReminderDaoMixin on DatabaseAccessor<AppDatabase> {
  $ItemPacksTable get itemPacks => attachedDatabase.itemPacks;
  $ItemsTable get items => attachedDatabase.items;
  $ResourcesTable get resources => attachedDatabase.resources;
  $ResourceConsumptionRulesTable get resourceConsumptionRules =>
      attachedDatabase.resourceConsumptionRules;
  $ItemActionRecordsTable get itemActionRecords =>
      attachedDatabase.itemActionRecords;
  $ResourceActionRecordsTable get resourceActionRecords =>
      attachedDatabase.resourceActionRecords;
  $StageTrackersTable get stageTrackers => attachedDatabase.stageTrackers;
  $StageRulesTable get stageRules => attachedDatabase.stageRules;
  $StageRecordsTable get stageRecords => attachedDatabase.stageRecords;
  $StageRelatedItemsTable get stageRelatedItems =>
      attachedDatabase.stageRelatedItems;
  $AppSettingsEntriesTable get appSettingsEntries =>
      attachedDatabase.appSettingsEntries;
  ReminderDaoManager get managers => ReminderDaoManager(this);
}

class ReminderDaoManager {
  final _$ReminderDaoMixin _db;
  ReminderDaoManager(this._db);
  $$ItemPacksTableTableManager get itemPacks =>
      $$ItemPacksTableTableManager(_db.attachedDatabase, _db.itemPacks);
  $$ItemsTableTableManager get items =>
      $$ItemsTableTableManager(_db.attachedDatabase, _db.items);
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
  $$StageTrackersTableTableManager get stageTrackers =>
      $$StageTrackersTableTableManager(_db.attachedDatabase, _db.stageTrackers);
  $$StageRulesTableTableManager get stageRules =>
      $$StageRulesTableTableManager(_db.attachedDatabase, _db.stageRules);
  $$StageRecordsTableTableManager get stageRecords =>
      $$StageRecordsTableTableManager(_db.attachedDatabase, _db.stageRecords);
  $$StageRelatedItemsTableTableManager get stageRelatedItems =>
      $$StageRelatedItemsTableTableManager(
        _db.attachedDatabase,
        _db.stageRelatedItems,
      );
  $$AppSettingsEntriesTableTableManager get appSettingsEntries =>
      $$AppSettingsEntriesTableTableManager(
        _db.attachedDatabase,
        _db.appSettingsEntries,
      );
}
