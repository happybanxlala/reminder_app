import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reminder_app/features/reminders/data/local/app_database.dart';
// ignore: depend_on_referenced_packages
import 'package:sqlite3/sqlite3.dart';

void main() {
  test(
    'database uses schema version 14 and item pack/item plus timeline tables are writable',
    () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);

      expect(db.schemaVersion, 14);

      final packId = await db
          .into(db.itemPacks)
          .insert(
            ItemPacksCompanion.insert(
              title: 'Cats',
              description: const Value('Cat care'),
              status: const Value('active'),
              isSystemDefault: const Value(false),
              createdAt: DateTime(2026, 4, 1).millisecondsSinceEpoch,
              updatedAt: DateTime(2026, 4, 1).millisecondsSinceEpoch,
            ),
          );

      final itemId = await db
          .into(db.items)
          .insert(
            ItemsCompanion.insert(
              packId: packId,
              title: 'Clean litter box',
              description: const Value('State based'),
              type: 'stateBased',
              fixedScheduleType: const Value.absent(),
              fixedAnchorDate: const Value.absent(),
              fixedDueDate: const Value.absent(),
              fixedTimeOfDay: const Value.absent(),
              fixedOverduePolicy: const Value.absent(),
              fixedExpectedBeforeMinutes: const Value.absent(),
              fixedWarningBeforeMinutes: const Value.absent(),
              fixedDangerBeforeMinutes: const Value.absent(),
              stateExpectedAfterMinutes: const Value(2880),
              stateWarningAfterMinutes: const Value(2880),
              stateDangerAfterMinutes: const Value(5760),
              resourceAnchorDate: const Value.absent(),
              resourceDurationDays: const Value.absent(),
              resourceExpectedBeforeDays: const Value.absent(),
              resourceWarningBeforeDays: const Value.absent(),
              resourceDangerBeforeDays: const Value.absent(),
              lastDoneAt: const Value.absent(),
              createdAt: DateTime(2026, 4, 1).millisecondsSinceEpoch,
              updatedAt: DateTime(2026, 4, 1).millisecondsSinceEpoch,
            ),
          );

      final timelineId = await db
          .into(db.timelines)
          .insert(
            TimelinesCompanion.insert(
              title: 'Timeline smoke test',
              startDate: DateTime(2026, 4, 10).millisecondsSinceEpoch,
              displayUnit: 'day',
              status: 'active',
              createdAt: DateTime(2026, 4, 1).millisecondsSinceEpoch,
              updatedAt: DateTime(2026, 4, 1).millisecondsSinceEpoch,
            ),
          );

      final ruleId = await db
          .into(db.timelineMilestoneRules)
          .insert(
            TimelineMilestoneRulesCompanion.insert(
              timelineId: timelineId,
              type: 'every_n_days',
              intervalValue: 1,
              intervalUnit: 'days',
              labelTemplate: const Value('第 {value}{unit}'),
              reminderOffsetDays: const Value(0),
              status: const Value('active'),
              createdAt: DateTime(2026, 4, 1).millisecondsSinceEpoch,
              updatedAt: DateTime(2026, 4, 1).millisecondsSinceEpoch,
            ),
          );

      final recordId = await db
          .into(db.timelineMilestoneRecords)
          .insert(
            TimelineMilestoneRecordsCompanion.insert(
              timelineId: timelineId,
              ruleId: ruleId,
              occurrenceIndex: 1,
              targetDate: DateTime(2026, 4, 10).millisecondsSinceEpoch,
              status: 'noticed',
              actedAt: Value(DateTime(2026, 4, 10).millisecondsSinceEpoch),
              createdAt: DateTime(2026, 4, 1).millisecondsSinceEpoch,
              updatedAt: DateTime(2026, 4, 1).millisecondsSinceEpoch,
            ),
          );

      expect(packId, greaterThan(0));
      expect(itemId, greaterThan(0));
      expect(timelineId, greaterThan(0));
      expect(ruleId, greaterThan(0));
      expect(recordId, greaterThan(0));

      final defaultPacks = await (db.select(
        db.itemPacks,
      )..where((t) => t.isSystemDefault.equals(true))).get();
      final items = await db.select(db.items).get();
      expect(defaultPacks, hasLength(1));
      expect(items.single.status, 'active');
    },
  );

  test(
    'v9 migration preserves timeline data and drops legacy task tables',
    () async {
      final tempDir = await Directory.systemTemp.createTemp('item-migration');
      addTearDown(() async {
        if (await tempDir.exists()) {
          await tempDir.delete(recursive: true);
        }
      });
      final file = File('${tempDir.path}/migration.sqlite');

      final sqlite = sqlite3.open(file.path);
      sqlite.execute('PRAGMA user_version = 9');
      sqlite.execute('''
      CREATE TABLE task_templates (
        id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        category_id INTEGER,
        note TEXT,
        kind TEXT NOT NULL,
        status TEXT NOT NULL,
        first_due_date INTEGER NOT NULL,
        repeat_rule TEXT,
        reminder_rule TEXT NOT NULL,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');
      sqlite.execute('''
      CREATE TABLE tasks (
        id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
        template_id INTEGER,
        kind TEXT NOT NULL,
        title_snapshot TEXT NOT NULL,
        note_snapshot TEXT,
        category_id INTEGER,
        due_date INTEGER NOT NULL,
        repeat_rule TEXT,
        reminder_rule TEXT NOT NULL,
        deferred_due_date INTEGER,
        status TEXT NOT NULL,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        resolved_at INTEGER
      )
    ''');
      sqlite.execute('''
      CREATE TABLE timelines (
        id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        start_date INTEGER NOT NULL,
        display_unit TEXT NOT NULL,
        status TEXT NOT NULL,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');
      sqlite.execute('''
      CREATE TABLE timeline_milestone_rules (
        id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
        timeline_id INTEGER NOT NULL,
        type TEXT NOT NULL,
        interval_value INTEGER NOT NULL,
        interval_unit TEXT NOT NULL,
        label_template TEXT,
        reminder_offset_days INTEGER NOT NULL DEFAULT 0,
        status TEXT NOT NULL DEFAULT 'active',
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');
      sqlite.execute('''
      CREATE TABLE timeline_milestone_records (
        id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
        timeline_id INTEGER NOT NULL,
        rule_id INTEGER NOT NULL,
        occurrence_index INTEGER NOT NULL,
        target_date INTEGER NOT NULL,
        status TEXT NOT NULL,
        notified_at INTEGER,
        acted_at INTEGER,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        UNIQUE(timeline_id, rule_id, occurrence_index)
      )
    ''');
      sqlite.execute('''
      INSERT INTO tasks (
        id, template_id, kind, title_snapshot, due_date, reminder_rule, status, created_at, updated_at
      ) VALUES (
        1, NULL, 'oneTime', 'Legacy task', 1775779200000, 'onDue', 'pending', 1775001600000, 1775001600000
      )
    ''');
      sqlite.execute('''
      INSERT INTO timelines (
        id, title, start_date, display_unit, status, created_at, updated_at
      ) VALUES (
        1, 'No sugar', 1775779200000, 'day', 'active', 1775001600000, 1775001600000
      )
    ''');
      sqlite.execute('''
      INSERT INTO timeline_milestone_rules (
        id, timeline_id, type, interval_value, interval_unit, label_template, reminder_offset_days, status, created_at, updated_at
      ) VALUES (
        1, 1, 'every_n_days', 10, 'days', '第 {value}{unit}', 0, 'active', 1775001600000, 1775001600000
      )
    ''');
      sqlite.execute('''
      INSERT INTO timeline_milestone_records (
        id, timeline_id, rule_id, occurrence_index, target_date, status, acted_at, created_at, updated_at
      ) VALUES (
        1, 1, 1, 1, 1776556800000, 'noticed', 1776556800000, 1775001600000, 1775001600000
      )
    ''');
      sqlite.close();

      final db = AppDatabase.forTesting(NativeDatabase(file));
      addTearDown(db.close);

      final packs = await db.select(db.itemPacks).get();
      final items = await db.select(db.items).get();
      final timelines = await db.select(db.timelines).get();
      final rules = await db.select(db.timelineMilestoneRules).get();
      final records = await db.select(db.timelineMilestoneRecords).get();
      final legacyTables = await db
          .customSelect(
            "SELECT name FROM sqlite_master WHERE type = 'table' AND name IN ('task_templates', 'tasks')",
          )
          .get();

      expect(db.schemaVersion, 14);
      expect(packs, hasLength(1));
      expect(packs.single.title, AppDatabase.systemDefaultPackTitle);
      expect(packs.single.status, 'active');
      expect(packs.single.isSystemDefault, isTrue);
      expect(items, isEmpty);
      expect(timelines, hasLength(1));
      expect(rules, hasLength(1));
      expect(records, hasLength(1));
      expect(legacyTables, isEmpty);
    },
  );

  test(
    'v10 migration backfills pack lifecycle columns, renames tables, and preserves item pack ids',
    () async {
      final tempDir = await Directory.systemTemp.createTemp(
        'item-pack-migration',
      );
      addTearDown(() async {
        if (await tempDir.exists()) {
          await tempDir.delete(recursive: true);
        }
      });
      final file = File('${tempDir.path}/migration-v10.sqlite');

      final sqlite = sqlite3.open(file.path);
      sqlite.execute('PRAGMA user_version = 10');
      sqlite.execute('''
      CREATE TABLE responsibility_packs (
        id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        description TEXT,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');
      sqlite.execute('''
      CREATE TABLE responsibility_items (
        id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
        pack_id INTEGER NOT NULL,
        title TEXT NOT NULL,
        description TEXT,
        type TEXT NOT NULL,
        fixed_schedule_type TEXT,
        fixed_anchor_date INTEGER,
        fixed_time_of_day TEXT,
        state_expected_interval_minutes INTEGER,
        state_warning_after_minutes INTEGER,
        state_danger_after_minutes INTEGER,
        resource_estimated_duration_minutes INTEGER,
        resource_warning_before_depletion_minutes INTEGER,
        last_done_at INTEGER,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');
      sqlite.execute('''
      CREATE TABLE timelines (
        id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        start_date INTEGER NOT NULL,
        display_unit TEXT NOT NULL,
        status TEXT NOT NULL,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');
      sqlite.execute('''
      CREATE TABLE timeline_milestone_rules (
        id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
        timeline_id INTEGER NOT NULL,
        type TEXT NOT NULL,
        interval_value INTEGER NOT NULL,
        interval_unit TEXT NOT NULL,
        label_template TEXT,
        reminder_offset_days INTEGER NOT NULL DEFAULT 0,
        status TEXT NOT NULL DEFAULT 'active',
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');
      sqlite.execute('''
      CREATE TABLE timeline_milestone_records (
        id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
        timeline_id INTEGER NOT NULL,
        rule_id INTEGER NOT NULL,
        occurrence_index INTEGER NOT NULL,
        target_date INTEGER NOT NULL,
        status TEXT NOT NULL,
        notified_at INTEGER,
        acted_at INTEGER,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        UNIQUE(timeline_id, rule_id, occurrence_index)
      )
    ''');
      sqlite.execute('''
      INSERT INTO responsibility_packs (
        id, title, description, created_at, updated_at
      ) VALUES (
        1, 'Default Responsibility Pack', 'Legacy default', 1775001600000, 1775001600000
      )
    ''');
      sqlite.execute('''
      INSERT INTO responsibility_items (
        id, pack_id, title, type, state_expected_interval_minutes,
        state_warning_after_minutes, state_danger_after_minutes,
        created_at, updated_at
      ) VALUES (
        1, 1, 'Legacy item', 'stateBased', 1440, 1440, 2880, 1775001600000, 1775001600000
      )
    ''');
      sqlite.close();

      final db = AppDatabase.forTesting(NativeDatabase(file));
      addTearDown(db.close);

      final packs = await db.select(db.itemPacks).get();
      final items = await db.select(db.items).get();

      expect(db.schemaVersion, 14);
      expect(packs, hasLength(1));
      expect(packs.single.status, 'active');
      expect(packs.single.isSystemDefault, isTrue);
      expect(items, hasLength(1));
      expect(items.single.packId, 1);
      expect(items.single.status, 'active');
    },
  );
}
