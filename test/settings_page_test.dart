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
    expect(find.text(ReminderUiText.backupDataLabel), findsOneWidget);
    expect(find.text(ReminderUiText.importDataLabel), findsOneWidget);
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

    await tester.tap(find.byKey(const Key('settings-import-data-row')));
    await tester.pumpAndSettle();

    expect(find.text(ReminderUiText.importConfirmTitle), findsOneWidget);
    expect(find.text(ReminderUiText.importConfirmMessage), findsOneWidget);
  });

  testWidgets('reset action requires RESET before confirm', (tester) async {
    await _pumpSettings(tester, developerVisible: false);

    await tester.tap(find.byKey(const Key('settings-reset-user-data-row')));
    await tester.pumpAndSettle();

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
      find.text(ReminderUiText.settingsDeveloperSectionTitle),
      findsOneWidget,
    );
    expect(find.text(ReminderUiText.previewDateSettingLabel), findsOneWidget);
    expect(
      find.byKey(const Key('settings-reset-database-row')),
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
  });

  testWidgets('preview date row opens date picker', (tester) async {
    await _pumpSettings(tester, developerVisible: true);

    await tester.tap(find.byKey(const Key('settings-preview-date-row')));
    await tester.pumpAndSettle();

    expect(find.byType(DatePickerDialog), findsOneWidget);
  });

  testWidgets('preview date can be updated and cleared', (tester) async {
    await _pumpSettings(
      tester,
      developerVisible: true,
      pickDate: (context, initialDate) async => DateTime(2026, 6, 2, 14),
    );

    await tester.tap(find.byKey(const Key('settings-preview-date-row')));
    await tester.pumpAndSettle();

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
      expect(find.text('9'), findsOneWidget);
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
      'ABCD-1234-EFGH',
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
    expect(find.textContaining('ABCD-1234-EFGH'), findsWidgets);
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
      'ABCD-1234-EFGH',
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
    expect(backup, isNot(contains('ABCD-1234-EFGH')));
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
        find.text(ReminderUiText.settingsDeveloperSectionTitle),
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
  await tester.scrollUntilVisible(
    find.byKey(key).first,
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
  bool rejectSnapshot = false;
  final hiddenItemIds = <String>{};

  final _packItems = <String, List<String>>{};
  final _completedItems = <String, RemoteItemCompletionResult>{};
  final _undoActivityItems = <String>{};

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
    final id = 'rpack$createdPackCalls';
    _packItems[id] = <String>[];
    return id;
  }

  @override
  Future<RemotePackInvite> createPackInvite({required String packId}) async {
    createdInviteCalls += 1;
    return RemotePackInvite(
      inviteId: 'invite$createdInviteCalls',
      inviteCode: 'ABCD-1234-EFGH',
      expiresAt: DateTime(2026, 6, 28, 10),
      maxUses: 10,
    );
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
