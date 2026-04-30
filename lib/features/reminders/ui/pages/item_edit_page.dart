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
import '../widgets/item_config_form_section.dart';

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
  bool _initialized = false;

  bool get _isEdit => widget.mode == ItemEditMode.edit;
  bool get _isPackLocked => widget.lockedPackId != null;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _descriptionController = TextEditingController();
    _configController = ItemConfigFormController();
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
            ),
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
    if (bundle != null) {
      final item = bundle.item;
      _titleController.text = item.title;
      _descriptionController.text = item.description ?? '';
      _selectedPackId = widget.lockedPackId ?? item.packId;
      _configController.load(item.config);
    }
    _initialized = true;
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
      config: _configController.buildConfig(),
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
