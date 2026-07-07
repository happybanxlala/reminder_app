import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:reminder_app/features/shared_pack/remote/shared_pack_remote_request_ids.dart';

const _specPath = 'docs/core/12_account_binding_foundation_spec.md';
const _catalogPath = 'docs/core/07_remote_request_catalog.md';

void main() {
  group('Account binding foundation spec', () {
    test('spec exists and records Phase 4A contract marker', () {
      final spec = File(_specPath);
      expect(spec.existsSync(), isTrue);

      final source = spec.readAsStringSync();
      expect(
        source,
        contains('phase_4a_status: account_binding_definition_confirmed'),
      );
      expect(
        source,
        contains(
          'Account binding means connecting the current device’s user data '
          'and shared identity to a stable account identity that can be '
          'recovered and re-verified later.',
        ),
      );
      expect(source, contains('Phase 4B: Secure Runtime Config Boundary'));
    });

    test('spec defines product language and account states', () {
      final source = File(_specPath).readAsStringSync();

      for (final term in [
        'Account protection',
        'Bind account',
        'Account status',
        'Cloud backup',
        'Restore on new device',
        'Protected by account',
        'Not yet protected by account',
        'Personal Pack',
        'Shared Pack',
      ]) {
        expect(source, contains(term), reason: '$term must be defined');
      }

      for (final state in [
        'unbound',
        'binding',
        'bound',
        'bindingFailed',
        'needsReauth',
      ]) {
        expect(source, contains('### $state'));
      }

      for (final forbiddenUiTerm in [
        'Local Pack',
        'Remote Pack',
        'local-only',
        'remote-backed',
        'anonymous identity',
        'anonymous user',
        'Supabase user',
        'Supabase UID',
      ]) {
        expect(source, contains(forbiddenUiTerm));
      }
    });

    test('spec locks non-implementation and future phase boundaries', () {
      final source = File(_specPath).readAsStringSync();

      for (final phrase in [
        'It does not mean Personal Pack cloud sync is complete immediately.',
        'It does not mean full restore is complete immediately.',
        'It does not mean realtime sync.',
        'It does not mean multi-account switching.',
        'It does not mean OAuth/provider overbuild in Phase 4A.',
        'Phase 4A does not implement login, OAuth, Supabase auth runtime, '
            'Personal Pack cloud migration, or Shared Pack production '
            'activation.',
        'Phase 4A does not migrate Personal Pack data.',
        'Personal Pack cloud migration is Phase 5.',
        'Realtime / Offline / Advanced Sync is Phase 6.',
        'Restart Phase 5: Personal Data Cloud Migration',
      ]) {
        expect(source, contains(phrase));
      }

      for (final tokenRule in [
        'Supabase access token',
        'refresh token',
        'service role key',
        'provider token',
        'database password',
        'DATABASE_URL',
        'plaintext credentials',
        'invite code as recovery method',
      ]) {
        expect(source, contains(tokenRule));
      }
    });

    test('source docs reference the Phase 4A spec', () {
      const docs = [
        'docs/core/04_core_model_spec_v1.md',
        'docs/core/06_shared_pack_direction_spec_v1.md',
        'docs/core/07_remote_request_catalog.md',
        'docs/core/11_shared_pack_phase_3_closure.md',
      ];

      for (final path in docs) {
        final source = File(path).readAsStringSync();
        expect(source, contains(_specPath), reason: '$path must link spec');
      }
    });

    test('catalog keeps account binding future-only', () {
      final catalog = File(_catalogPath).readAsStringSync();
      final section = _section(
        catalog,
        '## 7. Planned Requests: Account Binding',
        '\n## 8. ',
      );

      expect(section, contains('account_binding.bind_account.v1'));
      expect(section, contains('account_binding.get_status.v1'));
      expect(section, contains('does not implement account_binding'));
      expect(section, isNot(contains('| Status |')));
      expect(section, isNot(contains('implemented_not_wired')));
      expect(section, isNot(contains('active_v1_manual')));
    });

    test('Shared Pack v1 requests remain implemented but not wired', () {
      final catalog = File(_catalogPath).readAsStringSync();

      for (final requestId in SharedPackRemoteRequestIds.all) {
        final section = _section(catalog, '### $requestId', '\n### ');

        expect(section, contains('| Status | `implemented_not_wired` |'));
        expect(section, isNot(contains('| Status | `active` |')));
        expect(section, isNot(contains('active_v1_manual')));
      }
    });

    test('lib has no account binding runtime, auth, or startup wiring', () {
      final files = _dartFilesUnder('lib');
      final forbiddenPatterns = [
        'supabase.'
            'auth',
        'Supabase.'
            'instance',
        'signIn',
        'signUp',
        'OAuth',
        'GoogleSignIn',
        'SignInWithApple',
        'DATABASE_URL',
      ];
      final configBoundaryOnlyPatterns = [
        'String.'
            'fromEnvironment(',
        'REMINDER_SUPABASE_URL',
        'REMINDER_SUPABASE_ANON_KEY',
        'service_role',
        'anon_key',
      ];
      const approvedSafeBoundaryFiles = {
        'lib/core/config/remote_runtime_config.dart',
        'lib/features/account/application/account_identity.dart',
      };
      final matches = <String>[];

      for (final file in files) {
        final source = file.readAsStringSync();
        final path = file.path.replaceAll('\\', '/');
        for (final pattern in forbiddenPatterns) {
          if (source.contains(pattern)) {
            matches.add('${file.path}: $pattern');
          }
        }
        for (final pattern in configBoundaryOnlyPatterns) {
          if (!source.contains(pattern)) {
            continue;
          }
          if (!approvedSafeBoundaryFiles.contains(path)) {
            matches.add('${file.path}: $pattern');
          }
        }
      }

      expect(matches, isEmpty);
    });

    test('no OAuth provider dependency is added', () {
      final source = File('pubspec.yaml').readAsStringSync();
      final forbiddenDependencies = [
        'google_sign_in',
        'sign_in_with_apple',
        'oauth',
        'openid',
      ];

      for (final dependency in forbiddenDependencies) {
        expect(source, isNot(contains(dependency)));
      }
    });

    test('no account binding runtime or migration files exist', () {
      final paths = [
        ..._filesUnder('lib'),
        ..._filesUnder('supabase/migrations'),
      ].map((file) => file.path.replaceAll('\\', '/')).toList();
      final accountBindingPaths = paths
          .where((path) => path.contains('account_binding'))
          .toList();

      expect(accountBindingPaths, isEmpty);

      final migrationMatches = <String>[];
      for (final file in _filesUnder('supabase/migrations')) {
        if (!file.path.endsWith('.sql')) {
          continue;
        }
        final source = file.readAsStringSync();
        if (source.contains('account_binding')) {
          migrationMatches.add(file.path);
        }
      }

      expect(migrationMatches, isEmpty);
    });

    test('no actual credentials are committed', () {
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

    test('user-facing Shared Pack text avoids technical identity wording', () {
      final source = File(
        'lib/features/reminders/presentation/text/reminder_ui_text.dart',
      ).readAsStringSync();
      final relevantLines = source
          .split('\n')
          .where(
            (line) =>
                line.contains('sharedPack') ||
                line.contains('account') ||
                line.contains('Account'),
          )
          .join('\n');

      for (final term in [
        'Local Pack',
        'Remote Pack',
        'local-only',
        'remote-backed',
        'anonymous identity',
        'anonymous user',
        'Supabase user',
        'Supabase UID',
      ]) {
        expect(relevantLines, isNot(contains(term)));
      }
    });
  });
}

String _section(String source, String startMarker, String nextMarker) {
  final start = source.indexOf(startMarker);
  expect(start, isNot(-1), reason: '$startMarker must exist');

  final next = source.indexOf(nextMarker, start + startMarker.length);
  return source.substring(start, next == -1 ? source.length : next);
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
