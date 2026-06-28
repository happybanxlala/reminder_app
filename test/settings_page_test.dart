import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:reminder_app/app/theme/reminder_theme.dart';
import 'package:reminder_app/features/reminders/data/auth_repository.dart';
import 'package:reminder_app/features/reminders/data/identity_repository.dart';
import 'package:reminder_app/features/reminders/data/item_repository.dart';
import 'package:reminder_app/features/reminders/data/local/app_database.dart';
import 'package:reminder_app/features/reminders/data/reminder_backup_service.dart';
import 'package:reminder_app/features/reminders/data/remote_shared_pack_data_source.dart';
import 'package:reminder_app/features/reminders/data/remote_shared_pack_models.dart';
import 'package:reminder_app/features/reminders/data/remote_shared_pack_repository.dart';
import 'package:reminder_app/features/reminders/data/remote_shared_pack_realtime_data_source.dart';
import 'package:reminder_app/features/reminders/data/shared_pack_repository.dart';
import 'package:reminder_app/features/reminders/domain/app_settings.dart';
import 'package:reminder_app/features/reminders/domain/attention_policy.dart';
import 'package:reminder_app/features/reminders/domain/item.dart';
import 'package:reminder_app/features/reminders/domain/item_pack.dart';
import 'package:reminder_app/features/reminders/domain/remote_pack_freshness.dart';
import 'package:reminder_app/features/reminders/domain/shared_pack.dart';
import 'package:reminder_app/features/reminders/presentation/formatters/reminder_formatters.dart';
import 'package:reminder_app/features/reminders/presentation/text/reminder_ui_text.dart';
import 'package:reminder_app/features/reminders/providers/backup_providers.dart';
import 'package:reminder_app/features/reminders/providers/database_providers.dart';
import 'package:reminder_app/features/reminders/providers/developer_settings_providers.dart';
import 'package:reminder_app/features/reminders/providers/identity_providers.dart';
import 'package:reminder_app/features/reminders/providers/remote_shared_pack_providers.dart';
import 'package:reminder_app/features/reminders/providers/settings_providers.dart';
import 'package:reminder_app/features/reminders/ui/pages/feature_page.dart';

void main() {
  testWidgets('settings route opens with editor-style title', (tester) async {
    final router = GoRouter(
      initialLocation: SettingsPage.routePath,
      routes: [
        GoRoute(
          path: SettingsPage.routePath,
          name: SettingsPage.routeName,
          builder: (context, state) => const SettingsPage(),
        ),
      ],
    );
    addTearDown(router.dispose);

    await _pumpSettingsRouter(tester, router: router);

    expect(find.text(ReminderUiText.settingsTitle), findsOneWidget);
    expect(find.byKey(const Key('settings-page')), findsOneWidget);
  });

  testWidgets('feature page settings entry navigates to settings', (
    tester,
  ) async {
    final router = GoRouter(
      initialLocation: FeaturePage.routePath,
      routes: [
        GoRoute(
          path: FeaturePage.routePath,
          name: FeaturePage.routeName,
          builder: (context, state) => const FeaturePage(),
        ),
        GoRoute(
          path: SettingsPage.routePath,
          name: SettingsPage.routeName,
          builder: (context, state) => const SettingsPage(),
        ),
      ],
    );
    addTearDown(router.dispose);

    await _pumpSettingsRouter(tester, router: router);

    await tester.scrollUntilVisible(
      find.byKey(const Key('feature-entry-settings')),
      240,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text(ReminderUiText.settingsTitle).last);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('settings-page')), findsOneWidget);
    expect(
      find.text(ReminderUiText.settingsGeneralSectionTitle),
      findsOneWidget,
    );
  });

  testWidgets('general section shows reminder tone and time only', (
    tester,
  ) async {
    await _pumpSettings(tester, developerVisible: false);

    expect(
      find.text(ReminderUiText.settingsGeneralSectionTitle),
      findsOneWidget,
    );
    expect(find.text(ReminderUiText.reminderToneSettingLabel), findsOneWidget);
    expect(
      find.text(ReminderUiText.notificationReminderTimeLabel),
      findsOneWidget,
    );
    expect(
      find.text(ReminderUiText.showSystemStageTrackerSetting),
      findsNothing,
    );
    expect(
      find.byKey(const Key('settings-show-system-tracker-row')),
      findsNothing,
    );
    expect(
      find.text(ReminderFormatters.reminderTone(ReminderTone.standard)),
      findsOneWidget,
    );
    expect(find.text(ReminderUiText.previewDateSettingLabel), findsNothing);
    expect(find.text('外觀密度'), findsNothing);
  });

  testWidgets('normal settings show data management actions', (tester) async {
    await _pumpSettings(tester, developerVisible: false);

    expect(find.text(ReminderUiText.settingsDataSectionTitle), findsOneWidget);
    expect(find.text(ReminderUiText.accountProtectionTitle), findsOneWidget);
    expect(
      find.text(ReminderUiText.accountProtectionLocalOnly),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('settings-account-protection-action-row')),
      findsOneWidget,
    );
    expect(find.text(ReminderUiText.backupDataLabel), findsOneWidget);
    expect(find.text(ReminderUiText.importDataLabel), findsOneWidget);
    expect(find.text(ReminderUiText.backupDataDescription), findsOneWidget);
    expect(find.text(ReminderUiText.importDataDescription), findsOneWidget);
    expect(find.text(ReminderUiText.resetUserDataLabel), findsOneWidget);
    expect(find.byKey(const Key('settings-backup-data-row')), findsOneWidget);
    expect(find.byKey(const Key('settings-import-data-row')), findsOneWidget);
    expect(
      find.byKey(const Key('settings-reset-user-data-row')),
      findsOneWidget,
    );
  });

  testWidgets('import action shows overwrite confirmation', (tester) async {
    await _pumpSettings(tester, developerVisible: false);

    await _tapSettingsRow(tester, const Key('settings-import-data-row'));

    expect(find.text(ReminderUiText.importConfirmTitle), findsOneWidget);
    expect(find.text(ReminderUiText.importConfirmMessage), findsOneWidget);
    expect(find.textContaining('不會自動恢復遠端共同 Pack 存取權'), findsOneWidget);
  });

  testWidgets('account protection shows anonymous warning', (tester) async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final fakeAuth = FakeAuthRepository();
    final remote = await fakeAuth.signInAnonymously();
    await IdentityRepository(db.reminderDao).linkRemoteIdentity(
      remoteUserId: remote.remoteUserId,
      provider: AuthProviderType.supabaseAnonymous,
    );

    await _pumpSettings(
      tester,
      developerVisible: false,
      database: db,
      extraOverrides: [authRepositoryProvider.overrideWithValue(fakeAuth)],
    );

    expect(
      find.text(ReminderUiText.accountProtectionAnonymous),
      findsOneWidget,
    );
    expect(
      find.text(ReminderUiText.accountRecoveryBindingRequired),
      findsOneWidget,
    );
    expect(
      find.text(ReminderUiText.identityKindAnonymousRemote),
      findsOneWidget,
    );
  });

  testWidgets('account protection shows linked protected status', (
    tester,
  ) async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final fakeAuth = FakeAuthRepository();
    final remote = await fakeAuth.linkWithGoogle();
    await IdentityRepository(db.reminderDao).linkRemoteIdentity(
      remoteUserId: remote.remoteUserId,
      provider: AuthProviderType.google,
    );

    await _pumpSettings(
      tester,
      developerVisible: false,
      database: db,
      extraOverrides: [authRepositoryProvider.overrideWithValue(fakeAuth)],
    );

    expect(find.text(ReminderUiText.accountProtectionLinked), findsOneWidget);
    expect(find.text(ReminderUiText.identityBoundLabel), findsWidgets);
    expect(find.text(ReminderUiText.accountRecoveryAction), findsOneWidget);
    expect(find.text(ReminderUiText.accountRecoveryAvailable), findsOneWidget);
  });

  testWidgets('account binding placeholder returns unsupported safely', (
    tester,
  ) async {
    await _pumpSettings(tester, developerVisible: false);

    await tester.tap(
      find.byKey(const Key('settings-account-protection-action-row')),
    );
    await tester.pumpAndSettle();
    expect(
      find.text(ReminderUiText.accountProtectionSheetTitle),
      findsOneWidget,
    );
    expect(
      find.text(ReminderUiText.accountProtectionProviderPlanned),
      findsWidgets,
    );
    expect(find.text(ReminderUiText.emailBindingAvailable), findsOneWidget);

    await tester.tap(find.byKey(const Key('settings-account-binding-apple')));
    await tester.pumpAndSettle();

    expect(
      find.text(ReminderUiText.accountBindingUnsupportedMessage),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('email account binding uses code flow and marks protected', (
    tester,
  ) async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final fakeAuth = FakeAuthRepository();
    final remote = await fakeAuth.signInAnonymously();
    await IdentityRepository(db.reminderDao).linkRemoteIdentity(
      remoteUserId: remote.remoteUserId,
      provider: AuthProviderType.supabaseAnonymous,
    );

    await _pumpSettings(
      tester,
      developerVisible: false,
      database: db,
      extraOverrides: [authRepositoryProvider.overrideWithValue(fakeAuth)],
    );

    await tester.tap(
      find.byKey(const Key('settings-account-protection-action-row')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('settings-account-binding-email')));
    await tester.pumpAndSettle();

    expect(find.text(ReminderUiText.emailBindingSheetTitle), findsOneWidget);
    await tester.enterText(
      find.byKey(const Key('settings-email-binding-email-field')),
      'USER@example.COM',
    );
    await tester.tap(find.byKey(const Key('settings-email-binding-send-code')));
    await tester.pumpAndSettle();

    expect(
      find.text(ReminderUiText.emailBindingCodeSentMessage),
      findsOneWidget,
    );
    await tester.enterText(
      find.byKey(const Key('settings-email-binding-code-field')),
      '123456',
    );
    await tester.tap(
      find.byKey(const Key('settings-email-binding-confirm-code')),
    );
    await tester.pumpAndSettle();

    expect(
      find.text(
        '${ReminderUiText.emailBindingSuccessTitle}。${ReminderUiText.emailBindingSuccessMessage}',
      ),
      findsOneWidget,
    );
    expect(
      find.text(ReminderUiText.emailBindingRecoveryMessage),
      findsOneWidget,
    );
    expect(find.textContaining(remote.remoteUserId), findsNothing);
    final updated = await IdentityRepository(
      db.reminderDao,
    ).getCurrentAppUser();
    expect(updated.identityKind, LocalUserIdentityKind.linked);
    expect(updated.remoteProvider, AuthProviderType.email);
  });

  testWidgets('reset action requires RESET before confirm', (tester) async {
    await _pumpSettings(tester, developerVisible: false);

    await _tapSettingsRow(tester, const Key('settings-reset-user-data-row'));

    expect(find.text(ReminderUiText.resetConfirmTitle), findsOneWidget);
    expect(
      find.byKey(const Key('settings-reset-confirm-button')),
      findsOneWidget,
    );
    expect(
      tester
          .widget<FilledButton>(
            find.byKey(const Key('settings-reset-confirm-button')),
          )
          .enabled,
      isFalse,
    );

    await tester.enterText(
      find.byKey(const Key('settings-reset-confirm-field')),
      ReminderUiText.resetDatabaseConfirmWord,
    );
    await tester.pumpAndSettle();

    expect(
      tester
          .widget<FilledButton>(
            find.byKey(const Key('settings-reset-confirm-button')),
          )
          .enabled,
      isTrue,
    );
  });

  testWidgets('backup action shows success snackbar', (tester) async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final service = _FakeBackupService(db);
    await _pumpSettings(
      tester,
      developerVisible: false,
      backupService: service,
      database: db,
    );

    await tester.tap(find.byKey(const Key('settings-backup-data-row')));
    await tester.pumpAndSettle();

    expect(service.backupCalls, 1);
    expect(find.text(ReminderUiText.backupSuccessMessage), findsOneWidget);
  });

  testWidgets('reminder tone picker updates persisted setting', (tester) async {
    final db = await _pumpSettings(tester, developerVisible: false);

    await tester.tap(find.byKey(const Key('settings-reminder-tone-row')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('settings-tone-option-early')));
    await tester.pumpAndSettle();

    final settings = await db.reminderDao.getAppSettings();
    expect(settings.reminderTone, ReminderTone.early);
  });

  testWidgets('reminder time row opens time picker', (tester) async {
    await _pumpSettings(tester, developerVisible: false);

    await tester.tap(find.byKey(const Key('settings-reminder-time-row')));
    await tester.pumpAndSettle();

    expect(find.byType(TimePickerDialog), findsOneWidget);
  });

  testWidgets('developer tools are visible when flag is enabled', (
    tester,
  ) async {
    await _pumpSettings(tester, developerVisible: true);

    expect(
      find.text(
        ReminderUiText.settingsDeveloperSectionTitle,
        skipOffstage: false,
      ),
      findsOneWidget,
    );
    expect(
      find.text(ReminderUiText.previewDateSettingLabel, skipOffstage: false),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('settings-reset-database-row'), skipOffstage: false),
      findsOneWidget,
    );
  });

  testWidgets('developer tools are hidden when flag is disabled', (
    tester,
  ) async {
    await _pumpSettings(tester, developerVisible: false);

    expect(
      find.text(ReminderUiText.settingsDeveloperSectionTitle),
      findsNothing,
    );
    expect(find.text(ReminderUiText.previewDateSettingLabel), findsNothing);
    expect(find.byKey(const Key('settings-reset-database-row')), findsNothing);
    expect(
      find.byKey(const Key('settings-remote-poc-create-pack-row')),
      findsNothing,
    );
    expect(
      find.byKey(const Key('settings-remote-backed-flush-outbox-row')),
      findsNothing,
    );
    expect(
      find.byKey(const Key('settings-remote-recovery-restore-memberships-row')),
      findsNothing,
    );
    expect(
      find.byKey(const Key('settings-remote-freshness-refresh-row')),
      findsNothing,
    );
  });

  testWidgets('preview date row opens date picker', (tester) async {
    await _pumpSettings(tester, developerVisible: true);

    await _tapSettingsRow(tester, const Key('settings-preview-date-row'));

    expect(find.byType(DatePickerDialog), findsOneWidget);
  });

  testWidgets('preview date can be updated and cleared', (tester) async {
    await _pumpSettings(
      tester,
      developerVisible: true,
      pickDate: (context, initialDate) async => DateTime(2026, 6, 2, 14),
    );

    await _tapSettingsRow(tester, const Key('settings-preview-date-row'));

    expect(find.text('2026/06/02'), findsOneWidget);
    expect(find.text(ReminderUiText.dateSourcePreview), findsWidgets);

    await tester.scrollUntilVisible(
      find.byKey(const Key('reset-preview-date-button')).first,
      120,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('reset-preview-date-button')).first);
    await tester.pumpAndSettle();

    expect(find.text('2026/05/28'), findsOneWidget);
    expect(find.text(ReminderUiText.dateSourceRealToday), findsOneWidget);
  });

  testWidgets(
    'developer debug info and unavailable reset are compact and safe',
    (tester) async {
      await _pumpSettings(tester, developerVisible: true);

      expect(find.text(ReminderUiText.debugInfoSectionTitle), findsOneWidget);
      expect(find.text(ReminderUiText.databaseVersionLabel), findsOneWidget);
      expect(find.text('10'), findsOneWidget);
      expect(
        find.byKey(const Key('settings-debug-device-data-label')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('settings-debug-identity-kind')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('settings-debug-remote-provider')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('settings-debug-remote-user-id')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('settings-debug-supabase-config-status')),
        findsOneWidget,
      );
      expect(find.text(ReminderUiText.supabaseConfigMissing), findsOneWidget);
      expect(find.text(ReminderUiText.seedDemoDataLabel), findsNothing);
      expect(
        find.byKey(const Key('settings-reset-database-row')),
        findsOneWidget,
      );
      expect(
        find.text(ReminderUiText.resetDatabaseUnavailable),
        findsOneWidget,
      );

      final resetText = tester.widget<Text>(
        find.descendant(
          of: find.byKey(const Key('settings-reset-database-row')),
          matching: find.text(ReminderUiText.resetDatabaseLabel),
        ),
      );
      expect(resetText.style?.color, ReminderTheme.light().colorScheme.error);

      await tester.tap(
        find.byKey(const Key('settings-reset-database-row')),
        warnIfMissed: false,
      );
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('developer anonymous identity button handles missing config', (
    tester,
  ) async {
    await _pumpSettings(tester, developerVisible: true);

    await tester.scrollUntilVisible(
      find
          .byKey(const Key('settings-create-anonymous-remote-identity-row'))
          .first,
      120,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find
          .byKey(const Key('settings-create-anonymous-remote-identity-row'))
          .first,
    );
    await tester.pumpAndSettle();

    expect(
      find.text(ReminderUiText.supabaseConfigMissingMessage),
      findsWidgets,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'developer anonymous identity button links fake remote identity',
    (tester) async {
      await _pumpSettings(
        tester,
        developerVisible: true,
        extraOverrides: [
          authRepositoryProvider.overrideWithValue(FakeAuthRepository()),
        ],
      );

      await tester.scrollUntilVisible(
        find
            .byKey(const Key('settings-create-anonymous-remote-identity-row'))
            .first,
        120,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find
            .byKey(const Key('settings-create-anonymous-remote-identity-row'))
            .first,
      );
      await tester.pumpAndSettle();

      expect(
        find.text(ReminderUiText.anonymousRemoteIdentityCreatedMessage),
        findsWidgets,
      );
      expect(
        find.text(ReminderUiText.identityKindAnonymousRemote),
        findsWidgets,
      );
      expect(
        find.text(ReminderUiText.remoteProviderSupabaseAnonymous),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'developer remote POC shows missing shared pack and fails gently',
    (tester) async {
      final fakeRemote = _FakeRemoteSharedPackDataSource();
      await _pumpSettings(
        tester,
        developerVisible: true,
        extraOverrides: [
          authRepositoryProvider.overrideWithValue(FakeAuthRepository()),
          remoteSharedPackDataSourceProvider.overrideWithValue(fakeRemote),
        ],
      );

      expect(
        find.text(ReminderUiText.supabaseRemotePocSectionTitle),
        findsOneWidget,
      );
      expect(find.text(ReminderUiText.remotePocNoSharedPack), findsOneWidget);
      expect(fakeRemote.createdPackCalls, 0);
      expect(fakeRemote.createdItemCalls, 0);
      expect(fakeRemote.snapshotCalls, 0);

      await tester.scrollUntilVisible(
        find.byKey(const Key('settings-remote-poc-create-pack-row')).first,
        120,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const Key('settings-remote-poc-create-pack-row')).first,
      );
      await tester.pumpAndSettle();

      expect(find.text('請先建立 / 選擇 local shared pack'), findsWidgets);
      expect(fakeRemote.createdPackCalls, 0);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('developer remote POC displays first shared pack mapping', (
    tester,
  ) async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final seed = await _seedSharedPackForRemotePoc(db);
    await db.reminderDao.upsertSyncMapping(
      SyncMappingsCompanion.insert(
        localEntityType: RemoteSharedPackRepository.localEntityPack,
        localEntityId: seed.packId,
        remoteTable: RemoteSharedPackRepository.remoteTablePacks,
        remoteEntityId: 'remote1',
        syncState: SyncMappingState.pushed.name,
        lastPushedAt: Value(DateTime(2026, 6, 21).millisecondsSinceEpoch),
        createdAt: DateTime(2026, 6, 21).millisecondsSinceEpoch,
        updatedAt: DateTime(2026, 6, 21).millisecondsSinceEpoch,
      ),
    );

    await _pumpSettings(tester, developerVisible: true, database: db);

    expect(find.textContaining('POC Pack'), findsWidgets);
    expect(find.text('remote1'), findsWidgets);
    expect(find.text(ReminderUiText.remotePocViewerNoSnapshot), findsOneWidget);
  });

  testWidgets('developer remote realtime shows no target and fails gently', (
    tester,
  ) async {
    final fakeRemote = _FakeRemoteSharedPackDataSource();
    final fakeRealtime = _FakeRemoteSharedPackRealtimeDataSource();

    await _pumpSettings(
      tester,
      developerVisible: true,
      extraOverrides: [
        authRepositoryProvider.overrideWithValue(FakeAuthRepository()),
        remoteSharedPackDataSourceProvider.overrideWithValue(fakeRemote),
        remoteSharedPackRealtimeDataSourceProvider.overrideWithValue(
          fakeRealtime,
        ),
      ],
    );

    expect(
      find.text(ReminderUiText.remotePocRealtimeSectionTitle),
      findsWidgets,
    );
    expect(find.text(ReminderUiText.remotePocRealtimeNoTarget), findsWidgets);

    await _tapSettingsRow(
      tester,
      const Key('settings-remote-realtime-subscribe-row'),
    );

    expect(fakeRealtime.subscribeCalls, 0);
    expect(find.text('尚未有可監聽的遠端 Pack'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('developer remote POC actions run through fake remote source', (
    tester,
  ) async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final seed = await _seedSharedPackForRemotePoc(db);
    final fakeRemote = _FakeRemoteSharedPackDataSource();

    await _pumpSettings(
      tester,
      developerVisible: true,
      database: db,
      extraOverrides: [
        authRepositoryProvider.overrideWithValue(FakeAuthRepository()),
        remoteSharedPackDataSourceProvider.overrideWithValue(fakeRemote),
      ],
    );

    expect(fakeRemote.profileCalls, 0);
    expect(fakeRemote.createdPackCalls, 0);
    expect(fakeRemote.createdItemCalls, 0);
    expect(fakeRemote.snapshotCalls, 0);

    await _tapSettingsRow(
      tester,
      const Key('settings-remote-poc-create-profile-row'),
    );
    expect(fakeRemote.profileCalls, 1);
    expect(find.textContaining('Remote Profile 已確認'), findsWidgets);

    await _tapSettingsRow(
      tester,
      const Key('settings-remote-poc-create-pack-row'),
    );
    expect(fakeRemote.createdPackCalls, 1);
    expect(find.textContaining('已建立遠端 Pack'), findsWidgets);

    await _tapSettingsRow(
      tester,
      const Key('settings-remote-poc-push-items-row'),
    );
    expect(fakeRemote.createdItemCalls, 1);
    expect(find.textContaining('已推送 1 個 items'), findsWidgets);

    await _tapSettingsRow(
      tester,
      const Key('settings-remote-poc-complete-item-row'),
    );
    expect(fakeRemote.completionCalls, 1);
    expect(find.text('遠端 Item 已完成'), findsWidgets);
    expect(await db.reminderDao.listItemCompletions(seed.itemId), isEmpty);

    await _tapSettingsRow(
      tester,
      const Key('settings-remote-poc-complete-item-row'),
    );
    expect(fakeRemote.completionCalls, 2);
    expect(find.text('遠端 Item 已經完成，不覆寫完成者'), findsWidgets);
    expect(await db.reminderDao.listItemCompletions(seed.itemId), isEmpty);

    await _tapSettingsRow(
      tester,
      const Key('settings-remote-poc-pull-snapshot-row'),
    );
    expect(fakeRemote.snapshotCalls, 1);
    expect(
      find.text('members 2, items 2, completions 1, events 3'),
      findsWidgets,
    );
    expect(find.text('Remote POC Pack'), findsWidgets);
    expect(find.textContaining('Host Device'), findsWidgets);
    expect(find.textContaining('Remote POC Item'), findsWidgets);
    expect(find.textContaining('completed by'), findsWidgets);
    expect(find.textContaining('pack_created'), findsWidgets);
    expect(
      find.text(ReminderUiText.remotePocViewerNoSelectedItem),
      findsOneWidget,
    );

    await _tapSettingsRow(
      tester,
      const Key('settings-remote-freshness-refresh-row'),
    );
    expect(fakeRemote.freshnessCalls, 1);
    expect(
      find.textContaining('Member freshness：members 2, up-to-date 1'),
      findsWidgets,
    );

    await _tapSettingsRow(
      tester,
      const Key('settings-remote-freshness-report-row'),
    );
    expect(fakeRemote.reportCalls, 1);
    expect(fakeRemote.reportedActivityIds, ['event3']);
    expect(find.text('已回報我已取得此 Pack 資料'), findsWidgets);

    await _tapSettingsRow(
      tester,
      const Key('settings-remote-snapshot-select-ritem1'),
    );
    expect(
      find.textContaining(ReminderUiText.remotePocViewerSelectedIndicator),
      findsWidgets,
    );

    await _tapSettingsRow(
      tester,
      const Key('settings-remote-snapshot-complete-selected-button'),
    );
    expect(fakeRemote.completionCalls, 3);
    expect(find.textContaining('Remote Item 已經完成'), findsWidgets);
    expect(await db.reminderDao.listItemCompletions(seed.itemId), isEmpty);

    await _tapSettingsRow(
      tester,
      const Key('settings-remote-snapshot-undo-selected-button'),
    );
    expect(fakeRemote.undoCalls, 1);
    expect(find.textContaining('已復原選擇的 Remote Item'), findsWidgets);
    expect(await db.reminderDao.listItemCompletions(seed.itemId), isEmpty);

    await _tapSettingsRow(
      tester,
      const Key('settings-remote-poc-pull-snapshot-row'),
    );
    expect(fakeRemote.snapshotCalls, 2);
    expect(
      find.textContaining(ReminderUiText.remotePocViewerSelectedItemLabel),
      findsWidgets,
    );
    expect(
      find.textContaining(ReminderUiText.remotePocViewerIncomplete),
      findsWidgets,
    );
    expect(find.textContaining('item_undone'), findsWidgets);
  });

  testWidgets('developer remote POC shows safe RPC detail on RLS failure', (
    tester,
  ) async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    await _seedSharedPackForRemotePoc(db);
    final fakeRemote = _FakeRemoteSharedPackDataSource()
      ..rejectCreateSharedPack = true;

    await _pumpSettings(
      tester,
      developerVisible: true,
      database: db,
      extraOverrides: [
        authRepositoryProvider.overrideWithValue(FakeAuthRepository()),
        remoteSharedPackDataSourceProvider.overrideWithValue(fakeRemote),
      ],
    );

    await _tapSettingsRow(
      tester,
      const Key('settings-remote-poc-create-pack-row'),
    );

    expect(fakeRemote.createdPackCalls, 1);
    expect(find.text('create_shared_pack 被 Supabase 拒絕：42501'), findsWidgets);
  });

  testWidgets(
    'developer remote realtime signal is advisory until manual refresh',
    (tester) async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);
      final seed = await _seedSharedPackForRemotePoc(db);
      final fakeRemote = _FakeRemoteSharedPackDataSource();
      final fakeRealtime = _FakeRemoteSharedPackRealtimeDataSource();

      await _pumpSettings(
        tester,
        developerVisible: true,
        database: db,
        extraOverrides: [
          authRepositoryProvider.overrideWithValue(FakeAuthRepository()),
          remoteSharedPackDataSourceProvider.overrideWithValue(fakeRemote),
          remoteSharedPackRealtimeDataSourceProvider.overrideWithValue(
            fakeRealtime,
          ),
        ],
      );

      await _tapSettingsRow(
        tester,
        const Key('settings-remote-poc-create-pack-row'),
      );
      await _tapSettingsRow(
        tester,
        const Key('settings-remote-poc-push-items-row'),
      );
      await _tapSettingsRow(
        tester,
        const Key('settings-remote-poc-pull-snapshot-row'),
      );
      expect(fakeRemote.snapshotCalls, 1);
      expect(fakeRealtime.subscribeCalls, 0);

      await _tapSettingsRow(
        tester,
        const Key('settings-remote-realtime-subscribe-row'),
      );
      expect(fakeRealtime.subscribeCalls, 1);
      expect(find.text('已訂閱'), findsWidgets);

      await _tapSettingsRow(
        tester,
        const Key('settings-remote-realtime-subscribe-row'),
      );
      expect(fakeRealtime.subscribeCalls, 1);
      expect(find.text('已在監聽此遠端 Pack'), findsWidgets);

      fakeRealtime.emit(
        RemotePackChangeSignal(
          remotePackId: 'rpack1',
          activityEventId: 'event-realtime-1',
          action: 'item_completed',
          entityType: 'item',
          actorUserId: 'profile2',
          receivedAt: DateTime(2026, 6, 21, 10),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.text(ReminderUiText.remotePocRealtimeChangeBanner),
        findsWidgets,
      );
      expect(find.text('item_completed'), findsWidgets);
      expect(find.text('1'), findsWidgets);
      expect(fakeRemote.snapshotCalls, 1);
      expect(await db.reminderDao.listItemCompletions(seed.itemId), isEmpty);

      await _tapSettingsRow(
        tester,
        const Key('settings-remote-poc-pull-snapshot-row'),
      );

      expect(fakeRemote.snapshotCalls, 2);
      expect(
        find.text(ReminderUiText.remotePocRealtimeChangeBanner),
        findsNothing,
      );
      expect(find.text('0'), findsWidgets);
      expect(await db.reminderDao.listItemCompletions(seed.itemId), isEmpty);
    },
  );

  testWidgets('developer remote realtime error clears active subscription', (
    tester,
  ) async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    await _seedSharedPackForRemotePoc(db);
    final fakeRemote = _FakeRemoteSharedPackDataSource();
    final fakeRealtime = _FakeRemoteSharedPackRealtimeDataSource();

    await _pumpSettings(
      tester,
      developerVisible: true,
      database: db,
      extraOverrides: [
        authRepositoryProvider.overrideWithValue(FakeAuthRepository()),
        remoteSharedPackDataSourceProvider.overrideWithValue(fakeRemote),
        remoteSharedPackRealtimeDataSourceProvider.overrideWithValue(
          fakeRealtime,
        ),
      ],
    );

    await _tapSettingsRow(
      tester,
      const Key('settings-remote-poc-create-pack-row'),
    );
    await _tapSettingsRow(
      tester,
      const Key('settings-remote-realtime-subscribe-row'),
    );
    expect(fakeRealtime.subscribeCalls, 1);
    expect(find.text('已訂閱'), findsWidgets);

    fakeRealtime.emitError(
      const RemoteSharedPackException(
        RemoteSharedPackFailureReason.remoteNetworkFailed,
      ),
    );
    await tester.pumpAndSettle();

    expect(fakeRealtime.unsubscribeCalls, 1);
    expect(find.text('錯誤'), findsWidgets);
    expect(find.text('網絡連線失敗'), findsWidgets);
    expect(find.text(ReminderUiText.remotePocRealtimeNoTarget), findsWidgets);
    expect(fakeRemote.snapshotCalls, 0);
  });

  testWidgets('developer remote realtime retargets and disposes subscription', (
    tester,
  ) async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    await _seedSharedPackForRemotePoc(db);
    final fakeRemote = _FakeRemoteSharedPackDataSource();
    final fakeRealtime = _FakeRemoteSharedPackRealtimeDataSource();

    await _pumpSettings(
      tester,
      developerVisible: true,
      database: db,
      extraOverrides: [
        authRepositoryProvider.overrideWithValue(FakeAuthRepository()),
        remoteSharedPackDataSourceProvider.overrideWithValue(fakeRemote),
        remoteSharedPackRealtimeDataSourceProvider.overrideWithValue(
          fakeRealtime,
        ),
      ],
    );

    await _tapSettingsRow(
      tester,
      const Key('settings-remote-poc-create-pack-row'),
    );
    await _tapSettingsRow(
      tester,
      const Key('settings-remote-realtime-subscribe-row'),
    );
    expect(fakeRealtime.subscribeCalls, 1);

    await tester.scrollUntilVisible(
      find.byKey(const Key('settings-remote-poc-invite-input')),
      120,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.enterText(
      find.byKey(const Key('settings-remote-poc-invite-input')),
      'K7M4Q9',
    );
    await tester.pumpAndSettle();
    await _tapSettingsRow(
      tester,
      const Key('settings-remote-poc-join-invite-row'),
    );
    await _tapSettingsRow(
      tester,
      const Key('settings-remote-realtime-subscribe-row'),
    );

    expect(fakeRealtime.subscribeCalls, 2);
    expect(fakeRealtime.unsubscribeCalls, 1);
    expect(find.textContaining('joined'), findsWidgets);

    await _tapSettingsRow(
      tester,
      const Key('settings-remote-realtime-unsubscribe-row'),
    );
    expect(fakeRealtime.unsubscribeCalls, 2);
    expect(find.text('未啟用'), findsWidgets);

    await _tapSettingsRow(
      tester,
      const Key('settings-remote-realtime-subscribe-row'),
    );
    expect(fakeRealtime.subscribeCalls, 3);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();

    expect(fakeRealtime.unsubscribeCalls, 3);
  });

  testWidgets('developer remote POC invite flow stays volatile', (
    tester,
  ) async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final seed = await _seedSharedPackForRemotePoc(db);
    final fakeRemote = _FakeRemoteSharedPackDataSource();

    await _pumpSettings(
      tester,
      developerVisible: true,
      database: db,
      extraOverrides: [
        authRepositoryProvider.overrideWithValue(FakeAuthRepository()),
        remoteSharedPackDataSourceProvider.overrideWithValue(fakeRemote),
      ],
    );

    await _tapSettingsRow(
      tester,
      const Key('settings-remote-poc-create-invite-row'),
    );
    expect(find.text('請先建立遠端 Pack'), findsWidgets);
    expect(fakeRemote.createdInviteCalls, 0);

    await _tapSettingsRow(
      tester,
      const Key('settings-remote-poc-create-pack-row'),
    );
    await _tapSettingsRow(
      tester,
      const Key('settings-remote-poc-create-invite-row'),
    );
    expect(fakeRemote.createdInviteCalls, 1);
    expect(find.textContaining('K7M4Q9'), findsWidgets);
    expect(find.text('10'), findsWidgets);

    await _tapSettingsRow(
      tester,
      const Key('settings-remote-poc-join-invite-row'),
    );
    expect(find.text('請輸入 Invite Code'), findsWidgets);

    await tester.scrollUntilVisible(
      find.byKey(const Key('settings-remote-poc-invite-input')),
      120,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.enterText(
      find.byKey(const Key('settings-remote-poc-invite-input')),
      'K7M4Q9',
    );
    await tester.pumpAndSettle();
    await _tapSettingsRow(
      tester,
      const Key('settings-remote-poc-join-invite-row'),
    );
    expect(fakeRemote.joinInviteCalls, 1);
    expect(find.textContaining('加入遠端 Pack'), findsWidgets);

    await _tapSettingsRow(
      tester,
      const Key('settings-remote-poc-pull-snapshot-row'),
    );
    expect(fakeRemote.snapshotCalls, 1);
    expect(find.text('Remote POC Item'), findsWidgets);
    expect(find.textContaining('joined remote pack'), findsWidgets);

    await _tapSettingsRow(
      tester,
      const Key('settings-remote-snapshot-select-snapshot-extra-item'),
    );
    await _tapSettingsRow(
      tester,
      const Key('settings-remote-snapshot-undo-selected-button'),
    );
    expect(find.text('此 Remote Item 尚未完成'), findsWidgets);
    expect(fakeRemote.undoCalls, 0);

    await _tapSettingsRow(
      tester,
      const Key('settings-remote-poc-complete-snapshot-item-row'),
    );
    expect(fakeRemote.completionCalls, 1);
    expect(find.text('Snapshot Remote Item 已完成'), findsWidgets);
    expect(await db.reminderDao.listItemCompletions(seed.itemId), isEmpty);

    final backup = await ReminderBackupService(
      db.reminderDao,
    ).exportJsonString(exportedAt: DateTime(2026, 6, 21));
    expect(backup, isNot(contains('K7M4Q9')));
  });

  testWidgets('developer remote viewer clears selection when item disappears', (
    tester,
  ) async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    await _seedSharedPackForRemotePoc(db);
    final fakeRemote = _FakeRemoteSharedPackDataSource();

    await _pumpSettings(
      tester,
      developerVisible: true,
      database: db,
      extraOverrides: [
        authRepositoryProvider.overrideWithValue(FakeAuthRepository()),
        remoteSharedPackDataSourceProvider.overrideWithValue(fakeRemote),
      ],
    );

    await _tapSettingsRow(
      tester,
      const Key('settings-remote-poc-create-pack-row'),
    );
    await _tapSettingsRow(
      tester,
      const Key('settings-remote-poc-push-items-row'),
    );
    await _tapSettingsRow(
      tester,
      const Key('settings-remote-poc-pull-snapshot-row'),
    );
    await _tapSettingsRow(
      tester,
      const Key('settings-remote-snapshot-select-ritem1'),
    );
    expect(
      find.textContaining(ReminderUiText.remotePocViewerSelectedIndicator),
      findsWidgets,
    );

    fakeRemote.hiddenItemIds.add('ritem1');
    await _tapSettingsRow(
      tester,
      const Key('settings-remote-poc-pull-snapshot-row'),
    );

    expect(
      find.text(ReminderUiText.remotePocViewerNoSelectedItem),
      findsWidgets,
    );
  });

  testWidgets('developer remote viewer refresh failure is friendly', (
    tester,
  ) async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final seed = await _seedSharedPackForRemotePoc(db);
    await db.reminderDao.upsertSyncMapping(
      SyncMappingsCompanion.insert(
        localEntityType: RemoteSharedPackRepository.localEntityPack,
        localEntityId: seed.packId,
        remoteTable: RemoteSharedPackRepository.remoteTablePacks,
        remoteEntityId: 'remote-failure-pack',
        syncState: SyncMappingState.pushed.name,
        createdAt: DateTime(2026, 6, 21).millisecondsSinceEpoch,
        updatedAt: DateTime(2026, 6, 21).millisecondsSinceEpoch,
      ),
    );
    final fakeRemote = _FakeRemoteSharedPackDataSource()..rejectSnapshot = true;

    await _pumpSettings(
      tester,
      developerVisible: true,
      database: db,
      extraOverrides: [
        authRepositoryProvider.overrideWithValue(FakeAuthRepository()),
        remoteSharedPackDataSourceProvider.overrideWithValue(fakeRemote),
      ],
    );

    await _tapSettingsRow(
      tester,
      const Key('settings-remote-poc-pull-snapshot-row'),
    );

    expect(fakeRemote.snapshotCalls, 1);
    expect(find.text('遠端資料被 RLS 拒絕'), findsWidgets);
    expect(find.textContaining('failed'), findsWidgets);
    expect(await db.reminderDao.listItemCompletions(seed.itemId), isEmpty);
  });

  testWidgets('developer combined refresh imports mapped remote pack', (
    tester,
  ) async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final seed = await _seedSharedPackForRemotePoc(db);
    await db.reminderDao.upsertSyncMapping(
      SyncMappingsCompanion.insert(
        localEntityType: RemoteSharedPackRepository.localEntityPack,
        localEntityId: seed.packId,
        remoteTable: RemoteSharedPackRepository.remoteTablePacks,
        remoteEntityId: 'remote-combined-pack',
        syncState: SyncMappingState.pushed.name,
        createdAt: DateTime(2026, 6, 21).millisecondsSinceEpoch,
        updatedAt: DateTime(2026, 6, 21).millisecondsSinceEpoch,
      ),
    );
    final fakeRemote = _FakeRemoteSharedPackDataSource();

    await _pumpSettings(
      tester,
      developerVisible: true,
      database: db,
      extraOverrides: [
        authRepositoryProvider.overrideWithValue(FakeAuthRepository()),
        remoteSharedPackDataSourceProvider.overrideWithValue(fakeRemote),
      ],
    );

    await _tapSettingsRow(
      tester,
      const Key('settings-remote-poc-refresh-import-row'),
    );

    expect(fakeRemote.snapshotCalls, 1);
    expect(fakeRemote.completionCalls, 0);
    expect(fakeRemote.undoCalls, 0);
    final metadata = await db.reminderDao.getRemotePackSyncMetadataForLocalPack(
      seed.packId,
    );
    expect(metadata, isNotNull);
    expect(metadata!.remotePackId, 'remote-combined-pack');
    expect(await db.reminderDao.listSyncOutboxEntries(), isEmpty);
  });

  testWidgets(
    'developer recovery restore row is available for protected account',
    (tester) async {
      final fakeRemote = _FakeRemoteSharedPackDataSource();
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);
      final fakeAuth = FakeAuthRepository();
      final remoteIdentity = await fakeAuth.linkWithGoogle();
      await IdentityRepository(db.reminderDao).linkRemoteIdentity(
        remoteUserId: remoteIdentity.remoteUserId,
        provider: AuthProviderType.google,
      );
      await _pumpSettings(
        tester,
        developerVisible: true,
        database: db,
        extraOverrides: [
          authRepositoryProvider.overrideWithValue(fakeAuth),
          remoteSharedPackDataSourceProvider.overrideWithValue(fakeRemote),
        ],
      );

      final recoveryRow = find.byKey(
        const Key('settings-remote-recovery-restore-memberships-row'),
        skipOffstage: false,
      );
      await tester.scrollUntilVisible(
        recoveryRow.first,
        120,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pump();

      expect(
        find.text(ReminderUiText.remoteRecoveryRestoreMembershipsLabel),
        findsOneWidget,
      );
      expect(fakeRemote.snapshotCalls, 0);
      expect(await db.reminderDao.listSyncOutboxEntries(), isEmpty);
    },
  );

  testWidgets(
    'developer settings compatibility route renders unified settings',
    (tester) async {
      final router = GoRouter(
        initialLocation: DeveloperSettingsPage.routePath,
        routes: [
          GoRoute(
            path: DeveloperSettingsPage.routePath,
            name: DeveloperSettingsPage.routeName,
            builder: (context, state) => const DeveloperSettingsPage(),
          ),
        ],
      );
      addTearDown(router.dispose);

      await _pumpSettingsRouter(tester, router: router, developerVisible: true);

      expect(find.text(ReminderUiText.settingsTitle), findsOneWidget);
      expect(
        find.text(ReminderUiText.settingsGeneralSectionTitle),
        findsOneWidget,
      );
      expect(
        find.text(
          ReminderUiText.settingsDeveloperSectionTitle,
          skipOffstage: false,
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets('settings page fits iPhone 15 width', (tester) async {
    final view = tester.view;
    view.physicalSize = const Size(393, 852);
    view.devicePixelRatio = 1;
    addTearDown(() {
      view.resetPhysicalSize();
      view.resetDevicePixelRatio();
    });

    await _pumpSettings(tester, developerVisible: true);

    expect(tester.takeException(), isNull);
    expect(find.byKey(const Key('settings-page')), findsOneWidget);
  });
}

Future<AppDatabase> _pumpSettings(
  WidgetTester tester, {
  required bool developerVisible,
  PreviewDatePicker? pickDate,
  ReminderBackupService? backupService,
  AppDatabase? database,
  List<Override> extraOverrides = const [],
}) async {
  final db = database ?? AppDatabase.forTesting(NativeDatabase.memory());
  if (database == null) {
    addTearDown(db.close);
  }

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        appSettingsProvider.overrideWith((ref) => Stream.value(_appSettings())),
        if (backupService != null)
          reminderBackupServiceProvider.overrideWith((ref) => backupService),
        developerSettingsVisibleProvider.overrideWith(
          (ref) => developerVisible,
        ),
        systemPreviewDateProvider.overrideWith(
          (ref) => Stream.value(DateTime(2026, 5, 28)),
        ),
        ...extraOverrides,
      ],
      child: MaterialApp(
        theme: ReminderTheme.light(),
        home: SettingsPage(pickDate: pickDate),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return db;
}

Future<void> _tapSettingsRow(WidgetTester tester, Key key) async {
  final rowFinder = find.byKey(key, skipOffstage: false).first;
  await tester.scrollUntilVisible(
    rowFinder,
    120,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(key).first);
  await tester.pumpAndSettle();
}

class _RemotePocSeed {
  const _RemotePocSeed({required this.packId, required this.itemId});

  final int packId;
  final int itemId;
}

Future<_RemotePocSeed> _seedSharedPackForRemotePoc(AppDatabase db) async {
  final localUser = await IdentityRepository(
    db.reminderDao,
  ).ensureLocalIdentity();
  final itemRepository = ItemRepository(db.reminderDao);
  final packId = await itemRepository.createPack(
    const ItemPackInput(title: 'POC Pack'),
  );
  await SharedPackRepository(
    db.reminderDao,
  ).convertPackToShared(packId, hostUserId: localUser.id);
  final itemId = await itemRepository.createItem(
    ItemInput(
      title: 'POC Item',
      type: ItemType.stateBased,
      config: const StateBasedItemConfig(
        warningAfter: Duration(days: 1),
        dangerAfter: Duration(days: 2),
      ),
      packId: packId,
    ),
  );
  return _RemotePocSeed(packId: packId, itemId: itemId);
}

class _FakeRemoteSharedPackDataSource implements RemoteSharedPackDataSource {
  int profileCalls = 0;
  int createdPackCalls = 0;
  int createdInviteCalls = 0;
  int joinInviteCalls = 0;
  int createdItemCalls = 0;
  int completionCalls = 0;
  int undoCalls = 0;
  int snapshotCalls = 0;
  int reportCalls = 0;
  int freshnessCalls = 0;
  bool rejectCreateSharedPack = false;
  bool rejectSnapshot = false;
  bool rejectFreshnessReport = false;
  final hiddenItemIds = <String>{};
  final reportedActivityIds = <String?>[];

  final _packItems = <String, List<String>>{};
  final _completedItems = <String, RemoteItemCompletionResult>{};
  final _undoActivityItems = <String>{};
  final _activeInvites = <String, RemotePackInvite>{};

  @override
  Future<String> upsertCurrentProfile({required String displayName}) async {
    profileCalls += 1;
    return 'profile1';
  }

  @override
  Future<String> createSharedPack({
    required String name,
    String? description,
  }) async {
    createdPackCalls += 1;
    if (rejectCreateSharedPack) {
      throw const RemoteSharedPackException(
        RemoteSharedPackFailureReason.remoteRlsRejected,
        null,
        'create_shared_pack',
        '42501',
      );
    }
    final id = 'rpack$createdPackCalls';
    _packItems[id] = <String>[];
    return id;
  }

  @override
  Future<RemotePackInvite> createPackInvite({required String packId}) async {
    return ensureActivePackInvite(packId: packId);
  }

  @override
  Future<RemotePackInviteState> fetchPackInviteState({
    required String packId,
  }) async {
    return RemotePackInviteState(activeInvite: _activeInvites[packId]);
  }

  @override
  Future<RemotePackInvite> ensureActivePackInvite({
    required String packId,
  }) async {
    final existing = _activeInvites[packId];
    if (existing != null) {
      return existing;
    }
    createdInviteCalls += 1;
    final invite = RemotePackInvite(
      inviteId: 'invite$createdInviteCalls',
      inviteCode: 'K7M4Q9',
      expiresAt: DateTime(2026, 6, 28, 10),
      maxUses: 10,
    );
    _activeInvites[packId] = invite;
    return invite;
  }

  @override
  Future<RemotePackInvite> refreshPackInvite({required String packId}) async {
    _activeInvites.remove(packId);
    createdInviteCalls += 1;
    final invite = RemotePackInvite(
      inviteId: 'invite$createdInviteCalls',
      inviteCode: 'P8W6RA',
      expiresAt: DateTime(2026, 6, 28, 10),
      maxUses: 10,
    );
    _activeInvites[packId] = invite;
    return invite;
  }

  @override
  Future<RemoteJoinPackResult> joinPackWithInvite({
    required String inviteCode,
  }) async {
    joinInviteCalls += 1;
    _packItems.putIfAbsent('joined-pack', () => <String>['joined-item']);
    return const RemoteJoinPackResult(
      status: RemoteJoinPackStatus.joined,
      remotePackId: 'joined-pack',
      memberId: 'joined-member',
      role: 'member',
    );
  }

  @override
  Future<List<RemoteRecoverablePack>> fetchActiveMembershipPacks() async {
    return [
      RemoteRecoverablePack(
        remotePackId: 'joined-pack',
        name: 'Remote POC Pack',
        role: 'member',
        memberStatus: 'active',
        packStatus: 'active',
        hostUserId: 'profile1',
        updatedAt: DateTime(2026, 6, 21),
      ),
    ];
  }

  @override
  Future<RemoteRevokeInviteResult> revokePackInvite({
    required String inviteId,
  }) async {
    return RemoteRevokeInviteResult(
      status: RemoteRevokeInviteStatus.revoked,
      inviteId: inviteId,
    );
  }

  @override
  Future<String> createPackItem({
    required String packId,
    required String title,
    String? note,
  }) async {
    createdItemCalls += 1;
    final id = 'ritem$createdItemCalls';
    _packItems.putIfAbsent(packId, () => <String>[]).add(id);
    return id;
  }

  @override
  Future<RemoteItemCreateResult> createPackItemV2({
    required String packId,
    required String title,
    String? note,
    String? clientMutationId,
  }) async {
    return RemoteItemCreateResult(
      itemId: await createPackItem(packId: packId, title: title, note: note),
    );
  }

  @override
  Future<RemoteItemMutationResult> updatePackItem({
    required String itemId,
    required String title,
    String? note,
    String? assignedToUserId,
    String? clientMutationId,
  }) async {
    return RemoteItemMutationResult(itemId: itemId, status: 'updated');
  }

  @override
  Future<RemoteItemMutationResult> archivePackItem({
    required String itemId,
    String? clientMutationId,
  }) async {
    return RemoteItemMutationResult(itemId: itemId, status: 'archived');
  }

  @override
  Future<RemoteResourceCreateResult> createPackResource({
    required String packId,
    required String title,
    String? description,
    required String type,
    Map<String, Object?>? config,
    String? clientMutationId,
  }) async {
    return const RemoteResourceCreateResult(resourceId: 'remote_resource_1');
  }

  @override
  Future<RemoteResourceMutationResult> updatePackResource({
    required String resourceId,
    required String title,
    String? description,
    Map<String, Object?>? config,
    String? clientMutationId,
  }) async {
    return RemoteResourceMutationResult(
      resourceId: resourceId,
      status: 'updated',
    );
  }

  @override
  Future<RemoteResourceMutationResult> archivePackResource({
    required String resourceId,
    String? clientMutationId,
  }) async {
    return RemoteResourceMutationResult(
      resourceId: resourceId,
      status: 'archived',
    );
  }

  @override
  Future<RemoteResourceEventResult> applyResourceEvent({
    required String resourceId,
    required String changeType,
    int? deltaValue,
    int? newValue,
    String? unit,
    String? clientMutationId,
    Map<String, Object?>? metadata,
  }) async {
    return RemoteResourceEventResult(
      resourceId: resourceId,
      eventId: 'remote_resource_event_1',
      status: 'applied',
      currentValue: newValue,
    );
  }

  @override
  Future<RemoteItemCompletionResult> completePackItem({
    required String itemId,
    String? clientMutationId,
  }) async {
    completionCalls += 1;
    final existing = _completedItems[itemId];
    if (existing != null) {
      return RemoteItemCompletionResult(
        status: RemoteItemCompletionStatus.alreadyCompleted,
        completionId: existing.completionId,
        completedByUserId: existing.completedByUserId,
        completedAt: existing.completedAt,
      );
    }
    final result = RemoteItemCompletionResult(
      status: RemoteItemCompletionStatus.completed,
      completionId: 'completion1',
      completedByUserId: 'profile1',
      completedAt: DateTime(2026, 6, 21),
    );
    _completedItems[itemId] = result;
    return result;
  }

  @override
  Future<RemoteItemUndoResult> undoPackItemCompletion({
    required String itemId,
    String? clientMutationId,
  }) async {
    undoCalls += 1;
    final existing = _completedItems.remove(itemId);
    if (existing == null) {
      return RemoteItemUndoResult(
        status: RemoteItemUndoStatus.alreadyNotCompleted,
        itemId: itemId,
      );
    }
    _undoActivityItems.add(itemId);
    return RemoteItemUndoResult(
      status: RemoteItemUndoStatus.undone,
      itemId: itemId,
      completionId: existing.completionId,
      undoneByUserId: 'profile1',
      undoneAt: DateTime(2026, 6, 21, 3),
    );
  }

  @override
  Future<RemotePackSnapshot> fetchPackSnapshot(String remotePackId) async {
    snapshotCalls += 1;
    if (rejectSnapshot) {
      throw const RemoteSharedPackException(
        RemoteSharedPackFailureReason.remoteRlsRejected,
      );
    }
    final itemIds = _packItems[remotePackId] ?? const <String>[];
    final displayItemIds = itemIds.isEmpty
        ? <String>['snapshot-item-1', 'snapshot-item-2']
        : <String>[...itemIds, 'snapshot-extra-item'];
    displayItemIds.removeWhere(hiddenItemIds.contains);
    return RemotePackSnapshot(
      id: remotePackId,
      name: 'Remote POC Pack',
      hostUserId: 'profile1',
      status: 'active',
      createdAt: DateTime(2026, 6, 21),
      updatedAt: DateTime(2026, 6, 21),
      members: [
        RemotePackMemberSnapshot(
          id: 'member1',
          packId: remotePackId,
          userId: 'profile1',
          displayName: 'Host Device',
          role: 'host',
          status: 'active',
          joinedAt: DateTime(2026, 6, 21),
        ),
        RemotePackMemberSnapshot(
          id: 'member2',
          packId: remotePackId,
          userId: 'profile2',
          role: 'member',
          status: 'active',
          joinedAt: DateTime(2026, 6, 21),
        ),
      ],
      items: [
        for (final itemId in displayItemIds)
          RemoteItemSnapshot(
            id: itemId,
            packId: remotePackId,
            title:
                itemId == 'snapshot-extra-item' || itemId == 'snapshot-item-2'
                ? 'Remote Extra Item'
                : 'Remote POC Item',
            note: itemId == 'snapshot-extra-item' || itemId == 'snapshot-item-2'
                ? 'No completion yet'
                : 'Snapshot viewer note',
            status: 'active',
            assignedToUserId: itemId == 'snapshot-extra-item'
                ? 'profile2'
                : null,
            createdByUserId: 'profile1',
            updatedByUserId: 'profile1',
            createdAt: DateTime(2026, 6, 21),
            updatedAt: DateTime(2026, 6, 21),
          ),
      ],
      completions: [
        for (final entry in _completedItems.entries)
          if (displayItemIds.contains(entry.key))
            RemoteItemCompletionSnapshot(
              id: entry.value.completionId,
              packId: remotePackId,
              itemId: entry.key,
              completedByUserId: entry.value.completedByUserId,
              completedAt: entry.value.completedAt,
              createdAt: entry.value.completedAt,
            ),
      ],
      activityEvents: [
        RemoteActivityEventSnapshot(
          id: 'event1',
          packId: remotePackId,
          actorUserId: 'profile1',
          entityType: 'pack',
          entityId: remotePackId,
          action: 'pack_created',
          createdAt: DateTime(2026, 6, 21),
        ),
        RemoteActivityEventSnapshot(
          id: 'event2',
          packId: remotePackId,
          actorUserId: 'profile1',
          actorDisplayNameSnapshot: 'Host Device',
          entityType: 'pack_invite',
          entityId: 'invite1',
          action: 'invite_created',
          createdAt: DateTime(2026, 6, 21, 1),
        ),
        RemoteActivityEventSnapshot(
          id: 'event3',
          packId: remotePackId,
          actorUserId: 'profile2',
          entityType: 'item',
          entityId: displayItemIds.first,
          action: 'item_completed',
          createdAt: DateTime(2026, 6, 21, 2),
        ),
        for (final itemId in _undoActivityItems)
          RemoteActivityEventSnapshot(
            id: 'event-undo-$itemId',
            packId: remotePackId,
            actorUserId: 'profile1',
            entityType: 'item',
            entityId: itemId,
            action: 'item_undone',
            createdAt: DateTime(2026, 6, 21, 3),
          ),
      ],
    );
  }

  @override
  Future<void> reportPackSnapshotImported({
    required String remotePackId,
    String? latestActivityEventId,
    DateTime? latestActivityAt,
  }) async {
    reportCalls += 1;
    if (rejectFreshnessReport) {
      throw const RemoteSharedPackException(
        RemoteSharedPackFailureReason.remoteRlsRejected,
      );
    }
    reportedActivityIds.add(latestActivityEventId);
  }

  @override
  Future<List<RemotePackMemberFreshness>> getPackMemberFreshness({
    required String remotePackId,
  }) async {
    freshnessCalls += 1;
    return [
      RemotePackMemberFreshness(
        remoteUserId: 'profile1',
        displayName: 'Host Device',
        role: 'host',
        memberStatus: 'active',
        status: RemotePackFreshnessStatus.upToDate,
        lastImportedAt: DateTime(2026, 6, 21, 3),
      ),
      const RemotePackMemberFreshness(
        remoteUserId: 'profile2',
        displayName: 'Member',
        role: 'member',
        memberStatus: 'active',
        status: RemotePackFreshnessStatus.noSyncReport,
      ),
    ];
  }
}

class _FakeRemoteSharedPackRealtimeDataSource
    implements RemoteSharedPackRealtimeDataSource {
  int subscribeCalls = 0;
  int unsubscribeCalls = 0;
  final subscriptions = <_FakeRemotePackChangeSubscription>[];
  void Function(RemotePackChangeSignal signal)? _onSignal;
  void Function(Object error)? _onError;

  @override
  RemotePackChangeSubscription subscribeToRemotePackChanges({
    required String remotePackId,
    required void Function(RemotePackChangeSignal signal) onSignal,
    required void Function(Object error) onError,
    required void Function() onSubscribed,
  }) {
    subscribeCalls += 1;
    _onSignal = onSignal;
    _onError = onError;
    final subscription = _FakeRemotePackChangeSubscription(
      remotePackId: remotePackId,
      onUnsubscribe: () => unsubscribeCalls += 1,
    );
    subscriptions.add(subscription);
    onSubscribed();
    return subscription;
  }

  void emit(RemotePackChangeSignal signal) {
    _onSignal?.call(signal);
  }

  void emitError(Object error) {
    _onError?.call(error);
  }
}

class _FakeRemotePackChangeSubscription
    implements RemotePackChangeSubscription {
  _FakeRemotePackChangeSubscription({
    required this.remotePackId,
    required this.onUnsubscribe,
  });

  @override
  final String remotePackId;
  final VoidCallback onUnsubscribe;
  bool _isActive = true;

  @override
  bool get isActive => _isActive;

  @override
  Future<void> unsubscribe() async {
    if (!_isActive) {
      return;
    }
    _isActive = false;
    onUnsubscribe();
  }
}

class _FakeBackupService extends ReminderBackupService {
  _FakeBackupService(AppDatabase db) : super(db.reminderDao);

  int backupCalls = 0;

  @override
  Future<File> backupAndShare({DateTime? exportedAt}) async {
    backupCalls++;
    return File('fake.json');
  }
}

Future<void> _pumpSettingsRouter(
  WidgetTester tester, {
  required GoRouter router,
  bool developerVisible = true,
}) async {
  final db = AppDatabase.forTesting(NativeDatabase.memory());
  addTearDown(db.close);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        appSettingsProvider.overrideWith((ref) => Stream.value(_appSettings())),
        developerSettingsVisibleProvider.overrideWith(
          (ref) => developerVisible,
        ),
        systemPreviewDateProvider.overrideWith(
          (ref) => Stream.value(DateTime(2026, 5, 28)),
        ),
      ],
      child: MaterialApp.router(
        theme: ReminderTheme.light(),
        routerConfig: router,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

AppSettings _appSettings({
  ReminderTone tone = ReminderTone.standard,
  String reminderTime = '09:00',
}) {
  return AppSettings(
    reminderTone: tone,
    notificationReminderTime: reminderTime,
    updatedAt: DateTime(2026, 5, 28),
  );
}
