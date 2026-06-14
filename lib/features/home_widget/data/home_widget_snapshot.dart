import 'dart:convert';

import 'home_widget_entry.dart';
import 'home_widget_tab.dart';

class HomeWidgetSnapshot {
  const HomeWidgetSnapshot({
    required this.schemaVersion,
    required this.updatedAt,
    required this.selectedTab,
    required this.tabs,
  });

  factory HomeWidgetSnapshot.fromJson(Map<String, Object?> json) {
    final tabsJson = json['tabs'];
    return HomeWidgetSnapshot(
      schemaVersion: json['schemaVersion'] as int? ?? currentSchemaVersion,
      updatedAt:
          DateTime.tryParse(json['updatedAt'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      selectedTab: HomeWidgetTabId.parse(json['selectedTab'] as String?),
      tabs: tabsJson is List
          ? tabsJson
                .whereType<Map>()
                .map(
                  (tab) =>
                      HomeWidgetTab.fromJson(Map<String, Object?>.from(tab)),
                )
                .toList(growable: false)
          : const <HomeWidgetTab>[],
    );
  }

  factory HomeWidgetSnapshot.fromJsonString(String source) {
    final decoded = jsonDecode(source);
    if (decoded is! Map<String, Object?>) {
      throw const FormatException(
        'Home widget snapshot must be a JSON object.',
      );
    }
    return HomeWidgetSnapshot.fromJson(decoded);
  }

  static const currentSchemaVersion = 1;

  final int schemaVersion;
  final DateTime updatedAt;
  final HomeWidgetTabId selectedTab;
  final List<HomeWidgetTab> tabs;

  HomeWidgetSnapshot copyWith({
    int? schemaVersion,
    DateTime? updatedAt,
    HomeWidgetTabId? selectedTab,
    List<HomeWidgetTab>? tabs,
  }) {
    return HomeWidgetSnapshot(
      schemaVersion: schemaVersion ?? this.schemaVersion,
      updatedAt: updatedAt ?? this.updatedAt,
      selectedTab: selectedTab ?? this.selectedTab,
      tabs: tabs ?? this.tabs,
    );
  }

  Map<String, Object?> toJson() {
    return {
      'schemaVersion': schemaVersion,
      'updatedAt': updatedAt.toIso8601String(),
      'selectedTab': selectedTab.wireName,
      'tabs': tabs.map((tab) => tab.toJson()).toList(growable: false),
    };
  }

  String toJsonString() => jsonEncode(toJson());

  HomeWidgetEntry? findEntry(String entryId) {
    for (final tab in tabs) {
      for (final entry in tab.entries) {
        if (entry.entryId == entryId) {
          return entry;
        }
      }
    }
    return null;
  }
}
