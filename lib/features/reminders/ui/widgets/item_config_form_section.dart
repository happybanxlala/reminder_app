import 'package:flutter/material.dart';

import '../../domain/attention_policy.dart';
import '../../domain/item.dart';
import '../../domain/repeat_rule.dart';
import '../../domain/repeat_rule_v2.dart';
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

  final AttentionPolicyResolver _attentionPolicyResolver;
  ReminderTone reminderTone;
  ItemType type = ItemType.stateBased;
  FixedScheduleType scheduleType = FixedScheduleType.daily;
  RepeatRuleV2? fixedRepeatRuleV2;
  ItemOverduePolicy overduePolicy = ItemOverduePolicy.autoAdvance;
  bool customizeAttentionPolicy = false;
  DateTime selectedFixedAnchorDate = DateTime.now();
  DateTime selectedFixedDueDate = DateTime.now();
  DateTime selectedStateAnchorDate = DateTime.now();
  Duration fixedInfoBefore = Duration.zero;
  Duration stateInfoAfter = Duration.zero;

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
      repeatRuleV2: fixedRepeatRuleV2,
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
    return Card(
      margin: EdgeInsets.zero,
      child: ListTile(
        key: const Key('fixed-repeat-row'),
        title: const Text('重複'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              ReminderFormatters.repeatRuleV2Summary(rule),
              key: const Key('fixed-repeat-summary'),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right),
          ],
        ),
        onTap: onTap,
      ),
    );
  }
}

class RepeatRuleSheet extends StatefulWidget {
  const RepeatRuleSheet({
    super.key,
    required this.initialRule,
    required this.anchorDate,
    required this.dueDate,
  });

  final RepeatRuleV2? initialRule;
  final DateTime anchorDate;
  final DateTime dueDate;

  @override
  State<RepeatRuleSheet> createState() => _RepeatRuleSheetState();
}

class _RepeatRuleSheetState extends State<RepeatRuleSheet> {
  late bool _isCustom;
  late RepeatUnit _unit;
  late int _interval;
  late Set<int> _weekdays;
  late Set<int> _monthDays;
  late MonthlyRepeatMode _monthlyMode;
  late MonthlyWeekOrdinal _monthlyOrdinal;
  late int _monthlyWeekday;
  late RepeatEndType _endType;
  late DateTime _endDate;
  late int _endCount;

  @override
  void initState() {
    super.initState();
    final rule = widget.initialRule;
    _isCustom = false;
    _unit = rule?.unit ?? RepeatUnit.day;
    _interval = rule?.interval ?? 1;
    _weekdays = (rule?.weekdays.isNotEmpty ?? false)
        ? rule!.weekdays.toSet()
        : {widget.dueDate.weekday};
    _monthDays = (rule?.monthDays.isNotEmpty ?? false)
        ? rule!.monthDays.toSet()
        : {widget.dueDate.day.clamp(1, 31)};
    _monthlyMode = rule?.kind == RepeatRuleV2Kind.monthlyNthWeekday
        ? MonthlyRepeatMode.nthWeekday
        : MonthlyRepeatMode.dates;
    _monthlyOrdinal =
        rule?.monthlyWeekOrdinal ?? _ordinalForDate(widget.dueDate);
    _monthlyWeekday = rule?.monthlyWeekday ?? widget.dueDate.weekday;
    _endType = rule?.end.type ?? RepeatEndType.never;
    _endDate =
        rule?.end.untilDate ??
        DateTime(
          widget.dueDate.year,
          widget.dueDate.month + 1,
          widget.dueDate.day,
        );
    _endCount = rule?.end.occurrenceCount ?? 10;
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          bottom: MediaQuery.viewInsetsOf(context).bottom + 16,
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 180),
          child: _isCustom
              ? _buildCustom(context)
              : _buildQuickOptions(context),
        ),
      ),
    );
  }

  Widget _buildQuickOptions(BuildContext context) {
    final options = <_QuickRepeatOption>[
      const _QuickRepeatOption(label: '永不', keyValue: 'never', rule: null),
      _QuickRepeatOption(
        label: '每天',
        keyValue: 'daily',
        rule: RepeatRuleV2.simple(unit: RepeatUnit.day, interval: 1),
      ),
      _QuickRepeatOption(
        label: '每週',
        keyValue: 'weekly',
        rule: RepeatRuleV2.simple(unit: RepeatUnit.week, interval: 1),
      ),
      _QuickRepeatOption(
        label: '每月',
        keyValue: 'monthly',
        rule: RepeatRuleV2.simple(unit: RepeatUnit.month, interval: 1),
      ),
      _QuickRepeatOption(
        label: '每年',
        keyValue: 'yearly',
        rule: RepeatRuleV2.simple(unit: RepeatUnit.year, interval: 1),
      ),
    ];
    return Column(
      key: const ValueKey('quick-repeat-options'),
      mainAxisSize: MainAxisSize.min,
      children: [
        _SheetHeader(title: '重複', onBack: null),
        Card(
          margin: EdgeInsets.zero,
          child: Column(
            children: [
              for (final option in options)
                _RepeatOptionTile(
                  key: Key('repeat-option-${option.keyValue}'),
                  label: option.label,
                  selected: _matchesQuickOption(option.rule),
                  onTap: () => Navigator.of(
                    context,
                  ).pop(_RepeatRuleSelection(option.rule)),
                ),
              const Divider(height: 1),
              ListTile(
                key: const Key('repeat-option-custom'),
                title: const Text('自訂…'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => setState(() {
                  _isCustom = true;
                }),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCustom(BuildContext context) {
    final rule = _buildCurrentRule();
    return Column(
      key: const ValueKey('custom-repeat-options'),
      mainAxisSize: MainAxisSize.min,
      children: [
        _SheetHeader(
          title: '自訂重複',
          onBack: () => setState(() {
            _isCustom = false;
          }),
        ),
        Flexible(
          child: SingleChildScrollView(
            child: Column(
              children: [
                Card(
                  margin: EdgeInsets.zero,
                  child: Column(
                    children: [
                      ListTile(
                        title: const Text('頻率'),
                        trailing: DropdownButton<RepeatUnit>(
                          key: const Key('repeat-frequency-field'),
                          value: _unit,
                          items: const [
                            DropdownMenuItem(
                              value: RepeatUnit.day,
                              child: Text('每天'),
                            ),
                            DropdownMenuItem(
                              value: RepeatUnit.week,
                              child: Text('每週'),
                            ),
                            DropdownMenuItem(
                              value: RepeatUnit.month,
                              child: Text('每月'),
                            ),
                            DropdownMenuItem(
                              value: RepeatUnit.year,
                              child: Text('每年'),
                            ),
                          ],
                          onChanged: (value) {
                            if (value == null) {
                              return;
                            }
                            setState(() {
                              _unit = value;
                            });
                          },
                        ),
                      ),
                      const Divider(height: 1),
                      _StepperTile(
                        value: _interval,
                        unitLabel: _unitLabel(_unit),
                        onChanged: (value) => setState(() {
                          _interval = value;
                        }),
                      ),
                    ],
                  ),
                ),
                if (_unit == RepeatUnit.week) ...[
                  const SizedBox(height: 12),
                  _WeekdaySection(
                    selected: _weekdays,
                    onChanged: (value) => setState(() {
                      _weekdays = value;
                    }),
                  ),
                ],
                if (_unit == RepeatUnit.month) ...[
                  const SizedBox(height: 12),
                  _MonthlySection(
                    mode: _monthlyMode,
                    monthDays: _monthDays,
                    ordinal: _monthlyOrdinal,
                    weekday: _monthlyWeekday,
                    onModeChanged: (value) => setState(() {
                      _monthlyMode = value;
                    }),
                    onMonthDaysChanged: (value) => setState(() {
                      _monthDays = value;
                    }),
                    onOrdinalChanged: (value) => setState(() {
                      _monthlyOrdinal = value;
                    }),
                    onWeekdayChanged: (value) => setState(() {
                      _monthlyWeekday = value;
                    }),
                  ),
                ],
                const SizedBox(height: 12),
                _EndRepeatSection(
                  endType: _endType,
                  endDate: _endDate,
                  endCount: _endCount,
                  onEndTypeChanged: (value) => setState(() {
                    _endType = value;
                  }),
                  onEndDateChanged: (value) => setState(() {
                    _endDate = value;
                  }),
                  onEndCountChanged: (value) => setState(() {
                    _endCount = value;
                  }),
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    ReminderFormatters.repeatRuleV2Description(rule),
                    key: const Key('repeat-description'),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            key: const Key('repeat-save-custom'),
            onPressed: () =>
                Navigator.of(context).pop(_RepeatRuleSelection(rule)),
            child: const Text('完成'),
          ),
        ),
      ],
    );
  }

  bool _matchesQuickOption(RepeatRuleV2? rule) {
    final initial = widget.initialRule;
    if (initial == null || rule == null) {
      return initial == null && rule == null;
    }
    return initial.kind == RepeatRuleV2Kind.simple &&
        initial.unit == rule.unit &&
        initial.interval == rule.interval &&
        initial.end.isNever;
  }

  RepeatRuleV2 _buildCurrentRule() {
    final end = _buildEndCondition();
    return switch (_unit) {
      RepeatUnit.day => RepeatRuleV2.simple(
        unit: RepeatUnit.day,
        interval: _interval,
        end: end,
      ),
      RepeatUnit.week => RepeatRuleV2.weeklyWeekdays(
        interval: _interval,
        weekdays: _weekdays,
        end: end,
      ),
      RepeatUnit.month =>
        _monthlyMode == MonthlyRepeatMode.dates
            ? RepeatRuleV2.monthlyDates(
                interval: _interval,
                monthDays: _monthDays,
                end: end,
              )
            : RepeatRuleV2.monthlyNthWeekday(
                interval: _interval,
                ordinal: _monthlyOrdinal,
                weekday: _monthlyWeekday,
                end: end,
              ),
      RepeatUnit.year => RepeatRuleV2.simple(
        unit: RepeatUnit.year,
        interval: _interval,
        end: end,
      ),
    };
  }

  RepeatEndCondition _buildEndCondition() {
    return switch (_endType) {
      RepeatEndType.never => const RepeatEndCondition.never(),
      RepeatEndType.onDate => RepeatEndCondition.onDate(_endDate),
      RepeatEndType.afterCount => RepeatEndCondition.afterCount(_endCount),
    };
  }

  String _unitLabel(RepeatUnit unit) {
    return switch (unit) {
      RepeatUnit.day => '天',
      RepeatUnit.week => '週',
      RepeatUnit.month => '個月',
      RepeatUnit.year => '年',
    };
  }

  MonthlyWeekOrdinal _ordinalForDate(DateTime value) {
    final ordinal = ((value.day - 1) ~/ 7) + 1;
    return switch (ordinal) {
      1 => MonthlyWeekOrdinal.first,
      2 => MonthlyWeekOrdinal.second,
      3 => MonthlyWeekOrdinal.third,
      4 => MonthlyWeekOrdinal.fourth,
      _ => MonthlyWeekOrdinal.last,
    };
  }
}

class _QuickRepeatOption {
  const _QuickRepeatOption({
    required this.label,
    required this.keyValue,
    required this.rule,
  });

  final String label;
  final String keyValue;
  final RepeatRuleV2? rule;
}

class _SheetHeader extends StatelessWidget {
  const _SheetHeader({required this.title, required this.onBack});

  final String title;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          if (onBack != null)
            IconButton(
              onPressed: onBack,
              icon: const Icon(Icons.chevron_left),
              tooltip: MaterialLocalizations.of(context).backButtonTooltip,
            )
          else
            const SizedBox(width: 48),
          Expanded(
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }
}

class _RepeatOptionTile extends StatelessWidget {
  const _RepeatOptionTile({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(label),
      trailing: selected ? const Icon(Icons.check) : null,
      onTap: onTap,
    );
  }
}

class _StepperTile extends StatelessWidget {
  const _StepperTile({
    required this.value,
    required this.unitLabel,
    required this.onChanged,
  });

  final int value;
  final String unitLabel;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: const Text('每'),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton.outlined(
            key: const Key('repeat-interval-decrement'),
            onPressed: value <= 1 ? null : () => onChanged(value - 1),
            icon: const Icon(Icons.remove),
            tooltip: '減少',
          ),
          SizedBox(
            width: 88,
            child: Text(
              '$value $unitLabel',
              key: const Key('repeat-interval-value'),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          IconButton.outlined(
            key: const Key('repeat-interval-increment'),
            onPressed: () => onChanged(value + 1),
            icon: const Icon(Icons.add),
            tooltip: '增加',
          ),
        ],
      ),
    );
  }
}

class _WeekdaySection extends StatelessWidget {
  const _WeekdaySection({required this.selected, required this.onChanged});

  final Set<int> selected;
  final ValueChanged<Set<int>> onChanged;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('星期', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final weekday in _weekdays)
                  FilterChip(
                    key: Key('repeat-weekday-$weekday'),
                    label: Text(_shortWeekday(weekday)),
                    selected: selected.contains(weekday),
                    onSelected: (value) {
                      final next = {...selected};
                      if (value) {
                        next.add(weekday);
                      } else if (next.length > 1) {
                        next.remove(weekday);
                      }
                      onChanged(next);
                    },
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MonthlySection extends StatelessWidget {
  const _MonthlySection({
    required this.mode,
    required this.monthDays,
    required this.ordinal,
    required this.weekday,
    required this.onModeChanged,
    required this.onMonthDaysChanged,
    required this.onOrdinalChanged,
    required this.onWeekdayChanged,
  });

  final MonthlyRepeatMode mode;
  final Set<int> monthDays;
  final MonthlyWeekOrdinal ordinal;
  final int weekday;
  final ValueChanged<MonthlyRepeatMode> onModeChanged;
  final ValueChanged<Set<int>> onMonthDaysChanged;
  final ValueChanged<MonthlyWeekOrdinal> onOrdinalChanged;
  final ValueChanged<int> onWeekdayChanged;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SegmentedButton<MonthlyRepeatMode>(
              key: const Key('repeat-monthly-mode'),
              segments: const [
                ButtonSegment(
                  value: MonthlyRepeatMode.dates,
                  label: Text('日期'),
                ),
                ButtonSegment(
                  value: MonthlyRepeatMode.nthWeekday,
                  label: Text('星期…'),
                ),
              ],
              selected: {mode},
              onSelectionChanged: (value) => onModeChanged(value.single),
            ),
            const SizedBox(height: 12),
            if (mode == MonthlyRepeatMode.dates)
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (var day = 1; day <= 31; day += 1)
                    FilterChip(
                      key: Key('repeat-month-day-$day'),
                      label: Text('$day'),
                      selected: monthDays.contains(day),
                      onSelected: (value) {
                        final next = {...monthDays};
                        if (value) {
                          next.add(day);
                        } else if (next.length > 1) {
                          next.remove(day);
                        }
                        onMonthDaysChanged(next);
                      },
                    ),
                ],
              )
            else
              Row(
                children: [
                  Expanded(
                    child: DropdownButton<MonthlyWeekOrdinal>(
                      key: const Key('repeat-monthly-ordinal'),
                      value: ordinal,
                      isExpanded: true,
                      items: MonthlyWeekOrdinal.values
                          .map(
                            (value) => DropdownMenuItem(
                              value: value,
                              child: Text(_ordinalLabel(value)),
                            ),
                          )
                          .toList(growable: false),
                      onChanged: (value) {
                        if (value != null) {
                          onOrdinalChanged(value);
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButton<int>(
                      key: const Key('repeat-monthly-weekday'),
                      value: weekday,
                      isExpanded: true,
                      items: _weekdays
                          .map(
                            (value) => DropdownMenuItem(
                              value: value,
                              child: Text(_weekday(value)),
                            ),
                          )
                          .toList(growable: false),
                      onChanged: (value) {
                        if (value != null) {
                          onWeekdayChanged(value);
                        }
                      },
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _EndRepeatSection extends StatelessWidget {
  const _EndRepeatSection({
    required this.endType,
    required this.endDate,
    required this.endCount,
    required this.onEndTypeChanged,
    required this.onEndDateChanged,
    required this.onEndCountChanged,
  });

  final RepeatEndType endType;
  final DateTime endDate;
  final int endCount;
  final ValueChanged<RepeatEndType> onEndTypeChanged;
  final ValueChanged<DateTime> onEndDateChanged;
  final ValueChanged<int> onEndCountChanged;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Column(
        children: [
          ListTile(
            title: const Text('結束重複'),
            trailing: DropdownButton<RepeatEndType>(
              key: const Key('repeat-end-type'),
              value: endType,
              items: const [
                DropdownMenuItem(value: RepeatEndType.never, child: Text('永不')),
                DropdownMenuItem(
                  value: RepeatEndType.onDate,
                  child: Text('指定日期'),
                ),
                DropdownMenuItem(
                  value: RepeatEndType.afterCount,
                  child: Text('重複次數'),
                ),
              ],
              onChanged: (value) {
                if (value != null) {
                  onEndTypeChanged(value);
                }
              },
            ),
          ),
          if (endType == RepeatEndType.onDate) ...[
            const Divider(height: 1),
            ListTile(
              key: const Key('repeat-end-date-row'),
              title: const Text('直到'),
              trailing: Text(ReminderFormatters.date(endDate)),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: endDate,
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2035),
                );
                if (picked != null) {
                  onEndDateChanged(
                    DateTime(picked.year, picked.month, picked.day),
                  );
                }
              },
            ),
          ],
          if (endType == RepeatEndType.afterCount) ...[
            const Divider(height: 1),
            _StepperTile(
              value: endCount,
              unitLabel: '次',
              onChanged: onEndCountChanged,
            ),
          ],
        ],
      ),
    );
  }
}

const _weekdays = <int>[
  DateTime.monday,
  DateTime.tuesday,
  DateTime.wednesday,
  DateTime.thursday,
  DateTime.friday,
  DateTime.saturday,
  DateTime.sunday,
];

String _shortWeekday(int weekday) {
  return switch (weekday) {
    DateTime.monday => '一',
    DateTime.tuesday => '二',
    DateTime.wednesday => '三',
    DateTime.thursday => '四',
    DateTime.friday => '五',
    DateTime.saturday => '六',
    DateTime.sunday => '日',
    _ => '一',
  };
}

String _weekday(int weekday) {
  return '星期${_shortWeekday(weekday)}';
}

String _ordinalLabel(MonthlyWeekOrdinal ordinal) {
  return switch (ordinal) {
    MonthlyWeekOrdinal.first => '第一個',
    MonthlyWeekOrdinal.second => '第二個',
    MonthlyWeekOrdinal.third => '第三個',
    MonthlyWeekOrdinal.fourth => '第四個',
    MonthlyWeekOrdinal.fifth => '第五個',
    MonthlyWeekOrdinal.last => '最後一個',
  };
}

class _DaysField extends StatelessWidget {
  const _DaysField({
    super.key,
    required this.controller,
    required this.label,
    this.minimum = 0,
  });

  final TextEditingController controller;
  final String label;
  final int minimum;

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
        return null;
      },
    );
  }
}
