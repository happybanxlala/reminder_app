import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/home_models.dart';
import '../../data/local/task_timeline_dao.dart';
import '../../presentation/formatters/reminder_formatters.dart';
import '../../presentation/text/reminder_ui_text.dart';
import '../../presentation/view_models/task_milestone_card_view_model.dart';
import '../../providers/home_providers.dart';
import '../../providers/task_providers.dart';
import '../../providers/timeline_providers.dart';
import 'history_page.dart';
import 'management_page.dart';
import 'task_edit_page.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  static const routeName = 'home';
  static const routePath = '/';

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final todayAsync = ref.watch(todayHomeEntriesProvider);
    final upcomingAsync = ref.watch(upcomingHomeEntriesProvider);
    final overdueAsync = ref.watch(overdueTasksProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(ReminderUiText.homeTitle),
        actions: [
          IconButton(
            key: const Key('history-button'),
            onPressed: () => context.pushNamed(HistoryPage.routeName),
            icon: const Icon(Icons.history),
            tooltip: ReminderUiText.historyAction,
          ),
          IconButton(
            key: const Key('manage-button'),
            onPressed: () => context.pushNamed(ManagementPage.routeName),
            icon: const Icon(Icons.dashboard_customize_outlined),
            tooltip: ReminderUiText.manageAction,
          ),
          IconButton(
            key: const Key('quick-add-task-button'),
            onPressed: () => context.pushNamed(TaskEditPage.taskNewRouteName),
            icon: const Icon(Icons.add_task),
            tooltip: ReminderUiText.addTask,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: ReminderUiText.todayTab),
            Tab(text: ReminderUiText.upcomingTab),
            Tab(text: ReminderUiText.overdueTab),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          todayAsync.when(
            data: (items) => _HomeEntryList(
              items: items,
              emptyMessage: ReminderUiText.noTodayItems,
            ),
            error: (error, stack) => Text('讀取失敗: $error'),
            loading: () => const Center(child: CircularProgressIndicator()),
          ),
          upcomingAsync.when(
            data: (items) => _HomeEntryList(
              items: items,
              emptyMessage: ReminderUiText.noUpcomingItems,
            ),
            error: (error, stack) => Text('讀取失敗: $error'),
            loading: () => const Center(child: CircularProgressIndicator()),
          ),
          overdueAsync.when(
            data: (items) => _OverdueList(items: items),
            error: (error, stack) => Text('讀取失敗: $error'),
            loading: () => const Center(child: CircularProgressIndicator()),
          ),
        ],
      ),
    );
  }
}

class _HomeEntryList extends ConsumerWidget {
  const _HomeEntryList({required this.items, required this.emptyMessage});

  final List<HomeEntry> items;
  final String emptyMessage;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (items.isEmpty) {
      return Center(child: Text(emptyMessage));
    }
    return ListView.builder(
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        if (item is TaskHomeEntry) {
          final viewModel = TaskCardViewModel.fromBundle(item.bundle);
          return Card(
            child: Column(
              children: [
                ListTile(
                  key: Key('task-item-${viewModel.id}'),
                  title: Text(viewModel.title),
                  subtitle: Text(viewModel.subtitle),
                  trailing: const Text('Task'),
                ),
                OverflowBar(
                  children: [
                    TextButton(
                      onPressed: () async {
                        await ref
                            .read(taskRepositoryProvider)
                            .completeTask(viewModel.id);
                      },
                      child: const Text(ReminderUiText.completeAction),
                    ),
                    TextButton(
                      onPressed: () async {
                        await ref
                            .read(taskRepositoryProvider)
                            .skipTask(viewModel.id);
                      },
                      child: const Text(ReminderUiText.skipAction),
                    ),
                    TextButton(
                      onPressed: () async {
                        await ref
                            .read(taskRepositoryProvider)
                            .deferTask(viewModel.id, 1);
                      },
                      child: const Text(ReminderUiText.deferAction),
                    ),
                    TextButton(
                      onPressed: () async {
                        await ref
                            .read(taskRepositoryProvider)
                            .cancelTask(viewModel.id);
                      },
                      child: const Text(ReminderUiText.cancelAction),
                    ),
                  ],
                ),
              ],
            ),
          );
        }

        final occurrence = (item as TimelineMilestoneHomeEntry).occurrence;
        final viewModel = MilestoneCardViewModel.fromOccurrence(occurrence);
        return Card(
          child: Column(
            children: [
              ListTile(
                key: Key('milestone-item-${viewModel.id}'),
                title: Text(viewModel.title),
                subtitle: Text(viewModel.subtitle),
                trailing: const Text('Milestone'),
              ),
              OverflowBar(
                children: [
                  TextButton(
                    onPressed: () async {
                      await ref
                          .read(timelineRepositoryProvider)
                          .noticeOccurrence(occurrence);
                    },
                    child: const Text(ReminderUiText.noticedAction),
                  ),
                  TextButton(
                    onPressed: () async {
                      await ref
                          .read(timelineRepositoryProvider)
                          .skipOccurrence(occurrence);
                    },
                    child: const Text(ReminderUiText.skipAction),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _OverdueList extends ConsumerWidget {
  const _OverdueList({required this.items});

  final List<TaskBundle> items;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (items.isEmpty) {
      return const Center(child: Text(ReminderUiText.noOverdueItems));
    }
    return ListView(
      children: items
          .map(
            (item) => Card(
              child: Column(
                children: [
                  ListTile(
                    key: Key('overdue-task-${item.task.id}'),
                    title: Text(item.task.titleSnapshot),
                    subtitle: Text(ReminderFormatters.taskSummary(item)),
                    trailing: const Text('Task'),
                  ),
                  OverflowBar(
                    children: [
                      TextButton(
                        onPressed: () async {
                          await ref
                              .read(taskRepositoryProvider)
                              .completeTask(item.task.id);
                        },
                        child: const Text(ReminderUiText.completeAction),
                      ),
                      TextButton(
                        onPressed: () async {
                          await ref
                              .read(taskRepositoryProvider)
                              .skipTask(item.task.id);
                        },
                        child: const Text(ReminderUiText.skipAction),
                      ),
                      TextButton(
                        onPressed: () async {
                          await ref
                              .read(taskRepositoryProvider)
                              .deferTask(item.task.id, 1);
                        },
                        child: const Text(ReminderUiText.deferAction),
                      ),
                      TextButton(
                        onPressed: () async {
                          await ref
                              .read(taskRepositoryProvider)
                              .cancelTask(item.task.id);
                        },
                        child: const Text(ReminderUiText.cancelAction),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          )
          .toList(growable: false),
    );
  }
}
