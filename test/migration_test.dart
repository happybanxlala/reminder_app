import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reminder_app/features/reminders/data/local/app_database.dart';
// ignore: depend_on_referenced_packages
import 'package:sqlite3/sqlite3.dart';

void main() {
  test(
    'database uses schema version 9 and new milestone tables are writable',
    () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);

      expect(db.schemaVersion, 9);

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

      expect(timelineId, greaterThan(0));
      expect(ruleId, greaterThan(0));
      expect(recordId, greaterThan(0));
    },
  );

  test('v7 migration preserves timelines and seeds milestone rules', () async {
    final tempDir = await Directory.systemTemp.createTemp(
      'milestone-migration',
    );
    addTearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });
    final file = File('${tempDir.path}/migration.sqlite');

    final sqlite = sqlite3.open(file.path);
    sqlite.execute('PRAGMA user_version = 7');
    sqlite.execute('''
      CREATE TABLE timelines (
        id INTEGER NOT NULL PRIMARY KEY,
        title TEXT NOT NULL,
        start_date INTEGER NOT NULL,
        display_unit TEXT NOT NULL,
        status TEXT NOT NULL,
        milestone_reminder_rule TEXT NOT NULL,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');
    sqlite.execute('''
      CREATE TABLE milestones (
        id INTEGER NOT NULL PRIMARY KEY,
        timeline_id INTEGER NOT NULL,
        target_date INTEGER NOT NULL,
        description TEXT,
        source TEXT NOT NULL,
        status TEXT NOT NULL,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');
    sqlite.execute('''
      INSERT INTO timelines (
        id, title, start_date, display_unit, status, milestone_reminder_rule, created_at, updated_at
      ) VALUES (
        1, 'No sugar', 1775779200000, 'week', 'active', 'advance:3', 1775001600000, 1775001600000
      )
    ''');
    sqlite.execute('''
      INSERT INTO milestones (
        id, timeline_id, target_date, description, source, status, created_at, updated_at
      ) VALUES (
        1, 1, 1776384000000, 'legacy', 'ruleBased', 'upcoming', 1775001600000, 1775001600000
      )
    ''');
    sqlite.close();

    final db = AppDatabase.forTesting(NativeDatabase(file));
    addTearDown(db.close);

    final timelines = await db.select(db.timelines).get();
    final rules = await db.select(db.timelineMilestoneRules).get();
    final records = await db.select(db.timelineMilestoneRecords).get();
    final tables = await db
        .customSelect(
          "SELECT name FROM sqlite_master WHERE type = 'table' AND name IN ('milestones', 'timelines_v7', 'milestones_v7')",
        )
        .get();

    expect(db.schemaVersion, 9);
    expect(timelines, hasLength(1));
    expect(timelines.single.title, 'No sugar');
    expect(rules, hasLength(1));
    expect(rules.single.type, 'every_n_weeks');
    expect(rules.single.intervalValue, 1);
    expect(rules.single.intervalUnit, 'weeks');
    expect(rules.single.labelTemplate, '第 {value}{unit}');
    expect(rules.single.reminderOffsetDays, 3);
    expect(rules.single.status, 'active');
    expect(records, isEmpty);
    expect(tables, isEmpty);
  });

  test('v8 migration converts is_active to status', () async {
    final tempDir = await Directory.systemTemp.createTemp(
      'milestone-status-migration',
    );
    addTearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });
    final file = File('${tempDir.path}/migration_v8.sqlite');

    final sqlite = sqlite3.open(file.path);
    sqlite.execute('PRAGMA user_version = 8');
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
        is_active INTEGER NOT NULL DEFAULT 1,
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
      INSERT INTO timeline_milestone_rules (
        id, timeline_id, type, interval_value, interval_unit, label_template, reminder_offset_days, is_active, created_at, updated_at
      ) VALUES
        (1, 1, 'every_n_days', 10, 'days', '第 {value}{unit}', 0, 1, 1775001600000, 1775001600000),
        (2, 1, 'every_n_months', 1, 'months', '第 {value}{unit}', 0, 0, 1775001600000, 1775001600000)
    ''');
    sqlite.close();

    final db = AppDatabase.forTesting(NativeDatabase(file));
    addTearDown(db.close);

    final rules = await db.select(db.timelineMilestoneRules).get();

    expect(db.schemaVersion, 9);
    expect(rules, hasLength(2));
    expect(rules.first.status, 'active');
    expect(rules.last.status, 'paused');
  });
}
