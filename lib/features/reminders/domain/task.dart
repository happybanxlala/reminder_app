enum TaskStatus { pending, done, skipped, canceled }

class Task {
  const Task({
    required this.id,
    required this.templateId,
    required this.titleSnapshot,
    required this.dueDate,
    this.deferredDueDate,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.resolvedAt,
    this.noteSnapshot,
    this.categoryId,
  });

  final int id;
  final int templateId;
  final String titleSnapshot;
  final DateTime dueDate;
  final DateTime? deferredDueDate;
  final TaskStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? resolvedAt;
  final String? noteSnapshot;
  final int? categoryId;

  DateTime get effectiveDueDate => deferredDueDate ?? dueDate;
  bool get isPending => status == TaskStatus.pending;
}
