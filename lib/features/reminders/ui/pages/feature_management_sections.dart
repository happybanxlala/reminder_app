import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/local/item_timeline_dao.dart';
import '../../domain/item.dart';
import '../../domain/item_pack.dart';
import '../../domain/timeline.dart';
import '../../domain/timeline_milestone_occurrence.dart';
import '../../presentation/formatters/reminder_formatters.dart';
import '../../presentation/text/reminder_ui_text.dart';
import '../../providers/developer_settings_providers.dart';
import '../../providers/item_providers.dart';
import '../../providers/timeline_providers.dart';
import 'item_edit_page.dart';
import 'timeline_edit_page.dart';
import 'timeline_milestone_history_page.dart';

class DefaultItemsManagementContent extends ConsumerWidget {
  const DefaultItemsManagementContent({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final packsAsync = ref.watch(activeItemPacksProvider);
    final itemsAsync = ref.watch(itemsProvider);
    final previewDate = ref.watch(effectivePreviewDateProvider);

    if (packsAsync.hasError) {
      return Center(child: Text('讀取失敗: ${packsAsync.error}'));
    }
    if (itemsAsync.hasError) {
      return Center(child: Text('讀取失敗: ${itemsAsync.error}'));
    }
    if (packsAsync.isLoading || itemsAsync.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final defaultPack = packsAsync.requireValue.cast<ItemPack?>().firstWhere(
      (pack) => pack?.isSystemDefault ?? false,
      orElse: () => null,
    );
    if (defaultPack == null) {
      return const Center(child: Text(ReminderUiText.noDefaultItemPack));
    }

    final defaultItems = itemsAsync.requireValue
        .where((item) => item.pack.isSystemDefault)
        .toList(growable: false);
    final repository = ref.read(itemRepositoryProvider);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _SectionHeader(
          title: ReminderUiText.itemsManagementFeatureTitle,
          actions: [
            FilledButton(
              key: const Key('add-item-button'),
              onPressed: () {
                context.pushNamed(ItemEditPage.createRouteName);
              },
              child: const Text(ReminderUiText.addItem),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Card(
          key: Key('default-pack-${defaultPack.id}'),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      defaultPack.title,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Container(
                      key: Key('pack-system-default-${defaultPack.id}'),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.secondaryContainer,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: const Text(ReminderUiText.systemDefaultPackLabel),
                    ),
                  ],
                ),
                if ((defaultPack.description ?? '').trim().isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(defaultPack.description!.trim()),
                ],
                const SizedBox(height: 4),
                Text('${defaultItems.length} ${ReminderUiText.itemCountLabel}'),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        if (defaultItems.isEmpty)
          const Text(ReminderUiText.noItems)
        else
          ...defaultItems.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _ItemCard(
                bundle: item,
                status: repository.statusFor(item.item, now: previewDate),
              ),
            ),
          ),
      ],
    );
  }
}

class ItemPacksManagementContent extends ConsumerWidget {
  const ItemPacksManagementContent({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final packsAsync = ref.watch(activeItemPacksProvider);
    final itemsAsync = ref.watch(itemsProvider);

    if (packsAsync.hasError) {
      return Center(child: Text('讀取失敗: ${packsAsync.error}'));
    }
    if (itemsAsync.hasError) {
      return Center(child: Text('讀取失敗: ${itemsAsync.error}'));
    }
    if (packsAsync.isLoading || itemsAsync.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final packs = packsAsync.requireValue;
    final items = itemsAsync.requireValue;
    if (packs.isEmpty) {
      return ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          _SectionHeader(
            title: ReminderUiText.itemPacksManagementFeatureTitle,
            actions: [],
          ),
          SizedBox(height: 12),
          Text(ReminderUiText.noItemPacks),
        ],
      );
    }

    final itemsByPackId = <int, List<ItemBundle>>{};
    for (final item in items) {
      itemsByPackId.putIfAbsent(item.pack.id, () => []).add(item);
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _SectionHeader(
          title: ReminderUiText.itemPacksManagementFeatureTitle,
          actions: [
            FilledButton(
              key: const Key('add-pack-button'),
              onPressed: () => _showPackDialog(context, ref),
              child: const Text(ReminderUiText.addItemPack),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...packs.map(
          (pack) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _ItemPackSummaryCard(
              pack: pack,
              itemCount: (itemsByPackId[pack.id] ?? const []).length,
            ),
          ),
        ),
      ],
    );
  }
}

class TimelineManagementContent extends ConsumerWidget {
  const TimelineManagementContent({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timelinesAsync = ref.watch(timelinesProvider);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _SectionHeader(
          title: ReminderUiText.timelineManagementFeatureTitle,
          actions: [
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
                  .map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _TimelineCard(timeline: item),
                    ),
                  )
                  .toList(growable: false),
            );
          },
          error: (error, stack) => Text('讀取失敗: $error'),
          loading: () => const Center(child: CircularProgressIndicator()),
        ),
      ],
    );
  }
}

Future<void> _showPackDialog(
  BuildContext context,
  WidgetRef ref, {
  ItemPack? pack,
}) async {
  if (pack?.isSystemDefault ?? false) {
    return;
  }
  final input = await showDialog<ItemPackInput>(
    context: context,
    builder: (dialogContext) => _PackFormDialog(pack: pack),
  );
  if (input == null || !context.mounted) {
    return;
  }

  final repository = ref.read(itemRepositoryProvider);
  if (pack == null) {
    await repository.createPack(input);
    return;
  }

  final updated = await repository.updatePack(pack.id, input);
  if (!updated && context.mounted) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('此 pack 目前不可編輯。')));
  }
}

class _ItemPackSummaryCard extends ConsumerWidget {
  const _ItemPackSummaryCard({required this.pack, required this.itemCount});

  final ItemPack pack;
  final int itemCount;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repository = ref.read(itemRepositoryProvider);

    return Card(
      key: Key('pack-section-${pack.id}'),
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
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            pack.title,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          if (pack.isSystemDefault)
                            Container(
                              key: Key('pack-system-default-${pack.id}'),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Theme.of(
                                  context,
                                ).colorScheme.secondaryContainer,
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: const Text(
                                ReminderUiText.systemDefaultPackLabel,
                              ),
                            ),
                        ],
                      ),
                      if ((pack.description ?? '').trim().isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(pack.description!.trim()),
                      ],
                      const SizedBox(height: 4),
                      Text('$itemCount ${ReminderUiText.itemCountLabel}'),
                    ],
                  ),
                ),
                if (!pack.isSystemDefault)
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      OutlinedButton(
                        key: Key('pack-edit-${pack.id}'),
                        onPressed: () =>
                            _showPackDialog(context, ref, pack: pack),
                        child: const Text(ReminderUiText.editAction),
                      ),
                      OutlinedButton(
                        key: Key('pack-archive-${pack.id}'),
                        onPressed: () async {
                          final canArchive = await repository.canArchivePack(
                            pack.id,
                          );
                          if (!context.mounted) {
                            return;
                          }
                          if (!canArchive) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  ReminderUiText.packArchiveBlockedMessage,
                                ),
                              ),
                            );
                            return;
                          }
                          await repository.archivePack(pack.id);
                        },
                        child: const Text(ReminderUiText.archiveAction),
                      ),
                    ],
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ItemCard extends ConsumerWidget {
  const _ItemCard({required this.bundle, required this.status});

  final ItemBundle bundle;
  final ItemStatus status;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).dividerColor),
        borderRadius: BorderRadius.circular(12),
      ),
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
                        bundle.item.title,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(ReminderFormatters.itemSummary(bundle)),
                    ],
                  ),
                ),
                Text(ReminderFormatters.itemStatus(status)),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton(
                  key: Key('item-edit-${bundle.item.id}'),
                  onPressed: () {
                    context.pushNamed(
                      ItemEditPage.editRouteName,
                      pathParameters: {'id': bundle.item.id.toString()},
                    );
                  },
                  child: const Text(ReminderUiText.editAction),
                ),
                OutlinedButton(
                  key: Key('item-done-${bundle.item.id}'),
                  onPressed: () async {
                    await ref
                        .read(itemRepositoryProvider)
                        .markDone(bundle.item.id);
                  },
                  child: const Text(ReminderUiText.completeAction),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.actions});

  final String title;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        if (actions.isNotEmpty) ...[
          const SizedBox(height: 12),
          Wrap(spacing: 8, runSpacing: 8, children: actions),
        ],
      ],
    );
  }
}

class _PackFormDialog extends StatefulWidget {
  const _PackFormDialog({this.pack});

  final ItemPack? pack;

  @override
  State<_PackFormDialog> createState() => _PackFormDialogState();
}

class _PackFormDialogState extends State<_PackFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;

  bool get _isEdit => widget.pack != null;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.pack?.title ?? '');
    _descriptionController = TextEditingController(
      text: widget.pack?.description ?? '',
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        _isEdit ? ReminderUiText.editItemPack : ReminderUiText.addItemPack,
      ),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              key: const Key('pack-title-field'),
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: ReminderUiText.packTitleFieldLabel,
              ),
              validator: (value) {
                if ((value ?? '').trim().isEmpty) {
                  return '請輸入 Pack Title';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              key: const Key('pack-description-field'),
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: ReminderUiText.packDescriptionFieldLabel,
              ),
              maxLines: 2,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
        ),
        FilledButton(
          key: const Key('pack-save-button'),
          onPressed: _submit,
          child: const Text(ReminderUiText.saveAction),
        ),
      ],
    );
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    Navigator.of(context).pop(
      ItemPackInput(
        title: _titleController.text.trim(),
        description: _normalizeOptionalText(_descriptionController.text),
      ),
    );
  }

  String? _normalizeOptionalText(String value) {
    final normalized = value.trim();
    return normalized.isEmpty ? null : normalized;
  }
}

class _TimelineCard extends ConsumerWidget {
  const _TimelineCard({required this.timeline});

  final Timeline timeline;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(previewTimelineDetailProvider(timeline.id));

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
