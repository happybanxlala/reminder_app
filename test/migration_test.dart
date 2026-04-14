import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reminder_app/features/reminders/data/local/app_database.dart';
// ignore: depend_on_referenced_packages
import 'package:sqlite3/sqlite3.dart';

void main() {
  test(
    'database uses schema version 8 and new milestone tables are writable',
    () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);

      expect(db.schemaVersion, 8);

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
              labelTemplate: const Value('第 {n} 天'),
              reminderOffsetDays: const Value(0),
              isActive: const Value(true),
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

    expect(db.schemaVersion, 8);
    expect(timelines, hasLength(1));
    expect(timelines.single.title, 'No sugar');
    expect(rules, hasLength(1));
    expect(rules.single.type, 'every_n_days');
    expect(rules.single.intervalValue, 7);
    expect(rules.single.intervalUnit, 'days');
    expect(rules.single.reminderOffsetDays, 3);
    expect(records, isEmpty);
    expect(tables, isEmpty);
  });
}
