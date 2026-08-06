import 'package:drift/drift.dart' hide isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reminder_app/features/reminders/data/local/app_database.dart';

const _fingerprint = '0123456789abcdef0123456789abcdef';
const _now = 1770000000000;

void main() {
  test(
    'fresh v6 creates exact Shared schema, indexes, FKs, and no rows',
    () async {
      final db = await _openFresh();
      addTearDown(db.close);

      expect(db.schemaVersion, 6);
      final foreignKeys = await db
          .customSelect('PRAGMA foreign_keys')
          .getSingle();
      expect(foreignKeys.data.values.single, 1);

      final tableNames =
          (await db
                  .customSelect(
                    "SELECT name FROM sqlite_master WHERE type = 'table'",
                  )
                  .get())
              .map((row) => row.read<String>('name'))
              .toSet();
      expect(
        tableNames,
        containsAll(<String>{
          'item_packs',
          'items',
          'item_action_records',
          'resources',
          'resource_consumption_rules',
          'resource_action_records',
          'stage_trackers',
          'stage_rules',
          'stage_records',
          'stage_related_items',
          'app_settings',
          'pack_templates',
          'pack_template_items',
          'shared_pack_cache',
          'shared_membership_cache',
          'shared_item_cache',
          'shared_pending_mutation',
        }),
      );

      for (final table in _sharedTables) {
        expect(await _count(db, table), 0, reason: table);
      }
      expect(await _countWhere(db, 'item_packs', 'is_system_default = 1'), 1);
      expect(await _count(db, 'app_settings'), 1);
      expect(
        await _countWhere(db, 'stage_trackers', "system_key = 'reminder_app'"),
        1,
      );

      final indexRows = await db.customSelect('''
      SELECT name, sql FROM sqlite_master
      WHERE type = 'index' AND name LIKE 'shared_%'
      ORDER BY name
    ''').get();
      expect(
        indexRows.map((row) => row.read<String>('name')).toList(),
        _sharedIndexes.toList()..sort(),
      );
      final indexSql = {
        for (final row in indexRows)
          row.read<String>('name'): _normalized(row.read<String>('sql')),
      };
      expect(
        indexSql['shared_membership_cache_one_current_per_pack_uq'],
        contains('where is_current_membership = 1'),
      );
      expect(
        indexSql['shared_membership_cache_one_owner_per_pack_uq'],
        contains("where role = 'owner'"),
      );

      final membershipFks = await _foreignKeyRows(
        db,
        'shared_membership_cache',
      );
      expect(
        membershipFks,
        contains(
          allOf(
            containsPair('table', 'shared_pack_cache'),
            containsPair('from', 'remote_pack_id'),
            containsPair('to', 'remote_pack_id'),
            containsPair('on_delete', 'CASCADE'),
          ),
        ),
      );
      final itemFks = await _foreignKeyRows(db, 'shared_item_cache');
      expect(
        itemFks,
        contains(
          allOf(
            containsPair('table', 'shared_pack_cache'),
            containsPair('from', 'remote_pack_id'),
            containsPair('on_delete', 'CASCADE'),
          ),
        ),
      );
      final actorFk = itemFks.where(
        (row) => row['table'] == 'shared_membership_cache',
      );
      expect(actorFk, hasLength(2));
      expect(actorFk.map((row) => row['from']).toSet(), {
        'remote_pack_id',
        'completed_by_member_id',
      });
      expect(actorFk.map((row) => row['to']).toSet(), {
        'remote_pack_id',
        'remote_member_id',
      });
      expect(actorFk.every((row) => row['on_delete'] == 'RESTRICT'), isTrue);
    },
  );

  test('valid graph and Pack-scoped DAO identity work', () async {
    final db = await _openFresh();
    addTearDown(db.close);

    await _insertPack(db, 'P1');
    await _insertPack(db, 'P2');
    await _insertMembership(
      db,
      packId: 'P1',
      memberId: 'same-member',
      role: 'owner',
      displayName: 'Same Name',
      isCurrent: true,
    );
    await _insertMembership(
      db,
      packId: 'P1',
      memberId: 'member-2',
      role: 'member',
      displayName: 'Same Name',
    );
    await _insertMembership(
      db,
      packId: 'P2',
      memberId: 'same-member',
      role: 'owner',
      displayName: 'Same Name',
      isCurrent: true,
    );
    await _insertItem(db, packId: 'P1', itemId: 'same-item');
    await _insertItem(db, packId: 'P2', itemId: 'same-item');
    await _insertItem(
      db,
      packId: 'P1',
      itemId: 'completed-item',
      completedAt: _now,
      completedBy: 'same-member',
    );
    await _insertPending(db, requestId: 'request-null-pack');

    expect(await _count(db, 'shared_membership_cache'), 3);
    expect(await _count(db, 'shared_item_cache'), 3);
    final p1 = await db.sharedPackCacheDao.getItem(
      remotePackId: 'P1',
      remoteItemId: 'same-item',
    );
    final p2 = await db.sharedPackCacheDao.getItem(
      remotePackId: 'P2',
      remoteItemId: 'same-item',
    );
    expect(p1?.remotePackId, 'P1');
    expect(p2?.remotePackId, 'P2');

    expect(
      await db.sharedPackCacheDao.updateItem(
        remotePackId: 'P1',
        remoteItemId: 'same-item',
        changes: const SharedItemCacheCompanion(title: Value('P1 updated')),
      ),
      1,
    );
    expect(
      (await db.sharedPackCacheDao.getItem(
        remotePackId: 'P2',
        remoteItemId: 'same-item',
      ))?.title,
      'Item same-item',
    );
    expect(
      await db.sharedPackCacheDao.deleteItem(
        remotePackId: 'P1',
        remoteItemId: 'same-item',
      ),
      1,
    );
    expect(
      await db.sharedPackCacheDao.getItem(
        remotePackId: 'P2',
        remoteItemId: 'same-item',
      ),
      isNotNull,
    );
  });

  test('Pack checks reject every invalid category without inserting', () async {
    final db = await _openFresh();
    addTearDown(db.close);

    for (final values in <Map<String, Object?>>[
      {'remote_pack_id': ''},
      {'remote_pack_id': ''.padLeft(129, 'x')},
      {'icon_emoji': ''},
      {'remote_pack_version': 0},
      {'remote_snapshot_schema_version': 2},
      {'snapshot_fingerprint': ''.padLeft(31, 'a')},
      {'snapshot_fingerprint': ''.padLeft(33, 'a')},
      {'snapshot_fingerprint': ''.padLeft(32, 'A')},
      {'snapshot_fingerprint': ''.padLeft(32, 'g')},
      {'trust_state': 'unknown'},
      {'trust_state': 'verified', 'trust_failure_reason': 'projectionFailed'},
      {'trust_state': 'needsRevalidation', 'trust_failure_reason': ''},
      {
        'trust_state': 'needsRevalidation',
        'trust_failure_reason': ''.padLeft(65, 'x'),
      },
      {'last_verified_at': -1},
      {'remote_created_at': 253402300800000},
      {'remote_updated_at': -1},
    ]) {
      await _expectPackRejected(db, values);
    }
    await _insertPack(db, 'duplicate-pack');
    await _expectRejected(
      db,
      'shared_pack_cache',
      () => _insertPack(db, 'duplicate-pack'),
    );
  });

  test(
    'membership FKs, checks, and partial unique indexes reject invalid rows',
    () async {
      final db = await _openFresh();
      addTearDown(db.close);
      await _insertPack(db, 'P1');
      await _insertMembership(
        db,
        packId: 'P1',
        memberId: 'owner',
        role: 'owner',
        displayName: 'Owner',
        isCurrent: true,
      );

      await _expectRejected(
        db,
        'shared_membership_cache',
        () => _insertMembership(
          db,
          packId: 'missing',
          memberId: 'member',
          role: 'member',
          displayName: 'Member',
        ),
      );
      for (final action in <Future<void> Function()>[
        () => _insertMembership(
          db,
          packId: 'P1',
          memberId: '',
          role: 'member',
          displayName: 'Member',
        ),
        () => _insertMembership(
          db,
          packId: 'P1',
          memberId: ''.padLeft(129, 'x'),
          role: 'member',
          displayName: 'Member',
        ),
        () => _insertMembership(
          db,
          packId: 'P1',
          memberId: 'bad-role',
          role: 'editor',
          displayName: 'Member',
        ),
        () => _insertMembership(
          db,
          packId: 'P1',
          memberId: 'blank',
          role: 'member',
          displayName: '   ',
        ),
        () => _insertMembership(
          db,
          packId: 'P1',
          memberId: 'long-name',
          role: 'member',
          displayName: ''.padLeft(41, 'x'),
        ),
        () => _insertMembership(
          db,
          packId: 'P1',
          memberId: 'bad-time',
          role: 'member',
          displayName: 'Member',
          joinedAt: -1,
        ),
        () => _insertMembership(
          db,
          packId: 'P1',
          memberId: 'second-current',
          role: 'member',
          displayName: 'Member',
          isCurrent: true,
        ),
        () => _insertMembership(
          db,
          packId: 'P1',
          memberId: 'second-owner',
          role: 'owner',
          displayName: 'Owner 2',
        ),
        () => _insertMembership(
          db,
          packId: 'P1',
          memberId: 'owner',
          role: 'member',
          displayName: 'Duplicate identity',
        ),
      ]) {
        await _expectRejected(db, 'shared_membership_cache', action);
      }
    },
  );

  test(
    'item FKs, identity, type, thresholds, and completion pair are enforced',
    () async {
      final db = await _openFresh();
      addTearDown(db.close);
      await _insertPack(db, 'P1');
      await _insertPack(db, 'P2');
      await _insertMembership(
        db,
        packId: 'P1',
        memberId: 'actor',
        role: 'owner',
        displayName: 'Actor',
      );
      await _insertMembership(
        db,
        packId: 'P2',
        memberId: 'other-actor',
        role: 'owner',
        displayName: 'Other',
      );
      await _insertItem(db, packId: 'P1', itemId: 'existing');

      for (final action in <Future<void> Function()>[
        () => _insertItem(db, packId: 'missing', itemId: 'item'),
        () => _insertItem(db, packId: 'P1', itemId: ''),
        () => _insertItem(db, packId: 'P1', itemId: ''.padLeft(129, 'x')),
        () => _insertItem(db, packId: 'P1', itemId: 'bad-type', type: 'fixed'),
        () => _insertItem(
          db,
          packId: 'P1',
          itemId: 'bad-lifecycle',
          lifecycle: 'archived',
        ),
        () => _insertItem(
          db,
          packId: 'P1',
          itemId: 'negative-threshold',
          info: -1,
        ),
        () => _insertItem(
          db,
          packId: 'P1',
          itemId: 'bad-order',
          info: 20,
          warning: 10,
        ),
        () =>
            _insertItem(db, packId: 'P1', itemId: 'too-large', danger: 5258881),
        () => _insertItem(
          db,
          packId: 'P1',
          itemId: 'timestamp-only',
          completedAt: _now,
        ),
        () => _insertItem(
          db,
          packId: 'P1',
          itemId: 'actor-only',
          completedBy: 'actor',
        ),
        () => _insertItem(
          db,
          packId: 'P1',
          itemId: 'missing-actor',
          completedAt: _now,
          completedBy: 'missing',
        ),
        () => _insertItem(
          db,
          packId: 'P1',
          itemId: 'cross-pack-actor',
          completedAt: _now,
          completedBy: 'other-actor',
        ),
        () => _insertItem(db, packId: 'P1', itemId: 'existing'),
        () => _insertItem(
          db,
          packId: 'P1',
          itemId: 'bad-anchor',
          stateAnchor: -1,
        ),
        () => _insertItem(db, packId: 'P1', itemId: 'bad-version', version: 0),
        () => _insertItem(
          db,
          packId: 'P1',
          itemId: 'bad-created',
          remoteCreatedAt: -1,
        ),
      ]) {
        await _expectRejected(db, 'shared_item_cache', action);
      }
    },
  );

  test(
    'pending mutation is nullable-target marker storage with locked checks',
    () async {
      final db = await _openFresh();
      addTearDown(db.close);
      await _insertPending(db, requestId: 'existing');
      await _insertPending(
        db,
        requestId: 'unknown-target-is-allowed',
        targetPackId: 'not-in-cache',
      );

      for (final action in <Future<void> Function()>[
        () => _insertPending(
          db,
          requestId: 'read-operation',
          operation: 'getSharedPackSnapshot',
        ),
        () => _insertPending(db, requestId: ''),
        () => _insertPending(db, requestId: ''.padLeft(129, 'x')),
        () => _insertPending(db, requestId: 'bad-target', targetPackId: ''),
        () => _insertPending(
          db,
          requestId: 'bad-fingerprint-length',
          fingerprint: ''.padLeft(31, 'a'),
        ),
        () => _insertPending(
          db,
          requestId: 'bad-fingerprint-case',
          fingerprint: ''.padLeft(32, 'A'),
        ),
        () => _insertPending(db, requestId: 'bad-created', createdAt: -1),
        () => _insertPending(db, requestId: 'bad-status', status: 'retrying'),
        () => _insertPending(db, requestId: 'existing'),
      ]) {
        await _expectRejected(db, 'shared_pending_mutation', action);
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

Future<AppDatabase> _openFresh() async {
  final db = AppDatabase.forTesting(
    NativeDatabase.memory(
      setup: (database) => database.execute('PRAGMA foreign_keys = ON'),
    ),
  );
  await db.customSelect('SELECT 1').getSingle();
  return db;
}

Future<void> _insertPack(
  AppDatabase db,
  String packId, {
  Map<String, Object?> overrides = const {},
}) {
  final values = <String, Object?>{
    'remote_pack_id': packId,
    'title': 'Pack $packId',
    'description': 'Description',
    'icon_emoji': '📦',
    'remote_pack_version': 1,
    'remote_snapshot_schema_version': 1,
    'snapshot_fingerprint': _fingerprint,
    'trust_state': 'verified',
    'trust_failure_reason': null,
    'last_verified_at': _now,
    'remote_created_at': _now,
    'remote_updated_at': _now,
    ...overrides,
  };
  return _insertMap(db, 'shared_pack_cache', values);
}

Future<void> _expectPackRejected(
  AppDatabase db,
  Map<String, Object?> overrides,
) {
  return _expectRejected(
    db,
    'shared_pack_cache',
    () => _insertPack(db, 'pack-${overrides.hashCode}', overrides: overrides),
  );
}

Future<void> _insertMembership(
  AppDatabase db, {
  required String packId,
  required String memberId,
  required String role,
  required String displayName,
  bool isCurrent = false,
  int joinedAt = _now,
}) {
  return _insertMap(db, 'shared_membership_cache', {
    'remote_member_id': memberId,
    'remote_pack_id': packId,
    'role': role,
    'display_name': displayName,
    'joined_at': joinedAt,
    'is_current_membership': isCurrent ? 1 : 0,
  });
}

Future<void> _insertItem(
  AppDatabase db, {
  required String packId,
  required String itemId,
  String type = 'stateBased',
  String lifecycle = 'active',
  int stateAnchor = _now,
  int info = 10,
  int warning = 20,
  int danger = 30,
  int? completedAt,
  String? completedBy,
  int version = 1,
  int remoteCreatedAt = _now,
}) {
  return _insertMap(db, 'shared_item_cache', {
    'remote_item_id': itemId,
    'remote_pack_id': packId,
    'title': 'Item $itemId',
    'description': null,
    'type': type,
    'lifecycle_status': lifecycle,
    'state_anchor_date': stateAnchor,
    'info_after_minutes': info,
    'warning_after_minutes': warning,
    'danger_after_minutes': danger,
    'completed_at': completedAt,
    'completed_by_member_id': completedBy,
    'remote_item_version': version,
    'remote_created_at': remoteCreatedAt,
    'remote_updated_at': _now,
  });
}

Future<void> _insertPending(
  AppDatabase db, {
  required String requestId,
  String operation = 'createSharedPack',
  String? targetPackId,
  String fingerprint = _fingerprint,
  int createdAt = _now,
  String status = 'awaitingResolution',
}) {
  return _insertMap(db, 'shared_pending_mutation', {
    'operation_name': operation,
    'client_request_id': requestId,
    'target_remote_pack_id': targetPackId,
    'payload_fingerprint': fingerprint,
    'created_at': createdAt,
    'status': status,
  });
}

Future<void> _insertMap(
  AppDatabase db,
  String table,
  Map<String, Object?> values,
) {
  final columns = values.keys.toList(growable: false);
  final placeholders = List.filled(columns.length, '?').join(', ');
  return db.customStatement(
    'INSERT INTO $table (${columns.join(', ')}) VALUES ($placeholders)',
    columns.map((column) => values[column]).toList(growable: false),
  );
}

Future<void> _expectRejected(
  AppDatabase db,
  String table,
  Future<void> Function() action,
) async {
  final before = await _count(db, table);
  Object? error;
  try {
    await action();
  } catch (caught) {
    error = caught;
  }
  expect(error, isNotNull, reason: 'SQLite should reject write to $table');
  expect(await _count(db, table), before, reason: table);
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

Future<List<Map<String, Object?>>> _foreignKeyRows(
  AppDatabase db,
  String table,
) async {
  return (await db.customSelect('PRAGMA foreign_key_list($table)').get())
      .map((row) => row.data)
      .toList(growable: false);
}

String _normalized(String sql) =>
    sql.toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
