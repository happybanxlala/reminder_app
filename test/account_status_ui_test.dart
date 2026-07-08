import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reminder_app/app/theme/reminder_theme.dart';
import 'package:reminder_app/features/account/application/account_identity.dart';
import 'package:reminder_app/features/account/application/account_status_ui_controller.dart';
import 'package:reminder_app/features/reminders/data/local/app_database.dart';
import 'package:reminder_app/features/reminders/domain/app_settings.dart';
import 'package:reminder_app/features/reminders/domain/attention_policy.dart';
import 'package:reminder_app/features/reminders/providers/database_providers.dart';
import 'package:reminder_app/features/reminders/providers/developer_settings_providers.dart';
import 'package:reminder_app/features/reminders/providers/settings_providers.dart';
import 'package:reminder_app/features/reminders/ui/pages/feature_page.dart';
import 'package:reminder_app/features/shared_pack/remote/shared_pack_remote_request_ids.dart';

import 'support/fake_account_identity_runtime.dart';

const _accountStatusDocPath = 'docs/core/15_account_status_ui.md';
const _catalogPath = 'docs/core/07_remote_request_catalog.md';

void main() {
  group('Account Status UI', () {
    test('docs define Phase 4D and source references', () {
      final doc = File(_accountStatusDocPath);
      expect(doc.existsSync(), isTrue);

      final source = doc.readAsStringSync();
      expect(source, contains('phase_4d_status: account_status_ui_added'));
      expect(
        source,
        contains('docs/core/12_account_binding_foundation_spec.md'),
      );
      expect(
        source,
        contains('docs/core/14_account_identity_runtime_foundation.md'),
      );

      const referencingDocs = [
        'docs/core/04_core_model_spec_v1.md',
        'docs/core/07_remote_request_catalog.md',
        'docs/core/12_account_binding_foundation_spec.md',
        'docs/core/13_secure_runtime_config_boundary.md',
        'docs/core/14_account_identity_runtime_foundation.md',
      ];
      for (final path in referencingDocs) {
        expect(
          File(path).readAsStringSync(),
          contains(_accountStatusDocPath),
          reason: path,
        );
      }
    });

    testWidgets('default production account status renders unbound', (
      tester,
    ) async {
      await _pumpSettings(tester);

      expect(
        find.byKey(const Key('settings-account-status-section')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('settings-account-status-card')),
        findsOneWidget,
      );
      expect(find.text('帳號未綁定'), findsOneWidget);
      expect(find.text('此裝置上的 Personal Pack 資料尚未受到帳號保護。'), findsOneWidget);
      expect(
        find.text('綁定帳號後，日後可支援雲端備份與換機恢復。Shared Pack 功能亦會使用帳號保護成員身份。'),
        findsOneWidget,
      );
      _expectNoAccountStatusAction();
      _expectNoForbiddenVisibleAccountStatusText(tester);
    });

    testWidgets('fake runtime renders all account states safely', (
      tester,
    ) async {
      final identity = AccountIdentity(accountId: 'stable-account-id');
      final cases = [
        _StatusCase(
          snapshot: AccountIdentitySnapshot.unbound(),
          title: '帳號未綁定',
          body: '此裝置上的 Personal Pack 資料尚未受到帳號保護。',
        ),
        _StatusCase(
          snapshot: AccountIdentitySnapshot(
            status: AccountBindingStatus.binding,
          ),
          title: '正在綁定帳號',
          body: '正在準備帳號保護。',
        ),
        _StatusCase(
          snapshot: AccountIdentitySnapshot.bound(identity: identity),
          title: '帳號已綁定',
          body: '此裝置已有帳號保護身份。',
        ),
        _StatusCase(
          snapshot: AccountIdentitySnapshot(
            status: AccountBindingStatus.bindingFailed,
          ),
          title: '帳號綁定未完成',
          body: '帳號綁定未能完成，請稍後再試。',
        ),
        _StatusCase(
          snapshot: AccountIdentitySnapshot(
            status: AccountBindingStatus.needsReauth,
            identity: identity,
          ),
          title: '需要重新驗證帳號',
          body: '請重新驗證帳號，之後才能繼續使用帳號保護功能。',
        ),
      ];

      for (final testCase in cases) {
        await _pumpSettings(tester, snapshot: testCase.snapshot);

        expect(find.text(testCase.title), findsOneWidget);
        expect(find.text(testCase.body), findsOneWidget);
        expect(find.text('所有資料已備份'), findsNothing);
        expect(find.text('全部資料已同步'), findsNothing);
        expect(find.text('完整換機恢復已可用'), findsNothing);
        _expectNoAccountStatusAction();
        _expectNoForbiddenVisibleAccountStatusText(tester);
      }
    });

    test('catalog keeps remote requests inactive for Phase 4D', () {
      final catalog = File(_catalogPath).readAsStringSync();
      expect(catalog, contains(_accountStatusDocPath));
      expect(catalog, contains('Account status UI is local runtime/status UI'));

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
      expect(accountBindingSection, contains('account_binding.get_status.v1'));
      expect(accountBindingSection, isNot(contains('| Status |')));
      expect(accountBindingSection, isNot(contains('implemented_not_wired')));
      expect(accountBindingSection, isNot(contains('active_v1_manual')));
    });

    test('Phase 4D does not add auth, migration, secrets, or wiring', () {
      final libSources = _dartFilesUnder(
        'lib',
      ).map((file) => MapEntry(file.path, file.readAsStringSync())).toList();

      const authForbidden = [
        'Supabase.auth',
        'supabase.auth',
        'signIn',
        'signUp',
        'OAuth',
        'GoogleSignIn',
        'SignInWithApple',
      ];
      for (final entry in libSources) {
        for (final pattern in authForbidden) {
          expect(entry.value, isNot(contains(pattern)), reason: entry.key);
        }
      }

      final accountStatusSource = File(
        'lib/features/account/application/account_status_ui_controller.dart',
      ).readAsStringSync();
      for (final forbidden in [
        'Supabase',
        'supabase',
        'access token',
        'refresh token',
        'service_role',
        'DATABASE_URL',
        'Local Pack',
        'Remote Pack',
      ]) {
        expect(accountStatusSource, isNot(contains(forbidden)));
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

      const productionRoots = [
        'lib/app',
        'lib/features/reminders/ui',
        'lib/features/reminders/providers',
      ];
      final productionSources = productionRoots
          .expand(_dartFilesUnder)
          .map((file) => MapEntry(file.path, file.readAsStringSync()))
          .toList();
      final wiringMatches = <String>[];
      for (final entry in productionSources) {
        if (entry.value.contains('AccountBackedSharedPackIdentityProvider') ||
            entry.value.contains('account_shared_pack_identity_provider') ||
            entry.value.contains('SharedPackApplicationService(')) {
          wiringMatches.add(entry.key);
        }
      }
      expect(wiringMatches, isEmpty);

      final secretMatches = <String>[];
      for (final file in _dartFilesUnder('lib')) {
        final source = file.readAsStringSync();
        if (source.contains('service_role=') ||
            source.contains('DATABASE_URL=') ||
            source.contains('provider_token=') ||
            source.contains('database password')) {
          secretMatches.add(file.path);
        }
      }
      expect(secretMatches, isEmpty);
    });
  });
}

Future<void> _pumpSettings(
  WidgetTester tester, {
  AccountIdentitySnapshot? snapshot,
}) async {
  final db = AppDatabase.forTesting(NativeDatabase.memory());
  addTearDown(db.close);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        appSettingsProvider.overrideWith((ref) => Stream.value(_appSettings())),
        developerSettingsVisibleProvider.overrideWith((ref) => false),
        systemPreviewDateProvider.overrideWith(
          (ref) => Stream.value(DateTime(2026, 5, 28)),
        ),
        if (snapshot != null)
          accountIdentityRuntimeProvider.overrideWithValue(
            FakeAccountIdentityRuntime(snapshot),
          ),
      ],
      child: MaterialApp(
        theme: ReminderTheme.light(),
        home: const SettingsPage(),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
}

void _expectNoAccountStatusAction() {
  final section = find.byKey(const Key('settings-account-status-section'));
  for (final buttonFinder in [
    find.byType(FilledButton),
    find.byType(OutlinedButton),
    find.byType(TextButton),
    find.byType(ElevatedButton),
  ]) {
    expect(find.descendant(of: section, matching: buttonFinder), findsNothing);
  }
}

void _expectNoForbiddenVisibleAccountStatusText(WidgetTester tester) {
  final card = find.byKey(const Key('settings-account-status-card'));
  final textWidgets = tester
      .widgetList<Text>(find.descendant(of: card, matching: find.byType(Text)))
      .map((text) => text.data ?? text.textSpan?.toPlainText() ?? '')
      .join('\n');

  for (final forbidden in [
    'Supabase',
    'Supabase UID',
    'anonymous identity',
    'access token',
    'refresh token',
    'service_role',
    'DATABASE_URL',
    'Local Pack',
    'Remote Pack',
    'mapping',
    'snapshot',
    'RPC',
    'outbox',
  ]) {
    expect(textWidgets, isNot(contains(forbidden)), reason: forbidden);
  }
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

AppSettings _appSettings() {
  return AppSettings(
    reminderTone: ReminderTone.standard,
    notificationReminderTime: '09:00',
    updatedAt: DateTime(2026, 5, 28),
  );
}

class _StatusCase {
  const _StatusCase({
    required this.snapshot,
    required this.title,
    required this.body,
  });

  final AccountIdentitySnapshot snapshot;
  final String title;
  final String body;
}
