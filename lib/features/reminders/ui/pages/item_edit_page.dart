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
  const ItemEditPage({super.key, required this.mode, this.id});

  static const createRouteName = 'item-new';
  static const createRoutePath = '/item/new';
  static const editRouteName = 'item-edit';
  static const editRoutePath = '/item/:id';

  final ItemEditMode mode;
  final int? id;

  @override
  ConsumerState<ItemEditPage> createState() => _ItemEditPageState();
}

class _ItemEditPageState extends ConsumerState<ItemEditPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _anchorDateController;
  late final TextEditingController _expectedIntervalController;
  late final TextEditingController _warningAfterController;
  late final TextEditingController _dangerAfterController;
  late final TextEditingController _estimatedDurationController;
  late final TextEditingController _warningBeforeDepletionController;

  ItemType _type = ItemType.stateBased;
  FixedTimeScheduleType _scheduleType = FixedTimeScheduleType.daily;
  DateTime _selectedAnchorDate = DateTime.now();
  int? _selectedPackId;
  bool _initialized = false;

  bool get _isEdit => widget.mode == ItemEditMode.edit;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _descriptionController = TextEditingController();
    _anchorDateController = TextEditingController();
    _expectedIntervalController = TextEditingController(text: '7');
    _warningAfterController = TextEditingController(text: '7');
    _dangerAfterController = TextEditingController(text: '14');
    _estimatedDurationController = TextEditingController(text: '30');
    _warningBeforeDepletionController = TextEditingController(text: '7');
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _anchorDateController.dispose();
    _expectedIntervalController.dispose();
    _warningAfterController.dispose();
    _dangerAfterController.dispose();
    _estimatedDurationController.dispose();
    _warningBeforeDepletionController.dispose();
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
            const SizedBox(height: 12),
            DropdownButtonFormField<ItemType>(
              initialValue: _type,
              decoration: const InputDecoration(labelText: 'Item Type'),
              items: ItemType.values
                  .map(
                    (value) =>
                        DropdownMenuItem(value: value, child: Text(value.name)),
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
              ItemType.fixedTime => _buildFixedTimeFields(context),
              ItemType.stateBased => _buildStateBasedFields(context),
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
    if (bundle != null) {
      final item = bundle.item;
      _titleController.text = item.title;
      _descriptionController.text = item.description ?? '';
      _selectedPackId = item.packId;
      _type = item.type;
      switch (item.config) {
        case FixedTimeItemConfig config:
          _scheduleType = config.scheduleType;
          _selectedAnchorDate = config.anchorDate ?? _selectedAnchorDate;
          _anchorDateController.text = ReminderFormatters.date(
            _selectedAnchorDate,
          );
        case StateBasedItemConfig config:
          _expectedIntervalController.text =
              '${config.expectedInterval.inDays}';
          _warningAfterController.text = '${config.warningAfter.inDays}';
          _dangerAfterController.text = '${config.dangerAfter.inDays}';
        case ResourceBasedItemConfig config:
          _estimatedDurationController.text =
              '${config.estimatedDuration.inDays}';
          _warningBeforeDepletionController.text =
              '${config.warningBeforeDepletion.inDays}';
      }
    } else {
      _anchorDateController.text = ReminderFormatters.date(_selectedAnchorDate);
    }
    _initialized = true;
  }

  List<Widget> _buildFixedTimeFields(BuildContext context) {
    return [
      DropdownButtonFormField<FixedTimeScheduleType>(
        initialValue: _scheduleType,
        decoration: const InputDecoration(labelText: 'Schedule Type'),
        items: FixedTimeScheduleType.values
            .map(
              (value) =>
                  DropdownMenuItem(value: value, child: Text(value.name)),
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
      EditorDateField(
        controller: _anchorDateController,
        label: 'Anchor Date',
        onPickDate: () => _pickDate(context),
      ),
    ];
  }

  List<Widget> _buildStateBasedFields(BuildContext context) {
    return [
      _DaysField(
        key: const Key('expected-interval-field'),
        controller: _expectedIntervalController,
        label: 'Expected Interval (days)',
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
      _DaysField(
        key: const Key('estimated-duration-field'),
        controller: _estimatedDurationController,
        label: 'Estimated Duration (days)',
      ),
      const SizedBox(height: 12),
      _DaysField(
        key: const Key('warning-before-depletion-field'),
        controller: _warningBeforeDepletionController,
        label: 'Warning Before Depletion (days)',
      ),
    ];
  }

  Future<void> _pickDate(BuildContext context) async {
    final result = await showDatePicker(
      context: context,
      initialDate: _selectedAnchorDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (result == null) {
      return;
    }
    setState(() {
      _selectedAnchorDate = DateTime(result.year, result.month, result.day);
      _anchorDateController.text = ReminderFormatters.date(_selectedAnchorDate);
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
      packId: _selectedPackId,
    );

    if (_isEdit) {
      await repository.updateItem(widget.id!, input);
    } else {
      await repository.createItem(input);
    }

    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  ItemConfig _buildConfig() {
    return switch (_type) {
      ItemType.fixedTime => FixedTimeItemConfig(
        scheduleType: _scheduleType,
        anchorDate: _selectedAnchorDate,
      ),
      ItemType.stateBased => StateBasedItemConfig(
        expectedInterval: Duration(
          days: _parseDays(_expectedIntervalController),
        ),
        warningAfter: Duration(days: _parseDays(_warningAfterController)),
        dangerAfter: Duration(days: _parseDays(_dangerAfterController)),
      ),
      ItemType.resourceBased => ResourceBasedItemConfig(
        estimatedDuration: Duration(
          days: _parseDays(_estimatedDurationController),
        ),
        warningBeforeDepletion: Duration(
          days: _parseDays(_warningBeforeDepletionController),
        ),
      ),
    };
  }

  int _parseDays(TextEditingController controller) {
    return int.tryParse(controller.text.trim()) ?? 1;
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
  const _DaysField({super.key, required this.controller, required this.label});

  final TextEditingController controller;
  final String label;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(labelText: label),
      validator: (value) {
        final parsed = int.tryParse(value ?? '');
        if (parsed == null || parsed <= 0) {
          return '請輸入大於 0 的整數';
        }
        return null;
      },
    );
  }
}
