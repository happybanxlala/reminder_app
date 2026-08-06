import 'dart:convert';

import 'package:drift/drift.dart' hide isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reminder_app/features/reminders/data/backup_models.dart';
import 'package:reminder_app/features/reminders/data/local/app_database.dart';
import 'package:reminder_app/features/reminders/data/reminder_backup_service.dart';

const _fingerprint = '0123456789abcdef0123456789abcdef';
const _now = 1770000000000;

void main() {
  test(
    'Personal export, reset, and import exclude and preserve Shared state',
    () async {
      final source = await _openFresh();
      await _insertPersonalItem(
        source,
        packTitle: 'Imported Pack',
        itemTitle: 'Imported Item',
      );
      final backup = await ReminderBackupService(
        source.reminderDao,
      ).exportJsonString(exportedAt: DateTime.utc(2026, 8, 7));
      await source.close();

      final db = await _openFresh();
      addTearDown(db.close);
      await _insertPersonalItem(
        db,
        packTitle: 'Old Pack',
        itemTitle: 'Old Item',
      );
      await _insertSharedState(db);
      final sharedBefore = await _sharedState(db);
      final service = ReminderBackupService(db.reminderDao);

      final exported = await service.exportJsonString(
        exportedAt: DateTime.utc(2026, 8, 7, 1),
      );
      final envelope = jsonDecode(exported) as Map<String, Object?>;
      expect(envelope['schemaVersion'], BackupPayload.currentSchemaVersion);
      expect((envelope['data'] as Map<String, Object?>).keys.toSet(), <String>{
        'packs',
        'items',
        'resources',
        'stages',
        'stageTrackers',
        'customTemplates',
        'relations',
        'activityLogs',
      });
      for (final forbidden in <String>[
        'shared_pack_cache',
        'shared_membership_cache',
        'shared_item_cache',
        'shared_pending_mutation',
        'remote-pack-boundary',
        'remote-member-boundary',
        'remote-item-boundary',
        'remote-request-boundary',
        'needsRevalidation',
        'projectionFailed',
        _fingerprint,
        'pending',
        'invite',
        'identity',
        'token',
      ]) {
        expect(exported, isNot(contains(forbidden)), reason: forbidden);
      }

      await service.resetDatabase();
      expect(await _count(db, 'items'), 0);
      expect(await _countWhere(db, 'item_packs', 'is_system_default = 1'), 1);
      expect(
        await _countWhere(db, 'stage_trackers', "system_key = 'reminder_app'"),
        1,
      );
      expect(await _sharedState(db), sharedBefore);

      await service.importJsonString(backup);
      final personalItems = await db
          .customSelect('SELECT title FROM items ORDER BY id')
          .get();
      expect(personalItems.map((row) => row.read<String>('title')), [
        'Imported Item',
      ]);
      expect(await _sharedState(db), sharedBefore);
      expect(await _count(db, 'shared_membership_cache'), 1);
    },
  );
}

Future<AppDatabase> _openFresh() async {
  final db = AppDatabase.forTesting(
    NativeDatabase.memory(
      setup: (database) => database.execute('PRAGMA foreign_keys = ON'),
    ),
  );
  await db.customSelect('SELECT 1').getSingle();
  return db;
}

Future<void> _insertPersonalItem(
  AppDatabase db, {
  required String packTitle,
  required String itemTitle,
}) async {
  await db.customStatement(
    '''
    INSERT INTO item_packs (
      title, description, icon_emoji, order_index, status,
      is_system_default, created_at, updated_at
    ) VALUES (?, 'personal-only', '🏠', 1, 'active', 0, $_now, $_now)
  ''',
    [packTitle],
  );
  final pack = await db
      .customSelect(
        'SELECT id FROM item_packs WHERE title = ? ORDER BY id DESC LIMIT 1',
        variables: [Variable(packTitle)],
      )
      .getSingle();
  await db.customStatement(
    '''
    INSERT INTO items (
      pack_id, title, status, type, attention_policy_source,
      state_anchor_date, state_expected_after_minutes,
      state_warning_after_minutes, state_danger_after_minutes,
      created_at, updated_at
    ) VALUES (?, ?, 'active', 'stateBased', 'systemDefault',
      $_now, 10, 20, 30, $_now, $_now)
  ''',
    [pack.read<int>('id'), itemTitle],
  );
}

Future<void> _insertSharedState(AppDatabase db) async {
  await db.customStatement('''
    INSERT INTO shared_pack_cache (
      remote_pack_id, title, description, icon_emoji, remote_pack_version,
      remote_snapshot_schema_version, snapshot_fingerprint, trust_state,
      trust_failure_reason, last_verified_at, remote_created_at,
      remote_updated_at
    ) VALUES (
      'remote-pack-boundary', 'Shared Boundary', 'must remain', '🔒', 7,
      1, '$_fingerprint', 'needsRevalidation', 'projectionFailed',
      $_now, ${_now - 1000}, $_now
    )
  ''');
  await db.customStatement('''
    INSERT INTO shared_membership_cache (
      remote_member_id, remote_pack_id, role, display_name, joined_at,
      is_current_membership
    ) VALUES (
      'remote-member-boundary', 'remote-pack-boundary', 'owner',
      'Boundary Owner', ${_now - 1000}, 1
    )
  ''');
  await db.customStatement('''
    INSERT INTO shared_item_cache (
      remote_item_id, remote_pack_id, title, description, state_anchor_date,
      info_after_minutes, warning_after_minutes, danger_after_minutes,
      completed_at, completed_by_member_id, remote_item_version,
      remote_created_at, remote_updated_at
    ) VALUES (
      'remote-item-boundary', 'remote-pack-boundary', 'Shared Item',
      'must remain', $_now, 10, 20, 30, $_now,
      'remote-member-boundary', 4, ${_now - 1000}, $_now
    )
  ''');
  await db.customStatement('''
    INSERT INTO shared_pending_mutation (
      operation_name, client_request_id, target_remote_pack_id,
      payload_fingerprint, created_at
    ) VALUES (
      'completeSharedItem', 'remote-request-boundary',
      'remote-pack-boundary', '$_fingerprint', $_now
    )
  ''');
}

Future<Map<String, List<Map<String, Object?>>>> _sharedState(
  AppDatabase db,
) async {
  const tables = <String>[
    'shared_pack_cache',
    'shared_membership_cache',
    'shared_item_cache',
    'shared_pending_mutation',
  ];
  return {
    for (final table in tables)
      table:
          (await db
                  .customSelect('SELECT * FROM $table ORDER BY local_id')
                  .get())
              .map((row) => row.data)
              .toList(growable: false),
  };
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
