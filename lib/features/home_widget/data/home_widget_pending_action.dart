enum HomeWidgetPendingActionKind {
  complete('complete'),
  undo('undo');

  const HomeWidgetPendingActionKind(this.wireName);

  final String wireName;

  static HomeWidgetPendingActionKind? tryParse(String? value) {
    for (final action in HomeWidgetPendingActionKind.values) {
      if (action.wireName == value) {
        return action;
      }
    }
    return null;
  }
}

enum HomeWidgetPendingActionSource {
  android('android'),
  ios('ios'),
  unknown('unknown');

  const HomeWidgetPendingActionSource(this.wireName);

  final String wireName;

  static HomeWidgetPendingActionSource tryParse(String? value) {
    for (final source in HomeWidgetPendingActionSource.values) {
      if (source.wireName == value) {
        return source;
      }
    }
    return HomeWidgetPendingActionSource.unknown;
  }
}

class HomeWidgetPendingAction {
  const HomeWidgetPendingAction({
    required this.rawAction,
    required this.entryId,
    required this.sourcePlatform,
    this.createdAt,
    this.nonce,
  });

  factory HomeWidgetPendingAction.fromJson(Map<Object?, Object?> json) {
    return HomeWidgetPendingAction(
      rawAction: json['action'] as String? ?? '',
      entryId: json['entryId'] as String? ?? '',
      sourcePlatform: HomeWidgetPendingActionSource.tryParse(
        json['sourcePlatform'] as String?,
      ),
      createdAt: _parseCreatedAt(json['createdAt']),
      nonce: json['nonce'] as String?,
    );
  }

  final String rawAction;
  final String entryId;
  final HomeWidgetPendingActionSource sourcePlatform;
  final DateTime? createdAt;
  final String? nonce;

  HomeWidgetPendingActionKind? get action =>
      HomeWidgetPendingActionKind.tryParse(rawAction);

  bool get hasValidEntryId => entryId.trim().isNotEmpty;

  bool get isValid => action != null && hasValidEntryId;

  String get duplicateKey {
    final normalizedNonce = nonce?.trim();
    if (normalizedNonce != null && normalizedNonce.isNotEmpty) {
      return '${sourcePlatform.wireName}:$normalizedNonce';
    }
    final timestamp = createdAt?.millisecondsSinceEpoch.toString() ?? '';
    return '${sourcePlatform.wireName}:$rawAction:${entryId.trim()}:$timestamp';
  }

  static DateTime? _parseCreatedAt(Object? value) {
    if (value is int) {
      return DateTime.fromMillisecondsSinceEpoch(value);
    }
    if (value is double) {
      return DateTime.fromMillisecondsSinceEpoch(value.round());
    }
    if (value is String && value.isNotEmpty) {
      return DateTime.tryParse(value);
    }
    return null;
  }
}
