import 'package:flutter/material.dart';

class EditorTitleField extends StatelessWidget {
  const EditorTitleField({
    super.key,
    required this.controller,
    this.enabled = true,
  });

  final TextEditingController controller;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      key: const Key('title-field'),
      controller: controller,
      enabled: enabled,
      decoration: const InputDecoration(labelText: 'Title'),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return '請輸入標題';
        }
        return null;
      },
    );
  }
}

class EditorNoteField extends StatelessWidget {
  const EditorNoteField({super.key, required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      key: const Key('note-field'),
      controller: controller,
      decoration: const InputDecoration(labelText: 'Note'),
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
