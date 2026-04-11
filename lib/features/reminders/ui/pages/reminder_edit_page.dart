import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/local/daos.dart';
import '../../data/reminder_repository.dart';
import '../../domain/milestone.dart';
import '../../domain/milestone_reminder_rule.dart';
import '../../domain/reminder_rule.dart';
import '../../domain/repeat_rule.dart';
import '../../domain/task_template.dart';
import '../../domain/timeline.dart';
import '../../presentation/reminder_view_models.dart';

enum ReminderFormMode {
  taskCreate,
  taskTemplateCreate,
  taskTemplateEdit,
  taskEdit,
  timelineCreate,
  timelineEdit,
}

class ReminderEditPage extends ConsumerStatefulWidget {
  const ReminderEditPage({super.key, required this.mode, this.id});

  static const taskNewRouteName = 'task-new';
  static const taskNewRoutePath = '/task/new';
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
  List<_MilestoneDraft> _customMilestones = const [];
  List<MilestoneBundle> _ruleBasedMilestones = const [];

  bool get _isTaskCreate =>
      widget.mode == ReminderFormMode.taskCreate ||
      widget.mode == ReminderFormMode.taskTemplateCreate;

  bool get _isTaskTemplateEdit =>
      widget.mode == ReminderFormMode.taskTemplateEdit;

  bool get _isTaskTemplateFlow => _isTaskCreate || _isTaskTemplateEdit;

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
    final taskTemplateAsync = _isTaskTemplateEdit && widget.id != null
        ? ref.watch(taskTemplateDetailProvider(widget.id!))
        : const AsyncData<TaskTemplate?>(null);
    final taskAsync = _isTaskEdit && widget.id != null
        ? ref.watch(taskDetailProvider(widget.id!))
        : const AsyncData<TaskBundle?>(null);
    final timelineAsync = _isTimeline && widget.id != null
        ? ref.watch(timelineEditorDetailProvider(widget.id!))
        : const AsyncData<TimelineDetail?>(null);

    if (taskTemplateAsync.isLoading ||
        taskAsync.isLoading ||
        timelineAsync.isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text(_pageTitle)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    _initializeIfNeeded(
      taskTemplateAsync.valueOrNull,
      taskAsync.valueOrNull,
      timelineAsync.valueOrNull,
    );

    return Scaffold(
      appBar: AppBar(title: Text(_pageTitle)),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            ..._buildBasicSection(context),
            if (_isTaskTemplateFlow) ..._buildTaskRuleSection(),
            if (_isTimeline) ..._buildTimelineSection(context),
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
      ReminderFormMode.taskCreate => ReminderUiText.addTask,
      ReminderFormMode.taskTemplateCreate => ReminderUiText.addTaskTemplate,
      ReminderFormMode.taskTemplateEdit => ReminderUiText.editTaskTemplate,
      ReminderFormMode.taskEdit => ReminderUiText.editTask,
      ReminderFormMode.timelineCreate => ReminderUiText.addTimeline,
      ReminderFormMode.timelineEdit => ReminderUiText.editTimeline,
    };
  }

  List<Widget> _buildBasicSection(BuildContext context) {
    return [
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
            onPressed: () => _pickDate(
              initial: _selectedDate,
              onPicked: (value) {
                setState(() {
                  _selectedDate = value;
                  _dateController.text = ReminderFormatters.date(value);
                });
              },
            ),
            icon: const Icon(Icons.calendar_today_outlined),
          ),
        ),
      ),
    ];
  }

  List<Widget> _buildTaskRuleSection() {
    return [
      const SizedBox(height: 12),
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
                (value) =>
                    DropdownMenuItem(value: value, child: Text(value.name)),
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
          decoration: const InputDecoration(labelText: 'Repeat Interval'),
        ),
      ],
      const SizedBox(height: 12),
      DropdownButtonFormField<ReminderRuleType>(
        key: const Key('reminder-rule-field'),
        value: _reminderRuleType,
        decoration: const InputDecoration(labelText: 'Reminder Rule'),
        items: ReminderRuleType.values
            .map(
              (value) =>
                  DropdownMenuItem(value: value, child: Text(value.name)),
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
    ];
  }

  List<Widget> _buildTimelineSection(BuildContext context) {
    return [
      const SizedBox(height: 12),
      DropdownButtonFormField<TimelineDisplayUnit>(
        key: const Key('display-unit-field'),
        value: _displayUnit,
        decoration: const InputDecoration(labelText: 'Display Unit'),
        items: TimelineDisplayUnit.values
            .map(
              (value) =>
                  DropdownMenuItem(value: value, child: Text(value.name)),
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
      const SizedBox(height: 16),
      Row(
        children: [
          const Expanded(
            child: Text(
              ReminderUiText.customMilestoneTitle,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          TextButton.icon(
            key: const Key('add-milestone-button'),
            onPressed: _addMilestone,
            icon: const Icon(Icons.add),
            label: const Text(ReminderUiText.addMilestoneAction),
          ),
        ],
      ),
      if (_customMilestones.isEmpty)
        const Text('尚未設定 custom milestone。')
      else
        ..._customMilestones.asMap().entries.map(
          (entry) => _MilestoneDraftCard(
            key: Key('custom-milestone-${entry.key}'),
            draft: entry.value,
            onPickDate: () => _pickDate(
              initial: entry.value.targetDate,
              onPicked: (value) {
                setState(() {
                  _customMilestones = [
                    for (final item in _customMilestones)
                      identical(item, entry.value)
                          ? item.copyWith(targetDate: value)
                          : item,
                  ];
                });
              },
            ),
            onDescriptionChanged: (value) {
              setState(() {
                _customMilestones = [
                  for (final item in _customMilestones)
                    identical(item, entry.value)
                        ? item.copyWith(description: value)
                        : item,
                ];
              });
            },
            onRemove: () {
              setState(() {
                _customMilestones = _customMilestones
                    .where((item) => !identical(item, entry.value))
                    .toList(growable: false);
              });
            },
          ),
        ),
      const SizedBox(height: 16),
      const Text(
        ReminderUiText.ruleBasedMilestoneTitle,
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
      const SizedBox(height: 8),
      if (_ruleBasedMilestones.isEmpty)
        const Text('將依 display unit 產生未來 1 年內的 rule-based milestones。')
      else
        ..._ruleBasedMilestones.map(
          (item) => ListTile(
            key: Key('rule-based-milestone-${item.milestone.id}'),
            title: Text(item.milestone.description ?? item.timeline.title),
            subtitle: Text(ReminderFormatters.milestoneSummary(item)),
            trailing: Text(item.milestone.status.name),
          ),
        ),
      const SizedBox(height: 12),
      DropdownButtonFormField<MilestoneReminderRuleType>(
        key: const Key('milestone-reminder-rule-field'),
        value: _milestoneReminderRuleType,
        decoration: const InputDecoration(labelText: 'Milestone Reminder Rule'),
        items: MilestoneReminderRuleType.values
            .map(
              (value) =>
                  DropdownMenuItem(value: value, child: Text(value.name)),
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
        decoration: const InputDecoration(labelText: 'Reminder Offset Days'),
      ),
    ];
  }

  void _initializeIfNeeded(
    TaskTemplate? taskTemplate,
    TaskBundle? taskBundle,
    TimelineDetail? timelineDetail,
  ) {
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
    } else if (timelineDetail != null) {
      final timeline = timelineDetail.timeline;
      _titleController.text = timeline.title;
      _selectedDate = timeline.startDate;
      _dateController.text = ReminderFormatters.date(timeline.startDate);
      _displayUnit = timeline.displayUnit;
      _milestoneReminderRuleType = timeline.milestoneReminderRule.type;
      _offsetController.text =
          '${timeline.milestoneReminderRule.offsetDays ?? 0}';
      _customMilestones = timelineDetail.customMilestones
          .where((item) => item.milestone.status == MilestoneStatus.upcoming)
          .map(
            (item) => _MilestoneDraft(
              targetDate: item.milestone.targetDate,
              description: item.milestone.description ?? '',
            ),
          )
          .toList(growable: false);
      _ruleBasedMilestones = timelineDetail.ruleBasedMilestones;
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

  Future<void> _addMilestone() async {
    final initial = _selectedDate;
    await _pickDate(
      initial: initial,
      onPicked: (value) {
        setState(() {
          _customMilestones = [
            ..._customMilestones,
            _MilestoneDraft(targetDate: value, description: ''),
          ];
        });
      },
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_isTaskTemplateFlow) {
      final repository = ref.read(taskRepositoryProvider);
      final input = TaskTemplateInput(
        title: _titleController.text.trim(),
        note: _noteController.text.trim().isEmpty
            ? null
            : _noteController.text.trim(),
        kind: _recurring ? TaskKind.recurring : TaskKind.oneTime,
        firstDueDate: _selectedDate,
        repeatRule: _recurring
            ? RepeatRule(
                unit: _repeatUnit,
                interval: int.tryParse(_intervalController.text) ?? 1,
              )
            : null,
        reminderRule: switch (_reminderRuleType) {
          ReminderRuleType.advance => ReminderRule.advance(
            int.tryParse(_offsetController.text) ?? 0,
          ),
          ReminderRuleType.onDue => const ReminderRule.onDue(),
          ReminderRuleType.immediate => const ReminderRule.immediate(),
        },
      );

      if (widget.mode == ReminderFormMode.taskTemplateEdit) {
        await repository.updateTemplate(widget.id!, input);
      } else {
        await repository.createTemplateWithFirstTask(input);
      }
    } else if (_isTaskEdit) {
      await ref
          .read(taskRepositoryProvider)
          .updateTask(widget.id!, _selectedDate);
    } else {
      final input = TimelineInput(
        title: _titleController.text.trim(),
        startDate: _selectedDate,
        displayUnit: _displayUnit,
        milestoneReminderRule: switch (_milestoneReminderRuleType) {
          MilestoneReminderRuleType.advance => MilestoneReminderRule.advance(
            int.tryParse(_offsetController.text) ?? 0,
          ),
          MilestoneReminderRuleType.onDay =>
            const MilestoneReminderRule.onDay(),
        },
      );
      final customMilestones = _customMilestones
          .map(
            (item) => MilestoneInput(
              targetDate: item.targetDate,
              description: item.description.trim().isEmpty
                  ? null
                  : item.description.trim(),
              source: MilestoneSource.custom,
            ),
          )
          .toList(growable: false);
      if (widget.mode == ReminderFormMode.timelineCreate) {
        await ref
            .read(timelineRepositoryProvider)
            .createTimeline(input, customMilestones: customMilestones);
      } else {
        await ref
            .read(timelineRepositoryProvider)
            .updateTimeline(
              widget.id!,
              input,
              customMilestones: customMilestones,
            );
      }
    }

    if (mounted) {
      Navigator.of(context).pop();
    }
  }
}

class _MilestoneDraft {
  const _MilestoneDraft({required this.targetDate, required this.description});

  final DateTime targetDate;
  final String description;

  _MilestoneDraft copyWith({DateTime? targetDate, String? description}) {
    return _MilestoneDraft(
      targetDate: targetDate ?? this.targetDate,
      description: description ?? this.description,
    );
  }
}

class _MilestoneDraftCard extends StatelessWidget {
  const _MilestoneDraftCard({
    super.key,
    required this.draft,
    required this.onPickDate,
    required this.onDescriptionChanged,
    required this.onRemove,
  });

  final _MilestoneDraft draft;
  final VoidCallback onPickDate;
  final ValueChanged<String> onDescriptionChanged;
  final VoidCallback onRemove;

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
                  child: Text(ReminderFormatters.date(draft.targetDate)),
                ),
                TextButton(onPressed: onPickDate, child: const Text('選日期')),
                IconButton(
                  onPressed: onRemove,
                  icon: const Icon(Icons.delete_outline),
                ),
              ],
            ),
            TextFormField(
              initialValue: draft.description,
              decoration: const InputDecoration(labelText: 'Description'),
              onChanged: onDescriptionChanged,
            ),
          ],
        ),
      ),
    );
  }
}
