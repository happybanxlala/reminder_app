import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/task_template.dart';
import '../../domain/timeline.dart';
import '../../presentation/formatters/reminder_formatters.dart';
import '../../presentation/text/reminder_ui_text.dart';
import '../../providers/task_providers.dart';
import '../../providers/timeline_providers.dart';
import 'task_timeline_editor_page.dart';

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
                  context.pushNamed(
                    TaskTimelineEditorPage.taskTemplateNewRouteName,
                  );
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
                    .map((item) => _TaskTemplateCard(template: item))
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
                  context.pushNamed(
                    TaskTimelineEditorPage.timelineNewRouteName,
                  );
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
                    .map((item) => _TimelineCard(timeline: item))
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

class _TaskTemplateCard extends ConsumerWidget {
  const _TaskTemplateCard({required this.template});

  final TaskTemplate template;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repository = ref.read(taskRepositoryProvider);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        template.title,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        ReminderFormatters.templateSummary(
                          template.repeatRule,
                          template.reminderRule,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(ReminderFormatters.taskTemplateStatus(template.status)),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: switch (template.status) {
                TaskTemplateStatus.active => [
                  OutlinedButton(
                    key: Key('template-edit-${template.id}'),
                    onPressed: () {
                      context.pushNamed(
                        TaskTimelineEditorPage.taskTemplateEditRouteName,
                        pathParameters: {'id': template.id.toString()},
                      );
                    },
                    child: const Text(ReminderUiText.editAction),
                  ),
                  OutlinedButton(
                    key: Key('template-pause-${template.id}'),
                    onPressed: () async {
                      await repository.pauseTemplate(template.id);
                    },
                    child: const Text(ReminderUiText.pauseAction),
                  ),
                  OutlinedButton(
                    key: Key('template-archive-${template.id}'),
                    onPressed: () async {
                      await repository.archiveTemplate(template.id);
                    },
                    child: const Text(ReminderUiText.archiveAction),
                  ),
                ],
                TaskTemplateStatus.paused => [
                  OutlinedButton(
                    key: Key('template-resume-${template.id}'),
                    onPressed: () async {
                      await repository.resumeTemplate(template.id);
                    },
                    child: const Text(ReminderUiText.resumeAction),
                  ),
                  OutlinedButton(
                    key: Key('template-archive-${template.id}'),
                    onPressed: () async {
                      await repository.archiveTemplate(template.id);
                    },
                    child: const Text(ReminderUiText.archiveAction),
                  ),
                  OutlinedButton(
                    key: Key('template-edit-${template.id}'),
                    onPressed: () {
                      context.pushNamed(
                        TaskTimelineEditorPage.taskTemplateEditRouteName,
                        pathParameters: {'id': template.id.toString()},
                      );
                    },
                    child: const Text(ReminderUiText.editAction),
                  ),
                ],
                TaskTemplateStatus.archived => <Widget>[],
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _TimelineCard extends StatelessWidget {
  const _TimelineCard({required this.timeline});

  final Timeline timeline;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        timeline.title,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(ReminderFormatters.timelineSummary(timeline)),
                    ],
                  ),
                ),
                Text(ReminderFormatters.timelineStatus(timeline.status)),
              ],
            ),
            const SizedBox(height: 12),
            if (timeline.status != TimelineStatus.archived)
              OutlinedButton(
                key: Key('timeline-edit-${timeline.id}'),
                onPressed: () {
                  context.pushNamed(
                    TaskTimelineEditorPage.timelineEditRouteName,
                    pathParameters: {'id': timeline.id.toString()},
                  );
                },
                child: const Text(ReminderUiText.editAction),
              ),
          ],
        ),
      ),
    );
  }
}
