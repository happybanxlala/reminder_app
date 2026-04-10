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
}
