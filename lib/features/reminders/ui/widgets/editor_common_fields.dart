import 'package:flutter/material.dart';

import '../../presentation/text/reminder_ui_text.dart';

class EditorTitleField extends StatelessWidget {
  const EditorTitleField({
    super.key,
    required this.controller,
    this.enabled = true,
    this.fieldKey = const Key('title-field'),
    this.labelText = ReminderUiText.itemTitleFieldLabel,
    this.hintText = ReminderUiText.itemTitleFieldHint,
    this.requiredErrorText = ReminderUiText.itemTitleFieldRequiredError,
  });

  final TextEditingController controller;
  final bool enabled;
  final Key fieldKey;
  final String labelText;
  final String hintText;
  final String requiredErrorText;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      key: fieldKey,
      controller: controller,
      enabled: enabled,
      decoration: InputDecoration(labelText: labelText, hintText: hintText),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return requiredErrorText;
        }
        return null;
      },
    );
  }
}

class EditorNoteField extends StatelessWidget {
  const EditorNoteField({
    super.key,
    required this.controller,
    this.fieldKey = const Key('note-field'),
    this.labelText = ReminderUiText.itemNoteFieldLabel,
    this.hintText = ReminderUiText.itemNoteFieldHint,
  });

  final TextEditingController controller;
  final Key fieldKey;
  final String labelText;
  final String hintText;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      key: fieldKey,
      controller: controller,
      decoration: InputDecoration(labelText: labelText, hintText: hintText),
      maxLines: 2,
    );
  }
}

class EditorDateField extends StatelessWidget {
  const EditorDateField({
    super.key,
    required this.controller,
    required this.label,
    required this.onPickDate,
  });

  final TextEditingController controller;
  final String label;
  final VoidCallback onPickDate;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      key: const Key('date-field'),
      controller: controller,
      readOnly: true,
      decoration: InputDecoration(
        labelText: label,
        suffixIcon: IconButton(
          onPressed: onPickDate,
          icon: const Icon(Icons.calendar_today_outlined),
        ),
      ),
    );
  }
}
