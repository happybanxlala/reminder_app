import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reminder_app/features/shared_pack/application/shared_pack_ui_controller.dart';
import 'package:reminder_app/features/shared_pack/remote/shared_pack_remote_request_ids.dart';

const _decisionPath = 'docs/core/10_shared_pack_runtime_setup_decision.md';
const _catalogPath = 'docs/core/07_remote_request_catalog.md';
const _schemaPath = 'docs/core/08_shared_pack_remote_schema_v1.md';
const _manualUiPath =
    'docs/core/manual_tests/shared_pack_v1_product_ui_manual_test.md';

void main() {
  group('Shared Pack runtime setup decision', () {
    test(
      'decision document exists and has exactly one recommendation marker',
      () {
        final decision = File(_decisionPath);
        expect(decision.existsSync(), isTrue);

        final source = decision.readAsStringSync();
        expect(_occurrences(source, 'keep_dev_gated_until_phase_4'), 1);
        expect(source, isNot(contains('dev_internal_only')));
        expect(source, contains('Shared Pack v1 should not become active'));
      },
    );

    test('catalog, schema, and manual UI docs reference decision', () {
      final catalog = File(_catalogPath).readAsStringSync();
      final schema = File(_schemaPath).readAsStringSync();
      final manual = File(_manualUiPath).readAsStringSync();

      expect(catalog, contains(_decisionPath));
      expect(schema, contains(_decisionPath));
      expect(manual, contains(_decisionPath));
      expect(manual, contains('keep_dev_gated_until_phase_4'));
    });

    test(
      'Shared Pack v1 request catalog remains implemented but not wired',
      () {
        final catalog = File(_catalogPath).readAsStringSync();

        for (final requestId in SharedPackRemoteRequestIds.all) {
          final section = _catalogSection(catalog, requestId);

          expect(section, contains('| Status | `implemented_not_wired` |'));
          expect(section, isNot(contains('| Status | `active` |')));
          expect(section, isNot(contains('active_v1_manual')));
        }
      },
    );

    test('default UI controller availability remains setup-required', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final controller = container.read(sharedPackUiControllerProvider);
      final availability = controller.availability;

      expect(availability.isEnabled, isFalse);
      expect(
        availability.reason,
        SharedPackUiAvailability.productionSetupRequiredReason,
      );
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

    test('Supabase calls stay inside approved remote boundary', () {
      final files = _dartFilesUnder('lib');
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
        final path = file.path.replaceAll('\\', '/');

        for (final pattern in globallyForbiddenPatterns) {
          if (source.contains(pattern)) {
            matches.add('${file.path}: $pattern');
          }
        }

        for (final pattern in boundaryOnlyPatterns) {
          if (!source.contains(pattern)) {
            continue;
          }
          if (!approvedRemoteBoundaryFiles.contains(path)) {
            matches.add('${file.path}: $pattern');
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
        'remote',
        'Supabase',
        'anonymous identity',
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
  final root = Directory(rootPath);
  if (!root.existsSync()) {
    return const <File>[];
  }

  return root
      .listSync(recursive: true)
      .whereType<File>()
      .where((file) => file.path.endsWith('.dart'));
}

int _occurrences(String source, String pattern) {
  var count = 0;
  var index = 0;
  while (true) {
    index = source.indexOf(pattern, index);
    if (index == -1) {
      return count;
    }
    count += 1;
    index += pattern.length;
  }
}
