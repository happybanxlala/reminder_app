class ReminderModel {
  const ReminderModel({
    required this.id,
    required this.startId,
    required this.title,
    this.note,
    required this.remindDays,
    this.dueAt,
    this.repeatRule,
    required this.status,
    this.extendAt,
    required this.createdAt,
    required this.updatedAt,
  });

  final int id;
  final int startId;
  final String title;
  final String? note;
  final int remindDays;
  final DateTime? dueAt;
  final String? repeatRule;
  final int status;
  final DateTime? extendAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get isPending => status == 0;
  bool get isDone => status == 1;
  bool get isSkipped => status == 2;
  bool get isCanceled => status == 3;
}
