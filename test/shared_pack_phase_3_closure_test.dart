import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:reminder_app/features/shared_pack/remote/shared_pack_remote_request_ids.dart';

const _closurePath = 'docs/core/11_shared_pack_phase_3_closure.md';
const _catalogPath = 'docs/core/07_remote_request_catalog.md';

void main() {
  group('Shared Pack Phase 3 closure', () {
    test('closure document exists and records final status', () {
      final closure = File(_closurePath);
      expect(closure.existsSync(), isTrue);

      final source = closure.readAsStringSync();
      expect(
        source,
        contains('phase_3_status: completed_dev_gated_foundation'),
      );
      expect(source, contains('keep_dev_gated_until_phase_4'));
      expect(source, contains('implemented_not_wired'));
      expect(source, contains('Restart Phase 4: Account Binding Foundation'));
      expect(source, contains('Restart Phase 3 is closed'));
    });

    test('source docs reference closure document', () {
      const docs = [
        'docs/core/06_shared_pack_direction_spec_v1.md',
        'docs/core/07_remote_request_catalog.md',
        'docs/core/08_shared_pack_remote_schema_v1.md',
        'docs/core/10_shared_pack_runtime_setup_decision.md',
      ];

      for (final path in docs) {
        final source = File(path).readAsStringSync();
        expect(
          source,
          contains(_closurePath),
          reason: '$path must link closure',
        );
      }
    });

    test('manual test docs keep production QA gated', () {
      const docs = [
        'docs/core/manual_tests/shared_pack_v1_application_service_manual_test.md',
        'docs/core/manual_tests/shared_pack_v1_product_ui_manual_test.md',
      ];

      for (final path in docs) {
        final source = File(path).readAsStringSync();
        expect(
          source,
          contains(_closurePath),
          reason: '$path must link closure',
        );
        expect(source, contains('Production'));
        expect(source, contains('Phase 4'));
      }
    });

    test('six Shared Pack v1 requests remain implemented but not wired', () {
      final catalog = File(_catalogPath).readAsStringSync();

      for (final requestId in SharedPackRemoteRequestIds.all) {
        final section = _catalogSection(catalog, requestId);

        expect(section, contains('| Status | `implemented_not_wired` |'));
        expect(section, isNot(contains('| Status | `active` |')));
        expect(section, isNot(contains('active_v1_manual')));
      }
    });

    test('production UI and startup do not wire service or dev harness', () {
      const guardedRoots = [
        'lib/features/reminders/ui',
        'lib/features/reminders/providers',
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
          matches.add('${file.path}: service');
        }
        if (source.contains(harnessName)) {
          matches.add('${file.path}: harness');
        }
      }

      expect(matches, isEmpty);
    });

    test(
      'UI, provider, and controller files do not call Supabase directly',
      () {
        const guardedRoots = [
          'lib/features/reminders/ui',
          'lib/features/reminders/providers',
          'lib/features/shared_pack/application',
        ];
        final files = guardedRoots.expand(_dartFilesUnder);
        final forbiddenPatterns = [
          'supabase.'
              'from(',
          'supabase.'
              'rpc(',
          'Supabase.'
              'instance',
          'Supabase'
              'Client',
        ];
        final matches = <String>[];

        for (final file in files) {
          final source = file.readAsStringSync();
          for (final pattern in forbiddenPatterns) {
            if (source.contains(pattern)) {
              matches.add('${file.path}: $pattern');
            }
          }
        }

        expect(matches, isEmpty);
      },
    );

    test('no actual credentials are committed in app, tests, or docs', () {
      final files = [
        ..._filesUnder('lib'),
        ..._filesUnder('test'),
        ..._filesUnder('docs'),
      ].where(_isTextFile);
      final suspiciousPatterns = [
        RegExp(r'https://[a-z0-9]{20}\.supabase\.co'),
        RegExp(
          'postgresql'
          r'://\S+',
        ),
        RegExp(r'eyJ[A-Za-z0-9_-]{20,}'),
      ];
      final matches = <String>[];

      for (final file in files) {
        final source = file.readAsStringSync();
        for (final pattern in suspiciousPatterns) {
          if (pattern.hasMatch(source)) {
            matches.add('${file.path}: ${pattern.pattern}');
          }
        }
      }

      expect(matches, isEmpty);
    });

    test('Shared Pack user-facing UI text avoids technical wording', () {
      final source = File(
        'lib/features/reminders/presentation/text/reminder_ui_text.dart',
      ).readAsStringSync();
      final sharedPackLines = source
          .split('\n')
          .where((line) => line.contains('sharedPack'))
          .join('\n');
      const forbiddenTerms = [
        'Local Pack',
        'Remote Pack',
        'local-only',
        'remote-backed',
        'anonymous remote',
        'Supabase UID',
        'RLS',
        'mapping',
        'snapshot',
        'outbox',
        'RPC',
      ];

      for (final term in forbiddenTerms) {
        expect(sharedPackLines, isNot(contains(term)));
      }
    });
  });
}

String _catalogSection(String catalog, String requestId) {
  final start = catalog.indexOf('### $requestId');
  expect(start, isNot(-1), reason: '$requestId must exist in $_catalogPath');

  final next = catalog.indexOf('\n### ', start + 1);
  return catalog.substring(start, next == -1 ? catalog.length : next);
}

Iterable<File> _dartFilesUnder(String rootPath) {
  return _filesUnder(rootPath).where((file) => file.path.endsWith('.dart'));
}

Iterable<File> _filesUnder(String rootPath) {
  final root = Directory(rootPath);
  if (!root.existsSync()) {
    return const <File>[];
  }

  return root.listSync(recursive: true).whereType<File>();
}

bool _isTextFile(File file) {
  final path = file.path;
  return path.endsWith('.dart') ||
      path.endsWith('.md') ||
      path.endsWith('.yaml') ||
      path.endsWith('.yml') ||
      path.endsWith('.sql') ||
      path.endsWith('.json');
}
