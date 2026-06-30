import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:reminder_app/features/shared_pack/remote/shared_pack_remote_request_ids.dart';

const _catalogPath = 'docs/core/07_remote_request_catalog.md';

void main() {
  group('Shared Pack remote request catalog', () {
    test('mirrors every request ID from code', () {
      final catalog = File(_catalogPath).readAsStringSync();

      for (final requestId in SharedPackRemoteRequestIds.all) {
        expect(catalog, contains(requestId));
      }
    });

    test('keeps Shared Pack v1 entries implemented but not wired', () {
      final catalog = File(_catalogPath).readAsStringSync();

      for (final requestId in SharedPackRemoteRequestIds.all) {
        final section = _catalogSection(catalog, requestId);

        expect(section, contains('| Status | `implemented_not_wired` |'));
        expect(section, isNot(contains('| Status | `active` |')));
      }
    });
  });

  group('Shared Pack remote boundary guardrails', () {
    test('Dart source does not call Supabase directly', () {
      final files = [..._dartFilesUnder('lib'), ..._dartFilesUnder('test')];

      _expectNoForbiddenPatterns(files);
    });

    test(
      'UI, presentation, application, and provider folders stay remote-free',
      () {
        const guardedRoots = [
          'lib/features/reminders/ui',
          'lib/features/reminders/presentation',
          'lib/features/reminders/application',
          'lib/features/reminders/providers',
          'lib/features/shared_pack/ui',
          'lib/features/shared_pack/presentation',
          'lib/features/shared_pack/application',
          'lib/features/shared_pack/providers',
        ];
        final files = guardedRoots.expand(_dartFilesUnder);

        _expectNoForbiddenPatterns(files);
      },
    );

    test(
      'production UI, providers, routes, and startup do not wire service',
      () {
        const guardedRoots = [
          'lib/features/reminders/ui',
          'lib/features/reminders/providers',
          'lib/features/shared_pack/ui',
          'lib/features/shared_pack/providers',
          'lib/app',
        ];
        const guardedFiles = ['lib/main.dart'];
        final files = [
          ...guardedRoots.expand(_dartFilesUnder),
          ...guardedFiles
              .map((path) => File(path))
              .where((file) => file.existsSync()),
        ];
        final serviceName =
            'SharedPack'
            'ApplicationService';
        final harnessName =
            'shared_pack'
            '_dev_manual_flow';
        final matches = <String>[];

        for (final file in files) {
          final source = file.readAsStringSync();
          if (source.contains(serviceName)) {
            matches.add(file.path);
          }
          if (source.contains(harnessName)) {
            matches.add(file.path);
          }
        }

        expect(matches, isEmpty);
      },
    );
  });
}

String _catalogSection(String catalog, String requestId) {
  final start = catalog.indexOf('### $requestId');
  expect(start, isNot(-1), reason: '$requestId must exist in $_catalogPath');

  final next = catalog.indexOf('\n### ', start + 1);
  return catalog.substring(start, next == -1 ? catalog.length : next);
}

Iterable<File> _dartFilesUnder(String rootPath) {
  final root = Directory(rootPath);
  if (!root.existsSync()) {
    return const <File>[];
  }

  return root
      .listSync(recursive: true)
      .whereType<File>()
      .where((file) => file.path.endsWith('.dart'));
}

void _expectNoForbiddenPatterns(Iterable<File> files) {
  final globallyForbiddenPatterns = [
    'supabase.'
        'from(',
    'Supabase.'
        'instance',
  ];
  final boundaryOnlyPatterns = [
    'supabase.'
        'rpc(',
    'Supabase'
        'Client',
  ];
  const approvedRemoteBoundaryFiles = {
    'lib/features/shared_pack/remote/shared_pack_remote_api.dart',
  };

  final matches = <String>[];

  for (final file in files) {
    final source = file.readAsStringSync();
    final normalizedPath = file.path.replaceAll('\\', '/');

    for (final pattern in globallyForbiddenPatterns) {
      if (source.contains(pattern)) {
        matches.add('${file.path}: $pattern');
      }
    }

    for (final pattern in boundaryOnlyPatterns) {
      if (!source.contains(pattern)) {
        continue;
      }

      if (!approvedRemoteBoundaryFiles.contains(normalizedPath)) {
        matches.add('${file.path}: $pattern');
      }
    }
  }

  expect(matches, isEmpty);
}
