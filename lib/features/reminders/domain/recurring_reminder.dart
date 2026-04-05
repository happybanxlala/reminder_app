class RecurringReminderStatus {
  static const int pending = 0;
  static const int stopped = 1;
  static const int canceled = 2;
}

class RecurringReminderModel {
  const RecurringReminderModel({
    required this.id,
    required this.status,
    required this.title,
    this.note,
    required this.trackingMode,
    required this.triggerMode,
    this.triggerOffsetDays,
    this.repeatRule,
    this.topicCategoryId,
    this.actionCategoryId,
    this.topicCategoryName,
    this.actionCategoryName,
    required this.createdAt,
    required this.updatedAt,
  });

  final int id;
  final int status;
  final String title;
  final String? note;
  final int trackingMode;
  final int triggerMode;
  final int? triggerOffsetDays;
  final String? repeatRule;
  final int? topicCategoryId;
  final int? actionCategoryId;
  final String? topicCategoryName;
  final String? actionCategoryName;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get isPending => status == RecurringReminderStatus.pending;
  bool get isStopped => status == RecurringReminderStatus.stopped;
  bool get isCanceled => status == RecurringReminderStatus.canceled;

  String get trackingModeLabel => trackingMode == 1 ? '倒數式' : '起計式';

  @Deprecated('Use trackingMode instead.')
  int get timeBasis => trackingMode;

  @Deprecated('Use triggerMode instead.')
  int get notifyStrategy => triggerMode;

  @Deprecated('Use triggerOffsetDays instead.')
  int? get remindDays => triggerOffsetDays;

  @Deprecated('Use topicCategoryId instead.')
  int? get issueTypeId => topicCategoryId;

  @Deprecated('Use actionCategoryId instead.')
  int? get handleTypeId => actionCategoryId;

  @Deprecated('Use topicCategoryName instead.')
  String? get issueTypeName => topicCategoryName;

  @Deprecated('Use actionCategoryName instead.')
  String? get handleTypeName => actionCategoryName;

  @Deprecated('Use trackingModeLabel instead.')
  String get timeBasisLabel => trackingModeLabel;

  String get statusLabel {
    switch (status) {
      case RecurringReminderStatus.pending:
        return '進行中';
      case RecurringReminderStatus.stopped:
        return '已停止';
      case RecurringReminderStatus.canceled:
        return '已取消';
      default:
        return '未知狀態';
    }
  }

  String? get categoryLabel {
    if (topicCategoryName == null && actionCategoryName == null) {
      return null;
    }
    if (topicCategoryName != null && actionCategoryName != null) {
      return '$topicCategoryName / $actionCategoryName';
    }
    return topicCategoryName ?? actionCategoryName;
  }
}
