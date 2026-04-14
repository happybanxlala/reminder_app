import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'task_timeline_dao.dart';
import 'tables.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [
    TaskTemplates,
    Tasks,
    Timelines,
    TimelineMilestoneRules,
    TimelineMilestoneRecords,
  ],
  daos: [TaskTimelineDao],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());
  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 8;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
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

      if (from == 7) {
        await _migrateFromV7(m);
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
        is_active,
        created_at,
        updated_at
      )
      SELECT
        id,
        CASE display_unit
          WHEN 'day' THEN 'every_n_days'
          WHEN 'week' THEN 'every_n_days'
          WHEN 'month' THEN 'every_n_months'
          ELSE 'every_n_years'
        END,
        CASE display_unit
          WHEN 'week' THEN 7
          ELSE 1
        END,
        CASE display_unit
          WHEN 'day' THEN 'days'
          WHEN 'week' THEN 'days'
          WHEN 'month' THEN 'months'
          ELSE 'years'
        END,
        CASE display_unit
          WHEN 'day' THEN '第 {n} 天'
          WHEN 'week' THEN '第 {n} 週'
          WHEN 'month' THEN '第 {n} 個月'
          ELSE '第 {n} 年'
        END,
        CASE
          WHEN milestone_reminder_rule = 'onDay' THEN 0
          WHEN milestone_reminder_rule LIKE 'advance:%'
            THEN CAST(substr(milestone_reminder_rule, 9) AS INTEGER)
          ELSE 0
        END,
        1,
        created_at,
        updated_at
      FROM timelines_v7
    ''');

    await customStatement('DROP TABLE IF EXISTS milestones_v7');
    await customStatement('DROP TABLE IF EXISTS timelines_v7');
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'reminder_app.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
