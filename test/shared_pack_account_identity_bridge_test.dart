import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reminder_app/features/account/application/account_identity.dart';
import 'package:reminder_app/features/account/application/account_identity_result.dart';
import 'package:reminder_app/features/account/application/account_status_ui_controller.dart';
import 'package:reminder_app/features/shared_pack/application/shared_pack_account_identity_bridge.dart';
import 'package:reminder_app/features/shared_pack/application/shared_pack_identity_provider.dart';
import 'package:reminder_app/features/shared_pack/application/shared_pack_ui_controller.dart';
import 'package:reminder_app/features/shared_pack/remote/shared_pack_remote_request_ids.dart';

import 'support/fake_account_identity_runtime.dart';

const _bridgeDocPath = 'docs/core/16_shared_pack_account_identity_bridge.md';
const _catalogPath = 'docs/core/07_remote_request_catalog.md';

void main() {
  group('Shared Pack account identity bridge', () {
    test('doc exists and records Phase 4E marker', () {
      final doc = File(_bridgeDocPath);
      expect(doc.existsSync(), isTrue);

      final source = doc.readAsStringSync();
      expect(
        source,
        contains('phase_4e_status: shared_pack_account_identity_bridge_added'),
      );
      expect(
        source,
        contains('docs/core/14_account_identity_runtime_foundation.md'),
      );
      expect(source, contains('docs/core/15_account_status_ui.md'));
      expect(source, contains('Shared Pack v1 requests remain'));
      expect(source, contains('implemented_not_wired'));
    });

    test('bound account identity resolves requester account id', () async {
      final identity = AccountIdentity(accountId: 'stable-account-id');
      final provider = _providerFor(
        AccountIdentitySnapshot.bound(identity: identity),
      );

      expect(await provider.currentIdentityId(), 'stable-account-id');
    });

    test('non-bound account states fail safely', () async {
      final identity = AccountIdentity(accountId: 'stable-account-id');
      final snapshots = [
        AccountIdentitySnapshot.unbound(),
        AccountIdentitySnapshot(status: AccountBindingStatus.binding),
        AccountIdentitySnapshot(status: AccountBindingStatus.bindingFailed),
        AccountIdentitySnapshot(
          status: AccountBindingStatus.needsReauth,
          identity: identity,
        ),
      ];

      for (final snapshot in snapshots) {
        final provider = _providerFor(snapshot);

        expect(
          provider.currentIdentityId(),
          throwsA(isA<AccountIdentityUnavailableException>()),
          reason: snapshot.status.name,
        );
      }
    });

    test(
      'default bridge provider fails because production runtime is unbound',
      () {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        final provider = container.read(sharedPackAccountIdentityProvider);

        expect(
          provider.currentIdentityId(),
          throwsA(isA<AccountIdentityUnavailableException>()),
        );
      },
    );

    test(
      'bridge provider can resolve test-only bound runtime override',
      () async {
        final identity = AccountIdentity(accountId: 'stable-account-id');
        final container = ProviderContainer(
          overrides: [
            accountIdentityRuntimeProvider.overrideWithValue(
              FakeAccountIdentityRuntime(
                AccountIdentitySnapshot.bound(identity: identity),
              ),
            ),
          ],
        );
        addTearDown(container.dispose);

        final provider = container.read(sharedPackAccountIdentityProvider);

        expect(await provider.currentIdentityId(), 'stable-account-id');
      },
    );

    test('Shared Pack UI controller remains disabled by default', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final controller = container.read(sharedPackUiControllerProvider);

      expect(controller.availability.isEnabled, isFalse);
      expect(
        controller.availability.reason,
        SharedPackUiAvailability.productionSetupRequiredReason,
      );
    });

    test(
      'catalog remains implemented_not_wired and account binding future-only',
      () {
        final catalog = File(_catalogPath).readAsStringSync();
        expect(catalog, contains(_bridgeDocPath));

        for (final requestId in SharedPackRemoteRequestIds.all) {
          final section = _section(catalog, '### $requestId', '\n### ');
          expect(section, contains('| Status | `implemented_not_wired` |'));
          expect(section, isNot(contains('| Status | `active` |')));
          expect(section, isNot(contains('active_v1_manual')));
        }

        final accountBindingSection = _section(
          catalog,
          '## 7. Planned Requests: Account Binding',
          '\n## 8. ',
        );
        expect(
          accountBindingSection,
          contains('account_binding.bind_account.v1'),
        );
        expect(
          accountBindingSection,
          contains('account_binding.get_status.v1'),
        );
        expect(accountBindingSection, isNot(contains('| Status |')));
        expect(accountBindingSection, isNot(contains('implemented_not_wired')));
        expect(accountBindingSection, isNot(contains('active_v1_manual')));
      },
    );

    test('static identity remains test and dev/manual only', () {
      final productionMatches = <String>[];
      for (final file in _dartFilesUnder('lib')) {
        final path = file.path.replaceAll('\\', '/');
        if (path.endsWith(
          'lib/features/shared_pack/application/shared_pack_identity_provider.dart',
        )) {
          continue;
        }
        final source = file.readAsStringSync();
        if (source.contains('StaticSharedPackIdentityProvider')) {
          productionMatches.add(file.path);
        }
      }

      expect(productionMatches, isEmpty);

      final testAndManualMatches =
          [
                ..._dartFilesUnder('test'),
                ..._markdownFilesUnder('docs/core/manual_tests'),
                ..._markdownFilesUnder('docs/core'),
              ]
              .where((file) {
                return file.readAsStringSync().contains(
                  'StaticSharedPackIdentityProvider',
                );
              })
              .map((file) => file.path)
              .toSet();

      expect(testAndManualMatches, isNotEmpty);
    });

    test('no production UI, auth, migration, or secrets are introduced', () {
      const productionRoots = [
        'lib/app',
        'lib/features/reminders/ui',
        'lib/features/reminders/providers',
      ];
      final productionMatches = <String>[];
      for (final file in productionRoots.expand(_dartFilesUnder)) {
        final source = file.readAsStringSync();
        if (source.contains('sharedPackAccountIdentityProvider') ||
            source.contains('AccountBackedSharedPackIdentityProvider') ||
            source.contains('SharedPackApplicationService(')) {
          productionMatches.add(file.path);
        }
      }
      expect(productionMatches, isEmpty);

      final libSources = _dartFilesUnder(
        'lib',
      ).map((file) => MapEntry(file.path, file.readAsStringSync()));
      const forbidden = [
        'Supabase.auth',
        'supabase.auth',
        'signIn',
        'signUp',
        'OAuth',
        'GoogleSignIn',
        'SignInWithApple',
      ];
      for (final entry in libSources) {
        for (final pattern in forbidden) {
          expect(entry.value, isNot(contains(pattern)), reason: entry.key);
        }
      }

      final migrationMatches = _filesUnder('supabase/migrations')
          .where((file) => file.path.endsWith('.sql'))
          .where((file) {
            final source = file.readAsStringSync();
            return source.contains('account_binding') ||
                source.contains('account_identity');
          })
          .map((file) => file.path)
          .toList();
      expect(migrationMatches, isEmpty);
    });
  });
}

SharedPackIdentityProvider _providerFor(AccountIdentitySnapshot snapshot) {
  final container = ProviderContainer(
    overrides: [
      accountIdentityRuntimeProvider.overrideWithValue(
        FakeAccountIdentityRuntime(snapshot),
      ),
    ],
  );
  addTearDown(container.dispose);
  return container.read(sharedPackAccountIdentityProvider);
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

Iterable<File> _markdownFilesUnder(String rootPath) {
  return _filesUnder(rootPath).where((file) => file.path.endsWith('.md'));
}

Iterable<File> _filesUnder(String rootPath) {
  final root = Directory(rootPath);
  if (!root.existsSync()) {
    return const <File>[];
  }
  return root.listSync(recursive: true).whereType<File>();
}
