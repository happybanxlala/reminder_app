import 'package:flutter/material.dart';

import '../../presentation/reminder_view_models.dart';

class Step2RepeatToggleWidget extends StatelessWidget {
  const Step2RepeatToggleWidget({
    super.key,
    required this.draft,
    required this.isSeriesEdit,
    required this.onRepeatChoiceChanged,
  });

  final ReminderWizardDraft draft;
  final bool isSeriesEdit;
  final ValueChanged<ReminderWizardRepeatChoice> onRepeatChoiceChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _RepeatOptionTile(
          key: const Key('wizard-repeat-once'),
          selected: draft.repeatChoice == ReminderWizardRepeatChoice.once,
          enabled: !draft.readOnly && !isSeriesEdit,
          title: '不需要',
          subtitle: '只提醒一次',
          onTap: () => onRepeatChoiceChanged(ReminderWizardRepeatChoice.once),
        ),
        _RepeatOptionTile(
          key: const Key('wizard-repeat-recurring'),
          selected: draft.repeatChoice == ReminderWizardRepeatChoice.recurring,
          enabled: !draft.readOnly,
          title: '需要',
          subtitle: '系統會自動幫你安排下一次',
          onTap: () =>
              onRepeatChoiceChanged(ReminderWizardRepeatChoice.recurring),
        ),
        if (isSeriesEdit) ...[
          const SizedBox(height: 8),
          const Text('模板類型建立後不可修改。'),
        ],
      ],
    );
  }
}

class _RepeatOptionTile extends StatelessWidget {
  const _RepeatOptionTile({
    super.key,
    required this.selected,
    required this.enabled,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final bool selected;
  final bool enabled;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      enabled: enabled,
      leading: Icon(
        selected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
      ),
      title: Text(title),
      subtitle: Text(subtitle),
      onTap: enabled ? onTap : null,
    );
  }
}
