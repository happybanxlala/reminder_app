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
    ItemPackTemplates,
    ItemTemplateItems,
    ResourceTemplateItems,
    ResourceConsumptionRuleTemplateItems,
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
  static const systemDefaultPackTitle = 'Default Item Pack';
  static const systemDefaultPackDescription = 'System default pack';

  AppDatabase() : super(_openConnection());
  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    onUpgrade: (m, from, to) async {
      if (from < to) {
        throw UnsupportedError(
          'No schema upgrades are defined for this initial schema.',
        );
      }
      await customStatement('PRAGMA foreign_keys = OFF');
      await _dropExistingSchemaObjects();
      await m.createAll();
      await customStatement('PRAGMA foreign_keys = ON');
    },
    beforeOpen: (details) async {
      await _ensureSystemDefaultPack();
      await _ensureAppSettings();
    },
  );

  Future<void> _dropExistingSchemaObjects() async {
    final objects = await customSelect('''
      SELECT type, name
      FROM sqlite_master
      WHERE type IN ('trigger', 'view', 'table')
        AND name NOT LIKE 'sqlite_%'
      ORDER BY
        CASE type
          WHEN 'trigger' THEN 0
          WHEN 'view' THEN 1
          ELSE 2
        END
      ''').get();

    for (final object in objects) {
      final type = object.read<String>('type').toUpperCase();
      final name = _quoteIdentifier(object.read<String>('name'));
      await customStatement('DROP $type IF EXISTS $name');
    }
  }

  String _quoteIdentifier(String value) {
    return '"${value.replaceAll('"', '""')}"';
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
            title = '$systemDefaultPackTitle'
        WHERE is_system_default = 1
        ''');
      return;
    }

    final titledDefault = await customSelect('''
      SELECT id
      FROM item_packs
      WHERE title = '$systemDefaultPackTitle'
      LIMIT 1
      ''').getSingleOrNull();
    if (titledDefault != null) {
      await customStatement('''
        UPDATE item_packs
        SET is_system_default = 1,
            status = 'active',
            title = '$systemDefaultPackTitle'
        WHERE id = ${titledDefault.read<int>('id')}
        ''');
      return;
    }

    await into(itemPacks).insert(
      ItemPacksCompanion.insert(
        title: systemDefaultPackTitle,
        description: const Value(systemDefaultPackDescription),
        status: const Value('active'),
        isSystemDefault: const Value(true),
        createdAt: now,
        updatedAt: now,
      ),
    );
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
        createdAt: now,
        updatedAt: now,
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
