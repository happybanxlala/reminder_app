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
  late final TextEditingController _remindDaysController;
  late final TextEditingController _repeatIntervalController;

  bool _initialized = false;
  bool _isReadOnly = false;
  int _timeBasis = ReminderTrackingMode.countdown;
  int _notifyStrategy = ReminderTriggerMode.inRange;
  String? _repeatType;
  DateTime? _dueAt;
  DateTime? _startAt;
  int? _selectedIssueTypeId;
  int? _selectedHandleTypeId;

  bool get _showsDateFields => !widget.isSeriesEdit;
  bool get _requiresRepeatRule => widget.isSeriesMode;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _noteController = TextEditingController();
    _remindDaysController = TextEditingController(text: '0');
    _repeatIntervalController = TextEditingController(text: '1');
  }

  @override
  void dispose() {
    _titleController.dispose();
    _noteController.dispose();
    _remindDaysController.dispose();
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
          child: Text(widget.isSeriesMode ? '此週期提醒不存在' : '此提醒不存在或不可編輯'),
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
              _buildTimeBasisSection(),
              const SizedBox(height: 16),
              _buildNotifyStrategySection(),
              const SizedBox(height: 16),
              TextFormField(
                key: const Key('edit-remind-days-field'),
                controller: _remindDaysController,
                enabled: !_isReadOnly,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: _timeBasis == ReminderTrackingMode.countdown
                      ? '提前提醒天數'
                      : '累積提醒天數',
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
                if (_timeBasis == ReminderTrackingMode.countdown)
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
      return '檢視週期提醒';
    }
    switch (widget.mode) {
      case ReminderFormMode.reminderCreate:
        return '新增提醒';
      case ReminderFormMode.reminderEdit:
        return '編輯提醒';
      case ReminderFormMode.seriesCreate:
        return '新增週期提醒';
      case ReminderFormMode.seriesEdit:
        return '編輯週期提醒';
    }
  }

  _ReminderFormSeed? _resolveSeed(
    ReminderModel? reminder,
    RecurringReminderModel? recurringReminder,
  ) {
    if (reminder != null) {
      return _ReminderFormSeed.fromReminder(reminder);
    }
    if (recurringReminder != null) {
      return _ReminderFormSeed.fromRecurringReminder(recurringReminder);
    }
    if (widget.mode.isEditing) {
      return null;
    }
    return _ReminderFormSeed.createDefault();
  }

  void _initializeForm(_ReminderFormSeed? seed) {
    final currentSeed = seed ?? _ReminderFormSeed.createDefault();
    _titleController.text = currentSeed.title;
    _noteController.text = currentSeed.note ?? '';
    _remindDaysController.text = currentSeed.remindDays.toString();
    _timeBasis = currentSeed.timeBasis;
    _notifyStrategy = currentSeed.notifyStrategy;
    _dueAt = currentSeed.dueAt;
    _startAt = currentSeed.startAt;
    _selectedIssueTypeId = currentSeed.issueTypeId;
    _selectedHandleTypeId = currentSeed.handleTypeId;
    _isReadOnly = currentSeed.readOnly;
    _applyRepeatRule(currentSeed.repeatRule);
    _initialized = true;
  }

  Widget _buildTimeBasisSection() {
    final isLocked = _isReadOnly || widget.isSeriesEdit;
    return DropdownButtonFormField<int>(
      key: const Key('edit-time-basis-field'),
      initialValue: _timeBasis,
      decoration: const InputDecoration(
        labelText: '提醒類型',
        border: OutlineInputBorder(),
      ),
      items: const [
        DropdownMenuItem(
          value: ReminderTrackingMode.countdown,
          child: Text('倒數式'),
        ),
        DropdownMenuItem(
          value: ReminderTrackingMode.countUp,
          child: Text('起計式'),
        ),
      ],
      onChanged: isLocked
          ? null
          : (value) {
              if (value == null) {
                return;
              }
              setState(() {
                _timeBasis = value;
                _startAt ??= DateTime.now();
                if (_timeBasis == ReminderTrackingMode.countUp) {
                  _dueAt = null;
                  _notifyStrategy = ReminderTriggerMode.inRange;
                }
              });
            },
    );
  }

  Widget _buildNotifyStrategySection() {
    final items = _timeBasis == ReminderTrackingMode.countdown
        ? const [
            DropdownMenuItem(
              value: ReminderTriggerMode.inRange,
              child: Text('進入範圍提醒'),
            ),
            DropdownMenuItem(
              value: ReminderTriggerMode.immediate,
              child: Text('建立後立即提醒'),
            ),
            DropdownMenuItem(
              value: ReminderTriggerMode.onPoint,
              child: Text('到期才提醒'),
            ),
          ]
        : const [
            DropdownMenuItem(
              value: ReminderTriggerMode.inRange,
              child: Text('累積達標後提醒'),
            ),
          ];

    return DropdownButtonFormField<int>(
      key: const Key('edit-notify-strategy-field'),
      initialValue: _notifyStrategy,
      decoration: const InputDecoration(
        labelText: '提醒策略',
        border: OutlineInputBorder(),
      ),
      items: items,
      onChanged: _isReadOnly
          ? null
          : (value) {
              if (value == null) {
                return;
              }
              setState(() {
                _notifyStrategy = value;
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
        labelText: '到期時間',
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
        labelText: '起計時間',
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
      initialValue: _selectedIssueTypeId,
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
                _selectedIssueTypeId = value;
              });
            },
    );
  }

  Widget _buildActionCategorySection(
    List<ActionCategoryModel> actionCategories,
  ) {
    return DropdownButtonFormField<int?>(
      key: const Key('edit-handle-type-field'),
      initialValue: _selectedHandleTypeId,
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
                _selectedHandleTypeId = value;
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
    final draft = widget.demoDataFactory?.call() ?? DemoReminderDraft.random();
    setState(() {
      _titleController.text = draft.title;
      _noteController.text = draft.note ?? '';
      _timeBasis = draft.trackingMode;
      _notifyStrategy = draft.triggerMode;
      _remindDaysController.text = draft.triggerOffsetDays.toString();
      _dueAt = draft.dueAt;
      _startAt = draft.startAt;
      _repeatType = draft.repeatType;
      _repeatIntervalController.text = draft.repeatInterval.toString();
    });
  }

  Future<void> _onSave() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_requiresRepeatRule && _buildRepeatRule() == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('週期提醒需要設定重複規則')));
      return;
    }

    if (_showsDateFields &&
        _timeBasis == ReminderTrackingMode.countdown &&
        _dueAt == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('倒數式提醒需要設定到期時間')));
      return;
    }

    final repository = ref.read(reminderRepositoryProvider);
    final input = ReminderInput(
      title: _titleController.text.trim(),
      note: _noteController.text.trim().isEmpty
          ? null
          : _noteController.text.trim(),
      trackingMode: _timeBasis,
      triggerMode: _notifyStrategy,
      triggerOffsetDays: int.parse(_remindDaysController.text),
      dueAt: _timeBasis == ReminderTrackingMode.countdown ? _dueAt : null,
      startAt: _startAt ?? DateTime.now(),
      repeatRule: _buildRepeatRule(),
      topicCategoryId: _selectedIssueTypeId,
      actionCategoryId: _selectedHandleTypeId,
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
      final message = widget.isSeriesMode ? '此週期提醒不可編輯' : '此提醒不可編輯';
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

class _ReminderFormSeed {
  const _ReminderFormSeed({
    required this.title,
    this.note,
    required this.timeBasis,
    required this.notifyStrategy,
    required this.remindDays,
    this.repeatRule,
    this.dueAt,
    this.startAt,
    this.issueTypeId,
    this.handleTypeId,
    this.readOnly = false,
  });

  factory _ReminderFormSeed.createDefault() {
    return _ReminderFormSeed(
      title: '',
      note: null,
      timeBasis: ReminderTrackingMode.countdown,
      notifyStrategy: ReminderTriggerMode.inRange,
      remindDays: 0,
      startAt: DateTime.now(),
    );
  }

  factory _ReminderFormSeed.fromReminder(ReminderModel reminder) {
    return _ReminderFormSeed(
      title: reminder.title,
      note: reminder.note,
      timeBasis: reminder.trackingMode,
      notifyStrategy: reminder.triggerMode,
      remindDays: reminder.triggerOffsetDays ?? 0,
      repeatRule: reminder.repeatRule,
      dueAt: reminder.dueAt,
      startAt: reminder.startAt,
      issueTypeId: reminder.topicCategoryId,
      handleTypeId: reminder.actionCategoryId,
    );
  }

  factory _ReminderFormSeed.fromRecurringReminder(
    RecurringReminderModel recurringReminder,
  ) {
    return _ReminderFormSeed(
      title: recurringReminder.title,
      note: recurringReminder.note,
      timeBasis: recurringReminder.trackingMode,
      notifyStrategy: recurringReminder.triggerMode,
      remindDays: recurringReminder.triggerOffsetDays ?? 0,
      repeatRule: recurringReminder.repeatRule,
      issueTypeId: recurringReminder.topicCategoryId,
      handleTypeId: recurringReminder.actionCategoryId,
      readOnly: recurringReminder.isCanceled,
    );
  }

  final String title;
  final String? note;
  final int timeBasis;
  final int notifyStrategy;
  final int remindDays;
  final String? repeatRule;
  final DateTime? dueAt;
  final DateTime? startAt;
  final int? issueTypeId;
  final int? handleTypeId;
  final bool readOnly;
}
