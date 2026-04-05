class ReminderSeriesStatus {
  static const int pending = 0;
  static const int stopped = 1;
  static const int canceled = 2;
}

class ReminderSeriesModel {
  const ReminderSeriesModel({
    required this.id,
    required this.status,
    required this.title,
    this.note,
    required this.timeBasis,
    required this.notifyStrategy,
    this.remindDays,
    this.repeatRule,
    this.issueTypeId,
    this.handleTypeId,
    required this.createdAt,
    required this.updatedAt,
  });

  final int id;
  final int status;
  final String title;
  final String? note;
  final int timeBasis;
  final int notifyStrategy;
  final int? remindDays;
  final String? repeatRule;
  final int? issueTypeId;
  final int? handleTypeId;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get isPending => status == ReminderSeriesStatus.pending;
}
