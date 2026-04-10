import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../presentation/reminder_view_models.dart';

class Step4OnceWidget extends StatelessWidget {
  const Step4OnceWidget({
    super.key,
    required this.draft,
    required this.showsDateFields,
    required this.onPickDueAt,
    required this.onClearDueAt,
  });

  final ReminderWizardDraft draft;
  final bool showsDateFields;
  final VoidCallback onPickDueAt;
  final VoidCallback onClearDueAt;

  @override
  Widget build(BuildContext context) {
    final dueText = draft.dueAt == null
        ? '未設定'
        : DateFormat('yyyy/MM/dd').format(draft.dueAt!.toLocal());

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showsDateFields)
          InputDecorator(
            decoration: const InputDecoration(
              labelText: '日期（必填）',
              border: OutlineInputBorder(),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(dueText, key: const Key('edit-due-at-text')),
                ),
                TextButton(
                  onPressed: draft.readOnly ? null : onPickDueAt,
                  child: const Text('選擇'),
                ),
                TextButton(
                  onPressed: draft.readOnly ? null : onClearDueAt,
                  child: const Text('清除'),
                ),
              ],
            ),
          ),
        const SizedBox(height: 12),
        const Text('這是日期型提醒；目前不支援精準時分通知。'),
      ],
    );
  }
}
