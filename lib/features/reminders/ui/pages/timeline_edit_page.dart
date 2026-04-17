import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/timeline_models.dart';
import '../../domain/timeline.dart';
import '../../domain/timeline_milestone_occurrence.dart';
import '../../domain/timeline_milestone_service.dart';
import '../../presentation/formatters/reminder_formatters.dart';
import '../../presentation/text/reminder_ui_text.dart';
import '../../providers/timeline_providers.dart';
import '../widgets/editor_common_fields.dart';
import '../widgets/timeline_milestone_rule_form_card.dart';

enum TimelineEditMode { create, edit }

class TimelineEditPage extends ConsumerStatefulWidget {
  const TimelineEditPage({super.key, required this.mode, this.id});

  static const timelineNewRouteName = 'timeline-new';
  static const timelineNewRoutePath = '/timeline/new';
  static const timelineEditRouteName = 'timeline-edit';
  static const timelineEditRoutePath = '/timeline/:id';

  final TimelineEditMode mode;
  final int? id;

  @override
  ConsumerState<TimelineEditPage> createState() => _TimelineEditPageState();
}

class _TimelineEditPageState extends ConsumerState<TimelineEditPage> {
  final _formKey = GlobalKey<FormState>();
  final _milestoneService = const TimelineMilestoneService();
  late final TextEditingController _titleController;
  late final TextEditingController _dateController;

  DateTime _selectedDate = DateTime.now();
  TimelineDisplayUnit _displayUnit = TimelineDisplayUnit.day;
  bool _initialized = false;
  List<TimelineMilestoneRuleDraft> _ruleDrafts = const [];

  bool get _isCreate => widget.mode == TimelineEditMode.create;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _dateController = TextEditingController();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final timelineAsync = widget.id != null
        ? ref.watch(timelineDetailProvider(widget.id!))
        : const AsyncData<TimelineDetail?>(null);

    if (timelineAsync.isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text(_pageTitle)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    _initializeIfNeeded(timelineAsync.valueOrNull);

    return Scaffold(
      appBar: AppBar(title: Text(_pageTitle)),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            EditorTitleField(controller: _titleController),
            const SizedBox(height: 12),
            EditorDateField(
              controller: _dateController,
              label: 'Start Date',
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
            const SizedBox(height: 8),
            const Text('Timeline 持有的是 milestone rule；milestone 是規則推導出的時間事件。'),
            const SizedBox(height: 12),
            if (_ruleDrafts.isEmpty)
              const Text('尚未設定 milestone rule。')
            else
              ..._ruleDrafts.map(
                (draft) => TimelineMilestoneRuleFormCard(
                  key: Key('rule-draft-${draft.localId}'),
                  draft: draft,
                  previewLabel: _previewLabelForDraft(draft),
                  upcomingSummary: _upcomingSummaryForDraft(draft),
                  onChanged: (next) {
                    setState(() {
                      _ruleDrafts = [
                        for (final item in _ruleDrafts)
                          item.localId == draft.localId ? next : item,
                      ];
                    });
                  },
                  onRemove: () {
                    setState(() {
                      _ruleDrafts = _ruleDrafts
                          .where((item) => item.localId != draft.localId)
                          .toList(growable: false);
                    });
                  },
                  validatePositiveInt: _validatePositiveInt,
                  validateOffsetDays: _validateOffsetDays,
                ),
              ),
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

  String get _pageTitle =>
      _isCreate ? ReminderUiText.addTimeline : ReminderUiText.editTimeline;

  void _initializeIfNeeded(TimelineDetail? detail) {
    if (_initialized) {
      return;
    }
    if (detail != null) {
      final timeline = detail.timeline;
      _titleController.text = timeline.title;
      _selectedDate = timeline.startDate;
      _dateController.text = ReminderFormatters.date(timeline.startDate);
      _displayUnit = timeline.displayUnit;
      _ruleDrafts = detail.milestoneRuleDetails
          .map((item) => TimelineMilestoneRuleDraft.fromRule(item.rule))
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
      _ruleDrafts = [
        ..._ruleDrafts,
        TimelineMilestoneRuleDraft.defaults(_displayUnit),
      ];
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final input = TimelineInput(
      title: _titleController.text.trim(),
      startDate: _selectedDate,
      displayUnit: _displayUnit,
      milestoneRules: _ruleDrafts
          .map((draft) => draft.toInput())
          .toList(growable: false),
    );

    final repository = ref.read(timelineRepositoryProvider);

    try {
      final saved = _isCreate
          ? (await repository.createTimeline(input), true).$2
          : await repository.updateTimeline(widget.id!, input);
      if (!saved) {
        _showSaveError(ReminderUiText.timelineSaveFailedMessage);
        return;
      }
    } catch (_) {
      _showSaveError(ReminderUiText.saveFailedPrefix);
      return;
    }

    if (!_isCreate) {
      ref.invalidate(timelineByIdProvider(widget.id!));
      ref.invalidate(timelineDetailProvider(widget.id!));
    }
    ref.invalidate(timelinesProvider);

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

  String? _previewLabelForDraft(TimelineMilestoneRuleDraft draft) {
    final occurrence = _previewOccurrenceForDraft(draft);
    return occurrence?.label;
  }

  String? _upcomingSummaryForDraft(TimelineMilestoneRuleDraft draft) {
    final occurrence = _previewOccurrenceForDraft(draft);
    if (occurrence == null) {
      return null;
    }
    return '${occurrence.label} • ${ReminderFormatters.date(occurrence.targetDate)}';
  }

  TimelineMilestoneOccurrence? _previewOccurrenceForDraft(
    TimelineMilestoneRuleDraft draft,
  ) {
    final now = DateTime.now();
    final normalizedNow = DateTime(now.year, now.month, now.day);
    return _milestoneService.getNextOccurrence(
      draft.toRule(
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

  void _showSaveError(String message) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}
