part of 'stage_tracker_pages.dart';

Future<void> _showCreateStageTrackerDialog(
  BuildContext context,
  WidgetRef ref,
) async {
  final packs = await ref
      .read(activeItemPacksProvider.future)
      .catchError((_) => const <ItemPack>[]);
  if (!context.mounted) {
    return;
  }
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
  ref.invalidate(stageTrackerOverviewSummaryProvider);
  ref.invalidate(stageTrackerAttentionOccurrencesProvider);
  if (context.mounted) {
    context.pushNamed(
      StageTrackerDetailPage.routeName,
      pathParameters: {'id': id.toString()},
    );
  }
}

Future<void> _showEditStageTrackerDialog(
  BuildContext context,
  WidgetRef ref,
  StageTracker tracker,
) async {
  final packs = await ref
      .read(activeItemPacksProvider.future)
      .catchError((_) => const <ItemPack>[]);
  if (!context.mounted) {
    return;
  }
  final input = await showDialog<StageTrackerInput>(
    context: context,
    builder: (dialogContext) =>
        _StageTrackerFormDialog(packs: packs, initialTracker: tracker),
  );
  if (input == null || !context.mounted) {
    return;
  }
  final updated = await ref
      .read(stageTrackerRepositoryProvider)
      .updateStageTracker(tracker.id, input);
  _invalidateStageTrackerActionProviders(ref, tracker.id);
  if (!context.mounted) {
    return;
  }
  if (!updated) {
    _showStageTrackerSaveFailed(context);
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
  _invalidateStageTrackerActionProviders(ref, occurrence.stageTrackerId);
  final stageRecordId = occurrence.stageRecordId;
  if (stageRecordId != null) {
    ref.invalidate(stageRelatedItemEntriesProvider(stageRecordId));
  }
}

Future<bool?> _showStageActionConfirmation(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
  bool isDestructive = false,
}) {
  return showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: Text(
            MaterialLocalizations.of(dialogContext).cancelButtonLabel,
          ),
        ),
        TextButton(
          style: isDestructive
              ? TextButton.styleFrom(
                  foregroundColor: Theme.of(dialogContext).colorScheme.error,
                )
              : null,
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
}

void _invalidateStageTrackerActionProviders(WidgetRef ref, int trackerId) {
  ref.invalidate(stageTrackersProvider);
  ref.invalidate(stageTrackerDetailProvider(trackerId));
  ref.invalidate(stageTrackerOverviewSummaryProvider);
  ref.invalidate(stageTrackerAttentionOccurrencesProvider);
}

void _showStageTrackerSaveFailed(BuildContext context) {
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text(ReminderUiText.stageTrackerSaveFailedMessage)),
  );
}

class _StageTrackerFormDialog extends ConsumerStatefulWidget {
  const _StageTrackerFormDialog({required this.packs, this.initialTracker});

  final List<ItemPack> packs;
  final StageTracker? initialTracker;

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
  DateTime? _endDate;
  int? _packId;

  bool get _isEdit => widget.initialTracker != null;

  @override
  void initState() {
    super.initState();
    final tracker = widget.initialTracker;
    if (tracker == null) {
      return;
    }
    _titleController.text = tracker.title;
    _subjectController.text = tracker.subjectName ?? '';
    _startDate = tracker.trackingStartDate;
    _endDate = tracker.trackingEndDate;
    _packId = tracker.packId;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _subjectController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selectedPackId = _packId;
    final selectedPackIsVisible =
        selectedPackId == null ||
        widget.packs.any((pack) => pack.id == selectedPackId);
    return AlertDialog(
      title: Text(
        _isEdit
            ? ReminderUiText.editStageTracker
            : ReminderUiText.addStageTracker,
      ),
      content: SizedBox(
        width: 420,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ReminderUiText.stageTrackerBasicSectionTitle,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
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
                    if (!selectedPackIsVisible)
                      DropdownMenuItem<int?>(
                        value: selectedPackId,
                        child: const Text(ReminderUiText.currentPackOption),
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
                const SizedBox(height: 8),
                const Divider(),
                const SizedBox(height: 6),
                Text(
                  ReminderUiText.stageTrackerAdvancedSectionTitle,
                  key: const Key('stage-tracker-advanced-section-title'),
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                ListTile(
                  key: const Key('stage-tracker-start-date-tile'),
                  contentPadding: EdgeInsets.zero,
                  title: const Text(ReminderUiText.trackingStartDateFieldLabel),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(ReminderFormatters.date(_startDate)),
                      const SizedBox(height: 2),
                      Text(
                        ReminderUiText.trackingStartDateEditHelp,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
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
                ListTile(
                  key: const Key('stage-tracker-end-date-tile'),
                  contentPadding: EdgeInsets.zero,
                  title: const Text(ReminderUiText.trackingEndDateFieldLabel),
                  subtitle: Text(
                    _endDate == null
                        ? ReminderUiText.continuingTrackingLabel
                        : ReminderFormatters.date(_endDate!),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_endDate != null)
                        IconButton(
                          key: const Key('stage-tracker-clear-end-date'),
                          tooltip: ReminderUiText.clearTrackingEndDateAction,
                          onPressed: () => setState(() => _endDate = null),
                          icon: const Icon(Icons.clear),
                        ),
                      const Icon(Icons.calendar_month_outlined),
                    ],
                  ),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _endDate ?? _startDate,
                      firstDate: DateTime(1900),
                      lastDate: DateTime(2100),
                    );
                    if (picked != null) {
                      setState(() => _endDate = picked);
                    }
                  },
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
        trackingEndDate: _endDate,
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
    _invalidateStageTrackerActionProviders(ref, trackerId);
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
    _invalidateStageTrackerActionProviders(ref, trackerId);
    if (context.mounted) {
      Navigator.of(context).pop();
    }
  }
}

Future<void> _showEditStageRuleDialog(
  BuildContext context,
  WidgetRef ref,
  StageRule rule,
) async {
  await showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text(ReminderUiText.editStageRule),
      content: SizedBox(
        width: 420,
        child: _StageRuleForm(
          initialRule: rule,
          submitLabel: ReminderUiText.saveAction,
          onSubmit: (input) async {
            final updated = await ref
                .read(stageTrackerRepositoryProvider)
                .updateStageRule(rule.id, input);
            _invalidateStageTrackerActionProviders(ref, rule.stageTrackerId);
            if (!dialogContext.mounted) {
              return;
            }
            if (updated) {
              Navigator.of(dialogContext).pop();
            } else {
              _showStageTrackerSaveFailed(dialogContext);
            }
          },
        ),
      ),
    ),
  );
}

class _StageRuleForm extends StatefulWidget {
  const _StageRuleForm({
    required this.onSubmit,
    this.initialRule,
    this.submitLabel = ReminderUiText.addRecurringStage,
  });

  final Future<void> Function(StageRuleInput input) onSubmit;
  final StageRule? initialRule;
  final String submitLabel;

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
  void initState() {
    super.initState();
    final rule = widget.initialRule;
    if (rule == null) {
      return;
    }
    _intervalController.text = rule.intervalValue.toString();
    _unit = rule.intervalUnit;
    _labelController.text = rule.labelTemplate ?? '';
    _reminderController.text = rule.reminderOffsetDays?.toString() ?? '';
  }

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
            submitLabel: widget.submitLabel,
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
  const _ImportantStageForm({
    required this.onSubmit,
    this.initialOccurrence,
    this.submitLabel = ReminderUiText.addImportantStage,
  });

  final Future<void> Function(ManualStageInput input) onSubmit;
  final StageOccurrence? initialOccurrence;
  final String submitLabel;

  @override
  State<_ImportantStageForm> createState() => _ImportantStageFormState();
}

Future<void> _showEditImportantStageDialog(
  BuildContext context,
  WidgetRef ref,
  StageOccurrence occurrence,
) async {
  final stageRecordId = occurrence.stageRecordId;
  if (stageRecordId == null) {
    return;
  }
  await showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text(ReminderUiText.editImportantStage),
      content: SizedBox(
        width: 420,
        child: _ImportantStageForm(
          initialOccurrence: occurrence,
          submitLabel: ReminderUiText.saveAction,
          onSubmit: (input) async {
            final updated = await ref
                .read(stageTrackerRepositoryProvider)
                .updateImportantStage(stageRecordId, input);
            _invalidateStageTrackerActionProviders(
              ref,
              occurrence.stageTrackerId,
            );
            if (!dialogContext.mounted) {
              return;
            }
            if (updated) {
              Navigator.of(dialogContext).pop();
            } else {
              _showStageTrackerSaveFailed(dialogContext);
            }
          },
        ),
      ),
    ),
  );
}

class _ImportantStageFormState extends State<_ImportantStageForm> {
  final _titleController = TextEditingController();
  final _noteController = TextEditingController();
  final _reminderController = TextEditingController();
  DateTime _date = DateTime.now();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final occurrence = widget.initialOccurrence;
    if (occurrence == null) {
      return;
    }
    _titleController.text = occurrence.label;
    _noteController.text = occurrence.note ?? '';
    _reminderController.text = occurrence.reminderOffsetDays.toString();
    _date = occurrence.occurrenceDate;
  }

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
            submitLabel: widget.submitLabel,
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
