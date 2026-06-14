part of 'stage_tracker_pages.dart';

class StageTrackerDetailPage extends ConsumerStatefulWidget {
  const StageTrackerDetailPage({super.key, required this.stageTrackerId});

  static const routeName = 'stage-tracker-detail';
  static const routePath = '/stage-tracker/:id';

  final int stageTrackerId;

  @override
  ConsumerState<StageTrackerDetailPage> createState() =>
      _StageTrackerDetailPageState();
}

class _StageTrackerDetailPageState
    extends ConsumerState<StageTrackerDetailPage> {
  final Set<String> _expandedOccurrenceKeys = <String>{};

  @override
  Widget build(BuildContext context) {
    final detailAsync = ref.watch(
      stageTrackerDetailProvider(widget.stageTrackerId),
    );
    final previewDate = ref.watch(effectivePreviewDateProvider);
    final tracker = detailAsync.valueOrNull?.stageTracker;

    return Scaffold(
      appBar: AppBar(
        title: const SizedBox.shrink(),
        actions: [
          _StageTrackerDetailOverflowMenu(
            stageTrackerId: widget.stageTrackerId,
            tracker: tracker,
          ),
        ],
      ),
      body: detailAsync.when(
        data: (detail) {
          if (detail == null) {
            return ReminderRefreshablePlaceholder(
              onRefresh: _refresh,
              child: const Text(ReminderUiText.stageTrackerMissingMessage),
            );
          }
          final tracker = detail.stageTracker;
          final upcomingStages = _dedupeUpcomingStages(detail);
          final nextOccurrencesByRule = _nextOccurrencesByRule(
            detail,
            previewDate,
          );
          return ReminderRefreshable(
            onRefresh: _refresh,
            child: ListView(
              physics: reminderRefreshPhysics,
              padding: const EdgeInsets.all(
                _StageTrackerDetailDensity.pagePadding,
              ),
              children: [
                _StageHeroCard(
                  tracker: tracker,
                  now: previewDate,
                  recentState: _heroRecentState(detail.historyStages),
                  nextStage: detail.nextStage,
                ),
                if (!tracker.isSystemDefault) ...[
                  const SizedBox(height: _StageTrackerDetailDensity.cardGap),
                  _CompactAddStageAction(
                    onPressed: () =>
                        _showStageEntryDialog(context, ref, tracker.id),
                  ),
                ],
                const SizedBox(height: _StageTrackerDetailDensity.sectionGap),
                _CompactSection(
                  title: '即將到來',
                  child: upcomingStages.isEmpty
                      ? _CompactUpcomingEmptyState(
                          onAddStage: () =>
                              _showStageEntryDialog(context, ref, tracker.id),
                        )
                      : Column(
                          children: [
                            for (final occurrence in upcomingStages)
                              _CompactStageTimelineRow(
                                occurrence: occurrence,
                                now: previewDate,
                                keyPrefix: 'detail',
                                enableExpansion: true,
                                isExpanded: _expandedOccurrenceKeys.contains(
                                  _stageOccurrenceKey(occurrence),
                                ),
                                onToggleExpanded: () =>
                                    _toggleOccurrence(occurrence),
                              ),
                          ],
                        ),
                ),
                const SizedBox(height: _StageTrackerDetailDensity.sectionGap),
                _StageRuleList(
                  rules: detail.stageRules,
                  nextOccurrencesByRule: nextOccurrencesByRule,
                  now: previewDate,
                  canManage: !tracker.isSystemDefault,
                  onAddRule: () => _showStageEntryDialog(
                    context,
                    ref,
                    tracker.id,
                    initialTab: _StageEntryTab.recurring,
                  ),
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

  void _toggleOccurrence(StageOccurrence occurrence) {
    final key = _stageOccurrenceKey(occurrence);
    setState(() {
      if (!_expandedOccurrenceKeys.add(key)) {
        _expandedOccurrenceKeys.remove(key);
      }
    });
  }

  List<StageOccurrence> _dedupeUpcomingStages(StageTrackerDetail detail) {
    final items = _dedupeOccurrences([
      ?detail.nextStage,
      ...detail.dashboardUpcomingStages,
    ]);
    items.sort((a, b) => a.occurrenceDate.compareTo(b.occurrenceDate));
    return items;
  }

  Map<int, StageOccurrence> _nextOccurrencesByRule(
    StageTrackerDetail detail,
    DateTime previewDate,
  ) {
    final today = _normalizeDate(previewDate);
    final candidates =
        _dedupeOccurrences([
            ...detail.scheduleStages,
            ...detail.dashboardUpcomingStages,
          ]).where((occurrence) {
            final ruleId = occurrence.stageRuleId;
            return ruleId != null &&
                !_normalizeDate(occurrence.occurrenceDate).isBefore(today);
          }).toList()
          ..sort((a, b) => a.occurrenceDate.compareTo(b.occurrenceDate));

    final result = <int, StageOccurrence>{};
    for (final occurrence in candidates) {
      final ruleId = occurrence.stageRuleId;
      if (ruleId != null) {
        result.putIfAbsent(ruleId, () => occurrence);
      }
    }
    return result;
  }

  _StageHeroRecentState? _heroRecentState(List<StageOccurrence> historyStages) {
    final sorted = [...historyStages]
      ..sort((a, b) => b.occurrenceDate.compareTo(a.occurrenceDate));
    for (final occurrence in sorted) {
      if (occurrence.recordStatus != StageRecordStatus.acknowledged) {
        return _StageHeroRecentState(prefix: '待確認', occurrence: occurrence);
      }
    }
    for (final occurrence in sorted) {
      if (occurrence.recordStatus == StageRecordStatus.acknowledged) {
        return _StageHeroRecentState(prefix: '最近經歷', occurrence: occurrence);
      }
    }
    return null;
  }
}

enum _StageTrackerDetailMenuAction { edit, timeline, hide, archive }

class _StageTrackerDetailOverflowMenu extends ConsumerWidget {
  const _StageTrackerDetailOverflowMenu({
    required this.stageTrackerId,
    required this.tracker,
  });

  final int stageTrackerId;
  final StageTracker? tracker;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PopupMenuButton<_StageTrackerDetailMenuAction>(
      key: const Key('stage-tracker-detail-overflow'),
      tooltip: '階段追蹤操作',
      onSelected: (action) async {
        switch (action) {
          case _StageTrackerDetailMenuAction.edit:
            final currentTracker = tracker;
            if (currentTracker == null) {
              return;
            }
            await _showEditStageTrackerDialog(context, ref, currentTracker);
            return;
          case _StageTrackerDetailMenuAction.timeline:
            context.pushNamed(
              StageTrackerTimelinePage.routeName,
              pathParameters: {'id': stageTrackerId.toString()},
            );
            return;
          case _StageTrackerDetailMenuAction.hide:
            final confirmed = await _showStageActionConfirmation(
              context,
              title: ReminderUiText.hideSystemStageTrackerTitle,
              message: ReminderUiText.hideSystemStageTrackerMessage,
              confirmLabel: ReminderUiText.hideSystemStageTrackerLabel,
            );
            if (confirmed != true || !context.mounted) {
              return;
            }
            final hidden = await ref
                .read(stageTrackerRepositoryProvider)
                .hideSystemStageTracker();
            ref.invalidate(systemStageTrackerProvider);
            ref.invalidate(stageTrackersProvider);
            if (!context.mounted) {
              return;
            }
            if (!hidden) {
              _showStageTrackerSaveFailed(context);
              return;
            }
            context.goNamed(StageTrackerManagementPage.routeName);
            return;
          case _StageTrackerDetailMenuAction.archive:
            final confirmed = await _showStageActionConfirmation(
              context,
              title: ReminderUiText.archiveStageTrackerTitle,
              message: ReminderUiText.archiveStageTrackerMessage,
              confirmLabel: ReminderUiText.archiveAction,
              isDestructive: true,
            );
            if (confirmed != true || !context.mounted) {
              return;
            }
            final archived = await ref
                .read(stageTrackerRepositoryProvider)
                .archiveStageTracker(stageTrackerId);
            _invalidateStageTrackerActionProviders(ref, stageTrackerId);
            if (!context.mounted) {
              return;
            }
            if (!archived) {
              _showStageTrackerSaveFailed(context);
              return;
            }
            context.goNamed(StageTrackerManagementPage.routeName);
            return;
        }
      },
      itemBuilder: (context) {
        final isSystemDefault = tracker?.isSystemDefault ?? false;
        return [
          if (!isSystemDefault)
            PopupMenuItem(
              value: _StageTrackerDetailMenuAction.edit,
              enabled: tracker != null,
              child: const Text(ReminderUiText.editStageTracker),
            ),
          const PopupMenuItem(
            value: _StageTrackerDetailMenuAction.timeline,
            child: Text(ReminderUiText.stageTrackerTimelineTitle),
          ),
          const PopupMenuDivider(),
          if (isSystemDefault)
            const PopupMenuItem(
              value: _StageTrackerDetailMenuAction.hide,
              child: Text(ReminderUiText.hideSystemStageTrackerLabel),
            )
          else
            PopupMenuItem(
              value: _StageTrackerDetailMenuAction.archive,
              child: Text(
                ReminderUiText.archiveStageTracker,
                key: const Key('stage-tracker-archive-menu-text'),
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
        ];
      },
    );
  }
}

class _StageTrackerDetailDensity {
  const _StageTrackerDetailDensity._();

  static const pagePadding = 12.0;
  static const sectionGap = 10.0;
  static const cardGap = 6.0;
  static const heroPadding = 12.0;
  static const cardPadding = 10.0;
  static const cardRadius = 16.0;
  static const heroIconSize = 44.0;
  static const timelineMarkerSize = 10.0;
  static const rowActionSize = 34.0;
}

class _CompactAddStageAction extends StatelessWidget {
  const _CompactAddStageAction({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: FilledButton.icon(
        key: const Key('detail-add-stage-action'),
        onPressed: onPressed,
        icon: const Icon(Icons.add, size: 18),
        label: const Text(ReminderUiText.addStageEntry),
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          visualDensity: VisualDensity.compact,
          textStyle: Theme.of(
            context,
          ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800),
        ),
      ),
    );
  }
}

class _CompactUpcomingEmptyState extends StatelessWidget {
  const _CompactUpcomingEmptyState({required this.onAddStage});

  final VoidCallback onAddStage;

  @override
  Widget build(BuildContext context) {
    final palette = context.reminderPalette;
    return Container(
      key: const Key('detail-upcoming-empty'),
      width: double.infinity,
      padding: const EdgeInsets.all(_StageTrackerDetailDensity.cardPadding),
      decoration: BoxDecoration(
        color: palette.surfaceWarm,
        borderRadius: BorderRadius.circular(
          _StageTrackerDetailDensity.cardRadius,
        ),
        border: Border.all(color: palette.borderSubtle),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '尚未安排下一階段。',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: palette.textSecondary),
            ),
          ),
          TextButton.icon(
            key: const Key('detail-empty-add-stage-action'),
            onPressed: onAddStage,
            icon: const Icon(Icons.add, size: 16),
            label: const Text(ReminderUiText.addStageEntry),
            style: TextButton.styleFrom(
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            ),
          ),
        ],
      ),
    );
  }
}

class _CompactSection extends StatelessWidget {
  const _CompactSection({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: _StageTrackerDetailDensity.cardGap),
        child,
      ],
    );
  }
}

class _StageHeroRecentState {
  const _StageHeroRecentState({required this.prefix, required this.occurrence});

  final String prefix;
  final StageOccurrence occurrence;
}

List<StageOccurrence> _dedupeOccurrences(
  Iterable<StageOccurrence> occurrences,
) {
  final seen = <String>{};
  final items = <StageOccurrence>[];
  for (final occurrence in occurrences) {
    if (seen.add(_stageOccurrenceIdentity(occurrence))) {
      items.add(occurrence);
    }
  }
  return items;
}

String _stageOccurrenceIdentity(StageOccurrence occurrence) {
  final recordId = occurrence.stageRecordId;
  if (recordId != null) {
    return 'record-$recordId';
  }
  final ruleId = occurrence.stageRuleId;
  final index = occurrence.occurrenceIndex;
  if (ruleId != null && index != null) {
    return 'rule-$ruleId-$index';
  }
  return [
    occurrence.sourceType.name,
    occurrence.occurrenceDate.millisecondsSinceEpoch,
    occurrence.label,
  ].join('-');
}

String _stageOccurrenceKey(StageOccurrence occurrence) {
  final recordId = occurrence.stageRecordId;
  if (recordId != null) {
    return 'record-$recordId';
  }
  final ruleId = occurrence.stageRuleId;
  final index = occurrence.occurrenceIndex;
  if (ruleId != null && index != null) {
    return 'rule-$ruleId-$index';
  }
  return '${occurrence.stageTrackerId}-${occurrence.occurrenceDate.millisecondsSinceEpoch}-${occurrence.label.hashCode}';
}

String _countdownLabel(DateTime target, DateTime now) {
  final days = _normalizeDate(target).difference(_normalizeDate(now)).inDays;
  if (days == 0) {
    return '今日';
  }
  if (days == 1) {
    return '明日';
  }
  if (days > 1) {
    return '$days 天後';
  }
  return '已過 ${-days} 天';
}

String _relativeDayLabel(DateTime target, DateTime now) {
  final days = _normalizeDate(target).difference(_normalizeDate(now)).inDays;
  if (days == 0) {
    return '今天';
  }
  if (days == 1) {
    return '明天';
  }
  if (days > 1) {
    return '$days天後';
  }
  return '已過${-days}天';
}

String _stageOccurrenceSourceLabel(StageOccurrence occurrence) {
  return occurrence.isManual
      ? ReminderUiText.stageTimelineManualSemanticLabel
      : ReminderUiText.stageTimelineRecurringSemanticLabel;
}

String _stageOccurrenceHistoryStatusLabel(StageOccurrence occurrence) {
  return occurrence.recordStatus == StageRecordStatus.acknowledged
      ? ReminderUiText.stageTimelineAcknowledgedLabel
      : ReminderUiText.stageTimelinePendingAckLabel;
}

bool _hasVisibleRelatedItemSummary(StageRelatedItemSummary? summary) {
  return summary != null && summary.totalRelevantCount > 0;
}

DateTime _normalizeDate(DateTime value) {
  return DateTime(value.year, value.month, value.day);
}

Future<void> _refreshStageTrackerDetail(
  WidgetRef ref,
  int stageTrackerId,
) async {
  ref.invalidate(stageTrackerDetailProvider(stageTrackerId));
  await Future<void>.delayed(Duration.zero);
}
