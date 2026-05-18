import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/reminder_theme.dart';
import '../../data/home_models.dart';
import '../../data/local/reminder_dao.dart';
import '../../domain/attention_summary.dart';
import '../../domain/item_pack.dart';
import '../../domain/resource.dart';
import '../../domain/stage_tracker.dart';
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
import '../widgets/pack_picker.dart';
import '../widgets/reminder_components.dart';

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

class HomeContent extends ConsumerStatefulWidget {
  const HomeContent({super.key});

  @override
  ConsumerState<HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends ConsumerState<HomeContent> {
  int? _selectedPackId;

  @override
  Widget build(BuildContext context) {
    final summaryAsync = ref.watch(attentionSummaryProvider);
    final dangerAsync = ref.watch(dangerHomeEntriesProvider);
    final warningAsync = ref.watch(warningHomeEntriesProvider);
    final resourcesAsync = ref.watch(resourcesProvider);
    final stagesAsync = ref.watch(upcomingStagesProvider);
    final packsAsync = ref.watch(activeItemPacksProvider);
    final trackersAsync = ref.watch(stageTrackersProvider);
    final previewDate = ref.watch(effectivePreviewDateProvider);
    final packs = packsAsync.valueOrNull ?? const <ItemPack>[];
    final trackers = trackersAsync.valueOrNull ?? const <StageTracker>[];

    return ListView(
      padding: const EdgeInsets.all(ReminderSpacing.page),
      children: [
        summaryAsync.when(
          data: (summary) =>
              _AttentionSummaryCard(summary: summary, previewDate: previewDate),
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
        const SizedBox(height: ReminderSpacing.section),
        _HomePackFilter(
          packs: packs,
          selectedPackId: _selectedPackId,
          onChanged: (packId) {
            setState(() {
              _selectedPackId = packId;
            });
          },
        ),
        const SizedBox(height: ReminderSpacing.section),
        _HomeSection(
          title: ReminderUiText.dangerTab,
          icon: Icons.error_outline,
          child: dangerAsync.when(
            data: (items) => _ItemList(
              items: _filterItems(items),
              emptyMessage: ReminderUiText.noDangerItems,
            ),
            error: (error, stack) => Text('讀取失敗: $error'),
            loading: () => const Center(child: CircularProgressIndicator()),
          ),
        ),
        const SizedBox(height: ReminderSpacing.section),
        _HomeSection(
          title: ReminderUiText.warningTab,
          icon: Icons.visibility_outlined,
          child: warningAsync.when(
            data: (items) => _ItemList(
              items: _filterItems(items),
              emptyMessage: ReminderUiText.noWarningItems,
            ),
            error: (error, stack) => Text('讀取失敗: $error'),
            loading: () => const Center(child: CircularProgressIndicator()),
          ),
        ),
        const SizedBox(height: ReminderSpacing.section),
        resourcesAsync.when(
          data: (resources) {
            final filteredResources = _filterResources(resources);
            if (filteredResources.isEmpty) {
              return const SizedBox.shrink();
            }
            return Padding(
              padding: const EdgeInsets.only(bottom: ReminderSpacing.section),
              child: _HomeSection(
                title: '資源',
                icon: Icons.inventory_2_outlined,
                child: _ResourceList(resources: filteredResources),
              ),
            );
          },
          error: (error, stack) => Padding(
            padding: const EdgeInsets.only(bottom: ReminderSpacing.section),
            child: _HomeSection(
              title: '資源',
              icon: Icons.inventory_2_outlined,
              child: Text('讀取失敗: $error'),
            ),
          ),
          loading: () => const SizedBox.shrink(),
        ),
        _HomeSection(
          title: ReminderUiText.upcomingSectionTitle,
          icon: Icons.event_available_outlined,
          child: stagesAsync.when(
            data: (items) => _StageList(
              items: _filterStages(items, trackers),
              packs: packs,
              trackers: trackers,
              emptyMessage: ReminderUiText.noUpcomingStages,
            ),
            error: (error, stack) => Text('讀取失敗: $error'),
            loading: () => const Center(child: CircularProgressIndicator()),
          ),
        ),
        const ReminderFooterMark(),
      ],
    );
  }

  List<ItemHomeEntry> _filterItems(List<ItemHomeEntry> items) {
    final packId = _selectedPackId;
    if (packId == null) {
      return items;
    }
    return items
        .where((entry) => entry.bundle.item.packId == packId)
        .toList(growable: false);
  }

  List<ResourceBundle> _filterResources(List<ResourceBundle> resources) {
    final packId = _selectedPackId;
    if (packId == null) {
      return resources;
    }
    return resources
        .where((entry) => entry.resource.packId == packId)
        .toList(growable: false);
  }

  List<StageOccurrence> _filterStages(
    List<StageOccurrence> stages,
    List<StageTracker> trackers,
  ) {
    final packId = _selectedPackId;
    if (packId == null) {
      return stages;
    }
    final trackerPackIds = {
      for (final tracker in trackers) tracker.id: tracker.packId,
    };
    return stages
        .where((entry) => trackerPackIds[entry.stageTrackerId] == packId)
        .toList(growable: false);
  }
}

class _HomePackFilter extends StatelessWidget {
  const _HomePackFilter({
    required this.packs,
    required this.selectedPackId,
    required this.onChanged,
  });

  final List<ItemPack> packs;
  final int? selectedPackId;
  final ValueChanged<int?> onChanged;

  @override
  Widget build(BuildContext context) {
    final palette = context.reminderPalette;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              key: const Key('home-pack-filter-all'),
              avatar: selectedPackId == null
                  ? Icon(Icons.check, size: 18, color: palette.primaryWarmDark)
                  : null,
              label: const Text('全部'),
              selected: selectedPackId == null,
              showCheckmark: false,
              onSelected: (_) => onChanged(null),
              selectedColor: palette.primaryWarmContainer,
            ),
          ),
          for (final pack in packs)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Tooltip(
                message: pack.title,
                child: Semantics(
                  label: '生活場景 ${pack.title}',
                  button: true,
                  selected: selectedPackId == pack.id,
                  child: Builder(
                    builder: (context) {
                      final selected = selectedPackId == pack.id;
                      return ChoiceChip(
                        key: Key('home-pack-filter-${pack.id}'),
                        label: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(pack.iconEmoji),
                            if (selected) ...[
                              const SizedBox(width: 6),
                              Text(pack.title),
                            ],
                          ],
                        ),
                        selected: selected,
                        showCheckmark: false,
                        elevation: 0,
                        pressElevation: 0,
                        shadowColor: Colors.transparent,
                        selectedShadowColor: Colors.transparent,
                        onSelected: (_) => onChanged(pack.id),
                        selectedColor: palette.primaryWarmContainer,
                      );
                    },
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _AttentionSummaryCard extends StatelessWidget {
  const _AttentionSummaryCard({
    required this.summary,
    required this.previewDate,
  });

  final AttentionSummary summary;
  final DateTime previewDate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = context.reminderPalette;
    final breakdown = ReminderUiText.homeAttentionBreakdownTemplate
        .replaceFirst('{danger}', '${summary.dangerCount}')
        .replaceFirst('{warning}', '${summary.warningCount}')
        .replaceFirst('{stage}', '${summary.stageUpcomingCount}');

    return ReminderPaperCard(
      key: const Key('attention-summary-card'),
      backgroundColor: palette.surfaceWarm,
      padding: const EdgeInsets.all(20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ReminderBadge(
                  label: ReminderFormatters.date(previewDate),
                  icon: Icons.calendar_today_outlined,
                  color: palette.primaryWarmDark,
                  backgroundColor: palette.primaryWarmContainer,
                ),
                const SizedBox(height: 12),
                Text(
                  summary.hasAttention
                      ? '今天有 ${summary.totalCount} 件事需要處理'
                      : ReminderUiText.homeAttentionStable,
                  key: const Key('attention-summary-title'),
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (summary.hasAttention) ...[
                  const SizedBox(height: 8),
                  Text(
                    breakdown,
                    key: const Key('attention-summary-breakdown'),
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: palette.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
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
      return ReminderEmptyState(message: emptyMessage);
    }
    final previewDate = ref.watch(effectivePreviewDateProvider);
    return Column(
      children: [
        for (var index = 0; index < items.length; index++) ...[
          if (index > 0) const SizedBox(height: ReminderSpacing.listGap),
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
    final palette = context.reminderPalette;
    final baseViewModel = ItemCardViewModel.fromEntry(
      widget.entry,
      now: widget.previewDate,
    );
    final viewModel = baseViewModel.copyWith(isExpanded: _isExpanded);
    final stateColor = _itemStateColor(viewModel.displayState, palette);

    return ReminderRailCard(
      key: Key('item-card-${viewModel.id}'),
      railColor: stateColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Tooltip(
                message: widget.entry.bundle.pack.title,
                child: Semantics(
                  label: '生活場景 ${widget.entry.bundle.pack.title}',
                  child: ReminderIconBubble(
                    size: 58,
                    child: Text(widget.entry.bundle.pack.iconEmoji),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          viewModel.title,
                          key: Key('item-${viewModel.id}'),
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        _ItemTypeBadge(
                          label: viewModel.badgeLabel,
                          key: Key('item-badge-${viewModel.id}'),
                        ),
                      ],
                    ),
                    if (viewModel.trailingLabel != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        viewModel.trailingLabel!,
                        key: Key('item-tail-${viewModel.id}'),
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              FilledButton(
                key: Key('item-checkbox-${viewModel.id}'),
                onPressed: viewModel.canComplete
                    ? () => _handleComplete(viewModel)
                    : null,
                child: const Text(ReminderUiText.completeAction),
              ),
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
                icon: Icon(_isExpanded ? Icons.expand_less : Icons.expand_more),
              ),
            ],
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 180),
            child: viewModel.isExpanded
                ? Container(
                    key: Key('item-content-${viewModel.id}'),
                    padding: const EdgeInsets.only(top: 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _ItemDetailRow(
                          label: ReminderUiText.packFieldLabel,
                          value: packDisplayLabel(widget.entry.bundle.pack),
                        ),
                        if (viewModel.note != null)
                          _ItemDetailRow(label: '備註', value: viewModel.note!),
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
    final palette = context.reminderPalette;
    return ReminderBadge(
      label: label,
      color: palette.primaryWarmDark,
      backgroundColor: palette.primaryWarmContainer,
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
            ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          Text(value, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}

Color _itemStateColor(ItemCardDisplayState state, ReminderPalette palette) {
  return switch (state) {
    ItemCardDisplayState.normal => palette.statusNormal,
    ItemCardDisplayState.warning => palette.statusWarning,
    ItemCardDisplayState.danger => palette.statusDanger,
    ItemCardDisplayState.overdue => palette.statusDanger,
    ItemCardDisplayState.notStarted => palette.statusUnknown,
    ItemCardDisplayState.unknown => palette.statusUnknown,
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
      return const ReminderEmptyState(message: '目前沒有需要留意的資源。');
    }
    return Column(
      children: [
        for (var index = 0; index < attentionResources.length; index++) ...[
          if (index > 0) const SizedBox(height: ReminderSpacing.listGap),
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
    final palette = context.reminderPalette;
    final repository = ref.watch(resourceRepositoryProvider);
    final resource = bundle.resource;
    final status = repository.statusFor(resource, now: now);
    return ReminderRailCard(
      key: Key('resource-card-${resource.id}'),
      railColor: _resourceStatusColor(status, palette),
      child: Row(
        children: [
          Tooltip(
            message: bundle.pack.title,
            child: Semantics(
              label: '生活場景 ${bundle.pack.title}',
              child: ReminderIconBubble(
                size: 58,
                child: Text(bundle.pack.iconEmoji),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      resource.title,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    ReminderBadge(
                      label: '庫存',
                      icon: Icons.inventory_2_outlined,
                      color: palette.domainResource,
                      backgroundColor: palette.statusWarningContainer,
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  '${ReminderFormatters.resourceStatus(status)} · ${ReminderFormatters.resourceSummary(resource, now: now)}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ReminderBadge(
            label: ReminderFormatters.resourceTrailingLabel(resource, now: now),
            color: _resourceStatusColor(status, palette),
            backgroundColor: _resourceStatusContainer(status, palette),
          ),
        ],
      ),
    );
  }
}

Color _resourceStatusColor(ResourceStatus status, ReminderPalette palette) {
  return switch (status) {
    ResourceStatus.normal => palette.statusNormal,
    ResourceStatus.warning => palette.statusWarning,
    ResourceStatus.danger => palette.statusDanger,
    ResourceStatus.unknown => palette.statusUnknown,
  };
}

Color _resourceStatusContainer(ResourceStatus status, ReminderPalette palette) {
  return switch (status) {
    ResourceStatus.normal => palette.statusNormalContainer,
    ResourceStatus.warning => palette.statusWarningContainer,
    ResourceStatus.danger => palette.statusDangerContainer,
    ResourceStatus.unknown => palette.statusUnknownContainer,
  };
}

class _StageList extends ConsumerWidget {
  const _StageList({
    required this.items,
    required this.packs,
    required this.trackers,
    required this.emptyMessage,
  });

  final List<StageOccurrence> items;
  final List<ItemPack> packs;
  final List<StageTracker> trackers;
  final String emptyMessage;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (items.isEmpty) {
      return ReminderEmptyState(message: emptyMessage);
    }
    final palette = context.reminderPalette;
    return Column(
      children: [
        for (var index = 0; index < items.length; index++) ...[
          if (index > 0) const SizedBox(height: ReminderSpacing.listGap),
          Builder(
            builder: (context) {
              final occurrence = items[index];
              final viewModel = StageCardViewModel.fromOccurrence(occurrence);
              final pack = _packForOccurrence(occurrence);
              return ReminderRailCard(
                railColor: palette.domainStage,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      key: Key('stage-item-${viewModel.id}'),
                      children: [
                        if (pack != null) ...[
                          Tooltip(
                            message: pack.title,
                            child: Semantics(
                              label: '生活場景 ${pack.title}',
                              child: ReminderIconBubble(
                                size: 58,
                                child: Text(pack.iconEmoji),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                        ],
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Wrap(
                                spacing: 8,
                                runSpacing: 6,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  Text(
                                    viewModel.title,
                                    style: Theme.of(
                                      context,
                                    ).textTheme.titleLarge,
                                  ),
                                  ReminderBadge(
                                    label: ReminderUiText.stageLabel,
                                    icon: Icons.auto_graph_outlined,
                                    color: palette.domainStage,
                                    backgroundColor:
                                        palette.statusNormalContainer,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(viewModel.subtitle),
                            ],
                          ),
                        ),
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

  ItemPack? _packForOccurrence(StageOccurrence occurrence) {
    final tracker = trackers
        .where((item) => item.id == occurrence.stageTrackerId)
        .firstOrNull;
    if (tracker == null) {
      return null;
    }
    for (final pack in packs) {
      if (pack.id == tracker.packId) {
        return pack;
      }
    }
    return null;
  }
}

class _HomeSection extends StatelessWidget {
  const _HomeSection({required this.title, required this.child, this.icon});

  final String title;
  final Widget child;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ReminderSectionHeader(title: title, icon: icon),
        const SizedBox(height: 12),
        child,
      ],
    );
  }
}
