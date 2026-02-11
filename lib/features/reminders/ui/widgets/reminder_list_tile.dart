import 'package:flutter/material.dart';

import '../../domain/reminder.dart';

class ReminderListTile extends StatelessWidget {
  const ReminderListTile({
    super.key,
    required this.reminder,
    required this.onTap,
    required this.onToggleComplete,
    required this.onDelete,
  });

  final Reminder reminder;
  final VoidCallback onTap;
  final VoidCallback onToggleComplete;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Checkbox(
          value: reminder.isCompleted,
          onChanged: (_) => onToggleComplete(),
        ),
        title: Text(
          reminder.title,
          style: TextStyle(
            decoration: reminder.isCompleted
                ? TextDecoration.lineThrough
                : TextDecoration.none,
          ),
        ),
        subtitle: reminder.note == null ? null : Text(reminder.note!),
        onTap: onTap,
        trailing: IconButton(
          tooltip: '刪除',
          icon: const Icon(Icons.delete_outline),
          onPressed: onDelete,
        ),
      ),
    );
  }
}
