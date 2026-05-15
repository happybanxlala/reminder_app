import 'package:flutter/material.dart';

import '../../data/item_repository.dart';
import '../../data/local/reminder_dao.dart';
import '../../data/resource_repository.dart';
import '../../domain/resource.dart';

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
  });

  final List<ResourceBindingDraft> drafts;
  final List<ResourceBundle> resources;
  final int? packId;
  final ValueChanged<List<ResourceBindingDraft>> onChanged;

  @override
  Widget build(BuildContext context) {
    final quantityResources = _availableResources();
    return Card(
      key: const Key('resource-binding-draft-section'),
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('消耗資源'),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                key: const Key('add-resource-binding-draft-button'),
                onPressed: () => _addDraft(context, quantityResources),
                icon: const Icon(Icons.add),
                label: const Text('綁定資源'),
              ),
            ),
            const SizedBox(height: 8),
            if (drafts.isEmpty)
              const Text('建立後，完成這個 item 時可以扣掉指定資源。')
            else
              ...drafts.asMap().entries.map(
                (entry) => ListTile(
                  key: Key('resource-binding-draft-${entry.key}'),
                  contentPadding: EdgeInsets.zero,
                  title: Text(entry.value.title),
                  subtitle: Text(
                    '每次完成扣 ${entry.value.consumeAmount} ${entry.value.unit}',
                  ),
                  trailing: IconButton(
                    tooltip: '移除綁定',
                    onPressed: () {
                      final next = [...drafts]..removeAt(entry.key);
                      onChanged(next);
                    },
                    icon: const Icon(Icons.close),
                  ),
                ),
              ),
          ],
        ),
      ),
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
                  DropdownButtonFormField<int>(
                    key: const Key('existing-resource-binding-field'),
                    initialValue: _selectedResourceId,
                    decoration: const InputDecoration(labelText: '資源'),
                    items: widget.resources
                        .map(
                          (resource) => DropdownMenuItem(
                            value: resource.id,
                            child: Text(resource.title),
                          ),
                        )
                        .toList(growable: false),
                    validator: (value) => value == null ? '請選擇資源' : null,
                    onChanged: (value) {
                      setState(() {
                        _selectedResourceId = value;
                      });
                    },
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
                TextFormField(
                  key: const Key('resource-binding-consume-field'),
                  controller: _consumeController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: '每次完成扣多少'),
                  validator: (value) {
                    final parsed = int.tryParse((value ?? '').trim());
                    return parsed == null || parsed < 1 ? '請輸入 1 或以上' : null;
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

  void _submit() {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    final consumeAmount = int.tryParse(_consumeController.text.trim()) ?? 1;
    if (_mode == _ResourceDraftMode.existing) {
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
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(labelText: label),
      validator: (value) {
        final parsed = int.tryParse((value ?? '').trim());
        return parsed == null || parsed < 0 ? '請輸入 0 或以上' : null;
      },
    );
  }
}
