part of 'stage_tracker_pages.dart';

enum _StageTimelineFilter { all, upcoming, history }

class StageTrackerTimelinePage extends ConsumerStatefulWidget {
  const StageTrackerTimelinePage({super.key, required this.stageTrackerId});

  static const routeName = 'stage-tracker-timeline';
  static const routePath = '/stage-tracker/:id/timeline';

  final int stageTrackerId;

  @override
  ConsumerState<StageTrackerTimelinePage> createState() =>
      _StageTrackerTimelinePageState();
}

class _StageTrackerTimelinePageState
    extends ConsumerState<StageTrackerTimelinePage> {
  _StageTimelineFilter _filter = _StageTimelineFilter.all;

  @override
  Widget build(BuildContext context) {
    final detailAsync = ref.watch(
      stageTrackerDetailProvider(widget.stageTrackerId),
    );
    final previewDate = ref.watch(effectivePreviewDateProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text(ReminderUiText.stageTrackerTimelineTitle),
      ),
      body: detailAsync.when(
        data: (detail) {
          if (detail == null) {
            return ReminderRefreshablePlaceholder(
              onRefresh: _refresh,
              child: const Text(ReminderUiText.stageTrackerMissingMessage),
            );
          }
          final allEntries = _buildStageTimelineEntries(detail, previewDate);
          final entries = _filterStageTimelineEntries(allEntries, _filter);
          return ReminderRefreshable(
            onRefresh: _refresh,
            child: ListView(
              key: const Key('stage-tracker-timeline-page'),
              physics: reminderRefreshPhysics,
              padding: const EdgeInsets.all(
                _StageTrackerDetailDensity.pagePadding,
              ),
              children: [
                _StageTimelineSummaryCard(
                  detail: detail,
                  previewDate: previewDate,
                ),
                const SizedBox(height: _StageTrackerDetailDensity.cardGap),
                _StageTimelineFilterChips(
                  selectedFilter: _filter,
                  onChanged: (filter) => setState(() {
                    _filter = filter;
                  }),
                ),
                const SizedBox(height: _StageTrackerDetailDensity.sectionGap),
                if (entries.isEmpty)
                  _CompactTimelineEmptyState(filter: _filter)
                else
                  for (final entry in entries)
                    _StageCompleteTimelineRow(
                      entry: entry,
                      previewDate: previewDate,
                      canManage: !detail.stageTracker.isSystemDefault,
                    ),
              ],
            ),
          );
        },
        error: (error, stack) => ReminderRefreshablePlaceholder(
          onRefresh: _refresh,
          child: Text('讀取失敗: $error'),
        ),
        loading: () => ReminderRefreshablePlaceholder(
          onRefresh: _refresh,
          child: const CircularProgressIndicator(),
        ),
      ),
    );
  }

  Future<void> _refresh() =>
      _refreshStageTrackerDetail(ref, widget.stageTrackerId);
}

List<_StageTimelineEntry> _filterStageTimelineEntries(
  List<_StageTimelineEntry> entries,
  _StageTimelineFilter filter,
) {
  return entries
      .where((entry) {
        return switch (filter) {
          _StageTimelineFilter.all => true,
          _StageTimelineFilter.upcoming =>
            entry.bucket == _StageTimelineBucket.upcoming,
          _StageTimelineFilter.history =>
            entry.bucket == _StageTimelineBucket.history,
        };
      })
      .toList(growable: false);
}

List<_StageTimelineEntry> _buildStageTimelineEntries(
  StageTrackerDetail detail,
  DateTime previewDate,
) {
  final today = _normalizeDate(previewDate);
  final occurrences = _dedupeOccurrences([
    ?detail.nextStage,
    ...detail.dashboardUpcomingStages,
    ...detail.scheduleStages,
    ...detail.historyStages,
  ]);
  final upcoming = <_StageTimelineEntry>[];
  final history = <_StageTimelineEntry>[];
  for (final occurrence in occurrences) {
    final entry = _StageTimelineEntry(
      occurrence: occurrence,
      bucket: _normalizeDate(occurrence.occurrenceDate).isBefore(today)
          ? _StageTimelineBucket.history
          : _StageTimelineBucket.upcoming,
    );
    if (entry.bucket == _StageTimelineBucket.upcoming) {
      upcoming.add(entry);
    } else {
      history.add(entry);
    }
  }
  upcoming.sort(_compareUpcomingStageTimelineEntries);
  history.sort(_compareHistoryStageTimelineEntries);
  return [...upcoming, ...history];
}

int _compareUpcomingStageTimelineEntries(
  _StageTimelineEntry a,
  _StageTimelineEntry b,
) {
  final dateCompare = a.occurrence.occurrenceDate.compareTo(
    b.occurrence.occurrenceDate,
  );
  if (dateCompare != 0) {
    return dateCompare;
  }
  return _stageOccurrenceKey(
    a.occurrence,
  ).compareTo(_stageOccurrenceKey(b.occurrence));
}

int _compareHistoryStageTimelineEntries(
  _StageTimelineEntry a,
  _StageTimelineEntry b,
) {
  final dateCompare = b.occurrence.occurrenceDate.compareTo(
    a.occurrence.occurrenceDate,
  );
  if (dateCompare != 0) {
    return dateCompare;
  }
  return _stageOccurrenceKey(
    b.occurrence,
  ).compareTo(_stageOccurrenceKey(a.occurrence));
}

enum _StageTimelineBucket { upcoming, history }

class _StageTimelineEntry {
  const _StageTimelineEntry({required this.occurrence, required this.bucket});

  final StageOccurrence occurrence;
  final _StageTimelineBucket bucket;
}

class _CompactTimelineEmptyState extends StatelessWidget {
  const _CompactTimelineEmptyState({required this.filter});

  final _StageTimelineFilter filter;

  @override
  Widget build(BuildContext context) {
    final palette = context.reminderPalette;
    final text = switch (filter) {
      _StageTimelineFilter.all => ReminderUiText.stageTimelineEmptyAll,
      _StageTimelineFilter.upcoming =>
        ReminderUiText.stageTimelineEmptyUpcoming,
      _StageTimelineFilter.history => ReminderUiText.stageTimelineEmptyHistory,
    };
    return Container(
      key: Key('timeline-empty-${filter.name}'),
      width: double.infinity,
      padding: const EdgeInsets.all(_StageTrackerDetailDensity.cardPadding),
      decoration: BoxDecoration(
        color: palette.surfaceWarm,
        borderRadius: BorderRadius.circular(
          _StageTrackerDetailDensity.cardRadius,
        ),
        border: Border.all(color: palette.borderSubtle),
      ),
      child: Text(
        text,
        style: Theme.of(
          context,
        ).textTheme.bodySmall?.copyWith(color: palette.textSecondary),
      ),
    );
  }
}

class _StageTimelineSummaryCard extends StatelessWidget {
  const _StageTimelineSummaryCard({
    required this.detail,
    required this.previewDate,
  });

  final StageTrackerDetail detail;
  final DateTime previewDate;

  @override
  Widget build(BuildContext context) {
    final palette = context.reminderPalette;
    final tracker = detail.stageTracker;
    final recentState = _stageTimelineRecentState(detail.historyStages);
    return ReminderPaperCard(
      key: const Key('stage-tracker-timeline-summary-card'),
      backgroundColor: palette.surfaceWarm,
      padding: const EdgeInsets.all(_StageTrackerDetailDensity.cardPadding),
      radius: _StageTrackerDetailDensity.cardRadius,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            tracker.title,
            key: const Key('stage-tracker-timeline-summary-title'),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(
            _stageTimelineAccumulatedDaysLabel(tracker, previewDate),
            key: const Key('stage-tracker-timeline-summary-days'),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: palette.textSecondary,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (recentState != null) ...[
            const SizedBox(height: 2),
            Text(
              '${recentState.prefix}：${recentState.occurrence.label}',
              key: const Key('stage-tracker-timeline-summary-recent'),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: palette.textSecondary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
          const SizedBox(height: 2),
          Text(
            _stageTimelineNextStageLabel(detail.nextStage, previewDate),
            key: const Key('stage-tracker-timeline-summary-next'),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: palette.textMuted),
          ),
        ],
      ),
    );
  }
}

class _StageTimelineFilterChips extends StatelessWidget {
  const _StageTimelineFilterChips({
    required this.selectedFilter,
    required this.onChanged,
  });

  final _StageTimelineFilter selectedFilter;
  final ValueChanged<_StageTimelineFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      key: const Key('stage-timeline-filters'),
      spacing: 6,
      runSpacing: 4,
      children: [
        for (final filter in _StageTimelineFilter.values)
          ChoiceChip(
            key: Key('stage-timeline-filter-${filter.name}'),
            label: Text(_stageTimelineFilterLabel(filter)),
            selected: selectedFilter == filter,
            visualDensity: VisualDensity.compact,
            onSelected: (_) => onChanged(filter),
          ),
      ],
    );
  }
}

class _StageCompleteTimelineRow extends ConsumerWidget {
  const _StageCompleteTimelineRow({
    required this.entry,
    required this.previewDate,
    required this.canManage,
  });

  final _StageTimelineEntry entry;
  final DateTime previewDate;
  final bool canManage;

  StageOccurrence get occurrence => entry.occurrence;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = context.reminderPalette;
    final key = _stageOccurrenceKey(occurrence);
    final canManageManualStage =
        canManage && occurrence.isManual && occurrence.stageRecordId != null;
    return Container(
      key: Key('timeline-stage-occurrence-$key'),
      margin: const EdgeInsets.only(bottom: _StageTrackerDetailDensity.cardGap),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 18,
            child: Column(
              children: [
                Container(
                  key: Key('timeline-stage-marker-$key'),
                  width: _StageTrackerDetailDensity.timelineMarkerSize,
                  height: _StageTrackerDetailDensity.timelineMarkerSize,
                  margin: const EdgeInsets.only(top: 5),
                  decoration: BoxDecoration(
                    color: _stageTimelineMarkerColor(entry, palette),
                    shape: BoxShape.circle,
                  ),
                ),
                Container(
                  width: 1,
                  height: (occurrence.note ?? '').trim().isEmpty ? 36 : 54,
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
                  children: [
                    Semantics(
                      label: _stageTimelineSourceSemanticLabel(occurrence),
                      child: Text(
                        _stageTimelineSourceIcon(occurrence),
                        key: Key(
                          occurrence.isManual
                              ? 'timeline-manual-icon-$key'
                              : 'timeline-recurring-icon-$key',
                        ),
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        occurrence.label,
                        key: Key('timeline-stage-label-$key'),
                        maxLines: 1,
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
                  _metadataText(),
                  key: Key('timeline-stage-meta-$key'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: palette.textMuted,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if ((occurrence.note ?? '').trim().isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    occurrence.note!.trim(),
                    key: Key('timeline-stage-note-$key'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: palette.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (canManageManualStage)
            SizedBox(
              width: _StageTrackerDetailDensity.rowActionSize,
              height: _StageTrackerDetailDensity.rowActionSize,
              child: PopupMenuButton<_ManualStageMenuAction>(
                key: Key('timeline-manual-stage-overflow-$key'),
                tooltip: '重要階段操作',
                icon: const Icon(Icons.more_horiz, size: 20),
                padding: EdgeInsets.zero,
                itemBuilder: (context) => [
                  const PopupMenuItem<_ManualStageMenuAction>(
                    value: _ManualStageMenuAction.addRelated,
                    child: Text(ReminderUiText.addRelatedReminder),
                  ),
                  const PopupMenuItem<_ManualStageMenuAction>(
                    value: _ManualStageMenuAction.edit,
                    child: Text(ReminderUiText.editImportantStage),
                  ),
                  const PopupMenuDivider(),
                  PopupMenuItem<_ManualStageMenuAction>(
                    value: _ManualStageMenuAction.archive,
                    child: Text(
                      ReminderUiText.archiveImportantStage,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
                ],
                onSelected: (action) =>
                    _handleManualStageAction(context, ref, action),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _handleManualStageAction(
    BuildContext context,
    WidgetRef ref,
    _ManualStageMenuAction action,
  ) async {
    switch (action) {
      case _ManualStageMenuAction.addRelated:
        await _showRelatedItemDialog(context, ref, occurrence);
        return;
      case _ManualStageMenuAction.edit:
        await _showEditImportantStageDialog(context, ref, occurrence);
        return;
      case _ManualStageMenuAction.archive:
        final stageRecordId = occurrence.stageRecordId;
        if (stageRecordId == null) {
          return;
        }
        final confirmed = await _showStageActionConfirmation(
          context,
          title: ReminderUiText.archiveImportantStageTitle,
          message: ReminderUiText.archiveImportantStageMessage,
          confirmLabel: ReminderUiText.archiveAction,
          isDestructive: true,
        );
        if (confirmed != true) {
          return;
        }
        await ref
            .read(stageTrackerRepositoryProvider)
            .deleteOrArchiveImportantStage(stageRecordId);
        _invalidateStageTrackerActionProviders(ref, occurrence.stageTrackerId);
        return;
    }
  }

  String _metadataText() {
    final summary = occurrence.relatedItemSummary;
    final parts = [
      ReminderFormatters.date(occurrence.occurrenceDate),
      entry.bucket == _StageTimelineBucket.upcoming
          ? _relativeDayLabel(occurrence.occurrenceDate, previewDate)
          : _stageOccurrenceHistoryStatusLabel(occurrence),
      if (_hasVisibleRelatedItemSummary(summary))
        ReminderFormatters.relatedItemSummary(summary!),
    ];
    return parts.join('・');
  }
}

String _stageTimelineFilterLabel(_StageTimelineFilter filter) {
  return switch (filter) {
    _StageTimelineFilter.all => ReminderUiText.stageTimelineFilterAll,
    _StageTimelineFilter.upcoming => ReminderUiText.stageTimelineFilterUpcoming,
    _StageTimelineFilter.history => ReminderUiText.stageTimelineFilterHistory,
  };
}

String _stageTimelineSourceIcon(StageOccurrence occurrence) {
  return occurrence.isManual ? '⭐' : '🔁';
}

String _stageTimelineSourceSemanticLabel(StageOccurrence occurrence) {
  return occurrence.isManual
      ? ReminderUiText.stageTimelineManualSemanticLabel
      : ReminderUiText.stageTimelineRecurringSemanticLabel;
}

Color _stageTimelineMarkerColor(
  _StageTimelineEntry entry,
  ReminderPalette palette,
) {
  if (entry.bucket == _StageTimelineBucket.upcoming) {
    return palette.domainStage;
  }
  return entry.occurrence.recordStatus == StageRecordStatus.acknowledged
      ? palette.statusNormal
      : palette.statusWarning;
}

_StageHeroRecentState? _stageTimelineRecentState(
  List<StageOccurrence> historyStages,
) {
  final sorted = [...historyStages]
    ..sort((a, b) => b.occurrenceDate.compareTo(a.occurrenceDate));
  for (final occurrence in sorted) {
    if (occurrence.recordStatus != StageRecordStatus.acknowledged) {
      return _StageHeroRecentState(
        prefix: ReminderUiText.stageTimelinePendingAckLabel,
        occurrence: occurrence,
      );
    }
  }
  for (final occurrence in sorted) {
    if (occurrence.recordStatus == StageRecordStatus.acknowledged) {
      return _StageHeroRecentState(prefix: '最近經歷', occurrence: occurrence);
    }
  }
  return null;
}

String _stageTimelineAccumulatedDaysLabel(
  StageTracker tracker,
  DateTime previewDate,
) {
  return ReminderFormatters.stageTrackerDayLabel(tracker, now: previewDate);
}

String _stageTimelineNextStageLabel(
  StageOccurrence? occurrence,
  DateTime previewDate,
) {
  if (occurrence == null) {
    return '尚未安排下一階段';
  }
  return '下一階段：${occurrence.label}・${_relativeDayLabel(occurrence.occurrenceDate, previewDate)}';
}
