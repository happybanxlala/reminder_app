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
      find.byKey(const Key('reset-preview-date-button')),
      120,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('reset-preview-date-button')));
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
      expect(find.text('8'), findsOneWidget);
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
      find.byKey(const Key('settings-create-anonymous-remote-identity-row')),
      120,
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const Key('settings-create-anonymous-remote-identity-row')),
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
        find.byKey(const Key('settings-create-anonymous-remote-identity-row')),
        120,
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const Key('settings-create-anonymous-remote-identity-row')),
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
        find.byKey(const Key('settings-remote-poc-create-pack-row')),
        120,
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const Key('settings-remote-poc-create-pack-row')),
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
      find.text('members 1, items 1, completions 1, events 1'),
      findsWidgets,
    );
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
  await tester.scrollUntilVisible(find.byKey(key), 120);
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(key));
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
  int createdItemCalls = 0;
  int completionCalls = 0;
  int snapshotCalls = 0;

  final _packItems = <String, List<String>>{};
  final _completedItems = <String, RemoteItemCompletionResult>{};

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
  Future<RemotePackSnapshot> fetchPackSnapshot(String remotePackId) async {
    snapshotCalls += 1;
    final itemIds = _packItems[remotePackId] ?? const <String>[];
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
          role: 'host',
          status: 'active',
          joinedAt: DateTime(2026, 6, 21),
        ),
      ],
      items: [
        for (final itemId in itemIds)
          RemoteItemSnapshot(
            id: itemId,
            packId: remotePackId,
            title: 'Remote POC Item',
            status: 'active',
            createdByUserId: 'profile1',
            updatedByUserId: 'profile1',
            createdAt: DateTime(2026, 6, 21),
            updatedAt: DateTime(2026, 6, 21),
          ),
      ],
      completions: [
        for (final entry in _completedItems.entries)
          if (itemIds.contains(entry.key))
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
      ],
    );
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
