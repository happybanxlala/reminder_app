import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/home_models.dart';
import '../../domain/timeline_milestone_occurrence.dart';
import '../../presentation/text/reminder_ui_text.dart';
import '../../presentation/view_models/item_timeline_card_view_model.dart';
import '../../providers/home_providers.dart';
import '../../providers/item_providers.dart';
import '../../providers/timeline_providers.dart';
import 'history_page.dart';
import 'item_edit_page.dart';
import 'management_page.dart';

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
    final dangerAsync = ref.watch(dangerHomeEntriesProvider);
    final warningAsync = ref.watch(warningHomeEntriesProvider);
    final timelineAsync = ref.watch(upcomingTimelineMilestonesProvider);

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
            key: const Key('quick-add-item-button'),
            onPressed: () => context.pushNamed(ItemEditPage.createRouteName),
            icon: const Icon(Icons.add_task),
            tooltip: ReminderUiText.addItem,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: ReminderUiText.dangerTab),
            Tab(text: ReminderUiText.warningTab),
            Tab(text: ReminderUiText.timelineTab),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          dangerAsync.when(
            data: (items) => _ItemList(
              items: items,
              emptyMessage: ReminderUiText.noDangerItems,
            ),
            error: (error, stack) => Text('讀取失敗: $error'),
            loading: () => const Center(child: CircularProgressIndicator()),
          ),
          warningAsync.when(
            data: (items) => _ItemList(
              items: items,
              emptyMessage: ReminderUiText.noWarningItems,
            ),
            error: (error, stack) => Text('讀取失敗: $error'),
            loading: () => const Center(child: CircularProgressIndicator()),
          ),
          timelineAsync.when(
            data: (items) => _TimelineMilestoneList(
              items: items,
              emptyMessage: ReminderUiText.noUpcomingTimelineItems,
            ),
            error: (error, stack) => Text('讀取失敗: $error'),
            loading: () => const Center(child: CircularProgressIndicator()),
          ),
        ],
      ),
    );
  }
}

class _ItemList extends ConsumerWidget {
  const _ItemList({required this.items, required this.emptyMessage});

  final List<ItemHomeEntry> items;
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
        final viewModel = ItemCardViewModel.fromEntry(item);
        return Card(
          child: Column(
            children: [
              ListTile(
                key: Key('item-${viewModel.id}'),
                title: Text(viewModel.title),
                subtitle: Text(viewModel.subtitle),
                trailing: Text(viewModel.status),
              ),
              OverflowBar(
                children: [
                  TextButton(
                    onPressed: () async {
                      await ref
                          .read(itemRepositoryProvider)
                          .markDone(viewModel.id);
                    },
                    child: const Text(ReminderUiText.completeAction),
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

class _TimelineMilestoneList extends ConsumerWidget {
  const _TimelineMilestoneList({
    required this.items,
    required this.emptyMessage,
  });

  final List<TimelineMilestoneOccurrence> items;
  final String emptyMessage;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (items.isEmpty) {
      return Center(child: Text(emptyMessage));
    }
    return ListView.builder(
      itemCount: items.length,
      itemBuilder: (context, index) {
        final occurrence = items[index];
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
