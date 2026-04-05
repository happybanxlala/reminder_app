class ReminderTimeBasis {
  static const int countdown = 1;
  static const int countUp = 2;
}

class ReminderNotifyStrategy {
  static const int inRange = 1;
  static const int immediate = 2;
  static const int onPoint = 3;
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
    this.seriesId,
    this.previousReminderId,
    required this.timeBasis,
    required this.notifyStrategy,
    required this.status,
    required this.title,
    this.note,
    this.remindDays,
    this.remark,
    this.dueAt,
    required this.startAt,
    this.extendAt,
    this.issueTypeId,
    this.handleTypeId,
    this.issueTypeName,
    this.handleTypeName,
    this.repeatRule,
    required this.createdAt,
    required this.updatedAt,
  });

  final int id;
  final int? seriesId;
  final int? previousReminderId;
  final int timeBasis;
  final int notifyStrategy;
  final int status;
  final String title;
  final String? note;
  final int? remindDays;
  final String? remark;
  final DateTime? dueAt;
  final DateTime startAt;
  final DateTime? extendAt;
  final int? issueTypeId;
  final int? handleTypeId;
  final String? issueTypeName;
  final String? handleTypeName;
  final String? repeatRule;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get isPending => status == ReminderStatus.pending;
  bool get isDone => status == ReminderStatus.done;
  bool get isSkipped => status == ReminderStatus.skipped;
  bool get isCanceled => status == ReminderStatus.canceled;

  bool get isCountdown => timeBasis == ReminderTimeBasis.countdown;
  bool get isCountUp => timeBasis == ReminderTimeBasis.countUp;
  bool get isRecurring => seriesId != null;

  String get timeBasisLabel => isCountdown ? '倒數式' : '起計式';

  String? get categoryLabel {
    if (issueTypeName == null && handleTypeName == null) {
      return null;
    }
    if (issueTypeName != null && handleTypeName != null) {
      return '$issueTypeName / $handleTypeName';
    }
    return issueTypeName ?? handleTypeName;
  }
}
