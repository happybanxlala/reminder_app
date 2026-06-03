import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/reminder_theme.dart';
import '../../data/item_repository.dart';
import '../../data/local/reminder_dao.dart';
import '../../domain/item.dart';
import '../../domain/item_action_record.dart';
import '../../domain/item_pack.dart';
import '../../domain/item_status_service.dart';
import '../../presentation/formatters/reminder_formatters.dart';
import '../../presentation/text/reminder_ui_text.dart';
import '../../providers/developer_settings_providers.dart';
import '../../providers/item_providers.dart';
import '../widgets/reminder_components.dart';

enum _ItemHistoryFilter { all, done, reverted, resourceImpact }

class ItemHistoryPage extends ConsumerStatefulWidget {
  const ItemHistoryPage({super.key, required this.itemId});

  static const routeName = 'item-history';
  static const routePath = '/item/:id/history';

  final int itemId;

  @override
  ConsumerState<ItemHistoryPage> createState() => _ItemHistoryPageState();
}

class _ItemHistoryPageState extends ConsumerState<ItemHistoryPage> {
  _ItemHistoryFilter _filter = _ItemHistoryFilter.all;

  @override
  Widget build(BuildContext context) {
    final itemAsync = ref.watch(itemProvider(widget.itemId));
    final historyAsync = ref.watch(itemHistoryEntriesProvider(widget.itemId));
    final previewDate = ref.watch(effectivePreviewDateProvider);

    return Scaffold(
      appBar: AppBar(title: const Text(ReminderUiText.itemHistoryTitle)),
      body: itemAsync.when(
        data: (bundle) {
          if (bundle == null) {
            return ReminderRefreshablePlaceholder(
              onRefresh: _refresh,
              child: const Text(ReminderUiText.itemSaveFailedMessage),
            );
          }
          return historyAsync.when(
            data: (entries) => _ItemHistoryTimeline(
              bundle: bundle,
              entries: _filteredEntries(entries),
              selectedFilter: _filter,
              previewDate: previewDate,
              onFilterChanged: (filter) => setState(() {
                _filter = filter;
              }),
              onRefresh: _refresh,
            ),
            error: (error, stack) => ReminderRefreshablePlaceholder(
              onRefresh: _refresh,
              padding: const EdgeInsets.all(ReminderSpacing.page),
              child: Text('讀取失敗: $error'),
            ),
            loading: () => ReminderRefreshablePlaceholder(
              onRefresh: _refresh,
              child: const CircularProgressIndicator(),
            ),
          );
        },
        error: (error, stack) => ReminderRefreshablePlaceholder(
          onRefresh: _refresh,
          padding: const EdgeInsets.all(ReminderSpacing.page),
          child: Text('讀取失敗: $error'),
        ),
        loading: () => ReminderRefreshablePlaceholder(
          onRefresh: _refresh,
          child: const CircularProgressIndicator(),
        ),
      ),
    );
  }

  Future<void> _refresh() async {
    ref.invalidate(itemProvider(widget.itemId));
    ref.invalidate(itemHistoryEntriesProvider(widget.itemId));
    await Future<void>.delayed(Duration.zero);
  }

  List<ItemHistoryEntry> _filteredEntries(List<ItemHistoryEntry> entries) {
    return entries
        .where((entry) {
          return switch (_filter) {
            _ItemHistoryFilter.all => true,
            _ItemHistoryFilter.done => entry.actionType == ItemActionType.done,
            _ItemHistoryFilter.reverted =>
              entry.actionType == ItemActionType.done && entry.isReverted,
            _ItemHistoryFilter.resourceImpact => entry.hasResourceImpact,
          };
        })
        .toList(growable: false);
  }
}

class _ItemHistoryTimeline extends StatelessWidget {
  const _ItemHistoryTimeline({
    required this.bundle,
    required this.entries,
    required this.selectedFilter,
    required this.previewDate,
    required this.onFilterChanged,
    required this.onRefresh,
  });

  final ItemBundle bundle;
  final List<ItemHistoryEntry> entries;
  final _ItemHistoryFilter selectedFilter;
  final DateTime previewDate;
  final ValueChanged<_ItemHistoryFilter> onFilterChanged;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    final groups = _groupByDate(entries);
    return ReminderRefreshable(
      onRefresh: onRefresh,
      child: ListView(
        key: const Key('item-history-page'),
        physics: reminderRefreshPhysics,
        padding: const EdgeInsets.all(12),
        children: [
          _ItemHistorySummaryCard(bundle: bundle, previewDate: previewDate),
          const SizedBox(height: 10),
          _ItemHistoryFilters(
            selectedFilter: selectedFilter,
            onFilterChanged: onFilterChanged,
          ),
          const SizedBox(height: 12),
          if (entries.isEmpty)
            const _ItemHistoryEmptyState()
          else
            for (final group in groups) ...[
              _ItemHistoryDateHeader(label: group.label),
              for (final entry in group.entries) _ItemTimelineRow(entry: entry),
            ],
        ],
      ),
    );
  }

  List<_ItemHistoryDateGroup> _groupByDate(List<ItemHistoryEntry> entries) {
    final byDate = <DateTime, List<ItemHistoryEntry>>{};
    for (final entry in entries) {
      final key = _dateOnly(entry.actionDate);
      byDate.putIfAbsent(key, () => []).add(entry);
    }
    for (final groupEntries in byDate.values) {
      groupEntries.sort((a, b) {
        final dateCompare = b.actionDate.compareTo(a.actionDate);
        if (dateCompare != 0) {
          return dateCompare;
        }
        return b.actionRecordId.compareTo(a.actionRecordId);
      });
    }
    final dates = byDate.keys.toList()..sort((a, b) => b.compareTo(a));
    final today = _dateOnly(previewDate);
    final yesterday = today.subtract(const Duration(days: 1));
    return dates
        .map(
          (date) => _ItemHistoryDateGroup(
            label: _dateGroupLabel(date, today: today, yesterday: yesterday),
            entries: byDate[date]!,
          ),
        )
        .toList(growable: false);
  }

  String _dateGroupLabel(
    DateTime date, {
    required DateTime today,
    required DateTime yesterday,
  }) {
    if (date == today) {
      return ReminderUiText.todayDateGroupLabel;
    }
    if (date == yesterday) {
      return ReminderUiText.yesterdayDateGroupLabel;
    }
    return ReminderFormatters.date(date);
  }
}

class _ItemHistoryDateGroup {
  const _ItemHistoryDateGroup({required this.label, required this.entries});

  final String label;
  final List<ItemHistoryEntry> entries;
}

class _ItemHistorySummaryCard extends StatelessWidget {
  const _ItemHistorySummaryCard({
    required this.bundle,
    required this.previewDate,
  });

  final ItemBundle bundle;
  final DateTime previewDate;

  @override
  Widget build(BuildContext context) {
    final palette = context.reminderPalette;
    final status = const ItemStatusService().classify(
      bundle.item,
      now: previewDate,
    );
    return ReminderRailCard(
      key: const Key('item-history-summary-card'),
      railColor: _statusColor(status, palette),
      padding: const EdgeInsets.all(12),
      radius: 16,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _ItemHistoryPackChip(pack: bundle.pack),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  bundle.item.title,
                  key: Key('item-history-title-${bundle.item.id}'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${_itemHistoryTypeLabel(bundle.item.type)}・目前${ReminderFormatters.itemStatus(status)}',
            key: const Key('item-history-summary-status'),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: palette.textSecondary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '${bundle.pack.iconEmoji} ${bundle.pack.title}',
            key: const Key('item-history-summary-pack'),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: palette.textMuted,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _ItemHistoryPackChip extends StatelessWidget {
  const _ItemHistoryPackChip({required this.pack});

  final ItemPack pack;

  @override
  Widget build(BuildContext context) {
    final palette = context.reminderPalette;
    return Tooltip(
      message: pack.title,
      child: Container(
        key: Key('item-history-pack-chip-${pack.id}'),
        width: 28,
        height: 28,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: palette.surfaceWarm,
          shape: BoxShape.circle,
          border: Border.all(color: palette.borderSubtle),
        ),
        child: Text(pack.iconEmoji, style: const TextStyle(fontSize: 15)),
      ),
    );
  }
}

class _ItemHistoryFilters extends StatelessWidget {
  const _ItemHistoryFilters({
    required this.selectedFilter,
    required this.onFilterChanged,
  });

  final _ItemHistoryFilter selectedFilter;
  final ValueChanged<_ItemHistoryFilter> onFilterChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      key: const Key('item-history-filters'),
      spacing: 6,
      runSpacing: 4,
      children: [
        for (final filter in _ItemHistoryFilter.values)
          ChoiceChip(
            key: Key('item-history-filter-${filter.name}'),
            label: Text(_filterLabel(filter)),
            selected: selectedFilter == filter,
            visualDensity: VisualDensity.compact,
            onSelected: (_) => onFilterChanged(filter),
          ),
      ],
    );
  }

  String _filterLabel(_ItemHistoryFilter filter) {
    return switch (filter) {
      _ItemHistoryFilter.all => ReminderUiText.itemHistoryFilterAll,
      _ItemHistoryFilter.done => ReminderUiText.itemHistoryFilterDone,
      _ItemHistoryFilter.reverted => ReminderUiText.itemHistoryFilterReverted,
      _ItemHistoryFilter.resourceImpact =>
        ReminderUiText.itemHistoryFilterResourceImpact,
    };
  }
}

class _ItemHistoryDateHeader extends StatelessWidget {
  const _ItemHistoryDateHeader({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(2, 8, 2, 6),
      child: Text(
        label,
        key: Key('item-history-date-$label'),
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
          color: context.reminderPalette.textSecondary,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _ItemTimelineRow extends StatelessWidget {
  const _ItemTimelineRow({required this.entry});

  final ItemHistoryEntry entry;

  @override
  Widget build(BuildContext context) {
    final palette = context.reminderPalette;
    final isRevertedDone =
        entry.actionType == ItemActionType.done && entry.isReverted;
    final actionColor = isRevertedDone
        ? palette.textMuted
        : _actionColor(entry.actionType, palette);
    return Container(
      key: Key('item-history-row-${entry.actionRecordId}'),
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(12)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 18,
            child: Column(
              children: [
                Container(
                  key: Key('item-history-marker-${entry.actionRecordId}'),
                  width: 10,
                  height: 10,
                  margin: const EdgeInsets.only(top: 5),
                  decoration: BoxDecoration(
                    color: actionColor,
                    shape: BoxShape.circle,
                  ),
                ),
                Container(
                  width: 1,
                  height: entry.hasResourceImpact ? 48 : 34,
                  margin: const EdgeInsets.only(top: 4),
                  color: palette.borderSubtle,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _actionSymbol(entry),
                      key: Key(
                        'item-history-action-icon-${entry.actionRecordId}',
                      ),
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: actionColor,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        entry.titleLabel,
                        key: Key(
                          'item-history-action-title-${entry.actionRecordId}',
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: palette.textPrimary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  _metadataText(entry),
                  key: Key('item-history-action-meta-${entry.actionRecordId}'),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: palette.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (entry.resourceImpacts.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  for (final impact in entry.resourceImpacts)
                    _ResourceImpactRow(
                      key: Key(
                        'item-history-resource-impact-${entry.actionRecordId}-${impact.resourceId}-${impact.isCompensation}',
                      ),
                      impact: impact,
                    ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _metadataText(ItemHistoryEntry entry) {
    if (entry.actionType != ItemActionType.done) {
      return ReminderFormatters.dateTime(entry.actionDate);
    }
    final completed =
        '${ReminderUiText.itemHistoryCompletedAtLabel} ${ReminderFormatters.dateTime(entry.actionDate)}';
    final revertedAt = entry.revertedAt;
    if (revertedAt == null) {
      return completed;
    }
    return '$completed・${ReminderUiText.itemHistoryRevertedAtLabel} ${ReminderFormatters.dateTime(revertedAt)}';
  }
}

class _ResourceImpactRow extends StatelessWidget {
  const _ResourceImpactRow({super.key, required this.impact});

  final ItemResourceImpactEntry impact;

  @override
  Widget build(BuildContext context) {
    final palette = context.reminderPalette;
    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: Row(
        children: [
          Icon(
            Icons.inventory_2_outlined,
            size: 14,
            color: impact.isCompensation
                ? palette.textMuted
                : palette.domainResource,
          ),
          const SizedBox(width: 5),
          Expanded(
            child: Text(
              impact.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: palette.textSecondary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ItemHistoryEmptyState extends StatelessWidget {
  const _ItemHistoryEmptyState();

  @override
  Widget build(BuildContext context) {
    final palette = context.reminderPalette;
    return Container(
      key: const Key('item-history-empty'),
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: palette.surfaceWarm,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: palette.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            ReminderUiText.itemHistoryEmptyTitle,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: palette.textSecondary,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            ReminderUiText.itemHistoryEmptySubtitle,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: palette.textMuted),
          ),
        ],
      ),
    );
  }
}

Color _statusColor(ItemStatus status, ReminderPalette palette) {
  return switch (status) {
    ItemStatus.normal => palette.statusNormal,
    ItemStatus.warning => palette.statusWarning,
    ItemStatus.danger => palette.statusDanger,
    ItemStatus.unknown => palette.statusUnknown,
  };
}

Color _actionColor(ItemActionType actionType, ReminderPalette palette) {
  return switch (actionType) {
    ItemActionType.created => palette.domainItem,
    ItemActionType.done => palette.statusNormal,
    ItemActionType.skipped => palette.statusWarning,
    ItemActionType.deferred => palette.primaryWarm,
    ItemActionType.reverted => palette.textMuted,
  };
}

String _actionSymbol(ItemHistoryEntry entry) {
  if (entry.actionType == ItemActionType.done && entry.isReverted) {
    return '↩';
  }
  return switch (entry.actionType) {
    ItemActionType.done => '✓',
    ItemActionType.created => '+',
    ItemActionType.skipped => '–',
    ItemActionType.deferred => '→',
    ItemActionType.reverted => '↩',
  };
}

String _itemHistoryTypeLabel(ItemType type) {
  return switch (type) {
    ItemType.fixed => ReminderUiText.fixedItemTypeTitle,
    ItemType.stateBased => ReminderUiText.stateBasedItemTypeTitle,
  };
}

DateTime _dateOnly(DateTime value) {
  return DateTime(value.year, value.month, value.day);
}
