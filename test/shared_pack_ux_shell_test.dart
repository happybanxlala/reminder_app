import 'dart:async';

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
import 'package:reminder_app/features/shared_pack/application/shared_pack_ui_controller.dart';

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

  testWidgets('custom pack members menu opens setup-required invite shell', (
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
      find.byKey(const Key('shared-pack-setup-required-message')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('shared-pack-refresh-button')), findsNothing);
    expect(
      tester
          .widget<FilledButton>(
            find.byKey(const Key('shared-pack-invite-member-button')),
          )
          .enabled,
      isFalse,
    );
  });

  testWidgets('fake enabled member dialog shows loading and generated invite', (
    tester,
  ) async {
    final inviteCompleter =
        Completer<SharedPackUiActionResult<SharedPackGeneratedInviteUiModel>>();
    final controller = _FakeSharedPackUiController(
      generateInviteHandler: ({int? localPackId, String? remotePackId}) {
        return inviteCompleter.future;
      },
      refreshablePackIds: const {2},
    );

    await _pumpPackManagement(tester, controller: controller);
    await _openCustomPackMembersDialog(tester);

    expect(find.byKey(const Key('shared-pack-refresh-button')), findsOneWidget);

    await tester.tap(find.byKey(const Key('shared-pack-invite-member-button')));
    await tester.pump();

    expect(controller.generateInviteLocalPackIds, contains(2));
    expect(find.byKey(const Key('shared-pack-invite-loading')), findsOneWidget);

    inviteCompleter.complete(
      SharedPackUiActionResult.success(
        SharedPackGeneratedInviteUiModel(inviteCode: 'K7M4Q9', expiresAt: null),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('shared-pack-generated-invite-code')),
      findsOneWidget,
    );
    expect(find.text('K7M 4Q9'), findsOneWidget);

    await tester.tap(find.byKey(const Key('shared-pack-refresh-button')));
    await tester.pumpAndSettle();

    expect(controller.refreshLocalPackIds, contains(2));
    expect(find.byKey(const Key('shared-pack-refresh-result')), findsOneWidget);
  });

  testWidgets('fake enabled member dialog shows invite error', (tester) async {
    final controller = _FakeSharedPackUiController(
      generateInviteHandler: ({int? localPackId, String? remotePackId}) async {
        return SharedPackUiActionResult.failure(message: '目前無法產生邀請碼。');
      },
    );

    await _pumpPackManagement(tester, controller: controller);
    await _openCustomPackMembersDialog(tester);
    await tester.tap(find.byKey(const Key('shared-pack-invite-member-button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('shared-pack-invite-error')), findsOneWidget);
    expect(find.text('目前無法產生邀請碼。'), findsOneWidget);
  });

  testWidgets('settings invite code entry opens setup-required join shell', (
    tester,
  ) async {
    await _pumpSettings(tester);

    await tester.scrollUntilVisible(
      find.byKey(const Key('settings-shared-pack-section')),
      160,
    );
    await tester.pumpAndSettle();

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
          .widget<TextButton>(
            find.byKey(const Key('shared-pack-preview-invite-button')),
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

  testWidgets('fake enabled settings join previews and joins normalized code', (
    tester,
  ) async {
    final controller = _FakeSharedPackUiController(
      previewHandler: ({required String inviteCode}) async {
        return SharedPackUiActionResult.success(
          const SharedPackInvitePreviewUiModel(
            remotePackId: 'remote-pack-a',
            packName: '養貓共享',
            isJoinable: true,
          ),
        );
      },
      joinHandler: ({required String inviteCode}) async {
        return SharedPackUiActionResult.success(
          const SharedPackJoinedPackUiModel(
            remotePackId: 'remote-pack-a',
            packName: '養貓共享',
            localPackId: 7,
            refreshRecommended: true,
          ),
        );
      },
    );

    await _pumpSettings(tester, controller: controller);
    await _openSettingsJoinDialog(tester);

    await tester.enterText(
      find.byKey(const Key('shared-pack-invite-code-field')),
      'k7m 4q9',
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const Key('shared-pack-preview-invite-button')),
    );
    await tester.pumpAndSettle();

    expect(controller.previewInviteCodes, ['K7M4Q9']);
    expect(controller.previewLocalWriteCount, 0);
    expect(find.byKey(const Key('shared-pack-preview-result')), findsOneWidget);
    expect(find.text('養貓共享'), findsOneWidget);
    expect(
      tester
          .widget<TextField>(
            find.byKey(const Key('shared-pack-invite-code-field')),
          )
          .controller!
          .text,
      'K7M 4Q9',
    );

    await tester.tap(find.byKey(const Key('shared-pack-join-button')));
    await tester.pumpAndSettle();

    expect(controller.joinInviteCodes, ['K7M4Q9']);
    expect(find.byKey(const Key('shared-pack-join-success')), findsOneWidget);
  });

  test('invite code helpers normalize spaces and hyphens', () {
    expect(normalizeSharedPackInviteCode('k7m 4q9'), 'K7M4Q9');
    expect(normalizeSharedPackInviteCode('k7m-4q9'), 'K7M4Q9');
    expect(groupSharedPackInviteCode('k7m-4q9'), 'K7M 4Q9');
  });
}

Future<void> _pumpPackManagement(
  WidgetTester tester, {
  SharedPackUiController? controller,
}) async {
  final db = AppDatabase.forTesting(NativeDatabase.memory());
  addTearDown(db.close);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        if (controller != null)
          sharedPackUiControllerProvider.overrideWithValue(controller),
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

Future<void> _pumpSettings(
  WidgetTester tester, {
  SharedPackUiController? controller,
}) async {
  final db = AppDatabase.forTesting(NativeDatabase.memory());
  addTearDown(db.close);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        if (controller != null)
          sharedPackUiControllerProvider.overrideWithValue(controller),
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

Future<void> _openCustomPackMembersDialog(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('pack-overflow-2')));
  await tester.pumpAndSettle();
  await tester.tap(find.text(ReminderUiText.sharedPackMembersLabel));
  await tester.pumpAndSettle();
}

Future<void> _openSettingsJoinDialog(WidgetTester tester) async {
  await tester.scrollUntilVisible(
    find.byKey(const Key('settings-enter-invite-code-row')),
    160,
  );
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const Key('settings-enter-invite-code-row')));
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

class _FakeSharedPackUiController implements SharedPackUiController {
  _FakeSharedPackUiController({
    this.generateInviteHandler,
    this.previewHandler,
    this.joinHandler,
    this.refreshablePackIds = const {},
  });

  final Future<SharedPackUiActionResult<SharedPackGeneratedInviteUiModel>>
  Function({int? localPackId, String? remotePackId})?
  generateInviteHandler;
  final Future<SharedPackUiActionResult<SharedPackInvitePreviewUiModel>>
  Function({required String inviteCode})?
  previewHandler;
  final Future<SharedPackUiActionResult<SharedPackJoinedPackUiModel>> Function({
    required String inviteCode,
  })?
  joinHandler;
  final Set<int> refreshablePackIds;

  final generateInviteLocalPackIds = <int?>[];
  final previewInviteCodes = <String>[];
  final joinInviteCodes = <String>[];
  final refreshLocalPackIds = <int?>[];
  final updateLocalItemIds = <int?>[];
  var previewLocalWriteCount = 0;

  @override
  SharedPackUiAvailability get availability =>
      const SharedPackUiAvailability.enabled();

  @override
  Future<bool> canRefreshSharedPack({required int localPackId}) async {
    return refreshablePackIds.contains(localPackId);
  }

  @override
  Future<bool> canUpdateSharedItemState({required int localItemId}) async {
    return false;
  }

  @override
  Future<SharedPackUiActionResult<SharedPackGeneratedInviteUiModel>>
  generateInvite({int? localPackId, String? remotePackId}) {
    generateInviteLocalPackIds.add(localPackId);
    final handler = generateInviteHandler;
    if (handler != null) {
      return handler(localPackId: localPackId, remotePackId: remotePackId);
    }
    return Future.value(
      SharedPackUiActionResult.success(
        SharedPackGeneratedInviteUiModel(inviteCode: 'K7M4Q9', expiresAt: null),
      ),
    );
  }

  @override
  Future<SharedPackUiActionResult<SharedPackInvitePreviewUiModel>>
  previewInvite({required String inviteCode}) {
    previewInviteCodes.add(inviteCode);
    final handler = previewHandler;
    if (handler != null) {
      return handler(inviteCode: inviteCode);
    }
    return Future.value(
      SharedPackUiActionResult.success(
        const SharedPackInvitePreviewUiModel(
          remotePackId: 'remote-pack-a',
          packName: '養貓共享',
          isJoinable: true,
        ),
      ),
    );
  }

  @override
  Future<SharedPackUiActionResult<SharedPackJoinedPackUiModel>> joinByInvite({
    required String inviteCode,
  }) {
    joinInviteCodes.add(inviteCode);
    final handler = joinHandler;
    if (handler != null) {
      return handler(inviteCode: inviteCode);
    }
    return Future.value(
      SharedPackUiActionResult.success(
        const SharedPackJoinedPackUiModel(
          remotePackId: 'remote-pack-a',
          packName: '養貓共享',
          localPackId: 7,
          refreshRecommended: true,
        ),
      ),
    );
  }

  @override
  Future<SharedPackUiActionResult<SharedPackRefreshUiModel>> refreshSharedPack({
    int? localPackId,
    String? remotePackId,
  }) {
    refreshLocalPackIds.add(localPackId);
    return Future.value(
      SharedPackUiActionResult.success(
        SharedPackRefreshUiModel(
          localPackId: localPackId ?? 7,
          remotePackId: remotePackId ?? 'remote-pack-a',
          createdItemsCount: 0,
          updatedItemsCount: 1,
        ),
      ),
    );
  }

  @override
  Future<SharedPackUiActionResult<SharedPackItemStateUiModel>>
  updateSharedItemState({
    int? localItemId,
    String? remoteItemId,
    required String newState,
    DateTime? completedAt,
  }) {
    updateLocalItemIds.add(localItemId);
    return Future.value(
      SharedPackUiActionResult.success(
        SharedPackItemStateUiModel.projected(
          localItemId: localItemId ?? 10,
          localPackId: 7,
          remoteItemId: remoteItemId ?? 'remote-item-a',
          remotePackId: 'remote-pack-a',
        ),
      ),
    );
  }
}
