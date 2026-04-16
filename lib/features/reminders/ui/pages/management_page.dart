import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/timeline_milestone_occurrence.dart';
import '../../domain/timeline.dart';
import '../../presentation/formatters/reminder_formatters.dart';
import '../../presentation/text/reminder_ui_text.dart';
import '../../providers/responsibility_providers.dart';
import '../../providers/timeline_providers.dart';
import 'responsibility_item_edit_page.dart';
import 'timeline_edit_page.dart';
import 'timeline_milestone_history_page.dart';

class ManagementPage extends ConsumerWidget {
  const ManagementPage({super.key});

  static const routeName = 'management';
  static const routePath = '/manage';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final responsibilityItemsAsync = ref.watch(responsibilityItemsProvider);
    final timelinesAsync = ref.watch(timelinesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text(ReminderUiText.manageTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  ReminderUiText.responsibilityItemTitle,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              FilledButton(
                key: const Key('add-responsibility-item-button'),
                onPressed: () {
                  context.pushNamed(ResponsibilityItemEditPage.createRouteName);
                },
                child: const Text(ReminderUiText.addResponsibilityItem),
              ),
            ],
          ),
          const SizedBox(height: 12),
          responsibilityItemsAsync.when(
            data: (items) {
              if (items.isEmpty) {
                return const Text(ReminderUiText.noResponsibilityItems);
              }
              final repository = ref.read(responsibilityRepositoryProvider);
              return Column(
                children: items
                    .map(
                      (item) => Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item.item.title,
                                          style: Theme.of(
                                            context,
                                          ).textTheme.titleMedium,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(item.pack.title),
                                        const SizedBox(height: 4),
                                        Text(
                                          ReminderFormatters.responsibilitySummary(
                                            item,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Text(
                                    ReminderFormatters.responsibilityStatus(
                                      repository.statusFor(item.item),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Wrap(
                                spacing: 8,
                                children: [
                                  OutlinedButton(
                                    key: Key(
                                      'responsibility-edit-${item.item.id}',
                                    ),
                                    onPressed: () {
                                      context.pushNamed(
                                        ResponsibilityItemEditPage
                                            .editRouteName,
                                        pathParameters: {
                                          'id': item.item.id.toString(),
                                        },
                                      );
                                    },
                                    child: const Text(
                                      ReminderUiText.editAction,
                                    ),
                                  ),
                                  OutlinedButton(
                                    key: Key(
                                      'responsibility-done-${item.item.id}',
                                    ),
                                    onPressed: () async {
                                      await repository.markDone(item.item.id);
                                    },
                                    child: const Text(
                                      ReminderUiText.completeAction,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                    .toList(growable: false),
              );
            },
            error: (error, stack) => Text('讀取失敗: $error'),
            loading: () => const Center(child: CircularProgressIndicator()),
          ),
          const Divider(height: 32),
          Row(
            children: [
              const Expanded(
                child: Text(
                  ReminderUiText.timelineTitle,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              FilledButton(
                key: const Key('add-timeline-button'),
                onPressed: () {
                  context.pushNamed(TimelineEditPage.timelineNewRouteName);
                },
                child: const Text(ReminderUiText.addTimeline),
              ),
            ],
          ),
          const SizedBox(height: 12),
          timelinesAsync.when(
            data: (items) {
              if (items.isEmpty) {
                return const Text(ReminderUiText.noTimelines);
              }
              return Column(
                children: items
                    .map((item) => _TimelineCard(timeline: item))
                    .toList(growable: false),
              );
            },
            error: (error, stack) => Text('讀取失敗: $error'),
            loading: () => const Center(child: CircularProgressIndicator()),
          ),
        ],
      ),
    );
  }
}

class _TimelineCard extends ConsumerWidget {
  const _TimelineCard({required this.timeline});

  final Timeline timeline;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(timelineDetailProvider(timeline.id));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
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
                        timeline.title,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(ReminderFormatters.timelineSummary(timeline)),
                    ],
                  ),
                ),
                Text(ReminderFormatters.timelineStatus(timeline.status)),
              ],
            ),
            const SizedBox(height: 12),
            detailAsync.when(
              data: (detail) {
                final ruleDetails = detail?.milestoneRuleDetails ?? const [];
                if (ruleDetails.isEmpty) {
                  return const Text('尚未建立 milestone rule。');
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(ReminderUiText.milestoneRulesTitle),
                    const SizedBox(height: 8),
                    ...ruleDetails.map(
                      (item) => ListTile(
                        contentPadding: EdgeInsets.zero,
                        key: Key(
                          'timeline-rule-${timeline.id}-${item.rule.id}',
                        ),
                        title: Text(
                          ReminderFormatters.timelineMilestoneRuleSummary(
                            item.rule,
                          ),
                        ),
                        subtitle: Text(
                          item.nextMilestone == null
                              ? '下一筆：目前無法產生 milestone'
                              : '下一筆：${ReminderFormatters.milestoneSummary(item.nextMilestone!)}',
                        ),
                        trailing: Text(
                          ReminderFormatters.timelineMilestoneRuleStatus(
                            item.rule.status,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
              error: (error, stack) => const Text('讀取 milestone rule 失敗。'),
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
            const SizedBox(height: 12),
            detailAsync.when(
              data: (detail) {
                final firstUpcomingByRule = _firstUpcomingByRule(
                  detail?.upcomingMilestones ?? const [],
                );
                if (firstUpcomingByRule.isEmpty) {
                  return const Text(ReminderUiText.noTimelineUpcomingMilestone);
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(ReminderUiText.nextMilestoneLabel),
                    const SizedBox(height: 8),
                    ...firstUpcomingByRule.map(
                      (occurrence) => ListTile(
                        contentPadding: EdgeInsets.zero,
                        key: Key(
                          'timeline-upcoming-${timeline.id}-${occurrence.ruleId}',
                        ),
                        title: Text(occurrence.label),
                        subtitle: Text(
                          ReminderFormatters.date(occurrence.targetDate),
                        ),
                      ),
                    ),
                  ],
                );
              },
              error: (error, stack) => const Text('讀取 upcoming milestone 失敗。'),
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton(
                  key: Key('timeline-history-${timeline.id}'),
                  onPressed: () {
                    context.pushNamed(
                      TimelineMilestoneHistoryPage.routeName,
                      pathParameters: {'id': timeline.id.toString()},
                    );
                  },
                  child: const Text(
                    ReminderUiText.timelineMilestoneHistoryTitle,
                  ),
                ),
                if (timeline.status != TimelineStatus.archived)
                  OutlinedButton(
                    key: Key('timeline-edit-${timeline.id}'),
                    onPressed: () {
                      context.pushNamed(
                        TimelineEditPage.timelineEditRouteName,
                        pathParameters: {'id': timeline.id.toString()},
                      );
                    },
                    child: const Text(ReminderUiText.editAction),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  List<TimelineMilestoneOccurrence> _firstUpcomingByRule(
    List<TimelineMilestoneOccurrence> items,
  ) {
    final byRule = <int, TimelineMilestoneOccurrence>{};
    for (final item in items) {
      byRule.putIfAbsent(item.ruleId, () => item);
    }
    return byRule.values.toList(growable: false)
      ..sort((a, b) => a.targetDate.compareTo(b.targetDate));
  }
}
