part of 'stage_tracker_pages.dart';

class _StageHeroCard extends StatelessWidget {
  const _StageHeroCard({
    required this.tracker,
    required this.now,
    required this.recentState,
    required this.nextStage,
  });

  final StageTracker tracker;
  final DateTime now;
  final _StageHeroRecentState? recentState;
  final StageOccurrence? nextStage;

  @override
  Widget build(BuildContext context) {
    final palette = context.reminderPalette;
    return ReminderPaperCard(
      key: const Key('stage-tracker-detail-hero'),
      backgroundColor: palette.surfaceWarm,
      padding: const EdgeInsets.all(_StageTrackerDetailDensity.heroPadding),
      radius: _StageTrackerDetailDensity.cardRadius,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _StageTrackerDetailIcon(color: palette.domainStage),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tracker.title,
                      key: const Key('stage-tracker-detail-title'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      ReminderFormatters.stageTrackerDayLabel(
                        tracker,
                        now: now,
                      ),
                      key: const Key('stage-tracker-detail-accumulated-days'),
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: palette.textPrimary,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: palette.statusNormalContainer,
                  borderRadius: BorderRadius.circular(ReminderRadius.badge),
                  border: Border.all(
                    color: palette.domainStage.withValues(alpha: 0.24),
                  ),
                ),
                child: Text(
                  '階段設定',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: palette.domainStage,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          if (recentState != null) ...[
            const SizedBox(height: 8),
            Text(
              '${recentState!.prefix}：${recentState!.occurrence.label}',
              key: Key('stage-tracker-${recentState!.prefix}-line'),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: palette.textSecondary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
          const SizedBox(height: 4),
          Text(
            _nextStageLabel(nextStage, now),
            key: const Key('stage-tracker-next-stage-line'),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: palette.textSecondary),
          ),
        ],
      ),
    );
  }

  String _nextStageLabel(StageOccurrence? occurrence, DateTime now) {
    if (occurrence == null) {
      return '尚未安排下一階段';
    }
    return '下一階段：${occurrence.label}・${_countdownLabel(occurrence.occurrenceDate, now)}';
  }

  String _countdownLabel(DateTime target, DateTime now) {
    final days = _normalizeDate(target).difference(_normalizeDate(now)).inDays;
    if (days <= 0) {
      return '今日';
    }
    if (days == 1) {
      return '明日';
    }
    return '$days 天後';
  }

  DateTime _normalizeDate(DateTime value) {
    return DateTime(value.year, value.month, value.day);
  }
}

class _StageTrackerDetailIcon extends StatelessWidget {
  const _StageTrackerDetailIcon({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    final palette = context.reminderPalette;
    return Container(
      width: _StageTrackerDetailDensity.heroIconSize,
      height: _StageTrackerDetailDensity.heroIconSize,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: palette.statusNormalContainer,
        shape: BoxShape.circle,
        border: Border.all(color: palette.borderSubtle),
      ),
      child: Icon(Icons.auto_graph_outlined, size: 23, color: color),
    );
  }
}

class _StageRuleList extends StatelessWidget {
  const _StageRuleList({
    required this.rules,
    required this.nextOccurrencesByRule,
    required this.now,
    required this.canManage,
    required this.onAddRule,
  });

  final List<StageRule> rules;
  final Map<int, StageOccurrence> nextOccurrencesByRule;
  final DateTime now;
  final bool canManage;
  final VoidCallback? onAddRule;

  @override
  Widget build(BuildContext context) {
    return _CompactSection(
      title: ReminderUiText.stageRulesTitle,
      child: rules.isEmpty
          ? _CompactStageRuleEmptyState(
              canManage: canManage,
              onAddRule: onAddRule,
            )
          : Column(
              children: [
                for (final rule in rules)
                  _CompactStageRuleRow(
                    rule: rule,
                    nextOccurrence: nextOccurrencesByRule[rule.id],
                    now: now,
                    canManage: canManage,
                  ),
              ],
            ),
    );
  }
}

class _CompactStageRuleEmptyState extends StatelessWidget {
  const _CompactStageRuleEmptyState({
    required this.canManage,
    required this.onAddRule,
  });

  final bool canManage;
  final VoidCallback? onAddRule;

  @override
  Widget build(BuildContext context) {
    final palette = context.reminderPalette;
    return Container(
      key: const Key('stage-rule-empty-state'),
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
              ReminderUiText.stageRuleEmptyHint,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: palette.textSecondary),
            ),
          ),
          if (canManage)
            TextButton(
              key: const Key('stage-rule-empty-add-action'),
              onPressed: onAddRule,
              style: TextButton.styleFrom(
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              ),
              child: const Text(ReminderUiText.addRecurringStage),
            ),
        ],
      ),
    );
  }
}

enum _StageRuleMenuAction { edit, pause, resume, archive }

class _CompactStageRuleRow extends ConsumerWidget {
  const _CompactStageRuleRow({
    required this.rule,
    required this.nextOccurrence,
    required this.now,
    required this.canManage,
  });

  final StageRule rule;
  final StageOccurrence? nextOccurrence;
  final DateTime now;
  final bool canManage;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = context.reminderPalette;
    return Container(
      key: Key('stage-rule-row-${rule.id}'),
      margin: const EdgeInsets.only(bottom: _StageTrackerDetailDensity.cardGap),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: palette.surfaceCard,
        borderRadius: BorderRadius.circular(
          _StageTrackerDetailDensity.cardRadius,
        ),
        border: Border.all(color: palette.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ReminderFormatters.stageRuleSummary(rule),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: palette.textPrimary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _subtitle(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: palette.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              if (canManage)
                PopupMenuButton<_StageRuleMenuAction>(
                  key: Key('stage-rule-overflow-${rule.id}'),
                  tooltip: '重複階段操作',
                  icon: const Icon(Icons.more_horiz),
                  onSelected: (action) =>
                      _handleStageRuleAction(context, ref, rule, action),
                  itemBuilder: (context) {
                    if (rule.status == StageRuleStatus.archived) {
                      return const [
                        PopupMenuItem<_StageRuleMenuAction>(
                          enabled: false,
                          child: Text(ReminderUiText.lifecycleArchivedLabel),
                        ),
                      ];
                    }
                    return [
                      const PopupMenuItem<_StageRuleMenuAction>(
                        value: _StageRuleMenuAction.edit,
                        child: Text(ReminderUiText.editStageRule),
                      ),
                      PopupMenuItem<_StageRuleMenuAction>(
                        value: rule.status == StageRuleStatus.paused
                            ? _StageRuleMenuAction.resume
                            : _StageRuleMenuAction.pause,
                        child: Text(
                          rule.status == StageRuleStatus.paused
                              ? ReminderUiText.resumeStageRule
                              : ReminderUiText.pauseStageRule,
                        ),
                      ),
                      const PopupMenuDivider(),
                      PopupMenuItem<_StageRuleMenuAction>(
                        value: _StageRuleMenuAction.archive,
                        child: Text(
                          ReminderUiText.archiveStageRule,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      ),
                    ];
                  },
                ),
            ],
          ),
        ],
      ),
    );
  }

  String _subtitle() {
    final occurrence = nextOccurrence;
    if (occurrence == null) {
      return '尚未安排下一階段・${ReminderFormatters.stageRuleStatus(rule.status)}';
    }
    return [
      '下一階段：${occurrence.label}',
      ReminderFormatters.date(occurrence.occurrenceDate),
      _relativeDayLabel(occurrence.occurrenceDate, now),
    ].join('・');
  }

  Future<void> _handleStageRuleAction(
    BuildContext context,
    WidgetRef ref,
    StageRule rule,
    _StageRuleMenuAction action,
  ) async {
    switch (action) {
      case _StageRuleMenuAction.edit:
        await _showEditStageRuleDialog(context, ref, rule);
        return;
      case _StageRuleMenuAction.pause:
        final updated = await ref
            .read(stageTrackerRepositoryProvider)
            .updateStageRuleStatus(rule.id, StageRuleStatus.paused);
        _invalidateStageTrackerActionProviders(ref, rule.stageTrackerId);
        if (updated) {
          _syncAfterStageMutation(
            ref,
            await _stageTrackerPackId(ref, rule.stageTrackerId),
          );
        }
        return;
      case _StageRuleMenuAction.resume:
        final updated = await ref
            .read(stageTrackerRepositoryProvider)
            .updateStageRuleStatus(rule.id, StageRuleStatus.active);
        _invalidateStageTrackerActionProviders(ref, rule.stageTrackerId);
        if (updated) {
          _syncAfterStageMutation(
            ref,
            await _stageTrackerPackId(ref, rule.stageTrackerId),
          );
        }
        return;
      case _StageRuleMenuAction.archive:
        final confirmed = await _showStageActionConfirmation(
          context,
          title: ReminderUiText.archiveStageRuleTitle,
          message: ReminderUiText.archiveStageRuleMessage,
          confirmLabel: ReminderUiText.archiveAction,
          isDestructive: true,
        );
        if (confirmed != true) {
          return;
        }
        final updated = await ref
            .read(stageTrackerRepositoryProvider)
            .updateStageRuleStatus(rule.id, StageRuleStatus.archived);
        _invalidateStageTrackerActionProviders(ref, rule.stageTrackerId);
        if (updated) {
          _syncAfterStageMutation(
            ref,
            await _stageTrackerPackId(ref, rule.stageTrackerId),
          );
        }
        return;
    }
  }
}

enum _ManualStageMenuAction { addRelated, edit, archive }

class _CompactStageTimelineRow extends ConsumerWidget {
  const _CompactStageTimelineRow({
    required this.occurrence,
    required this.now,
    required this.keyPrefix,
    this.enableExpansion = false,
    this.isExpanded = false,
    this.onToggleExpanded,
  });

  final StageOccurrence occurrence;
  final DateTime now;
  final String keyPrefix;
  final bool enableExpansion;
  final bool isExpanded;
  final VoidCallback? onToggleExpanded;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = context.reminderPalette;
    final summary = occurrence.relatedItemSummary;
    final canManageManualStage =
        occurrence.isManual && occurrence.stageRecordId != null;
    final showRecurringIcon =
        keyPrefix == 'detail' &&
        (occurrence.stageRuleId != null || occurrence.isGenerated);
    return Container(
      key: Key(
        '$keyPrefix-stage-occurrence-${_stageOccurrenceKey(occurrence)}',
      ),
      margin: const EdgeInsets.only(bottom: _StageTrackerDetailDensity.cardGap),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: palette.surfaceCard,
        borderRadius: BorderRadius.circular(
          _StageTrackerDetailDensity.cardRadius,
        ),
        border: Border.all(color: palette.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 5),
                child: Container(
                  width: _StageTrackerDetailDensity.timelineMarkerSize,
                  height: _StageTrackerDetailDensity.timelineMarkerSize,
                  decoration: BoxDecoration(
                    color: palette.domainStage,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: GestureDetector(
                  key: Key(
                    '$keyPrefix-stage-occurrence-body-${_stageOccurrenceKey(occurrence)}',
                  ),
                  behavior: HitTestBehavior.opaque,
                  onTap: enableExpansion ? onToggleExpanded : null,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              occurrence.label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(
                                    color: palette.textPrimary,
                                    fontWeight: FontWeight.w800,
                                  ),
                            ),
                          ),
                          if (showRecurringIcon) ...[
                            const SizedBox(width: 4),
                            Icon(
                              Icons.autorenew,
                              key: Key(
                                '$keyPrefix-recurring-occurrence-icon-${_stageOccurrenceKey(occurrence)}',
                              ),
                              size: 15,
                              color: palette.textMuted,
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _metadata(summary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: palette.textMuted,
                        ),
                      ),
                      if ((occurrence.note ?? '').trim().isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          occurrence.note!.trim(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(color: palette.textSecondary),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              if (canManageManualStage)
                SizedBox(
                  width: _StageTrackerDetailDensity.rowActionSize,
                  height: _StageTrackerDetailDensity.rowActionSize,
                  child: PopupMenuButton<_ManualStageMenuAction>(
                    key: Key(
                      '$keyPrefix-manual-stage-overflow-${_stageOccurrenceKey(occurrence)}',
                    ),
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
                    onSelected: (action) => _handleManualStageAction(
                      context,
                      ref,
                      occurrence,
                      action,
                    ),
                  ),
                ),
            ],
          ),
          if (enableExpansion && isExpanded) ...[
            const SizedBox(height: 8),
            Padding(
              padding: EdgeInsets.only(
                left: _StageTrackerDetailDensity.timelineMarkerSize + 10,
              ),
              child: _StageRelatedReminderExpansion(
                occurrence: occurrence,
                previewDate: now,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _handleManualStageAction(
    BuildContext context,
    WidgetRef ref,
    StageOccurrence occurrence,
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
        final archived = await ref
            .read(stageTrackerRepositoryProvider)
            .deleteOrArchiveImportantStage(stageRecordId);
        _invalidateStageTrackerActionProviders(ref, occurrence.stageTrackerId);
        if (archived) {
          _syncAfterStageMutation(
            ref,
            await _stageTrackerPackId(ref, occurrence.stageTrackerId),
          );
        }
        return;
    }
  }

  String _metadata(StageRelatedItemSummary? summary) {
    final parts = [
      ReminderFormatters.date(occurrence.occurrenceDate),
      _countdownLabel(occurrence.occurrenceDate, now),
      if (_hasVisibleRelatedItemSummary(summary))
        ReminderFormatters.relatedItemSummary(summary!),
    ];
    return parts.join('・');
  }
}

class _StageRelatedReminderExpansion extends ConsumerWidget {
  const _StageRelatedReminderExpansion({
    required this.occurrence,
    required this.previewDate,
  });

  final StageOccurrence occurrence;
  final DateTime previewDate;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recordId = occurrence.stageRecordId;
    if (recordId == null) {
      return _StageRelatedReminderPanel(
        occurrence: occurrence,
        entries: const [],
        previewDate: previewDate,
      );
    }
    final entriesAsync = ref.watch(stageRelatedItemEntriesProvider(recordId));
    return entriesAsync.when(
      data: (entries) => _StageRelatedReminderPanel(
        occurrence: occurrence,
        entries: entries,
        previewDate: previewDate,
      ),
      error: (error, stack) => Text(
        '讀取相關提醒失敗',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: context.reminderPalette.textSecondary,
        ),
      ),
      loading: () => const SizedBox(
        height: 24,
        child: Align(
          alignment: Alignment.centerLeft,
          child: SizedBox.square(
            dimension: 14,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      ),
    );
  }
}

class _StageRelatedReminderPanel extends ConsumerWidget {
  const _StageRelatedReminderPanel({
    required this.occurrence,
    required this.entries,
    required this.previewDate,
  });

  final StageOccurrence occurrence;
  final List<StageRelatedItemEntry> entries;
  final DateTime previewDate;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = context.reminderPalette;
    return Container(
      key: Key('stage-related-expanded-${_stageOccurrenceKey(occurrence)}'),
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: palette.surfaceWarm,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            entries.isEmpty
                ? ReminderUiText.noRelatedReminders
                : ReminderUiText.relatedItemsTitle,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: palette.textSecondary,
              fontWeight: FontWeight.w800,
            ),
          ),

          if (entries.isNotEmpty) ...[
            const SizedBox(height: 4),
            for (final entry in entries)
              _StageRelatedReminderRow(entry: entry, previewDate: previewDate),
          ],
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              key: Key(
                'stage-related-create-${_stageOccurrenceKey(occurrence)}',
              ),
              onPressed: () => _showRelatedItemDialog(context, ref, occurrence),
              style: TextButton.styleFrom(
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              icon: const Icon(Icons.add, size: 16),
              label: const Text(ReminderUiText.addRelatedReminder),
            ),
          ),
        ],
      ),
    );
  }
}

class _StageRelatedReminderRow extends StatelessWidget {
  const _StageRelatedReminderRow({
    required this.entry,
    required this.previewDate,
  });

  final StageRelatedItemEntry entry;
  final DateTime previewDate;

  @override
  Widget build(BuildContext context) {
    final palette = context.reminderPalette;
    final viewModel = ManagementItemCardViewModel.fromBundle(
      entry.bundle,
      now: previewDate,
    );
    return InkWell(
      key: Key('stage-related-item-${entry.relatedItemId}'),
      onTap: () => showItemSummaryDialog(
        context,
        entry.bundle,
        previewDate: previewDate,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          children: [
            SizedBox(
              width: 18,
              child: Text(
                _relatedItemMarker(entry),
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: _relatedItemColor(entry, viewModel, palette),
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            Expanded(
              child: Text(
                viewModel.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: palette.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 8),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 96),
              child: Text(
                _relatedItemStatusLabel(entry, viewModel),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(
                  context,
                ).textTheme.labelSmall?.copyWith(color: palette.textMuted),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _relatedItemMarker(StageRelatedItemEntry entry) {
    if (entry.hasDoneAction) {
      return '✓';
    }
    if (entry.hasSkippedAction) {
      return '!';
    }
    return '○';
  }

  Color _relatedItemColor(
    StageRelatedItemEntry entry,
    ManagementItemCardViewModel viewModel,
    ReminderPalette palette,
  ) {
    if (entry.hasDoneAction) {
      return palette.statusNormal;
    }
    if (entry.hasSkippedAction || viewModel.status.isWarningOrDanger) {
      return palette.statusDanger;
    }
    return palette.textMuted;
  }

  String _relatedItemStatusLabel(
    StageRelatedItemEntry entry,
    ManagementItemCardViewModel viewModel,
  ) {
    if (entry.hasDoneAction) {
      return '已完成';
    }
    if (entry.hasSkippedAction) {
      return '已跳過';
    }
    if (entry.bundle.item.status == ItemLifecycleStatus.paused) {
      return ReminderUiText.lifecyclePausedLabel;
    }
    return viewModel.dueDateLabel ?? viewModel.compactSummaryLabel;
  }
}

class _StageOccurrenceTile extends StatelessWidget {
  const _StageOccurrenceTile({
    required this.occurrence,
    required this.now,
    this.showSource = false,
  });

  final StageOccurrence occurrence;
  final DateTime now;
  final bool showSource;

  @override
  Widget build(BuildContext context) {
    final summary = occurrence.relatedItemSummary;
    final palette = context.reminderPalette;
    return ReminderPaperCard(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(ReminderSpacing.cardCompact),
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: ReminderIconBubble(
          size: 44,
          backgroundColor: palette.statusNormalContainer,
          child: Icon(Icons.flag_outlined, color: palette.domainStage),
        ),
        title: Text(occurrence.label),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(ReminderFormatters.date(occurrence.occurrenceDate)),
            if (showSource)
              Text('來源：${_stageOccurrenceSourceLabel(occurrence)}'),
            if ((occurrence.note ?? '').trim().isNotEmpty)
              Text(occurrence.note!.trim()),
            if (_hasVisibleRelatedItemSummary(summary))
              Text(ReminderFormatters.relatedItemSummary(summary!)),
          ],
        ),
      ),
    );
  }
}
