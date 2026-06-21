import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reminder_app/features/reminders/data/backup_models.dart';
import 'package:reminder_app/features/reminders/data/identity_repository.dart';
import 'package:reminder_app/features/reminders/data/item_repository.dart';
import 'package:reminder_app/features/reminders/data/local/app_database.dart';
import 'package:reminder_app/features/reminders/data/pack_template_repository.dart';
import 'package:reminder_app/features/reminders/data/reminder_backup_service.dart';
import 'package:reminder_app/features/reminders/data/resource_repository.dart';
import 'package:reminder_app/features/reminders/data/shared_pack_repository.dart';
import 'package:reminder_app/features/reminders/data/stage_tracker_models.dart';
import 'package:reminder_app/features/reminders/data/stage_tracker_repository.dart';
import 'package:reminder_app/features/reminders/domain/item.dart';
import 'package:reminder_app/features/reminders/domain/item_pack.dart';
import 'package:reminder_app/features/reminders/domain/resource.dart';
import 'package:reminder_app/features/reminders/domain/shared_pack.dart';
import 'package:reminder_app/features/reminders/domain/stage_occurrence.dart';
import 'package:reminder_app/features/reminders/domain/stage_record.dart';
import 'package:reminder_app/features/reminders/domain/stage_rule.dart';

void main() {
  test('export JSON includes required envelope and user data', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    await _seedUserData(db);
    await IdentityRepository(db.reminderDao).linkRemoteIdentity(
      remoteUserId: 'supabase-user-backup',
      provider: AuthProviderType.supabaseAnonymous,
    );
    final service = ReminderBackupService(db.reminderDao);

    final source = await service.exportJsonString(
      exportedAt: DateTime(2026, 6, 4, 9, 30),
    );
    final json = jsonDecode(source) as Map<String, Object?>;
    final data = json['data'] as Map<String, Object?>;

    expect(json['app'], BackupPayload.appName);
    expect(json['schemaVersion'], BackupPayload.currentSchemaVersion);
    expect(json['exportedAt'], '2026-06-04T09:30:00.000');
    expect(
      data.keys,
      containsAll([
        'packs',
        'items',
        'resources',
        'stages',
        'stageTrackers',
        'customTemplates',
        'relations',
        'activityLogs',
      ]),
    );
    expect(data['items'], isNotEmpty);
    expect(data['resources'], isNotEmpty);
    expect(data['stageTrackers'], isNotEmpty);
    expect(data['customTemplates'], isNotEmpty);
    expect(data['relations'], isNotEmpty);
    expect(data['activityLogs'], isNotEmpty);
    final relations = data['relations'] as List<Object?>;
    final activityLogs = data['activityLogs'] as List<Object?>;
    expect(
      relations.whereType<Map<String, Object?>>().map(
        (row) => row['relationType'],
      ),
      containsAll([
        'localUser',
        'appInstallation',
        'packMember',
        'syncMapping',
        'resourceConsumptionRule',
      ]),
    );
    expect(
      activityLogs.whereType<Map<String, Object?>>().map(
        (row) => row['logType'],
      ),
      containsAll([
        'itemAction',
        'resourceAction',
        'itemCompletion',
        'resourceEvent',
        'stageAcknowledgement',
        'activityEvent',
      ]),
    );
    expect(source, isNot(contains('access_token')));
    expect(source, isNot(contains('refresh_token')));
    expect(source, isNot(contains('oauth')));
    expect(source, isNot(contains('credential')));
    expect(source, isNot(contains('session')));
    expect(source, isNot(contains('service_role')));
    expect(source, isNot(contains('secret')));
    expect(source, isNot(contains('ABCD-1234-EFGH')));
    expect(source, isNot(contains('Invite Code')));
    expect(source, isNot(contains('remoteChangeCount')));
    expect(source, isNot(contains('hasRemoteChanges')));
    expect(source, isNot(contains('realtimeStatus')));
    expect(source, isNot(contains('lastRemoteChange')));
    expect(source, contains('supabase-user-backup'));
    expect(source, contains('supabase_anonymous'));
  });

  test('export excludes system stage tracker and related records', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    await _seedUserData(db);
    final systemTracker = await StageTrackerRepository(
      db.reminderDao,
    ).ensureSystemStageTracker();
    await db.reminderDao.insertStageRule(
      StageRulesCompanion.insert(
        stageTrackerId: systemTracker.id,
        type: StageRuleType.everyNDays.name,
        intervalValue: 1,
        intervalUnit: StageIntervalUnit.days.name,
        createdAt: DateTime(2026, 6, 4).millisecondsSinceEpoch,
        updatedAt: DateTime(2026, 6, 4).millisecondsSinceEpoch,
      ),
    );

    final payload = await ReminderBackupService(db.reminderDao).exportPayload();

    expect(
      payload.data.stageTrackers.any(
        (row) => row['systemKey'] == AppDatabase.systemDefaultStageTrackerKey,
      ),
      isFalse,
    );
    expect(
      payload.data.stageTrackers.any((row) => row['isSystemDefault'] == true),
      isFalse,
    );
    expect(
      payload.data.stages.any(
        (row) => row['stage_tracker_id'] == systemTracker.id,
      ),
      isFalse,
    );
  });

  test(
    'import rejects invalid metadata without modifying existing data',
    () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);
      final itemRepository = ItemRepository(db.reminderDao);
      await itemRepository.createItem(
        const ItemInput(
          title: 'Keep me',
          type: ItemType.stateBased,
          config: StateBasedItemConfig(
            warningAfter: Duration(days: 1),
            dangerAfter: Duration(days: 2),
          ),
        ),
      );
      final service = ReminderBackupService(db.reminderDao);

      await expectLater(
        service.importJsonString('{bad json'),
        throwsA(isA<InvalidBackupFormatException>()),
      );
      await expectLater(
        service.importJsonString(
          jsonEncode({
            'app': 'other_app',
            'schemaVersion': 1,
            'exportedAt': DateTime(2026).toIso8601String(),
            'data': _emptyDataJson(),
          }),
        ),
        throwsA(isA<InvalidBackupAppException>()),
      );
      await expectLater(
        service.importJsonString(
          jsonEncode({
            'app': BackupPayload.appName,
            'schemaVersion': 999,
            'exportedAt': DateTime(2026).toIso8601String(),
            'data': _emptyDataJson(),
          }),
        ),
        throwsA(isA<UnsupportedBackupVersionException>()),
      );

      final items = await itemRepository.watchPackManagementItems().first;
      expect(items.map((item) => item.item.title), contains('Keep me'));
    },
  );

  test('import replaces user data and keeps system seed data', () async {
    final sourceDb = AppDatabase.forTesting(NativeDatabase.memory());
    await _seedUserData(sourceDb);
    await IdentityRepository(sourceDb.reminderDao).linkRemoteIdentity(
      remoteUserId: 'supabase-user-restore-reference',
      provider: AuthProviderType.supabaseAnonymous,
    );
    final backup = await ReminderBackupService(
      sourceDb.reminderDao,
    ).exportJsonString();
    await sourceDb.close();

    final targetDb = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(targetDb.close);
    final targetItemRepository = ItemRepository(targetDb.reminderDao);
    await targetItemRepository.createItem(
      const ItemInput(
        title: 'Old item',
        type: ItemType.stateBased,
        config: StateBasedItemConfig(
          warningAfter: Duration(days: 1),
          dangerAfter: Duration(days: 2),
        ),
      ),
    );

    await ReminderBackupService(targetDb.reminderDao).importJsonString(backup);

    final items = await targetItemRepository.watchPackManagementItems().first;
    final packs = await targetItemRepository
        .watchPacks(includeArchived: true)
        .first;
    final systemTracker = await StageTrackerRepository(
      targetDb.reminderDao,
    ).ensureSystemStageTracker();
    expect(items.map((item) => item.item.title), contains('Clean sink'));
    expect(items.map((item) => item.item.title), isNot(contains('Old item')));
    expect(packs.any((pack) => pack.isSystemDefault), isTrue);
    expect(systemTracker.isSystemDefault, isTrue);
    final sharedPack = packs.firstWhere((pack) => pack.title == 'Housework');
    expect(sharedPack.packType.name, 'shared');
    expect(
      await targetDb.reminderDao.listPackMembers(sharedPack.id),
      isNotEmpty,
    );
    expect(
      await targetDb.reminderDao.listActivityEventsForPack(sharedPack.id),
      isNotEmpty,
    );
    final syncMappings = await targetDb.reminderDao.listSyncMappings();
    expect(syncMappings, isNotEmpty);
    expect(syncMappings.single.remoteEntityId, 'remote-pack-housework');
    final cleanSink = items.firstWhere(
      (item) => item.item.title == 'Clean sink',
    );
    expect(
      await targetDb.reminderDao.listItemCompletions(cleanSink.item.id),
      isNotEmpty,
    );
    expect(
      await ResourceRepository(
        targetDb.reminderDao,
      ).listResourceEventsForPack(sharedPack.id),
      isNotEmpty,
    );
    expect(
      await StageTrackerRepository(
        targetDb.reminderDao,
      ).listStageAcknowledgementsForPack(sharedPack.id),
      isNotEmpty,
    );
    final identity = await IdentityRepository(
      targetDb.reminderDao,
    ).getCurrentAppUser();
    final installations = await targetDb.reminderDao.listAppInstallations();
    expect(identity.id, isNotEmpty);
    expect(identity.identityKind, LocalUserIdentityKind.anonymousRemote);
    expect(identity.remoteUserId, 'supabase-user-restore-reference');
    expect(identity.remoteProvider, AuthProviderType.supabaseAnonymous);
    expect(installations, isNotEmpty);
  });

  test('import accepts v1 backup without shared pack metadata', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);

    final service = ReminderBackupService(db.reminderDao);
    await service.importJsonString(jsonEncode(_v1BackupJson()));

    final itemRepository = ItemRepository(db.reminderDao);
    final packs = await itemRepository.watchPacks(includeArchived: true).first;
    final importedPack = packs.firstWhere((pack) => pack.title == 'Legacy');
    final items = await itemRepository.watchPackManagementItems().first;
    final importedItem = items.firstWhere(
      (bundle) => bundle.item.title == 'Legacy item',
    );

    expect(importedPack.packType, ItemPackType.personal);
    expect(importedPack.hostUserId, isNull);
    expect(importedItem.item.assignedToUserId, isNull);
    final identity = await IdentityRepository(
      db.reminderDao,
    ).getCurrentAppUser();
    expect(identity.id, AppDatabase.defaultHostUserId);
    expect(identity.identityKind, LocalUserIdentityKind.local);
  });

  test('reset clears user data and rebuilds system seed', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    await _seedUserData(db);

    await ReminderBackupService(db.reminderDao).resetDatabase();

    final itemRepository = ItemRepository(db.reminderDao);
    final resourceRepository = ResourceRepository(db.reminderDao);
    final stageRepository = StageTrackerRepository(db.reminderDao);
    final items = await itemRepository.watchPackManagementItems().first;
    final resources = await resourceRepository.watchManagedResources().first;
    final trackers = await stageRepository.watchStageTrackers().first;
    final packs = await itemRepository.watchPacks(includeArchived: true).first;
    expect(items, isEmpty);
    expect(resources, isEmpty);
    expect(trackers.where((tracker) => !tracker.isSystemDefault), isEmpty);
    expect(packs.singleWhere((pack) => pack.isSystemDefault).title, '一般');
    expect(
      (await db.reminderDao.getAppSettings()).notificationReminderTime,
      '09:00',
    );
  });
}

Future<void> _seedUserData(AppDatabase db) async {
  final itemRepository = ItemRepository(db.reminderDao);
  final resourceRepository = ResourceRepository(db.reminderDao);
  final sharedRepository = SharedPackRepository(db.reminderDao);
  final stageRepository = StageTrackerRepository(db.reminderDao);
  final templateRepository = PackTemplateRepository(db.reminderDao);
  final packId = await itemRepository.createPack(
    const ItemPackInput(title: 'Housework', iconEmoji: '🏠'),
  );
  await sharedRepository.convertPackToShared(packId);
  await sharedRepository.addLocalMember(packId);
  await db.reminderDao.upsertSyncMapping(
    SyncMappingsCompanion.insert(
      localEntityType: 'pack',
      localEntityId: packId,
      remoteTable: 'packs',
      remoteEntityId: 'remote-pack-housework',
      syncState: SyncMappingState.pushed.name,
      lastPushedAt: Value(DateTime(2026, 6, 4).millisecondsSinceEpoch),
      createdAt: DateTime(2026, 6, 4).millisecondsSinceEpoch,
      updatedAt: DateTime(2026, 6, 4).millisecondsSinceEpoch,
    ),
  );
  final itemId = await itemRepository.createItem(
    ItemInput(
      title: 'Clean sink',
      type: ItemType.stateBased,
      config: const StateBasedItemConfig(
        warningAfter: Duration(days: 1),
        dangerAfter: Duration(days: 2),
      ),
      packId: packId,
    ),
  );
  await itemRepository.assignItemToUser(
    itemId,
    assignedToUserId: AppDatabase.defaultMemberUserId,
  );
  await itemRepository.markDone(
    itemId,
    doneAt: DateTime(2026, 6, 4),
    actorUserId: AppDatabase.defaultMemberUserId,
  );
  final resourceId = await resourceRepository.createResource(
    ResourceInput(
      title: 'Soap',
      type: ResourceType.quantityBased,
      config: const QuantityBasedResourceConfig(
        currentQuantity: 3,
        unitLabel: '個',
        warningThreshold: 1,
        dangerThreshold: 0,
      ),
      packId: packId,
    ),
  );
  await resourceRepository.createConsumptionRule(
    ResourceConsumptionRuleInput(
      itemId: itemId,
      resourceId: resourceId,
      consumeAmount: 1,
    ),
  );
  await resourceRepository.adjustResourceQuantity(
    resourceId,
    newQuantity: 4,
    actorUserId: AppDatabase.defaultHostUserId,
  );
  final trackerId = await stageRepository.createStageTracker(
    StageTrackerInput(
      title: 'Maintenance',
      trackingStartDate: DateTime(2026, 6, 1),
      packId: packId,
    ),
  );
  await stageRepository.createStageRule(
    trackerId,
    const StageRuleInput(
      type: StageRuleType.everyNDays,
      intervalValue: 7,
      intervalUnit: StageIntervalUnit.days,
    ),
  );
  final stageRecordId = await stageRepository.createImportantStage(
    trackerId,
    ManualStageInput(label: 'Inspection', occurrenceDate: DateTime(2026, 6, 4)),
  );
  await stageRepository.acknowledgeOccurrence(
    StageOccurrence(
      stageTrackerId: trackerId,
      stageRecordId: stageRecordId,
      sourceType: StageRecordSourceType.manual,
      occurrenceDate: DateTime(2026, 6, 4),
      label: 'Inspection',
      reminderOffsetDays: 0,
      recordStatus: StageRecordStatus.normal,
    ),
    actorUserId: AppDatabase.defaultHostUserId,
  );
  await templateRepository.savePackAsTemplate(
    packId: packId,
    templateName: 'Housework template',
  );
}

Map<String, Object?> _v1BackupJson() {
  final now = DateTime(2026, 5, 1).toIso8601String();
  return {
    'app': BackupPayload.appName,
    'schemaVersion': 1,
    'exportedAt': now,
    'data': {
      'packs': [
        {
          'id': 99,
          'title': 'Legacy',
          'description': null,
          'icon_emoji': '📌',
          'order_index': 0,
          'status': 'active',
          'is_system_default': false,
          'created_at': now,
          'updated_at': now,
        },
      ],
      'items': [
        {
          'id': 100,
          'pack_id': 99,
          'title': 'Legacy item',
          'description': null,
          'status': 'active',
          'type': 'stateBased',
          'attention_policy_source': 'systemDefault',
          'fixed_schedule_type': null,
          'fixed_schedule_interval': null,
          'fixed_monthly_day': null,
          'fixed_repeat_rule_v2': null,
          'fixed_anchor_date': null,
          'fixed_due_date': null,
          'fixed_time_of_day': null,
          'fixed_overdue_policy': null,
          'fixed_expected_before_minutes': null,
          'fixed_warning_before_minutes': null,
          'fixed_danger_before_minutes': null,
          'state_anchor_date': null,
          'state_expected_after_minutes': 1440,
          'state_warning_after_minutes': 1440,
          'state_danger_after_minutes': 2880,
          'last_done_at': null,
          'created_at': now,
          'updated_at': now,
        },
      ],
      'resources': [],
      'stages': [],
      'stageTrackers': [],
      'customTemplates': [],
      'relations': [],
      'activityLogs': [],
    },
  };
}

Map<String, Object?> _emptyDataJson() {
  return {
    'packs': [],
    'items': [],
    'resources': [],
    'stages': [],
    'stageTrackers': [],
    'customTemplates': [],
    'relations': [],
    'activityLogs': [],
  };
}
