import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/reminder_theme.dart';
import '../../data/item_repository.dart';
import '../../data/local/reminder_dao.dart';
import '../../data/resource_repository.dart';
import '../../domain/attention_policy.dart';
import '../../domain/item.dart';
import '../../domain/item_pack.dart';
import '../../domain/resource.dart';
import '../../presentation/formatters/reminder_formatters.dart';
import '../../presentation/text/reminder_ui_text.dart';
import '../../providers/item_providers.dart';
import '../../providers/resource_providers.dart';
import '../../providers/settings_providers.dart';
import '../widgets/editor_common_fields.dart';
import '../widgets/item_config_form_section.dart';
import '../widgets/pack_picker.dart';
import '../widgets/resource_binding_draft_section.dart';
import '../widgets/reminder_components.dart';

enum ItemEditMode { create, edit }

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
    final reminderTone = ref.watch(reminderToneProvider);
    _configController.reminderTone = reminderTone;

    if (itemAsync.isLoading ||
        activePacksAsync.isLoading ||
        resourcesAsync.isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text(_pageTitle)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final bundle = itemAsync.valueOrNull;
    final activePacks = activePacksAsync.valueOrNull ?? const <ItemPack>[];
    final resources = resourcesAsync.valueOrNull ?? const <ResourceBundle>[];
    _initializeIfNeeded(bundle);
    final packOptions = _packOptions(activePacks, bundle?.pack);
    final draftPackId = _resolvedPackId(activePacks);

    return PopScope<Object?>(
      canPop: !_shouldConfirmDiscard,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) {
          return;
        }
        await _discardAndPopIfConfirmed();
      },
      child: Scaffold(
        appBar: AppBar(title: Text(_pageTitle)),
        body: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(ReminderSpacing.page),
            children: [
              EditorTitleField(controller: _titleController),
              const SizedBox(height: 12),
              EditorNoteField(controller: _descriptionController),
              if (_isEdit) ...[
                const SizedBox(height: 12),
                InputDecorator(
                  decoration: const InputDecoration(
                    labelText: ReminderUiText.packFieldLabel,
                  ),
                  child: Text(
                    _readOnlyPackLabel(bundle?.pack),
                    key: const Key('pack-readonly'),
                  ),
                ),
              ] else if (!_isPackLocked) ...[
                const SizedBox(height: 12),
                DropdownButtonFormField<int?>(
                  key: const Key('pack-field'),
                  initialValue: _selectedPackId,
                  decoration: const InputDecoration(
                    labelText: ReminderUiText.packFieldLabel,
                  ),
                  items: packOptions
                      .map(
                        (option) => DropdownMenuItem<int?>(
                          value: option.id,
                          enabled: option.enabled,
                          child: Text(option.label),
                        ),
                      )
                      .toList(growable: false),
                  onChanged: (value) {
                    setState(() {
                      _selectedPackId = value;
                    });
                  },
                ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    key: const Key('create-item-add-pack-button'),
                    onPressed: _createPackInline,
                    icon: const Icon(Icons.add),
                    label: const Text(ReminderUiText.addItemPack),
                  ),
                ),
              ],
              const SizedBox(height: 12),
              if (_isEdit)
                InputDecorator(
                  decoration: const InputDecoration(
                    labelText: ReminderUiText.itemTypeFieldLabel,
                  ),
                  child: Text(
                    ReminderFormatters.itemType(_configController.type),
                    key: const Key('item-type-readonly'),
                  ),
                )
              else
                DropdownButtonFormField<ItemType>(
                  key: const Key('item-type-field'),
                  initialValue: _configController.type,
                  decoration: const InputDecoration(
                    labelText: ReminderUiText.itemTypeFieldLabel,
                  ),
                  items: ItemType.values
                      .map(
                        (value) => DropdownMenuItem(
                          value: value,
                          child: Text(ReminderFormatters.itemType(value)),
                        ),
                      )
                      .toList(growable: false),
                  onChanged: (value) {
                    if (value == null) {
                      return;
                    }
                    setState(() {
                      _configController.type = value;
                    });
                  },
                ),
              const SizedBox(height: 12),
              ItemConfigFormSection(
                controller: _configController,
                onChanged: () => setState(() {}),
                showAttentionFields: false,
              ),
              if (!_isEdit) ...[
                const SizedBox(height: 12),
                ResourceBindingDraftSection(
                  drafts: _resourceBindingDrafts,
                  resources: resources,
                  packId: draftPackId,
                  onChanged: (drafts) {
                    setState(() {
                      _resourceBindingDrafts = drafts;
                    });
                  },
                ),
              ],
              if (_isEdit) ...[
                const SizedBox(height: 12),
                AttentionPolicyAdvancedSection(
                  controller: _configController,
                  onChanged: () => setState(() {}),
                ),
                if (bundle != null) ...[
                  const SizedBox(height: 12),
                  _ResourceConsumptionSection(itemId: widget.id!),
                ],
              ],
              const SizedBox(height: 24),
              if (_isEdit)
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        key: const Key('cancel-button'),
                        onPressed: _cancel,
                        child: Text(
                          MaterialLocalizations.of(context).cancelButtonLabel,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        key: const Key('save-button'),
                        onPressed: _save,
                        child: const Text(ReminderUiText.saveAction),
                      ),
                    ),
                  ],
                )
              else
                FilledButton(
                  key: const Key('save-button'),
                  onPressed: _save,
                  child: const Text(ReminderUiText.saveAction),
                ),
            ],
          ),
        ),
      ),
    );
  }

  String get _pageTitle => switch (widget.mode) {
    ItemEditMode.create => ReminderUiText.addItem,
    ItemEditMode.edit => ReminderUiText.editItem,
  };

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
          _isEdit && _configController.customizeAttentionPolicy
          ? AttentionPolicySource.userCustomized
          : AttentionPolicySource.systemDefault,
      packId: widget.lockedPackId ?? _selectedPackId,
    );

    try {
      final saved = _isEdit
          ? await repository.updateItem(widget.id!, input)
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

  Future<void> _cancel() async {
    if (_shouldConfirmDiscard) {
      await _discardAndPopIfConfirmed();
      return;
    }
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  List<_PackOption> _packOptions(
    List<ItemPack> activePacks,
    ItemPack? currentPack,
  ) {
    final options = <_PackOption>[
      const _PackOption(id: null, label: ReminderUiText.unassignedPackOption),
      ...activePacks.map(
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
      _configController.type.name,
      _configController.scheduleType.name,
      _configController.fixedRepeatRuleV2?.encode(),
      _configController.overduePolicy.name,
      _configController.customizeAttentionPolicy,
      _configController.selectedFixedAnchorDate.toIso8601String(),
      _configController.selectedFixedDueDate.toIso8601String(),
      _configController.selectedStateAnchorDate.toIso8601String(),
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

class _ResourceConsumptionSection extends ConsumerWidget {
  const _ResourceConsumptionSection({required this.itemId});

  final int itemId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rulesAsync = ref.watch(itemConsumptionRulesProvider(itemId));
    final resourcesAsync = ref.watch(resourcesProvider);
    return ReminderPaperCard(
      key: const Key('resource-consumption-section'),
      child: Padding(
        padding: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // const Expanded(child: Text('消耗資源')),
                TextButton.icon(
                  key: const Key('add-resource-rule-button'),
                  onPressed: () => _showAddResourceRuleDialog(context, ref),
                  icon: const Icon(Icons.add),
                  label: const Text('綁定資源'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            rulesAsync.when(
              data: (rules) => resourcesAsync.when(
                data: (resources) {
                  final enabledRules = rules
                      .where((rule) => rule.isEnabled)
                      .toList(growable: false);
                  if (enabledRules.isEmpty) {
                    return const Text('尚未綁定會消耗的資源。');
                  }
                  return Column(
                    children: [
                      for (final rule in enabledRules)
                        _ResourceRuleTile(
                          rule: rule,
                          resource: _findResource(resources, rule.resourceId),
                        ),
                    ],
                  );
                },
                error: (error, stack) => Text('讀取資源失敗: $error'),
                loading: () => const Text('正在讀取資源...'),
              ),
              error: (error, stack) => Text('讀取綁定失敗: $error'),
              loading: () => const Text('正在讀取綁定...'),
            ),
          ],
        ),
      ),
    );
  }

  Resource? _findResource(List<ResourceBundle> bundles, int resourceId) {
    for (final bundle in bundles) {
      if (bundle.resource.id == resourceId) {
        return bundle.resource;
      }
    }
    return null;
  }

  Future<void> _showAddResourceRuleDialog(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final resources = await ref.read(resourcesProvider.future);
    final quantityResources = resources
        .map((bundle) => bundle.resource)
        .where((resource) => resource.config is QuantityBasedResourceConfig)
        .toList(growable: false);
    if (!context.mounted) {
      return;
    }
    if (quantityResources.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('目前沒有可綁定的數量資源。')));
      return;
    }
    final input = await showDialog<_ResourceRuleDraft>(
      context: context,
      builder: (dialogContext) =>
          _ResourceRuleDialog(resources: quantityResources),
    );
    if (input == null) {
      return;
    }
    await ref
        .read(resourceRepositoryProvider)
        .createConsumptionRule(
          ResourceConsumptionRuleInput(
            resourceId: input.resourceId,
            itemId: itemId,
            consumeAmount: input.consumeAmount,
          ),
        );
  }
}

class _ResourceRuleTile extends ConsumerWidget {
  const _ResourceRuleTile({required this.rule, required this.resource});

  final ResourceConsumptionRule rule;
  final Resource? resource;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = resource?.config;
    final unit = config is QuantityBasedResourceConfig ? config.unitLabel : '';
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(resource?.title ?? '已不存在的資源'),
      subtitle: Text('每次完成此 item 扣 ${rule.consumeAmount} $unit'),
      trailing: IconButton(
        key: Key('remove-resource-rule-${rule.id}'),
        onPressed: () async {
          await ref
              .read(resourceRepositoryProvider)
              .disableConsumptionRule(rule.id);
        },
        tooltip: '移除綁定',
        icon: const Icon(Icons.close),
      ),
    );
  }
}

class _ResourceRuleDraft {
  const _ResourceRuleDraft({
    required this.resourceId,
    required this.consumeAmount,
  });

  final int resourceId;
  final int consumeAmount;
}

class _ResourceRuleDialog extends StatefulWidget {
  const _ResourceRuleDialog({required this.resources});

  final List<Resource> resources;

  @override
  State<_ResourceRuleDialog> createState() => _ResourceRuleDialogState();
}

class _ResourceRuleDialogState extends State<_ResourceRuleDialog> {
  late int _resourceId;
  late final TextEditingController _amountController;

  @override
  void initState() {
    super.initState();
    _resourceId = widget.resources.first.id;
    _amountController = TextEditingController(text: '1');
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('綁定資源'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DropdownButtonFormField<int>(
            key: const Key('resource-rule-resource-field'),
            initialValue: _resourceId,
            decoration: const InputDecoration(labelText: '資源'),
            items: widget.resources
                .map(
                  (resource) => DropdownMenuItem<int>(
                    value: resource.id,
                    child: Text(resource.title),
                  ),
                )
                .toList(growable: false),
            onChanged: (value) {
              if (value == null) {
                return;
              }
              setState(() {
                _resourceId = value;
              });
            },
          ),
          const SizedBox(height: 12),
          TextFormField(
            key: const Key('resource-rule-amount-field'),
            controller: _amountController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: '每次完成扣多少'),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
        ),
        FilledButton(
          key: const Key('resource-rule-save-button'),
          onPressed: () {
            final amount = int.tryParse(_amountController.text.trim()) ?? 1;
            Navigator.of(context).pop(
              _ResourceRuleDraft(
                resourceId: _resourceId,
                consumeAmount: amount < 1 ? 1 : amount,
              ),
            );
          },
          child: const Text(ReminderUiText.saveAction),
        ),
      ],
    );
  }
}
