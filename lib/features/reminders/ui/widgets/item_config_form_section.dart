import 'package:flutter/material.dart';

import '../../domain/attention_policy.dart';
import '../../domain/item.dart';
import '../../domain/repeat_rule.dart';
import '../../domain/repeat_rule_v2.dart';
import '../../presentation/formatters/reminder_formatters.dart';
import '../../presentation/text/reminder_ui_text.dart';
import 'editor_form_components.dart';

part 'repeat_rule_sheet.dart';

enum FixedCompletionMode { dueOnly, leadWindow }

class ItemConfigFormController {
  ItemConfigFormController({
    AttentionPolicyResolver? attentionPolicyResolver,
    this.reminderTone = ReminderTone.standard,
  }) : _attentionPolicyResolver =
           attentionPolicyResolver ?? const AttentionPolicyResolver() {
    fixedAnchorDateController = TextEditingController();
    fixedDueDateController = TextEditingController();
    fixedLeadDaysController = TextEditingController(text: '1');
    fixedScheduleIntervalController = TextEditingController(text: '1');
    fixedMonthlyDayController = TextEditingController(text: '1');
    fixedWarningBeforeController = TextEditingController(text: '1');
    fixedDangerBeforeController = TextEditingController(text: '0');
    stateAnchorDateController = TextEditingController();
    stateExpectedIntervalController = TextEditingController(text: '14');
    warningAfterController = TextEditingController(text: '7');
    dangerAfterController = TextEditingController(text: '14');
    syncDateControllers();
  }

  late final TextEditingController fixedAnchorDateController;
  late final TextEditingController fixedDueDateController;
  late final TextEditingController fixedLeadDaysController;
  late final TextEditingController fixedScheduleIntervalController;
  late final TextEditingController fixedMonthlyDayController;
  late final TextEditingController fixedWarningBeforeController;
  late final TextEditingController fixedDangerBeforeController;
  late final TextEditingController stateAnchorDateController;
  late final TextEditingController stateExpectedIntervalController;
  late final TextEditingController warningAfterController;
  late final TextEditingController dangerAfterController;

  final AttentionPolicyResolver _attentionPolicyResolver;
  ReminderTone reminderTone;
  ItemType type = ItemType.fixed;
  FixedScheduleType scheduleType = FixedScheduleType.daily;
  RepeatRuleV2? fixedRepeatRuleV2;
  FixedCompletionMode fixedCompletionMode = FixedCompletionMode.dueOnly;
  ItemOverduePolicy overduePolicy = ItemOverduePolicy.waitForAction;
  bool customizeAttentionPolicy = false;
  bool fixedDateWindowNeedsRepair = false;
  DateTime selectedFixedAnchorDate = DateTime.now();
  DateTime selectedFixedDueDate = DateTime.now();
  DateTime selectedStateAnchorDate = DateTime.now();
  Duration fixedInfoBefore = Duration.zero;
  Duration stateInfoAfter = Duration.zero;

  void dispose() {
    fixedAnchorDateController.dispose();
    fixedDueDateController.dispose();
    fixedLeadDaysController.dispose();
    fixedScheduleIntervalController.dispose();
    fixedMonthlyDayController.dispose();
    fixedWarningBeforeController.dispose();
    fixedDangerBeforeController.dispose();
    stateAnchorDateController.dispose();
    stateExpectedIntervalController.dispose();
    warningAfterController.dispose();
    dangerAfterController.dispose();
  }

  void load(ItemConfig config) {
    type = config.type;
    switch (config) {
      case FixedItemConfig fixed:
        scheduleType = fixed.scheduleType;
        fixedRepeatRuleV2 = fixed.repeatRuleV2;
        fixedScheduleIntervalController.text = '${fixed.scheduleInterval}';
        fixedMonthlyDayController.text =
            '${fixed.monthlyDay ?? fixed.dueDate?.day ?? 1}';
        overduePolicy = fixed.overduePolicy;
        selectedFixedDueDate = fixed.dueDate ?? selectedFixedDueDate;
        _loadFixedCompletionWindow(fixed);
        fixedInfoBefore = fixed.infoBefore;
        fixedWarningBeforeController.text = '${fixed.warningBefore.inDays}';
        fixedDangerBeforeController.text = '${fixed.dangerBefore.inDays}';
      case StateBasedItemConfig state:
        selectedStateAnchorDate = state.anchorDate ?? selectedStateAnchorDate;
        stateInfoAfter = state.infoAfter;
        stateExpectedIntervalController.text = '${state.dangerAfter.inDays}';
        warningAfterController.text = '${state.warningAfter.inDays}';
        dangerAfterController.text = '${state.dangerAfter.inDays}';
    }
    syncDateControllers();
  }

  void syncDateControllers() {
    selectedFixedAnchorDate = derivedFixedAnchorDate;
    fixedAnchorDateController.text = ReminderFormatters.date(
      selectedFixedAnchorDate,
    );
    fixedDueDateController.text = ReminderFormatters.date(selectedFixedDueDate);
    stateAnchorDateController.text = ReminderFormatters.date(
      selectedStateAnchorDate,
    );
  }

  DateTime get derivedFixedAnchorDate {
    return switch (fixedCompletionMode) {
      FixedCompletionMode.dueOnly => selectedFixedDueDate,
      FixedCompletionMode.leadWindow => selectedFixedDueDate.subtract(
        Duration(days: parsePositiveDays(fixedLeadDaysController)),
      ),
    };
  }

  String? get fixedDateWindowErrorText => fixedDateWindowNeedsRepair
      ? ReminderUiText.fixedScheduleInvalidWindowError
      : null;

  void setFixedCompletionMode(FixedCompletionMode value) {
    fixedCompletionMode = value;
    fixedDateWindowNeedsRepair = false;
    syncDateControllers();
  }

  void setFixedDueDate(DateTime value) {
    selectedFixedDueDate = value;
    fixedDateWindowNeedsRepair = false;
    syncDateControllers();
  }

  ItemConfig buildConfig() {
    return buildConfigForEdit();
  }

  ItemConfig buildConfigForCreate() {
    return switch (type) {
      ItemType.fixed => _buildFixedConfig(deriveAttentionPolicy: true),
      ItemType.stateBased => _buildStateBasedConfig(
        deriveAttentionPolicy: true,
      ),
    };
  }

  ItemConfig buildConfigForEdit() {
    return switch (type) {
      ItemType.fixed => _buildFixedConfig(deriveAttentionPolicy: false),
      ItemType.stateBased => _buildStateBasedConfig(
        deriveAttentionPolicy: false,
      ),
    };
  }

  ItemConfig buildConfigForCurrentPolicySource() {
    if (type == ItemType.fixed) {
      return buildConfigForCreate();
    }
    return customizeAttentionPolicy
        ? buildConfigForEdit()
        : buildConfigForCreate();
  }

  void setCustomizeAttentionPolicy(bool value) {
    if (value && !customizeAttentionPolicy) {
      _loadRawAttentionPolicy(buildConfigForCreate());
    }
    customizeAttentionPolicy = value;
  }

  void _loadRawAttentionPolicy(ItemConfig config) {
    switch (config) {
      case FixedItemConfig fixed:
        fixedWarningBeforeController.text = '${fixed.warningBefore.inDays}';
        fixedDangerBeforeController.text = '${fixed.dangerBefore.inDays}';
      case StateBasedItemConfig state:
        warningAfterController.text = '${state.warningAfter.inDays}';
        dangerAfterController.text = '${state.dangerAfter.inDays}';
    }
  }

  FixedItemConfig _buildFixedConfig({required bool deriveAttentionPolicy}) {
    final anchorDate = derivedFixedAnchorDate;
    final policy = deriveAttentionPolicy
        ? _attentionPolicyResolver.resolveFixed(
            anchorDate: anchorDate,
            dueDate: selectedFixedDueDate,
            tone: reminderTone,
          )
        : null;
    return FixedItemConfig(
      scheduleType: scheduleType,
      scheduleInterval: _usesScheduleInterval(scheduleType)
          ? parsePositiveDays(fixedScheduleIntervalController)
          : 1,
      monthlyDay: scheduleType == FixedScheduleType.monthly
          ? parseMonthlyDay(fixedMonthlyDayController)
          : null,
      repeatRuleV2: fixedRepeatRuleV2,
      anchorDate: anchorDate,
      dueDate: selectedFixedDueDate,
      overduePolicy: overduePolicy,
      infoBefore: fixedInfoBefore,
      warningBefore: Duration(
        days:
            policy?.warningBeforeDays ??
            parseDays(fixedWarningBeforeController),
      ),
      dangerBefore: Duration(
        days:
            policy?.dangerBeforeDays ?? parseDays(fixedDangerBeforeController),
      ),
    );
  }

  void _loadFixedCompletionWindow(FixedItemConfig fixed) {
    final dueDate = fixed.dueDate ?? selectedFixedDueDate;
    final anchorDate = fixed.anchorDate ?? dueDate;
    selectedFixedAnchorDate = anchorDate;
    if (anchorDate.isAfter(dueDate)) {
      fixedCompletionMode = FixedCompletionMode.dueOnly;
      fixedLeadDaysController.text = '1';
      fixedDateWindowNeedsRepair = true;
      return;
    }
    fixedDateWindowNeedsRepair = false;
    final leadDays = dueDate.difference(anchorDate).inDays;
    if (leadDays <= 0) {
      fixedCompletionMode = FixedCompletionMode.dueOnly;
      fixedLeadDaysController.text = '1';
      return;
    }
    fixedCompletionMode = FixedCompletionMode.leadWindow;
    fixedLeadDaysController.text = '$leadDays';
  }

  StateBasedItemConfig _buildStateBasedConfig({
    required bool deriveAttentionPolicy,
  }) {
    final policy = deriveAttentionPolicy
        ? _attentionPolicyResolver.resolveFlexible(
            expectedIntervalDays: parsePositiveDays(
              stateExpectedIntervalController,
            ),
            tone: reminderTone,
          )
        : null;
    return StateBasedItemConfig(
      anchorDate: selectedStateAnchorDate,
      infoAfter: stateInfoAfter,
      warningAfter: Duration(
        days: policy?.warningAfterDays ?? parseDays(warningAfterController),
      ),
      dangerAfter: Duration(
        days: policy?.dangerAfterDays ?? parseDays(dangerAfterController),
      ),
    );
  }

  int parseDays(TextEditingController controller) {
    return int.tryParse(controller.text.trim()) ?? 1;
  }

  int parsePositiveDays(TextEditingController controller) {
    final parsed = int.tryParse(controller.text.trim());
    if (parsed == null || parsed < 1) {
      return 1;
    }
    return parsed;
  }

  int parseMonthlyDay(TextEditingController controller) {
    final parsed = int.tryParse(controller.text.trim());
    if (parsed == null) {
      return 1;
    }
    return parsed.clamp(1, 31);
  }

  bool _usesScheduleInterval(FixedScheduleType type) {
    return type == FixedScheduleType.everyXDays ||
        type == FixedScheduleType.everyXWeeks ||
        type == FixedScheduleType.monthly;
  }

  void setFixedRepeatRule(RepeatRuleV2? rule) {
    fixedRepeatRuleV2 = rule;
    if (rule == null) {
      scheduleType = FixedScheduleType.oneTime;
      fixedScheduleIntervalController.text = '1';
      return;
    }
    final legacy = rule.legacySimpleRule;
    if (legacy == null || !rule.end.isNever) {
      scheduleType = switch (rule.unit) {
        RepeatUnit.day =>
          rule.interval == 1
              ? FixedScheduleType.daily
              : FixedScheduleType.everyXDays,
        RepeatUnit.week =>
          rule.interval == 1
              ? FixedScheduleType.weekly
              : FixedScheduleType.everyXWeeks,
        RepeatUnit.month => FixedScheduleType.monthly,
        RepeatUnit.year => FixedScheduleType.oneTime,
      };
      fixedScheduleIntervalController.text = '${rule.interval}';
      return;
    }
    fixedRepeatRuleV2 = legacy.unit == RepeatUnit.year ? rule : null;
    scheduleType = switch (legacy.unit) {
      RepeatUnit.day =>
        legacy.interval == 1
            ? FixedScheduleType.daily
            : FixedScheduleType.everyXDays,
      RepeatUnit.week =>
        legacy.interval == 1
            ? FixedScheduleType.weekly
            : FixedScheduleType.everyXWeeks,
      RepeatUnit.month => FixedScheduleType.monthly,
      RepeatUnit.year => FixedScheduleType.oneTime,
    };
    fixedScheduleIntervalController.text = '${legacy.interval}';
  }
}

class AttentionPolicyAdvancedSection extends StatelessWidget {
  const AttentionPolicyAdvancedSection({
    super.key,
    required this.controller,
    required this.onChanged,
    this.embedded = false,
  });

  final ItemConfigFormController controller;
  final VoidCallback onChanged;
  final bool embedded;

  @override
  Widget build(BuildContext context) {
    final previewStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
      color: Theme.of(context).colorScheme.onSurfaceVariant,
    );
    if (controller.type == ItemType.fixed) {
      final preview = Text(
        ReminderFormatters.attentionPolicySummary(_previewConfig),
        key: const Key('attention-policy-fixed-preview'),
        style: previewStyle,
      );
      if (embedded) {
        return preview;
      }
      return ExpansionTile(
        key: const Key('attention-policy-advanced-section'),
        tilePadding: EdgeInsets.zero,
        title: const Text(ReminderUiText.attentionPolicyAdvancedTitle),
        subtitle: Text(
          ReminderFormatters.attentionPolicySummary(_previewConfig),
        ),
        children: [preview],
      );
    }
    final content = [
      Text(
        ReminderFormatters.attentionPolicySummary(_previewConfig),
        style: previewStyle,
      ),
      SwitchListTile(
        key: const Key('attention-policy-custom-switch'),
        contentPadding: EdgeInsets.zero,
        title: const Text(ReminderUiText.customAttentionPolicyLabel),
        subtitle: const Text(ReminderUiText.customAttentionPolicyHelp),
        value: controller.customizeAttentionPolicy,
        onChanged: (value) {
          controller.setCustomizeAttentionPolicy(value);
          onChanged();
        },
      ),
      if (controller.customizeAttentionPolicy) ...[
        const SizedBox(height: 8),
        ..._buildRawFields(),
      ],
    ];

    if (embedded) {
      return Column(
        key: const Key('attention-policy-advanced-section-content'),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: content,
      );
    }

    return ExpansionTile(
      key: const Key('attention-policy-advanced-section'),
      tilePadding: EdgeInsets.zero,
      title: const Text(ReminderUiText.attentionPolicyAdvancedTitle),
      subtitle: Text(ReminderFormatters.attentionPolicySummary(_previewConfig)),
      children: content.skip(1).toList(growable: false),
    );
  }

  ItemConfig get _previewConfig =>
      controller.buildConfigForCurrentPolicySource();

  List<Widget> _buildRawFields() {
    return switch (controller.type) {
      ItemType.fixed => [
        ReminderEditorNumberField(
          fieldKey: const Key('attention-warning-field'),
          controller: controller.fixedWarningBeforeController,
          label: ReminderUiText.warningTimingLabel,
          suffixText: '天前',
        ),
        const SizedBox(height: 12),
        ReminderEditorNumberField(
          fieldKey: const Key('attention-danger-field'),
          controller: controller.fixedDangerBeforeController,
          label: ReminderUiText.dangerTimingLabel,
          suffixText: '天前',
        ),
      ],
      ItemType.stateBased => [
        ReminderEditorNumberField(
          fieldKey: const Key('attention-warning-field'),
          controller: controller.warningAfterController,
          label: ReminderUiText.warningTimingLabel,
          suffixText: '天後',
        ),
        const SizedBox(height: 12),
        ReminderEditorNumberField(
          fieldKey: const Key('attention-danger-field'),
          controller: controller.dangerAfterController,
          label: ReminderUiText.dangerTimingLabel,
          suffixText: '天後',
        ),
      ],
    };
  }
}

class ItemConfigFormSection extends StatelessWidget {
  const ItemConfigFormSection({
    super.key,
    required this.controller,
    required this.onChanged,
    this.showAttentionFields = true,
  });

  final ItemConfigFormController controller;
  final VoidCallback onChanged;
  final bool showAttentionFields;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: switch (controller.type) {
        ItemType.fixed => _buildFixedFields(context),
        ItemType.stateBased => _buildStateBasedFields(context),
      },
    );
  }

  List<Widget> _buildFixedFields(BuildContext context) {
    return [
      _RepeatRuleRow(
        rule: ReminderFormatters.repeatRuleV2FromFixedConfig(
          controller.buildConfigForEdit() as FixedItemConfig,
        ),
        onTap: () => _showRepeatRuleSheet(context),
      ),
      const SizedBox(height: 12),
      ReminderEditorDateRow(
        key: const Key('fixed-due-date-row'),
        label: ReminderUiText.fixedDueDateLabel,
        date: controller.selectedFixedDueDate,
        onTap: () => _pickDate(
          context,
          initialDate: controller.selectedFixedDueDate,
          onSelected: (value) {
            controller.setFixedDueDate(value);
            onChanged();
          },
        ),
      ),
      const SizedBox(height: 12),
      _FixedCompletionModeField(
        mode: controller.fixedCompletionMode,
        errorText: controller.fixedDateWindowErrorText,
        onChanged: (value) {
          controller.setFixedCompletionMode(value);
          onChanged();
        },
      ),
      if (controller.fixedCompletionMode == FixedCompletionMode.leadWindow) ...[
        const SizedBox(height: 12),
        ReminderEditorNumberField(
          fieldKey: const Key('fixed-lead-days-field'),
          controller: controller.fixedLeadDaysController,
          label: ReminderUiText.fixedLeadWindowLabel,
          prefixText: '到期前 ',
          suffixText: ReminderUiText.fixedLeadWindowSuffix,
          helperText: ReminderUiText.fixedLeadWindowHelp,
          minimum: 1,
          onChanged: () {
            controller.fixedDateWindowNeedsRepair = false;
            controller.syncDateControllers();
            onChanged();
          },
        ),
      ],
      const SizedBox(height: 12),
      ReminderEditorPickerRow(
        key: const Key('fixed-overdue-policy-row'),
        label: ReminderUiText.overduePolicyLabel,
        value: ReminderFormatters.itemOverduePolicy(controller.overduePolicy),
        onTap: () => _showOverduePolicySheet(context),
      ),
      if (showAttentionFields) ...[
        const SizedBox(height: 12),
        ReminderEditorNumberField(
          fieldKey: const Key('config-warning-timing-field'),
          controller: controller.fixedWarningBeforeController,
          label: ReminderUiText.warningTimingLabel,
          suffixText: '天前',
        ),
        const SizedBox(height: 12),
        ReminderEditorNumberField(
          fieldKey: const Key('config-danger-timing-field'),
          controller: controller.fixedDangerBeforeController,
          label: ReminderUiText.dangerTimingLabel,
          suffixText: '天前',
        ),
      ] else ...[
        const SizedBox(height: 12),
        _AttentionPolicyPreview(config: controller.buildConfigForCreate()),
      ],
    ];
  }

  Future<void> _showOverduePolicySheet(BuildContext context) async {
    final selection = await showModalBottomSheet<ItemOverduePolicy>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          children: [
            Text(
              ReminderUiText.overduePolicyLabel,
              style: Theme.of(sheetContext).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            for (final value in _overduePolicyDisplayOrder)
              ListTile(
                key: Key('overdue-policy-${value.name}'),
                title: Text(ReminderFormatters.itemOverduePolicy(value)),
                trailing: controller.overduePolicy == value
                    ? const Icon(Icons.check)
                    : null,
                onTap: () => Navigator.of(sheetContext).pop(value),
              ),
          ],
        ),
      ),
    );
    if (selection == null || !context.mounted) {
      return;
    }
    controller.overduePolicy = selection;
    onChanged();
  }

  Future<void> _showRepeatRuleSheet(BuildContext context) async {
    final initialRule = ReminderFormatters.repeatRuleV2FromFixedConfig(
      controller.buildConfigForEdit() as FixedItemConfig,
    );
    final selection = await showModalBottomSheet<_RepeatRuleSelection>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => RepeatRuleSheet(
        initialRule: initialRule,
        anchorDate: controller.selectedFixedAnchorDate,
        dueDate: controller.selectedFixedDueDate,
      ),
    );
    if (selection != null && context.mounted) {
      controller.setFixedRepeatRule(selection.rule);
      onChanged();
    }
  }

  static const _overduePolicyDisplayOrder = [
    ItemOverduePolicy.waitForAction,
    ItemOverduePolicy.autoAdvance,
  ];

  List<Widget> _buildStateBasedFields(BuildContext context) {
    return [
      ReminderEditorDateRow(
        key: const Key('state-anchor-date-row'),
        label: ReminderUiText.stateAnchorDateLabel,
        date: controller.selectedStateAnchorDate,
        onTap: () => _pickDate(
          context,
          initialDate: controller.selectedStateAnchorDate,
          onSelected: (value) {
            controller.selectedStateAnchorDate = value;
            controller.syncDateControllers();
            onChanged();
          },
        ),
      ),
      if (showAttentionFields) ...[
        const SizedBox(height: 12),
        ReminderEditorNumberField(
          fieldKey: const Key('config-warning-timing-field'),
          controller: controller.warningAfterController,
          label: ReminderUiText.warningTimingLabel,
          suffixText: '天後',
        ),
        const SizedBox(height: 12),
        ReminderEditorNumberField(
          fieldKey: const Key('config-danger-timing-field'),
          controller: controller.dangerAfterController,
          label: ReminderUiText.dangerTimingLabel,
          suffixText: '天後',
        ),
      ] else ...[
        const SizedBox(height: 12),
        ReminderEditorNumberField(
          fieldKey: const Key('expected-interval-field'),
          controller: controller.stateExpectedIntervalController,
          label: ReminderUiText.expectedIntervalLabel,
          suffixText: '天',
          minimum: 1,
          onChanged: onChanged,
        ),
        const SizedBox(height: 12),
        _AttentionPolicyPreview(config: controller.buildConfigForCreate()),
      ],
    ];
  }

  Future<void> _pickDate(
    BuildContext context, {
    required DateTime initialDate,
    required ValueChanged<DateTime> onSelected,
  }) async {
    final result = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (result == null) {
      return;
    }
    onSelected(DateTime(result.year, result.month, result.day));
  }
}

class _AttentionPolicyPreview extends StatelessWidget {
  const _AttentionPolicyPreview({required this.config});

  final ItemConfig config;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        ReminderFormatters.attentionPolicySummary(config),
        key: const Key('attention-policy-preview'),
        style: Theme.of(context).textTheme.bodyMedium,
      ),
    );
  }
}

class _RepeatRuleSelection {
  const _RepeatRuleSelection(this.rule);

  final RepeatRuleV2? rule;
}

class _RepeatRuleRow extends StatelessWidget {
  const _RepeatRuleRow({required this.rule, required this.onTap});

  final RepeatRuleV2? rule;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ReminderEditorPickerRow(
      key: const Key('fixed-repeat-row'),
      label: ReminderUiText.repeatRuleLabel,
      value: rule == null
          ? ReminderUiText.noRepeatLabel
          : ReminderFormatters.repeatRuleV2Summary(rule),
      onTap: onTap,
    );
  }
}

class _FixedCompletionModeField extends StatelessWidget {
  const _FixedCompletionModeField({
    required this.mode,
    required this.onChanged,
    this.errorText,
  });

  final FixedCompletionMode mode;
  final ValueChanged<FixedCompletionMode> onChanged;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final error = errorText;
    return FormField<FixedCompletionMode>(
      initialValue: mode,
      validator: (_) => error,
      builder: (field) {
        return Column(
          key: const Key('fixed-completion-mode-field'),
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              ReminderUiText.fixedCompletionModeLabel,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            RadioGroup<FixedCompletionMode>(
              groupValue: mode,
              onChanged: (value) {
                if (value != null) {
                  field.didChange(value);
                  onChanged(value);
                }
              },
              child: const Column(
                children: [
                  RadioListTile<FixedCompletionMode>(
                    key: Key('fixed-completion-due-only-option'),
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    title: Text(ReminderUiText.fixedCompletionDueOnlyLabel),
                    value: FixedCompletionMode.dueOnly,
                  ),
                  RadioListTile<FixedCompletionMode>(
                    key: Key('fixed-completion-lead-window-option'),
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    title: Text(ReminderUiText.fixedCompletionLeadWindowLabel),
                    value: FixedCompletionMode.leadWindow,
                  ),
                ],
              ),
            ),
            if (error != null || field.hasError)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  error ?? field.errorText!,
                  key: const Key('fixed-completion-mode-error'),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
