import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/item_repository.dart';
import '../../data/local/item_timeline_dao.dart';
import '../../domain/item.dart';
import '../../domain/item_pack.dart';
import '../../presentation/formatters/reminder_formatters.dart';
import '../../presentation/text/reminder_ui_text.dart';
import '../../providers/item_providers.dart';
import '../widgets/editor_common_fields.dart';

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
  late final TextEditingController _fixedAnchorDateController;
  late final TextEditingController _fixedDueDateController;
  late final TextEditingController _fixedExpectedBeforeController;
  late final TextEditingController _fixedWarningBeforeController;
  late final TextEditingController _fixedDangerBeforeController;
  late final TextEditingController _stateExpectedAfterController;
  late final TextEditingController _warningAfterController;
  late final TextEditingController _dangerAfterController;
  late final TextEditingController _resourceAnchorDateController;
  late final TextEditingController _resourceDurationController;
  late final TextEditingController _resourceExpectedBeforeController;
  late final TextEditingController _resourceWarningBeforeController;
  late final TextEditingController _resourceDangerBeforeController;

  ItemType _type = ItemType.stateBased;
  FixedScheduleType _scheduleType = FixedScheduleType.daily;
  ItemOverduePolicy _overduePolicy = ItemOverduePolicy.autoAdvance;
  DateTime _selectedFixedAnchorDate = DateTime.now();
  DateTime _selectedFixedDueDate = DateTime.now();
  DateTime _selectedResourceAnchorDate = DateTime.now();
  int? _selectedPackId;
  bool _initialized = false;

  bool get _isEdit => widget.mode == ItemEditMode.edit;
  bool get _isPackLocked => widget.lockedPackId != null;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _descriptionController = TextEditingController();
    _fixedAnchorDateController = TextEditingController();
    _fixedDueDateController = TextEditingController();
    _fixedExpectedBeforeController = TextEditingController(text: '3');
    _fixedWarningBeforeController = TextEditingController(text: '1');
    _fixedDangerBeforeController = TextEditingController(text: '0');
    _stateExpectedAfterController = TextEditingController(text: '7');
    _warningAfterController = TextEditingController(text: '7');
    _dangerAfterController = TextEditingController(text: '14');
    _resourceAnchorDateController = TextEditingController();
    _resourceDurationController = TextEditingController(text: '30');
    _resourceExpectedBeforeController = TextEditingController(text: '7');
    _resourceWarningBeforeController = TextEditingController(text: '3');
    _resourceDangerBeforeController = TextEditingController(text: '0');
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _fixedAnchorDateController.dispose();
    _fixedDueDateController.dispose();
    _fixedExpectedBeforeController.dispose();
    _fixedWarningBeforeController.dispose();
    _fixedDangerBeforeController.dispose();
    _stateExpectedAfterController.dispose();
    _warningAfterController.dispose();
    _dangerAfterController.dispose();
    _resourceAnchorDateController.dispose();
    _resourceDurationController.dispose();
    _resourceExpectedBeforeController.dispose();
    _resourceWarningBeforeController.dispose();
    _resourceDangerBeforeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final itemAsync = _isEdit && widget.id != null
        ? ref.watch(itemProvider(widget.id!))
        : const AsyncData<ItemBundle?>(null);
    final activePacksAsync = ref.watch(activeItemPacksProvider);

    if (itemAsync.isLoading || activePacksAsync.isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text(_pageTitle)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final bundle = itemAsync.valueOrNull;
    final activePacks = activePacksAsync.valueOrNull ?? const <ItemPack>[];
    _initializeIfNeeded(bundle);
    final packOptions = _packOptions(activePacks, bundle?.pack);

    return Scaffold(
      appBar: AppBar(title: Text(_pageTitle)),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            EditorTitleField(controller: _titleController),
            const SizedBox(height: 12),
            EditorNoteField(controller: _descriptionController),
            if (!_isPackLocked) ...[
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
            ],
            const SizedBox(height: 12),
            DropdownButtonFormField<ItemType>(
              initialValue: _type,
              decoration: const InputDecoration(labelText: 'Item Type'),
              items: ItemType.values
                  .map(
                    (value) => DropdownMenuItem(
                      value: value,
                      child: Text(value.name),
                    ),
                  )
                  .toList(growable: false),
              onChanged: (value) {
                if (value == null) {
                  return;
                }
                setState(() {
                  _type = value;
                });
              },
            ),
            const SizedBox(height: 12),
            ...switch (_type) {
              ItemType.fixed => _buildFixedFields(context),
              ItemType.stateBased => _buildStateBasedFields(),
              ItemType.resourceBased => _buildResourceBasedFields(context),
            },
            const SizedBox(height: 24),
            FilledButton(
              key: const Key('save-button'),
              onPressed: _save,
              child: const Text(ReminderUiText.saveAction),
            ),
          ],
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
    _syncDateControllers();
    if (bundle != null) {
      final item = bundle.item;
      _titleController.text = item.title;
      _descriptionController.text = item.description ?? '';
      _selectedPackId = widget.lockedPackId ?? item.packId;
      _type = item.type;
      switch (item.config) {
        case FixedItemConfig config:
          _scheduleType = config.scheduleType;
          _overduePolicy = config.overduePolicy;
          _selectedFixedAnchorDate =
              config.anchorDate ?? _selectedFixedAnchorDate;
          _selectedFixedDueDate = config.dueDate ?? _selectedFixedDueDate;
          _fixedExpectedBeforeController.text =
              '${config.expectedBefore.inDays}';
          _fixedWarningBeforeController.text =
              '${config.warningBefore.inDays}';
          _fixedDangerBeforeController.text =
              '${config.dangerBefore.inDays}';
        case StateBasedItemConfig config:
          _stateExpectedAfterController.text =
              '${config.expectedAfter.inDays}';
          _warningAfterController.text = '${config.warningAfter.inDays}';
          _dangerAfterController.text = '${config.dangerAfter.inDays}';
        case ResourceBasedItemConfig config:
          _selectedResourceAnchorDate =
              config.anchorDate ?? _selectedResourceAnchorDate;
          _resourceDurationController.text = '${config.durationDays}';
          _resourceExpectedBeforeController.text =
              '${config.expectedBefore}';
          _resourceWarningBeforeController.text =
              '${config.warningBefore}';
          _resourceDangerBeforeController.text =
              '${config.dangerBefore}';
      }
      _syncDateControllers();
    }
    _initialized = true;
  }

  List<Widget> _buildFixedFields(BuildContext context) {
    return [
      DropdownButtonFormField<FixedScheduleType>(
        initialValue: _scheduleType,
        decoration: const InputDecoration(labelText: 'Schedule Type'),
        items: FixedScheduleType.values
            .map(
              (value) => DropdownMenuItem(
                value: value,
                child: Text(value.name),
              ),
            )
            .toList(growable: false),
        onChanged: (value) {
          if (value == null) {
            return;
          }
          setState(() {
            _scheduleType = value;
          });
        },
      ),
      const SizedBox(height: 12),
      DropdownButtonFormField<ItemOverduePolicy>(
        initialValue: _overduePolicy,
        decoration: const InputDecoration(labelText: 'Overdue Policy'),
        items: ItemOverduePolicy.values
            .map(
              (value) => DropdownMenuItem(
                value: value,
                child: Text(value.name),
              ),
            )
            .toList(growable: false),
        onChanged: (value) {
          if (value == null) {
            return;
          }
          setState(() {
            _overduePolicy = value;
          });
        },
      ),
      const SizedBox(height: 12),
      EditorDateField(
        controller: _fixedAnchorDateController,
        label: 'Anchor Date',
        onPickDate: () => _pickDate(
          context,
          initialDate: _selectedFixedAnchorDate,
          onSelected: (value) {
            _selectedFixedAnchorDate = value;
            _syncDateControllers();
          },
        ),
      ),
      const SizedBox(height: 12),
      EditorDateField(
        controller: _fixedDueDateController,
        label: 'Due Date',
        onPickDate: () => _pickDate(
          context,
          initialDate: _selectedFixedDueDate,
          onSelected: (value) {
            _selectedFixedDueDate = value;
            _syncDateControllers();
          },
        ),
      ),
      const SizedBox(height: 12),
      _DaysField(
        key: const Key('fixed-expected-before-field'),
        controller: _fixedExpectedBeforeController,
        label: 'Expected Before (days)',
      ),
      const SizedBox(height: 12),
      _DaysField(
        key: const Key('fixed-warning-before-field'),
        controller: _fixedWarningBeforeController,
        label: 'Warning Before (days)',
      ),
      const SizedBox(height: 12),
      _DaysField(
        key: const Key('fixed-danger-before-field'),
        controller: _fixedDangerBeforeController,
        label: 'Danger Before (days)',
      ),
    ];
  }

  List<Widget> _buildStateBasedFields() {
    return [
      _DaysField(
        key: const Key('expected-interval-field'),
        controller: _stateExpectedAfterController,
        label: 'Expected After (days)',
      ),
      const SizedBox(height: 12),
      _DaysField(
        key: const Key('warning-after-field'),
        controller: _warningAfterController,
        label: 'Warning After (days)',
      ),
      const SizedBox(height: 12),
      _DaysField(
        key: const Key('danger-after-field'),
        controller: _dangerAfterController,
        label: 'Danger After (days)',
      ),
    ];
  }

  List<Widget> _buildResourceBasedFields(BuildContext context) {
    return [
      EditorDateField(
        controller: _resourceAnchorDateController,
        label: 'Resource Anchor Date',
        onPickDate: () => _pickDate(
          context,
          initialDate: _selectedResourceAnchorDate,
          onSelected: (value) {
            _selectedResourceAnchorDate = value;
            _syncDateControllers();
          },
        ),
      ),
      const SizedBox(height: 12),
      _DaysField(
        key: const Key('estimated-duration-field'),
        controller: _resourceDurationController,
        label: 'Duration Days',
      ),
      const SizedBox(height: 12),
      _DaysField(
        key: const Key('resource-expected-before-field'),
        controller: _resourceExpectedBeforeController,
        label: 'Expected Before (days)',
      ),
      const SizedBox(height: 12),
      _DaysField(
        key: const Key('warning-before-depletion-field'),
        controller: _resourceWarningBeforeController,
        label: 'Warning Before (days)',
      ),
      const SizedBox(height: 12),
      _DaysField(
        key: const Key('resource-danger-before-field'),
        controller: _resourceDangerBeforeController,
        label: 'Danger Before (days)',
      ),
    ];
  }

  Future<void> _pickDate(
    BuildContext context, {
    required DateTime initialDate,
    required ValueChanged<DateTime> onSelected,
  }) async {
    final result = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (result == null) {
      return;
    }
    setState(() {
      onSelected(DateTime(result.year, result.month, result.day));
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final repository = ref.read(itemRepositoryProvider);
    final input = ItemInput(
      title: _titleController.text.trim(),
      description: _normalizeOptionalText(_descriptionController.text),
      type: _type,
      config: _buildConfig(),
      packId: widget.lockedPackId ?? _selectedPackId,
    );

    try {
      final saved = _isEdit
          ? await repository.updateItem(widget.id!, input)
          : (await repository.createItem(input), true).$2;
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
      Navigator.of(context).pop();
    }
  }

  ItemConfig _buildConfig() {
    return switch (_type) {
      ItemType.fixed => FixedItemConfig(
        scheduleType: _scheduleType,
        anchorDate: _selectedFixedAnchorDate,
        dueDate: _selectedFixedDueDate,
        overduePolicy: _overduePolicy,
        expectedBefore: Duration(days: _parseDays(_fixedExpectedBeforeController)),
        warningBefore: Duration(days: _parseDays(_fixedWarningBeforeController)),
        dangerBefore: Duration(days: _parseDays(_fixedDangerBeforeController)),
      ),
      ItemType.stateBased => StateBasedItemConfig(
        expectedAfter: Duration(
          days: _parseDays(_stateExpectedAfterController),
        ),
        warningAfter: Duration(days: _parseDays(_warningAfterController)),
        dangerAfter: Duration(days: _parseDays(_dangerAfterController)),
      ),
      ItemType.resourceBased => ResourceBasedItemConfig(
        anchorDate: _selectedResourceAnchorDate,
        durationDays: _parseDays(_resourceDurationController),
        expectedBefore: _parseDays(_resourceExpectedBeforeController),
        warningBefore: _parseDays(_resourceWarningBeforeController),
        dangerBefore: _parseDays(_resourceDangerBeforeController),
      ),
    };
  }

  int _parseDays(TextEditingController controller) {
    return int.tryParse(controller.text.trim()) ?? 1;
  }

  void _syncDateControllers() {
    _fixedAnchorDateController.text = ReminderFormatters.date(
      _selectedFixedAnchorDate,
    );
    _fixedDueDateController.text = ReminderFormatters.date(_selectedFixedDueDate);
    _resourceAnchorDateController.text = ReminderFormatters.date(
      _selectedResourceAnchorDate,
    );
  }

  List<_PackOption> _packOptions(
    List<ItemPack> activePacks,
    ItemPack? currentPack,
  ) {
    final options = <_PackOption>[
      const _PackOption(id: null, label: ReminderUiText.unassignedPackOption),
      ...activePacks.map(
        (pack) => _PackOption(id: pack.id, label: _packLabel(pack)),
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

  String _packLabel(ItemPack pack) {
    if (!pack.isSystemDefault) {
      return pack.title;
    }
    return '${pack.title} (${ReminderUiText.systemDefaultPackLabel})';
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

class _DaysField extends StatelessWidget {
  const _DaysField({
    super.key,
    required this.controller,
    required this.label,
  });

  final TextEditingController controller;
  final String label;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(labelText: label),
      validator: (value) {
        final parsed = int.tryParse((value ?? '').trim());
        if (parsed == null || parsed < 0) {
          return '請輸入 0 或以上整數';
        }
        return null;
      },
    );
  }
}
