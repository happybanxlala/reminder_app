import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:reminder_app/features/shared_pack/remote/shared_pack_remote_request_ids.dart';

const _catalogPath = 'docs/core/07_remote_request_catalog.md';
const _schemaContractPath = 'docs/core/08_shared_pack_remote_schema_v1.md';

void main() {
  group('Shared Pack remote schema contract', () {
    test('document exists', () {
      expect(File(_schemaContractPath).existsSync(), isTrue);
    });

    test('references every Shared Pack v1 request ID', () {
      final schemaContract = File(_schemaContractPath).readAsStringSync();

      for (final requestId in SharedPackRemoteRequestIds.all) {
        expect(schemaContract, contains(requestId));
      }
    });

    test('is referenced by the remote request catalog', () {
      final catalog = File(_catalogPath).readAsStringSync();

      expect(catalog, contains(_schemaContractPath));
    });
  });
}
