import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:reminder_app/features/reminders/data/home_models.dart';
import 'package:reminder_app/features/reminders/data/home_repository.dart';
import 'package:reminder_app/features/reminders/data/item_repository.dart';
import 'package:reminder_app/features/reminders/data/local/app_database.dart';
import 'package:reminder_app/features/reminders/data/local/item_timeline_dao.dart';
import 'package:reminder_app/features/reminders/data/timeline_repository.dart';
import 'package:reminder_app/features/reminders/domain/item.dart';
import 'package:reminder_app/features/reminders/domain/item_pack.dart';
import 'package:reminder_app/features/reminders/domain/timeline_milestone_occurrence.dart';
import 'package:reminder_app/features/reminders/domain/timeline_milestone_record.dart';
import 'package:reminder_app/features/reminders/providers/developer_settings_providers.dart';
import 'package:reminder_app/features/reminders/providers/item_providers.dart';
import 'package:reminder_app/features/reminders/presentation/text/reminder_ui_text.dart';
import 'package:reminder_app/features/reminders/providers/home_providers.dart';
import 'package:reminder_app/features/reminders/ui/pages/feature_page.dart';
import 'package:reminder_app/features/reminders/ui/pages/home_page.dart';
import 'package:reminder_app/features/reminders/ui/pages/item_edit_page.dart';

void main() {
  testWidgets('home shows danger warning and timeline tabs', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          dangerHomeEntriesProvider.overrideWith(
            (ref) => Stream.value([
              _itemEntry(title: 'Clean litter box', status: ItemStatus.danger),
            ]),
          ),
          warningHomeEntriesProvider.overrideWith(
            (ref) => Stream.value([
              _itemEntry(
                title: 'Refill water fountain',
                status: ItemStatus.warning,
              ),
            ]),
          ),
          upcomingTimelineMilestonesProvider.overrideWith(
            (ref) => Stream.value([_occurrence(title: 'No sugar')]),
          ),
        ],
        child: const MaterialApp(home: HomePage()),
      ),
    );
    await tester.pump();

    expect(find.text('Danger'), findsOneWidget);
    expect(find.text('Warning'), findsOneWidget);
    expect(find.text('Timeline'), findsOneWidget);
    expect(find.text('Clean litter box'), findsOneWidget);
    expect(find.byKey(const Key('history-button')), findsNothing);
    expect(find.byKey(const Key('quick-add-item-button')), findsNothing);
    expect(find.byKey(const Key('home-add-item-fab')), findsOneWidget);
  });

  testWidgets('timeline tab only renders timeline milestone items', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          dangerHomeEntriesProvider.overrideWith(
            (ref) => Stream.value(<ItemHomeEntry>[]),
          ),
          warningHomeEntriesProvider.overrideWith(
            (ref) => Stream.value(<ItemHomeEntry>[]),
          ),
          upcomingTimelineMilestonesProvider.overrideWith(
            (ref) => Stream.value([_occurrence(title: 'No sugar')]),
          ),
        ],
        child: const MaterialApp(home: HomePage()),
      ),
    );
    await tester.pump();

    await tester.tap(find.text('Timeline', skipOffstage: false).last);
    await tester.pumpAndSettle();

    expect(find.text('No sugar'), findsOneWidget);
    expect(find.text('Milestone'), findsOneWidget);
    expect(find.text('已看過'), findsOneWidget);
    expect(find.text('跳過'), findsOneWidget);
  });

  testWidgets('home feature button navigates to feature page', (tester) async {
    final router = GoRouter(
      initialLocation: HomePage.routePath,
      routes: [
        GoRoute(
          path: HomePage.routePath,
          name: HomePage.routeName,
          builder: (context, state) => const HomePage(),
        ),
        GoRoute(
          path: FeaturePage.routePath,
          name: FeaturePage.routeName,
          builder: (context, state) => const FeaturePage(),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          dangerHomeEntriesProvider.overrideWith(
            (ref) => Stream.value(<ItemHomeEntry>[]),
          ),
          warningHomeEntriesProvider.overrideWith(
            (ref) => Stream.value(<ItemHomeEntry>[]),
          ),
          upcomingTimelineMilestonesProvider.overrideWith(
            (ref) => Stream.value(<TimelineMilestoneOccurrence>[]),
          ),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('feature-button')), findsOneWidget);

    await tester.tap(find.byKey(const Key('feature-button')));
    await tester.pumpAndSettle();

    expect(find.text(ReminderUiText.featurePageTitle), findsOneWidget);
  });

  testWidgets('home add item fab navigates to item create page', (
    tester,
  ) async {
    final router = GoRouter(
      initialLocation: HomePage.routePath,
      routes: [
        GoRoute(
          path: HomePage.routePath,
          name: HomePage.routeName,
          builder: (context, state) => const HomePage(),
        ),
        GoRoute(
          path: ItemEditPage.createRoutePath,
          name: ItemEditPage.createRouteName,
          builder: (context, state) =>
              const Scaffold(body: Text('Create Item Page')),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          dangerHomeEntriesProvider.overrideWith(
            (ref) => Stream.value(<ItemHomeEntry>[]),
          ),
          warningHomeEntriesProvider.overrideWith(
            (ref) => Stream.value(<ItemHomeEntry>[]),
          ),
          upcomingTimelineMilestonesProvider.overrideWith(
            (ref) => Stream.value(<TimelineMilestoneOccurrence>[]),
          ),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('home-add-item-fab')), findsOneWidget);

    await tester.tap(find.byKey(const Key('home-add-item-fab')));
    await tester.pumpAndSettle();

    expect(find.text('Create Item Page'), findsOneWidget);
  });

  testWidgets('home preview updates when developer date override changes', (
    tester,
  ) async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final container = ProviderContainer(
      overrides: [
        homeRepositoryProvider.overrideWith(
          (ref) => _FakeHomeRepository(
            itemRepository: ItemRepository(db.itemTimelineDao),
            timelineRepository: TimelineRepository(db.itemTimelineDao),
          ),
        ),
      ],
    );
    addTearDown(container.dispose);
    container.read(developerDateOverrideProvider.notifier).state = DateTime(
      2026,
      4,
      11,
    );

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: HomePage()),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('Danger 11'), findsOneWidget);

    container.read(developerDateOverrideProvider.notifier).state = DateTime(
      2026,
      4,
      18,
    );
    await tester.pumpAndSettle();

    expect(find.text('Danger 11'), findsNothing);
    expect(find.text('Danger 18'), findsOneWidget);
  });

  testWidgets(
    'home preview follows system preview date when override is null',
    (tester) async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);
      final controller = StreamController<DateTime>.broadcast();
      addTearDown(controller.close);
      final container = ProviderContainer(
        overrides: [
          homeRepositoryProvider.overrideWith(
            (ref) => _FakeHomeRepository(
              itemRepository: ItemRepository(db.itemTimelineDao),
              timelineRepository: TimelineRepository(db.itemTimelineDao),
            ),
          ),
          systemPreviewDateProvider.overrideWith((ref) => controller.stream),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: HomePage()),
        ),
      );

      controller.add(DateTime(2026, 4, 18));
      await tester.pumpAndSettle();
      expect(find.text('Danger 18'), findsOneWidget);

      controller.add(DateTime(2026, 4, 19));
      await tester.pumpAndSettle();
      expect(find.text('Danger 18'), findsNothing);
      expect(find.text('Danger 19'), findsOneWidget);
    },
  );

  testWidgets('home complete action writes preview date into lastDoneAt', (
    tester,
  ) async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final itemRepository = _RecordingItemRepository(db.itemTimelineDao);
    final previewDate = DateTime(2026, 4, 11);
    const itemId = 101;
    final container = ProviderContainer(
      overrides: [
        itemRepositoryProvider.overrideWith((ref) => itemRepository),
        dangerHomeEntriesProvider.overrideWith(
          (ref) => Stream.value([
            ItemHomeEntry(
              bundle: ItemBundle(
                item: Item(
                  id: itemId,
                  packId: 1,
                  title: 'Clean litter box',
                  type: ItemType.stateBased,
                  config: const StateBasedItemConfig(
                    expectedInterval: Duration(days: 1),
                    warningAfter: Duration(days: 1),
                    dangerAfter: Duration(days: 2),
                  ),
                  lastDoneAt: DateTime(2026, 4, 8),
                  createdAt: DateTime(2026, 4, 1),
                  updatedAt: DateTime(2026, 4, 1),
                ),
                pack: ItemPack(
                  id: 1,
                  title: 'Default Item Pack',
                  status: ItemPackStatus.active,
                  isSystemDefault: true,
                  createdAt: DateTime(2026, 4, 1),
                  updatedAt: DateTime(2026, 4, 1),
                ),
              ),
              status: ItemStatus.danger,
              elapsed: const Duration(days: 3),
            ),
          ]),
        ),
        warningHomeEntriesProvider.overrideWith(
          (ref) => Stream.value(const <ItemHomeEntry>[]),
        ),
        upcomingTimelineMilestonesProvider.overrideWith(
          (ref) => Stream.value(const <TimelineMilestoneOccurrence>[]),
        ),
      ],
    );
    addTearDown(container.dispose);
    container.read(developerDateOverrideProvider.notifier).state = previewDate;

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: HomePage()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text(ReminderUiText.completeAction).first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(itemRepository.recordedItemId, itemId);
    expect(itemRepository.recordedDoneAt, previewDate);
  });
}

ItemHomeEntry _itemEntry({required String title, required ItemStatus status}) {
  final id = title.hashCode;
  return ItemHomeEntry(
    bundle: ItemBundle(
      item: Item(
        id: id,
        packId: 1,
        title: title,
        type: ItemType.stateBased,
        config: const StateBasedItemConfig(
          expectedInterval: Duration(days: 1),
          warningAfter: Duration(days: 1),
          dangerAfter: Duration(days: 2),
        ),
        lastDoneAt: DateTime(2026, 4, 10),
        createdAt: DateTime(2026, 4, 1),
        updatedAt: DateTime(2026, 4, 1),
      ),
      pack: ItemPack(
        id: 1,
        title: 'Default Item Pack',
        status: ItemPackStatus.active,
        isSystemDefault: true,
        createdAt: DateTime(2026, 4, 1),
        updatedAt: DateTime(2026, 4, 1),
      ),
    ),
    status: status,
    elapsed: const Duration(days: 5),
  );
}

class _FakeHomeRepository extends HomeRepository {
  _FakeHomeRepository({
    required super.itemRepository,
    required super.timelineRepository,
  }) : super();

  @override
  Stream<List<ItemHomeEntry>> watchDangerItems({DateTime? now}) {
    final current = now ?? DateTime.now();
    return Stream.value([
      _itemEntry(title: 'Danger ${current.day}', status: ItemStatus.danger),
    ]);
  }

  @override
  Stream<List<ItemHomeEntry>> watchWarningItems({DateTime? now}) {
    return Stream.value(const <ItemHomeEntry>[]);
  }

  @override
  Stream<List<TimelineMilestoneOccurrence>> watchUpcomingTimelineMilestones({
    DateTime? now,
  }) {
    return Stream.value(const <TimelineMilestoneOccurrence>[]);
  }
}

class _RecordingItemRepository extends ItemRepository {
  _RecordingItemRepository(super.dao);

  int? recordedItemId;
  DateTime? recordedDoneAt;

  @override
  Future<bool> markDone(
    int id, {
    int? addedDays,
    DateTime? doneAt,
    ItemNextCycleStrategy nextCycleStrategy =
        ItemNextCycleStrategy.keepSchedule,
    String? remark,
  }) async {
    recordedItemId = id;
    recordedDoneAt = doneAt;
    return true;
  }
}

TimelineMilestoneOccurrence _occurrence({required String title}) {
  final id = title.hashCode;
  return TimelineMilestoneOccurrence(
    recordId: id,
    timelineId: id,
    timelineTitle: title,
    ruleId: id,
    occurrenceIndex: 1,
    targetDate: DateTime(2026, 4, 10),
    label: '第 1 天',
    status: TimelineMilestoneRecordStatus.noticed,
    reminderOffsetDays: 0,
    actedAt: DateTime(2026, 4, 10),
  );
}
