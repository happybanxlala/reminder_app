import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reminder_app/features/reminders/data/backup_models.dart';
import 'package:reminder_app/features/reminders/data/item_repository.dart';
import 'package:reminder_app/features/reminders/data/local/app_database.dart';
import 'package:reminder_app/features/reminders/data/pack_template_repository.dart';
import 'package:reminder_app/features/reminders/data/reminder_backup_service.dart';
import 'package:reminder_app/features/reminders/data/resource_repository.dart';
import 'package:reminder_app/features/reminders/data/stage_tracker_models.dart';
import 'package:reminder_app/features/reminders/data/stage_tracker_repository.dart';
import 'package:reminder_app/features/reminders/domain/item.dart';
import 'package:reminder_app/features/reminders/domain/item_pack.dart';
import 'package:reminder_app/features/reminders/domain/resource.dart';
import 'package:reminder_app/features/reminders/domain/stage_rule.dart';

void main() {
  test('export JSON includes required envelope and user data', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    await _seedUserData(db);
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
  final stageRepository = StageTrackerRepository(db.reminderDao);
  final templateRepository = PackTemplateRepository(db.reminderDao);
  final packId = await itemRepository.createPack(
    const ItemPackInput(title: 'Housework', iconEmoji: '🏠'),
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
  await stageRepository.createImportantStage(
    trackerId,
    ManualStageInput(label: 'Inspection', occurrenceDate: DateTime(2026, 6, 4)),
  );
  await templateRepository.savePackAsTemplate(
    packId: packId,
    templateName: 'Housework template',
  );
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
