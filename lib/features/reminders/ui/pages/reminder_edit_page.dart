import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../data/reminder_repository.dart';
import '../../domain/demo_reminder_draft.dart';
import '../../domain/action_category.dart';
import '../../domain/reminder.dart';
import '../../domain/recurring_reminder.dart';
import '../../domain/topic_category.dart';
import '../../presentation/reminder_view_models.dart';

enum ReminderFormMode { reminderCreate, reminderEdit, seriesCreate, seriesEdit }

extension on ReminderFormMode {
  bool get isSeriesMode =>
      this == ReminderFormMode.seriesCreate ||
      this == ReminderFormMode.seriesEdit;

  bool get isEditing =>
      this == ReminderFormMode.reminderEdit ||
      this == ReminderFormMode.seriesEdit;
}

class ReminderEditPage extends ConsumerStatefulWidget {
  const ReminderEditPage({
    super.key,
    this.mode = ReminderFormMode.reminderCreate,
    this.reminderId,
    this.seriesId,
    this.demoDataFactory,
  });

  static const newRouteName = 'reminder-new';
  static const newRoutePath = '/reminder/new';
  static const editRouteName = 'reminder-edit';
  static const editRoutePath = '/reminder/:id';
  static const recurringNewRouteName = 'recurring-reminder-new';
  static const recurringNewRoutePath = '/recurring/new';
  static const recurringEditRouteName = 'recurring-reminder-edit';
  static const recurringEditRoutePath = '/recurring/:id';
  static const seriesNewRouteName = recurringNewRouteName;
  static const seriesNewRoutePath = recurringNewRoutePath;
  static const seriesEditRouteName = recurringEditRouteName;
  static const seriesEditRoutePath = recurringEditRoutePath;

  final ReminderFormMode mode;
  final int? reminderId;
  final int? seriesId;
  final DemoReminderDraft Function()? demoDataFactory;

  bool get isReminderEdit => mode == ReminderFormMode.reminderEdit;
  bool get isSeriesCreate => mode == ReminderFormMode.seriesCreate;
  bool get isSeriesEdit => mode == ReminderFormMode.seriesEdit;
  bool get isSeriesMode => mode.isSeriesMode;

  @override
  ConsumerState<ReminderEditPage> createState() => _ReminderEditPageState();
}

class _ReminderEditPageState extends ConsumerState<ReminderEditPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _noteController;
  late final TextEditingController _triggerOffsetDaysController;
  late final TextEditingController _repeatIntervalController;

  bool _initialized = false;
  bool _isReadOnly = false;
  int _trackingMode = ReminderTrackingMode.countdown;
  int _triggerMode = ReminderTriggerMode.inRange;
  String? _repeatType;
  DateTime? _dueAt;
  DateTime? _startAt;
  int? _selectedTopicCategoryId;
  int? _selectedActionCategoryId;

  bool get _showsDateFields => !widget.isSeriesEdit;
  bool get _requiresRepeatRule => widget.isSeriesMode;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _noteController = TextEditingController();
    _triggerOffsetDaysController = TextEditingController(text: '0');
    _repeatIntervalController = TextEditingController(text: '1');
  }

  @override
  void dispose() {
    _titleController.dispose();
    _noteController.dispose();
    _triggerOffsetDaysController.dispose();
    _repeatIntervalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reminderDetailAsync =
        widget.isReminderEdit && widget.reminderId != null
        ? ref.watch(reminderDetailProvider(widget.reminderId!))
        : const AsyncData<ReminderModel?>(null);
    final recurringReminderDetailAsync =
        widget.isSeriesEdit && widget.seriesId != null
        ? ref.watch(recurringReminderDetailProvider(widget.seriesId!))
        : const AsyncData<RecurringReminderModel?>(null);
    final topicCategoriesAsync = ref.watch(topicCategoriesProvider);
    final actionCategoriesAsync = ref.watch(actionCategoriesProvider);

    final error =
        reminderDetailAsync.asError?.error ??
        recurringReminderDetailAsync.asError?.error ??
        topicCategoriesAsync.asError?.error ??
        actionCategoriesAsync.asError?.error;

    if (error != null) {
      return Scaffold(
        appBar: AppBar(title: Text(_pageTitle)),
        body: Center(child: Text('讀取失敗: $error')),
      );
    }

    final isLoading =
        reminderDetailAsync.isLoading ||
        recurringReminderDetailAsync.isLoading ||
        topicCategoriesAsync.isLoading ||
        actionCategoriesAsync.isLoading;
    if (isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text(_pageTitle)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final seed = _resolveSeed(
      reminderDetailAsync.valueOrNull,
      recurringReminderDetailAsync.valueOrNull,
    );
    if (widget.mode.isEditing && seed == null) {
      return Scaffold(
        appBar: AppBar(title: Text(_pageTitle)),
        body: Center(
          child: Text(widget.isSeriesMode ? '此習慣不存在' : '此任務不存在或不可編輯'),
        ),
      );
    }

    if (!_initialized) {
      _initializeForm(seed);
    }

    final topicCategories =
        topicCategoriesAsync.valueOrNull ?? const <TopicCategoryModel>[];
    final actionCategories =
        actionCategoriesAsync.valueOrNull ?? const <ActionCategoryModel>[];

    return Scaffold(
      appBar: AppBar(title: Text(_pageTitle)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                key: const Key('edit-title-field'),
                controller: _titleController,
                enabled: !_isReadOnly,
                decoration: const InputDecoration(
                  labelText: '標題',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return '請輸入標題';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                key: const Key('edit-note-field'),
                controller: _noteController,
                enabled: !_isReadOnly,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: '備註（選填）',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              _buildTrackingModeSection(),
              const SizedBox(height: 16),
              _buildTriggerModeSection(),
              const SizedBox(height: 16),
              TextFormField(
                key: const Key('edit-remind-days-field'),
                controller: _triggerOffsetDaysController,
                enabled: !_isReadOnly,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: _trackingMode == ReminderTrackingMode.countdown
                      ? '提前通知天數'
                      : '累積天數',
                  border: const OutlineInputBorder(),
                ),
                validator: (value) {
                  final days = int.tryParse(value ?? '');
                  if (days == null || days < 0) {
                    return '請輸入 0 或以上';
                  }
                  return null;
                },
              ),
              if (_showsDateFields) ...[
                const SizedBox(height: 16),
                if (_trackingMode == ReminderTrackingMode.countdown)
                  _buildDueAtSection(context)
                else
                  _buildStartAtSection(context),
              ],
              const SizedBox(height: 16),
              _buildRepeatSection(),
              const SizedBox(height: 16),
              _buildTopicCategorySection(topicCategories),
              const SizedBox(height: 16),
              _buildActionCategorySection(actionCategories),
              if (!_isReadOnly) ...[
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  key: const Key('random-fill-button'),
                  onPressed: _fillWithRandomDemoData,
                  icon: const Icon(Icons.auto_awesome),
                  label: const Text('[demo]隨機生成欄位資料'),
                ),
              ],
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _closePage,
                      child: Text(_isReadOnly ? '返回' : '取消'),
                    ),
                  ),
                  if (!_isReadOnly) ...[
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: _onSave,
                        child: const Text('儲存'),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String get _pageTitle {
    if (_isReadOnly) {
      return ReminderUiText.viewHabit;
    }
    switch (widget.mode) {
      case ReminderFormMode.reminderCreate:
        return ReminderUiText.addTask;
      case ReminderFormMode.reminderEdit:
        return ReminderUiText.editTask;
      case ReminderFormMode.seriesCreate:
        return ReminderUiText.addHabit;
      case ReminderFormMode.seriesEdit:
        return ReminderUiText.editHabit;
    }
  }

  ReminderFormDraft? _resolveSeed(
    ReminderModel? reminder,
    RecurringReminderModel? recurringReminder,
  ) {
    if (reminder != null) {
      return ReminderFormDraft.fromReminder(reminder);
    }
    if (recurringReminder != null) {
      return ReminderFormDraft.fromRecurringReminder(recurringReminder);
    }
    if (widget.mode.isEditing) {
      return null;
    }
    return ReminderFormDraft.createDefault();
  }

  void _initializeForm(ReminderFormDraft? seed) {
    final currentSeed = seed ?? ReminderFormDraft.createDefault();
    _titleController.text = currentSeed.title;
    _noteController.text = currentSeed.note ?? '';
    _triggerOffsetDaysController.text = currentSeed.triggerOffsetDays
        .toString();
    _trackingMode = currentSeed.trackingMode;
    _triggerMode = currentSeed.triggerMode;
    _dueAt = currentSeed.dueAt;
    _startAt = currentSeed.startAt;
    _selectedTopicCategoryId = currentSeed.topicCategoryId;
    _selectedActionCategoryId = currentSeed.actionCategoryId;
    _isReadOnly = currentSeed.readOnly;
    _applyRepeatRule(currentSeed.repeatRule);
    _initialized = true;
  }

  Widget _buildTrackingModeSection() {
    final isLocked = _isReadOnly || widget.isSeriesEdit;
    return DropdownButtonFormField<int>(
      key: const Key('edit-time-basis-field'),
      initialValue: _trackingMode,
      decoration: const InputDecoration(
        labelText: ReminderUiText.trackingModeField,
        border: OutlineInputBorder(),
      ),
      items: ReminderTrackingModeOption.values
          .map(
            (option) => DropdownMenuItem(
              value: option.value,
              child: Text(option.label),
            ),
          )
          .toList(growable: false),
      onChanged: isLocked
          ? null
          : (value) {
              if (value == null) {
                return;
              }
              setState(() {
                _trackingMode = value;
                _startAt ??= DateTime.now();
                if (_trackingMode == ReminderTrackingMode.accumulation) {
                  _dueAt = null;
                  _triggerMode = ReminderTriggerMode.inRange;
                }
              });
            },
    );
  }

  Widget _buildTriggerModeSection() {
    return DropdownButtonFormField<int>(
      key: const Key('edit-notify-strategy-field'),
      initialValue: _triggerMode,
      decoration: const InputDecoration(
        labelText: ReminderUiText.triggerModeField,
        border: OutlineInputBorder(),
      ),
      items: ReminderTriggerModeOption.forTrackingMode(_trackingMode)
          .map(
            (option) => DropdownMenuItem(
              value: option.value,
              child: Text(option.label),
            ),
          )
          .toList(growable: false),
      onChanged: _isReadOnly
          ? null
          : (value) {
              if (value == null) {
                return;
              }
              setState(() {
                _triggerMode = value;
              });
            },
    );
  }

  Widget _buildDueAtSection(BuildContext context) {
    final dueText = _dueAt == null
        ? '未設定'
        : DateFormat('yyyy/MM/dd').format(_dueAt!.toLocal());

    return InputDecorator(
      decoration: const InputDecoration(
        labelText: ReminderUiText.fixedTimeField,
        border: OutlineInputBorder(),
      ),
      child: Row(
        children: [
          Expanded(child: Text(dueText, key: const Key('edit-due-at-text'))),
          TextButton(
            onPressed: _isReadOnly
                ? null
                : () => _pickDate(
                    context,
                    initial: _dueAt ?? DateTime.now(),
                    onPicked: (value) => setState(() => _dueAt = value),
                  ),
            child: const Text('選擇'),
          ),
          TextButton(
            onPressed: _isReadOnly ? null : () => setState(() => _dueAt = null),
            child: const Text('清除'),
          ),
        ],
      ),
    );
  }

  Widget _buildStartAtSection(BuildContext context) {
    final startText = _startAt == null
        ? '未設定'
        : DateFormat('yyyy/MM/dd').format(_startAt!.toLocal());

    return InputDecorator(
      decoration: const InputDecoration(
        labelText: ReminderUiText.startDateField,
        border: OutlineInputBorder(),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(startText, key: const Key('edit-start-at-text')),
          ),
          TextButton(
            onPressed: _isReadOnly
                ? null
                : () => _pickDate(
                    context,
                    initial: _startAt ?? DateTime.now(),
                    onPicked: (value) => setState(() => _startAt = value),
                  ),
            child: const Text('選擇'),
          ),
          TextButton(
            onPressed: _isReadOnly
                ? null
                : () => setState(() => _startAt = DateTime.now()),
            child: const Text('現在'),
          ),
        ],
      ),
    );
  }

  Widget _buildRepeatSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<String?>(
          key: ValueKey<String?>(
            _repeatType == null
                ? 'repeat-type-null'
                : 'repeat-type-$_repeatType',
          ),
          initialValue: _repeatType,
          decoration: InputDecoration(
            labelText: _requiresRepeatRule ? '重複規則類型（必填）' : '重複規則類型',
            border: const OutlineInputBorder(),
          ),
          items: const [
            DropdownMenuItem<String?>(value: null, child: Text('不重複')),
            DropdownMenuItem<String?>(value: 'D', child: Text('每 N 天')),
            DropdownMenuItem<String?>(value: 'W', child: Text('每 N 週')),
            DropdownMenuItem<String?>(value: 'M', child: Text('每 N 月')),
            DropdownMenuItem<String?>(value: 'Y', child: Text('每 N 年')),
          ],
          onChanged: _isReadOnly
              ? null
              : (value) {
                  setState(() {
                    _repeatType = value;
                  });
                },
        ),
        const SizedBox(height: 12),
        TextFormField(
          key: const Key('edit-repeat-interval-field'),
          controller: _repeatIntervalController,
          enabled: !_isReadOnly,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: '重複間隔（預設 1）',
            border: OutlineInputBorder(),
          ),
          validator: (value) {
            if (_repeatType == null) {
              return null;
            }
            final interval = int.tryParse(value ?? '');
            if (interval == null || interval < 1) {
              return '請輸入 1 或以上';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildTopicCategorySection(List<TopicCategoryModel> topicCategories) {
    return DropdownButtonFormField<int?>(
      key: const Key('edit-issue-type-field'),
      initialValue: _selectedTopicCategoryId,
      decoration: const InputDecoration(
        labelText: '主題分類',
        border: OutlineInputBorder(),
      ),
      items: [
        const DropdownMenuItem<int?>(value: null, child: Text('未指定')),
        ...topicCategories.map(
          (item) =>
              DropdownMenuItem<int?>(value: item.id, child: Text(item.name)),
        ),
      ],
      onChanged: _isReadOnly
          ? null
          : (value) {
              setState(() {
                _selectedTopicCategoryId = value;
              });
            },
    );
  }

  Widget _buildActionCategorySection(
    List<ActionCategoryModel> actionCategories,
  ) {
    return DropdownButtonFormField<int?>(
      key: const Key('edit-handle-type-field'),
      initialValue: _selectedActionCategoryId,
      decoration: const InputDecoration(
        labelText: '行動分類',
        border: OutlineInputBorder(),
      ),
      items: [
        const DropdownMenuItem<int?>(value: null, child: Text('未指定')),
        ...actionCategories.map(
          (item) =>
              DropdownMenuItem<int?>(value: item.id, child: Text(item.name)),
        ),
      ],
      onChanged: _isReadOnly
          ? null
          : (value) {
              setState(() {
                _selectedActionCategoryId = value;
              });
            },
    );
  }

  Future<void> _pickDate(
    BuildContext context, {
    required DateTime initial,
    required ValueChanged<DateTime> onPicked,
  }) async {
    final now = DateTime.now();
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 10),
    );

    if (pickedDate == null || !mounted || !context.mounted) {
      return;
    }

    onPicked(DateTime(pickedDate.year, pickedDate.month, pickedDate.day));
  }

  void _applyRepeatRule(String? repeatRule) {
    if (repeatRule == null || repeatRule.isEmpty) {
      _repeatType = null;
      _repeatIntervalController.text = '1';
      return;
    }

    final match = RegExp(r'^([DWMY])(\d+)$').firstMatch(repeatRule);
    if (match == null) {
      _repeatType = null;
      _repeatIntervalController.text = '1';
      return;
    }

    _repeatType = match.group(1);
    _repeatIntervalController.text = match.group(2)!;
  }

  void _fillWithRandomDemoData() {
    final draft = ReminderFormDraft.fromDemo(
      widget.demoDataFactory?.call() ?? DemoReminderDraft.random(),
    );
    setState(() {
      _titleController.text = draft.title;
      _noteController.text = draft.note ?? '';
      _trackingMode = draft.trackingMode;
      _triggerMode = draft.triggerMode;
      _triggerOffsetDaysController.text = draft.triggerOffsetDays.toString();
      _dueAt = draft.dueAt;
      _startAt = draft.startAt;
      _applyRepeatRule(draft.repeatRule);
    });
  }

  Future<void> _onSave() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_requiresRepeatRule && _buildRepeatRule() == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(ReminderUiText.habitRepeatRuleRequired)),
      );
      return;
    }

    if (_showsDateFields &&
        _trackingMode == ReminderTrackingMode.countdown &&
        _dueAt == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(ReminderUiText.fixedTimeRequired)),
      );
      return;
    }

    final repository = ref.read(reminderRepositoryProvider);
    final input = ReminderInput(
      title: _titleController.text.trim(),
      note: _noteController.text.trim().isEmpty
          ? null
          : _noteController.text.trim(),
      trackingMode: _trackingMode,
      triggerMode: _triggerMode,
      triggerOffsetDays: int.parse(_triggerOffsetDaysController.text),
      dueAt: _trackingMode == ReminderTrackingMode.countdown ? _dueAt : null,
      startAt: _startAt ?? DateTime.now(),
      repeatRule: _buildRepeatRule(),
      topicCategoryId: _selectedTopicCategoryId,
      actionCategoryId: _selectedActionCategoryId,
    );

    var success = true;
    switch (widget.mode) {
      case ReminderFormMode.reminderCreate:
        await repository.create(input);
      case ReminderFormMode.reminderEdit:
        success = await repository.updateById(widget.reminderId!, input);
      case ReminderFormMode.seriesCreate:
        await repository.createRecurringReminderWithFirstOccurrence(input);
      case ReminderFormMode.seriesEdit:
        success = await repository.updateRecurringReminderById(
          widget.seriesId!,
          input,
        );
    }

    if (!success && mounted) {
      final message = widget.isSeriesMode ? '此習慣不可編輯' : '此任務不可編輯';
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
      return;
    }

    if (mounted) {
      _closePage();
    }
  }

  void _closePage() {
    final navigator = Navigator.maybeOf(context);
    if (navigator != null && navigator.canPop()) {
      navigator.pop();
      return;
    }

    final router = GoRouter.maybeOf(context);
    if (router != null) {
      router.pop();
    }
  }

  String? _buildRepeatRule() {
    if (_repeatType == null) {
      return null;
    }

    final interval = int.tryParse(_repeatIntervalController.text);
    if (interval == null || interval < 1) {
      return null;
    }

    return '$_repeatType$interval';
  }
}
