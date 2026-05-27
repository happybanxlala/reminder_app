import 'package:flutter/material.dart';

import '../../data/item_repository.dart';
import '../../data/local/reminder_dao.dart';
import '../../data/resource_repository.dart';
import '../../domain/resource.dart';
import '../../presentation/text/reminder_ui_text.dart';
import 'editor_form_components.dart';

class ResourceBindingDraft {
  const ResourceBindingDraft.existing({
    required this.resourceId,
    required this.resourceTitle,
    required this.unitLabel,
    this.consumeAmount = 1,
  }) : newResource = null;

  const ResourceBindingDraft.newResource({
    required ResourceInput resource,
    this.consumeAmount = 1,
  }) : resourceId = null,
       resourceTitle = null,
       unitLabel = null,
       newResource = resource;

  final int? resourceId;
  final String? resourceTitle;
  final String? unitLabel;
  final ResourceInput? newResource;
  final int consumeAmount;

  String get title => resourceTitle ?? newResource?.title ?? '新資源';

  String get unit {
    final existingUnit = unitLabel;
    if (existingUnit != null && existingUnit.trim().isNotEmpty) {
      return existingUnit;
    }
    final config = newResource?.config;
    if (config is QuantityBasedResourceConfig) {
      return config.unitLabel;
    }
    return '';
  }

  ItemResourceBindingInput toInput() {
    final existingId = resourceId;
    if (existingId != null) {
      return ItemResourceBindingInput.existing(
        resourceId: existingId,
        consumeAmount: consumeAmount,
      );
    }
    final resource = newResource;
    if (resource == null) {
      throw StateError('Resource draft is incomplete.');
    }
    return ItemResourceBindingInput.newResource(
      resource: resource,
      consumeAmount: consumeAmount,
    );
  }
}

class ResourceBindingDraftSection extends StatelessWidget {
  const ResourceBindingDraftSection({
    super.key,
    required this.drafts,
    required this.resources,
    required this.packId,
    required this.onChanged,
    this.embedded = false,
  });

  final List<ResourceBindingDraft> drafts;
  final List<ResourceBundle> resources;
  final int? packId;
  final ValueChanged<List<ResourceBindingDraft>> onChanged;
  final bool embedded;

  @override
  Widget build(BuildContext context) {
    final quantityResources = _availableResources();
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            key: const Key('add-resource-binding-draft-button'),
            onPressed: () => _addDraft(context, quantityResources),
            icon: const Icon(Icons.add),
            label: const Text(ReminderUiText.addResourceBindingLabel),
          ),
        ),
        const SizedBox(height: 8),
        if (drafts.isEmpty)
          const Text('建立後，完成這個事項時可以扣掉指定資源。')
        else
          ...drafts.asMap().entries.map(
            (entry) => _ResourceBindingDraftRow(
              key: Key('resource-binding-row-${entry.key}'),
              draft: entry.value,
              onRemove: () {
                final next = [...drafts]..removeAt(entry.key);
                onChanged(next);
              },
            ),
          ),
      ],
    );

    if (embedded) {
      return KeyedSubtree(
        key: const Key('resource-binding-draft-section'),
        child: content,
      );
    }

    return Card(
      key: const Key('resource-binding-draft-section'),
      margin: EdgeInsets.zero,
      child: Padding(padding: const EdgeInsets.all(12), child: content),
    );
  }

  List<Resource> _availableResources() {
    final usedResourceIds = drafts
        .map((draft) => draft.resourceId)
        .whereType<int>()
        .toSet();
    return resources
        .map((bundle) => bundle.resource)
        .where(
          (resource) =>
              resource.packId == packId &&
              resource.status == ResourceLifecycleStatus.active &&
              resource.config is QuantityBasedResourceConfig &&
              !usedResourceIds.contains(resource.id),
        )
        .toList(growable: false);
  }

  Future<void> _addDraft(
    BuildContext context,
    List<Resource> quantityResources,
  ) async {
    final draft = await showDialog<ResourceBindingDraft>(
      context: context,
      builder: (dialogContext) =>
          _ResourceBindingDraftDialog(resources: quantityResources),
    );
    if (draft == null) {
      return;
    }
    onChanged([...drafts, draft]);
  }
}

class _ResourceBindingDraftRow extends StatelessWidget {
  const _ResourceBindingDraftRow({
    super.key,
    required this.draft,
    required this.onRemove,
  });

  final ResourceBindingDraft draft;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final unit = draft.unit.trim();
    final amount = unit.isEmpty
        ? '${draft.consumeAmount}'
        : '${draft.consumeAmount} $unit';
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 48),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(draft.title, style: Theme.of(context).textTheme.bodyLarge),
                const SizedBox(height: 2),
                Text(
                  '${ReminderUiText.resourceBindingConsumePrefix} $amount',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: '移除綁定',
            onPressed: onRemove,
            icon: const Icon(Icons.close),
          ),
        ],
      ),
    );
  }
}

enum _ResourceDraftMode { existing, newResource }

class _ResourceBindingDraftDialog extends StatefulWidget {
  const _ResourceBindingDraftDialog({required this.resources});

  final List<Resource> resources;

  @override
  State<_ResourceBindingDraftDialog> createState() =>
      _ResourceBindingDraftDialogState();
}

class _ResourceBindingDraftDialogState
    extends State<_ResourceBindingDraftDialog> {
  final _formKey = GlobalKey<FormState>();
  final _consumeController = TextEditingController(text: '1');
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _quantityController = TextEditingController(text: '1');
  final _unitController = TextEditingController(text: '個');
  final _warningController = TextEditingController(text: '2');
  final _dangerController = TextEditingController(text: '1');

  late _ResourceDraftMode _mode;
  int? _selectedResourceId;

  @override
  void initState() {
    super.initState();
    _mode = widget.resources.isEmpty
        ? _ResourceDraftMode.newResource
        : _ResourceDraftMode.existing;
    _selectedResourceId = widget.resources.isEmpty
        ? null
        : widget.resources.first.id;
  }

  @override
  void dispose() {
    _consumeController.dispose();
    _titleController.dispose();
    _descriptionController.dispose();
    _quantityController.dispose();
    _unitController.dispose();
    _warningController.dispose();
    _dangerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('綁定資源'),
      content: SizedBox(
        width: 420,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SegmentedButton<_ResourceDraftMode>(
                  segments: [
                    ButtonSegment(
                      value: _ResourceDraftMode.existing,
                      enabled: widget.resources.isNotEmpty,
                      label: const Text('既有資源'),
                    ),
                    const ButtonSegment(
                      value: _ResourceDraftMode.newResource,
                      label: Text('新增庫存'),
                    ),
                  ],
                  selected: {_mode},
                  onSelectionChanged: (selection) {
                    setState(() {
                      _mode = selection.single;
                    });
                  },
                ),
                const SizedBox(height: 12),
                if (_mode == _ResourceDraftMode.existing)
                  ReminderEditorPickerRow(
                    key: const Key('existing-resource-binding-field'),
                    label: '資源',
                    value: _selectedResourceTitle,
                    onTap: _showResourcePicker,
                  )
                else
                  _NewQuantityResourceFields(
                    titleController: _titleController,
                    descriptionController: _descriptionController,
                    quantityController: _quantityController,
                    unitController: _unitController,
                    warningController: _warningController,
                    dangerController: _dangerController,
                  ),
                const SizedBox(height: 12),
                ReminderEditorNumberField(
                  fieldKey: const Key('resource-binding-consume-field'),
                  controller: _consumeController,
                  label: '每次完成扣多少',
                  minimum: 1,
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
        ),
        FilledButton(
          key: const Key('resource-binding-save-button'),
          onPressed: _submit,
          child: const Text('確定'),
        ),
      ],
    );
  }

  String get _selectedResourceTitle {
    for (final resource in widget.resources) {
      if (resource.id == _selectedResourceId) {
        return resource.title;
      }
    }
    return '請選擇資源';
  }

  Future<void> _showResourcePicker() async {
    final value = await showModalBottomSheet<int>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          children: [
            Text('資源', style: Theme.of(sheetContext).textTheme.titleMedium),
            const SizedBox(height: 8),
            for (final resource in widget.resources)
              ListTile(
                key: Key('resource-binding-option-${resource.id}'),
                title: Text(resource.title),
                trailing: resource.id == _selectedResourceId
                    ? const Icon(Icons.check)
                    : null,
                onTap: () => Navigator.of(sheetContext).pop(resource.id),
              ),
          ],
        ),
      ),
    );
    if (value == null || !mounted) {
      return;
    }
    setState(() {
      _selectedResourceId = value;
    });
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    final consumeAmount = int.tryParse(_consumeController.text.trim()) ?? 1;
    if (_mode == _ResourceDraftMode.existing) {
      if (_selectedResourceId == null) {
        return;
      }
      final resource = widget.resources.firstWhere(
        (item) => item.id == _selectedResourceId,
      );
      final config = resource.config as QuantityBasedResourceConfig;
      Navigator.of(context).pop(
        ResourceBindingDraft.existing(
          resourceId: resource.id,
          resourceTitle: resource.title,
          unitLabel: config.unitLabel,
          consumeAmount: consumeAmount,
        ),
      );
      return;
    }

    Navigator.of(context).pop(
      ResourceBindingDraft.newResource(
        consumeAmount: consumeAmount,
        resource: ResourceInput(
          title: _titleController.text.trim(),
          description: _normalizeOptionalText(_descriptionController.text),
          type: ResourceType.quantityBased,
          config: QuantityBasedResourceConfig(
            currentQuantity: _nonNegativeInt(_quantityController),
            unitLabel: _unitController.text.trim().isEmpty
                ? '個'
                : _unitController.text.trim(),
            warningThreshold: _nonNegativeInt(_warningController),
            dangerThreshold: _nonNegativeInt(_dangerController),
          ),
        ),
      ),
    );
  }

  int _nonNegativeInt(TextEditingController controller) {
    final parsed = int.tryParse(controller.text.trim());
    return parsed == null || parsed < 0 ? 0 : parsed;
  }

  String? _normalizeOptionalText(String value) {
    final normalized = value.trim();
    return normalized.isEmpty ? null : normalized;
  }
}

class _NewQuantityResourceFields extends StatelessWidget {
  const _NewQuantityResourceFields({
    required this.titleController,
    required this.descriptionController,
    required this.quantityController,
    required this.unitController,
    required this.warningController,
    required this.dangerController,
  });

  final TextEditingController titleController;
  final TextEditingController descriptionController;
  final TextEditingController quantityController;
  final TextEditingController unitController;
  final TextEditingController warningController;
  final TextEditingController dangerController;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextFormField(
          key: const Key('new-resource-binding-title-field'),
          controller: titleController,
          decoration: const InputDecoration(labelText: '資源名稱'),
          validator: (value) => (value ?? '').trim().isEmpty ? '請輸入資源名稱' : null,
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: descriptionController,
          decoration: const InputDecoration(labelText: '備註'),
        ),
        const SizedBox(height: 12),
        _numberField(quantityController, '目前有多少'),
        const SizedBox(height: 12),
        TextFormField(
          controller: unitController,
          decoration: const InputDecoration(labelText: '單位'),
        ),
        const SizedBox(height: 12),
        _numberField(warningController, '剩多少開始提醒'),
        const SizedBox(height: 12),
        _numberField(dangerController, '剩多少進入危急'),
      ],
    );
  }

  Widget _numberField(TextEditingController controller, String label) {
    return ReminderEditorNumberField(
      controller: controller,
      label: label,
      minimum: 0,
    );
  }
}
