import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/local/task_timeline_dao.dart';
import '../../data/task_repository.dart';
import '../../domain/reminder_rule.dart';
import '../../domain/repeat_rule.dart';
import '../../domain/task_template.dart';
import '../../presentation/formatters/reminder_formatters.dart';
import '../../presentation/text/reminder_ui_text.dart';
import '../../providers/task_providers.dart';
import '../widgets/editor_common_fields.dart';

enum TaskEditMode { taskCreate, taskTemplateCreate, taskTemplateEdit, taskEdit }

class TaskEditPage extends ConsumerStatefulWidget {
  const TaskEditPage({super.key, required this.mode, this.id});

  static const taskNewRouteName = 'task-new';
  static const taskNewRoutePath = '/task/new';
  static const taskTemplateNewRouteName = 'task-template-new';
  static const taskTemplateNewRoutePath = '/task-template/new';
  static const taskTemplateEditRouteName = 'task-template-edit';
  static const taskTemplateEditRoutePath = '/task-template/:id';
  static const taskEditRouteName = 'task-edit';
  static const taskEditRoutePath = '/task/:id';

  final TaskEditMode mode;
  final int? id;

  @override
  ConsumerState<TaskEditPage> createState() => _TaskEditPageState();
}

class _TaskEditPageState extends ConsumerState<TaskEditPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _noteController;
  late final TextEditingController _dateController;
  late final TextEditingController _intervalController;
  late final TextEditingController _offsetController;

  DateTime _selectedDate = DateTime.now();
  bool _recurring = false;
  RepeatUnit _repeatUnit = RepeatUnit.week;
  ReminderRuleType _reminderRuleType = ReminderRuleType.onDue;
  bool _initialized = false;

  bool get _isDirectTaskCreate => widget.mode == TaskEditMode.taskCreate;
  bool get _isTaskCreate =>
      widget.mode == TaskEditMode.taskCreate ||
      widget.mode == TaskEditMode.taskTemplateCreate;
  bool get _isTaskTemplateEdit => widget.mode == TaskEditMode.taskTemplateEdit;
  bool get _isTaskTemplateFlow => _isTaskCreate || _isTaskTemplateEdit;
  bool get _isTaskEdit => widget.mode == TaskEditMode.taskEdit;
  bool get _showOffsetField => _reminderRuleType == ReminderRuleType.advance;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _noteController = TextEditingController();
    _dateController = TextEditingController();
    _intervalController = TextEditingController(text: '1');
    _offsetController = TextEditingController(text: '0');
    _recurring = !_isDirectTaskCreate;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _noteController.dispose();
    _dateController.dispose();
    _intervalController.dispose();
    _offsetController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final taskTemplateAsync = _isTaskTemplateEdit && widget.id != null
        ? ref.watch(taskTemplateProvider(widget.id!))
        : const AsyncData<TaskTemplate?>(null);
    final taskAsync = _isTaskEdit && widget.id != null
        ? ref.watch(taskBundleProvider(widget.id!))
        : const AsyncData<TaskBundle?>(null);

    if (taskTemplateAsync.isLoading || taskAsync.isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text(_pageTitle)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    _initializeIfNeeded(
      taskTemplate: taskTemplateAsync.valueOrNull,
      taskBundle: taskAsync.valueOrNull,
    );

    return Scaffold(
      appBar: AppBar(title: Text(_pageTitle)),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            EditorTitleField(
              controller: _titleController,
              enabled: !_isTaskEdit,
            ),
            if (!_isTaskEdit) ...[
              const SizedBox(height: 12),
              EditorNoteField(controller: _noteController),
            ],
            const SizedBox(height: 12),
            EditorDateField(
              controller: _dateController,
              label: 'Due Date',
              onPickDate: () => _pickDate(
                initial: _selectedDate,
                onPicked: (value) {
                  setState(() {
                    _selectedDate = value;
                    _dateController.text = ReminderFormatters.date(value);
                  });
                },
              ),
            ),
            if (_isTaskTemplateFlow) ...[
              const SizedBox(height: 12),
              _TaskScheduleSection(
                recurring: _recurring,
                isDirectTaskCreate: _isDirectTaskCreate,
                repeatUnit: _repeatUnit,
                repeatIntervalController: _intervalController,
                reminderRuleType: _reminderRuleType,
                offsetController: _offsetController,
                showOffsetField: _showOffsetField,
                onRecurringChanged: (value) {
                  setState(() {
                    _recurring = value;
                  });
                },
                onRepeatUnitChanged: (value) {
                  if (value == null) {
                    return;
                  }
                  setState(() {
                    _repeatUnit = value;
                  });
                },
                onReminderRuleTypeChanged: (value) {
                  if (value == null) {
                    return;
                  }
                  setState(() {
                    _reminderRuleType = value;
                  });
                },
                validateOffsetDays: _validateOffsetDays,
              ),
            ],
            const SizedBox(height: 24),
            FilledButton(
              key: const Key('save-button'),
              onPressed: _save,
              child: const Text(ReminderUiText.saveAction),
            ),
          ],
        ),
      ),
    );
  }

  String get _pageTitle {
    return switch (widget.mode) {
      TaskEditMode.taskCreate => ReminderUiText.addTask,
      TaskEditMode.taskTemplateCreate => ReminderUiText.addTaskTemplate,
      TaskEditMode.taskTemplateEdit => ReminderUiText.editTaskTemplate,
      TaskEditMode.taskEdit => ReminderUiText.editTask,
    };
  }

  void _initializeIfNeeded({
    required TaskTemplate? taskTemplate,
    required TaskBundle? taskBundle,
  }) {
    if (_initialized) {
      return;
    }
    if (taskTemplate != null) {
      _titleController.text = taskTemplate.title;
      _noteController.text = taskTemplate.note ?? '';
      _selectedDate = taskTemplate.firstDueDate;
      _dateController.text = ReminderFormatters.date(taskTemplate.firstDueDate);
      _recurring = taskTemplate.kind == TaskKind.recurring;
      if (taskTemplate.repeatRule != null) {
        _repeatUnit = taskTemplate.repeatRule!.unit;
        _intervalController.text = '${taskTemplate.repeatRule!.interval}';
      }
      _reminderRuleType = taskTemplate.reminderRule.type;
      _offsetController.text = '${taskTemplate.reminderRule.offsetDays ?? 0}';
    } else if (taskBundle != null) {
      _titleController.text = taskBundle.task.titleSnapshot;
      _selectedDate = taskBundle.task.effectiveDueDate;
      _dateController.text = ReminderFormatters.date(
        taskBundle.task.effectiveDueDate,
      );
    } else {
      _dateController.text = ReminderFormatters.date(_selectedDate);
    }
    _initialized = true;
  }

  Future<void> _pickDate({
    required DateTime initial,
    required ValueChanged<DateTime> onPicked,
  }) async {
    final result = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (result == null) {
      return;
    }
    onPicked(DateTime(result.year, result.month, result.day));
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final repository = ref.read(taskRepositoryProvider);
    final reminderRule = switch (_reminderRuleType) {
      ReminderRuleType.advance => ReminderRule.advance(
        int.parse(_offsetController.text),
      ),
      ReminderRuleType.onDue => const ReminderRule.onDue(),
      ReminderRuleType.immediate => const ReminderRule.immediate(),
    };

    if (_isTaskTemplateFlow) {
      if (_isDirectTaskCreate && !_recurring) {
        await repository.createStandaloneTask(
          TaskInput(
            title: _titleController.text.trim(),
            note: _normalizeOptionalText(_noteController.text),
            dueDate: _selectedDate,
            reminderRule: reminderRule,
          ),
        );
      } else {
        final input = TaskTemplateInput(
          title: _titleController.text.trim(),
          note: _normalizeOptionalText(_noteController.text),
          kind: TaskKind.recurring,
          firstDueDate: _selectedDate,
          repeatRule: RepeatRule(
            unit: _repeatUnit,
            interval: int.tryParse(_intervalController.text) ?? 1,
          ),
          reminderRule: reminderRule,
        );

        if (_isTaskTemplateEdit) {
          await repository.updateTemplate(widget.id!, input);
        } else {
          await repository.createTemplateWithFirstTask(input);
        }
      }
    } else if (_isTaskEdit) {
      await repository.updateTask(widget.id!, _selectedDate);
    }

    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  String? _validateOffsetDays(String? value) {
    final parsed = int.tryParse(value ?? '');
    if (parsed == null || parsed < 0) {
      return '請輸入 0 或以上的整數';
    }
    return null;
  }

  String? _normalizeOptionalText(String value) {
    final normalized = value.trim();
    return normalized.isEmpty ? null : normalized;
  }
}

class _TaskScheduleSection extends StatelessWidget {
  const _TaskScheduleSection({
    required this.recurring,
    required this.isDirectTaskCreate,
    required this.repeatUnit,
    required this.repeatIntervalController,
    required this.reminderRuleType,
    required this.offsetController,
    required this.showOffsetField,
    required this.onRecurringChanged,
    required this.onRepeatUnitChanged,
    required this.onReminderRuleTypeChanged,
    required this.validateOffsetDays,
  });

  final bool recurring;
  final bool isDirectTaskCreate;
  final RepeatUnit repeatUnit;
  final TextEditingController repeatIntervalController;
  final ReminderRuleType reminderRuleType;
  final TextEditingController offsetController;
  final bool showOffsetField;
  final ValueChanged<bool> onRecurringChanged;
  final ValueChanged<RepeatUnit?> onRepeatUnitChanged;
  final ValueChanged<ReminderRuleType?> onReminderRuleTypeChanged;
  final FormFieldValidator<String> validateOffsetDays;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (isDirectTaskCreate)
          SwitchListTile(
            key: const Key('recurring-switch'),
            value: recurring,
            title: const Text('Recurring task'),
            onChanged: onRecurringChanged,
          ),
        if (recurring) ...[
          DropdownButtonFormField<RepeatUnit>(
            key: const Key('repeat-unit-field'),
            initialValue: repeatUnit,
            decoration: const InputDecoration(labelText: 'Repeat Unit'),
            items: RepeatUnit.values
                .map(
                  (value) =>
                      DropdownMenuItem(value: value, child: Text(value.name)),
                )
                .toList(growable: false),
            onChanged: onRepeatUnitChanged,
          ),
          const SizedBox(height: 12),
          TextFormField(
            key: const Key('repeat-interval-field'),
            controller: repeatIntervalController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Repeat Interval'),
          ),
        ],
        const SizedBox(height: 12),
        DropdownButtonFormField<ReminderRuleType>(
          key: const Key('reminder-rule-field'),
          initialValue: reminderRuleType,
          decoration: const InputDecoration(labelText: 'Reminder Rule'),
          items: ReminderRuleType.values
              .map(
                (value) =>
                    DropdownMenuItem(value: value, child: Text(value.name)),
              )
              .toList(growable: false),
          onChanged: onReminderRuleTypeChanged,
        ),
        if (showOffsetField) ...[
          const SizedBox(height: 12),
          TextFormField(
            key: const Key('offset-field'),
            controller: offsetController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Offset Days'),
            validator: validateOffsetDays,
          ),
        ],
      ],
    );
  }
}
