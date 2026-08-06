import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:reminder_app/app/theme/reminder_theme.dart';
import 'package:reminder_app/features/reminders/data/local/app_database.dart';
import 'package:reminder_app/features/reminders/data/reminder_backup_service.dart';
import 'package:reminder_app/features/reminders/domain/app_settings.dart';
import 'package:reminder_app/features/reminders/domain/attention_policy.dart';
import 'package:reminder_app/features/reminders/presentation/formatters/reminder_formatters.dart';
import 'package:reminder_app/features/reminders/presentation/text/reminder_ui_text.dart';
import 'package:reminder_app/features/reminders/providers/backup_providers.dart';
import 'package:reminder_app/features/reminders/providers/database_providers.dart';
import 'package:reminder_app/features/reminders/providers/developer_settings_providers.dart';
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
      expect(find.text('6'), findsOneWidget);
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
