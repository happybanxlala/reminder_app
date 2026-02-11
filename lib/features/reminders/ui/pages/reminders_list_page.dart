import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../services/reminders_service.dart';
import '../widgets/reminder_list_tile.dart';
import 'reminder_edit_page.dart';

class RemindersListPage extends ConsumerWidget {
  const RemindersListPage({super.key});

  static const routeName = 'reminders-list';
  static const routePath = '/reminders';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reminders = ref.watch(remindersServiceProvider);
    final service = ref.read(remindersServiceProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Reminders')),
      body: reminders.isEmpty
          ? const Center(child: Text('目前沒有提醒事項，點右下角新增。'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: reminders.length,
              itemBuilder: (context, index) {
                final reminder = reminders[index];
                return ReminderListTile(
                  reminder: reminder,
                  onTap: () {
                    context.pushNamed(
                      ReminderEditPage.editRouteName,
                      pathParameters: {'id': reminder.id},
                    );
                  },
                  onToggleComplete: () => service.toggleComplete(reminder.id),
                  onDelete: () => service.remove(reminder.id),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.pushNamed(ReminderEditPage.newRouteName),
        icon: const Icon(Icons.add),
        label: const Text('新增'),
      ),
    );
  }
}
