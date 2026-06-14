enum HomeWidgetEntryType {
  itemAttention('itemAttention'),
  resourceAttention('resourceAttention'),
  completedItem('completedItem'),
  completedResource('completedResource'),
  completedStage('completedStage');

  const HomeWidgetEntryType(this.wireName);

  final String wireName;

  static HomeWidgetEntryType? tryParse(String? value) {
    for (final type in HomeWidgetEntryType.values) {
      if (type.wireName == value) {
        return type;
      }
    }
    return null;
  }
}

enum HomeWidgetEntryAction {
  complete('complete'),
  undo('undo');

  const HomeWidgetEntryAction(this.wireName);

  final String wireName;

  static HomeWidgetEntryAction? tryParse(String? value) {
    for (final action in HomeWidgetEntryAction.values) {
      if (action.wireName == value) {
        return action;
      }
    }
    return null;
  }
}

class HomeWidgetEntry {
  const HomeWidgetEntry({
    required this.entryId,
    required this.type,
    this.targetId,
    this.actionRecordId,
    required this.title,
    required this.statusText,
    this.buttonText,
    this.action,
    required this.canAct,
  });

  factory HomeWidgetEntry.fromJson(Map<String, Object?> json) {
    return HomeWidgetEntry(
      entryId: json['entryId'] as String? ?? '',
      type:
          HomeWidgetEntryType.tryParse(json['type'] as String?) ??
          HomeWidgetEntryType.itemAttention,
      targetId: json['targetId'] as int?,
      actionRecordId: json['actionRecordId'] as int?,
      title: json['title'] as String? ?? '',
      statusText: json['statusText'] as String? ?? '',
      buttonText: json['buttonText'] as String?,
      action: HomeWidgetEntryAction.tryParse(json['action'] as String?),
      canAct: json['canAct'] as bool? ?? false,
    );
  }

  final String entryId;
  final HomeWidgetEntryType type;
  final int? targetId;
  final int? actionRecordId;
  final String title;
  final String statusText;
  final String? buttonText;
  final HomeWidgetEntryAction? action;
  final bool canAct;

  Map<String, Object?> toJson() {
    return {
      'entryId': entryId,
      'type': type.wireName,
      'targetId': targetId,
      'actionRecordId': actionRecordId,
      'title': title,
      'statusText': statusText,
      'buttonText': buttonText,
      'action': action?.wireName,
      'canAct': canAct,
    };
  }
}
