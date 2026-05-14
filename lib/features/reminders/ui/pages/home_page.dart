import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/home_models.dart';
import '../../data/local/reminder_dao.dart';
import '../../domain/attention_summary.dart';
import '../../domain/resource.dart';
import '../../domain/stage_occurrence.dart';
import '../../providers/developer_settings_providers.dart';
import '../../providers/attention_summary_providers.dart';
import '../../presentation/text/reminder_ui_text.dart';
import '../../presentation/view_models/item_card_view_model.dart';
import '../../providers/home_providers.dart';
import '../../providers/item_providers.dart';
import '../../providers/resource_providers.dart';
import '../../providers/stage_tracker_providers.dart';
import '../../presentation/formatters/reminder_formatters.dart';
import 'feature_page.dart';
import 'item_edit_page.dart';
import 'item_history_page.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  static const routeName = 'home';
  static const routePath = '/';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
      ),
      body: const HomeContent(),
      floatingActionButton: FloatingActionButton(
        key: const Key('home-add-item-fab'),
        onPressed: () => context.pushNamed(ItemEditPage.createRouteName),
        tooltip: ReminderUiText.addItem,
        child: const Icon(Icons.add_circle_outline),
      ),
    );
  }
}

class HomeContent extends ConsumerWidget {
  const HomeContent({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(attentionSummaryProvider);
    final dangerAsync = ref.watch(dangerHomeEntriesProvider);
    final warningAsync = ref.watch(warningHomeEntriesProvider);
    final resourcesAsync = ref.watch(resourcesProvider);
    final stagesAsync = ref.watch(upcomingStagesProvider);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        summaryAsync.when(
          data: (summary) => _AttentionSummaryCard(summary: summary),
          error: (error, stack) => Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text('讀取失敗: $error'),
            ),
          ),
          loading: () => const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            ),
          ),
        ),
        const SizedBox(height: 16),
        resourcesAsync.when(
          data: (resources) {
            if (resources.isEmpty) {
              return const SizedBox.shrink();
            }
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _HomeSection(
                title: '資源',
                child: _ResourceList(resources: resources),
              ),
            );
          },
          error: (error, stack) => Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: _HomeSection(title: '資源', child: Text('讀取失敗: $error')),
          ),
          loading: () => const SizedBox.shrink(),
        ),
        _HomeSection(
          title: ReminderUiText.dangerTab,
          child: dangerAsync.when(
            data: (items) => _ItemList(
              items: items,
              emptyMessage: ReminderUiText.noDangerItems,
            ),
            error: (error, stack) => Text('讀取失敗: $error'),
            loading: () => const Center(child: CircularProgressIndicator()),
          ),
        ),
        const SizedBox(height: 16),
        _HomeSection(
          title: ReminderUiText.warningTab,
          child: warningAsync.when(
            data: (items) => _ItemList(
              items: items,
              emptyMessage: ReminderUiText.noWarningItems,
            ),
            error: (error, stack) => Text('讀取失敗: $error'),
            loading: () => const Center(child: CircularProgressIndicator()),
          ),
        ),
        const SizedBox(height: 16),
        _HomeSection(
          title: ReminderUiText.upcomingSectionTitle,
          child: stagesAsync.when(
            data: (items) => _StageList(
              items: items,
              emptyMessage: ReminderUiText.noUpcomingStages,
            ),
            error: (error, stack) => Text('讀取失敗: $error'),
            loading: () => const Center(child: CircularProgressIndicator()),
          ),
        ),
      ],
    );
  }
}

class _AttentionSummaryCard extends StatelessWidget {
  const _AttentionSummaryCard({required this.summary});

  final AttentionSummary summary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final breakdown = ReminderUiText.homeAttentionBreakdownTemplate
        .replaceFirst('{danger}', '${summary.dangerCount}')
        .replaceFirst('{warning}', '${summary.warningCount}')
        .replaceFirst('{stage}', '${summary.stageUpcomingCount}');

    return Card(
      key: const Key('attention-summary-card'),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: summary.hasAttention
                    ? const Color(0xFFFFF3E0)
                    : const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                summary.hasAttention
                    ? Icons.notifications_active_outlined
                    : Icons.check_circle_outline,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    summary.hasAttention
                        ? '今天有 ${summary.totalCount} 件事需要處理'
                        : ReminderUiText.homeAttentionStable,
                    key: const Key('attention-summary-title'),
                    style: theme.textTheme.titleMedium,
                  ),
                  if (summary.hasAttention) ...[
                    const SizedBox(height: 6),
                    Text(
                      breakdown,
                      key: const Key('attention-summary-breakdown'),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
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
      return Text(emptyMessage);
    }
    final previewDate = ref.watch(effectivePreviewDateProvider);
    return Column(
      children: [
        for (var index = 0; index < items.length; index++) ...[
          if (index > 0) const SizedBox(height: 12),
          _ItemCard(entry: items[index], previewDate: previewDate),
        ],
      ],
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
                  tooltip: _isExpanded
                      ? ReminderUiText.collapseAction
                      : ReminderUiText.expandAction,
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
    await ref
        .read(itemRepositoryProvider)
        .markDone(viewModel.id, doneAt: widget.previewDate);
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

class _ResourceList extends ConsumerWidget {
  const _ResourceList({required this.resources});

  final List<ResourceBundle> resources;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final previewDate = ref.watch(effectivePreviewDateProvider);
    final repository = ref.watch(resourceRepositoryProvider);
    final attentionResources = resources
        .where((bundle) {
          final status = repository.statusFor(
            bundle.resource,
            now: previewDate,
          );
          return status == ResourceStatus.warning ||
              status == ResourceStatus.danger;
        })
        .toList(growable: false);
    if (attentionResources.isEmpty) {
      return const Text('目前沒有需要留意的資源。');
    }
    return Column(
      children: [
        for (var index = 0; index < attentionResources.length; index++) ...[
          if (index > 0) const SizedBox(height: 12),
          _ResourceCard(bundle: attentionResources[index], now: previewDate),
        ],
      ],
    );
  }
}

class _ResourceCard extends ConsumerWidget {
  const _ResourceCard({required this.bundle, required this.now});

  final ResourceBundle bundle;
  final DateTime now;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repository = ref.watch(resourceRepositoryProvider);
    final resource = bundle.resource;
    final status = repository.statusFor(resource, now: now);
    return Card(
      margin: EdgeInsets.zero,
      child: ListTile(
        key: Key('resource-card-${resource.id}'),
        leading: const Icon(Icons.inventory_2_outlined),
        title: Text(resource.title),
        subtitle: Text(
          '${ReminderFormatters.resourceStatus(status)} • ${ReminderFormatters.resourceSummary(resource, now: now)}',
        ),
        trailing: Text(
          ReminderFormatters.resourceTrailingLabel(resource, now: now),
        ),
      ),
    );
  }
}

class _StageList extends ConsumerWidget {
  const _StageList({required this.items, required this.emptyMessage});

  final List<StageOccurrence> items;
  final String emptyMessage;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (items.isEmpty) {
      return Text(emptyMessage);
    }
    return Column(
      children: [
        for (var index = 0; index < items.length; index++) ...[
          if (index > 0) const SizedBox(height: 12),
          Builder(
            builder: (context) {
              final occurrence = items[index];
              final viewModel = StageCardViewModel.fromOccurrence(occurrence);
              return Card(
                child: Column(
                  children: [
                    ListTile(
                      key: Key('stage-item-${viewModel.id}'),
                      title: Text(viewModel.title),
                      subtitle: Text(viewModel.subtitle),
                      trailing: const Text(ReminderUiText.stageLabel),
                    ),
                    OverflowBar(
                      children: [
                        TextButton(
                          onPressed: () async {
                            await ref
                                .read(stageTrackerRepositoryProvider)
                                .acknowledgeOccurrence(occurrence);
                          },
                          child: const Text(ReminderUiText.acknowledgedAction),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ],
    );
  }
}

class _HomeSection extends StatelessWidget {
  const _HomeSection({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}
