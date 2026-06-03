import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/reminder_theme.dart';
import '../../data/local/reminder_dao.dart';
import '../../data/stage_tracker_models.dart';
import '../../domain/item.dart';
import '../../domain/item_pack.dart';
import '../../domain/stage_occurrence.dart';
import '../../domain/stage_occurrence_service.dart';
import '../../domain/stage_record.dart';
import '../../domain/stage_related_item.dart';
import '../../domain/stage_rule.dart';
import '../../domain/stage_tracker.dart';
import '../../presentation/formatters/reminder_formatters.dart';
import '../../presentation/text/reminder_ui_text.dart';
import '../../presentation/view_models/management_item_card_view_model.dart';
import '../../providers/developer_settings_providers.dart';
import '../../providers/item_providers.dart';
import '../../providers/stage_tracker_providers.dart';
import '../widgets/editor_common_fields.dart';
import '../widgets/editor_form_components.dart';
import '../widgets/item_summary_dialog.dart';
import '../widgets/pack_picker.dart';
import '../widgets/reminder_components.dart';

part 'stage_tracker_dialogs.dart';

class StageTrackerManagementPage extends StatelessWidget {
  const StageTrackerManagementPage({super.key});

  static const routeName = 'stage-trackers';
  static const routePath = '/feature/stage-trackers';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(ReminderUiText.stageTrackerManagementFeatureTitle),
      ),
      body: const StageTrackerManagementContent(),
    );
  }
}

class StageTrackerManagementContent extends ConsumerWidget {
  const StageTrackerManagementContent({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trackersAsync = ref.watch(stageTrackersProvider);
    final packsAsync = ref.watch(itemPacksProvider);
    final rulesAsync = ref.watch(stageRulesProvider);
    final recordsAsync = ref.watch(stageRecordsProvider);
    final previewDate = ref.watch(effectivePreviewDateProvider);
    final summaryAsync = ref.watch(stageTrackerOverviewSummaryProvider);
    final attentionOccurrences =
        ref.watch(stageTrackerAttentionOccurrencesProvider).valueOrNull ??
        const <StageOccurrence>[];

    return ReminderRefreshable(
      onRefresh: () async {
        ref.invalidate(stageTrackersProvider);
        ref.invalidate(stageRulesProvider);
        ref.invalidate(stageRecordsProvider);
        ref.invalidate(itemPacksProvider);
        ref.invalidate(stageTrackerOverviewSummaryProvider);
        ref.invalidate(stageTrackerAttentionOccurrencesProvider);
        await Future<void>.delayed(Duration.zero);
      },
      child: ListView(
        physics: reminderRefreshPhysics,
        padding: const EdgeInsets.all(
          _StageTrackerManagementDensity.pagePadding,
        ),
        children: [
          _StageTrackerManagementHeader(
            onAddTracker: () => _showCreateStageTrackerDialog(context, ref),
          ),
          const SizedBox(height: _StageTrackerManagementDensity.sectionGap),
          _StageTrackerSummaryCard(summaryAsync: summaryAsync),
          const SizedBox(height: _StageTrackerManagementDensity.sectionGap),
          trackersAsync.when(
            data: (trackers) {
              final showAddCard = trackers
                  .where((tracker) => !tracker.isSystemDefault)
                  .isEmpty;
              final packs = packsAsync.valueOrNull ?? const <ItemPack>[];
              final rules = rulesAsync.valueOrNull ?? const <StageRule>[];
              final records = recordsAsync.valueOrNull ?? const <StageRecord>[];
              return GridView.builder(
                key: const Key('stage-tracker-grid'),
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: trackers.length + (showAddCard ? 1 : 0),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: _StageTrackerManagementDensity.gridGap,
                  mainAxisSpacing: _StageTrackerManagementDensity.gridGap,
                  childAspectRatio: 0.88,
                ),
                itemBuilder: (context, index) {
                  if (showAddCard && index == trackers.length) {
                    return _StageTrackerDashedAddCard(
                      onTap: () => _showCreateStageTrackerDialog(context, ref),
                    );
                  }
                  final tracker = trackers[index];
                  return _StageTrackerAchievementCard(
                    tracker: tracker,
                    pack: _packFor(tracker.packId, packs),
                    now: previewDate,
                    nearestOccurrence: _nearestOccurrenceFor(
                      tracker,
                      attentionOccurrences,
                      rules,
                      records,
                      previewDate,
                    ),
                  );
                },
              );
            },
            error: (error, stack) => Text('讀取失敗: $error'),
            loading: () => const Center(child: CircularProgressIndicator()),
          ),
        ],
      ),
    );
  }

  ItemPack? _packFor(int packId, List<ItemPack> packs) {
    for (final pack in packs) {
      if (pack.id == packId) {
        return pack;
      }
    }
    return null;
  }

  StageOccurrence? _nearestOccurrenceFor(
    StageTracker tracker,
    List<StageOccurrence> occurrences,
    List<StageRule> rules,
    List<StageRecord> records,
    DateTime previewDate,
  ) {
    for (final occurrence in occurrences) {
      if (occurrence.stageTrackerId == tracker.id) {
        return occurrence;
      }
    }
    if (tracker.status != StageTrackerStatus.active) {
      return null;
    }
    final service = const StageOccurrenceService();
    final trackerRules = rules.where(
      (rule) => rule.stageTrackerId == tracker.id,
    );
    final trackerRecords = records
        .where((record) => record.stageTrackerId == tracker.id)
        .toList(growable: false);
    final ruleOccurrences = [
      for (final rule in trackerRules)
        service.getNextOccurrence(
          rule,
          tracker,
          after: previewDate,
          records: trackerRecords,
        ),
    ].whereType<StageOccurrence>().toList()..sort(service.compareFuture);
    if (ruleOccurrences.isNotEmpty) {
      return ruleOccurrences.first;
    }
    return null;
  }
}

class _StageTrackerManagementDensity {
  const _StageTrackerManagementDensity._();

  static const pagePadding = 12.0;
  static const sectionGap = 10.0;
  static const gridGap = 8.0;
  static const cardPadding = 9.0;
  static const cardRadius = 16.0;
  static const iconSize = 34.0;
}

class _StageTrackerManagementHeader extends StatelessWidget {
  const _StageTrackerManagementHeader({required this.onAddTracker});

  final VoidCallback onAddTracker;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            ReminderUiText.stageTrackerManagementFeatureTitle,
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
        TextButton.icon(
          key: const Key('stage-tracker-content-add-button'),
          onPressed: onAddTracker,
          icon: const Icon(Icons.add, size: 18),
          label: const Text(ReminderUiText.addStageTracker),
        ),
      ],
    );
  }
}

class _StageTrackerSummaryCard extends StatelessWidget {
  const _StageTrackerSummaryCard({required this.summaryAsync});

  final AsyncValue<StageTrackerOverviewSummary> summaryAsync;

  @override
  Widget build(BuildContext context) {
    final palette = context.reminderPalette;
    return ReminderPaperCard(
      key: const Key('stage-tracker-summary-card'),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      radius: _StageTrackerManagementDensity.cardRadius,
      backgroundColor: palette.surfaceWarm,
      child: summaryAsync.when(
        data: (summary) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final entry in summary.entries)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 1),
                child: Row(
                  children: [
                    Icon(
                      _summaryIcon(entry.kind),
                      size: 15,
                      color: entry.kind == StageTrackerSummaryEntryKind.neutral
                          ? palette.textSecondary
                          : palette.domainStage,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        entry.text,
                        key: Key('stage-tracker-summary-${entry.kind.name}'),
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
              ),
          ],
        ),
        error: (error, stack) => Text(
          '讀取失敗: $error',
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: palette.textSecondary),
        ),
        loading: () => Text(
          '持續記錄中。',
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: palette.textSecondary),
        ),
      ),
    );
  }

  IconData _summaryIcon(StageTrackerSummaryEntryKind kind) {
    return switch (kind) {
      StageTrackerSummaryEntryKind.upcoming => Icons.flag_outlined,
      StageTrackerSummaryEntryKind.longest => Icons.auto_graph_outlined,
      StageTrackerSummaryEntryKind.next => Icons.event_available_outlined,
      StageTrackerSummaryEntryKind.neutral => Icons.check_circle_outline,
    };
  }
}

class _StageTrackerDashedAddCard extends StatelessWidget {
  const _StageTrackerDashedAddCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.reminderPalette;
    return Semantics(
      button: true,
      label: ReminderUiText.addStageTrackerCardTitle,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(
          _StageTrackerManagementDensity.cardRadius,
        ),
        child: InkWell(
          key: const Key('stage-tracker-dashed-add-card'),
          onTap: onTap,
          borderRadius: BorderRadius.circular(
            _StageTrackerManagementDensity.cardRadius,
          ),
          child: CustomPaint(
            painter: _DashedBorderPainter(
              color: palette.domainStage.withValues(alpha: 0.45),
              radius: _StageTrackerManagementDensity.cardRadius,
            ),
            child: Container(
              alignment: Alignment.center,
              padding: const EdgeInsets.all(
                _StageTrackerManagementDensity.cardPadding,
              ),
              decoration: BoxDecoration(
                color: palette.surfaceWarm.withValues(alpha: 0.72),
                borderRadius: BorderRadius.circular(
                  _StageTrackerManagementDensity.cardRadius,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '+',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: palette.domainStage,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    ReminderUiText.addStageTrackerCardTitle,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: palette.textPrimary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    ReminderUiText.addStageTrackerCardSubtitle,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: palette.textSecondary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  const _DashedBorderPainter({required this.color, required this.radius});

  final Color color;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(radius)),
      );
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final end = (distance + 6).clamp(0.0, metric.length);
        canvas.drawPath(metric.extractPath(distance, end), paint);
        distance += 10;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedBorderPainter oldDelegate) {
    return color != oldDelegate.color || radius != oldDelegate.radius;
  }
}

class _StageTrackerAchievementCard extends StatelessWidget {
  const _StageTrackerAchievementCard({
    required this.tracker,
    required this.pack,
    required this.now,
    required this.nearestOccurrence,
  });

  final StageTracker tracker;
  final ItemPack? pack;
  final DateTime now;
  final StageOccurrence? nearestOccurrence;

  @override
  Widget build(BuildContext context) {
    final palette = context.reminderPalette;
    final statusLabel = _statusLabel(nearestOccurrence, now);
    return Tooltip(
      message: '查看 ${tracker.title} 階段追蹤',
      child: Semantics(
        label: '查看 ${tracker.title} 階段追蹤',
        button: true,
        child: ReminderPaperCard(
          key: Key('stage-tracker-card-${tracker.id}'),
          onTap: () => context.pushNamed(
            StageTrackerDetailPage.routeName,
            pathParameters: {'id': tracker.id.toString()},
          ),
          padding: const EdgeInsets.all(
            _StageTrackerManagementDensity.cardPadding,
          ),
          radius: _StageTrackerManagementDensity.cardRadius,
          borderColor: palette.domainStage.withValues(alpha: 0.28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _StageTrackerEmojiBubble(pack: pack, trackerId: tracker.id),
              const SizedBox(height: 7),
              Text(
                ReminderFormatters.stageTrackerDayLabel(tracker, now: now),
                key: Key('stage-tracker-days-${tracker.id}'),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: palette.textPrimary,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                _trackerTitle(tracker),
                key: Key('stage-tracker-short-title-${tracker.id}'),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: palette.textSecondary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (statusLabel != null) ...[
                const SizedBox(height: 2),
                Text(
                  statusLabel,
                  key: Key('stage-tracker-status-${tracker.id}'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: palette.textMuted,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String? _statusLabel(StageOccurrence? attentionOccurrence, DateTime now) {
    if (attentionOccurrence != null) {
      final current = _normalizeDate(now);
      final occurrenceDate = _normalizeDate(attentionOccurrence.occurrenceDate);
      return _countdownLabel(occurrenceDate.difference(current).inDays);
    }
    return null;
  }

  String _countdownLabel(int days) {
    if (days <= 0) {
      return '今天';
    }
    if (days == 1) {
      return '明天';
    }
    return '$days天後';
  }

  String _trackerTitle(StageTracker tracker) {
    final trackerTitle = tracker.title.trim();
    return trackerTitle.isEmpty
        ? ReminderUiText.stageTrackerLabel
        : trackerTitle;
  }

  DateTime _normalizeDate(DateTime value) {
    return DateTime(value.year, value.month, value.day);
  }
}

class _StageTrackerEmojiBubble extends StatelessWidget {
  const _StageTrackerEmojiBubble({required this.pack, required this.trackerId});

  final ItemPack? pack;
  final int trackerId;

  @override
  Widget build(BuildContext context) {
    final palette = context.reminderPalette;
    return Container(
      key: Key('stage-tracker-emoji-$trackerId'),
      width: _StageTrackerManagementDensity.iconSize,
      height: _StageTrackerManagementDensity.iconSize,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: palette.statusNormalContainer,
        shape: BoxShape.circle,
        border: Border.all(color: palette.borderSubtle),
      ),
      child: pack == null
          ? Icon(Icons.timeline_outlined, size: 18, color: palette.domainStage)
          : Text(pack!.iconEmoji, style: const TextStyle(fontSize: 18)),
    );
  }
}

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

class StageTrackerSchedulePage extends ConsumerWidget {
  const StageTrackerSchedulePage({super.key, required this.stageTrackerId});

  static const routeName = 'stage-tracker-schedule';
  static const routePath = '/stage-tracker/:id/schedule';

  final int stageTrackerId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(stageTrackerDetailProvider(stageTrackerId));
    final previewDate = ref.watch(effectivePreviewDateProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('完整時間表')),
      body: detailAsync.when(
        data: (detail) {
          final stages = detail?.scheduleStages ?? const <StageOccurrence>[];
          if (stages.isEmpty) {
            return ReminderRefreshablePlaceholder(
              onRefresh: () => _refreshStageTrackerDetail(ref, stageTrackerId),
              child: const Text(ReminderUiText.noStageUpcoming),
            );
          }
          return ReminderRefreshable(
            onRefresh: () => _refreshStageTrackerDetail(ref, stageTrackerId),
            child: ListView(
              physics: reminderRefreshPhysics,
              padding: const EdgeInsets.all(ReminderSpacing.page),
              children: [
                for (final occurrence in stages)
                  _StageOccurrenceTile(
                    occurrence: occurrence,
                    now: previewDate,
                  ),
              ],
            ),
          );
        },
        error: (error, stack) => ReminderRefreshablePlaceholder(
          onRefresh: () => _refreshStageTrackerDetail(ref, stageTrackerId),
          child: Text('讀取失敗: $error'),
        ),
        loading: () => ReminderRefreshablePlaceholder(
          onRefresh: () => _refreshStageTrackerDetail(ref, stageTrackerId),
          child: const CircularProgressIndicator(),
        ),
      ),
    );
  }
}

class StageTrackerHistoryPage extends ConsumerWidget {
  const StageTrackerHistoryPage({super.key, required this.stageTrackerId});

  static const routeName = 'stage-tracker-history';
  static const routePath = '/stage-tracker/:id/history';

  final int stageTrackerId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(stageTrackerDetailProvider(stageTrackerId));
    final previewDate = ref.watch(effectivePreviewDateProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text(ReminderUiText.stageTrackerHistoryTitle),
      ),
      body: detailAsync.when(
        data: (detail) {
          final stages = detail?.historyStages ?? const <StageOccurrence>[];
          if (stages.isEmpty) {
            return ReminderRefreshablePlaceholder(
              onRefresh: () => _refreshStageTrackerDetail(ref, stageTrackerId),
              child: const Text(ReminderUiText.noStageTrackerHistory),
            );
          }
          return ReminderRefreshable(
            onRefresh: () => _refreshStageTrackerDetail(ref, stageTrackerId),
            child: ListView(
              physics: reminderRefreshPhysics,
              padding: const EdgeInsets.all(ReminderSpacing.page),
              children: [
                for (final occurrence in stages)
                  _StageOccurrenceTile(
                    occurrence: occurrence,
                    now: previewDate,
                    showSource: true,
                  ),
              ],
            ),
          );
        },
        error: (error, stack) => ReminderRefreshablePlaceholder(
          onRefresh: () => _refreshStageTrackerDetail(ref, stageTrackerId),
          child: Text('讀取失敗: $error'),
        ),
        loading: () => ReminderRefreshablePlaceholder(
          onRefresh: () => _refreshStageTrackerDetail(ref, stageTrackerId),
          child: const CircularProgressIndicator(),
        ),
      ),
    );
  }
}

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
  final VoidCallback onAddRule;

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
  final VoidCallback onAddRule;

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
        await ref
            .read(stageTrackerRepositoryProvider)
            .updateStageRuleStatus(rule.id, StageRuleStatus.paused);
        _invalidateStageTrackerActionProviders(ref, rule.stageTrackerId);
        return;
      case _StageRuleMenuAction.resume:
        await ref
            .read(stageTrackerRepositoryProvider)
            .updateStageRuleStatus(rule.id, StageRuleStatus.active);
        _invalidateStageTrackerActionProviders(ref, rule.stageTrackerId);
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
        await ref
            .read(stageTrackerRepositoryProvider)
            .updateStageRuleStatus(rule.id, StageRuleStatus.archived);
        _invalidateStageTrackerActionProviders(ref, rule.stageTrackerId);
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
        await ref
            .read(stageTrackerRepositoryProvider)
            .deleteOrArchiveImportantStage(stageRecordId);
        _invalidateStageTrackerActionProviders(ref, occurrence.stageTrackerId);
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
