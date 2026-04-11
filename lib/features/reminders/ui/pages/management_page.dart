import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/reminder_repository.dart';
import '../../presentation/reminder_view_models.dart';
import 'reminder_edit_page.dart';

class ManagementPage extends ConsumerWidget {
  const ManagementPage({super.key});

  static const routeName = 'management';
  static const routePath = '/manage';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final templatesAsync = ref.watch(taskTemplatesProvider);
    final timelinesAsync = ref.watch(timelinesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text(ReminderUiText.manageTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  ReminderUiText.taskTemplateTitle,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              FilledButton(
                key: const Key('add-task-template-button'),
                onPressed: () {
                  context.pushNamed(ReminderEditPage.taskTemplateNewRouteName);
                },
                child: const Text(ReminderUiText.addTaskTemplate),
              ),
            ],
          ),
          const SizedBox(height: 12),
          templatesAsync.when(
            data: (items) {
              if (items.isEmpty) {
                return const Text(ReminderUiText.noTemplates);
              }
              return Column(
                children: items
                    .map(TemplateListItemViewModel.fromDomain)
                    .map(
                      (item) => ListTile(
                        title: Text(item.title),
                        subtitle: Text(item.subtitle),
                        trailing: Text(item.status),
                        onTap: () {
                          context.pushNamed(
                            ReminderEditPage.taskTemplateEditRouteName,
                            pathParameters: {'id': item.id.toString()},
                          );
                        },
                      ),
                    )
                    .toList(growable: false),
              );
            },
            error: (error, stack) => Text('讀取失敗: $error'),
            loading: () => const Center(child: CircularProgressIndicator()),
          ),
          const Divider(height: 32),
          Row(
            children: [
              const Expanded(
                child: Text(
                  ReminderUiText.timelineTitle,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              FilledButton(
                key: const Key('add-timeline-button'),
                onPressed: () {
                  context.pushNamed(ReminderEditPage.timelineNewRouteName);
                },
                child: const Text(ReminderUiText.addTimeline),
              ),
            ],
          ),
          const SizedBox(height: 12),
          timelinesAsync.when(
            data: (items) {
              if (items.isEmpty) {
                return const Text(ReminderUiText.noTimelines);
              }
              return Column(
                children: items
                    .map(TimelineListItemViewModel.fromDomain)
                    .map(
                      (item) => ListTile(
                        title: Text(item.title),
                        subtitle: Text(item.subtitle),
                        trailing: Text(item.status),
                        onTap: () {
                          context.pushNamed(
                            ReminderEditPage.timelineEditRouteName,
                            pathParameters: {'id': item.id.toString()},
                          );
                        },
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
