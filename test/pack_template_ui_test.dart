import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:reminder_app/app/theme/reminder_theme.dart';
import 'package:reminder_app/features/reminders/data/auth_repository.dart';
import 'package:reminder_app/features/reminders/data/default_pack_templates.dart';
import 'package:reminder_app/features/reminders/data/item_repository.dart';
import 'package:reminder_app/features/reminders/data/local/app_database.dart';
import 'package:reminder_app/features/reminders/data/local/reminder_dao.dart';
import 'package:reminder_app/features/reminders/data/remote_shared_pack_data_source.dart';
import 'package:reminder_app/features/reminders/data/remote_shared_pack_models.dart';
import 'package:reminder_app/features/reminders/data/shared_pack_repository.dart';
import 'package:reminder_app/features/reminders/domain/item.dart';
import 'package:reminder_app/features/reminders/domain/item_pack.dart';
import 'package:reminder_app/features/reminders/domain/pack_template.dart';
import 'package:reminder_app/features/reminders/presentation/text/reminder_ui_text.dart';
import 'package:reminder_app/features/reminders/providers/database_providers.dart';
import 'package:reminder_app/features/reminders/providers/identity_providers.dart';
import 'package:reminder_app/features/reminders/providers/item_providers.dart';
import 'package:reminder_app/features/reminders/providers/pack_template_providers.dart';
import 'package:reminder_app/features/reminders/providers/remote_shared_pack_providers.dart';
import 'package:reminder_app/features/reminders/ui/pages/feature_management_sections.dart';
import 'package:reminder_app/features/reminders/ui/pages/feature_page.dart';

void main() {
  testWidgets('pack management template entry opens picker and preview', (
    tester,
  ) async {
    await _pumpPackManagement(tester);

    expect(find.byKey(const Key('pack-template-entry-card')), findsOneWidget);
    await tester.tap(find.byKey(const Key('pack-template-entry-action')));
    await tester.pumpAndSettle();

    expect(find.text(ReminderUiText.packTemplatePickerTitle), findsOneWidget);
    expect(
      find.text(ReminderUiText.packTemplateDefaultSectionTitle),
      findsOneWidget,
    );
    expect(
      find.text(ReminderUiText.packTemplateCustomSectionTitle),
      findsOneWidget,
    );
    expect(find.text('家務'), findsOneWidget);
    expect(find.text('個人護理'), findsOneWidget);
    expect(find.text('養貓'), findsOneWidget);
    expect(find.text('5 個事項'), findsAtLeastNWidgets(2));
    expect(find.byKey(const Key('pack-template-custom-empty')), findsOneWidget);

    await tester.tap(
      find.byKey(const Key('pack-template-row-default-housework')),
    );
    await tester.pumpAndSettle();

    expect(find.text('家務'), findsOneWidget);
    expect(find.text('生活場景：家務(模版)'), findsOneWidget);
    expect(find.text('倒垃圾'), findsOneWidget);
    expect(find.byType(Checkbox), findsNothing);
    expect(find.byType(TextFormField), findsNothing);
    expect(find.byKey(const Key('pack-template-use-button')), findsOneWidget);
  });

  testWidgets('create from template creates pack and snackbar view action', (
    tester,
  ) async {
    await _pumpPackManagement(tester);

    await tester.tap(find.byKey(const Key('pack-template-entry-action')));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const Key('pack-template-row-default-housework')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('pack-template-use-button')));
    await tester.pumpAndSettle();

    expect(find.text('已建立「家務(模版)」'), findsOneWidget);

    await tester.tap(find.text(ReminderUiText.packTemplateViewAction));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('items-route')), findsOneWidget);
  });

  testWidgets('pack create dialog exposes template entry', (tester) async {
    await _pumpPackManagement(tester);

    await tester.tap(find.byKey(const Key('pack-management-add')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('pack-dialog-template-entry')), findsOneWidget);

    await tester.tap(find.byKey(const Key('pack-dialog-template-entry')));
    await tester.pumpAndSettle();

    expect(find.text(ReminderUiText.packTemplatePickerTitle), findsOneWidget);
  });

  testWidgets('pack templates fit phone viewport', (tester) async {
    final view = tester.view;
    view.physicalSize = const Size(393, 852);
    view.devicePixelRatio = 1;
    addTearDown(() {
      view.resetPhysicalSize();
      view.resetDevicePixelRatio();
    });

    await _pumpPackManagement(tester);
    await tester.tap(find.byKey(const Key('pack-template-entry-action')));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });

  testWidgets('pack rows show shared care status labels', (tester) async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    final repository = ItemRepository(db.reminderDao);
    final personalId = await repository.createPack(
      const ItemPackInput(title: 'Plants', iconEmoji: '🪴'),
    );
    final sharedId = await repository.createPack(
      const ItemPackInput(title: 'Cats', iconEmoji: '🐱'),
    );
    await SharedPackRepository(db.reminderDao).convertPackToShared(sharedId);
    final packs = [
      _defaultPack(),
      (await repository.getPackById(personalId))!,
      (await repository.getPackById(sharedId))!,
    ];

    await _pumpPackManagement(tester, database: db, packs: packs);

    expect(find.text(ReminderUiText.systemDefaultPackLabel), findsWidgets);
    expect(find.text(ReminderUiText.packCareLocalOnlyLabel), findsOneWidget);
    expect(find.text('1 人一起照顧'), findsOneWidget);
  });

  testWidgets('pack overflow exposes care action before edit', (tester) async {
    final customPack = _customPack(id: 2, title: 'Cats');
    await _pumpPackManagement(tester, packs: [_defaultPack(), customPack]);

    expect(find.byKey(const Key('pack-overflow-1')), findsNothing);
    await tester.tap(find.byKey(const Key('pack-overflow-2')));
    await tester.pumpAndSettle();

    expect(find.text(ReminderUiText.packCareAction), findsOneWidget);
    final careTop = tester
        .getTopLeft(find.text(ReminderUiText.packCareAction))
        .dy;
    final editTop = tester.getTopLeft(find.text(ReminderUiText.editAction)).dy;
    expect(careTop, lessThan(editTop));
  });

  testWidgets('join entry opens join dialog', (tester) async {
    await _pumpPackManagement(tester);

    await tester.tap(find.byKey(const Key('pack-management-join')));
    await tester.pumpAndSettle();

    expect(find.text(ReminderUiText.packCareJoinTitle), findsWidgets);
    expect(find.byKey(const Key('pack-care-join-code-input')), findsOneWidget);
  });

  testWidgets('invite flow shows invite code actions', (tester) async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    final repository = ItemRepository(db.reminderDao);
    final packId = await repository.createPack(
      const ItemPackInput(title: 'Cats', iconEmoji: '🐱'),
    );
    await repository.createItem(
      ItemInput(
        title: 'Feed cat',
        type: ItemType.stateBased,
        config: const StateBasedItemConfig(
          warningAfter: Duration(days: 1),
          dangerAfter: Duration(days: 2),
        ),
        packId: packId,
      ),
    );
    final pack = (await repository.getPackById(packId))!;
    final remote = _FakeRemoteSharedPackDataSource();

    await _pumpPackManagement(
      tester,
      database: db,
      packs: [_defaultPack(), pack],
      extraOverrides: [
        authRepositoryProvider.overrideWithValue(FakeAuthRepository()),
        remoteSharedPackDataSourceProvider.overrideWithValue(remote),
      ],
    );

    await tester.tap(find.byKey(Key('pack-overflow-$packId')));
    await tester.pumpAndSettle();
    await tester.tap(find.text(ReminderUiText.packCareAction));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(Key('pack-care-invite-$packId')));
    await tester.pumpAndSettle();
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('pack-care-active-invite-card')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('pack-care-invite-code')), findsOneWidget);
    expect(find.text('K7M 4Q9'), findsOneWidget);
    expect(find.text(ReminderUiText.packCareShareInviteCode), findsOneWidget);
    expect(find.text(ReminderUiText.packCareCopyInviteCode), findsOneWidget);
    expect(find.text(ReminderUiText.packCareRefreshInviteCode), findsOneWidget);
    expect(remote.createdInviteCount, 1);
    expect(remote.createdItems.map((item) => item.title), ['Feed cat']);
  });
}

Future<void> _pumpPackManagement(
  WidgetTester tester, {
  AppDatabase? database,
  List<ItemPack>? packs,
  List<ItemBundle> itemBundles = const [],
  List<PackTemplate>? templates,
  List<Override> extraOverrides = const [],
}) async {
  final db = database ?? AppDatabase.forTesting(NativeDatabase.memory());
  final visiblePacks = packs ?? [_defaultPack()];
  final visibleTemplates = templates ?? defaultPackTemplates;
  final router = GoRouter(
    initialLocation: ItemPacksManagementPage.routePath,
    routes: [
      GoRoute(
        path: ItemPacksManagementPage.routePath,
        name: ItemPacksManagementPage.routeName,
        builder: (context, state) => const ItemPacksManagementPage(),
      ),
      GoRoute(
        path: ItemsManagementPage.routePath,
        name: ItemsManagementPage.routeName,
        builder: (context, state) => const Scaffold(
          body: KeyedSubtree(
            key: Key('items-route'),
            child: ItemsManagementContent(),
          ),
        ),
      ),
    ],
  );
  addTearDown(() async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1));
    router.dispose();
    await db.close();
  });

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        activeItemPacksProvider.overrideWith(
          (ref) => Stream.value(visiblePacks),
        ),
        packManagementItemsProvider.overrideWith(
          (ref) => Stream.value(itemBundles),
        ),
        packTemplatesProvider.overrideWith(
          (ref) => Stream.value(visibleTemplates),
        ),
        customPackTemplatesProvider.overrideWith(
          (ref) => Stream.value(
            visibleTemplates
                .where(
                  (template) => template.source == PackTemplateSource.custom,
                )
                .toList(growable: false),
          ),
        ),
        ...extraOverrides,
      ],
      child: MaterialApp.router(
        theme: ReminderTheme.light(),
        routerConfig: router,
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
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

ItemPack _customPack({required int id, required String title}) {
  return ItemPack(
    id: id,
    title: title,
    iconEmoji: '🐱',
    orderIndex: id,
    status: ItemPackStatus.active,
    isSystemDefault: false,
    createdAt: DateTime(2026, 5, 1),
    updatedAt: DateTime(2026, 5, 1),
  );
}

class _RemoteItemDraft {
  const _RemoteItemDraft({required this.id, required this.title});

  final String id;
  final String title;
}

class _FakeRemoteSharedPackDataSource implements RemoteSharedPackDataSource {
  int createdPackCount = 0;
  int createdInviteCount = 0;
  final _activeInvites = <String, RemotePackInvite>{};
  final createdItems = <_RemoteItemDraft>[];

  @override
  Future<String> upsertCurrentProfile({required String displayName}) async {
    return 'fake_profile';
  }

  @override
  Future<String> createSharedPack({
    required String name,
    String? description,
  }) async {
    createdPackCount += 1;
    return 'remote_pack_$createdPackCount';
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
    createdInviteCount += 1;
    final invite = RemotePackInvite(
      inviteId: 'invite_$createdInviteCount',
      inviteCode: 'K7M4Q9',
      expiresAt: DateTime(2026, 6, 29),
      maxUses: 10,
    );
    _activeInvites[packId] = invite;
    return invite;
  }

  @override
  Future<RemotePackInvite> refreshPackInvite({required String packId}) async {
    _activeInvites.remove(packId);
    createdInviteCount += 1;
    final invite = RemotePackInvite(
      inviteId: 'invite_$createdInviteCount',
      inviteCode: 'P8W6RA',
      expiresAt: DateTime(2026, 6, 29),
      maxUses: 10,
    );
    _activeInvites[packId] = invite;
    return invite;
  }

  @override
  Future<String> createPackItem({
    required String packId,
    required String title,
    String? note,
  }) async {
    final id = 'remote_item_${createdItems.length + 1}';
    createdItems.add(_RemoteItemDraft(id: id, title: title));
    return id;
  }

  @override
  Future<RemoteJoinPackResult> joinPackWithInvite({
    required String inviteCode,
  }) {
    throw const RemoteSharedPackException(
      RemoteSharedPackFailureReason.remoteUnknownFailure,
    );
  }

  @override
  Future<RemotePackSnapshot> fetchPackSnapshot(String remotePackId) {
    throw const RemoteSharedPackException(
      RemoteSharedPackFailureReason.remoteUnknownFailure,
    );
  }

  @override
  Future<RemoteItemCompletionResult> completePackItem({
    required String itemId,
    String? clientMutationId,
  }) {
    throw const RemoteSharedPackException(
      RemoteSharedPackFailureReason.remoteUnknownFailure,
    );
  }

  @override
  Future<RemoteRevokeInviteResult> revokePackInvite({
    required String inviteId,
  }) {
    throw const RemoteSharedPackException(
      RemoteSharedPackFailureReason.remoteUnknownFailure,
    );
  }

  @override
  Future<RemoteItemUndoResult> undoPackItemCompletion({
    required String itemId,
    String? clientMutationId,
  }) {
    throw const RemoteSharedPackException(
      RemoteSharedPackFailureReason.remoteUnknownFailure,
    );
  }
}
