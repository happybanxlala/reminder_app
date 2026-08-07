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

  test(
    'Shared Drift persistence remains feature-owned and Personal-isolated',
    () {
      final tableSource = File(
        'lib/features/shared_packs/data/local/shared_pack_cache_tables.dart',
      ).readAsStringSync();
      final daoSource = File(
        'lib/features/shared_packs/data/local/shared_pack_cache_dao.dart',
      ).readAsStringSync();
      final readAdapterSource = File(
        'lib/features/shared_packs/data/local/'
        'drift_shared_cache_read_adapter.dart',
      ).readAsStringSync();
      final personalTables = File(
        'lib/features/reminders/data/local/tables.dart',
      ).readAsStringSync();
      final reminderDao = File(
        'lib/features/reminders/data/local/reminder_dao.dart',
      ).readAsStringSync();
      final database = File(
        'lib/features/reminders/data/local/app_database.dart',
      ).readAsStringSync();

      for (final table in const <String>[
        'shared_pack_cache',
        'shared_membership_cache',
        'shared_item_cache',
        'shared_pending_mutation',
      ]) {
        expect(tableSource, contains(table));
        expect(personalTables, isNot(contains(table)));
        expect(reminderDao, isNot(contains(table)));
      }
      expect(database, contains('SharedPackCacheDao'));
      expect(database, contains('SharedPackCache'));
      expect(reminderDao, isNot(contains('shared_pack_cache_dao.dart')));
      expect(daoSource, isNot(contains('/domain/')));
      expect(daoSource, isNot(contains('package:flutter/')));
      expect(daoSource, isNot(contains('package:flutter_riverpod/')));
      expect(daoSource, isNot(contains('package:go_router/')));
      expect(daoSource, isNot(contains('package:supabase')));
      expect(daoSource, contains('required String remotePackId'));
      expect(daoSource, contains('required String remoteItemId'));
      expect(readAdapterSource, contains('implements SharedCacheReadPort'));
      expect(readAdapterSource, contains('SharedPackCacheDao'));
      expect(readAdapterSource, isNot(contains('ItemRepository')));
      expect(readAdapterSource, isNot(contains('ReminderDao')));
      expect(readAdapterSource, isNot(contains('HomeRepository')));
      expect(readAdapterSource, isNot(contains('package:flutter/')));
      expect(readAdapterSource, isNot(contains('package:flutter_riverpod/')));
      expect(readAdapterSource, isNot(contains('package:go_router/')));
      expect(readAdapterSource, isNot(contains('package:supabase')));

      for (final root in const <String>[
        'lib/features/reminders/data',
        'lib/features/reminders/providers',
        'lib/features/home_widget',
      ]) {
        for (final file in _dartFiles(root)) {
          if (root == 'lib/features/reminders/data' &&
              !file.path.endsWith('_repository.dart')) {
            continue;
          }
          final source = file.readAsStringSync();
          expect(
            source,
            isNot(contains('shared_pack_cache_dao.dart')),
            reason: file.path,
          );
        }
      }
    },
  );

  test('Phase 2c adds no Shared provider, route, or UI implementation', () {
    expect(
      Directory('lib/features/shared_packs/providers').existsSync(),
      isFalse,
    );
    expect(Directory('lib/features/shared_packs/ui').existsSync(), isFalse);

    final router = File('lib/app/router.dart').readAsStringSync();
    expect(router, isNot(contains('/shared-packs')));
    expect(router, isNot(contains('shared-pack-detail')));

    for (final root in const <String>[
      'lib/features/reminders/providers',
      'lib/features/reminders/data/home_repository.dart',
      'lib/features/home_widget',
    ]) {
      final files = FileSystemEntity.isDirectorySync(root)
          ? _dartFiles(root)
          : [File(root)];
      for (final file in files) {
        final source = file.readAsStringSync();
        expect(source, isNot(contains('DriftSharedCacheReadAdapter')));
        expect(source, isNot(contains('SharedCacheReadPort')));
      }
    }
  });
}

List<File> _dartFiles(String path) => Directory(path)
    .listSync(recursive: true)
    .whereType<File>()
    .where((file) => file.path.endsWith('.dart'))
    .toList(growable: false);
