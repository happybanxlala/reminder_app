import 'dart:async';

import 'package:flutter/material.dart';

import '../../presentation/reminder_view_models.dart';

class PendingReminderTile extends StatefulWidget {
  const PendingReminderTile({
    super.key,
    required this.reminder,
    required this.onToggleDone,
    required this.onDefer,
    required this.onSkip,
    required this.onCancel,
    required this.onLongPress,
  });

  final PendingReminderItemViewModel reminder;
  final VoidCallback onToggleDone;
  final VoidCallback onDefer;
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
        label: ReminderUiText.skipAction,
      ),
      secondaryBackground: _swipeBackground(
        alignment: Alignment.centerRight,
        color: Colors.red,
        icon: Icons.cancel,
        label: ReminderUiText.cancelAction,
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
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.reminder.primaryText,
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 2),
              Text(widget.reminder.secondaryText),
              const SizedBox(height: 2),
              Text(
                widget.reminder.metaText,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
              ),
            ],
          ),
          isThreeLine: true,
          leading: Checkbox(
            value: widget.reminder.isDone,
            onChanged: (_) => widget.onToggleDone(),
          ),
          trailing: widget.reminder.canDefer
              ? IconButton(
                  key: ValueKey('defer-${widget.reminder.id}'),
                  tooltip: ReminderUiText.deferTooltip,
                  onPressed: widget.onDefer,
                  icon: const Icon(Icons.event_busy_outlined),
                )
              : null,
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
  const HistoryReminderTile({super.key, required this.reminder});

  final HistoryReminderItemViewModel reminder;

  @override
  Widget build(BuildContext context) {
    final color = reminder.isDone ? Colors.green : Colors.orange;

    return ListTile(
      title: Text(
        reminder.title,
        style: const TextStyle(decoration: TextDecoration.lineThrough),
      ),
      subtitle: Text(reminder.subtitle),
      isThreeLine: false,
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

  final CompletedPendingReminderItemViewModel reminder;
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
      subtitle: Text(
        reminder.subtitle,
        style: const TextStyle(color: Colors.grey),
      ),
      leading: const Icon(Icons.check_circle, color: Colors.grey),
      onTap: onRestore,
    );
  }
}
