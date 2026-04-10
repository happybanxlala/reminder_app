import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../presentation/reminder_view_models.dart';

class Step4SinceStartWidget extends StatelessWidget {
  const Step4SinceStartWidget({
    super.key,
    required this.draft,
    required this.repeatIntervalController,
    required this.triggerOffsetDaysController,
    required this.showsDateFields,
    required this.onPickStartAt,
    required this.onSetToday,
    required this.onAccumulationDisplayChanged,
    required this.onRepeatTypeChanged,
    required this.onRepeatIntervalChanged,
    required this.onTriggerOffsetDaysChanged,
  });

  final ReminderWizardDraft draft;
  final TextEditingController repeatIntervalController;
  final TextEditingController triggerOffsetDaysController;
  final bool showsDateFields;
  final VoidCallback onPickStartAt;
  final VoidCallback onSetToday;
  final ValueChanged<ReminderWizardAccumulationDisplay>
  onAccumulationDisplayChanged;
  final ValueChanged<String?> onRepeatTypeChanged;
  final ValueChanged<int> onRepeatIntervalChanged;
  final ValueChanged<int> onTriggerOffsetDaysChanged;

  @override
  Widget build(BuildContext context) {
    final startText = draft.startAt == null
        ? '未設定'
        : DateFormat('yyyy/MM/dd').format(draft.startAt!.toLocal());

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showsDateFields)
          InputDecorator(
            decoration: const InputDecoration(
              labelText: '起始日期',
              border: OutlineInputBorder(),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(startText, key: const Key('edit-start-at-text')),
                ),
                TextButton(
                  onPressed: draft.readOnly ? null : onPickStartAt,
                  child: const Text('選擇'),
                ),
                TextButton(
                  onPressed: draft.readOnly ? null : onSetToday,
                  child: const Text('今天'),
                ),
              ],
            ),
          ),
        const SizedBox(height: 12),
        DropdownButtonFormField<ReminderWizardAccumulationDisplay>(
          key: const Key('wizard-accumulation-display-field'),
          initialValue: draft.accumulationDisplay,
          decoration: const InputDecoration(
            labelText: '顯示方式',
            border: OutlineInputBorder(),
          ),
          items: const [
            DropdownMenuItem(
              value: ReminderWizardAccumulationDisplay.day,
              child: Text('第幾天'),
            ),
            DropdownMenuItem(
              value: ReminderWizardAccumulationDisplay.week,
              child: Text('第幾週'),
            ),
            DropdownMenuItem(
              value: ReminderWizardAccumulationDisplay.year,
              child: Text('第幾年'),
            ),
          ],
          onChanged: draft.readOnly
              ? null
              : (value) {
                  if (value != null) {
                    onAccumulationDisplayChanged(value);
                  }
                },
        ),
        const SizedBox(height: 12),
        Text(
          _accumulationPreviewText(draft),
          key: const Key('wizard-accumulation-preview'),
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const SizedBox(height: 12),
        _RepeatSection(
          draft: draft,
          labelText: '提醒頻率',
          repeatIntervalController: repeatIntervalController,
          onRepeatTypeChanged: onRepeatTypeChanged,
          onRepeatIntervalChanged: onRepeatIntervalChanged,
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
      decoration: const InputDecoration(
        labelText: '第幾天提醒',
        border: OutlineInputBorder(),
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

String _accumulationPreviewText(ReminderWizardDraft draft) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final startValue = draft.startAt ?? today;
  final start = DateTime(startValue.year, startValue.month, startValue.day);
  final diffDays = today.difference(start).inDays;
  if (diffDays < 0) {
    return '還有 ${diffDays.abs()} 天開始';
  }

  final count = switch (draft.accumulationDisplay) {
    ReminderWizardAccumulationDisplay.day => diffDays + 1,
    ReminderWizardAccumulationDisplay.week => (diffDays ~/ 7) + 1,
    ReminderWizardAccumulationDisplay.year => _yearCount(start, today),
  };
  final unit = switch (draft.accumulationDisplay) {
    ReminderWizardAccumulationDisplay.day => '天',
    ReminderWizardAccumulationDisplay.week => '週',
    ReminderWizardAccumulationDisplay.year => '年',
  };
  return '今天是第 $count $unit';
}

int _yearCount(DateTime start, DateTime today) {
  var years = today.year - start.year;
  final anniversaryThisYear = DateTime(today.year, start.month, start.day);
  if (today.isBefore(anniversaryThisYear)) {
    years -= 1;
  }
  return years + 1;
}
