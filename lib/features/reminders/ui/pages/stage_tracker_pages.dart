import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/reminder_theme.dart';
import '../../data/stage_tracker_models.dart';
import '../../domain/item_pack.dart';
import '../../domain/stage_occurrence.dart';
import '../../domain/stage_rule.dart';
import '../../domain/stage_tracker.dart';
import '../../presentation/formatters/reminder_formatters.dart';
import '../../presentation/text/reminder_ui_text.dart';
import '../../providers/developer_settings_providers.dart';
import '../../providers/item_providers.dart';
import '../../providers/stage_tracker_providers.dart';
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
    final previewDate = ref.watch(effectivePreviewDateProvider);
    final summaryAsync = ref.watch(stageTrackerOverviewSummaryProvider);
    final attentionOccurrences =
        ref.watch(stageTrackerAttentionOccurrencesProvider).valueOrNull ??
        const <StageOccurrence>[];

    return ListView(
      padding: const EdgeInsets.all(_StageTrackerManagementDensity.pagePadding),
      children: [
        _StageTrackerManagementHeader(
          onAddTracker: () => _showCreateStageTrackerDialog(context, ref),
        ),
        const SizedBox(height: _StageTrackerManagementDensity.sectionGap),
        _StageTrackerSummaryCard(summaryAsync: summaryAsync),
        const SizedBox(height: _StageTrackerManagementDensity.sectionGap),
        trackersAsync.when(
          data: (trackers) {
            if (trackers.isEmpty) {
              return const _StageTrackerCompactEmptyState();
            }
            final packs = packsAsync.valueOrNull ?? const <ItemPack>[];
            return GridView.builder(
              key: const Key('stage-tracker-grid'),
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: trackers.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: _StageTrackerManagementDensity.gridGap,
                mainAxisSpacing: _StageTrackerManagementDensity.gridGap,
                childAspectRatio: 0.88,
              ),
              itemBuilder: (context, index) {
                final tracker = trackers[index];
                return _StageTrackerAchievementCard(
                  tracker: tracker,
                  pack: _packFor(tracker.packId, packs),
                  now: previewDate,
                  attentionOccurrence: _attentionOccurrenceFor(
                    tracker.id,
                    attentionOccurrences,
                  ),
                );
              },
            );
          },
          error: (error, stack) => Text('讀取失敗: $error'),
          loading: () => const Center(child: CircularProgressIndicator()),
        ),
      ],
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

  StageOccurrence? _attentionOccurrenceFor(
    int trackerId,
    List<StageOccurrence> occurrences,
  ) {
    for (final occurrence in occurrences) {
      if (occurrence.stageTrackerId == trackerId) {
        return occurrence;
      }
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
        Semantics(
          label: ReminderUiText.addStageTracker,
          button: true,
          child: IconButton.filled(
            key: const Key('add-stage-tracker-button'),
            onPressed: onAddTracker,
            tooltip: ReminderUiText.addStageTracker,
            icon: const Icon(Icons.add),
            visualDensity: VisualDensity.compact,
            constraints: const BoxConstraints.tightFor(width: 40, height: 40),
          ),
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

class _StageTrackerCompactEmptyState extends StatelessWidget {
  const _StageTrackerCompactEmptyState();

  @override
  Widget build(BuildContext context) {
    final palette = context.reminderPalette;
    return Container(
      key: const Key('stage-tracker-empty-state'),
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: palette.surfaceWarm,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: palette.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '還沒有階段追蹤。',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: palette.textSecondary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '建立第一個追蹤，看看時間累積起來的樣子。',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: palette.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _StageTrackerAchievementCard extends StatelessWidget {
  const _StageTrackerAchievementCard({
    required this.tracker,
    required this.pack,
    required this.now,
    required this.attentionOccurrence,
  });

  final StageTracker tracker;
  final ItemPack? pack;
  final DateTime now;
  final StageOccurrence? attentionOccurrence;

  @override
  Widget build(BuildContext context) {
    final palette = context.reminderPalette;
    final statusLabel = _statusLabel(tracker, attentionOccurrence, now);
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
                _accumulatedDaysLabel(tracker, now),
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
                _shortTitle(tracker, pack),
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

  String _accumulatedDaysLabel(StageTracker tracker, DateTime now) {
    final start = _normalizeDate(tracker.trackingStartDate);
    final current = _normalizeDate(now);
    if (current.isBefore(start)) {
      return '0天';
    }
    final end = tracker.trackingEndDate == null
        ? null
        : _normalizeDate(tracker.trackingEndDate!);
    final effectiveDate = end != null && current.isAfter(end) ? end : current;
    final days = effectiveDate.difference(start).inDays;
    if (days < 0) {
      return '0天';
    }
    return '$days天';
  }

  String? _statusLabel(
    StageTracker tracker,
    StageOccurrence? attentionOccurrence,
    DateTime now,
  ) {
    if (tracker.status == StageTrackerStatus.archived) {
      return '已封存';
    }
    if (attentionOccurrence != null) {
      final current = _normalizeDate(now);
      final occurrenceDate = _normalizeDate(attentionOccurrence.occurrenceDate);
      return _countdownLabel(occurrenceDate.difference(current).inDays);
    }
    return null;
  }

  String _countdownLabel(int days) {
    if (days <= 0) {
      return '今日';
    }
    if (days == 1) {
      return '明日';
    }
    return '$days天後';
  }

  String _shortTitle(StageTracker tracker, ItemPack? pack) {
    final trackerTitle = tracker.title.trim();
    final packTitle = pack?.title.trim();
    if (pack != null &&
        !pack.isSystemDefault &&
        packTitle != null &&
        packTitle.isNotEmpty &&
        packTitle.length < trackerTitle.length) {
      return packTitle;
    }
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

class StageTrackerDetailPage extends ConsumerWidget {
  const StageTrackerDetailPage({super.key, required this.stageTrackerId});

  static const routeName = 'stage-tracker-detail';
  static const routePath = '/stage-tracker/:id';

  final int stageTrackerId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(stageTrackerDetailProvider(stageTrackerId));
    final previewDate = ref.watch(effectivePreviewDateProvider);

    return Scaffold(
      appBar: AppBar(title: const Text(ReminderUiText.stageTrackerTitle)),
      body: detailAsync.when(
        data: (detail) {
          if (detail == null) {
            return const Center(
              child: Text(ReminderUiText.stageTrackerMissingMessage),
            );
          }
          final tracker = detail.stageTracker;
          final next = detail.nextStage;
          return ListView(
            padding: const EdgeInsets.all(ReminderSpacing.page),
            children: [
              _StageHeroCard(tracker: tracker, now: previewDate),
              const SizedBox(height: ReminderSpacing.section),
              _InfoPanel(
                title: ReminderUiText.nextStageLabel,
                icon: Icons.flag_outlined,
                child: next == null
                    ? const ReminderEmptyState(
                        message: ReminderUiText.noStageUpcoming,
                      )
                    : _StageOccurrenceTile(
                        occurrence: next,
                        now: previewDate,
                        showRelatedAction: true,
                      ),
              ),
              const SizedBox(height: ReminderSpacing.section),
              _InfoPanel(
                title: ReminderUiText.upcomingStagesTitle,
                icon: Icons.event_available_outlined,
                child: detail.dashboardUpcomingStages.isEmpty
                    ? const ReminderEmptyState(
                        message: ReminderUiText.noStageUpcoming,
                      )
                    : Column(
                        children: [
                          for (final occurrence
                              in detail.dashboardUpcomingStages)
                            _StageOccurrenceTile(
                              occurrence: occurrence,
                              now: previewDate,
                              showRelatedAction: true,
                            ),
                        ],
                      ),
              ),
              const SizedBox(height: ReminderSpacing.section),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  FilledButton(
                    key: const Key('add-stage-rule-button'),
                    onPressed: () =>
                        _showStageRuleDialog(context, ref, tracker.id),
                    child: const Text('加入重複階段'),
                  ),
                  FilledButton(
                    key: const Key('add-important-stage-button'),
                    onPressed: () =>
                        _showImportantStageDialog(context, ref, tracker.id),
                    child: const Text('新增重要階段'),
                  ),
                  OutlinedButton(
                    onPressed: () => context.pushNamed(
                      StageTrackerSchedulePage.routeName,
                      pathParameters: {'id': tracker.id.toString()},
                    ),
                    child: const Text('查看完整時間表'),
                  ),
                  OutlinedButton(
                    onPressed: () => context.pushNamed(
                      StageTrackerHistoryPage.routeName,
                      pathParameters: {'id': tracker.id.toString()},
                    ),
                    child: const Text('查看歷史'),
                  ),
                ],
              ),
              const SizedBox(height: ReminderSpacing.section),
              _StageRuleList(rules: detail.stageRules),
            ],
          );
        },
        error: (error, stack) => Center(child: Text('讀取失敗: $error')),
        loading: () => const Center(child: CircularProgressIndicator()),
      ),
    );
  }
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
            return const Center(child: Text(ReminderUiText.noStageUpcoming));
          }
          return ListView(
            padding: const EdgeInsets.all(ReminderSpacing.page),
            children: [
              for (final occurrence in stages)
                _StageOccurrenceTile(
                  occurrence: occurrence,
                  now: previewDate,
                  showRelatedAction: true,
                ),
            ],
          );
        },
        error: (error, stack) => Center(child: Text('讀取失敗: $error')),
        loading: () => const Center(child: CircularProgressIndicator()),
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
            return const Center(
              child: Text(ReminderUiText.noStageTrackerHistory),
            );
          }
          return ListView(
            padding: const EdgeInsets.all(ReminderSpacing.page),
            children: [
              for (final occurrence in stages)
                _StageOccurrenceTile(
                  occurrence: occurrence,
                  now: previewDate,
                  showRelatedAction: false,
                  showSource: true,
                ),
            ],
          );
        },
        error: (error, stack) => Center(child: Text('讀取失敗: $error')),
        loading: () => const Center(child: CircularProgressIndicator()),
      ),
    );
  }
}

class _StageHeroCard extends StatelessWidget {
  const _StageHeroCard({required this.tracker, required this.now});

  final StageTracker tracker;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final palette = context.reminderPalette;
    return ReminderPaperCard(
      backgroundColor: palette.surfaceWarm,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ReminderIconBubble(
                size: 64,
                backgroundColor: palette.statusNormalContainer,
                child: Icon(
                  Icons.child_care_outlined,
                  color: palette.domainStage,
                ),
              ),
              const SizedBox(width: 14),
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
                          tracker.title,
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        ReminderBadge(
                          label: '階段追蹤',
                          color: palette.domainStage,
                          backgroundColor: palette.statusNormalContainer,
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      ReminderFormatters.stageProgress(tracker, now: now),
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const ReminderTimelineDots(
            labels: ['開始', '現在', '下一步', '之後'],
            activeIndex: 1,
          ),
        ],
      ),
    );
  }
}

class _StageRuleList extends StatelessWidget {
  const _StageRuleList({required this.rules});

  final List<StageRule> rules;

  @override
  Widget build(BuildContext context) {
    if (rules.isEmpty) {
      return const Text(ReminderUiText.stageRuleMissingMessage);
    }
    return _InfoPanel(
      title: ReminderUiText.stageRulesTitle,
      icon: Icons.repeat_outlined,
      child: Column(
        children: [
          for (final rule in rules)
            ReminderPaperCard(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(ReminderSpacing.cardCompact),
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(ReminderFormatters.stageRuleSummary(rule)),
                subtitle: rule.labelTemplate == null
                    ? null
                    : Text(rule.labelTemplate!),
                trailing: Text(ReminderFormatters.stageRuleStatus(rule.status)),
              ),
            ),
        ],
      ),
    );
  }
}

class _StageOccurrenceTile extends ConsumerWidget {
  const _StageOccurrenceTile({
    required this.occurrence,
    required this.now,
    required this.showRelatedAction,
    this.showSource = false,
  });

  final StageOccurrence occurrence;
  final DateTime now;
  final bool showRelatedAction;
  final bool showSource;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
            if (showSource) Text(occurrence.isManual ? '來源：重要階段' : '來源：重複階段'),
            if ((occurrence.note ?? '').trim().isNotEmpty)
              Text(occurrence.note!.trim()),
            if (summary != null)
              Text(ReminderFormatters.relatedItemSummary(summary)),
          ],
        ),
        trailing: showRelatedAction
            ? IconButton(
                tooltip: '建立相關提醒',
                onPressed: () =>
                    _showRelatedItemDialog(context, ref, occurrence),
                icon: const Icon(Icons.add_circle_outline),
              )
            : null,
      ),
    );
  }
}

class _InfoPanel extends StatelessWidget {
  const _InfoPanel({required this.title, required this.child, this.icon});

  final String title;
  final Widget child;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ReminderSectionHeader(title: title, icon: icon),
        const SizedBox(height: 8),
        child,
      ],
    );
  }
}
