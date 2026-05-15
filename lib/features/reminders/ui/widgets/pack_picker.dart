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
  const PackFormDialog({super.key, this.pack});

  final ItemPack? pack;

  @override
  State<PackFormDialog> createState() => _PackFormDialogState();
}

class _PackFormDialogState extends State<PackFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _emojiController;
  late final TextEditingController _descriptionController;
  bool _emojiWasEdited = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.pack?.title ?? '');
    _emojiController = TextEditingController(
      text: widget.pack?.iconEmoji ?? '🏷️',
    );
    _descriptionController = TextEditingController(
      text: widget.pack?.description ?? '',
    );
    _titleController.addListener(_suggestEmojiIfNeeded);
    _emojiController.addListener(() {
      _emojiWasEdited = true;
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _emojiController.dispose();
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
              TextFormField(
                key: const Key('pack-emoji-field'),
                controller: _emojiController,
                decoration: const InputDecoration(
                  labelText: ReminderUiText.packEmojiFieldLabel,
                ),
                validator: (value) =>
                    (value ?? '').trim().isEmpty ? '請輸入 emoji' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                key: const Key('pack-description-field'),
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: ReminderUiText.packDescriptionFieldLabel,
                ),
              ),
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

  void _suggestEmojiIfNeeded() {
    if (_emojiWasEdited || widget.pack != null) {
      return;
    }
    final suggested = suggestPackEmoji(_titleController.text);
    if (_emojiController.text != suggested) {
      _emojiController.text = suggested;
      _emojiWasEdited = false;
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
        iconEmoji: _emojiController.text.trim(),
      ),
    );
  }

  String? _normalizeOptionalText(String value) {
    final normalized = value.trim();
    return normalized.isEmpty ? null : normalized;
  }
}
