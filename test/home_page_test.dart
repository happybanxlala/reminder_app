import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reminder_app/features/reminders/data/home_models.dart';
import 'package:reminder_app/features/reminders/data/local/item_timeline_dao.dart';
import 'package:reminder_app/features/reminders/domain/item.dart';
import 'package:reminder_app/features/reminders/domain/item_pack.dart';
import 'package:reminder_app/features/reminders/domain/timeline_milestone_occurrence.dart';
import 'package:reminder_app/features/reminders/domain/timeline_milestone_record.dart';
import 'package:reminder_app/features/reminders/domain/timeline_milestone_rule.dart';
import 'package:reminder_app/features/reminders/domain/timeline.dart';
import 'package:reminder_app/features/reminders/providers/history_providers.dart';
import 'package:reminder_app/features/reminders/providers/home_providers.dart';
import 'package:reminder_app/features/reminders/ui/pages/history_page.dart';
import 'package:reminder_app/features/reminders/ui/pages/home_page.dart';

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

  testWidgets('history page shows item note and paginated milestone section', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          milestoneHistoryProvider.overrideWith(
            (ref) => Stream.value(
              List.generate(
                11,
                (index) => _milestoneRecordBundle(title: 'Timeline $index'),
              ),
            ),
          ),
        ],
        child: const MaterialApp(home: HistoryPage()),
      ),
    );
    await tester.pump();

    expect(find.text('Item History'), findsOneWidget);
    expect(find.textContaining('不保留 item completion history'), findsOneWidget);
    expect(find.text('Milestone History'), findsOneWidget);
    expect(find.text('Timeline 0'), findsOneWidget);
    expect(find.text('Timeline 10'), findsNothing);

    await tester.ensureVisible(find.byKey(const Key('milestone-history-next')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('milestone-history-next')));
    await tester.pumpAndSettle();

    expect(find.text('Timeline 10'), findsOneWidget);
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

TimelineMilestoneRecordBundle _milestoneRecordBundle({required String title}) {
  final id = title.hashCode;
  return TimelineMilestoneRecordBundle(
    record: TimelineMilestoneRecord(
      id: id,
      timelineId: id,
      ruleId: id,
      occurrenceIndex: 1,
      targetDate: DateTime(2026, 4, 10),
      status: TimelineMilestoneRecordStatus.noticed,
      actedAt: DateTime(2026, 4, 10),
      createdAt: DateTime(2026, 4, 1),
      updatedAt: DateTime(2026, 4, 1),
    ),
    rule: TimelineMilestoneRule(
      id: id,
      timelineId: id,
      type: TimelineMilestoneRuleType.everyNDays,
      intervalValue: 30,
      intervalUnit: TimelineMilestoneIntervalUnit.days,
      labelTemplate: '第 {n} 個 30 天',
      reminderOffsetDays: 0,
      status: TimelineMilestoneRuleStatus.active,
      createdAt: DateTime(2026, 4, 1),
      updatedAt: DateTime(2026, 4, 1),
    ),
    timeline: Timeline(
      id: id,
      title: title,
      startDate: DateTime(2026, 4, 1),
      displayUnit: TimelineDisplayUnit.day,
      status: TimelineStatus.active,
      createdAt: DateTime(2026, 4, 1),
      updatedAt: DateTime(2026, 4, 1),
    ),
  );
}
