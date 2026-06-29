// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'reminder_dao.dart';

// ignore_for_file: type=lint
mixin _$ReminderDaoMixin on DatabaseAccessor<AppDatabase> {
  $LocalUsersTable get localUsers => attachedDatabase.localUsers;
  $AppInstallationsTable get appInstallations =>
      attachedDatabase.appInstallations;
  $ItemPacksTable get itemPacks => attachedDatabase.itemPacks;
  $PackMembersTable get packMembers => attachedDatabase.packMembers;
  $ItemsTable get items => attachedDatabase.items;
  $PackTemplatesTable get packTemplates => attachedDatabase.packTemplates;
  $PackTemplateItemsTable get packTemplateItems =>
      attachedDatabase.packTemplateItems;
  $ResourcesTable get resources => attachedDatabase.resources;
  $ResourceConsumptionRulesTable get resourceConsumptionRules =>
      attachedDatabase.resourceConsumptionRules;
  $ItemActionRecordsTable get itemActionRecords =>
      attachedDatabase.itemActionRecords;
  $ResourceActionRecordsTable get resourceActionRecords =>
      attachedDatabase.resourceActionRecords;
  $ItemCompletionsTable get itemCompletions => attachedDatabase.itemCompletions;
  $ResourceEventsTable get resourceEvents => attachedDatabase.resourceEvents;
  $StageTrackersTable get stageTrackers => attachedDatabase.stageTrackers;
  $StageRulesTable get stageRules => attachedDatabase.stageRules;
  $StageRecordsTable get stageRecords => attachedDatabase.stageRecords;
  $StageRelatedItemsTable get stageRelatedItems =>
      attachedDatabase.stageRelatedItems;
  $StageAcknowledgementsTable get stageAcknowledgements =>
      attachedDatabase.stageAcknowledgements;
  $ActivityEventsTable get activityEvents => attachedDatabase.activityEvents;
  $SyncMappingsTable get syncMappings => attachedDatabase.syncMappings;
  $RemotePackSyncMetadataTable get remotePackSyncMetadata =>
      attachedDatabase.remotePackSyncMetadata;
  $RemoteItemSyncMetadataTable get remoteItemSyncMetadata =>
      attachedDatabase.remoteItemSyncMetadata;
  $RemoteResourceSyncMetadataTable get remoteResourceSyncMetadata =>
      attachedDatabase.remoteResourceSyncMetadata;
  $RemoteStageSyncMetadataTable get remoteStageSyncMetadata =>
      attachedDatabase.remoteStageSyncMetadata;
  $RemoteCompletionSyncMetadataTable get remoteCompletionSyncMetadata =>
      attachedDatabase.remoteCompletionSyncMetadata;
  $SyncOutboxTable get syncOutbox => attachedDatabase.syncOutbox;
  $AppSettingsEntriesTable get appSettingsEntries =>
      attachedDatabase.appSettingsEntries;
  ReminderDaoManager get managers => ReminderDaoManager(this);
}

class ReminderDaoManager {
  final _$ReminderDaoMixin _db;
  ReminderDaoManager(this._db);
  $$LocalUsersTableTableManager get localUsers =>
      $$LocalUsersTableTableManager(_db.attachedDatabase, _db.localUsers);
  $$AppInstallationsTableTableManager get appInstallations =>
      $$AppInstallationsTableTableManager(
        _db.attachedDatabase,
        _db.appInstallations,
      );
  $$ItemPacksTableTableManager get itemPacks =>
      $$ItemPacksTableTableManager(_db.attachedDatabase, _db.itemPacks);
  $$PackMembersTableTableManager get packMembers =>
      $$PackMembersTableTableManager(_db.attachedDatabase, _db.packMembers);
  $$ItemsTableTableManager get items =>
      $$ItemsTableTableManager(_db.attachedDatabase, _db.items);
  $$PackTemplatesTableTableManager get packTemplates =>
      $$PackTemplatesTableTableManager(_db.attachedDatabase, _db.packTemplates);
  $$PackTemplateItemsTableTableManager get packTemplateItems =>
      $$PackTemplateItemsTableTableManager(
        _db.attachedDatabase,
        _db.packTemplateItems,
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
  $$ItemCompletionsTableTableManager get itemCompletions =>
      $$ItemCompletionsTableTableManager(
        _db.attachedDatabase,
        _db.itemCompletions,
      );
  $$ResourceEventsTableTableManager get resourceEvents =>
      $$ResourceEventsTableTableManager(
        _db.attachedDatabase,
        _db.resourceEvents,
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
  $$StageAcknowledgementsTableTableManager get stageAcknowledgements =>
      $$StageAcknowledgementsTableTableManager(
        _db.attachedDatabase,
        _db.stageAcknowledgements,
      );
  $$ActivityEventsTableTableManager get activityEvents =>
      $$ActivityEventsTableTableManager(
        _db.attachedDatabase,
        _db.activityEvents,
      );
  $$SyncMappingsTableTableManager get syncMappings =>
      $$SyncMappingsTableTableManager(_db.attachedDatabase, _db.syncMappings);
  $$RemotePackSyncMetadataTableTableManager get remotePackSyncMetadata =>
      $$RemotePackSyncMetadataTableTableManager(
        _db.attachedDatabase,
        _db.remotePackSyncMetadata,
      );
  $$RemoteItemSyncMetadataTableTableManager get remoteItemSyncMetadata =>
      $$RemoteItemSyncMetadataTableTableManager(
        _db.attachedDatabase,
        _db.remoteItemSyncMetadata,
      );
  $$RemoteResourceSyncMetadataTableTableManager
  get remoteResourceSyncMetadata =>
      $$RemoteResourceSyncMetadataTableTableManager(
        _db.attachedDatabase,
        _db.remoteResourceSyncMetadata,
      );
  $$RemoteStageSyncMetadataTableTableManager get remoteStageSyncMetadata =>
      $$RemoteStageSyncMetadataTableTableManager(
        _db.attachedDatabase,
        _db.remoteStageSyncMetadata,
      );
  $$RemoteCompletionSyncMetadataTableTableManager
  get remoteCompletionSyncMetadata =>
      $$RemoteCompletionSyncMetadataTableTableManager(
        _db.attachedDatabase,
        _db.remoteCompletionSyncMetadata,
      );
  $$SyncOutboxTableTableManager get syncOutbox =>
      $$SyncOutboxTableTableManager(_db.attachedDatabase, _db.syncOutbox);
  $$AppSettingsEntriesTableTableManager get appSettingsEntries =>
      $$AppSettingsEntriesTableTableManager(
        _db.attachedDatabase,
        _db.appSettingsEntries,
      );
}
