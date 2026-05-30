import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'reminder_dao.dart';
import 'tables.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [
    ItemPacks,
    Items,
    PackTemplates,
    PackTemplateItems,
    Resources,
    ResourceConsumptionRules,
    ResourceActionRecords,
    ItemActionRecords,
    StageTrackers,
    StageRules,
    StageRecords,
    StageRelatedItems,
    AppSettingsEntries,
  ],
  daos: [ReminderDao],
)
class AppDatabase extends _$AppDatabase {
  static const systemDefaultPackTitle = '一般';
  static const systemDefaultPackIconEmoji = '📌';
  static const systemDefaultPackOrderIndex = 0;
  static const systemDefaultPackDescription = 'System default pack';
  static const systemDefaultStageTrackerTitle = 'Reminder App';
  static const systemDefaultStageTrackerSubject = '系統';
  static const systemDefaultStageTrackerKey = 'reminder_app';

  AppDatabase() : super(_openConnection());
  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 5;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        await _upgradeToV2(m);
      }
      if (from < 3) {
        await _upgradeToV3(m);
      }
      if (from < 4) {
        await _upgradeToV4(m);
      }
      if (from < 5) {
        await _upgradeToV5(m);
      }
    },
    beforeOpen: (details) async {
      await _ensureSystemDefaultPack();
      await _ensureAppSettings();
      await _ensureSystemDefaultStageTracker();
    },
  );

  Future<void> _upgradeToV2(Migrator m) async {
    await customStatement('PRAGMA foreign_keys = OFF');
    await m.addColumn(itemPacks, itemPacks.iconEmoji);
    await m.addColumn(itemPacks, itemPacks.orderIndex);
    await _ensureSystemDefaultPack();
    final defaultPackId = await _systemDefaultPackId();
    await customStatement('''
      UPDATE stage_trackers
      SET pack_id = $defaultPackId
      WHERE pack_id IS NULL
      ''');
    await customStatement('''
      CREATE TABLE stage_trackers_new (
        id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
        pack_id INTEGER NOT NULL REFERENCES item_packs(id),
        title TEXT NOT NULL,
        subject_name TEXT NULL,
        tracking_start_date INTEGER NOT NULL,
        tracking_end_date INTEGER NULL,
        status TEXT NOT NULL DEFAULT 'active',
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL
      )
      ''');
    await customStatement('''
      INSERT INTO stage_trackers_new (
        id,
        pack_id,
        title,
        subject_name,
        tracking_start_date,
        tracking_end_date,
        status,
        created_at,
        updated_at
      )
      SELECT
        id,
        pack_id,
        title,
        subject_name,
        tracking_start_date,
        tracking_end_date,
        status,
        created_at,
        updated_at
      FROM stage_trackers
      ''');
    await customStatement('DROP TABLE stage_trackers');
    await customStatement(
      'ALTER TABLE stage_trackers_new RENAME TO stage_trackers',
    );
    await customStatement(
      'DROP TABLE IF EXISTS resource_consumption_rule_template_items',
    );
    await customStatement('DROP TABLE IF EXISTS resource_template_items');
    await customStatement('DROP TABLE IF EXISTS item_template_items');
    await customStatement('DROP TABLE IF EXISTS item_pack_templates');
    await customStatement('PRAGMA foreign_keys = ON');
  }

  Future<void> _upgradeToV3(Migrator m) async {
    await m.addColumn(itemActionRecords, itemActionRecords.isReverted);
    await m.addColumn(itemActionRecords, itemActionRecords.revertedAt);
    await m.addColumn(
      itemActionRecords,
      itemActionRecords.revertedByActionRecordId,
    );
    await m.addColumn(resourceActionRecords, resourceActionRecords.isReverted);
    await m.addColumn(resourceActionRecords, resourceActionRecords.revertedAt);
    await m.addColumn(
      resourceActionRecords,
      resourceActionRecords.revertedByActionRecordId,
    );
  }

  Future<void> _upgradeToV4(Migrator m) async {
    await m.addColumn(stageTrackers, stageTrackers.isSystemDefault);
    await m.addColumn(stageTrackers, stageTrackers.systemKey);
    await m.addColumn(stageTrackers, stageTrackers.isHidden);
    await m.addColumn(
      appSettingsEntries,
      appSettingsEntries.notificationReminderTime,
    );
    await customStatement('''
      CREATE UNIQUE INDEX IF NOT EXISTS stage_trackers_system_key_unique
      ON stage_trackers(system_key)
      WHERE system_key IS NOT NULL
      ''');
  }

  Future<void> _upgradeToV5(Migrator m) async {
    await m.createTable(packTemplates);
    await m.createTable(packTemplateItems);
  }

  Future<void> _ensureSystemDefaultPack() async {
    final existingDefault = await customSelect('''
      SELECT id
      FROM item_packs
      WHERE is_system_default = 1
      LIMIT 1
      ''').getSingleOrNull();
    final now = DateTime.now().millisecondsSinceEpoch;

    if (existingDefault != null) {
      await customStatement('''
        UPDATE item_packs
        SET status = 'active',
            title = '$systemDefaultPackTitle',
            icon_emoji = '$systemDefaultPackIconEmoji',
            order_index = $systemDefaultPackOrderIndex
        WHERE is_system_default = 1
        ''');
      return;
    }

    final titledDefault = await customSelect('''
      SELECT id
      FROM item_packs
      WHERE title IN ('$systemDefaultPackTitle', 'Default Item Pack')
      LIMIT 1
      ''').getSingleOrNull();
    if (titledDefault != null) {
      await customStatement('''
        UPDATE item_packs
        SET is_system_default = 1,
            status = 'active',
            title = '$systemDefaultPackTitle',
            icon_emoji = '$systemDefaultPackIconEmoji',
            order_index = $systemDefaultPackOrderIndex
        WHERE id = ${titledDefault.read<int>('id')}
        ''');
      return;
    }

    await into(itemPacks).insert(
      ItemPacksCompanion.insert(
        title: systemDefaultPackTitle,
        description: const Value(systemDefaultPackDescription),
        iconEmoji: const Value(systemDefaultPackIconEmoji),
        orderIndex: const Value(systemDefaultPackOrderIndex),
        status: const Value('active'),
        isSystemDefault: const Value(true),
        createdAt: now,
        updatedAt: now,
      ),
    );
  }

  Future<int> _systemDefaultPackId() async {
    final row = await customSelect('''
      SELECT id
      FROM item_packs
      WHERE is_system_default = 1
      LIMIT 1
      ''').getSingle();
    return row.read<int>('id');
  }

  Future<void> _ensureAppSettings() async {
    final existingSettings = await customSelect('''
      SELECT id
      FROM app_settings
      WHERE id = 1
      LIMIT 1
      ''').getSingleOrNull();
    final now = DateTime.now().millisecondsSinceEpoch;

    if (existingSettings != null) {
      return;
    }

    await into(appSettingsEntries).insert(
      AppSettingsEntriesCompanion.insert(
        id: const Value(1),
        reminderTone: const Value('standard'),
        notificationReminderTime: const Value('09:00'),
        createdAt: now,
        updatedAt: now,
      ),
    );
  }

  Future<void> _ensureSystemDefaultStageTracker() async {
    final existingDefault = await customSelect('''
      SELECT id
      FROM stage_trackers
      WHERE system_key = '$systemDefaultStageTrackerKey'
      LIMIT 1
      ''').getSingleOrNull();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day).millisecondsSinceEpoch;
    final defaultPackId = await _systemDefaultPackId();

    if (existingDefault != null) {
      await customStatement('''
        UPDATE stage_trackers
        SET pack_id = $defaultPackId,
            title = '$systemDefaultStageTrackerTitle',
            subject_name = '$systemDefaultStageTrackerSubject',
            status = 'active',
            is_system_default = 1
        WHERE system_key = '$systemDefaultStageTrackerKey'
        ''');
      return;
    }

    await into(stageTrackers).insert(
      StageTrackersCompanion.insert(
        packId: defaultPackId,
        title: systemDefaultStageTrackerTitle,
        subjectName: const Value(systemDefaultStageTrackerSubject),
        trackingStartDate: today,
        status: const Value('active'),
        isSystemDefault: const Value(true),
        systemKey: const Value(systemDefaultStageTrackerKey),
        isHidden: const Value(false),
        createdAt: now.millisecondsSinceEpoch,
        updatedAt: now.millisecondsSinceEpoch,
      ),
    );
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'reminder_app.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
