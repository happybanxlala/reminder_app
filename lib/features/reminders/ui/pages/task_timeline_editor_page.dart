import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/local/task_timeline_dao.dart';
import '../../data/task_repository.dart';
import '../../data/timeline_repository.dart';
import '../../domain/reminder_rule.dart';
import '../../domain/repeat_rule.dart';
import '../../domain/task_template.dart';
import '../../domain/timeline.dart';
import '../../domain/timeline_milestone_occurrence.dart';
import '../../domain/timeline_milestone_rule.dart';
import '../../domain/timeline_milestone_service.dart';
import '../../presentation/formatters/reminder_formatters.dart';
import '../../presentation/text/reminder_ui_text.dart';
import '../../providers/task_providers.dart';
import '../../providers/timeline_providers.dart';

enum TaskTimelineEditorMode {
  taskCreate,
  taskTemplateCreate,
  taskTemplateEdit,
  taskEdit,
  timelineCreate,
  timelineEdit,
}

class TaskTimelineEditorPage extends ConsumerStatefulWidget {
  const TaskTimelineEditorPage({super.key, required this.mode, this.id});

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

  final TaskTimelineEditorMode mode;
  final int? id;

  @override
  ConsumerState<TaskTimelineEditorPage> createState() =>
      _TaskTimelineEditorPageState();
}

class _TaskTimelineEditorPageState
    extends ConsumerState<TaskTimelineEditorPage> {
  final _formKey = GlobalKey<FormState>();
  final _milestoneService = const TimelineMilestoneService();
  late final TextEditingController _titleController;
  late final TextEditingController _noteController;
  late final TextEditingController _dateController;
  late final TextEditingController _intervalController;
  late final TextEditingController _taskOffsetController;

  DateTime _selectedDate = DateTime.now();
  bool _recurring = false;
  RepeatUnit _repeatUnit = RepeatUnit.week;
  ReminderRuleType _reminderRuleType = ReminderRuleType.onDue;
  TimelineDisplayUnit _displayUnit = TimelineDisplayUnit.day;
  bool _initialized = false;
  List<_RuleDraft> _ruleDrafts = const [];

  bool get _isDirectTaskCreate =>
      widget.mode == TaskTimelineEditorMode.taskCreate;

  bool get _isTaskCreate =>
      widget.mode == TaskTimelineEditorMode.taskCreate ||
      widget.mode == TaskTimelineEditorMode.taskTemplateCreate;

  bool get _isTaskTemplateEdit =>
      widget.mode == TaskTimelineEditorMode.taskTemplateEdit;

  bool get _isTaskTemplateFlow => _isTaskCreate || _isTaskTemplateEdit;

  bool get _isTaskEdit => widget.mode == TaskTimelineEditorMode.taskEdit;

  bool get _isTimeline =>
      widget.mode == TaskTimelineEditorMode.timelineCreate ||
      widget.mode == TaskTimelineEditorMode.timelineEdit;

  bool get _showTaskOffsetField =>
      _reminderRuleType == ReminderRuleType.advance;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _noteController = TextEditingController();
    _dateController = TextEditingController();
    _intervalController = TextEditingController(text: '1');
    _taskOffsetController = TextEditingController(text: '0');
    _recurring = !_isDirectTaskCreate && !_isTimeline;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _noteController.dispose();
    _dateController.dispose();
    _intervalController.dispose();
    _taskOffsetController.dispose();
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
            if (_isTimeline) ..._buildTimelineSection(),
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
      TaskTimelineEditorMode.taskCreate => ReminderUiText.addTask,
      TaskTimelineEditorMode.taskTemplateCreate =>
        ReminderUiText.addTaskTemplate,
      TaskTimelineEditorMode.taskTemplateEdit =>
        ReminderUiText.editTaskTemplate,
      TaskTimelineEditorMode.taskEdit => ReminderUiText.editTask,
      TaskTimelineEditorMode.timelineCreate => ReminderUiText.addTimeline,
      TaskTimelineEditorMode.timelineEdit => ReminderUiText.editTimeline,
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
      if (_isDirectTaskCreate)
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
          initialValue: _repeatUnit,
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
        initialValue: _reminderRuleType,
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
      if (_showTaskOffsetField) ...[
        const SizedBox(height: 12),
        TextFormField(
          key: const Key('offset-field'),
          controller: _taskOffsetController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Offset Days'),
          validator: _validateOffsetDays,
        ),
      ],
    ];
  }

  List<Widget> _buildTimelineSection() {
    return [
      const SizedBox(height: 12),
      DropdownButtonFormField<TimelineDisplayUnit>(
        key: const Key('display-unit-field'),
        initialValue: _displayUnit,
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
              ReminderUiText.milestoneRulesTitle,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          TextButton.icon(
            key: const Key('add-rule-button'),
            onPressed: _addRule,
            icon: const Icon(Icons.add),
            label: const Text(ReminderUiText.addRuleAction),
          ),
        ],
      ),
      if (_ruleDrafts.isEmpty)
        const Text('尚未設定 milestone rule。')
      else
        ..._ruleDrafts.asMap().entries.map(
          (entry) => _RuleDraftCard(
            key: Key('rule-draft-${entry.value.localId}'),
            draft: entry.value,
            previewLabel: _previewLabelForDraft(entry.value),
            onChanged: (next) {
              setState(() {
                _ruleDrafts = [
                  for (final item in _ruleDrafts)
                    item.localId == entry.value.localId ? next : item,
                ];
              });
            },
            onRemove: () {
              setState(() {
                _ruleDrafts = _ruleDrafts
                    .where((item) => item.localId != entry.value.localId)
                    .toList(growable: false);
              });
            },
            validatePositiveInt: _validatePositiveInt,
            validateOffsetDays: _validateOffsetDays,
            upcomingSummary: _upcomingSummaryForDraft(entry.value),
          ),
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
      _taskOffsetController.text =
          '${taskTemplate.reminderRule.offsetDays ?? 0}';
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
      _ruleDrafts = timelineDetail.rules
          .map((rule) => _RuleDraft.fromDomain(rule))
          .toList(growable: false);
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

  void _addRule() {
    setState(() {
      _ruleDrafts = [..._ruleDrafts, _RuleDraft.defaults(_displayUnit)];
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_isTaskTemplateFlow) {
      final repository = ref.read(taskRepositoryProvider);
      final reminderRule = switch (_reminderRuleType) {
        ReminderRuleType.advance => ReminderRule.advance(
          int.parse(_taskOffsetController.text),
        ),
        ReminderRuleType.onDue => const ReminderRule.onDue(),
        ReminderRuleType.immediate => const ReminderRule.immediate(),
      };

      if (_isDirectTaskCreate && !_recurring) {
        await repository.createStandaloneTask(
          TaskInput(
            title: _titleController.text.trim(),
            note: _noteController.text.trim().isEmpty
                ? null
                : _noteController.text.trim(),
            dueDate: _selectedDate,
            reminderRule: reminderRule,
          ),
        );
      } else {
        final input = TaskTemplateInput(
          title: _titleController.text.trim(),
          note: _noteController.text.trim().isEmpty
              ? null
              : _noteController.text.trim(),
          kind: TaskKind.recurring,
          firstDueDate: _selectedDate,
          repeatRule: RepeatRule(
            unit: _repeatUnit,
            interval: int.tryParse(_intervalController.text) ?? 1,
          ),
          reminderRule: reminderRule,
        );

        if (widget.mode == TaskTimelineEditorMode.taskTemplateEdit) {
          await repository.updateTemplate(widget.id!, input);
        } else {
          await repository.createTemplateWithFirstTask(input);
        }
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
        milestoneRules: _ruleDrafts
            .map((draft) => draft.toInput())
            .toList(growable: false),
      );
      if (widget.mode == TaskTimelineEditorMode.timelineCreate) {
        await ref.read(timelineRepositoryProvider).createTimeline(input);
      } else {
        await ref
            .read(timelineRepositoryProvider)
            .updateTimeline(widget.id!, input);
        ref.invalidate(timelineDetailProvider(widget.id!));
        ref.invalidate(timelineEditorDetailProvider(widget.id!));
      }
      ref.invalidate(timelinesProvider);
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

  String? _validatePositiveInt(String? value) {
    final parsed = int.tryParse(value ?? '');
    if (parsed == null || parsed < 1) {
      return '請輸入 1 或以上的整數';
    }
    return null;
  }

  String? _previewLabelForDraft(_RuleDraft draft) {
    final occurrence = _previewOccurrenceForDraft(draft);
    return occurrence?.label;
  }

  String? _upcomingSummaryForDraft(_RuleDraft draft) {
    final occurrence = _previewOccurrenceForDraft(draft);
    if (occurrence == null) {
      return null;
    }
    return '${occurrence.label} • ${ReminderFormatters.date(occurrence.targetDate)}';
  }

  TimelineMilestoneOccurrence? _previewOccurrenceForDraft(_RuleDraft draft) {
    if (!_isTimeline) {
      return null;
    }
    final now = DateTime.now();
    final normalizedNow = DateTime(now.year, now.month, now.day);
    return _milestoneService.getNextOccurrence(
      draft.toDomain(
        timelineId: widget.id ?? 0,
        ruleId: draft.effectiveRuleId,
        now: now,
      ),
      Timeline(
        id: widget.id ?? 0,
        title: _titleController.text.trim().isEmpty
            ? 'Timeline'
            : _titleController.text.trim(),
        startDate: _selectedDate,
        displayUnit: _displayUnit,
        status: TimelineStatus.active,
        createdAt: now,
        updatedAt: now,
      ),
      after: normalizedNow.subtract(const Duration(days: 1)),
    );
  }
}

class _RuleDraft {
  const _RuleDraft({
    required this.localId,
    this.id,
    required this.type,
    required this.intervalValue,
    required this.intervalUnit,
    required this.labelTemplate,
    required this.reminderOffsetDays,
    required this.status,
  });

  factory _RuleDraft.fromDomain(TimelineMilestoneRule rule) {
    return _RuleDraft(
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

  factory _RuleDraft.defaults(TimelineDisplayUnit displayUnit) {
    final seed = DateTime.now().microsecondsSinceEpoch;
    return switch (displayUnit) {
      TimelineDisplayUnit.day => _RuleDraft(
        localId: seed,
        type: TimelineMilestoneRuleType.everyNDays,
        intervalValue: '1',
        intervalUnit: TimelineMilestoneIntervalUnit.days,
        labelTemplate: '第 {value}{unit}',
        reminderOffsetDays: '0',
        status: TimelineMilestoneRuleStatus.active,
      ),
      TimelineDisplayUnit.week => _RuleDraft(
        localId: seed,
        type: TimelineMilestoneRuleType.everyNWeeks,
        intervalValue: '1',
        intervalUnit: TimelineMilestoneIntervalUnit.weeks,
        labelTemplate: '第 {value}{unit}',
        reminderOffsetDays: '0',
        status: TimelineMilestoneRuleStatus.active,
      ),
      TimelineDisplayUnit.month => _RuleDraft(
        localId: seed,
        type: TimelineMilestoneRuleType.everyNMonths,
        intervalValue: '1',
        intervalUnit: TimelineMilestoneIntervalUnit.months,
        labelTemplate: '第 {value}{unit}',
        reminderOffsetDays: '0',
        status: TimelineMilestoneRuleStatus.active,
      ),
      TimelineDisplayUnit.year => _RuleDraft(
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

  _RuleDraft copyWith({
    TimelineMilestoneRuleType? type,
    String? intervalValue,
    TimelineMilestoneIntervalUnit? intervalUnit,
    String? labelTemplate,
    String? reminderOffsetDays,
    TimelineMilestoneRuleStatus? status,
  }) {
    return _RuleDraft(
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

  TimelineMilestoneRule toDomain({
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

class _RuleDraftCard extends StatefulWidget {
  const _RuleDraftCard({
    super.key,
    required this.draft,
    required this.previewLabel,
    required this.upcomingSummary,
    required this.onChanged,
    required this.onRemove,
    required this.validatePositiveInt,
    required this.validateOffsetDays,
  });

  final _RuleDraft draft;
  final String? previewLabel;
  final String? upcomingSummary;
  final ValueChanged<_RuleDraft> onChanged;
  final VoidCallback onRemove;
  final FormFieldValidator<String> validatePositiveInt;
  final FormFieldValidator<String> validateOffsetDays;

  @override
  State<_RuleDraftCard> createState() => _RuleDraftCardState();
}

class _RuleDraftCardState extends State<_RuleDraftCard> {
  late final TextEditingController _labelController;

  @override
  void initState() {
    super.initState();
    _labelController = TextEditingController(text: widget.draft.labelTemplate);
  }

  @override
  void didUpdateWidget(covariant _RuleDraftCard oldWidget) {
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
                    decoration: const InputDecoration(labelText: 'Rule Type'),
                    items: TimelineMilestoneRuleType.values
                        .map(
                          (value) => DropdownMenuItem(
                            value: value,
                            child: Text(value.name),
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
              decoration: const InputDecoration(labelText: 'Interval Value'),
              validator: widget.validatePositiveInt,
              onChanged: (value) =>
                  widget.onChanged(widget.draft.copyWith(intervalValue: value)),
            ),
            const SizedBox(height: 12),
            TextFormField(
              key: Key('rule-label-${widget.draft.localId}'),
              controller: _labelController,
              decoration: const InputDecoration(labelText: 'Label Template'),
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
                    ? '預覽：目前無法產生下一筆 milestone'
                    : '預覽：${widget.previewLabel}',
                key: Key('rule-preview-${widget.draft.localId}'),
              ),
            ),
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                widget.upcomingSummary == null
                    ? '下一筆：目前無法產生 upcoming milestone'
                    : '下一筆：${widget.upcomingSummary}',
                key: Key('rule-next-occurrence-${widget.draft.localId}'),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              key: Key('rule-offset-${widget.draft.localId}'),
              initialValue: widget.draft.reminderOffsetDays,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Reminder Offset Days',
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
              title: const Text('Active'),
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
