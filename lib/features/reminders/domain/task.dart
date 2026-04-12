import 'reminder_rule.dart';
import 'repeat_rule.dart';
import 'task_template.dart';

enum TaskStatus { pending, done, skipped, canceled }

class Task {
  const Task({
    required this.id,
    required this.templateId,
    required this.kind,
    required this.titleSnapshot,
    required this.dueDate,
    required this.reminderRule,
    this.deferredDueDate,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.resolvedAt,
    this.repeatRule,
    this.noteSnapshot,
    this.categoryId,
  });

  final int id;
  final int? templateId;
  final TaskKind kind;
  final String titleSnapshot;
  final DateTime dueDate;
  final ReminderRule reminderRule;
  final DateTime? deferredDueDate;
  final TaskStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? resolvedAt;
  final RepeatRule? repeatRule;
  final String? noteSnapshot;
  final int? categoryId;

  DateTime get effectiveDueDate => deferredDueDate ?? dueDate;
  bool get isPending => status == TaskStatus.pending;
  bool get isRecurring => kind == TaskKind.recurring;
}
