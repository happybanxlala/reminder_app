import 'package:flutter/material.dart';

import '../../domain/attention_policy.dart';
import '../../domain/item.dart';
import '../../presentation/formatters/reminder_formatters.dart';
import '../../presentation/text/reminder_ui_text.dart';
import 'editor_common_fields.dart';

class ItemConfigFormController {
  ItemConfigFormController({
    AttentionPolicyResolver? attentionPolicyResolver,
    this.reminderTone = ReminderTone.standard,
  }) : _attentionPolicyResolver =
           attentionPolicyResolver ?? const AttentionPolicyResolver() {
    fixedAnchorDateController = TextEditingController();
    fixedDueDateController = TextEditingController();
    fixedScheduleIntervalController = TextEditingController(text: '1');
    fixedMonthlyDayController = TextEditingController(text: '1');
    fixedWarningBeforeController = TextEditingController(text: '1');
    fixedDangerBeforeController = TextEditingController(text: '0');
    stateAnchorDateController = TextEditingController();
    stateExpectedIntervalController = TextEditingController(text: '14');
    warningAfterController = TextEditingController(text: '7');
    dangerAfterController = TextEditingController(text: '14');
    resourceAnchorDateController = TextEditingController();
    resourceDurationController = TextEditingController(text: '30');
    resourceWarningBeforeController = TextEditingController(text: '3');
    resourceDangerBeforeController = TextEditingController(text: '0');
    syncDateControllers();
  }

  late final TextEditingController fixedAnchorDateController;
  late final TextEditingController fixedDueDateController;
  late final TextEditingController fixedScheduleIntervalController;
  late final TextEditingController fixedMonthlyDayController;
  late final TextEditingController fixedWarningBeforeController;
  late final TextEditingController fixedDangerBeforeController;
  late final TextEditingController stateAnchorDateController;
  late final TextEditingController stateExpectedIntervalController;
  late final TextEditingController warningAfterController;
  late final TextEditingController dangerAfterController;
  late final TextEditingController resourceAnchorDateController;
  late final TextEditingController resourceDurationController;
  late final TextEditingController resourceWarningBeforeController;
  late final TextEditingController resourceDangerBeforeController;

  final AttentionPolicyResolver _attentionPolicyResolver;
  ReminderTone reminderTone;
  ItemType type = ItemType.stateBased;
  FixedScheduleType scheduleType = FixedScheduleType.daily;
  ItemOverduePolicy overduePolicy = ItemOverduePolicy.autoAdvance;
  UsageSpeed usageSpeed = UsageSpeed.medium;
  bool customizeAttentionPolicy = false;
  DateTime selectedFixedAnchorDate = DateTime.now();
  DateTime selectedFixedDueDate = DateTime.now();
  DateTime selectedStateAnchorDate = DateTime.now();
  DateTime selectedResourceAnchorDate = DateTime.now();
  Duration fixedInfoBefore = Duration.zero;
  Duration stateInfoAfter = Duration.zero;
  int resourceInfoBefore = 0;

  void dispose() {
    fixedAnchorDateController.dispose();
    fixedDueDateController.dispose();
    fixedScheduleIntervalController.dispose();
    fixedMonthlyDayController.dispose();
    fixedWarningBeforeController.dispose();
    fixedDangerBeforeController.dispose();
    stateAnchorDateController.dispose();
    stateExpectedIntervalController.dispose();
    warningAfterController.dispose();
    dangerAfterController.dispose();
    resourceAnchorDateController.dispose();
    resourceDurationController.dispose();
    resourceWarningBeforeController.dispose();
    resourceDangerBeforeController.dispose();
  }

  void load(ItemConfig config) {
    type = config.type;
    switch (config) {
      case FixedItemConfig fixed:
        scheduleType = fixed.scheduleType;
        fixedScheduleIntervalController.text = '${fixed.scheduleInterval}';
        fixedMonthlyDayController.text =
            '${fixed.monthlyDay ?? fixed.dueDate?.day ?? 1}';
        overduePolicy = fixed.overduePolicy;
        selectedFixedAnchorDate = fixed.anchorDate ?? selectedFixedAnchorDate;
        selectedFixedDueDate = fixed.dueDate ?? selectedFixedDueDate;
        fixedInfoBefore = fixed.infoBefore;
        fixedWarningBeforeController.text = '${fixed.warningBefore.inDays}';
        fixedDangerBeforeController.text = '${fixed.dangerBefore.inDays}';
      case StateBasedItemConfig state:
        selectedStateAnchorDate = state.anchorDate ?? selectedStateAnchorDate;
        stateInfoAfter = state.infoAfter;
        stateExpectedIntervalController.text = '${state.dangerAfter.inDays}';
        warningAfterController.text = '${state.warningAfter.inDays}';
        dangerAfterController.text = '${state.dangerAfter.inDays}';
      case ResourceBasedItemConfig resource:
        selectedResourceAnchorDate =
            resource.anchorDate ?? selectedResourceAnchorDate;
        resourceDurationController.text = '${resource.durationDays}';
        resourceInfoBefore = resource.infoBefore;
        resourceWarningBeforeController.text = '${resource.warningBefore}';
        resourceDangerBeforeController.text = '${resource.dangerBefore}';
    }
    syncDateControllers();
  }

  void syncDateControllers() {
    fixedAnchorDateController.text = ReminderFormatters.date(
      selectedFixedAnchorDate,
    );
    fixedDueDateController.text = ReminderFormatters.date(selectedFixedDueDate);
    stateAnchorDateController.text = ReminderFormatters.date(
      selectedStateAnchorDate,
    );
    resourceAnchorDateController.text = ReminderFormatters.date(
      selectedResourceAnchorDate,
    );
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
      ItemType.resourceBased => _buildResourceConfig(
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
      ItemType.resourceBased => _buildResourceConfig(
        deriveAttentionPolicy: false,
      ),
    };
  }

  ItemConfig buildConfigForCurrentPolicySource() {
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
      case ResourceBasedItemConfig resource:
        resourceWarningBeforeController.text = '${resource.warningBefore}';
        resourceDangerBeforeController.text = '${resource.dangerBefore}';
    }
  }

  FixedItemConfig _buildFixedConfig({required bool deriveAttentionPolicy}) {
    final policy = deriveAttentionPolicy
        ? _attentionPolicyResolver.resolveFixed(
            anchorDate: selectedFixedAnchorDate,
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
      anchorDate: selectedFixedAnchorDate,
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

  ResourceBasedItemConfig _buildResourceConfig({
    required bool deriveAttentionPolicy,
  }) {
    final durationDays = parsePositiveDays(resourceDurationController);
    final policy = deriveAttentionPolicy
        ? _attentionPolicyResolver.resolveStock(
            estimatedDurationDays: durationDays,
            usageSpeed: usageSpeed,
            tone: reminderTone,
          )
        : null;
    return ResourceBasedItemConfig(
      anchorDate: selectedResourceAnchorDate,
      durationDays: durationDays,
      infoBefore: resourceInfoBefore,
      warningBefore:
          policy?.warningBeforeDays ??
          parseDays(resourceWarningBeforeController),
      dangerBefore:
          policy?.dangerBeforeDays ?? parseDays(resourceDangerBeforeController),
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
}

class AttentionPolicyAdvancedSection extends StatelessWidget {
  const AttentionPolicyAdvancedSection({
    super.key,
    required this.controller,
    required this.onChanged,
  });

  final ItemConfigFormController controller;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      key: const Key('attention-policy-advanced-section'),
      tilePadding: EdgeInsets.zero,
      title: const Text(ReminderUiText.attentionPolicyAdvancedTitle),
      subtitle: Text(ReminderFormatters.attentionPolicySummary(_previewConfig)),
      children: [
        SwitchListTile(
          key: const Key('attention-policy-custom-switch'),
          contentPadding: EdgeInsets.zero,
          title: const Text(ReminderUiText.attentionPolicyCustomToggleLabel),
          subtitle: const Text(ReminderUiText.attentionPolicyCustomToggleHelp),
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
      ],
    );
  }

  ItemConfig get _previewConfig =>
      controller.buildConfigForCurrentPolicySource();

  List<Widget> _buildRawFields() {
    return switch (controller.type) {
      ItemType.fixed => [
        _DaysField(
          key: const Key('fixed-warning-before-field'),
          controller: controller.fixedWarningBeforeController,
          label: ReminderUiText.warningBeforeDaysFieldLabel,
        ),
        const SizedBox(height: 12),
        _DaysField(
          key: const Key('fixed-danger-before-field'),
          controller: controller.fixedDangerBeforeController,
          label: ReminderUiText.dangerBeforeDaysFieldLabel,
        ),
      ],
      ItemType.stateBased => [
        _DaysField(
          key: const Key('warning-after-field'),
          controller: controller.warningAfterController,
          label: ReminderUiText.warningAfterDaysFieldLabel,
        ),
        const SizedBox(height: 12),
        _DaysField(
          key: const Key('danger-after-field'),
          controller: controller.dangerAfterController,
          label: ReminderUiText.dangerAfterDaysFieldLabel,
        ),
      ],
      ItemType.resourceBased => [
        _DaysField(
          key: const Key('warning-before-depletion-field'),
          controller: controller.resourceWarningBeforeController,
          label: ReminderUiText.warningBeforeDaysFieldLabel,
        ),
        const SizedBox(height: 12),
        _DaysField(
          key: const Key('resource-danger-before-field'),
          controller: controller.resourceDangerBeforeController,
          label: ReminderUiText.dangerBeforeDaysFieldLabel,
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
        ItemType.resourceBased => _buildResourceBasedFields(context),
      },
    );
  }

  List<Widget> _buildFixedFields(BuildContext context) {
    return [
      DropdownButtonFormField<FixedScheduleType>(
        initialValue: controller.scheduleType,
        decoration: const InputDecoration(
          labelText: ReminderUiText.scheduleTypeFieldLabel,
        ),
        items: FixedScheduleType.values
            .map(
              (value) => DropdownMenuItem(
                value: value,
                child: Text(ReminderFormatters.fixedScheduleTypeLabel(value)),
              ),
            )
            .toList(growable: false),
        onChanged: (value) {
          if (value == null) {
            return;
          }
          controller.scheduleType = value;
          onChanged();
        },
      ),
      const SizedBox(height: 12),
      if (_usesScheduleInterval(controller.scheduleType)) ...[
        _DaysField(
          key: const Key('fixed-schedule-interval-field'),
          controller: controller.fixedScheduleIntervalController,
          label: ReminderUiText.scheduleIntervalFieldLabel,
          minimum: 1,
        ),
        const SizedBox(height: 12),
      ],
      if (controller.scheduleType == FixedScheduleType.monthly) ...[
        _DaysField(
          key: const Key('fixed-monthly-day-field'),
          controller: controller.fixedMonthlyDayController,
          label: ReminderUiText.monthlyDayFieldLabel,
          minimum: 1,
          maximum: 31,
        ),
        const SizedBox(height: 12),
      ],
      DropdownButtonFormField<ItemOverduePolicy>(
        initialValue: controller.overduePolicy,
        decoration: const InputDecoration(
          labelText: ReminderUiText.overduePolicyFieldLabel,
        ),
        items: ItemOverduePolicy.values
            .map(
              (value) => DropdownMenuItem(
                value: value,
                child: Text(ReminderFormatters.itemOverduePolicy(value)),
              ),
            )
            .toList(growable: false),
        onChanged: (value) {
          if (value == null) {
            return;
          }
          controller.overduePolicy = value;
          onChanged();
        },
      ),
      const SizedBox(height: 12),
      EditorDateField(
        controller: controller.fixedAnchorDateController,
        label: ReminderUiText.fixedAnchorDateFieldLabel,
        onPickDate: () => _pickDate(
          context,
          initialDate: controller.selectedFixedAnchorDate,
          onSelected: (value) {
            controller.selectedFixedAnchorDate = value;
            controller.syncDateControllers();
            onChanged();
          },
        ),
      ),
      const SizedBox(height: 12),
      EditorDateField(
        controller: controller.fixedDueDateController,
        label: ReminderUiText.fixedDueDateFieldLabel,
        onPickDate: () => _pickDate(
          context,
          initialDate: controller.selectedFixedDueDate,
          onSelected: (value) {
            controller.selectedFixedDueDate = value;
            controller.syncDateControllers();
            onChanged();
          },
        ),
      ),
      if (showAttentionFields) ...[
        const SizedBox(height: 12),
        _DaysField(
          key: const Key('fixed-warning-before-field'),
          controller: controller.fixedWarningBeforeController,
          label: ReminderUiText.warningBeforeDaysFieldLabel,
        ),
        const SizedBox(height: 12),
        _DaysField(
          key: const Key('fixed-danger-before-field'),
          controller: controller.fixedDangerBeforeController,
          label: ReminderUiText.dangerBeforeDaysFieldLabel,
        ),
      ] else ...[
        const SizedBox(height: 12),
        _AttentionPolicyPreview(config: controller.buildConfigForCreate()),
      ],
    ];
  }

  bool _usesScheduleInterval(FixedScheduleType type) {
    return type == FixedScheduleType.everyXDays ||
        type == FixedScheduleType.everyXWeeks ||
        type == FixedScheduleType.monthly;
  }

  List<Widget> _buildStateBasedFields(BuildContext context) {
    return [
      EditorDateField(
        key: const Key('state-anchor-date-field'),
        controller: controller.stateAnchorDateController,
        label: ReminderUiText.stateAnchorDateFieldLabel,
        onPickDate: () => _pickDate(
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
        _DaysField(
          key: const Key('warning-after-field'),
          controller: controller.warningAfterController,
          label: ReminderUiText.warningAfterDaysFieldLabel,
        ),
        const SizedBox(height: 12),
        _DaysField(
          key: const Key('danger-after-field'),
          controller: controller.dangerAfterController,
          label: ReminderUiText.dangerAfterDaysFieldLabel,
        ),
      ] else ...[
        const SizedBox(height: 12),
        _DaysField(
          key: const Key('expected-interval-field'),
          controller: controller.stateExpectedIntervalController,
          label: ReminderUiText.expectedIntervalDaysFieldLabel,
          minimum: 1,
        ),
        const SizedBox(height: 12),
        _AttentionPolicyPreview(config: controller.buildConfigForCreate()),
      ],
    ];
  }

  List<Widget> _buildResourceBasedFields(BuildContext context) {
    return [
      EditorDateField(
        controller: controller.resourceAnchorDateController,
        label: ReminderUiText.resourceAnchorDateFieldLabel,
        onPickDate: () => _pickDate(
          context,
          initialDate: controller.selectedResourceAnchorDate,
          onSelected: (value) {
            controller.selectedResourceAnchorDate = value;
            controller.syncDateControllers();
            onChanged();
          },
        ),
      ),
      const SizedBox(height: 12),
      _DaysField(
        key: const Key('estimated-duration-field'),
        controller: controller.resourceDurationController,
        label: ReminderUiText.durationDaysFieldLabel,
        minimum: 1,
      ),
      if (showAttentionFields) ...[
        const SizedBox(height: 12),
        _DaysField(
          key: const Key('warning-before-depletion-field'),
          controller: controller.resourceWarningBeforeController,
          label: ReminderUiText.warningBeforeDaysFieldLabel,
        ),
        const SizedBox(height: 12),
        _DaysField(
          key: const Key('resource-danger-before-field'),
          controller: controller.resourceDangerBeforeController,
          label: ReminderUiText.dangerBeforeDaysFieldLabel,
        ),
      ] else ...[
        const SizedBox(height: 12),
        DropdownButtonFormField<UsageSpeed>(
          key: const Key('usage-speed-field'),
          initialValue: controller.usageSpeed,
          decoration: const InputDecoration(
            labelText: ReminderUiText.usageSpeedFieldLabel,
          ),
          items: UsageSpeed.values
              .map(
                (value) => DropdownMenuItem(
                  value: value,
                  child: Text(ReminderFormatters.usageSpeed(value)),
                ),
              )
              .toList(growable: false),
          onChanged: (value) {
            if (value == null) {
              return;
            }
            controller.usageSpeed = value;
            onChanged();
          },
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

class _DaysField extends StatelessWidget {
  const _DaysField({
    super.key,
    required this.controller,
    required this.label,
    this.minimum = 0,
    this.maximum,
  });

  final TextEditingController controller;
  final String label;
  final int minimum;
  final int? maximum;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(labelText: label),
      validator: (value) {
        final parsed = int.tryParse((value ?? '').trim());
        if (parsed == null || parsed < minimum) {
          return minimum <= 0 ? '請輸入 0 或以上整數' : '請輸入 $minimum 或以上整數';
        }
        if (maximum != null && parsed > maximum!) {
          return '請輸入 $maximum 或以下整數';
        }
        return null;
      },
    );
  }
}
