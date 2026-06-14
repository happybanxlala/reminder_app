import 'home_widget_entry.dart';

enum HomeWidgetTabId {
  needsHandling('needsHandling', '需要處理'),
  attention('attention', '要留意'),
  todayCompleted('todayCompleted', '今天已完成');

  const HomeWidgetTabId(this.wireName, this.label);

  final String wireName;
  final String label;

  static HomeWidgetTabId? tryParse(String? value) {
    for (final tab in HomeWidgetTabId.values) {
      if (tab.wireName == value) {
        return tab;
      }
    }
    return null;
  }

  static HomeWidgetTabId parse(String? value) {
    return tryParse(value) ?? HomeWidgetTabId.needsHandling;
  }
}

class HomeWidgetTab {
  const HomeWidgetTab({
    required this.id,
    required this.label,
    required this.count,
    required this.entries,
  });

  factory HomeWidgetTab.fromJson(Map<String, Object?> json) {
    final id = HomeWidgetTabId.parse(json['id'] as String?);
    final entriesJson = json['entries'];
    return HomeWidgetTab(
      id: id,
      label: json['label'] as String? ?? id.label,
      count: json['count'] as int? ?? 0,
      entries: entriesJson is List
          ? entriesJson
                .whereType<Map>()
                .map(
                  (entry) => HomeWidgetEntry.fromJson(
                    Map<String, Object?>.from(entry),
                  ),
                )
                .toList(growable: false)
          : const <HomeWidgetEntry>[],
    );
  }

  final HomeWidgetTabId id;
  final String label;
  final int count;
  final List<HomeWidgetEntry> entries;

  Map<String, Object?> toJson() {
    return {
      'id': id.wireName,
      'label': label,
      'count': count,
      'entries': entries.map((entry) => entry.toJson()).toList(growable: false),
    };
  }
}
