import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:reminder_app/app/theme/reminder_theme.dart';
import 'package:reminder_app/features/reminders/data/item_repository.dart';
import 'package:reminder_app/features/reminders/data/local/app_database.dart';
import 'package:reminder_app/features/reminders/data/local/reminder_dao.dart';
import 'package:reminder_app/features/reminders/data/resource_repository.dart';
import 'package:reminder_app/features/reminders/domain/item.dart';
import 'package:reminder_app/features/reminders/domain/item_action_record.dart';
import 'package:reminder_app/features/reminders/domain/item_pack.dart';
import 'package:reminder_app/features/reminders/domain/resource.dart';
import 'package:reminder_app/features/reminders/providers/database_providers.dart';
import 'package:reminder_app/features/reminders/providers/developer_settings_providers.dart';
import 'package:reminder_app/features/reminders/providers/item_providers.dart';
import 'package:reminder_app/features/reminders/ui/pages/item_history_page.dart';

void main() {
  testWidgets('route opens item history page with summary and filters', (
    tester,
  ) async {
    final pack = _pack();
    final bundle = _stateItemBundle(pack: pack);
    await _pumpHistoryRoute(
      tester,
      bundle: bundle,
      entries: [
        _entry(id: 1, date: DateTime(2026, 5, 20, 14, 30), titleLabel: '完成'),
      ],
    );

    expect(find.text('事項紀錄'), findsOneWidget);
    expect(find.byKey(const Key('item-history-summary-card')), findsOneWidget);
    expect(find.text('換濾芯'), findsOneWidget);
    expect(find.text('彈性節奏・目前穩定'), findsOneWidget);
    expect(find.text('🏠 家務'), findsOneWidget);
    expect(find.text('全部'), findsOneWidget);
    expect(find.byType(RefreshIndicator), findsOneWidget);
    expect(find.text('完成'), findsWidgets);
    expect(find.text('已回復'), findsOneWidget);
    expect(find.text('資源影響'), findsOneWidget);
  });

  testWidgets('filters narrow done, reverted, and resource impact entries', (
    tester,
  ) async {
    final pack = _pack();
    await _pumpHistory(
      tester,
      bundle: _stateItemBundle(pack: pack),
      entries: [
        _entry(id: 1, date: DateTime(2026, 5, 20, 14), titleLabel: '完成'),
        _entry(
          id: 2,
          date: DateTime(2026, 5, 19, 10),
          titleLabel: '完成，後來已回復',
          revertedAt: DateTime(2026, 5, 20),
        ),
        _entry(
          id: 3,
          type: ItemActionType.skipped,
          date: DateTime(2026, 5, 18),
          titleLabel: '跳過',
        ),
        _entry(
          id: 4,
          date: DateTime(2026, 5, 17),
          titleLabel: '完成',
          impacts: const [
            ItemResourceImpactEntry(
              resourceId: 7,
              resourceTitle: '濾芯',
              amount: 1,
              unitLabel: '個',
              isCompensation: false,
            ),
          ],
        ),
      ],
    );

    await tester.tap(find.byKey(const Key('item-history-filter-done')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('item-history-row-1')), findsOneWidget);
    expect(find.byKey(const Key('item-history-row-2')), findsOneWidget);
    expect(find.byKey(const Key('item-history-row-3')), findsNothing);

    await tester.tap(find.byKey(const Key('item-history-filter-reverted')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('item-history-row-1')), findsNothing);
    expect(find.byKey(const Key('item-history-row-2')), findsOneWidget);

    await tester.tap(
      find.byKey(const Key('item-history-filter-resourceImpact')),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('item-history-row-4')), findsOneWidget);
    expect(find.text('扣除：濾芯 1 個'), findsOneWidget);
  });

  testWidgets('reverted done is one merged row with restored resource impact', (
    tester,
  ) async {
    final pack = _pack();
    await _pumpHistory(
      tester,
      bundle: _stateItemBundle(pack: pack),
      entries: [
        _entry(
          id: 1,
          date: DateTime(2026, 5, 19, 9),
          titleLabel: '完成，後來已回復',
          revertedAt: DateTime(2026, 5, 20, 8),
          impacts: const [
            ItemResourceImpactEntry(
              resourceId: 7,
              resourceTitle: '濾芯',
              amount: 1,
              unitLabel: '個',
              isCompensation: false,
            ),
            ItemResourceImpactEntry(
              resourceId: 7,
              resourceTitle: '濾芯',
              amount: 1,
              unitLabel: '個',
              isCompensation: true,
            ),
          ],
        ),
      ],
    );

    expect(find.byKey(const Key('item-history-row-1')), findsOneWidget);
    expect(find.text('↩'), findsOneWidget);
    expect(find.text('完成，後來已回復'), findsOneWidget);
    expect(find.textContaining('完成於 2026/05/19 09:00'), findsOneWidget);
    expect(find.textContaining('回復於 2026/05/20 08:00'), findsOneWidget);
    expect(find.text('扣除：濾芯 1 個'), findsOneWidget);
    expect(find.text('已補回：濾芯 1 個'), findsOneWidget);
  });

  testWidgets('fixed item history displays action date without preview date', (
    tester,
  ) async {
    final pack = _pack();
    await _pumpHistory(
      tester,
      bundle: _fixedItemBundle(pack: pack),
      previewDate: DateTime(2026, 6, 1),
      entries: [
        _entry(id: 1, date: DateTime(2026, 5, 20, 14), titleLabel: '完成'),
      ],
    );

    expect(find.textContaining('完成於 2026/05/20 14:00'), findsOneWidget);
    expect(find.textContaining('2026/06/01'), findsNothing);
    expect(find.textContaining('previewDate'), findsNothing);
  });

  testWidgets('timeline groups dates and sorts by time', (tester) async {
    final pack = _pack();
    await _pumpHistory(
      tester,
      bundle: _stateItemBundle(pack: pack),
      entries: [
        _entry(id: 1, date: DateTime(2026, 5, 20, 9), titleLabel: '完成'),
        _entry(id: 2, date: DateTime(2026, 5, 20, 15), titleLabel: '完成'),
        _entry(id: 3, date: DateTime(2026, 5, 19, 8), titleLabel: '完成'),
      ],
    );

    expect(find.byKey(const Key('item-history-date-今天')), findsOneWidget);
    expect(find.byKey(const Key('item-history-date-昨天')), findsOneWidget);
    expect(find.byKey(const Key('item-history-marker-1')), findsOneWidget);
    final row2Top = tester
        .getTopLeft(find.byKey(const Key('item-history-row-2')))
        .dy;
    final row1Top = tester
        .getTopLeft(find.byKey(const Key('item-history-row-1')))
        .dy;
    expect(row2Top, lessThan(row1Top));
  });

  testWidgets('item history empty state is compact', (tester) async {
    final pack = _pack();
    await _pumpHistory(
      tester,
      bundle: _stateItemBundle(pack: pack),
      entries: const [],
    );

    expect(find.byKey(const Key('item-history-empty')), findsOneWidget);
    expect(find.text('尚未有事項紀錄。'), findsOneWidget);
    expect(find.text('完成事項後，這裡會顯示紀錄。'), findsOneWidget);
  });

  testWidgets('resource impacts support multiple rows and missing fallback', (
    tester,
  ) async {
    final pack = _pack();
    await _pumpHistory(
      tester,
      bundle: _stateItemBundle(pack: pack),
      entries: [
        _entry(
          id: 1,
          date: DateTime(2026, 5, 20),
          titleLabel: '完成',
          impacts: const [
            ItemResourceImpactEntry(
              resourceId: 7,
              resourceTitle: '濾芯',
              amount: 1,
              unitLabel: '個',
              isCompensation: false,
            ),
            ItemResourceImpactEntry(
              resourceId: 8,
              resourceTitle: '已封存資源',
              amount: 2,
              unitLabel: '個',
              isCompensation: false,
            ),
          ],
        ),
      ],
    );

    expect(find.text('扣除：濾芯 1 個'), findsOneWidget);
    expect(find.text('扣除：已封存資源 2 個'), findsOneWidget);
  });

  testWidgets('item history fits iPhone 15 width', (tester) async {
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final pack = _pack();
    await _pumpHistory(
      tester,
      bundle: _stateItemBundle(pack: pack, title: '很長很長很長的事項名稱'),
      entries: [
        _entry(
          id: 1,
          date: DateTime(2026, 5, 20),
          titleLabel: '完成，後來已回復',
          revertedAt: DateTime(2026, 5, 20, 15),
          impacts: const [
            ItemResourceImpactEntry(
              resourceId: 7,
              resourceTitle: '很長很長很長的資源名稱',
              amount: 100,
              unitLabel: '個',
              isCompensation: true,
            ),
          ],
        ),
      ],
    );

    expect(tester.takeException(), isNull);
  });

  test(
    'repository read model merges done, reverted, and resource impacts',
    () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);
      final itemRepository = ItemRepository(db.reminderDao);
      final resourceRepository = ResourceRepository(db.reminderDao);

      final itemId = await itemRepository.createItem(
        const ItemInput(
          title: '換濾芯',
          type: ItemType.stateBased,
          config: StateBasedItemConfig(
            warningAfter: Duration(days: 7),
            dangerAfter: Duration(days: 14),
          ),
        ),
      );
      final resourceId = await resourceRepository.createResource(
        const ResourceInput(
          title: '濾芯',
          type: ResourceType.quantityBased,
          config: QuantityBasedResourceConfig(
            currentQuantity: 2,
            unitLabel: '個',
            warningThreshold: 1,
            dangerThreshold: 0,
          ),
        ),
      );
      await resourceRepository.createConsumptionRule(
        ResourceConsumptionRuleInput(
          resourceId: resourceId,
          itemId: itemId,
          consumeAmount: 1,
        ),
      );
      await itemRepository.markDone(itemId, doneAt: DateTime(2026, 5, 20));
      final doneRecord = (await itemRepository.listActionHistory(
        itemId,
      )).firstWhere((record) => record.actionType == ItemActionType.done);
      await itemRepository.undoDone(
        doneRecord.id,
        revertedAt: DateTime(2026, 5, 21),
      );

      final entries = await itemRepository.watchHistoryEntries(itemId).first;
      final doneEntry = entries.firstWhere(
        (entry) => entry.actionRecordId == doneRecord.id,
      );

      expect(
        entries.where((entry) => entry.actionType == ItemActionType.reverted),
        isEmpty,
      );
      expect(doneEntry.titleLabel, '完成，後來已回復');
      expect(doneEntry.revertedAt, DateTime(2026, 5, 21));
      expect(doneEntry.resourceImpacts.map((impact) => impact.label), [
        '扣除：濾芯 1 個',
        '已補回：濾芯 1 個',
      ]);
    },
  );
}

Future<void> _pumpHistoryRoute(
  WidgetTester tester, {
  required ItemBundle bundle,
  required List<ItemHistoryEntry> entries,
}) async {
  final router = GoRouter(
    initialLocation: '/item/${bundle.item.id}/history',
    routes: [
      GoRoute(
        path: ItemHistoryPage.routePath,
        name: ItemHistoryPage.routeName,
        builder: (context, state) =>
            ItemHistoryPage(itemId: int.parse(state.pathParameters['id']!)),
      ),
    ],
  );
  addTearDown(router.dispose);
  await _pumpHistory(tester, bundle: bundle, entries: entries, router: router);
}

Future<void> _pumpHistory(
  WidgetTester tester, {
  required ItemBundle bundle,
  required List<ItemHistoryEntry> entries,
  DateTime? previewDate,
  GoRouter? router,
}) async {
  final db = AppDatabase.forTesting(NativeDatabase.memory());
  addTearDown(db.close);
  final child = router == null
      ? MaterialApp(
          theme: ReminderTheme.light(),
          home: ItemHistoryPage(itemId: bundle.item.id),
        )
      : MaterialApp.router(theme: ReminderTheme.light(), routerConfig: router);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        effectivePreviewDateProvider.overrideWith(
          (ref) => previewDate ?? DateTime(2026, 5, 20),
        ),
        itemProvider(bundle.item.id).overrideWith((ref) async => bundle),
        itemHistoryEntriesProvider(
          bundle.item.id,
        ).overrideWith((ref) => Stream.value(entries)),
      ],
      child: child,
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

ItemBundle _stateItemBundle({required ItemPack pack, String title = '換濾芯'}) {
  return ItemBundle(
    item: Item(
      id: 10,
      packId: pack.id,
      title: title,
      type: ItemType.stateBased,
      config: StateBasedItemConfig(
        anchorDate: DateTime(2026, 5, 20),
        warningAfter: const Duration(days: 7),
        dangerAfter: const Duration(days: 14),
      ),
      createdAt: DateTime(2026, 5, 1),
      updatedAt: DateTime(2026, 5, 20),
    ),
    pack: pack,
  );
}

ItemBundle _fixedItemBundle({required ItemPack pack}) {
  return ItemBundle(
    item: Item(
      id: 11,
      packId: pack.id,
      title: '繳電費',
      type: ItemType.fixed,
      config: FixedItemConfig(
        scheduleType: FixedScheduleType.monthly,
        anchorDate: DateTime(2026, 5, 1),
        dueDate: DateTime(2026, 5, 20),
      ),
      lastDoneAt: DateTime(2026, 5, 20),
      createdAt: DateTime(2026, 5, 1),
      updatedAt: DateTime(2026, 5, 20),
    ),
    pack: pack,
  );
}

ItemHistoryEntry _entry({
  required int id,
  required DateTime date,
  required String titleLabel,
  ItemActionType type = ItemActionType.done,
  DateTime? revertedAt,
  List<ItemResourceImpactEntry> impacts = const [],
}) {
  return ItemHistoryEntry(
    id: '${type.name}-$id',
    actionRecordId: id,
    actionType: type,
    actionDate: date,
    titleLabel: titleLabel,
    revertedAt: revertedAt,
    revertedActionRecordId: revertedAt == null ? null : id + 100,
    resourceImpacts: impacts,
  );
}
