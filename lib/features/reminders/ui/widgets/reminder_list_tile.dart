import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../domain/reminder.dart';

class PendingReminderTile extends StatefulWidget {
  const PendingReminderTile({
    super.key,
    required this.reminder,
    required this.remainingLabel,
    required this.onToggleDone,
    required this.onSkip,
    required this.onCancel,
    required this.onLongPress,
  });

  final ReminderModel reminder;
  final String remainingLabel;
  final VoidCallback onToggleDone;
  final VoidCallback onSkip;
  final VoidCallback onCancel;
  final VoidCallback onLongPress;

  @override
  State<PendingReminderTile> createState() => _PendingReminderTileState();
}

class _PendingReminderTileState extends State<PendingReminderTile> {
  Timer? _holdTimer;

  @override
  void dispose() {
    _holdTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey('pending-${widget.reminder.id}'),
      background: _swipeBackground(
        alignment: Alignment.centerLeft,
        color: Colors.orange,
        icon: Icons.skip_next,
        label: 'Skip',
      ),
      secondaryBackground: _swipeBackground(
        alignment: Alignment.centerRight,
        color: Colors.red,
        icon: Icons.cancel,
        label: 'Cancel',
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          widget.onSkip();
        } else {
          widget.onCancel();
        }
        return false;
      },
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) {
          _holdTimer?.cancel();
          _holdTimer = Timer(const Duration(seconds: 2), widget.onLongPress);
        },
        onTapUp: (_) => _holdTimer?.cancel(),
        onTapCancel: () => _holdTimer?.cancel(),
        child: ListTile(
          title: Text(widget.reminder.title),
          subtitle: Text(widget.remainingLabel),
          leading: Checkbox(
            value: widget.reminder.isDone,
            onChanged: (_) => widget.onToggleDone(),
          ),
        ),
      ),
    );
  }

  Widget _swipeBackground({
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

class HistoryReminderTile extends StatelessWidget {
  const HistoryReminderTile({
    super.key,
    required this.reminder,
  });

  final ReminderModel reminder;

  @override
  Widget build(BuildContext context) {
    final color = reminder.isDone ? Colors.green : Colors.orange;
    final label = reminder.isDone ? 'Done' : 'Skipped';
    final updatedAtText = DateFormat(
      'yyyy/MM/dd HH:mm',
    ).format(reminder.updatedAt.toLocal());
    final dueAtText = reminder.dueAt == null
        ? '無到期時間'
        : DateFormat('yyyy/MM/dd HH:mm').format(reminder.dueAt!.toLocal());

    return ListTile(
      title: Text(
        reminder.title,
        style: const TextStyle(decoration: TextDecoration.lineThrough),
      ),
      subtitle: Text('狀態: $label\n更新: $updatedAtText\n到期: $dueAtText'),
      isThreeLine: true,
      trailing: Icon(Icons.circle, color: color, size: 12),
    );
  }
}

class CompletedPendingTile extends StatelessWidget {
  const CompletedPendingTile({
    super.key,
    required this.reminder,
    required this.onRestore,
  });

  final ReminderModel reminder;
  final VoidCallback onRestore;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(
        reminder.title,
        style: const TextStyle(
          color: Colors.grey,
          decoration: TextDecoration.lineThrough,
        ),
      ),
      subtitle: const Text(
        '已完成（點擊可恢復）',
        style: TextStyle(color: Colors.grey),
      ),
      leading: const Icon(Icons.check_circle, color: Colors.grey),
      onTap: onRestore,
    );
  }
}
