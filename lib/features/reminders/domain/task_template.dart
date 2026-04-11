import 'reminder_rule.dart';
import 'repeat_rule.dart';

enum TaskKind { oneTime, recurring }

enum TaskTemplateStatus { active, paused, archived }

class TaskTemplate {
  const TaskTemplate({
    required this.id,
    required this.title,
    this.categoryId,
    this.note,
    required this.kind,
    required this.status,
    required this.firstDueDate,
    this.repeatRule,
    required this.reminderRule,
    required this.createdAt,
    required this.updatedAt,
  });

  final int id;
  final String title;
  final int? categoryId;
  final String? note;
  final TaskKind kind;
  final TaskTemplateStatus status;
  final DateTime firstDueDate;
  final RepeatRule? repeatRule;
  final ReminderRule reminderRule;
  final DateTime createdAt;
  final DateTime updatedAt;
}
