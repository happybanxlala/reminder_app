import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reminder_app/app/theme/reminder_theme.dart';
import 'package:reminder_app/features/reminders/data/home_models.dart';
import 'package:reminder_app/features/reminders/data/item_repository.dart';
import 'package:reminder_app/features/reminders/data/local/app_database.dart';
import 'package:reminder_app/features/reminders/data/local/reminder_dao.dart';
import 'package:reminder_app/features/reminders/data/resource_repository.dart';
import 'package:reminder_app/features/reminders/domain/attention_summary.dart';
import 'package:reminder_app/features/reminders/domain/item.dart';
import 'package:reminder_app/features/reminders/domain/item_action_record.dart';
import 'package:reminder_app/features/reminders/domain/item_pack.dart';
import 'package:reminder_app/features/reminders/domain/remote_sync.dart';
import 'package:reminder_app/features/reminders/domain/resource.dart';
import 'package:reminder_app/features/reminders/domain/stage_occurrence.dart';
import 'package:reminder_app/features/reminders/domain/stage_tracker.dart';
import 'package:reminder_app/features/reminders/providers/attention_summary_providers.dart';
import 'package:reminder_app/features/reminders/providers/database_providers.dart';
import 'package:reminder_app/features/reminders/providers/developer_settings_providers.dart';
import 'package:reminder_app/features/reminders/providers/home_providers.dart';
import 'package:reminder_app/features/reminders/providers/item_providers.dart';
import 'package:reminder_app/features/reminders/providers/resource_providers.dart';
import 'package:reminder_app/features/reminders/providers/stage_tracker_providers.dart';
import 'package:reminder_app/features/reminders/ui/pages/home_page.dart';
import 'package:reminder_app/features/reminders/ui/widgets/reminder_components.dart';

void main() {
  testWidgets('home renders compact mixed entries and pack filtering', (
    tester,
  ) async {
    final fixture = await _pumpHome(tester);

    expect(find.text('Clean litter box'), findsOneWidget);
    expect(find.text('Cat litter'), findsOneWidget);
    expect(find.byKey(const Key('resource-card-11')), findsOneWidget);
    expect(find.byKey(const Key('resource-card-12')), findsOneWidget);
    expect(find.text('彈性處理'), findsNothing);
    expect(find.text('庫存'), findsNothing);
    expect(find.byType(RefreshIndicator), findsOneWidget);
    expect(find.byType(ReminderIconBubble), findsNothing);
    expect(
      find.byKey(Key('home-pack-chip-${fixture.catPack.id}')),
      findsWidgets,
    );
    expect(find.byTooltip('完成'), findsWidgets);
    expect(find.byTooltip('補充'), findsWidgets);

    await tester.tap(find.byKey(Key('home-pack-filter-${fixture.catPack.id}')));
    await tester.pump();

    expect(find.text('Clean litter box'), findsOneWidget);
    expect(find.text('Cat litter'), findsOneWidget);
    expect(find.text('Dish soap'), findsNothing);
    expect(find.byKey(const Key('resource-card-11')), findsOneWidget);
    expect(find.byKey(const Key('resource-card-12')), findsNothing);
  });

  testWidgets('home card body expands one entry at a time', (tester) async {
    await _pumpHome(tester);

    await tester.tap(find.byKey(const Key('home-card-body-item-21')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('item-content-21')), findsOneWidget);
    expect(find.text('彈性處理'), findsOneWidget);
    expect(find.byKey(const Key('item-content-22')), findsNothing);

    await tester.tap(find.byKey(const Key('home-card-body-item-22')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('item-content-21')), findsNothing);
    expect(find.byKey(const Key('item-content-22')), findsOneWidget);
    expect(find.byKey(const Key('item-content-21')), findsNothing);
  });

  testWidgets('remote-backed home card shows sync status label', (
    tester,
  ) async {
    await _pumpHome(
      tester,
      firstItemSyncStatus: const HomeItemSyncStatus(
        isRemoteBacked: true,
        pendingMutationAction: SyncOutboxActionType.completeItem,
        pendingMutationStatus: SyncOutboxStatus.pending,
      ),
    );

    expect(find.byKey(const Key('item-sync-status-21')), findsOneWidget);
    expect(find.text('等待同步'), findsOneWidget);
  });

  testWidgets('complete icon does not expand item card', (tester) async {
    await _pumpHome(tester);

    await tester.tap(find.byKey(const Key('item-checkbox-21')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('item-content-21')), findsNothing);
  });

  testWidgets('resource card expands and refill icon opens compact dialog', (
    tester,
  ) async {
    await _pumpHome(tester);

    await tester.tap(find.byKey(const Key('home-card-body-resource-11')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('resource-content-11')), findsOneWidget);
    expect(find.text('數量庫存'), findsOneWidget);
    expect(find.byKey(const Key('resource-history-11')), findsOneWidget);

    await tester.tap(find.byKey(const Key('resource-refill-11')));
    await tester.pumpAndSettle();

    expect(find.text('補充資源'), findsOneWidget);
    expect(find.text('新增數量'), findsOneWidget);
  });

  testWidgets('home compact layout fits phone-sized viewport', (tester) async {
    final view = tester.view;
    view.physicalSize = const Size(393, 852);
    view.devicePixelRatio = 1;
    addTearDown(() {
      view.resetPhysicalSize();
      view.resetDevicePixelRatio();
    });

    await _pumpHome(tester);

    expect(tester.takeException(), isNull);
    expect(find.byType(HomeContent), findsOneWidget);
  });

  testWidgets('today completed section expands and undo removes item entry', (
    tester,
  ) async {
    final controller = StreamController<List<TodayCompletedEntry>>.broadcast();
    DateTime? revertedAt;
    await _pumpHome(
      tester,
      completedController: controller,
      onUndo: (value) {
        revertedAt = value;
      },
    );
    await tester.pump();
    controller.add(_completedEntries());
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView), const Offset(0, -700));
    await tester.pumpAndSettle();

    expect(find.text('今天已完成 2 項'), findsOneWidget);
    expect(find.byKey(const Key('today-completed-content')), findsNothing);

    await tester.tap(find.byKey(const Key('today-completed-header')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('today-completed-content')), findsOneWidget);
    expect(find.text('Clean litter box'), findsWidgets);
    expect(find.text('Cat litter'), findsWidgets);
    expect(find.byTooltip('恢復成未完成'), findsOneWidget);

    await tester.tap(find.byTooltip('恢復成未完成'));
    controller.add(const <TodayCompletedEntry>[]);
    await tester.pumpAndSettle();

    expect(revertedAt, DateTime(2026, 5, 2));
    expect(find.text('今天已完成 2 項'), findsNothing);
  });
}

Future<_HomeFixture> _pumpHome(
  WidgetTester tester, {
  StreamController<List<TodayCompletedEntry>>? completedController,
  ValueChanged<DateTime?>? onUndo,
  HomeItemSyncStatus firstItemSyncStatus = HomeItemSyncStatus.localOnly,
}) async {
  final db = AppDatabase.forTesting(NativeDatabase.memory());
  addTearDown(db.close);
  final catPack = _pack(id: 1, title: 'Cat', iconEmoji: '🐱');
  final homePack = _pack(id: 2, title: 'Home', iconEmoji: '🏠');
  final catResource = _resourceBundle(
    id: 11,
    pack: catPack,
    title: 'Cat litter',
  );
  final homeResource = _resourceBundle(
    id: 12,
    pack: homePack,
    title: 'Dish soap',
  );
  final entries = [
    _itemEntry(
      id: 21,
      pack: catPack,
      title: 'Clean litter box',
      syncStatus: firstItemSyncStatus,
    ),
    _itemEntry(id: 22, pack: homePack, title: 'Pay electricity bill'),
    HomeAttentionEntry.resource(
      bundle: catResource,
      severity: HomeAttentionSeverity.danger,
      urgencyDate: null,
    ),
    HomeAttentionEntry.resource(
      bundle: homeResource,
      severity: HomeAttentionSeverity.danger,
      urgencyDate: null,
    ),
  ];

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        effectivePreviewDateProvider.overrideWith(
          (ref) => DateTime(2026, 5, 2),
        ),
        attentionSummaryProvider.overrideWith(
          (ref) => Stream.value(
            const AttentionSummary(
              dangerItemCount: 2,
              warningItemCount: 0,
              dangerResourceCount: 2,
              warningResourceCount: 0,
              stageUpcomingCount: 0,
            ),
          ),
        ),
        dangerHomeAttentionEntriesProvider.overrideWith(
          (ref) => Stream.value(entries),
        ),
        warningHomeAttentionEntriesProvider.overrideWith(
          (ref) => Stream.value(const <HomeAttentionEntry>[]),
        ),
        upcomingStagesProvider.overrideWith(
          (ref) => Stream.value(const <StageOccurrence>[]),
        ),
        todayCompletedEntriesProvider.overrideWith(
          (ref) =>
              completedController?.stream ??
              Stream.value(const <TodayCompletedEntry>[]),
        ),
        activeItemPacksProvider.overrideWith(
          (ref) => Stream.value([catPack, homePack]),
        ),
        stageTrackersProvider.overrideWith(
          (ref) => Stream.value(const <StageTracker>[]),
        ),
        resourcesProvider.overrideWith(
          (ref) => Stream.value([catResource, homeResource]),
        ),
        resourceSyncStatusProvider.overrideWith(
          (ref, resourceId) => ResourceSyncStatus.localOnly,
        ),
        itemRepositoryProvider.overrideWith(
          (ref) => _UndoItemRepository(
            db.reminderDao,
            onUndo: (value) {
              onUndo?.call(value);
              completedController?.add(const <TodayCompletedEntry>[]);
            },
          ),
        ),
        resourceRepositoryProvider.overrideWith(
          (ref) => ResourceRepository(db.reminderDao),
        ),
      ],
      child: MaterialApp(
        theme: ReminderTheme.light(),
        home: const Scaffold(body: HomeContent()),
      ),
    ),
  );
  await tester.pump();
  await tester.pump();
  return _HomeFixture(catPack: catPack);
}

List<TodayCompletedEntry> _completedEntries() {
  final pack = _pack(id: 1, title: 'Cat', iconEmoji: '🐱');
  final item = Item(
    id: 21,
    packId: pack.id,
    title: 'Clean litter box',
    type: ItemType.stateBased,
    config: const StateBasedItemConfig(
      warningAfter: Duration(days: 1),
      dangerAfter: Duration(days: 2),
    ),
    createdAt: DateTime(2026, 5),
    updatedAt: DateTime(2026, 5),
  );
  final resource = _resourceBundle(id: 11, pack: pack, title: 'Cat litter');
  return [
    TodayCompletedEntry.itemDone(
      ItemActionEntry(
        record: ItemActionRecord(
          id: 31,
          itemId: item.id,
          actionType: ItemActionType.done,
          actionDate: DateTime(2026, 5, 2),
          payload: const {
            'undoSnapshot': {
              'fixedAnchorDate': null,
              'fixedDueDate': null,
              'fixedRepeatRuleV2': null,
              'stateAnchorDate': null,
              'lastDoneAt': null,
            },
          },
          createdAt: DateTime(2026, 5, 2),
          updatedAt: DateTime(2026, 5, 2),
        ),
        item: item,
        pack: pack,
      ),
    ),
    TodayCompletedEntry.resource(
      ResourceActionEntry(
        record: ResourceActionRecord(
          id: 41,
          resourceId: resource.resource.id,
          actionType: ResourceActionType.refilled,
          actionDate: DateTime(2026, 5, 2),
          amount: 1,
          resultingQuantity: 1,
          createdAt: DateTime(2026, 5, 2),
          updatedAt: DateTime(2026, 5, 2),
        ),
        resource: resource.resource,
        pack: resource.pack,
      ),
    ),
  ];
}

HomeAttentionEntry _itemEntry({
  required int id,
  required ItemPack pack,
  required String title,
  HomeItemSyncStatus syncStatus = HomeItemSyncStatus.localOnly,
}) {
  return HomeAttentionEntry.item(
    entry: ItemHomeEntry(
      bundle: ItemBundle(
        item: Item(
          id: id,
          packId: pack.id,
          title: title,
          type: ItemType.stateBased,
          config: StateBasedItemConfig(
            anchorDate: DateTime(2026, 5, 1),
            warningAfter: const Duration(days: 1),
            dangerAfter: const Duration(days: 2),
          ),
          createdAt: DateTime(2026, 5),
          updatedAt: DateTime(2026, 5),
        ),
        pack: pack,
      ),
      status: ItemStatus.danger,
      syncStatus: syncStatus,
    ),
    severity: HomeAttentionSeverity.danger,
    urgencyDate: DateTime(2026, 5, 2),
  );
}

ResourceBundle _resourceBundle({
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
        currentQuantity: 0,
        unitLabel: '包',
        warningThreshold: 2,
        dangerThreshold: 1,
      ),
      createdAt: DateTime(2026, 5),
      updatedAt: DateTime(2026, 5),
    ),
    pack: pack,
  );
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
    isSystemDefault: false,
    createdAt: DateTime(2026, 5),
    updatedAt: DateTime(2026, 5),
  );
}

class _HomeFixture {
  const _HomeFixture({required this.catPack});

  final ItemPack catPack;
}

class _UndoItemRepository extends ItemRepository {
  _UndoItemRepository(super.dao, {required this.onUndo});

  final ValueChanged<DateTime?> onUndo;

  @override
  Future<bool> undoDone(
    int doneActionRecordId, {
    DateTime? revertedAt,
    String? actorUserId,
  }) async {
    onUndo(revertedAt);
    return true;
  }
}
