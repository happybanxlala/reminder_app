import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/home_models.dart';
import '../../domain/item.dart';
import '../../domain/timeline_milestone_occurrence.dart';
import '../../providers/developer_settings_providers.dart';
import '../../presentation/text/reminder_ui_text.dart';
import '../../presentation/view_models/item_timeline_card_view_model.dart';
import '../../providers/home_providers.dart';
import '../../providers/item_providers.dart';
import '../../providers/timeline_providers.dart';
import 'feature_page.dart';
import 'item_edit_page.dart';
import 'item_history_page.dart';

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
            key: const Key('feature-button'),
            onPressed: () => context.pushNamed(FeaturePage.routeName),
            icon: const Icon(Icons.widgets_outlined),
            tooltip: ReminderUiText.featureAction,
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
      floatingActionButton: FloatingActionButton(
        key: const Key('home-add-item-fab'),
        onPressed: () => context.pushNamed(ItemEditPage.createRouteName),
        tooltip: ReminderUiText.addItem,
        child: const Icon(Icons.add_task),
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
    final previewDate = ref.watch(effectivePreviewDateProvider);
    return ListView.builder(
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        final viewModel = ItemCardViewModel.fromEntry(item, now: previewDate);
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
                      final addedDays =
                          item.bundle.item.type == ItemType.resourceBased
                          ? await _pickResourceAddedDays(
                              context,
                              initialValue:
                                  (item.bundle.item.config
                                          as ResourceBasedItemConfig)
                                      .durationDays,
                            )
                          : null;
                      if (item.bundle.item.type == ItemType.resourceBased &&
                          addedDays == null) {
                        return;
                      }
                      await ref
                          .read(itemRepositoryProvider)
                          .markDone(
                            viewModel.id,
                            doneAt: previewDate,
                            addedDays: addedDays,
                          );
                    },
                    child: const Text(ReminderUiText.completeAction),
                  ),
                  if (item.bundle.item.type != ItemType.resourceBased)
                    TextButton(
                      onPressed: () async {
                        await ref
                            .read(itemRepositoryProvider)
                            .skip(viewModel.id, actionAt: previewDate);
                      },
                      child: const Text(ReminderUiText.skipAction),
                    ),
                  if (item.bundle.item.type == ItemType.fixed)
                    TextButton(
                      onPressed: () async {
                        final deferDays = await _pickDeferDays(context);
                        if (deferDays == null) {
                          return;
                        }
                        await ref
                            .read(itemRepositoryProvider)
                            .defer(
                              viewModel.id,
                              deferDays: deferDays,
                              actionAt: previewDate,
                            );
                      },
                      child: const Text(ReminderUiText.deferAction),
                    ),
                  TextButton(
                    onPressed: () {
                      context.pushNamed(
                        ItemHistoryPage.routeName,
                        pathParameters: {'id': viewModel.id.toString()},
                      );
                    },
                    child: const Text(ReminderUiText.viewAllAction),
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

Future<int?> _pickDeferDays(BuildContext context) async {
  final controller = TextEditingController(text: '1');
  final result = await showDialog<int>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text(ReminderUiText.deferAction),
      content: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        decoration: const InputDecoration(labelText: '延期天數'),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: () {
            Navigator.of(
              context,
            ).pop(int.tryParse(controller.text.trim()) ?? 1);
          },
          child: const Text(ReminderUiText.saveAction),
        ),
      ],
    ),
  );
  controller.dispose();
  return result;
}

Future<int?> _pickResourceAddedDays(
  BuildContext context, {
  required int initialValue,
}) async {
  var inputValue = '$initialValue';
  String? errorText;
  final result = await showDialog<int>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: const Text(ReminderUiText.completeAction),
        content: TextFormField(
          autofocus: true,
          initialValue: inputValue,
          keyboardType: TextInputType.number,
          onChanged: (value) {
            inputValue = value;
          },
          decoration: InputDecoration(
            labelText: '補充 addedDays',
            errorText: errorText,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () {
              final value = int.tryParse(inputValue.trim());
              if (value == null || value <= 0) {
                setState(() {
                  errorText = '請輸入 1 或以上整數';
                });
                return;
              }
              Navigator.of(context).pop(value);
            },
            child: const Text(ReminderUiText.saveAction),
          ),
        ],
      ),
    ),
  );
  return result;
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
