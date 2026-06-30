import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

const _schemaContractPath = 'docs/core/08_shared_pack_remote_schema_v1.md';
const _smokeTestPath = 'supabase/tests/shared_pack_v1_rpc_smoke_test.sql';

const _requiredRpcs = [
  'shared_pack_create_pack_v1',
  'shared_pack_generate_invite_v1',
  'shared_pack_preview_invite_v1',
  'shared_pack_join_by_invite_v1',
  'shared_pack_fetch_snapshot_v1',
  'shared_pack_update_item_state_v1',
];

const _happyPathKeywords = [
  'create pack',
  'generate invite',
  'preview invite',
  'join by invite',
  'prepare item',
  'fetch snapshot',
  'update item state',
];

const _negativeCaseKeywords = [
  'invalid invite',
  'non-member fetch',
  'non-member update',
  'invalid invite code constraint',
];

void main() {
  group('Shared Pack RPC smoke test artifact', () {
    test('exists', () {
      expect(File(_smokeTestPath).existsSync(), isTrue);
    });

    test('references required RPCs', () {
      final smokeTest = File(_smokeTestPath).readAsStringSync();

      for (final rpc in _requiredRpcs) {
        expect(smokeTest, contains(rpc));
      }
    });

    test('documents happy path and negative cases', () {
      final smokeTest = File(_smokeTestPath).readAsStringSync().toLowerCase();

      for (final keyword in _happyPathKeywords) {
        expect(smokeTest, contains(keyword));
      }

      for (final keyword in _negativeCaseKeywords) {
        expect(smokeTest, contains(keyword));
      }
    });

    test('is referenced by the schema contract', () {
      final schemaContract = File(_schemaContractPath).readAsStringSync();

      expect(schemaContract, contains(_smokeTestPath));
    });
  });
}
