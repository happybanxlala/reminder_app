import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/reminder_repository.dart';
import '../widgets/reminder_list_tile.dart';
import 'reminder_edit_page.dart';

class RemindersListPage extends ConsumerWidget {
  const RemindersListPage({super.key});

  static const routeName = 'reminders-list';
  static const routePath = '/';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final remindersAsync = ref.watch(remindersListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Reminders')),
      body: remindersAsync.when(
        data: (reminders) {
          if (reminders.isEmpty) {
            return const Center(child: Text('目前沒有提醒事項，點右下角新增。'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: reminders.length,
            itemBuilder: (context, index) {
              final reminder = reminders[index];
              return ReminderListTile(
                reminder: reminder,
                onTap: () {
                  if (reminder.isDone == 0) {
                    context.pushNamed(
                      ReminderEditPage.editRouteName,
                      pathParameters: {'id': reminder.id.toString()},
                    );
                  }
                },
                onComplete: () async {
                  await ref
                      .read(reminderRepositoryProvider)
                      .complete(reminder.id);
                },
                onDelete: () async {
                  await ref
                      .read(reminderRepositoryProvider)
                      .delete(reminder.id);
                },
              );
            },
          );
        },
        error: (error, stack) => Center(child: Text('讀取失敗: $error')),
        loading: () => const Center(child: CircularProgressIndicator()),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.pushNamed(ReminderEditPage.newRouteName),
        icon: const Icon(Icons.add),
        label: const Text('新增'),
      ),
    );
  }
}
