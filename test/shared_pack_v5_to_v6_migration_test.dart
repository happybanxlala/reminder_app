import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reminder_app/features/reminders/data/local/app_database.dart';

import 'support/shared_pack_v5_fixture.dart';

const _fingerprint = '0123456789abcdef0123456789abcdef';
const _now = 1770000000000;

void main() {
  test(
    'production migration upgrades genuine v5 and preserves Personal graph',
    () async {
      final directory = await Directory.systemTemp.createTemp('shared-v5-v6-');
      addTearDown(() => directory.delete(recursive: true));
      final file = await createPinnedV5Database(directory);

      final db = AppDatabase.forTesting(openFixtureFile(file));
      var dbClosed = false;
      addTearDown(() async {
        if (!dbClosed) {
          await db.close();
        }
      });
      await db.customSelect('SELECT 1').getSingle();

      expect(await _pragmaInt(db, 'user_version'), 6);
      expect(await _pragmaInt(db, 'foreign_keys'), 1);
      expect(await _count(db, 'item_packs'), 2);
      expect(await _count(db, 'items'), 1);
      expect(await _count(db, 'item_action_records'), 1);
      expect(await _count(db, 'resources'), 1);
      expect(await _count(db, 'resource_consumption_rules'), 1);
      expect(await _count(db, 'resource_action_records'), 1);
      expect(await _count(db, 'stage_trackers'), 2);
      expect(await _count(db, 'stage_rules'), 1);
      expect(await _count(db, 'stage_records'), 1);
      expect(await _count(db, 'stage_related_items'), 1);
      expect(await _count(db, 'pack_templates'), 1);
      expect(await _count(db, 'pack_template_items'), 1);
      expect(await _count(db, 'app_settings'), 1);

      expect(
        (await db.customSelect('SELECT * FROM items WHERE id = 10').getSingle())
            .read<String>('title'),
        'Fixture Item',
      );
      expect(
        (await db
                .customSelect(
                  'SELECT * FROM resource_consumption_rules WHERE id = 21',
                )
                .getSingle())
            .data,
        containsPair('item_id', 10),
      );
      expect(
        (await db
                .customSelect(
                  'SELECT * FROM resource_action_records WHERE id = 22',
                )
                .getSingle())
            .data,
        containsPair('source_item_action_record_id', 11),
      );
      expect(
        (await db
                .customSelect('SELECT * FROM stage_related_items WHERE id = 33')
                .getSingle())
            .data,
        allOf(containsPair('stage_record_id', 32), containsPair('item_id', 10)),
      );
      expect(
        (await db
                .customSelect('SELECT * FROM pack_template_items WHERE id = 41')
                .getSingle())
            .data,
        containsPair('template_id', 40),
      );
      final settings = await db
          .customSelect('SELECT * FROM app_settings WHERE id = 1')
          .getSingle();
      expect(settings.read<String>('reminder_tone'), 'early');
      expect(settings.read<String>('notification_reminder_time'), '20:30');
      expect(await _countWhere(db, 'item_packs', 'is_system_default = 1'), 1);
      expect(
        await _countWhere(db, 'stage_trackers', "system_key = 'reminder_app'"),
        1,
      );

      for (final table in _sharedTables) {
        expect(await _count(db, table), 0, reason: table);
      }
      expect(await _sharedIndexNames(db), _sharedIndexes);

      await _insertValidSharedGraph(db);
      await _expectRejected(
        db,
        'shared_membership_cache',
        "INSERT INTO shared_membership_cache (remote_member_id, remote_pack_id, role, display_name, joined_at) VALUES ('missing', 'missing-pack', 'member', 'Missing', $_now)",
      );
      await _expectRejected(
        db,
        'shared_membership_cache',
        "INSERT INTO shared_membership_cache (remote_member_id, remote_pack_id, role, display_name, joined_at, is_current_membership) VALUES ('second-current', 'P1', 'member', 'Second', $_now, 1)",
      );
      await _expectRejected(
        db,
        'shared_membership_cache',
        "INSERT INTO shared_membership_cache (remote_member_id, remote_pack_id, role, display_name, joined_at) VALUES ('second-owner', 'P1', 'owner', 'Second', $_now)",
      );
      await _expectRejected(
        db,
        'shared_item_cache',
        _itemInsert(packId: 'P1', itemId: 'I1'),
      );
      await _expectRejected(
        db,
        'shared_item_cache',
        _itemInsert(packId: 'P1', itemId: 'overflow', danger: 5258881),
      );
      await _expectRejected(
        db,
        'shared_item_cache',
        _itemInsert(
          packId: 'P1',
          itemId: 'cross-pack',
          completedAt: _now,
          completedBy: 'owner-p2',
        ),
      );
      await db.customStatement(_itemInsert(packId: 'P2', itemId: 'I1'));
      expect(
        await _countWhere(db, 'shared_item_cache', "remote_item_id = 'I1'"),
        2,
      );

      final upgradedSchema = await _sharedSchema(db);
      await db.close();
      dbClosed = true;
      final fresh = AppDatabase.forTesting(
        NativeDatabase.memory(
          setup: (database) => database.execute('PRAGMA foreign_keys = ON'),
        ),
      );
      addTearDown(fresh.close);
      await fresh.customSelect('SELECT 1').getSingle();
      expect(await _sharedSchema(fresh), upgradedSchema);
    },
  );

  test(
    'failed v6 migration rolls back and same file can be upgraded later',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'shared-v6-fail-',
      );
      addTearDown(() => directory.delete(recursive: true));
      final file = await createPinnedV5Database(directory);

      final failing = AppDatabase.forTesting(
        openFixtureFile(file),
        v6MigrationTestHook: () async {
          throw StateError('controlled v6 migration failure');
        },
      );
      await expectLater(
        failing.customSelect('SELECT 1').getSingle(),
        throwsA(isA<StateError>()),
      );
      await failing.close();

      final inspection = AppDatabase.forTesting(
        openFixtureFile(file, enableMigrations: false),
      );
      await inspection.customSelect('SELECT 1').getSingle();
      expect(await _pragmaInt(inspection, 'user_version'), 5);
      expect(await _count(inspection, 'items'), 1);
      expect(
        (await inspection
                .customSelect('SELECT title FROM items WHERE id = 10')
                .getSingle())
            .read<String>('title'),
        'Fixture Item',
      );
      expect(await _existingSharedTables(inspection), isEmpty);
      await inspection.close();

      final recovered = AppDatabase.forTesting(openFixtureFile(file));
      addTearDown(recovered.close);
      await recovered.customSelect('SELECT 1').getSingle();
      expect(await _pragmaInt(recovered, 'user_version'), 6);
      expect(await _count(recovered, 'items'), 1);
      expect(await _existingSharedTables(recovered), _sharedTables.toSet());
      for (final table in _sharedTables) {
        expect(await _count(recovered, table), 0, reason: table);
      }
    },
  );
}

const _sharedTables = <String>[
  'shared_pack_cache',
  'shared_membership_cache',
  'shared_item_cache',
  'shared_pending_mutation',
];

const _sharedIndexes = <String>{
  'shared_pack_cache_remote_pack_id_uq',
  'shared_pack_cache_trust_state_idx',
  'shared_membership_cache_pack_member_uq',
  'shared_membership_cache_one_current_per_pack_uq',
  'shared_membership_cache_one_owner_per_pack_uq',
  'shared_item_cache_pack_item_uq',
  'shared_pending_mutation_operation_request_uq',
};

Future<void> _insertValidSharedGraph(AppDatabase db) async {
  for (final packId in ['P1', 'P2']) {
    await db.customStatement(
      '''
      INSERT INTO shared_pack_cache (
        remote_pack_id, title, icon_emoji, remote_pack_version,
        remote_snapshot_schema_version, snapshot_fingerprint, trust_state,
        last_verified_at, remote_created_at, remote_updated_at
      ) VALUES (?, ?, '📦', 1, 1, ?, 'verified', ?, ?, ?)
    ''',
      [packId, 'Pack $packId', _fingerprint, _now, _now, _now],
    );
  }
  await db.customStatement('''
    INSERT INTO shared_membership_cache (
      remote_member_id, remote_pack_id, role, display_name, joined_at,
      is_current_membership
    ) VALUES ('owner-p1', 'P1', 'owner', 'Owner One', $_now, 1)
  ''');
  await db.customStatement('''
    INSERT INTO shared_membership_cache (
      remote_member_id, remote_pack_id, role, display_name, joined_at,
      is_current_membership
    ) VALUES ('owner-p2', 'P2', 'owner', 'Owner Two', $_now, 1)
  ''');
  await db.customStatement(_itemInsert(packId: 'P1', itemId: 'I1'));
  await db.customStatement('''
    INSERT INTO shared_pending_mutation (
      operation_name, client_request_id, target_remote_pack_id,
      payload_fingerprint, created_at
    ) VALUES ('createSharedPack', 'request-1', NULL, '$_fingerprint', $_now)
  ''');
}

String _itemInsert({
  required String packId,
  required String itemId,
  int danger = 30,
  int? completedAt,
  String? completedBy,
}) {
  final completedAtSql = completedAt?.toString() ?? 'NULL';
  final completedBySql = completedBy == null ? 'NULL' : "'$completedBy'";
  return '''
    INSERT INTO shared_item_cache (
      remote_item_id, remote_pack_id, title, state_anchor_date,
      info_after_minutes, warning_after_minutes, danger_after_minutes,
      completed_at, completed_by_member_id, remote_item_version,
      remote_created_at, remote_updated_at
    ) VALUES (
      '$itemId', '$packId', 'Item $itemId', $_now,
      10, 20, $danger, $completedAtSql, $completedBySql, 1, $_now, $_now
    )
  ''';
}

Future<void> _expectRejected(
  AppDatabase db,
  String table,
  String statement,
) async {
  final before = await _count(db, table);
  Object? error;
  try {
    await db.customStatement(statement);
  } catch (caught) {
    error = caught;
  }
  expect(error, isNotNull);
  expect(await _count(db, table), before);
}

Future<int> _pragmaInt(AppDatabase db, String pragma) async {
  final row = await db.customSelect('PRAGMA $pragma').getSingle();
  return row.data.values.single! as int;
}

Future<int> _count(AppDatabase db, String table) async {
  final row = await db
      .customSelect('SELECT COUNT(*) AS count FROM $table')
      .getSingle();
  return row.read<int>('count');
}

Future<int> _countWhere(AppDatabase db, String table, String predicate) async {
  final row = await db
      .customSelect('SELECT COUNT(*) AS count FROM $table WHERE $predicate')
      .getSingle();
  return row.read<int>('count');
}

Future<Set<String>> _sharedIndexNames(AppDatabase db) async {
  final rows = await db
      .customSelect(
        "SELECT name FROM sqlite_master WHERE type = 'index' AND name LIKE 'shared_%'",
      )
      .get();
  return rows.map((row) => row.read<String>('name')).toSet();
}

Future<Set<String>> _existingSharedTables(AppDatabase db) async {
  final rows = await db
      .customSelect(
        "SELECT name FROM sqlite_master WHERE type = 'table' AND name LIKE 'shared_%'",
      )
      .get();
  return rows.map((row) => row.read<String>('name')).toSet();
}

Future<Map<String, String>> _sharedSchema(AppDatabase db) async {
  final rows = await db.customSelect('''
    SELECT type, name, sql FROM sqlite_master
    WHERE name LIKE 'shared_%' AND type IN ('table', 'index')
    ORDER BY type, name
  ''').get();
  return {
    for (final row in rows)
      '${row.read<String>('type')}:${row.read<String>('name')}': row
          .read<String>('sql')
          .toLowerCase()
          .replaceAll(RegExp(r'\s+'), ' ')
          .trim(),
  };
}
