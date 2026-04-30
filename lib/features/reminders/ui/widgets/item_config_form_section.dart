import 'package:flutter/material.dart';

import '../../domain/item.dart';
import '../../presentation/formatters/reminder_formatters.dart';
import '../../presentation/text/reminder_ui_text.dart';
import 'editor_common_fields.dart';

class ItemConfigFormController {
  ItemConfigFormController() {
    fixedAnchorDateController = TextEditingController();
    fixedDueDateController = TextEditingController();
    fixedWarningBeforeController = TextEditingController(text: '1');
    fixedDangerBeforeController = TextEditingController(text: '0');
    stateAnchorDateController = TextEditingController();
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
  late final TextEditingController fixedWarningBeforeController;
  late final TextEditingController fixedDangerBeforeController;
  late final TextEditingController stateAnchorDateController;
  late final TextEditingController warningAfterController;
  late final TextEditingController dangerAfterController;
  late final TextEditingController resourceAnchorDateController;
  late final TextEditingController resourceDurationController;
  late final TextEditingController resourceWarningBeforeController;
  late final TextEditingController resourceDangerBeforeController;

  ItemType type = ItemType.stateBased;
  FixedScheduleType scheduleType = FixedScheduleType.daily;
  ItemOverduePolicy overduePolicy = ItemOverduePolicy.autoAdvance;
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
    fixedWarningBeforeController.dispose();
    fixedDangerBeforeController.dispose();
    stateAnchorDateController.dispose();
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
        overduePolicy = fixed.overduePolicy;
        selectedFixedAnchorDate = fixed.anchorDate ?? selectedFixedAnchorDate;
        selectedFixedDueDate = fixed.dueDate ?? selectedFixedDueDate;
        fixedInfoBefore = fixed.infoBefore;
        fixedWarningBeforeController.text = '${fixed.warningBefore.inDays}';
        fixedDangerBeforeController.text = '${fixed.dangerBefore.inDays}';
      case StateBasedItemConfig state:
        selectedStateAnchorDate = state.anchorDate ?? selectedStateAnchorDate;
        stateInfoAfter = state.infoAfter;
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
    return switch (type) {
      ItemType.fixed => FixedItemConfig(
        scheduleType: scheduleType,
        anchorDate: selectedFixedAnchorDate,
        dueDate: selectedFixedDueDate,
        overduePolicy: overduePolicy,
        infoBefore: fixedInfoBefore,
        warningBefore: Duration(days: parseDays(fixedWarningBeforeController)),
        dangerBefore: Duration(days: parseDays(fixedDangerBeforeController)),
      ),
      ItemType.stateBased => StateBasedItemConfig(
        anchorDate: selectedStateAnchorDate,
        infoAfter: stateInfoAfter,
        warningAfter: Duration(days: parseDays(warningAfterController)),
        dangerAfter: Duration(days: parseDays(dangerAfterController)),
      ),
      ItemType.resourceBased => ResourceBasedItemConfig(
        anchorDate: selectedResourceAnchorDate,
        durationDays: parseDays(resourceDurationController),
        infoBefore: resourceInfoBefore,
        warningBefore: parseDays(resourceWarningBeforeController),
        dangerBefore: parseDays(resourceDangerBeforeController),
      ),
    };
  }

  int parseDays(TextEditingController controller) {
    return int.tryParse(controller.text.trim()) ?? 1;
  }
}

class ItemConfigFormSection extends StatelessWidget {
  const ItemConfigFormSection({
    super.key,
    required this.controller,
    required this.onChanged,
  });

  final ItemConfigFormController controller;
  final VoidCallback onChanged;

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
    ];
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
      ),
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

class _DaysField extends StatelessWidget {
  const _DaysField({super.key, required this.controller, required this.label});

  final TextEditingController controller;
  final String label;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(labelText: label),
      validator: (value) {
        final parsed = int.tryParse((value ?? '').trim());
        if (parsed == null || parsed < 0) {
          return '請輸入 0 或以上整數';
        }
        return null;
      },
    );
  }
}
