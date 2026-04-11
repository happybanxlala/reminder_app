import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/reminder_repository.dart';
import '../../presentation/reminder_view_models.dart';

class HistoryPage extends ConsumerWidget {
  const HistoryPage({super.key});

  static const routeName = 'history';
  static const routePath = '/history';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final taskHistoryAsync = ref.watch(taskHistoryProvider);
    final milestoneHistoryAsync = ref.watch(milestoneHistoryProvider);

    return Scaffold(
      appBar: AppBar(title: const Text(ReminderUiText.historyTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            ReminderUiText.taskHistoryTitle,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          taskHistoryAsync.when(
            data: (items) {
              if (items.isEmpty) {
                return const Text(ReminderUiText.noTaskHistory);
              }
              return Column(
                children: items
                    .map(
                      (item) => ListTile(
                        key: Key('task-history-${item.task.id}'),
                        title: Text(item.task.titleSnapshot),
                        subtitle: Text(ReminderFormatters.taskHistory(item)),
                        trailing: const Text('Task'),
                      ),
                    )
                    .toList(growable: false),
              );
            },
            error: (error, stack) => Text('讀取失敗: $error'),
            loading: () => const Center(child: CircularProgressIndicator()),
          ),
          const Divider(height: 32),
          const Text(
            ReminderUiText.milestoneHistoryTitle,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          milestoneHistoryAsync.when(
            data: (items) {
              if (items.isEmpty) {
                return const Text(ReminderUiText.noMilestoneHistory);
              }
              return Column(
                children: items
                    .map(
                      (item) => ListTile(
                        key: Key('milestone-history-${item.milestone.id}'),
                        title: Text(item.timeline.title),
                        subtitle: Text(
                          ReminderFormatters.milestoneHistory(item),
                        ),
                        trailing: const Text('Milestone'),
                      ),
                    )
                    .toList(growable: false),
              );
            },
            error: (error, stack) => Text('讀取失敗: $error'),
            loading: () => const Center(child: CircularProgressIndicator()),
          ),
        ],
      ),
    );
  }
}
