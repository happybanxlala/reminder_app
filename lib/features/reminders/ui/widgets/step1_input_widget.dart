import 'package:flutter/material.dart';

import '../../domain/action_category.dart';
import '../../domain/topic_category.dart';
import '../../presentation/reminder_view_models.dart';

class Step1InputWidget extends StatelessWidget {
  const Step1InputWidget({
    super.key,
    required this.draft,
    required this.titleController,
    required this.noteController,
    required this.topicCategories,
    required this.actionCategories,
    required this.onTitleChanged,
    required this.onNoteChanged,
    required this.onTopicCategoryChanged,
    required this.onActionCategoryChanged,
  });

  final ReminderWizardDraft draft;
  final TextEditingController titleController;
  final TextEditingController noteController;
  final List<TopicCategoryModel> topicCategories;
  final List<ActionCategoryModel> actionCategories;
  final ValueChanged<String> onTitleChanged;
  final ValueChanged<String> onNoteChanged;
  final ValueChanged<int?> onTopicCategoryChanged;
  final ValueChanged<int?> onActionCategoryChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          key: const Key('edit-title-field'),
          controller: titleController,
          enabled: !draft.readOnly,
          decoration: const InputDecoration(
            labelText: '你想提醒什麼？',
            border: OutlineInputBorder(),
          ),
          onChanged: onTitleChanged,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return '請輸入任務內容';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        Text('分類（選填）', style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 8),
        DropdownButtonFormField<int?>(
          key: const Key('edit-issue-type-field'),
          initialValue: draft.topicCategoryId,
          decoration: const InputDecoration(
            labelText: '主題分類（選填）',
            border: OutlineInputBorder(),
          ),
          items: [
            const DropdownMenuItem<int?>(value: null, child: Text('未指定')),
            ...topicCategories.map(
              (item) => DropdownMenuItem<int?>(
                value: item.id,
                child: Text(item.name),
              ),
            ),
          ],
          onChanged: draft.readOnly ? null : onTopicCategoryChanged,
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<int?>(
          key: const Key('edit-handle-type-field'),
          initialValue: draft.actionCategoryId,
          decoration: const InputDecoration(
            labelText: '行動分類（選填）',
            border: OutlineInputBorder(),
          ),
          items: [
            const DropdownMenuItem<int?>(value: null, child: Text('未指定')),
            ...actionCategories.map(
              (item) => DropdownMenuItem<int?>(
                value: item.id,
                child: Text(item.name),
              ),
            ),
          ],
          onChanged: draft.readOnly ? null : onActionCategoryChanged,
        ),
        const SizedBox(height: 8),
        ExpansionTile(
          key: ValueKey<bool>(draft.note != null),
          tilePadding: EdgeInsets.zero,
          childrenPadding: EdgeInsets.zero,
          initiallyExpanded: draft.note != null,
          title: const Text('進階'),
          children: [
            TextFormField(
              key: const Key('edit-note-field'),
              controller: noteController,
              enabled: !draft.readOnly,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: '備註（選填）',
                border: OutlineInputBorder(),
              ),
              onChanged: onNoteChanged,
            ),
          ],
        ),
      ],
    );
  }
}
