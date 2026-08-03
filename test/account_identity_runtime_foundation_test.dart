import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:reminder_app/features/account/application/account_identity.dart';
import 'package:reminder_app/features/account/application/account_identity_result.dart';
import 'package:reminder_app/features/account/application/account_identity_runtime.dart';
import 'package:reminder_app/features/account/application/account_shared_pack_identity_provider.dart';
import 'package:reminder_app/features/shared_pack/remote/shared_pack_remote_request_ids.dart';

import 'support/fake_account_identity_runtime.dart';

const _identityDocPath = 'docs/core/14_account_identity_runtime_foundation.md';
const _catalogPath = 'docs/core/07_remote_request_catalog.md';

void main() {
  group('Account identity runtime foundation', () {
    test('doc exists and records Phase 4C status', () {
      final doc = File(_identityDocPath);
      expect(doc.existsSync(), isTrue);

      final source = doc.readAsStringSync();
      expect(
        source,
        contains(
          'phase_4c_status: account_identity_runtime_foundation_defined',
        ),
      );
      expect(
        source,
        contains('docs/core/12_account_binding_foundation_spec.md'),
      );
      expect(
        source,
        contains('docs/core/13_secure_runtime_config_boundary.md'),
      );

      for (final phrase in [
        'Default production runtime remains unbound',
        'It does not implement login.',
        'It does not implement OAuth.',
        'It does not call Supabase.auth.',
        'It does not activate Shared Pack production UI.',
        'It does not migrate Personal Pack data.',
        'Phase 4D: Account Status UI',
      ]) {
        expect(source, contains(phrase));
      }
    });

    test('account binding status contains the product states', () {
      expect(AccountBindingStatus.values.map((status) => status.name), [
        'unbound',
        'binding',
        'bound',
        'bindingFailed',
        'needsReauth',
      ]);
    });

    test('account identity validates account id and secret-looking values', () {
      expect(
        () => AccountIdentity(accountId: ''),
        throwsA(isA<ArgumentError>()),
      );
      expect(
        () => AccountIdentity(accountId: 'access_token_value'),
        throwsA(isA<ArgumentError>()),
      );
      expect(
        () => AccountIdentity(accountId: 'stable-account-id'),
        returnsNormally,
      );
    });

    test('account identity snapshot enforces state rules', () {
      final identity = AccountIdentity(accountId: 'stable-account-id');

      expect(AccountIdentitySnapshot.unbound().identity, isNull);
      expect(
        () => AccountIdentitySnapshot(
          status: AccountBindingStatus.unbound,
          identity: identity,
        ),
        throwsA(isA<ArgumentError>()),
      );
      expect(
        () => AccountIdentitySnapshot(status: AccountBindingStatus.bound),
        throwsA(isA<ArgumentError>()),
      );

      final bound = AccountIdentitySnapshot.bound(identity: identity);
      expect(bound.identity, identity);
      expect(bound.canProvideIdentityForRemoteWrites, isTrue);

      final needsReauth = AccountIdentitySnapshot(
        status: AccountBindingStatus.needsReauth,
        identity: identity,
      );
      expect(needsReauth.identity, identity);
      expect(needsReauth.canProvideIdentityForRemoteWrites, isFalse);
    });

    test('default runtime returns unbound', () async {
      const runtime = DefaultUnboundAccountIdentityRuntime();

      final snapshot = await runtime.currentSnapshot();

      expect(snapshot.status, AccountBindingStatus.unbound);
      expect(snapshot.identity, isNull);
      expect(snapshot.canProvideIdentityForRemoteWrites, isFalse);
    });

    test(
      'fake runtime can return bound, unbound, and needsReauth snapshots',
      () async {
        final identity = AccountIdentity(accountId: 'stable-account-id');
        final runtime = FakeAccountIdentityRuntime(
          AccountIdentitySnapshot.bound(identity: identity),
        );

        expect(
          (await runtime.currentSnapshot()).status,
          AccountBindingStatus.bound,
        );

        runtime.snapshot = AccountIdentitySnapshot.unbound();
        expect(
          (await runtime.currentSnapshot()).status,
          AccountBindingStatus.unbound,
        );

        runtime.snapshot = AccountIdentitySnapshot(
          status: AccountBindingStatus.needsReauth,
          identity: identity,
        );
        expect(
          (await runtime.currentSnapshot()).status,
          AccountBindingStatus.needsReauth,
        );
      },
    );

    test('adapter returns account id only for bound identity', () async {
      final identity = AccountIdentity(accountId: 'stable-account-id');
      final provider = AccountBackedSharedPackIdentityProvider(
        FakeAccountIdentityRuntime(
          AccountIdentitySnapshot.bound(identity: identity),
        ),
      );

      expect(await provider.currentIdentityId(), 'stable-account-id');
    });

    test('adapter fails safely when account is unavailable', () async {
      for (final snapshot in [
        AccountIdentitySnapshot.unbound(),
        AccountIdentitySnapshot(status: AccountBindingStatus.binding),
        AccountIdentitySnapshot(status: AccountBindingStatus.bindingFailed),
        AccountIdentitySnapshot(
          status: AccountBindingStatus.needsReauth,
          identity: AccountIdentity(accountId: 'stable-account-id'),
        ),
      ]) {
        final provider = AccountBackedSharedPackIdentityProvider(
          FakeAccountIdentityRuntime(snapshot),
        );

        expect(
          provider.currentIdentityId(),
          throwsA(isA<AccountIdentityUnavailableException>()),
        );
      }
    });

    test('account runtime and adapter do not import or call Supabase', () {
      const paths = [
        'lib/features/account/application/account_identity.dart',
        'lib/features/account/application/account_identity_runtime.dart',
        'lib/features/account/application/account_identity_result.dart',
        'lib/features/account/application/account_shared_pack_identity_provider.dart',
      ];
      const forbidden = [
        'supabase',
        'Supabase',
        'signIn',
        'signUp',
        'OAuth',
        'GoogleSignIn',
        'SignInWithApple',
      ];

      for (final path in paths) {
        final source = File(path).readAsStringSync();
        for (final pattern in forbidden) {
          expect(source, isNot(contains(pattern)), reason: '$path $pattern');
        }
      }
    });

    test('source docs reference the Phase 4C foundation doc', () {
      const docs = [
        'docs/core/04_core_model_spec_v1.md',
        'docs/core/07_remote_request_catalog.md',
        'docs/core/10_shared_pack_runtime_setup_decision.md',
        'docs/core/11_shared_pack_phase_3_closure.md',
        'docs/core/12_account_binding_foundation_spec.md',
        'docs/core/13_secure_runtime_config_boundary.md',
      ];

      for (final path in docs) {
        final source = File(path).readAsStringSync();
        expect(source, contains(_identityDocPath), reason: path);
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

    test('production UI and startup do not import the account adapter', () {
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
      final matches = <String>[];

      for (final file in files) {
        final source = file.readAsStringSync();
        if (source.contains('AccountBackedSharedPackIdentityProvider') ||
            source.contains('account_shared_pack_identity_provider')) {
          matches.add(file.path);
        }
      }

      expect(matches, isEmpty);
    });

    test('no account identity migration or secret fields are added', () {
      final accountSource = File(
        'lib/features/account/application/account_identity.dart',
      ).readAsStringSync();
      for (final forbiddenField in [
        'accessToken',
        'refreshToken',
        'providerToken',
        'serviceRole',
        'databaseUrl',
      ]) {
        expect(accountSource, isNot(contains(forbiddenField)));
      }

      final migrationMatches = _filesUnder('supabase/migrations')
          .where((file) => file.path.endsWith('.sql'))
          .where((file) => file.readAsStringSync().contains('account_identity'))
          .map((file) => file.path)
          .toList();

      expect(migrationMatches, isEmpty);
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
