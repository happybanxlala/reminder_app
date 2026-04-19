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
    ItemActionRecords,
    Timelines,
    TimelineMilestoneRules,
    TimelineMilestoneRecords,
  ],
  daos: [ItemTimelineDao],
)
class AppDatabase extends _$AppDatabase {
  static const legacySystemDefaultPackTitle = 'Default Responsibility Pack';
  static const systemDefaultPackTitle = 'Default Item Pack';
  static const systemDefaultPackDescription = 'System default pack';

  AppDatabase() : super(_openConnection());
  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 14;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    beforeOpen: (details) async {
      await _ensureSystemDefaultPack();
    },
    onUpgrade: (m, from, to) async {
      if (from < 7) {
        await customStatement('DROP TABLE IF EXISTS reminders');
        await customStatement('DROP TABLE IF EXISTS recurring_reminders');
        await customStatement('DROP TABLE IF EXISTS reminder_series');
        await customStatement('DROP TABLE IF EXISTS issue_types');
        await customStatement('DROP TABLE IF EXISTS topic_categories');
        await customStatement('DROP TABLE IF EXISTS handle_types');
        await customStatement('DROP TABLE IF EXISTS action_categories');
        await customStatement('DROP TABLE IF EXISTS task_templates');
        await customStatement('DROP TABLE IF EXISTS tasks');
        await customStatement('DROP TABLE IF EXISTS timelines');
        await customStatement('DROP TABLE IF EXISTS milestones');
        await customStatement('DROP TABLE IF EXISTS timeline_milestone_rules');
        await customStatement(
          'DROP TABLE IF EXISTS timeline_milestone_records',
        );
        await m.createAll();
        return;
      }

      var currentFrom = from;

      if (currentFrom == 7) {
        await _migrateFromV7(m);
        currentFrom = 9;
      }

      if (currentFrom == 8) {
        await _migrateFromV8(m);
        currentFrom = 9;
      }

      if (currentFrom == 9) {
        await _migrateFromV9ToV10(m);
        currentFrom = 14;
      }

      if (currentFrom == 10) {
        await _migrateFromV10ToV11(m);
        currentFrom = 11;
      }

      if (currentFrom == 11) {
        await _migrateFromV11ToV12();
        currentFrom = 12;
      }

      if (currentFrom == 12) {
        await _migrateFromV12ToV13();
        currentFrom = 13;
      }

      if (currentFrom == 13) {
        await _migrateFromV13ToV14(m);
      }
    },
  );

  Future<void> _migrateFromV7(Migrator m) async {
    await customStatement('ALTER TABLE timelines RENAME TO timelines_v7');
    await customStatement('ALTER TABLE milestones RENAME TO milestones_v7');

    await m.createTable(timelines);
    await m.createTable(timelineMilestoneRules);
    await m.createTable(timelineMilestoneRecords);

    await customStatement('''
      INSERT INTO timelines (id, title, start_date, display_unit, status, created_at, updated_at)
      SELECT id, title, start_date, display_unit, status, created_at, updated_at
      FROM timelines_v7
    ''');

    await customStatement('''
      INSERT INTO timeline_milestone_rules (
        timeline_id,
        type,
        interval_value,
        interval_unit,
          label_template,
          reminder_offset_days,
          status,
          created_at,
          updated_at
      )
      SELECT
        id,
        CASE display_unit
          WHEN 'day' THEN 'every_n_days'
          WHEN 'week' THEN 'every_n_weeks'
          WHEN 'month' THEN 'every_n_months'
          ELSE 'every_n_years'
        END,
        CASE display_unit
          WHEN 'week' THEN 1
          ELSE 1
        END,
        CASE display_unit
          WHEN 'day' THEN 'days'
          WHEN 'week' THEN 'weeks'
          WHEN 'month' THEN 'months'
          ELSE 'years'
        END,
        CASE display_unit
          WHEN 'day' THEN '第 {value}{unit}'
          WHEN 'week' THEN '第 {value}{unit}'
          WHEN 'month' THEN '第 {value}{unit}'
          ELSE '第 {value}{unit}'
        END,
        CASE
          WHEN milestone_reminder_rule = 'onDay' THEN 0
          WHEN milestone_reminder_rule LIKE 'advance:%'
            THEN CAST(substr(milestone_reminder_rule, 9) AS INTEGER)
          ELSE 0
        END,
        'active',
        created_at,
        updated_at
      FROM timelines_v7
    ''');

    await customStatement('DROP TABLE IF EXISTS milestones_v7');
    await customStatement('DROP TABLE IF EXISTS timelines_v7');
  }

  Future<void> _migrateFromV8(Migrator m) async {
    await customStatement(
      'ALTER TABLE timeline_milestone_rules RENAME TO timeline_milestone_rules_v8',
    );
    await m.createTable(timelineMilestoneRules);
    await customStatement('''
      INSERT INTO timeline_milestone_rules (
        id,
        timeline_id,
        type,
        interval_value,
        interval_unit,
        label_template,
        reminder_offset_days,
        status,
        created_at,
        updated_at
      )
      SELECT
        id,
        timeline_id,
        type,
        interval_value,
        interval_unit,
        label_template,
        reminder_offset_days,
        CASE
          WHEN is_active = 1 THEN 'active'
          ELSE 'paused'
        END,
        created_at,
        updated_at
      FROM timeline_milestone_rules_v8
    ''');
    await customStatement('DROP TABLE IF EXISTS timeline_milestone_rules_v8');
  }

  Future<void> _migrateFromV9ToV10(Migrator m) async {
    await m.createTable(itemPacks);
    await m.createTable(items);
    await customStatement('DROP TABLE IF EXISTS task_templates');
    await customStatement('DROP TABLE IF EXISTS tasks');
  }

  Future<void> _migrateFromV10ToV11(Migrator m) async {
    await customStatement(
      "ALTER TABLE responsibility_packs ADD COLUMN status TEXT NOT NULL DEFAULT 'active'",
    );
    await customStatement(
      'ALTER TABLE responsibility_packs ADD COLUMN is_system_default INTEGER NOT NULL DEFAULT 0',
    );
    await customStatement(
      "UPDATE responsibility_packs SET status = 'active' WHERE status IS NULL OR status = ''",
    );
    await customStatement('''
      UPDATE responsibility_packs
      SET is_system_default = 1
      WHERE title IN ('$legacySystemDefaultPackTitle', '$systemDefaultPackTitle')
      ''');
  }

  Future<void> _migrateFromV11ToV12() async {
    await customStatement(
      'ALTER TABLE responsibility_packs RENAME TO item_packs',
    );
    await customStatement('ALTER TABLE responsibility_items RENAME TO items');
  }

  Future<void> _migrateFromV12ToV13() async {
    final columns = await customSelect('PRAGMA table_info(items)').get();
    final hasStatusColumn = columns.any(
      (row) => row.read<String>('name') == 'status',
    );
    if (hasStatusColumn) {
      return;
    }
    await customStatement(
      "ALTER TABLE items ADD COLUMN status TEXT NOT NULL DEFAULT 'active'",
    );
    await customStatement(
      "UPDATE items SET status = 'active' WHERE status IS NULL OR status = ''",
    );
  }

  Future<void> _migrateFromV13ToV14(Migrator m) async {
    await customStatement('ALTER TABLE items RENAME TO items_v13');
    await m.createTable(items);
    await m.createTable(itemActionRecords);
    await customStatement('''
      INSERT INTO items (
        id,
        pack_id,
        title,
        description,
        status,
        type,
        fixed_schedule_type,
        fixed_anchor_date,
        fixed_due_date,
        fixed_time_of_day,
        fixed_overdue_policy,
        fixed_expected_before_minutes,
        fixed_warning_before_minutes,
        fixed_danger_before_minutes,
        state_expected_after_minutes,
        state_warning_after_minutes,
        state_danger_after_minutes,
        resource_anchor_date,
        resource_duration_days,
        resource_expected_before_days,
        resource_warning_before_days,
        resource_danger_before_days,
        last_done_at,
        created_at,
        updated_at
      )
      SELECT
        id,
        pack_id,
        title,
        description,
        status,
        CASE type
          WHEN 'fixedTime' THEN 'fixed'
          ELSE type
        END,
        fixed_schedule_type,
        fixed_anchor_date,
        fixed_anchor_date,
        fixed_time_of_day,
        'autoAdvance',
        0,
        0,
        0,
        state_expected_interval_minutes,
        state_warning_after_minutes,
        state_danger_after_minutes,
        last_done_at,
        CAST(resource_estimated_duration_minutes / 1440 AS INTEGER),
        0,
        CAST(resource_warning_before_depletion_minutes / 1440 AS INTEGER),
        0,
        last_done_at,
        created_at,
        updated_at
      FROM items_v13
    ''');
    await customStatement('DROP TABLE IF EXISTS items_v13');
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
      WHERE title IN ('$legacySystemDefaultPackTitle', '$systemDefaultPackTitle')
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
