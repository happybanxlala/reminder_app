import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../domain/reminder.dart';
import '../../presentation/reminder_view_models.dart';

class Step4FixedWidget extends StatelessWidget {
  const Step4FixedWidget({
    super.key,
    required this.draft,
    required this.repeatIntervalController,
    required this.triggerOffsetDaysController,
    required this.showsDateFields,
    required this.onRepeatTypeChanged,
    required this.onRepeatIntervalChanged,
    required this.onTriggerModeChanged,
    required this.onTriggerOffsetDaysChanged,
    required this.onPickDueAt,
    required this.onClearDueAt,
  });

  final ReminderWizardDraft draft;
  final TextEditingController repeatIntervalController;
  final TextEditingController triggerOffsetDaysController;
  final bool showsDateFields;
  final ValueChanged<String?> onRepeatTypeChanged;
  final ValueChanged<int> onRepeatIntervalChanged;
  final ValueChanged<int> onTriggerModeChanged;
  final ValueChanged<int> onTriggerOffsetDaysChanged;
  final VoidCallback onPickDueAt;
  final VoidCallback onClearDueAt;

  @override
  Widget build(BuildContext context) {
    final options = ReminderTriggerModeOption.forTrackingMode(
      draft.trackingMode,
    );
    final values = options.map((item) => item.value).toSet();
    final effectiveValue = values.contains(draft.triggerMode)
        ? draft.triggerMode
        : ReminderTriggerMode.inRange;
    final dueText = draft.dueAt == null
        ? '未設定'
        : DateFormat('yyyy/MM/dd').format(draft.dueAt!.toLocal());

    return Column(
      children: [
        _RepeatSection(
          draft: draft,
          labelText: '頻率',
          repeatIntervalController: repeatIntervalController,
          onRepeatTypeChanged: onRepeatTypeChanged,
          onRepeatIntervalChanged: onRepeatIntervalChanged,
        ),
        if (showsDateFields) ...[
          const SizedBox(height: 12),
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
        ],
        const SizedBox(height: 12),
        const Text('這是日期型提醒；目前不支援精準時分通知。'),
        const SizedBox(height: 12),
        DropdownButtonFormField<int>(
          key: const Key('edit-notify-strategy-field'),
          initialValue: effectiveValue,
          decoration: const InputDecoration(
            labelText: '提醒方式',
            border: OutlineInputBorder(),
          ),
          items: options
              .map(
                (option) => DropdownMenuItem(
                  value: option.value,
                  child: Text(option.label),
                ),
              )
              .toList(growable: false),
          onChanged: draft.readOnly
              ? null
              : (value) {
                  if (value != null) {
                    onTriggerModeChanged(value);
                  }
                },
        ),
        const SizedBox(height: 12),
        _TriggerOffsetField(
          draft: draft,
          controller: triggerOffsetDaysController,
          onChanged: onTriggerOffsetDaysChanged,
        ),
      ],
    );
  }
}

class _RepeatSection extends StatelessWidget {
  const _RepeatSection({
    required this.draft,
    required this.labelText,
    required this.repeatIntervalController,
    required this.onRepeatTypeChanged,
    required this.onRepeatIntervalChanged,
  });

  final ReminderWizardDraft draft;
  final String labelText;
  final TextEditingController repeatIntervalController;
  final ValueChanged<String?> onRepeatTypeChanged;
  final ValueChanged<int> onRepeatIntervalChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<String?>(
          key: ValueKey<String?>(
            draft.repeatType == null
                ? 'repeat-type-null'
                : 'repeat-type-${draft.repeatType}',
          ),
          initialValue: draft.repeatType,
          decoration: InputDecoration(
            labelText: labelText,
            border: const OutlineInputBorder(),
          ),
          items: const [
            DropdownMenuItem<String?>(value: 'D', child: Text('每天 / 每 X 天')),
            DropdownMenuItem<String?>(value: 'W', child: Text('每週')),
            DropdownMenuItem<String?>(value: 'M', child: Text('每月')),
            DropdownMenuItem<String?>(value: 'Y', child: Text('每年')),
          ],
          onChanged: draft.readOnly ? null : onRepeatTypeChanged,
        ),
        const SizedBox(height: 12),
        TextFormField(
          key: const Key('edit-repeat-interval-field'),
          controller: repeatIntervalController,
          enabled: !draft.readOnly,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: '間隔（1 代表每次）',
            border: OutlineInputBorder(),
          ),
          onChanged: (value) {
            final interval = int.tryParse(value);
            if (interval != null && interval >= 1) {
              onRepeatIntervalChanged(interval);
            }
          },
          validator: (value) {
            final interval = int.tryParse(value ?? '');
            if (interval == null || interval < 1) {
              return '請輸入 1 或以上';
            }
            return null;
          },
        ),
      ],
    );
  }
}

class _TriggerOffsetField extends StatelessWidget {
  const _TriggerOffsetField({
    required this.draft,
    required this.controller,
    required this.onChanged,
  });

  final ReminderWizardDraft draft;
  final TextEditingController controller;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      key: const Key('edit-remind-days-field'),
      controller: controller,
      enabled: !draft.readOnly,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: draft.trackingMode == ReminderTrackingMode.countdown
            ? '提前提醒天數'
            : '第幾天提醒',
        border: const OutlineInputBorder(),
      ),
      onChanged: (value) {
        final days = int.tryParse(value);
        if (days != null && days >= 0) {
          onChanged(days);
        }
      },
      validator: (value) {
        final days = int.tryParse(value ?? '');
        if (days == null || days < 0) {
          return '請輸入 0 或以上';
        }
        return null;
      },
    );
  }
}
