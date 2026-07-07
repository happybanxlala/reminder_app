import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:reminder_app/core/config/remote_runtime_config.dart';
import 'package:reminder_app/features/shared_pack/remote/shared_pack_remote_request_ids.dart';

const _boundaryDocPath = 'docs/core/13_secure_runtime_config_boundary.md';
const _catalogPath = 'docs/core/07_remote_request_catalog.md';
const _configBoundaryPath = 'lib/core/config/remote_runtime_config.dart';

void main() {
  group('Secure runtime config boundary', () {
    test('missing config validates as missing', () {
      const config = RemoteRuntimeConfig(supabaseUrl: '', supabaseAnonKey: '');

      final result = config.validate();

      expect(result.status, RemoteRuntimeConfigStatus.missing);
      expect(result.isUsable, isFalse);
      expect(result.issues, isNotEmpty);
      expect(config.hasSupabaseConfig, isFalse);
    });

    test('placeholder config validates as placeholder', () {
      const config = RemoteRuntimeConfig(
        supabaseUrl: 'https://YOUR_PROJECT.supabase.co',
        supabaseAnonKey: 'YOUR_SUPABASE_ANON_KEY',
      );

      final result = config.validate();

      expect(result.status, RemoteRuntimeConfigStatus.placeholder);
      expect(result.isUsable, isFalse);
      expect(result.issues.join('\n'), contains('placeholder'));
    });

    test('safe fake config validates as valid', () {
      const config = RemoteRuntimeConfig(
        supabaseUrl: 'https://example.supabase.co',
        supabaseAnonKey: 'safe-test-anon-key-123456',
      );

      final result = config.validate();

      expect(config.hasSupabaseConfig, isTrue);
      expect(result.status, RemoteRuntimeConfigStatus.valid);
      expect(result.isUsable, isTrue);
      expect(result.issues, isEmpty);
    });

    test('malformed URL validates as placeholder', () {
      const config = RemoteRuntimeConfig(
        supabaseUrl: 'not-a-url',
        supabaseAnonKey: 'safe-test-anon-key-123456',
      );

      final result = config.validate();

      expect(result.status, RemoteRuntimeConfigStatus.placeholder);
      expect(result.issues.join('\n'), contains('absolute http or https URL'));
    });

    test('service-role-looking values are rejected', () {
      const config = RemoteRuntimeConfig(
        supabaseUrl: 'https://example.supabase.co',
        supabaseAnonKey: 'service_role_test_key',
      );

      final result = config.validate();

      expect(result.status, RemoteRuntimeConfigStatus.placeholder);
      expect(result.issues.join('\n'), contains('service role'));
    });

    test('database connection values are rejected', () {
      const config = RemoteRuntimeConfig(
        supabaseUrl:
            'postgresql'
            '://user:password@localhost:5432/postgres',
        supabaseAnonKey: 'safe-test-anon-key-123456',
      );

      final result = config.validate();

      expect(result.status, RemoteRuntimeConfigStatus.placeholder);
      expect(result.issues.join('\n'), contains('database connection string'));
    });

    test('runtime credential token values are rejected', () {
      const config = RemoteRuntimeConfig(
        supabaseUrl: 'https://example.supabase.co',
        supabaseAnonKey: 'refresh_token_test_value',
      );

      final result = config.validate();

      expect(result.status, RemoteRuntimeConfigStatus.placeholder);
      expect(result.issues.join('\n'), contains('runtime credential tokens'));
    });

    test('redacted summary hides full anon key', () {
      const anonKey = 'safe-test-anon-key-123456';
      const config = RemoteRuntimeConfig(
        supabaseUrl: 'https://example.supabase.co',
        supabaseAnonKey: anonKey,
      );

      final summary = config.redactedSummary();

      expect(summary, contains('example.supabase.co'));
      expect(summary, contains('supabaseAnonKeyLength: 25'));
      expect(summary, isNot(contains(anonKey)));
    });

    test('dart define source uses project-specific names', () {
      expect(
        DartDefineRemoteRuntimeConfigSource.supabaseUrlDefineName,
        'REMINDER_SUPABASE_URL',
      );
      expect(
        DartDefineRemoteRuntimeConfigSource.supabaseAnonKeyDefineName,
        'REMINDER_SUPABASE_ANON_KEY',
      );
    });

    test('boundary doc exists and records Phase 4B status', () {
      final doc = File(_boundaryDocPath);
      expect(doc.existsSync(), isTrue);

      final source = doc.readAsStringSync();
      expect(
        source,
        contains('phase_4b_status: secure_runtime_config_boundary_defined'),
      );

      for (final phrase in [
        'REMINDER_SUPABASE_URL',
        'REMINDER_SUPABASE_ANON_KEY',
        'service_role key',
        'DATABASE_URL',
        'access token',
        'refresh token',
        'setup-required',
        _configBoundaryPath,
        'Phase 4C: Account Identity Runtime Foundation',
      ]) {
        expect(source, contains(phrase));
      }
    });

    test('source docs reference the Phase 4B boundary doc', () {
      const docs = [
        'docs/core/04_core_model_spec_v1.md',
        'docs/core/07_remote_request_catalog.md',
        'docs/core/10_shared_pack_runtime_setup_decision.md',
        'docs/core/11_shared_pack_phase_3_closure.md',
        'docs/core/12_account_binding_foundation_spec.md',
      ];

      for (final path in docs) {
        final source = File(path).readAsStringSync();
        expect(
          source,
          contains(_boundaryDocPath),
          reason: '$path must reference Phase 4B boundary',
        );
      }
    });

    test('Shared Pack requests remain implemented but not wired', () {
      final catalog = File(_catalogPath).readAsStringSync();

      for (final requestId in SharedPackRemoteRequestIds.all) {
        final section = _section(catalog, '### $requestId', '\n### ');

        expect(section, contains('| Status | `implemented_not_wired` |'));
        expect(section, isNot(contains('| Status | `active` |')));
        expect(section, isNot(contains('active_v1_manual')));
      }
    });

    test('account binding requests remain future-only', () {
      final catalog = File(_catalogPath).readAsStringSync();
      final section = _section(
        catalog,
        '## 7. Planned Requests: Account Binding',
        '\n## 8. ',
      );

      expect(section, contains('account_binding.bind_account.v1'));
      expect(section, contains('account_binding.get_status.v1'));
      expect(section, isNot(contains('| Status |')));
      expect(section, isNot(contains('implemented_not_wired')));
      expect(section, isNot(contains('active_v1_manual')));
    });

    test('no Supabase auth, startup, or UI activation wiring is added', () {
      final files = _dartFilesUnder('lib');
      final matches = <String>[];
      final globallyForbidden = [
        'supabase.'
            'auth',
        'Supabase.'
            'initialize',
        'Supabase.'
            'instance',
        'signIn',
        'signUp',
        'OAuth',
        'GoogleSignIn',
        'SignInWithApple',
      ];

      for (final file in files) {
        final source = file.readAsStringSync();
        for (final pattern in globallyForbidden) {
          if (source.contains(pattern)) {
            matches.add('${file.path}: $pattern');
          }
        }
      }

      expect(matches, isEmpty);
    });

    test('production UI and startup do not import config boundary', () {
      const guardedRoots = [
        'lib/features/reminders/ui',
        'lib/features/reminders/providers',
        'lib/features/shared_pack/application',
        'lib/app',
      ];
      const guardedFiles = ['lib/main.dart'];
      final files = [
        ...guardedRoots.expand(_dartFilesUnder),
        ...guardedFiles
            .map((path) => File(path))
            .where((file) => file.existsSync()),
      ];
      final matches = <String>[];

      for (final file in files) {
        final source = file.readAsStringSync();
        if (source.contains('remote_runtime_config') ||
            source.contains('RemoteRuntimeConfig')) {
          matches.add(file.path);
        }
      }

      expect(matches, isEmpty);
    });

    test('no account binding migration or runtime files are added', () {
      final accountBindingPaths =
          [..._filesUnder('lib'), ..._filesUnder('supabase/migrations')]
              .map((file) => file.path.replaceAll('\\', '/'))
              .where((path) => path.contains('account_binding'))
              .toList();

      expect(accountBindingPaths, isEmpty);
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
