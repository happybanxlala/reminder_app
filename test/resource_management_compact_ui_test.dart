import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:reminder_app/app/theme/reminder_theme.dart';
import 'package:reminder_app/features/reminders/data/local/app_database.dart';
import 'package:reminder_app/features/reminders/data/local/reminder_dao.dart';
import 'package:reminder_app/features/reminders/domain/item_pack.dart';
import 'package:reminder_app/features/reminders/domain/resource.dart';
import 'package:reminder_app/features/reminders/providers/database_providers.dart';
import 'package:reminder_app/features/reminders/providers/developer_settings_providers.dart';
import 'package:reminder_app/features/reminders/providers/resource_providers.dart';
import 'package:reminder_app/features/reminders/ui/pages/feature_management_sections.dart';
import 'package:reminder_app/features/reminders/ui/pages/resource_history_page.dart';
import 'package:reminder_app/features/reminders/ui/widgets/reminder_components.dart';

void main() {
  testWidgets('resource management renders a single compact list', (
    tester,
  ) async {
    final catPack = _pack(id: 1, title: '養貓', iconEmoji: '🐱');
    final homePack = _pack(id: 2, title: '家務', iconEmoji: '🏠');
    await _pumpResourceManagement(
      tester,
      resources: [
        _quantityBundle(id: 11, pack: catPack, title: '貓砂'),
        _timeBundle(id: 12, pack: homePack, title: '洗髮精'),
      ],
    );

    expect(find.byKey(const Key('pack-section-1')), findsNothing);
    expect(find.byKey(const Key('resource-pack-chip-1')), findsOneWidget);
    expect(find.byKey(const Key('resource-pack-chip-2')), findsOneWidget);
    expect(find.text('貓砂'), findsOneWidget);
    expect(find.text('已不足・剩 1 包'), findsOneWidget);
    expect(find.text('洗髮精'), findsOneWidget);
    expect(find.text('剩 3 天・5/23 用完'), findsOneWidget);
    expect(find.byType(ReminderIconBubble), findsNothing);
    expect(find.byType(ReminderBadge), findsNothing);
    expect(find.widgetWithText(FilledButton, '補充'), findsNothing);
    expect(find.byKey(const Key('resource-refill-11')), findsOneWidget);
  });

  testWidgets('refill icon opens refill dialog without opening detail', (
    tester,
  ) async {
    final catPack = _pack(id: 1, title: '養貓', iconEmoji: '🐱');
    await _pumpResourceManagement(
      tester,
      resources: [_quantityBundle(id: 11, pack: catPack, title: '貓砂')],
    );

    await tester.tap(find.byKey(const Key('resource-refill-11')));
    await tester.pumpAndSettle();

    expect(find.text('補充資源'), findsOneWidget);
    expect(find.byKey(const Key('resource-detail-dialog-11')), findsNothing);
  });

  testWidgets('row body opens resource detail dialog', (tester) async {
    final catPack = _pack(id: 1, title: '養貓', iconEmoji: '🐱');
    await _pumpResourceManagement(
      tester,
      resources: [_quantityBundle(id: 11, pack: catPack, title: '貓砂')],
    );

    await tester.tap(find.byKey(const Key('resource-card-body-11')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('resource-detail-dialog-11')), findsOneWidget);
  });

  testWidgets('overflow keeps resource management actions', (tester) async {
    final catPack = _pack(id: 1, title: '養貓', iconEmoji: '🐱');
    await _pumpResourceManagement(
      tester,
      resources: [_quantityBundle(id: 11, pack: catPack, title: '貓砂')],
    );

    await tester.tap(find.byKey(const Key('resource-overflow-11')));
    await tester.pumpAndSettle();

    expect(find.text('調整'), findsOneWidget);
    expect(find.text('編輯'), findsOneWidget);
    expect(find.text('詳細資訊'), findsOneWidget);
    expect(find.text('歷史紀錄'), findsOneWidget);
    expect(find.text('封存'), findsOneWidget);
  });

  testWidgets('time-based resource overflow omits adjust action', (
    tester,
  ) async {
    final homePack = _pack(id: 2, title: '家務', iconEmoji: '🏠');
    await _pumpResourceManagement(
      tester,
      resources: [_timeBundle(id: 12, pack: homePack, title: '洗髮精')],
    );

    await tester.tap(find.byKey(const Key('resource-overflow-12')));
    await tester.pumpAndSettle();

    expect(find.text('調整'), findsNothing);
    expect(find.text('編輯'), findsOneWidget);
    expect(find.text('詳細資訊'), findsOneWidget);
    expect(find.text('歷史紀錄'), findsOneWidget);
    expect(find.text('封存'), findsOneWidget);
  });

  testWidgets('resource management header keeps compact add action', (
    tester,
  ) async {
    await _pumpResourceManagement(tester, resources: const []);

    final addButton = tester.widget<IconButton>(
      find.byKey(const Key('add-resource-button')),
    );

    expect(addButton.tooltip, '新增資源');
  });

  testWidgets('compact resource management fits phone viewport', (
    tester,
  ) async {
    final view = tester.view;
    view.physicalSize = const Size(393, 852);
    view.devicePixelRatio = 1;
    addTearDown(() {
      view.resetPhysicalSize();
      view.resetDevicePixelRatio();
    });

    final catPack = _pack(id: 1, title: '養貓', iconEmoji: '🐱');
    await _pumpResourceManagement(
      tester,
      resources: [
        _quantityBundle(id: 11, pack: catPack, title: '貓砂'),
        _quantityBundle(id: 12, pack: catPack, title: '貓糧'),
        _timeBundle(id: 13, pack: catPack, title: '洗髮精'),
      ],
    );

    expect(tester.takeException(), isNull);
    expect(find.byType(ResourceManagementContent), findsOneWidget);
  });
}

Future<void> _pumpResourceManagement(
  WidgetTester tester, {
  required List<ResourceBundle> resources,
}) async {
  final db = AppDatabase.forTesting(NativeDatabase.memory());
  final router = GoRouter(
    initialLocation: ResourceManagementPage.routePath,
    routes: [
      GoRoute(
        path: ResourceManagementPage.routePath,
        name: ResourceManagementPage.routeName,
        builder: (context, state) => const ResourceManagementContent(),
      ),
      GoRoute(
        path: ResourceHistoryPage.routePath,
        name: ResourceHistoryPage.routeName,
        builder: (context, state) => Scaffold(
          body: Text('resource-history-${state.pathParameters['id']}'),
        ),
      ),
    ],
  );
  addTearDown(() async {
    router.dispose();
    await db.close();
  });

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        effectivePreviewDateProvider.overrideWith(
          (ref) => DateTime(2026, 5, 20),
        ),
        managedResourcesProvider.overrideWith((ref) => Stream.value(resources)),
        resourceBindingsProvider.overrideWith(
          (ref, resourceId) => Stream.value(const <ResourceBinding>[]),
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
    createdAt: DateTime(2026, 5, 1),
    updatedAt: DateTime(2026, 5, 1),
  );
}

ResourceBundle _quantityBundle({
  required int id,
  required ItemPack pack,
  required String title,
}) {
  return ResourceBundle(
    resource: Resource(
      id: id,
      packId: pack.id,
      title: title,
      type: ResourceType.quantityBased,
      config: const QuantityBasedResourceConfig(
        currentQuantity: 1,
        unitLabel: '包',
        warningThreshold: 2,
        dangerThreshold: 1,
      ),
      createdAt: DateTime(2026, 5, 1),
      updatedAt: DateTime(2026, 5, 1),
    ),
    pack: pack,
  );
}

ResourceBundle _timeBundle({
  required int id,
  required ItemPack pack,
  required String title,
}) {
  return ResourceBundle(
    resource: Resource(
      id: id,
      packId: pack.id,
      title: title,
      type: ResourceType.timeBased,
      config: TimeBasedResourceConfig(
        anchorDate: DateTime(2026, 5, 20),
        durationDays: 4,
        warningBeforeDays: 2,
        dangerBeforeDays: 1,
      ),
      createdAt: DateTime(2026, 5, 1),
      updatedAt: DateTime(2026, 5, 1),
    ),
    pack: pack,
  );
}
