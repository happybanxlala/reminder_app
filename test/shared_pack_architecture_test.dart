import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Shared domain and application contracts keep inward dependencies', () {
    final domainFiles = _dartFiles('lib/features/shared_packs/domain');
    final applicationFiles = _dartFiles(
      'lib/features/shared_packs/application',
    );

    const forbiddenPackages = <String>[
      'package:flutter/',
      'package:flutter_riverpod/',
      'package:drift/',
      'package:supabase',
      'package:go_router/',
    ];

    for (final file in [...domainFiles, ...applicationFiles]) {
      final source = file.readAsStringSync();
      for (final package in forbiddenPackages) {
        expect(source, isNot(contains(package)), reason: file.path);
      }
      expect(source, isNot(contains('features/reminders')), reason: file.path);
    }

    for (final file in domainFiles) {
      final source = file.readAsStringSync();
      expect(source, isNot(contains('../application/')), reason: file.path);
      expect(source, isNot(contains('../data/')), reason: file.path);
    }

    for (final file in applicationFiles) {
      expect(
        file.readAsStringSync(),
        isNot(contains('../data/')),
        reason: file.path,
      );
    }
  });

  test('remote port keeps the exact operation-specific catalog', () {
    final source = File(
      'lib/features/shared_packs/application/shared_pack_remote_contracts.dart',
    ).readAsStringSync();
    const methods = <String>[
      'createSharedPack(',
      'updateSharedPackMetadata(',
      'createSharedItem(',
      'updateSharedItem(',
      'archiveSharedItem(',
      'completeSharedItem(',
      'getOrCreateInviteCode(',
      'rotateInviteCode(',
      'previewInviteCode(',
      'joinSharedPack(',
      'getSharedPackSnapshot(',
    ];
    for (final method in methods) {
      expect(source, contains(method));
    }
    expect(source, isNot(contains('call(String operation')));
  });
}

List<File> _dartFiles(String path) => Directory(path)
    .listSync(recursive: true)
    .whereType<File>()
    .where((file) => file.path.endsWith('.dart'))
    .toList(growable: false);
