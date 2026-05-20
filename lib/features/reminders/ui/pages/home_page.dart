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
import 'resource_history_page.dart';
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

class _HomeDensity {
  const _HomeDensity._();

  static const pagePadding = 12.0;
  static const sectionGap = 12.0;
  static const headerGap = 8.0;
  static const listGap = 6.0;
  static const cardPaddingVertical = 8.0;
  static const cardPaddingHorizontal = 10.0;
  static const cardRadius = 16.0;
  static const packChipSize = 26.0;

  static const cardPadding = EdgeInsets.symmetric(
    vertical: cardPaddingVertical,
    horizontal: cardPaddingHorizontal,
  );
}

class HomeContent extends ConsumerStatefulWidget {
  const HomeContent({super.key});

  @override
  ConsumerState<HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends ConsumerState<HomeContent> {
  int? _selectedPackId;
  String? _expandedEntryKey;
  bool _isTodayCompletedExpanded = false;

  @override
  Widget build(BuildContext context) {
    final summaryAsync = ref.watch(attentionSummaryProvider);
    final dangerAsync = ref.watch(dangerHomeAttentionEntriesProvider);
    final warningAsync = ref.watch(warningHomeAttentionEntriesProvider);
    final stagesAsync = ref.watch(upcomingStagesProvider);
    final completedAsync = ref.watch(todayCompletedEntriesProvider);
    final packsAsync = ref.watch(activeItemPacksProvider);
    final trackersAsync = ref.watch(stageTrackersProvider);
    final previewDate = ref.watch(effectivePreviewDateProvider);
    final packs = packsAsync.valueOrNull ?? const <ItemPack>[];
    final trackers = trackersAsync.valueOrNull ?? const <StageTracker>[];

    return ListView(
      padding: const EdgeInsets.all(_HomeDensity.pagePadding),
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
        const SizedBox(height: _HomeDensity.sectionGap),
        _HomePackFilter(
          packs: packs,
          selectedPackId: _selectedPackId,
          onChanged: (packId) {
            setState(() {
              _selectedPackId = packId;
              _expandedEntryKey = null;
              _isTodayCompletedExpanded = false;
            });
          },
        ),
        const SizedBox(height: _HomeDensity.sectionGap),
        _HomeSection(
          title: ReminderUiText.dangerTab,
          icon: Icons.error_outline,
          child: dangerAsync.when(
            data: (items) => _AttentionEntryList(
              entries: _filterAttentionEntries(items),
              emptyMessage: ReminderUiText.noDangerItems,
              expandedEntryKey: _expandedEntryKey,
              onToggleEntry: _toggleEntry,
            ),
            error: (error, stack) => Text('讀取失敗: $error'),
            loading: () => const Center(child: CircularProgressIndicator()),
          ),
        ),
        const SizedBox(height: _HomeDensity.sectionGap),
        _HomeSection(
          title: ReminderUiText.warningTab,
          icon: Icons.visibility_outlined,
          child: warningAsync.when(
            data: (items) => _AttentionEntryList(
              entries: _filterAttentionEntries(items),
              emptyMessage: ReminderUiText.noWarningItems,
              expandedEntryKey: _expandedEntryKey,
              onToggleEntry: _toggleEntry,
            ),
            error: (error, stack) => Text('讀取失敗: $error'),
            loading: () => const Center(child: CircularProgressIndicator()),
          ),
        ),
        const SizedBox(height: _HomeDensity.sectionGap),
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
        completedAsync.when(
          data: (items) {
            final filtered = _filterCompletedEntries(items);
            if (filtered.isEmpty) {
              return const SizedBox.shrink();
            }
            return Padding(
              padding: const EdgeInsets.only(top: _HomeDensity.sectionGap),
              child: _TodayCompletedSection(
                entries: filtered,
                isExpanded: _isTodayCompletedExpanded,
                onToggle: () {
                  setState(() {
                    _isTodayCompletedExpanded = !_isTodayCompletedExpanded;
                  });
                },
              ),
            );
          },
          error: (error, stack) => Padding(
            padding: const EdgeInsets.only(top: _HomeDensity.sectionGap),
            child: Text('讀取失敗: $error'),
          ),
          loading: () => const SizedBox.shrink(),
        ),
        const ReminderFooterMark(),
      ],
    );
  }

  void _toggleEntry(String key) {
    setState(() {
      _expandedEntryKey = _expandedEntryKey == key ? null : key;
    });
  }

  List<HomeAttentionEntry> _filterAttentionEntries(
    List<HomeAttentionEntry> items,
  ) {
    final packId = _selectedPackId;
    if (packId == null) {
      return items;
    }
    return items
        .where((entry) => entry.packId == packId)
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

  List<TodayCompletedEntry> _filterCompletedEntries(
    List<TodayCompletedEntry> entries,
  ) {
    final packId = _selectedPackId;
    if (packId == null) {
      return entries;
    }
    return entries
        .where((entry) => entry.packId == packId)
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
      padding: const EdgeInsets.all(14),
      radius: _HomeDensity.cardRadius,
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
                const SizedBox(height: 8),
                Text(
                  summary.hasAttention
                      ? ReminderUiText.homeAttentionTitleTemplate.replaceFirst(
                          '{total}',
                          '${summary.totalCount}',
                        )
                      : ReminderUiText.homeAttentionStable,
                  key: const Key('attention-summary-title'),
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (summary.hasAttention) ...[
                  const SizedBox(height: 4),
                  Text(
                    breakdown,
                    key: const Key('attention-summary-breakdown'),
                    style: theme.textTheme.bodyMedium?.copyWith(
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

class _AttentionEntryList extends ConsumerWidget {
  const _AttentionEntryList({
    required this.entries,
    required this.emptyMessage,
    required this.expandedEntryKey,
    required this.onToggleEntry,
  });

  final List<HomeAttentionEntry> entries;
  final String emptyMessage;
  final String? expandedEntryKey;
  final ValueChanged<String> onToggleEntry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (entries.isEmpty) {
      return _HomeCompactEmptyState(message: emptyMessage);
    }
    final previewDate = ref.watch(effectivePreviewDateProvider);
    return Column(
      children: [
        for (var index = 0; index < entries.length; index++) ...[
          if (index > 0) const SizedBox(height: _HomeDensity.listGap),
          switch (entries[index].type) {
            HomeAttentionEntryType.item => _ItemCard(
              entryKey: entries[index].stableKey,
              entry: entries[index].itemEntry!,
              previewDate: previewDate,
              isExpanded: expandedEntryKey == entries[index].stableKey,
              onToggle: () => onToggleEntry(entries[index].stableKey),
            ),
            HomeAttentionEntryType.resource => _ResourceCard(
              entryKey: entries[index].stableKey,
              bundle: entries[index].resourceBundle!,
              now: previewDate,
              isExpanded: expandedEntryKey == entries[index].stableKey,
              onToggle: () => onToggleEntry(entries[index].stableKey),
            ),
          },
        ],
      ],
    );
  }
}

class _HomeCompactEmptyState extends StatelessWidget {
  const _HomeCompactEmptyState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final palette = context.reminderPalette;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: palette.surfaceWarm,
        borderRadius: BorderRadius.circular(_HomeDensity.cardRadius),
        border: Border.all(color: palette.borderSubtle),
      ),
      child: Row(
        children: [
          Icon(
            Icons.check_circle_outline,
            size: 18,
            color: palette.statusNormal,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(message, style: Theme.of(context).textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }
}

class _ItemCard extends ConsumerWidget {
  const _ItemCard({
    required this.entryKey,
    required this.entry,
    required this.previewDate,
    required this.isExpanded,
    required this.onToggle,
  });

  final String entryKey;
  final ItemHomeEntry entry;
  final DateTime previewDate;
  final bool isExpanded;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = context.reminderPalette;
    final baseViewModel = ItemCardViewModel.fromEntry(entry, now: previewDate);
    final viewModel = baseViewModel.copyWith(isExpanded: isExpanded);
    final stateColor = _itemStateColor(viewModel.displayState, palette);

    return ReminderRailCard(
      key: Key('item-card-${viewModel.id}'),
      railColor: stateColor,
      padding: _HomeDensity.cardPadding,
      radius: _HomeDensity.cardRadius,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: InkWell(
                  key: Key('home-card-body-$entryKey'),
                  onTap: onToggle,
                  borderRadius: BorderRadius.circular(_HomeDensity.cardRadius),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: Row(
                      children: [
                        _PackEmojiChip(pack: entry.bundle.pack),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            viewModel.title,
                            key: Key('item-${viewModel.id}'),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                        if (viewModel.trailingLabel != null) ...[
                          const SizedBox(width: 8),
                          Text(
                            viewModel.trailingLabel!,
                            key: Key('item-tail-${viewModel.id}'),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: _itemStateColor(
                                    viewModel.displayState,
                                    palette,
                                  ),
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              IconButton(
                key: Key('item-checkbox-${viewModel.id}'),
                onPressed: viewModel.canComplete
                    ? () => _handleComplete(ref, viewModel)
                    : null,
                tooltip: ReminderUiText.completeAction,
                icon: const Icon(Icons.check_rounded),
                visualDensity: VisualDensity.compact,
                constraints: const BoxConstraints.tightFor(
                  width: 36,
                  height: 36,
                ),
              ),
            ],
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 160),
            child: viewModel.isExpanded
                ? Container(
                    key: Key('item-content-${viewModel.id}'),
                    padding: const EdgeInsets.only(top: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _HomeDetailRow(
                          label: '類型',
                          value: viewModel.badgeLabel,
                        ),
                        _HomeDetailRow(
                          label: ReminderUiText.packFieldLabel,
                          value: packDisplayLabel(entry.bundle.pack),
                        ),
                        if (viewModel.note != null)
                          _HomeDetailRow(label: '備註', value: viewModel.note!),
                        if (viewModel.anchorDateLabel != null)
                          _HomeDetailRow(
                            label: '開始日期',
                            value: viewModel.anchorDateLabel!,
                          ),
                        if (viewModel.dueDateLabel != null)
                          _HomeDetailRow(
                            label: '到期日期',
                            value: viewModel.dueDateLabel!,
                          ),
                        if (viewModel.overduePolicyLabel != null)
                          _HomeDetailRow(
                            label: '逾期策略',
                            value: viewModel.overduePolicyLabel!,
                          ),
                        const SizedBox(height: 4),
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: [
                            if (viewModel.canSkip)
                              TextButton(
                                key: Key('item-skip-${viewModel.id}'),
                                onPressed: () async {
                                  await ref
                                      .read(itemRepositoryProvider)
                                      .skip(
                                        viewModel.id,
                                        actionAt: previewDate,
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

  Future<void> _handleComplete(
    WidgetRef ref,
    ItemCardViewModel viewModel,
  ) async {
    await ref
        .read(itemRepositoryProvider)
        .markDone(viewModel.id, doneAt: previewDate);
  }
}

class _PackEmojiChip extends StatelessWidget {
  const _PackEmojiChip({required this.pack});

  final ItemPack pack;

  @override
  Widget build(BuildContext context) {
    final palette = context.reminderPalette;
    return Tooltip(
      message: pack.title,
      child: Semantics(
        label: '生活場景 ${pack.title}',
        child: Container(
          key: Key('home-pack-chip-${pack.id}'),
          width: _HomeDensity.packChipSize,
          height: _HomeDensity.packChipSize,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: palette.surfaceWarm,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: palette.borderSubtle),
          ),
          child: Text(pack.iconEmoji, style: const TextStyle(fontSize: 15)),
        ),
      ),
    );
  }
}

class _HomeDetailRow extends StatelessWidget {
  const _HomeDetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: Wrap(
        spacing: 4,
        children: [
          Text(
            '$label：',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          Text(value, style: Theme.of(context).textTheme.bodySmall),
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

class _ResourceCard extends ConsumerWidget {
  const _ResourceCard({
    required this.entryKey,
    required this.bundle,
    required this.now,
    required this.isExpanded,
    required this.onToggle,
  });

  final String entryKey;
  final ResourceBundle bundle;
  final DateTime now;
  final bool isExpanded;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = context.reminderPalette;
    final repository = ref.watch(resourceRepositoryProvider);
    final resource = bundle.resource;
    final status = repository.statusFor(resource, now: now);
    return ReminderRailCard(
      key: Key('resource-card-${resource.id}'),
      railColor: _resourceStatusColor(status, palette),
      padding: _HomeDensity.cardPadding,
      radius: _HomeDensity.cardRadius,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: InkWell(
                  key: Key('home-card-body-$entryKey'),
                  onTap: onToggle,
                  borderRadius: BorderRadius.circular(_HomeDensity.cardRadius),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: Row(
                      children: [
                        _PackEmojiChip(pack: bundle.pack),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            resource.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          ReminderFormatters.resourceTrailingLabel(
                            resource,
                            now: now,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: _resourceStatusColor(status, palette),
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              IconButton(
                key: Key('resource-refill-${resource.id}'),
                onPressed: () =>
                    _showResourceRefillDialog(context, ref, resource),
                tooltip: '補充',
                icon: const Icon(Icons.add_rounded),
                visualDensity: VisualDensity.compact,
                constraints: const BoxConstraints.tightFor(
                  width: 36,
                  height: 36,
                ),
              ),
            ],
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 160),
            child: isExpanded
                ? Container(
                    key: Key('resource-content-${resource.id}'),
                    padding: const EdgeInsets.only(top: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _HomeDetailRow(
                          label: '類型',
                          value: ReminderFormatters.resourceType(resource.type),
                        ),
                        _HomeDetailRow(
                          label: ReminderUiText.packFieldLabel,
                          value: packDisplayLabel(bundle.pack),
                        ),
                        _HomeDetailRow(
                          label: '狀態',
                          value: ReminderFormatters.resourceStatus(status),
                        ),
                        _HomeDetailRow(
                          label: '摘要',
                          value: ReminderFormatters.resourceSummary(
                            resource,
                            now: now,
                          ),
                        ),
                        const SizedBox(height: 4),
                        TextButton(
                          key: Key('resource-history-${resource.id}'),
                          onPressed: () {
                            context.pushNamed(
                              ResourceHistoryPage.routeName,
                              pathParameters: {'id': resource.id.toString()},
                            );
                          },
                          child: const Text('歷史紀錄'),
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

  Future<void> _showResourceRefillDialog(
    BuildContext context,
    WidgetRef ref,
    Resource resource,
  ) async {
    final input = await showDialog<int>(
      context: context,
      builder: (dialogContext) => _HomeNumberInputDialog(
        title: '補充資源',
        label: resource.config is TimeBasedResourceConfig ? '新增可用天數' : '新增數量',
      ),
    );
    if (input == null || !context.mounted) {
      return;
    }
    await ref
        .read(resourceRepositoryProvider)
        .refillResource(
          resource.id,
          actionAt: now,
          addedDays: resource.config is TimeBasedResourceConfig ? input : null,
          addedQuantity: resource.config is QuantityBasedResourceConfig
              ? input
              : null,
        );
  }
}

class _HomeNumberInputDialog extends StatefulWidget {
  const _HomeNumberInputDialog({required this.title, required this.label});

  final String title;
  final String label;

  @override
  State<_HomeNumberInputDialog> createState() => _HomeNumberInputDialogState();
}

class _HomeNumberInputDialogState extends State<_HomeNumberInputDialog> {
  final _controller = TextEditingController(text: '1');
  String? _errorText;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: TextField(
        controller: _controller,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          labelText: widget.label,
          errorText: _errorText,
        ),
        autofocus: true,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text(ReminderUiText.closeAction),
        ),
        FilledButton(
          onPressed: _submit,
          child: const Text(ReminderUiText.confirmAction),
        ),
      ],
    );
  }

  void _submit() {
    final value = int.tryParse(_controller.text.trim());
    if (value == null || value <= 0) {
      setState(() {
        _errorText = ReminderUiText.resourceCompletionDialogError;
      });
      return;
    }
    Navigator.of(context).pop(value);
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
      return _HomeCompactEmptyState(message: emptyMessage);
    }
    final palette = context.reminderPalette;
    return Column(
      children: [
        for (var index = 0; index < items.length; index++) ...[
          if (index > 0) const SizedBox(height: _HomeDensity.listGap),
          Builder(
            builder: (context) {
              final occurrence = items[index];
              final viewModel = StageCardViewModel.fromOccurrence(occurrence);
              final pack = _packForOccurrence(occurrence);
              return ReminderRailCard(
                railColor: palette.domainStage,
                padding: _HomeDensity.cardPadding,
                radius: _HomeDensity.cardRadius,
                child: Row(
                  key: Key('stage-item-${viewModel.id}'),
                  children: [
                    if (pack != null) ...[
                      _PackEmojiChip(pack: pack),
                      const SizedBox(width: 8),
                    ],
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            viewModel.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            viewModel.subtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      key: Key('stage-ack-${viewModel.id}'),
                      onPressed: () async {
                        await ref
                            .read(stageTrackerRepositoryProvider)
                            .acknowledgeOccurrence(occurrence);
                      },
                      tooltip: ReminderUiText.acknowledgedAction,
                      icon: const Icon(Icons.check_circle_outline_rounded),
                      visualDensity: VisualDensity.compact,
                      constraints: const BoxConstraints.tightFor(
                        width: 36,
                        height: 36,
                      ),
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

class _TodayCompletedSection extends StatelessWidget {
  const _TodayCompletedSection({
    required this.entries,
    required this.isExpanded,
    required this.onToggle,
  });

  final List<TodayCompletedEntry> entries;
  final bool isExpanded;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final palette = context.reminderPalette;
    return ReminderRailCard(
      key: const Key('today-completed-section'),
      railColor: palette.statusNormal,
      padding: _HomeDensity.cardPadding,
      radius: _HomeDensity.cardRadius,
      child: Column(
        children: [
          InkWell(
            key: const Key('today-completed-header'),
            onTap: onToggle,
            borderRadius: BorderRadius.circular(_HomeDensity.cardRadius),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                children: [
                  Icon(
                    Icons.task_alt_rounded,
                    size: 18,
                    color: palette.statusNormal,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      ReminderUiText.todayCompletedSummary(entries.length),
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Icon(
                    isExpanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 160),
            child: isExpanded
                ? Padding(
                    key: const Key('today-completed-content'),
                    padding: const EdgeInsets.only(top: 8),
                    child: Column(
                      children: [
                        for (
                          var index = 0;
                          index < entries.length;
                          index++
                        ) ...[
                          if (index > 0)
                            const SizedBox(height: _HomeDensity.listGap),
                          _TodayCompletedRow(entry: entries[index]),
                        ],
                      ],
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

class _TodayCompletedRow extends ConsumerWidget {
  const _TodayCompletedRow({required this.entry});

  final TodayCompletedEntry entry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = context.reminderPalette;
    return Container(
      key: Key('today-completed-row-${entry.stableKey}'),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: palette.surfaceWarm,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: palette.borderSubtle),
      ),
      child: Row(
        children: [
          Icon(_iconForEntry(), size: 18, color: _colorForEntry(palette)),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.title,
                  key: Key('today-completed-title-${entry.stableKey}'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Text(
                  _subtitle(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          if (entry.type == TodayCompletedEntryType.itemDone && entry.canUndo)
            IconButton(
              key: Key('today-completed-undo-${entry.itemActionRecord!.id}'),
              onPressed: () => _undoDone(context, ref),
              tooltip: ReminderUiText.restoreIncompleteAction,
              icon: const Icon(Icons.undo_rounded),
              visualDensity: VisualDensity.compact,
              constraints: const BoxConstraints.tightFor(width: 36, height: 36),
            ),
        ],
      ),
    );
  }

  IconData _iconForEntry() {
    return switch (entry.type) {
      TodayCompletedEntryType.itemDone => Icons.check_rounded,
      TodayCompletedEntryType.resourceRefilled => Icons.add_rounded,
      TodayCompletedEntryType.resourceAdjusted => Icons.tune_rounded,
      TodayCompletedEntryType.stageAcknowledged =>
        Icons.check_circle_outline_rounded,
    };
  }

  Color _colorForEntry(ReminderPalette palette) {
    return switch (entry.type) {
      TodayCompletedEntryType.itemDone => palette.statusNormal,
      TodayCompletedEntryType.resourceRefilled => palette.domainResource,
      TodayCompletedEntryType.resourceAdjusted => palette.domainResource,
      TodayCompletedEntryType.stageAcknowledged => palette.domainStage,
    };
  }

  String _subtitle() {
    final action = switch (entry.type) {
      TodayCompletedEntryType.itemDone => '完成',
      TodayCompletedEntryType.resourceRefilled => '已補充',
      TodayCompletedEntryType.resourceAdjusted => '已修正',
      TodayCompletedEntryType.stageAcknowledged =>
        ReminderUiText.acknowledgedAction,
    };
    return '${ReminderFormatters.date(entry.actionDate)} $action';
  }

  Future<void> _undoDone(BuildContext context, WidgetRef ref) async {
    final record = entry.itemActionRecord;
    if (record == null) {
      return;
    }
    final previewDate = ref.read(effectivePreviewDateProvider);
    final success = await ref
        .read(itemRepositoryProvider)
        .undoDone(record.id, revertedAt: previewDate);
    if (!context.mounted || !success) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text(ReminderUiText.restoredIncompleteMessage)),
    );
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
        const SizedBox(height: _HomeDensity.headerGap),
        child,
      ],
    );
  }
}
