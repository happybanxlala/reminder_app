import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reminder_app/features/reminders/data/local/app_database.dart';
import 'package:reminder_app/features/reminders/data/local/item_timeline_dao.dart';
import 'package:reminder_app/features/reminders/data/item_repository.dart';
import 'package:reminder_app/features/reminders/data/timeline_models.dart';
import 'package:reminder_app/features/reminders/domain/item.dart';
import 'package:reminder_app/features/reminders/domain/item_pack.dart';
import 'package:reminder_app/features/reminders/domain/timeline.dart';
import 'package:reminder_app/features/reminders/domain/timeline_milestone_occurrence.dart';
import 'package:reminder_app/features/reminders/domain/timeline_milestone_record.dart';
import 'package:reminder_app/features/reminders/domain/timeline_milestone_rule.dart';
import 'package:reminder_app/features/reminders/presentation/text/reminder_ui_text.dart';
import 'package:reminder_app/features/reminders/providers/item_providers.dart';
import 'package:reminder_app/features/reminders/providers/timeline_providers.dart';
import 'package:reminder_app/features/reminders/ui/pages/management_page.dart';

void main() {
  testWidgets('management page groups items by pack', (tester) async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          itemRepositoryProvider.overrideWith(
            (ref) => ItemRepository(db.itemTimelineDao),
          ),
          activeItemPacksProvider.overrideWith(
            (ref) => Stream.value([
              _pack(1, title: 'Default Item Pack', isSystemDefault: true),
              _pack(2, title: 'Cat Care'),
            ]),
          ),
          itemsProvider.overrideWith(
            (ref) => Stream.value([
              _itemBundle(1, ItemType.stateBased),
              _itemBundle(
                2,
                ItemType.resourceBased,
                packId: 2,
                packTitle: 'Cat Care',
              ),
            ]),
          ),
          timelinesProvider.overrideWith(
            (ref) => Stream.value([
              Timeline(
                id: 9,
                title: 'No sugar',
                startDate: DateTime(2026, 4, 10),
                displayUnit: TimelineDisplayUnit.day,
                status: TimelineStatus.active,
                createdAt: DateTime(2026, 4, 1),
                updatedAt: DateTime(2026, 4, 1),
              ),
              Timeline(
                id: 10,
                title: 'No late coffee',
                startDate: DateTime(2026, 4, 10),
                displayUnit: TimelineDisplayUnit.week,
                status: TimelineStatus.archived,
                createdAt: DateTime(2026, 4, 1),
                updatedAt: DateTime(2026, 4, 1),
              ),
            ]),
          ),
          timelineDetailProvider(9).overrideWith(
            (ref) => Future.value(
              TimelineDetail(
                timeline: Timeline(
                  id: 9,
                  title: 'No sugar',
                  startDate: DateTime(2026, 4, 10),
                  displayUnit: TimelineDisplayUnit.day,
                  status: TimelineStatus.active,
                  createdAt: DateTime(2026, 4, 1),
                  updatedAt: DateTime(2026, 4, 1),
                ),
                milestoneRuleDetails: [
                  TimelineMilestoneRuleDetail(
                    rule: _rule(92, TimelineMilestoneRuleStatus.active),
                    nextMilestone: TimelineMilestoneOccurrence(
                      timelineId: 9,
                      timelineTitle: 'No sugar',
                      ruleId: 92,
                      occurrenceIndex: 1,
                      targetDate: DateTime(2026, 4, 20),
                      label: '第 10天',
                      status: TimelineMilestoneRecordStatus.upcoming,
                      reminderOffsetDays: 0,
                    ),
                    historyRecords: const [],
                  ),
                  TimelineMilestoneRuleDetail(
                    rule: _rule(91, TimelineMilestoneRuleStatus.active),
                    nextMilestone: TimelineMilestoneOccurrence(
                      timelineId: 9,
                      timelineTitle: 'No sugar',
                      ruleId: 91,
                      occurrenceIndex: 1,
                      targetDate: DateTime(2026, 5, 10),
                      label: '第 30天',
                      status: TimelineMilestoneRecordStatus.upcoming,
                      reminderOffsetDays: 0,
                    ),
                    historyRecords: const [],
                  ),
                ],
                upcomingMilestones: [
                  TimelineMilestoneOccurrence(
                    timelineId: 9,
                    timelineTitle: 'No sugar',
                    ruleId: 92,
                    occurrenceIndex: 1,
                    targetDate: DateTime(2026, 4, 20),
                    label: '第 10天',
                    status: TimelineMilestoneRecordStatus.upcoming,
                    reminderOffsetDays: 0,
                  ),
                  TimelineMilestoneOccurrence(
                    timelineId: 9,
                    timelineTitle: 'No sugar',
                    ruleId: 91,
                    occurrenceIndex: 1,
                    targetDate: DateTime(2026, 5, 10),
                    label: '第 30天',
                    status: TimelineMilestoneRecordStatus.upcoming,
                    reminderOffsetDays: 0,
                  ),
                  TimelineMilestoneOccurrence(
                    timelineId: 9,
                    timelineTitle: 'No sugar',
                    ruleId: 91,
                    occurrenceIndex: 2,
                    targetDate: DateTime(2026, 6, 9),
                    label: '第 60天',
                    status: TimelineMilestoneRecordStatus.upcoming,
                    reminderOffsetDays: 0,
                  ),
                ],
                milestoneHistory: const [],
              ),
            ),
          ),
          timelineDetailProvider(10).overrideWith(
            (ref) => Future.value(
              TimelineDetail(
                timeline: Timeline(
                  id: 10,
                  title: 'No late coffee',
                  startDate: DateTime(2026, 4, 10),
                  displayUnit: TimelineDisplayUnit.week,
                  status: TimelineStatus.archived,
                  createdAt: DateTime(2026, 4, 1),
                  updatedAt: DateTime(2026, 4, 1),
                ),
                milestoneRuleDetails: const [],
                upcomingMilestones: const [],
                milestoneHistory: const [],
              ),
            ),
          ),
        ],
        child: const MaterialApp(home: ManagementPage()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('add-pack-button')), findsOneWidget);
    expect(find.byKey(const Key('pack-section-1')), findsOneWidget);
    expect(find.byKey(const Key('pack-section-2')), findsOneWidget);
    expect(find.byKey(const Key('pack-system-default-1')), findsOneWidget);
    expect(find.byKey(const Key('pack-edit-2')), findsOneWidget);
    expect(find.byKey(const Key('pack-archive-2')), findsOneWidget);
    expect(find.byKey(const Key('item-edit-1')), findsOneWidget);
    expect(find.byKey(const Key('item-done-1')), findsOneWidget);
    expect(find.byKey(const Key('item-edit-2')), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('No sugar', skipOffstage: false),
      200,
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('timeline-edit-9')), findsOneWidget);
    expect(find.byKey(const Key('timeline-history-9')), findsOneWidget);
    expect(find.byKey(const Key('timeline-rule-9-92')), findsOneWidget);
    expect(find.byKey(const Key('timeline-rule-9-91')), findsOneWidget);
    expect(find.byKey(const Key('timeline-upcoming-9-92')), findsOneWidget);
    expect(find.byKey(const Key('timeline-upcoming-9-91')), findsOneWidget);
    expect(find.text('每 10 天'), findsOneWidget);
    expect(find.text('每 30 天'), findsOneWidget);
    expect(find.text('第 10天'), findsOneWidget);
    expect(find.text('2026/04/20'), findsOneWidget);
    expect(find.text('第 30天'), findsOneWidget);
    expect(find.text('2026/05/10'), findsOneWidget);
    expect(find.text('第 60天'), findsNothing);

    expect(find.byKey(const Key('timeline-edit-10')), findsNothing);
    expect(find.byKey(const Key('timeline-history-10')), findsOneWidget);
    expect(find.text('目前沒有 upcoming milestone。'), findsOneWidget);
  });

  testWidgets('management page adds pack and blocks archiving non-empty pack', (
    tester,
  ) async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final repository = ItemRepository(db.itemTimelineDao);

    final choresPackId = await repository.createPack(
      const ItemPackInput(
        title: 'Cat Care',
        description: 'Feeding and cleanup',
      ),
    );
    await repository.createItem(
      ItemInput(
        title: 'Clean litter box',
        type: ItemType.stateBased,
        config: const StateBasedItemConfig(
          expectedInterval: Duration(days: 2),
          warningAfter: Duration(days: 2),
          dangerAfter: Duration(days: 4),
        ),
        packId: choresPackId,
      ),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          itemRepositoryProvider.overrideWith((ref) => repository),
          activeItemPacksProvider.overrideWith(
            (ref) => Stream.value([
              _pack(1, title: 'Default Item Pack', isSystemDefault: true),
              _pack(choresPackId, title: 'Cat Care'),
            ]),
          ),
          itemsProvider.overrideWith(
            (ref) => Stream.value([
              _itemBundle(
                1,
                ItemType.stateBased,
                packId: choresPackId,
                packTitle: 'Cat Care',
              ),
            ]),
          ),
          timelinesProvider.overrideWith((ref) => Stream.value(const [])),
        ],
        child: const MaterialApp(home: ManagementPage()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Cat Care'), findsOneWidget);
    await tester.tap(find.byKey(Key('pack-archive-$choresPackId')));
    await tester.pumpAndSettle();

    expect(find.text(ReminderUiText.packArchiveBlockedMessage), findsOneWidget);

    await tester.tap(find.byKey(const Key('add-pack-button')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('pack-title-field')), 'Health');
    await tester.enterText(
      find.byKey(const Key('pack-description-field')),
      'Vet and medication',
    );
    await tester.tap(find.byKey(const Key('pack-save-button')));
    await tester.pumpAndSettle();

    final packs = await db.select(db.itemPacks).get();
    expect(packs.any((item) => item.title == 'Health'), isTrue);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });
}

ItemBundle _itemBundle(
  int id,
  ItemType type, {
  int packId = 1,
  String packTitle = 'Default Item Pack',
}) {
  final config = switch (type) {
    ItemType.stateBased => const StateBasedItemConfig(
      expectedInterval: Duration(days: 7),
      warningAfter: Duration(days: 7),
      dangerAfter: Duration(days: 14),
    ),
    ItemType.resourceBased => const ResourceBasedItemConfig(
      estimatedDuration: Duration(days: 30),
      warningBeforeDepletion: Duration(days: 7),
    ),
    ItemType.fixedTime => FixedTimeItemConfig(
      scheduleType: FixedTimeScheduleType.daily,
      anchorDate: DateTime(2026, 4, 10),
    ),
  };
  return ItemBundle(
    item: Item(
      id: id,
      packId: packId,
      title: 'Item $id',
      type: type,
      config: config,
      lastDoneAt: DateTime(2026, 4, 10),
      createdAt: DateTime(2026, 4, 1),
      updatedAt: DateTime(2026, 4, 1),
    ),
    pack: _pack(packId, title: packTitle, isSystemDefault: packId == 1),
  );
}

ItemPack _pack(int id, {required String title, bool isSystemDefault = false}) {
  return ItemPack(
    id: id,
    title: title,
    status: ItemPackStatus.active,
    isSystemDefault: isSystemDefault,
    createdAt: DateTime(2026, 4, 1),
    updatedAt: DateTime(2026, 4, 1),
  );
}

TimelineMilestoneRule _rule(int id, TimelineMilestoneRuleStatus status) {
  return TimelineMilestoneRule(
    id: id,
    timelineId: 9,
    type: TimelineMilestoneRuleType.everyNDays,
    intervalValue: id == 92 ? 10 : 30,
    intervalUnit: TimelineMilestoneIntervalUnit.days,
    labelTemplate: '第 {value}{unit}',
    reminderOffsetDays: 0,
    status: status,
    createdAt: DateTime(2026, 4, 1),
    updatedAt: DateTime(2026, 4, 1),
  );
}
