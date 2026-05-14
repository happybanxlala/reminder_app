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

Future<void> _showCreateStageTrackerDialog(
  BuildContext context,
  WidgetRef ref,
) async {
  final packs = ref.read(itemPacksProvider).valueOrNull ?? const <ItemPack>[];
  final input = await showDialog<StageTrackerInput>(
    context: context,
    builder: (dialogContext) => _StageTrackerFormDialog(packs: packs),
  );
  if (input == null || !context.mounted) {
    return;
  }
  final id = await ref
      .read(stageTrackerRepositoryProvider)
      .createStageTracker(input);
  ref.invalidate(stageTrackersProvider);
  if (context.mounted) {
    context.pushNamed(
      StageTrackerDetailPage.routeName,
      pathParameters: {'id': id.toString()},
    );
  }
}

Future<void> _showStageRuleDialog(
  BuildContext context,
  WidgetRef ref,
  int trackerId,
) async {
  final input = await showDialog<StageRuleInput>(
    context: context,
    builder: (dialogContext) => const _StageRuleFormDialog(),
  );
  if (input == null) {
    return;
  }
  await ref
      .read(stageTrackerRepositoryProvider)
      .createStageRule(trackerId, input);
  ref.invalidate(stageTrackerDetailProvider(trackerId));
}

Future<void> _showImportantStageDialog(
  BuildContext context,
  WidgetRef ref,
  int trackerId,
) async {
  final input = await showDialog<ManualStageInput>(
    context: context,
    builder: (dialogContext) => const _ImportantStageFormDialog(),
  );
  if (input == null) {
    return;
  }
  await ref
      .read(stageTrackerRepositoryProvider)
      .createImportantStage(trackerId, input);
  ref.invalidate(stageTrackerDetailProvider(trackerId));
}

Future<void> _showRelatedItemDialog(
  BuildContext context,
  WidgetRef ref,
  StageOccurrence occurrence,
) async {
  final input = await showDialog<_RelatedItemInput>(
    context: context,
    builder: (dialogContext) => _RelatedItemDialog(occurrence: occurrence),
  );
  if (input == null) {
    return;
  }
  await ref
      .read(stageTrackerRepositoryProvider)
      .createRelatedItemFromOccurrence(
        occurrence,
        title: input.title,
        description: input.description,
        dueDate: input.dueDate,
      );
  ref.invalidate(stageTrackerDetailProvider(occurrence.stageTrackerId));
}

class _StageTrackerFormDialog extends StatefulWidget {
  const _StageTrackerFormDialog({required this.packs});

  final List<ItemPack> packs;

  @override
  State<_StageTrackerFormDialog> createState() =>
      _StageTrackerFormDialogState();
}

class _StageTrackerFormDialogState extends State<_StageTrackerFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _subjectController = TextEditingController();
  DateTime _startDate = DateTime.now();
  int? _packId;

  @override
  void dispose() {
    _titleController.dispose();
    _subjectController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text(ReminderUiText.addStageTracker),
      content: SizedBox(
        width: 420,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  key: const Key('stage-tracker-title-field'),
                  controller: _titleController,
                  decoration: const InputDecoration(labelText: '名稱'),
                  validator: (value) =>
                      value == null || value.trim().isEmpty ? '請輸入名稱' : null,
                ),
                TextFormField(
                  key: const Key('stage-tracker-subject-field'),
                  controller: _subjectController,
                  decoration: const InputDecoration(
                    labelText: '${ReminderUiText.subjectNameFieldLabel}，可留空',
                  ),
                ),
                const SizedBox(height: 8),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text(ReminderUiText.trackingStartDateFieldLabel),
                  subtitle: Text(ReminderFormatters.date(_startDate)),
                  trailing: const Icon(Icons.calendar_month_outlined),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _startDate,
                      firstDate: DateTime(1900),
                      lastDate: DateTime(2100),
                    );
                    if (picked != null) {
                      setState(() => _startDate = picked);
                    }
                  },
                ),
                DropdownButtonFormField<int?>(
                  key: const Key('stage-tracker-pack-field'),
                  initialValue: _packId,
                  decoration: const InputDecoration(
                    labelText: '${ReminderUiText.packFieldLabel} / 全局',
                  ),
                  items: [
                    const DropdownMenuItem<int?>(
                      value: null,
                      child: Text('全局'),
                    ),
                    ...widget.packs
                        .where((pack) => !pack.isSystemDefault)
                        .map(
                          (pack) => DropdownMenuItem<int?>(
                            value: pack.id,
                            child: Text(pack.title),
                          ),
                        ),
                  ],
                  onChanged: (value) => setState(() => _packId = value),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text(ReminderUiText.closeAction),
        ),
        FilledButton(
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
      StageTrackerInput(
        title: _titleController.text.trim(),
        subjectName: _subjectController.text.trim(),
        trackingStartDate: _startDate,
        packId: _packId,
      ),
    );
  }
}

class _StageRuleFormDialog extends StatefulWidget {
  const _StageRuleFormDialog();

  @override
  State<_StageRuleFormDialog> createState() => _StageRuleFormDialogState();
}

class _StageRuleFormDialogState extends State<_StageRuleFormDialog> {
  final _intervalController = TextEditingController(text: '1');
  final _labelController = TextEditingController();
  final _reminderController = TextEditingController();
  StageIntervalUnit _unit = StageIntervalUnit.months;

  @override
  void dispose() {
    _intervalController.dispose();
    _labelController.dispose();
    _reminderController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text(ReminderUiText.stageRulesTitle),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              key: const Key('stage-rule-interval-field'),
              controller: _intervalController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: ReminderUiText.stageRuleIntervalValueFieldLabel,
              ),
            ),
            DropdownButtonFormField<StageIntervalUnit>(
              key: const Key('stage-rule-unit-field'),
              initialValue: _unit,
              decoration: const InputDecoration(labelText: '單位'),
              items: const [
                DropdownMenuItem(
                  value: StageIntervalUnit.days,
                  child: Text('天'),
                ),
                DropdownMenuItem(
                  value: StageIntervalUnit.weeks,
                  child: Text('週'),
                ),
                DropdownMenuItem(
                  value: StageIntervalUnit.months,
                  child: Text('個月'),
                ),
                DropdownMenuItem(
                  value: StageIntervalUnit.years,
                  child: Text('年'),
                ),
              ],
              onChanged: (value) => setState(() => _unit = value ?? _unit),
            ),
            TextField(
              controller: _labelController,
              decoration: const InputDecoration(
                labelText: ReminderUiText.stageRuleLabelTemplateFieldLabel,
                helperText: '可使用 {value} 與 {unit}',
              ),
            ),
            TextField(
              controller: _reminderController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: ReminderUiText.stageRuleReminderOffsetFieldLabel,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text(ReminderUiText.closeAction),
        ),
        FilledButton(
          onPressed: () {
            final interval = int.tryParse(_intervalController.text.trim()) ?? 1;
            final type = switch (_unit) {
              StageIntervalUnit.days => StageRuleType.everyNDays,
              StageIntervalUnit.weeks => StageRuleType.everyNWeeks,
              StageIntervalUnit.months => StageRuleType.everyNMonths,
              StageIntervalUnit.years => StageRuleType.everyNYears,
            };
            Navigator.of(context).pop(
              StageRuleInput(
                type: type,
                intervalValue: interval <= 0 ? 1 : interval,
                intervalUnit: _unit,
                labelTemplate: _labelController.text.trim().isEmpty
                    ? null
                    : _labelController.text.trim(),
                reminderOffsetDays: int.tryParse(
                  _reminderController.text.trim(),
                ),
              ),
            );
          },
          child: const Text(ReminderUiText.saveAction),
        ),
      ],
    );
  }
}

class _ImportantStageFormDialog extends StatefulWidget {
  const _ImportantStageFormDialog();

  @override
  State<_ImportantStageFormDialog> createState() =>
      _ImportantStageFormDialogState();
}

class _ImportantStageFormDialogState extends State<_ImportantStageFormDialog> {
  final _titleController = TextEditingController();
  final _noteController = TextEditingController();
  final _reminderController = TextEditingController();
  DateTime _date = DateTime.now();

  @override
  void dispose() {
    _titleController.dispose();
    _noteController.dispose();
    _reminderController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text(ReminderUiText.importantStageTitle),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              key: const Key('important-stage-title-field'),
              controller: _titleController,
              decoration: const InputDecoration(labelText: '標題'),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('日期'),
              subtitle: Text(ReminderFormatters.date(_date)),
              trailing: const Icon(Icons.calendar_month_outlined),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _date,
                  firstDate: DateTime(1900),
                  lastDate: DateTime(2100),
                );
                if (picked != null) {
                  setState(() => _date = picked);
                }
              },
            ),
            TextField(
              controller: _noteController,
              decoration: const InputDecoration(labelText: '備註'),
            ),
            TextField(
              controller: _reminderController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: '提醒提前天數，可選'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text(ReminderUiText.closeAction),
        ),
        FilledButton(
          onPressed: () {
            final title = _titleController.text.trim();
            if (title.isEmpty) {
              return;
            }
            Navigator.of(context).pop(
              ManualStageInput(
                label: title,
                occurrenceDate: _date,
                note: _noteController.text.trim().isEmpty
                    ? null
                    : _noteController.text.trim(),
                reminderOffsetDays: int.tryParse(
                  _reminderController.text.trim(),
                ),
              ),
            );
          },
          child: const Text(ReminderUiText.saveAction),
        ),
      ],
    );
  }
}

class _RelatedItemInput {
  const _RelatedItemInput({
    required this.title,
    this.description,
    required this.dueDate,
  });

  final String title;
  final String? description;
  final DateTime dueDate;
}

class _RelatedItemDialog extends StatefulWidget {
  const _RelatedItemDialog({required this.occurrence});

  final StageOccurrence occurrence;

  @override
  State<_RelatedItemDialog> createState() => _RelatedItemDialogState();
}

class _RelatedItemDialogState extends State<_RelatedItemDialog> {
  late final TextEditingController _titleController;
  final _descriptionController = TextEditingController();
  late DateTime _dueDate;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.occurrence.label);
    _dueDate = widget.occurrence.occurrenceDate;
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
      title: const Text('建立相關提醒'),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: '名稱'),
            ),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(labelText: '備註'),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text(ReminderUiText.fixedDueDateFieldLabel),
              subtitle: Text(ReminderFormatters.date(_dueDate)),
              trailing: const Icon(Icons.calendar_month_outlined),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _dueDate,
                  firstDate: DateTime(1900),
                  lastDate: DateTime(2100),
                );
                if (picked != null) {
                  setState(() => _dueDate = picked);
                }
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text(ReminderUiText.closeAction),
        ),
        FilledButton(
          onPressed: () {
            final title = _titleController.text.trim();
            if (title.isEmpty) {
              return;
            }
            Navigator.of(context).pop(
              _RelatedItemInput(
                title: title,
                description: _descriptionController.text.trim().isEmpty
                    ? null
                    : _descriptionController.text.trim(),
                dueDate: _dueDate,
              ),
            );
          },
          child: const Text(ReminderUiText.saveAction),
        ),
      ],
    );
  }
}
