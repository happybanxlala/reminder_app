import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/reminder_theme.dart';
import '../../data/local/reminder_dao.dart';
import '../../data/resource_repository.dart';
import '../../domain/item_pack.dart';
import '../../domain/resource.dart';
import '../../presentation/formatters/reminder_formatters.dart';
import '../../presentation/text/reminder_ui_text.dart';
import '../../providers/developer_settings_providers.dart';
import '../../providers/item_providers.dart';
import '../../providers/resource_providers.dart';
import '../widgets/editor_common_fields.dart';
import '../widgets/editor_form_components.dart';
import '../widgets/pack_picker.dart';

class ResourceEditPage extends ConsumerStatefulWidget {
  const ResourceEditPage({super.key, required this.resourceId});

  static const routeName = 'resource-edit';
  static const routePath = '/resource/:id/edit';

  final int resourceId;

  @override
  ConsumerState<ResourceEditPage> createState() => _ResourceEditPageState();
}

class _ResourceEditPageState extends ConsumerState<ResourceEditPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _unitController = TextEditingController();
  final _warningController = TextEditingController();
  final _dangerController = TextEditingController();

  int? _selectedPackId;
  DateTime? _selectedAnchorDate;
  bool _initialized = false;
  bool _discardingChanges = false;
  String? _cleanFingerprint;

  bool get _shouldConfirmDiscard =>
      _initialized &&
      !_discardingChanges &&
      _cleanFingerprint != null &&
      _cleanFingerprint != _formFingerprint();

  @override
  void initState() {
    super.initState();
    _addDirtyListeners();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _unitController.dispose();
    _warningController.dispose();
    _dangerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final resourceAsync = ref.watch(resourceProvider(widget.resourceId));
    final activePacksAsync = ref.watch(activeItemPacksProvider);
    final bindingsAsync = ref.watch(
      resourceBindingsProvider(widget.resourceId),
    );
    final previewDate = ref.watch(effectivePreviewDateProvider);

    if (resourceAsync.isLoading ||
        activePacksAsync.isLoading ||
        bindingsAsync.isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text(ReminderUiText.editResourceTitle)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final bundle = resourceAsync.valueOrNull;
    if (bundle == null) {
      return Scaffold(
        appBar: AppBar(title: const Text(ReminderUiText.editResourceTitle)),
        body: const Center(
          child: Text(ReminderUiText.resourceSaveFailedMessage),
        ),
      );
    }

    final activePacks = activePacksAsync.valueOrNull ?? const <ItemPack>[];
    final bindings = bindingsAsync.valueOrNull ?? const <ResourceBinding>[];
    _initializeIfNeeded(bundle);
    final packOptions = _packOptions(activePacks, bundle.pack);

    return PopScope<Object?>(
      canPop: !_shouldConfirmDiscard,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) {
          return;
        }
        await _discardAndPopIfConfirmed();
      },
      child: ReminderEditorScaffold(
        title: ReminderUiText.editResourceTitle,
        bottomBar: ReminderEditorBottomBar(onSave: () => _save(bundle)),
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
              _buildBasicSection(activePacks, bundle, packOptions, bindings),
              const SizedBox(height: 12),
              _buildTypeSection(bundle.resource),
              const SizedBox(height: 12),
              _buildCurrentStatusSection(bundle.resource, previewDate),
              const SizedBox(height: 12),
              _buildThresholdSection(bundle.resource),
              const SizedBox(height: 12),
              _buildAdvancedSection(bundle.resource),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBasicSection(
    List<ItemPack> activePacks,
    ResourceBundle bundle,
    List<_ResourcePackOption> packOptions,
    List<ResourceBinding> bindings,
  ) {
    final packLocked = bindings.isNotEmpty;
    return ReminderEditorSection(
      key: const Key('resource-editor-section-basic-info'),
      title: ReminderUiText.basicInfoSectionTitle,
      children: [
        EditorTitleField(
          controller: _titleController,
          fieldKey: const Key('resource-title-field'),
          labelText: ReminderUiText.resourceNameFieldLabel,
          hintText: ReminderUiText.resourceNameFieldHint,
          requiredErrorText: ReminderUiText.resourceNameFieldRequiredError,
        ),
        EditorNoteField(
          controller: _descriptionController,
          fieldKey: const Key('resource-note-field'),
        ),
        ReminderEditorPickerRow(
          key: packLocked
              ? const Key('resource-pack-readonly-row')
              : const Key('resource-pack-picker-row'),
          label: ReminderUiText.packFieldLabel,
          value: _selectedPackLabel(activePacks, bundle.pack),
          readOnly: packLocked,
          showChevron: !packLocked,
          onTap: packLocked ? null : () => _showPackPicker(packOptions),
        ),
        if (packLocked)
          const _EditorHelperText(
            text: ReminderUiText.resourcePackLockedByBindingsHint,
          ),
      ],
    );
  }

  Widget _buildTypeSection(Resource resource) {
    return ReminderEditorSection(
      key: const Key('resource-editor-section-type'),
      title: ReminderUiText.resourceTypeSectionTitle,
      children: [
        ReminderEditorPickerRow(
          key: const Key('resource-type-readonly-row'),
          label: ReminderUiText.resourceTypeSectionTitle,
          value: _resourceTypeLabel(resource.type),
          readOnly: true,
          showChevron: false,
        ),
      ],
    );
  }

  Widget _buildCurrentStatusSection(Resource resource, DateTime previewDate) {
    final config = resource.config;
    final value = switch (config) {
      QuantityBasedResourceConfig quantity =>
        '${quantity.currentQuantity} ${quantity.unitLabel}',
      TimeBasedResourceConfig _ =>
        ReminderFormatters.resourceCompactRemainingSummary(
          resource,
          now: previewDate,
        ),
      _ => '',
    };
    final label = config is QuantityBasedResourceConfig
        ? ReminderUiText.currentQuantityLabel
        : '剩餘天數';
    final helper = config is QuantityBasedResourceConfig
        ? ReminderUiText.adjustQuantityHint
        : ReminderUiText.refillDaysHint;
    return ReminderEditorSection(
      key: const Key('resource-editor-section-current-status'),
      title: ReminderUiText.resourceStatusSectionTitle,
      children: [
        ReminderEditorPickerRow(
          key: const Key('resource-current-status-readonly-row'),
          label: label,
          value: value,
          readOnly: true,
          showChevron: false,
        ),
        _EditorHelperText(text: helper),
      ],
    );
  }

  Widget _buildThresholdSection(Resource resource) {
    final config = resource.config;
    final unit = config is QuantityBasedResourceConfig ? config.unitLabel : '天';
    return ReminderEditorSection(
      key: const Key('resource-editor-section-thresholds'),
      title: ReminderUiText.resourceThresholdSectionTitle,
      children: [
        ReminderEditorNumberField(
          fieldKey: config is QuantityBasedResourceConfig
              ? const Key('resource-warning-quantity-field')
              : const Key('resource-warning-days-field'),
          controller: _warningController,
          label: config is QuantityBasedResourceConfig
              ? ReminderUiText.warningQuantityLabel
              : ReminderUiText.warningDaysLabel,
          suffixText: config is QuantityBasedResourceConfig
              ? unit
              : ReminderUiText.dayUnit,
        ),
        ReminderEditorNumberField(
          fieldKey: config is QuantityBasedResourceConfig
              ? const Key('resource-danger-quantity-field')
              : const Key('resource-danger-days-field'),
          controller: _dangerController,
          label: config is QuantityBasedResourceConfig
              ? ReminderUiText.dangerQuantityLabel
              : ReminderUiText.dangerDaysLabel,
          suffixText: config is QuantityBasedResourceConfig
              ? unit
              : ReminderUiText.dayUnit,
        ),
        if (config is QuantityBasedResourceConfig)
          TextFormField(
            key: const Key('resource-unit-field'),
            controller: _unitController,
            decoration: const InputDecoration(
              labelText: ReminderUiText.resourceUnitLabel,
            ),
          ),
      ],
    );
  }

  Widget _buildAdvancedSection(Resource resource) {
    final config = resource.config;
    return ReminderEditorAdvancedSection(
      key: const Key('resource-editor-section-advanced'),
      title: ReminderUiText.advancedSettingsSectionTitle,
      toggleKey: const Key('resource-editor-toggle-advanced'),
      children: [
        if (config is TimeBasedResourceConfig) ...[
          ReminderEditorDateRow(
            key: const Key('resource-anchor-date-row'),
            label: ReminderUiText.startCountingDateLabel,
            date: _selectedAnchorDate ?? _today(),
            onTap: _pickAnchorDate,
          ),
          const _EditorHelperText(
            text: ReminderUiText.resourceAnchorDateEditHelp,
          ),
        ] else
          const _EditorHelperText(text: '目前沒有其他進階設定。'),
      ],
    );
  }

  void _initializeIfNeeded(ResourceBundle bundle) {
    if (_initialized) {
      return;
    }
    final resource = bundle.resource;
    _titleController.text = resource.title;
    _descriptionController.text = resource.description ?? '';
    _selectedPackId = resource.packId;
    switch (resource.config) {
      case QuantityBasedResourceConfig config:
        _unitController.text = config.unitLabel;
        _warningController.text = '${config.warningThreshold}';
        _dangerController.text = '${config.dangerThreshold}';
      case TimeBasedResourceConfig config:
        _selectedAnchorDate = _normalizeDate(config.anchorDate ?? _today());
        _warningController.text = '${config.warningBeforeDays}';
        _dangerController.text = '${config.dangerBeforeDays}';
      default:
        break;
    }
    _initialized = true;
    _cleanFingerprint = _formFingerprint();
  }

  Future<void> _save(ResourceBundle bundle) async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    final resource = bundle.resource;
    final config = resource.config;
    final updatedConfig = switch (config) {
      QuantityBasedResourceConfig quantity => QuantityBasedResourceConfig(
        currentQuantity: quantity.currentQuantity,
        unitLabel: _unitController.text.trim().isEmpty
            ? '個'
            : _unitController.text.trim(),
        infoThreshold: quantity.infoThreshold,
        warningThreshold: _nonNegativeInt(_warningController),
        dangerThreshold: _nonNegativeInt(_dangerController),
      ),
      TimeBasedResourceConfig time => TimeBasedResourceConfig(
        anchorDate: _selectedAnchorDate ?? time.anchorDate,
        durationDays: time.durationDays,
        infoBeforeDays: time.infoBeforeDays,
        warningBeforeDays: _nonNegativeInt(_warningController),
        dangerBeforeDays: _nonNegativeInt(_dangerController),
      ),
      _ => config,
    };
    final input = ResourceInput(
      title: _titleController.text.trim(),
      description: _normalizeOptionalText(_descriptionController.text),
      type: resource.type,
      config: updatedConfig,
      packId: _selectedPackId ?? resource.packId,
    );
    final saved = await ref
        .read(resourceRepositoryProvider)
        .updateResource(resource.id, input);
    if (!saved) {
      _showSaveError(ReminderUiText.resourceSaveFailedMessage);
      return;
    }
    if (mounted) {
      _markClean();
      await _popWithoutPrompt();
    }
  }

  List<_ResourcePackOption> _packOptions(
    List<ItemPack> activePacks,
    ItemPack currentPack,
  ) {
    final options = <_ResourcePackOption>[
      ...activePacks.map(
        (pack) =>
            _ResourcePackOption(id: pack.id, label: packDisplayLabel(pack)),
      ),
    ];
    if (currentPack.status == ItemPackStatus.archived &&
        activePacks.every((pack) => pack.id != currentPack.id)) {
      options.add(
        _ResourcePackOption(
          id: currentPack.id,
          label:
              '${packDisplayLabel(currentPack)} (${ReminderUiText.archivedPackSuffix})',
          enabled: false,
        ),
      );
    }
    return options;
  }

  Future<void> _showPackPicker(List<_ResourcePackOption> packOptions) async {
    final selection = await showModalBottomSheet<_ResourcePackPickerSelection>(
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
                key: Key('resource-pack-option-${option.id ?? 'none'}'),
                enabled: option.enabled,
                title: Text(option.label),
                trailing: _selectedPackId == option.id
                    ? const Icon(Icons.check)
                    : null,
                onTap: option.enabled
                    ? () => Navigator.of(
                        sheetContext,
                      ).pop(_ResourcePackPickerSelection(id: option.id))
                    : null,
              ),
            const Divider(),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                key: const Key('resource-add-pack-button'),
                onPressed: () => Navigator.of(
                  sheetContext,
                ).pop(const _ResourcePackPickerSelection.createPack()),
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
      _selectedPackId = selection.id;
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
      _selectedPackId = packId;
    });
  }

  Future<void> _pickAnchorDate() async {
    final current = _selectedAnchorDate ?? _today();
    final picked = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked == null || !mounted) {
      return;
    }
    setState(() {
      _selectedAnchorDate = _normalizeDate(picked);
    });
  }

  String _selectedPackLabel(List<ItemPack> activePacks, ItemPack currentPack) {
    final selectedPackId = _selectedPackId;
    if (selectedPackId == null) {
      return ReminderUiText.selectPackPlaceholder;
    }
    for (final pack in [...activePacks, currentPack]) {
      if (pack.id == selectedPackId) {
        if (pack.status == ItemPackStatus.archived) {
          return '${packDisplayLabel(pack)} (${ReminderUiText.archivedPackSuffix})';
        }
        return packDisplayLabel(pack);
      }
    }
    return ReminderUiText.selectPackPlaceholder;
  }

  int _nonNegativeInt(TextEditingController controller) {
    final parsed = int.tryParse(controller.text.trim());
    if (parsed == null || parsed < 0) {
      return 0;
    }
    return parsed;
  }

  String? _normalizeOptionalText(String value) {
    final normalized = value.trim();
    return normalized.isEmpty ? null : normalized;
  }

  DateTime _today() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  DateTime _normalizeDate(DateTime value) {
    return DateTime(value.year, value.month, value.day);
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
      _unitController,
      _warningController,
      _dangerController,
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
      _unitController.text,
      _warningController.text,
      _dangerController.text,
      _selectedAnchorDate?.toIso8601String(),
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

String _resourceTypeLabel(ResourceType type) {
  return switch (type) {
    ResourceType.quantityBased => ReminderUiText.quantityResourceTitle,
    ResourceType.timeBased => ReminderUiText.timeBasedResourceTitle,
  };
}

class _EditorHelperText extends StatelessWidget {
  const _EditorHelperText({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, right: 8),
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: context.reminderPalette.textSecondary,
        ),
      ),
    );
  }
}

class _ResourcePackOption {
  const _ResourcePackOption({
    required this.id,
    required this.label,
    this.enabled = true,
  });

  final int? id;
  final String label;
  final bool enabled;
}

class _ResourcePackPickerSelection {
  const _ResourcePackPickerSelection({required this.id}) : createPack = false;

  const _ResourcePackPickerSelection.createPack()
    : id = null,
      createPack = true;

  final int? id;
  final bool createPack;
}
