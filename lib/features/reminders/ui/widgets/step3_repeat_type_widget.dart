import 'package:flutter/material.dart';

import '../../presentation/reminder_view_models.dart';

class Step3RepeatTypeWidget extends StatelessWidget {
  const Step3RepeatTypeWidget({
    super.key,
    required this.draft,
    required this.isSeriesEdit,
    required this.onRepeatPatternChanged,
  });

  final ReminderWizardDraft draft;
  final bool isSeriesEdit;
  final ValueChanged<ReminderWizardRepeatPattern> onRepeatPatternChanged;

  @override
  Widget build(BuildContext context) {
    final isLocked = draft.readOnly || isSeriesEdit;
    return Column(
      key: const Key('edit-time-basis-field'),
      children: [
        _RepeatPatternTile(
          key: const Key('wizard-repeat-pattern-fixed'),
          selected:
              draft.repeatPattern == ReminderWizardRepeatPattern.fixedTime,
          enabled: !isLocked,
          title: '固定時間',
          subtitle: '例如每天、每週一',
          onTap: () =>
              onRepeatPatternChanged(ReminderWizardRepeatPattern.fixedTime),
        ),
        _RepeatPatternTile(
          key: const Key('wizard-repeat-pattern-start'),
          selected:
              draft.repeatPattern == ReminderWizardRepeatPattern.fromStart,
          enabled: !isLocked,
          title: '從某天開始',
          subtitle: '例如紀念日、養寵物第幾天',
          onTap: () =>
              onRepeatPatternChanged(ReminderWizardRepeatPattern.fromStart),
        ),
      ],
    );
  }
}

class _RepeatPatternTile extends StatelessWidget {
  const _RepeatPatternTile({
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
