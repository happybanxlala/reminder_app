import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

const _catalogPath = 'docs/core/07_remote_request_catalog.md';
const _schemaContractPath = 'docs/core/08_shared_pack_remote_schema_v1.md';
const _migrationPath =
    'supabase/migrations/20260630000000_shared_pack_v1_remote_schema.sql';

const _requiredTables = [
  'shared_packs',
  'shared_pack_members',
  'shared_pack_invites',
  'shared_pack_items',
];

const _requiredRpcs = [
  'shared_pack_create_pack_v1',
  'shared_pack_generate_invite_v1',
  'shared_pack_preview_invite_v1',
  'shared_pack_join_by_invite_v1',
  'shared_pack_fetch_snapshot_v1',
  'shared_pack_update_item_state_v1',
];

void main() {
  group('Shared Pack remote migration contract', () {
    test('migration file exists', () {
      expect(File(_migrationPath).existsSync(), isTrue);
    });

    test('migration includes required tables and RPC contracts', () {
      final migration = File(_migrationPath).readAsStringSync();

      for (final table in _requiredTables) {
        expect(migration, contains(table));
      }

      for (final rpc in _requiredRpcs) {
        expect(migration, contains(rpc));
      }
    });

    test('migration includes invite code constraints', () {
      final migration = File(_migrationPath).readAsStringSync();

      expect(migration, contains('char_length(code) = 6'));
      expect(migration, contains('ABCDEFGHJKLMNPQRSTUVWXYZ23456789'));
      expect(migration, contains('[0O1IL]'));
    });

    test('catalog references migration, tables, and RPCs', () {
      final catalog = File(_catalogPath).readAsStringSync();

      expect(catalog, contains(_migrationPath));

      for (final table in _requiredTables) {
        expect(catalog, contains(table));
      }

      for (final rpc in _requiredRpcs) {
        expect(catalog, contains(rpc));
      }
    });

    test('schema contract references migration filename', () {
      final schemaContract = File(_schemaContractPath).readAsStringSync();

      expect(schemaContract, contains(_migrationPath));
    });
  });
}
