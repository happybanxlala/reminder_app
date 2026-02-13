class ReminderModel {
  const ReminderModel({
    required this.id,
    required this.startId,
    required this.title,
    this.note,
    required this.remindDays,
    this.dueAt,
    this.repeatRule,
    required this.isDone,
    this.extendAt,
    required this.isCanceled,
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
  final int isDone;
  final DateTime? extendAt;
  final bool isCanceled;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get isPending => isDone == 0 && !isCanceled;
}
