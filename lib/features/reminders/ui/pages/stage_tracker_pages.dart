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

    return ListView(
      padding: const EdgeInsets.all(ReminderSpacing.page),
      children: [
        FilledButton.icon(
          key: const Key('add-stage-tracker-button'),
          onPressed: () => _showCreateStageTrackerDialog(context, ref),
          icon: const Icon(Icons.add),
          label: const Text(ReminderUiText.addStageTracker),
        ),
        const SizedBox(height: ReminderSpacing.section),
        trackersAsync.when(
          data: (trackers) {
            if (trackers.isEmpty) {
              return const ReminderEmptyState(
                message: ReminderUiText.noStageTrackers,
              );
            }
            final packs = packsAsync.valueOrNull ?? const <ItemPack>[];
            final active = trackers
                .where((item) => !item.isTrackingRangeCompleted(previewDate))
                .toList(growable: false);
            final completed = trackers
                .where((item) => item.isTrackingRangeCompleted(previewDate))
                .toList(growable: false);
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _TrackerGroup(
                  title: ReminderUiText.activeTrackingGroup,
                  trackers: active,
                  packs: packs,
                  now: previewDate,
                ),
                const SizedBox(height: ReminderSpacing.section),
                _TrackerGroup(
                  title: ReminderUiText.completedTrackingRangeGroup,
                  trackers: completed,
                  packs: packs,
                  now: previewDate,
                ),
              ],
            );
          },
          error: (error, stack) => Text('讀取失敗: $error'),
          loading: () => const Center(child: CircularProgressIndicator()),
        ),
      ],
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

class _TrackerGroup extends StatelessWidget {
  const _TrackerGroup({
    required this.title,
    required this.trackers,
    required this.packs,
    required this.now,
  });

  final String title;
  final List<StageTracker> trackers;
  final List<ItemPack> packs;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    if (trackers.isEmpty) {
      return const SizedBox.shrink();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ReminderSectionHeader(title: title, icon: Icons.auto_graph_outlined),
        const SizedBox(height: 8),
        for (final tracker in trackers)
          Padding(
            padding: const EdgeInsets.only(bottom: ReminderSpacing.listGap),
            child: _StageTrackerCard(
              tracker: tracker,
              packTitle: _packTitle(tracker.packId, packs),
              now: now,
            ),
          ),
      ],
    );
  }

  String _packTitle(int packId, List<ItemPack> packs) {
    for (final pack in packs) {
      if (pack.id == packId) {
        return packDisplayLabel(pack);
      }
    }
    return ReminderUiText.unassignedPackTitle;
  }
}

class _StageTrackerCard extends ConsumerWidget {
  const _StageTrackerCard({
    required this.tracker,
    required this.packTitle,
    required this.now,
  });

  final StageTracker tracker;
  final String packTitle;
  final DateTime now;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = context.reminderPalette;
    final detailAsync = ref.watch(stageTrackerDetailProvider(tracker.id));
    final next = detailAsync.valueOrNull?.nextStage;
    return ReminderRailCard(
      railColor: palette.domainStage,
      onTap: () => context.pushNamed(
        StageTrackerDetailPage.routeName,
        pathParameters: {'id': tracker.id.toString()},
      ),
      child: Row(
        key: Key('stage-tracker-${tracker.id}'),
        children: [
          ReminderIconBubble(
            size: 56,
            backgroundColor: palette.statusNormalContainer,
            child: Icon(Icons.timeline_outlined, color: palette.domainStage),
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
                      tracker.title,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    ReminderBadge(
                      label: '階段追蹤',
                      color: palette.domainStage,
                      backgroundColor: palette.statusNormalContainer,
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(packTitle),
                Text(ReminderFormatters.stageProgress(tracker, now: now)),
                if (next != null)
                  Text(
                    '${ReminderUiText.nextStageLabel}：${ReminderFormatters.stageRelativeLabel(next, now: now)}',
                  ),
              ],
            ),
          ),
          Icon(Icons.chevron_right, color: palette.primaryWarm),
        ],
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
