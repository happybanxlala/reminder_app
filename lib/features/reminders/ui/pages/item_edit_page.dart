import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/reminder_theme.dart';
import '../../data/item_repository.dart';
import '../../data/local/reminder_dao.dart';
import '../../domain/attention_policy.dart';
import '../../domain/item.dart';
import '../../domain/item_pack.dart';
import '../../domain/resource.dart';
import '../../presentation/formatters/reminder_formatters.dart';
import '../../presentation/text/reminder_ui_text.dart';
import '../../providers/item_providers.dart';
import '../../providers/resource_providers.dart';
import '../../providers/settings_providers.dart';
import '../../providers/stage_tracker_providers.dart';
import '../widgets/editor_common_fields.dart';
import '../widgets/editor_form_components.dart';
import '../widgets/item_config_form_section.dart';
import '../widgets/pack_picker.dart';
import '../widgets/resource_binding_draft_section.dart';
import '../widgets/resource_consumption_section.dart';
import 'item_history_page.dart';

enum ItemEditMode { create, edit }

enum _ItemEditMenuAction { history }

class ItemEditPage extends ConsumerStatefulWidget {
  const ItemEditPage({
    super.key,
    required this.mode,
    this.id,
    this.lockedPackId,
  });

  static const createRouteName = 'item-new';
  static const createRoutePath = '/item/new';
  static const editRouteName = 'item-edit';
  static const editRoutePath = '/item/:id';

  final ItemEditMode mode;
  final int? id;
  final int? lockedPackId;

  @override
  ConsumerState<ItemEditPage> createState() => _ItemEditPageState();
}

class _ItemEditPageState extends ConsumerState<ItemEditPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final ItemConfigFormController _configController;

  int? _selectedPackId;
  List<ResourceBindingDraft> _resourceBindingDrafts = const [];
  bool _initialized = false;
  bool _discardingChanges = false;
  bool _moveLinkedResourcesOnPackChange = true;
  String? _cleanFingerprint;

  bool get _isEdit => widget.mode == ItemEditMode.edit;
  bool get _isPackLocked => widget.lockedPackId != null;
  bool get _shouldConfirmDiscard =>
      _isEdit &&
      _initialized &&
      !_discardingChanges &&
      _cleanFingerprint != null &&
      _cleanFingerprint != _formFingerprint();

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _descriptionController = TextEditingController();
    _configController = ItemConfigFormController();
    _addDirtyListeners();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _configController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final itemAsync = _isEdit && widget.id != null
        ? ref.watch(itemProvider(widget.id!))
        : const AsyncData<ItemBundle?>(null);
    final activePacksAsync = ref.watch(activeItemPacksProvider);
    final resourcesAsync = ref.watch(resourcesProvider);
    final consumptionRulesAsync = _isEdit && widget.id != null
        ? ref.watch(itemConsumptionRulesProvider(widget.id!))
        : const AsyncValue<List<ResourceConsumptionRule>>.data([]);
    final reminderTone = ref.watch(reminderToneProvider);
    _configController.reminderTone = reminderTone;

    if (itemAsync.isLoading ||
        activePacksAsync.isLoading ||
        resourcesAsync.isLoading ||
        consumptionRulesAsync.isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text(_pageTitle)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final bundle = itemAsync.valueOrNull;
    final activePacks = activePacksAsync.valueOrNull ?? const <ItemPack>[];
    final resources = resourcesAsync.valueOrNull ?? const <ResourceBundle>[];
    final consumptionRules =
        consumptionRulesAsync.valueOrNull ?? const <ResourceConsumptionRule>[];
    _initializeIfNeeded(bundle);
    final packOptions = _packOptions(activePacks, bundle?.pack);
    final draftPackId = _resolvedPackId(activePacks);
    final showResourceBinding = draftPackId != null;

    return PopScope<Object?>(
      canPop: !_shouldConfirmDiscard,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) {
          return;
        }
        await _discardAndPopIfConfirmed();
      },
      child: ReminderEditorScaffold(
        title: _pageTitle,
        actions: _isEdit ? [_buildHistoryMenuAction()] : null,
        bottomBar: ReminderEditorBottomBar(onSave: _save),
        body: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              ReminderSpacing.page,
              ReminderSpacing.page,
              ReminderSpacing.page,
              96,
            ),
            children: [
              _buildBasicSection(
                activePacks,
                bundle,
                packOptions,
                consumptionRules,
              ),
              const SizedBox(height: 12),
              _buildReminderModeSection(),
              const SizedBox(height: 12),
              ReminderEditorSection(
                key: const Key('editor-section-schedule-settings'),
                title: ReminderUiText.scheduleSettingsSectionTitle,
                children: [
                  ItemConfigFormSection(
                    controller: _configController,
                    onChanged: () => setState(() {}),
                    showAttentionFields: false,
                  ),
                ],
              ),
              if (showResourceBinding) ...[
                const SizedBox(height: 12),
                ReminderEditorSection(
                  key: const Key('editor-section-resource-binding'),
                  title: ReminderUiText.resourceBindingSectionTitle,
                  trailing: Text(
                    _resourceBindingSummary,
                    key: const Key('resource-binding-summary'),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  collapsible: true,
                  initiallyExpanded: false,
                  toggleKey: const Key(
                    'editor-section-toggle-resource-binding',
                  ),
                  children: [
                    ResourceBindingDraftSection(
                      drafts: _resourceBindingDrafts,
                      resources: resources,
                      packId: draftPackId,
                      embedded: true,
                      onChanged: (drafts) {
                        setState(() {
                          _resourceBindingDrafts = drafts;
                        });
                      },
                    ),
                  ],
                ),
              ],
              if (_isEdit) ...[
                const SizedBox(height: 12),
                ReminderEditorAdvancedSection(
                  key: const Key('attention-policy-advanced-section'),
                  title: ReminderUiText.advancedSettingsSectionTitle,
                  subtitle: ReminderUiText.attentionPolicyAdvancedTitle,
                  toggleKey: const Key(
                    'editor-section-toggle-advanced-settings',
                  ),
                  children: [
                    AttentionPolicyAdvancedSection(
                      controller: _configController,
                      onChanged: () => setState(() {}),
                      embedded: true,
                    ),
                  ],
                ),
                if (bundle != null) ...[
                  const SizedBox(height: 12),
                  ReminderEditorSection(
                    key: const Key('editor-section-resource-consumption'),
                    title: ReminderUiText.resourceBindingSectionTitle,
                    collapsible: true,
                    initiallyExpanded: false,
                    toggleKey: const Key(
                      'editor-section-toggle-resource-consumption',
                    ),
                    children: [ResourceConsumptionSection(itemId: widget.id!)],
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }

  String get _pageTitle => switch (widget.mode) {
    ItemEditMode.create => ReminderUiText.itemEditorCreateTitle,
    ItemEditMode.edit => ReminderUiText.itemEditorEditTitle,
  };

  String get _resourceBindingSummary => _resourceBindingDrafts.isEmpty
      ? ReminderUiText.resourceBindingEmptySummary
      : '${_resourceBindingDrafts.length} ${ReminderUiText.resourceBindingCountSuffix}';

  Widget _buildHistoryMenuAction() {
    return PopupMenuButton<_ItemEditMenuAction>(
      key: const Key('item-edit-overflow'),
      tooltip: ReminderUiText.itemActionMenuTitle,
      onSelected: (action) {
        switch (action) {
          case _ItemEditMenuAction.history:
            final id = widget.id;
            if (id == null) {
              return;
            }
            context.pushNamed(
              ItemHistoryPage.routeName,
              pathParameters: {'id': id.toString()},
            );
        }
      },
      itemBuilder: (context) => const [
        PopupMenuItem(
          key: Key('item-edit-menu-history'),
          value: _ItemEditMenuAction.history,
          child: Text(ReminderUiText.itemHistoryMenuLabel),
        ),
      ],
    );
  }

  Widget _buildBasicSection(
    List<ItemPack> activePacks,
    ItemBundle? bundle,
    List<_PackOption> packOptions,
    List<ResourceConsumptionRule> consumptionRules,
  ) {
    return ReminderEditorSection(
      key: const Key('editor-section-basic-info'),
      title: ReminderUiText.basicInfoSectionTitle,
      children: [
        EditorTitleField(controller: _titleController),
        EditorNoteField(controller: _descriptionController),
        _buildPackRow(activePacks, bundle, packOptions, consumptionRules),
      ],
    );
  }

  Widget _buildPackRow(
    List<ItemPack> activePacks,
    ItemBundle? bundle,
    List<_PackOption> packOptions,
    List<ResourceConsumptionRule> consumptionRules,
  ) {
    final readOnly = _isPackLocked;
    final value = readOnly
        ? _readOnlyPackLabel(_findPack(activePacks, widget.lockedPackId))
        : _selectedPackLabel(activePacks, currentPack: bundle?.pack);

    return KeyedSubtree(
      key: readOnly ? const Key('pack-readonly') : const Key('pack-picker-row'),
      child: ReminderEditorPickerRow(
        label: ReminderUiText.packFieldLabel,
        value: value,
        readOnly: readOnly,
        showChevron: !readOnly,
        onTap: readOnly
            ? null
            : () => _showPackPicker(
                packOptions,
                currentPackId: bundle?.item.packId,
                hasLinkedResources: consumptionRules.any(
                  (rule) => rule.isEnabled,
                ),
              ),
      ),
    );
  }

  Widget _buildReminderModeSection() {
    return ReminderEditorSection(
      key: const Key('editor-section-reminder-mode'),
      title: ReminderUiText.reminderModeSectionTitle,
      children: [
        if (_isEdit)
          KeyedSubtree(
            key: const Key('item-type-readonly'),
            child: ReminderEditorPickerRow(
              label: ReminderUiText.itemTypeFieldLabel,
              value: ReminderFormatters.itemType(_configController.type),
              readOnly: true,
              showChevron: false,
            ),
          )
        else ...[
          ReminderEditorSelectableCard(
            key: const Key('item-type-fixed-card'),
            selected: _configController.type == ItemType.fixed,
            title: ReminderUiText.fixedItemTypeTitle,
            description: ReminderUiText.fixedItemTypeDescription,
            icon: Icons.event_repeat_outlined,
            onTap: () => _setItemType(ItemType.fixed),
          ),
          ReminderEditorSelectableCard(
            key: const Key('item-type-state-based-card'),
            selected: _configController.type == ItemType.stateBased,
            title: ReminderUiText.stateBasedItemTypeTitle,
            description: ReminderUiText.stateBasedItemTypeDescription,
            icon: Icons.trending_up_outlined,
            onTap: () => _setItemType(ItemType.stateBased),
          ),
        ],
      ],
    );
  }

  void _setItemType(ItemType value) {
    if (_configController.type == value) {
      return;
    }
    setState(() {
      _configController.type = value;
    });
  }

  void _initializeIfNeeded(ItemBundle? bundle) {
    if (_initialized) {
      return;
    }
    _selectedPackId = widget.lockedPackId;
    if (bundle != null) {
      final item = bundle.item;
      _titleController.text = item.title;
      _descriptionController.text = item.description ?? '';
      _selectedPackId = widget.lockedPackId ?? item.packId;
      _configController.load(item.config);
      _configController.customizeAttentionPolicy =
          item.attentionPolicySource == AttentionPolicySource.userCustomized;
    }
    _initialized = true;
    _cleanFingerprint = _formFingerprint();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final repository = ref.read(itemRepositoryProvider);
    final input = ItemInput(
      title: _titleController.text.trim(),
      description: _normalizeOptionalText(_descriptionController.text),
      type: _configController.type,
      config: _isEdit
          ? _configController.buildConfigForCurrentPolicySource()
          : _configController.buildConfigForCreate(),
      attentionPolicySource:
          _configController.type != ItemType.fixed &&
              _isEdit &&
              _configController.customizeAttentionPolicy
          ? AttentionPolicySource.userCustomized
          : AttentionPolicySource.systemDefault,
      packId: widget.lockedPackId ?? _selectedPackId,
    );

    try {
      final saved = _isEdit
          ? await repository.updateItem(
              widget.id!,
              input,
              resourceBindings: _resourceBindingDrafts
                  .map((draft) => draft.toInput())
                  .toList(growable: false),
              moveLinkedResourcesOnPackChange: _moveLinkedResourcesOnPackChange,
            )
          : (
              await repository.createItem(
                input,
                resourceBindings: _resourceBindingDrafts
                    .map((draft) => draft.toInput())
                    .toList(growable: false),
              ),
              true,
            ).$2;
      if (!saved) {
        _showSaveError(ReminderUiText.itemSaveFailedMessage);
        return;
      }
    } on StateError catch (error) {
      _showSaveError(_saveErrorMessage(error));
      return;
    } catch (_) {
      _showSaveError(ReminderUiText.saveFailedPrefix);
      return;
    }

    if (mounted) {
      _markClean();
      await _popWithoutPrompt();
    }
  }

  List<_PackOption> _packOptions(
    List<ItemPack> activePacks,
    ItemPack? currentPack,
  ) {
    final options = <_PackOption>[
      if (!_isEdit) _PackOption(id: null, label: packCreateUndecidedLabel()),
      ...activePacks
          .where((pack) => _isEdit || !pack.isSystemDefault)
          .map(
            (pack) => _PackOption(id: pack.id, label: packDisplayLabel(pack)),
          ),
    ];

    final pack = currentPack;
    if (pack != null &&
        pack.status == ItemPackStatus.archived &&
        activePacks.every((item) => item.id != pack.id)) {
      options.add(
        _PackOption(
          id: pack.id,
          label: '${_packLabel(pack)} (${ReminderUiText.archivedPackSuffix})',
          enabled: false,
        ),
      );
    }

    return options;
  }

  Future<void> _showPackPicker(
    List<_PackOption> packOptions, {
    int? currentPackId,
    bool hasLinkedResources = false,
  }) async {
    final selection = await showModalBottomSheet<_PackPickerSelection>(
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
            for (final option in packOptions)
              ListTile(
                key: Key('pack-option-${option.id ?? 'none'}'),
                enabled: option.enabled,
                title: Text(option.label),
                trailing: _selectedPackId == option.id
                    ? const Icon(Icons.check)
                    : null,
                onTap: option.enabled
                    ? () => Navigator.of(
                        sheetContext,
                      ).pop(_PackPickerSelection(id: option.id))
                    : null,
              ),
            const Divider(),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                key: const Key('create-item-add-pack-button'),
                onPressed: () => Navigator.of(
                  sheetContext,
                ).pop(const _PackPickerSelection.createPack()),
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
    if (_isEdit && selection.id != currentPackId) {
      final confirmed = await _confirmMoveItem(
        hasLinkedResources: hasLinkedResources,
      );
      if (confirmed != true || !mounted) {
        return;
      }
    }
    setState(() {
      _selectedPackId = selection.id;
    });
  }

  Future<bool?> _confirmMoveItem({required bool hasLinkedResources}) async {
    final itemId = widget.id;
    final hasStageRelated = itemId == null
        ? false
        : await ref
                  .read(stageTrackerRepositoryProvider)
                  .getRelatedItemSourceForItem(itemId) !=
              null;
    if (!mounted) {
      return false;
    }
    var moveResources = hasLinkedResources
        ? _moveLinkedResourcesOnPackChange
        : false;
    return showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text(ReminderUiText.moveItemTitle),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(ReminderUiText.moveItemMessage),
              if (hasLinkedResources)
                CheckboxListTile(
                  key: const Key('move-item-linked-resources-checkbox'),
                  contentPadding: EdgeInsets.zero,
                  value: moveResources,
                  title: const Text(ReminderUiText.moveLinkedResourcesLabel),
                  onChanged: (value) {
                    setDialogState(() {
                      moveResources = value ?? true;
                    });
                  },
                ),
              if (hasStageRelated)
                const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Text(ReminderUiText.moveUnlinksStageTrackerMessage),
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(
                MaterialLocalizations.of(dialogContext).cancelButtonLabel,
              ),
            ),
            FilledButton(
              key: const Key('move-item-confirm-button'),
              onPressed: () {
                _moveLinkedResourcesOnPackChange = moveResources;
                Navigator.of(dialogContext).pop(true);
              },
              child: const Text(ReminderUiText.confirmAction),
            ),
          ],
        ),
      ),
    );
  }

  String _readOnlyPackLabel(ItemPack? pack) {
    if (pack == null || pack.isSystemDefault) {
      return pack == null
          ? ReminderUiText.unassignedPackTitle
          : packDisplayLabel(pack);
    }
    if (pack.status == ItemPackStatus.archived) {
      return '${packDisplayLabel(pack)} (${ReminderUiText.archivedPackSuffix})';
    }
    return packDisplayLabel(pack);
  }

  String _packLabel(ItemPack pack) {
    return packDisplayLabel(pack);
  }

  String _selectedPackLabel(
    List<ItemPack> activePacks, {
    ItemPack? currentPack,
  }) {
    final selectedPackId = _selectedPackId;
    if (selectedPackId == null) {
      return packCreateUndecidedLabel();
    }
    final pack =
        _findPack(activePacks, selectedPackId) ??
        (currentPack?.id == selectedPackId ? currentPack : null);
    if (pack != null && pack.status == ItemPackStatus.archived) {
      return '${packDisplayLabel(pack)} (${ReminderUiText.archivedPackSuffix})';
    }
    return pack == null
        ? ReminderUiText.selectPackPlaceholder
        : packDisplayLabel(pack);
  }

  ItemPack? _findPack(List<ItemPack> packs, int? id) {
    if (id == null) {
      return null;
    }
    for (final pack in packs) {
      if (pack.id == id) {
        return pack;
      }
    }
    return null;
  }

  int? _resolvedPackId(List<ItemPack> activePacks) {
    if (widget.lockedPackId != null) {
      return widget.lockedPackId;
    }
    if (_selectedPackId != null) {
      return _selectedPackId;
    }
    for (final pack in activePacks) {
      if (pack.isSystemDefault) {
        return pack.id;
      }
    }
    return null;
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
      _selectedPackId = packId;
    });
  }

  String? _normalizeOptionalText(String value) {
    final normalized = value.trim();
    return normalized.isEmpty ? null : normalized;
  }

  String _saveErrorMessage(StateError error) {
    final message = error.message.toString().trim();
    if (message.isNotEmpty) {
      return message;
    }
    return ReminderUiText.saveFailedPrefix;
  }

  void _showSaveError(String message) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  void _addDirtyListeners() {
    for (final controller in [
      _titleController,
      _descriptionController,
      _configController.fixedAnchorDateController,
      _configController.fixedDueDateController,
      _configController.fixedLeadDaysController,
      _configController.fixedScheduleIntervalController,
      _configController.fixedMonthlyDayController,
      _configController.fixedWarningBeforeController,
      _configController.fixedDangerBeforeController,
      _configController.stateAnchorDateController,
      _configController.stateExpectedIntervalController,
      _configController.warningAfterController,
      _configController.dangerAfterController,
    ]) {
      controller.addListener(_notifyPotentialChange);
    }
  }

  void _notifyPotentialChange() {
    if (!_initialized || !mounted) {
      return;
    }
    setState(() {});
  }

  void _markClean() {
    _cleanFingerprint = _formFingerprint();
  }

  String _formFingerprint() {
    return [
      _titleController.text,
      _descriptionController.text,
      _selectedPackId,
      _moveLinkedResourcesOnPackChange,
      _configController.type.name,
      _configController.scheduleType.name,
      _configController.fixedRepeatRuleV2?.encode(),
      _configController.overduePolicy.name,
      _configController.fixedCompletionMode.name,
      _configController.customizeAttentionPolicy,
      _configController.selectedFixedAnchorDate.toIso8601String(),
      _configController.selectedFixedDueDate.toIso8601String(),
      _configController.selectedStateAnchorDate.toIso8601String(),
      _configController.fixedLeadDaysController.text,
      _configController.fixedScheduleIntervalController.text,
      _configController.fixedMonthlyDayController.text,
      _configController.fixedWarningBeforeController.text,
      _configController.fixedDangerBeforeController.text,
      _configController.stateExpectedIntervalController.text,
      _configController.warningAfterController.text,
      _configController.dangerAfterController.text,
      ..._resourceBindingDrafts.map(
        (draft) =>
            '${draft.resourceId}:${draft.newResource?.title}:${draft.consumeAmount}',
      ),
    ].join('\u001f');
  }

  Future<void> _discardAndPopIfConfirmed() async {
    final confirmed = await _showDiscardChangesDialog();
    if (confirmed != true || !mounted) {
      return;
    }
    await _popWithoutPrompt();
  }

  Future<void> _popWithoutPrompt() async {
    setState(() {
      _discardingChanges = true;
    });
    await Future<void>.delayed(Duration.zero);
    if (!mounted) {
      return;
    }
    Navigator.of(context).pop();
  }

  Future<bool?> _showDiscardChangesDialog() {
    return showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text(ReminderUiText.discardChangesTitle),
        content: const Text(ReminderUiText.discardChangesMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(
              MaterialLocalizations.of(dialogContext).cancelButtonLabel,
            ),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text(ReminderUiText.discardChangesAction),
          ),
        ],
      ),
    );
  }
}

class _PackOption {
  const _PackOption({
    required this.id,
    required this.label,
    this.enabled = true,
  });

  final int? id;
  final String label;
  final bool enabled;
}

class _PackPickerSelection {
  const _PackPickerSelection({required this.id}) : createPack = false;

  const _PackPickerSelection.createPack() : id = null, createPack = true;

  final int? id;
  final bool createPack;
}
