import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reminder_app/app/theme/reminder_theme.dart';
import 'package:reminder_app/features/reminders/data/local/app_database.dart';
import 'package:reminder_app/features/reminders/data/local/reminder_dao.dart';
import 'package:reminder_app/features/reminders/domain/item.dart';
import 'package:reminder_app/features/reminders/domain/item_pack.dart';
import 'package:reminder_app/features/reminders/domain/resource.dart';
import 'package:reminder_app/features/reminders/providers/database_providers.dart';
import 'package:reminder_app/features/reminders/providers/developer_settings_providers.dart';
import 'package:reminder_app/features/reminders/providers/resource_providers.dart';
import 'package:reminder_app/features/reminders/ui/pages/resource_history_page.dart';

void main() {
  testWidgets('quantity history shows summary, filters, and timeline rows', (
    tester,
  ) async {
    final pack = _pack();
    final bundle = _quantityBundle(pack: pack);
    await _pumpHistory(
      tester,
      bundle: bundle,
      defaultEntries: [
        _entry(
          id: 1,
          type: ResourceActionType.refilled,
          date: DateTime(2026, 5, 20, 14, 30),
          amount: 2,
          resultingQuantity: 4,
          remark: '手動補充',
        ),
        _entry(
          id: 2,
          type: ResourceActionType.consumed,
          date: DateTime(2026, 5, 19, 9),
          amount: 1,
          resultingQuantity: 3,
          sourceItem: _item(title: '換濾芯'),
        ),
        _entry(
          id: 3,
          type: ResourceActionType.adjusted,
          date: DateTime(2026, 5, 18, 8),
          resultingQuantity: 5,
        ),
      ],
    );

    expect(
      find.byKey(const Key('resource-history-summary-card')),
      findsOneWidget,
    );
    expect(find.text('濾芯'), findsOneWidget);
    expect(find.text('目前：2 個'), findsOneWidget);
    expect(find.text('狀態：快不足'), findsOneWidget);
    expect(find.text('全部'), findsOneWidget);
    expect(find.text('補充'), findsWidgets);
    expect(find.text('消耗'), findsOneWidget);
    expect(find.text('調整'), findsOneWidget);
    expect(find.text('回復'), findsOneWidget);
    expect(find.text('顯示已抵銷紀錄'), findsOneWidget);
    expect(find.byKey(const Key('resource-history-date-今天')), findsOneWidget);
    expect(find.byKey(const Key('resource-history-date-昨天')), findsOneWidget);
    expect(find.byKey(const Key('resource-history-marker-1')), findsOneWidget);
    expect(find.text('+'), findsOneWidget);
    expect(find.text('-'), findsOneWidget);
    expect(find.text('↔'), findsOneWidget);
    expect(find.text('補充 2 個'), findsOneWidget);
    expect(find.text('消耗 1 個'), findsOneWidget);
    expect(find.text('調整 5 個'), findsOneWidget);
    expect(find.textContaining('因完成「換濾芯」'), findsOneWidget);
  });

  testWidgets('time history summary shows remaining days and depletion date', (
    tester,
  ) async {
    final pack = _pack();
    await _pumpHistory(
      tester,
      bundle: _timeBundle(pack: pack),
      defaultEntries: const [],
    );

    expect(find.text('洗髮精'), findsOneWidget);
    expect(find.text('剩餘：19 天'), findsOneWidget);
    expect(find.text('預計用完：2026/06/08'), findsOneWidget);
    expect(find.byKey(const Key('resource-history-empty')), findsOneWidget);
  });

  testWidgets('history hides reverted records until toggle is enabled', (
    tester,
  ) async {
    final pack = _pack();
    final visible = _entry(
      id: 1,
      type: ResourceActionType.refilled,
      date: DateTime(2026, 5, 20),
      amount: 2,
      resultingQuantity: 4,
    );
    final reverted = _entry(
      id: 2,
      type: ResourceActionType.consumed,
      date: DateTime(2026, 5, 19),
      amount: 1,
      isReverted: true,
    );
    final compensation = _entry(
      id: 3,
      type: ResourceActionType.reverted,
      date: DateTime(2026, 5, 19),
      amount: 1,
    );
    await _pumpHistory(
      tester,
      bundle: _quantityBundle(pack: pack),
      defaultEntries: [visible],
      allEntries: [visible, reverted, compensation],
    );

    expect(find.byKey(const Key('resource-history-row-1')), findsOneWidget);
    expect(find.byKey(const Key('resource-history-row-2')), findsNothing);
    expect(find.byKey(const Key('resource-history-row-3')), findsNothing);

    await tester.tap(find.byKey(const Key('resource-history-show-reverted')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('resource-history-row-2')), findsOneWidget);
    expect(find.byKey(const Key('resource-history-row-3')), findsOneWidget);
    expect(find.text('已抵銷'), findsOneWidget);
    expect(find.text('回復補償'), findsWidgets);
    expect(find.text('↩'), findsOneWidget);
  });

  testWidgets('history filter chips narrow timeline rows', (tester) async {
    final pack = _pack();
    await _pumpHistory(
      tester,
      bundle: _quantityBundle(pack: pack),
      defaultEntries: [
        _entry(
          id: 1,
          type: ResourceActionType.refilled,
          date: DateTime(2026, 5, 20),
          amount: 2,
        ),
        _entry(
          id: 2,
          type: ResourceActionType.consumed,
          date: DateTime(2026, 5, 20),
          amount: 1,
        ),
      ],
    );

    await tester.tap(find.byKey(const Key('resource-history-filter-consumed')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('resource-history-row-1')), findsNothing);
    expect(find.byKey(const Key('resource-history-row-2')), findsOneWidget);
  });

  testWidgets('history fits iPhone 15 width', (tester) async {
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final pack = _pack();
    await _pumpHistory(
      tester,
      bundle: _quantityBundle(pack: pack, title: '很長很長很長的濾芯名稱'),
      defaultEntries: [
        _entry(
          id: 1,
          type: ResourceActionType.refilled,
          date: DateTime(2026, 5, 20),
          amount: 200,
          remark: '一段比較長的手動補充備註，應該要被截斷而不是 overflow',
        ),
      ],
    );

    expect(tester.takeException(), isNull);
  });
}

Future<void> _pumpHistory(
  WidgetTester tester, {
  required ResourceBundle bundle,
  required List<ResourceActionHistoryEntry> defaultEntries,
  List<ResourceActionHistoryEntry>? allEntries,
}) async {
  final db = AppDatabase.forTesting(NativeDatabase.memory());
  addTearDown(db.close);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        effectivePreviewDateProvider.overrideWith(
          (ref) => DateTime(2026, 5, 20),
        ),
        resourceProvider(
          bundle.resource.id,
        ).overrideWith((ref) async => bundle),
        resourceActionHistoryEntriesProvider(
          bundle.resource.id,
        ).overrideWith((ref) => Stream.value(defaultEntries)),
        resourceActionHistoryEntriesWithRevertedProvider(
          bundle.resource.id,
        ).overrideWith((ref) => Stream.value(allEntries ?? defaultEntries)),
      ],
      child: MaterialApp(
        theme: ReminderTheme.light(),
        home: ResourceHistoryPage(resourceId: bundle.resource.id),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

ItemPack _pack() {
  return ItemPack(
    id: 1,
    title: '家務',
    iconEmoji: '🏠',
    status: ItemPackStatus.active,
    isSystemDefault: false,
    createdAt: DateTime(2026, 5, 1),
    updatedAt: DateTime(2026, 5, 1),
  );
}

ResourceBundle _quantityBundle({required ItemPack pack, String title = '濾芯'}) {
  return ResourceBundle(
    resource: Resource(
      id: 10,
      packId: pack.id,
      title: title,
      type: ResourceType.quantityBased,
      config: const QuantityBasedResourceConfig(
        currentQuantity: 2,
        unitLabel: '個',
        warningThreshold: 2,
        dangerThreshold: 1,
      ),
      createdAt: DateTime(2026, 5, 1),
      updatedAt: DateTime(2026, 5, 20),
    ),
    pack: pack,
  );
}

ResourceBundle _timeBundle({required ItemPack pack}) {
  return ResourceBundle(
    resource: Resource(
      id: 11,
      packId: pack.id,
      title: '洗髮精',
      type: ResourceType.timeBased,
      config: TimeBasedResourceConfig(
        anchorDate: DateTime(2026, 5, 20),
        durationDays: 20,
        warningBeforeDays: 3,
        dangerBeforeDays: 1,
      ),
      createdAt: DateTime(2026, 5, 1),
      updatedAt: DateTime(2026, 5, 20),
    ),
    pack: pack,
  );
}

ResourceActionHistoryEntry _entry({
  required int id,
  required ResourceActionType type,
  required DateTime date,
  int? amount,
  int? resultingQuantity,
  bool isReverted = false,
  String? remark,
  Item? sourceItem,
}) {
  return ResourceActionHistoryEntry(
    record: ResourceActionRecord(
      id: id,
      resourceId: 10,
      actionType: type,
      actionDate: date,
      amount: amount,
      resultingQuantity: resultingQuantity,
      sourceItemActionRecordId: sourceItem == null ? null : 100 + id,
      remark: remark,
      isReverted: isReverted,
      createdAt: date,
      updatedAt: date,
    ),
    sourceItem: sourceItem,
  );
}

Item _item({required String title}) {
  return Item(
    id: 1,
    packId: 1,
    title: title,
    type: ItemType.stateBased,
    config: StateBasedItemConfig(
      warningAfter: const Duration(days: 7),
      dangerAfter: const Duration(days: 14),
    ),
    createdAt: DateTime(2026, 5, 1),
    updatedAt: DateTime(2026, 5, 1),
  );
}
