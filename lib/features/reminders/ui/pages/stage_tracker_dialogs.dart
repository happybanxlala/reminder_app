part of 'stage_tracker_pages.dart';

Future<void> _showCreateStageTrackerDialog(
  BuildContext context,
  WidgetRef ref,
) async {
  final packs =
      ref.read(activeItemPacksProvider).valueOrNull ?? const <ItemPack>[];
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

enum _StageEntryTab { important, recurring }

Future<void> _showStageEntryDialog(
  BuildContext context,
  WidgetRef ref,
  int trackerId, {
  _StageEntryTab initialTab = _StageEntryTab.important,
}) async {
  await showDialog<void>(
    context: context,
    builder: (dialogContext) => _StageEntryDialog(
      trackerId: trackerId,
      ref: ref,
      initialTab: initialTab,
    ),
  );
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

Future<void> _showRelatedItemSummaryDialog(
  BuildContext context,
  StageRelatedItemSummary summary,
) async {
  await showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text(ReminderUiText.relatedItemsTitle),
      content: Text(ReminderFormatters.relatedItemSummary(summary)),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(),
          child: const Text(ReminderUiText.closeAction),
        ),
      ],
    ),
  );
}

class _StageTrackerFormDialog extends ConsumerStatefulWidget {
  const _StageTrackerFormDialog({required this.packs});

  final List<ItemPack> packs;

  @override
  ConsumerState<_StageTrackerFormDialog> createState() =>
      _StageTrackerFormDialogState();
}

class _StageTrackerFormDialogState
    extends ConsumerState<_StageTrackerFormDialog> {
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
                    labelText: ReminderUiText.packFieldLabel,
                  ),
                  items: [
                    const DropdownMenuItem<int?>(
                      value: null,
                      child: Text(ReminderUiText.unassignedPackOption),
                    ),
                    ...widget.packs.map(
                      (pack) => DropdownMenuItem<int?>(
                        value: pack.id,
                        child: Text(packDisplayLabel(pack)),
                      ),
                    ),
                  ],
                  onChanged: (value) => setState(() => _packId = value),
                ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    key: const Key('stage-tracker-add-pack-button'),
                    onPressed: _createPackInline,
                    icon: const Icon(Icons.add),
                    label: const Text(ReminderUiText.addItemPack),
                  ),
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

  Future<void> _createPackInline() async {
    final input = await showDialog<ItemPackInput>(
      context: context,
      builder: (dialogContext) => const PackFormDialog(),
    );
    if (input == null || !mounted) {
      return;
    }
    final packId = await ref.read(itemRepositoryProvider).createPack(input);
    if (!mounted) {
      return;
    }
    setState(() {
      _packId = packId;
    });
  }
}

class _StageEntryDialog extends StatelessWidget {
  const _StageEntryDialog({
    required this.trackerId,
    required this.ref,
    required this.initialTab,
  });

  final int trackerId;
  final WidgetRef ref;
  final _StageEntryTab initialTab;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      initialIndex: initialTab == _StageEntryTab.recurring ? 1 : 0,
      child: AlertDialog(
        title: const Text(ReminderUiText.addStageEntry),
        content: SizedBox(
          width: 420,
          height: 430,
          child: Column(
            children: [
              const TabBar(
                tabs: [
                  Tab(text: ReminderUiText.importantStageTitle),
                  Tab(text: ReminderUiText.stageRulesTitle),
                ],
              ),
              const SizedBox(height: 8),
              Expanded(
                child: TabBarView(
                  children: [
                    _ImportantStageForm(
                      onSubmit: (input) =>
                          _createImportantStage(context, input),
                    ),
                    _StageRuleForm(
                      onSubmit: (input) => _createStageRule(context, input),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _createImportantStage(
    BuildContext context,
    ManualStageInput input,
  ) async {
    await ref
        .read(stageTrackerRepositoryProvider)
        .createImportantStage(trackerId, input);
    ref.invalidate(stageTrackerDetailProvider(trackerId));
    if (context.mounted) {
      Navigator.of(context).pop();
    }
  }

  Future<void> _createStageRule(
    BuildContext context,
    StageRuleInput input,
  ) async {
    await ref
        .read(stageTrackerRepositoryProvider)
        .createStageRule(trackerId, input);
    ref.invalidate(stageTrackerDetailProvider(trackerId));
    if (context.mounted) {
      Navigator.of(context).pop();
    }
  }
}

class _StageRuleForm extends StatefulWidget {
  const _StageRuleForm({required this.onSubmit});

  final Future<void> Function(StageRuleInput input) onSubmit;

  @override
  State<_StageRuleForm> createState() => _StageRuleFormState();
}

class _StageRuleFormState extends State<_StageRuleForm> {
  final _intervalController = TextEditingController(text: '1');
  final _labelController = TextEditingController();
  final _reminderController = TextEditingController();
  StageIntervalUnit _unit = StageIntervalUnit.months;
  bool _saving = false;

  @override
  void dispose() {
    _intervalController.dispose();
    _labelController.dispose();
    _reminderController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
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
              DropdownMenuItem(value: StageIntervalUnit.days, child: Text('天')),
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
          const SizedBox(height: 12),
          _StageEntryFormActions(
            saving: _saving,
            submitLabel: ReminderUiText.addRecurringStage,
            onSubmit: _submit,
          ),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    if (_saving) {
      return;
    }
    setState(() => _saving = true);
    final interval = int.tryParse(_intervalController.text.trim()) ?? 1;
    final type = switch (_unit) {
      StageIntervalUnit.days => StageRuleType.everyNDays,
      StageIntervalUnit.weeks => StageRuleType.everyNWeeks,
      StageIntervalUnit.months => StageRuleType.everyNMonths,
      StageIntervalUnit.years => StageRuleType.everyNYears,
    };
    try {
      await widget.onSubmit(
        StageRuleInput(
          type: type,
          intervalValue: interval <= 0 ? 1 : interval,
          intervalUnit: _unit,
          labelTemplate: _labelController.text.trim().isEmpty
              ? null
              : _labelController.text.trim(),
          reminderOffsetDays: int.tryParse(_reminderController.text.trim()),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }
}

class _ImportantStageForm extends StatefulWidget {
  const _ImportantStageForm({required this.onSubmit});

  final Future<void> Function(ManualStageInput input) onSubmit;

  @override
  State<_ImportantStageForm> createState() => _ImportantStageFormState();
}

class _ImportantStageFormState extends State<_ImportantStageForm> {
  final _titleController = TextEditingController();
  final _noteController = TextEditingController();
  final _reminderController = TextEditingController();
  DateTime _date = DateTime.now();
  bool _saving = false;

  @override
  void dispose() {
    _titleController.dispose();
    _noteController.dispose();
    _reminderController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
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
          const SizedBox(height: 12),
          _StageEntryFormActions(
            saving: _saving,
            submitLabel: ReminderUiText.addImportantStage,
            onSubmit: _submit,
          ),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    if (_saving) {
      return;
    }
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      return;
    }
    setState(() => _saving = true);
    try {
      await widget.onSubmit(
        ManualStageInput(
          label: title,
          occurrenceDate: _date,
          note: _noteController.text.trim().isEmpty
              ? null
              : _noteController.text.trim(),
          reminderOffsetDays: int.tryParse(_reminderController.text.trim()),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }
}

class _StageEntryFormActions extends StatelessWidget {
  const _StageEntryFormActions({
    required this.saving,
    required this.submitLabel,
    required this.onSubmit,
  });

  final bool saving;
  final String submitLabel;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextButton(
          onPressed: saving ? null : () => Navigator.of(context).pop(),
          child: const Text(ReminderUiText.closeAction),
        ),
        const SizedBox(width: 8),
        FilledButton(
          onPressed: saving ? null : onSubmit,
          child: Text(submitLabel),
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
