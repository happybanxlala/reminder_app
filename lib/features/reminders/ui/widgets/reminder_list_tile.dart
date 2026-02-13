import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../domain/reminder.dart';

class ReminderListTile extends StatelessWidget {
  const ReminderListTile({
    super.key,
    required this.reminder,
    required this.onTap,
    required this.onComplete,
    required this.onDelete,
  });

  final ReminderModel reminder;
  final VoidCallback onTap;
  final VoidCallback onComplete;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final dueText = reminder.dueAt == null
        ? '無到期時間'
        : DateFormat('yyyy/MM/dd HH:mm').format(reminder.dueAt!.toLocal());

    return Dismissible(
      key: ValueKey(reminder.id),
      background: _swipeBackground(
        context,
        alignment: Alignment.centerLeft,
        color: Colors.green,
        icon: Icons.check,
        label: '完成',
      ),
      secondaryBackground: _swipeBackground(
        context,
        alignment: Alignment.centerRight,
        color: Colors.red,
        icon: Icons.delete_outline,
        label: '刪除',
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          onComplete();
        } else {
          onDelete();
        }
        return false;
      },
      child: Card(
        child: ListTile(
          title: Text(
            reminder.title,
            style: TextStyle(
              decoration: reminder.isDone == 0
                  ? TextDecoration.none
                  : TextDecoration.lineThrough,
            ),
          ),
          subtitle: Text(dueText),
          onTap: onTap,
        ),
      ),
    );
  }

  Widget _swipeBackground(
    BuildContext context, {
    required Alignment alignment,
    required Color color,
    required IconData icon,
    required String label,
  }) {
    return Container(
      alignment: alignment,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      color: color,
      child: Row(
        mainAxisAlignment: alignment == Alignment.centerLeft
            ? MainAxisAlignment.start
            : MainAxisAlignment.end,
        children: [
          Icon(icon, color: Colors.white),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(color: Colors.white)),
        ],
      ),
    );
  }
}
