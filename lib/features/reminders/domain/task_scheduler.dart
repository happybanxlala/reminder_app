import 'reminder_rule.dart';
import 'repeat_rule.dart';
import 'task.dart';
import 'task_template.dart';

class TaskScheduler {
  const TaskScheduler();

  DateTime reminderStart(Task task, ReminderRule reminderRule) {
    return switch (reminderRule.type) {
      ReminderRuleType.advance => task.effectiveDueDate.subtract(
        Duration(days: reminderRule.offsetDays ?? 0),
      ),
      ReminderRuleType.onDue => task.effectiveDueDate,
      ReminderRuleType.immediate => task.createdAt,
    };
  }

  bool isInToday(Task task, ReminderRule reminderRule, DateTime now) {
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final start = reminderStart(task, reminderRule);
    final effectiveDueDate = task.effectiveDueDate;
    return task.isPending &&
        !effectiveDueDate.isBefore(today) &&
        start.isBefore(tomorrow);
  }

  bool isUpcoming(Task task, ReminderRule reminderRule, DateTime now) {
    final today = DateTime(now.year, now.month, now.day);
    final start = reminderStart(task, reminderRule);
    return task.isPending && start.isAfter(today);
  }

  bool isOverdue(Task task, DateTime now) {
    final today = DateTime(now.year, now.month, now.day);
    return task.isPending && task.effectiveDueDate.isBefore(today);
  }

  DateTime nextDueDate(Task task, TaskTemplate template) {
    final rule = template.repeatRule;
    if (rule == null) {
      return task.effectiveDueDate;
    }
    return rule.advance(task.effectiveDueDate);
  }
}
