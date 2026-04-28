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
        return _ItemCard(entry: items[index], previewDate: previewDate);
      },
    );
  }
}

class _ItemCard extends ConsumerStatefulWidget {
  const _ItemCard({required this.entry, required this.previewDate});

  final ItemHomeEntry entry;
  final DateTime previewDate;

  @override
  ConsumerState<_ItemCard> createState() => _ItemCardState();
}

class _ItemCardState extends ConsumerState<_ItemCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final baseViewModel = ItemCardViewModel.fromEntry(
      widget.entry,
      now: widget.previewDate,
    );
    final viewModel = baseViewModel.copyWith(isExpanded: _isExpanded);

    return Card(
      key: Key('item-card-${viewModel.id}'),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            key: Key('item-header-${viewModel.id}'),
            color: _headerColor(viewModel.displayState),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Checkbox(
                  key: Key('item-checkbox-${viewModel.id}'),
                  value: false,
                  onChanged: viewModel.canComplete
                      ? (_) => _handleComplete(viewModel)
                      : null,
                ),
                Expanded(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          viewModel.title,
                          key: Key('item-${viewModel.id}'),
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                      const SizedBox(width: 8),
                      _ItemTypeBadge(
                        label: viewModel.badgeLabel,
                        key: Key('item-badge-${viewModel.id}'),
                      ),
                    ],
                  ),
                ),
                if (viewModel.trailingLabel != null) ...[
                  const SizedBox(width: 16),
                  Text(
                    viewModel.trailingLabel!,
                    key: Key('item-tail-${viewModel.id}'),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
                IconButton(
                  key: Key('item-expand-${viewModel.id}'),
                  onPressed: () {
                    setState(() {
                      _isExpanded = !_isExpanded;
                    });
                  },
                  tooltip: _isExpanded ? ReminderUiText.collapseAction : '展開',
                  icon: Icon(
                    _isExpanded ? Icons.expand_less : Icons.expand_more,
                  ),
                ),
              ],
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 180),
            child: viewModel.isExpanded
                ? Container(
                    key: Key('item-content-${viewModel.id}'),
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _ItemDetailRow(
                          label: 'Pack',
                          value: viewModel.packTitle,
                        ),
                        if (viewModel.note != null)
                          _ItemDetailRow(label: 'Note', value: viewModel.note!),
                        if (viewModel.anchorDateLabel != null)
                          _ItemDetailRow(
                            label: '開始日期',
                            value: viewModel.anchorDateLabel!,
                          ),
                        if (viewModel.dueDateLabel != null)
                          _ItemDetailRow(
                            label: '到期日期',
                            value: viewModel.dueDateLabel!,
                          ),
                        if (viewModel.overduePolicyLabel != null)
                          _ItemDetailRow(
                            label: '逾期策略',
                            value: viewModel.overduePolicyLabel!,
                          ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            if (viewModel.canSkip)
                              TextButton(
                                key: Key('item-skip-${viewModel.id}'),
                                onPressed: () async {
                                  await ref
                                      .read(itemRepositoryProvider)
                                      .skip(
                                        viewModel.id,
                                        actionAt: widget.previewDate,
                                      );
                                },
                                child: const Text(ReminderUiText.skipAction),
                              ),
                            if (viewModel.canDefer)
                              TextButton(
                                key: Key('item-defer-${viewModel.id}'),
                                onPressed: () async {
                                  final deferDays = await _pickDeferDays(
                                    context,
                                  );
                                  if (deferDays == null) {
                                    return;
                                  }
                                  await ref
                                      .read(itemRepositoryProvider)
                                      .defer(
                                        viewModel.id,
                                        deferDays: deferDays,
                                        actionAt: widget.previewDate,
                                      );
                                },
                                child: const Text(ReminderUiText.deferAction),
                              ),
                            TextButton(
                              key: Key('item-history-${viewModel.id}'),
                              onPressed: () {
                                context.pushNamed(
                                  ItemHistoryPage.routeName,
                                  pathParameters: {
                                    'id': viewModel.id.toString(),
                                  },
                                );
                              },
                              child: const Text(ReminderUiText.viewAllAction),
                            ),
                          ],
                        ),
                      ],
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Future<void> _handleComplete(ItemCardViewModel viewModel) async {
    final item = widget.entry.bundle.item;
    final addedDays = item.type == ItemType.resourceBased
        ? await _pickResourceAddedDays(
            context,
            initialValue: (item.config as ResourceBasedItemConfig).durationDays,
          )
        : null;
    if (item.type == ItemType.resourceBased && addedDays == null) {
      return;
    }
    await ref
        .read(itemRepositoryProvider)
        .markDone(
          viewModel.id,
          doneAt: widget.previewDate,
          addedDays: addedDays,
        );
  }
}

class _ItemTypeBadge extends StatelessWidget {
  const _ItemTypeBadge({required this.label, super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).dividerColor),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(label, style: Theme.of(context).textTheme.labelMedium),
    );
  }
}

class _ItemDetailRow extends StatelessWidget {
  const _ItemDetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Wrap(
        spacing: 4,
        children: [
          Text(
            '$label：',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          Text(value, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}

Color _headerColor(ItemCardDisplayState state) {
  return switch (state) {
    ItemCardDisplayState.normal => const Color(0xFFE8F5E9),
    ItemCardDisplayState.warning => const Color(0xFFFFF8E1),
    ItemCardDisplayState.danger => const Color(0xFFFFEBEE),
    ItemCardDisplayState.overdue => const Color(0xFFEF9A9A),
    ItemCardDisplayState.notStarted => Colors.white,
    ItemCardDisplayState.unknown => const Color(0xFFF5F5F5),
  };
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
