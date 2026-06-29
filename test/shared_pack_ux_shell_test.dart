import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reminder_app/app/theme/reminder_theme.dart';
import 'package:reminder_app/features/reminders/data/local/app_database.dart';
import 'package:reminder_app/features/reminders/domain/app_settings.dart';
import 'package:reminder_app/features/reminders/domain/attention_policy.dart';
import 'package:reminder_app/features/reminders/domain/item_pack.dart';
import 'package:reminder_app/features/reminders/presentation/text/reminder_ui_text.dart';
import 'package:reminder_app/features/reminders/providers/database_providers.dart';
import 'package:reminder_app/features/reminders/providers/developer_settings_providers.dart';
import 'package:reminder_app/features/reminders/providers/item_providers.dart';
import 'package:reminder_app/features/reminders/providers/settings_providers.dart';
import 'package:reminder_app/features/reminders/ui/pages/feature_page.dart';

void main() {
  testWidgets('pack management shows shared pack shell and personal packs', (
    tester,
  ) async {
    await _pumpPackManagement(tester);

    expect(find.byKey(const Key('shared-pack-shell-card')), findsOneWidget);
    expect(find.text(ReminderUiText.sharedPackLabel), findsOneWidget);
    expect(
      find.text(ReminderUiText.sharedPackUnavailableLabel),
      findsOneWidget,
    );
    expect(find.textContaining(ReminderUiText.personalPackLabel), findsWidgets);
    expect(find.byKey(const Key('pack-overflow-1')), findsNothing);
  });

  testWidgets('custom pack members menu opens disabled invite shell', (
    tester,
  ) async {
    await _pumpPackManagement(tester);

    await tester.tap(find.byKey(const Key('pack-overflow-2')));
    await tester.pumpAndSettle();

    expect(find.text(ReminderUiText.sharedPackMembersLabel), findsOneWidget);

    await tester.tap(find.text(ReminderUiText.sharedPackMembersLabel));
    await tester.pumpAndSettle();

    expect(find.text(ReminderUiText.sharedPackMembersShellTitle), findsWidgets);
    expect(
      find.byKey(const Key('shared-pack-member-state-card')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('shared-pack-invite-code-preview')),
      findsOneWidget,
    );
    expect(
      find.textContaining(ReminderUiText.sharedPackInviteCodePreviewValue),
      findsOneWidget,
    );
    expect(
      tester
          .widget<FilledButton>(
            find.byKey(const Key('shared-pack-invite-member-button')),
          )
          .enabled,
      isFalse,
    );
  });

  testWidgets('settings invite code entry opens disabled join shell', (
    tester,
  ) async {
    await _pumpSettings(tester);

    expect(
      find.byKey(const Key('settings-shared-pack-section')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('settings-enter-invite-code-row')),
      findsOneWidget,
    );

    await tester.scrollUntilVisible(
      find.byKey(const Key('settings-enter-invite-code-row')),
      160,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('settings-enter-invite-code-row')));
    await tester.pumpAndSettle();

    expect(find.text(ReminderUiText.sharedPackJoinShellTitle), findsWidgets);
    expect(
      find.byKey(const Key('shared-pack-invite-code-field')),
      findsOneWidget,
    );
    expect(
      tester
          .widget<TextField>(
            find.byKey(const Key('shared-pack-invite-code-field')),
          )
          .enabled,
      isFalse,
    );
    expect(
      tester
          .widget<FilledButton>(
            find.byKey(const Key('shared-pack-join-button')),
          )
          .enabled,
      isFalse,
    );
  });
}

Future<void> _pumpPackManagement(WidgetTester tester) async {
  final db = AppDatabase.forTesting(NativeDatabase.memory());
  addTearDown(db.close);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        activeItemPacksProvider.overrideWith(
          (ref) => Stream.value([_defaultPack(), _customPack()]),
        ),
      ],
      child: MaterialApp(
        theme: ReminderTheme.light(),
        home: const ItemPacksManagementPage(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _pumpSettings(WidgetTester tester) async {
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
      ],
      child: MaterialApp(
        theme: ReminderTheme.light(),
        home: const SettingsPage(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

ItemPack _defaultPack() {
  return ItemPack(
    id: 1,
    title: '一般',
    iconEmoji: '📌',
    orderIndex: 0,
    status: ItemPackStatus.active,
    isSystemDefault: true,
    createdAt: DateTime(2026, 5, 1),
    updatedAt: DateTime(2026, 5, 1),
  );
}

ItemPack _customPack() {
  return ItemPack(
    id: 2,
    title: '養貓',
    iconEmoji: '🐱',
    orderIndex: 1,
    status: ItemPackStatus.active,
    isSystemDefault: false,
    createdAt: DateTime(2026, 5, 1),
    updatedAt: DateTime(2026, 5, 1),
  );
}

AppSettings _appSettings() {
  return AppSettings(
    reminderTone: ReminderTone.standard,
    notificationReminderTime: '09:00',
    updatedAt: DateTime(2026, 5, 28),
  );
}
