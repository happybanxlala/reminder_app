import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/reminder_theme.dart';
import '../../data/local/reminder_dao.dart';
import '../../domain/item_pack.dart';
import '../../domain/resource.dart';
import '../../domain/resource_status_service.dart';
import '../../presentation/formatters/reminder_formatters.dart';
import '../../presentation/text/reminder_ui_text.dart';
import '../../providers/developer_settings_providers.dart';
import '../../providers/resource_providers.dart';
import '../widgets/reminder_components.dart';

enum _ResourceHistoryFilter { all, refilled, consumed, adjusted, reverted }

class ResourceHistoryPage extends ConsumerStatefulWidget {
  const ResourceHistoryPage({super.key, required this.resourceId});

  static const routeName = 'resource-history';
  static const routePath = '/resource/:id/history';

  final int resourceId;

  @override
  ConsumerState<ResourceHistoryPage> createState() =>
      _ResourceHistoryPageState();
}

class _ResourceHistoryPageState extends ConsumerState<ResourceHistoryPage> {
  _ResourceHistoryFilter _filter = _ResourceHistoryFilter.all;
  bool _showReverted = false;

  @override
  Widget build(BuildContext context) {
    final resourceAsync = ref.watch(resourceProvider(widget.resourceId));
    final historyAsync = ref.watch(
      _showReverted
          ? resourceActionHistoryEntriesWithRevertedProvider(widget.resourceId)
          : resourceActionHistoryEntriesProvider(widget.resourceId),
    );
    final previewDate = ref.watch(effectivePreviewDateProvider);

    return Scaffold(
      appBar: AppBar(title: const Text(ReminderUiText.resourceHistoryTitle)),
      body: resourceAsync.when(
        data: (bundle) {
          if (bundle == null) {
            return ReminderRefreshablePlaceholder(
              onRefresh: _refresh,
              child: const Text(ReminderUiText.resourceSaveFailedMessage),
            );
          }
          return historyAsync.when(
            data: (entries) => _ResourceHistoryTimeline(
              bundle: bundle,
              entries: _filteredEntries(entries),
              selectedFilter: _filter,
              showReverted: _showReverted,
              previewDate: previewDate,
              onFilterChanged: (filter) => setState(() {
                _filter = filter;
              }),
              onShowRevertedChanged: (value) => setState(() {
                _showReverted = value;
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
    ref.invalidate(resourceProvider(widget.resourceId));
    ref.invalidate(resourceActionHistoryEntriesProvider(widget.resourceId));
    ref.invalidate(
      resourceActionHistoryEntriesWithRevertedProvider(widget.resourceId),
    );
    await Future<void>.delayed(Duration.zero);
  }

  List<ResourceActionHistoryEntry> _filteredEntries(
    List<ResourceActionHistoryEntry> entries,
  ) {
    return entries
        .where((entry) {
          return switch (_filter) {
            _ResourceHistoryFilter.all => true,
            _ResourceHistoryFilter.refilled =>
              entry.record.actionType == ResourceActionType.refilled,
            _ResourceHistoryFilter.consumed =>
              entry.record.actionType == ResourceActionType.consumed,
            _ResourceHistoryFilter.adjusted =>
              entry.record.actionType == ResourceActionType.adjusted,
            _ResourceHistoryFilter.reverted =>
              entry.record.actionType == ResourceActionType.reverted,
          };
        })
        .toList(growable: false);
  }
}

class _ResourceHistoryTimeline extends StatelessWidget {
  const _ResourceHistoryTimeline({
    required this.bundle,
    required this.entries,
    required this.selectedFilter,
    required this.showReverted,
    required this.previewDate,
    required this.onFilterChanged,
    required this.onShowRevertedChanged,
    required this.onRefresh,
  });

  final ResourceBundle bundle;
  final List<ResourceActionHistoryEntry> entries;
  final _ResourceHistoryFilter selectedFilter;
  final bool showReverted;
  final DateTime previewDate;
  final ValueChanged<_ResourceHistoryFilter> onFilterChanged;
  final ValueChanged<bool> onShowRevertedChanged;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    final groups = _groupByDate(entries);
    return ReminderRefreshable(
      onRefresh: onRefresh,
      child: ListView(
        key: const Key('resource-history-page'),
        physics: reminderRefreshPhysics,
        padding: const EdgeInsets.all(12),
        children: [
          _ResourceHistorySummaryCard(bundle: bundle, previewDate: previewDate),
          const SizedBox(height: 10),
          _ResourceHistoryFilters(
            selectedFilter: selectedFilter,
            showReverted: showReverted,
            onFilterChanged: onFilterChanged,
            onShowRevertedChanged: onShowRevertedChanged,
          ),
          const SizedBox(height: 12),
          if (entries.isEmpty)
            const _ResourceHistoryEmptyState()
          else
            for (final group in groups) ...[
              _ResourceHistoryDateHeader(label: group.label),
              for (final entry in group.entries)
                _ResourceTimelineRow(entry: entry, resource: bundle.resource),
            ],
        ],
      ),
    );
  }

  List<_ResourceHistoryDateGroup> _groupByDate(
    List<ResourceActionHistoryEntry> entries,
  ) {
    final byDate = <DateTime, List<ResourceActionHistoryEntry>>{};
    for (final entry in entries) {
      final key = _dateOnly(entry.record.actionDate);
      byDate.putIfAbsent(key, () => []).add(entry);
    }
    final dates = byDate.keys.toList()..sort((a, b) => b.compareTo(a));
    final today = _dateOnly(previewDate);
    final yesterday = today.subtract(const Duration(days: 1));
    return dates
        .map(
          (date) => _ResourceHistoryDateGroup(
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

class _ResourceHistoryDateGroup {
  const _ResourceHistoryDateGroup({required this.label, required this.entries});

  final String label;
  final List<ResourceActionHistoryEntry> entries;
}

class _ResourceHistorySummaryCard extends ConsumerWidget {
  const _ResourceHistorySummaryCard({
    required this.bundle,
    required this.previewDate,
  });

  final ResourceBundle bundle;
  final DateTime previewDate;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resource = bundle.resource;
    final repository = ref.watch(resourceRepositoryProvider);
    final status = repository.statusFor(resource, now: previewDate);
    final palette = context.reminderPalette;
    final statusColor = _statusColor(status, palette);
    final summaryRows = _summaryRows(resource, previewDate);
    return ReminderRailCard(
      key: const Key('resource-history-summary-card'),
      railColor: statusColor,
      padding: const EdgeInsets.all(12),
      radius: 16,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _ResourceHistoryPackChip(pack: bundle.pack),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  resource.title,
                  key: Key('resource-history-title-${resource.id}'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          for (final row in summaryRows) ...[
            Text(
              row,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: palette.textSecondary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 2),
          ],
          Text(
            '${ReminderUiText.resourceHistoryStatusLabel}：${_resourceStatusLabel(resource, status)}',
            key: const Key('resource-history-status-label'),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: statusColor,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  List<String> _summaryRows(Resource resource, DateTime previewDate) {
    return switch (resource.config) {
      QuantityBasedResourceConfig config => [
        '${ReminderUiText.resourceHistoryCurrentLabel}：${config.currentQuantity} ${config.unitLabel}',
      ],
      TimeBasedResourceConfig config => _timeSummaryRows(config, previewDate),
      _ => const <String>[],
    };
  }

  List<String> _timeSummaryRows(
    TimeBasedResourceConfig config,
    DateTime previewDate,
  ) {
    const statusService = ResourceStatusService();
    final remaining = statusService.timeBasedRemainingDays(
      config,
      now: previewDate,
    );
    final depletion = statusService.depletionDate(config);
    return [
      '${ReminderUiText.resourceHistoryRemainingLabel}：${remaining == null ? ReminderUiText.resourceHistoryUnavailableLabel : '${remaining < 0 ? 0 : remaining} ${ReminderUiText.dayUnit}'}',
      '${ReminderUiText.estimatedRunOutDateLabel}：${depletion == null ? ReminderUiText.resourceHistoryUnavailableLabel : ReminderFormatters.date(depletion)}',
    ];
  }
}

class _ResourceHistoryPackChip extends StatelessWidget {
  const _ResourceHistoryPackChip({required this.pack});

  final ItemPack pack;

  @override
  Widget build(BuildContext context) {
    final palette = context.reminderPalette;
    return Tooltip(
      message: pack.title,
      child: Container(
        key: Key('resource-history-pack-chip-${pack.id}'),
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

class _ResourceHistoryFilters extends StatelessWidget {
  const _ResourceHistoryFilters({
    required this.selectedFilter,
    required this.showReverted,
    required this.onFilterChanged,
    required this.onShowRevertedChanged,
  });

  final _ResourceHistoryFilter selectedFilter;
  final bool showReverted;
  final ValueChanged<_ResourceHistoryFilter> onFilterChanged;
  final ValueChanged<bool> onShowRevertedChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      key: const Key('resource-history-filters'),
      spacing: 6,
      runSpacing: 4,
      children: [
        for (final filter in _ResourceHistoryFilter.values)
          ChoiceChip(
            key: Key('resource-history-filter-${filter.name}'),
            label: Text(_filterLabel(filter)),
            selected: selectedFilter == filter,
            visualDensity: VisualDensity.compact,
            onSelected: (_) => onFilterChanged(filter),
          ),
        FilterChip(
          key: const Key('resource-history-show-reverted'),
          label: const Text(ReminderUiText.showRevertedRecordsLabel),
          selected: showReverted,
          visualDensity: VisualDensity.compact,
          onSelected: onShowRevertedChanged,
        ),
      ],
    );
  }

  String _filterLabel(_ResourceHistoryFilter filter) {
    return switch (filter) {
      _ResourceHistoryFilter.all => ReminderUiText.resourceHistoryFilterAll,
      _ResourceHistoryFilter.refilled =>
        ReminderUiText.resourceHistoryFilterRefill,
      _ResourceHistoryFilter.consumed =>
        ReminderUiText.resourceHistoryFilterConsume,
      _ResourceHistoryFilter.adjusted =>
        ReminderUiText.resourceHistoryFilterAdjust,
      _ResourceHistoryFilter.reverted =>
        ReminderUiText.resourceHistoryFilterRevert,
    };
  }
}

class _ResourceHistoryDateHeader extends StatelessWidget {
  const _ResourceHistoryDateHeader({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(2, 8, 2, 6),
      child: Text(
        label,
        key: Key('resource-history-date-$label'),
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
          color: context.reminderPalette.textSecondary,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _ResourceTimelineRow extends StatelessWidget {
  const _ResourceTimelineRow({required this.entry, required this.resource});

  final ResourceActionHistoryEntry entry;
  final Resource resource;

  @override
  Widget build(BuildContext context) {
    final record = entry.record;
    final palette = context.reminderPalette;
    final muted =
        record.isReverted || record.actionType == ResourceActionType.reverted;
    final actionColor = muted
        ? palette.textMuted
        : _actionColor(record.actionType, palette);
    final textColor = muted ? palette.textMuted : palette.textPrimary;
    final metaColor = muted ? palette.textMuted : palette.textSecondary;
    return Container(
      key: Key('resource-history-row-${record.id}'),
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: muted ? palette.surfaceWarm.withValues(alpha: 0.56) : null,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 18,
            child: Column(
              children: [
                Container(
                  key: Key('resource-history-marker-${record.id}'),
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
                  height: 34,
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
                      _actionSymbol(record.actionType),
                      key: Key('resource-history-action-icon-${record.id}'),
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: actionColor,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        _titleText(record, resource),
                        key: Key('resource-history-action-title-${record.id}'),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: textColor,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  _metaText(record, entry),
                  key: Key('resource-history-action-meta-${record.id}'),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: metaColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (muted) ...[
                  const SizedBox(height: 4),
                  _MutedRecordBadge(record: record),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _titleText(ResourceActionRecord record, Resource resource) {
    final amount = _amountText(record, resource);
    final suffix = amount.isEmpty ? '' : ' $amount';
    return '${_actionLabel(record.actionType)}$suffix';
  }

  String _amountText(ResourceActionRecord record, Resource resource) {
    final config = resource.config;
    if (config is QuantityBasedResourceConfig) {
      final amount = record.actionType == ResourceActionType.adjusted
          ? record.resultingQuantity
          : record.amount;
      if (amount == null) {
        return record.resultingQuantity == null
            ? ''
            : '${record.resultingQuantity} ${config.unitLabel}';
      }
      return '$amount ${config.unitLabel}';
    }
    if (record.addedDays != null) {
      return '${record.addedDays} ${ReminderUiText.dayUnit}';
    }
    if (record.resultingDurationDays != null) {
      return '${record.resultingDurationDays} ${ReminderUiText.dayUnit}';
    }
    return '';
  }

  String _metaText(
    ResourceActionRecord record,
    ResourceActionHistoryEntry entry,
  ) {
    final source = _sourceText(record, entry);
    return '$source・${ReminderFormatters.dateTime(record.actionDate)}';
  }

  String _sourceText(
    ResourceActionRecord record,
    ResourceActionHistoryEntry entry,
  ) {
    final remark = record.remark?.trim();
    if (remark != null && remark.isNotEmpty) {
      return remark;
    }
    final sourceTitle = entry.sourceItem?.title;
    if (sourceTitle != null && sourceTitle.isNotEmpty) {
      return record.actionType == ResourceActionType.reverted
          ? '因回復「$sourceTitle」'
          : '因完成「$sourceTitle」';
    }
    return switch (record.actionType) {
      ResourceActionType.created => ReminderUiText.resourceCreatedSourceLabel,
      ResourceActionType.refilled => ReminderUiText.resourceManualRefillLabel,
      ResourceActionType.consumed => ReminderUiText.resourceConsumedSourceLabel,
      ResourceActionType.adjusted => ReminderUiText.resourceManualAdjustLabel,
      ResourceActionType.reverted =>
        ReminderUiText.resourceRecordCompensationLabel,
    };
  }
}

class _MutedRecordBadge extends StatelessWidget {
  const _MutedRecordBadge({required this.record});

  final ResourceActionRecord record;

  @override
  Widget build(BuildContext context) {
    final palette = context.reminderPalette;
    final label = record.actionType == ResourceActionType.reverted
        ? ReminderUiText.resourceRecordCompensationLabel
        : ReminderUiText.resourceRecordRevertedLabel;
    return Container(
      key: Key('resource-history-muted-label-${record.id}'),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: palette.surfaceMuted,
        borderRadius: BorderRadius.circular(ReminderRadius.badge),
        border: Border.all(color: palette.borderSubtle),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: palette.textMuted,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _ResourceHistoryEmptyState extends StatelessWidget {
  const _ResourceHistoryEmptyState();

  @override
  Widget build(BuildContext context) {
    final palette = context.reminderPalette;
    return Container(
      key: const Key('resource-history-empty'),
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: palette.surfaceWarm,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: palette.borderSubtle),
      ),
      child: Text(
        ReminderUiText.noResourceHistory,
        style: Theme.of(
          context,
        ).textTheme.bodySmall?.copyWith(color: palette.textSecondary),
      ),
    );
  }
}

Color _statusColor(ResourceStatus status, ReminderPalette palette) {
  return switch (status) {
    ResourceStatus.normal => palette.statusNormal,
    ResourceStatus.warning => palette.statusWarning,
    ResourceStatus.danger => palette.statusDanger,
    ResourceStatus.unknown => palette.statusUnknown,
  };
}

String _resourceStatusLabel(Resource resource, ResourceStatus status) {
  return switch (status) {
    ResourceStatus.normal => '正常',
    ResourceStatus.warning =>
      resource.config is TimeBasedResourceConfig ? '快用完' : '快不足',
    ResourceStatus.danger => '危急',
    ResourceStatus.unknown => ReminderUiText.resourceHistoryUnavailableLabel,
  };
}

Color _actionColor(ResourceActionType actionType, ReminderPalette palette) {
  return switch (actionType) {
    ResourceActionType.created => palette.domainResource,
    ResourceActionType.refilled => palette.statusNormal,
    ResourceActionType.consumed => palette.statusDanger,
    ResourceActionType.adjusted => palette.primaryWarm,
    ResourceActionType.reverted => palette.textMuted,
  };
}

String _actionSymbol(ResourceActionType actionType) {
  return switch (actionType) {
    ResourceActionType.created => '•',
    ResourceActionType.refilled => '+',
    ResourceActionType.consumed => '-',
    ResourceActionType.adjusted => '↔',
    ResourceActionType.reverted => '↩',
  };
}

String _actionLabel(ResourceActionType actionType) {
  return switch (actionType) {
    ResourceActionType.created => ReminderUiText.resourceHistoryActionCreated,
    ResourceActionType.refilled => ReminderUiText.resourceHistoryFilterRefill,
    ResourceActionType.consumed => ReminderUiText.resourceHistoryFilterConsume,
    ResourceActionType.adjusted => ReminderUiText.resourceHistoryFilterAdjust,
    ResourceActionType.reverted => ReminderUiText.resourceHistoryFilterRevert,
  };
}

DateTime _dateOnly(DateTime value) {
  return DateTime(value.year, value.month, value.day);
}
