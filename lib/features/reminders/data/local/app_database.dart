import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'item_timeline_dao.dart';
import 'tables.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [
    ItemPacks,
    Items,
    ItemPackTemplates,
    ItemTemplateItems,
    ItemActionRecords,
    Timelines,
    TimelineMilestoneRules,
    TimelineMilestoneRecords,
  ],
  daos: [ItemTimelineDao],
)
class AppDatabase extends _$AppDatabase {
  static const systemDefaultPackTitle = 'Default Item Pack';
  static const systemDefaultPackDescription = 'System default pack';

  AppDatabase() : super(_openConnection());
  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        await m.addColumn(items, items.fixedScheduleInterval);
        await m.addColumn(items, items.fixedMonthlyDay);
        await m.createTable(itemPackTemplates);
        await m.createTable(itemTemplateItems);
      }
    },
    beforeOpen: (details) async {
      await _ensureSystemDefaultPack();
    },
  );

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
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'reminder_app.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
