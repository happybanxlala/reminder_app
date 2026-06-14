import 'package:flutter_test/flutter_test.dart';
import 'package:reminder_app/features/home_widget/data/home_widget_entry.dart';
import 'package:reminder_app/features/home_widget/data/home_widget_snapshot.dart';
import 'package:reminder_app/features/home_widget/data/home_widget_tab.dart';

void main() {
  test('snapshot JSON round trip preserves tabs entries and actions', () {
    final snapshot = HomeWidgetSnapshot(
      schemaVersion: HomeWidgetSnapshot.currentSchemaVersion,
      updatedAt: DateTime(2026, 6, 10, 9, 30),
      selectedTab: HomeWidgetTabId.attention,
      tabs: [
        HomeWidgetTab(
          id: HomeWidgetTabId.attention,
          label: HomeWidgetTabId.attention.label,
          count: 1,
          entries: const [
            HomeWidgetEntry(
              entryId: 'item-7',
              type: HomeWidgetEntryType.itemAttention,
              targetId: 7,
              title: 'Clean bowl',
              statusText: '已持續2日',
              displayIcon: '🐱',
              buttonText: '完成',
              action: HomeWidgetEntryAction.complete,
              canAct: true,
            ),
          ],
        ),
      ],
    );

    final decoded = HomeWidgetSnapshot.fromJsonString(snapshot.toJsonString());

    expect(decoded.schemaVersion, HomeWidgetSnapshot.currentSchemaVersion);
    expect(decoded.updatedAt, DateTime(2026, 6, 10, 9, 30));
    expect(decoded.selectedTab, HomeWidgetTabId.attention);
    expect(decoded.tabs.single.count, 1);
    expect(decoded.tabs.single.entries.single.entryId, 'item-7');
    expect(decoded.tabs.single.entries.single.displayIcon, '🐱');
    expect(
      decoded.tabs.single.entries.single.action,
      HomeWidgetEntryAction.complete,
    );
  });

  test('selected tab parsing falls back to a safe known tab', () {
    final snapshot = HomeWidgetSnapshot.fromJson({
      'schemaVersion': 1,
      'updatedAt': '2026-06-10T09:30:00.000',
      'selectedTab': 'unknownFutureTab',
      'futureField': 'ignored',
      'tabs': const <Object?>[],
    });

    expect(snapshot.selectedTab, HomeWidgetTabId.needsHandling);
  });

  test('unknown row protocol values are non-actionable after decoding', () {
    final snapshot = HomeWidgetSnapshot.fromJson({
      'schemaVersion': 1,
      'updatedAt': '2026-06-10T09:30:00.000',
      'selectedTab': 'needsHandling',
      'tabs': [
        {
          'id': 'needsHandling',
          'label': '需要處理',
          'count': 1,
          'futureField': 'ignored',
          'entries': [
            {
              'entryId': 'future-1',
              'type': 'futureType',
              'title': 'Future row',
              'statusText': 'Future status',
              'action': 'futureAction',
              'canAct': true,
            },
          ],
        },
      ],
    });

    final entry = snapshot.tabs.single.entries.single;
    expect(entry.type, HomeWidgetEntryType.itemAttention);
    expect(entry.action, isNull);
  });
}
