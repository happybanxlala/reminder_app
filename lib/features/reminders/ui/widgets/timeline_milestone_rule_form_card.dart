import 'package:flutter/material.dart';

import '../../data/timeline_models.dart';
import '../../domain/timeline.dart';
import '../../domain/timeline_milestone_rule.dart';
import '../../presentation/formatters/reminder_formatters.dart';
import '../../presentation/text/reminder_ui_text.dart';

class TimelineMilestoneRuleDraft {
  const TimelineMilestoneRuleDraft({
    required this.localId,
    this.id,
    required this.type,
    required this.intervalValue,
    required this.intervalUnit,
    required this.labelTemplate,
    required this.reminderOffsetDays,
    required this.status,
  });

  factory TimelineMilestoneRuleDraft.fromRule(TimelineMilestoneRule rule) {
    return TimelineMilestoneRuleDraft(
      localId: rule.id,
      id: rule.id,
      type: rule.type,
      intervalValue: '${rule.intervalValue}',
      intervalUnit: rule.intervalUnit,
      labelTemplate: rule.labelTemplate ?? '',
      reminderOffsetDays: '${rule.reminderOffsetDays}',
      status: rule.status,
    );
  }

  factory TimelineMilestoneRuleDraft.defaults(TimelineDisplayUnit displayUnit) {
    final seed = DateTime.now().microsecondsSinceEpoch;
    return switch (displayUnit) {
      TimelineDisplayUnit.day => TimelineMilestoneRuleDraft(
        localId: seed,
        type: TimelineMilestoneRuleType.everyNDays,
        intervalValue: '1',
        intervalUnit: TimelineMilestoneIntervalUnit.days,
        labelTemplate: '第 {value}{unit}',
        reminderOffsetDays: '0',
        status: TimelineMilestoneRuleStatus.active,
      ),
      TimelineDisplayUnit.week => TimelineMilestoneRuleDraft(
        localId: seed,
        type: TimelineMilestoneRuleType.everyNWeeks,
        intervalValue: '1',
        intervalUnit: TimelineMilestoneIntervalUnit.weeks,
        labelTemplate: '第 {value}{unit}',
        reminderOffsetDays: '0',
        status: TimelineMilestoneRuleStatus.active,
      ),
      TimelineDisplayUnit.month => TimelineMilestoneRuleDraft(
        localId: seed,
        type: TimelineMilestoneRuleType.everyNMonths,
        intervalValue: '1',
        intervalUnit: TimelineMilestoneIntervalUnit.months,
        labelTemplate: '第 {value}{unit}',
        reminderOffsetDays: '0',
        status: TimelineMilestoneRuleStatus.active,
      ),
      TimelineDisplayUnit.year => TimelineMilestoneRuleDraft(
        localId: seed,
        type: TimelineMilestoneRuleType.everyNYears,
        intervalValue: '1',
        intervalUnit: TimelineMilestoneIntervalUnit.years,
        labelTemplate: '第 {value}{unit}',
        reminderOffsetDays: '0',
        status: TimelineMilestoneRuleStatus.active,
      ),
    };
  }

  final int localId;
  final int? id;
  final TimelineMilestoneRuleType type;
  final String intervalValue;
  final TimelineMilestoneIntervalUnit intervalUnit;
  final String labelTemplate;
  final String reminderOffsetDays;
  final TimelineMilestoneRuleStatus status;

  int get effectiveRuleId => id ?? -localId;

  TimelineMilestoneRuleDraft copyWith({
    TimelineMilestoneRuleType? type,
    String? intervalValue,
    TimelineMilestoneIntervalUnit? intervalUnit,
    String? labelTemplate,
    String? reminderOffsetDays,
    TimelineMilestoneRuleStatus? status,
  }) {
    return TimelineMilestoneRuleDraft(
      localId: localId,
      id: id,
      type: type ?? this.type,
      intervalValue: intervalValue ?? this.intervalValue,
      intervalUnit: intervalUnit ?? this.intervalUnit,
      labelTemplate: labelTemplate ?? this.labelTemplate,
      reminderOffsetDays: reminderOffsetDays ?? this.reminderOffsetDays,
      status: status ?? this.status,
    );
  }

  TimelineMilestoneRuleInput toInput() {
    return TimelineMilestoneRuleInput(
      id: id,
      type: type,
      intervalValue: int.tryParse(intervalValue) ?? 1,
      intervalUnit: intervalUnit,
      labelTemplate: labelTemplate.trim().isEmpty ? null : labelTemplate.trim(),
      reminderOffsetDays: int.tryParse(reminderOffsetDays) ?? 0,
      status: status,
    );
  }

  TimelineMilestoneRule toRule({
    required int timelineId,
    required int ruleId,
    required DateTime now,
  }) {
    return TimelineMilestoneRule(
      id: ruleId,
      timelineId: timelineId,
      type: type,
      intervalValue: int.tryParse(intervalValue) ?? 1,
      intervalUnit: intervalUnit,
      labelTemplate: labelTemplate.trim().isEmpty ? null : labelTemplate.trim(),
      reminderOffsetDays: int.tryParse(reminderOffsetDays) ?? 0,
      status: status,
      createdAt: now,
      updatedAt: now,
    );
  }
}

class TimelineMilestoneRuleFormCard extends StatefulWidget {
  const TimelineMilestoneRuleFormCard({
    super.key,
    required this.draft,
    required this.previewLabel,
    required this.upcomingSummary,
    required this.onChanged,
    required this.onRemove,
    required this.validatePositiveInt,
    required this.validateOffsetDays,
  });

  final TimelineMilestoneRuleDraft draft;
  final String? previewLabel;
  final String? upcomingSummary;
  final ValueChanged<TimelineMilestoneRuleDraft> onChanged;
  final VoidCallback onRemove;
  final FormFieldValidator<String> validatePositiveInt;
  final FormFieldValidator<String> validateOffsetDays;

  @override
  State<TimelineMilestoneRuleFormCard> createState() =>
      _TimelineMilestoneRuleFormCardState();
}

class _TimelineMilestoneRuleFormCardState
    extends State<TimelineMilestoneRuleFormCard> {
  late final TextEditingController _labelController;

  @override
  void initState() {
    super.initState();
    _labelController = TextEditingController(text: widget.draft.labelTemplate);
  }

  @override
  void didUpdateWidget(covariant TimelineMilestoneRuleFormCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.draft.labelTemplate != widget.draft.labelTemplate &&
        _labelController.text != widget.draft.labelTemplate) {
      _labelController.text = widget.draft.labelTemplate;
    }
  }

  @override
  void dispose() {
    _labelController.dispose();
    super.dispose();
  }

  void _appendToken(String token) {
    final next = '${_labelController.text}$token';
    _labelController.value = TextEditingValue(
      text: next,
      selection: TextSelection.collapsed(offset: next.length),
    );
    widget.onChanged(widget.draft.copyWith(labelTemplate: next));
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<TimelineMilestoneRuleType>(
                    key: Key('rule-type-${widget.draft.localId}'),
                    initialValue: widget.draft.type,
                    decoration: const InputDecoration(
                      labelText: ReminderUiText.timelineRuleTypeFieldLabel,
                    ),
                    items: TimelineMilestoneRuleType.values
                        .map(
                          (value) => DropdownMenuItem(
                            value: value,
                            child: Text(
                              ReminderFormatters.timelineMilestoneRuleType(
                                value,
                              ),
                            ),
                          ),
                        )
                        .toList(growable: false),
                    onChanged: (value) {
                      if (value == null) {
                        return;
                      }
                      widget.onChanged(
                        widget.draft.copyWith(
                          type: value,
                          intervalUnit: switch (value) {
                            TimelineMilestoneRuleType.everyNDays =>
                              TimelineMilestoneIntervalUnit.days,
                            TimelineMilestoneRuleType.everyNWeeks =>
                              TimelineMilestoneIntervalUnit.weeks,
                            TimelineMilestoneRuleType.everyNMonths =>
                              TimelineMilestoneIntervalUnit.months,
                            TimelineMilestoneRuleType.everyNYears =>
                              TimelineMilestoneIntervalUnit.years,
                          },
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 12),
                IconButton(
                  key: Key('remove-rule-${widget.draft.localId}'),
                  onPressed: widget.onRemove,
                  icon: const Icon(Icons.delete_outline),
                ),
              ],
            ),
            TextFormField(
              key: Key('rule-interval-${widget.draft.localId}'),
              initialValue: widget.draft.intervalValue,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: ReminderUiText.timelineRuleIntervalValueFieldLabel,
              ),
              validator: widget.validatePositiveInt,
              onChanged: (value) =>
                  widget.onChanged(widget.draft.copyWith(intervalValue: value)),
            ),
            const SizedBox(height: 12),
            TextFormField(
              key: Key('rule-label-${widget.draft.localId}'),
              controller: _labelController,
              decoration: const InputDecoration(
                labelText: ReminderUiText.timelineRuleLabelTemplateFieldLabel,
              ),
              onChanged: (value) =>
                  widget.onChanged(widget.draft.copyWith(labelTemplate: value)),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton(
                  key: Key('rule-token-n-${widget.draft.localId}'),
                  onPressed: () => _appendToken('{n}'),
                  child: const Text('次數'),
                ),
                OutlinedButton(
                  key: Key('rule-token-value-${widget.draft.localId}'),
                  onPressed: () => _appendToken('{value}'),
                  child: const Text('累積值'),
                ),
                OutlinedButton(
                  key: Key('rule-token-unit-${widget.draft.localId}'),
                  onPressed: () => _appendToken('{unit}'),
                  child: const Text('單位'),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                widget.previewLabel == null
                    ? ReminderUiText.timelineRulePreviewUnavailable
                    : '預覽：${widget.previewLabel}',
                key: Key('rule-preview-${widget.draft.localId}'),
              ),
            ),
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                widget.upcomingSummary == null
                    ? ReminderUiText.timelineRuleUpcomingUnavailable
                    : '${ReminderUiText.timelineRuleNextLabel}：${widget.upcomingSummary}',
                key: Key('rule-next-occurrence-${widget.draft.localId}'),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              key: Key('rule-offset-${widget.draft.localId}'),
              initialValue: widget.draft.reminderOffsetDays,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: ReminderUiText.timelineRuleReminderOffsetFieldLabel,
              ),
              validator: widget.validateOffsetDays,
              onChanged: (value) => widget.onChanged(
                widget.draft.copyWith(reminderOffsetDays: value),
              ),
            ),
            SwitchListTile(
              key: Key('rule-active-${widget.draft.localId}'),
              contentPadding: EdgeInsets.zero,
              value: widget.draft.status == TimelineMilestoneRuleStatus.active,
              title: const Text(ReminderUiText.timelineRuleActiveLabel),
              onChanged: (value) => widget.onChanged(
                widget.draft.copyWith(
                  status: value
                      ? TimelineMilestoneRuleStatus.active
                      : TimelineMilestoneRuleStatus.paused,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
