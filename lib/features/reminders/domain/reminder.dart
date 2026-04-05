class ReminderTrackingMode {
  static const int countdown = 1;
  static const int countUp = 2;
}

@Deprecated('Use ReminderTrackingMode instead.')
class ReminderTimeBasis {
  static const int countdown = ReminderTrackingMode.countdown;
  static const int countUp = ReminderTrackingMode.countUp;
}

class ReminderTriggerMode {
  static const int inRange = 1;
  static const int immediate = 2;
  static const int onPoint = 3;
}

@Deprecated('Use ReminderTriggerMode instead.')
class ReminderNotifyStrategy {
  static const int inRange = ReminderTriggerMode.inRange;
  static const int immediate = ReminderTriggerMode.immediate;
  static const int onPoint = ReminderTriggerMode.onPoint;
}

class ReminderStatus {
  static const int pending = 0;
  static const int done = 1;
  static const int skipped = 2;
  static const int canceled = 3;
}

class ReminderModel {
  const ReminderModel({
    required this.id,
    this.recurringReminderId,
    this.previousOccurrenceId,
    required this.trackingMode,
    required this.triggerMode,
    required this.status,
    required this.title,
    this.note,
    this.triggerOffsetDays,
    this.statusNote,
    this.dueAt,
    required this.startAt,
    this.deferredDueAt,
    this.topicCategoryId,
    this.actionCategoryId,
    this.topicCategoryName,
    this.actionCategoryName,
    this.repeatRule,
    required this.createdAt,
    required this.updatedAt,
  });

  final int id;
  final int? recurringReminderId;
  final int? previousOccurrenceId;
  final int trackingMode;
  final int triggerMode;
  final int status;
  final String title;
  final String? note;
  final int? triggerOffsetDays;
  final String? statusNote;
  final DateTime? dueAt;
  final DateTime startAt;
  final DateTime? deferredDueAt;
  final int? topicCategoryId;
  final int? actionCategoryId;
  final String? topicCategoryName;
  final String? actionCategoryName;
  final String? repeatRule;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get isPending => status == ReminderStatus.pending;
  bool get isDone => status == ReminderStatus.done;
  bool get isSkipped => status == ReminderStatus.skipped;
  bool get isCanceled => status == ReminderStatus.canceled;

  bool get isCountdown => trackingMode == ReminderTrackingMode.countdown;
  bool get isCountUp => trackingMode == ReminderTrackingMode.countUp;
  bool get isRecurring => recurringReminderId != null;

  String get trackingModeLabel => isCountdown ? '倒數式' : '起計式';

  @Deprecated('Use recurringReminderId instead.')
  int? get seriesId => recurringReminderId;

  @Deprecated('Use previousOccurrenceId instead.')
  int? get previousReminderId => previousOccurrenceId;

  @Deprecated('Use trackingMode instead.')
  int get timeBasis => trackingMode;

  @Deprecated('Use triggerMode instead.')
  int get notifyStrategy => triggerMode;

  @Deprecated('Use triggerOffsetDays instead.')
  int? get remindDays => triggerOffsetDays;

  @Deprecated('Use statusNote instead.')
  String? get remark => statusNote;

  @Deprecated('Use deferredDueAt instead.')
  DateTime? get extendAt => deferredDueAt;

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
