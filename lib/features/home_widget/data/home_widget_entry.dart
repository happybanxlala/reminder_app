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

enum HomeWidgetEntrySyncStatus {
  none('none'),
  pending('pending'),
  failed('failed'),
  stale('stale'),
  accessLost('accessLost');

  const HomeWidgetEntrySyncStatus(this.wireName);

  final String wireName;

  static HomeWidgetEntrySyncStatus tryParse(String? value) {
    for (final status in HomeWidgetEntrySyncStatus.values) {
      if (status.wireName == value) {
        return status;
      }
    }
    return HomeWidgetEntrySyncStatus.none;
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
    this.displayIcon,
    this.buttonText,
    this.action,
    required this.canAct,
    this.isRemoteBacked = false,
    this.syncLabel,
    this.syncStatus = HomeWidgetEntrySyncStatus.none,
    this.hasPendingMutation = false,
    this.pendingAction,
    this.actionDisabledReason,
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
      displayIcon: json['displayIcon'] as String?,
      buttonText: json['buttonText'] as String?,
      action: HomeWidgetEntryAction.tryParse(json['action'] as String?),
      canAct: json['canAct'] as bool? ?? false,
      isRemoteBacked: json['isRemoteBacked'] as bool? ?? false,
      syncLabel: json['syncLabel'] as String?,
      syncStatus: HomeWidgetEntrySyncStatus.tryParse(
        json['syncStatus'] as String?,
      ),
      hasPendingMutation: json['hasPendingMutation'] as bool? ?? false,
      pendingAction: json['pendingAction'] as String?,
      actionDisabledReason: json['actionDisabledReason'] as String?,
    );
  }

  final String entryId;
  final HomeWidgetEntryType type;
  final int? targetId;
  final int? actionRecordId;
  final String title;
  final String statusText;
  final String? displayIcon;
  final String? buttonText;
  final HomeWidgetEntryAction? action;
  final bool canAct;
  final bool isRemoteBacked;
  final String? syncLabel;
  final HomeWidgetEntrySyncStatus syncStatus;
  final bool hasPendingMutation;
  final String? pendingAction;
  final String? actionDisabledReason;

  Map<String, Object?> toJson() {
    return {
      'entryId': entryId,
      'type': type.wireName,
      'targetId': targetId,
      'actionRecordId': actionRecordId,
      'title': title,
      'statusText': statusText,
      'displayIcon': displayIcon,
      'buttonText': buttonText,
      'action': action?.wireName,
      'canAct': canAct,
      'isRemoteBacked': isRemoteBacked,
      'syncLabel': syncLabel,
      'syncStatus': syncStatus.wireName,
      'hasPendingMutation': hasPendingMutation,
      'pendingAction': pendingAction,
      'actionDisabledReason': actionDisabledReason,
    };
  }
}
