import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:reminder_app/app/theme/reminder_theme.dart';
import 'package:reminder_app/features/reminders/data/local/app_database.dart';
import 'package:reminder_app/features/reminders/data/local/reminder_dao.dart';
import 'package:reminder_app/features/reminders/domain/item.dart';
import 'package:reminder_app/features/reminders/domain/item_pack.dart';
import 'package:reminder_app/features/reminders/presentation/text/reminder_ui_text.dart';
import 'package:reminder_app/features/reminders/providers/database_providers.dart';
import 'package:reminder_app/features/reminders/providers/developer_settings_providers.dart';
import 'package:reminder_app/features/reminders/providers/item_providers.dart';
import 'package:reminder_app/features/reminders/ui/pages/feature_management_sections.dart';
import 'package:reminder_app/features/reminders/ui/pages/feature_page.dart';
import 'package:reminder_app/features/reminders/ui/pages/item_edit_page.dart';
import 'package:reminder_app/features/reminders/ui/widgets/reminder_components.dart';

void main() {
  testWidgets('item management shows pack groups expanded by default', (
    tester,
  ) async {
    final catPack = _pack(id: 1, title: '養貓', iconEmoji: '🐱');
    final homePack = _pack(id: 2, title: '家務', iconEmoji: '🏠');
    final fixture = await _pumpManagement(
      tester,
      initialGroups: [
        _group(catPack, [_fixedBundle(id: 101, pack: catPack, title: '清貓砂')]),
        _group(homePack, [
          _stateBundle(id: 201, pack: homePack, title: '整理冰箱'),
        ]),
      ],
    );

    expect(find.byKey(const Key('pack-section-1')), findsOneWidget);
    expect(find.byKey(const Key('pack-section-2')), findsOneWidget);
    expect(find.byKey(const Key('item-card-101')), findsOneWidget);
    expect(find.byKey(const Key('item-card-201')), findsOneWidget);

    await tester.tap(find.byKey(const Key('pack-toggle-1')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('pack-section-1')), findsOneWidget);
    expect(find.byKey(const Key('item-card-101')), findsNothing);
    expect(find.byKey(const Key('item-card-201')), findsOneWidget);

    await tester.tap(find.byKey(const Key('pack-toggle-1')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('item-card-101')), findsOneWidget);

    final babyPack = _pack(id: 3, title: '寶寶', iconEmoji: '🍼');
    fixture.groupsController.state = AsyncData([
      _group(catPack, [_fixedBundle(id: 101, pack: catPack, title: '清貓砂')]),
      _group(homePack, [_stateBundle(id: 201, pack: homePack, title: '整理冰箱')]),
      _group(babyPack, [_fixedBundle(id: 301, pack: babyPack, title: '洗奶瓶')]),
    ]);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('pack-section-3')), findsOneWidget);
    expect(find.byKey(const Key('item-card-301')), findsOneWidget);
  });

  testWidgets('managed item row uses compact rail layout and edit menu', (
    tester,
  ) async {
    final catPack = _pack(id: 1, title: '養貓', iconEmoji: '🐱');
    await _pumpManagement(
      tester,
      initialGroups: [
        _group(catPack, [
          _fixedBundle(id: 101, pack: catPack, title: '清貓砂'),
          _stateBundle(id: 102, pack: catPack, title: '飲水器濾芯'),
        ]),
      ],
    );

    expect(find.byType(ReminderIconBubble), findsNothing);
    expect(find.byType(ReminderBadge), findsNothing);
    expect(find.byKey(const Key('item-edit-101')), findsNothing);
    expect(find.text('清貓砂'), findsOneWidget);
    expect(find.text('固定・每週'), findsOneWidget);
    expect(find.text('飲水器濾芯'), findsOneWidget);
    expect(find.text('彈性・2天前'), findsOneWidget);
    expect(find.text(ReminderUiText.fixedTypeLabel), findsNothing);
    expect(find.text('下次截止：2026/05/09'), findsNothing);

    await tester.tap(find.byKey(const Key('item-card-body-101')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('item-detail-dialog-101')), findsOneWidget);
    await tester.tap(find.text(ReminderUiText.closeAction));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('item-overflow-101')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('item-menu-edit-101')), findsOneWidget);
    expect(find.text(ReminderUiText.editAction), findsOneWidget);

    await tester.tap(find.byKey(const Key('item-menu-edit-101')));
    await tester.pumpAndSettle();

    expect(find.text('edit-route-101'), findsOneWidget);
  });

  testWidgets('management header keeps compact resource and add item actions', (
    tester,
  ) async {
    await _pumpManagement(tester, initialGroups: const []);

    final resourceButton = tester.widget<IconButton>(
      find.byKey(const Key('resource-management-button')),
    );
    final addButton = tester.widget<IconButton>(
      find.byKey(const Key('add-item-button')),
    );

    expect(resourceButton.tooltip, '資源管理');
    expect(addButton.tooltip, ReminderUiText.addItem);
  });

  testWidgets('compact item management fits phone viewport', (tester) async {
    final view = tester.view;
    view.physicalSize = const Size(393, 852);
    view.devicePixelRatio = 1;
    addTearDown(() {
      view.resetPhysicalSize();
      view.resetDevicePixelRatio();
    });

    final catPack = _pack(id: 1, title: '養貓', iconEmoji: '🐱');
    await _pumpManagement(
      tester,
      initialGroups: [
        _group(catPack, [
          _fixedBundle(id: 101, pack: catPack, title: '清貓砂'),
          _fixedBundle(id: 102, pack: catPack, title: '繳電費'),
          _stateBundle(id: 103, pack: catPack, title: '飲水器濾芯'),
        ]),
      ],
    );

    expect(tester.takeException(), isNull);
    expect(find.byType(ItemsManagementContent), findsOneWidget);
  });
}

Future<_ManagementFixture> _pumpManagement(
  WidgetTester tester, {
  required List<ItemManagementGroup> initialGroups,
}) async {
  final db = AppDatabase.forTesting(NativeDatabase.memory());
  final groupsProvider = StateProvider<AsyncValue<List<ItemManagementGroup>>>(
    (ref) => AsyncData(initialGroups),
  );
  final container = ProviderContainer(
    overrides: [
      appDatabaseProvider.overrideWithValue(db),
      effectivePreviewDateProvider.overrideWith((ref) => DateTime(2026, 5, 2)),
      itemManagementGroupsProvider.overrideWith(
        (ref) => ref.watch(groupsProvider),
      ),
    ],
  );
  final router = GoRouter(
    initialLocation: ItemsManagementPage.routePath,
    routes: [
      GoRoute(
        path: ItemsManagementPage.routePath,
        name: ItemsManagementPage.routeName,
        builder: (context, state) => const ItemsManagementContent(),
      ),
      GoRoute(
        path: ResourceManagementPage.routePath,
        name: ResourceManagementPage.routeName,
        builder: (context, state) => const Scaffold(body: Text('resources')),
      ),
      GoRoute(
        path: ItemEditPage.editRoutePath,
        name: ItemEditPage.editRouteName,
        builder: (context, state) =>
            Scaffold(body: Text('edit-route-${state.pathParameters['id']}')),
      ),
    ],
  );
  addTearDown(() async {
    router.dispose();
    container.dispose();
    await db.close();
  });

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(
        theme: ReminderTheme.light(),
        routerConfig: router,
      ),
    ),
  );
  await tester.pumpAndSettle();

  return _ManagementFixture(
    groupsController: container.read(groupsProvider.notifier),
  );
}

ItemManagementGroup _group(ItemPack pack, List<ItemBundle> items) {
  return ItemManagementGroup(pack: pack, items: items);
}

ItemPack _pack({
  required int id,
  required String title,
  required String iconEmoji,
}) {
  return ItemPack(
    id: id,
    title: title,
    iconEmoji: iconEmoji,
    status: ItemPackStatus.active,
    isSystemDefault: id == 0,
    createdAt: DateTime(2026, 5),
    updatedAt: DateTime(2026, 5),
  );
}

ItemBundle _fixedBundle({
  required int id,
  required ItemPack pack,
  required String title,
}) {
  return _bundle(
    id: id,
    pack: pack,
    title: title,
    type: ItemType.fixed,
    config: FixedItemConfig(
      scheduleType: FixedScheduleType.weekly,
      anchorDate: DateTime(2026, 5, 2),
      dueDate: DateTime(2026, 5, 9),
      warningBefore: const Duration(days: 2),
      dangerBefore: const Duration(days: 1),
    ),
  );
}

ItemBundle _stateBundle({
  required int id,
  required ItemPack pack,
  required String title,
}) {
  return _bundle(
    id: id,
    pack: pack,
    title: title,
    type: ItemType.stateBased,
    config: StateBasedItemConfig(
      anchorDate: DateTime(2026, 5),
      warningAfter: const Duration(days: 5),
      dangerAfter: const Duration(days: 7),
    ),
  );
}

ItemBundle _bundle({
  required int id,
  required ItemPack pack,
  required String title,
  required ItemType type,
  required ItemConfig config,
}) {
  return ItemBundle(
    item: Item(
      id: id,
      packId: pack.id,
      title: title,
      type: type,
      config: config,
      createdAt: DateTime(2026, 5),
      updatedAt: DateTime(2026, 5),
    ),
    pack: pack,
  );
}

class _ManagementFixture {
  const _ManagementFixture({required this.groupsController});

  final StateController<AsyncValue<List<ItemManagementGroup>>> groupsController;
}
