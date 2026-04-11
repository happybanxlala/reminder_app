import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/reminder_repository.dart';
import '../../domain/milestone_reminder_rule.dart';
import '../../domain/reminder_rule.dart';
import '../../domain/repeat_rule.dart';
import '../../domain/task_template.dart';
import '../../domain/timeline.dart';
import '../../presentation/reminder_view_models.dart';

enum ReminderFormMode {
  taskTemplateCreate,
  taskTemplateEdit,
  taskEdit,
  timelineCreate,
  timelineEdit,
}

class ReminderEditPage extends ConsumerStatefulWidget {
  const ReminderEditPage({super.key, required this.mode, this.id});

  static const taskTemplateNewRouteName = 'task-template-new';
  static const taskTemplateNewRoutePath = '/task-template/new';
  static const taskTemplateEditRouteName = 'task-template-edit';
  static const taskTemplateEditRoutePath = '/task-template/:id';
  static const taskEditRouteName = 'task-edit';
  static const taskEditRoutePath = '/task/:id';
  static const timelineNewRouteName = 'timeline-new';
  static const timelineNewRoutePath = '/timeline/new';
  static const timelineEditRouteName = 'timeline-edit';
  static const timelineEditRoutePath = '/timeline/:id';

  final ReminderFormMode mode;
  final int? id;

  @override
  ConsumerState<ReminderEditPage> createState() => _ReminderEditPageState();
}

class _ReminderEditPageState extends ConsumerState<ReminderEditPage> {
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
  MilestoneReminderRuleType _milestoneReminderRuleType =
      MilestoneReminderRuleType.onDay;
  TimelineDisplayUnit _displayUnit = TimelineDisplayUnit.day;
  bool _initialized = false;

  bool get _isTaskTemplate =>
      widget.mode == ReminderFormMode.taskTemplateCreate ||
      widget.mode == ReminderFormMode.taskTemplateEdit;

  bool get _isTaskEdit => widget.mode == ReminderFormMode.taskEdit;

  bool get _isTimeline =>
      widget.mode == ReminderFormMode.timelineCreate ||
      widget.mode == ReminderFormMode.timelineEdit;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _noteController = TextEditingController();
    _dateController = TextEditingController();
    _intervalController = TextEditingController(text: '1');
    _offsetController = TextEditingController(text: '0');
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
    final taskTemplateAsync = _isTaskTemplate && widget.id != null
        ? ref.watch(taskTemplateDetailProvider(widget.id!))
        : const AsyncData(null);
    final taskAsync = _isTaskEdit && widget.id != null
        ? ref.watch(taskDetailProvider(widget.id!))
        : const AsyncData(null);
    final timelineAsync = _isTimeline && widget.id != null
        ? ref.watch(timelineDetailProvider(widget.id!))
        : const AsyncData(null);

    if (taskTemplateAsync.isLoading ||
        taskAsync.isLoading ||
        timelineAsync.isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text(_title)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final taskTemplate = taskTemplateAsync.valueOrNull;
    final taskBundle = taskAsync.valueOrNull;
    final timeline = timelineAsync.valueOrNull;
    _initializeIfNeeded(taskTemplate, taskBundle, timeline);

    return Scaffold(
      appBar: AppBar(title: Text(_title)),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              key: const Key('title-field'),
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Title'),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return '請輸入標題';
                }
                return null;
              },
            ),
            if (!_isTaskEdit) ...[
              const SizedBox(height: 12),
              TextFormField(
                key: const Key('note-field'),
                controller: _noteController,
                decoration: const InputDecoration(labelText: 'Note'),
                maxLines: 2,
              ),
            ],
            const SizedBox(height: 12),
            TextFormField(
              key: const Key('date-field'),
              controller: _dateController,
              readOnly: true,
              decoration: InputDecoration(
                labelText: _isTimeline ? 'Start Date' : 'Due Date',
                suffixIcon: IconButton(
                  onPressed: _pickDate,
                  icon: const Icon(Icons.calendar_today_outlined),
                ),
              ),
            ),
            if (_isTaskTemplate) ...[
              SwitchListTile(
                key: const Key('recurring-switch'),
                value: _recurring,
                title: const Text('Recurring task'),
                onChanged: (value) {
                  setState(() {
                    _recurring = value;
                  });
                },
              ),
              if (_recurring) ...[
                DropdownButtonFormField<RepeatUnit>(
                  key: const Key('repeat-unit-field'),
                  value: _repeatUnit,
                  decoration: const InputDecoration(labelText: 'Repeat Unit'),
                  items: RepeatUnit.values
                      .map(
                        (value) => DropdownMenuItem(
                          value: value,
                          child: Text(value.name),
                        ),
                      )
                      .toList(growable: false),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _repeatUnit = value;
                      });
                    }
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  key: const Key('repeat-interval-field'),
                  controller: _intervalController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Repeat Interval',
                  ),
                ),
              ],
              const SizedBox(height: 12),
              DropdownButtonFormField<ReminderRuleType>(
                key: const Key('reminder-rule-field'),
                value: _reminderRuleType,
                decoration: const InputDecoration(labelText: 'Reminder Rule'),
                items: ReminderRuleType.values
                    .map(
                      (value) => DropdownMenuItem(
                        value: value,
                        child: Text(value.name),
                      ),
                    )
                    .toList(growable: false),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _reminderRuleType = value;
                    });
                  }
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                key: const Key('offset-field'),
                controller: _offsetController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Offset Days'),
              ),
            ],
            if (_isTimeline) ...[
              DropdownButtonFormField<TimelineDisplayUnit>(
                key: const Key('display-unit-field'),
                value: _displayUnit,
                decoration: const InputDecoration(labelText: 'Display Unit'),
                items: TimelineDisplayUnit.values
                    .map(
                      (value) => DropdownMenuItem(
                        value: value,
                        child: Text(value.name),
                      ),
                    )
                    .toList(growable: false),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _displayUnit = value;
                    });
                  }
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<MilestoneReminderRuleType>(
                key: const Key('milestone-reminder-rule-field'),
                value: _milestoneReminderRuleType,
                decoration: const InputDecoration(
                  labelText: 'Milestone Reminder Rule',
                ),
                items: MilestoneReminderRuleType.values
                    .map(
                      (value) => DropdownMenuItem(
                        value: value,
                        child: Text(value.name),
                      ),
                    )
                    .toList(growable: false),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _milestoneReminderRuleType = value;
                    });
                  }
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                key: const Key('milestone-offset-field'),
                controller: _offsetController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Reminder Offset Days',
                ),
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

  String get _title {
    return switch (widget.mode) {
      ReminderFormMode.taskTemplateCreate => ReminderUiText.addTaskTemplate,
      ReminderFormMode.taskTemplateEdit => ReminderUiText.editTaskTemplate,
      ReminderFormMode.taskEdit => '編輯 Task',
      ReminderFormMode.timelineCreate => ReminderUiText.addTimeline,
      ReminderFormMode.timelineEdit => ReminderUiText.editTimeline,
    };
  }

  void _initializeIfNeeded(taskTemplate, taskBundle, timeline) {
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
    } else if (timeline != null) {
      _titleController.text = timeline.title;
      _selectedDate = timeline.startDate;
      _dateController.text = ReminderFormatters.date(timeline.startDate);
      _displayUnit = timeline.displayUnit;
      _milestoneReminderRuleType = timeline.milestoneReminderRule.type;
      _offsetController.text =
          '${timeline.milestoneReminderRule.offsetDays ?? 0}';
    } else {
      _dateController.text = ReminderFormatters.date(_selectedDate);
    }
    _initialized = true;
  }

  Future<void> _pickDate() async {
    final result = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (result == null) {
      return;
    }
    setState(() {
      _selectedDate = DateTime(result.year, result.month, result.day);
      _dateController.text = ReminderFormatters.date(_selectedDate);
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    if (_isTaskTemplate) {
      final repository = ref.read(taskRepositoryProvider);
      final repeatRule = _recurring
          ? RepeatRule(
              unit: _repeatUnit,
              interval: int.tryParse(_intervalController.text) ?? 1,
            )
          : null;
      final reminderRule = switch (_reminderRuleType) {
        ReminderRuleType.advance => ReminderRule.advance(
          int.tryParse(_offsetController.text) ?? 0,
        ),
        ReminderRuleType.onDue => const ReminderRule.onDue(),
        ReminderRuleType.immediate => const ReminderRule.immediate(),
      };
      final input = TaskTemplateInput(
        title: _titleController.text.trim(),
        note: _noteController.text.trim().isEmpty
            ? null
            : _noteController.text.trim(),
        kind: _recurring ? TaskKind.recurring : TaskKind.oneTime,
        firstDueDate: _selectedDate,
        repeatRule: repeatRule,
        reminderRule: reminderRule,
      );
      if (widget.mode == ReminderFormMode.taskTemplateCreate) {
        await repository.createTemplateWithFirstTask(input);
      } else {
        await repository.updateTemplate(widget.id!, input);
      }
    } else if (_isTaskEdit) {
      await ref
          .read(taskRepositoryProvider)
          .updateTask(widget.id!, _selectedDate);
    } else {
      final reminderRule = switch (_milestoneReminderRuleType) {
        MilestoneReminderRuleType.advance => MilestoneReminderRule.advance(
          int.tryParse(_offsetController.text) ?? 0,
        ),
        MilestoneReminderRuleType.onDay => const MilestoneReminderRule.onDay(),
      };
      final input = TimelineInput(
        title: _titleController.text.trim(),
        startDate: _selectedDate,
        displayUnit: _displayUnit,
        milestoneReminderRule: reminderRule,
      );
      if (widget.mode == ReminderFormMode.timelineCreate) {
        await ref.read(timelineRepositoryProvider).createTimeline(input);
      } else {
        await ref
            .read(timelineRepositoryProvider)
            .updateTimeline(widget.id!, input);
      }
    }
    if (mounted) {
      Navigator.of(context).pop();
    }
  }
}
