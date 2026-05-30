import 'package:flutter/material.dart';

import '../../domain/item_pack.dart';
import '../../presentation/text/reminder_ui_text.dart';

String packDisplayLabel(ItemPack pack) =>
    pack.isSystemDefault ? '📌 一般' : '${pack.iconEmoji} ${pack.title}';

String suggestPackEmoji(String title) {
  final value = title.trim();
  if (value.contains('貓')) {
    return '🐱';
  }
  if (value.contains('狗')) {
    return '🐶';
  }
  if (value.contains('家') || value.contains('清潔') || value.contains('家務')) {
    return '🏠';
  }
  if (value.contains('健康') || value.contains('醫')) {
    return '🩺';
  }
  if (value.contains('寶寶') || value.contains('小孩')) {
    return '👶';
  }
  return '🏷️';
}

class PackFormDialog extends StatefulWidget {
  const PackFormDialog({
    super.key,
    this.pack,
    this.showTemplateEntry = false,
    this.onCreateFromTemplate,
  });

  final ItemPack? pack;
  final bool showTemplateEntry;
  final VoidCallback? onCreateFromTemplate;

  @override
  State<PackFormDialog> createState() => _PackFormDialogState();
}

class _PackFormDialogState extends State<PackFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late String _selectedIcon;
  bool _iconWasSelected = false;

  static const _iconOptions = [
    _PackIconOption('🏷️', '一般標籤'),
    _PackIconOption('📌', '固定事項'),
    _PackIconOption('🏠', '家務'),
    _PackIconOption('🩺', '健康'),
    _PackIconOption('👶', '寶寶'),
    _PackIconOption('🐱', '貓'),
    _PackIconOption('🐶', '狗'),
    _PackIconOption('🍽️', '飲食'),
    _PackIconOption('🧹', '清潔'),
    _PackIconOption('💊', '用藥'),
    _PackIconOption('📚', '學習'),
    _PackIconOption('💼', '工作'),
  ];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.pack?.title ?? '');
    _selectedIcon = widget.pack?.iconEmoji ?? '🏷️';
    _descriptionController = TextEditingController(
      text: widget.pack?.description ?? '',
    );
    _titleController.addListener(_suggestIconIfNeeded);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.pack != null;
    return AlertDialog(
      title: Text(
        isEdit ? ReminderUiText.editItemPack : ReminderUiText.addItemPack,
      ),
      content: SizedBox(
        width: 420,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                key: const Key('pack-title-field'),
                controller: _titleController,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: ReminderUiText.packTitleFieldLabel,
                ),
                validator: (value) =>
                    (value ?? '').trim().isEmpty ? '請輸入名稱' : null,
              ),
              const SizedBox(height: 12),
              KeyedSubtree(
                key: const Key('pack-emoji-field'),
                child: DropdownButtonFormField<String>(
                  key: ValueKey(_selectedIcon),
                  initialValue: _selectedIcon,
                  decoration: const InputDecoration(
                    labelText: ReminderUiText.packEmojiFieldLabel,
                  ),
                  items: _iconMenuItems(),
                  onChanged: (value) {
                    if (value == null) {
                      return;
                    }
                    setState(() {
                      _selectedIcon = value;
                      _iconWasSelected = true;
                    });
                  },
                  validator: (value) =>
                      (value ?? '').trim().isEmpty ? '請選擇 emoji' : null,
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                key: const Key('pack-description-field'),
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: ReminderUiText.packDescriptionFieldLabel,
                ),
              ),
              if (!isEdit && widget.showTemplateEntry) ...[
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    key: const Key('pack-dialog-template-entry'),
                    onPressed: widget.onCreateFromTemplate == null
                        ? null
                        : () {
                            Navigator.of(context).pop();
                            widget.onCreateFromTemplate!();
                          },
                    icon: const Icon(Icons.auto_awesome_outlined),
                    label: const Text(
                      ReminderUiText.packTemplateCreateFromTemplateLabel,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
        ),
        FilledButton(
          key: const Key('pack-save-button'),
          onPressed: _submit,
          child: const Text(ReminderUiText.saveAction),
        ),
      ],
    );
  }

  List<DropdownMenuItem<String>> _iconMenuItems() {
    final options = [
      if (_iconOptions.every((option) => option.value != _selectedIcon))
        _PackIconOption(_selectedIcon, '目前圖示'),
      ..._iconOptions,
    ];
    return options
        .map(
          (option) => DropdownMenuItem<String>(
            value: option.value,
            child: Text('${option.value} ${option.label}'),
          ),
        )
        .toList(growable: false);
  }

  void _suggestIconIfNeeded() {
    if (_iconWasSelected || widget.pack != null) {
      return;
    }
    final suggested = suggestPackEmoji(_titleController.text);
    if (_selectedIcon != suggested) {
      setState(() {
        _selectedIcon = suggested;
        _iconWasSelected = false;
      });
    }
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    Navigator.of(context).pop(
      ItemPackInput(
        title: _titleController.text.trim(),
        description: _normalizeOptionalText(_descriptionController.text),
        iconEmoji: _selectedIcon.trim(),
      ),
    );
  }

  String? _normalizeOptionalText(String value) {
    final normalized = value.trim();
    return normalized.isEmpty ? null : normalized;
  }
}

class _PackIconOption {
  const _PackIconOption(this.value, this.label);

  final String value;
  final String label;
}
