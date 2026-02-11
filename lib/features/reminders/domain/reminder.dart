class Reminder {
  const Reminder({
    required this.id,
    required this.title,
    this.note,
    this.dueAt,
    this.isCompleted = false,
  });

  final String id;
  final String title;
  final String? note;
  final DateTime? dueAt;
  final bool isCompleted;

  Reminder copyWith({
    String? id,
    String? title,
    String? note,
    DateTime? dueAt,
    bool? isCompleted,
  }) {
    return Reminder(
      id: id ?? this.id,
      title: title ?? this.title,
      note: note ?? this.note,
      dueAt: dueAt ?? this.dueAt,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}
