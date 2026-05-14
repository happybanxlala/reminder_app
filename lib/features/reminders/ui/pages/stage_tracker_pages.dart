import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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
      padding: const EdgeInsets.all(16),
      children: [
        FilledButton.icon(
          key: const Key('add-stage-tracker-button'),
          onPressed: () => _showCreateStageTrackerDialog(context, ref),
          icon: const Icon(Icons.add),
          label: const Text(ReminderUiText.addStageTracker),
        ),
        const SizedBox(height: 16),
        trackersAsync.when(
          data: (trackers) {
            if (trackers.isEmpty) {
              return const Text(ReminderUiText.noStageTrackers);
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
                const SizedBox(height: 20),
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
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                tracker.title,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 4),
              Text(ReminderFormatters.stageProgress(tracker, now: previewDate)),
              const SizedBox(height: 16),
              _InfoPanel(
                title: ReminderUiText.nextStageLabel,
                child: next == null
                    ? const Text(ReminderUiText.noStageUpcoming)
                    : _StageOccurrenceTile(
                        occurrence: next,
                        now: previewDate,
                        showRelatedAction: true,
                      ),
              ),
              const SizedBox(height: 16),
              _InfoPanel(
                title: ReminderUiText.upcomingStagesTitle,
                child: detail.dashboardUpcomingStages.isEmpty
                    ? const Text(ReminderUiText.noStageUpcoming)
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
              const SizedBox(height: 16),
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
              const SizedBox(height: 16),
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
            padding: const EdgeInsets.all(16),
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
            padding: const EdgeInsets.all(16),
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
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        for (final tracker in trackers)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _StageTrackerCard(
              tracker: tracker,
              packTitle: _packTitle(tracker.packId, packs),
              now: now,
            ),
          ),
      ],
    );
  }

  String _packTitle(int? packId, List<ItemPack> packs) {
    if (packId == null) {
      return '全局';
    }
    for (final pack in packs) {
      if (pack.id == packId) {
        return pack.isSystemDefault ? '全局' : pack.title;
      }
    }
    return '全局';
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
    final detailAsync = ref.watch(stageTrackerDetailProvider(tracker.id));
    final next = detailAsync.valueOrNull?.nextStage;
    return Card(
      child: ListTile(
        key: Key('stage-tracker-${tracker.id}'),
        onTap: () => context.pushNamed(
          StageTrackerDetailPage.routeName,
          pathParameters: {'id': tracker.id.toString()},
        ),
        title: Text(tracker.title),
        subtitle: Text(
          [
            packTitle,
            ReminderFormatters.stageProgress(tracker, now: now),
            if (next != null)
              '${ReminderUiText.nextStageLabel}：${ReminderFormatters.stageRelativeLabel(next, now: now)}',
          ].join('\n'),
        ),
        isThreeLine: true,
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
      child: Column(
        children: [
          for (final rule in rules)
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(ReminderFormatters.stageRuleSummary(rule)),
              subtitle: rule.labelTemplate == null
                  ? null
                  : Text(rule.labelTemplate!),
              trailing: Text(ReminderFormatters.stageRuleStatus(rule.status)),
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
    return ListTile(
      contentPadding: EdgeInsets.zero,
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
              onPressed: () => _showRelatedItemDialog(context, ref, occurrence),
              icon: const Icon(Icons.add_circle_outline),
            )
          : null,
    );
  }
}

class _InfoPanel extends StatelessWidget {
  const _InfoPanel({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        child,
      ],
    );
  }
}
