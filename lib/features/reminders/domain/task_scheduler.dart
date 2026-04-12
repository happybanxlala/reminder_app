import 'reminder_rule.dart';
import 'repeat_rule.dart';
import 'task.dart';

class TaskScheduler {
  const TaskScheduler();

  DateTime reminderStart(Task task) {
    return switch (task.reminderRule.type) {
      ReminderRuleType.advance => task.effectiveDueDate.subtract(
        Duration(days: task.reminderRule.offsetDays ?? 0),
      ),
      ReminderRuleType.onDue => task.effectiveDueDate,
      ReminderRuleType.immediate => task.createdAt,
    };
  }

  bool isInToday(Task task, DateTime now) {
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    return task.isPending &&
        !task.effectiveDueDate.isBefore(today) &&
        task.effectiveDueDate.isBefore(tomorrow);
  }

  bool isUpcoming(Task task, DateTime now) {
    final today = DateTime(now.year, now.month, now.day);
    if (!task.isPending || !task.effectiveDueDate.isAfter(today)) {
      return false;
    }

    return switch (task.reminderRule.type) {
      ReminderRuleType.immediate => true,
      ReminderRuleType.advance => !today.isBefore(reminderStart(task)),
      ReminderRuleType.onDue => false,
    };
  }

  bool isOverdue(Task task, DateTime now) {
    final today = DateTime(now.year, now.month, now.day);
    return task.isPending && task.effectiveDueDate.isBefore(today);
  }

  DateTime nextDueDate(Task task, RepeatRule? repeatRule) {
    final rule = repeatRule;
    if (rule == null) {
      return task.effectiveDueDate;
    }
    return rule.advance(task.effectiveDueDate);
  }
}
