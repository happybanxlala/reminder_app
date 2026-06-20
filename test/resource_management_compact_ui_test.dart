import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:reminder_app/app/theme/reminder_theme.dart';
import 'package:reminder_app/features/reminders/data/local/app_database.dart';
import 'package:reminder_app/features/reminders/data/local/reminder_dao.dart';
import 'package:reminder_app/features/reminders/data/resource_repository.dart';
import 'package:reminder_app/features/reminders/domain/item_pack.dart';
import 'package:reminder_app/features/reminders/domain/resource.dart';
import 'package:reminder_app/features/reminders/presentation/text/reminder_ui_text.dart';
import 'package:reminder_app/features/reminders/providers/database_providers.dart';
import 'package:reminder_app/features/reminders/providers/developer_settings_providers.dart';
import 'package:reminder_app/features/reminders/providers/item_providers.dart';
import 'package:reminder_app/features/reminders/providers/resource_providers.dart';
import 'package:reminder_app/features/reminders/ui/pages/feature_management_sections.dart';
import 'package:reminder_app/features/reminders/ui/pages/resource_edit_page.dart';
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
    expect(
      find.byKey(const Key('resource-refill-editor-section')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('resource-detail-dialog-11')), findsNothing);
  });

  testWidgets('quantity refill dialog validates and submits refillResource', (
    tester,
  ) async {
    _useTallViewport(tester);
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final repository = _RecordingResourceRepository(db);
    final catPack = _pack(id: 1, title: '養貓', iconEmoji: '🐱');
    await _pumpResourceManagement(
      tester,
      resources: [_quantityBundle(id: 11, pack: catPack, title: '貓砂')],
      db: db,
      repository: repository,
    );

    await tester.tap(find.byKey(const Key('resource-refill-11')));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('resource-refill-editor-section')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('resource-refill-quantity-field')),
      findsOneWidget,
    );
    expect(find.text('補充數量'), findsOneWidget);
    expect(find.text('目前 1 包，補充後 2 包'), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('resource-refill-quantity-field')),
      '0',
    );
    await tester.tap(find.byKey(const Key('resource-refill-submit')));
    await tester.pumpAndSettle();
    expect(find.text('請輸入 1 或以上整數'), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('resource-refill-quantity-field')),
      '3',
    );
    await tester.enterText(
      find.byKey(const Key('resource-refill-note-field')),
      '買了一包',
    );
    await tester.tap(find.byKey(const Key('resource-refill-submit')));
    await tester.pump(const Duration(milliseconds: 300));

    expect(repository.refillCalls.single.resourceId, 11);
    expect(repository.refillCalls.single.addedQuantity, 3);
    expect(repository.refillCalls.single.addedDays, isNull);
    expect(repository.refillCalls.single.remark, '買了一包');
  });

  testWidgets('time refill dialog uses added-days flow and preview', (
    tester,
  ) async {
    _useTallViewport(tester);
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final repository = _RecordingResourceRepository(db);
    final homePack = _pack(id: 2, title: '家務', iconEmoji: '🏠');
    await _pumpResourceManagement(
      tester,
      resources: [_timeBundle(id: 12, pack: homePack, title: '洗髮精')],
      db: db,
      repository: repository,
    );

    await tester.tap(find.byKey(const Key('resource-refill-12')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('resource-refill-days-field')), findsOneWidget);
    expect(find.text('新增可用天數'), findsOneWidget);
    expect(find.text('預計用完：2026/05/24'), findsOneWidget);
    expect(find.textContaining('增加'), findsNothing);

    await tester.enterText(
      find.byKey(const Key('resource-refill-days-field')),
      '5',
    );
    await tester.tap(find.byKey(const Key('resource-refill-submit')));
    await tester.pump(const Duration(milliseconds: 300));

    expect(repository.refillCalls.single.resourceId, 12);
    expect(repository.refillCalls.single.addedDays, 5);
    expect(repository.refillCalls.single.addedQuantity, isNull);
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
    expect(find.text(ReminderUiText.archiveAction), findsOneWidget);
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
    expect(find.text(ReminderUiText.archiveAction), findsOneWidget);
  });

  testWidgets('quantity adjust dialog validates and submits adjustment', (
    tester,
  ) async {
    _useTallViewport(tester);
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final repository = _RecordingResourceRepository(db);
    final catPack = _pack(id: 1, title: '養貓', iconEmoji: '🐱');
    await _pumpResourceManagement(
      tester,
      resources: [_quantityBundle(id: 11, pack: catPack, title: '貓砂')],
      db: db,
      repository: repository,
    );

    await tester.tap(find.byKey(const Key('resource-overflow-11')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('調整').last);
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('resource-adjust-editor-section')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('resource-adjust-quantity-field')),
      findsOneWidget,
    );
    expect(find.text('修正後數量'), findsOneWidget);
    expect(find.text('目前 1 包，將修正為 1 包'), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('resource-adjust-quantity-field')),
      '-1',
    );
    await tester.tap(find.byKey(const Key('resource-adjust-submit')));
    await tester.pumpAndSettle();
    expect(find.text('請輸入 0 或以上整數'), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('resource-adjust-quantity-field')),
      '5',
    );
    await tester.enterText(
      find.byKey(const Key('resource-adjust-note-field')),
      '盤點修正',
    );
    await tester.tap(find.byKey(const Key('resource-adjust-submit')));
    await tester.pump(const Duration(milliseconds: 300));

    expect(repository.adjustCalls.single.resourceId, 11);
    expect(repository.adjustCalls.single.newQuantity, 5);
    expect(repository.adjustCalls.single.remark, '盤點修正');
  });

  testWidgets('resource management header keeps compact add action', (
    tester,
  ) async {
    await _pumpResourceManagement(tester, resources: const []);

    final addButton = tester.widget<IconButton>(
      find.byKey(const Key('add-resource-button')),
    );

    expect(addButton.tooltip, '新增資源');
    expect(find.byType(RefreshIndicator), findsOneWidget);
  });

  testWidgets('add resource opens editor-style create dialog', (tester) async {
    _useTallViewport(tester);
    await _pumpResourceManagement(tester, resources: const []);

    await tester.tap(find.byKey(const Key('add-resource-button')));
    await tester.pumpAndSettle();

    expect(find.text('新增資源'), findsOneWidget);
    expect(
      find.byKey(const Key('resource-create-section-basic-info')),
      findsOneWidget,
    );
    expect(find.text('資源名稱'), findsOneWidget);
    expect(find.text('備註'), findsOneWidget);
    expect(find.byKey(const Key('resource-pack-picker-row')), findsOneWidget);
    expect(find.byType(DropdownButtonFormField<int?>), findsNothing);
    expect(find.byType(DropdownButtonFormField<ResourceType>), findsNothing);
    expect(
      find.byKey(const Key('resource-type-quantity-card')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('resource-type-time-card')), findsOneWidget);
    expect(
      find.byKey(const Key('resource-initial-quantity-field')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('resource-unit-field')), findsOneWidget);
    expect(
      find.byKey(const Key('resource-warning-quantity-field')),
      findsNothing,
    );

    await tester.tap(find.byKey(const Key('resource-pack-picker-row')));
    await tester.pumpAndSettle();
    expect(find.text(ReminderUiText.unassignedPackOption), findsWidgets);
    expect(find.text(ReminderUiText.systemDefaultPackLabel), findsNothing);
    await tester.tap(find.text(ReminderUiText.unassignedPackOption).last);
    await tester.pumpAndSettle();

    await tester.ensureVisible(
      find.byKey(const Key('resource-type-time-card')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('resource-type-time-card')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const Key('resource-available-days-field')),
      findsOneWidget,
    );
  });

  testWidgets('create dialog validates name and creates quantity config', (
    tester,
  ) async {
    _useTallViewport(tester);
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final repository = _RecordingResourceRepository(db);
    await _pumpResourceManagement(
      tester,
      resources: const [],
      db: db,
      repository: repository,
    );

    await tester.tap(find.byKey(const Key('add-resource-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('resource-save-button')));
    await tester.pumpAndSettle();
    expect(find.text('請輸入資源名稱'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('resource-title-field')), '濾芯');
    await tester.enterText(
      find.byKey(const Key('resource-initial-quantity-field')),
      '6',
    );
    await tester.enterText(find.byKey(const Key('resource-unit-field')), '');
    await tester.tap(find.byKey(const Key('resource-save-button')));
    await tester.pump(const Duration(milliseconds: 300));

    final input = repository.createdInputs.single;
    final config = input.config as QuantityBasedResourceConfig;
    expect(input.title, '濾芯');
    expect(config.currentQuantity, 6);
    expect(config.unitLabel, '個');
    expect(config.warningThreshold, 2);
    expect(config.dangerThreshold, 1);
  });

  testWidgets('time create defaults anchor date to today', (tester) async {
    _useTallViewport(tester);
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final repository = _RecordingResourceRepository(db);
    await _pumpResourceManagement(
      tester,
      resources: const [],
      db: db,
      repository: repository,
    );

    await tester.tap(find.byKey(const Key('add-resource-button')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('resource-title-field')),
      '洗髮精',
    );
    await tester.ensureVisible(
      find.byKey(const Key('resource-type-time-card')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('resource-type-time-card')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('resource-available-days-field')),
      '20',
    );
    final today = _today();
    await tester.tap(find.byKey(const Key('resource-save-button')));
    await tester.pump(const Duration(milliseconds: 300));

    final config =
        repository.createdInputs.single.config as TimeBasedResourceConfig;
    expect(config.anchorDate, today);
    expect(config.durationDays, 20);
    expect(config.warningBeforeDays, 3);
    expect(config.dangerBeforeDays, 1);
  });

  testWidgets('resource edit action navigates to full page editor', (
    tester,
  ) async {
    final catPack = _pack(id: 1, title: '養貓', iconEmoji: '🐱');
    await _pumpResourceManagement(
      tester,
      resources: [_quantityBundle(id: 11, pack: catPack, title: '貓砂')],
    );

    await tester.tap(find.byKey(const Key('resource-overflow-11')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('編輯'));
    await tester.pumpAndSettle();

    expect(find.text('編輯資源'), findsOneWidget);
    expect(find.byKey(const Key('editor-bottom-save-bar')), findsOneWidget);
    expect(find.byKey(const Key('resource-title-field')), findsOneWidget);
    expect(find.byKey(const Key('resource-type-readonly-row')), findsOneWidget);
    expect(
      find.byKey(const Key('resource-current-status-readonly-row')),
      findsOneWidget,
    );
    expect(find.text('如要修正數量，請使用「調整庫存」。'), findsOneWidget);
    expect(
      find.byKey(const Key('resource-initial-quantity-field')),
      findsNothing,
    );
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
  AppDatabase? db,
  ResourceRepository? repository,
}) async {
  final database = db ?? AppDatabase.forTesting(NativeDatabase.memory());
  final ownsDatabase = db == null;
  final packs = _packsFromResources(resources);
  final router = GoRouter(
    initialLocation: ResourceManagementPage.routePath,
    routes: [
      GoRoute(
        path: ResourceManagementPage.routePath,
        name: ResourceManagementPage.routeName,
        builder: (context, state) => const ResourceManagementContent(),
      ),
      GoRoute(
        path: ResourceEditPage.routePath,
        name: ResourceEditPage.routeName,
        builder: (context, state) {
          final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
          return ResourceEditPage(resourceId: id);
        },
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
    if (ownsDatabase) {
      await database.close();
    }
  });

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        appDatabaseProvider.overrideWithValue(database),
        effectivePreviewDateProvider.overrideWith(
          (ref) => DateTime(2026, 5, 20),
        ),
        activeItemPacksProvider.overrideWith((ref) => Stream.value(packs)),
        if (repository != null)
          resourceRepositoryProvider.overrideWith((ref) => repository),
        managedResourcesProvider.overrideWith((ref) => Stream.value(resources)),
        resourceProvider.overrideWith((ref, resourceId) async {
          for (final resource in resources) {
            if (resource.resource.id == resourceId) {
              return resource;
            }
          }
          return null;
        }),
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

List<ItemPack> _packsFromResources(List<ResourceBundle> resources) {
  final byId = <int, ItemPack>{};
  for (final resource in resources) {
    byId[resource.pack.id] = resource.pack;
  }
  return byId.values.toList(growable: false);
}

DateTime _today() {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day);
}

void _useTallViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(800, 1200);
  tester.view.devicePixelRatio = 1;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}

class _RecordingResourceRepository extends ResourceRepository {
  _RecordingResourceRepository(AppDatabase db) : super(db.reminderDao);

  final List<ResourceInput> createdInputs = [];
  final List<_RefillCall> refillCalls = [];
  final List<_AdjustCall> adjustCalls = [];

  @override
  Future<int> createResource(ResourceInput input) async {
    createdInputs.add(input);
    return createdInputs.length;
  }

  @override
  Future<bool> refillResource(
    int resourceId, {
    DateTime? actionAt,
    int? addedDays,
    int? addedQuantity,
    String? remark,
  }) async {
    refillCalls.add(
      _RefillCall(
        resourceId: resourceId,
        actionAt: actionAt,
        addedDays: addedDays,
        addedQuantity: addedQuantity,
        remark: remark,
      ),
    );
    return true;
  }

  @override
  Future<bool> adjustResourceQuantity(
    int resourceId, {
    required int newQuantity,
    DateTime? actionAt,
    String? remark,
    String? actorUserId,
  }) async {
    adjustCalls.add(
      _AdjustCall(
        resourceId: resourceId,
        newQuantity: newQuantity,
        actionAt: actionAt,
        remark: remark,
      ),
    );
    return true;
  }
}

class _RefillCall {
  const _RefillCall({
    required this.resourceId,
    this.actionAt,
    this.addedDays,
    this.addedQuantity,
    this.remark,
  });

  final int resourceId;
  final DateTime? actionAt;
  final int? addedDays;
  final int? addedQuantity;
  final String? remark;
}

class _AdjustCall {
  const _AdjustCall({
    required this.resourceId,
    required this.newQuantity,
    this.actionAt,
    this.remark,
  });

  final int resourceId;
  final int newQuantity;
  final DateTime? actionAt;
  final String? remark;
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
