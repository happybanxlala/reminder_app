import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reminder_app/app/theme/reminder_theme.dart';
import 'package:reminder_app/features/reminders/data/local/app_database.dart';
import 'package:reminder_app/features/reminders/data/local/reminder_dao.dart';
import 'package:reminder_app/features/reminders/data/resource_repository.dart';
import 'package:reminder_app/features/reminders/domain/item.dart';
import 'package:reminder_app/features/reminders/domain/item_pack.dart';
import 'package:reminder_app/features/reminders/domain/resource.dart';
import 'package:reminder_app/features/reminders/providers/developer_settings_providers.dart';
import 'package:reminder_app/features/reminders/providers/item_providers.dart';
import 'package:reminder_app/features/reminders/providers/resource_providers.dart';
import 'package:reminder_app/features/reminders/ui/pages/resource_edit_page.dart';

void main() {
  testWidgets('quantity edit page shows current quantity as read-only', (
    tester,
  ) async {
    final pack = _pack(id: 1, title: '一般');
    await _pumpFakeResourceEditPage(
      tester,
      bundle: _quantityBundle(id: 11, pack: pack),
    );

    expect(find.text('編輯資源'), findsOneWidget);
    expect(find.byKey(const Key('editor-bottom-save-bar')), findsOneWidget);
    expect(find.text('目前數量'), findsOneWidget);
    expect(find.text('5 個'), findsOneWidget);
    expect(find.text('如要修正數量，請使用「調整庫存」。'), findsOneWidget);
    expect(find.byKey(const Key('resource-type-readonly-row')), findsOneWidget);
    expect(
      find.byKey(const Key('resource-initial-quantity-field')),
      findsNothing,
    );
    expect(find.byKey(const Key('resource-pack-picker-row')), findsOneWidget);
  });

  testWidgets('time edit page shows remaining days as read-only', (
    tester,
  ) async {
    final pack = _pack(id: 1, title: '一般');
    await _pumpFakeResourceEditPage(
      tester,
      bundle: _timeBundle(id: 12, pack: pack),
    );

    expect(find.text('如要增加可用天數，請使用「補充」。'), findsOneWidget);
    expect(
      find.byKey(const Key('resource-available-days-field')),
      findsNothing,
    );
    expect(
      find.byKey(const Key('resource-warning-days-field')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('resource-danger-days-field')), findsOneWidget);
  });

  testWidgets('resource with bindings locks pack row', (tester) async {
    final pack = _pack(id: 1, title: '一般');
    await _pumpFakeResourceEditPage(
      tester,
      bundle: _quantityBundle(id: 11, pack: pack),
      bindings: [_binding(11)],
    );

    expect(find.byKey(const Key('resource-pack-readonly-row')), findsOneWidget);
    expect(find.byKey(const Key('resource-pack-picker-row')), findsNothing);
    expect(find.text('已綁定 item 的資源不能更改生活場景。'), findsOneWidget);
  });

  test('quantity update config preserves current quantity', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final repository = ResourceRepository(db.reminderDao);
    final resourceId = await repository.createResource(
      const ResourceInput(
        title: '濾芯',
        type: ResourceType.quantityBased,
        config: QuantityBasedResourceConfig(
          currentQuantity: 5,
          unitLabel: '個',
          warningThreshold: 2,
          dangerThreshold: 1,
        ),
      ),
    );
    final before = await repository.getResourceById(resourceId);
    final beforeConfig = before!.resource.config as QuantityBasedResourceConfig;

    expect(
      await repository.updateResource(
        resourceId,
        ResourceInput(
          title: before.resource.title,
          type: before.resource.type,
          config: QuantityBasedResourceConfig(
            currentQuantity: beforeConfig.currentQuantity,
            unitLabel: '包',
            warningThreshold: 4,
            dangerThreshold: 2,
          ),
        ),
      ),
      isTrue,
    );

    final saved = await repository.getResourceById(resourceId);
    final config = saved!.resource.config as QuantityBasedResourceConfig;
    expect(config.currentQuantity, 5);
    expect(config.unitLabel, '包');
    expect(config.warningThreshold, 4);
    expect(config.dangerThreshold, 2);
  });

  test('time update config preserves duration days', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final repository = ResourceRepository(db.reminderDao);
    final resourceId = await repository.createResource(
      ResourceInput(
        title: '洗髮精',
        type: ResourceType.timeBased,
        config: TimeBasedResourceConfig(
          anchorDate: DateTime(2026, 5, 1),
          durationDays: 20,
          warningBeforeDays: 3,
          dangerBeforeDays: 1,
        ),
      ),
    );
    final before = await repository.getResourceById(resourceId);
    final beforeConfig = before!.resource.config as TimeBasedResourceConfig;

    expect(
      await repository.updateResource(
        resourceId,
        ResourceInput(
          title: before.resource.title,
          type: before.resource.type,
          config: TimeBasedResourceConfig(
            anchorDate: beforeConfig.anchorDate,
            durationDays: beforeConfig.durationDays,
            warningBeforeDays: 5,
            dangerBeforeDays: 2,
          ),
        ),
      ),
      isTrue,
    );

    final saved = await repository.getResourceById(resourceId);
    final config = saved!.resource.config as TimeBasedResourceConfig;
    expect(config.anchorDate, DateTime(2026, 5, 1));
    expect(config.durationDays, 20);
    expect(config.warningBeforeDays, 5);
    expect(config.dangerBeforeDays, 2);
  });
}

Future<void> _pumpFakeResourceEditPage(
  WidgetTester tester, {
  required ResourceBundle bundle,
  List<ResourceBinding> bindings = const [],
}) async {
  tester.view.physicalSize = const Size(800, 1200);
  tester.view.devicePixelRatio = 1;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        effectivePreviewDateProvider.overrideWith(
          (ref) => DateTime(2026, 5, 10),
        ),
        activeItemPacksProvider.overrideWith(
          (ref) => Stream.value([bundle.pack]),
        ),
        resourceProvider(
          bundle.resource.id,
        ).overrideWith((ref) async => bundle),
        resourceBindingsProvider(
          bundle.resource.id,
        ).overrideWith((ref) => Stream.value(bindings)),
      ],
      child: MaterialApp(
        theme: ReminderTheme.light(),
        home: ResourceEditPage(resourceId: bundle.resource.id),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
}

ItemPack _pack({required int id, required String title}) {
  return ItemPack(
    id: id,
    title: title,
    status: ItemPackStatus.active,
    isSystemDefault: id == 1,
    createdAt: DateTime(2026, 5, 1),
    updatedAt: DateTime(2026, 5, 1),
  );
}

ResourceBundle _quantityBundle({required int id, required ItemPack pack}) {
  return ResourceBundle(
    resource: Resource(
      id: id,
      packId: pack.id,
      title: '濾芯',
      type: ResourceType.quantityBased,
      config: const QuantityBasedResourceConfig(
        currentQuantity: 5,
        unitLabel: '個',
        warningThreshold: 2,
        dangerThreshold: 1,
      ),
      createdAt: DateTime(2026, 5, 1),
      updatedAt: DateTime(2026, 5, 1),
    ),
    pack: pack,
  );
}

ResourceBundle _timeBundle({required int id, required ItemPack pack}) {
  return ResourceBundle(
    resource: Resource(
      id: id,
      packId: pack.id,
      title: '洗髮精',
      type: ResourceType.timeBased,
      config: TimeBasedResourceConfig(
        anchorDate: DateTime(2026, 5, 1),
        durationDays: 20,
        warningBeforeDays: 3,
        dangerBeforeDays: 1,
      ),
      createdAt: DateTime(2026, 5, 1),
      updatedAt: DateTime(2026, 5, 1),
    ),
    pack: pack,
  );
}

ResourceBinding _binding(int resourceId) {
  final now = DateTime(2026, 5, 1);
  return ResourceBinding(
    rule: ResourceConsumptionRule(
      id: 1,
      resourceId: resourceId,
      itemId: 1,
      consumeAmount: 1,
      createdAt: now,
      updatedAt: now,
    ),
    item: Item(
      id: 1,
      packId: 1,
      title: '清貓砂',
      type: ItemType.stateBased,
      config: StateBasedItemConfig(
        warningAfter: const Duration(days: 2),
        dangerAfter: const Duration(days: 4),
      ),
      createdAt: now,
      updatedAt: now,
    ),
  );
}
