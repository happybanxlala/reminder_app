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

enum _StageRuleFrequencyPreset { weekly, monthly, yearly, custom }

Future<void> _showStageEntryDialog(
  BuildContext context,
  WidgetRef ref,
  int trackerId, {
  _StageEntryTab initialTab = _StageEntryTab.important,
}) async {
  final previewDate = ref.read(effectivePreviewDateProvider);
  final detail = await ref
      .read(stageTrackerDetailProvider(trackerId).future)
      .catchError((_) => null);
  final tracker =
      detail?.stageTracker ??
      await ref
          .read(stageTrackerByIdProvider(trackerId).future)
          .catchError((_) => null);
  if (!context.mounted) {
    return;
  }
  await showDialog<void>(
    context: context,
    builder: (dialogContext) => _StageEntryDialog(
      hostContext: context,
      trackerId: trackerId,
      ref: ref,
      tracker: tracker,
      previewDate: previewDate,
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
  late DateTime _startDate = _normalizeStageDate(DateTime.now());
  DateTime? _endDate;
  int? _packId;
  final List<ItemPack> _createdPacks = [];

  bool get _isEdit => widget.initialTracker != null;

  @override
  void initState() {
    super.initState();
    _titleController.addListener(_refreshPreview);
    _subjectController.addListener(_refreshPreview);
    final tracker = widget.initialTracker;
    if (tracker == null) {
      return;
    }
    _titleController.text = tracker.title;
    _subjectController.text = tracker.subjectName ?? '';
    _startDate = _normalizeStageDate(tracker.trackingStartDate);
    _endDate = tracker.trackingEndDate == null
        ? null
        : _normalizeStageDate(tracker.trackingEndDate!);
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
    final selectedPack = _selectedPack;
    final previewDate = ref.watch(effectivePreviewDateProvider);
    return AlertDialog(
      title: Text(
        _isEdit
            ? ReminderUiText.editStageTracker
            : ReminderUiText.addStageTracker,
      ),
      content: SizedBox(
        width: 480,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _StageTrackerPreviewCard(
                  key: const Key('stage-tracker-preview-card'),
                  title: _previewTitle,
                  subjectName: _previewSubject,
                  packLabel: _selectedPackLabel,
                  emoji: selectedPack?.iconEmoji ?? '🏷️',
                  startDate: _startDate,
                  endDate: _endDate,
                  previewDate: previewDate,
                ),
                const SizedBox(height: 12),
                ReminderEditorSection(
                  key: const Key('stage-tracker-section-basic-info'),
                  title: ReminderUiText.stageTrackerBasicSectionTitle,
                  children: [
                    EditorTitleField(
                      controller: _titleController,
                      fieldKey: const Key('stage-tracker-title-field'),
                      labelText: ReminderUiText.stageTrackerNameFieldLabel,
                      hintText: ReminderUiText.stageTrackerNameFieldHint,
                      requiredErrorText:
                          ReminderUiText.stageTrackerNameRequiredError,
                    ),
                    TextFormField(
                      key: const Key('stage-tracker-subject-field'),
                      controller: _subjectController,
                      decoration: const InputDecoration(
                        labelText: ReminderUiText.stageTrackerSubjectFieldLabel,
                        hintText: ReminderUiText.stageTrackerSubjectFieldHint,
                      ),
                    ),
                    ReminderEditorPickerRow(
                      key: const Key('stage-tracker-pack-picker-row'),
                      label: ReminderUiText.packFieldLabel,
                      value: _selectedPackLabel,
                      onTap: () => _showPackPicker(_packOptions()),
                    ),
                  ],
                ),
                if (!_isEdit) ...[
                  const SizedBox(height: 12),
                  ReminderEditorSection(
                    key: const Key('stage-tracker-section-tracking-settings'),
                    title: ReminderUiText.stageTrackerTrackingSettingsTitle,
                    children: [
                      ReminderEditorDateRow(
                        key: const Key('stage-tracker-start-date-row'),
                        label: ReminderUiText.trackingStartDateFieldLabel,
                        date: _startDate,
                        onTap: _pickStartDate,
                      ),
                      const _EditorHelperText(
                        ReminderUiText.stageTrackerStartDateHelp,
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 12),
                ReminderEditorAdvancedSection(
                  key: const Key('stage-tracker-section-advanced'),
                  title: ReminderUiText.stageTrackerAdvancedSectionTitle,
                  toggleKey: const Key('stage-tracker-advanced-toggle'),
                  children: [
                    if (_isEdit) ...[
                      ReminderEditorDateRow(
                        key: const Key('stage-tracker-start-date-row'),
                        label: ReminderUiText.trackingStartDateFieldLabel,
                        date: _startDate,
                        onTap: _pickStartDate,
                      ),
                      const _EditorHelperText(
                        ReminderUiText.stageTrackerAdvancedDateHelp,
                      ),
                    ],
                    _EndDateRow(
                      endDate: _endDate,
                      onPick: _pickEndDate,
                      onClear: _endDate == null
                          ? null
                          : () => setState(() => _endDate = null),
                    ),
                  ],
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
        subjectName: _normalizeOptionalText(_subjectController.text),
        trackingStartDate: _startDate,
        trackingEndDate: _endDate,
        packId: _packId,
      ),
    );
  }

  ItemPack? get _selectedPack {
    final selectedPackId = _packId;
    if (selectedPackId == null) {
      return null;
    }
    for (final pack in _availablePacks) {
      if (pack.id == selectedPackId) {
        return pack;
      }
    }
    return null;
  }

  String get _previewTitle {
    final title = _titleController.text.trim();
    return title.isEmpty
        ? ReminderUiText.stageTrackerPreviewFallbackTitle
        : title;
  }

  String? get _previewSubject =>
      _normalizeOptionalText(_subjectController.text);

  String get _selectedPackLabel {
    final selectedPackId = _packId;
    if (selectedPackId == null) {
      return ReminderUiText.selectPackPlaceholder;
    }
    final selectedPack = _selectedPack;
    if (selectedPack != null) {
      return packDisplayLabel(selectedPack);
    }
    return ReminderUiText.currentPackOption;
  }

  List<_StageTrackerPackOption> _packOptions() {
    final selectedPackId = _packId;
    final selectedPackIsVisible =
        selectedPackId == null ||
        _availablePacks.any((pack) => pack.id == selectedPackId);
    return [
      const _StageTrackerPackOption(
        id: null,
        label: ReminderUiText.unassignedPackTitle,
      ),
      if (!selectedPackIsVisible)
        _StageTrackerPackOption(
          id: selectedPackId,
          label: ReminderUiText.currentPackOption,
          enabled: false,
        ),
      ..._availablePacks.map(
        (pack) =>
            _StageTrackerPackOption(id: pack.id, label: packDisplayLabel(pack)),
      ),
    ];
  }

  Future<void> _showPackPicker(List<_StageTrackerPackOption> options) async {
    final selection =
        await showModalBottomSheet<_StageTrackerPackPickerSelection>(
          context: context,
          showDragHandle: true,
          builder: (sheetContext) => SafeArea(
            child: ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              children: [
                Text(
                  ReminderUiText.packFieldLabel,
                  style: Theme.of(sheetContext).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                for (final option in options)
                  ListTile(
                    key: Key(
                      'stage-tracker-pack-option-${option.id ?? 'none'}',
                    ),
                    enabled: option.enabled,
                    title: Text(option.label),
                    trailing: _packId == option.id
                        ? const Icon(Icons.check)
                        : null,
                    onTap: option.enabled
                        ? () => Navigator.of(
                            sheetContext,
                          ).pop(_StageTrackerPackPickerSelection(id: option.id))
                        : null,
                  ),
                const Divider(),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    key: const Key('stage-tracker-add-pack-button'),
                    onPressed: () => Navigator.of(
                      sheetContext,
                    ).pop(const _StageTrackerPackPickerSelection.createPack()),
                    icon: const Icon(Icons.add),
                    label: const Text(ReminderUiText.addItemPack),
                  ),
                ),
              ],
            ),
          ),
        );
    if (selection == null || !mounted) {
      return;
    }
    if (selection.createPack) {
      await _createPackInline();
      return;
    }
    setState(() {
      _packId = selection.id;
    });
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
      final now = DateTime.now();
      _createdPacks.add(
        ItemPack(
          id: packId,
          title: input.title,
          description: input.description,
          iconEmoji: input.iconEmoji,
          orderIndex: widget.packs.length + _createdPacks.length + 1,
          status: ItemPackStatus.active,
          isSystemDefault: false,
          createdAt: now,
          updatedAt: now,
        ),
      );
    });
  }

  Future<void> _pickStartDate() async {
    final picked = await _pickDate(initialDate: _startDate);
    if (picked == null || !mounted) {
      return;
    }
    setState(() => _startDate = picked);
  }

  Future<void> _pickEndDate() async {
    final picked = await _pickDate(initialDate: _endDate ?? _startDate);
    if (picked == null || !mounted) {
      return;
    }
    setState(() => _endDate = picked);
  }

  Future<DateTime?> _pickDate({required DateTime initialDate}) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
    );
    return picked == null ? null : _normalizeStageDate(picked);
  }

  void _refreshPreview() {
    if (mounted) {
      setState(() {});
    }
  }

  List<ItemPack> get _availablePacks => [...widget.packs, ..._createdPacks];
}

class _StageEntryDialog extends StatelessWidget {
  const _StageEntryDialog({
    required this.hostContext,
    required this.trackerId,
    required this.ref,
    required this.tracker,
    required this.previewDate,
    required this.initialTab,
  });

  final BuildContext hostContext;
  final int trackerId;
  final WidgetRef ref;
  final StageTracker? tracker;
  final DateTime previewDate;
  final _StageEntryTab initialTab;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      initialIndex: initialTab == _StageEntryTab.recurring ? 1 : 0,
      child: AlertDialog(
        title: const Text(ReminderUiText.addStageEntry),
        content: SizedBox(
          width: 480,
          height: 520,
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
                      previewDate: previewDate,
                      onSubmit: (input) =>
                          _createImportantStage(context, input),
                    ),
                    _StageRuleForm(
                      tracker: tracker,
                      previewDate: previewDate,
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
    final messenger = ScaffoldMessenger.maybeOf(hostContext);
    final relatedDialogContext = hostContext;
    final stageRecordId = await ref
        .read(stageTrackerRepositoryProvider)
        .createImportantStage(trackerId, input);
    _invalidateStageTrackerActionProviders(ref, trackerId);
    final occurrence = stageRecordId <= 0
        ? null
        : StageOccurrence(
            stageTrackerId: trackerId,
            stageTrackerTitle: tracker?.title,
            subjectName: tracker?.subjectName,
            stageRecordId: stageRecordId,
            sourceType: StageRecordSourceType.manual,
            occurrenceDate: _normalizeStageDate(input.occurrenceDate),
            label: input.label,
            note: input.note,
            reminderOffsetDays:
                input.reminderOffsetDays ??
                StageOccurrenceService.defaultReminderOffsetDays,
            recordStatus: StageRecordStatus.normal,
          );
    if (context.mounted) {
      Navigator.of(context).pop();
    }
    if (messenger == null) {
      return;
    }
    messenger.showSnackBar(
      SnackBar(
        content: const Text(ReminderUiText.importantStageCreatedMessage),
        action: occurrence == null
            ? null
            : SnackBarAction(
                label: ReminderUiText.addRelatedReminder,
                onPressed: () {
                  if (relatedDialogContext.mounted) {
                    _showRelatedItemDialog(
                      relatedDialogContext,
                      ref,
                      occurrence,
                    );
                  }
                },
              ),
      ),
    );
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
  final previewDate = ref.read(effectivePreviewDateProvider);
  final tracker = await ref
      .read(stageTrackerByIdProvider(rule.stageTrackerId).future)
      .catchError((_) => null);
  if (!context.mounted) {
    return;
  }
  await showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text(ReminderUiText.editStageRule),
      content: SizedBox(
        width: 480,
        child: _StageRuleForm(
          tracker: tracker,
          previewDate: previewDate,
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
    required this.previewDate,
    this.tracker,
    this.initialRule,
    this.submitLabel = ReminderUiText.addRecurringStage,
  });

  final Future<void> Function(StageRuleInput input) onSubmit;
  final DateTime previewDate;
  final StageTracker? tracker;
  final StageRule? initialRule;
  final String submitLabel;

  @override
  State<_StageRuleForm> createState() => _StageRuleFormState();
}

class _StageRuleFormState extends State<_StageRuleForm> {
  final _formKey = GlobalKey<FormState>();
  final _intervalController = TextEditingController(text: '1');
  final _labelController = TextEditingController();
  final _reminderController = TextEditingController();
  StageIntervalUnit _unit = StageIntervalUnit.months;
  _StageRuleFrequencyPreset _frequencyPreset =
      _StageRuleFrequencyPreset.monthly;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _intervalController.addListener(_refreshPreview);
    _labelController.addListener(_refreshPreview);
    final rule = widget.initialRule;
    if (rule != null) {
      _intervalController.text = rule.intervalValue.toString();
      _unit = rule.intervalUnit;
      _labelController.text = _friendlyStageRuleTemplate(rule.labelTemplate);
      _reminderController.text = rule.reminderOffsetDays?.toString() ?? '';
    }
    _frequencyPreset = _presetFor(_safeIntervalValue, _unit);
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
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ReminderEditorSection(
              key: const Key('stage-rule-section-rule'),
              title: ReminderUiText.stageRuleSettingsSectionTitle,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    ReminderUiText.stageRuleFrequencyLabel,
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                ),
                _StageRuleFrequencyChips(
                  selected: _frequencyPreset,
                  onSelected: _setFrequencyPreset,
                ),
                if (_frequencyPreset == _StageRuleFrequencyPreset.custom) ...[
                  ReminderEditorNumberField(
                    fieldKey: const Key('stage-rule-interval-field'),
                    controller: _intervalController,
                    label: ReminderUiText.stageRuleIntervalNumberLabel,
                    minimum: 1,
                  ),
                  ReminderEditorPickerRow(
                    key: const Key('stage-rule-unit-picker-row'),
                    label: ReminderUiText.stageRuleIntervalUnitLabel,
                    value: _stageIntervalUnitLabel(_unit),
                    onTap: _showUnitPicker,
                  ),
                ],
                ReminderEditorPickerRow(
                  key: const Key('stage-rule-preview-row'),
                  label: ReminderUiText.stageRulePreviewRuleLabel,
                  value: _rulePreviewText,
                  readOnly: true,
                  showChevron: false,
                ),
                ReminderEditorPickerRow(
                  key: const Key('stage-rule-next-preview-row'),
                  label: ReminderUiText.stageRuleNextPreviewLabel,
                  value: _nextStagePreviewText,
                  readOnly: true,
                  showChevron: false,
                ),
              ],
            ),
            const SizedBox(height: 12),
            ReminderEditorAdvancedSection(
              key: const Key('stage-rule-section-name-format'),
              title: ReminderUiText.stageRuleNameFormatSectionTitle,
              subtitle: ReminderUiText.stageRuleNameFormatHelp,
              toggleKey: const Key('stage-rule-name-format-toggle'),
              children: [
                TextFormField(
                  key: const Key('stage-rule-label-template-field'),
                  controller: _labelController,
                  decoration: const InputDecoration(
                    labelText: ReminderUiText.stageRuleNameFormatFieldLabel,
                    hintText: ReminderUiText.stageRuleNameFormatFieldHint,
                    helperText: ReminderUiText.stageRuleTokenHelp,
                  ),
                ),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    OutlinedButton.icon(
                      key: const Key('stage-rule-insert-value-token'),
                      onPressed: () =>
                          _insertToken(ReminderUiText.insertStageValueToken),
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text(ReminderUiText.insertStageValueToken),
                    ),
                    OutlinedButton.icon(
                      key: const Key('stage-rule-insert-unit-token'),
                      onPressed: () =>
                          _insertToken(ReminderUiText.insertStageUnitToken),
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text(ReminderUiText.insertStageUnitToken),
                    ),
                  ],
                ),
                ReminderEditorPickerRow(
                  key: const Key('stage-rule-template-preview-row'),
                  label: ReminderUiText.stageRulePreviewLabel,
                  value: _previewLabel,
                  readOnly: true,
                  showChevron: false,
                ),
              ],
            ),
            const SizedBox(height: 12),
            ReminderEditorAdvancedSection(
              key: const Key('stage-rule-section-reminder'),
              title: ReminderUiText.stageReminderSettingsSectionTitle,
              toggleKey: const Key('stage-rule-reminder-toggle'),
              children: [
                _OptionalIntegerField(
                  fieldKey: const Key('stage-rule-reminder-field'),
                  controller: _reminderController,
                  label: ReminderUiText.advanceReminderLabel,
                  minimum: 0,
                  summaryBuilder: _reminderOffsetSummary,
                ),
              ],
            ),
            const SizedBox(height: 12),
            _StageEntryFormActions(
              saving: _saving,
              submitLabel: widget.submitLabel,
              onSubmit: _submit,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (_saving) {
      return;
    }
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() => _saving = true);
    final interval = _safeIntervalValue;
    final type = _stageRuleTypeForUnit(_unit);
    try {
      await widget.onSubmit(
        StageRuleInput(
          type: type,
          intervalValue: interval,
          intervalUnit: _unit,
          labelTemplate: _stageRuleTemplateForSave(_labelController.text),
          reminderOffsetDays: int.tryParse(_reminderController.text.trim()),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  Future<void> _showUnitPicker() async {
    final selected = await showModalBottomSheet<StageIntervalUnit>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          children: [
            Text(
              ReminderUiText.stageRuleIntervalUnitLabel,
              style: Theme.of(sheetContext).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            for (final unit in StageIntervalUnit.values)
              ListTile(
                key: Key('stage-rule-unit-option-${unit.name}'),
                title: Text(_stageIntervalUnitLabel(unit)),
                trailing: unit == _unit ? const Icon(Icons.check) : null,
                onTap: () => Navigator.of(sheetContext).pop(unit),
              ),
          ],
        ),
      ),
    );
    if (selected == null || !mounted) {
      return;
    }
    setState(() {
      _unit = selected;
      _frequencyPreset = _StageRuleFrequencyPreset.custom;
    });
  }

  void _setFrequencyPreset(_StageRuleFrequencyPreset preset) {
    setState(() {
      _frequencyPreset = preset;
      switch (preset) {
        case _StageRuleFrequencyPreset.weekly:
          _intervalController.text = '1';
          _unit = StageIntervalUnit.weeks;
          break;
        case _StageRuleFrequencyPreset.monthly:
          _intervalController.text = '1';
          _unit = StageIntervalUnit.months;
          break;
        case _StageRuleFrequencyPreset.yearly:
          _intervalController.text = '1';
          _unit = StageIntervalUnit.years;
          break;
        case _StageRuleFrequencyPreset.custom:
          break;
      }
    });
  }

  void _insertToken(String token) {
    final text = _labelController.text;
    final selection = _labelController.selection;
    final start = selection.isValid ? selection.start : text.length;
    final end = selection.isValid ? selection.end : text.length;
    final nextText = text.replaceRange(start, end, token);
    final nextOffset = start + token.length;
    _labelController.value = TextEditingValue(
      text: nextText,
      selection: TextSelection.collapsed(offset: nextOffset),
    );
  }

  String get _previewLabel {
    return _stageOccurrenceService.formatLabel(_previewRule, 1);
  }

  String get _rulePreviewText {
    final interval = _safeIntervalValue;
    if (interval == 1) {
      return switch (_unit) {
        StageIntervalUnit.days => '每天',
        StageIntervalUnit.weeks => ReminderUiText.weeklyStageRuleShortcut,
        StageIntervalUnit.months => ReminderUiText.monthlyStageRuleShortcut,
        StageIntervalUnit.years => ReminderUiText.yearlyStageRuleShortcut,
      };
    }
    return '每 $interval ${_stageIntervalUnitLabel(_unit)}';
  }

  String get _nextStagePreviewText {
    final tracker = widget.tracker;
    if (tracker == null) {
      return ReminderUiText.stageRulePreviewUnavailable;
    }
    final rule = _previewRule;
    final date = _stageOccurrenceService.targetDateForOccurrence(
      tracker.trackingStartDate,
      rule,
      1,
    );
    return '${_stageOccurrenceService.formatLabel(rule, 1)}・${ReminderFormatters.date(date)}';
  }

  StageRule get _previewRule {
    final now = DateTime.fromMillisecondsSinceEpoch(0);
    return StageRule(
      id: widget.initialRule?.id ?? 0,
      stageTrackerId:
          widget.tracker?.id ?? widget.initialRule?.stageTrackerId ?? 0,
      type: _stageRuleTypeForUnit(_unit),
      intervalValue: _safeIntervalValue,
      intervalUnit: _unit,
      labelTemplate: _stageRuleTemplateForSave(_labelController.text),
      reminderOffsetDays: int.tryParse(_reminderController.text.trim()),
      status: StageRuleStatus.active,
      createdAt: now,
      updatedAt: now,
    );
  }

  int get _safeIntervalValue {
    final interval = int.tryParse(_intervalController.text.trim()) ?? 1;
    return interval <= 0 ? 1 : interval;
  }

  static const StageOccurrenceService _stageOccurrenceService =
      StageOccurrenceService();

  void _refreshPreview() {
    if (mounted) {
      setState(() {});
    }
  }
}

class _StageRuleFrequencyChips extends StatelessWidget {
  const _StageRuleFrequencyChips({
    required this.selected,
    required this.onSelected,
  });

  final _StageRuleFrequencyPreset selected;
  final ValueChanged<_StageRuleFrequencyPreset> onSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _chip(
          key: const Key('stage-rule-frequency-weekly'),
          label: ReminderUiText.weeklyStageRuleShortcut,
          preset: _StageRuleFrequencyPreset.weekly,
        ),
        _chip(
          key: const Key('stage-rule-frequency-monthly'),
          label: ReminderUiText.monthlyStageRuleShortcut,
          preset: _StageRuleFrequencyPreset.monthly,
        ),
        _chip(
          key: const Key('stage-rule-frequency-yearly'),
          label: ReminderUiText.yearlyStageRuleShortcut,
          preset: _StageRuleFrequencyPreset.yearly,
        ),
        _chip(
          key: const Key('stage-rule-frequency-custom'),
          label: ReminderUiText.customStageRuleShortcut,
          preset: _StageRuleFrequencyPreset.custom,
        ),
      ],
    );
  }

  Widget _chip({
    required Key key,
    required String label,
    required _StageRuleFrequencyPreset preset,
  }) {
    return ChoiceChip(
      key: key,
      label: Text(label),
      selected: selected == preset,
      onSelected: (_) => onSelected(preset),
    );
  }
}

class _ImportantStageForm extends StatefulWidget {
  const _ImportantStageForm({
    required this.onSubmit,
    required this.previewDate,
    this.initialOccurrence,
    this.submitLabel = ReminderUiText.addImportantStage,
  });

  final Future<void> Function(ManualStageInput input) onSubmit;
  final DateTime previewDate;
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
        width: 480,
        child: _ImportantStageForm(
          initialOccurrence: occurrence,
          previewDate: ref.read(effectivePreviewDateProvider),
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
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _noteController = TextEditingController();
  final _reminderController = TextEditingController();
  late DateTime _date = _normalizeStageDate(DateTime.now());
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
    _reminderController.text = occurrence.reminderOffsetDays == 0
        ? ''
        : occurrence.reminderOffsetDays.toString();
    _date = _normalizeStageDate(occurrence.occurrenceDate);
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
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ReminderEditorSection(
              key: const Key('important-stage-section-content'),
              title: ReminderUiText.importantStageContentSectionTitle,
              children: [
                TextFormField(
                  key: const Key('important-stage-title-field'),
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: ReminderUiText.importantStageNameFieldLabel,
                    hintText: ReminderUiText.importantStageNameFieldHint,
                  ),
                  validator: (value) => (value ?? '').trim().isEmpty
                      ? ReminderUiText.importantStageNameRequiredError
                      : null,
                ),
                ReminderEditorDateRow(
                  key: const Key('important-stage-date-row'),
                  label: ReminderUiText.stageDateFieldLabel,
                  date: _date,
                  onTap: _pickDate,
                ),
                if (_isPastStageDate)
                  const _EditorHelperText(
                    ReminderUiText.importantStagePastDateHint,
                  ),
                EditorNoteField(
                  controller: _noteController,
                  fieldKey: const Key('important-stage-note-field'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ReminderEditorAdvancedSection(
              key: const Key('important-stage-section-reminder'),
              title: ReminderUiText.stageReminderSettingsSectionTitle,
              toggleKey: const Key('important-stage-reminder-toggle'),
              children: [
                _OptionalIntegerField(
                  fieldKey: const Key('important-stage-reminder-field'),
                  controller: _reminderController,
                  label: ReminderUiText.advanceReminderLabel,
                  minimum: 0,
                  summaryBuilder: _reminderOffsetSummary,
                ),
              ],
            ),
            const SizedBox(height: 12),
            _StageEntryFormActions(
              saving: _saving,
              submitLabel: widget.submitLabel,
              onSubmit: _submit,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (_saving) {
      return;
    }
    if (!_formKey.currentState!.validate()) {
      return;
    }
    final title = _titleController.text.trim();
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

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
    );
    if (picked == null || !mounted) {
      return;
    }
    setState(() => _date = _normalizeStageDate(picked));
  }

  bool get _isPastStageDate => _normalizeStageDate(
    _date,
  ).isBefore(_normalizeStageDate(widget.previewDate));
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
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  final _descriptionController = TextEditingController();
  late DateTime _dueDate;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.occurrence.label);
    _dueDate = _normalizeStageDate(widget.occurrence.occurrenceDate);
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
      title: const Text(ReminderUiText.addRelatedReminder),
      content: SizedBox(
        width: 480,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: ReminderEditorSection(
              key: const Key('related-reminder-section-content'),
              title: ReminderUiText.relatedReminderContentSectionTitle,
              children: [
                TextFormField(
                  key: const Key('related-reminder-title-field'),
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: ReminderUiText.relatedReminderNameFieldLabel,
                  ),
                  validator: (value) => (value ?? '').trim().isEmpty
                      ? ReminderUiText.relatedReminderNameRequiredError
                      : null,
                ),
                EditorNoteField(
                  controller: _descriptionController,
                  fieldKey: const Key('related-reminder-note-field'),
                ),
                ReminderEditorDateRow(
                  key: const Key('related-reminder-due-date-row'),
                  label: ReminderUiText.relatedReminderDueDateFieldLabel,
                  date: _dueDate,
                  onTap: _pickDueDate,
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

  Future<void> _pickDueDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate,
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
    );
    if (picked == null || !mounted) {
      return;
    }
    setState(() => _dueDate = _normalizeStageDate(picked));
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    Navigator.of(context).pop(
      _RelatedItemInput(
        title: _titleController.text.trim(),
        description: _normalizeOptionalText(_descriptionController.text),
        dueDate: _dueDate,
      ),
    );
  }
}

class _StageTrackerPreviewCard extends StatelessWidget {
  const _StageTrackerPreviewCard({
    super.key,
    required this.title,
    required this.subjectName,
    required this.packLabel,
    required this.emoji,
    required this.startDate,
    required this.endDate,
    required this.previewDate,
  });

  final String title;
  final String? subjectName;
  final String packLabel;
  final String emoji;
  final DateTime startDate;
  final DateTime? endDate;
  final DateTime previewDate;

  @override
  Widget build(BuildContext context) {
    final palette = context.reminderPalette;
    return ReminderPaperCard(
      padding: const EdgeInsets.all(14),
      radius: 16,
      borderColor: palette.domainStage.withValues(alpha: 0.26),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: palette.statusNormalContainer,
              shape: BoxShape.circle,
              border: Border.all(color: palette.borderSubtle),
            ),
            child: Text(emoji, style: const TextStyle(fontSize: 22)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  key: const Key('stage-tracker-preview-title'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 2),
                Text(
                  ReminderFormatters.stageTrackerDayLabel(
                    StageTracker(
                      id: 0,
                      packId: 0,
                      title: title,
                      subjectName: subjectName,
                      trackingStartDate: startDate,
                      trackingEndDate: endDate,
                      status: StageTrackerStatus.active,
                      createdAt: previewDate,
                      updatedAt: previewDate,
                    ),
                    now: previewDate,
                  ),
                  key: const Key('stage-tracker-preview-days'),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: palette.textSecondary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subjectName == null ? packLabel : '追蹤對象：$subjectName',
                  key: const Key('stage-tracker-preview-subject'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: palette.textMuted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EndDateRow extends StatelessWidget {
  const _EndDateRow({
    required this.endDate,
    required this.onPick,
    required this.onClear,
  });

  final DateTime? endDate;
  final VoidCallback onPick;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ReminderEditorPickerRow(
            key: const Key('stage-tracker-end-date-row'),
            label: ReminderUiText.trackingEndDateFieldLabel,
            value: endDate == null
                ? ReminderUiText.continuingTrackingLabel
                : ReminderFormatters.date(endDate!),
            onTap: onPick,
            leading: Icon(
              Icons.calendar_today_outlined,
              size: 18,
              color: context.reminderPalette.primaryWarm,
            ),
          ),
        ),
        if (onClear != null)
          IconButton(
            key: const Key('stage-tracker-clear-end-date'),
            tooltip: ReminderUiText.clearTrackingEndDateAction,
            onPressed: onClear,
            icon: const Icon(Icons.clear),
          ),
      ],
    );
  }
}

class _EditorHelperText extends StatelessWidget {
  const _EditorHelperText(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: context.reminderPalette.textMuted,
        ),
      ),
    );
  }
}

class _OptionalIntegerField extends StatelessWidget {
  const _OptionalIntegerField({
    required this.fieldKey,
    required this.controller,
    required this.label,
    required this.minimum,
    this.summaryBuilder,
  });

  final Key fieldKey;
  final TextEditingController controller;
  final String label;
  final int minimum;
  final String Function(String value)? summaryBuilder;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (context, value, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextFormField(
              key: fieldKey,
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: label,
                hintText: ReminderUiText.noAdvanceReminderLabel,
              ),
              validator: (fieldValue) {
                final text = (fieldValue ?? '').trim();
                if (text.isEmpty) {
                  return null;
                }
                final parsed = int.tryParse(text);
                if (parsed == null || parsed < minimum) {
                  return minimum <= 0 ? '請輸入 0 或以上整數' : '請輸入 $minimum 或以上整數';
                }
                return null;
              },
            ),
            if (summaryBuilder != null) ...[
              const SizedBox(height: 6),
              _EditorHelperText(summaryBuilder!(value.text)),
            ],
          ],
        );
      },
    );
  }
}

class _StageTrackerPackOption {
  const _StageTrackerPackOption({
    required this.id,
    required this.label,
    this.enabled = true,
  });

  final int? id;
  final String label;
  final bool enabled;
}

class _StageTrackerPackPickerSelection {
  const _StageTrackerPackPickerSelection({required this.id})
    : createPack = false;

  const _StageTrackerPackPickerSelection.createPack()
    : id = null,
      createPack = true;

  final int? id;
  final bool createPack;
}

DateTime _normalizeStageDate(DateTime value) {
  return DateTime(value.year, value.month, value.day);
}

String? _normalizeOptionalText(String value) {
  final normalized = value.trim();
  return normalized.isEmpty ? null : normalized;
}

String _stageIntervalUnitLabel(StageIntervalUnit unit) {
  return switch (unit) {
    StageIntervalUnit.days => '天',
    StageIntervalUnit.weeks => '週',
    StageIntervalUnit.months => '個月',
    StageIntervalUnit.years => '年',
  };
}

StageRuleType _stageRuleTypeForUnit(StageIntervalUnit unit) {
  return switch (unit) {
    StageIntervalUnit.days => StageRuleType.everyNDays,
    StageIntervalUnit.weeks => StageRuleType.everyNWeeks,
    StageIntervalUnit.months => StageRuleType.everyNMonths,
    StageIntervalUnit.years => StageRuleType.everyNYears,
  };
}

_StageRuleFrequencyPreset _presetFor(int interval, StageIntervalUnit unit) {
  if (interval == 1 && unit == StageIntervalUnit.weeks) {
    return _StageRuleFrequencyPreset.weekly;
  }
  if (interval == 1 && unit == StageIntervalUnit.months) {
    return _StageRuleFrequencyPreset.monthly;
  }
  if (interval == 1 && unit == StageIntervalUnit.years) {
    return _StageRuleFrequencyPreset.yearly;
  }
  return _StageRuleFrequencyPreset.custom;
}

String _reminderOffsetSummary(String value) {
  final text = value.trim();
  if (text.isEmpty) {
    return ReminderUiText.noAdvanceReminderLabel;
  }
  final days = int.tryParse(text);
  if (days == null) {
    return ReminderUiText.noAdvanceReminderLabel;
  }
  if (days <= 0) {
    return ReminderUiText.sameDayReminderLabel;
  }
  if (days == 1) {
    return '提前 1 天';
  }
  return '提前 $days 天';
}

String _friendlyStageRuleTemplate(String? template) {
  final value = template?.trim() ?? '';
  if (value.isEmpty) {
    return '';
  }
  return value
      .replaceAll('{value}', ReminderUiText.insertStageValueToken)
      .replaceAll('{unit}', ReminderUiText.insertStageUnitToken);
}

String? _stageRuleTemplateForSave(String value) {
  final normalized = value.trim();
  if (normalized.isEmpty) {
    return null;
  }
  return normalized
      .replaceAll(ReminderUiText.insertStageValueToken, '{value}')
      .replaceAll(ReminderUiText.insertStageUnitToken, '{unit}');
}
